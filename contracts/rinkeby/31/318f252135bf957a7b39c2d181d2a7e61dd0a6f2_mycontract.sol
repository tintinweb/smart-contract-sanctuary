/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract mycontract{
    uint counter = 0;
    struct xyz{
        uint X;
        uint Y;
        uint Z;
    }
    struct xyzInfo{
        uint cube;
        xyz test;
        xyz[] tset;
    }
    
    mapping (uint => xyzInfo) public xyzinfo;

    function yes(uint x, uint y, uint z) public {
    xyzinfo[counter].cube = x*y*z;
    xyzinfo[counter].test.X = x;
    xyzinfo[counter].test.Y = y;
    xyzinfo[counter].test.Z = z;
    xyzinfo[counter].tset.push(xyz(x, y, z));
    counter++;
    }
}