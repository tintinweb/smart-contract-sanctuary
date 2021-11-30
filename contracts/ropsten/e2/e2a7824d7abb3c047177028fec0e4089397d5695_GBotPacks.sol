/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

/**
 *Submitted for verification at polygonscan.com on 2021-10-30
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File contracts/token/ERC1155/IERC1155InventoryBurnable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC1155 Inventory. optional extension: Burnable.
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 * @dev Note: The ERC-165 identifier for this interface is 0x921ed8d1.
 */
interface IERC1155InventoryBurnable {
    /**
     * Burns some token.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `id` does not represent a token.
     * @dev Reverts if `id` represents a Fungible Token and `value` is 0.
     * @dev Reverts if `id` represents a Fungible Token and `value` is higher than `from`'s balance.
     * @dev Reverts if `id` represents a Non-Fungible Token and `value` is not 1.
     * @dev Reverts if `id` represents a Non-Fungible Token which is not owned by `from`.
     * @dev Emits an {IERC1155-TransferSingle} event.
     * @param from Address of the current token owner.
     * @param id Identifier of the token to burn.
     * @param value Amount of token to burn.
     */
    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) external;

    /**
     * Burns multiple tokens.
     * @dev Reverts if `ids` and `values` have different lengths.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `ids` does not represent a token.
     * @dev Reverts if one of `ids` represents a Fungible Token and `value` is 0.
     * @dev Reverts if one of `ids` represents a Fungible Token and `value` is higher than `from`'s balance.
     * @dev Reverts if one of `ids` represents a Non-Fungible Token and `value` is not 1.
     * @dev Reverts if one of `ids` represents a Non-Fungible Token which is not owned by `from`.
     * @dev Emits an {IERC1155-TransferBatch} event.
     * @param from Address of the current tokens owner.
     * @param ids Identifiers of the tokens to burn.
     * @param values Amounts of tokens to burn.
     */
    function batchBurnFrom(
        address from,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external;
}


// File contracts/utils/types/AddressIsContract.sol



// Partially derived from OpenZeppelin:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/406c83649bd6169fc1b578e08506d78f0873b276/contracts/utils/Address.sol

pragma solidity >=0.7.6 <0.8.0;

/**
 * @dev Upgrades the address type to check if it is a contract.
 */
library AddressIsContract {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}


// File contracts/token/ERC1155/ERC1155InventoryIdentifiersLib.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC1155InventoryIdentifiersLib, a library to introspect inventory identifiers.
 * @dev With N=32, representing the Non-Fungible Collection mask length, identifiers are represented as follow:
 * (a) a Fungible Token:
 *     - most significant bit == 0
 * (b) a Non-Fungible Collection:
 *     - most significant bit == 1
 *     - (256-N) least significant bits == 0
 * (c) a Non-Fungible Token:
 *     - most significant bit == 1
 *     - (256-N) least significant bits != 0
 */
library ERC1155InventoryIdentifiersLib {
    // Non-Fungible bit. If an id has this bit set, it is a Non-Fungible (either Collection or Token)
    uint256 internal constant _NF_BIT = 1 << 255;

    // Mask for Non-Fungible Collection (including the nf bit)
    uint256 internal constant _NF_COLLECTION_MASK = uint256(type(uint32).max) << 224;
    uint256 internal constant _NF_TOKEN_MASK = ~_NF_COLLECTION_MASK;

    function isFungibleToken(uint256 id) internal pure returns (bool) {
        return id & _NF_BIT == 0;
    }

    function isNonFungibleToken(uint256 id) internal pure returns (bool) {
        return id & _NF_BIT != 0 && id & _NF_TOKEN_MASK != 0;
    }

    function getNonFungibleCollection(uint256 nftId) internal pure returns (uint256) {
        return nftId & _NF_COLLECTION_MASK;
    }
}


// File contracts/metatx/ManagedIdentity.sol



pragma solidity >=0.7.6 <0.8.0;

/*
 * Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner.
 */
abstract contract ManagedIdentity {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}


// File contracts/utils/introspection/IERC165.sol



pragma solidity >=0.7.6 <0.8.0;

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


// File contracts/token/ERC1155/IERC1155.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC1155 Multi Token Standard, basic interface.
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 * @dev Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    event URI(string _value, uint256 indexed _id);

    /**
     * Safely transfers some token.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `from` has an insufficient balance.
     * @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155received} fails or is refused.
     * @dev Emits a `TransferSingle` event.
     * @param from Current token owner.
     * @param to Address of the new token owner.
     * @param id Identifier of the token to transfer.
     * @param value Amount of token to transfer.
     * @param data Optional data to send along to a receiver contract.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /**
     * Safely transfers a batch of tokens.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `ids` and `values` have different lengths.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `from` has an insufficient balance for any of `ids`.
     * @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155batchReceived} fails or is refused.
     * @dev Emits a `TransferBatch` event.
     * @param from Current token owner.
     * @param to Address of the new token owner.
     * @param ids Identifiers of the tokens to transfer.
     * @param values Amounts of tokens to transfer.
     * @param data Optional data to send along to a receiver contract.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    /**
     * Retrieves the balance of `id` owned by account `owner`.
     * @param owner The account to retrieve the balance of.
     * @param id The identifier to retrieve the balance of.
     * @return The balance of `id` owned by account `owner`.
     */
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /**
     * Retrieves the balances of `ids` owned by accounts `owners`. For each pair:
     * @dev Reverts if `owners` and `ids` have different lengths.
     * @param owners The addresses of the token holders
     * @param ids The identifiers to retrieve the balance of.
     * @return The balances of `ids` owned by accounts `owners`.
     */
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * Enables or disables an operator's approval.
     * @dev Emits an `ApprovalForAll` event.
     * @param operator Address of the operator.
     * @param approved True to approve the operator, false to revoke an approval.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * Retrieves the approval status of an operator for a given owner.
     * @param owner Address of the authorisation giver.
     * @param operator Address of the operator.
     * @return True if the operator is approved, false if not.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File contracts/token/ERC1155/IERC1155InventoryFunctions.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC1155 Multi Token Standard, optional extension: Inventory.
 * Interface for Fungible/Non-Fungible Tokens management on an ERC1155 contract.
 * @dev See https://eips.ethereum.org/EIPS/eip-xxxx
 * @dev Note: The ERC-165 identifier for this interface is 0x09ce5c46.
 */
