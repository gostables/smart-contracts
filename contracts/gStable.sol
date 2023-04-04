// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./AdminAuth.sol";

contract gStable is ERC20, AdminAuth {
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    function mint(address reciever, uint256 mintAmount)
        external
        onlyAdmin(msg.sender)
    {
        _mint(reciever, mintAmount);
    }

    function burn(address hodler, uint256 burnAmount)
        external
        onlyAdmin(msg.sender)
    {
        _burn(hodler, burnAmount);
    }
}

interface IgStable is IERC20{
    function mint(address reciever, uint256 mintAmount) external;

    function burn(address hodler, uint256 burnAmount) external;
}
