/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

struct Signature {
    address signatory;
    uint8   v;
    bytes32 r;
    bytes32 s;
}

contract A {
    uint internal _a = 1;
    
    function a() virtual public view returns (uint) {
        return _a;
    }

    function b() virtual public view returns (uint) {
        return 0;
    }
    
    function c() virtual public view returns (uint) {
        return 0;
    }

    function s(Signature memory signature) virtual public view returns (uint) {
        return signature.v;
    }
}

contract B {
    uint internal _b = 2;
    
    function a() virtual public view returns (uint) {
        return 0;
    }

    function b() virtual public view returns (uint) {
        return _b;
    }
    
    function c() virtual public view returns (uint) {
        return 0;
    }
}

contract C is A, B {
    uint internal _c = 3;

    function a() override(A, B) public view returns (uint) {
        return _a;
    }

    function b() override(A, B) public view returns (uint) {
        return _b;
    }
    
    function c() override(A, B) public view returns (uint) {
        return _c;
    }
}