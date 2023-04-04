// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./gStable.sol";
import "./gStableManager.sol";
import "./goStableBase.sol";
import "./Rewards.sol";

contract VaultStableCoin is goStableBase, Pausable, ReentrancyGuard {
    mapping (uint => uint256) public gStableIntervalMap;
    mapping (uint => uint256) public gStableTotalValueMap;
    mapping (uint => uint256) public gStableAllocatedRewardsMap;

    mapping(uint => mapping(address => uint256)) gStableBalanceMap;
    mapping(uint => mapping(address => uint256)) gStableLockPeriodMap;
    mapping(uint => mapping(address => uint256)) gStableRewardMap;

    mapping(uint => mapping(address => bool)) isParticipant;
    mapping(uint => address[]) participants;

    IRewards rewards;
    IgStableManager gStableLookup; 

    event Deposit(address depositor, uint256 amount, uint gStableId);
    event Withdrawal(address withdrawer, uint256 _tokens, uint gStableId);
    event ClaimReward(address hodler, uint256 reward, uint gStableId);

    constructor(
        address stableCoinAddress,
        address marketAddress,
        address rewardsAddress_,
        address gStableLookupAddress_
    ) goStableBase(stableCoinAddress, marketAddress) {
        rewards = IRewards(rewardsAddress_);
        gStableLookup = IgStableManager(gStableLookupAddress_);        
    }

    function pause() public onlyAdmin(msg.sender) {
        _pause();
    }

    function unpause() public onlyAdmin(msg.sender) {
        _unpause();
    }

    function setRewardsAddress(address addr) public onlyAdmin(msg.sender) {
        rewards = IRewards(addr);
    } 

    function setGStableLookup(address addr) public onlyAdmin(msg.sender) {
        gStableLookup = IgStableManager(addr);
    }         

    modifier hasGStableAddress(uint id) {
        require(gStableLookup.getGStableAddress(id) != address(0), "No gStable exists");
        _;
    }
    
    modifier isGStable(uint id) {
        require(!gStableLookup.isStableCoin(id), "stable coins not allowed");
        _;
    }       

    function setLockInterval(uint id, uint256 _interval) public onlyAdmin(msg.sender) {
        gStableIntervalMap[id] = _interval;
    }

    function getBalance(uint id, address hodler) public view returns (uint256, uint256) {
        return (gStableBalanceMap[id][hodler], gStableLockPeriodMap[id][hodler]);
    }

    function deposit(uint id, uint256 _tokens) external hasGStableAddress(id) onlyPositive(_tokens) whenNotPaused nonReentrant  {
        require(
            _tokens <= stableCoin.balanceOf(msg.sender),
            "amount > stableCoinsbalance"
        );
        
        gStableBalanceMap[id][msg.sender] += _tokens;
        gStableLockPeriodMap[id][msg.sender] = block.timestamp + (gStableIntervalMap[id] * 1 minutes);
        gStableTotalValueMap[id] += _tokens;

        stableCoin.transferFrom(msg.sender, address(this), _tokens);
        stableCoin.approve(address(market), _tokens * 2);
        market.mint(_tokens);
        if (!isParticipant[id][msg.sender]) {
            isParticipant[id][msg.sender] = true;
            participants[id].push(msg.sender);
        }

        emit Deposit(msg.sender, _tokens, id);
    }

    function withdraw(uint id, uint256 _tokens) external hasGStableAddress(id) onlyPositive(_tokens) whenNotPaused nonReentrant {
        require(_tokens <= gStableBalanceMap[id][msg.sender], "amount > balance");
        require(block.timestamp > gStableLockPeriodMap[id][msg.sender], "< period");

        gStableBalanceMap[id][msg.sender] -= _tokens;
        gStableTotalValueMap[id] -= _tokens;

        market.redeemUnderlying(_tokens);
        stableCoin.transfer(msg.sender, _tokens);

        emit Withdrawal(msg.sender, _tokens, id);
    }

    function setRewards(uint id, uint256 _tokens)
        external
        onlyAdmin(msg.sender)
    {
        require(
            _tokens <= IgStable(gStableLookup.getGStableAddress(id)).balanceOf(address(this)) - gStableAllocatedRewardsMap[id] ,
            "gStable amount > balance"
        );
        for (uint256 i = 0; i < participants[id].length; i++) {
            gStableRewardMap[id][participants[id][i]] +=
                (_tokens * gStableBalanceMap[id][participants[id][i]]) /
                gStableTotalValueMap[id];
        }
        gStableAllocatedRewardsMap[id] += _tokens;
    }

    function getPendingRewards(uint id, address hodler) public view returns (uint256) {
        return (gStableRewardMap[id][hodler]);
    }

    function claimRewards(uint id, uint256 _tokens) external hasGStableAddress(id) onlyPositive(_tokens) whenNotPaused nonReentrant {
        require(_tokens <= gStableRewardMap[id][msg.sender], "amount > rewards");

        gStableAllocatedRewardsMap[id] -= _tokens;
        gStableRewardMap[id][msg.sender] -= _tokens;
        
        IgStable(gStableLookup.getGStableAddress(id)).transfer(msg.sender, _tokens);

        emit ClaimReward(msg.sender, _tokens, id);
    }

    function claim(uint256 merkleIndex, uint256 index, uint256 amount, bytes32[] calldata merkleProof) public onlyAdmin(msg.sender) {
        rewards.claim(merkleIndex, index, amount, merkleProof);
    }     
}
