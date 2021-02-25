/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

// Sources flattened with hardhat v2.0.11 https://hardhat.org

// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC721/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

/**
 * @title ERC721 Non-Fungible Token Standard, basic interface
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 * Note: The ERC-165 identifier for this interface is 0x80ac58cd.
 */
interface IERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * Gets the balance of the specified address
     * @param owner address to query the balance of
     * @return balance uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * Gets the owner of the specified ID
     * @param tokenId uint256 ID to query the owner of
     * @return owner address currently marked as the owner of the given ID
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * Approves another address to transfer the given token ID
     * @dev The zero address indicates there is no approved address.
     * @dev There can only be one approved address per token at a given time.
     * @dev Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * Gets the approved address for a token ID, or zero if no address set
     * @dev Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return operator address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * Sets or unsets the approval of a given operator
     * @dev An operator is allowed to transfer all tokens of the sender on their behalf
     * @param operator operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * Tells whether an operator is approved by a given owner
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * Transfers the ownership of a given token ID to another address
     * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * Safely transfers the ownership of a given token ID to another address
     *
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     *
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * Safely transfers the ownership of a given token ID to another address
     *
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     *
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts/introspection/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC721/[email protected]

pragma solidity 0.6.8;

/**
    @title ERC721 Non-Fungible Token Standard, token receiver
    @dev See https://eips.ethereum.org/EIPS/eip-721
    Interface for any contract that wants to support safeTransfers from ERC721 asset contracts.
    Note: The ERC-165 identifier for this interface is 0x150b7a02.
 */
interface IERC721Receiver {
    /**
        @notice Handle the receipt of an NFT
        @dev The ERC721 smart contract calls this function on the recipient
        after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
        otherwise the caller will revert the transaction. The selector to be
        returned can be obtained as `this.onERC721Received.selector`. This
        function MAY throw to revert and reject the transfer.
        Note: the ERC721 contract address is always the message sender.
        @param operator The address which called `safeTransferFrom` function
        @param from The address which previously owned the token
        @param tokenId The NFT identifier which is being transferred
        @param data Additional data with no specified format
        @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @animoca/ethereum-contracts-assets_inventory/contracts/token/ERC721/[email protected]

pragma solidity 0.6.8;


abstract contract ERC721Receiver is IERC721Receiver, IERC165 {
    bytes4 private constant _ERC165_INTERFACE_ID = type(IERC165).interfaceId;
    bytes4 private constant _ERC721_RECEIVER_INTERFACE_ID = type(IERC721Receiver).interfaceId;

    bytes4 internal constant _ERC721_RECEIVED = type(IERC721Receiver).interfaceId;
    bytes4 internal constant _ERC721_REJECTED = 0xffffffff;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _ERC165_INTERFACE_ID || interfaceId == _ERC721_RECEIVER_INTERFACE_ID;
    }
}


// File contracts/token/ERC1155721/BlackHoleBoredElonTweeter.sol

pragma solidity ^0.6.8;


contract BlackHoleBoredElonTweeter is ERC721Receiver {

    address public constant RARIBLE_NFT_CONTRACT = 0x60F80121C31A0d46B5279700f9DF786054aa5eE5;
    uint256 public constant BOREDELON_TWEET_NFT_ID = 182768;

    // some place with no way back
    address public constant BLACK_HOLE = 0xDeAD0deAD0DeAd0DEaD0dEAd0DeaD0dEAd0DEaD1;

    string public daImmortalText;
    string public daImmortalAuthor;
    address public daImmortalOwner;

    function onERC721Received(
        address /*operator*/,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // Door to hell, no trespassers
        require(msg.sender == RARIBLE_NFT_CONTRACT, "Wrong contract");
        require(tokenId == BOREDELON_TWEET_NFT_ID, "Wrong token");

        // Mark this moment forever on-chain
        daImmortalOwner = from;
        (daImmortalText, daImmortalAuthor) = abi.decode(data, (string, string));

        // NFT destruction
        IERC721(RARIBLE_NFT_CONTRACT).transferFrom(address(this), BLACK_HOLE, BOREDELON_TWEET_NFT_ID);

        // All went well :)
        return _ERC721_RECEIVED;
    }
}