/**
 *Submitted for verification at polygonscan.com on 2021-10-21
*/

/**
 *Submitted for verification at polygonscan.com on 2021-06-09
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 {
    /* is ERC165 */
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absense of an event assumes disabled).
    */
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

/**
    @title ERC-1155 Mixed Fungible Token Standard
 */
interface IERC1155MixedFungible {
    /**
        @notice Returns true for non-fungible token id.
        @dev    Returns true for non-fungible token id.
        @param _id  Id of the token
        @return     If a token is non-fungible
     */
    function isNonFungible(uint256 _id) external pure returns (bool);

    /**
        @notice Returns true for fungible token id.
        @dev    Returns true for fungible token id.
        @param _id  Id of the token
        @return     If a token is fungible
     */
    function isFungible(uint256 _id) external pure returns (bool);

    /**
        @notice Returns the mint# of a token type.
        @dev    Returns the mint# of a token type.
        @param _id  Id of the token
        @return     The mint# of a token type.
     */
    function getNonFungibleIndex(uint256 _id) external pure returns (uint256);

    /**
        @notice Returns the base type of a token id.
        @dev    Returns the base type of a token id.
        @param _id  Id of the token
        @return     The base type of a token id.
     */
    function getNonFungibleBaseType(uint256 _id)
        external
        pure
        returns (uint256);

    /**
        @notice Returns true if the base type of the token id is a non-fungible base type.
        @dev    Returns true if the base type of the token id is a non-fungible base type.
        @param _id  Id of the token
        @return     The non-fungible base type info as bool
     */
    function isNonFungibleBaseType(uint256 _id) external pure returns (bool);

    /**
        @notice Returns true if the base type of the token id is a fungible base type.
        @dev    Returns true if the base type of the token id is a fungible base type.
        @param _id  Id of the token
        @return     The fungible base type info as bool
     */
    function isNonFungibleItem(uint256 _id) external pure returns (bool);

    /**
        @notice Returns the owner of a token.
        @dev    Returns the owner of a token.
        @param _id  Id of the token
        @return     The owner address
     */
    function ownerOf(uint256 _id) external view returns (address);
}

/**
    @author The Calystral Team
    @title The ERC1155CalystralMixedFungibleMintable' Interface
*/
interface IERC1155CalystralMixedFungibleMintable {
    /**
        @dev MUST emit when a release timestamp is set or updated.
        The `typeId` argument MUST be the id of a type.
        The `timestamp` argument MUST be the timestamp of the release in seconds.
    */
    event OnReleaseTimestamp(uint256 indexed typeId, uint256 timestamp);

    /**
        @notice Updates the metadata base URI.
        @dev Updates the `_metadataBaseURI`.
        @param uri The metadata base URI
    */
    function updateMetadataBaseURI(string calldata uri) external;

    /**
        @notice Creates a non-fungible type.
        @dev Creates a non-fungible type. This function only creates the type and is not used for minting.
        The type also has a maxSupply since there can be multiple tokens of the same type, e.g. 100x 'Pikachu'.
        Reverts if the `maxSupply` is 0 or exceeds the `MAX_TYPE_SUPPLY`.
        @param maxSupply        The maximum amount that can be created of this type, unlimited SHOULD be 2**128 (uint128) as the max. MUST NOT be set to 0
        @param releaseTimestamp The timestamp for the release time, SHOULD be set to 1337 for releasing it right away. MUST NOT be set to 0
        @return                 The `typeId`
    */
    function createNonFungibleType(uint256 maxSupply, uint256 releaseTimestamp)
        external
        returns (uint256);

    /**
        @notice Creates a fungible type.
        @dev Creates a fungible type. This function only creates the type and is not used for minting.
        Reverts if the `maxSupply` is 0 or exceeds the `MAX_TYPE_SUPPLY`.
        @param maxSupply        The maximum amount that can be created of this type, unlimited SHOULD be 2**128 (uint128) as the max. MUST NOT be set to 0
        @param releaseTimestamp The timestamp for the release time, SHOULD be set to 1337 for releasing it right away. MUST NOT be set to 0
        @return                 The `typeId`
    */
    function createFungibleType(uint256 maxSupply, uint256 releaseTimestamp)
        external
        returns (uint256);

    /**
        @notice Mints a non-fungible type.
        @dev Mints a non-fungible type.
        Reverts if type id is not existing.
        Reverts if out of stock.
        Emits the `TransferSingle` event.
        @param typeId   The type which should be minted
        @param toArr    An array of receivers
    */
    function mintNonFungible(uint256 typeId, address[] calldata toArr) external;

    /**
        @notice Mints a fungible type.
        @dev Mints a fungible type.
        Reverts if array lengths are unequal.
        Reverts if type id is not existing.
        Reverts if out of stock.
        Emits the `TransferSingle` event.
        @param typeId   The type which should be minted
        @param toArr    An array of receivers
    */
    function mintFungible(
        uint256 typeId,
        address[] calldata toArr,
        uint256[] calldata quantitiesArr
    ) external;

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        Uses Meta Transactions - transactions are signed by the owner or operator of the owner but are executed by anybody.
        Reverts if the signature is invalid.
        Reverts if array lengths are unequal.
        Reverts if the transaction expired.
        Reverts if the transaction was executed already.
        Reverts if the signer is not the asset owner or approved operator of the owner.
        Reverts if `_to` is the zero address.
        Reverts if balance of holder for token `_id` is lower than the `_value` sent.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param signature    The signature of the signing account as proof for execution allowance
        @param signer       The signing account. This SHOULD be the owner of the asset or an approved operator of the owner.
        @param _to          Target address
        @param _id          ID of the token type
        @param _value       Transfer amount
        @param _data        Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
        @param nonce        Each sent meta transaction includes a nonce to prevent that a signed transaction is executed multiple times
        @param maxTimestamp The maximum point in time before the meta transaction expired, thus becoming invalid
    */
    function metaSafeTransferFrom(
        bytes memory signature,
        address signer,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data,
        uint256 nonce,
        uint256 maxTimestamp
    ) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        Uses Meta Transactions - transactions are signed by the owner or operator of the owner but are executed by anybody.
        Reverts if the signature is invalid.
        Reverts if array lengths are unequal.
        Reverts if the transaction expired.
        Reverts if the transaction was executed already.
        Reverts if the signer is not the asset owner or approved operator of the owner.
        Reverts if `_to` is the zero address.
        Reverts if length of `_ids` is not the same as length of `_values`.
        Reverts if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param signature    The signature of the signing account as proof for execution allowance
        @param signer       The signing account. This SHOULD be the owner of the asset or an approved operator of the owner.
        @param _to          Target address
        @param _ids         IDs of each token type (order and length must match _values array)
        @param _values      Transfer amounts per token type (order and length must match _ids array)
        @param _data        Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
        @param nonce        Each sent meta transaction includes a nonce to prevent that a signed transaction is executed multiple times
        @param maxTimestamp The maximum point in time before the meta transaction expired, thus becoming invalid
    */
    function metaSafeBatchTransferFrom(
        bytes memory signature,
        address signer,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data,
        uint256 nonce,
        uint256 maxTimestamp
    ) external;

