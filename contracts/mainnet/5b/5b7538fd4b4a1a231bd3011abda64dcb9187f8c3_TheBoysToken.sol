// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "../ERC20.sol";

contract TheBoysToken is ERC20 {
    using SafeMath for uint256;
    using Address for address;
    
    constructor (string memory name, string memory symbol) public ERC20(name,symbol) {
        
        //mint 1B tokens to the creator account
        uint256 _supply = 10**9; //1B
        
        _mint(msg.sender, _supply * (10**18)); //10**18 is for decimal places
    }
}