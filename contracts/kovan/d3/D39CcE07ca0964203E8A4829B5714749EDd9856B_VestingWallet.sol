/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


contract VestingWallet {

    struct Simple {
        uint256 one;
        uint256 two;
    }
    
    Simple[] public structs;
    
    function add(Simple calldata simple) public {
        structs.push(simple);
    }
    
    function show1() public view returns (uint one, uint two){
        return (structs[0].one, structs[0].two);
    }
    
    function show2() public view returns (uint one, uint two){
        one = structs[0].one;
        two = structs[0].two;
    }
}