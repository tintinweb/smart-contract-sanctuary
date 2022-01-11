pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Exchange {

    struct Order {
      string id;
      string tokenFrom;
      string tokenTo;
      string orderType;
      string price;
      string quantity;
      address from;
      string created;
    }

    bytes32 DOMAIN_SEPARATOR;
    
    mapping(address => string) private password;

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 constant ORDERS_TYPEHASH = keccak256("Order(string id,string tokenFrom,string tokenTo,string orderType,string price,string quantity,address from,string created)");

    constructor () {
        uint chainId = 1337;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes("BrowserBook")),
            keccak256(bytes("1")),
            chainId,
           address(this)
        ));
    }

    function setPass(string memory authorizationKey) public returns(bool){
        password[msg.sender] = authorizationKey;
        return true;
    }

    function getPass() public returns(string memory){
        return password[msg.sender];
    }

    function verifySignature(Order memory order, uint8 v, bytes32 r, bytes32 s) internal view returns(bool){
       bytes32 OrderHash =  keccak256(abi.encode(
            ORDERS_TYPEHASH,
            keccak256(bytes(order.id)),
            keccak256(bytes(order.tokenFrom)),
            keccak256(bytes(order.tokenTo)),
            keccak256(bytes(order.orderType)),
            keccak256(bytes(order.price)),
            keccak256(bytes(order.quantity)),
            order.from,
            keccak256(bytes(order.created))
        ));

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            OrderHash
        ));

        return ecrecover(digest, v, r, s) == order.from;
    }

    function executeOrder(
        address tokenOneAddress,
        address tokenTwoAddress,
        address tokenOneOwner,
        address tokenTwoOwner,
        uint256 tokenOneId,
        uint256 tokenTwoId,
        uint256 tokenOneAmount,
        uint256 tokenTwoAmount,
        bytes calldata data
    ) public {
        // Execute `safeBatchTransferFrom` call
        // Either succeeds or throws
        IERC1155(tokenOneAddress).safeTransferFrom(
            tokenOneOwner,
            tokenTwoOwner,
            tokenOneId,
            tokenOneAmount,
            data
        );

        // Execute `safeBatchTransferFrom` call
        // Either succeeds or throws
        IERC1155(tokenTwoAddress).safeTransferFrom(
            tokenTwoOwner,
            tokenOneOwner,
            tokenTwoId,
            tokenTwoAmount,
            data
        );
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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