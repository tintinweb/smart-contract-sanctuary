/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

pragma solidity ^0.4.24;

// 계약 선언
contract Booleans {
    // a가 true이므로 b의 값과 상관없이 true를 리턴합니다.
    function getTrue() public pure returns (bool) {
        bool a = true;
        bool b = false;
        return a || b;
    }

    // a가 false이므로 b의 값과 상관없이 false를 리턴합니다.
    function getFalse() public pure returns (bool) {
        bool a = false;
        bool b = true;
        return a && b;
    }
}