    /**
        @notice Burns fungible and/or non-fungible tokens.
        @dev Sends FTs and/or NFTs to 0x0 address.
        Uses Meta Transactions - transactions are signed by the owner but are executed by anybody.
        Reverts if the signature is invalid.
        Reverts if array lengths are unequal.
        Reverts if the transaction expired.
        Reverts if the transaction was executed already.
        Reverts if the signer is not the asset owner.
        Emits the `TransferBatch` event where the `to` argument is the 0x0 address.
        @param signature    The signature of the signing account as proof for execution allowance
        @param signer The signing account. This SHOULD be the owner of the asset
        @param ids An array of token Ids which should be burned
        @param values An array of amounts which should be burned. The order matches the order in the ids array
        @param nonce Each sent meta transaction includes a nonce to prevent that a signed transaction is executed multiple times
        @param maxTimestamp The maximum point in time before the meta transaction expired, thus becoming invalid
    */
    function metaBatchBurn(
        bytes memory signature,
        address signer,
        uint256[] calldata ids,
        uint256[] calldata values,
        uint256 nonce,
        uint256 maxTimestamp
    ) external;

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        Uses Meta Transactions - transactions are signed by the owner but are executed by anybody.
        Reverts if the signature is invalid.
        Reverts if array lengths are unequal.
        Reverts if the transaction expired.
        Reverts if the transaction was executed already.
        Reverts if the signer is not the asset owner.
        @param signature    The signature of the signing account as proof for execution allowance
        @param signer       The signing account. This SHOULD be the owner of the asset
        @param _operator    Address to add to the set of authorized operators
        @param _approved    True if the operator is approved, false to revoke approval
        @param nonce        Each sent meta transaction includes a nonce to prevent that a signed transaction is executed multiple times
        @param maxTimestamp The maximum point in time before the meta transaction expired, thus becoming invalid
    */
    function metaSetApprovalForAll(
        bytes memory signature,
        address signer,
        address _operator,
        bool _approved,
        uint256 nonce,
        uint256 maxTimestamp
    ) external;

    /**
        @notice Sets a release timestamp.
        @dev Sets a release timestamp.
        Reverts if `timestamp` == 0.
        Reverts if the `typeId` is released already.
        @param typeId       The type which should be set or updated
        @param timestamp    The timestamp for the release time, SHOULD be set to 1337 for releasing it right away. MUST NOT be set to 0
    */
    function setReleaseTimestamp(uint256 typeId, uint256 timestamp) external;

    /**
        @notice Get the release timestamp of a type.
        @dev Get the release timestamp of a type.
        @return The release timestamp of a type.
    */
    function getReleaseTimestamp(uint256 typeId)
        external
        view
        returns (uint256);

    /**
        @notice Get all existing type Ids.
        @dev Get all existing type Ids.
        @return An array of all existing type Ids.
    */
    function getTypeIds() external view returns (uint256[] memory);

    /**
        @notice Get a specific type Id.
        @dev Get a specific type Id.
        Reverts if `typeNonce` is 0 or if it does not exist.
        @param  typeNonce The type nonce for which the id is requested
        @return A specific type Id.
    */
    function getTypeId(uint256 typeNonce) external view returns (uint256);

    /**
        @notice Get all non-fungible assets for a specific user.
        @dev Get all non-fungible assets for a specific user.
        @param  owner The address of the requested user
        @return An array of Ids that are owned by the user
    */
    function getNonFungibleAssets(address owner)
        external
        view
        returns (uint256[] memory);

    /**
        @notice Get all fungible assets for a specific user.
        @dev Get all fungible assets for a specific user.
        @param  owner The address of the requested user
        @return An array of Ids that are owned by the user
                An array for the amount owned of each Id
    */
    function getFungibleAssets(address owner)
        external
        view
        returns (uint256[] memory, uint256[] memory);

    /**
        @notice Get the type nonce.
        @dev Get the type nonce.
        @return The type nonce.
    */
    function getTypeNonce() external view returns (uint256);

    /**
        @notice The amount of tokens that have been minted of a specific type.
        @dev    The amount of tokens that have been minted of a specific type.
                Reverts if the given typeId does not exist.
        @param  typeId The requested type
        @return The minted amount
    */
    function getMintedSupply(uint256 typeId) external view returns (uint256);

    /**
        @notice The amount of tokens that can be minted of a specific type.
        @dev    The amount of tokens that can be minted of a specific type.
                Reverts if the given typeId does not exist.
        @param  typeId The requested type
        @return The maximum mintable amount
    */
    function getMaxSupply(uint256 typeId) external view returns (uint256);

    /**
        @notice Get the burn nonce of a specific user.
        @dev    Get the burn nonce of a specific user / signer.
        @param  signer The requested signer
        @return The burn nonce of a specific user
    */
    function getMetaNonce(address signer) external view returns (uint256);
}

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

/**
    @author The Calystral Team
    @title The RegistrableContractState's Interface
*/
interface IRegistrableContractState is IERC165 {
    /*==============================
    =           EVENTS             =
    ==============================*/
    /// @dev MUST emit when the contract is set to an active state.
    event Activated();
    /// @dev MUST emit when the contract is set to an inactive state.
    event Inactivated();

    /*==============================
    =          FUNCTIONS           =
    ==============================*/
    /**
        @notice Sets the contract state to active.
        @dev Sets the contract state to active.
    */
    function setActive() external;

    /**
        @notice Sets the contract state to inactive.
        @dev Sets the contract state to inactive.
    */
    function setInactive() external;

    /**
        @dev Sets the registry contract object.
        Reverts if the registryAddress doesn't implement the IRegistry interface.
        @param registryAddress The registry address
    */
    function setRegistry(address registryAddress) external;

    /**
        @notice Returns the current contract state.
        @dev Returns the current contract state.
        @return The current contract state (true == active; false == inactive)
    */
    function getIsActive() external view returns (bool);

    /**
        @notice Returns the Registry address.
        @dev Returns the Registry address.
        @return The Registry address
    */
    function getRegistryAddress() external view returns (address);

    /**
        @notice Returns the current address associated with `key` identifier.
        @dev Look-up in the Registry.
        Returns the current address associated with `key` identifier.
        @return The key identifier
    */
    function getContractAddress(uint256 key) external view returns (address);
}

