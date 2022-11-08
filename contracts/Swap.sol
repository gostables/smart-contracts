// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./JLMarket.sol";
import "./gStable.sol";
import "./ClientAuth.sol";
import "./goStableBase.sol";

contract Swap is Ownable, goStableBase {
    uint256 public conversionRatio = 0;
    uint256 public swapFeesFactor = 0;
    uint256 public accumulatedSwapFees = 0;
    uint256 public rewardPC = 40;

    event Deposit(
        address depositor,
        uint256 amount,
        uint256 conversionRatio,
        uint256 swapFeesFactor
    );
    event Withdrawal(
        address withdrawer,
        uint256 _tokens,
        uint256 conversionRatio,
        uint256 swapFeesFactor
    );

    constructor(
        address stableCoinAddress,
        address marketAddress,
        address gStableAddress
    ) goStableBase(stableCoinAddress, marketAddress, gStableAddress) {}

    function setConversion(uint256 ratio) public onlyClients(msg.sender) {
        conversionRatio = ratio;
    }

    function getConversion() public view returns (uint256) {
        return conversionRatio;
    }

    function setSwapFeesFactor(uint256 fees) public onlyClients(msg.sender) {
        swapFeesFactor = fees;
    }

    function setRewardsPercent(uint256 _rewardPC)
        public
        onlyClients(msg.sender)
    {
        rewardPC = _rewardPC;
    }

    function deposit(uint256 _amount) external onlyPositive(_amount) {
        require(
            _amount <= stableCoin.balanceOf(msg.sender),
            "amount > stableCoinsbalance"
        );

        stableCoin.transferFrom(msg.sender, address(this), _amount);

        uint256 swapFees = (_amount * swapFeesFactor) / 10000;
        accumulatedSwapFees += swapFees;

        stableCoin.approve(address(market), _amount * 2);
        market.mint(_amount - swapFees);

        uint256 tokens = ((_amount - swapFees) * conversionRatio) / 10000;
        gStableCoin.mint(msg.sender, tokens);

        emit Deposit(msg.sender, _amount, conversionRatio, swapFeesFactor);
    }

    function withdraw(uint256 _tokens) external onlyPositive(_tokens) {
        require(
            _tokens <= gStableCoin.balanceOf(msg.sender),
            "_tokens > gStableCoinsbalance"
        );

        gStableCoin.burn(msg.sender, _tokens);

        uint256 _amount = (_tokens * 10000) / conversionRatio;

        market.redeemUnderlying(_amount);

        uint256 swapFees = (_amount * swapFeesFactor) / 10000;
        accumulatedSwapFees += swapFees;

        stableCoin.transfer(msg.sender, _amount - swapFees);

        emit Withdrawal(msg.sender, _tokens, conversionRatio, swapFeesFactor);
    }

    function transferRewards(address vaultAddress)
        external
        onlyClients(msg.sender)
    {
        require(vaultAddress != address(0));

        uint256 swapFeesAsRewards = (accumulatedSwapFees * rewardPC) / 100;

        // Transfer rewards in gStable to Vault
        uint256 rewardTokens = (swapFeesAsRewards * conversionRatio) / 10000;
        gStableCoin.mint(vaultAddress, rewardTokens);

        // supply accumulateSwapFees to JL and get JL tokens
        stableCoin.approve(address(market), accumulatedSwapFees * 2);
        market.mint(accumulatedSwapFees);

        //reset accumulatedSwapFees
        accumulatedSwapFees = 0;
    }
}
