/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// hevm: flattened sources of src/Proxy.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

////// src/Proxy.sol
/* pragma solidity ^0.8.0; */

contract Proxy {

    event ProxyCreated(address indexed proxy, address indexed implementation);

    address internal _implementation;

    constructor(address implementation_) {
        _implementation = implementation_;
        
        emit ProxyCreated(address(this), implementation_);
    }

    fallback() payable external virtual {
        address implementation = _implementation;

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

}