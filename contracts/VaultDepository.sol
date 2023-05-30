// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./BankDepository.sol";
import "./gStableManager.sol";
import "./AdminAuth.sol";
import "./gStable.sol";


contract VaultDepository is AdminAuth, Pausable, ReentrancyGuard {
    uint256 public basisPointCredit;
    uint256 public maxTransferPercent;

    mapping (uint => uint256) public gStableIntervalMap;
    mapping(address => mapping(uint => uint256)) public vaultBalances;
    mapping(uint => mapping(address => uint256)) public gStableLockPeriodMap;
    mapping(address => mapping(uint => uint256)) public transferableBalances;


    event Deposit(address depositor, uint256 amount, uint gStableId);
    event Mint(address depositor, uint256 amount, uint gStableId);
    event Redeem(address redeemer, uint256 amount, uint gStableId);
    event Transfer(address indexed from, address indexed to, uint256 amount, uint256 gStableId);



    IBankDepository bankDepositoryAddress;
    IgStableManager gStableLookup;

    constructor(address bankDepositoryAddress_, uint256 basisPointCredit_, address gStableLookupAddress_) {
        bankDepositoryAddress = IBankDepository(bankDepositoryAddress_);
        basisPointCredit = basisPointCredit_;
        gStableLookup = IgStableManager(gStableLookupAddress_);
    }

    modifier onlyPositive(uint256 val) {
        require(val > 0, "<0");
        _;
    }    

    modifier isGStable(uint256 id) {
        require(!gStableLookup.isStableCoin(id), "is stable coin");
        _;
    }  

    modifier hasGStableAddress(uint id) {
        require(gStableLookup.getGStableAddress(id) != address(0), "No gStable exists for this ID");
        _;
    }

    function pause() public onlyAdmin(msg.sender) {
        _pause();
    }

    function unpause() public onlyAdmin(msg.sender) {
        _unpause();
    }

    function setBankDepositoryAddress(address bankDepositoryAddress_)  public onlyAdmin(msg.sender) {
        bankDepositoryAddress = IBankDepository(bankDepositoryAddress_);
    }

    function setbasisPointCredit(uint256 basisPointCredit_)  public onlyAdmin(msg.sender) {
        basisPointCredit = basisPointCredit_;
    }

    function setGStableLookup(address addr) public onlyAdmin(msg.sender) {
        gStableLookup = IgStableManager(addr);
    }  

    function setLockInterval(uint id, uint256 freezePeriod_)  public onlyAdmin(msg.sender) {
        gStableIntervalMap[id] = freezePeriod_;
    }

    function setMaxTransferPercent(uint256 maxTransferPercent_) public onlyAdmin(msg.sender) {
        require(maxTransferPercent <= 100, "Invalid percentage");
        maxTransferPercent = maxTransferPercent_;
    }

    function transferDeposit(uint gStableId, uint256 _tokens) external hasGStableAddress(gStableId) onlyPositive(_tokens) isGStable(gStableId) whenNotPaused nonReentrant {
    IBankDepository bankDepository = IBankDepository(bankDepositoryAddress);

    // Calculate transferable amount based on deposited balance and percentage
    uint256 transferableAmount = (_tokens * maxTransferPercent) / 100;

    // Move gStables from user's account to the vault
    uint result = bankDepository.moveGL(msg.sender, address(this), gStableId, _tokens);
    require(result == 4, "Deposit failed");

    // Update vault balances
    vaultBalances[msg.sender][gStableId] += _tokens;

    // Lock deposit
    gStableLockPeriodMap[gStableId][msg.sender] = block.timestamp + (gStableIntervalMap[gStableId] * 1 minutes);

    // Update transferable balance
    transferableBalances[msg.sender][gStableId] += transferableAmount;

    // Calculate credit limit amount based on the deposited amount
    uint256 creditLimit = (_tokens * basisPointCredit) / (100 * 100);

    // Mint credit limit directly to user
    gStableLookup.mint(msg.sender, gStableId, creditLimit);

    emit Deposit(msg.sender, _tokens, gStableId);
    emit Mint(msg.sender, creditLimit, gStableId);
    }



    function redeem(uint gStableId, uint256 amount) external isGStable(gStableId) onlyPositive(amount) {
        IBankDepository bankDepository = IBankDepository(bankDepositoryAddress);
        require(amount <= vaultBalances[msg.sender][gStableId], "Insufficient balance");
        require(block.timestamp > gStableLockPeriodMap[gStableId][msg.sender], "< period");

        // Move gStables from the vault to the user's account in bankDepository contract
        uint redeemResult = bankDepository.moveGL(address(this), msg.sender, gStableId, amount);
        require(redeemResult == 4, "Redemption failed");

        // Update vault balances
        vaultBalances[msg.sender][gStableId] -= amount;

        emit Redeem(msg.sender, amount, gStableId);
    }

    function transferBalance(uint gStableId, address recipient, uint256 amount) external isGStable(gStableId) onlyPositive(amount) whenNotPaused nonReentrant {
        require(amount <= transferableBalances[msg.sender][gStableId], "Insufficient transferable balance");

        // Update sender's transferable balance
        transferableBalances[msg.sender][gStableId] -= amount;

        // Update recipient's balances
        transferableBalances[recipient][gStableId] += amount;
        vaultBalances[recipient][gStableId] += amount;

        emit Transfer(msg.sender, recipient, amount, gStableId);
    }

}
