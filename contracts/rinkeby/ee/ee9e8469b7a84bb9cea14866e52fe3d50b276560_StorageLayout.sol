/**
 *Submitted for verification at Etherscan.io on 2021-12-24
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
    uint256[3] THETA;
    bytes8 IOTA = "abcdefgh";
    enum KAPPA {
        LAMDA,
        MU,
        NU
    }
    KAPPA XI = KAPPA.LAMDA;
    address OMICRON;
    uint256[3][] SIGMA;
    mapping (address => mapping (uint => bool)) TAU;
    uint[][] UPSILON;
    uint[3] PHI;
    uint[][3] KI;

    constructor() {
        OMICRON = address(this);
    }
    function store() external {
        ZETA[ALPHA] = EPSILON; 
        ETA[OMICRON][ALPHA] = EPSILON;
        THETA = [1, 2, 3];
        SIGMA.push(THETA);
        TAU[OMICRON][1] = true;
        TAU[OMICRON][2] = true;
        UPSILON.push(THETA);
        PHI = THETA;
        KI = [THETA];
    }
}