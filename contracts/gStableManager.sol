// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./gStable.sol";
import "./Rewards.sol";

contract gStableManager is AdminAuth {
    address[] gStables;
    mapping(address => bool) gStableExists;
    mapping (uint => address) public gStableAddressMap;
    
    mapping (uint => bool) public isStableCoin_;

    mapping (uint => uint256) public gStableConversionRatioMap;
    mapping(uint => address) public gStableMarketMap;

    address defaultMarketAddress;

    constructor(address defaultMarketAddress_) {
        defaultMarketAddress = defaultMarketAddress_;
    }

    function setGStableAddress(uint id, address addr) public onlyAdmin(msg.sender) {
        gStableAddressMap[id] = addr;
    }

    function removeGStable(uint256 index) public onlyAdmin(msg.sender) {
        require(index < gStables.length, "index !< length");
        gStableExists[gStables[index]] = false;

        for (uint256 i = index; i < gStables.length - 1; i++) {
            gStables[i] = gStables[i + 1];
        }
        gStables.pop();
    }    

    function getGStableAddress(uint id) external view returns (address) {
        return gStableAddressMap[id];
    }

    modifier hasGStableAddress(uint id) {
        require(gStableAddressMap[id] != address(0), "No gStable exists");
        _;
    }    

    function setConversion( uint id, uint256 ratio) public onlyAdmin(msg.sender) {
        gStableConversionRatioMap[id] = ratio;
    }

    function getConversion(uint id) external view returns (uint256) {
        return (gStableConversionRatioMap[id]);
    }

    function setAsStableCoin( uint id, bool stableCoinStatus) public onlyAdmin(msg.sender) {
        isStableCoin_[id] = stableCoinStatus;
    }

    function isStableCoin( uint id) external view returns(bool)  {
        return isStableCoin_[id];
    }

    function setGStableMarketAddress(uint id, address addr) public onlyAdmin(msg.sender) {
        gStableMarketMap[id] = addr;
    }
    
    function getGStableMarketAddress(uint id) external view returns (address) {
        if(gStableMarketMap[id] !=  address(0)){
            return gStableMarketMap[id];
        }
        return defaultMarketAddress;
    }

    modifier onlyPositive(uint256 val) {
        require(val > 0, "<0");
        _;
    }    

    function mint( address hodler, uint id, uint256 _tokens) external hasGStableAddress(id) onlyPositive(_tokens) onlyAdmin(msg.sender) {
        address gStableAddress = gStableAddressMap[id];
        IgStable gStable_ = IgStable(gStableAddress);        
        gStable_.mint(hodler, _tokens);
    }  

    function burn( address hodler, uint id, uint256 _tokens) external hasGStableAddress(id) onlyPositive(_tokens) onlyAdmin(msg.sender) {
        address gStableAddress = gStableAddressMap[id];
        IgStable gStable_ = IgStable(gStableAddress);         
        require(
            _tokens <= gStable_.balanceOf(hodler),
            "_tokens > gStableCoinsbalance"
        );
        gStable_.burn(hodler, _tokens);
    }    
  
}

interface IgStableManager {

    function getGStableAddress(uint id) external returns (address);

    function getConversion(uint id) external returns (uint256);
    
    function isStableCoin( uint id) external returns(bool);

    function getGStableMarketAddress(uint id) external returns (address);

    function mint( address hodler, uint id, uint256 _tokens) external; 

    function burn( address hodler, uint id, uint256 _tokens) external;

}