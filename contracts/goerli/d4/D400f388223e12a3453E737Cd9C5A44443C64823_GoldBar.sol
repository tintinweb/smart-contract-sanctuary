/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

contract GoldBar {
    bytes2 constant _symbol = 'oz'; 
    bytes7 constant _name = 'GoldBar';
    
    function symbol() external pure returns(bytes2) {
        assembly {
            mstore(0x0, _symbol)
            return(0x0, 0x2)
       }
       //return _symbol;
    }

    function name() external pure returns(bytes7) {
        assembly {
            mstore(0x0, _name)
            return(0x0, 0x7)
        }
    }
}