/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
 
 
 contract Bar{

    struct Foo{
        uint x;
    }
    mapping(uint => Foo[]) foo;

    function add(uint id, uint _x) public {
        foo[id].push(Foo(_x));
    }

    function get(uint id, uint index) public view returns(uint){
        return foo[id][index].x;
    }
    
    function populate() public {
        for (uint i = 0; i < 10000; i++) {
            foo[i].push(Foo(i+i));
        }
    }
}