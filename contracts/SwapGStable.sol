// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./gStable.sol";
import "./AdminAuth.sol";
import "./SwapStableCoin.sol";

contract SwapGStable is AdminAuth {
    address public swapStableCoinAddress;

    event Swap(address hodler, uint fromId, uint fromTokens, uint toId, uint toTokens);

    constructor(address swapStableCoinAddress_){
        swapStableCoinAddress = swapStableCoinAddress_;
    }

    modifier onlyPositive(uint256 val) {
        require(val > 0, "<0");
        _;
    }    
    
    function setSwapStableCoinAddress(address addr) public onlyAdmin(msg.sender) {
        swapStableCoinAddress = addr;
    }     

    function swap(uint fromId, uint256 fromTokens, uint toId) external  onlyPositive(fromTokens) {

        ISwapStableCoin swapStable = ISwapStableCoin(swapStableCoinAddress);

        uint256 _amount = (fromTokens * 10000) / swapStable.getConversion(fromId);
        uint256 toTokens = (_amount * swapStable.getConversion(toId)) / 10000;
        uint256 swapFees = (_amount * swapStable.getSwapFeesFactor(toId)) / 10000;

        swapStable.addSwapFees(msg.sender, toId, swapFees);

        swapStable.burn(msg.sender, fromId, fromTokens);

        swapStable.mint(msg.sender, toId, toTokens);
        
        emit Swap(msg.sender, fromId, fromTokens, toId, toTokens);
    }

    function marketDeposit( uint256 _amount) external onlyPositive(_amount) {
        ISwapStableCoin swapStable = ISwapStableCoin(swapStableCoinAddress);
        swapStable.marketDeposit(_amount);
    }  

    function marketRedeem( uint256 _amount) external onlyPositive(_amount) onlyAdmin(msg.sender) {
        ISwapStableCoin swapStable = ISwapStableCoin(swapStableCoinAddress);
        swapStable.marketRedeem(_amount);
    }     

}    
