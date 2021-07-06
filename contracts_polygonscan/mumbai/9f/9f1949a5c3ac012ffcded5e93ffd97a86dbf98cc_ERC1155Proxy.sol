/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "../archive/Ownable.sol";
import "../src/interfaces/IAssetProxy.sol";
import "../src/interfaces/IAssetProxyDispatcher.sol";


contract MixinAssetProxyDispatcher is
    Ownable,
    IAssetProxyDispatcher
{
    // Mapping from Asset Proxy Id's to their respective Asset Proxy
    mapping (bytes4 => address) public assetProxies;

    /// @dev Registers an asset proxy to its asset proxy id.
    ///      Once an asset proxy is registered, it cannot be unregistered.
    /// @param assetProxy Address of new asset proxy to register.
    function registerAssetProxy(address assetProxy)
        external
        onlyOwner
    {
        // Ensure that no asset proxy exists with current id.
        bytes4 assetProxyId = IAssetProxy(assetProxy).getProxyId();
        address currentAssetProxy = assetProxies[assetProxyId];
        require(
            currentAssetProxy == address(0),
            "ASSET_PROXY_ALREADY_EXISTS"
        );

        // Add asset proxy and log registration.
        assetProxies[assetProxyId] = assetProxy;
        emit AssetProxyRegistered(
            assetProxyId,
            assetProxy
        );
    }

    /// @dev Gets an asset proxy.
    /// @param assetProxyId Id of the asset proxy.
    /// @return The asset proxy registered to assetProxyId. Returns 0x0 if no proxy is registered.
    function getAssetProxy(bytes4 assetProxyId)
        external
        view
        returns (address)
    {
        return assetProxies[assetProxyId];
    }

    /// @dev Forwards arguments to assetProxy and calls `transferFrom`. Either succeeds or throws.
    /// @param assetData Byte array encoded for the asset.
    /// @param from Address to transfer token from.
    /// @param to Address to transfer token to.
    /// @param amount Amount of token to transfer.
    function _dispatchTransferFrom(
        bytes memory assetData,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        // Do nothing if no amount should be transferred.
        if (amount > 0 && from != to) {
            // Ensure assetData length is valid
            require(
                assetData.length > 3,
                "LENGTH_GREATER_THAN_3_REQUIRED"
            );

            // Lookup assetProxy. We do not use `LibBytes.readBytes4` for gas efficiency reasons.
            bytes4 assetProxyId;
            assembly {
                assetProxyId := and(mload(
                    add(assetData, 32)),
                    0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
                )
            }
            address assetProxy = assetProxies[assetProxyId];

            // Ensure that assetProxy exists
            require(
                assetProxy != address(0),
                "ASSET_PROXY_DOES_NOT_EXIST"
            );

            // We construct calldata for the `assetProxy.transferFrom` ABI.
            // The layout of this calldata is in the table below.
            //
            // | Area     | Offset | Length  | Contents                                    |
            // | -------- |--------|---------|-------------------------------------------- |
            // | Header   | 0      | 4       | function selector                           |
            // | Params   |        | 4 * 32  | function parameters:                        |
            // |          | 4      |         |   1. offset to assetData (*)                |
            // |          | 36     |         |   2. from                                   |
            // |          | 68     |         |   3. to                                     |
            // |          | 100    |         |   4. amount                                 |
            // | Data     |        |         | assetData:                                  |
            // |          | 132    | 32      | assetData Length                            |
            // |          | 164    | **      | assetData Contents                          |

            assembly {
                /////// Setup State ///////
                // `cdStart` is the start of the calldata for `assetProxy.transferFrom` (equal to free memory ptr).
                let cdStart := mload(64)
                // `dataAreaLength` is the total number of words needed to store `assetData`
                //  As-per the ABI spec, this value is padded up to the nearest multiple of 32,
                //  and includes 32-bytes for length.
                let dataAreaLength := and(add(mload(assetData), 63), 0xFFFFFFFFFFFE0)
                // `cdEnd` is the end of the calldata for `assetProxy.transferFrom`.
                let cdEnd := add(cdStart, add(132, dataAreaLength))


                /////// Setup Header Area ///////
                // This area holds the 4-byte `transferFromSelector`.
                // bytes4(keccak256("transferFrom(bytes,address,address,uint256)")) = 0xa85e59e4
                mstore(cdStart, 0xa85e59e400000000000000000000000000000000000000000000000000000000)

                /////// Setup Params Area ///////
                // Each parameter is padded to 32-bytes. The entire Params Area is 128 bytes.
                // Notes:
                //   1. The offset to `assetData` is the length of the Params Area (128 bytes).
                //   2. A 20-byte mask is applied to addresses to zero-out the unused bytes.
                mstore(add(cdStart, 4), 128)
                mstore(add(cdStart, 36), and(from, 0xffffffffffffffffffffffffffffffffffffffff))
                mstore(add(cdStart, 68), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
                mstore(add(cdStart, 100), amount)

                /////// Setup Data Area ///////
                // This area holds `assetData`.
                let dataArea := add(cdStart, 132)
                // solhint-disable-next-line no-empty-blocks
                for {} lt(dataArea, cdEnd) {} {
                    mstore(dataArea, mload(assetData))
                    dataArea := add(dataArea, 32)
                    assetData := add(assetData, 32)
                }

                /////// Call `assetProxy.transferFrom` using the constructed calldata ///////
                let success := call(
                    gas,                    // forward all gas
                    assetProxy,             // call address of asset proxy
                    0,                      // don't send any ETH
                    cdStart,                // pointer to start of input
                    sub(cdEnd, cdStart),    // length of input
                    cdStart,                // write output over input
                    512                     // reserve 512 bytes for output
                )
                if iszero(success) {
                    revert(cdStart, returndatasize())
                }
            }
        }
    }
}

pragma solidity ^0.5.9;

import "@0x/contracts-utils/contracts/src/interfaces/IOwnable.sol";


contract Ownable is
    IOwnable
{
    address public owner;

    constructor ()
        public
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "ONLY_CONTRACT_OWNER"
        );
        _;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


contract IOwnable {

    /// @dev Emitted by Ownable when ownership is transferred.
    /// @param previousOwner The previous owner of the contract.
    /// @param newOwner The new owner of the contract.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev Transfers ownership of the contract to a new address.
    /// @param newOwner The address that will become the owner.
    function transferOwnership(address newOwner)
        public;
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


contract IAssetProxy {

    /// @dev Transfers assets. Either succeeds or throws.
    /// @param assetData Byte array encoded for the respective asset proxy.
    /// @param from Address to transfer asset from.
    /// @param to Address to transfer asset to.
    /// @param amount Amount of asset to transfer.
    function transferFrom(
        bytes calldata assetData,
        address from,
        address to,
        uint256 amount
    )
        external;
    
    /// @dev Gets the proxy id associated with the proxy address.
    /// @return Proxy id.
    function getProxyId()
        external
        pure
        returns (bytes4);
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


contract IAssetProxyDispatcher {

    // Logs registration of new asset proxy
    event AssetProxyRegistered(
        bytes4 id,              // Id of new registered AssetProxy.
        address assetProxy      // Address of new registered AssetProxy.
    );

    /// @dev Registers an asset proxy to its asset proxy id.
    ///      Once an asset proxy is registered, it cannot be unregistered.
    /// @param assetProxy Address of new asset proxy to register.
    function registerAssetProxy(address assetProxy)
        external;

    /// @dev Gets an asset proxy.
    /// @param assetProxyId Id of the asset proxy.
    /// @return The asset proxy registered to assetProxyId. Returns 0x0 if no proxy is registered.
    function getAssetProxy(bytes4 assetProxyId)
        external
        view
        returns (address);
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "../archive/Ownable.sol";
import "../src/interfaces/IAuthorizable.sol";


contract MixinAuthorizable is
    Ownable,
    IAuthorizable
{
    /// @dev Only authorized addresses can invoke functions with this modifier.
    modifier onlyAuthorized {
        require(
            authorized[msg.sender],
            "SENDER_NOT_AUTHORIZED"
        );
        _;
    }

    mapping (address => bool) public authorized;
    address[] public authorities;

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function addAuthorizedAddress(address target)
        external
        onlyOwner
    {
        require(
            !authorized[target],
            "TARGET_ALREADY_AUTHORIZED"
        );

        authorized[target] = true;
        authorities.push(target);
        emit AuthorizedAddressAdded(target, msg.sender);
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    function removeAuthorizedAddress(address target)
        external
        onlyOwner
    {
        require(
            authorized[target],
            "TARGET_NOT_AUTHORIZED"
        );

        delete authorized[target];
        for (uint256 i = 0; i < authorities.length; i++) {
            if (authorities[i] == target) {
                authorities[i] = authorities[authorities.length - 1];
                authorities.length -= 1;
                break;
            }
        }
        emit AuthorizedAddressRemoved(target, msg.sender);
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function removeAuthorizedAddressAtIndex(
        address target,
        uint256 index
    )
        external
        onlyOwner
    {
        require(
            authorized[target],
            "TARGET_NOT_AUTHORIZED"
        );
        require(
            index < authorities.length,
            "INDEX_OUT_OF_BOUNDS"
        );
        require(
            authorities[index] == target,
            "AUTHORIZED_ADDRESS_MISMATCH"
        );

        delete authorized[target];
        authorities[index] = authorities[authorities.length - 1];
        authorities.length -= 1;
        emit AuthorizedAddressRemoved(target, msg.sender);
    }

    /// @dev Gets all authorized addresses.
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses()
        external
        view
        returns (address[] memory)
    {
        return authorities;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "@0x/contracts-utils/contracts/src/interfaces/IOwnable.sol";


contract IAuthorizable is
    IOwnable
{
    // Event logged when a new address is authorized.
    event AuthorizedAddressAdded(
        address indexed target,
        address indexed caller
    );

    // Event logged when a currently authorized address is unauthorized.
    event AuthorizedAddressRemoved(
        address indexed target,
        address indexed caller
    );

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function addAuthorizedAddress(address target)
        external;

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    function removeAuthorizedAddress(address target)
        external;

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function removeAuthorizedAddressAtIndex(
        address target,
        uint256 index
    )
        external;

    /// @dev Gets all authorized addresses.
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses()
        external
        view
        returns (address[] memory);
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "@0x/contracts-utils/contracts/src/LibBytes.sol";
import "@0x/contracts-utils/contracts/src/LibSafeMath.sol";
import "@0x/contracts-erc1155/contracts/src/interfaces/IERC1155.sol";
import "../archive/MixinAuthorizable.sol";
import "./interfaces/IAssetProxy.sol";


contract ERC1155Proxy is
    MixinAuthorizable,
    IAssetProxy
{
    using LibBytes for bytes;
    using LibSafeMath for uint256;

    // Id of this proxy.
    bytes4 constant internal PROXY_ID = bytes4(keccak256("ERC1155Assets(address,uint256[],uint256[],bytes)"));

    /// @dev Transfers batch of ERC1155 assets. Either succeeds or throws.
    /// @param assetData Byte array encoded with ERC1155 token address, array of ids, array of values, and callback data.
    /// @param from Address to transfer assets from.
    /// @param to Address to transfer assets to.
    /// @param amount Amount that will be multiplied with each element of `assetData.values` to scale the
    ///        values that will be transferred.
    function transferFrom(
        bytes calldata assetData,
        address from,
        address to,
        uint256 amount
    )
        external
        onlyAuthorized
    {
        // Decode params from `assetData`
        // solhint-disable indent
        (
            address erc1155TokenAddress,
            uint256[] memory ids,
            uint256[] memory values,
            bytes memory data
        ) = abi.decode(
            assetData.sliceDestructive(4, assetData.length),
            (address, uint256[], uint256[], bytes)
        );
        // solhint-enable indent

        // Scale values up by `amount`
        uint256 length = values.length;
        uint256[] memory scaledValues = new uint256[](length);
        for (uint256 i = 0; i != length; i++) {
            // We write the scaled values to an unused location in memory in order
            // to avoid copying over `ids` or `data`. This is possible if they are
            // identical to `values` and the offsets for each are pointing to the
            // same location in the ABI encoded calldata.
            scaledValues[i] = values[i].safeMul(amount);
        }

        // Execute `safeBatchTransferFrom` call
        // Either succeeds or throws
        IERC1155(erc1155TokenAddress).safeBatchTransferFrom(
            from,
            to,
            ids,
            scaledValues,
            data
        );
    }

    /// @dev Gets the proxy id associated with the proxy address.
    /// @return Proxy id.
    function getProxyId()
        external
        pure
        returns (bytes4)
    {
        return PROXY_ID;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "./LibBytesRichErrors.sol";
import "./LibRichErrors.sol";


library LibBytes {

    using LibBytes for bytes;

    /// @dev Gets the memory address for a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of byte array. This
    ///         points to the header of the byte array which contains
    ///         the length.
    function rawAddress(bytes memory input)
        internal
        pure
        returns (uint256 memoryAddress)
    {
        assembly {
            memoryAddress := input
        }
        return memoryAddress;
    }

    /// @dev Gets the memory address for the contents of a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of the contents of the byte array.
    function contentAddress(bytes memory input)
        internal
        pure
        returns (uint256 memoryAddress)
    {
        assembly {
            memoryAddress := add(input, 32)
        }
        return memoryAddress;
    }

    /// @dev Copies `length` bytes from memory location `source` to `dest`.
    /// @param dest memory address to copy bytes to.
    /// @param source memory address to copy bytes from.
    /// @param length number of bytes to copy.
    function memCopy(
        uint256 dest,
        uint256 source,
        uint256 length
    )
        internal
        pure
    {
        if (length < 32) {
            // Handle a partial word by reading destination and masking
            // off the bits we are interested in.
            // This correctly handles overlap, zero lengths and source == dest
            assembly {
                let mask := sub(exp(256, sub(32, length)), 1)
                let s := and(mload(source), not(mask))
                let d := and(mload(dest), mask)
                mstore(dest, or(s, d))
            }
        } else {
            // Skip the O(length) loop when source == dest.
            if (source == dest) {
                return;
            }

            // For large copies we copy whole words at a time. The final
            // word is aligned to the end of the range (instead of after the
            // previous) to handle partial words. So a copy will look like this:
            //
            //  ####
            //      ####
            //          ####
            //            ####
            //
            // We handle overlap in the source and destination range by
            // changing the copying direction. This prevents us from
            // overwriting parts of source that we still need to copy.
            //
            // This correctly handles source == dest
            //
            if (source > dest) {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because it
                    // is easier to compare with in the loop, and these
                    // are also the addresses we need for copying the
                    // last bytes.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the last 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the last bytes in
                    // source already due to overlap.
                    let last := mload(sEnd)

                    // Copy whole words front to back
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {} lt(source, sEnd) {} {
                        mstore(dest, mload(source))
                        source := add(source, 32)
                        dest := add(dest, 32)
                    }

                    // Write the last 32 bytes
                    mstore(dEnd, last)
                }
            } else {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because those
                    // are the starting points when copying a word at the end.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the first 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the first bytes in
                    // source already due to overlap.
                    let first := mload(source)

                    // Copy whole words back to front
                    // We use a signed comparisson here to allow dEnd to become
                    // negative (happens when source and dest < 32). Valid
                    // addresses in local memory will never be larger than
                    // 2**255, so they can be safely re-interpreted as signed.
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {} slt(dest, dEnd) {} {
                        mstore(dEnd, mload(sEnd))
                        sEnd := sub(sEnd, 32)
                        dEnd := sub(dEnd, 32)
                    }

                    // Write the first 32 bytes
                    mstore(dest, first)
                }
            }
        }
    }

    /// @dev Returns a slices from a byte array.
    /// @param b The byte array to take a slice from.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function slice(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                from,
                to
            ));
        }
        if (to > b.length) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
                to,
                b.length
            ));
        }

        // Create a new bytes structure and copy contents
        result = new bytes(to - from);
        memCopy(
            result.contentAddress(),
            b.contentAddress() + from,
            result.length
        );
        return result;
    }

    /// @dev Returns a slice from a byte array without preserving the input.
    /// @param b The byte array to take a slice from. Will be destroyed in the process.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    /// @dev When `from == 0`, the original array will match the slice. In other cases its state will be corrupted.
    function sliceDestructive(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                from,
                to
            ));
        }
        if (to > b.length) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
                to,
                b.length
            ));
        }

        // Create a new bytes structure around [from, to) in-place.
        assembly {
            result := add(b, from)
            mstore(result, sub(to, from))
        }
        return result;
    }

    /// @dev Pops the last byte off of a byte array by modifying its length.
    /// @param b Byte array that will be modified.
    /// @return The byte that was popped off.
    function popLastByte(bytes memory b)
        internal
        pure
        returns (bytes1 result)
    {
        if (b.length == 0) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanZeroRequired,
                b.length,
                0
            ));
        }

        // Store last byte.
        result = b[b.length - 1];

        assembly {
            // Decrement length of byte array.
            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }

    /// @dev Tests equality of two byte arrays.
    /// @param lhs First byte array to compare.
    /// @param rhs Second byte array to compare.
    /// @return True if arrays are the same. False otherwise.
    function equals(
        bytes memory lhs,
        bytes memory rhs
    )
        internal
        pure
        returns (bool equal)
    {
        // Keccak gas cost is 30 + numWords * 6. This is a cheap way to compare.
        // We early exit on unequal lengths, but keccak would also correctly
        // handle this.
        return lhs.length == rhs.length && keccak256(lhs) == keccak256(rhs);
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return address from byte array.
    function readAddress(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (address result)
    {
        if (b.length < index + 20) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
                b.length,
                index + 20 // 20 is length of address
            ));
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    /// @dev Writes an address into a specific position in a byte array.
    /// @param b Byte array to insert address into.
    /// @param index Index in byte array of address.
    /// @param input Address to put into byte array.
    function writeAddress(
        bytes memory b,
        uint256 index,
        address input
    )
        internal
        pure
    {
        if (b.length < index + 20) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
                b.length,
                index + 20 // 20 is length of address
            ));
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Store address into array memory
        assembly {
            // The address occupies 20 bytes and mstore stores 32 bytes.
            // First fetch the 32-byte word where we'll be storing the address, then
            // apply a mask so we have only the bytes in the word that the address will not occupy.
            // Then combine these bytes with the address and store the 32 bytes back to memory with mstore.

            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 12-byte mask to obtain extra bytes occupying word of memory where we'll store the address
            let neighbors := and(
                mload(add(b, index)),
                0xffffffffffffffffffffffff0000000000000000000000000000000000000000
            )

            // Make sure input address is clean.
            // (Solidity does not guarantee this)
            input := and(input, 0xffffffffffffffffffffffffffffffffffffffff)

            // Store the neighbors and address into memory
            mstore(add(b, index), xor(input, neighbors))
        }
    }

    /// @dev Reads a bytes32 value from a position in a byte array.
    /// @param b Byte array containing a bytes32 value.
    /// @param index Index in byte array of bytes32 value.
    /// @return bytes32 value from byte array.
    function readBytes32(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes32 result)
    {
        if (b.length < index + 32) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
                b.length,
                index + 32
            ));
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

    /// @dev Writes a bytes32 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input bytes32 to put into byte array.
    function writeBytes32(
        bytes memory b,
        uint256 index,
        bytes32 input
    )
        internal
        pure
    {
        if (b.length < index + 32) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
                b.length,
                index + 32
            ));
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            mstore(add(b, index), input)
        }
    }

    /// @dev Reads a uint256 value from a position in a byte array.
    /// @param b Byte array containing a uint256 value.
    /// @param index Index in byte array of uint256 value.
    /// @return uint256 value from byte array.
    function readUint256(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (uint256 result)
    {
        result = uint256(readBytes32(b, index));
        return result;
    }

    /// @dev Writes a uint256 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input uint256 to put into byte array.
    function writeUint256(
        bytes memory b,
        uint256 index,
        uint256 input
    )
        internal
        pure
    {
        writeBytes32(b, index, bytes32(input));
    }

    /// @dev Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return bytes4 value from byte array.
    function readBytes4(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes4 result)
    {
        if (b.length < index + 4) {
            LibRichErrors.rrevert(LibBytesRichErrors.InvalidByteOperationError(
                LibBytesRichErrors.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsFourRequired,
                b.length,
                index + 4
            ));
        }

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

    /// @dev Writes a new length to a byte array.
    ///      Decreasing length will lead to removing the corresponding lower order bytes from the byte array.
    ///      Increasing length may lead to appending adjacent in-memory bytes to the end of the byte array.
    /// @param b Bytes array to write new length to.
    /// @param length New length of byte array.
    function writeLength(bytes memory b, uint256 length)
        internal
        pure
    {
        assembly {
            mstore(b, length)
        }
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


library LibBytesRichErrors {

    enum InvalidByteOperationErrorCodes {
        FromLessThanOrEqualsToRequired,
        ToLessThanOrEqualsLengthRequired,
        LengthGreaterThanZeroRequired,
        LengthGreaterThanOrEqualsFourRequired,
        LengthGreaterThanOrEqualsTwentyRequired,
        LengthGreaterThanOrEqualsThirtyTwoRequired,
        LengthGreaterThanOrEqualsNestedBytesLengthRequired,
        DestinationLengthGreaterThanOrEqualSourceLengthRequired
    }

    // bytes4(keccak256("InvalidByteOperationError(uint8,uint256,uint256)"))
    bytes4 internal constant INVALID_BYTE_OPERATION_ERROR_SELECTOR =
        0x28006595;

    // solhint-disable func-name-mixedcase
    function InvalidByteOperationError(
        InvalidByteOperationErrorCodes errorCode,
        uint256 offset,
        uint256 required
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INVALID_BYTE_OPERATION_ERROR_SELECTOR,
            errorCode,
            offset,
            required
        );
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


library LibRichErrors {

    // bytes4(keccak256("Error(string)"))
    bytes4 internal constant STANDARD_ERROR_SELECTOR =
        0x08c379a0;

    // solhint-disable func-name-mixedcase
    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(
        string memory message
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            STANDARD_ERROR_SELECTOR,
            bytes(message)
        );
    }
    // solhint-enable func-name-mixedcase

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData)
        internal
        pure
    {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}

pragma solidity ^0.5.9;

import "./LibRichErrors.sol";
import "./LibSafeMathRichErrors.sol";


library LibSafeMath {

    function safeMul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        if (c / a != b) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function safeDiv(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b == 0) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.DIVISION_BY_ZERO,
                a,
                b
            ));
        }
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b > a) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                a,
                b
            ));
        }
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        if (c < a) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.ADDITION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function max256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}

pragma solidity ^0.5.9;


library LibSafeMathRichErrors {

    // bytes4(keccak256("Uint256BinOpError(uint8,uint256,uint256)"))
    bytes4 internal constant UINT256_BINOP_ERROR_SELECTOR =
        0xe946c1bb;

    // bytes4(keccak256("Uint256DowncastError(uint8,uint256)"))
    bytes4 internal constant UINT256_DOWNCAST_ERROR_SELECTOR =
        0xc996af7b;

    enum BinOpErrorCodes {
        ADDITION_OVERFLOW,
        MULTIPLICATION_OVERFLOW,
        SUBTRACTION_UNDERFLOW,
        DIVISION_BY_ZERO
    }

    enum DowncastErrorCodes {
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT32,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT64,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT96
    }

    // solhint-disable func-name-mixedcase
    function Uint256BinOpError(
        BinOpErrorCodes errorCode,
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_BINOP_ERROR_SELECTOR,
            errorCode,
            a,
            b
        );
    }

    function Uint256DowncastError(
        DowncastErrorCodes errorCode,
        uint256 a
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_DOWNCAST_ERROR_SELECTOR,
            errorCode,
            a
        );
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;


/// @title ERC-1155 Multi Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
/// Note: The ERC-165 identifier for this interface is 0xd9b67a26.
interface IERC1155 {

    /// @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred,
    ///      including zero value transfers as well as minting or burning.
    /// Operator will always be msg.sender.
    /// Either event from address `0x0` signifies a minting operation.
    /// An event to address `0x0` signifies a burning or melting operation.
    /// The total value transferred from address 0x0 minus the total value transferred to 0x0 may
    /// be used by clients and exchanges to be added to the "circulating supply" for a given token ID.
    /// To define a token ID with no initial balance, the contract SHOULD emit the TransferSingle event
    /// from `0x0` to `0x0`, with the token creator as `_operator`.
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /// @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred,
    ///      including zero value transfers as well as minting or burning.
    ///Operator will always be msg.sender.
    /// Either event from address `0x0` signifies a minting operation.
    /// An event to address `0x0` signifies a burning or melting operation.
    /// The total value transferred from address 0x0 minus the total value transferred to 0x0 may
    /// be used by clients and exchanges to be added to the "circulating supply" for a given token ID.
    /// To define multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event
    /// from `0x0` to `0x0`, with the token creator as `_operator`.
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /// @dev MUST emit when an approval is updated.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /// @dev MUST emit when the URI is updated for a token ID.
    /// URIs are defined in RFC 3986.
    /// The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata JSON Schema".
    event URI(
        string value,
        uint256 indexed id
    );

    /// @notice Transfers value amount of an _id from the _from address to the _to address specified.
    /// @dev MUST emit TransferSingle event on success.
    /// Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
    /// MUST throw if `_to` is the zero address.
    /// MUST throw if balance of sender for token `_id` is lower than the `_value` sent.
    /// MUST throw on any other error.
    /// When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0).
    /// If so, it MUST call `onERC1155Received` on `_to` and revert if the return value
    /// is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`.
    /// @param from    Source address
    /// @param to      Target address
    /// @param id      ID of the token type
    /// @param value   Transfer amount
    /// @param data    Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external;

    /// @notice Send multiple types of Tokens from a 3rd party in one transfer (with safety call).
    /// @dev MUST emit TransferBatch event on success.
    /// Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
    /// MUST throw if `_to` is the zero address.
    /// MUST throw if length of `_ids` is not the same as length of `_values`.
    ///  MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_values` sent.
    /// MUST throw on any other error.
    /// When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0).
    /// If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return value
    /// is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`.
    /// @param from    Source addresses
    /// @param to      Target addresses
    /// @param ids     IDs of each token type
    /// @param values  Transfer amounts per token type
    /// @param data    Additional data with no specified format, sent in call to `_to`
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external;

    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param operator  Address to add to the set of authorized operators
    /// @param approved  True if the operator is approved, false to revoke approval
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Queries the approval status of an operator for a given owner.
    /// @param owner     The owner of the Tokens
    /// @param operator  Address of authorized operator
    /// @return           True if the operator is approved, false if not
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @notice Get the balance of an account's Tokens.
    /// @param owner  The address of the token holder
    /// @param id     ID of the Token
    /// @return        The _owner's balance of the Token type requested
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /// @notice Get the balance of multiple account/token pairs
    /// @param owners The addresses of the token holders
    /// @param ids    ID of the Tokens
    /// @return        The _owner's balance of the Token types requested
    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    )
        external
        view
        returns (uint256[] memory balances_);
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/LibBytes.sol";
import "@0x/contracts-utils/contracts/src/LibSafeMath.sol";
import "@0x/contracts-utils/contracts/src/Authorizable.sol";
import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "./interfaces/IAssetProxy.sol";
import "./interfaces/IERC20Bridge.sol";


