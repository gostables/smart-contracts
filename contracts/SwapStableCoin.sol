// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./gStable.sol";
import "./gStableManager.sol";
import "./goStableBase.sol";
import "./Rewards.sol";

contract SwapStableCoin is goStableBase, Pausable, ReentrancyGuard {
    mapping (uint => uint256) public gStableAccumulatedSwapFeesMap;
    mapping (uint => uint256) public gStableSwapFeesFactorMap;
    mapping (uint => uint256) public gStableUnderlyingCollateralMap;

    uint256 public rewardPC = 40;


    IRewards rewards;
    IgStableManager gStableLookup;

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

    function getSwapFeesFactor(uint id) external view returns (uint256) {
        return (gStableSwapFeesFactorMap[id]);
    }     

    function setRewardsPercent(uint256 _rewardPC) public onlyAdmin(msg.sender) {
        rewardPC = _rewardPC;
    }

    function deposit(uint id, uint256 _amount) external hasGStableAddress(id) isGStable(id) hasPositiveConversionRatio(id) onlyPositive(_amount) whenNotPaused nonReentrant {
        require(
            _amount <= stableCoin.balanceOf(msg.sender),
            "amount > stableCoinsbalance"
        );

        uint256 swapFees = (_amount * gStableSwapFeesFactorMap[id]) / 10000;
        gStableAccumulatedSwapFeesMap[id] += swapFees;
        gStableUnderlyingCollateralMap[id] += _amount;

        stableCoin.transferFrom(msg.sender, address(this), _amount);

        stableCoin.approve(address(market), _amount * 2);
        market.mint(_amount - swapFees);

        uint256 tokens = ((_amount - swapFees) * gStableLookup.getConversion(id)) / 10000;
        IgStable(gStableLookup.getGStableAddress(id)).mint(msg.sender, tokens);

        emit Deposit(msg.sender, _amount, id);
    }

    function withdraw(uint id, uint256 _tokens) external hasGStableAddress(id) isGStable(id) hasPositiveConversionRatio(id) onlyPositive(_tokens) whenNotPaused nonReentrant {
        address gStableAddress = gStableLookup.getGStableAddress(id);
        IgStable gStable_ = IgStable(gStableAddress);
        require(
            _tokens <= gStable_.balanceOf(msg.sender),
            "_tokens > gStableCoinsbalance"
        );
        
        uint256 _amount = (_tokens * 10000) / gStableLookup.getConversion(id);
        uint256 swapFees = (_amount * gStableSwapFeesFactorMap[id]) / 10000;
        gStableAccumulatedSwapFeesMap[id] += swapFees;
        gStableUnderlyingCollateralMap[id] -= _amount;

        gStable_.burn(msg.sender, _tokens);
        market.redeemUnderlying(_amount);
        stableCoin.transfer(msg.sender, _amount - swapFees);

        emit Withdrawal(msg.sender, _tokens, id);
    }

    function marketDeposit( uint256 _amount) external onlyPositive(_amount) onlyAdmin(msg.sender) {
        stableCoin.approve(address(market), _amount * 2);
        market.mint(_amount);
    }  

    function marketRedeem( uint256 _amount) external onlyPositive(_amount) onlyAdmin(msg.sender) {
        market.redeemUnderlying(_amount);
    }    

    function addSwapFees( uint id, uint256 _swapFees) external hasGStableAddress(id) onlyPositive(_swapFees) onlyAdmin(msg.sender) {
        gStableAccumulatedSwapFeesMap[id] += _swapFees;
    }

    function claim(uint256 merkleIndex, uint256 index, uint256 amount, bytes32[] calldata merkleProof) public onlyAdmin(msg.sender) {
        rewards.claim(merkleIndex, index, amount, merkleProof);
    } 

    function transferRewards(uint id, address vaultAddress)
        external hasGStableAddress(id) hasPositiveConversionRatio(id) onlyAdmin(msg.sender) {

        address gStableAddress = gStableLookup.getGStableAddress(id);
        IgStable gStable_ = IgStable(gStableAddress); 

        require(vaultAddress != address(0));

        uint256 swapFeesAsRewards = (gStableAccumulatedSwapFeesMap[id] * rewardPC) / 100;

        // Transfer rewards in gStable to Vault
        uint256 rewardTokens = (swapFeesAsRewards * gStableLookup.getConversion(id)) / 10000;
        gStable_.mint(vaultAddress, rewardTokens);

        // supply accumulateSwapFees to JL and get JL tokens
        stableCoin.approve(address(market), gStableAccumulatedSwapFeesMap[id] * 2);
        market.mint(gStableAccumulatedSwapFeesMap[id]);

        //reset accumulatedSwapFees
        gStableAccumulatedSwapFeesMap[id] = 0;
    }

}


interface ISwapStableCoin {

    function getSwapFeesFactor(uint id) external returns (uint256);

    function marketDeposit( uint256 _amount) external;

    function marketRedeem( uint256 _amount) external;

    function addSwapFees( uint id, uint256 _swapFees) external;    
}

