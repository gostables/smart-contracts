// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./gStableManager.sol";
import "./AdminAuth.sol";
import "./gStable.sol";
import "./Rewards.sol";
import "./JLMarket.sol";

contract BankDepository is AdminAuth, Pausable, ReentrancyGuard {
    mapping(uint => uint256) public gStableTotalValueMap;
    mapping(uint => mapping(address => uint256)) public  gStableBalanceMap;

    event Deposit(address depositor, uint256 amount, uint gStableId);
    event Withdrawal(address withdrawer, uint256 _tokens, uint gStableId);
    event Sent(address from, uint256 _tokens, uint gStableId, address to);
    event Exchange(address from, uint fromGStableId, uint256 fromTokens,  uint toGStableId, uint256 toTokens);

    IRewards rewards;
    IgStableManager gStableLookup;

    address marketAddress;

    constructor(address marketAddress_,
        address rewardsAddress_,
        address gStableLookupAddress_) {
        rewards = IRewards(rewardsAddress_);
        gStableLookup = IgStableManager(gStableLookupAddress_);
        marketAddress = marketAddress_;
    }

    modifier onlyPositive(uint256 val) {
        require(val > 0, "<0");
        _;
    }    

    function pause() public onlyAdmin(msg.sender) {
        _pause();
    }

    function unpause() public onlyAdmin(msg.sender) {
        _unpause();
    }
    modifier hasGStableAddress(uint id) {
        require(gStableLookup.getGStableAddress(id) != address(0), "No gStable exists for this ID");
        _;
    } 

    function deposit(uint id, uint256 _tokens) external hasGStableAddress(id) onlyPositive(_tokens) whenNotPaused nonReentrant  {
        address gStableAddress = gStableLookup.getGStableAddress(id);
        IgStable gStable_ = IgStable(gStableAddress);
        require(
            _tokens <= gStable_.balanceOf(msg.sender),
            "_tokens > gStableCoinsbalance"
        );        
        
        gStable_.transferFrom(msg.sender, address(this), _tokens);

        //JL Market related
        if(gStableLookup.isStableCoin(id)){
            IJLMarket market = IJLMarket(gStableLookup.getGStableMarketAddress(id));
            market.mint(_tokens);
        }

        gStableBalanceMap[id][msg.sender] += _tokens;
        gStableTotalValueMap[id] += _tokens;

        emit Deposit(msg.sender, _tokens, id);
    }

    function withdraw(uint id, uint256 _tokens) external hasGStableAddress(id) onlyPositive(_tokens) whenNotPaused nonReentrant {
        require(_tokens <= gStableBalanceMap[id][msg.sender], "amount > balance");

        gStableBalanceMap[id][msg.sender] -= _tokens;
        gStableTotalValueMap[id] -= _tokens;

        //JL Market related
        if(gStableLookup.isStableCoin(id)){
            IJLMarket market = IJLMarket(gStableLookup.getGStableMarketAddress(id));
            market.redeemUnderlying(_tokens);
        }

        address gStableAddress = gStableLookup.getGStableAddress(id);
        IgStable gStable_ = IgStable(gStableAddress);

        gStable_.transfer(msg.sender, _tokens);

        emit Withdrawal(msg.sender, _tokens, id);
    }

    function send(uint id, uint256 _tokens, address toAddress) external hasGStableAddress(id) onlyPositive(_tokens) whenNotPaused nonReentrant  {
        require(
            _tokens <= gStableBalanceMap[id][msg.sender],
            "gStable amount > balance"
        );

        gStableBalanceMap[id][msg.sender] -= _tokens;
        gStableBalanceMap[id][toAddress] += _tokens;

        emit Sent(msg.sender, _tokens, id, toAddress);
    } 

    function exchangeGL(address hodler, uint fromId, uint256 fromTokens, uint toId) external  onlyPositive(fromTokens) onlyAdmin(msg.sender) returns(uint) {
        if(gStableLookup.isStableCoin(fromId)){
            return 41;
        }
        if(gStableLookup.isStableCoin(toId)){
            return 42;
        }
        if(fromTokens > gStableBalanceMap[fromId][msg.sender]){
            return 43;
        }

        uint256 _amount = (fromTokens * 10000) / gStableLookup.getConversion(fromId);

        uint256 toTokens = (_amount * gStableLookup.getConversion(toId)) / 10000;

        gStableBalanceMap[fromId][hodler] -= fromTokens;
        gStableBalanceMap[toId][hodler] += toTokens;

        gStableLookup.burn(address(this), fromId, fromTokens);

        gStableLookup.mint(address(this), toId, toTokens);
        
        emit Exchange(hodler, fromId, fromTokens, toId, toTokens);
        return 3;
    }    

    function moveGL(address fromAddress, address toAddress, uint id, uint256 _tokens) external hasGStableAddress(id) onlyPositive(_tokens) whenNotPaused nonReentrant onlyAdmin(msg.sender) returns(uint) {
        if(_tokens > gStableBalanceMap[id][fromAddress]){
            return 3;
        }

        gStableBalanceMap[id][fromAddress] -= _tokens;
        gStableBalanceMap[id][toAddress] += _tokens;

        emit Sent(fromAddress, _tokens, id, toAddress);
        return 4;
    }   

    function claim(uint256 merkleIndex, uint256 index, uint256 amount, bytes32[] calldata merkleProof) public onlyAdmin(msg.sender) {
        rewards.claim(merkleIndex, index, amount, merkleProof);
    }      
}

interface IBankDepository {
    function moveGL(address fromAddress, address toAddress, uint id, uint256 _tokens) external returns(uint);
    function exchangeGL(address hodler, uint fromId, uint256 fromTokens, uint toId) external  returns(uint);
}
