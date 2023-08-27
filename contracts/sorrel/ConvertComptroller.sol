// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../AdminAuth.sol";
import "../gStable.sol";
import "../Rewards.sol";
import "./BankDepository.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ConvertComptroller is AdminAuth, Pausable, ReentrancyGuard {
    using ECDSA for bytes32;

    event ConversionInitiated(
        address hodler,
        uint fromId,
        uint fromTokens,
        uint toId,
        uint nonce
    );

    event ConversionExecuted(
        address hodler,
        uint fromId,
        uint fromTokens,
        uint toId,
        uint nonce
    );        

    event ConversionCancelled(
        address hodler,
        uint fromId,
        uint fromTokens,
        uint toId,
        uint nonce
    );            

    uint nonce; 

    struct Transaction {
        address hodler;
        uint fromId;
        uint fromTokens;
        uint toId;
        uint nonce;
        uint initiatedTime;
        uint executedTime;
        bytes32 txHash;
    }

    IBankDepository bank;

    //1 : initiated, 2 : cancelled by user, 3 : Executed Success, 4x. Executed Fail 41. fromId is stableCoin 42. toId is stableCoin 43. gstables balance is not available
    mapping(bytes32 => uint) public status;

    mapping(bytes32 => Transaction) public hashTxMapping;
    mapping(address => bytes32[]) public userTxHashMapping;


    constructor(address depositoryAddress) {
        bank = IBankDepository(depositoryAddress);
    }

    modifier onlyPositive(uint val) {
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

    function getUserTransactions(address hodler) public view returns(
        uint[] memory idPair,
        uint[] memory fromTokens, 
        uint[] memory timePair, 
        uint[] memory nonceList,
        bytes32[] memory txHash,
        uint[] memory statusList){
        
        bytes32[] memory userTxs = userTxHashMapping[hodler];
        uint pairLength = 2 * userTxs.length;
        
        uint[] memory idPairs = new uint[](pairLength);
        uint[] memory fromTokenss = new uint[](userTxs.length);
        uint[] memory timePairs = new uint[](pairLength);
        uint[] memory nonces = new uint[](userTxs.length);
        bytes32[] memory txHashs = new bytes32[](userTxs.length);
        uint[] memory statuss = new uint[](userTxs.length);
        
        for (uint i = 0; i < userTxs.length; i++) {
            Transaction memory userTx = hashTxMapping[userTxs[i]];
            idPairs[i] = userTx.fromId;
            idPairs[i + userTxs.length] = userTx.toId;
            fromTokenss[i] = userTx.fromTokens;
            timePairs[i] = userTx.initiatedTime;
            timePairs[i + userTxs.length] = userTx.executedTime;
            statuss[i] = status[userTxs[i]];
            txHashs[i] = userTx.txHash;
            nonces[i] = userTx.nonce;
        }
        
        return (idPairs, fromTokenss, timePairs, nonces, txHashs, statuss);
    }

    function getNonce() private returns(uint){
        return nonce++;
    }    

    function initiateTransaction(
        address _hodler,
        uint _fromId,
        uint _fromTokens,
        uint _toId
    ) public onlyAdmin(msg.sender) {

        uint nonce_ = getNonce();

        bytes32 txHash_ = getTxHash(_hodler, _fromId, _fromTokens, _toId, nonce_);
        require(status[txHash_] < 2, "tx already exists");
        
        Transaction memory txn = Transaction({
            hodler:_hodler, 
            fromId:_fromId, 
            fromTokens:_fromTokens, 
            toId:_toId, 
            nonce:nonce_, 
            initiatedTime: block.timestamp, 
            executedTime: 0,
            txHash: txHash_});

        status[txHash_] = 1;   

        hashTxMapping[txHash_] = txn;
        userTxHashMapping[_hodler].push(txHash_);

        emit ConversionInitiated(_hodler, _fromId, _fromTokens, _toId, nonce_);
    }
    
    function executeTransaction(
        address _hodler,
        uint _fromId,
        uint _fromTokens,
        uint _toId,
        uint nonce_
    ) external onlyAdmin(msg.sender) {
        
        bytes32 txHash = getTxHash(_hodler, _fromId, _fromTokens, _toId, nonce_);
        
        require(status[txHash] < 2, "tx executed");
        
        Transaction storage txn = hashTxMapping[txHash];

        status[txHash] = bank.exchangeGL(txn.hodler, txn.fromId, txn.fromTokens, txn.toId);

        txn.executedTime = block.timestamp;

        emit ConversionExecuted(txn.hodler, txn.fromId, txn.fromTokens, txn.toId, txn.nonce);
    }   

    function cancelTransaction(
        address _hodler,
        uint _fromId,
        uint _fromTokens,
        uint _toId,
        uint nonce_) public {

            require(msg.sender == _hodler, "not auth");

            bytes32 txHash = getTxHash(_hodler, _fromId, _fromTokens, _toId, nonce_);
            
            require(status[txHash] < 2, "tx executed");
            
            status[txHash] = 2;
            
            Transaction storage txn = hashTxMapping[txHash];
            
            emit ConversionCancelled(txn.hodler, txn.fromId, txn.fromTokens, txn.toId, txn.nonce);
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
}
