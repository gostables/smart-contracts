// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AdminAuth is Ownable {
    address[] admins;
    mapping(address => bool) adminExists;

    constructor() {
        setAdmin(msg.sender);
    }

    modifier onlyAdmin(address adminAddress) {
        require(adminExists[adminAddress], "admin not supported");
        _;
    }

    function setAdmin(address adminAddress) public onlyOwner {
        require(!adminExists[adminAddress], "admin already exists");
        admins.push(adminAddress);
        adminExists[adminAddress] = true;
    }

    function removeAdmin(uint256 index) public onlyOwner {
        require(index < admins.length, "index !< length");
        adminExists[admins[index]] = false;

        for (uint256 i = index; i < admins.length - 1; i++) {
            admins[i] = admins[i + 1];
        }
        admins.pop();
    }

    function getAdmins() public view returns (address[] memory) {
        return admins;
    }
}
