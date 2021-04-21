/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// File: contracts\interfaces\ITestNFTScalingManager.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITestNFTScalingManager {
  event LogNFTLifted(address indexed token, address indexed t1Address, bytes32 indexed t2PublicKey, uint256[] tokenIds,
      uint256[] values, bool isFungible, uint256 nonce);
}

// File: contracts\interfaces\IERC165.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
  }

// File: contracts\interfaces\IERC1155.sol



pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// File: contracts\interfaces\IERC1155Receiver.sol



pragma solidity ^0.8.0;

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
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

// File: contracts\interfaces\IERC721Receiver.sol



pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// File: ..\contracts\TestNFTScalingManager.sol



pragma solidity ^0.8.0;

/**
 * TestNFTScalingManager is a contract which
 * - can receive and lift ERC721 tokens
 * - can receive and lift ERC1155 tokens
 * - can receive and lift bacthes of ERC1155 tokens
 */

 // TODO: - the "data" passed into each method could encode all sorts(eg: rules sets) - for now we just pass the T2 recipient

contract TestNFTScalingManager is ITestNFTScalingManager, IERC1155Receiver, IERC721Receiver {

  bytes4 constant internal ERC721Receiver = 0x150b7a02;
  bytes4 constant internal ERC1155Receiver = 0xf23a6e61;
  bytes4 constant internal ERC1155BatchReceiver = 0xbc197c81;
  uint256 constant internal LIFT_LIMIT = type(uint128).max;

  uint256 public liftNonce;

  constructor() {}

  function supportsInterface(bytes4 interfaceId)
    external
    override
    pure
    returns (bool)
  {
    return (interfaceId == ERC721Receiver || interfaceId == ERC1155Receiver || interfaceId == ERC1155BatchReceiver);
  }

  function onERC721Received(address /* operator */, address from, uint256 tokenId, bytes calldata data)
    external
    override
    returns (bytes4)
  {
    uint256[] memory ids;
    ids[0] = tokenId;
    uint256[] memory values;
    values[0] = 1;

    bytes32 t2PublicKey = abi.decode(data, (bytes32));

    emit LogNFTLifted(msg.sender, from, t2PublicKey, ids, values, false, ++liftNonce);

    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  function onERC1155Received(address /* operator */, address from, uint256 id, uint256 value, bytes calldata data)
    external
    override
    returns(bytes4)
  {
    uint256[] memory ids;
    ids[0] = id;
    uint256[] memory values;
    values[0] = value;

    (bytes32 t2PublicKey, bool isFungible) = abi.decode(data, (bytes32, bool));
    // Solidity 0.8.0 reverts on overflow
    require(IERC1155(msg.sender).balanceOf(address(this), id) + value <= LIFT_LIMIT, "Exceeds ERC1155 lift limit");

    emit LogNFTLifted(msg.sender, from, t2PublicKey, ids, values, isFungible, ++liftNonce);

    return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
  }

  function onERC1155BatchReceived(address /* operator */, address from, uint256[] calldata ids, uint256[] calldata values,
      bytes calldata data)
    external
    override
    returns(bytes4)
  {
    require(ids.length == values.length, "Bad batch");

    (bytes32 t2PublicKey, bool isFungible) = abi.decode(data, (bytes32, bool));
    for (uint256 i = 0; i < ids.length; i++) {
        // Solidity 0.8.0 reverts on overflow
        // TODO: Improve this so we can sum same ids to check total is not > LIFT_LIMIT
        require(IERC1155(msg.sender).balanceOf(address(this), ids[i]) + values[i] <= LIFT_LIMIT, "Exceeds ERC1155 lift limit");
    }

    emit LogNFTLifted(msg.sender, from, t2PublicKey, ids, values, isFungible, ++liftNonce);

    return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
  }
}