contract ERC20BridgeProxy is
    IAssetProxy,
    Authorizable
{
    using LibBytes for bytes;
    using LibSafeMath for uint256;

    // @dev Id of this proxy. Also the result of a successful bridge call.
    //      bytes4(keccak256("ERC20Bridge(address,address,bytes)"))
    bytes4 constant private PROXY_ID = 0xdc1600f3;

    /// @dev Calls a bridge contract to transfer `amount` of ERC20 from `from`
    ///      to `to`. Asserts that the balance of `to` has increased by `amount`.
    /// @param assetData Abi-encoded data for this asset proxy encoded as:
    ///          abi.encodeWithSelector(
    ///             bytes4 PROXY_ID,
    ///             address tokenAddress,
    ///             address bridgeAddress,
    ///             bytes bridgeData
    ///          )
    /// @param from Address to transfer asset from.
    /// @param to Address to transfer asset to.
    /// @param amount Amount of asset to transfer.
    function transferFrom(
        bytes calldata assetData,
        address from,
        address to,
        uint256 amount
    )
        external
        onlyAuthorized
    {
        // Extract asset data fields.
        (
            address tokenAddress,
            address bridgeAddress,
            bytes memory bridgeData
        ) = abi.decode(
            assetData.sliceDestructive(4, assetData.length),
            (address, address, bytes)
        );

        // Remember the balance of `to` before calling the bridge.
        uint256 balanceBefore = balanceOf(tokenAddress, to);
        // Call the bridge, who should transfer `amount` of `tokenAddress` to
        // `to`.
        bytes4 success = IERC20Bridge(bridgeAddress).bridgeTransferFrom(
            tokenAddress,
            from,
            to,
            amount,
            bridgeData
        );
        // Bridge must return the proxy ID to indicate success.
        require(success == PROXY_ID, "BRIDGE_FAILED");
        // Ensure that the balance of `to` has increased by at least `amount`.
        require(
            balanceBefore.safeAdd(amount) <= balanceOf(tokenAddress, to),
            "BRIDGE_UNDERPAY"
        );
    }

    /// @dev Gets the proxy id associated with this asset proxy.
    /// @return proxyId The proxy id.
    function getProxyId()
        external
        pure
        returns (bytes4 proxyId)
    {
        return PROXY_ID;
    }

    /// @dev Retrieves the balance of `owner` for this asset.
    /// @return balance The balance of the ERC20 token being transferred by this
    ///         asset proxy.
    function balanceOf(bytes calldata assetData, address owner)
        external
        view
        returns (uint256 balance)
    {
        (address tokenAddress) = abi.decode(
            assetData.sliceDestructive(4, assetData.length),
            (address)
        );
        return balanceOf(tokenAddress, owner);
    }

    /// @dev Retrieves the balance of `owner` given an ERC20 address.
    /// @return balance The balance of the ERC20 token for `owner`.
    function balanceOf(address tokenAddress, address owner)
        private
        view
        returns (uint256 balance)
    {
        return IERC20Token(tokenAddress).balanceOf(owner);
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "./interfaces/IAuthorizable.sol";
import "./LibAuthorizableRichErrors.sol";
import "./LibRichErrors.sol";
import "./Ownable.sol";


// solhint-disable no-empty-blocks
contract Authorizable is
    Ownable,
    IAuthorizable
{
    /// @dev Only authorized addresses can invoke functions with this modifier.
    modifier onlyAuthorized {
        _assertSenderIsAuthorized();
        _;
    }

    /// @dev Whether an adderss is authorized to call privileged functions.
    /// @param 0 Address to query.
    /// @return 0 Whether the address is authorized.
    mapping (address => bool) public authorized;
    /// @dev Whether an adderss is authorized to call privileged functions.
    /// @param 0 Index of authorized address.
    /// @return 0 Authorized address.
    address[] public authorities;

    /// @dev Initializes the `owner` address.
    constructor()
        public
        Ownable()
    {}

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function addAuthorizedAddress(address target)
        external
        onlyOwner
    {
        _addAuthorizedAddress(target);
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    function removeAuthorizedAddress(address target)
        external
        onlyOwner
    {
        if (!authorized[target]) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.TargetNotAuthorizedError(target));
        }
        for (uint256 i = 0; i < authorities.length; i++) {
            if (authorities[i] == target) {
                _removeAuthorizedAddressAtIndex(target, i);
                break;
            }
        }
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function removeAuthorizedAddressAtIndex(
        address target,
        uint256 index
    )
        external
        onlyOwner
    {
        _removeAuthorizedAddressAtIndex(target, index);
    }

    /// @dev Gets all authorized addresses.
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses()
        external
        view
        returns (address[] memory)
    {
        return authorities;
    }

    /// @dev Reverts if msg.sender is not authorized.
    function _assertSenderIsAuthorized()
        internal
        view
    {
        if (!authorized[msg.sender]) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.SenderNotAuthorizedError(msg.sender));
        }
    }

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function _addAuthorizedAddress(address target)
        internal
    {
        // Ensure that the target is not the zero address.
        if (target == address(0)) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.ZeroCantBeAuthorizedError());
        }

        // Ensure that the target is not already authorized.
        if (authorized[target]) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.TargetAlreadyAuthorizedError(target));
        }

        authorized[target] = true;
        authorities.push(target);
        emit AuthorizedAddressAdded(target, msg.sender);
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function _removeAuthorizedAddressAtIndex(
        address target,
        uint256 index
    )
        internal
    {
        if (!authorized[target]) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.TargetNotAuthorizedError(target));
        }
        if (index >= authorities.length) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.IndexOutOfBoundsError(
                index,
                authorities.length
            ));
        }
        if (authorities[index] != target) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.AuthorizedAddressMismatchError(
                authorities[index],
                target
            ));
        }

        delete authorized[target];
        authorities[index] = authorities[authorities.length - 1];
        authorities.length -= 1;
        emit AuthorizedAddressRemoved(target, msg.sender);
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "./IOwnable.sol";


contract IAuthorizable is
    IOwnable
{
    // Event logged when a new address is authorized.
    event AuthorizedAddressAdded(
        address indexed target,
        address indexed caller
    );

    // Event logged when a currently authorized address is unauthorized.
    event AuthorizedAddressRemoved(
        address indexed target,
        address indexed caller
    );

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function addAuthorizedAddress(address target)
        external;

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    function removeAuthorizedAddress(address target)
        external;

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function removeAuthorizedAddressAtIndex(
        address target,
        uint256 index
    )
        external;

    /// @dev Gets all authorized addresses.
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses()
        external
        view
        returns (address[] memory);
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


library LibAuthorizableRichErrors {

    // bytes4(keccak256("AuthorizedAddressMismatchError(address,address)"))
    bytes4 internal constant AUTHORIZED_ADDRESS_MISMATCH_ERROR_SELECTOR =
        0x140a84db;

    // bytes4(keccak256("IndexOutOfBoundsError(uint256,uint256)"))
    bytes4 internal constant INDEX_OUT_OF_BOUNDS_ERROR_SELECTOR =
        0xe9f83771;

    // bytes4(keccak256("SenderNotAuthorizedError(address)"))
    bytes4 internal constant SENDER_NOT_AUTHORIZED_ERROR_SELECTOR =
        0xb65a25b9;

    // bytes4(keccak256("TargetAlreadyAuthorizedError(address)"))
    bytes4 internal constant TARGET_ALREADY_AUTHORIZED_ERROR_SELECTOR =
        0xde16f1a0;

    // bytes4(keccak256("TargetNotAuthorizedError(address)"))
    bytes4 internal constant TARGET_NOT_AUTHORIZED_ERROR_SELECTOR =
        0xeb5108a2;

    // bytes4(keccak256("ZeroCantBeAuthorizedError()"))
    bytes internal constant ZERO_CANT_BE_AUTHORIZED_ERROR_BYTES =
        hex"57654fe4";

    // solhint-disable func-name-mixedcase
    function AuthorizedAddressMismatchError(
        address authorized,
        address target
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            AUTHORIZED_ADDRESS_MISMATCH_ERROR_SELECTOR,
            authorized,
            target
        );
    }

    function IndexOutOfBoundsError(
        uint256 index,
        uint256 length
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INDEX_OUT_OF_BOUNDS_ERROR_SELECTOR,
            index,
            length
        );
    }

    function SenderNotAuthorizedError(address sender)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            SENDER_NOT_AUTHORIZED_ERROR_SELECTOR,
            sender
        );
    }

    function TargetAlreadyAuthorizedError(address target)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            TARGET_ALREADY_AUTHORIZED_ERROR_SELECTOR,
            target
        );
    }

    function TargetNotAuthorizedError(address target)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            TARGET_NOT_AUTHORIZED_ERROR_SELECTOR,
            target
        );
    }

    function ZeroCantBeAuthorizedError()
        internal
        pure
        returns (bytes memory)
    {
        return ZERO_CANT_BE_AUTHORIZED_ERROR_BYTES;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "./interfaces/IOwnable.sol";
import "./LibOwnableRichErrors.sol";
import "./LibRichErrors.sol";


contract Ownable is
    IOwnable
{
    /// @dev The owner of this contract.
    /// @return 0 The owner address.
    address public owner;

    constructor ()
        public
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        _assertSenderIsOwner();
        _;
    }

    /// @dev Change the owner of this contract.
    /// @param newOwner New owner address.
    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        if (newOwner == address(0)) {
            LibRichErrors.rrevert(LibOwnableRichErrors.TransferOwnerToZeroError());
        } else {
            owner = newOwner;
            emit OwnershipTransferred(msg.sender, newOwner);
        }
    }

    function _assertSenderIsOwner()
        internal
        view
    {
        if (msg.sender != owner) {
            LibRichErrors.rrevert(LibOwnableRichErrors.OnlyOwnerError(
                msg.sender,
                owner
            ));
        }
    }
}

pragma solidity ^0.5.9;