interface IERC1155InventoryFunctions {
    function ownerOf(uint256 nftId) external view returns (address);

    function isFungible(uint256 id) external view returns (bool);

    function collectionOf(uint256 nftId) external view returns (uint256);
}


// File contracts/token/ERC1155/IERC1155Inventory.sol



pragma solidity >=0.7.6 <0.8.0;


/**
 * @title ERC1155 Multi Token Standard, optional extension: Inventory.
 * Interface for Fungible/Non-Fungible Tokens management on an ERC1155 contract.
 *
 * This interface rationalizes the co-existence of Fungible and Non-Fungible Tokens
 * within the same contract. As several kinds of Fungible Tokens can be managed under
 * the Multi-Token standard, we consider that Non-Fungible Tokens can be classified
 * under their own specific type. We introduce the concept of Non-Fungible Collection
 * and consider the usage of 3 types of identifiers:
 * (a) Fungible Token identifiers, each representing a set of Fungible Tokens,
 * (b) Non-Fungible Collection identifiers, each representing a set of Non-Fungible Tokens (this is not a token),
 * (c) Non-Fungible Token identifiers.
 *
 * Identifiers nature
 * |       Type                | isFungible  | isCollection | isToken |
 * |  Fungible Token           |   true      |     true     |  true   |
 * |  Non-Fungible Collection  |   false     |     true     |  false  |
 * |  Non-Fungible Token       |   false     |     false    |  true   |
 *
 * Identifiers compatibilities
 * |       Type                |  transfer  |   balance    |   supply    |  owner  |
 * |  Fungible Token           |    OK      |     OK       |     OK      |   NOK   |
 * |  Non-Fungible Collection  |    NOK     |     OK       |     OK      |   NOK   |
 * |  Non-Fungible Token       |    OK      |   0 or 1     |   0 or 1    |   OK    |
 *
 * @dev See https://eips.ethereum.org/EIPS/eip-xxxx
 * @dev Note: The ERC-165 identifier for this interface is 0x09ce5c46.
 */
interface IERC1155Inventory is IERC1155, IERC1155InventoryFunctions {
    //================================================== ERC1155Inventory ===================================================//
    /**
     * Optional event emitted when a collection (Fungible Token or Non-Fungible Collection) is created.
     *  This event can be used by a client application to determine which identifiers are meaningful
     *  to track through the functions `balanceOf`, `balanceOfBatch` and `totalSupply`.
     * @dev This event MUST NOT be emitted twice for the same `collectionId`.
     */
    event CollectionCreated(uint256 indexed collectionId, bool indexed fungible);

    /**
     * Retrieves the owner of a Non-Fungible Token (ERC721-compatible).
     * @dev Reverts if `nftId` is owned by the zero address.
     * @param nftId Identifier of the token to query.
     * @return Address of the current owner of the token.
     */
    function ownerOf(uint256 nftId) external view override returns (address);

    /**
     * Introspects whether or not `id` represents a Fungible Token.
     *  This function MUST return true even for a Fungible Token which is not-yet created.
     * @param id The identifier to query.
     * @return bool True if `id` represents aFungible Token, false otherwise.
     */
    function isFungible(uint256 id) external view override returns (bool);

    /**
     * Introspects the Non-Fungible Collection to which `nftId` belongs.
     * @dev This function MUST return a value representing a Non-Fungible Collection.
     * @dev This function MUST return a value for a non-existing token, and SHOULD NOT be used to check the existence of a Non-Fungible Token.
     * @dev Reverts if `nftId` does not represent a Non-Fungible Token.
     * @param nftId The token identifier to query the collection of.
     * @return The Non-Fungible Collection identifier to which `nftId` belongs.
     */
    function collectionOf(uint256 nftId) external view override returns (uint256);

    //======================================================= ERC1155 =======================================================//

    /**
     * Retrieves the balance of `id` owned by account `owner`.
     * @param owner The account to retrieve the balance of.
     * @param id The identifier to retrieve the balance of.
     * @return
     *  If `id` represents a collection (Fungible Token or Non-Fungible Collection), the balance for this collection.
     *  If `id` represents a Non-Fungible Token, 1 if the token is owned by `owner`, else 0.
     */
    function balanceOf(address owner, uint256 id) external view override returns (uint256);

    /**
     * Retrieves the balances of `ids` owned by accounts `owners`.
     * @dev Reverts if `owners` and `ids` have different lengths.
     * @param owners The accounts to retrieve the balances of.
     * @param ids The identifiers to retrieve the balances of.
     * @return An array of elements such as for each pair `id`/`owner`:
     *  If `id` represents a collection (Fungible Token or Non-Fungible Collection), the balance for this collection.
     *  If `id` represents a Non-Fungible Token, 1 if the token is owned by `owner`, else 0.
     */
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view override returns (uint256[] memory);

