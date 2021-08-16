/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

// File: node_modules\@openzeppelin\contracts\utils\introspection\IERC165.sol

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

// File: @openzeppelin\contracts\token\ERC1155\IERC1155.sol

// SPDX_License_Identifier: MIT

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

// File: contracts\model\IERC1155Views.sol

// SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @title IERC1155Views - An optional utility interface to improve the ERC-1155 Standard.
 * @dev This interface introduces some additional capabilities for ERC-1155 Tokens.
 */
interface IERC1155Views {

    /**
     * @dev Returns the total supply of the given token id
     * @param itemId the id of the token whose availability you want to know 
     */
    function totalSupply(uint256 itemId) external view returns (uint256);

    /**
     * @dev Returns the name of the given token id
     * @param itemId the id of the token whose name you want to know 
     */
    function name(uint256 itemId) external view returns (string memory);

    /**
     * @dev Returns the symbol of the given token id
     * @param itemId the id of the token whose symbol you want to know 
     */
    function symbol(uint256 itemId) external view returns (string memory);

    /**
     * @dev Returns the decimals of the given token id
     * @param itemId the id of the token whose decimals you want to know 
     */
    function decimals(uint256 itemId) external view returns (uint256);

    /**
     * @dev Returns the uri of the given token id
     * @param itemId the id of the token whose uri you want to know 
     */
    function uri(uint256 itemId) external view returns (string memory);
}

// File: contracts\model\Item.sol

//SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;
pragma abicoder v2;



struct Header {
    address host;
    string name;
    string symbol;
    string uri;
}

struct CreateItem {
    Header header;
    bytes32 collectionId;
    uint256 id;
    address[] accounts;
    uint256[] amounts;
}

interface Item is IERC1155, IERC1155Views {

    event CollectionItem(bytes32 indexed fromCollectionId, bytes32 indexed toCollectionId, uint256 indexed itemId);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);

    function burn(address account, uint256 itemId, uint256 amount) external;
    function burnBatch(address account, uint256[] calldata itemIds, uint256[] calldata amounts) external;

    function burn(address account, uint256 itemId, uint256 amount, bytes calldata data) external;
    function burnBatch(address account, uint256[] calldata itemIds, uint256[] calldata amounts, bytes calldata data) external;

    function mintItems(CreateItem[] calldata items) external returns(uint256[] memory itemIds);
    function setItemsCollection(uint256[] calldata itemIds, bytes32[] calldata collectionIds) external returns(bytes32[] memory oldCollectionIds);
    function setItemsMetadata(uint256[] calldata itemIds, Header[] calldata amounts) external returns(Header[] memory oldValues);

    function interoperableOf(uint256 itemId) external view returns(address);
}

// File: node_modules\@ethereansos\swissknife\contracts\generic\model\ILazyInitCapableElement.sol

// SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;


interface ILazyInitCapableElement is IERC165 {

    function lazyInit(bytes calldata lazyInitData) external returns(bytes memory initResponse);
    function initializer() external view returns(address);

    event Host(address indexed from, address indexed to);

    function host() external view returns(address);
    function setHost(address newValue) external returns(address oldValue);

    function subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata payload, uint256 value) external view returns(bool);
}

// File: @ethereansos\swissknife\contracts\dynamicMetadata\model\IDynamicMetadataCapableElement.sol

//SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;


interface IDynamicMetadataCapableElement is ILazyInitCapableElement {

    function uri() external view returns(string memory);
    function plainUri() external view returns(string memory);

    function setUri(string calldata newValue) external returns (string memory oldValue);

    function dynamicUriResolver() external view returns(address);
    function setDynamicUriResolver(address newValue) external returns(address oldValue);
}

// File: contracts\model\IItemMainInterface.sol

//SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;



struct ItemData {
    bytes32 collectionId;
    Header header;
    bytes32 domainSeparator;
    uint256 totalSupply;
    mapping(address => uint256) balanceOf;
    mapping(address => mapping(address => uint256)) allowance;
    mapping(address => uint256) nonces;
}

interface IItemMainInterface is Item, IDynamicMetadataCapableElement {

    event Collection(address indexed from, address indexed to, bytes32 indexed collectionId);

    function interoperableInterfaceModel() external view returns(address);
    function setInteroperableInterfaceModel(address value) external returns(address oldValue);

