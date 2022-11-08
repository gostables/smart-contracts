// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ClientAuth.sol";

contract gStable is ERC20, Pausable, Ownable, ClientAuth {
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    function mint(address reciever, uint256 mintAmount)
        external
        onlyClients(msg.sender)
    {
        _mint(reciever, mintAmount);
    }

    function burn(address hodler, uint256 burnAmount)
        external
        onlyClients(msg.sender)
    {
        _burn(hodler, burnAmount);
    }
}

interface IgStable {
    function mint(address reciever, uint256 mintAmount) external;

    function burn(address hodler, uint256 burnAmount) external;

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
