// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./gStable.sol";
import "./gStableManager.sol";
import "./goStableBase.sol";
import "./Rewards.sol";

/**
 * @title gStableSwapLP
 * @dev This contract facilitates swapping gStable tokens, manages fees and reserves, and interacts with JustLend USDD Market.
 */
contract gStableSwapLP is goStableBase, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    mapping (uint => uint256) public gStableAccumulatedSwapFeesMap;
    mapping (uint => uint256) public gStableSwapFeesFactorMap;
    mapping (uint => uint256) public gStableUnderlyingCollateralMap;
    mapping (uint => uint256) public gStableCollateralReserveMap;
    mapping (uint => uint256) public gStableReservePCMap;
    mapping (uint => address) public gStableReserveAddressMap;

    uint256 public rewardPC = 40; // Default is 40%

    IRewards rewards;
    IgStableManager gStableLookup;
    
    
    event Deposit(address depositor, uint256 amount, uint gStableId);
    event Redeemed(address withdrawer, uint256 _tokens, uint gStableId);
    event ReserveAdded(uint256 id, uint256 amount);
    event ReserveRemoved(uint256 id, uint256 amount);

    constructor(
        address stableCoinAddress,
        address marketAddress,
        address rewardsAddress_,
        address gStableLookupAddress_
    ) goStableBase(stableCoinAddress, marketAddress) {
        rewards = IRewards(rewardsAddress_);
        gStableLookup = IgStableManager(gStableLookupAddress_);
    }

    function pause() public onlyAdmin(msg.sender) {
        _pause();
    }

    function unpause() public onlyAdmin(msg.sender) {
        _unpause();
    }   
    
    function setRewardsAddress(address addr) public onlyAdmin(msg.sender) {
        rewards = IRewards(addr);
    }
    function setGStableLookup(address addr) public onlyAdmin(msg.sender) {
        gStableLookup = IgStableManager(addr);
    }         

    modifier hasGStableAddress(uint id) {
        require(gStableLookup.getGStableAddress(id) != address(0), "No gStable exists");
        _;
    }
    
    modifier isGStable(uint id) {
        require(!gStableLookup.isStableCoin(id), "stable coins not allowed");
        _;
    }        

    modifier hasPositiveConversionRatio(uint id) {
        require(gStableLookup.getConversion(id) > 0, "Conversion ratio must be positive");
        _;
    }    

    function setSwapFeesFactor(uint256 id, uint256 newSwapFeesFactor) public onlyAdmin(msg.sender) {
        gStableSwapFeesFactorMap[id] = newSwapFeesFactor;
    }

    function setRewardsPercent(uint256 _rewardPC) public onlyAdmin(msg.sender) {
        rewardPC = _rewardPC;
    }

    function setReserveFeesFactor(uint id, uint256 _reservePC) public onlyAdmin(msg.sender) {
        gStableReservePCMap[id] = _reservePC;
    }

    function setReserveAddress(uint256 id, address _address) public onlyAdmin(msg.sender) {
        require(_address != address(0), "must be valid address");
        gStableReserveAddressMap[id] = _address;
    }

    /**
     * @dev Mints gStable tokens in exchange for USDD.
     * @param id The ID of the gStable token.
     * @param _amount The amount of USDD to be swapped for gStable tokens.
     */
    function deposit(uint id, uint256 _amount) external hasGStableAddress(id) isGStable(id) hasPositiveConversionRatio(id) onlyPositive(_amount) whenNotPaused nonReentrant {
        require(
            _amount <= stableCoin.balanceOf(msg.sender),
            "amount > stableCoinsbalance"
        );

        // Calculate swap and reserve fees
        uint256 swapFees = _amount.mul(gStableSwapFeesFactorMap[id]).div(10000);
        uint256 reserveFees = _amount.mul(gStableReservePCMap[id]).div(10000);

        //Update mappings
        gStableAccumulatedSwapFeesMap[id] = gStableAccumulatedSwapFeesMap[id].add(swapFees);
        gStableUnderlyingCollateralMap[id] = gStableUnderlyingCollateralMap[id].add(_amount).sub(swapFees);
        gStableCollateralReserveMap[id] = gStableCollateralReserveMap[id].add(reserveFees);

        stableCoin.transferFrom(msg.sender, address(this), _amount);

        // Supply to JL Market
        stableCoin.approve(address(market), _amount.mul(2));
        market.mint(_amount.sub(swapFees));

        //Subtract swapfees and reservefees from amount before minting gStables at conversion rate
        uint256 tokens =  (_amount.sub(swapFees.add(reserveFees)).mul(gStableLookup.getConversion(id))).div(10000);
        IgStable(gStableLookup.getGStableAddress(id)).mint(msg.sender, tokens);

        emit Deposit(msg.sender, tokens, id);
        emit ReserveAdded(id, reserveFees);
    }

    /**
     * @dev Redeems gStable tokens for USDD. gStables are burned upon successful redemption.
     * @param id The ID of the gStable token.
     * @param _tokens The amount of gStable tokens to be redeemed/burned.
     */
    function redeem(uint id, uint256 _tokens) external hasGStableAddress(id) isGStable(id) hasPositiveConversionRatio(id) onlyPositive(_tokens) whenNotPaused nonReentrant {
        address gStableAddress = gStableLookup.getGStableAddress(id);
        IgStable gStable_ = IgStable(gStableAddress);
        require(
            _tokens <= gStable_.balanceOf(msg.sender),
            "_tokens > gStableCoinsbalance"
        );

        // Calculate amount using conversion rate along with swap fees
        uint256 _amount = _tokens.mul(10000).div(gStableLookup.getConversion(id));  
        uint256 swapFees = _amount.mul(gStableSwapFeesFactorMap[id]).div(10000);

        // Update mappings
        gStableAccumulatedSwapFeesMap[id] = gStableAccumulatedSwapFeesMap[id].add(swapFees);
        gStableUnderlyingCollateralMap[id] = gStableUnderlyingCollateralMap[id].sub(_amount);

        // Burn gStables, redeem from  JL Market and transfer to user
        gStable_.burn(msg.sender, _tokens); 
        market.redeemUnderlying(_amount);
        stableCoin.transfer(msg.sender, _amount.sub(swapFees));

        emit Redeemed(msg.sender, _tokens, id);
    }

    /**
     * @dev Adds USDD to the reserve, increasing underlying collateral and reserve amounts.
     * @param id The ID of the gStable token.
     * @param _amount The amount of USDD to be added to the reserve.
     */
    function addToReserve( uint id, uint256 _amount) external hasGStableAddress(id) onlyPositive(_amount) nonReentrant onlyAdmin(msg.sender) {
        // Update mappings
        gStableUnderlyingCollateralMap[id] = gStableUnderlyingCollateralMap[id].add(_amount);
        gStableCollateralReserveMap[id] = gStableCollateralReserveMap[id].add(_amount);

        // Supply to JL Market
        stableCoin.transferFrom(msg.sender, address(this), _amount);
        stableCoin.approve(address(market), _amount.mul(2));
        market.mint(_amount);

        emit ReserveAdded(id, _amount);
    }


    /**
     * @dev Removes USDD from the reserve, decreasing underlying collateral and reserve amounts.
     * @param id The ID of the gStable token.
     * @param _amount The amount of USDD to be removed from the reserve.
     */
    function removeFromReserve( uint id, uint256 _amount) external hasGStableAddress(id) onlyPositive(_amount) nonReentrant onlyAdmin(msg.sender) {
        require(_amount <= gStableCollateralReserveMap[id], "_amount > gStableCollateralReserve");

        // Update mappings
        gStableCollateralReserveMap[id] = gStableCollateralReserveMap[id].sub(_amount);
        gStableUnderlyingCollateralMap[id] = gStableUnderlyingCollateralMap[id].sub(_amount);

        // Redeem from JL Market and transfer to external reserve address
        market.redeemUnderlying(_amount);
        stableCoin.transfer(gStableReserveAddressMap[id], _amount); 

        emit ReserveRemoved(id, _amount);
    }


    /**
     * @dev Claims yield rewards from JL USDD Market when available
     */
    function claim(uint256 merkleIndex, uint256 index, uint256 amount, bytes32[] calldata merkleProof) public onlyAdmin(msg.sender) {
        rewards.claim(merkleIndex, index, amount, merkleProof);
    } 

    /**
     * @dev Transfers gStable rewards from accumulated swap fees to the Vault for distribution
     * @param id The ID of the gStable token.
     * @param vaultAddress The vault address.
     */
    function transferRewards(uint id, address vaultAddress) external hasGStableAddress(id) hasPositiveConversionRatio(id) onlyAdmin(msg.sender) {

        address gStableAddress = gStableLookup.getGStableAddress(id);
        IgStable gStable_ = IgStable(gStableAddress); 

        require(vaultAddress != address(0));

        uint256 swapFeesAsRewards = gStableAccumulatedSwapFeesMap[id].mul(rewardPC).div(100);

        // Transfer rewards in gStable to Vault
        uint256 rewardTokens = swapFeesAsRewards.mul(gStableLookup.getConversion(id)).div(10000);
        gStable_.mint(vaultAddress, rewardTokens);

        // supply accumulateSwapFees to JL and get JL tokens
        stableCoin.approve(address(market), gStableAccumulatedSwapFeesMap[id].mul(2));
        market.mint(gStableAccumulatedSwapFeesMap[id]);

        //reset accumulatedSwapFees
        gStableAccumulatedSwapFeesMap[id] = 0;
    }


}


interface ISwapStableCoin {

    function addToReserve( uint id, uint256 _amount) external;

    function removeFromReserve( uint id, uint256 _amount) external;
 
}

