// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./JLMarket.sol";
import "./gStable.sol";
import "./AdminAuth.sol";

contract goStableBase is AdminAuth {
    IJLMarket market;
    IERC20 stableCoin;
    
    uint256 public treasuryStableCoinValue = 0;

    constructor(
        address stableCoinAddress,
        address marketAddress
    ) {
        stableCoin = IERC20(stableCoinAddress);
        market = IJLMarket(marketAddress);
        stableCoin.approve(marketAddress, 1000);
    }

    function getMarketAddress() public view returns (address) {
        return address(market);
    }

    function getStableCoinAddress() public view returns (address) {
        return address(stableCoin);
    }

    function setMarket(address marketAddress) public onlyAdmin(msg.sender) {
        market = IJLMarket(marketAddress);
        stableCoin.approve(marketAddress, 1000);
    }

    function setStableCoin(address stableCoinAddress)
        public
        onlyAdmin(msg.sender)
    {
        stableCoin = IERC20(stableCoinAddress);
    }

    modifier onlyPositive(uint256 val) {
        require(val > 0, "<0");
        _;
    }

    function investIntoTreasury(uint256 amount)
        external
        onlyAdmin(msg.sender)
    {
        require(
            amount <= stableCoin.balanceOf(address(this)),
            "amount > stableCoinBalance"
        );

        stableCoin.approve(address(market), amount * 2);
        market.mint(amount);

        treasuryStableCoinValue += amount;
    }

    function withdrawFromTreasury(uint256 amount)
        external
        onlyAdmin(msg.sender)
    {
        require(
            amount <= treasuryStableCoinValue,
            "amount > treasuryStableCoinValue"
        );
        market.redeemUnderlying(amount);
        stableCoin.transfer(msg.sender, amount);

        treasuryStableCoinValue -= amount;
    }
}
