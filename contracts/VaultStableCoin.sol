// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./JLMarket.sol";
import "./gStable.sol";
import "./goStableBase2.sol";

contract Vault is Ownable, goStableBase {
    mapping (uint => address) public gStableAddressMap;

    mapping (uint => uint256) public gStableIntervalMap;
    mapping (uint => uint256) public gStableTotalValueMap;
    mapping (uint => uint256) public gStableAllocatedRewardsMap;

    // uint256 public interval = 2;
    // uint256 public totalValue = 0;
    // uint256 public allocatedRewards = 0;

    mapping(uint => mapping(address => uint256)) gStableBalanceMap;
    mapping(uint => mapping(address => uint256)) gStableLockPeriodMap;
    mapping(uint => mapping(address => uint256)) gStableRewardMap;

    // mapping(address => uint256) balances;
    // mapping(address => uint256) lockPeriod;
    // mapping(address => uint256) rewards;

    mapping(uint => mapping(address => bool)) isParticipant;
    mapping(uint => address[]) participants;

    event Deposit(address depositor, uint256 amount, uint gStableId);
    event Withdrawal(address withdrawer, uint256 _tokens, uint gStableId);

    constructor(
        address stableCoinAddress,
        address marketAddress
    ) goStableBase(stableCoinAddress, marketAddress) {}

    function setGStableAddress(uint id, address addr) public onlyAdmin(msg.sender) {
        gStableAddressMap[id] = addr;
    }

    function getGStableAddress(uint id) public view returns (address) {
        return gStableAddressMap[id];
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

    function getCurrentRewardsValue(uint id, address hodler)
        public
        view
        returns (uint256)
    {
        return (gStableRewardMap[id][hodler]);
    }

    function deposit(uint id, uint256 _amount) external hasGStableAddress(id) onlyPositive(_amount) {
        require(
            _amount <= stableCoin.balanceOf(msg.sender),
            "amount > stableCoinsbalance"
        );

        stableCoin.transferFrom(msg.sender, address(this), _amount);
        gStableBalanceMap[id][msg.sender] += _amount;
        gStableLockPeriodMap[id][msg.sender] = block.timestamp + (gStableIntervalMap[id] * 1 minutes);
        gStableTotalValueMap[id] += _amount;

        stableCoin.approve(address(market), _amount * 2);
        market.mint(_amount);
        if (!isParticipant[id][msg.sender]) {
            isParticipant[id][msg.sender] = true;
            participants[id].push(msg.sender);
        }

        emit Deposit(msg.sender, _amount, id);
    }

    function withdraw(uint id, uint256 _amount) external hasGStableAddress(id) onlyPositive(_amount) {
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
            amountgStable <= IgStable(gStableAddressMap[id]).balanceOf(address(this)),
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

    function claimRewards(uint id, uint256 amountgStable) external {
        require(amountgStable <= gStableRewardMap[id][msg.sender], "amount > rewards");
        gStableAllocatedRewardsMap[id] -= amountgStable;
        IgStable(gStableAddressMap[id]).transfer(msg.sender, amountgStable);
        gStableRewardMap[id][msg.sender] -= amountgStable;
    }
}
