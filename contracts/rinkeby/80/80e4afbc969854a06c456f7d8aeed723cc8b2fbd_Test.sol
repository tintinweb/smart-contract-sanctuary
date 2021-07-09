/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Test {
    
    function _delegate(address implementation, bytes memory callData) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            // calldatacopy(0, 0, calldatasize())
            // let callDataSize = mload(callData);
            

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            // let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            // delegatecall(g, a, in, insize, out, outsize)
            let result := delegatecall(gas(), implementation, add(callData, 0x20), mload(callData), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    
    
    event Hello(address indexed impl, bytes indexed  pData, bytes indexed  mData);
    
    function hello(address impl, bytes memory pData) public {
        emit Hello(impl, pData, msg.data);
        
        _delegate(impl, pData);
    }
}