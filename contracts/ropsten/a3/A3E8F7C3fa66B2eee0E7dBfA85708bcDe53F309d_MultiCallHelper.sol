/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// Copyright (C) 2018  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IFilter {
    function isValid(address _wallet, address _spender, address _to, bytes calldata _data) external view returns (bool);
}

interface ITransferStorage {
    function setWhitelist(address _wallet, address _target, uint256 _value) external;

    function getWhitelist(address _wallet, address _target) external view returns (uint256);
}

interface IDappRegistry {
    function enabledRegistryIds(address _wallet) external view returns (bytes32);
    function authorisations(uint8 _registryId, address _dapp) external view returns (bytes32);
}

/**
 * @title MultiCallHelper
 * @notice Helper contract that can be used to check in 1 call if and why a sequence of transactions is authorised to be executed by a wallet.
 * @author Julien Niset - <[email protected]>
 */
contract MultiCallHelper {

    uint256 private constant MAX_UINT = 2**256 - 1;

    bytes4 private constant ERC20_TRANSFER = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 private constant ERC20_APPROVE = bytes4(keccak256("approve(address,uint256)"));
    bytes4 private constant ERC721_TRANSFER_FROM = bytes4(keccak256("transferFrom(address,address,uint256)"));
    bytes4 private constant ERC721_SAFE_TRANSFER_FROM = bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
    bytes4 private constant ERC721_SAFE_TRANSFER_FROM_BYTES = bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));
    bytes4 private constant ERC721_SET_APPROVAL_FOR_ALL = bytes4(keccak256("setApprovalForAll(address,bool)"));
    bytes4 private constant ERC1155_SAFE_TRANSFER_FROM = bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)"));

    struct Call {
        address to;
        uint256 value;
        bytes data;
    }

    // The trusted contacts storage
    ITransferStorage internal immutable userWhitelist;
    // The dapp registry contract
    IDappRegistry internal immutable dappRegistry;

    constructor(ITransferStorage _userWhitelist, IDappRegistry _dappRegistry) public {
        userWhitelist = _userWhitelist;
        dappRegistry = _dappRegistry;
    }

    /**
     * @notice Checks if a sequence of transactions is authorised to be executed by a wallet.
     * The method returns false if any of the inner transaction is not to a trusted contact or an authorised dapp.
     * @param _wallet The target wallet.
     * @param _transactions The sequence of transactions.
     */
    function isMultiCallAuthorised(address _wallet, Call[] calldata _transactions) external view returns (bool) {
        for(uint i = 0; i < _transactions.length; i++) {
            address spender = recoverSpender(_wallet, _transactions[i]);
            if (!isWhitelisted(_wallet, spender) && isAuthorised(_wallet, spender, _transactions[i].to, _transactions[i].data) == MAX_UINT) {
                return false;
            }
        }
        return true;
    }

    /**
     * @notice Checks if each of the transaction of a sequence of transactions is authorised to be executed by a wallet.
     * For each transaction of the sequence it returns an Id where:
     *     - Id is in [0,255]: the transaction is to an address authorised in registry Id of the DappRegistry
     *     - Id = 256: the transaction is to an address authorised in the trusted contacts of the wallet
     *     - Id = MAX_UINT: the transaction is not authorised
     * @param _wallet The target wallet.
     * @param _transactions The sequence of transactions.
     */
    function multiCallAuthorisation(address _wallet, Call[] calldata _transactions) external view returns (uint256[] memory registryIds) {
        registryIds = new uint256[](_transactions.length);
        for(uint i = 0; i < _transactions.length; i++) {
            address spender = recoverSpender(_wallet, _transactions[i]);
            if (isWhitelisted(_wallet, spender)) {
                registryIds[i] = 256;
            } else {
                registryIds[i] = isAuthorised(_wallet, spender, _transactions[i].to, _transactions[i].data);
            }
        }
    }

    function recoverSpender(address _wallet, Call calldata _transaction) internal pure returns (address) {
        if(_transaction.data.length >= 4) {
            bytes4 methodId;
            bytes memory data = _transaction.data;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                methodId := mload(add(data, 0x20))
            }
            if(
                methodId == ERC20_TRANSFER ||
                methodId == ERC20_APPROVE ||
                methodId == ERC721_TRANSFER_FROM ||
                methodId == ERC721_SAFE_TRANSFER_FROM ||
                methodId == ERC721_SAFE_TRANSFER_FROM_BYTES ||
                methodId == ERC721_SET_APPROVAL_FOR_ALL ||
                methodId == ERC1155_SAFE_TRANSFER_FROM
            ) {
                require(_transaction.value == 0, "TM: unsecure call");
                (address first, address second) = abi.decode(_transaction.data[4:], (address, address));
                return first == _wallet ? second : first;
            }
        }
        return _transaction.to;
    } 


    function isAuthorised(address _wallet, address _spender, address _to, bytes calldata _data) internal view returns (uint256) {
        uint registries = uint(dappRegistry.enabledRegistryIds(_wallet));
        // Check Argent Default Registry first. It is enabled by default, implying that a zero 
        // at position 0 of the `registries` bit vector means that the Argent Registry is enabled)
        for(uint registryId = 0; registryId == 0 || (registries >> registryId) > 0; registryId++) {
            bool isEnabled = (((registries >> registryId) & 1) > 0) /* "is bit set for regId?" */ == (registryId > 0) /* "not Argent registry?" */;
            if(isEnabled) { // if registryId is enabled
                uint auth = uint(dappRegistry.authorisations(uint8(registryId), _spender)); 
                uint validAfter = auth & 0xffffffffffffffff;
                if (0 < validAfter && validAfter <= block.timestamp) { // if the current time is greater than the validity time
                    address filter = address(uint160(auth >> 64));
                    if(filter == address(0) || IFilter(filter).isValid(_wallet, _spender, _to, _data)) {
                        return registryId;
                    }
                }
            }
        }
        return MAX_UINT;
    }

    function isWhitelisted(address _wallet, address _target) internal view returns (bool _isWhitelisted) {
        uint whitelistAfter = userWhitelist.getWhitelist(_wallet, _target);
        return whitelistAfter > 0 && whitelistAfter < block.timestamp;
    }
}