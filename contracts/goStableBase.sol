// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./JLMarket.sol";
import "./gStable.sol";
import "./ClientAuth.sol";

contract goStableBase is ClientAuth {
    IJLMarket market;
    IERC20 stableCoin;
    IgStable gStableCoin;
    uint256 public treasuryStableCoinValue = 0;

    constructor(
        address stableCoinAddress,
        address marketAddress,
        address gStableAddress
    ) {
        stableCoin = IERC20(stableCoinAddress);
        market = IJLMarket(marketAddress);
        stableCoin.approve(marketAddress, 1000);
        gStableCoin = IgStable(gStableAddress);
    }

    function getMarketAddress() public view returns (address) {
        return address(market);
    }

    function getgStableCoinAddress() public view returns (address) {
        return address(gStableCoin);
    }

    function getStableCoinAddress() public view returns (address) {
        return address(stableCoin);
    }

    function setMarket(address marketAddress) public onlyClients(msg.sender) {
        market = IJLMarket(marketAddress);
        stableCoin.approve(marketAddress, 1000);
    }

    function setStableCoin(address stableCoinAddress)
        public
        onlyClients(msg.sender)
    {
        stableCoin = IERC20(stableCoinAddress);
    }

    function setgStable(address gStableAddress) public onlyClients(msg.sender) {
        gStableCoin = IgStable(gStableAddress);
    }

    modifier onlyPositive(uint256 val) {
        require(val > 0, "<0");
        _;
    }

    function investIntoTreasury(uint256 amount)
        external
        onlyClients(msg.sender)
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
        onlyClients(msg.sender)
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
