//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract JST is ERC20, Ownable {

    constructor(uint _totalSupply) ERC20("Jig Stack", "JST", _totalSupply) {
    
    }

}