/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

contract GoldBar {
    bytes2 constant _symbol = 'oz'; 
    bytes8 constant _name = 'GoldBar';

    event Transfer(address indexed from, address indexed to, uint256 value);
    constructor() {
        emit Transfer(address(0), address(this), 1000);
    }
    
    function symbol() external pure returns(bytes2) {
        assembly {
            mstore(0x0, _symbol)
            return(0x0, 0x2)
       }
       //return _symbol;
    }

    function name() external pure returns(bytes8) {
        assembly {
            return(_name, 0x8)
        }
    }
}