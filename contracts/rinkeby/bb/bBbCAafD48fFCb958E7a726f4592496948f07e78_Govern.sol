/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;


abstract contract ERC1271 {
    bytes4 constant internal MAGICVALUE = 0x1626ba7e;
    function isValidSignature(bytes32 _hash, bytes memory _signature) virtual public view returns (bytes4 magicValue);
}

contract AdaptiveERC165 {
    
    function _registerStandard(bytes4 _interfaceId) internal {
        
    }

}

contract Govern is AdaptiveERC165 {

    constructor(address _initialExecutor)  public {
        
    }

    function initialize(address _initialExecutor) public {
        uint x = 222;
        _registerStandard(type(ERC1271).interfaceId); //TODO THIS IS BUG
    } 

}