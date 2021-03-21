/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "@aragon/govern-contract-utils/contracts/adaptive-erc165/AdaptiveERC165.sol";

abstract contract ERC1271 {
    bytes4 constant internal MAGICVALUE = 0x1626ba7e;
    function isValidSignature(bytes32 _hash, bytes memory _signature) virtual public view returns (bytes4 magicValue);
}

contract Govern is AdaptiveERC165 {

    constructor(address _initialExecutor)  public {
        
    }

    function initialize(address _initialExecutor) public {
        uint x = 223;
        _registerStandard(type(ERC1271).interfaceId); //TODO THIS IS BUG
    } 

}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.6.8;


contract AdaptiveERC165 {
    
    function _registerStandard(bytes4 _interfaceId) internal {
        
    }

}