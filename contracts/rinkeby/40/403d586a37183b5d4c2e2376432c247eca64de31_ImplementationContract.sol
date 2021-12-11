/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract ImplementationContract {
    address public owner;
    address payable implementation;
    uint256 version;

    uint256 public test1;
    uint256 public test2;
    uint256 public result;
    
    function setFirstParam(uint256 _test1) public {
        test1 = _test1;
    }
    
    function setSecondParam(uint256 _test2) public {
        test2 = _test2;
    }
    
    function calculateResult() public {
        result = test1 + test2;
    }
}