    /**
     * Safely transfers some token.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if `id` does not represent a token.
     * @dev Reverts if `id` represents a Non-Fungible Token and `value` is not 1.
     * @dev Reverts if `id` represents a Non-Fungible Token and is not owned by `from`.
     * @dev Reverts if `id` represents a Fungible Token and `value` is 0.
     * @dev Reverts if `id` represents a Fungible Token and `from` has an insufficient balance.
     * @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155received} fails or is refused.
     * @dev Emits an {IERC1155-TransferSingle} event.
     * @param from Current token owner.
     * @param to Address of the new token owner.
     * @param id Identifier of the token to transfer.
     * @param value Amount of token to transfer.
     * @param data Optional data to pass to the receiver contract.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override;

    /**
     * @notice this documentation overrides its {IERC1155-safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)}.
     * Safely transfers a batch of tokens.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender is not approved.
     * @dev Reverts if one of `ids` does not represent a token.
     * @dev Reverts if one of `ids` represents a Non-Fungible Token and `value` is not 1.
     * @dev Reverts if one of `ids` represents a Non-Fungible Token and is not owned by `from`.
     * @dev Reverts if one of `ids` represents a Fungible Token and `value` is 0.
     * @dev Reverts if one of `ids` represents a Fungible Token and `from` has an insufficient balance.
     * @dev Reverts if one of `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155batchReceived} fails or is refused.
     * @dev Emits an {IERC1155-TransferBatch} event.
     * @param from Current tokens owner.
     * @param to Address of the new tokens owner.
     * @param ids Identifiers of the tokens to transfer.
     * @param values Amounts of tokens to transfer.
     * @param data Optional data to pass to the receiver contract.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override;
}


// File contracts/token/ERC1155/IERC1155MetadataURI.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC1155 Multi Token Standard, optional extension: Metadata URI.
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 * @dev Note: The ERC-165 identifier for this interface is 0x0e89341c.
 */
interface IERC1155MetadataURI {
    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given token.
     * @dev URIs are defined in RFC 3986.
     * @dev The URI MUST point to a JSON file that conforms to the "ERC1155 Metadata URI JSON Schema".
     * @dev The uri function SHOULD be used to retrieve values if no event was emitted.
     * @dev The uri function MUST return the same value as the latest event for an _id if it was emitted.
     * @dev The uri function MUST NOT be used to check for the existence of a token as it is possible for
     *  an implementation to return a valid string even if the token does not exist.
     * @return URI string
     */
    function uri(uint256 id) external view returns (string memory);
}


// File contracts/token/ERC1155/IERC1155InventoryTotalSupply.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC1155 Inventory, optional extension: Total Supply.
 * @dev See https://eips.ethereum.org/EIPS/eip-xxxx
 * @dev Note: The ERC-165 identifier for this interface is 0xbd85b039.
 */
interface IERC1155InventoryTotalSupply {
    /**
     * Retrieves the total supply of `id`.
     * @param id The identifier for which to retrieve the supply of.
     * @return
     *  If `id` represents a collection (Fungible Token or Non-Fungible Collection), the total supply for this collection.
     *  If `id` represents a Non-Fungible Token, 1 if the token exists, else 0.
     */
    function totalSupply(uint256 id) external view returns (uint256);
}


// File contracts/token/ERC1155/IERC1155TokenReceiver.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC1155 Multi Token Standard, Tokens Receiver.
 * Interface for any contract that wants to support transfers from ERC1155 asset contracts.
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 * @dev Note: The ERC-165 identifier for this interface is 0x4e2312e0.
 */
interface IERC1155TokenReceiver {
    /**
     * @notice Handle the receipt of a single ERC1155 token type.
     * An ERC1155 contract MUST call this function on a recipient contract, at the end of a `safeTransferFrom` after the balance update.
     * This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     *  (i.e. 0xf23a6e61) to accept the transfer.
     * Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
     * @param operator  The address which initiated the transfer (i.e. msg.sender)
     * @param from      The address which previously owned the token
     * @param id        The ID of the token being transferred
     * @param value     The amount of tokens being transferred
     * @param data      Additional data with no specified format
     * @return bytes4   `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice Handle the receipt of multiple ERC1155 token types.
     * An ERC1155 contract MUST call this function on a recipient contract, at the end of a `safeBatchTransferFrom` after the balance updates.
     * This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     *  (i.e. 0xbc197c81) if to accept the transfer(s).
     * Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
     * @param operator  The address which initiated the batch transfer (i.e. msg.sender)
     * @param from      The address which previously owned the token
     * @param ids       An array containing ids of each token being transferred (order and length must match _values array)
     * @param values    An array containing amounts of each token being transferred (order and length must match _ids array)
     * @param data      Additional data with no specified format
     * @return          `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


// File contracts/token/ERC1155/ERC1155InventoryBase.sol



pragma solidity >=0.7.6 <0.8.0;







/**
 * @title ERC1155 Inventory Base.
 * @dev The functions `safeTransferFrom(address,address,uint256,uint256,bytes)`
 *  and `safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)` need to be implemented by a child contract.
 * @dev The function `uri(uint256)` needs to be implemented by a child contract, for example with the help of `BaseMetadataURI`.
 */
abstract contract ERC1155InventoryBase is ManagedIdentity, IERC165, IERC1155Inventory, IERC1155MetadataURI, IERC1155InventoryTotalSupply {
    using ERC1155InventoryIdentifiersLib for uint256;

    // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant _ERC1155_RECEIVED = 0xf23a6e61;

    // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    bytes4 internal constant _ERC1155_BATCH_RECEIVED = 0xbc197c81;

    // Burnt Non-Fungible Token owner's magic value
    uint256 internal constant _BURNT_NFT_OWNER = 0xdead000000000000000000000000000000000000000000000000000000000000;

    /* owner => operator => approved */
    mapping(address => mapping(address => bool)) internal _operators;

    /* collection ID => owner => balance */
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    /* collection ID => supply */
    mapping(uint256 => uint256) internal _supplies;

    /* NFT ID => owner */
    mapping(uint256 => uint256) internal _owners;

    /* collection ID => creator */
    mapping(uint256 => address) internal _creators;

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IERC1155InventoryFunctions).interfaceId ||
            interfaceId == type(IERC1155InventoryTotalSupply).interfaceId;
    }

    //======================================================= ERC1155 =======================================================//

    /// @inheritdoc IERC1155Inventory
    function balanceOf(address owner, uint256 id) public view virtual override returns (uint256) {
        require(owner != address(0), "Inventory: zero address");

        if (id.isNonFungibleToken()) {
            return address(uint160(_owners[id])) == owner ? 1 : 0;
        }

        return _balances[id][owner];
    }

    /// @inheritdoc IERC1155Inventory
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view virtual override returns (uint256[] memory) {
        require(owners.length == ids.length, "Inventory: inconsistent arrays");

        uint256[] memory balances = new uint256[](owners.length);

        for (uint256 i = 0; i != owners.length; ++i) {
            balances[i] = balanceOf(owners[i], ids[i]);
        }

        return balances;
    }

