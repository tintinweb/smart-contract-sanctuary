// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./ERC20.sol";

//@custom:security-contact: [email protected]

contract Nuva is ERC20{
    constructor(uint256 initialSupply) ERC20("NuvaToken", "NUVA"){
       _mint(msg.sender, initialSupply);
    }

}