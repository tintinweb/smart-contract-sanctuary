/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

contract DemoStruct{
    
    struct Struct1 {
        uint128 f1; // spot rate of 1 A in units of B when liquidity was added (numerator)
        uint128 f2; // spot rate of 1 A in units of B when liquidity was added (denominator)
        address f3; // liquidity provider
        uint256 f4; // pool token amount
        Fraction f5;
    }
    
    struct Fraction {
        uint256 n; // numerator
        uint256 d; // denominator
    }
    
    function getRemoveLiquidityData() public view returns(Struct1 memory, uint256) {
        Struct1 memory s1;
        s1.f1 = 1;
        s1.f2 = 2;
        s1.f3 = address(this);
        s1.f4 = 4;
        Fraction memory _f5;
        _f5.n = 1;
        _f5.d = 2;
        s1.f5 = _f5;
        //
        uint256 u = 1;
        //
        return (s1, u);
    }
    
}