/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

// File: test.sol

pragma solidity ^0.5.16;

contract MyContract {
        uint256 [] public  T;
        uint8 public a;
        uint256 public b;
        constructor() public {
                T = [1,2,3,4,5];
        }
        function pushUintToT(uint256 _value) public {
                T.push(_value);
        }

        function setTLength(uint256 len) public {
                T.length = len;
        }
        function setTIndexValue(uint256 _index, uint256 _value) public {
                T[_index] = _value;
        }
        function setaValue(uint8 _value) public {
                a = _value;
        }
        function setbValue(uint256 _value) public {
                b = _value;
        }
        function T_Length() public view returns (uint) {
                return T.length;
        }
        function getBlock() public view returns (uint) {
                return block.number;
        }
}