/**
    @author The Calystral Team
    @title The Assets' Interface
*/
interface IAssets is
    IERC1155,
    IERC1155MixedFungible,
    IERC1155CalystralMixedFungibleMintable,
    IRegistrableContractState
{
    /**
        @dev MUST emit when any property type is created.
        The `propertyId` argument MUST be the id of a property.
        The `name` argument MUST be the name of this specific id.
        The `propertyType` argument MUST be the property type.
    */
    event OnCreateProperty(
        uint256 propertyId,
        string name,
        PropertyType indexed propertyType
    );
    /**
        @dev MUST emit when an int type property is updated.
        The `tokenId` argument MUST be the id of the token of which the property is updated.
        The `propertyId` argument MUST be the property id which is updated.
        The `value` argument MUST be the value to which the token's property is updated.
    */
    event OnUpdateIntProperty(
        uint256 indexed tokenId,
        uint256 indexed propertyId,
        int256 value
    );
    /**
        @dev MUST emit when an string type property is updated.
        The `tokenId` argument MUST be the id of the token of which the property is updated.
        The `propertyId` argument MUST be the property id which is updated.
        The `value` argument MUST be the value to which the token's property is updated.
    */
    event OnUpdateStringProperty(
        uint256 indexed tokenId,
        uint256 indexed propertyId,
        string value
    );
    /**
        @dev MUST emit when an address type property is updated.
        The `tokenId` argument MUST be the id of the token of which the property is updated.
        The `propertyId` argument MUST be the property id which is updated.
        The `value` argument MUST be the value to which the token's property is updated.
    */
    event OnUpdateAddressProperty(
        uint256 indexed tokenId,
        uint256 indexed propertyId,
        address value
    );
    /**
        @dev MUST emit when an byte type property is updated.
        The `tokenId` argument MUST be the id of the token of which the property is updated.
        The `propertyId` argument MUST be the property id which is updated.
        The `value` argument MUST be the value to which the token's property is updated.
    */
    event OnUpdateByteProperty(
        uint256 indexed tokenId,
        uint256 indexed propertyId,
        bytes32 value
    );
    /**
        @dev MUST emit when an int array type property is updated.
        The `tokenId` argument MUST be the id of the token of which the property is updated.
        The `propertyId` argument MUST be the property id which is updated.
        The `value` argument MUST be the value to which the token's property is updated.
    */
    event OnUpdateIntArrayProperty(
        uint256 indexed tokenId,
        uint256 indexed propertyId,
        int256[] value
    );
    /**
        @dev MUST emit when an address array type property is updated.
        The `tokenId` argument MUST be the id of the token of which the property is updated.
        The `propertyId` argument MUST be the property id which is updated.
        The `value` argument MUST be the value to which the token's property is updated.
    */
    event OnUpdateAddressArrayProperty(
        uint256 indexed tokenId,
        uint256 indexed propertyId,
        address[] value
    );

    /// @dev Enum representing all existing property types that can be used.
    enum PropertyType {INT, STRING, ADDRESS, BYTE, INTARRAY, ADDRESSARRAY}

    /**
        @notice Creates a property of type int.
        @dev Creates a property of type int.
        @param name The name for this property
        @return     The property id
    */
    function createIntProperty(string calldata name) external returns (uint256);

    /**
        @notice Creates a property of type string.
        @dev Creates a property of type string.
        @param name The name for this property
        @return     The property id
    */
    function createStringProperty(string calldata name)
        external
        returns (uint256);

    /**
        @notice Creates a property of type address.
        @dev Creates a property of type address.
        @param name The name for this property
        @return     The property id
    */
    function createAddressProperty(string calldata name)
        external
        returns (uint256);

    /**
        @notice Creates a property of type byte.
        @dev Creates a property of type byte.
        @param name The name for this property
        @return     The property id
    */
    function createByteProperty(string calldata name)
        external
        returns (uint256);

    /**
        @notice Creates a property of type int array.
        @dev Creates a property of type int array.
        @param name The name for this property
        @return     The property id
    */
    function createIntArrayProperty(string calldata name)
        external
        returns (uint256);

    /**
        @notice Creates a property of type address array.
        @dev Creates a property of type address array.
        @param name The name for this property
        @return     The property id
    */
    function createAddressArrayProperty(string calldata name)
        external
        returns (uint256);

    /**
        @notice Updates an existing int property for the passed value.
        @dev Updates an existing int property for the passed `value`.
        @param tokenId      The id of the token of which the property is updated
        @param propertyId   The property id which is updated
        @param value        The value to which the token's property is updated
    */
    function updateIntProperty(
        uint256 tokenId,
        uint256 propertyId,
        int256 value
    ) external;

    /**
        @notice Updates an existing string property for the passed value.
        @dev Updates an existing string property for the passed `value`.
        @param tokenId      The id of the token of which the property is updated
        @param propertyId   The property id which is updated
        @param value        The value to which the token's property is updated
    */
    function updateStringProperty(
        uint256 tokenId,
        uint256 propertyId,
        string calldata value
    ) external;

    /**
        @notice Updates an existing address property for the passed value.
        @dev Updates an existing address property for the passed `value`.
        @param tokenId      The id of the token of which the property is updated
        @param propertyId   The property id which is updated
        @param value        The value to which the token's property is updated
    */
    function updateAddressProperty(
        uint256 tokenId,
        uint256 propertyId,
        address value
    ) external;

    /**
        @notice Updates an existing byte property for the passed value.
        @dev Updates an existing byte property for the passed `value`.
        @param tokenId      The id of the token of which the property is updated
        @param propertyId   The property id which is updated
        @param value        The value to which the token's property is updated
    */
    function updateByteProperty(
        uint256 tokenId,
        uint256 propertyId,
        bytes32 value
    ) external;

    /**
        @notice Updates an existing int array property for the passed value.
        @dev Updates an existing int array property for the passed `value`.
        @param tokenId      The id of the token of which the property is updated
        @param propertyId   The property id which is updated
        @param value        The value to which the token's property is updated
    */
    function updateIntArrayProperty(
        uint256 tokenId,
        uint256 propertyId,
        int256[] calldata value
    ) external;

    /**
        @notice Updates an existing address array property for the passed value.
        @dev Updates an existing address array property for the passed `value`.
        @param tokenId      The id of the token of which the property is updated
        @param propertyId   The property id which is updated
        @param value        The value to which the token's property is updated
    */
    function updateAddressArrayProperty(
        uint256 tokenId,
        uint256 propertyId,
        address[] calldata value
    ) external;

    /**
        @notice Get the property type of a property.
        @dev Get the property type of a property.
        @return The property type
    */
    function getPropertyType(uint256 propertyId)
        external
        view
        returns (PropertyType);

    /**
        @notice Get the count of available properties.
        @dev Get the count of available properties.
        @return The property count
    */
    function getPropertyCounter() external view returns (uint256);
}

/**
    Note: The ERC-165 identifier for this interface is 0x0e89341c.
*/
interface IERC1155Metadata_URI {
    /**
        @notice A distinct Uniform Resource Identifier (URI) for a given token.
        @dev URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".        
        @return URI string
    */
    function uri(uint256 _id) external view returns (string memory);
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

/**
    @author The Calystral Team
    @title The Registry's Interface
*/
interface IRegistry is IRegistrableContractState {
    /*==============================
    =           EVENTS             =
    ==============================*/
    /**
        @dev MUST emit when an entry in the Registry is set or updated.
        The `key` argument MUST be the key of the entry which is set or updated.
        The `value` argument MUST be the address of the entry which is set or updated.
    */
    event EntrySet(uint256 indexed key, address value);
    /**
        @dev MUST emit when an entry in the Registry is removed.
        The `key` argument MUST be the key of the entry which is removed.
        The `value` argument MUST be the address of the entry which is removed.
    */
    event EntryRemoved(uint256 indexed key, address value);

    /*==============================
    =          FUNCTIONS           =
    ==============================*/
    /**
        @notice Sets the MultiSigAdmin contract as Registry entry 1.
        @dev Sets the MultiSigAdmin contract as Registry entry 1.
        @param msaAddress The contract address of the MultiSigAdmin
    */
    function initializeMultiSigAdmin(address msaAddress) external;

    /**
        @notice Checks if the registry Map contains the key.
        @dev Returns true if the key is in the registry map. O(1).
        @param key  The key to search for
        @return     The boolean result
    */
    function contains(uint256 key) external view returns (bool);

    /**
        @notice Returns the registry map length.
        @dev Returns the number of key-value pairs in the registry map. O(1).
        @return     The registry map length
    */
    function length() external view returns (uint256);

    /**
        @notice Returns the key-value pair stored at position `index` in the registry map.
        @dev Returns the key-value pair stored at position `index` in the registry map. O(1).
        Note that there are no guarantees on the ordering of entries inside the
        array, and it may change when more entries are added or removed.
        Requirements:
        - `index` must be strictly less than {length}.
        @param index    The position in the registry map
        @return         The key-value pair as a tuple
    */
    function at(uint256 index) external view returns (uint256, address);

    /**
        @notice Tries to return the value associated with `key`.
        @dev Tries to return the value associated with `key`.  O(1).
        Does not revert if `key` is not in the registry map.
        @param key    The key to search for
        @return       The key-value pair as a tuple
    */
    function tryGet(uint256 key) external view returns (bool, address);

