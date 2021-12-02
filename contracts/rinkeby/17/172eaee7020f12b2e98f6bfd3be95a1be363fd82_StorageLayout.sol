/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract StorageLayout {
    uint248 ALPHA = 1;
    bool BETA = true;
    uint8 GAMMA = 8;
    struct DELTA {
        bool b;
        uint248 a;
    }
    DELTA EPSILON = DELTA(BETA, ALPHA);
    mapping (uint => DELTA) ZETA;
    mapping (address => mapping (uint => DELTA)) ETA;
    uint248[3] THETA;
    bytes8 IOTA = "abcdefgh";
    enum KAPPA {
        LAMDA,
        MU,
        NU
    }
    KAPPA XI = KAPPA.LAMDA;
    
    function store() external {
        ZETA[ALPHA] = EPSILON; 
    }
}