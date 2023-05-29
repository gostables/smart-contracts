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
    uint public usddId;  // ID of USDD stablecoin

    mapping(uint => uint256) public gStableTotalValueMap;
    mapping(uint => mapping(address => uint256)) public  gStableBalanceMap;

    mapping(uint => uint256) public gStableAccumulatedFeeMap;

    event Deposit(address depositor, uint256 amount, uint gStableId);
    event Withdrawal(address withdrawer, uint256 _tokens, uint gStableId);
    event Sent(address from, uint256 _tokens, uint gStableId, address to);
    event Exchange(address from, uint fromGStableId, uint256 fromTokens,  uint toGStableId, uint256 toTokens);
    event Claimed(address to, uint256 amount);

    IRewards rewards;
    IgStableManager gStableLookup;

    // 1 deposit 2 withdraw 3 send 4 convert 5 transferGL 6 convertGL
    mapping(uint => uint) public functionFeeBasisPoint;

    constructor(address rewardsAddress_,
        address gStableLookupAddress_) {
        rewards = IRewards(rewardsAddress_);
        gStableLookup = IgStableManager(gStableLookupAddress_);
    }

    modifier onlyPositive(uint256 val) {
        require(val > 0, "<0");
        _;
    }    

    modifier isGStable(uint256 id) {
        require(!gStableLookup.isStableCoin(id), "is stable coin");
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

    function setRewards(address rewardsAddress_) public onlyAdmin(msg.sender) {
        rewards = IRewards(rewardsAddress_);
    }

    function setUsddId(uint usddId_) public onlyAdmin(msg.sender) {
        usddId = usddId_;  // Set the usddId value
    }

    function setGStableLookup(address addr) public onlyAdmin(msg.sender) {
        gStableLookup = IgStableManager(addr);
    }  

    function setFeeBasisPoint(uint256 fnCode, uint256 feeBasisPoint_) public onlyAdmin(msg.sender) {
        functionFeeBasisPoint[fnCode] = feeBasisPoint_;
    }
    
    function withdrawFeesForGStable(uint256 id, uint256 _tokens) public onlyAdmin(msg.sender) {
        address gStableAddress = gStableLookup.getGStableAddress(id);
        IgStable gStable_ = IgStable(gStableAddress);

        gStable_.transfer(msg.sender, _tokens);

        gStableAccumulatedFeeMap[id] -= _tokens;
    }           

    function deposit(uint id, uint256 _tokens) external hasGStableAddress(id) onlyPositive(_tokens) whenNotPaused nonReentrant  {
        address gStableAddress = gStableLookup.getGStableAddress(id);
        IgStable gStable_ = IgStable(gStableAddress);
        require(
            _tokens <= gStable_.balanceOf(msg.sender),
            "_tokens > gStableCoinsbalance"
        );        
        
        gStable_.transferFrom(msg.sender, address(this), _tokens);
        
        uint fees = (_tokens * functionFeeBasisPoint[1])/(100 * 100);
        gStableAccumulatedFeeMap[id] += fees; 

        uint tokensAfterFees = _tokens - fees;

        //JL Market related
        if(gStableLookup.isStableCoin(id)){
            address marketAddress_ = gStableLookup.getGStableMarketAddress(id);
            IJLMarket market = IJLMarket(marketAddress_);
            uint allowance = gStable_.allowance(address(this), marketAddress_);
            if(allowance < tokensAfterFees){
                gStable_.approve(marketAddress_, tokensAfterFees * 10);
            }
            market.mint(tokensAfterFees);
        }


        gStableBalanceMap[id][msg.sender] += tokensAfterFees;
        gStableTotalValueMap[id] += tokensAfterFees;

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

        uint fees = (_tokens * functionFeeBasisPoint[2])/(100 * 100);
        gStableAccumulatedFeeMap[id] += fees; 

        gStable_.transfer(msg.sender, _tokens - fees);

        emit Withdrawal(msg.sender, _tokens, id);
    }

    function send(uint id, uint256 _tokens, address toAddress) external hasGStableAddress(id) onlyPositive(_tokens) whenNotPaused nonReentrant  {
        require(
            _tokens <= gStableBalanceMap[id][msg.sender],
            "gStable amount > balance"
        );

        gStableBalanceMap[id][msg.sender] -= _tokens;

        uint fees = (_tokens * functionFeeBasisPoint[3])/(100 * 100);
        gStableAccumulatedFeeMap[id] += fees; 

        gStableBalanceMap[id][toAddress] += _tokens - fees;

        emit Sent(msg.sender, _tokens, id, toAddress);
    } 

    function exchange(uint fromId, uint256 fromTokens, uint toId) external  onlyPositive(fromTokens) isGStable(fromId) isGStable(toId)  {
        require(fromTokens <= gStableBalanceMap[fromId][msg.sender], "not enough balance");

        uint fees = (fromTokens * functionFeeBasisPoint[4])/(100 * 100);
        gStableAccumulatedFeeMap[fromId] += fees;

        uint fromTokensAfterFees = (fromTokens - fees);

        uint256 toTokens = (fromTokensAfterFees * gStableLookup.getConversion(toId)) / gStableLookup.getConversion(fromId);

        gStableBalanceMap[fromId][msg.sender] -= fromTokens;
        gStableBalanceMap[toId][msg.sender] += toTokens;

        gStableLookup.burn(address(this), fromId, fromTokensAfterFees);

        gStableLookup.mint(address(this), toId, toTokens);
        
        emit Exchange(msg.sender, fromId, fromTokens, toId, toTokens);
    } 


    function exchangeGL(address hodler, uint fromId, uint256 fromTokens, uint toId) external  onlyPositive(fromTokens) onlyAdmin(msg.sender) returns(uint) {
        if(gStableLookup.isStableCoin(fromId)){
            return 31;
        }
        if(gStableLookup.isStableCoin(toId)){
            return 32;
        }
        if(fromTokens > gStableBalanceMap[fromId][hodler]){
            return 33;
        }

        uint fees = (fromTokens * functionFeeBasisPoint[6])/(100 * 100);
        gStableAccumulatedFeeMap[fromId] += fees;

        uint fromTokensAfterFees = (fromTokens - fees);

        uint256 toTokens = (fromTokensAfterFees * gStableLookup.getConversion(toId)) / gStableLookup.getConversion(fromId);

        gStableBalanceMap[fromId][hodler] -= fromTokens;
        gStableBalanceMap[toId][hodler] += toTokens;

        gStableLookup.burn(address(this), fromId, fromTokensAfterFees);

        gStableLookup.mint(address(this), toId, toTokens);
        
        emit Exchange(hodler, fromId, fromTokens, toId, toTokens);
        return 4;
    }    

    function moveGL(address fromAddress, address toAddress, uint id, uint256 _tokens) external hasGStableAddress(id) onlyPositive(_tokens) whenNotPaused nonReentrant onlyAdmin(msg.sender) returns(uint) {
        if(_tokens > gStableBalanceMap[id][fromAddress]){
            return 3;
        }

        uint fees = (_tokens * functionFeeBasisPoint[5])/(100 * 100);
        gStableAccumulatedFeeMap[id] += fees;

        uint tokensAfterFees = (_tokens - fees);

        gStableBalanceMap[id][fromAddress] -= _tokens;
        gStableBalanceMap[id][toAddress] += tokensAfterFees;

        emit Sent(fromAddress, _tokens, id, toAddress);
        return 4;
    }   

    function claim(uint256 merkleIndex, uint256 index, uint256 amount, bytes32[] calldata merkleProof) public onlyAdmin(msg.sender) {
        rewards.claim(merkleIndex, index, amount, merkleProof);
        
        // Transfer the claimed USDD amount to the admin's sender address
        address adminSender = msg.sender;
        address usddAddress = gStableLookup.getGStableAddress(usddId); 
        IgStable usdd = IgStable(usddAddress);
        usdd.transfer(adminSender, amount);

        emit Claimed(adminSender, amount);
    }    

}

interface IBankDepository {
    function moveGL(address fromAddress, address toAddress, uint id, uint256 _tokens) external returns(uint);
    function exchangeGL(address hodler, uint fromId, uint256 fromTokens, uint toId) external  returns(uint);
}