    /**
        @notice Returns the value associated with `key`.
        @dev Returns the value associated with `key`.  O(1).
        Requirements:
        - `key` must be in the registry map.
        @param key    The key to search for
        @return       The contract address
    */
    function get(uint256 key) external view returns (address);

    /**
        @notice Returns all indices, keys, addresses.
        @dev Returns all indices, keys, addresses as three seperate arrays.
        @return Indices, keys, addresses
    */
    function getAll()
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            address[] memory
        );

    /**
        @notice Adds a key-value pair to a map, or updates the value for an existing
        key.
        @dev Adds a key-value pair to the registry map, or updates the value for an existing
        key. O(1).
        Returns true if the key was added to the registry map, that is if it was not
        already present.
        @param key    The key as an identifier
        @param value  The address of the contract
        @return       Success as a bool
    */
    function set(uint256 key, address value) external returns (bool);

    /**
        @notice Removes a value from the registry map.
        @dev Removes a value from the registry map. O(1).
        Returns true if the key was removed from the registry map, that is if it was present.
        @param key    The key as an identifier
        @return       Success as a bool
    */
    function remove(uint256 key) external returns (bool);

    /**
        @notice Sets a contract state to active.
        @dev Sets a contract state to active.
        @param key    The key as an identifier
    */
    function setContractActiveByKey(uint256 key) external;

    /**
        @notice Sets a contract state to active.
        @dev Sets a contract state to active.
        @param contractAddress The contract's address
    */
    function setContractActiveByAddress(address contractAddress) external;

    /**
        @notice Sets all contracts within the registry to state active.
        @dev Sets all contracts within the registry to state active.
        Does NOT revert if any contract doesn't implement the RegistrableContractState interface.
        Does NOT revert if it is an externally owned user account.
    */
    function setAllContractsActive() external;

    /**
        @notice Sets a contract state to inactive.
        @dev Sets a contract state to inactive.
        @param key    The key as an identifier
    */
    function setContractInactiveByKey(uint256 key) external;

    /**
        @notice Sets a contract state to inactive.
        @dev Sets a contract state to inactive.
        @param contractAddress The contract's address
    */
    function setContractInactiveByAddress(address contractAddress) external;

    /**
        @notice Sets all contracts within the registry to state inactive.
        @dev Sets all contracts within the registry to state inactive.
        Does NOT revert if any contract doesn't implement the RegistrableContractState interface.
        Does NOT revert if it is an externally owned user account.
    */
    function setAllContractsInactive() external;
}

/**
    @author The Calystral Team
    @title A helper parent contract: Pausable & Registry
*/
contract RegistrableContractState is IRegistrableContractState, ERC165 {
    /*==============================
    =          CONSTANTS           =
    ==============================*/

    /*==============================
    =            STORAGE           =
    ==============================*/
    /// @dev Current contract state
    bool private _isActive;
    /// @dev Current registry pointer
    address private _registryAddress;

    /*==============================
    =          MODIFIERS           =
    ==============================*/
    modifier isActive() {
        _isActiveCheck();
        _;
    }

    modifier isAuthorizedAdmin() {
        _isAuthorizedAdmin();
        _;
    }

    modifier isAuthorizedAdminOrRegistry() {
        _isAuthorizedAdminOrRegistry();
        _;
    }

    /*==============================
    =          CONSTRUCTOR         =
    ==============================*/
    /**
        @notice Creates and initializes the contract.
        @dev Creates and initializes the contract.
        Registers all implemented interfaces.
        Inheriting contracts are INACTIVE by default.
    */
    constructor(address registryAddress) {
        _registryAddress = registryAddress;

        _registerInterface(type(IRegistrableContractState).interfaceId);
    }

    /*==============================
    =      PUBLIC & EXTERNAL       =
    ==============================*/

    /*==============================
    =          RESTRICTED          =
    ==============================*/
    function setActive() external override isAuthorizedAdminOrRegistry() {
        _isActive = true;

        emit Activated();
    }

    function setInactive() external override isAuthorizedAdminOrRegistry() {
        _isActive = false;

        emit Inactivated();
    }

    function setRegistry(address registryAddress)
        external
        override
        isAuthorizedAdmin()
    {
        _registryAddress = registryAddress;

        try
            _registryContract().supportsInterface(type(IRegistry).interfaceId)
        returns (bool supportsInterface) {
            require(
                supportsInterface,
                "The provided contract does not implement the Registry interface"
            );
        } catch {
            revert(
                "The provided contract does not implement the Registry interface"
            );
        }
    }

    /*==============================
    =          VIEW & PURE         =
    ==============================*/
    function getIsActive() public view override returns (bool) {
        return _isActive;
    }

    function getRegistryAddress() public view override returns (address) {
        return _registryAddress;
    }

    function getContractAddress(uint256 key)
        public
        view
        override
        returns (address)
    {
        return _registryContract().get(key);
    }

    /*==============================
    =      INTERNAL & PRIVATE      =
    ==============================*/
    /**
        @dev Returns the target Registry object.
        @return The target Registry object
    */
    function _registryContract() internal view returns (IRegistry) {
        return IRegistry(_registryAddress);
    }

    /**
        @dev Checks if the contract is in an active state.
        Reverts if the contract is INACTIVE.
    */
    function _isActiveCheck() internal view {
        require(_isActive == true, "The contract is not active");
    }

    /**
        @dev Checks if the msg.sender is the Admin.
        Reverts if msg.sender is not the Admin.
    */
    function _isAuthorizedAdmin() internal view {
        require(msg.sender == getContractAddress(1), "Unauthorized call");
    }

    /**
        @dev Checks if the msg.sender is the Admin or the Registry.
        Reverts if msg.sender is not the Admin or the Registry.
    */
    function _isAuthorizedAdminOrRegistry() internal view {
        require(
            msg.sender == _registryAddress ||
                msg.sender == getContractAddress(1),
            "Unauthorized call"
        );
    }
}

