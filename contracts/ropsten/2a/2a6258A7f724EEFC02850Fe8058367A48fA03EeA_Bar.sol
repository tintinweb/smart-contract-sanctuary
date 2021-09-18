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
    
    string public storage_;


    function store_it(string calldata s) public{
        storage_=s;
    }

    function add(uint id, uint _x) public {
        foo[id].push(Foo(_x));
    }

    function get(uint id, uint index) public view returns(uint){
        return foo[id][index].x;
    }
    
    function populate(uint num) public {
        for (uint i = 0; i < num; i++) {
            foo[i].push(Foo(i+i));
        }
    }
}