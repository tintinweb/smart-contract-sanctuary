/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract con1 {
    uint256 value;
    constructor(){

    }

    function add(uint256 _value)public {
        value+=_value;
    }
    function sub(uint256 _value)public {
        value -=_value;
    }
}


contract con2 {
    uint256 value;
    constructor(uint256 _value){
        value =_value;
    }

    function add(uint256 _value)public {
        value+=_value;
    }
    function sub(uint256 _value)public {
        value -=_value;
    }
}

contract createor {
    con1 public contract1;
    con2 public contract2;
    constructor(){

    }

    function create()public {
        contract1 = new con1();
    }

    function create2(uint256 _value)public {
        contract2 = new con2(_value);
    }
}