    function collection(bytes32 collectionId) external view returns(address host, string memory name, string memory symbol, string memory uri);
    function collectionUri(bytes32 collectionId) external view returns(string memory);
    function createCollection(Header calldata _collection, CreateItem[] calldata items) external returns(bytes32 collectionId, uint256[] memory itemIds);
    function setCollectionsMetadata(bytes32[] calldata collectionIds, Header[] calldata values) external returns(Header[] memory oldValues);

    function item(uint256 itemId) external view returns(bytes32 collectionId, Header memory header, bytes32 domainSeparator, uint256 totalSupply);

    function mintTransferOrBurn(bool isMulti, bytes calldata data) external;

    function allowance(address account, address spender, uint256 itemId) external view returns(uint256);
    function approve(address account, address spender, uint256 amount, uint256 itemId) external;
    function TYPEHASH_PERMIT() external view returns (bytes32);
    function EIP712_PERMIT_DOMAINSEPARATOR_NAME_AND_VERSION() external view returns(string memory domainSeparatorName, string memory domainSeparatorVersion);
    function permit(uint256 itemId, address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner, uint256 itemId) external view returns(uint256);
}

// File: contracts\impl\ItemMainInterfaceSupportsInterfaceImplementer.sol

//SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;


contract ItemMainInterfaceSupportsInterfaceImplementer is IERC165 {

    function supportsInterface(bytes4 interfaceId) external override pure returns(bool) {
        return 
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == IItemMainInterface(address(0)).balanceOf.selector ||
            interfaceId == IItemMainInterface(address(0)).balanceOfBatch.selector ||
            interfaceId == IItemMainInterface(address(0)).setApprovalForAll.selector ||
            interfaceId == IItemMainInterface(address(0)).isApprovedForAll.selector ||
            interfaceId == IItemMainInterface(address(0)).safeTransferFrom.selector ||
            interfaceId == IItemMainInterface(address(0)).safeBatchTransferFrom.selector ||
            interfaceId == 0xd9b67a26 ||//OpenSea Standard
            interfaceId == type(IERC1155Views).interfaceId ||
            interfaceId == IItemMainInterface(address(0)).totalSupply.selector ||
            interfaceId == 0x00ad800c ||//name(uint256)
            interfaceId == 0x4e41a1fb ||//symbol(uint256)
            interfaceId == IItemMainInterface(address(0)).decimals.selector ||
            interfaceId == 0x0e89341c ||//uri(uint256)
            interfaceId == type(Item).interfaceId ||
            interfaceId == 0x06fdde03 ||//name()
            interfaceId == 0x95d89b41 ||//symbol()
            interfaceId == 0xf5298aca ||//burn(address,uint256,uint256)
            interfaceId == 0x6b20c454 ||//burnBatch(address,uint256[],uint256[])
            interfaceId == 0x8a94b05f ||//burn(address,uint256,uint256,bytes)
            interfaceId == 0x5473422e ||//burnBatch(address,uint256[],uint256[],bytes)
            interfaceId == IItemMainInterface(address(0)).mintItems.selector ||
            interfaceId == IItemMainInterface(address(0)).setItemsCollection.selector ||
            interfaceId == IItemMainInterface(address(0)).setItemsMetadata.selector ||
            interfaceId == IItemMainInterface(address(0)).interoperableOf.selector ||
            interfaceId == type(IItemMainInterface).interfaceId ||
            interfaceId == IItemMainInterface(address(0)).interoperableInterfaceModel.selector ||
            interfaceId == IItemMainInterface(address(0)).setInteroperableInterfaceModel.selector ||
            interfaceId == IItemMainInterface(address(0)).collection.selector ||
            interfaceId == IItemMainInterface(address(0)).collectionUri.selector ||
            interfaceId == IItemMainInterface(address(0)).createCollection.selector ||
            interfaceId == IItemMainInterface(address(0)).setCollectionsMetadata.selector ||
            interfaceId == IItemMainInterface(address(0)).item.selector ||
            interfaceId == IItemMainInterface(address(0)).mintTransferOrBurn.selector ||
            interfaceId == IItemMainInterface(address(0)).allowance.selector ||
            interfaceId == IItemMainInterface(address(0)).approve.selector ||
            interfaceId == IItemMainInterface(address(0)).TYPEHASH_PERMIT.selector ||
            interfaceId == IItemMainInterface(address(0)).EIP712_PERMIT_DOMAINSEPARATOR_NAME_AND_VERSION.selector ||
            interfaceId == IItemMainInterface(address(0)).permit.selector ||
            interfaceId == IItemMainInterface(address(0)).nonces.selector;
    }
}