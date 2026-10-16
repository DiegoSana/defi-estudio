// SPDX-License-Identifier: MIT
pragma solidity ^0.8.36;

import {ERC20} from "./ERC20.sol";

contract MiToken is ERC20 {

    address public owner = msg.sender;

    constructor() ERC20("Mi Token", "MTK") {}

    function mint(address to, uint256 amount) public {
        require(msg.sender == owner, "only owner can mint");
        _mint(to, amount);
    }
}