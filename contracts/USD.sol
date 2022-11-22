// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USD is ERC20 {
    constructor() ERC20("USDD", "USDD") {}

    function mint(uint256 _amount) external {
        _mint(msg.sender, _amount);
    }
}
