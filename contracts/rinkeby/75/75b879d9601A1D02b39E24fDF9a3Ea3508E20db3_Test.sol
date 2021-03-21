/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;


abstract contract ERC1271 {
   
}

contract Test {
    
    constructor(uint x1, uint x2) public {
       
    }

    function _registerStandard(bytes4 _interfaceId) internal {
        
    }

    function initialize(address _initialExecutor) public {
        uint x = 3334;
        _registerStandard(type(ERC1271).interfaceId); //TODO THIS IS BUG
    } 
}


contract Test2 {
    address public base;

    constructor() public {
        setupBases();
    }

    function setupBases() private {
        base = address(new Test(10, 20));
    }
}