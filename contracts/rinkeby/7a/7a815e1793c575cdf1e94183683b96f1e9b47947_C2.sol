// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.6;

import "./C1.sol";
contract C2 {
    C1 c1;
    constructor() {
        c1 = new C1();
    }
    
    function add() public view returns (uint) {
       uint c =  c1.sum(5,6);
       return c;
    }
}