    /// @inheritdoc IERC1155
    function setApprovalForAll(address operator, bool approved) public virtual override {
        address sender = _msgSender();
        require(operator != sender, "Inventory: self-approval");
        _operators[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /// @inheritdoc IERC1155
    function isApprovedForAll(address tokenOwner, address operator) public view virtual override returns (bool) {
        return _operators[tokenOwner][operator];
    }

    //================================================== ERC1155Inventory ===================================================//

    /// @inheritdoc IERC1155Inventory
    function isFungible(uint256 id) external pure virtual override returns (bool) {
        return id.isFungibleToken();
    }

    /// @inheritdoc IERC1155Inventory
    function collectionOf(uint256 nftId) external pure virtual override returns (uint256) {
        require(nftId.isNonFungibleToken(), "Inventory: not an NFT");
        return nftId.getNonFungibleCollection();
    }

    /// @inheritdoc IERC1155Inventory
    function ownerOf(uint256 nftId) public view virtual override returns (address) {
        address owner = address(uint160(_owners[nftId]));
        require(owner != address(0), "Inventory: non-existing NFT");
        return owner;
    }

    //============================================= ERC1155InventoryTotalSupply =============================================//

    /// @inheritdoc IERC1155InventoryTotalSupply
    function totalSupply(uint256 id) external view virtual override returns (uint256) {
        if (id.isNonFungibleToken()) {
            return address(uint160(_owners[id])) == address(0) ? 0 : 1;
        } else {
            return _supplies[id];
        }
    }

    //============================================ High-level Internal Functions ============================================//

    /**
     * Creates a collection (optional).
     * @dev Reverts if `collectionId` does not represent a collection.
     * @dev Reverts if `collectionId` has already been created.
     * @dev Emits a {IERC1155Inventory-CollectionCreated} event.
     * @param collectionId Identifier of the collection.
     */
    function _createCollection(uint256 collectionId) internal virtual {
        require(!collectionId.isNonFungibleToken(), "Inventory: not a collection");
        require(_creators[collectionId] == address(0), "Inventory: existing collection");
        _creators[collectionId] = _msgSender();
        emit CollectionCreated(collectionId, collectionId.isFungibleToken());
    }

    function _creator(uint256 collectionId) internal view virtual returns (address) {
        require(!collectionId.isNonFungibleToken(), "Inventory: not a collection");
        return _creators[collectionId];
    }

    //============================================== Helper Internal Functions ==============================================//

    /**
     * Returns whether `sender` is authorised to make a transfer on behalf of `from`.
     * @param from The address to check operatibility upon.
     * @param sender The sender address.
     * @return True if sender is `from` or an operator for `from`, false otherwise.
     */
    function _isOperatable(address from, address sender) internal view virtual returns (bool) {
        return (from == sender) || _operators[from][sender];
    }

    /**
     * Calls {IERC1155TokenReceiver-onERC1155Received} on a target contract.
     * @dev Reverts if `to` is not a contract.
     * @dev Reverts if the call to the target fails or is refused.
     * @param from Previous token owner.
     * @param to New token owner.
     * @param id Identifier of the token transferred.
     * @param value Amount of token transferred.
     * @param data Optional data to send along with the receiver contract call.
     */
    function _callOnERC1155Received(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal {
        require(IERC1155TokenReceiver(to).onERC1155Received(_msgSender(), from, id, value, data) == _ERC1155_RECEIVED, "Inventory: transfer refused");
    }

    /**
     * Calls {IERC1155TokenReceiver-onERC1155batchReceived} on a target contract.
     * @dev Reverts if `to` is not a contract.
     * @dev Reverts if the call to the target fails or is refused.
     * @param from Previous tokens owner.
     * @param to New tokens owner.
     * @param ids Identifiers of the tokens to transfer.
     * @param values Amounts of tokens to transfer.
     * @param data Optional data to send along with the receiver contract call.
     */
    function _callOnERC1155BatchReceived(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        require(
            IERC1155TokenReceiver(to).onERC1155BatchReceived(_msgSender(), from, ids, values, data) == _ERC1155_BATCH_RECEIVED,
            "Inventory: transfer refused"
        );
    }
}


// File contracts/token/ERC1155/ERC1155Inventory.sol



pragma solidity >=0.7.6 <0.8.0;

// solhint-disable-next-line max-line-length

/**
 * @title ERC1155Inventory, a contract which manages up to multiple Collections of Fungible and Non-Fungible Tokens.
 * @dev The function `uri(uint256)` needs to be implemented by a child contract, for example with the help of `BaseMetadataURI`.
 */
abstract contract ERC1155Inventory is ERC1155InventoryBase {
    using AddressIsContract for address;
    using ERC1155InventoryIdentifiersLib for uint256;

    //======================================================= ERC1155 =======================================================//

    /// @inheritdoc IERC1155Inventory
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override {
        address sender = _msgSender();
        require(to != address(0), "Inventory: transfer to zero");
        require(_isOperatable(from, sender), "Inventory: non-approved sender");

        if (id.isFungibleToken()) {
            _transferFungible(from, to, id, value);
        } else if (id.isNonFungibleToken()) {
            _transferNFT(from, to, id, value, false);
        } else {
            revert("Inventory: not a token id");
        }

        emit TransferSingle(sender, from, to, id, value);
        if (to.isContract()) {
            _callOnERC1155Received(from, to, id, value, data);
        }
    }

    /// @inheritdoc IERC1155Inventory
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override {
        // internal function to avoid stack too deep error
        _safeBatchTransferFrom(from, to, ids, values, data);
    }

    //============================================ High-level Internal Functions ============================================//

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        require(to != address(0), "Inventory: transfer to zero");
        uint256 length = ids.length;
        require(length == values.length, "Inventory: inconsistent arrays");
        address sender = _msgSender();
        require(_isOperatable(from, sender), "Inventory: non-approved sender");

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        for (uint256 i; i != length; ++i) {
            uint256 id = ids[i];
            uint256 value = values[i];
            if (id.isFungibleToken()) {
                _transferFungible(from, to, id, value);
            } else if (id.isNonFungibleToken()) {
                _transferNFT(from, to, id, value, true);
                uint256 nextCollectionId = id.getNonFungibleCollection();
                if (nfCollectionId == 0) {
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    if (nextCollectionId != nfCollectionId) {
                        _transferNFTUpdateCollection(from, to, nfCollectionId, nfCollectionCount);
                        nfCollectionId = nextCollectionId;
                        nfCollectionCount = 1;
                    } else {
                        ++nfCollectionCount;
                    }
                }
            } else {
                revert("Inventory: not a token id");
            }
        }

        if (nfCollectionId != 0) {
            _transferNFTUpdateCollection(from, to, nfCollectionId, nfCollectionCount);
        }

        emit TransferBatch(sender, from, to, ids, values);
        if (to.isContract()) {
            _callOnERC1155BatchReceived(from, to, ids, values, data);
        }
    }

    function _safeMint(
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal {
        require(to != address(0), "Inventory: mint to zero");

        if (id.isFungibleToken()) {
            _mintFungible(to, id, value);
        } else if (id.isNonFungibleToken()) {
            _mintNFT(to, id, value, false);
        } else {
            revert("Inventory: not a token id");
        }

        emit TransferSingle(_msgSender(), address(0), to, id, value);
        if (to.isContract()) {
            _callOnERC1155Received(address(0), to, id, value, data);
        }
    }

    function _safeBatchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "Inventory: mint to zero");
        uint256 length = ids.length;
        require(length == values.length, "Inventory: inconsistent arrays");

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        for (uint256 i; i != length; ++i) {
            uint256 id = ids[i];
            uint256 value = values[i];
            if (id.isFungibleToken()) {
                _mintFungible(to, id, value);
            } else if (id.isNonFungibleToken()) {
                _mintNFT(to, id, value, true);
                uint256 nextCollectionId = id.getNonFungibleCollection();
                if (nfCollectionId == 0) {
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    if (nextCollectionId != nfCollectionId) {
                        _balances[nfCollectionId][to] += nfCollectionCount;
                        _supplies[nfCollectionId] += nfCollectionCount;
                        nfCollectionId = nextCollectionId;
                        nfCollectionCount = 1;
                    } else {
                        ++nfCollectionCount;
                    }
                }
            } else {
                revert("Inventory: not a token id");
            }
        }

        if (nfCollectionId != 0) {
            _balances[nfCollectionId][to] += nfCollectionCount;
            _supplies[nfCollectionId] += nfCollectionCount;
        }

        emit TransferBatch(_msgSender(), address(0), to, ids, values);
        if (to.isContract()) {
            _callOnERC1155BatchReceived(address(0), to, ids, values, data);
        }
    }

    //============================================== Helper Internal Functions ==============================================//

    function _mintFungible(
        address to,
        uint256 id,
        uint256 value
    ) internal {
        require(value != 0, "Inventory: zero value");
        uint256 supply = _supplies[id];
        uint256 newSupply = supply + value;
        require(newSupply > supply, "Inventory: supply overflow");
        _supplies[id] = newSupply;
        // cannot overflow as any balance is bounded up by the supply which cannot overflow
        _balances[id][to] += value;
    }

    function _mintNFT(
        address to,
        uint256 id,
        uint256 value,
        bool isBatch
    ) internal {
        require(value == 1, "Inventory: wrong NFT value");
        require(_owners[id] == 0, "Inventory: existing/burnt NFT");

        _owners[id] = uint256(uint160(to));

        if (!isBatch) {
            uint256 collectionId = id.getNonFungibleCollection();
            // it is virtually impossible that a Non-Fungible Collection supply
            // overflows due to the cost of minting individual tokens
            ++_supplies[collectionId];
            // cannot overflow as supply cannot overflow
            ++_balances[collectionId][to];
        }
    }

    function _transferFungible(
        address from,
        address to,
        uint256 id,
        uint256 value
    ) internal {
        require(value != 0, "Inventory: zero value");
        uint256 balance = _balances[id][from];
        require(balance >= value, "Inventory: not enough balance");
        if (from != to) {
            _balances[id][from] = balance - value;
            // cannot overflow as supply cannot overflow
            _balances[id][to] += value;
        }
    }

    function _transferNFT(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bool isBatch
    ) internal {
        require(value == 1, "Inventory: wrong NFT value");
        require(from == address(uint160(_owners[id])), "Inventory: non-owned NFT");
        _owners[id] = uint256(uint160(to));
        if (!isBatch) {
            uint256 collectionId = id.getNonFungibleCollection();
            // cannot underflow as balance is verified through ownership
            _balances[collectionId][from] -= 1;
            // cannot overflow as supply cannot overflow
            _balances[collectionId][to] += 1;
        }
    }

    function _transferNFTUpdateCollection(
        address from,
        address to,
        uint256 collectionId,
        uint256 amount
    ) internal virtual {
        if (from != to) {
            // cannot underflow as balance is verified through ownership
            _balances[collectionId][from] -= amount;
            // cannot overflow as supply cannot overflow
            _balances[collectionId][to] += amount;
        }
    }
}


// File contracts/token/ERC1155/ERC1155InventoryBurnable.sol



pragma solidity >=0.7.6 <0.8.0;


/**
 * @title ERC1155Inventory, burnable version.
 * @dev The function `uri(uint256)` needs to be implemented by a child contract, for example with the help of `BaseMetadataURI`.
 */
abstract contract ERC1155InventoryBurnable is IERC1155InventoryBurnable, ERC1155Inventory {
    using ERC1155InventoryIdentifiersLib for uint256;

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155InventoryBurnable).interfaceId || super.supportsInterface(interfaceId);
    }

    //============================================== ERC1155InventoryBurnable ===============================================//

    /// @inheritdoc IERC1155InventoryBurnable
    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) public virtual override {
        address sender = _msgSender();
        require(_isOperatable(from, sender), "Inventory: non-approved sender");

        if (id.isFungibleToken()) {
            _burnFungible(from, id, value);
        } else if (id.isNonFungibleToken()) {
            _burnNFT(from, id, value, false);
        } else {
            revert("Inventory: not a token id");
        }

        emit TransferSingle(sender, from, address(0), id, value);
    }

    /// @inheritdoc IERC1155InventoryBurnable
    function batchBurnFrom(
        address from,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {
        uint256 length = ids.length;
        require(length == values.length, "Inventory: inconsistent arrays");

        address sender = _msgSender();
        require(_isOperatable(from, sender), "Inventory: non-approved sender");

        uint256 nfCollectionId;
        uint256 nfCollectionCount;
        for (uint256 i; i != length; ++i) {
            uint256 id = ids[i];
            uint256 value = values[i];
            if (id.isFungibleToken()) {
                _burnFungible(from, id, value);
            } else if (id.isNonFungibleToken()) {
                _burnNFT(from, id, value, true);
                uint256 nextCollectionId = id.getNonFungibleCollection();
                if (nfCollectionId == 0) {
                    nfCollectionId = nextCollectionId;
                    nfCollectionCount = 1;
                } else {
                    if (nextCollectionId != nfCollectionId) {
                        _balances[nfCollectionId][from] -= nfCollectionCount;
                        _supplies[nfCollectionId] -= nfCollectionCount;
                        nfCollectionId = nextCollectionId;
                        nfCollectionCount = 1;
                    } else {
                        ++nfCollectionCount;
                    }
                }
            } else {
                revert("Inventory: not a token id");
            }
        }

        if (nfCollectionId != 0) {
            _balances[nfCollectionId][from] -= nfCollectionCount;
            _supplies[nfCollectionId] -= nfCollectionCount;
        }

        emit TransferBatch(sender, from, address(0), ids, values);
    }

    //============================================== Helper Internal Functions ==============================================//

    function _burnFungible(
        address from,
        uint256 id,
        uint256 value
    ) internal {
        require(value != 0, "Inventory: zero value");
        uint256 balance = _balances[id][from];
        require(balance >= value, "Inventory: not enough balance");
        _balances[id][from] = balance - value;
        // Cannot underflow
        _supplies[id] -= value;
    }

    function _burnNFT(
        address from,
        uint256 id,
        uint256 value,
        bool isBatch
    ) internal {
        require(value == 1, "Inventory: wrong NFT value");
        require(from == address(uint160(_owners[id])), "Inventory: non-owned NFT");
        _owners[id] = _BURNT_NFT_OWNER;

        if (!isBatch) {
            uint256 collectionId = id.getNonFungibleCollection();
            // cannot underflow as balance is confirmed through ownership
            --_balances[collectionId][from];
            // Cannot underflow
            --_supplies[collectionId];
        }
    }
}


