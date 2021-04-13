/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.11;

import "StorageSlots.sol";
import "Common.sol";

/**
  CallProxy is a 'call' based proxy.
  It is a facade to a real implementation,
  only that unlike the Proxy pattern, it uses call and not delegatecall,
  so that the state is recorded on the called contract.

  This contract is expected to be placed behind the regular proxy,
  thus:
  1. Implementation address is stored in a hashed slot (other than proxy's one...).
  2. No state variable is allowed in low address ranges.
  3. Setting of implementation is done in initialize.
  4. isFrozen and initialize are implemented, to be compliant with Proxy.

  This implementation is intentionally minimal,
  and has no management or governance.
  The assumption is that if a different implementation is needed, it will be performed
  in an upgradeTo a new deployed CallProxy, pointing to a new implementation.
*/
contract CallProxy is StorageSlots {

    using Addresses for address;

    // Proxy client - initialize & isFrozen.
    // NOLINTNEXTLINE: external-function.
    function isFrozen() public pure returns(bool) {
        return false;
    }

    function initialize(bytes calldata data) external {
        require(data.length == 32, "INCORRECT_DATA_SIZE");
        address impl = abi.decode(data, (address));
        require(impl.isContract(), "ADDRESS_NOT_CONTRACT");
        setCallProxyImplementation(impl);
    }

    /*
      Returns the call proxy implementation address.
    */
    function callProxyImplementation() public view returns (address _implementation) {
        bytes32 slot = CALL_PROXY_IMPL_SLOT;
        assembly {
            _implementation := sload(slot)
        }
    }

    /*
      Sets the call proxy implementation address.
    */
    function setCallProxyImplementation(address newImplementation) private {
        bytes32 slot = CALL_PROXY_IMPL_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }

    /*
      Contract's default function. Pass execution to the implementation contract (using call).
      It returns back to the external caller whatever the implementation called code returns.
    */
    // NOLINTNEXTLINE: locked-ether.
    fallback() external payable {
        address _implementation = callProxyImplementation();
        require(_implementation != address(0x0), "MISSING_IMPLEMENTATION");
        uint256 value = msg.value;
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 for now, as we don't know the out size yet.
            let result := call(gas(), _implementation, value, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
                // delegatecall returns 0 on error.
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }
}