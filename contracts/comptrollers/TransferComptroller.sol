// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../AdminAuth.sol";
import "../gStable.sol";
import "../Rewards.sol";
import "../BankDepository.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TransferComptroller is AdminAuth, Pausable, ReentrancyGuard {
    using ECDSA for bytes32;

    event TransactionSubmitted(
        address indexed from,
        address indexed to,
        uint id,
        uint value,
        bytes32 txHash
    );  
    event TransactionExecuted(
        address indexed from,
        address indexed to,
        uint id,
        uint value,
        bytes32 txHash
    );        

    struct Transaction {
        address from;
        address to;
        uint id;
        uint value;
        uint initiatedTime;
        uint executedTime;
        bytes32 txHash;
    }

    IBankDepository bank;

    //1 : initiated, 2 : cancelled, 3 : Executed Success, 4. Executed Fail
    mapping(bytes32 => uint) public status;

    mapping(bytes32 => Transaction) public hashTxMapping;
    mapping(address => bytes32[]) public userTxHashMapping;


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

    fallback() external payable {}

    receive() external payable {}

    function setBankDepository(address addr) public onlyAdmin(msg.sender) {
        bank = IBankDepository(addr);
    }

    function getUserTransactions(address hodler) public view returns(
        address[] memory addressPair, 
        uint[] memory value, 
        uint[] memory timePair, 
        bytes32[] memory txHash,
        uint[] memory statusList){
        
        bytes32[] memory userTxs = userTxHashMapping[hodler];
        uint pairLength = 2 * userTxs.length;
        
        address[] memory addressPairs = new address[](pairLength);
        uint256[] memory values = new uint256[](userTxs.length);
        uint256[] memory timePairs = new uint256[](pairLength);
        bytes32[] memory txHashs = new bytes32[](userTxs.length);
        uint256[] memory statuss = new uint256[](userTxs.length);
        
        for (uint i = 0; i < userTxs.length; i++) {
            Transaction memory userTx = hashTxMapping[userTxs[i]];
            addressPairs[i] = userTx.from;
            addressPairs[i + userTxs.length] = userTx.from;
            values[i] = userTx.value;
            timePairs[i] = userTx.initiatedTime;
            timePairs[i + userTxs.length] = userTx.executedTime;
            statuss[i] = status[userTxs[i]];
            txHashs[i] = userTx.txHash;
        }
        
        return (addressPairs, values, timePairs, txHashs, statuss);
    }

    function initiateTransaction(
        address _from,
        address _to,
        uint _id, 
        uint _value
    ) public onlyAdmin(msg.sender) returns(bytes32) {

        uint nonce_ = userTxHashMapping[_from].length;

        bytes32 txHash_ = getTxHash(_from, _to, _id, _value, nonce_);
        require(status[txHash_] < 1, "tx already exists");

        uint status_ = 1;
        
        Transaction memory txn = Transaction({from:_from, to:_to, id:_id, value:_value, initiatedTime: block.timestamp, executedTime: 0, txHash: txHash_});

        status[txHash_] = status_;   

        hashTxMapping[txHash_] = txn;
        userTxHashMapping[_from].push(txHash_);
        userTxHashMapping[_to].push(txHash_);

        emit TransactionSubmitted(_from, _to, _id, _value, txHash_);

        return txHash_;
    }
    
    function executeTransaction(
        address _from,
        address _to,
        uint _id, 
        uint _amount,
        uint _nonce,
        bytes memory _sig
    ) external onlyAdmin(msg.sender) {
        
        bytes32 txHash = getTxHash(_from, _to, _id, _amount, _nonce);

        require(status[txHash] < 2, "tx executed");
        require(_checkSigs(_sig, txHash), "invalid sig");
        
        Transaction storage txn = hashTxMapping[txHash];

        uint status_ = bank.moveGL(txn.from, txn.to, txn.id, txn.value);

        status[txHash] = status_;
        txn.executedTime = block.timestamp;

        emit TransactionExecuted(txn.from, txn.to, txn.id, txn.value, txn.txHash);
    }       

    function getTxHash(
        address _from,
        address _to,
        uint _id, 
        uint _amount,
        uint _nonce
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), _from, _to, _id, _amount, _nonce));
    }

    function _checkSigs(
        bytes memory _sig,
        bytes32 _txHash
    ) private view returns (bool) {
        bytes32 ethSignedHash = _txHash.toEthSignedMessageHash();

        address signer = ethSignedHash.recover(_sig);
        
        return signer == hashTxMapping[_txHash].from;
    }    
}
