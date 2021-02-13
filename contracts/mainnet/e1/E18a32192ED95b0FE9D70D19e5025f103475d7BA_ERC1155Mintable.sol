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

pragma solidity ^0.7.0;

import "./lib/LibSafeMath.sol";
import "./lib/LibAddress.sol";
import "./ERC1155.sol";
import "./interface/IERC1155Mintable.sol";
import "./mixin/MixinOwnable.sol";
import "./mixin/MixinContractURI.sol";
import "./mixin/MixinTokenURI.sol";

/// @dev Mintable form of ERC1155
/// Shows how easy it is to mint new items
contract ERC1155Mintable is
    IERC1155Mintable,
    ERC1155,
    MixinContractURI,
    MixinTokenURI
{
    using LibSafeMath for uint256;
    using LibAddress for address;

    uint256 internal nonce;

    /// mapping from token to max index
    mapping (uint256 => uint256) public maxIndex;

    mapping (uint256 => mapping(address => bool)) internal creatorApproval;

    modifier onlyCreator(uint256 _id) {
        require(creatorApproval[_id][msg.sender], "not an approved creator of id");
        _;
    }

    function setCreatorApproval(uint256 id, address creator, bool status) external onlyCreator(id) {
        creatorApproval[id][creator] = status;
    }

    /// @dev creates a new token
    /// @param isNF is non-fungible token
    /// @return type_ of token (a unique identifier)
    function create(
        bool isNF
    )
        external
        override
        onlyOwner()
        returns (uint256 type_)
    {
        // Store the type in the upper 128 bits
        type_ = (++nonce << 128);

        // Set a flag if this is an NFI.
        if (isNF) {
            type_ = type_ | TYPE_NF_BIT;
        }

        creatorApproval[type_][msg.sender] = true;

        // emit a Transfer event with Create semantic to help with discovery.
        emit TransferSingle(
            msg.sender,
            address(0x0),
            address(0x0),
            type_,
            0
        );

        emit URI(uri(type_), type_);
    }

    /// @dev creates a new token
    /// @param type_ of token
    function createWithType(
        uint256 type_
    )
        external
        onlyOwner()
    {

        creatorApproval[type_][msg.sender] = true;

        // emit a Transfer event with Create semantic to help with discovery.
        emit TransferSingle(
            msg.sender,
            address(0x0),
            address(0x0),
            type_,
            0
        );

        emit URI(uri(type_), type_);
    }

    /// @dev mints fungible tokens
    /// @param id token type
    /// @param to beneficiaries of minted tokens
    /// @param quantities amounts of minted tokens
    function mintFungible(
        uint256 id,
        address[] calldata to,
        uint256[] calldata quantities
    )
        external
        override
        onlyCreator(id)
    {
        // sanity checks
        require(
            isFungible(id),
            "TRIED_TO_MINT_FUNGIBLE_FOR_NON_FUNGIBLE_TOKEN"
        );

        // mint tokens
        for (uint256 i = 0; i < to.length; ++i) {
            // cache to reduce number of loads
            address dst = to[i];
            uint256 quantity = quantities[i];

            // Grant the items to the caller
            balances[id][dst] = quantity.safeAdd(balances[id][dst]);

            // Emit the Transfer/Mint event.
            // the 0x0 source address implies a mint
            // It will also provide the circulating supply info.
            emit TransferSingle(
                msg.sender,
                address(0x0),
                dst,
                id,
                quantity
            );

            // if `to` is a contract then trigger its callback
            if (dst.isContract()) {
                bytes4 callbackReturnValue = IERC1155Receiver(dst).onERC1155Received(
                    msg.sender,
                    msg.sender,
                    id,
                    quantity,
                    ""
                );
                require(
                    callbackReturnValue == ERC1155_RECEIVED,
                    "BAD_RECEIVER_RETURN_VALUE"
                );
            }
        }
    }

    /// @dev mints a non-fungible token
    /// @param type_ token type
    /// @param to beneficiaries of minted tokens
    function mintNonFungible(
        uint256 type_,
        address[] calldata to
    )
        external
        override
        onlyCreator(type_)
    {
        require(
            isNonFungible(type_),
            "TRIED_TO_MINT_NON_FUNGIBLE_FOR_FUNGIBLE_TOKEN"
        );

        // Index are 1-based.
        uint256 index = maxIndex[type_] + 1;

        for (uint256 i = 0; i < to.length; ++i) {
            // cache to reduce number of loads
            address dst = to[i];
            uint256 id  = type_ | index + i;

            nfOwners[id] = dst;

            // You could use base-type id to store NF type balances if you wish.
            balances[type_][dst] = balances[type_][dst].safeAdd(1);

            emit TransferSingle(msg.sender, address(0x0), dst, id, 1);

            // if `to` is a contract then trigger its callback
            if (dst.isContract()) {
                bytes4 callbackReturnValue = IERC1155Receiver(dst).onERC1155Received(
                    msg.sender,
                    msg.sender,
                    id,
                    1,
                    ""
                );
                require(
                    callbackReturnValue == ERC1155_RECEIVED,
                    "BAD_RECEIVER_RETURN_VALUE"
                );
            }
        }

        // record the `maxIndex` of this nft type
        // this allows us to mint more nft's of this type in a subsequent call.
        maxIndex[type_] = to.length.safeAdd(maxIndex[type_]);
    }
}

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;


