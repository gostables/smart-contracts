// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./JLMarket.sol";
import "./gStable.sol";
import "./AdminAuth.sol";
import "./goStableBase2.sol";

contract Swap is Ownable, goStableBase {
    mapping (uint => address) public gStableAddressMap;
    mapping (uint => uint256) public gStableConversionRatioMap;
    mapping (uint => uint256) public gStableAccumulatedSwapFeesMap;

    uint256 public swapFeesFactor = 0;
    uint256 public rewardPC = 40;

    event Deposit(
        address depositor,
        uint256 amount,
        uint gStableId
    );
    event Withdrawal(
        address withdrawer,
        uint256 _tokens,
        uint gStableId
    );

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

    function setConversion( uint id, uint256 ratio) public onlyAdmin(msg.sender) {
        gStableConversionRatioMap[id] = ratio;
    }

    function getConversion(uint id) public view returns (uint256) {
        return gStableConversionRatioMap[id];
    }

    modifier hasPositiveConversionRatio(uint id) {
        require(gStableConversionRatioMap[id] > 0, "Conversion ratio must be positive");
        _;
    }    

    function setSwapFeesFactor(uint256 fees) public onlyAdmin(msg.sender) {
        swapFeesFactor = fees;
    }

    function setRewardsPercent(uint256 _rewardPC)
        public
        onlyAdmin(msg.sender)
    {
        rewardPC = _rewardPC;
    }

    function deposit(uint id, uint256 _amount) external hasGStableAddress(id) hasPositiveConversionRatio(id) onlyPositive(_amount) {
        require(
            _amount <= stableCoin.balanceOf(msg.sender),
            "amount > stableCoinsbalance"
        );

        stableCoin.transferFrom(msg.sender, address(this), _amount);

        uint256 swapFees = (_amount * swapFeesFactor) / 10000;
        gStableAccumulatedSwapFeesMap[id] += swapFees;

        stableCoin.approve(address(market), _amount * 2);
        market.mint(_amount - swapFees);

        uint256 tokens = ((_amount - swapFees) * gStableConversionRatioMap[id]) / 10000;
        IgStable(gStableAddressMap[id]).mint(msg.sender, tokens);

        emit Deposit(msg.sender, _amount, id);
    }

    function withdraw(uint id, uint256 _tokens) external hasGStableAddress(id) hasPositiveConversionRatio(id) onlyPositive(_tokens) {
        require(
            _tokens <= IgStable(gStableAddressMap[id]).balanceOf(msg.sender),
            "_tokens > gStableCoinsbalance"
        );

        IgStable(gStableAddressMap[id]).burn(msg.sender, _tokens);

        uint256 _amount = (_tokens * 10000) / gStableConversionRatioMap[id];

        market.redeemUnderlying(_amount);

        uint256 swapFees = (_amount * swapFeesFactor) / 10000;
        gStableAccumulatedSwapFeesMap[id] += swapFees;

        stableCoin.transfer(msg.sender, _amount - swapFees);

        emit Withdrawal(msg.sender, _tokens, id);
    }

    function transferRewards(uint id, address vaultAddress)
        external hasGStableAddress(id) hasPositiveConversionRatio(id) onlyAdmin(msg.sender) {
        require(vaultAddress != address(0));

        uint256 swapFeesAsRewards = (gStableAccumulatedSwapFeesMap[id] * rewardPC) / 100;

        // Transfer rewards in gStable to Vault
        uint256 rewardTokens = (swapFeesAsRewards * gStableConversionRatioMap[id]) / 10000;
        IgStable(gStableAddressMap[id]).mint(vaultAddress, rewardTokens);

        // supply accumulateSwapFees to JL and get JL tokens
        stableCoin.approve(address(market), gStableAccumulatedSwapFeesMap[id] * 2);
        market.mint(gStableAccumulatedSwapFeesMap[id]);

        //reset accumulatedSwapFees
        gStableAccumulatedSwapFeesMap[id] = 0;
    }
}
