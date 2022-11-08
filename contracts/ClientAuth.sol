// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ClientAuth is Ownable {
    address[] clients;
    mapping(address => bool) clientExists;

    constructor() {
        setClient(msg.sender);
    }

    modifier onlyClients(address clientAddress) {
        require(clientExists[clientAddress], "client not supported");
        _;
    }

    function setClient(address clientAddress) public onlyOwner {
        require(!clientExists[clientAddress], "client already exists");
        clients.push(clientAddress);
        clientExists[clientAddress] = true;
    }

    function removeClient(uint256 index) public onlyOwner {
        require(index < clients.length, "index !< length");
        clientExists[clients[index]] = false;

        for (uint256 i = index; i < clients.length - 1; i++) {
            clients[i] = clients[i + 1];
        }
        clients.pop();
    }

    function getClients() public view returns (address[] memory) {
        return clients;
    }
}
