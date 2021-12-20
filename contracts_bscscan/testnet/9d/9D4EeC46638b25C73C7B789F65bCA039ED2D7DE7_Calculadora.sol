/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

pragma solidity >= 0.7.0 < 0.9.0;
// SPDX-License-Identifier: No license

contract Calculadora {
    function suma(int _n1, int _n2) public pure returns(int) {
        return _n1 + _n2;
    }

    function resta(int _n1, int _n2) public pure returns(int) {
        return _n1 - _n2;
    }

    function multiplicacion(int _n1, int _n2) public pure returns(int) {
        return _n1 * _n2;
    }
}