// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./JLMarket.sol";
import "./gStable.sol";
import "./goStableBase.sol";

contract Vault is Ownable, goStableBase {
    uint256 public interval = 2;
    uint256 public totalValue = 0;
    uint256 public allocatedRewards = 0;

    mapping(address => uint256) balances;
    mapping(address => uint256) lockPeriod;
    mapping(address => uint256) rewards;

    mapping(address => bool) isParticipant;
    address[] participants;

    event Deposit(address depositor, uint256 amount);
    event Withdrawal(address withdrawer, uint256 _tokens);

    constructor(
        address stableCoinAddress,
        address marketAddress,
        address gStableAddress
    ) goStableBase(stableCoinAddress, marketAddress, gStableAddress) {}

    function setLockInterval(uint256 _interval) public onlyClients(msg.sender) {
        interval = _interval;
    }

    function getBalance(address hodler) public view returns (uint256, uint256) {
        return (balances[hodler], lockPeriod[hodler]);
    }

    function getCurrentRewardsValue(address hodler)
        public
        view
        returns (uint256)
    {
        return (rewards[hodler]);
    }

    function deposit(uint256 _amount) external onlyPositive(_amount) {
        require(
            _amount <= stableCoin.balanceOf(msg.sender),
            "amount > stableCoinsbalance"
        );

        stableCoin.transferFrom(msg.sender, address(this), _amount);
        balances[msg.sender] += _amount;
        lockPeriod[msg.sender] = block.timestamp + (interval * 1 minutes);
        totalValue += _amount;

        stableCoin.approve(address(market), _amount * 2);
        market.mint(_amount);
        if (!isParticipant[msg.sender]) {
            isParticipant[msg.sender] = true;
            participants.push(msg.sender);
        }

        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external onlyPositive(_amount) {
        require(_amount <= balances[msg.sender], "amount > balance");
        require(block.timestamp > lockPeriod[msg.sender], "< period");

        balances[msg.sender] -= _amount;
        // lockPeriod[msg.sender] = 0;
        totalValue -= _amount;

        market.redeemUnderlying(_amount);

        stableCoin.transfer(msg.sender, _amount);

        emit Withdrawal(msg.sender, _amount);
    }

    function setRewards(uint256 amountgStable)
        external
        onlyClients(msg.sender)
    {
        require(
            amountgStable <= gStableCoin.balanceOf(address(this)),
            "gStable amount > balance"
        );
        for (uint256 i = 0; i < participants.length; i++) {
            rewards[participants[i]] +=
                (amountgStable * balances[participants[i]]) /
                totalValue;
        }
        allocatedRewards += amountgStable;
    }

    function getPendingRewards(address hodler) public view returns (uint256) {
        return (rewards[hodler]);
    }

    function claimRewards(uint256 amountgStable) external {
        require(amountgStable <= rewards[msg.sender], "amount > rewards");
        allocatedRewards -= amountgStable;
        gStableCoin.transfer(msg.sender, amountgStable);
        rewards[msg.sender] -= amountgStable;
    }
}
