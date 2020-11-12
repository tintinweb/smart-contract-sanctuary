// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC20.sol";

contract TokenOfferingPlatformERC20 is ERC20 {
    using Address for address;
    address private _owner;
   
    constructor (string memory name, string memory symbol, uint256 totalSupply) ERC20(name,symbol) public {
        _mint(_msgSender(),totalSupply);
    } 
}