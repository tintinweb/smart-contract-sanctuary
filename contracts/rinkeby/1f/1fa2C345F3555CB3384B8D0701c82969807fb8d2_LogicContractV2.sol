/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
contract LogicContractV2 {
    address public ownerSlot;//slot 0 == owner address
    address public implementationSlot;
    uint256 versionSlot;

    uint256 public test1;
    uint256 public test2;
    uint256 public result;
    uint256 public test3;

    function setFirst(uint256 _test1) public{
        test1  = _test1;
    }
    function setSecond(uint256 _test2) public{
        test2  = _test2;
    }
     function setThird(uint256 _test3) public{
        test3  = _test3;
    }
    function multiply () public{
        result = test1 * test2 * test3;
    }
}