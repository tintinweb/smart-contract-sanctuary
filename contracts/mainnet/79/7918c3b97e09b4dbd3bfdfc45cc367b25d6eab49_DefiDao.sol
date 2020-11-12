// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC20.sol";

 contract DefiDao is ERC20 {
    using SafeMath for uint256;
    using Address for address;
    address private _owner;

    constructor (string memory name, string memory symbol,uint8 decimals, uint256 totalSupply) ERC20(name,symbol,decimals) public {
        _mint(_msgSender(),totalSupply);
    } 
}