// File contracts/token/ERC1155/IERC1155InventoryMintable.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC1155 Inventory, optional extension: Mintable.
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 */
interface IERC1155InventoryMintable {
    /**
     * Safely mints some token.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `id` is not a token.
     * @dev Reverts if `id` represents a Non-Fungible Token and `value` is not 1.
     * @dev Reverts if `id` represents a Non-Fungible Token which has already been minted.
     * @dev Reverts if `id` represents a Fungible Token and `value` is 0.
     * @dev Reverts if `id` represents a Fungible Token and there is an overflow of supply.
     * @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails or is refused.
     * @dev Emits an {IERC1155-TransferSingle} event.
     * @param to Address of the new token owner.
     * @param id Identifier of the token to mint.
     * @param value Amount of token to mint.
     * @param data Optional data to send along to a receiver contract.
     */
    function safeMint(
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /**
     * Safely mints a batch of tokens.
     * @dev Reverts if `ids` and `values` have different lengths.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if one of `ids` is not a token.
     * @dev Reverts if one of `ids` represents a Non-Fungible Token and its paired value is not 1.
     * @dev Reverts if one of `ids` represents a Non-Fungible Token which has already been minted.
     * @dev Reverts if one of `ids` represents a Fungible Token and its paired value is 0.
     * @dev Reverts if one of `ids` represents a Fungible Token and there is an overflow of supply.
     * @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155batchReceived} fails or is refused.
     * @dev Emits an {IERC1155-TransferBatch} event.
     * @param to Address of the new tokens owner.
     * @param ids Identifiers of the tokens to mint.
     * @param values Amounts of tokens to mint.
     * @param data Optional data to send along to a receiver contract.
     */
    function safeBatchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}


// File contracts/token/ERC1155/IERC1155InventoryCreator.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC1155 Inventory, optional extension: Creator.
 * @dev See https://eips.ethereum.org/EIPS/eip-1155
 * @dev Note: The ERC-165 identifier for this interface is 0x510b5158.
 */
interface IERC1155InventoryCreator {
    /**
     * Returns the creator of a collection, or the zero address if the collection has not been created.
     * @dev Reverts if `collectionId` does not represent a collection.
     * @param collectionId Identifier of the collection.
     * @return The creator of a collection, or the zero address if the collection has not been created.
     */
    function creator(uint256 collectionId) external view returns (address);
}


// File contracts/utils/access/IERC173.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC-173 Contract Ownership Standard
 * Note: the ERC-165 identifier for this interface is 0x7f5828d0
 */
interface IERC173 {
    /**
     * Event emited when ownership of a contract changes.
     * @param previousOwner the previous owner.
     * @param newOwner the new owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * Get the address of the owner
     * @return The address of the owner.
     */
    function owner() external view returns (address);

