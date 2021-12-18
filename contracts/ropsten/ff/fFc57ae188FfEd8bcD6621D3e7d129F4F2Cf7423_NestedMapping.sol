/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract NestedMapping {
    //  Nested mapping
    mapping(address => mapping(uint => bool)) public nested;

    function get(address _addr1 ,uint _i) public view returns (bool) {
        //  未初始化也可以取值
        return nested[_addr1][_i];
    }

    function set(
        address _addr1,
        uint _i,
        bool _boo
    ) public {
        nested[_addr1][_i] = _boo;
    }

    function remove(address _addr1, uint _i) public {
        delete nested[_addr1][_i];
    }
}