/**
    Note: Simple contract to use as base for const vals
*/
contract CommonConstants {
    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/*
Begin solidity-cborutils
https://github.com/smartcontractkit/solidity-cborutils

MIT License

Copyright (c) 2018 SmartContract ChainLink, Ltd.
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

library Strings {
    function strConcat(string memory _a, string memory _b)
        internal
        pure
        returns (string memory _concatenatedString)
    {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c
    ) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d
    ) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde =
            new string(
                _ba.length + _bb.length + _bc.length + _bd.length + _be.length
            );
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        uint256 i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

/**
    @author The Calystral Team
    @title Synergy of Serra Assets (NFTs, FTs, and their arbitrary Properties)
*/
contract SynergyOfSerraAssets is
    IAssets,
    IERC1155Metadata_URI,
    RegistrableContractState,
    CommonConstants
{
    using Address for address;
    using Strings for string;

    /*==============================
    =          CONSTANTS           =
    ==============================*/
    /// @dev The maximum allowed supply for FTs and NFTs, half of uint256 is reserved for type and half for the index.
    uint256 public constant MAX_TYPE_SUPPLY = 2**128;

    /// @dev Use a split bit implementation. Store the type in the upper 128 bits..
    uint256 public constant TYPE_MASK = uint256(uint128(int128(~0))) << 128;

    /// @dev ..and the non-fungible index in the lower 128
    uint256 public constant NF_INDEX_MASK = uint128(int128(~0));

    /// @dev The top bit is a flag to tell if this is a NFI.
    uint256 public constant TYPE_NF_BIT = 1 << 255;

    /*==============================
    =            STORAGE           =
    ==============================*/
    /// @dev A counter used to create the propertyId where propertyId 0 is not existing / reserved.
    uint256 public propertyCounter;

    /// @dev A counter which is used to iterate over all existing type Ids. There is no type for _typeNonce 0.
    uint256 private _typeNonce;

    /// @dev Points to the base url of an api to receive meta data.
    string private _metadataBaseURI;

    /// @dev property id => property type
    mapping(uint256 => PropertyType) private _propertyIdToPropertyType;

    /// @dev type id => minted supply
    mapping(uint256 => uint256) private _typeToMintedSupply;

    /// @dev type id => max supply
    mapping(uint256 => uint256) private _typeToMaxSupply;

    /// @dev type id => release timestamp
    mapping(uint256 => uint256) private _tokenTypeToReleaseTimestamp;

    /// @dev type nonce => type id
    mapping(uint256 => uint256) private _typeNonceToTypeId;

    /// @dev signer => burn nonce
    mapping(address => uint256) private _signerToMetaNonce;

    /// @dev id => (owner => balance)
    mapping(uint256 => mapping(address => uint256)) internal balances;

    /// @dev id => owner
    mapping(uint256 => address) nfOwners;

    /// @dev owner => (operator => approved)
    mapping(address => mapping(address => bool)) internal operatorApproval;

    /*==============================
    =          MODIFIERS           =
    ==============================*/
    modifier isValidToken(uint256 tokenId) {
        _isValidToken(tokenId);
        _;
    }

    modifier isValidProperty(uint256 propertyId) {
        _isValidProperty(propertyId);
        _;
    }

    modifier isPropertyType(uint256 propertyId, PropertyType propertyType) {
        _isPropertyType(propertyId, propertyType);
        _;
    }

    modifier isAuthorizedAssetManager() {
        _isAuthorizedAssetManager();
        _;
    }

    modifier isValidTypeId(uint256 typeId) {
        _isValidTypeId(typeId);
        _;
    }

    /*==============================
    =          CONSTRUCTOR         =
    ==============================*/
    /**
        @notice Creates and initializes the contract.
        @dev Creates and initializes the contract.
        Registers all implemented interfaces.
        Contract is INACTIVE by default.
        @param registryAddress Address of the Registry
    */
    constructor(address registryAddress)
        RegistrableContractState(registryAddress)
    {
        _registerInterface(type(IAssets).interfaceId);
        _registerInterface(type(IERC1155).interfaceId);
        _registerInterface(type(IERC1155Metadata_URI).interfaceId);
        _registerInterface(type(IERC1155MixedFungible).interfaceId);
        _registerInterface(
            type(IERC1155CalystralMixedFungibleMintable).interfaceId
        );
    }

    /*==============================
    =      PUBLIC & EXTERNAL       =
    ==============================*/
    function metaSafeTransferFrom(
        bytes memory signature,
        address signer,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data,
        uint256 nonce,
        uint256 maxTimestamp
    ) external override isActive() {
        // Meta Transaction
        bytes32 dataHash =
            _getSafeTransferFromDataHash(
                signer,
                _to,
                _id,
                _value,
                _data,
                nonce,
                maxTimestamp
            );
        address signaturePublicKey =
            ECDSA.recover(ECDSA.toEthSignedMessageHash(dataHash), signature);
        require(
            signer == signaturePublicKey ||
                operatorApproval[signer][signaturePublicKey] == true,
            "Need operator approval for 3rd party transfers."
        );
        require(
            block.timestamp < maxTimestamp,
            "This transaction is not valid anymore."
        );
        require(
            _signerToMetaNonce[signer] == nonce,
            "This transaction was executed already."
        );
        _signerToMetaNonce[signer]++;
        // Function Logic
        require(_to != address(0x0), "cannot send to zero address");
        if (isNonFungible(_id)) {
            require(nfOwners[_id] == signer);
            nfOwners[_id] = _to;
            // You could keep balance of NF type in base type id like so:
            // uint256 baseType = getNonFungibleBaseType(_id);
            // balances[baseType][signer] = balances[baseType][signer] - _value ;
            // balances[baseType][_to]   = balances[baseType][_to] + _value ;
        } else {
            balances[_id][signer] -= _value;
            balances[_id][_to] += _value;
        }
        emit TransferSingle(msg.sender, signer, _to, _id, _value);
        _doSafeTransferAcceptanceCheck(
            msg.sender,
            signer,
            _to,
            _id,
            _value,
            _data
        );
    }

    function metaSafeBatchTransferFrom(
        bytes memory signature,
        address signer,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data,
        uint256 nonce,
        uint256 maxTimestamp
    ) external override isActive() {
        // Meta Transaction
        address signaturePublicKey =
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    _getSafeBatchTransferFromDataHash(
                        signer,
                        _to,
                        _ids,
                        _values,
                        _data,
                        nonce,
                        maxTimestamp
                    )
                ),
                signature
            );
        require(
            signer == signaturePublicKey ||
                operatorApproval[signer][signaturePublicKey] == true,
            "Need operator approval for 3rd party transfers."
        );
        require(_ids.length == _values.length, "Array length must match.");
        require(
            block.timestamp < maxTimestamp,
            "This transaction is not valid anymore."
        );
        require(
            _signerToMetaNonce[signer] == nonce,
            "This transaction was executed already."
        );
        _signerToMetaNonce[signer]++;
        // Function Logic
        require(_to != address(0x0), "cannot send to zero address");
        require(_ids.length == _values.length, "Array length must match");
        for (uint256 i = 0; i < _ids.length; ++i) {
            if (isNonFungible(_ids[i])) {
                require(nfOwners[_ids[i]] == signer);
                nfOwners[_ids[i]] = _to;
            } else {
                balances[_ids[i]][signer] -= _values[i];
                balances[_ids[i]][_to] += _values[i];
            }
        }
        emit TransferBatch(msg.sender, signer, _to, _ids, _values);
        _doSafeBatchTransferAcceptanceCheck(
            msg.sender,
            signer,
            _to,
            _ids,
            _values,
            _data
        );
    }

    function metaSetApprovalForAll(
        bytes memory signature,
        address signer,
        address _operator,
        bool _approved,
        uint256 nonce,
        uint256 maxTimestamp
    ) external override isActive() {
        // Meta Transaction
        bytes32 dataHash =
            _getSetApprovalForAllHash(
                _operator,
                _approved,
                nonce,
                maxTimestamp
            );
        address signaturePublicKey =
            ECDSA.recover(ECDSA.toEthSignedMessageHash(dataHash), signature);
        require(signaturePublicKey == signer, "Invalid signature.");
        require(
            block.timestamp < maxTimestamp,
            "This transaction is not valid anymore."
        );
        require(
            _signerToMetaNonce[signer] == nonce,
            "This transaction was executed already."
        );
        _signerToMetaNonce[signer]++;
        // Function Logic
        operatorApproval[signaturePublicKey][_operator] = _approved;
        emit ApprovalForAll(signaturePublicKey, _operator, _approved);
    }

    function setApprovalForAll(address _operator, bool _approved)
        external
        override
        isActive()
    {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external override isActive() {
        require(_to != address(0x0), "cannot send to zero address");
        require(
            _from == msg.sender || operatorApproval[_from][msg.sender] == true,
            "Need operator approval for 3rd party transfers."
        );

        if (isNonFungible(_id)) {
            require(nfOwners[_id] == _from);
            nfOwners[_id] = _to;
            // You could keep balance of NF type in base type id like so:
            // uint256 baseType = getNonFungibleBaseType(_id);
            // balances[baseType][_from] = balances[baseType][_from] - _value;
            // balances[baseType][_to]   = balances[baseType][_to] + _value;
        } else {
            balances[_id][_from] = balances[_id][_from] - _value;
            balances[_id][_to] = balances[_id][_to] + _value;
        }

        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        _doSafeTransferAcceptanceCheck(
            msg.sender,
            _from,
            _to,
            _id,
            _value,
            _data
        );
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external override isActive() {
        require(_to != address(0x0), "cannot send to zero address");
        require(_ids.length == _values.length, "Array length must match");

        // Only supporting a global operator approval allows us to do only 1 check and not to touch storage to handle allowances.
        require(
            _from == msg.sender || operatorApproval[_from][msg.sender] == true,
            "Need operator approval for 3rd party transfers."
        );

        for (uint256 i = 0; i < _ids.length; ++i) {
            // Cache value to local variable to reduce read costs.
            uint256 id = _ids[i];
            uint256 value = _values[i];

            if (isNonFungible(id)) {
                require(nfOwners[id] == _from);
                nfOwners[id] = _to;
            } else {
                balances[id][_from] = balances[id][_from] - value;
                balances[id][_to] = value + balances[id][_to];
            }
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        _doSafeBatchTransferAcceptanceCheck(
            msg.sender,
            _from,
            _to,
            _ids,
            _values,
            _data
        );
    }

    /*==============================
    =          RESTRICTED          =
    ==============================*/
    function metaBatchBurn(
        bytes memory signature,
        address signer,
        uint256[] calldata ids,
        uint256[] calldata values,
        uint256 nonce,
        uint256 maxTimestamp
    ) external override isAuthorizedAssetManager() {
        // Meta Transaction
        bytes32 dataHash = _getBurnDataHash(ids, values, nonce, maxTimestamp);
        require(
            (
                ECDSA.recover(ECDSA.toEthSignedMessageHash(dataHash), signature)
            ) == signer,
            "Invalid signature."
        );
        require(ids.length == values.length, "Array length must match.");
        require(
            block.timestamp < maxTimestamp,
            "This transaction is not valid anymore."
        );
        require(
            _signerToMetaNonce[signer] == nonce,
            "This transaction was executed already."
        );
        _signerToMetaNonce[signer]++;
        // Function Logic
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            if (isNonFungible(id)) {
                require(nfOwners[id] == signer, "You are not the owner.");
                nfOwners[id] = address(0x0);
            } else {
                uint256 value = values[i];
                balances[id][signer] -= value;
            }
        }
        emit TransferBatch(msg.sender, signer, address(0x0), ids, values);
    }

    function createIntProperty(string calldata name)
        external
        override
        isAuthorizedAssetManager()
        returns (uint256)
    {
        return _createProperty(name, PropertyType.INT);
    }

    function createStringProperty(string calldata name)
        external
        override
        isAuthorizedAssetManager()
        returns (uint256)
    {
        return _createProperty(name, PropertyType.STRING);
    }

    function createAddressProperty(string calldata name)
        external
        override
        isAuthorizedAssetManager()
        returns (uint256)
    {
        return _createProperty(name, PropertyType.ADDRESS);
    }

    function createByteProperty(string calldata name)
        external
        override
        isAuthorizedAssetManager()
        returns (uint256)
    {
        return _createProperty(name, PropertyType.BYTE);
    }

    function createIntArrayProperty(string calldata name)
        external
        override
        isAuthorizedAssetManager()
        returns (uint256)
    {
        return _createProperty(name, PropertyType.INTARRAY);
    }

    function createAddressArrayProperty(string calldata name)
        external
        override
        isAuthorizedAssetManager()
        returns (uint256)
    {
        return _createProperty(name, PropertyType.ADDRESSARRAY);
    }

    function updateIntProperty(
        uint256 tokenId,
        uint256 propertyId,
        int256 value
    )
        external
        override
        isAuthorizedAssetManager()
        isValidToken(tokenId)
        isValidProperty(propertyId)
        isPropertyType(propertyId, PropertyType.INT)
    {
        emit OnUpdateIntProperty(tokenId, propertyId, value);
    }

    function updateStringProperty(
        uint256 tokenId,
        uint256 propertyId,
        string calldata value
    )
        external
        override
        isAuthorizedAssetManager()
        isValidToken(tokenId)
        isValidProperty(propertyId)
        isPropertyType(propertyId, PropertyType.STRING)
    {
        emit OnUpdateStringProperty(tokenId, propertyId, value);
    }

    function updateAddressProperty(
        uint256 tokenId,
        uint256 propertyId,
        address value
    )
        external
        override
        isAuthorizedAssetManager()
        isValidToken(tokenId)
        isValidProperty(propertyId)
        isPropertyType(propertyId, PropertyType.ADDRESS)
    {
        emit OnUpdateAddressProperty(tokenId, propertyId, value);
    }

    function updateByteProperty(
        uint256 tokenId,
        uint256 propertyId,
        bytes32 value
    )
        external
        override
        isAuthorizedAssetManager()
        isValidToken(tokenId)
        isValidProperty(propertyId)
        isPropertyType(propertyId, PropertyType.BYTE)
    {
        emit OnUpdateByteProperty(tokenId, propertyId, value);
    }

    function updateIntArrayProperty(
        uint256 tokenId,
        uint256 propertyId,
        int256[] calldata value
    )
        external
        override
        isAuthorizedAssetManager()
        isValidToken(tokenId)
        isValidProperty(propertyId)
        isPropertyType(propertyId, PropertyType.INTARRAY)
    {
        emit OnUpdateIntArrayProperty(tokenId, propertyId, value);
    }

    function updateAddressArrayProperty(
        uint256 tokenId,
        uint256 propertyId,
        address[] calldata value
    )
        external
        override
        isAuthorizedAssetManager()
        isValidToken(tokenId)
        isValidProperty(propertyId)
        isPropertyType(propertyId, PropertyType.ADDRESSARRAY)
    {
        emit OnUpdateAddressArrayProperty(tokenId, propertyId, value);
    }

    function updateMetadataBaseURI(string calldata baseUri)
        external
        override
        isAuthorizedAssetManager()
    {
        _metadataBaseURI = baseUri;
    }

    function createNonFungibleType(uint256 maxSupply, uint256 releaseTimestamp)
        external
        override
        isAuthorizedAssetManager()
        returns (uint256)
    {
        uint256 result = _create(true, maxSupply);
        _setReleaseTimestamp(result, releaseTimestamp);
        return result;
    }

    function createFungibleType(uint256 maxSupply, uint256 releaseTimestamp)
        external
        override
        isAuthorizedAssetManager()
        returns (uint256)
    {
        uint256 result = _create(false, maxSupply);
        _setReleaseTimestamp(result, releaseTimestamp);
        return result;
    }

    function mintNonFungible(uint256 typeId, address[] calldata toArr)
        external
        override
        isAuthorizedAssetManager()
        isValidTypeId(typeId)
    {
        require(
            isNonFungible(typeId),
            "This typeId is not a non fungible type."
        );

        // Index are 1-based.
        uint256 index = _typeToMintedSupply[typeId] + 1;
        _typeToMintedSupply[typeId] += toArr.length;

        for (uint256 i = 0; i < toArr.length; ++i) {
            address to = toArr[i];
            uint256 id = typeId | (index + i);

            nfOwners[id] = to;

            emit TransferSingle(msg.sender, address(0x0), to, id, 1);

            _doSafeTransferAcceptanceCheck(
                msg.sender,
                msg.sender,
                to,
                id,
                1,
                ""
            );
        }
        require(
            _typeToMintedSupply[typeId] <= _typeToMaxSupply[typeId],
            "Out of stock."
        );
    }

    function mintFungible(
        uint256 typeId,
        address[] calldata toArr,
        uint256[] calldata quantitiesArr
    ) external override isAuthorizedAssetManager() isValidTypeId(typeId) {
        require(isFungible(typeId), "This typeId is not a fungible type.");
        require(
            toArr.length == quantitiesArr.length,
            "Array length must match."
        );

        for (uint256 i = 0; i < toArr.length; ++i) {
            address to = toArr[i];
            uint256 quantity = quantitiesArr[i];

            // Grant the items to the caller
            balances[typeId][to] += quantity;
            _typeToMintedSupply[typeId] += quantity;

            // the 0x0 source address implies a mint
            // It will also provide the circulating supply info.
            emit TransferSingle(msg.sender, address(0x0), to, typeId, quantity);

            _doSafeTransferAcceptanceCheck(
                msg.sender,
                msg.sender,
                to,
                typeId,
                quantity,
                ""
            );
        }
        require(
            _typeToMintedSupply[typeId] <= _typeToMaxSupply[typeId],
            "Out of stock."
        );
    }

    function setReleaseTimestamp(uint256 typeId, uint256 timestamp)
        external
        override
        isAuthorizedAssetManager()
        isValidTypeId(typeId)
    {
        _setReleaseTimestamp(typeId, timestamp);
    }

    /*==============================
    =          VIEW & PURE         =
    ==============================*/
    function getPropertyType(uint256 propertyId)
        public
        view
        override
        isValidProperty(propertyId)
        returns (PropertyType)
    {
        return _propertyIdToPropertyType[propertyId];
    }

    function getPropertyCounter() public view override returns (uint256) {
        return propertyCounter;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return Strings.strConcat(_metadataBaseURI, Strings.uint2str(_id));
    }

    function getReleaseTimestamp(uint256 typeId)
        public
        view
        override
        isValidTypeId(typeId)
        returns (uint256)
    {
        return _tokenTypeToReleaseTimestamp[typeId];
    }

    function getTypeIds() public view override returns (uint256[] memory) {
        uint256[] memory resultIds = new uint256[](_typeNonce);
        for (uint256 i = 0; i < _typeNonce; i++) {
            resultIds[i] = getTypeId(i + 1);
        }
        return resultIds;
    }

    function getTypeId(uint256 typeNonce)
        public
        view
        override
        returns (uint256)
    {
        require(
            typeNonce <= _typeNonce && typeNonce != 0,
            "TypeNonce does not exist."
        );
        return _typeNonceToTypeId[typeNonce];
    }

    function getNonFungibleAssets(address owner)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256 counter;
        for (uint256 i = 1; i <= _typeNonce; i++) {
            uint256 typeId = (i << 128) | TYPE_NF_BIT;
            if (_typeToMaxSupply[typeId] != 0) {
                for (uint256 j = 1; j <= _typeToMintedSupply[typeId]; j++) {
                    uint256 id = typeId | j;
                    if (nfOwners[id] == owner) {
                        counter++;
                    }
                }
            }
        }

        uint256[] memory result = new uint256[](counter);
        counter = 0;
        for (uint256 i = 1; i <= _typeNonce; i++) {
            uint256 typeId = (i << 128) | TYPE_NF_BIT;
            if (_typeToMaxSupply[typeId] != 0) {
                for (uint256 j = 1; j <= _typeToMintedSupply[typeId]; j++) {
                    uint256 id = typeId | j;
                    if (nfOwners[id] == owner) {
                        result[counter] = id;
                        counter++;
                    }
                }
            }
        }
        return result;
    }

    function getFungibleAssets(address owner)
        public
        view
        override
        returns (uint256[] memory, uint256[] memory)
    {
        uint256 counter;
        for (uint256 i = 1; i <= _typeNonce; i++) {
            uint256 typeId = i << 128;
            if (_typeToMaxSupply[typeId] != 0) {
                if (balances[typeId][owner] > 0) {
                    counter++;
                }
            }
        }

        uint256[] memory resultIds = new uint256[](counter);
        uint256[] memory resultAmounts = new uint256[](counter);
        counter = 0;
        for (uint256 i = 1; i <= _typeNonce; i++) {
            uint256 typeId = i << 128;
            if (_typeToMaxSupply[typeId] != 0) {
                if (balances[typeId][owner] > 0) {
                    resultIds[counter] = typeId;
                    resultAmounts[counter] = balances[typeId][owner];
                    counter++;
                }
            }
        }
        return (resultIds, resultAmounts);
    }

    function getTypeNonce() public view override returns (uint256) {
        return _typeNonce;
    }

    function getMintedSupply(uint256 typeId)
        public
        view
        override
        isValidTypeId(typeId)
        returns (uint256)
    {
        return _typeToMintedSupply[typeId];
    }

    function getMaxSupply(uint256 typeId)
        public
        view
        override
        isValidTypeId(typeId)
        returns (uint256)
    {
        return _typeToMaxSupply[typeId];
    }

    function getMetaNonce(address signer)
        public
        view
        override
        returns (uint256)
    {
        return _signerToMetaNonce[signer];
    }

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        override
        returns (bool)
    {
        return operatorApproval[_owner][_operator];
    }

    function isNonFungible(uint256 _id) public pure override returns (bool) {
        return _id & TYPE_NF_BIT == TYPE_NF_BIT;
    }

    function isFungible(uint256 _id) public pure override returns (bool) {
        return _id & TYPE_NF_BIT == 0;
    }

    function getNonFungibleIndex(uint256 _id)
        public
        pure
        override
        returns (uint256)
    {
        return _id & NF_INDEX_MASK;
    }

    function getNonFungibleBaseType(uint256 _id)
        public
        pure
        override
        returns (uint256)
    {
        return _id & TYPE_MASK;
    }

    function isNonFungibleBaseType(uint256 _id)
        public
        pure
        override
        returns (bool)
    {
        // A base type has the NF bit but does not have an index.
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK == 0);
    }

    function isNonFungibleItem(uint256 _id)
        public
        pure
        override
        returns (bool)
    {
        // A base type has the NF bit but does has an index.
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK != 0);
    }

    function ownerOf(uint256 _id) public view override returns (address) {
        return nfOwners[_id];
    }

    function balanceOf(address _owner, uint256 _id)
        external
        view
        override
        returns (uint256)
    {
        if (isNonFungibleItem(_id)) return nfOwners[_id] == _owner ? 1 : 0;
        return balances[_id][_owner];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        override
        returns (uint256[] memory)
    {
        require(_owners.length == _ids.length);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            uint256 id = _ids[i];
            if (isNonFungibleItem(id)) {
                balances_[i] = nfOwners[id] == _owners[i] ? 1 : 0;
            } else {
                balances_[i] = balances[id][_owners[i]];
            }
        }

        return balances_;
    }

    /*==============================
    =      INTERNAL & PRIVATE      =
    ==============================*/
    /**
        @dev Checks if the `tokenId` exists:
        NFs are checked via `nfOwners` mapping.
        NFTs are checked via `getMaxSupply` function.
        @param tokenId  The tokenId which should be checked
    */
    function _isValidToken(uint256 tokenId) internal view {
        if (isNonFungible(tokenId)) {
            require(
                nfOwners[tokenId] != address(0x0),
                "TokenId does not exist."
            );
        } else {
            require(getMaxSupply(tokenId) != 0, "TokenId does not exist.");
        }
    }

    /**
        @dev Checks if the `propertyId` exists.
        @param propertyId  The propertyId which should be checked
    */
    function _isValidProperty(uint256 propertyId) internal view {
        require(
            propertyId <= propertyCounter && propertyId != 0,
            "Invalid property requested."
        );
    }

    /**
        @dev Checks if a given `propertyId` matches the given `propertyType`.
        @param propertyId   The propertyId which should be checked
        @param propertyType The PropertyType which should be checked against
    */
    function _isPropertyType(uint256 propertyId, PropertyType propertyType)
        internal
        view
    {
        require(
            _propertyIdToPropertyType[propertyId] == propertyType,
            "The given property id does not match the property type."
        );
    }

    /**
        @dev Creates a new property.
        @param name         The name of the property
        @param propertyType The PropertyType of the property
        @return             The propertyId of the property
    */
    function _createProperty(string memory name, PropertyType propertyType)
        private
        returns (uint256)
    {
        propertyCounter++; // propertyCounter starts with 1 for the first attribute
        _propertyIdToPropertyType[propertyCounter] = propertyType;

        emit OnCreateProperty(propertyCounter, name, propertyType);

        return propertyCounter;
    }

    /**
        @dev Checks if the AssetManager (from the Registry) is the msg.sender.
        Reverts if the msg.sender is not the correct AssetManager registered in the Registry.
    */
    function _isAuthorizedAssetManager() internal view {
        require(
            getContractAddress(3) == msg.sender,
            "Unauthorized call. Thanks for supporting the network with your ETH."
        );
    }

    /**
        @dev Checks if a given `typeId` exists.
        Reverts if given `typeId` does not exist.
        @param typeId The typeId which should be checked
    */
    function _isValidTypeId(uint256 typeId) internal view {
        require(_typeToMaxSupply[typeId] != 0, "TypeId does not exist.");
    }

    /**
        @dev Creates fungible and non-fungible types. This function only creates the type and is not used for minting.
        NFT types also has a maxSupply since there can be multiple tokens of the same type, e.g. 100x 'Pikachu'.
        Reverts if the `maxSupply` is 0 or exceeds the `MAX_TYPE_SUPPLY`.
        @param isNF         Flag if the creation should be a non-fungible, false for fungible tokens
        @param maxSupply    The maximum amount that can be created of this type, unlimited SHOULD be 2**128 (uint128) as the max. MUST NOT be set to 0
        @return             The `typeId`
    */
    function _create(bool isNF, uint256 maxSupply) private returns (uint256) {
        require(
            maxSupply != 0 && maxSupply <= MAX_TYPE_SUPPLY,
            "Minimum 1 and maximum 2**128 tokens of one type can exist."
        );

        // Store the type in the upper 128 bits
        uint256 typeId = (++_typeNonce << 128);

        // Set a flag if this is an NFI.
        if (isNF) typeId = typeId | TYPE_NF_BIT;

        _typeToMaxSupply[typeId] = maxSupply;
        _typeNonceToTypeId[_typeNonce] = typeId;

        // emit a Transfer event with Create semantic to help with discovery.
        emit TransferSingle(msg.sender, address(0x0), address(0x0), typeId, 0);

        return typeId;
    }

    /**
        @dev Sets a release timestamp.
        Reverts if `timestamp` == 0.
        Reverts if the `typeId` is released already.
        @param typeId       The type which should be set or updated
        @param timestamp    The timestamp for the release time, SHOULD be set to 1337 for releasing it right away. MUST NOT be set to 0
    */
    function _setReleaseTimestamp(uint256 typeId, uint256 timestamp) private {
        require(
            timestamp != 0,
            "A 0 timestamp is not allowed. For immediate release choose 1337."
        );
        require(
            _tokenTypeToReleaseTimestamp[typeId] == 0 ||
                _tokenTypeToReleaseTimestamp[typeId] > block.timestamp,
            "This token is released already."
        );
        _tokenTypeToReleaseTimestamp[typeId] = timestamp;

        emit OnReleaseTimestamp(typeId, timestamp);
    }

    /**
        @dev Get the data hash required for the meta transaction comparison of burn executions.
        @param ids          An array of token Ids which should be burned
        @param values       An array of amounts which should be burned
        @param nonce        Each sent meta transaction includes a nonce to prevent that a signed transaction is executed multiple times
        @param maxTimestamp The maximum point in time before the meta transaction expired, thus becoming invalid
        @return             The keccak256 hash of the data input
    */
    function _getBurnDataHash(
        uint256[] memory ids,
        uint256[] memory values,
        uint256 nonce,
        uint256 maxTimestamp
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(ids, values, nonce, maxTimestamp));
    }

    /**
        @dev Get the data hash required for the meta transaction comparison of transfer executions.
        @param signer       The signer of the transaction
        @param _to          The receiver address
        @param _id          An token id which should be transfered
        @param _value       An amount which should be transfered
        @param _data        Additional data field
        @param nonce        Each sent meta transaction includes a nonce to prevent that a signed transaction is executed multiple times
        @param maxTimestamp The maximum point in time before the meta transaction expired, thus becoming invalid
        @return             The keccak256 hash of the data input
    */
    function _getSafeTransferFromDataHash(
        address signer,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes memory _data,
        uint256 nonce,
        uint256 maxTimestamp
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    signer,
                    _to,
                    _id,
                    _value,
                    _data,
                    nonce,
                    maxTimestamp
                )
            );
    }

    /**
        @dev Get the data hash required for the meta transaction comparison of transfer executions.
        @param signer       The signer of the transaction
        @param _to          The receiver address
        @param _ids         An array of token Ids which should be transfered
        @param _values      An array of amounts which should be transfered
        @param _data        Additional data field
        @param nonce        Each sent meta transaction includes a nonce to prevent that a signed transaction is executed multiple times
        @param maxTimestamp The maximum point in time before the meta transaction expired, thus becoming invalid
        @return             The keccak256 hash of the data input
    */
    function _getSafeBatchTransferFromDataHash(
        address signer,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes memory _data,
        uint256 nonce,
        uint256 maxTimestamp
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    signer,
                    _to,
                    _ids,
                    _values,
                    _data,
                    nonce,
                    maxTimestamp
                )
            );
    }

    /**
        @dev Get the data hash required for the meta transaction comparison of transfer executions.
        @param _operator    Address to add to the set of authorized operators
        @param _approved    True if the operator is approved, false to revoke approval
        @param nonce        Each sent meta transaction includes a nonce to prevent that a signed transaction is executed multiple times
        @param maxTimestamp The maximum point in time before the meta transaction expired, thus becoming invalid
        @return             The keccak256 hash of the data input
    */
    function _getSetApprovalForAllHash(
        address _operator,
        bool _approved,
        uint256 nonce,
        uint256 maxTimestamp
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_operator, _approved, nonce, maxTimestamp)
            );
    }

    /**
        @dev Checks if the contract allows receiving ERC1155 in case the "to" address is a contract.
        The receiving contract needs to implement IERC1155TokenReceiver.
        @param operator The operator address
        @param from     The address of the holder whose balance is decreased
        @param to       Target address
        @param id       ID of the token type
        @param amount   Transfer amount
        @param data     Additional data field
    */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try
                IERC1155TokenReceiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155TokenReceiver(to).onERC1155Received.selector
                ) {
                    revert("ERC1155: ERC1155TokenReceiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert(
                    "ERC1155: transfer to non ERC1155TokenReceiver implementer"
                );
            }
        }
    }

    /**
        @dev Checks if the contract allows receiving ERC1155 in case the "to" address is a contract.
        The receiving contract needs to implement IERC1155TokenReceiver.
        @param operator The operator address
        @param from     The address of the holder whose balance is decreased
        @param to       Target address
        @param ids      Array of ids of the token types
        @param amounts  Array of amounts of to transfer
        @param data     Additional data field
    */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try
                IERC1155TokenReceiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155TokenReceiver(to).onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
}