library LibOwnableRichErrors {

    // bytes4(keccak256("OnlyOwnerError(address,address)"))
    bytes4 internal constant ONLY_OWNER_ERROR_SELECTOR =
        0x1de45ad1;

    // bytes4(keccak256("TransferOwnerToZeroError()"))
    bytes internal constant TRANSFER_OWNER_TO_ZERO_ERROR_BYTES =
        hex"e69edc3e";

    // solhint-disable func-name-mixedcase
    function OnlyOwnerError(
        address sender,
        address owner
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ONLY_OWNER_ERROR_SELECTOR,
            sender,
            owner
        );
    }

    function TransferOwnerToZeroError()
        internal
        pure
        returns (bytes memory)
    {
        return TRANSFER_OWNER_TO_ZERO_ERROR_BYTES;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


contract IERC20Token {

    // solhint-disable no-simple-event-func-name
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    /// @dev send `value` token to `to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return True if transfer was successful
    function transfer(address _to, uint256 _value)
        external
        returns (bool);

    /// @dev send `value` token to `to` from `from` on the condition it is approved by `from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return True if transfer was successful
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        returns (bool);

    /// @dev `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Always true if the call has enough gas to complete execution
    function approve(address _spender, uint256 _value)
        external
        returns (bool);

    /// @dev Query total supply of token
    /// @return Total supply of token
    function totalSupply()
        external
        view
        returns (uint256);

    /// @param _owner The address from which the balance will be retrieved
    /// @return Balance of owner
    function balanceOf(address _owner)
        external
        view
        returns (uint256);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


contract IERC20Bridge {

    /// @dev Result of a successful bridge call.
    bytes4 constant internal BRIDGE_SUCCESS = 0xdc1600f3;

    /// @dev Emitted when a trade occurs.
    /// @param inputToken The token the bridge is converting from.
    /// @param outputToken The token the bridge is converting to.
    /// @param inputTokenAmount Amount of input token.
    /// @param outputTokenAmount Amount of output token.
    /// @param from The `from` address in `bridgeTransferFrom()`
    /// @param to The `to` address in `bridgeTransferFrom()`
    event ERC20BridgeTransfer(
        address inputToken,
        address outputToken,
        uint256 inputTokenAmount,
        uint256 outputTokenAmount,
        address from,
        address to
    );

    /// @dev Transfers `amount` of the ERC20 `tokenAddress` from `from` to `to`.
    /// @param tokenAddress The address of the ERC20 token to transfer.
    /// @param from Address to transfer asset from.
    /// @param to Address to transfer asset to.
    /// @param amount Amount of asset to transfer.
    /// @param bridgeData Arbitrary asset data needed by the bridge contract.
    /// @return success The magic bytes `0xdc1600f3` if successful.
    function bridgeTransferFrom(
        address tokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success);
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "../archive/MixinAuthorizable.sol";


contract ERC20Proxy is
    MixinAuthorizable
{
    // Id of this proxy.
    bytes4 constant internal PROXY_ID = bytes4(keccak256("ERC20Token(address)"));

    // solhint-disable-next-line payable-fallback
    function ()
        external
    {
        assembly {
            // The first 4 bytes of calldata holds the function selector
            let selector := and(calldataload(0), 0xffffffff00000000000000000000000000000000000000000000000000000000)

            // `transferFrom` will be called with the following parameters:
            // assetData Encoded byte array.
            // from Address to transfer asset from.
            // to Address to transfer asset to.
            // amount Amount of asset to transfer.
            // bytes4(keccak256("transferFrom(bytes,address,address,uint256)")) = 0xa85e59e4
            if eq(selector, 0xa85e59e400000000000000000000000000000000000000000000000000000000) {

                // To lookup a value in a mapping, we load from the storage location keccak256(k, p),
                // where k is the key left padded to 32 bytes and p is the storage slot
                let start := mload(64)
                mstore(start, and(caller, 0xffffffffffffffffffffffffffffffffffffffff))
                mstore(add(start, 32), authorized_slot)

                // Revert if authorized[msg.sender] == false
                if iszero(sload(keccak256(start, 64))) {
                    // Revert with `Error("SENDER_NOT_AUTHORIZED")`
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x0000001553454e4445525f4e4f545f415554484f52495a454400000000000000)
                    mstore(96, 0)
                    revert(0, 100)
                }

                // `transferFrom`.
                // The function is marked `external`, so no abi decodeding is done for
                // us. Instead, we expect the `calldata` memory to contain the
                // following:
                //
                // | Area     | Offset | Length  | Contents                            |
                // |----------|--------|---------|-------------------------------------|
                // | Header   | 0      | 4       | function selector                   |
                // | Params   |        | 4 * 32  | function parameters:                |
                // |          | 4      |         |   1. offset to assetData (*)        |
                // |          | 36     |         |   2. from                           |
                // |          | 68     |         |   3. to                             |
                // |          | 100    |         |   4. amount                         |
                // | Data     |        |         | assetData:                          |
                // |          | 132    | 32      | assetData Length                    |
                // |          | 164    | **      | assetData Contents                  |
                //
                // (*): offset is computed from start of function parameters, so offset
                //      by an additional 4 bytes in the calldata.
                //
                // (**): see table below to compute length of assetData Contents
                //
                // WARNING: The ABIv2 specification allows additional padding between
                //          the Params and Data section. This will result in a larger
                //          offset to assetData.

                // Asset data itself is encoded as follows:
                //
                // | Area     | Offset | Length  | Contents                            |
                // |----------|--------|---------|-------------------------------------|
                // | Header   | 0      | 4       | function selector                   |
                // | Params   |        | 1 * 32  | function parameters:                |
                // |          | 4      | 12 + 20 |   1. token address                  |

                // We construct calldata for the `token.transferFrom` ABI.
                // The layout of this calldata is in the table below.
                //
                // | Area     | Offset | Length  | Contents                            |
                // |----------|--------|---------|-------------------------------------|
                // | Header   | 0      | 4       | function selector                   |
                // | Params   |        | 3 * 32  | function parameters:                |
                // |          | 4      |         |   1. from                           |
                // |          | 36     |         |   2. to                             |
                // |          | 68     |         |   3. amount                         |

                /////// Read token address from calldata ///////
                // * The token address is stored in `assetData`.
                //
                // * The "offset to assetData" is stored at offset 4 in the calldata (table 1).
                //   [assetDataOffsetFromParams = calldataload(4)]
                //
                // * Notes that the "offset to assetData" is relative to the "Params" area of calldata;
                //   add 4 bytes to account for the length of the "Header" area (table 1).
                //   [assetDataOffsetFromHeader = assetDataOffsetFromParams + 4]
                //
                // * The "token address" is offset 32+4=36 bytes into "assetData" (tables 1 & 2).
                //   [tokenOffset = assetDataOffsetFromHeader + 36 = calldataload(4) + 4 + 36]
                let token := calldataload(add(calldataload(4), 40))

                /////// Setup Header Area ///////
                // This area holds the 4-byte `transferFrom` selector.
                // Any trailing data in transferFromSelector will be
                // overwritten in the next `mstore` call.
                mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)

                /////// Setup Params Area ///////
                // We copy the fields `from`, `to` and `amount` in bulk
                // from our own calldata to the new calldata.
                calldatacopy(4, 36, 96)

                /////// Call `token.transferFrom` using the calldata ///////
                let success := call(
                    gas,            // forward all gas
                    token,          // call address of token contract
                    0,              // don't send any ETH
                    0,              // pointer to start of input
                    100,            // length of input
                    0,              // write output over input
                    32              // output size should be 32 bytes
                )

                /////// Check return data. ///////
                // If there is no return data, we assume the token incorrectly
                // does not return a bool. In this case we expect it to revert
                // on failure, which was handled above.
                // If the token does return data, we require that it is a single
                // nonzero 32 bytes value.
                // So the transfer succeeded if the call succeeded and either
                // returned nothing, or returned a non-zero 32 byte value.
                success := and(success, or(
                    iszero(returndatasize),
                    and(
                        eq(returndatasize, 32),
                        gt(mload(0), 0)
                    )
                ))
                if success {
                    return(0, 0)
                }

                // Revert with `Error("TRANSFER_FAILED")`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000f5452414e534645525f4641494c454400000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }

            // Revert if undefined function is called
            revert(0, 0)
        }
    }

    /// @dev Gets the proxy id associated with the proxy address.
    /// @return Proxy id.
    function getProxyId()
        external
        pure
        returns (bytes4)
    {
        return PROXY_ID;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "../archive/MixinAuthorizable.sol";


contract ERC721Proxy is
    MixinAuthorizable
{
    // Id of this proxy.
    bytes4 constant internal PROXY_ID = bytes4(keccak256("ERC721Token(address,uint256)"));

    // solhint-disable-next-line payable-fallback
    function ()
        external
    {
        assembly {
            // The first 4 bytes of calldata holds the function selector
            let selector := and(calldataload(0), 0xffffffff00000000000000000000000000000000000000000000000000000000)

            // `transferFrom` will be called with the following parameters:
            // assetData Encoded byte array.
            // from Address to transfer asset from.
            // to Address to transfer asset to.
            // amount Amount of asset to transfer.
            // bytes4(keccak256("transferFrom(bytes,address,address,uint256)")) = 0xa85e59e4
            if eq(selector, 0xa85e59e400000000000000000000000000000000000000000000000000000000) {

                // To lookup a value in a mapping, we load from the storage location keccak256(k, p),
                // where k is the key left padded to 32 bytes and p is the storage slot
                let start := mload(64)
                mstore(start, and(caller, 0xffffffffffffffffffffffffffffffffffffffff))
                mstore(add(start, 32), authorized_slot)

                // Revert if authorized[msg.sender] == false
                if iszero(sload(keccak256(start, 64))) {
                    // Revert with `Error("SENDER_NOT_AUTHORIZED")`
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x0000001553454e4445525f4e4f545f415554484f52495a454400000000000000)
                    mstore(96, 0)
                    revert(0, 100)
                }

                // `transferFrom`.
                // The function is marked `external`, so no abi decodeding is done for
                // us. Instead, we expect the `calldata` memory to contain the
                // following:
                //
                // | Area     | Offset | Length  | Contents                            |
                // |----------|--------|---------|-------------------------------------|
                // | Header   | 0      | 4       | function selector                   |
                // | Params   |        | 4 * 32  | function parameters:                |
                // |          | 4      |         |   1. offset to assetData (*)        |
                // |          | 36     |         |   2. from                           |
                // |          | 68     |         |   3. to                             |
                // |          | 100    |         |   4. amount                         |
                // | Data     |        |         | assetData:                          |
                // |          | 132    | 32      | assetData Length                    |
                // |          | 164    | **      | assetData Contents                  |
                //
                // (*): offset is computed from start of function parameters, so offset
                //      by an additional 4 bytes in the calldata.
                //
                // (**): see table below to compute length of assetData Contents
                //
                // WARNING: The ABIv2 specification allows additional padding between
                //          the Params and Data section. This will result in a larger
                //          offset to assetData.

                // Asset data itself is encoded as follows:
                //
                // | Area     | Offset | Length  | Contents                            |
                // |----------|--------|---------|-------------------------------------|
                // | Header   | 0      | 4       | function selector                   |
                // | Params   |        | 2 * 32  | function parameters:                |
                // |          | 4      | 12 + 20 |   1. token address                  |
                // |          | 36     |         |   2. tokenId                        |

                // We construct calldata for the `token.transferFrom` ABI.
                // The layout of this calldata is in the table below.
                //
                // | Area     | Offset | Length  | Contents                            |
                // |----------|--------|---------|-------------------------------------|
                // | Header   | 0      | 4       | function selector                   |
                // | Params   |        | 3 * 32  | function parameters:                |
                // |          | 4      |         |   1. from                           |
                // |          | 36     |         |   2. to                             |
                // |          | 68     |         |   3. tokenId                        |

                // There exists only 1 of each token.
                // require(amount == 1, "INVALID_AMOUNT")
                if sub(calldataload(100), 1) {
                    // Revert with `Error("INVALID_AMOUNT")`
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x0000000e494e56414c49445f414d4f554e540000000000000000000000000000)
                    mstore(96, 0)
                    revert(0, 100)
                }

                /////// Setup Header Area ///////
                // This area holds the 4-byte `transferFrom` selector.
                // Any trailing data in transferFromSelector will be
                // overwritten in the next `mstore` call.
                mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)

                /////// Setup Params Area ///////
                // We copy the fields `from` and `to` in bulk
                // from our own calldata to the new calldata.
                calldatacopy(4, 36, 64)

                // Copy `tokenId` field from our own calldata to the new calldata.
                let assetDataOffset := calldataload(4)
                calldatacopy(68, add(assetDataOffset, 72), 32)

                /////// Call `token.transferFrom` using the calldata ///////
                let token := calldataload(add(assetDataOffset, 40))
                let success := call(
                    gas,            // forward all gas
                    token,          // call address of token contract
                    0,              // don't send any ETH
                    0,              // pointer to start of input
                    100,            // length of input
                    0,              // write output to null
                    0               // output size is 0 bytes
                )
                if success {
                    return(0, 0)
                }

                // Revert with `Error("TRANSFER_FAILED")`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000f5452414e534645525f4641494c454400000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }

            // Revert if undefined function is called
            revert(0, 0)
        }
    }

    /// @dev Gets the proxy id associated with the proxy address.
    /// @return Proxy id.
    function getProxyId()
        external
        pure
        returns (bytes4)
    {
        return PROXY_ID;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "../archive/MixinAssetProxyDispatcher.sol";
import "../archive/MixinAuthorizable.sol";


contract MultiAssetProxy is
    MixinAssetProxyDispatcher,
    MixinAuthorizable
{
    // Id of this proxy.
    bytes4 constant internal PROXY_ID = bytes4(keccak256("MultiAsset(uint256[],bytes[])"));

    // solhint-disable-next-line payable-fallback
    function ()
        external
    {
        // NOTE: The below assembly assumes that clients do some input validation and that the input is properly encoded according to the AbiV2 specification.
        // It is technically possible for inputs with very large lengths and offsets to cause overflows. However, this would make the calldata prohibitively
        // expensive and we therefore do not check for overflows in these scenarios.
        assembly {
            // The first 4 bytes of calldata holds the function selector
            let selector := and(calldataload(0), 0xffffffff00000000000000000000000000000000000000000000000000000000)

            // `transferFrom` will be called with the following parameters:
            // assetData Encoded byte array.
            // from Address to transfer asset from.
            // to Address to transfer asset to.
            // amount Amount of asset to transfer.
            // bytes4(keccak256("transferFrom(bytes,address,address,uint256)")) = 0xa85e59e4
            if eq(selector, 0xa85e59e400000000000000000000000000000000000000000000000000000000) {

                // To lookup a value in a mapping, we load from the storage location keccak256(k, p),
                // where k is the key left padded to 32 bytes and p is the storage slot
                mstore(0, caller)
                mstore(32, authorized_slot)

                // Revert if authorized[msg.sender] == false
                if iszero(sload(keccak256(0, 64))) {
                    // Revert with `Error("SENDER_NOT_AUTHORIZED")`
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x0000001553454e4445525f4e4f545f415554484f52495a454400000000000000)
                    mstore(96, 0)
                    revert(0, 100)
                }

                // `transferFrom`.
                // The function is marked `external`, so no abi decoding is done for
                // us. Instead, we expect the `calldata` memory to contain the
                // following:
                //
                // | Area     | Offset | Length  | Contents                            |
                // |----------|--------|---------|-------------------------------------|
                // | Header   | 0      | 4       | function selector                   |
                // | Params   |        | 4 * 32  | function parameters:                |
                // |          | 4      |         |   1. offset to assetData (*)        |
                // |          | 36     |         |   2. from                           |
                // |          | 68     |         |   3. to                             |
                // |          | 100    |         |   4. amount                         |
                // | Data     |        |         | assetData:                          |
                // |          | 132    | 32      | assetData Length                    |
                // |          | 164    | **      | assetData Contents                  |
                //
                // (*): offset is computed from start of function parameters, so offset
                //      by an additional 4 bytes in the calldata.
                //
                // (**): see table below to compute length of assetData Contents
                //
                // WARNING: The ABIv2 specification allows additional padding between
                //          the Params and Data section. This will result in a larger
                //          offset to assetData.

                // Load offset to `assetData`
                let assetDataOffset := add(calldataload(4), 4)

                // Load length in bytes of `assetData`
                let assetDataLength := calldataload(assetDataOffset)

                // Asset data itself is encoded as follows:
                //
                // | Area     | Offset      | Length  | Contents                            |
                // |----------|-------------|---------|-------------------------------------|
                // | Header   | 0           | 4       | assetProxyId                        |
                // | Params   |             | 2 * 32  | function parameters:                |
                // |          | 4           |         |   1. offset to amounts (*)          |
                // |          | 36          |         |   2. offset to nestedAssetData (*)  |
                // | Data     |             |         | amounts:                            |
                // |          | 68          | 32      | amounts Length                      |
                // |          | 100         | a       | amounts Contents                    |
                // |          |             |         | nestedAssetData:                    |
                // |          | 100 + a     | 32      | nestedAssetData Length              |
                // |          | 132 + a     | b       | nestedAssetData Contents (offsets)  |
                // |          | 132 + a + b |         | nestedAssetData[0, ..., len]        |

                // Assert that the length of asset data:
                // 1. Must be at least 68 bytes (see table above)
                // 2. Must be a multiple of 32 (excluding the 4-byte selector)
                if or(lt(assetDataLength, 68), mod(sub(assetDataLength, 4), 32)) {
                    // Revert with `Error("INVALID_ASSET_DATA_LENGTH")`
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x00000019494e56414c49445f41535345545f444154415f4c454e475448000000)
                    mstore(96, 0)
                    revert(0, 100)
                }

                // End of asset data in calldata
                // assetDataOffset
                // + 32 (assetData len)
                let assetDataEnd := add(assetDataOffset, add(assetDataLength, 32))
                if gt(assetDataEnd, calldatasize()) {
                    // Revert with `Error("INVALID_ASSET_DATA_END")`
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x00000016494e56414c49445f41535345545f444154415f454e44000000000000)
                    mstore(96, 0)
                    revert(0, 100)
                }

                // In order to find the offset to `amounts`, we must add:
                // assetDataOffset
                // + 32 (assetData len)
                // + 4 (assetProxyId)
                let amountsOffset := calldataload(add(assetDataOffset, 36))

                // In order to find the offset to `nestedAssetData`, we must add:
                // assetDataOffset
                // + 32 (assetData len)
                // + 4 (assetProxyId)
                // + 32 (amounts offset)
                let nestedAssetDataOffset := calldataload(add(assetDataOffset, 68))

                // In order to find the start of the `amounts` contents, we must add:
                // assetDataOffset
                // + 32 (assetData len)
                // + 4 (assetProxyId)
                // + amountsOffset
                // + 32 (amounts len)
                let amountsContentsStart := add(assetDataOffset, add(amountsOffset, 68))

                // Load number of elements in `amounts`
                let amountsLen := calldataload(sub(amountsContentsStart, 32))

                // In order to find the start of the `nestedAssetData` contents, we must add:
                // assetDataOffset
                // + 32 (assetData len)
                // + 4 (assetProxyId)
                // + nestedAssetDataOffset
                // + 32 (nestedAssetData len)
                let nestedAssetDataContentsStart := add(assetDataOffset, add(nestedAssetDataOffset, 68))

                // Load number of elements in `nestedAssetData`
                let nestedAssetDataLen := calldataload(sub(nestedAssetDataContentsStart, 32))

                // Revert if number of elements in `amounts` differs from number of elements in `nestedAssetData`
                if sub(amountsLen, nestedAssetDataLen) {
                    // Revert with `Error("LENGTH_MISMATCH")`
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x0000000f4c454e4754485f4d49534d4154434800000000000000000000000000)
                    mstore(96, 0)
                    revert(0, 100)
                }

                // Copy `transferFrom` selector, offset to `assetData`, `from`, and `to` from calldata to memory
                calldatacopy(
                    0,   // memory can safely be overwritten from beginning
                    0,   // start of calldata
                    100  // length of selector (4) and 3 params (32 * 3)
                )

                // Overwrite existing offset to `assetData` with our own
                mstore(4, 128)

                // Load `amount`
                let amount := calldataload(100)

                // Calculate number of bytes in `amounts` contents
                let amountsByteLen := mul(amountsLen, 32)

                // Initialize `assetProxyId` and `assetProxy` to 0
                let assetProxyId := 0
                let assetProxy := 0

                // Loop through `amounts` and `nestedAssetData`, calling `transferFrom` for each respective element
                for {let i := 0} lt(i, amountsByteLen) {i := add(i, 32)} {

                    // Calculate the total amount
                    let amountsElement := calldataload(add(amountsContentsStart, i))
                    let totalAmount := mul(amountsElement, amount)

                    // Revert if `amount` != 0 and multiplication resulted in an overflow
                    if iszero(or(
                        iszero(amount),
                        eq(div(totalAmount, amount), amountsElement)
                    )) {
                        // Revert with `Error("UINT256_OVERFLOW")`
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                        mstore(64, 0x0000001055494e543235365f4f564552464c4f57000000000000000000000000)
                        mstore(96, 0)
                        revert(0, 100)
                    }

                    // Write `totalAmount` to memory
                    mstore(100, totalAmount)

                    // Load offset to `nestedAssetData[i]`
                    let nestedAssetDataElementOffset := calldataload(add(nestedAssetDataContentsStart, i))

                    // In order to find the start of the `nestedAssetData[i]` contents, we must add:
                    // assetDataOffset
                    // + 32 (assetData len)
                    // + 4 (assetProxyId)
                    // + nestedAssetDataOffset
                    // + 32 (nestedAssetData len)
                    // + nestedAssetDataElementOffset
                    // + 32 (nestedAssetDataElement len)
                    let nestedAssetDataElementContentsStart := add(
                        assetDataOffset,
                        add(
                            nestedAssetDataOffset,
                            add(nestedAssetDataElementOffset, 100)
                        )
                    )

                    // Load length of `nestedAssetData[i]`
                    let nestedAssetDataElementLenStart := sub(nestedAssetDataElementContentsStart, 32)
                    let nestedAssetDataElementLen := calldataload(nestedAssetDataElementLenStart)

                    // Revert if the `nestedAssetData` does not contain a 4 byte `assetProxyId`
                    if lt(nestedAssetDataElementLen, 4) {
                        // Revert with `Error("LENGTH_GREATER_THAN_3_REQUIRED")`
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                        mstore(64, 0x0000001e4c454e4754485f475245415445525f5448414e5f335f524551554952)
                        mstore(96, 0x4544000000000000000000000000000000000000000000000000000000000000)
                        revert(0, 100)
                    }

                    // Load AssetProxy id
                    let currentAssetProxyId := and(
                        calldataload(nestedAssetDataElementContentsStart),
                        0xffffffff00000000000000000000000000000000000000000000000000000000
                    )

                    // Only load `assetProxy` if `currentAssetProxyId` does not equal `assetProxyId`
                    // We do not need to check if `currentAssetProxyId` is 0 since `assetProxy` is also initialized to 0
                    if sub(currentAssetProxyId, assetProxyId) {
                        // Update `assetProxyId`
                        assetProxyId := currentAssetProxyId
                        // To lookup a value in a mapping, we load from the storage location keccak256(k, p),
                        // where k is the key left padded to 32 bytes and p is the storage slot
                        mstore(132, assetProxyId)
                        mstore(164, assetProxies_slot)
                        assetProxy := sload(keccak256(132, 64))
                    }

                    // Revert if AssetProxy with given id does not exist
                    if iszero(assetProxy) {
                        // Revert with `Error("ASSET_PROXY_DOES_NOT_EXIST")`
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                        mstore(64, 0x0000001a41535345545f50524f58595f444f45535f4e4f545f45584953540000)
                        mstore(96, 0)
                        revert(0, 100)
                    }

                    // Copy `nestedAssetData[i]` from calldata to memory
                    calldatacopy(
                        132,                                // memory slot after `amounts[i]`
                        nestedAssetDataElementLenStart,     // location of `nestedAssetData[i]` in calldata
                        add(nestedAssetDataElementLen, 32)  // `nestedAssetData[i].length` plus 32 byte length
                    )

                    // call `assetProxy.transferFrom`
                    let success := call(
                        gas,                                    // forward all gas
                        assetProxy,                             // call address of asset proxy
                        0,                                      // don't send any ETH
                        0,                                      // pointer to start of input
                        add(164, nestedAssetDataElementLen),    // length of input
                        0,                                      // write output over memory that won't be reused
                        0                                       // don't copy output to memory
                    )

                    // Revert with reason given by AssetProxy if `transferFrom` call failed
                    if iszero(success) {
                        returndatacopy(
                            0,                // copy to memory at 0
                            0,                // copy from return data at 0
                            returndatasize()  // copy all return data
                        )
                        revert(0, returndatasize())
                    }
                }

                // Return if no `transferFrom` calls reverted
                return(0, 0)
            }

            // Revert if undefined function is called
            revert(0, 0)
        }
    }

    /// @dev Gets the proxy id associated with the proxy address.
    /// @return Proxy id.
    function getProxyId()
        external
        pure
        returns (bytes4)
    {
        return PROXY_ID;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "@0x/contracts-utils/contracts/src/LibBytes.sol";


// solhint-disable no-unused-vars
contract StaticCallProxy {

    using LibBytes for bytes;

    // Id of this proxy.
    bytes4 constant internal PROXY_ID = bytes4(keccak256("StaticCall(address,bytes,bytes32)"));

    /// @dev Makes a staticcall to a target address and verifies that the data returned matches the expected return data.
    /// @param assetData Byte array encoded with staticCallTarget, staticCallData, and expectedCallResultHash
    /// @param from This value is ignored.
    /// @param to This value is ignored.
    /// @param amount This value is ignored.
    function transferFrom(
        bytes calldata assetData,
        address from,
        address to,
        uint256 amount
    )
        external
        view
    {
        // Decode params from `assetData`
        (
            address staticCallTarget,
            bytes memory staticCallData,
            bytes32 expectedReturnDataHash
        ) = abi.decode(
            assetData.sliceDestructive(4, assetData.length),
            (address, bytes, bytes32)
        );

        // Execute staticcall
        (bool success, bytes memory returnData) = staticCallTarget.staticcall(staticCallData);

        // Revert with returned data if staticcall is unsuccessful
        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }

        // Revert if hash of return data is not as expected
        bytes32 returnDataHash = keccak256(returnData);
        require(
            expectedReturnDataHash == returnDataHash,
            "UNEXPECTED_STATIC_CALL_RESULT"
        );
    }

    /// @dev Gets the proxy id associated with the proxy address.
    /// @return Proxy id.
    function getProxyId()
        external
        pure
        returns (bytes4)
    {
        return PROXY_ID;
    }
}

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-erc20/contracts/src/LibERC20Token.sol";
import "@0x/contracts-exchange-libs/contracts/src/IWallet.sol";
import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "../interfaces/IERC20Bridge.sol";
import "../interfaces/IBalancerPool.sol";


contract BalancerBridge is
    IERC20Bridge,
    IWallet,
    DeploymentConstants
{
    /// @dev Callback for `IERC20Bridge`. Tries to buy `amount` of
    ///      `toTokenAddress` tokens by selling the entirety of the `fromTokenAddress`
    ///      token encoded in the bridge data, then transfers the bought
    ///      tokens to `to`.
    /// @param toTokenAddress The token to buy and transfer to `to`.
    /// @param from The maker (this contract).
    /// @param to The recipient of the bought tokens.
    /// @param amount Minimum amount of `toTokenAddress` tokens to buy.
    /// @param bridgeData The abi-encoded addresses of the "from" token and Balancer pool.
    /// @return success The magic bytes if successful.
    function bridgeTransferFrom(
        address toTokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success)
    {
        // Decode the bridge data.
        (address fromTokenAddress, address poolAddress) = abi.decode(
            bridgeData,
            (address, address)
        );
        require(toTokenAddress != fromTokenAddress, "BalancerBridge/INVALID_PAIR");

        uint256 fromTokenBalance = IERC20Token(fromTokenAddress).balanceOf(address(this));
        // Grant an allowance to the exchange to spend `fromTokenAddress` token.
        LibERC20Token.approveIfBelow(fromTokenAddress, poolAddress, fromTokenBalance);

        // Sell all of this contract's `fromTokenAddress` token balance.
        (uint256 boughtAmount,) = IBalancerPool(poolAddress).swapExactAmountIn(
            fromTokenAddress, // tokenIn
            fromTokenBalance, // tokenAmountIn
            toTokenAddress,   // tokenOut
            amount,           // minAmountOut
            uint256(-1)       // maxPrice
        );

        // Transfer the converted `toToken`s to `to`.
        LibERC20Token.transfer(toTokenAddress, to, boughtAmount);

        emit ERC20BridgeTransfer(
            fromTokenAddress,
            toTokenAddress,
            fromTokenBalance,
            boughtAmount,
            from,
            to
        );
        return BRIDGE_SUCCESS;
    }

    /// @dev `SignatureType.Wallet` callback, so that this bridge can be the maker
    ///      and sign for itself in orders. Always succeeds.
    /// @return magicValue Magic success bytes, always.
    function isValidSignature(
        bytes32,
        bytes calldata
    )
        external
        view
        returns (bytes4 magicValue)
    {
        return LEGACY_WALLET_MAGIC_VALUE;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "@0x/contracts-utils/contracts/src/LibRichErrors.sol";
import "@0x/contracts-utils/contracts/src/LibBytes.sol";
import "../src/interfaces/IERC20Token.sol";


library LibERC20Token {
    bytes constant private DECIMALS_CALL_DATA = hex"313ce567";

    /// @dev Calls `IERC20Token(token).approve()`.
    ///      Reverts if `false` is returned or if the return
    ///      data length is nonzero and not 32 bytes.
    /// @param token The address of the token contract.
    /// @param spender The address that receives an allowance.
    /// @param allowance The allowance to set.
    function approve(
        address token,
        address spender,
        uint256 allowance
    )
        internal
    {
        bytes memory callData = abi.encodeWithSelector(
            IERC20Token(0).approve.selector,
            spender,
            allowance
        );
        _callWithOptionalBooleanResult(token, callData);
    }

    /// @dev Calls `IERC20Token(token).approve()` and sets the allowance to the
    ///      maximum if the current approval is not already >= an amount.
    ///      Reverts if `false` is returned or if the return
    ///      data length is nonzero and not 32 bytes.
    /// @param token The address of the token contract.
    /// @param spender The address that receives an allowance.
    /// @param amount The minimum allowance needed.
    function approveIfBelow(
        address token,
        address spender,
        uint256 amount
    )
        internal
    {
        if (IERC20Token(token).allowance(address(this), spender) < amount) {
            approve(token, spender, uint256(-1));
        }
    }

    /// @dev Calls `IERC20Token(token).transfer()`.
    ///      Reverts if `false` is returned or if the return
    ///      data length is nonzero and not 32 bytes.
    /// @param token The address of the token contract.
    /// @param to The address that receives the tokens
    /// @param amount Number of tokens to transfer.
    function transfer(
        address token,
        address to,
        uint256 amount
    )
        internal
    {
        bytes memory callData = abi.encodeWithSelector(
            IERC20Token(0).transfer.selector,
            to,
            amount
        );
        _callWithOptionalBooleanResult(token, callData);
    }

    /// @dev Calls `IERC20Token(token).transferFrom()`.
    ///      Reverts if `false` is returned or if the return
    ///      data length is nonzero and not 32 bytes.
    /// @param token The address of the token contract.
    /// @param from The owner of the tokens.
    /// @param to The address that receives the tokens
    /// @param amount Number of tokens to transfer.
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        bytes memory callData = abi.encodeWithSelector(
            IERC20Token(0).transferFrom.selector,
            from,
            to,
            amount
        );
        _callWithOptionalBooleanResult(token, callData);
    }

    /// @dev Retrieves the number of decimals for a token.
    ///      Returns `18` if the call reverts.
    /// @param token The address of the token contract.
    /// @return tokenDecimals The number of decimals places for the token.
    function decimals(address token)
        internal
        view
        returns (uint8 tokenDecimals)
    {
        tokenDecimals = 18;
        (bool didSucceed, bytes memory resultData) = token.staticcall(DECIMALS_CALL_DATA);
        if (didSucceed && resultData.length == 32) {
            tokenDecimals = uint8(LibBytes.readUint256(resultData, 0));
        }
    }

    /// @dev Retrieves the allowance for a token, owner, and spender.
    ///      Returns `0` if the call reverts.
    /// @param token The address of the token contract.
    /// @param owner The owner of the tokens.
    /// @param spender The address the spender.
    /// @return allowance The allowance for a token, owner, and spender.
    function allowance(address token, address owner, address spender)
        internal
        view
        returns (uint256 allowance_)
    {
        (bool didSucceed, bytes memory resultData) = token.staticcall(
            abi.encodeWithSelector(
                IERC20Token(0).allowance.selector,
                owner,
                spender
            )
        );
        if (didSucceed && resultData.length == 32) {
            allowance_ = LibBytes.readUint256(resultData, 0);
        }
    }

    /// @dev Retrieves the balance for a token owner.
    ///      Returns `0` if the call reverts.
    /// @param token The address of the token contract.
    /// @param owner The owner of the tokens.
    /// @return balance The token balance of an owner.
    function balanceOf(address token, address owner)
        internal
        view
        returns (uint256 balance)
    {
        (bool didSucceed, bytes memory resultData) = token.staticcall(
            abi.encodeWithSelector(
                IERC20Token(0).balanceOf.selector,
                owner
            )
        );
        if (didSucceed && resultData.length == 32) {
            balance = LibBytes.readUint256(resultData, 0);
        }
    }

    /// @dev Executes a call on address `target` with calldata `callData`
    ///      and asserts that either nothing was returned or a single boolean
    ///      was returned equal to `true`.
    /// @param target The call target.
    /// @param callData The abi-encoded call data.
    function _callWithOptionalBooleanResult(
        address target,
        bytes memory callData
    )
        private
    {
        (bool didSucceed, bytes memory resultData) = target.call(callData);
        if (didSucceed) {
            if (resultData.length == 0) {
                return;
            }
            if (resultData.length == 32) {
                uint256 result = LibBytes.readUint256(resultData, 0);
                if (result == 1) {
                    return;
                }
            }
        }
        LibRichErrors.rrevert(resultData);
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;


contract IWallet {

    bytes4 internal constant LEGACY_WALLET_MAGIC_VALUE = 0xb0671381;

    /// @dev Validates a hash with the `Wallet` signature type.
    /// @param hash Message hash that is signed.
    /// @param signature Proof of signing.
    /// @return magicValue `bytes4(0xb0671381)` if the signature check succeeds.
    function isValidSignature(
        bytes32 hash,
        bytes calldata signature
    )
        external
        view
        returns (bytes4 magicValue);
}

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


contract DeploymentConstants {

    // solhint-disable separate-by-one-line-in-contract

    // Mainnet addresses ///////////////////////////////////////////////////////
    /// @dev Mainnet address of the WETH contract.
    address constant private WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    /// @dev Mainnet address of the KyberNetworkProxy contract.
    address constant private KYBER_NETWORK_PROXY_ADDRESS = 0x9AAb3f75489902f3a48495025729a0AF77d4b11e;
    /// @dev Mainnet address of the KyberHintHandler contract.
    address constant private KYBER_HINT_HANDLER_ADDRESS = 0xa1C0Fa73c39CFBcC11ec9Eb1Afc665aba9996E2C;
    /// @dev Mainnet address of the `UniswapExchangeFactory` contract.
    address constant private UNISWAP_EXCHANGE_FACTORY_ADDRESS = 0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95;
    /// @dev Mainnet address of the `UniswapV2Router01` contract.
    address constant private UNISWAP_V2_ROUTER_01_ADDRESS = 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a;
    /// @dev Mainnet address of the Eth2Dai `MatchingMarket` contract.
    address constant private ETH2DAI_ADDRESS = 0x794e6e91555438aFc3ccF1c5076A74F42133d08D;
    /// @dev Mainnet address of the `ERC20BridgeProxy` contract
    address constant private ERC20_BRIDGE_PROXY_ADDRESS = 0x8ED95d1746bf1E4dAb58d8ED4724f1Ef95B20Db0;
    ///@dev Mainnet address of the `Dai` (multi-collateral) contract
    address constant private DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    /// @dev Mainnet address of the `Chai` contract
    address constant private CHAI_ADDRESS = 0x06AF07097C9Eeb7fD685c692751D5C66dB49c215;
    /// @dev Mainnet address of the 0x DevUtils contract.
    address constant private DEV_UTILS_ADDRESS = 0x74134CF88b21383713E096a5ecF59e297dc7f547;
    /// @dev Kyber ETH pseudo-address.
    address constant internal KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev Mainnet address of the dYdX contract.
    address constant private DYDX_ADDRESS = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    /// @dev Mainnet address of the GST2 contract
    address constant private GST_ADDRESS = 0x0000000000b3F879cb30FE243b4Dfee438691c04;
    /// @dev Mainnet address of the GST Collector
    address constant private GST_COLLECTOR_ADDRESS = 0x000000D3b08566BE75A6DB803C03C85C0c1c5B96;
    /// @dev Mainnet address of the mStable mUSD contract.
    address constant private MUSD_ADDRESS = 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5;
    /// @dev Mainnet address of the Mooniswap Registry contract
    address constant private MOONISWAP_REGISTRY = 0x71CD6666064C3A1354a3B4dca5fA1E2D3ee7D303;
    /// @dev Mainnet address of the DODO Registry (ZOO) contract
    address constant private DODO_REGISTRY = 0x3A97247DF274a17C59A3bd12735ea3FcDFb49950;
    /// @dev Mainnet address of the DODO Helper contract
    address constant private DODO_HELPER = 0x533dA777aeDCE766CEAe696bf90f8541A4bA80Eb;

    // // Ropsten addresses ///////////////////////////////////////////////////////
    // /// @dev Mainnet address of the WETH contract.
    // address constant private WETH_ADDRESS = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    // /// @dev Mainnet address of the KyberNetworkProxy contract.
    // address constant private KYBER_NETWORK_PROXY_ADDRESS = 0xd719c34261e099Fdb33030ac8909d5788D3039C4;
    // /// @dev Mainnet address of the `UniswapExchangeFactory` contract.
    // address constant private UNISWAP_EXCHANGE_FACTORY_ADDRESS = 0x9c83dCE8CA20E9aAF9D3efc003b2ea62aBC08351;
    // /// @dev Mainnet address of the `UniswapV2Router01` contract.
    // address constant private UNISWAP_V2_ROUTER_01_ADDRESS = 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a;
    // /// @dev Mainnet address of the Eth2Dai `MatchingMarket` contract.
    // address constant private ETH2DAI_ADDRESS = address(0);
    // /// @dev Mainnet address of the `ERC20BridgeProxy` contract
    // address constant private ERC20_BRIDGE_PROXY_ADDRESS = 0xb344afeD348de15eb4a9e180205A2B0739628339;
    // ///@dev Mainnet address of the `Dai` (multi-collateral) contract
    // address constant private DAI_ADDRESS = address(0);
    // /// @dev Mainnet address of the `Chai` contract
    // address constant private CHAI_ADDRESS = address(0);
    // /// @dev Mainnet address of the 0x DevUtils contract.
    // address constant private DEV_UTILS_ADDRESS = 0xC812AF3f3fBC62F76ea4262576EC0f49dB8B7f1c;
    // /// @dev Kyber ETH pseudo-address.
    // address constant internal KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // /// @dev Mainnet address of the dYdX contract.
    // address constant private DYDX_ADDRESS = address(0);
    // /// @dev Mainnet address of the GST2 contract
    // address constant private GST_ADDRESS = address(0);
    // /// @dev Mainnet address of the GST Collector
    // address constant private GST_COLLECTOR_ADDRESS = address(0);
    // /// @dev Mainnet address of the mStable mUSD contract.
    // address constant private MUSD_ADDRESS = 0x4E1000616990D83e56f4b5fC6CC8602DcfD20459;

    // // Rinkeby addresses ///////////////////////////////////////////////////////
    // /// @dev Mainnet address of the WETH contract.
    // address constant private WETH_ADDRESS = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    // /// @dev Mainnet address of the KyberNetworkProxy contract.
    // address constant private KYBER_NETWORK_PROXY_ADDRESS = 0x0d5371e5EE23dec7DF251A8957279629aa79E9C5;
    // /// @dev Mainnet address of the `UniswapExchangeFactory` contract.
    // address constant private UNISWAP_EXCHANGE_FACTORY_ADDRESS = 0xf5D915570BC477f9B8D6C0E980aA81757A3AaC36;
    // /// @dev Mainnet address of the `UniswapV2Router01` contract.
    // address constant private UNISWAP_V2_ROUTER_01_ADDRESS = 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a;
    // /// @dev Mainnet address of the Eth2Dai `MatchingMarket` contract.
    // address constant private ETH2DAI_ADDRESS = address(0);
    // /// @dev Mainnet address of the `ERC20BridgeProxy` contract
    // address constant private ERC20_BRIDGE_PROXY_ADDRESS = 0xA2AA4bEFED748Fba27a3bE7Dfd2C4b2c6DB1F49B;
    // ///@dev Mainnet address of the `Dai` (multi-collateral) contract
    // address constant private DAI_ADDRESS = address(0);
    // /// @dev Mainnet address of the `Chai` contract
    // address constant private CHAI_ADDRESS = address(0);
    // /// @dev Mainnet address of the 0x DevUtils contract.
    // address constant private DEV_UTILS_ADDRESS = 0x46B5BC959e8A754c0256FFF73bF34A52Ad5CdfA9;
    // /// @dev Kyber ETH pseudo-address.
    // address constant internal KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // /// @dev Mainnet address of the dYdX contract.
    // address constant private DYDX_ADDRESS = address(0);
    // /// @dev Mainnet address of the GST2 contract
    // address constant private GST_ADDRESS = address(0);
    // /// @dev Mainnet address of the GST Collector
    // address constant private GST_COLLECTOR_ADDRESS = address(0);
    // /// @dev Mainnet address of the mStable mUSD contract.
    // address constant private MUSD_ADDRESS = address(0);

    // // Kovan addresses /////////////////////////////////////////////////////////
    // /// @dev Kovan address of the WETH contract.
    // address constant private WETH_ADDRESS = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    // /// @dev Kovan address of the KyberNetworkProxy contract.
    // address constant private KYBER_NETWORK_PROXY_ADDRESS = 0x692f391bCc85cefCe8C237C01e1f636BbD70EA4D;
    // /// @dev Kovan address of the `UniswapExchangeFactory` contract.
    // address constant private UNISWAP_EXCHANGE_FACTORY_ADDRESS = 0xD3E51Ef092B2845f10401a0159B2B96e8B6c3D30;
    // /// @dev Kovan address of the `UniswapV2Router01` contract.
    // address constant private UNISWAP_V2_ROUTER_01_ADDRESS = 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a;
    // /// @dev Kovan address of the Eth2Dai `MatchingMarket` contract.
    // address constant private ETH2DAI_ADDRESS = 0xe325acB9765b02b8b418199bf9650972299235F4;
    // /// @dev Kovan address of the `ERC20BridgeProxy` contract
    // address constant private ERC20_BRIDGE_PROXY_ADDRESS = 0x3577552C1Fb7A44aD76BeEB7aB53251668A21F8D;
    // /// @dev Kovan address of the `Chai` contract
    // address constant private CHAI_ADDRESS = address(0);
    // /// @dev Kovan address of the `Dai` (multi-collateral) contract
    // address constant private DAI_ADDRESS = 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa;
    // /// @dev Kovan address of the 0x DevUtils contract.
    // address constant private DEV_UTILS_ADDRESS = 0x9402639A828BdF4E9e4103ac3B69E1a6E522eB59;
    // /// @dev Kyber ETH pseudo-address.
    // address constant internal KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // /// @dev Kovan address of the dYdX contract.
    // address constant private DYDX_ADDRESS = address(0);
    // /// @dev Kovan address of the GST2 contract
    // address constant private GST_ADDRESS = address(0);
    // /// @dev Kovan address of the GST Collector
    // address constant private GST_COLLECTOR_ADDRESS = address(0);
    // /// @dev Mainnet address of the mStable mUSD contract.
    // address constant private MUSD_ADDRESS = address(0);

    /// @dev Overridable way to get the `KyberNetworkProxy` address.
    /// @return kyberAddress The `IKyberNetworkProxy` address.
    function _getKyberNetworkProxyAddress()
        internal
        view
        returns (address kyberAddress)
    {
        return KYBER_NETWORK_PROXY_ADDRESS;
    }

    /// @dev Overridable way to get the `KyberHintHandler` address.
    /// @return kyberAddress The `IKyberHintHandler` address.
    function _getKyberHintHandlerAddress()
        internal
        view
        returns (address hintHandlerAddress)
    {
        return KYBER_HINT_HANDLER_ADDRESS;
    }

    /// @dev Overridable way to get the WETH address.
    /// @return wethAddress The WETH address.
    function _getWethAddress()
        internal
        view
        returns (address wethAddress)
    {
        return WETH_ADDRESS;
    }

    /// @dev Overridable way to get the `UniswapExchangeFactory` address.
    /// @return uniswapAddress The `UniswapExchangeFactory` address.
    function _getUniswapExchangeFactoryAddress()
        internal
        view
        returns (address uniswapAddress)
    {
        return UNISWAP_EXCHANGE_FACTORY_ADDRESS;
    }

    /// @dev Overridable way to get the `UniswapV2Router01` address.
    /// @return uniswapRouterAddress The `UniswapV2Router01` address.
    function _getUniswapV2Router01Address()
        internal
        view
        returns (address uniswapRouterAddress)
    {
        return UNISWAP_V2_ROUTER_01_ADDRESS;
    }

    /// @dev An overridable way to retrieve the Eth2Dai `MatchingMarket` contract.
    /// @return eth2daiAddress The Eth2Dai `MatchingMarket` contract.
    function _getEth2DaiAddress()
        internal
        view
        returns (address eth2daiAddress)
    {
        return ETH2DAI_ADDRESS;
    }

    /// @dev An overridable way to retrieve the `ERC20BridgeProxy` contract.
    /// @return erc20BridgeProxyAddress The `ERC20BridgeProxy` contract.
    function _getERC20BridgeProxyAddress()
        internal
        view
        returns (address erc20BridgeProxyAddress)
    {
        return ERC20_BRIDGE_PROXY_ADDRESS;
    }

    /// @dev An overridable way to retrieve the `Dai` contract.
    /// @return daiAddress The `Dai` contract.
    function _getDaiAddress()
        internal
        view
        returns (address daiAddress)
    {
        return DAI_ADDRESS;
    }

    /// @dev An overridable way to retrieve the `Chai` contract.
    /// @return chaiAddress The `Chai` contract.
    function _getChaiAddress()
        internal
        view
        returns (address chaiAddress)
    {
        return CHAI_ADDRESS;
    }

    /// @dev An overridable way to retrieve the 0x `DevUtils` contract address.
    /// @return devUtils The 0x `DevUtils` contract address.
    function _getDevUtilsAddress()
        internal
        view
        returns (address devUtils)
    {
        return DEV_UTILS_ADDRESS;
    }

    /// @dev Overridable way to get the DyDx contract.
    /// @return exchange The DyDx exchange contract.
    function _getDydxAddress()
        internal
        view
        returns (address dydxAddress)
    {
        return DYDX_ADDRESS;
    }

    /// @dev An overridable way to retrieve the GST2 contract address.
    /// @return gst The GST contract.
    function _getGstAddress()
        internal
        view
        returns (address gst)
    {
        return GST_ADDRESS;
    }

    /// @dev An overridable way to retrieve the GST Collector address.
    /// @return collector The GST collector address.
    function _getGstCollectorAddress()
        internal
        view
        returns (address collector)
    {
        return GST_COLLECTOR_ADDRESS;
    }

    /// @dev An overridable way to retrieve the mStable mUSD address.
    /// @return musd The mStable mUSD address.
    function _getMUsdAddress()
        internal
        view
        returns (address musd)
    {
        return MUSD_ADDRESS;
    }

    /// @dev An overridable way to retrieve the Mooniswap registry address.
    /// @return registry The Mooniswap registry address.
    function _getMooniswapAddress()
        internal
        view
        returns (address)
    {
        return MOONISWAP_REGISTRY;
    }

    /// @dev An overridable way to retrieve the DODO Registry contract address.
    /// @return registry The DODO Registry contract address.
    function _getDODORegistryAddress()
        internal
        view
        returns (address)
    {
        return DODO_REGISTRY;
    }

    /// @dev An overridable way to retrieve the DODO Helper contract address.
    /// @return registry The DODO Helper contract address.
    function _getDODOHelperAddress()
        internal
        view
        returns (address)
    {
        return DODO_HELPER;
    }
}

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


interface IBalancerPool {
    /// @dev Sell `tokenAmountIn` of `tokenIn` and receive `tokenOut`.
    /// @param tokenIn The token being sold
    /// @param tokenAmountIn The amount of `tokenIn` to sell.
    /// @param tokenOut The token being bought.
    /// @param minAmountOut The minimum amount of `tokenOut` to buy.
    /// @param maxPrice The maximum value for `spotPriceAfter`.
    /// @return tokenAmountOut The amount of `tokenOut` bought.
    /// @return spotPriceAfter The new marginal spot price of the given
    ///         token pair for this pool.
    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    ) external returns (uint tokenAmountOut, uint spotPriceAfter);
}

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-erc20/contracts/src/interfaces/IEtherToken.sol";
import "@0x/contracts-erc20/contracts/src/LibERC20Token.sol";
import "@0x/contracts-exchange-libs/contracts/src/IWallet.sol";
import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "../interfaces/IERC20Bridge.sol";
import "../interfaces/IBancorNetwork.sol";


contract BancorBridge is
    IERC20Bridge,
    IWallet,
    DeploymentConstants
{
    struct TransferState {
        address bancorNetworkAddress;
        address[] path;
        IEtherToken weth;
    }

    /// @dev Bancor ETH pseudo-address.
    address constant public BANCOR_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // solhint-disable no-empty-blocks
    /// @dev Payable fallback to receive ETH from Bancor/WETH.
    function ()
        external
        payable
    {
        // Poor man's receive in 0.5.9
        require(msg.data.length == 0);
    }

    /// @dev Callback for `IERC20Bridge`. Tries to buy `amount` of
    ///      `toTokenAddress` tokens by selling the entirety of the `fromTokenAddress`
    ///      token encoded in the bridge data, then transfers the bought
    ///      tokens to `to`.
    /// @param toTokenAddress The token to buy and transfer to `to`.
    /// @param from The maker (this contract).
    /// @param to The recipient of the bought tokens.
    /// @param amount Minimum amount of `toTokenAddress` tokens to buy.
    /// @param bridgeData The abi-encoded conversion path addresses and Bancor network address
    /// @return success The magic bytes if successful.
    function bridgeTransferFrom(
        address toTokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success)
    {
        // hold variables to get around stack depth limitations
        TransferState memory state;
        // Decode the bridge data.
        (
            state.path,
            state.bancorNetworkAddress
        // solhint-disable indent
        ) = abi.decode(bridgeData, (address[], address));
        // solhint-enable indent
        state.weth = IEtherToken(_getWethAddress());

        require(state.path.length >= 2, "BancorBridge/PATH_LENGTH_MUST_BE_GREATER_THAN_TWO");

        // Grant an allowance to the Bancor Network to spend `fromTokenAddress` token.
        uint256 fromTokenBalance;
        uint256 payableAmount = 0;
        // If it's ETH in the path then withdraw from WETH
        // The Bancor path will have ETH as the 0xeee address
        // Bancor expects to be paid in ETH not WETH
        if (state.path[0] == BANCOR_ETH_ADDRESS) {
            fromTokenBalance = state.weth.balanceOf(address(this));
            state.weth.withdraw(fromTokenBalance);
            payableAmount = fromTokenBalance;
        } else {
            fromTokenBalance = IERC20Token(state.path[0]).balanceOf(address(this));
            LibERC20Token.approveIfBelow(state.path[0], state.bancorNetworkAddress, fromTokenBalance);
        }

        // Convert the tokens
        uint256 boughtAmount = IBancorNetwork(state.bancorNetworkAddress).convertByPath.value(payableAmount)(
            state.path, // path originating with source token and terminating in destination token
            fromTokenBalance, // amount of source token to trade
            amount, // minimum amount of destination token expected to receive
            state.path[state.path.length-1] == BANCOR_ETH_ADDRESS ? address(this) : to, // beneficiary
            address(0), // affiliateAccount; no fee paid
            0 // affiliateFee; no fee paid
        );

        if (state.path[state.path.length-1] == BANCOR_ETH_ADDRESS) {
            state.weth.deposit.value(boughtAmount)();
            state.weth.transfer(to, boughtAmount);
        }

        emit ERC20BridgeTransfer(
            state.path[0] == BANCOR_ETH_ADDRESS ? address(state.weth) : state.path[0],
            toTokenAddress,
            fromTokenBalance,
            boughtAmount,
            from,
            to
        );
        return BRIDGE_SUCCESS;
    }

    /// @dev `SignatureType.Wallet` callback, so that this bridge can be the maker
    ///      and sign for itself in orders. Always succeeds.
    /// @return magicValue Magic success bytes, always.
    function isValidSignature(
        bytes32,
        bytes calldata
    )
        external
        view
        returns (bytes4 magicValue)
    {
        return LEGACY_WALLET_MAGIC_VALUE;
    }

}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "./IERC20Token.sol";


contract IEtherToken is
    IERC20Token
{
    function deposit()
        public
        payable;
    
    function withdraw(uint256 amount)
        public;
}

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


contract IContractRegistry {
    function addressOf(
        bytes32 contractName
    ) external returns(address);
}


contract IBancorNetwork {
    function convertByPath(
        address[] calldata _path,
        uint256 _amount,
        uint256 _minReturn,
        address _beneficiary,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) external payable returns (uint256);
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../interfaces/IERC20Bridge.sol";
import "../interfaces/IChai.sol";
import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";


// solhint-disable space-after-comma
contract ChaiBridge is
    IERC20Bridge,
    DeploymentConstants
{
    /// @dev Withdraws `amount` of `from` address's Dai from the Chai contract.
    ///      Transfers `amount` of Dai to `to` address.
    /// @param from Address to transfer asset from.
    /// @param to Address to transfer asset to.
    /// @param amount Amount of asset to transfer.
    /// @return success The magic bytes `0xdc1600f3` if successful.
    function bridgeTransferFrom(
        address /* tokenAddress */,
        address from,
        address to,
        uint256 amount,
        bytes calldata /* bridgeData */
    )
        external
        returns (bytes4 success)
    {
        // Ensure that only the `ERC20BridgeProxy` can call this function.
        require(
            msg.sender == _getERC20BridgeProxyAddress(),
            "ChaiBridge/ONLY_CALLABLE_BY_ERC20_BRIDGE_PROXY"
        );

        // Withdraw `from` address's Dai.
        // NOTE: This contract must be approved to spend Chai on behalf of `from`.
        bytes memory drawCalldata = abi.encodeWithSelector(
            IChai(address(0)).draw.selector,
            from,
            amount
        );

        (bool success,) = _getChaiAddress().call(drawCalldata);
        require(
            success,
            "ChaiBridge/DRAW_DAI_FAILED"
        );

        // Transfer Dai to `to`
        // This will never fail if the `draw` call was successful
        IERC20Token(_getDaiAddress()).transfer(to, amount);

        return BRIDGE_SUCCESS;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";


contract PotLike {
    function chi() external returns (uint256);
    function rho() external returns (uint256);
    function drip() external returns (uint256);
    function join(uint256) external;
    function exit(uint256) external;
}


// The actual Chai contract can be found here: https://github.com/dapphub/chai
contract IChai is
    IERC20Token
{
    /// @dev Withdraws Dai owned by `src`
    /// @param src Address that owns Dai.
    /// @param wad Amount of Dai to withdraw.
    function draw(
        address src,
        uint256 wad
    )
        external;

    /// @dev Queries Dai balance of Chai holder.
    /// @param usr Address of Chai holder.
    /// @return Dai balance.
    function dai(address usr)
        external
        returns (uint256);

    /// @dev Queries the Pot contract used by the Chai contract.
    function pot()
        external
        returns (PotLike);

    /// @dev Deposits Dai in exchange for Chai
    /// @param dst Address to receive Chai.
    /// @param wad Amount of Dai to deposit.
    function join(
        address dst,
        uint256 wad
    )
        external;
}

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-erc20/contracts/src/LibERC20Token.sol";
import "@0x/contracts-exchange-libs/contracts/src/IWallet.sol";
import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "../interfaces/IERC20Bridge.sol";
import "../interfaces/IBalancerPool.sol";


contract CreamBridge is
    IERC20Bridge,
    IWallet,
    DeploymentConstants
{
    /// @dev Callback for `IERC20Bridge`. Tries to buy `amount` of
    ///      `toTokenAddress` tokens by selling the entirety of the `fromTokenAddress`
    ///      token encoded in the bridge data, then transfers the bought
    ///      tokens to `to`.
    /// @param toTokenAddress The token to buy and transfer to `to`.
    /// @param from The maker (this contract).
    /// @param to The recipient of the bought tokens.
    /// @param amount Minimum amount of `toTokenAddress` tokens to buy.
    /// @param bridgeData The abi-encoded addresses of the "from" token and Balancer pool.
    /// @return success The magic bytes if successful.
    function bridgeTransferFrom(
        address toTokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success)
    {
        // Decode the bridge data.
        (address fromTokenAddress, address poolAddress) = abi.decode(
            bridgeData,
            (address, address)
        );
        require(toTokenAddress != fromTokenAddress, "CreamBridge/INVALID_PAIR");

        uint256 fromTokenBalance = IERC20Token(fromTokenAddress).balanceOf(address(this));
        // Grant an allowance to the exchange to spend `fromTokenAddress` token.
        LibERC20Token.approveIfBelow(fromTokenAddress, poolAddress, fromTokenBalance);

        // Sell all of this contract's `fromTokenAddress` token balance.
        (uint256 boughtAmount,) = IBalancerPool(poolAddress).swapExactAmountIn(
            fromTokenAddress, // tokenIn
            fromTokenBalance, // tokenAmountIn
            toTokenAddress,   // tokenOut
            amount,           // minAmountOut
            uint256(-1)       // maxPrice
        );

        // Transfer the converted `toToken`s to `to`.
        LibERC20Token.transfer(toTokenAddress, to, boughtAmount);

        emit ERC20BridgeTransfer(
            fromTokenAddress,
            toTokenAddress,
            fromTokenBalance,
            boughtAmount,
            from,
            to
        );
        return BRIDGE_SUCCESS;
    }

    /// @dev `SignatureType.Wallet` callback, so that this bridge can be the maker
    ///      and sign for itself in orders. Always succeeds.
    /// @return magicValue Magic success bytes, always.
    function isValidSignature(
        bytes32,
        bytes calldata
    )
        external
        view
        returns (bytes4 magicValue)
    {
        return LEGACY_WALLET_MAGIC_VALUE;
    }
}

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-erc20/contracts/src/interfaces/IEtherToken.sol";
import "@0x/contracts-erc20/contracts/src/LibERC20Token.sol";
import "@0x/contracts-exchange-libs/contracts/src/IWallet.sol";
import "@0x/contracts-utils/contracts/src/LibAddressArray.sol";
import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "../interfaces/IUniswapV2Router01.sol";
import "../interfaces/IERC20Bridge.sol";


// solhint-disable space-after-comma
// solhint-disable not-rely-on-time
contract CryptoComBridge is
    IERC20Bridge,
    IWallet,
    DeploymentConstants
{
    struct TransferState {
        address[] path;
        address router;
        uint256 fromTokenBalance;
    }

    /// @dev Callback for `IERC20Bridge`. Tries to buy `amount` of
    ///      `toTokenAddress` tokens by selling the entirety of the `fromTokenAddress`
    ///      token encoded in the bridge data.
    /// @param toTokenAddress The token to buy and transfer to `to`.
    /// @param from The maker (this contract).
    /// @param to The recipient of the bought tokens.
    /// @param amount Minimum amount of `toTokenAddress` tokens to buy.
    /// @param bridgeData The abi-encoded path of token addresses. Last element must be toTokenAddress
    /// @return success The magic bytes if successful.
    function bridgeTransferFrom(
        address toTokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success)
    {
        // hold variables to get around stack depth limitations
        TransferState memory state;

        // Decode the bridge data to get the `fromTokenAddress`.
        // solhint-disable indent
        (state.path, state.router) = abi.decode(bridgeData, (address[], address));
        // solhint-enable indent

        require(state.path.length >= 2, "CryptoComBridge/PATH_LENGTH_MUST_BE_AT_LEAST_TWO");
        require(state.path[state.path.length - 1] == toTokenAddress, "CryptoComBridge/LAST_ELEMENT_OF_PATH_MUST_MATCH_OUTPUT_TOKEN");

        // Just transfer the tokens if they're the same.
        if (state.path[0] == toTokenAddress) {
            LibERC20Token.transfer(state.path[0], to, amount);
            return BRIDGE_SUCCESS;
        }

        // Get our balance of `fromTokenAddress` token.
        state.fromTokenBalance = IERC20Token(state.path[0]).balanceOf(address(this));

        // Grant the SushiSwap router an allowance.
        LibERC20Token.approveIfBelow(
            state.path[0],
            state.router,
            state.fromTokenBalance
        );

        // Buy as much `toTokenAddress` token with `fromTokenAddress` token
        // and transfer it to `to`.
        IUniswapV2Router01 router = IUniswapV2Router01(state.router);
        uint[] memory amounts = router.swapExactTokensForTokens(
             // Sell all tokens we hold.
            state.fromTokenBalance,
             // Minimum buy amount.
            amount,
            // Convert `fromTokenAddress` to `toTokenAddress`.
            state.path,
            // Recipient is `to`.
            to,
            // Expires after this block.
            block.timestamp
        );

        emit ERC20BridgeTransfer(
            // input token
            state.path[0],
            // output token
            toTokenAddress,
            // input token amount
            state.fromTokenBalance,
            // output token amount
            amounts[amounts.length - 1],
            from,
            to
        );

        return BRIDGE_SUCCESS;
    }

    /// @dev `SignatureType.Wallet` callback, so that this bridge can be the maker
    ///      and sign for itself in orders. Always succeeds.
    /// @return magicValue Success bytes, always.
    function isValidSignature(
        bytes32,
        bytes calldata
    )
        external
        view
        returns (bytes4 magicValue)
    {
        return LEGACY_WALLET_MAGIC_VALUE;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "./LibAddressArrayRichErrors.sol";
import "./LibBytes.sol";
import "./LibRichErrors.sol";


library LibAddressArray {

    /// @dev Append a new address to an array of addresses.
    ///      The `addressArray` may need to be reallocated to make space
    ///      for the new address. Because of this we return the resulting
    ///      memory location of `addressArray`.
    /// @param addressArray Array of addresses.
    /// @param addressToAppend  Address to append.
    /// @return Array of addresses: [... addressArray, addressToAppend]
    function append(address[] memory addressArray, address addressToAppend)
        internal
        pure
        returns (address[] memory)
    {
        // Get stats on address array and free memory
        uint256 freeMemPtr = 0;
        uint256 addressArrayBeginPtr = 0;
        uint256 addressArrayEndPtr = 0;
        uint256 addressArrayLength = addressArray.length;
        uint256 addressArrayMemSizeInBytes = 32 + (32 * addressArrayLength);
        assembly {
            freeMemPtr := mload(0x40)
            addressArrayBeginPtr := addressArray
            addressArrayEndPtr := add(addressArray, addressArrayMemSizeInBytes)
        }

        // Cases for `freeMemPtr`:
        //  `freeMemPtr` == `addressArrayEndPtr`: Nothing occupies memory after `addressArray`
        //  `freeMemPtr` > `addressArrayEndPtr`: Some value occupies memory after `addressArray`
        //  `freeMemPtr` < `addressArrayEndPtr`: Memory has not been managed properly.
        if (freeMemPtr < addressArrayEndPtr) {
            LibRichErrors.rrevert(LibAddressArrayRichErrors.MismanagedMemoryError(
                freeMemPtr,
                addressArrayEndPtr
            ));
        }

        // If free memory begins at the end of `addressArray`
        // then we can append `addressToAppend` directly.
        // Otherwise, we must copy the array to free memory
        // before appending new values to it.
        if (freeMemPtr > addressArrayEndPtr) {
            LibBytes.memCopy(freeMemPtr, addressArrayBeginPtr, addressArrayMemSizeInBytes);
            assembly {
                addressArray := freeMemPtr
                addressArrayBeginPtr := addressArray
            }
        }

        // Append `addressToAppend`
        addressArrayLength += 1;
        addressArrayMemSizeInBytes += 32;
        addressArrayEndPtr = addressArrayBeginPtr + addressArrayMemSizeInBytes;
        freeMemPtr = addressArrayEndPtr;
        assembly {
            // Store new array length
            mstore(addressArray, addressArrayLength)

            // Update `freeMemPtr`
            mstore(0x40, freeMemPtr)
        }
        addressArray[addressArrayLength - 1] = addressToAppend;
        return addressArray;
    }

    /// @dev Checks if an address array contains the target address.
    /// @param addressArray Array of addresses.
    /// @param target Address to search for in array.
    /// @return True if the addressArray contains the target.
    function contains(address[] memory addressArray, address target)
        internal
        pure
        returns (bool success)
    {
        assembly {

            // Calculate byte length of array
            let arrayByteLen := mul(mload(addressArray), 32)
            // Calculate beginning of array contents
            let arrayContentsStart := add(addressArray, 32)
            // Calclulate end of array contents
            let arrayContentsEnd := add(arrayContentsStart, arrayByteLen)

            // Loop through array
            for {let i:= arrayContentsStart} lt(i, arrayContentsEnd) {i := add(i, 32)} {

                // Load array element
                let arrayElement := mload(i)

                // Return true if array element equals target
                if eq(target, arrayElement) {
                    // Set success to true
                    success := 1
                    // Break loop
                    i := arrayContentsEnd
                }
            }
        }
        return success;
    }

    /// @dev Finds the index of an address within an array.
    /// @param addressArray Array of addresses.
    /// @param target Address to search for in array.
    /// @return Existence and index of the target in the array.
    function indexOf(address[] memory addressArray, address target)
        internal
        pure
        returns (bool success, uint256 index)
    {
        assembly {

            // Calculate byte length of array
            let arrayByteLen := mul(mload(addressArray), 32)
            // Calculate beginning of array contents
            let arrayContentsStart := add(addressArray, 32)
            // Calclulate end of array contents
            let arrayContentsEnd := add(arrayContentsStart, arrayByteLen)

            // Loop through array
            for {let i:= arrayContentsStart} lt(i, arrayContentsEnd) {i := add(i, 32)} {

                // Load array element
                let arrayElement := mload(i)

                // Return true if array element equals target
                if eq(target, arrayElement) {
                    // Set success and index
                    success := 1
                    index := div(sub(i, arrayContentsStart), 32)
                    // Break loop
                    i := arrayContentsEnd
                }
            }
        }
        return (success, index);
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


library LibAddressArrayRichErrors {

    // bytes4(keccak256("MismanagedMemoryError(uint256,uint256)"))
    bytes4 internal constant MISMANAGED_MEMORY_ERROR_SELECTOR =
        0x5fc83722;

    // solhint-disable func-name-mixedcase
    function MismanagedMemoryError(
        uint256 freeMemPtr,
        uint256 addressArrayEndPtr
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            MISMANAGED_MEMORY_ERROR_SELECTOR,
            freeMemPtr,
            addressArrayEndPtr
        );
    }
}

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


interface IUniswapV2Router01 {

    /// @dev Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined by the path.
    ///      The first element of path is the input token, the last is the output token, and any intermediate elements represent
    ///      intermediate pairs to trade through (if, for example, a direct pair does not exist).
    /// @param amountIn The amount of input tokens to send.
    /// @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
    /// @param path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity.
    /// @param to Recipient of the output tokens.
    /// @param deadline Unix timestamp after which the transaction will revert.
    /// @return amounts The input token amount and all subsequent output token amounts.
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-erc20/contracts/src/LibERC20Token.sol";
import "@0x/contracts-exchange-libs/contracts/src/IWallet.sol";
import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "../interfaces/IERC20Bridge.sol";
import "../interfaces/ICurve.sol";


// solhint-disable not-rely-on-time
// solhint-disable space-after-comma
contract CurveBridge is
    IERC20Bridge,
    IWallet,
    DeploymentConstants
{
    struct CurveBridgeData {
        address curveAddress;
        bytes4 exchangeFunctionSelector;
        address fromTokenAddress;
        int128 fromCoinIdx;
        int128 toCoinIdx;
    }

    /// @dev Callback for `ICurve`. Tries to buy `amount` of
    ///      `toTokenAddress` tokens by selling the entirety of the opposing asset
    ///      (DAI, USDC) to the Curve contract, then transfers the bought
    ///      tokens to `to`.
    /// @param toTokenAddress The token to give to `to` (i.e DAI, USDC, USDT).
    /// @param from The maker (this contract).
    /// @param to The recipient of the bought tokens.
    /// @param amount Minimum amount of `toTokenAddress` tokens to buy.
    /// @param bridgeData The abi-encoeded "from" token address.
    /// @return success The magic bytes if successful.
    function bridgeTransferFrom(
        address toTokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success)
    {
        // Decode the bridge data to get the Curve metadata.
        CurveBridgeData memory data = abi.decode(bridgeData, (CurveBridgeData));

        require(toTokenAddress != data.fromTokenAddress, "CurveBridge/INVALID_PAIR");
        uint256 fromTokenBalance = IERC20Token(data.fromTokenAddress).balanceOf(address(this));
        // Grant an allowance to the exchange to spend `fromTokenAddress` token.
        LibERC20Token.approveIfBelow(data.fromTokenAddress, data.curveAddress, fromTokenBalance);

        // Try to sell all of this contract's `fromTokenAddress` token balance.
        {
            (bool didSucceed, bytes memory resultData) =
                data.curveAddress.call(abi.encodeWithSelector(
                    data.exchangeFunctionSelector,
                    data.fromCoinIdx,
                    data.toCoinIdx,
                    // dx
                    fromTokenBalance,
                    // min dy
                    amount
                ));
            if (!didSucceed) {
                assembly { revert(add(resultData, 32), mload(resultData)) }
            }
        }

        uint256 toTokenBalance = IERC20Token(toTokenAddress).balanceOf(address(this));
        // Transfer the converted `toToken`s to `to`.
        LibERC20Token.transfer(toTokenAddress, to, toTokenBalance);

        emit ERC20BridgeTransfer(
            data.fromTokenAddress,
            toTokenAddress,
            fromTokenBalance,
            toTokenBalance,
            from,
            to
        );
        return BRIDGE_SUCCESS;
    }

    /// @dev `SignatureType.Wallet` callback, so that this bridge can be the maker
    ///      and sign for itself in orders. Always succeeds.
    /// @return magicValue Magic success bytes, always.
    function isValidSignature(
        bytes32,
        bytes calldata
    )
        external
        view
        returns (bytes4 magicValue)
    {
        return LEGACY_WALLET_MAGIC_VALUE;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


// solhint-disable func-name-mixedcase
interface ICurve {

    /// @dev Sell `sellAmount` of `fromToken` token and receive `toToken` token.
    ///      This function exists on later versions of Curve (USDC/DAI/USDT)
    /// @param i The token index being sold.
    /// @param j The token index being bought.
    /// @param sellAmount The amount of token being bought.
    /// @param minBuyAmount The minimum buy amount of the token being bought.
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 sellAmount,
        uint256 minBuyAmount
    )
        external;

    /// @dev Get the amount of `toToken` by selling `sellAmount` of `fromToken`
    /// @param i The token index being sold.
    /// @param j The token index being bought.
    /// @param sellAmount The amount of token being bought.
    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 sellAmount
    )
        external
        returns (uint256 dy);

    /// @dev Get the amount of `fromToken` by buying `buyAmount` of `toToken`
    /// @param i The token index being sold.
    /// @param j The token index being bought.
    /// @param buyAmount The amount of token being bought.
    function get_dx_underlying(
        int128 i,
        int128 j,
        uint256 buyAmount
    )
        external
        returns (uint256 dx);

    /// @dev Get the underlying token address from the token index
    /// @param i The token index.
    function underlying_coins(
        int128 i
    )
        external
        returns (address tokenAddress);
}

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-erc20/contracts/src/LibERC20Token.sol";
import "@0x/contracts-exchange-libs/contracts/src/IWallet.sol";
import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "../interfaces/IERC20Bridge.sol";


interface IDODOHelper {

    function querySellQuoteToken(address dodo, uint256 amount) external view returns (uint256);
}


interface IDODO {

    function sellBaseToken(uint256 amount, uint256 minReceiveQuote, bytes calldata data) external returns (uint256);

    function buyBaseToken(uint256 amount, uint256 maxPayQuote, bytes calldata data) external returns (uint256);

}


contract DODOBridge is
    IERC20Bridge,
    IWallet,
    DeploymentConstants
{

    struct TransferState {
        address fromTokenAddress;
        uint256 fromTokenBalance;
        address pool;
        bool isSellBase;
    }

    /// @dev Callback for `IERC20Bridge`. Tries to buy `amount` of
    ///      `toTokenAddress` tokens by selling the entirety of the `fromTokenAddress`
    ///      token encoded in the bridge data.
    /// @param toTokenAddress The token to buy and transfer to `to`.
    /// @param from The maker (this contract).
    /// @param to The recipient of the bought tokens.
    /// @param amount Minimum amount of `toTokenAddress` tokens to buy.
    /// @param bridgeData The abi-encoded path of token addresses. Last element must be toTokenAddress
    /// @return success The magic bytes if successful.
    function bridgeTransferFrom(
        address toTokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success)
    {
        TransferState memory state;
        // Decode the bridge data to get the `fromTokenAddress`.
        (state.fromTokenAddress, state.pool, state.isSellBase) = abi.decode(bridgeData, (address, address, bool));
        require(state.pool != address(0), "DODOBridge/InvalidPool");
        IDODO exchange = IDODO(state.pool);
        // Get our balance of `fromTokenAddress` token.
        state.fromTokenBalance = IERC20Token(state.fromTokenAddress).balanceOf(address(this));

        // Grant the pool an allowance.
        LibERC20Token.approveIfBelow(
            state.fromTokenAddress,
            address(exchange),
            state.fromTokenBalance
        );

        uint256 boughtAmount;
        if (state.isSellBase) {
            boughtAmount = exchange.sellBaseToken(
                // amount to sell
                state.fromTokenBalance,
                // min receive amount
                1,
                new bytes(0)
            );
        } else {
            // Need to re-calculate the sell quote amount into buyBase
            boughtAmount = IDODOHelper(_getDODOHelperAddress()).querySellQuoteToken(
                address(exchange),
                state.fromTokenBalance
            );
            exchange.buyBaseToken(
                // amount to buy
                boughtAmount,
                // max pay amount
                state.fromTokenBalance,
                new bytes(0)
            );
        }
        // Transfer funds to `to`
        IERC20Token(toTokenAddress).transfer(to, boughtAmount);


        emit ERC20BridgeTransfer(
            // input token
            state.fromTokenAddress,
            // output token
            toTokenAddress,
            // input token amount
            state.fromTokenBalance,
            // output token amount
            boughtAmount,
            from,
            to
        );

        return BRIDGE_SUCCESS;
    }

    /// @dev `SignatureType.Wallet` callback, so that this bridge can be the maker
    ///      and sign for itself in orders. Always succeeds.
    /// @return magicValue Success bytes, always.
    function isValidSignature(
        bytes32,
        bytes calldata
    )
        external
        view
        returns (bytes4 magicValue)
    {
        return LEGACY_WALLET_MAGIC_VALUE;
    }
}

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-erc20/contracts/src/LibERC20Token.sol";
import "@0x/contracts-exchange-libs/contracts/src/IWallet.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibMath.sol";
import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "@0x/contracts-utils/contracts/src/LibBytes.sol";
import "@0x/contracts-utils/contracts/src/LibSafeMath.sol";
import "../interfaces/IERC20Bridge.sol";
import "./MixinGasToken.sol";


// solhint-disable space-after-comma, indent
contract DexForwarderBridge is
    IERC20Bridge,
    IWallet,
    DeploymentConstants,
    MixinGasToken
{
    using LibSafeMath for uint256;

    /// @dev Data needed to reconstruct a bridge call.
    struct BridgeCall {
        address target;
        uint256 inputTokenAmount;
        uint256 outputTokenAmount;
        bytes bridgeData;
    }

    /// @dev Intermediate state variables used by `bridgeTransferFrom()`, in
    ///      struct form to get around stack limits.
    struct TransferFromState {
        address inputToken;
        uint256 initialInputTokenBalance;
        uint256 callInputTokenAmount;
        uint256 callOutputTokenAmount;
        uint256 totalInputTokenSold;
        BridgeCall[] calls;
    }

    /// @dev Spends this contract's entire balance of input tokens by forwarding
    /// them to other bridges. Reverts if the entire balance is not spent.
    /// @param outputToken The token being bought.
    /// @param to The recipient of the bought tokens.
    /// @param bridgeData The abi-encoded input token address.
    /// @return success The magic bytes if successful.
    function bridgeTransferFrom(
        address outputToken,
        address /* from */,
        address to,
        uint256 /* amount */,
        bytes calldata bridgeData
    )
        external
        freesGasTokensFromCollector
        returns (bytes4 success)
    {
        require(
            msg.sender == _getERC20BridgeProxyAddress(),
            "DexForwarderBridge/SENDER_NOT_AUTHORIZED"
        );
        TransferFromState memory state;
        (
            state.inputToken,
            state.calls
        ) = abi.decode(bridgeData, (address, BridgeCall[]));

        state.initialInputTokenBalance =
            IERC20Token(state.inputToken).balanceOf(address(this));

        for (uint256 i = 0; i < state.calls.length; ++i) {
            // Stop if the we've sold all our input tokens.
            if (state.totalInputTokenSold >= state.initialInputTokenBalance) {
                break;
            }

            // Compute token amounts.
            state.callInputTokenAmount = LibSafeMath.min256(
                state.calls[i].inputTokenAmount,
                state.initialInputTokenBalance.safeSub(state.totalInputTokenSold)
            );
            state.callOutputTokenAmount = LibMath.getPartialAmountFloor(
                state.callInputTokenAmount,
                state.calls[i].inputTokenAmount,
                state.calls[i].outputTokenAmount
            );

            // Execute the call in a new context so we can recoup transferred
            // funds by reverting.
            (bool didSucceed, ) = address(this)
                .call(abi.encodeWithSelector(
                    this.executeBridgeCall.selector,
                    state.calls[i].target,
                    to,
                    state.inputToken,
                    outputToken,
                    state.callInputTokenAmount,
                    state.callOutputTokenAmount,
                    state.calls[i].bridgeData
                ));

            if (didSucceed) {
                // Increase the amount of tokens sold.
                state.totalInputTokenSold = state.totalInputTokenSold.safeAdd(
                    state.callInputTokenAmount
                );
            }
        }
        // Always succeed.
        return BRIDGE_SUCCESS;
    }

    /// @dev Transfers `inputToken` token to a bridge contract then calls
    ///      its `bridgeTransferFrom()`. This is executed in separate context
    ///      so we can revert the transfer on error. This can only be called
    //       by this contract itself.
    /// @param bridge The bridge contract.
    /// @param to The recipient of `outputToken` tokens.
    /// @param inputToken The input token.
    /// @param outputToken The output token.
    /// @param inputTokenAmount The amount of input tokens to transfer to `bridge`.
    /// @param outputTokenAmount The amount of expected output tokens to be sent
    ///        to `to` by `bridge`.
    function executeBridgeCall(
        address bridge,
        address to,
        address inputToken,
        address outputToken,
        uint256 inputTokenAmount,
        uint256 outputTokenAmount,
        bytes calldata bridgeData
    )
        external
    {
        // Must be called through `bridgeTransferFrom()`.
        require(msg.sender == address(this), "DexForwarderBridge/ONLY_SELF");
        // `bridge` must not be this contract.
        require(bridge != address(this));

        // Get the starting balance of output tokens for `to`.
        uint256 initialRecipientBalance = IERC20Token(outputToken).balanceOf(to);

        // Transfer input tokens to the bridge.
        LibERC20Token.transfer(inputToken, bridge, inputTokenAmount);

        // Call the bridge.
        (bool didSucceed, bytes memory resultData) =
            bridge.call(abi.encodeWithSelector(
                IERC20Bridge(0).bridgeTransferFrom.selector,
                outputToken,
                bridge,
                to,
                outputTokenAmount,
                bridgeData
            ));

        // Revert if the call failed or not enough tokens were bought.
        // This will also undo the token transfer.
        require(
            didSucceed
            && resultData.length == 32
            && LibBytes.readBytes32(resultData, 0) == bytes32(BRIDGE_SUCCESS)
            && IERC20Token(outputToken).balanceOf(to).safeSub(initialRecipientBalance) >= outputTokenAmount
        );
    }

    /// @dev `SignatureType.Wallet` callback, so that this bridge can be the maker
    ///      and sign for itself in orders. Always succeeds.
    /// @return magicValue Magic success bytes, always.
    function isValidSignature(
        bytes32,
        bytes calldata
    )
        external
        view
        returns (bytes4 magicValue)
    {
        return LEGACY_WALLET_MAGIC_VALUE;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "@0x/contracts-utils/contracts/src/LibSafeMath.sol";
import "@0x/contracts-utils/contracts/src/LibRichErrors.sol";
import "./LibMathRichErrors.sol";


library LibMath {

    using LibSafeMath for uint256;

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target rounded down.
    function safeGetPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        if (isRoundingErrorFloor(
                numerator,
                denominator,
                target
        )) {
            LibRichErrors.rrevert(LibMathRichErrors.RoundingError(
                numerator,
                denominator,
                target
            ));
        }

        partialAmount = numerator.safeMul(target).safeDiv(denominator);
        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target rounded up.
    function safeGetPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        if (isRoundingErrorCeil(
                numerator,
                denominator,
                target
        )) {
            LibRichErrors.rrevert(LibMathRichErrors.RoundingError(
                numerator,
                denominator,
                target
            ));
        }

        // safeDiv computes `floor(a / b)`. We use the identity (a, b integer):
        //       ceil(a / b) = floor((a + b - 1) / b)
        // To implement `ceil(a / b)` using safeDiv.
        partialAmount = numerator.safeMul(target)
            .safeAdd(denominator.safeSub(1))
            .safeDiv(denominator);

        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target rounded down.
    function getPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        partialAmount = numerator.safeMul(target).safeDiv(denominator);
        return partialAmount;
    }

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target rounded up.
    function getPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        // safeDiv computes `floor(a / b)`. We use the identity (a, b integer):
        //       ceil(a / b) = floor((a + b - 1) / b)
        // To implement `ceil(a / b)` using safeDiv.
        partialAmount = numerator.safeMul(target)
            .safeAdd(denominator.safeSub(1))
            .safeDiv(denominator);

        return partialAmount;
    }

    /// @dev Checks if rounding error >= 0.1% when rounding down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return Rounding error is present.
    function isRoundingErrorFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (bool isError)
    {
        if (denominator == 0) {
            LibRichErrors.rrevert(LibMathRichErrors.DivisionByZeroError());
        }

        // The absolute rounding error is the difference between the rounded
        // value and the ideal value. The relative rounding error is the
        // absolute rounding error divided by the absolute value of the
        // ideal value. This is undefined when the ideal value is zero.
        //
        // The ideal value is `numerator * target / denominator`.
        // Let's call `numerator * target % denominator` the remainder.
        // The absolute error is `remainder / denominator`.
        //
        // When the ideal value is zero, we require the absolute error to
        // be zero. Fortunately, this is always the case. The ideal value is
        // zero iff `numerator == 0` and/or `target == 0`. In this case the
        // remainder and absolute error are also zero.
        if (target == 0 || numerator == 0) {
            return false;
        }

        // Otherwise, we want the relative rounding error to be strictly
        // less than 0.1%.
        // The relative error is `remainder / (numerator * target)`.
        // We want the relative error less than 1 / 1000:
        //        remainder / (numerator * denominator)  <  1 / 1000
        // or equivalently:
        //        1000 * remainder  <  numerator * target
        // so we have a rounding error iff:
        //        1000 * remainder  >=  numerator * target
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        isError = remainder.safeMul(1000) >= numerator.safeMul(target);
        return isError;
    }

    /// @dev Checks if rounding error >= 0.1% when rounding up.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return Rounding error is present.
    function isRoundingErrorCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (bool isError)
    {
        if (denominator == 0) {
            LibRichErrors.rrevert(LibMathRichErrors.DivisionByZeroError());
        }

        // See the comments in `isRoundingError`.
        if (target == 0 || numerator == 0) {
            // When either is zero, the ideal value and rounded value are zero
            // and there is no rounding error. (Although the relative error
            // is undefined.)
            return false;
        }
        // Compute remainder as before
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        remainder = denominator.safeSub(remainder) % denominator;
        isError = remainder.safeMul(1000) >= numerator.safeMul(target);
        return isError;
    }
}

pragma solidity ^0.5.9;


library LibMathRichErrors {

    // bytes4(keccak256("DivisionByZeroError()"))
    bytes internal constant DIVISION_BY_ZERO_ERROR =
        hex"a791837c";

    // bytes4(keccak256("RoundingError(uint256,uint256,uint256)"))
    bytes4 internal constant ROUNDING_ERROR_SELECTOR =
        0x339f3de2;

    // solhint-disable func-name-mixedcase
    function DivisionByZeroError()
        internal
        pure
        returns (bytes memory)
    {
        return DIVISION_BY_ZERO_ERROR;
    }

    function RoundingError(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ROUNDING_ERROR_SELECTOR,
            numerator,
            denominator,
            target
        );
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.16;

import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "../interfaces/IGasToken.sol";


contract MixinGasToken is
    DeploymentConstants
{

    /// @dev Frees gas tokens based on the amount of gas consumed in the function
    modifier freesGasTokens {
        uint256 gasBefore = gasleft();
        _;
        IGasToken gst = IGasToken(_getGstAddress());
        if (address(gst) != address(0)) {
            // (gasUsed + FREE_BASE) / (2 * REIMBURSE - FREE_TOKEN)
            //            14154             24000        6870
            uint256 value = (gasBefore - gasleft() + 14154) / 41130;
            gst.freeUpTo(value);
        }
    }

    /// @dev Frees gas tokens using the balance of `from`. Amount freed is based
    ///     on the gas consumed in the function
    modifier freesGasTokensFromCollector() {
        uint256 gasBefore = gasleft();
        _;
        IGasToken gst = IGasToken(_getGstAddress());
        if (address(gst) != address(0)) {
            // (gasUsed + FREE_BASE) / (2 * REIMBURSE - FREE_TOKEN)
            //            14154             24000        6870
            uint256 value = (gasBefore - gasleft() + 14154) / 41130;
            gst.freeFromUpTo(_getGstCollectorAddress(), value);
        }
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.15;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";


contract IGasToken is IERC20Token {

    /// @dev Frees up to `value` sub-tokens
    /// @param value The amount of tokens to free
    /// @return How many tokens were freed
    function freeUpTo(uint256 value) external returns (uint256 freed);

    /// @dev Frees up to `value` sub-tokens owned by `from`
    /// @param from The owner of tokens to spend
    /// @param value The amount of tokens to free
    /// @return How many tokens were freed
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);

    /// @dev Mints `value` amount of tokens
    /// @param value The amount of tokens to mint
    function mint(uint256 value) external;
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "@0x/contracts-utils/contracts/src/LibSafeMath.sol";
import "@0x/contracts-exchange-libs/contracts/src/LibMath.sol";
import "../interfaces/IERC20Bridge.sol";
import "../interfaces/IDydxBridge.sol";
import "../interfaces/IDydx.sol";


contract DydxBridge is
    IERC20Bridge,
    IDydxBridge,
    DeploymentConstants
{

    using LibSafeMath for uint256;

    /// @dev Callback for `IERC20Bridge`. Deposits or withdraws tokens from a dydx account.
    ///      Notes:
    ///         1. This bridge must be set as an operator of the input dydx account.
    ///         2. This function may only be called in the context of the 0x Exchange.
    ///         3. The maker or taker of the 0x order must be the dydx account owner.
    ///         4. Deposits into dydx are made from the `from` address.
    ///         5. Withdrawals from dydx are made to the `to` address.
    ///         6. Calling this function must always withdraw at least `amount`,
    ///            otherwise the `ERC20Bridge` will revert.
    /// @param from The sender of the tokens and owner of the dydx account.
    /// @param to The recipient of the tokens.
    /// @param amount Minimum amount of `toTokenAddress` tokens to deposit or withdraw.
    /// @param encodedBridgeData An abi-encoded `BridgeData` struct.
    /// @return success The magic bytes if successful.
    function bridgeTransferFrom(
        address, /* toTokenAddress */
        address from,
        address to,
        uint256 amount,
        bytes calldata encodedBridgeData
    )
        external
        returns (bytes4 success)
    {
        // Ensure that only the `ERC20BridgeProxy` can call this function.
        require(
            msg.sender == _getERC20BridgeProxyAddress(),
            "DydxBridge/ONLY_CALLABLE_BY_ERC20_BRIDGE_PROXY"
        );

        // Decode bridge data.
        (BridgeData memory bridgeData) = abi.decode(encodedBridgeData, (BridgeData));

        // The dydx accounts are owned by the `from` address.
        IDydx.AccountInfo[] memory accounts = _createAccounts(from, bridgeData);

        // Create dydx actions to run on the dydx accounts.
        IDydx.ActionArgs[] memory actions = _createActions(
            from,
            to,
            amount,
            bridgeData
        );

        // Run operation. This will revert on failure.
        IDydx(_getDydxAddress()).operate(accounts, actions);

        return BRIDGE_SUCCESS;
    }

    /// @dev Creates an array of accounts for dydx to operate on.
    ///      All accounts must belong to the same owner.
    /// @param accountOwner Owner of the dydx account.
    /// @param bridgeData A `BridgeData` struct.
    function _createAccounts(
        address accountOwner,
        BridgeData memory bridgeData
    )
        internal
        returns (IDydx.AccountInfo[] memory accounts)
    {
        uint256[] memory accountNumbers = bridgeData.accountNumbers;
        uint256 nAccounts = accountNumbers.length;
        accounts = new IDydx.AccountInfo[](nAccounts);
        for (uint256 i = 0; i < nAccounts; ++i) {
            accounts[i] = IDydx.AccountInfo({
                owner: accountOwner,
                number: accountNumbers[i]
            });
        }
    }

    /// @dev Creates an array of actions to carry out on dydx.
    /// @param depositFrom Deposit value from this address (owner of the dydx account).
    /// @param withdrawTo Withdraw value to this address.
    /// @param amount The amount of value available to operate on.
    /// @param bridgeData A `BridgeData` struct.
    function _createActions(
        address depositFrom,
        address withdrawTo,
        uint256 amount,
        BridgeData memory bridgeData
    )
        internal
        returns (IDydx.ActionArgs[] memory actions)
    {
        BridgeAction[] memory bridgeActions = bridgeData.actions;
        uint256 nBridgeActions = bridgeActions.length;
        actions = new IDydx.ActionArgs[](nBridgeActions);
        for (uint256 i = 0; i < nBridgeActions; ++i) {
            // Cache current bridge action.
            BridgeAction memory bridgeAction = bridgeActions[i];

            // Scale amount, if conversion rate is set.
            uint256 scaledAmount;
            if (bridgeAction.conversionRateDenominator > 0) {
                scaledAmount = LibMath.safeGetPartialAmountFloor(
                    bridgeAction.conversionRateNumerator,
                    bridgeAction.conversionRateDenominator,
                    amount
                );
            } else {
                scaledAmount = amount;
            }

            // Construct dydx action.
            if (bridgeAction.actionType == BridgeActionType.Deposit) {
                // Deposit tokens from the account owner into their dydx account.
                actions[i] = _createDepositAction(
                    depositFrom,
                    scaledAmount,
                    bridgeAction
                );
            } else if (bridgeAction.actionType == BridgeActionType.Withdraw) {
                // Withdraw tokens from dydx to the `otherAccount`.
                actions[i] = _createWithdrawAction(
                    withdrawTo,
                    scaledAmount,
                    bridgeAction
                );
            } else {
                // If all values in the `Action` enum are handled then this
                // revert is unreachable: Solidity will revert when casting
                // from `uint8` to `Action`.
                revert("DydxBridge/UNRECOGNIZED_BRIDGE_ACTION");
            }
        }
    }

    /// @dev Returns a dydx `DepositAction`.
    /// @param depositFrom Deposit tokens from this address who is also the account owner.
    /// @param amount of tokens to deposit.
    /// @param bridgeAction A `BridgeAction` struct.
    /// @return depositAction The encoded dydx action.
    function _createDepositAction(
        address depositFrom,
        uint256 amount,
        BridgeAction memory bridgeAction
    )
        internal
        pure
        returns (
            IDydx.ActionArgs memory depositAction
        )
    {
        // Create dydx amount.
        IDydx.AssetAmount memory dydxAmount = IDydx.AssetAmount({
            sign: true,                                 // true if positive.
            denomination: IDydx.AssetDenomination.Wei,  // Wei => actual token amount held in account.
            ref: IDydx.AssetReference.Delta,                // Delta => a relative amount.
            value: amount                               // amount to deposit.
        });

        // Create dydx deposit action.
        depositAction = IDydx.ActionArgs({
            actionType: IDydx.ActionType.Deposit,           // deposit tokens.
            amount: dydxAmount,                             // amount to deposit.
            accountIdx: bridgeAction.accountIdx,             // index in the `accounts` when calling `operate`.
            primaryMarketId: bridgeAction.marketId,         // indicates which token to deposit.
            otherAddress: depositFrom,                      // deposit from the account owner.
            // unused parameters
            secondaryMarketId: 0,
            otherAccountIdx: 0,
            data: hex''
        });
    }

    /// @dev Returns a dydx `WithdrawAction`.
    /// @param withdrawTo Withdraw tokens to this address.
    /// @param amount of tokens to withdraw.
    /// @param bridgeAction A `BridgeAction` struct.
    /// @return withdrawAction The encoded dydx action.
    function _createWithdrawAction(
        address withdrawTo,
        uint256 amount,
        BridgeAction memory bridgeAction
    )
        internal
        pure
        returns (
            IDydx.ActionArgs memory withdrawAction
        )
    {
        // Create dydx amount.
        IDydx.AssetAmount memory amountToWithdraw = IDydx.AssetAmount({
            sign: false,                                    // false if negative.
            denomination: IDydx.AssetDenomination.Wei,      // Wei => actual token amount held in account.
            ref: IDydx.AssetReference.Delta,                // Delta => a relative amount.
            value: amount                                   // amount to withdraw.
        });

        // Create withdraw action.
        withdrawAction = IDydx.ActionArgs({
            actionType: IDydx.ActionType.Withdraw,          // withdraw tokens.
            amount: amountToWithdraw,                       // amount to withdraw.
            accountIdx: bridgeAction.accountIdx,            // index in the `accounts` when calling `operate`.
            primaryMarketId: bridgeAction.marketId,         // indicates which token to withdraw.
            otherAddress: withdrawTo,                       // withdraw tokens to this address.
            // unused parameters
            secondaryMarketId: 0,
            otherAccountIdx: 0,
            data: hex''
        });
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


interface IDydxBridge {

    /// @dev This is the subset of `IDydx.ActionType` that are supported by the bridge.
    enum BridgeActionType {
        Deposit,                    // Deposit tokens into dydx account.
        Withdraw                    // Withdraw tokens from dydx account.
    }

    struct BridgeAction {
        BridgeActionType actionType;            // Action to run on dydx account.
        uint256 accountIdx;                     // Index in `BridgeData.accountNumbers` for this action.
        uint256 marketId;                       // Market to operate on.
        uint256 conversionRateNumerator;        // Optional. If set, transfer amount is scaled by (conversionRateNumerator/conversionRateDenominator).
        uint256 conversionRateDenominator;      // Optional. If set, transfer amount is scaled by (conversionRateNumerator/conversionRateDenominator).
    }

    struct BridgeData {
        uint256[] accountNumbers;               // Account number used to identify the owner's specific account.
        BridgeAction[] actions;                 // Actions to carry out on the owner's accounts.
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;


interface IDydx {

    /// @dev Represents the unique key that specifies an account
    struct AccountInfo {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    enum ActionType {
        Deposit,   // supply tokens
        Withdraw,  // borrow tokens
        Transfer,  // transfer balance between accounts
        Buy,       // buy an amount of some token (externally)
        Sell,      // sell an amount of some token (externally)
        Trade,     // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize,  // use excess tokens to zero-out a completely negative account
        Call       // send arbitrary data to an address
    }

    /// @dev Arguments that are passed to Solo in an ordered list as part of a single operation.
    /// Each ActionArgs has an actionType which specifies which action struct that this data will be
    /// parsed into before being processed.
    struct ActionArgs {
        ActionType actionType;
        uint256 accountIdx;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountIdx;
        bytes data;
    }

    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par  // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct D256 {
        uint256 value;
    }

    struct Value {
        uint256 value;
    }

    struct Price {
        uint256 value;
    }

    struct OperatorArg {
        address operator;
        bool trusted;
    }

    /// @dev The global risk parameters that govern the health and security of the system
    struct RiskParams {
        // Required ratio of over-collateralization
        D256 marginRatio;
        // Percentage penalty incurred by liquidated accounts
        D256 liquidationSpread;
        // Percentage of the borrower's interest fee that gets passed to the suppliers
        D256 earningsRate;
        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        Value minBorrowedValue;
    }

    /// @dev The main entry-point to Solo that allows users and contracts to manage accounts.
    ///      Take one or more actions on one or more accounts. The msg.sender must be the owner or
    ///      operator of all accounts except for those being liquidated, vaporized, or traded with.
    ///      One call to operate() is considered a singular "operation". Account collateralization is
    ///      ensured only after the completion of the entire operation.
    /// @param  accounts  A list of all accounts that will be used in this operation. Cannot contain
    ///                   duplicates. In each action, the relevant account will be referred-to by its
    ///                   index in the list.
    /// @param  actions   An ordered list of all actions that will be taken in this operation. The
    ///                   actions will be processed in order.
    function operate(
        AccountInfo[] calldata accounts,
        ActionArgs[] calldata actions
    )
        external;

    // @dev Approves/disapproves any number of operators. An operator is an external address that has the
    //      same permissions to manipulate an account as the owner of the account. Operators are simply
    //      addresses and therefore may either be externally-owned Ethereum accounts OR smart contracts.
    //      Operators are also able to act as AutoTrader contracts on behalf of the account owner if the
    //      operator is a smart contract and implements the IAutoTrader interface.
    // @param args A list of OperatorArgs which have an address and a boolean. The boolean value
    //        denotes whether to approve (true) or revoke approval (false) for that address.
    function setOperators(OperatorArg[] calldata args) external;

    /// @dev Return true if a particular address is approved as an operator for an owner's accounts.
    ///      Approved operators can act on the accounts of the owner as if it were the operator's own.
    /// @param owner The owner of the accounts
    /// @param operator The possible operator
    /// @return isLocalOperator True if operator is approved for owner's accounts
    function getIsLocalOperator(
        address owner,
        address operator
    )
        external
        view
        returns (bool isLocalOperator);

    /// @dev Get the ERC20 token address for a market.
    /// @param marketId The market to query
    /// @return tokenAddress The token address
    function getMarketTokenAddress(
        uint256 marketId
    )
        external
        view
        returns (address tokenAddress);

    /// @dev Get all risk parameters in a single struct.
    /// @return riskParams All global risk parameters
    function getRiskParams()
        external
        view
        returns (RiskParams memory riskParams);

    /// @dev Get the price of the token for a market.
    /// @param marketId The market to query
    /// @return price The price of each atomic unit of the token
    function getMarketPrice(
        uint256 marketId
    )
        external
        view
        returns (Price memory price);

    /// @dev Get the margin premium for a market. A margin premium makes it so that any positions that
    ///      include the market require a higher collateralization to avoid being liquidated.
    /// @param  marketId  The market to query
    /// @return premium The market's margin premium
    function getMarketMarginPremium(uint256 marketId)
        external
        view
        returns (D256 memory premium);

    /// @dev Get the total supplied and total borrowed values of an account adjusted by the marginPremium
    ///      of each market. Supplied values are divided by (1 + marginPremium) for each market and
    ///      borrowed values are multiplied by (1 + marginPremium) for each market. Comparing these
    ///      adjusted values gives the margin-ratio of the account which will be compared to the global
    ///      margin-ratio when determining if the account can be liquidated.
    /// @param account The account to query
    /// @return supplyValue The supplied value of the account (adjusted for marginPremium)
    /// @return borrowValue The borrowed value of the account (adjusted for marginPremium)
    function getAdjustedAccountValues(
        AccountInfo calldata account
    )
        external
        view
        returns (Value memory supplyValue, Value memory borrowValue);
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-erc20/contracts/src/LibERC20Token.sol";
import "@0x/contracts-exchange-libs/contracts/src/IWallet.sol";
import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "../interfaces/IERC20Bridge.sol";
import "../interfaces/IEth2Dai.sol";


// solhint-disable space-after-comma
contract Eth2DaiBridge is
    IERC20Bridge,
    IWallet,
    DeploymentConstants
{
    /// @dev Callback for `IERC20Bridge`. Tries to buy `amount` of
    ///      `toTokenAddress` tokens by selling the entirety of the opposing asset
    ///      (DAI or WETH) to the Eth2Dai contract, then transfers the bought
    ///      tokens to `to`.
    /// @param toTokenAddress The token to give to `to` (either DAI or WETH).
    /// @param from The maker (this contract).
    /// @param to The recipient of the bought tokens.
    /// @param amount Minimum amount of `toTokenAddress` tokens to buy.
    /// @param bridgeData The abi-encoeded "from" token address.
    /// @return success The magic bytes if successful.
    function bridgeTransferFrom(
        address toTokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success)
    {
        // Decode the bridge data to get the `fromTokenAddress`.
        (address fromTokenAddress) = abi.decode(bridgeData, (address));

        IEth2Dai exchange = IEth2Dai(_getEth2DaiAddress());
        uint256 fromTokenBalance = IERC20Token(fromTokenAddress).balanceOf(address(this));
        // Grant an allowance to the exchange to spend `fromTokenAddress` token.
        LibERC20Token.approveIfBelow(fromTokenAddress, address(exchange), fromTokenBalance);

        // Try to sell all of this contract's `fromTokenAddress` token balance.
        uint256 boughtAmount = exchange.sellAllAmount(
            fromTokenAddress,
            fromTokenBalance,
            toTokenAddress,
            amount
        );
        // Transfer the converted `toToken`s to `to`.
        LibERC20Token.transfer(toTokenAddress, to, boughtAmount);

        emit ERC20BridgeTransfer(
            fromTokenAddress,
            toTokenAddress,
            fromTokenBalance,
            boughtAmount,
            from,
            to
        );
        return BRIDGE_SUCCESS;
    }

    /// @dev `SignatureType.Wallet` callback, so that this bridge can be the maker
    ///      and sign for itself in orders. Always succeeds.
    /// @return magicValue Magic success bytes, always.
    function isValidSignature(
        bytes32,
        bytes calldata
    )
        external
        view
        returns (bytes4 magicValue)
    {
        return LEGACY_WALLET_MAGIC_VALUE;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


interface IEth2Dai {

    /// @dev Sell `sellAmount` of `fromToken` token and receive `toToken` token.
    /// @param fromToken The token being sold.
    /// @param sellAmount The amount of `fromToken` token being sold.
    /// @param toToken The token being bought.
    /// @param minFillAmount Minimum amount of `toToken` token to buy.
    /// @return fillAmount Amount of `toToken` bought.
    function sellAllAmount(
        address fromToken,
        uint256 sellAmount,
        address toToken,
        uint256 minFillAmount
    )
        external
        returns (uint256 fillAmount);
}

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-erc20/contracts/src/interfaces/IEtherToken.sol";
import "@0x/contracts-erc20/contracts/src/LibERC20Token.sol";
import "@0x/contracts-exchange-libs/contracts/src/IWallet.sol";
import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "@0x/contracts-utils/contracts/src/LibSafeMath.sol";
import "../interfaces/IERC20Bridge.sol";
import "../interfaces/IKyberNetworkProxy.sol";


// solhint-disable space-after-comma
contract KyberBridge is
    IERC20Bridge,
    IWallet,
    DeploymentConstants
{
    using LibSafeMath for uint256;

    // @dev Structure used internally to get around stack limits.
    struct TradeState {
        IKyberNetworkProxy kyber;
        IEtherToken weth;
        address fromTokenAddress;
        uint256 fromTokenBalance;
        uint256 payableAmount;
        uint256 conversionRate;
        bytes hint;
    }

    /// @dev Kyber ETH pseudo-address.
    address constant public KYBER_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev `bridgeTransferFrom()` failure result.
    bytes4 constant private BRIDGE_FAILED = 0x0;
    /// @dev Precision of Kyber rates.
    uint256 constant private KYBER_RATE_BASE = 10 ** 18;

    // solhint-disable no-empty-blocks
    /// @dev Payable fallback to receive ETH from Kyber/WETH.
    function ()
        external
        payable
    {
        // Poor man's receive in 0.5.9
        require(msg.data.length == 0);
    }

    /// @dev Callback for `IKyberBridge`. Tries to buy `amount` of
    ///      `toTokenAddress` tokens by selling the entirety of the opposing asset
    ///      to the `KyberNetworkProxy` contract, then transfers the bought
    ///      tokens to `to`.
    /// @param toTokenAddress The token to give to `to`.
    /// @param from The maker (this contract).
    /// @param to The recipient of the bought tokens.
    /// @param amount Minimum amount of `toTokenAddress` tokens to buy.
    /// @param bridgeData The abi-encoeded "from" token address.
    /// @return success The magic bytes if successful.
    function bridgeTransferFrom(
        address toTokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success)
    {
        TradeState memory state;
        state.kyber = IKyberNetworkProxy(_getKyberNetworkProxyAddress());
        state.weth = IEtherToken(_getWethAddress());
        // Decode the bridge data to get the `fromTokenAddress`.
        (state.fromTokenAddress, state.hint) = abi.decode(bridgeData, (address, bytes));
        // Query the balance of "from" tokens.
        state.fromTokenBalance = IERC20Token(state.fromTokenAddress).balanceOf(address(this));
        if (state.fromTokenBalance == 0) {
            // Return failure if no input tokens.
            return BRIDGE_FAILED;
        }
        if (state.fromTokenAddress == toTokenAddress) {
            // Just transfer the tokens if they're the same.
            LibERC20Token.transfer(state.fromTokenAddress, to, state.fromTokenBalance);
            return BRIDGE_SUCCESS;
        }
        if (state.fromTokenAddress == address(state.weth)) {
            // From WETH
            state.fromTokenAddress = KYBER_ETH_ADDRESS;
            state.payableAmount = state.fromTokenBalance;
            state.weth.withdraw(state.fromTokenBalance);
        } else {
            LibERC20Token.approveIfBelow(
                state.fromTokenAddress,
                address(state.kyber),
                state.fromTokenBalance
            );
        }
        bool isToTokenWeth = toTokenAddress == address(state.weth);

        // Try to sell all of this contract's input token balance through
        // `KyberNetworkProxy.trade()`.
        uint256 boughtAmount = state.kyber.tradeWithHint.value(state.payableAmount)(
            // Input token.
            state.fromTokenAddress,
            // Sell amount.
            state.fromTokenBalance,
            // Output token.
            isToTokenWeth ? KYBER_ETH_ADDRESS : toTokenAddress,
            // Transfer to this contract if converting to ETH, otherwise
            // transfer directly to the recipient.
            isToTokenWeth ? address(uint160(address(this))) : address(uint160(to)),
            // Buy as much as possible.
            uint256(-1),
            // The minimum conversion rate
            1,
            // No affiliate address.
            address(0),
            state.hint
        );
        // Wrap ETH output and transfer to recipient.
        if (isToTokenWeth) {
            state.weth.deposit.value(boughtAmount)();
            state.weth.transfer(to, boughtAmount);
        }

        emit ERC20BridgeTransfer(
            state.fromTokenAddress == KYBER_ETH_ADDRESS ? address(state.weth) : state.fromTokenAddress,
            toTokenAddress,
            state.fromTokenBalance,
            boughtAmount,
            from,
            to
        );
        return BRIDGE_SUCCESS;
    }

    /// @dev `SignatureType.Wallet` callback, so that this bridge can be the maker
    ///      and sign for itself in orders. Always succeeds.
    /// @return magicValue Magic success bytes, always.
    function isValidSignature(
        bytes32,
        bytes calldata
    )
        external
        view
        returns (bytes4 magicValue)
    {
        return LEGACY_WALLET_MAGIC_VALUE;
    }

}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


interface IKyberNetworkProxy {

    /// @dev Sells `sellTokenAddress` tokens for `buyTokenAddress` tokens.
    /// @param sellTokenAddress Token to sell.
    /// @param sellAmount Amount of tokens to sell.
    /// @param buyTokenAddress Token to buy.
    /// @param recipientAddress Address to send bought tokens to.
    /// @param maxBuyTokenAmount A limit on the amount of tokens to buy.
    /// @param minConversionRate The minimal conversion rate. If actual rate
    ///        is lower, trade is canceled.
    /// @param walletId The wallet ID to send part of the fees
    /// @return boughtAmount Amount of tokens bought.
    function trade(
        address sellTokenAddress,
        uint256 sellAmount,
        address buyTokenAddress,
        address payable recipientAddress,
        uint256 maxBuyTokenAmount,
        uint256 minConversionRate,
        address walletId
    )
        external
        payable
        returns (uint256 boughtAmount);

    /// @dev Sells `sellTokenAddress` tokens for `buyTokenAddress` tokens
    /// using a hint for the reserve.
    /// @param sellTokenAddress Token to sell.
    /// @param sellAmount Amount of tokens to sell.
    /// @param buyTokenAddress Token to buy.
    /// @param recipientAddress Address to send bought tokens to.
    /// @param maxBuyTokenAmount A limit on the amount of tokens to buy.
    /// @param minConversionRate The minimal conversion rate. If actual rate
    ///        is lower, trade is canceled.
    /// @param walletId The wallet ID to send part of the fees
    /// @param hint The hint for the selective inclusion (or exclusion) of reserves
    /// @return boughtAmount Amount of tokens bought.
    function tradeWithHint(
        address sellTokenAddress,
        uint256 sellAmount,
        address buyTokenAddress,
        address payable recipientAddress,
        uint256 maxBuyTokenAmount,
        uint256 minConversionRate,
        address payable walletId,
        bytes calldata hint
    )
        external
        payable
        returns (uint256 boughtAmount);
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-erc20/contracts/src/LibERC20Token.sol";
import "@0x/contracts-exchange-libs/contracts/src/IWallet.sol";
import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "../interfaces/IERC20Bridge.sol";
import "../interfaces/IMStable.sol";


contract MStableBridge is
    IERC20Bridge,
    IWallet,
    DeploymentConstants
{

    /// @dev Swaps specified tokens against the mStable mUSD contract
    /// @param toTokenAddress The token to give to `to` (i.e DAI, USDC, USDT).
    /// @param from The maker (this contract).
    /// @param to The recipient of the bought tokens.
    /// @param amount Minimum amount of `toTokenAddress` tokens to buy.
    /// @param bridgeData The abi-encoded "from" token address.
    /// @return success The magic bytes if successful.
    // solhint-disable no-unused-vars
    function bridgeTransferFrom(
        address toTokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success)
    {
        // Decode the bridge data to get the `fromTokenAddress`.
        (address fromTokenAddress) = abi.decode(bridgeData, (address));

        IMStable exchange = IMStable(_getMUsdAddress());
        uint256 fromTokenBalance = IERC20Token(fromTokenAddress).balanceOf(address(this));
        // Grant an allowance to the exchange to spend `fromTokenAddress` token.
        LibERC20Token.approveIfBelow(fromTokenAddress, address(exchange), fromTokenBalance);

        // Try to sell all of this contract's `fromTokenAddress` token balance.
        uint256 boughtAmount = exchange.swap(
            fromTokenAddress,
            toTokenAddress,
            fromTokenBalance,
            to
        );

        emit ERC20BridgeTransfer(
            fromTokenAddress,
            toTokenAddress,
            fromTokenBalance,
            boughtAmount,
            from,
            to
        );
        return BRIDGE_SUCCESS;
    }

    /// @dev `SignatureType.Wallet` callback, so that this bridge can be the maker
    ///      and sign for itself in orders. Always succeeds.
    /// @return magicValue Magic success bytes, always.
    function isValidSignature(
        bytes32,
        bytes calldata
    )
        external
        view
        returns (bytes4 magicValue)
    {
        return LEGACY_WALLET_MAGIC_VALUE;
    }
}

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


interface IMStable {

    function swap(
        address _input,
        address _output,
        uint256 _quantity,
        address _recipient
    )
        external
        returns (uint256 output);
}

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-erc20/contracts/src/interfaces/IEtherToken.sol";
import "@0x/contracts-erc20/contracts/src/LibERC20Token.sol";
import "@0x/contracts-exchange-libs/contracts/src/IWallet.sol";
import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "../interfaces/IERC20Bridge.sol";
import "../interfaces/IMooniswap.sol";


// solhint-disable space-after-comma
// solhint-disable not-rely-on-time
contract MooniswapBridge is
    IERC20Bridge,
    IWallet,
    DeploymentConstants
{

    struct TransferState {
        IMooniswap pool;
        uint256 fromTokenBalance;
        IEtherToken weth;
        uint256 boughtAmount;
        address fromTokenAddress;
        address toTokenAddress;
    }

    // solhint-disable no-empty-blocks
    /// @dev Payable fallback to receive ETH from uniswap.
    function ()
        external
        payable
    {}

    /// @dev Callback for `IERC20Bridge`. Tries to buy `amount` of
    ///      `toTokenAddress` tokens by selling the entirety of the `fromTokenAddress`
    ///      token encoded in the bridge data.
    /// @param toTokenAddress The token to buy and transfer to `to`.
    /// @param from The maker (this contract).
    /// @param to The recipient of the bought tokens.
    /// @param amount Minimum amount of `toTokenAddress` tokens to buy.
    /// @param bridgeData The abi-encoded path of token addresses. Last element must be toTokenAddress
    /// @return success The magic bytes if successful.
    function bridgeTransferFrom(
        address toTokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success)
    {
        // State memory object to avoid stack overflows.
        TransferState memory state;
        // Decode the bridge data to get the `fromTokenAddress`.
        address fromTokenAddress = abi.decode(bridgeData, (address));
        // Get the weth contract.
        state.weth = IEtherToken(_getWethAddress());
        // Get our balance of `fromTokenAddress` token.
        state.fromTokenBalance = IERC20Token(fromTokenAddress).balanceOf(address(this));

        state.fromTokenAddress = fromTokenAddress == address(state.weth) ? address(0) : fromTokenAddress;
        state.toTokenAddress = toTokenAddress == address(state.weth) ? address(0) : toTokenAddress;
        state.pool = IMooniswap(
            IMooniswapRegistry(_getMooniswapAddress()).pools(
                state.fromTokenAddress,
                state.toTokenAddress
            )
        );

        // withdraw WETH to ETH
        if (state.fromTokenAddress == address(0)) {
            state.weth.withdraw(state.fromTokenBalance);
        } else {
            // Grant the pool an allowance.
            LibERC20Token.approveIfBelow(
                state.fromTokenAddress,
                address(state.pool),
                state.fromTokenBalance
            );
        }
        uint256 ethValue = state.fromTokenAddress == address(0) ? state.fromTokenBalance : 0;
        state.boughtAmount = state.pool.swap.value(ethValue)(
            state.fromTokenAddress,
            state.toTokenAddress,
            state.fromTokenBalance,
            amount,
            address(0)
        );
        // Deposit to WETH
        if (state.toTokenAddress == address(0)) {
            state.weth.deposit.value(state.boughtAmount)();
        }

        // Transfer funds to `to`
        LibERC20Token.transfer(toTokenAddress, to, state.boughtAmount);

        emit ERC20BridgeTransfer(
            // input token
            fromTokenAddress,
            // output token
            toTokenAddress,
            // input token amount
            state.fromTokenBalance,
            // output token amount
            state.boughtAmount,
            from,
            to
        );

        return BRIDGE_SUCCESS;
    }

    /// @dev `SignatureType.Wallet` callback, so that this bridge can be the maker
    ///      and sign for itself in orders. Always succeeds.
    /// @return magicValue Success bytes, always.
    function isValidSignature(
        bytes32,
        bytes calldata
    )
        external
        view
        returns (bytes4 magicValue)
    {
        return LEGACY_WALLET_MAGIC_VALUE;
    }
}

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


interface IMooniswapRegistry {

    function pools(address token1, address token2) external view returns(address);
}


interface IMooniswap {

    function swap(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        address referral
    )
        external
        payable
        returns(uint256 returnAmount);
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-erc20/contracts/src/LibERC20Token.sol";
import "@0x/contracts-exchange-libs/contracts/src/IWallet.sol";
import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "../interfaces/IERC20Bridge.sol";
import "../interfaces/IShell.sol";


contract ShellBridge is
    IERC20Bridge,
    IWallet,
    DeploymentConstants
{

    /// @dev Swaps specified tokens against the Shell contract
    /// @param toTokenAddress The token to give to `to`.
    /// @param from The maker (this contract).
    /// @param to The recipient of the bought tokens.
    /// @param amount Minimum amount of `toTokenAddress` tokens to buy.
    /// @param bridgeData The abi-encoded "from" token address.
    /// @return success The magic bytes if successful.
    // solhint-disable no-unused-vars
    function bridgeTransferFrom(
        address toTokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success)
    {
        // Decode the bridge data to get the `fromTokenAddress` and `pool`.
        (address fromTokenAddress, address pool) = abi.decode(bridgeData, (address, address));

        uint256 fromTokenBalance = IERC20Token(fromTokenAddress).balanceOf(address(this));
        // Grant an allowance to the exchange to spend `fromTokenAddress` token.
        LibERC20Token.approveIfBelow(fromTokenAddress, pool, fromTokenBalance);

        // Try to sell all of this contract's `fromTokenAddress` token balance.
        uint256 boughtAmount = IShell(pool).originSwap(
            fromTokenAddress,
            toTokenAddress,
            fromTokenBalance,
            amount, // min amount
            block.timestamp + 1
        );
        LibERC20Token.transfer(toTokenAddress, to, boughtAmount);

        emit ERC20BridgeTransfer(
            fromTokenAddress,
            toTokenAddress,
            fromTokenBalance,
            boughtAmount,
            from,
            to
        );
        return BRIDGE_SUCCESS;
    }

    /// @dev `SignatureType.Wallet` callback, so that this bridge can be the maker
    ///      and sign for itself in orders. Always succeeds.
    /// @return magicValue Magic success bytes, always.
    function isValidSignature(
        bytes32,
        bytes calldata
    )
        external
        view
        returns (bytes4 magicValue)
    {
        return LEGACY_WALLET_MAGIC_VALUE;
    }
}

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


interface IShell {

    function originSwap(
        address from,
        address to,
        uint256 fromAmount,
        uint256 minTargetAmount,
        uint256 deadline
    )
        external
        returns (uint256 toAmount);
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-erc20/contracts/src/LibERC20Token.sol";
import "@0x/contracts-exchange-libs/contracts/src/IWallet.sol";
import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "../interfaces/IERC20Bridge.sol";
import "../interfaces/ICurve.sol";


// solhint-disable not-rely-on-time
// solhint-disable space-after-comma
contract SnowSwapBridge is
    IERC20Bridge,
    IWallet,
    DeploymentConstants
{
    struct SnowSwapBridgeData {
        address curveAddress;
        bytes4 exchangeFunctionSelector;
        address fromTokenAddress;
        int128 fromCoinIdx;
        int128 toCoinIdx;
    }

    /// @dev Callback for `ICurve`. Tries to buy `amount` of
    ///      `toTokenAddress` tokens by selling the entirety of the opposing asset
    ///      (DAI, USDC) to the Curve contract, then transfers the bought
    ///      tokens to `to`.
    /// @param toTokenAddress The token to give to `to` (i.e DAI, USDC, USDT).
    /// @param from The maker (this contract).
    /// @param to The recipient of the bought tokens.
    /// @param amount Minimum amount of `toTokenAddress` tokens to buy.
    /// @param bridgeData The abi-encoeded "from" token address.
    /// @return success The magic bytes if successful.
    function bridgeTransferFrom(
        address toTokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success)
    {
        // Decode the bridge data to get the SnowSwap metadata.
        SnowSwapBridgeData memory data = abi.decode(bridgeData, (SnowSwapBridgeData));

        require(toTokenAddress != data.fromTokenAddress, "SnowSwapBridge/INVALID_PAIR");
        uint256 fromTokenBalance = IERC20Token(data.fromTokenAddress).balanceOf(address(this));
        // Grant an allowance to the exchange to spend `fromTokenAddress` token.
        LibERC20Token.approveIfBelow(data.fromTokenAddress, data.curveAddress, fromTokenBalance);

        // Try to sell all of this contract's `fromTokenAddress` token balance.
        {
            (bool didSucceed, bytes memory resultData) =
                data.curveAddress.call(abi.encodeWithSelector(
                    data.exchangeFunctionSelector,
                    data.fromCoinIdx,
                    data.toCoinIdx,
                    // dx
                    fromTokenBalance,
                    // min dy
                    amount
                ));
            if (!didSucceed) {
                assembly { revert(add(resultData, 32), mload(resultData)) }
            }
        }

        uint256 toTokenBalance = IERC20Token(toTokenAddress).balanceOf(address(this));
        // Transfer the converted `toToken`s to `to`.
        LibERC20Token.transfer(toTokenAddress, to, toTokenBalance);

        emit ERC20BridgeTransfer(
            data.fromTokenAddress,
            toTokenAddress,
            fromTokenBalance,
            toTokenBalance,
            from,
            to
        );
        return BRIDGE_SUCCESS;
    }

    /// @dev `SignatureType.Wallet` callback, so that this bridge can be the maker
    ///      and sign for itself in orders. Always succeeds.
    /// @return magicValue Magic success bytes, always.
    function isValidSignature(
        bytes32,
        bytes calldata
    )
        external
        view
        returns (bytes4 magicValue)
    {
        return LEGACY_WALLET_MAGIC_VALUE;
    }
}

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-erc20/contracts/src/interfaces/IEtherToken.sol";
import "@0x/contracts-erc20/contracts/src/LibERC20Token.sol";
import "@0x/contracts-exchange-libs/contracts/src/IWallet.sol";
import "@0x/contracts-utils/contracts/src/LibAddressArray.sol";
import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "../interfaces/IUniswapV2Router01.sol";
import "../interfaces/IERC20Bridge.sol";


// solhint-disable space-after-comma
// solhint-disable not-rely-on-time
contract SushiSwapBridge is
    IERC20Bridge,
    IWallet,
    DeploymentConstants
{
    struct TransferState {
        address[] path;
        address router;
        uint256 fromTokenBalance;
    }

    /// @dev Callback for `IERC20Bridge`. Tries to buy `amount` of
    ///      `toTokenAddress` tokens by selling the entirety of the `fromTokenAddress`
    ///      token encoded in the bridge data.
    /// @param toTokenAddress The token to buy and transfer to `to`.
    /// @param from The maker (this contract).
    /// @param to The recipient of the bought tokens.
    /// @param amount Minimum amount of `toTokenAddress` tokens to buy.
    /// @param bridgeData The abi-encoded path of token addresses. Last element must be toTokenAddress
    /// @return success The magic bytes if successful.
    function bridgeTransferFrom(
        address toTokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success)
    {
        // hold variables to get around stack depth limitations
        TransferState memory state;

        // Decode the bridge data to get the `fromTokenAddress`.
        // solhint-disable indent
        (state.path, state.router) = abi.decode(bridgeData, (address[], address));
        // solhint-enable indent

        require(state.path.length >= 2, "SushiSwapBridge/PATH_LENGTH_MUST_BE_AT_LEAST_TWO");
        require(state.path[state.path.length - 1] == toTokenAddress, "SushiSwapBridge/LAST_ELEMENT_OF_PATH_MUST_MATCH_OUTPUT_TOKEN");

        // Just transfer the tokens if they're the same.
        if (state.path[0] == toTokenAddress) {
            LibERC20Token.transfer(state.path[0], to, amount);
            return BRIDGE_SUCCESS;
        }

        // Get our balance of `fromTokenAddress` token.
        state.fromTokenBalance = IERC20Token(state.path[0]).balanceOf(address(this));

        // Grant the SushiSwap router an allowance.
        LibERC20Token.approveIfBelow(
            state.path[0],
            state.router,
            state.fromTokenBalance
        );

        // Buy as much `toTokenAddress` token with `fromTokenAddress` token
        // and transfer it to `to`.
        IUniswapV2Router01 router = IUniswapV2Router01(state.router);
        uint[] memory amounts = router.swapExactTokensForTokens(
             // Sell all tokens we hold.
            state.fromTokenBalance,
             // Minimum buy amount.
            amount,
            // Convert `fromTokenAddress` to `toTokenAddress`.
            state.path,
            // Recipient is `to`.
            to,
            // Expires after this block.
            block.timestamp
        );

        emit ERC20BridgeTransfer(
            // input token
            state.path[0],
            // output token
            toTokenAddress,
            // input token amount
            state.fromTokenBalance,
            // output token amount
            amounts[amounts.length - 1],
            from,
            to
        );

        return BRIDGE_SUCCESS;
    }

    /// @dev `SignatureType.Wallet` callback, so that this bridge can be the maker
    ///      and sign for itself in orders. Always succeeds.
    /// @return magicValue Success bytes, always.
    function isValidSignature(
        bytes32,
        bytes calldata
    )
        external
        view
        returns (bytes4 magicValue)
    {
        return LEGACY_WALLET_MAGIC_VALUE;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-erc20/contracts/src/LibERC20Token.sol";
import "@0x/contracts-exchange-libs/contracts/src/IWallet.sol";
import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "../interfaces/IERC20Bridge.sol";
import "../interfaces/ICurve.sol";


// solhint-disable not-rely-on-time
// solhint-disable space-after-comma
contract SwerveBridge is
    IERC20Bridge,
    IWallet,
    DeploymentConstants
{
    struct SwerveBridgeData {
        address curveAddress;
        bytes4 exchangeFunctionSelector;
        address fromTokenAddress;
        int128 fromCoinIdx;
        int128 toCoinIdx;
    }

    /// @dev Callback for `ICurve`. Tries to buy `amount` of
    ///      `toTokenAddress` tokens by selling the entirety of the opposing asset
    ///      (DAI, USDC) to the Curve contract, then transfers the bought
    ///      tokens to `to`.
    /// @param toTokenAddress The token to give to `to` (i.e DAI, USDC, USDT).
    /// @param from The maker (this contract).
    /// @param to The recipient of the bought tokens.
    /// @param amount Minimum amount of `toTokenAddress` tokens to buy.
    /// @param bridgeData The abi-encoeded "from" token address.
    /// @return success The magic bytes if successful.
    function bridgeTransferFrom(
        address toTokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success)
    {
        // Decode the bridge data to get the SwerveBridgeData metadata.
        SwerveBridgeData memory data = abi.decode(bridgeData, (SwerveBridgeData));

        require(toTokenAddress != data.fromTokenAddress, "SwerveBridge/INVALID_PAIR");
        uint256 fromTokenBalance = IERC20Token(data.fromTokenAddress).balanceOf(address(this));
        // Grant an allowance to the exchange to spend `fromTokenAddress` token.
        LibERC20Token.approveIfBelow(data.fromTokenAddress, data.curveAddress, fromTokenBalance);

        // Try to sell all of this contract's `fromTokenAddress` token balance.
        {
            (bool didSucceed, bytes memory resultData) =
                data.curveAddress.call(abi.encodeWithSelector(
                    data.exchangeFunctionSelector,
                    data.fromCoinIdx,
                    data.toCoinIdx,
                    // dx
                    fromTokenBalance,
                    // min dy
                    amount
                ));
            if (!didSucceed) {
                assembly { revert(add(resultData, 32), mload(resultData)) }
            }
        }

        uint256 toTokenBalance = IERC20Token(toTokenAddress).balanceOf(address(this));
        // Transfer the converted `toToken`s to `to`.
        LibERC20Token.transfer(toTokenAddress, to, toTokenBalance);

        emit ERC20BridgeTransfer(
            data.fromTokenAddress,
            toTokenAddress,
            fromTokenBalance,
            toTokenBalance,
            from,
            to
        );
        return BRIDGE_SUCCESS;
    }

    /// @dev `SignatureType.Wallet` callback, so that this bridge can be the maker
    ///      and sign for itself in orders. Always succeeds.
    /// @return magicValue Magic success bytes, always.
    function isValidSignature(
        bytes32,
        bytes calldata
    )
        external
        view
        returns (bytes4 magicValue)
    {
        return LEGACY_WALLET_MAGIC_VALUE;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-erc20/contracts/src/interfaces/IEtherToken.sol";
import "@0x/contracts-erc20/contracts/src/LibERC20Token.sol";
import "@0x/contracts-exchange-libs/contracts/src/IWallet.sol";
import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "../interfaces/IUniswapExchangeFactory.sol";
import "../interfaces/IUniswapExchange.sol";
import "../interfaces/IERC20Bridge.sol";


// solhint-disable space-after-comma
// solhint-disable not-rely-on-time
contract UniswapBridge is
    IERC20Bridge,
    IWallet,
    DeploymentConstants
{
    // Struct to hold `bridgeTransferFrom()` local variables in memory and to avoid
    // stack overflows.
    struct TransferState {
        IUniswapExchange exchange;
        uint256 fromTokenBalance;
        IEtherToken weth;
        uint256 boughtAmount;
    }

    // solhint-disable no-empty-blocks
    /// @dev Payable fallback to receive ETH from uniswap.
    function ()
        external
        payable
    {}

    /// @dev Callback for `IERC20Bridge`. Tries to buy `amount` of
    ///      `toTokenAddress` tokens by selling the entirety of the `fromTokenAddress`
    ///      token encoded in the bridge data.
    /// @param toTokenAddress The token to buy and transfer to `to`.
    /// @param from The maker (this contract).
    /// @param to The recipient of the bought tokens.
    /// @param amount Minimum amount of `toTokenAddress` tokens to buy.
    /// @param bridgeData The abi-encoded "from" token address.
    /// @return success The magic bytes if successful.
    function bridgeTransferFrom(
        address toTokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success)
    {
        // State memory object to avoid stack overflows.
        TransferState memory state;
        // Decode the bridge data to get the `fromTokenAddress`.
        (address fromTokenAddress) = abi.decode(bridgeData, (address));

        // Just transfer the tokens if they're the same.
        if (fromTokenAddress == toTokenAddress) {
            LibERC20Token.transfer(fromTokenAddress, to, amount);
            return BRIDGE_SUCCESS;
        }

        // Get the exchange for the token pair.
        state.exchange = _getUniswapExchangeForTokenPair(
            fromTokenAddress,
            toTokenAddress
        );
        // Get our balance of `fromTokenAddress` token.
        state.fromTokenBalance = IERC20Token(fromTokenAddress).balanceOf(address(this));
        // Get the weth contract.
        state.weth = IEtherToken(_getWethAddress());

        // Convert from WETH to a token.
        if (fromTokenAddress == address(state.weth)) {
            // Unwrap the WETH.
            state.weth.withdraw(state.fromTokenBalance);
            // Buy as much of `toTokenAddress` token with ETH as possible and
            // transfer it to `to`.
            state.boughtAmount = state.exchange.ethToTokenTransferInput.value(state.fromTokenBalance)(
                // Minimum buy amount.
                amount,
                // Expires after this block.
                block.timestamp,
                // Recipient is `to`.
                to
            );

        // Convert from a token to WETH.
        } else if (toTokenAddress == address(state.weth)) {
            // Grant the exchange an allowance.
            _grantExchangeAllowance(state.exchange, fromTokenAddress, state.fromTokenBalance);
            // Buy as much ETH with `fromTokenAddress` token as possible.
            state.boughtAmount = state.exchange.tokenToEthSwapInput(
                // Sell all tokens we hold.
                state.fromTokenBalance,
                // Minimum buy amount.
                amount,
                // Expires after this block.
                block.timestamp
            );
            // Wrap the ETH.
            state.weth.deposit.value(state.boughtAmount)();
            // Transfer the WETH to `to`.
            IEtherToken(toTokenAddress).transfer(to, state.boughtAmount);

        // Convert from one token to another.
        } else {
            // Grant the exchange an allowance.
            _grantExchangeAllowance(state.exchange, fromTokenAddress, state.fromTokenBalance);
            // Buy as much `toTokenAddress` token with `fromTokenAddress` token
            // and transfer it to `to`.
            state.boughtAmount = state.exchange.tokenToTokenTransferInput(
                // Sell all tokens we hold.
                state.fromTokenBalance,
                // Minimum buy amount.
                amount,
                // Must buy at least 1 intermediate ETH.
                1,
                // Expires after this block.
                block.timestamp,
                // Recipient is `to`.
                to,
                // Convert to `toTokenAddress`.
                toTokenAddress
            );
        }

        emit ERC20BridgeTransfer(
            fromTokenAddress,
            toTokenAddress,
            state.fromTokenBalance,
            state.boughtAmount,
            from,
            to
        );
        return BRIDGE_SUCCESS;
    }

    /// @dev `SignatureType.Wallet` callback, so that this bridge can be the maker
    ///      and sign for itself in orders. Always succeeds.
    /// @return magicValue Success bytes, always.
    function isValidSignature(
        bytes32,
        bytes calldata
    )
        external
        view
        returns (bytes4 magicValue)
    {
        return LEGACY_WALLET_MAGIC_VALUE;
    }

    /// @dev Grants an unlimited allowance to the exchange for its token
    ///      on behalf of this contract.
    /// @param exchange The Uniswap token exchange.
    /// @param tokenAddress The token address for the exchange.
    /// @param minimumAllowance The minimum necessary allowance.
    function _grantExchangeAllowance(
        IUniswapExchange exchange,
        address tokenAddress,
        uint256 minimumAllowance
    )
        private
    {
        LibERC20Token.approveIfBelow(
            tokenAddress,
            address(exchange),
            minimumAllowance
        );
    }

    /// @dev Retrieves the uniswap exchange for a given token pair.
    ///      In the case of a WETH-token exchange, this will be the non-WETH token.
    ///      In th ecase of a token-token exchange, this will be the first token.
    /// @param fromTokenAddress The address of the token we are converting from.
    /// @param toTokenAddress The address of the token we are converting to.
    /// @return exchange The uniswap exchange.
    function _getUniswapExchangeForTokenPair(
        address fromTokenAddress,
        address toTokenAddress
    )
        private
        view
        returns (IUniswapExchange exchange)
    {
        address exchangeTokenAddress = fromTokenAddress;
        // Whichever isn't WETH is the exchange token.
        if (fromTokenAddress == _getWethAddress()) {
            exchangeTokenAddress = toTokenAddress;
        }
        exchange = IUniswapExchange(
            IUniswapExchangeFactory(_getUniswapExchangeFactoryAddress())
            .getExchange(exchangeTokenAddress)
        );
        require(address(exchange) != address(0), "NO_UNISWAP_EXCHANGE_FOR_TOKEN");
        return exchange;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "./IUniswapExchange.sol";


interface IUniswapExchangeFactory {

    /// @dev Get the exchange for a token.
    /// @param tokenAddress The address of the token contract.
    function getExchange(address tokenAddress)
        external
        view
        returns (address);
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


interface IUniswapExchange {

    /// @dev Buys at least `minTokensBought` tokens with ETH and transfer them
    ///      to `recipient`.
    /// @param minTokensBought The minimum number of tokens to buy.
    /// @param deadline Time when this order expires.
    /// @param recipient Who to transfer the tokens to.
    /// @return tokensBought Amount of tokens bought.
    function ethToTokenTransferInput(
        uint256 minTokensBought,
        uint256 deadline,
        address recipient
    )
        external
        payable
        returns (uint256 tokensBought);

    /// @dev Buys at least `minEthBought` ETH with tokens.
    /// @param tokensSold Amount of tokens to sell.
    /// @param minEthBought The minimum amount of ETH to buy.
    /// @param deadline Time when this order expires.
    /// @return ethBought Amount of tokens bought.
    function tokenToEthSwapInput(
        uint256 tokensSold,
        uint256 minEthBought,
        uint256 deadline
    )
        external
        returns (uint256 ethBought);

    /// @dev Buys at least `minTokensBought` tokens with the exchange token
    ///      and transfer them to `recipient`.
    /// @param minTokensBought The minimum number of tokens to buy.
    /// @param minEthBought The minimum amount of intermediate ETH to buy.
    /// @param deadline Time when this order expires.
    /// @param recipient Who to transfer the tokens to.
    /// @param toTokenAddress The token being bought.
    /// @return tokensBought Amount of tokens bought.
    function tokenToTokenTransferInput(
        uint256 tokensSold,
        uint256 minTokensBought,
        uint256 minEthBought,
        uint256 deadline,
        address recipient,
        address toTokenAddress
    )
        external
        returns (uint256 tokensBought);
}

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-erc20/contracts/src/interfaces/IEtherToken.sol";
import "@0x/contracts-erc20/contracts/src/LibERC20Token.sol";
import "@0x/contracts-exchange-libs/contracts/src/IWallet.sol";
import "@0x/contracts-utils/contracts/src/LibAddressArray.sol";
import "@0x/contracts-utils/contracts/src/DeploymentConstants.sol";
import "../interfaces/IUniswapV2Router01.sol";
import "../interfaces/IERC20Bridge.sol";


// solhint-disable space-after-comma
// solhint-disable not-rely-on-time
contract UniswapV2Bridge is
    IERC20Bridge,
    IWallet,
    DeploymentConstants
{
    struct TransferState {
        address[] path;
        uint256 fromTokenBalance;
    }

    /// @dev Callback for `IERC20Bridge`. Tries to buy `amount` of
    ///      `toTokenAddress` tokens by selling the entirety of the `fromTokenAddress`
    ///      token encoded in the bridge data.
    /// @param toTokenAddress The token to buy and transfer to `to`.
    /// @param from The maker (this contract).
    /// @param to The recipient of the bought tokens.
    /// @param amount Minimum amount of `toTokenAddress` tokens to buy.
    /// @param bridgeData The abi-encoded path of token addresses. Last element must be toTokenAddress
    /// @return success The magic bytes if successful.
    function bridgeTransferFrom(
        address toTokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4 success)
    {
        // hold variables to get around stack depth limitations
        TransferState memory state;

        // Decode the bridge data to get the `fromTokenAddress`.
        // solhint-disable indent
        state.path = abi.decode(bridgeData, (address[]));
        // solhint-enable indent

        require(state.path.length >= 2, "UniswapV2Bridge/PATH_LENGTH_MUST_BE_AT_LEAST_TWO");
        require(state.path[state.path.length - 1] == toTokenAddress, "UniswapV2Bridge/LAST_ELEMENT_OF_PATH_MUST_MATCH_OUTPUT_TOKEN");

        // Just transfer the tokens if they're the same.
        if (state.path[0] == toTokenAddress) {
            LibERC20Token.transfer(state.path[0], to, amount);
            return BRIDGE_SUCCESS;
        }

        // Get our balance of `fromTokenAddress` token.
        state.fromTokenBalance = IERC20Token(state.path[0]).balanceOf(address(this));

        // Grant the Uniswap router an allowance.
        LibERC20Token.approveIfBelow(
            state.path[0],
            _getUniswapV2Router01Address(),
            state.fromTokenBalance
        );

        // Buy as much `toTokenAddress` token with `fromTokenAddress` token
        // and transfer it to `to`.
        IUniswapV2Router01 router = IUniswapV2Router01(_getUniswapV2Router01Address());
        uint[] memory amounts = router.swapExactTokensForTokens(
             // Sell all tokens we hold.
            state.fromTokenBalance,
             // Minimum buy amount.
            amount,
            // Convert `fromTokenAddress` to `toTokenAddress`.
            state.path,
            // Recipient is `to`.
            to,
            // Expires after this block.
            block.timestamp
        );

        emit ERC20BridgeTransfer(
            // input token
            state.path[0],
            // output token
            toTokenAddress,
            // input token amount
            state.fromTokenBalance,
            // output token amount
            amounts[amounts.length - 1],
            from,
            to
        );

        return BRIDGE_SUCCESS;
    }

    /// @dev `SignatureType.Wallet` callback, so that this bridge can be the maker
    ///      and sign for itself in orders. Always succeeds.
    /// @return magicValue Success bytes, always.
    function isValidSignature(
        bytes32,
        bytes calldata
    )
        external
        view
        returns (bytes4 magicValue)
    {
        return LEGACY_WALLET_MAGIC_VALUE;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

// solhint-disable
pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;


// @dev Interface of the asset proxy's assetData.
// The asset proxies take an ABI encoded `bytes assetData` as argument.
// This argument is ABI encoded as one of the methods of this interface.
interface IAssetData {

    /// @dev Function signature for encoding ERC20 assetData.
    /// @param tokenAddress Address of ERC20Token contract.
    function ERC20Token(address tokenAddress)
        external;

    /// @dev Function signature for encoding ERC721 assetData.
    /// @param tokenAddress Address of ERC721 token contract.
    /// @param tokenId Id of ERC721 token to be transferred.
    function ERC721Token(
        address tokenAddress,
        uint256 tokenId
    )
        external;

    /// @dev Function signature for encoding ERC1155 assetData.
    /// @param tokenAddress Address of ERC1155 token contract.
    /// @param tokenIds Array of ids of tokens to be transferred.
    /// @param values Array of values that correspond to each token id to be transferred.
    ///        Note that each value will be multiplied by the amount being filled in the order before transferring.
    /// @param callbackData Extra data to be passed to receiver's `onERC1155Received` callback function.
    function ERC1155Assets(
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata values,
        bytes calldata callbackData
    )
        external;

    /// @dev Function signature for encoding MultiAsset assetData.
    /// @param values Array of amounts that correspond to each asset to be transferred.
    ///        Note that each value will be multiplied by the amount being filled in the order before transferring.
    /// @param nestedAssetData Array of assetData fields that will be be dispatched to their correspnding AssetProxy contract.
    function MultiAsset(
        uint256[] calldata values,
        bytes[] calldata nestedAssetData
    )
        external;

    /// @dev Function signature for encoding StaticCall assetData.
    /// @param staticCallTargetAddress Address that will execute the staticcall.
    /// @param staticCallData Data that will be executed via staticcall on the staticCallTargetAddress.
    /// @param expectedReturnDataHash Keccak-256 hash of the expected staticcall return data.
    function StaticCall(
        address staticCallTargetAddress,
        bytes calldata staticCallData,
        bytes32 expectedReturnDataHash
    )
        external;

    /// @dev Function signature for encoding ERC20Bridge assetData.
    /// @param tokenAddress Address of token to transfer.
    /// @param bridgeAddress Address of the bridge contract.
    /// @param bridgeData Arbitrary data to be passed to the bridge contract.
    function ERC20Bridge(
        address tokenAddress,
        address bridgeAddress,
        bytes calldata bridgeData
    )
        external;
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-utils/contracts/src/LibSafeMath.sol";
import "@0x/contracts-utils/contracts/src/LibAddressArray.sol";
import "../src/bridges/BancorBridge.sol";
import "../src/interfaces/IBancorNetwork.sol";


contract TestEventsRaiser {

    event TokenTransfer(
        address token,
        address from,
        address to,
        uint256 amount
    );

    event TokenApprove(
        address spender,
        uint256 allowance
    );

    event ConvertByPathInput(
        uint amountIn,
        uint amountOutMin,
        address toTokenAddress,
        address to,
        address feeRecipient,
        uint256 feeAmount
    );

    function raiseTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        external
    {
        emit TokenTransfer(
            msg.sender,
            from,
            to,
            amount
        );
    }

    function raiseTokenApprove(address spender, uint256 allowance) external {
        emit TokenApprove(spender, allowance);
    }

    function raiseConvertByPathInput(
        uint amountIn,
        uint amountOutMin,
        address toTokenAddress,
        address to,
        address feeRecipient,
        uint256 feeAmount
    ) external
    {
        emit ConvertByPathInput(
            amountIn,
            amountOutMin,
            toTokenAddress,
            to,
            feeRecipient,
            feeAmount
        );
    }
}


/// @dev A minimalist ERC20 token.
contract TestToken {

    using LibSafeMath for uint256;

    mapping (address => uint256) public balances;
    string private _nextRevertReason;

    /// @dev Set the balance for `owner`.
    function setBalance(address owner, uint256 balance)
        external
        payable
    {
        balances[owner] = balance;
    }

    /// @dev Just emits a TokenTransfer event on the caller
    function transfer(address to, uint256 amount)
        external
        returns (bool)
    {
        TestEventsRaiser(msg.sender).raiseTokenTransfer(msg.sender, to, amount);
        return true;
    }

    /// @dev Just emits a TokenApprove event on the caller
    function approve(address spender, uint256 allowance)
        external
        returns (bool)
    {
        TestEventsRaiser(msg.sender).raiseTokenApprove(spender, allowance);
        return true;
    }

    function allowance(address, address) external view returns (uint256) {
        return 0;
    }

    /// @dev Retrieve the balance for `owner`.
    function balanceOf(address owner)
        external
        view
        returns (uint256)
    {
        return balances[owner];
    }
}


/// @dev Mock the BancorNetwork contract
contract TestBancorNetwork is
    IBancorNetwork
{
    string private _nextRevertReason;

    /// @dev Set the revert reason for `swapExactTokensForTokens`.
    function setRevertReason(string calldata reason)
        external
    {
        _nextRevertReason = reason;
    }

    function convertByPath(
        address[] calldata _path,
        uint256 _amount,
        uint256 _minReturn,
        address _beneficiary,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) external payable returns (uint256)
    {
        _revertIfReasonExists();

        TestEventsRaiser(msg.sender).raiseConvertByPathInput(
            // tokens sold
            _amount,
            // tokens bought
            _minReturn,
            // output token
            _path[_path.length - 1],
            // recipient
            _beneficiary,
            // fee recipient
            _affiliateAccount,
            // fee amount
            _affiliateFee
        );
    }

    function _revertIfReasonExists()
        private
        view
    {
        if (bytes(_nextRevertReason).length != 0) {
            revert(_nextRevertReason);
        }
    }

}


/// @dev BancorBridge overridden to mock tokens and BancorNetwork
contract TestBancorBridge is
    BancorBridge,
    TestEventsRaiser
{

    // Token address to TestToken instance.
    mapping (address => TestToken) private _testTokens;
    // TestRouter instance.
    TestBancorNetwork private _testNetwork;

    constructor() public {
        _testNetwork = new TestBancorNetwork();
    }

    function setNetworkRevertReason(string calldata revertReason)
        external
    {
        _testNetwork.setRevertReason(revertReason);
    }

    /// @dev Sets the balance of this contract for an existing token.
    function setTokenBalance(address tokenAddress, uint256 balance)
        external
    {
        TestToken token = _testTokens[tokenAddress];
        token.setBalance(address(this), balance);
    }

    /// @dev Create a new token
    /// @param tokenAddress The token address. If zero, one will be created.
    function createToken(
        address tokenAddress
    )
        external
        returns (TestToken token)
    {
        token = TestToken(tokenAddress);
        if (tokenAddress == address(0)) {
            token = new TestToken();
        }
        _testTokens[address(token)] = token;

        return token;
    }

    function getNetworkAddress()
        external
        view
        returns (address)
    {
        return address(_testNetwork);
    }

}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../src/bridges/ChaiBridge.sol";
import "@0x/contracts-erc20/contracts/src/ERC20Token.sol";


contract TestChaiDai is
    ERC20Token
{
    address private constant ALWAYS_REVERT_ADDRESS = address(1);

    function draw(
        address from,
        uint256 amount
    )
        external
    {
        if (from == ALWAYS_REVERT_ADDRESS) {
            revert();
        }
        balances[msg.sender] += amount;
    }
}


contract TestChaiBridge is
    ChaiBridge
{
    address public testChaiDai;
    address private constant ALWAYS_REVERT_ADDRESS = address(1);

    constructor()
        public
    {
        testChaiDai = address(new TestChaiDai());
    }

    function _getDaiAddress()
        internal
        view
        returns (address)
    {
        return testChaiDai;
    }

    function _getChaiAddress()
        internal
        view
        returns (address)
    {
        return testChaiDai;
    }

    function _getERC20BridgeProxyAddress()
        internal
        view
        returns (address)
    {
        return msg.sender == ALWAYS_REVERT_ADDRESS ? address(0) : msg.sender;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "./interfaces/IERC20Token.sol";


contract ERC20Token is
    IERC20Token
{
    mapping (address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 internal _totalSupply;

    /// @dev send `value` token to `to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return True if transfer was successful
    function transfer(address _to, uint256 _value)
        external
        returns (bool)
    {
        require(
            balances[msg.sender] >= _value,
            "ERC20_INSUFFICIENT_BALANCE"
        );
        require(
            balances[_to] + _value >= balances[_to],
            "UINT256_OVERFLOW"
        );

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(
            msg.sender,
            _to,
            _value
        );

        return true;
    }

    /// @dev send `value` token to `to` from `from` on the condition it is approved by `from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return True if transfer was successful
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        returns (bool)
    {
        require(
            balances[_from] >= _value,
            "ERC20_INSUFFICIENT_BALANCE"
        );
        require(
            allowed[_from][msg.sender] >= _value,
            "ERC20_INSUFFICIENT_ALLOWANCE"
        );
        require(
            balances[_to] + _value >= balances[_to],
            "UINT256_OVERFLOW"
        );

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(
            _from,
            _to,
            _value
        );

        return true;
    }

    /// @dev `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Always true if the call has enough gas to complete execution
    function approve(address _spender, uint256 _value)
        external
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(
            msg.sender,
            _spender,
            _value
        );
        return true;
    }

    /// @dev Query total supply of token
    /// @return Total supply of token
    function totalSupply()
        external
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    /// @dev Query the balance of owner
    /// @param _owner The address from which the balance will be retrieved
    /// @return Balance of owner
    function balanceOf(address _owner)
        external
        view
        returns (uint256)
    {
        return balances[_owner];
    }

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }
}

/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../src/bridges/DexForwarderBridge.sol";
import "@0x/contracts-utils/contracts/src/LibSafeMath.sol";


interface ITestDexForwarderBridge {
    event BridgeTransferFromCalled(
        address caller,
        uint256 inputTokenBalance,
        address inputToken,
        address outputToken,
        address from,
        address to,
        uint256 amount
    );

    event TokenTransferCalled(
        address from,
        address to,
        uint256 amount
    );

    function emitBridgeTransferFromCalled(
        address caller,
        uint256 inputTokenBalance,
        address inputToken,
        address outputToken,
        address from,
        address to,
        uint256 amount
    ) external;

    function emitTokenTransferCalled(
        address from,
        address to,
        uint256 amount
    ) external;
}


interface ITestDexForwarderBridgeTestToken {

    function transfer(address to, uint256 amount)
        external
        returns (bool);

    function mint(address to, uint256 amount)
        external;

    function balanceOf(address owner) external view returns (uint256);
}


contract TestDexForwarderBridgeTestBridge {

    bytes4 private _returnCode;
    string private _revertError;
    uint256 private _transferAmount;
    ITestDexForwarderBridge private _testContract;

    constructor(bytes4 returnCode, string memory revertError) public {
        _testContract = ITestDexForwarderBridge(msg.sender);
        _returnCode = returnCode;
        _revertError = revertError;
    }

    function setTransferAmount(uint256 amount) external {
        _transferAmount = amount;
    }

    function bridgeTransferFrom(
        address outputToken,
        address from,
        address to,
        uint256 amount,
        bytes memory bridgeData
    )
        public
        returns (bytes4 success)
    {
        if (bytes(_revertError).length != 0) {
            revert(_revertError);
        }
        address inputToken = abi.decode(bridgeData, (address));
        _testContract.emitBridgeTransferFromCalled(
            msg.sender,
            ITestDexForwarderBridgeTestToken(inputToken).balanceOf(address(this)),
            inputToken,
            outputToken,
            from,
            to,
            amount
        );
        ITestDexForwarderBridgeTestToken(outputToken).mint(to, _transferAmount);
        return _returnCode;
    }
}


contract TestDexForwarderBridgeTestToken {

    using LibSafeMath for uint256;

    mapping(address => uint256) public balanceOf;
    ITestDexForwarderBridge private _testContract;

    constructor() public {
        _testContract = ITestDexForwarderBridge(msg.sender);
    }

    function transfer(address to, uint256 amount)
        external
        returns (bool)
    {
        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(amount);
        balanceOf[to] = balanceOf[to].safeAdd(amount);
        _testContract.emitTokenTransferCalled(msg.sender, to, amount);
        return true;
    }

    function mint(address owner, uint256 amount)
        external
    {
        balanceOf[owner] = balanceOf[owner].safeAdd(amount);
    }

    function setBalance(address owner, uint256 amount)
        external
    {
        balanceOf[owner] = amount;
    }
}


contract TestDexForwarderBridge is
    ITestDexForwarderBridge,
    DexForwarderBridge
{
    address private AUTHORIZED_ADDRESS; // solhint-disable-line var-name-mixedcase

    function setAuthorized(address authorized)
        public
    {
        AUTHORIZED_ADDRESS = authorized;
    }

    function createBridge(
        bytes4 returnCode,
        string memory revertError
    )
        public
        returns (address bridge)
    {
        return address(new TestDexForwarderBridgeTestBridge(returnCode, revertError));
    }

    function createToken() public returns (address token) {
        return address(new TestDexForwarderBridgeTestToken());
    }

    function setTokenBalance(address token, address owner, uint256 amount) public {
        TestDexForwarderBridgeTestToken(token).setBalance(owner, amount);
    }

    function setBridgeTransferAmount(address bridge, uint256 amount) public {
        TestDexForwarderBridgeTestBridge(bridge).setTransferAmount(amount);
    }

    function emitBridgeTransferFromCalled(
        address caller,
        uint256 inputTokenBalance,
        address inputToken,
        address outputToken,
        address from,
        address to,
        uint256 amount
    )
        public
    {
        emit BridgeTransferFromCalled(
            caller,
            inputTokenBalance,
            inputToken,
            outputToken,
            from,
            to,
            amount
        );
    }

    function emitTokenTransferCalled(
        address from,
        address to,
        uint256 amount
    )
        public
    {
        emit TokenTransferCalled(
            from,
            to,
            amount
        );
    }

    function balanceOf(address token, address owner) public view returns (uint256) {
        return TestDexForwarderBridgeTestToken(token).balanceOf(owner);
    }

    function _getGstAddress()
        internal
        view
        returns (address gst)
    {
        return address(0);
    }

    function _getERC20BridgeProxyAddress()
        internal
        view
        returns (address erc20BridgeProxyAddress)
    {
        return AUTHORIZED_ADDRESS;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "../src/bridges/DydxBridge.sol";


// solhint-disable no-empty-blocks
contract TestDydxBridgeToken {

    uint256 private constant INIT_HOLDER_BALANCE = 10 * 10**18; // 10 tokens
    mapping (address => uint256) private _balances;

    /// @dev Sets initial balance of token holders.
    constructor(address[] memory holders)
        public
    {
        for (uint256 i = 0; i != holders.length; ++i) {
            _balances[holders[i]] = INIT_HOLDER_BALANCE;
        }
        _balances[msg.sender] = INIT_HOLDER_BALANCE;
    }

    /// @dev Basic transferFrom implementation.
    function transferFrom(address from, address to, uint256 amount)
        external
        returns (bool)
    {
        if (_balances[from] < amount || _balances[to] + amount < _balances[to]) {
            return false;
        }
        _balances[from] -= amount;
        _balances[to] += amount;
        return true;
    }

    /// @dev Returns balance of `holder`.
    function balanceOf(address holder)
        external
        view
        returns (uint256)
    {
        return _balances[holder];
    }
}


// solhint-disable space-after-comma
contract TestDydxBridge is
    IDydx,
    DydxBridge
{

    address private constant ALWAYS_REVERT_ADDRESS = address(1);
    address private _testTokenAddress;
    bool private _shouldRevertOnOperate;

    event OperateAccount(
        address owner,
        uint256 number
    );

    event OperateAction(
        ActionType actionType,
        uint256 accountIdx,
        bool amountSign,
        AssetDenomination amountDenomination,
        AssetReference amountRef,
        uint256 amountValue,
        uint256 primaryMarketId,
        uint256 secondaryMarketId,
        address otherAddress,
        uint256 otherAccountId,
        bytes data
    );

    constructor(address[] memory holders)
        public
    {
        // Deploy a test token. This represents the asset being deposited/withdrawn from dydx.
        _testTokenAddress = address(new TestDydxBridgeToken(holders));
    }

    /// @dev Simulates `operate` in dydx contract.
    ///      Emits events so that arguments can be validated client-side.
    function operate(
        AccountInfo[] calldata accounts,
        ActionArgs[] calldata actions
    )
        external
    {
        if (_shouldRevertOnOperate) {
            revert("TestDydxBridge/SHOULD_REVERT_ON_OPERATE");
        }

        for (uint i = 0; i < accounts.length; ++i) {
            emit OperateAccount(
                accounts[i].owner,
                accounts[i].number
            );
        }

        for (uint i = 0; i < actions.length; ++i) {
            emit OperateAction(
                actions[i].actionType,
                actions[i].accountIdx,
                actions[i].amount.sign,
                actions[i].amount.denomination,
                actions[i].amount.ref,
                actions[i].amount.value,
                actions[i].primaryMarketId,
                actions[i].secondaryMarketId,
                actions[i].otherAddress,
                actions[i].otherAccountIdx,
                actions[i].data
            );

            if (actions[i].actionType == IDydx.ActionType.Withdraw) {
                require(
                    IERC20Token(_testTokenAddress).transferFrom(
                        address(this),
                        actions[i].otherAddress,
                        actions[i].amount.value
                    ),
                    "TestDydxBridge/WITHDRAW_FAILED"
                );
            } else if (actions[i].actionType == IDydx.ActionType.Deposit) {
                require(
                    IERC20Token(_testTokenAddress).transferFrom(
                        actions[i].otherAddress,
                        address(this),
                        actions[i].amount.value
                    ),
                    "TestDydxBridge/DEPOSIT_FAILED"
                );
            } else {
                revert("TestDydxBridge/UNSUPPORTED_ACTION");
            }
        }
    }

    /// @dev If `true` then subsequent calls to `operate` will revert.
    function setRevertOnOperate(bool shouldRevert)
        external
    {
        _shouldRevertOnOperate = shouldRevert;
    }

    /// @dev Returns test token.
    function getTestToken()
        external
        returns (address)
    {
        return _testTokenAddress;
    }

    /// @dev Unused.
    function setOperators(OperatorArg[] calldata args) external {}

    /// @dev Unused.
    function getIsLocalOperator(
        address owner,
        address operator
    )
        external
        view
        returns (bool isLocalOperator)
    {}

    /// @dev Unused.
    function getMarketTokenAddress(
        uint256 marketId
    )
        external
        view
        returns (address tokenAddress)
    {}

    /// @dev Unused.
    function getRiskParams()
        external
        view
        returns (RiskParams memory riskParams)
    {}

    /// @dev Unsused.
    function getMarketPrice(
        uint256 marketId
    )
        external
        view
        returns (Price memory price)
    {}

    /// @dev Unsused
    function getMarketMarginPremium(uint256 marketId)
        external
        view
        returns (IDydx.D256 memory premium)
    {}

    /// @dev Unused.
    function getAdjustedAccountValues(
        AccountInfo calldata account
    )
        external
        view
        returns (Value memory supplyValue, Value memory borrowValue)
    {}

    /// @dev overrides `_getDydxAddress()` from `DeploymentConstants` to return this address.
    function _getDydxAddress()
        internal
        view
        returns (address)
    {
        return address(this);
    }

    /// @dev overrides `_getERC20BridgeProxyAddress()` from `DeploymentConstants` for testing.
    function _getERC20BridgeProxyAddress()
        internal
        view
        returns (address)
    {
        return msg.sender == ALWAYS_REVERT_ADDRESS ? address(0) : msg.sender;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "../src/interfaces/IERC20Bridge.sol";


/// @dev Test bridge token
contract TestERC20BridgeToken {
    mapping (address => uint256) private _balances;

    function addBalance(address owner, int256 amount)
        external
    {
        setBalance(owner, uint256(int256(balanceOf(owner)) + amount));
    }

    function setBalance(address owner, uint256 balance)
        public
    {
        _balances[owner] = balance;
    }

    function balanceOf(address owner)
        public
        view
        returns (uint256)
    {
        return _balances[owner];
    }
}


/// @dev Test bridge contract.
contract TestERC20Bridge is
    IERC20Bridge
{
    TestERC20BridgeToken public testToken;

    event BridgeWithdrawTo(
        address tokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes bridgeData
    );

    constructor() public {
        testToken = new TestERC20BridgeToken();
    }

    function setTestTokenBalance(address owner, uint256 balance)
        external
    {
        testToken.setBalance(owner, balance);
    }

    function bridgeTransferFrom(
        address tokenAddress,
        address from,
        address to,
        uint256 amount,
        bytes calldata bridgeData
    )
        external
        returns (bytes4)
    {
        emit BridgeWithdrawTo(
            tokenAddress,
            from,
            to,
            amount,
            bridgeData
        );
        // Unpack the bridgeData.
        (
            int256 transferAmount,
            bytes memory revertData,
            bytes memory returnData
        ) = abi.decode(bridgeData, (int256, bytes, bytes));

        // If `revertData` is set, revert.
        if (revertData.length != 0) {
            assembly { revert(add(revertData, 0x20), mload(revertData)) }
        }
        // Increase `to`'s balance by `transferAmount`.
        TestERC20BridgeToken(tokenAddress).addBalance(to, transferAmount);
        // Return `returnData`.
        assembly { return(add(returnData, 0x20), mload(returnData)) }
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "../src/bridges/Eth2DaiBridge.sol";
import "../src/interfaces/IEth2Dai.sol";


// solhint-disable no-simple-event-func-name
contract TestEvents {

    event TokenTransfer(
        address token,
        address from,
        address to,
        uint256 amount
    );

    event TokenApprove(
        address token,
        address spender,
        uint256 allowance
    );

    function raiseTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        external
    {
        emit TokenTransfer(
            msg.sender,
            from,
            to,
            amount
        );
    }

    function raiseTokenApprove(address spender, uint256 allowance)
        external
    {
        emit TokenApprove(msg.sender, spender, allowance);
    }
}


/// @dev A minimalist ERC20 token.
contract TestToken {

    mapping (address => uint256) public balances;
    string private _nextTransferRevertReason;
    bytes private _nextTransferReturnData;

    /// @dev Just calls `raiseTokenTransfer()` on the caller.
    function transfer(address to, uint256 amount)
        external
        returns (bool)
    {
        TestEvents(msg.sender).raiseTokenTransfer(msg.sender, to, amount);
        if (bytes(_nextTransferRevertReason).length != 0) {
            revert(_nextTransferRevertReason);
        }
        bytes memory returnData = _nextTransferReturnData;
        assembly { return(add(returnData, 0x20), mload(returnData)) }
    }

    /// @dev Set the balance for `owner`.
    function setBalance(address owner, uint256 balance)
        external
    {
        balances[owner] = balance;
    }

    /// @dev Set the behavior of the `transfer()` call.
    function setTransferBehavior(
        string calldata revertReason,
        bytes calldata returnData
    )
        external
    {
        _nextTransferRevertReason = revertReason;
        _nextTransferReturnData = returnData;
    }

    /// @dev Just calls `raiseTokenApprove()` on the caller.
    function approve(address spender, uint256 allowance)
        external
        returns (bool)
    {
        TestEvents(msg.sender).raiseTokenApprove(spender, allowance);
        return true;
    }

    function allowance(address, address) external view returns (uint256) {
        return 0;
    }

    /// @dev Retrieve the balance for `owner`.
    function balanceOf(address owner)
        external
        view
        returns (uint256)
    {
        return balances[owner];
    }
}


/// @dev Eth2DaiBridge overridden to mock tokens and
///      implement IEth2Dai.
contract TestEth2DaiBridge is
    TestEvents,
    IEth2Dai,
    Eth2DaiBridge
{
    event SellAllAmount(
        address sellToken,
        uint256 sellTokenAmount,
        address buyToken,
        uint256 minimumFillAmount
    );

    mapping (address => TestToken)  public testTokens;
    string private _nextRevertReason;
    uint256 private _nextFillAmount;

    /// @dev Create a token and set this contract's balance.
    function createToken(uint256 balance)
        external
        returns (address tokenAddress)
    {
        TestToken token = new TestToken();
        testTokens[address(token)] = token;
        token.setBalance(address(this), balance);
        return address(token);
    }

    /// @dev Set the behavior for `IEth2Dai.sellAllAmount()`.
    function setFillBehavior(string calldata revertReason, uint256 fillAmount)
        external
    {
        _nextRevertReason = revertReason;
        _nextFillAmount = fillAmount;
    }

    /// @dev Set the behavior of a token's `transfer()`.
    function setTransferBehavior(
        address tokenAddress,
        string calldata revertReason,
        bytes calldata returnData
    )
        external
    {
        testTokens[tokenAddress].setTransferBehavior(revertReason, returnData);
    }

    /// @dev Implementation of `IEth2Dai.sellAllAmount()`
    function sellAllAmount(
        address sellTokenAddress,
        uint256 sellTokenAmount,
        address buyTokenAddress,
        uint256 minimumFillAmount
    )
        external
        returns (uint256 fillAmount)
    {
        emit SellAllAmount(
            sellTokenAddress,
            sellTokenAmount,
            buyTokenAddress,
            minimumFillAmount
        );
        if (bytes(_nextRevertReason).length != 0) {
            revert(_nextRevertReason);
        }
        return _nextFillAmount;
    }

    // @dev This contract will double as the Eth2Dai contract.
    function _getEth2DaiAddress()
        internal
        view
        returns (address)
    {
        return address(this);
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "../src/bridges/KyberBridge.sol";
import "../src/interfaces/IKyberNetworkProxy.sol";


// solhint-disable no-simple-event-func-name
interface ITestContract {

    function wethWithdraw(
        address payable ownerAddress,
        uint256 amount
    )
        external;

    function wethDeposit(
        address ownerAddress
    )
        external
        payable;

    function tokenTransfer(
        address ownerAddress,
        address recipientAddress,
        uint256 amount
    )
        external
        returns (bool success);

    function tokenApprove(
        address ownerAddress,
        address spenderAddress,
        uint256 allowance
    )
        external
        returns (bool success);

    function tokenBalanceOf(
        address ownerAddress
    )
        external
        view
        returns (uint256 balance);
}


/// @dev A minimalist ERC20/WETH token.
contract TestToken {

    uint8 public decimals;
    ITestContract private _testContract;

    constructor(uint8 decimals_) public {
        decimals = decimals_;
        _testContract = ITestContract(msg.sender);
    }

    function approve(address spender, uint256 allowance)
        external
        returns (bool)
    {
        return _testContract.tokenApprove(
            msg.sender,
            spender,
            allowance
        );
    }

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        return _testContract.tokenTransfer(
            msg.sender,
            recipient,
            amount
        );
    }

    function withdraw(uint256 amount)
        external
    {
        return _testContract.wethWithdraw(msg.sender, amount);
    }

    function deposit()
        external
        payable
    {
        return _testContract.wethDeposit.value(msg.value)(msg.sender);
    }

    function allowance(address, address) external view returns (uint256) {
        return 0;
    }

    function balanceOf(address owner)
        external
        view
        returns (uint256)
    {
        return _testContract.tokenBalanceOf(owner);
    }
}


/// @dev KyberBridge overridden to mock tokens and implement IKyberBridge.
contract TestKyberBridge is
    KyberBridge,
    ITestContract,
    IKyberNetworkProxy
{
    event KyberBridgeTrade(
        uint256 msgValue,
        address sellTokenAddress,
        uint256 sellAmount,
        address buyTokenAddress,
        address payable recipientAddress,
        uint256 maxBuyTokenAmount,
        uint256 minConversionRate,
        address walletId
    );

    event KyberBridgeWethWithdraw(
        address ownerAddress,
        uint256 amount
    );

    event KyberBridgeWethDeposit(
        uint256 msgValue,
        address ownerAddress,
        uint256 amount
    );

    event KyberBridgeTokenApprove(
        address tokenAddress,
        address ownerAddress,
        address spenderAddress,
        uint256 allowance
    );

    event KyberBridgeTokenTransfer(
        address tokenAddress,
        address ownerAddress,
        address recipientAddress,
        uint256 amount
    );

    IEtherToken public weth;
    mapping (address => mapping (address => uint256)) private _tokenBalances;
    uint256 private _nextFillAmount;

    constructor() public {
        weth = IEtherToken(address(new TestToken(18)));
    }

    /// @dev Implementation of `IKyberNetworkProxy.trade()`
    function trade(
        address sellTokenAddress,
        uint256 sellAmount,
        address buyTokenAddress,
        address payable recipientAddress,
        uint256 maxBuyTokenAmount,
        uint256 minConversionRate,
        address walletId
    )
        external
        payable
        returns(uint256 boughtAmount)
    {
        emit KyberBridgeTrade(
            msg.value,
            sellTokenAddress,
            sellAmount,
            buyTokenAddress,
            recipientAddress,
            maxBuyTokenAmount,
            minConversionRate,
            walletId
        );
        return _nextFillAmount;
    }

    function tradeWithHint(
        address sellTokenAddress,
        uint256 sellAmount,
        address buyTokenAddress,
        address payable recipientAddress,
        uint256 maxBuyTokenAmount,
        uint256 minConversionRate,
        address payable walletId,
        bytes calldata hint
    )
        external
        payable
        returns (uint256 boughtAmount)
    {
        emit KyberBridgeTrade(
            msg.value,
            sellTokenAddress,
            sellAmount,
            buyTokenAddress,
            recipientAddress,
            maxBuyTokenAmount,
            minConversionRate,
            walletId
        );
        return _nextFillAmount;
    }

    function createToken(uint8 decimals)
        external
        returns (address tokenAddress)
    {
        return address(new TestToken(decimals));
    }

    function setNextFillAmount(uint256 amount)
        external
        payable
    {
        if (msg.value != 0) {
            require(amount == msg.value, "VALUE_AMOUNT_MISMATCH");
            grantTokensTo(address(weth), address(this), msg.value);
        }
        _nextFillAmount = amount;
    }

    function wethDeposit(
        address ownerAddress
    )
        external
        payable
    {
        require(msg.sender == address(weth), "ONLY_WETH");
        grantTokensTo(address(weth), ownerAddress, msg.value);
        emit KyberBridgeWethDeposit(
            msg.value,
            ownerAddress,
            msg.value
        );
    }

    function wethWithdraw(
        address payable ownerAddress,
        uint256 amount
    )
        external
    {
        require(msg.sender == address(weth), "ONLY_WETH");
        _tokenBalances[address(weth)][ownerAddress] -= amount;
        ownerAddress.transfer(amount);
        emit KyberBridgeWethWithdraw(
            ownerAddress,
            amount
        );
    }

    function tokenApprove(
        address ownerAddress,
        address spenderAddress,
        uint256 allowance
    )
        external
        returns (bool success)
    {
        emit KyberBridgeTokenApprove(
            msg.sender,
            ownerAddress,
            spenderAddress,
            allowance
        );
        return true;
    }

    function tokenTransfer(
        address ownerAddress,
        address recipientAddress,
        uint256 amount
    )
        external
        returns (bool success)
    {
        _tokenBalances[msg.sender][ownerAddress] -= amount;
        _tokenBalances[msg.sender][recipientAddress] += amount;
        emit KyberBridgeTokenTransfer(
            msg.sender,
            ownerAddress,
            recipientAddress,
            amount
        );
        return true;
    }

    function tokenBalanceOf(
        address ownerAddress
    )
        external
        view
        returns (uint256 balance)
    {
        return _tokenBalances[msg.sender][ownerAddress];
    }

    function grantTokensTo(address tokenAddress, address ownerAddress, uint256 amount)
        public
        payable
    {
        _tokenBalances[tokenAddress][ownerAddress] += amount;
        if (tokenAddress != address(weth)) {
            // Send back ether if not WETH.
            msg.sender.transfer(msg.value);
        } else {
            require(msg.value == amount, "VALUE_AMOUNT_MISMATCH");
        }
    }

    // @dev overridden to point to this contract.
    function _getKyberNetworkProxyAddress()
        internal
        view
        returns (address)
    {
        return address(this);
    }

    // @dev overridden to point to test WETH.
    function _getWethAddress()
        internal
        view
        returns (address)
    {
        return address(weth);
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "@0x/contracts-utils/contracts/src/LibBytes.sol";


contract TestStaticCallTarget {

    using LibBytes for bytes;

    uint256 internal _state;
 
    function updateState()
        external
    {
        _state++;
    }

    function assertEvenNumber(uint256 target)
        external
        pure
    {
        require(
            target % 2 == 0,
            "TARGET_NOT_EVEN"
        );
    }

    function isOddNumber(uint256 target)
        external
        pure
        returns (bool isOdd)
    {
        isOdd = target % 2 == 1;
        return isOdd;
    }

    function noInputFunction()
        external
        pure
    {
        assert(msg.data.length == 4 && msg.data.readBytes4(0) == bytes4(keccak256("noInputFunction()")));
    }

    function dynamicInputFunction(bytes calldata a)
        external
        pure
    {
        bytes memory abiEncodedData = abi.encodeWithSignature("dynamicInputFunction(bytes)", a);
        assert(msg.data.equals(abiEncodedData));
    }

    function returnComplexType(uint256 a, uint256 b)
        external
        view
        returns (bytes memory result)
    {
        result = abi.encodePacked(
            address(this),
            a,
            b
        );
        return result;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-utils/contracts/src/LibSafeMath.sol";
import "../src/bridges/UniswapBridge.sol";
import "../src/interfaces/IUniswapExchangeFactory.sol";
import "../src/interfaces/IUniswapExchange.sol";


// solhint-disable no-simple-event-func-name
contract TestEventsRaiser {

    event TokenTransfer(
        address token,
        address from,
        address to,
        uint256 amount
    );

    event TokenApprove(
        address spender,
        uint256 allowance
    );

    event WethDeposit(
        uint256 amount
    );

    event WethWithdraw(
        uint256 amount
    );

    event EthToTokenTransferInput(
        address exchange,
        uint256 minTokensBought,
        uint256 deadline,
        address recipient
    );

    event TokenToEthSwapInput(
        address exchange,
        uint256 tokensSold,
        uint256 minEthBought,
        uint256 deadline
    );

    event TokenToTokenTransferInput(
        address exchange,
        uint256 tokensSold,
        uint256 minTokensBought,
        uint256 minEthBought,
        uint256 deadline,
        address recipient,
        address toTokenAddress
    );

    function raiseEthToTokenTransferInput(
        uint256 minTokensBought,
        uint256 deadline,
        address recipient
    )
        external
    {
        emit EthToTokenTransferInput(
            msg.sender,
            minTokensBought,
            deadline,
            recipient
        );
    }

    function raiseTokenToEthSwapInput(
        uint256 tokensSold,
        uint256 minEthBought,
        uint256 deadline
    )
        external
    {
        emit TokenToEthSwapInput(
            msg.sender,
            tokensSold,
            minEthBought,
            deadline
        );
    }

    function raiseTokenToTokenTransferInput(
        uint256 tokensSold,
        uint256 minTokensBought,
        uint256 minEthBought,
        uint256 deadline,
        address recipient,
        address toTokenAddress
    )
        external
    {
        emit TokenToTokenTransferInput(
            msg.sender,
            tokensSold,
            minTokensBought,
            minEthBought,
            deadline,
            recipient,
            toTokenAddress
        );
    }

    function raiseTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        external
    {
        emit TokenTransfer(
            msg.sender,
            from,
            to,
            amount
        );
    }

    function raiseTokenApprove(address spender, uint256 allowance)
        external
    {
        emit TokenApprove(spender, allowance);
    }

    function raiseWethDeposit(uint256 amount)
        external
    {
        emit WethDeposit(amount);
    }

    function raiseWethWithdraw(uint256 amount)
        external
    {
        emit WethWithdraw(amount);
    }
}


/// @dev A minimalist ERC20/WETH token.
contract TestToken {

    using LibSafeMath for uint256;

    mapping (address => uint256) public balances;
    string private _nextRevertReason;

    /// @dev Set the balance for `owner`.
    function setBalance(address owner)
        external
        payable
    {
        balances[owner] = msg.value;
    }

    /// @dev Set the revert reason for `transfer()`,
    ///      `deposit()`, and `withdraw()`.
    function setRevertReason(string calldata reason)
        external
    {
        _nextRevertReason = reason;
    }

    /// @dev Just calls `raiseTokenTransfer()` on the caller.
    function transfer(address to, uint256 amount)
        external
        returns (bool)
    {
        _revertIfReasonExists();
        TestEventsRaiser(msg.sender).raiseTokenTransfer(msg.sender, to, amount);
        return true;
    }

    /// @dev Just calls `raiseTokenApprove()` on the caller.
    function approve(address spender, uint256 allowance)
        external
        returns (bool)
    {
        TestEventsRaiser(msg.sender).raiseTokenApprove(spender, allowance);
        return true;
    }

    /// @dev `IWETH.deposit()` that increases balances and calls
    ///     `raiseWethDeposit()` on the caller.
    function deposit()
        external
        payable
    {
        _revertIfReasonExists();
        balances[msg.sender] += balances[msg.sender].safeAdd(msg.value);
        TestEventsRaiser(msg.sender).raiseWethDeposit(msg.value);
    }

    /// @dev `IWETH.withdraw()` that just reduces balances and calls
    ///       `raiseWethWithdraw()` on the caller.
    function withdraw(uint256 amount)
        external
    {
        _revertIfReasonExists();
        balances[msg.sender] = balances[msg.sender].safeSub(amount);
        msg.sender.transfer(amount);
        TestEventsRaiser(msg.sender).raiseWethWithdraw(amount);
    }

    function allowance(address, address) external view returns (uint256) {
        return 0;
    }

    /// @dev Retrieve the balance for `owner`.
    function balanceOf(address owner)
        external
        view
        returns (uint256)
    {
        return balances[owner];
    }

    function _revertIfReasonExists()
        private
        view
    {
        if (bytes(_nextRevertReason).length != 0) {
            revert(_nextRevertReason);
        }
    }
}


contract TestExchange is
    IUniswapExchange
{
    address public tokenAddress;
    string private _nextRevertReason;

    constructor(address _tokenAddress) public {
        tokenAddress = _tokenAddress;
    }

    function setFillBehavior(
        string calldata revertReason
    )
        external
        payable
    {
        _nextRevertReason = revertReason;
    }

    function ethToTokenTransferInput(
        uint256 minTokensBought,
        uint256 deadline,
        address recipient
    )
        external
        payable
        returns (uint256 tokensBought)
    {
        TestEventsRaiser(msg.sender).raiseEthToTokenTransferInput(
            minTokensBought,
            deadline,
            recipient
        );
        _revertIfReasonExists();
        return address(this).balance;
    }

    function tokenToEthSwapInput(
        uint256 tokensSold,
        uint256 minEthBought,
        uint256 deadline
    )
        external
        returns (uint256 ethBought)
    {
        TestEventsRaiser(msg.sender).raiseTokenToEthSwapInput(
            tokensSold,
            minEthBought,
            deadline
        );
        _revertIfReasonExists();
        uint256 fillAmount = address(this).balance;
        msg.sender.transfer(fillAmount);
        return fillAmount;
    }

    function tokenToTokenTransferInput(
        uint256 tokensSold,
        uint256 minTokensBought,
        uint256 minEthBought,
        uint256 deadline,
        address recipient,
        address toTokenAddress
    )
        external
        returns (uint256 tokensBought)
    {
        TestEventsRaiser(msg.sender).raiseTokenToTokenTransferInput(
            tokensSold,
            minTokensBought,
            minEthBought,
            deadline,
            recipient,
            toTokenAddress
        );
        _revertIfReasonExists();
        return address(this).balance;
    }

    function toTokenAddress()
        external
        view
        returns (address _tokenAddress)
    {
        return tokenAddress;
    }

    function _revertIfReasonExists()
        private
        view
    {
        if (bytes(_nextRevertReason).length != 0) {
            revert(_nextRevertReason);
        }
    }
}


/// @dev UniswapBridge overridden to mock tokens and implement IUniswapExchangeFactory.
contract TestUniswapBridge is
    IUniswapExchangeFactory,
    TestEventsRaiser,
    UniswapBridge
{
    TestToken public wethToken;
    // Token address to TestToken instance.
    mapping (address => TestToken) private _testTokens;
    // Token address to TestExchange instance.
    mapping (address => TestExchange) private _testExchanges;

    constructor() public {
        wethToken = new TestToken();
        _testTokens[address(wethToken)] = wethToken;
    }

    /// @dev Sets the balance of this contract for an existing token.
    ///      The wei attached will be the balance.
    function setTokenBalance(address tokenAddress)
        external
        payable
    {
        TestToken token = _testTokens[tokenAddress];
        token.deposit.value(msg.value)();
    }

    /// @dev Sets the revert reason for an existing token.
    function setTokenRevertReason(address tokenAddress, string calldata revertReason)
        external
    {
        TestToken token = _testTokens[tokenAddress];
        token.setRevertReason(revertReason);
    }

    /// @dev Create a token and exchange (if they don't exist) for a new token
    ///      and sets the exchange revert and fill behavior. The wei attached
    ///      will be the fill amount for the exchange.
    /// @param tokenAddress The token address. If zero, one will be created.
    /// @param revertReason The revert reason for exchange operations.
    function createTokenAndExchange(
        address tokenAddress,
        string calldata revertReason
    )
        external
        payable
        returns (TestToken token, TestExchange exchange)
    {
        token = TestToken(tokenAddress);
        if (tokenAddress == address(0)) {
            token = new TestToken();
        }
        _testTokens[address(token)] = token;
        exchange = _testExchanges[address(token)];
        if (address(exchange) == address(0)) {
            _testExchanges[address(token)] = exchange = new TestExchange(address(token));
        }
        exchange.setFillBehavior.value(msg.value)(revertReason);
        return (token, exchange);
    }

    /// @dev `IUniswapExchangeFactory.getExchange`
    function getExchange(address tokenAddress)
        external
        view
        returns (address)
    {
        return address(_testExchanges[tokenAddress]);
    }

    // @dev Use `wethToken`.
    function _getWethAddress()
        internal
        view
        returns (address)
    {
        return address(wethToken);
    }

    // @dev This contract will double as the Uniswap contract.
    function _getUniswapExchangeFactoryAddress()
        internal
        view
        returns (address)
    {
        return address(this);
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/interfaces/IERC20Token.sol";
import "@0x/contracts-utils/contracts/src/LibSafeMath.sol";
import "@0x/contracts-utils/contracts/src/LibAddressArray.sol";
import "../src/bridges/UniswapV2Bridge.sol";
import "../src/interfaces/IUniswapV2Router01.sol";


contract TestEventsRaiser {

    event TokenTransfer(
        address token,
        address from,
        address to,
        uint256 amount
    );

    event TokenApprove(
        address spender,
        uint256 allowance
    );

    event SwapExactTokensForTokensInput(
        uint amountIn,
        uint amountOutMin,
        address toTokenAddress,
        address to,
        uint deadline
    );

    function raiseTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        external
    {
        emit TokenTransfer(
            msg.sender,
            from,
            to,
            amount
        );
    }

    function raiseTokenApprove(address spender, uint256 allowance) external {
        emit TokenApprove(spender, allowance);
    }

    function raiseSwapExactTokensForTokensInput(
        uint amountIn,
        uint amountOutMin,
        address toTokenAddress,
        address to,
        uint deadline
    ) external
    {
        emit SwapExactTokensForTokensInput(
            amountIn,
            amountOutMin,
            toTokenAddress,
            to,
            deadline
        );
    }
}


/// @dev A minimalist ERC20 token.
contract TestToken {

    using LibSafeMath for uint256;

    mapping (address => uint256) public balances;
    string private _nextRevertReason;

    /// @dev Set the balance for `owner`.
    function setBalance(address owner, uint256 balance)
        external
        payable
    {
        balances[owner] = balance;
    }

    /// @dev Just emits a TokenTransfer event on the caller
    function transfer(address to, uint256 amount)
        external
        returns (bool)
    {
        TestEventsRaiser(msg.sender).raiseTokenTransfer(msg.sender, to, amount);
        return true;
    }

    /// @dev Just emits a TokenApprove event on the caller
    function approve(address spender, uint256 allowance)
        external
        returns (bool)
    {
        TestEventsRaiser(msg.sender).raiseTokenApprove(spender, allowance);
        return true;
    }

    function allowance(address, address) external view returns (uint256) {
        return 0;
    }

    /// @dev Retrieve the balance for `owner`.
    function balanceOf(address owner)
        external
        view
        returns (uint256)
    {
        return balances[owner];
    }
}


/// @dev Mock the UniswapV2Router01 contract
contract TestRouter is
    IUniswapV2Router01
{
    string private _nextRevertReason;

    /// @dev Set the revert reason for `swapExactTokensForTokens`.
    function setRevertReason(string calldata reason)
        external
    {
        _nextRevertReason = reason;
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts)
    {
        _revertIfReasonExists();

        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        amounts[amounts.length - 1] = amountOutMin;

        TestEventsRaiser(msg.sender).raiseSwapExactTokensForTokensInput(
            // tokens sold
            amountIn,
            // tokens bought
            amountOutMin,
            // output token (toTokenAddress)
            path[path.length - 1],
            // recipient
            to,
            // deadline
            deadline
        );
    }

    function _revertIfReasonExists()
        private
        view
    {
        if (bytes(_nextRevertReason).length != 0) {
            revert(_nextRevertReason);
        }
    }

}


/// @dev UniswapV2Bridge overridden to mock tokens and Uniswap router
contract TestUniswapV2Bridge is
    UniswapV2Bridge,
    TestEventsRaiser
{

    // Token address to TestToken instance.
    mapping (address => TestToken) private _testTokens;
    // TestRouter instance.
    TestRouter private _testRouter;

    constructor() public {
        _testRouter = new TestRouter();
    }

    function setRouterRevertReason(string calldata revertReason)
        external
    {
        _testRouter.setRevertReason(revertReason);
    }

    /// @dev Sets the balance of this contract for an existing token.
    ///      The wei attached will be the balance.
    function setTokenBalance(address tokenAddress, uint256 balance)
        external
    {
        TestToken token = _testTokens[tokenAddress];
        token.setBalance(address(this), balance);
    }

    /// @dev Create a new token
    /// @param tokenAddress The token address. If zero, one will be created.
    function createToken(
        address tokenAddress
    )
        external
        returns (TestToken token)
    {
        token = TestToken(tokenAddress);
        if (tokenAddress == address(0)) {
            token = new TestToken();
        }
        _testTokens[address(token)] = token;

        return token;
    }

    function getRouterAddress()
        external
        view
        returns (address)
    {
        return address(_testRouter);
    }

    function _getUniswapV2Router01Address()
        internal
        view
        returns (address)
    {
        return address(_testRouter);
    }
}