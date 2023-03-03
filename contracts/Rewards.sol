// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Rewards {
    function claim(uint256 merkleIndex, uint256 index, uint256 amount, bytes32[] calldata merkleProof) external{

    }
}

interface IRewards {
    function claim(uint256 merkleIndex, uint256 index, uint256 amount, bytes32[] calldata merkleProof) external;
}