/**
 *Submitted for verification at BscScan.com on 2021-08-15
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract MyProperty {
    int public value;
    
    function setValue (int _value) public {
        value = _value;
    }
}