/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract Primitives {
    bool public boo = true;
    
    /*
        uint = unsigned integer
        uint8 ranges from 0 to 2^8-1
        ...
        uint256 ranges from 0 to 2^256-1
    */
    uint public u8 = 1;
    uint public u256 = 456;
    uint public u =123;  //  uint is same as uint256

    /*
        Negative numbers are allowed for int types

        int256 ranges from -2^255 to 2^255-1
        int128 ranges from -2^127 to 2^127-1
    */
    int8 public i8 = -1;
    int public i256 = 456;
    int public i= -123; //  int is same as int256

    //  min and max of int
    int public minInt = type(int).min;
    int public maxInt = type(int).max;

    address public addr = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;

    //  Default values
    //  Unassigned variables hava a default value
    bool public defaultBoo; //  false
    uint public defaultUint;    //  0    
    int public defaultInt;  //  0
    address public defaultAddr; //  0x0000000000000000000000000000000000000
}