// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../AdminAuth.sol";
import "../gStable.sol";
import "../Rewards.sol";
import "../BankDepository.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ConvertComptroller is AdminAuth, Pausable, ReentrancyGuard {
    using ECDSA for bytes32;

    event SubmitTransaction(
        address hodler,
        uint fromId,
        uint fromTokens,
        uint toId,
        uint nonce
    );    

    struct Transaction {
        address hodler;
        uint fromId;
        uint fromTokens;
        uint toId;
        uint nonce;
        uint initiatedTime;
        uint executedTime;
    }

    Transaction[] public transactions;

    IBankDepository bank;

    //1 : initiated, 2 : cancelled by user, 3 : Executed Success, 4x. Executed Fail 41. fromId is stableCoin 42. toId is stableCoin 43. gstables balance is not available
    mapping(bytes32 => uint) public executed;

    mapping(bytes32 => Transaction) public hashTrxMapping;
    mapping(address => Transaction[]) public userTrxMapping;


    constructor(address depositoryAddress) {
        bank = IBankDepository(depositoryAddress);
    }

    modifier onlyPositive(uint256 val) {
        require(val > 0, "<0");
        _;
    }    

    function pause() public onlyAdmin(msg.sender) {
        _pause();
    }

    function unpause() public onlyAdmin(msg.sender) {
        _unpause();
    }

    function setBankDepository(address addr) public onlyAdmin(msg.sender) {
        bank = IBankDepository(addr);
    }

    function initiateTransaction(
        address _hodler,
        uint _fromId,
        uint _fromTokens,
        uint _toId
    ) public onlyAdmin(msg.sender) returns(uint) {

        uint nonce_ = transactions.length;

        bytes32 txHash = getTxHash(_hodler, _fromId, _fromTokens, _toId, nonce_);
        require(executed[txHash] < 1, "tx already exists");
        
        Transaction memory txn = Transaction({hodler:_hodler, fromId:_fromId, fromTokens:_fromTokens, toId:_toId, nonce:nonce_, initiatedTime: block.timestamp, executedTime: 0});

        executed[txHash] = 1;   

        hashTrxMapping[txHash] = txn;
        userTrxMapping[_hodler].push(txn);
        transactions.push(txn);

        emit SubmitTransaction(_hodler, _fromId, _fromTokens, _toId, nonce_);

        return nonce_;
    }
    
    function executeTransaction(
        address _hodler,
        uint _fromId,
        uint _fromTokens,
        uint _toId,
        uint nonce_,
        bytes memory _sig
    ) external onlyAdmin(msg.sender) {
        
        bytes32 txHash = getTxHash(_hodler, _fromId, _fromTokens, _toId, nonce_);
        
        require(executed[txHash] < 2, "tx executed");
        require(_checkSigs(_sig, txHash), "invalid sig");
        
        Transaction memory txn = hashTrxMapping[txHash];

        executed[txHash] = bank.exchangeGL(txn.hodler, txn.fromId, txn.fromTokens, txn.toId);

        txn.executedTime = block.timestamp;

    }       

    function getTxHash(
        address _hodler,
        uint _fromId,
        uint _fromTokens,
        uint _toId,
        uint _nonce
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), _hodler, _fromId, _fromTokens, _toId, _nonce));
    }

    function _checkSigs(
        bytes memory _sig,
        bytes32 _txHash
    ) private view returns (bool) {
        bytes32 ethSignedHash = _txHash.toEthSignedMessageHash();

        address signer = ethSignedHash.recover(_sig);
        
        return signer == hashTrxMapping[_txHash].hodler;
    }    
}
