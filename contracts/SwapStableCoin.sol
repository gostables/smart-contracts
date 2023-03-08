// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./gStable.sol";
import "./goStableBase.sol";
import "./Rewards.sol";

contract SwapStableCoin is goStableBase, Pausable, ReentrancyGuard {
    mapping (uint => address) public gStableAddressMap;
    mapping (uint => uint256) public gStableConversionRatioMap;
    mapping (uint => uint256) public gStableAccumulatedSwapFeesMap;
    mapping (uint => uint256) public gStableSwapFeesFactorMap;
    mapping (uint => uint256) public gStableUnderlyingCollateralMap;

    uint256 public rewardPC = 40;

    address public rewardsAddress; 

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
        address rewardsAddress_ 
    ) goStableBase(stableCoinAddress, marketAddress) {
        rewardsAddress = rewardsAddress_;
    }

    function pause() public onlyAdmin(msg.sender) {
        _pause();
    }

    function unpause() public onlyAdmin(msg.sender) {
        _unpause();
    }   
    
    function setRewardsAddress(address addr) public onlyAdmin(msg.sender) {
        rewardsAddress = addr;
    }     

    function setGStableAddress(uint id, address addr) public onlyAdmin(msg.sender) {
        gStableAddressMap[id] = addr;
        gStableSwapFeesFactorMap[id] = 30;
    }

    modifier hasGStableAddress(uint id) {
        require(gStableAddressMap[id] != address(0), "No gStable exists for this ID");
        _;
    }    

    function setConversion( uint id, uint256 ratio) public onlyAdmin(msg.sender) {
        gStableConversionRatioMap[id] = ratio;
    }

    function getConversion(uint id) external view returns (uint256) {
        return (gStableConversionRatioMap[id]);
    }    

    modifier hasPositiveConversionRatio(uint id) {
        require(gStableConversionRatioMap[id] > 0, "Conversion ratio must be positive");
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

    function deposit(uint id, uint256 _amount) external hasGStableAddress(id) hasPositiveConversionRatio(id) onlyPositive(_amount) whenNotPaused nonReentrant {
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

        uint256 tokens = ((_amount - swapFees) * gStableConversionRatioMap[id]) / 10000;
        IgStable(gStableAddressMap[id]).mint(msg.sender, tokens);

        

        emit Deposit(msg.sender, _amount, id);
    }

    function withdraw(uint id, uint256 _tokens) external hasGStableAddress(id) hasPositiveConversionRatio(id) onlyPositive(_tokens) whenNotPaused nonReentrant {
        require(
            _tokens <= IgStable(gStableAddressMap[id]).balanceOf(msg.sender),
            "_tokens > gStableCoinsbalance"
        );
        
        uint256 _amount = (_tokens * 10000) / gStableConversionRatioMap[id];
        uint256 swapFees = (_amount * gStableSwapFeesFactorMap[id]) / 10000;
        gStableAccumulatedSwapFeesMap[id] += swapFees;
        gStableUnderlyingCollateralMap[id] -= _amount;

        IgStable(gStableAddressMap[id]).burn(msg.sender, _tokens);
        market.redeemUnderlying(_amount);
        stableCoin.transfer(msg.sender, _amount - swapFees);

        emit Withdrawal(msg.sender, _tokens, id);
    }

    function mint( address hodler, uint id, uint256 _tokens) external hasGStableAddress(id) onlyPositive(_tokens) onlyAdmin(msg.sender) {
        IgStable(gStableAddressMap[id]).mint(hodler, _tokens);
    }  

    function burn( address hodler, uint id, uint256 _tokens) external hasGStableAddress(id) onlyPositive(_tokens) onlyAdmin(msg.sender) {
        require(
            _tokens <= IgStable(gStableAddressMap[id]).balanceOf(hodler),
            "_tokens > gStableCoinsbalance"
        );
        IgStable(gStableAddressMap[id]).burn(hodler, _tokens);
    }

    function marketDeposit( uint256 _amount) external onlyPositive(_amount) onlyAdmin(msg.sender) {
        stableCoin.approve(address(market), _amount * 2);
        market.mint(_amount);
    }  

    function marketRedeem( uint256 _amount) external onlyPositive(_amount) onlyAdmin(msg.sender) {
        market.redeemUnderlying(_amount);
    }    

    function addSwapFees( address hodler, uint id, uint256 _swapFees) external hasGStableAddress(id) onlyPositive(_swapFees) onlyAdmin(msg.sender) {
        require(
            _swapFees <= stableCoin.balanceOf(hodler),
            "swapFees > stableCoinsbalance"
        );
        
        stableCoin.transferFrom(hodler, address(this), _swapFees);

        gStableAccumulatedSwapFeesMap[id] += _swapFees;
    }   

    function claim(uint256 merkleIndex, uint256 index, uint256 amount, bytes32[] calldata merkleProof) public onlyAdmin(msg.sender) {
        IRewards(rewardsAddress).claim(merkleIndex, index, amount, merkleProof);
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


interface ISwapStableCoin {

    function getConversion(uint id) external returns (uint256);

    function getSwapFeesFactor(uint id) external returns (uint256);

    function mint( address hodler, uint id, uint256 _tokens) external;

    function burn( address hodler, uint id, uint256 _tokens) external;

    function marketDeposit( uint256 _amount) external;

    function marketRedeem( uint256 _amount) external;

    function addSwapFees( address hodler, uint id, uint256 _swapFees) external;    
}

