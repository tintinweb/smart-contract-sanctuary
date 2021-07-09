/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Impl {
    
    event LogData(bytes lData);
 
    
    function log() public {
        emit LogData(msg.data);
    }
}

contract ProxyRouter {
    function _delegate(address implementation, bytes memory callData) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
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
    
    event Hello(address indexed impl, bytes pData, bytes mData);
    
    function hello(address impl, bytes memory pData) public {
        emit Hello(impl, pData, msg.data);
        
        _delegate(impl, pData);
    }
}