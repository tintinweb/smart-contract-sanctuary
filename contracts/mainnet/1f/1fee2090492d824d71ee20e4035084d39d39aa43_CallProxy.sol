/*
  Copyright 2019-2021 StarkWare Industries Ltd.

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

import "IFactRegistry.sol";
import "StorageSlots.sol";
import "BlockDirectCall.sol";
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
// NOLINTNEXTLINE locked-ether.
contract CallProxy is BlockDirectCall, StorageSlots {
    using Addresses for address;

    string public constant CALL_PROXY_VERSION = "3.1.0";

    // Proxy client - initialize & isFrozen.
    // NOLINTNEXTLINE: external-function.
    function isFrozen() public pure returns (bool) {
        return false;
    }

    /*
      Proxy calls the function initialize upon activating an implementation.
      In the context of the CallProxy contract, the mainstream operation of
      initialize is to extract the real implementation from the passed call data,
      and to save it in the CallProxyImplementation slot.

      However, in a case of EIC flow,
      The implementation address is set, as in the normal flow, and then the
      EIC initialize() function is called with the remaining data.

      Case I (no EIC):
        [0 .. 31] implementation address

      Case II (EIC):
        data length >= 64
        [0  .. 31] implementation address
        [32 .. 63] EIC address
        [64 -    ] EIC init data.
    */
    function initialize(bytes calldata data) external notCalledDirectly {
        require(data.length == 32 || data.length >= 64, "INCORRECT_DATA_SIZE");
        address impl = abi.decode(data, (address));
        require(impl.isContract(), "ADDRESS_NOT_CONTRACT");
        setCallProxyImplementation(impl);
        if (data.length >= 64) {
            address eic = abi.decode(data[32:64], (address));
            if (eic != address(0x0)) {
                callExternalInitializer(eic, data[64:]);
            }
        }
    }

    function callExternalInitializer(address externalInitializerAddr, bytes calldata eicData)
        private
    {
        require(externalInitializerAddr.isContract(), "EIC_NOT_A_CONTRACT");

        // NOLINTNEXTLINE: low-level-calls, controlled-delegatecall.
        (bool success, bytes memory returndata) = externalInitializerAddr.delegatecall(
            abi.encodeWithSelector(this.initialize.selector, eicData)
        );
        require(success, string(returndata));
        require(returndata.length == 0, string(returndata));
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
      An explicit isValid entry point, used to make isValid a part of the ABI and visible
      on Etherscan (and alike).
    */
    function isValid(bytes32 fact) external view returns (bool) {
        return IFactRegistry(callProxyImplementation()).isValid(fact);
    }

    /*
      This entry point serves only transactions with empty calldata. (i.e. pure value transfer tx).
      We don't expect to receive such, thus block them.
    */
    receive() external payable {
        revert("CONTRACT_NOT_EXPECTED_TO_RECEIVE");
    }

    /*
      Contract's default function. Pass execution to the implementation contract (using call).
      It returns back to the external caller whatever the implementation called code returns.
    */
    fallback() external payable {
        // NOLINT locked-ether.
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