// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./gStable.sol";
import "./AdminAuth.sol";
import "./SwapStableCoin.sol";

contract SwapGStable is AdminAuth {
    ISwapStableCoin swapStable;
    IgStableManager gStableLookup;

    event Swap(address hodler, uint fromId, uint fromTokens, uint toId, uint toTokens);

    constructor(address swapStableCoinAddress_, address gStableLookupAddress_){
        swapStable = ISwapStableCoin(swapStableCoinAddress_);
        gStableLookup = IgStableManager(gStableLookupAddress_);
    }

    modifier onlyPositive(uint256 val) {
        require(val > 0, "<0");
        _;
    }    
    
    function setSwapStable(address addr) public onlyAdmin(msg.sender) {
        swapStable = ISwapStableCoin(addr);
    }   
    function setGStableLookup(address addr) public onlyAdmin(msg.sender) {
        gStableLookup = IgStableManager(addr);
    }       

    function swap(uint fromId, uint256 fromTokens, uint toId) external  onlyPositive(fromTokens) {
        address gStableAddress = gStableLookup.getGStableAddress(fromId);
        IgStable gStable_ = IgStable(gStableAddress);        

        require(
            fromTokens <= gStable_.balanceOf(msg.sender),
            "fromTokens > gStableCoinsbalance"
        );

        uint256 _amount = (fromTokens * 10000) / gStableLookup.getConversion(fromId);

        uint256 swapFees = (_amount * swapStable.getSwapFeesFactor(toId)) / 10000;

        uint256 toTokens = ((_amount-swapFees) * gStableLookup.getConversion(toId)) / 10000;

        swapStable.addSwapFees(fromId, swapFees);

        gStableLookup.burn(msg.sender, fromId, fromTokens);

        gStableLookup.mint(msg.sender, toId, toTokens);
        
        emit Swap(msg.sender, fromId, fromTokens, toId, toTokens);
    }
}    
