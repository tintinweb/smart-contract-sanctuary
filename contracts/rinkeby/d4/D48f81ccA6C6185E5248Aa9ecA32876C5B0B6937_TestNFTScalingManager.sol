/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// File: contracts\interfaces\ITestNFTScalingManager.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITestNFTScalingManager {
  event LogLifted(address indexed nftAddress, address indexed t1Address, bytes32 indexed t2PublicKey, uint256[] tokenIds,
      uint256[] amounts, uint256 nonce);
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

  uint256 public liftNonce;
  bytes4 constant internal ERC721Receiver = 0x150b7a02;
  bytes4 constant internal ERC1155Receiver = 0xf23a6e61;
  bytes4 constant internal ERC1155BatchReceiver = 0xbc197c81;

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
    emit LogLifted(msg.sender, from, abi.decode(data, (bytes32)), ids, values, ++liftNonce);
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
    emit LogLifted(msg.sender, from, abi.decode(data, (bytes32)), ids, values, ++liftNonce);
    return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
  }

  function onERC1155BatchReceived(address /* operator */, address from, uint256[] calldata ids, uint256[] calldata values,
      bytes calldata data)
    external
    override
    returns(bytes4)
  {
    emit LogLifted(msg.sender, from, abi.decode(data, (bytes32)), ids, values, ++liftNonce);
    return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
  }
}