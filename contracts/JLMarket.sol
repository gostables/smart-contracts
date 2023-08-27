// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract JLMarket is ERC20 {
    IERC20 underlyingAsset;

    uint256 supplyRate = 2;

    uint256 conversionRatio = 99;

    constructor(
        address _underlyingAssetAddress,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        underlyingAsset = IERC20(_underlyingAssetAddress);
    }

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint256 mintAmount) external returns (uint256) {
        underlyingAsset.transferFrom(msg.sender, address(this), mintAmount);
        uint256 tokens = mintAmount * conversionRatio;
        _mint(msg.sender, tokens);
        return 0;
    }

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint256 redeemTokens) external returns (uint256) {
        _burn(msg.sender, redeemTokens);
        uint256 amount = redeemTokens / conversionRatio;
        underlyingAsset.transfer(msg.sender, amount);
        return 0;
    }

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256) {
        uint256 tokens = redeemAmount * conversionRatio;
        _burn(msg.sender, tokens);
        underlyingAsset.transfer(msg.sender, redeemAmount);
        return 0;
    }

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner)
        external
        view
        returns (uint256)
    {
        uint256 balanceTokens = balanceOf(owner);
        uint256 balance = balanceTokens / conversionRatio;
        return balance;
    }



}

interface IJLMarket {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns(uint256);

    function repayBorrow(uint256 amount) external returns(uint256);

    function getAccountSnapshot(address account) external view returns(uint256, uint256, uint256, uint256);

}
