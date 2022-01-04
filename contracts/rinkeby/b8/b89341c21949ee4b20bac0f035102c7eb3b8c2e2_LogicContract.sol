/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract LogicContract {
    address public ownerSlot;//slot 0 == owner address
    address public implementationSlot;
    uint256 versionSlot;

    uint256 public test1;
    uint256 public test2;
    uint256 public result;

    function initialize(uint _test1) public{
        test1 = _test1;
    }

    function setFirst(uint256 _test1) public{
        test1  = _test1;
    }
    function setSecond(uint256 _test2) public{
        test2  = _test2;
    }
    function add () public{
        result = test1 + test2;
    }
}