/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ImplementationContract {
    address public owner;

    uint256 public test1; //5 
    uint256 public test2; //10
    uint256 public result;
    
    function setFirstParam(uint256 _test1) public {
        test1 = _test1;
    }
    
    function setSecondParam(uint256 _test2) public {
        test2 = _test2;
    }
    
    function calculateResult() public {
        result = test1 + test2; // 15
    }
    
    function calculateResultV2() public {
        result = test2 * test1; //50
    }
    
    function calculateResultV3() public {
        result = test2 / test1; // 2
    }
    
    function calculateResultV4() public {
        result = (test2 * test1) + 10; // 60
    }
}