    /**
     * Set the address of the new owner of the contract
     * Set newOwner to address(0) to renounce any ownership.
     * @dev Emits an {OwnershipTransferred} event.
     * @param newOwner The address of the new owner of the contract. Using the zero address means renouncing ownership.
     */
    function transferOwnership(address newOwner) external;
}


// File contracts/utils/access/Ownable.sol



pragma solidity >=0.7.6 <0.8.0;


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
abstract contract Ownable is ManagedIdentity, IERC173 {
    address internal _owner;

    /**
     * Initializes the contract, setting the deployer as the initial owner.
     * @dev Emits an {IERC173-OwnershipTransferred(address,address)} event.
     */
    constructor(address owner_) {
        _owner = owner_;
        emit OwnershipTransferred(address(0), owner_);
    }

    /**
     * Gets the address of the current contract owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * See {IERC173-transferOwnership(address)}
     * @dev Reverts if the sender is not the current contract owner.
     * @param newOwner the address of the new owner. Use the zero address to renounce the ownership.
     */
    function transferOwnership(address newOwner) public virtual override {
        _requireOwnership(_msgSender());
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    /**
     * @dev Reverts if `account` is not the contract owner.
     * @param account the account to test.
     */
    function _requireOwnership(address account) internal virtual {
        require(account == this.owner(), "Ownable: not the owner");
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}


// File contracts/utils/types/UInt256ToDecimalString.sol



// Partially derived from OpenZeppelin:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/8b10cb38d8fedf34f2d89b0ed604f2dceb76d6a9/contracts/utils/Strings.sol

pragma solidity >=0.7.6 <0.8.0;

library UInt256ToDecimalString {
    function toDecimalString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }
}


// File contracts/metadata/BaseMetadataURI.sol



pragma solidity >=0.7.6 <0.8.0;


abstract contract BaseMetadataURI is ManagedIdentity, Ownable {
    using UInt256ToDecimalString for uint256;

    event BaseMetadataURISet(string baseMetadataURI);

    string public baseMetadataURI;

    function setBaseMetadataURI(string calldata baseMetadataURI_) external {
        _requireOwnership(_msgSender());
        baseMetadataURI = baseMetadataURI_;
        emit BaseMetadataURISet(baseMetadataURI_);
    }

    function _uri(uint256 id) internal view virtual returns (string memory) {
        return string(abi.encodePacked(baseMetadataURI, id.toDecimalString()));
    }
}


// File contracts/utils/access/MinterRole.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * Contract which allows derived contracts access control over token minting operations.
 */
contract MinterRole is Ownable {
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    mapping(address => bool) public isMinter;

    /**
     * Constructor.
     */
    constructor(address owner_) Ownable(owner_) {
        _addMinter(owner_);
    }

    /**
     * Grants the minter role to a non-minter.
     * @dev reverts if the sender is not the contract owner.
     * @param account The account to grant the minter role to.
     */
    function addMinter(address account) public {
        _requireOwnership(_msgSender());
        _addMinter(account);
    }

    /**
     * Renounces the granted minter role.
     * @dev reverts if the sender is not a minter.
     */
    function renounceMinter() public {
        address account = _msgSender();
        _requireMinter(account);
        isMinter[account] = false;
        emit MinterRemoved(account);
    }

    function _requireMinter(address account) internal view {
        require(isMinter[account], "MinterRole: not a Minter");
    }

    function _addMinter(address account) internal {
        isMinter[account] = true;
        emit MinterAdded(account);
    }
}


// File contracts/utils/ERC20Wrapper.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20Wrapper
 * Wraps ERC20 functions to support non-standard implementations which do not return a bool value.
 * Calls to the wrapped functions revert only if they throw or if they return false.
 */
library ERC20Wrapper {
    using AddressIsContract for address;

    function wrappedTransfer(
        IWrappedERC20 token,
        address to,
        uint256 value
    ) internal {
        _callWithOptionalReturnData(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function wrappedTransferFrom(
        IWrappedERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callWithOptionalReturnData(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function wrappedApprove(
        IWrappedERC20 token,
        address spender,
        uint256 value
    ) internal {
        _callWithOptionalReturnData(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function _callWithOptionalReturnData(IWrappedERC20 token, bytes memory callData) internal {
        address target = address(token);
        require(target.isContract(), "ERC20Wrapper: non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = target.call(callData);
        if (success) {
            if (data.length != 0) {
                require(abi.decode(data, (bool)), "ERC20Wrapper: operation failed");
            }
        } else {
            // revert using a standard revert message
            if (data.length == 0) {
                revert("ERC20Wrapper: operation failed");
            }

            // revert using the revert message coming from the call
            assembly {
                let size := mload(data)
                revert(add(32, data), size)
            }
        }
    }
}

interface IWrappedERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);
}


// File contracts/utils/Recoverable.sol



pragma solidity >=0.7.6 <0.8.0;



abstract contract Recoverable is ManagedIdentity, Ownable {
    using ERC20Wrapper for IWrappedERC20;

    /**
     * Extract ERC20 tokens which were accidentally sent to the contract to a list of accounts.
     * Warning: this function should be overriden for contracts which are supposed to hold ERC20 tokens
     * so that the extraction is limited to only amounts sent accidentally.
     * @dev Reverts if the sender is not the contract owner.
     * @dev Reverts if `accounts`, `tokens` and `amounts` do not have the same length.
     * @dev Reverts if one of `tokens` is does not implement the ERC20 transfer function.
     * @dev Reverts if one of the ERC20 transfers fail for any reason.
     * @param accounts the list of accounts to transfer the tokens to.
     * @param tokens the list of ERC20 token addresses.
     * @param amounts the list of token amounts to transfer.
     */
    function recoverERC20s(
        address[] calldata accounts,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external virtual {
        _requireOwnership(_msgSender());
        uint256 length = accounts.length;
        require(length == tokens.length && length == amounts.length, "Recov: inconsistent arrays");
        for (uint256 i = 0; i != length; ++i) {
            IWrappedERC20(tokens[i]).wrappedTransfer(accounts[i], amounts[i]);
        }
    }

    /**
     * Extract ERC721 tokens which were accidentally sent to the contract to a list of accounts.
     * Warning: this function should be overriden for contracts which are supposed to hold ERC721 tokens
     * so that the extraction is limited to only tokens sent accidentally.
     * @dev Reverts if the sender is not the contract owner.
     * @dev Reverts if `accounts`, `contracts` and `amounts` do not have the same length.
     * @dev Reverts if one of `contracts` is does not implement the ERC721 transferFrom function.
     * @dev Reverts if one of the ERC721 transfers fail for any reason.
     * @param accounts the list of accounts to transfer the tokens to.
     * @param contracts the list of ERC721 contract addresses.
     * @param tokenIds the list of token ids to transfer.
     */
    function recoverERC721s(
        address[] calldata accounts,
        address[] calldata contracts,
        uint256[] calldata tokenIds
    ) external virtual {
        _requireOwnership(_msgSender());
        uint256 length = accounts.length;
        require(length == contracts.length && length == tokenIds.length, "Recov: inconsistent arrays");
        for (uint256 i = 0; i != length; ++i) {
            IRecoverableERC721(contracts[i]).transferFrom(address(this), accounts[i], tokenIds[i]);
        }
    }
}

interface IRecoverableERC721 {
    /// See {IERC721-transferFrom(address,address,uint256)}
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}


// File contracts/utils/lifecycle/Pausable.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @dev Contract which allows children to implement pausability.
 */
abstract contract Pausable is ManagedIdentity {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool public paused;

    constructor(bool paused_) {
        paused = paused_;
    }

    function _requireNotPaused() internal view {
        require(!paused, "Pausable: paused");
    }

    function _requirePaused() internal view {
        require(paused, "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual {
        _requireNotPaused();
        paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual {
        _requirePaused();
        paused = false;
        emit Unpaused(_msgSender());
    }
}


// File ethereum-universal-forwarder/src/solc_0.7/ERC2771/[email protected]


pragma solidity ^0.7.0;

abstract contract UsingAppendedCallData {
    function _lastAppendedDataAsSender() internal pure virtual returns (address payable sender) {
        // Copied from openzeppelin : https://github.com/OpenZeppelin/openzeppelin-contracts/blob/9d5f77db9da0604ce0b25148898a94ae2c20d70f/contracts/metatx/ERC2771Context.sol1
        // The assembly code is more direct than the Solidity version using `abi.decode`.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sender := shr(96, calldataload(sub(calldatasize(), 20)))
        }
    }

    function _msgDataAssuming20BytesAppendedData() internal pure virtual returns (bytes calldata) {
        return msg.data[:msg.data.length - 20];
    }
}


// File ethereum-universal-forwarder/src/solc_0.7/ERC2771/[email protected]


pragma solidity ^0.7.0;

interface IERC2771 {
    function isTrustedForwarder(address forwarder) external view returns (bool);
}


// File ethereum-universal-forwarder/src/solc_0.7/ERC2771/[email protected]


pragma solidity ^0.7.0;

interface IForwarderRegistry {
    function isForwarderFor(address, address) external view returns (bool);
}


// File ethereum-universal-forwarder/src/solc_0.7/ERC2771/[email protected]


pragma solidity ^0.7.0;



abstract contract UsingUniversalForwarding is UsingAppendedCallData, IERC2771 {
    IForwarderRegistry internal immutable _forwarderRegistry;
    address internal immutable _universalForwarder;

    constructor(IForwarderRegistry forwarderRegistry, address universalForwarder) {
        _universalForwarder = universalForwarder;
        _forwarderRegistry = forwarderRegistry;
    }

    function isTrustedForwarder(address forwarder) external view virtual override returns (bool) {
        return forwarder == _universalForwarder || forwarder == address(_forwarderRegistry);
    }

    function _msgSender() internal view virtual returns (address payable) {
        address payable msgSender = msg.sender;
        address payable sender = _lastAppendedDataAsSender();
        if (msgSender == address(_forwarderRegistry) || msgSender == _universalForwarder) {
            // if forwarder use appended data
            return sender;
        }

        // if msg.sender is neither the registry nor the universal forwarder,
        // we have to check the last 20bytes of the call data intepreted as an address
        // and check if the msg.sender was registered as forewarder for that address
        // we check tx.origin to save gas in case where msg.sender == tx.origin
        // solhint-disable-next-line avoid-tx-origin
        if (msgSender != tx.origin && _forwarderRegistry.isForwarderFor(sender, msgSender)) {
            return sender;
        }

        return msgSender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        address payable msgSender = msg.sender;
        if (msgSender == address(_forwarderRegistry) || msgSender == _universalForwarder) {
            // if forwarder use appended data
            return _msgDataAssuming20BytesAppendedData();
        }

        // we check tx.origin to save gas in case where msg.sender == tx.origin
        // solhint-disable-next-line avoid-tx-origin
        if (msgSender != tx.origin && _forwarderRegistry.isForwarderFor(_lastAppendedDataAsSender(), msgSender)) {
            return _msgDataAssuming20BytesAppendedData();
        }
        return msg.data;
    }
}


// File contracts/token/ERC1155/GBotPacks/GBotPacks.sol



pragma solidity >=0.7.6 <0.8.0;

// solhint-disable max-line-length








// solhint-enable max-line-length

contract GBotPacks is
    ERC1155InventoryBurnable,
    IERC1155InventoryMintable,
    IERC1155InventoryCreator,
    BaseMetadataURI,
    MinterRole,
    Pausable,
    Recoverable,
    UsingUniversalForwarding
{
    constructor(IForwarderRegistry forwarderRegistry, address universalForwarder)
        ERC1155Inventory()
        MinterRole(msg.sender)
        Pausable(false)
        UsingUniversalForwarding(forwarderRegistry, universalForwarder)
    {}

    // ===================================================================================================
    //                                 User Public Functions
    // ===================================================================================================

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155InventoryCreator).interfaceId || super.supportsInterface(interfaceId);
    }

    //================================== ERC1155MetadataURI =======================================/

    /// @dev See {IERC1155MetadataURI-uri(uint256)}.
    function uri(uint256 id) public view virtual override returns (string memory) {
        return _uri(id);
    }

    //================================== ERC1155InventoryCreator =======================================/

    /// @dev See {IERC1155InventoryCreator-creator(uint256)}.
    function creator(uint256 collectionId) external view override returns (address) {
        return _creator(collectionId);
    }

    // ===================================================================================================
    //                               Admin Public Functions
    // ===================================================================================================

    // Destroys the contract
    function deprecate() external {
        _requirePaused();
        address payable sender = _msgSender();
        _requireOwnership(sender);
        selfdestruct(sender);
    }

    /**
     * Creates a collection.
     * @dev Reverts if the sender is not the contract owner.
     * @dev Reverts if `collectionId` does not represent a collection.
     * @dev Reverts if `collectionId` has already been created.
     * @dev Emits a {IERC1155Inventory-CollectionCreated} event.
     * @param collectionId Identifier of the collection.
     */
    function createCollection(uint256 collectionId) external {
        _requireOwnership(_msgSender());
        _createCollection(collectionId);
    }

    //================================== Pausable =======================================/

    function pause() external virtual {
        _requireOwnership(_msgSender());
        _pause();
    }

    function unpause() external virtual {
        _requireOwnership(_msgSender());
        _unpause();
    }

    //================================== ERC1155 =======================================/

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override {
        _requireNotPaused();
        super.safeTransferFrom(from, to, id, value, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override {
        _requireNotPaused();
        super.safeBatchTransferFrom(from, to, ids, values, data);
    }

    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) public virtual override {
        _requireNotPaused();
        super.burnFrom(from, id, value);
    }

    function batchBurnFrom(
        address from,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {
        _requireNotPaused();
        super.batchBurnFrom(from, ids, values);
    }

    //================================== ERC1155InventoryMintable =======================================/


    /**
     * Safely mints some token (ERC1155-compatible).
     * @dev See {IERC1155721InventoryMintable-safeMint(address,uint256,uint256,bytes)}.
     */
    function safeMint(
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) public virtual override {
        _requireMinter(_msgSender());
        _safeMint(to, id, value, data);
    }

    /**
     * Safely mints a batch of tokens (ERC1155-compatible).
     * @dev See {IERC1155721InventoryMintable-safeBatchMint(address,uint256[],uint256[],bytes)}.
     */
    function safeBatchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override {
        _requireMinter(_msgSender());
        _safeBatchMint(to, ids, values, data);
    }


    function _msgSender() internal view virtual override(ManagedIdentity, UsingUniversalForwarding) returns (address payable) {
        return UsingUniversalForwarding._msgSender();
    }

    function _msgData() internal view virtual override(ManagedIdentity, UsingUniversalForwarding) returns (bytes memory ret) {
        return UsingUniversalForwarding._msgData();
    }
}