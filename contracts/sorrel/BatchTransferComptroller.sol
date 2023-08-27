// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./BankDepository.sol";
import "../AdminAuth.sol";

contract BatchTransferComptroller is AdminAuth {
    BankDepository public bankDepository;
    mapping(address => uint256) public feesCollected;
    uint256 public basisPointFee;

    constructor(address bankDepositoryAddress) {
        bankDepository = BankDepository(bankDepositoryAddress);
    }

    // admin can set the basisPointFee
    function setBasisPointFee(uint256 _basisPointFee) public onlyAdmin(msg.sender) {
        basisPointFee = _basisPointFee;
    }

    // member can batch transfer from their own address to N members
    function batchTransferByMember(address[] calldata recipients, uint256[] calldata amounts, uint256 gStableId) public {
        require(recipients.length == amounts.length, "Invalid input");

        for (uint256 i = 0; i < recipients.length; i++) {
            bankDepository.moveGL(msg.sender, recipients[i], gStableId, amounts[i]);
        }
    }

    // admin can batch transfer from N address once approved, to N members
    function batchTransferByAdmin(address[] calldata senders, address[] calldata recipients, uint256[] calldata amounts, uint256 gStableId) public onlyAdmin(msg.sender) {
        require(recipients.length == senders.length && recipients.length == amounts.length, "Invalid input");

        for (uint256 i = 0; i < recipients.length; i++) {
            bankDepository.moveGL(senders[i], recipients[i], gStableId, amounts[i]);
        }
    }

    // anyone can batch transfer gStables outside of Sorrel
    function batchTransferByAnyone(address gStableAddress, address[] calldata recipients, uint256[] calldata amounts) public {
        require(recipients.length == amounts.length, "Invalid input");

        IERC20 gStable_ = IERC20(gStableAddress);

        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 feeAmount = amounts[i] * basisPointFee / 10000;

            gStable_.transferFrom(msg.sender, recipients[i], amounts[i]);
            feesCollected[gStableAddress] += feeAmount;
        }
        gStable_.transferFrom(msg.sender, (address(this)), feesCollected[gStableAddress]);
    }

    // admin can withdraw collected fees
    function withdrawFees(address[] calldata gStableAddresses) public onlyAdmin(msg.sender) {
        for (uint256 i = 0; i < gStableAddresses.length; i++) {
            IERC20 gStable_ = IERC20(gStableAddresses[i]);
            uint256 feeAmount = feesCollected[gStableAddresses[i]];

            if (feeAmount > 0) {
                feesCollected[gStableAddresses[i]] = 0;
                gStable_.transfer(msg.sender, feeAmount);
            }
        }
    }




}