/**
 * Utility library of inline functions on addresses
 */
library LibAddress {

    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

pragma solidity ^0.7.0;

import "./lib/LibSafeMath.sol";
import "./lib/LibAddress.sol";
import "./interface/IERC1155.sol";
import "./interface/IERC1155Receiver.sol";
import "./mixin/MixinNonFungibleToken.sol";
import "./mixin/MixinOwnable.sol";
import "./WhitelistExchangesProxy.sol";

contract ERC1155 is
    IERC1155,
    MixinNonFungibleToken,
    Ownable
{
    using LibAddress for address;
    using LibSafeMath for uint256;

    // selectors for receiver callbacks
    bytes4 constant public ERC1155_RECEIVED       = 0xf23a6e61;
    bytes4 constant public ERC1155_BATCH_RECEIVED = 0xbc197c81;

    // id => (owner => balance)
    mapping (uint256 => mapping(address => uint256)) internal balances;

    // owner => (operator => approved)
    mapping (address => mapping(address => bool)) internal operatorApproval;

    address public exchangesRegistry;

    function setExchangesRegistry(address newExchangesRegistry) external onlyOwner() {
        exchangesRegistry = newExchangesRegistry;
    }

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
        override
        external
    {
        // sanity checks
        require(
            to != address(0x0),
            "CANNOT_TRANSFER_TO_ADDRESS_ZERO"
        );
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "INSUFFICIENT_ALLOWANCE"
        );

        // perform transfer
        if (isNonFungible(id)) {
            require(
                    value == 1,
                    "AMOUNT_EQUAL_TO_ONE_REQUIRED"
            );
            require(
                nfOwners[id] == from,
                "NFT_NOT_OWNED_BY_FROM_ADDRESS"
            );
            nfOwners[id] = to;
            // You could keep balance of NF type in base type id like so:
            // uint256 baseType = getNonFungibleBaseType(_id);
            // balances[baseType][_from] = balances[baseType][_from].safeSub(_value);
            // balances[baseType][_to]   = balances[baseType][_to].safeAdd(_value);
        } else {
            balances[id][from] = balances[id][from].safeSub(value);
            balances[id][to] = balances[id][to].safeAdd(value);
        }
        emit TransferSingle(msg.sender, from, to, id, value);

        // if `to` is a contract then trigger its callback
        if (to.isContract()) {
            bytes4 callbackReturnValue = IERC1155Receiver(to).onERC1155Received(
                msg.sender,
                from,
                id,
                value,
                data
            );
            require(
                callbackReturnValue == ERC1155_RECEIVED,
                "BAD_RECEIVER_RETURN_VALUE"
            );
        }
    }

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
        override
        external
    {
        // sanity checks
        require(
            to != address(0x0),
            "CANNOT_TRANSFER_TO_ADDRESS_ZERO"
        );
        require(
            ids.length == values.length,
            "TOKEN_AND_VALUES_LENGTH_MISMATCH"
        );

        // Only supporting a global operator approval allows us to do
        // only 1 check and not to touch storage to handle allowances.
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "INSUFFICIENT_ALLOWANCE"
        );

        // perform transfers
        for (uint256 i = 0; i < ids.length; ++i) {
            // Cache value to local variable to reduce read costs.
            uint256 id = ids[i];
            uint256 value = values[i];

            if (isNonFungible(id)) {
                require(
                    value == 1,
                    "AMOUNT_EQUAL_TO_ONE_REQUIRED"
                );
                require(
                    nfOwners[id] == from,
                    "NFT_NOT_OWNED_BY_FROM_ADDRESS"
                );
                nfOwners[id] = to;
            } else {
                balances[id][from] = balances[id][from].safeSub(value);
                balances[id][to] = balances[id][to].safeAdd(value);
            }
        }
        emit TransferBatch(msg.sender, from, to, ids, values);

        // if `to` is a contract then trigger its callback
        if (to.isContract()) {
            bytes4 callbackReturnValue = IERC1155Receiver(to).onERC1155BatchReceived(
                msg.sender,
                from,
                ids,
                values,
                data
            );
            require(
                callbackReturnValue == ERC1155_BATCH_RECEIVED,
                "BAD_RECEIVER_RETURN_VALUE"
            );
        }
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param operator  Address to add to the set of authorized operators
    /// @param approved  True if the operator is approved, false to revoke approval
    function setApprovalForAll(address operator, bool approved) external override {
        operatorApproval[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Queries the approval status of an operator for a given owner.
    /// @param owner     The owner of the Tokens
    /// @param operator  Address of authorized operator
    /// @return           True if the operator is approved, false if not
    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        bool approved = operatorApproval[owner][operator];
        if (!approved && exchangesRegistry != address(0)) {
            return WhitelistExchangesProxy(exchangesRegistry).isAddressWhitelisted(operator) == true;
        }
        return approved;
    }

    /// @notice Get the balance of an account's Tokens.
    /// @param owner  The address of the token holder
    /// @param id     ID of the Token
    /// @return        The _owner's balance of the Token type requested
    function balanceOf(address owner, uint256 id) external override view returns (uint256) {
        if (isNonFungibleItem(id)) {
            return nfOwners[id] == owner ? 1 : 0;
        }
        return balances[id][owner];
    }

    /// @notice Get the balance of multiple account/token pairs
    /// @param owners The addresses of the token holders
    /// @param ids    ID of the Tokens
    /// @return balances_       The _owner's balance of the Token types requested
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external override view returns (uint256[] memory balances_) {
        // sanity check
        require(
            owners.length == ids.length,
            "OWNERS_AND_IDS_MUST_HAVE_SAME_LENGTH"
        );

        // get balances
        balances_ = new uint256[](owners.length);
        for (uint256 i = 0; i < owners.length; ++i) {
            uint256 id = ids[i];
            if (isNonFungibleItem(id)) {
                balances_[i] = nfOwners[id] == owners[i] ? 1 : 0;
            } else {
                balances_[i] = balances[id][owners[i]];
            }
        }

        return balances_;
    }

    bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        if (_interfaceID == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceID == INTERFACE_SIGNATURE_ERC1155) {
        return true;
        }
        return false;
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

pragma solidity ^0.7.0;

import "./IERC1155.sol";


/// @dev Mintable form of ERC1155
/// Shows how easy it is to mint new items
interface IERC1155Mintable is
    IERC1155
{

    /// @dev creates a new token
    /// @param isNF is non-fungible token
    /// @return type_ of token (a unique identifier)
    function create(
        bool isNF
    )
        external
        returns (uint256 type_);

    /// @dev mints fungible tokens
    /// @param id token type
    /// @param to beneficiaries of minted tokens
    /// @param quantities amounts of minted tokens
    function mintFungible(
        uint256 id,
        address[] calldata to,
        uint256[] calldata quantities
    )
        external;

    /// @dev mints a non-fungible token
    /// @param type_ token type
    /// @param to beneficiaries of minted tokens
    function mintNonFungible(
        uint256 type_,
        address[] calldata to
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.7.0;

import "./MixinOwnable.sol";

contract MixinContractURI is Ownable {
    string public contractURI;

    function setContractURI(string calldata newContractURI) external onlyOwner() {
        contractURI = newContractURI;
    }
}

pragma solidity ^0.7.0;

import "./MixinOwnable.sol";
import "../lib/LibString.sol";

contract MixinTokenURI is Ownable {
    using LibString for string;

    string public baseMetadataURI = "";

    function setBaseMetadataURI(string memory newBaseMetadataURI) public onlyOwner() {
        baseMetadataURI = newBaseMetadataURI;
    }

    function uri(uint256 _id) public view returns (string memory) {
        return LibString.strConcat(
        baseMetadataURI,
        LibString.uint2hexstr(_id)
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

pragma solidity ^0.7.0;


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

pragma solidity ^0.7.0;


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

pragma solidity ^0.7.0;

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
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
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
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    /// @dev MUST emit when an approval is updated.
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /// @dev MUST emit when the URI is updated for a token ID.
    /// URIs are defined in RFC 3986.
    /// The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata JSON Schema".
    event URI(
        string _value,
        uint256 indexed _id
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
    /// @return balances_ The _owner's balance of the Token types requested
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

pragma solidity ^0.7.0;


interface IERC1155Receiver {

    /// @notice Handle the receipt of a single ERC1155 token type
    /// @dev The smart contract calls this function on the recipient
    /// after a `safeTransferFrom`. This function MAY throw to revert and reject the
    /// transfer. Return of other than the magic value MUST result in the
    ///transaction being reverted
    /// Note: the contract address is always the message sender
    /// @param operator  The address which called `safeTransferFrom` function
    /// @param from      The address which previously owned the token
    /// @param id        An array containing the ids of the token being transferred
    /// @param value     An array containing the amount of tokens being transferred
    /// @param data      Additional data with no specified format
    /// @return          `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /// @notice Handle the receipt of multiple ERC1155 token types
    /// @dev The smart contract calls this function on the recipient
    /// after a `safeTransferFrom`. This function MAY throw to revert and reject the
    /// transfer. Return of other than the magic value MUST result in the
    /// transaction being reverted
    /// Note: the contract address is always the message sender
    /// @param operator  The address which called `safeTransferFrom` function
    /// @param from      The address which previously owned the token
    /// @param ids       An array containing ids of each token being transferred
    /// @param values    An array containing amounts of each token being transferred
    /// @param data      Additional data with no specified format
    /// @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
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

pragma solidity ^0.7.0;


contract MixinNonFungibleToken {
    uint256 constant internal TYPE_MASK = uint256(uint128(~0)) << 128;

    uint256 constant internal NF_INDEX_MASK = uint128(~0);

    uint256 constant internal TYPE_NF_BIT = 1 << 255;

    mapping (uint256 => address) internal nfOwners;

    /// @dev Returns true if token is non-fungible
    function isNonFungible(uint256 id) public pure returns(bool) {
        return id & TYPE_NF_BIT == TYPE_NF_BIT;
    }

    /// @dev Returns true if token is fungible
    function isFungible(uint256 id) public pure returns(bool) {
        return id & TYPE_NF_BIT == 0;
    }

    /// @dev Returns index of non-fungible token
    function getNonFungibleIndex(uint256 id) public pure returns(uint256) {
        return id & NF_INDEX_MASK;
    }

    /// @dev Returns base type of non-fungible token
    function getNonFungibleBaseType(uint256 id) public pure returns(uint256) {
        return id & TYPE_MASK;
    }

    /// @dev Returns true if input is base-type of a non-fungible token
    function isNonFungibleBaseType(uint256 id) public pure returns(bool) {
        // A base type has the NF bit but does not have an index.
        return (id & TYPE_NF_BIT == TYPE_NF_BIT) && (id & NF_INDEX_MASK == 0);
    }

    /// @dev Returns true if input is a non-fungible token
    function isNonFungibleItem(uint256 id) public pure returns(bool) {
        // A base type has the NF bit but does has an index.
        return (id & TYPE_NF_BIT == TYPE_NF_BIT) && (id & NF_INDEX_MASK != 0);
    }

    /// @dev returns owner of a non-fungible token
    function ownerOf(uint256 id) public view returns (address) {
        return nfOwners[id];
    }
}

pragma solidity ^0.7.0;

import "./mixin/MixinOwnable.sol";

contract WhitelistExchangesProxy is Ownable {
    mapping(address => bool) internal proxies;

    bool public paused = true;
    
    function setPaused(bool newPaused) external onlyOwner() {
        paused = newPaused;
    }

    function updateProxyAddress(address proxy, bool status) external onlyOwner() {
        proxies[proxy] = status;
    }

    function isAddressWhitelisted(address proxy) external view returns (bool) {
        if (paused) {
            return false;
        } else {
            return proxies[proxy];
        }
    }
}

pragma solidity ^0.7.0;

library LibString {
  // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function uint2hexstr(uint i) internal pure returns (string memory) {
        if (i == 0) {
            return "0";
        }
        uint j = i;
        uint len;
        while (j != 0) {
            len++;
            j = j >> 4;
        }
        uint mask = 15;
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            uint curr = (i & mask);
            bstr[k--] = curr > 9 ? byte(uint8(55 + curr)) : byte(uint8(48 + curr));
            i = i >> 4;
        }
        return string(bstr);
    }
}