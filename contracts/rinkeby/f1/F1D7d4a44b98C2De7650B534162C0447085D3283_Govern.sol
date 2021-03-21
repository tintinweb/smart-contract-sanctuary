/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;


abstract contract ERC1271 {
   
}



contract Govern {

    constructor(address _initialExecutor)  public {
        
    }

    function _registerStandard(bytes4 _interfaceId) internal {
        
    }

    function initialize(address _initialExecutor) public {
        uint x = 3339;
        _registerStandard(type(ERC1271).interfaceId); //TODO THIS IS BUG
    } 

}