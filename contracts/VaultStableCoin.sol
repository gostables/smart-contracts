// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./gStable.sol";
import "./goStableBase.sol";
import "./Rewards.sol";

contract VaultStableCoin is goStableBase, Pausable, ReentrancyGuard {
    mapping (uint => address) public gStableAddressMap;

    mapping (uint => uint256) public gStableIntervalMap;
    mapping (uint => uint256) public gStableTotalValueMap;
    mapping (uint => uint256) public gStableAllocatedRewardsMap;

    mapping(uint => mapping(address => uint256)) gStableBalanceMap;
    mapping(uint => mapping(address => uint256)) gStableLockPeriodMap;
    mapping(uint => mapping(address => uint256)) gStableRewardMap;

    mapping(uint => mapping(address => bool)) isParticipant;
    mapping(uint => address[]) participants;

    address public rewardsAddress; 

    event Deposit(address depositor, uint256 amount, uint gStableId);
    event Withdrawal(address withdrawer, uint256 _tokens, uint gStableId);
    event ClaimReward(address hodler, uint256 reward, uint gStableId);

    constructor(
        address stableCoinAddress,
        address marketAddress,
        address rewardsAddress_ 
    ) goStableBase(stableCoinAddress, marketAddress) {
        rewardsAddress = rewardsAddress_;
    }

    function pause() public onlyAdmin(msg.sender) {
        _pause();
    }

    function unpause() public onlyAdmin(msg.sender) {
        _unpause();
    }

    function setRewardsAddress(address addr) public onlyAdmin(msg.sender) {
        rewardsAddress = addr;
    } 

    function setGStableAddress(uint id, address addr) public onlyAdmin(msg.sender) {
        gStableAddressMap[id] = addr;
        gStableIntervalMap[id] = 2;
    }

    modifier hasGStableAddress(uint id) {
        require(gStableAddressMap[id] != address(0), "No gStable exists for this ID");
        _;
    }     

    function setLockInterval(uint id, uint256 _interval) public onlyAdmin(msg.sender) {
        gStableIntervalMap[id] = _interval;
    }

    function getBalance(uint id, address hodler) public view returns (uint256, uint256) {
        return (gStableBalanceMap[id][hodler], gStableLockPeriodMap[id][hodler]);
    }

    function deposit(uint id, uint256 _amount) external hasGStableAddress(id) onlyPositive(_amount) whenNotPaused nonReentrant  {
        require(
            _amount <= stableCoin.balanceOf(msg.sender),
            "amount > stableCoinsbalance"
        );
        
        gStableBalanceMap[id][msg.sender] += _amount;
        gStableLockPeriodMap[id][msg.sender] = block.timestamp + (gStableIntervalMap[id] * 1 minutes);
        gStableTotalValueMap[id] += _amount;

        stableCoin.transferFrom(msg.sender, address(this), _amount);
        stableCoin.approve(address(market), _amount * 2);
        market.mint(_amount);
        if (!isParticipant[id][msg.sender]) {
            isParticipant[id][msg.sender] = true;
            participants[id].push(msg.sender);
        }

        emit Deposit(msg.sender, _amount, id);
    }

    function withdraw(uint id, uint256 _amount) external hasGStableAddress(id) onlyPositive(_amount) whenNotPaused nonReentrant {
        require(_amount <= gStableBalanceMap[id][msg.sender], "amount > balance");
        require(block.timestamp > gStableLockPeriodMap[id][msg.sender], "< period");

        gStableBalanceMap[id][msg.sender] -= _amount;
        gStableTotalValueMap[id] -= _amount;

        market.redeemUnderlying(_amount);
        stableCoin.transfer(msg.sender, _amount);

        emit Withdrawal(msg.sender, _amount, id);
    }

    function setRewards(uint id, uint256 amountgStable)
        external
        onlyAdmin(msg.sender)
    {
        require(
            amountgStable <= IgStable(gStableAddressMap[id]).balanceOf(address(this)) - gStableAllocatedRewardsMap[id] ,
            "gStable amount > balance"
        );
        for (uint256 i = 0; i < participants[id].length; i++) {
            gStableRewardMap[id][participants[id][i]] +=
                (amountgStable * gStableBalanceMap[id][participants[id][i]]) /
                gStableTotalValueMap[id];
        }
        gStableAllocatedRewardsMap[id] += amountgStable;
    }

    function getPendingRewards(uint id, address hodler) public view returns (uint256) {
        return (gStableRewardMap[id][hodler]);
    }

    function claimRewards(uint id, uint256 amountgStable) external hasGStableAddress(id) onlyPositive(amountgStable) whenNotPaused nonReentrant {
        require(amountgStable <= gStableRewardMap[id][msg.sender], "amount > rewards");

        gStableAllocatedRewardsMap[id] -= amountgStable;
        gStableRewardMap[id][msg.sender] -= amountgStable;
        
        IgStable(gStableAddressMap[id]).transfer(msg.sender, amountgStable);

        emit ClaimReward(msg.sender, amountgStable, id);
    }

    function claim(uint256 merkleIndex, uint256 index, uint256 amount, bytes32[] calldata merkleProof) public onlyAdmin(msg.sender) {
        IRewards(rewardsAddress).claim(merkleIndex, index, amount, merkleProof);
    }     
}
