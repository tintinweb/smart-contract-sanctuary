/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;
pragma abicoder v2;

/**
 * @dev ERC1155TokenReceiver interface of the ERC1155 standard as defined in the EIP.
 * @dev The ERC-165 identifier for this interface is 0x4e2312e0
 */
interface ERC1155TokenReceiver {
    /**
     * @notice Handle the receipt of a single ERC1155 token type.
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
     * This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
     * This function MUST revert if it rejects the transfer.
     * Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
     * @param _operator  The address which initiated the transfer (i.e. msg.sender)
     * @param _from      The address which previously owned the token
     * @param _id        The ID of the token being transferred
     * @param _value     The amount of tokens being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /**
     * @notice Handle the receipt of multiple ERC1155 token types.
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
     * This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
     * This function MUST revert if it rejects the transfer(s).
     * Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
     * @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
     * @param _from      The address which previously owned the token
     * @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
     * @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
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
 * @dev Interface of the ERC165 standard as defined in the EIP.
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceID The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     * @return `true` if the contract implements `interfaceID` and
     * `interfaceID` is not 0xffffffff, `false` otherwise
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/**
 * @dev Interface for proxiable logic contracts.
 * @dev The ERC-165 identifier for this interface is 0xc1fdc5a0
 */
interface IFeedsContractProxiable {
    /**
     * @dev Emit when the logic contract is updated
     */
    event CodeUpdated(address indexed _codeAddress);

    /**
     * @dev upgrade the logic contract to one on the new code address
     * @param _newAddress New code address of the upgraded logic contract
     */
    function updateCodeAddress(address _newAddress) external;

    /**
     * @dev get the code address of the current logic contract
     * @return Logic contract address
     */
    function getCodeAddress() external view returns (address);
}

/**
 * @dev Token interface of the ERC1155 standard as defined in the EIP.
 * @dev The ERC-165 identifier for this interface is 0xd9b67a26
 */
interface IERC1155 {
    /**
     * @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
     * The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
     * The `_from` argument MUST be the address of the holder whose balance is decreased.
     * The `_to` argument MUST be the address of the recipient whose balance is increased.
     * The `_id` argument MUST be the token type being transferred.
     * The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
     * When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
     * When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
     */
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    /**
     * @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
     * The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
     * The `_from` argument MUST be the address of the holder whose balance is decreased.
     * The `_to` argument MUST be the address of the recipient whose balance is increased.
     * The `_ids` argument MUST be the list of tokens being transferred.
     * The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
     * When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
     * When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
     */
    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    /**
     * @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).
     */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * @dev MUST emit when the URI is updated for a token ID.
     * URIs are defined in RFC 3986.
     * The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
     */
    event URI(string _value, uint256 indexed _id);

    /**
     * @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
     * MUST revert if `_to` is the zero address.
     * MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
     * MUST revert on any other error.
     * MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
     * After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _value   Transfer amount
     * @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    /**
     * @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
     * MUST revert if `_to` is the zero address.
     * MUST revert if length of `_ids` is not the same as length of `_values`.
     * MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
     * MUST revert on any other error.
     * MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
     * Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
     * After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * @param _from    Source address
     * @param _to      Target address
     * @param _ids     IDs of each token type (order and length must match _values array)
     * @param _values  Transfer amounts per token type (order and length must match _ids array)
     * @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /**
     * @notice Get the balance of an account's tokens.
     * @param _owner  The address of the token holder
     * @param _id     ID of the token
     * @return        The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
     * @notice Get the balance of multiple account/token pairs
     * @param _owners The addresses of the token holders
     * @param _ids    ID of the tokens
     * @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
     * @dev MUST emit the ApprovalForAll event on success.
     * @param _operator  Address to add to the set of authorized operators
     * @param _approved  True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
     * @notice Queries the approval status of an operator for a given owner.
     * @param _owner     The owner of the tokens
     * @param _operator  Address of authorized operator
     * @return           True if the operator is approved, false if not
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/**
 * @dev Custom extension interface for simplified transfer methods
 */
interface ISimpleTransfer {
    /**
     * @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
     * @dev This works identically to the other function with an extra data parameter, except this function just sets data to "".
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _value   Transfer amount
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value
    ) external;

    /**
     * @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
     * @dev This works identically to the other function with an extra data parameter, except this function just sets data to "".
     * @param _from    Source address
     * @param _to      Target address
     * @param _ids     IDs of each token type (order and length must match _values array)
     * @param _values  Transfer amounts per token type (order and length must match _ids array)
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values
    ) external;
}

/**
 * @dev Custom extension interface for metadata information
 */
interface ITokenMetaData {
    /**
     * @notice Get the name of this multi-token contract
     * @return Name string
     */
    function name() external view returns (string memory);

    /**
     * @notice Get the symbol of this multi-token contract
     * @return Symbol string
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Get distinct Uniform Resource Identifier (URI) for a given token.
     * @dev URIs are defined in RFC 3986.
     * The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
     * @param _id ID of the token
     * @return URI string
     */
    function uri(uint256 _id) external view returns (string memory);

    /**
     * @notice Get distinct Uniform Resource Identifier (URI) for multiple tokens.
     * @dev URIs are defined in RFC 3986.
     * The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
     * @param _ids ID of the tokens
     * @return URI strings
     */
    function uriBatch(uint256[] calldata _ids) external view returns (string[] memory);
}

/**
 * @dev Custom extension interface for token enumeration methods
 */
interface ITokenEnumerable {
    /**
     * @notice Count token types tracked by this contract
     * @return A count of valid token types tracked by this contract, where each one of
     *  them has an assigned and queryable token id
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Query number of tokens in a given token type
     * @param _id the ID of the token
     * @return Number of tokens
     */
    function tokenSupply(uint256 _id) external view returns (uint256);

    /**
     * @notice Query number of tokens in multiple token types
     * @param _ids the ID of the tokens
     * @return Number of tokens array
     */
    function tokenSupplyBatch(uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
     * @notice Enumerate valid token ids
     * @param _index A counter less than `totalSupply()`
     * @return The token identifier for the `_index`th token type
     */
    function tokenIdByIndex(uint256 _index) external view returns (uint256);

    /**
     * @notice Enumerate valid token ids for multiple indexes
     * @param _indexes An array of counters less than `totalSupply()`
     * @return The token identifiers for the `_index`th token types
     */
    function tokenIdByIndexBatch(uint256[] calldata _indexes) external view returns (uint256[] memory);

    /**
     * @notice Query number of token types held by a given owner
     * @param _owner An address where we are interested in token types owned by them
     * @return Number of token types
     */
    function tokenCountOfOwner(address _owner) external view returns (uint256);

    /**
     * @notice Query number of token types held by multiple owners
     * @param _owners Addresses where we are interested in token types owned by them
     * @return Number of token types array
     */
    function tokenCountOfOwnerBatch(address[] calldata _owners) external view returns (uint256[] memory);

    /**
     * @notice Enumerate token ids held by a given owner
     * @param _owner An address where we are interested in token types owned by them
     * @param _index A counter less than `tokenCountOfOwner(_owner)`
     * @return The token identifier for the `_index`th token type held by the owner
     */
    function tokenIdOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);

    /**
     * @notice Enumerate multiple token ids held by a given owner
     * @param _owner An address where we are interested in token types owned by them
     * @param _indexes An array of counters less than `tokenCountOfOwner(_owner)`
     * @return The token identifiers for the `_index`th token types held by the owner
     */
    function tokenIdOfOwnerByIndexBatch(address _owner, uint256[] calldata _indexes)
        external
        view
        returns (uint256[] memory);
}

/**
 * @dev Custom extension interface for token royalty methods
 */
interface ITokenRoyalty {
    /**
     * @dev MUST emit when the royalty owner is updated for a token ID.
     * @param _owner The royalty owner address
     * @param _id The token identifier
     */
    event RoyaltyOwner(address indexed _owner, uint256 indexed _id);

    /**
     * @dev MUST emit when the royalty fee is updated for a token ID.
     * @param _fee The royalty fee rate in terms of parts per million
     * @param _id The token identifier
     */
    event RoyaltyFee(uint256 _fee, uint256 indexed _id);

    /**
     * @notice Get the royalty owner address of a given token type
     * @param _id The token identifier of a given token type
     * @return The royalty owner address
     */
    function tokenRoyaltyOwner(uint256 _id) external view returns (address);

    /**
     * @notice Get the royalty owner address of multiple token types
     * @param _ids The token identifiers of the token types
     * @return The royalty owner addresses
     */
    function tokenRoyaltyOwnerBatch(uint256[] calldata _ids) external view returns (address[] memory);

    /**
     * @notice Get the royalty fee rate of a given token type
     * @param _id The token identifier of a given token type
     * @return The royalty fee rate in terms of parts per million
     */
    function tokenRoyaltyFee(uint256 _id) external view returns (uint256);

    /**
     * @notice Get the royalty fee rate of multiple token types
     * @param _ids The token identifiers of the token types
     * @return The royalty fee rates in terms of parts per million
     */
    function tokenRoyaltyFeeBatch(uint256[] calldata _ids) external view returns (uint256[] memory);
}

/**
 * @dev Custom extension interface that allows sticker art creators to create their own token types
 */
interface ITokenMintable {
    /**
     * @notice Create a new token type that is associated with a sticker art image
     * @dev The token minter is assigned as the royalty owner when minting a completely new token type
     * @param _id The token identifier which is the hash value of the sticker art image
     * @param _tokenSupply Number of tokens which represents number of copies of the sticker art image
     * @param _uri URI to the metadata description file for the sticker art image
     * @param _royaltyFee The royalty fee rate in terms of parts per million when trading the token
     * @param _didUri DID URI of the token minter
     */
    function mint(
        uint256 _id,
        uint256 _tokenSupply,
        string calldata _uri,
        uint256 _royaltyFee,
        string calldata _didUri
    ) external;
}

/**
 * @dev Custom extension interface that allows token holders and operators to destroy tokens owned or managed by them
 */
interface ITokenBurnable {
    /**
     * @notice Destroy tokens held by the caller
     * @param _id The identifier of the token type where tokens are to be destroyed
     * @param _value The amount of tokens to be destroyed
     */
    function burn(uint256 _id, uint256 _value) external;

    /**
     * @notice Destroy tokens held by `_owner`
     * @dev The caller must be an operator for `owner`'s tokens
     * @param _owner The token holder address
     * @param _id The identifier of the token type where tokens are to be destroyed
     * @param _value The amount of tokens to be destroyed
     */
    function burnFrom(
        address _owner,
        uint256 _id,
        uint256 _value
    ) external;
}

/**
 * @dev Custom extension interface for aggregated token information
 */
interface ITokenInfo {
    /**
     * @dev Data structure that stores aggregated token information
     */
    struct TokenInfo {
        uint256 tokenId; // The token identifier ie. hash value of the associated sticker art image
        uint256 tokenIndex; // The enumerable index of the token type
        uint256 tokenSupply; // The number of tokens in the token type
        string tokenUri; // The URI for the metadata description file
        address royaltyOwner; // The royalty owner of the token
        uint256 royaltyFee; // The royalty fee rate in terms of parts per million
        uint256 createTime; // The timestamp of when the token is first minted
        uint256 updateTime; // The timestamp of last modification of the token's state
    }

    /**
     * @notice Get aggregated token information for a given token
     * @param _id The token identifier
     * @return The aggregated token information
     */
    function tokenInfo(uint256 _id) external view returns (TokenInfo memory);

    /**
     * @notice Get aggregated token information for multiple tokens
     * @param _ids The token identifiers
     * @return The aggregated token information array
     */
    function tokenInfoBatch(uint256[] calldata _ids) external view returns (TokenInfo[] memory);
}

interface IVersion {
    function getVersion() external view returns (string memory);

    function getMagic() external view returns (string memory);
}

/**
 * @dev Methods for compatibility purposes
 */
interface ITokenCompatibility {
    /**
     * @dev Always returns zero for sticker art tokens
     * @return uint8(0)
     */
    function decimals() external view returns (uint8);
}

/**
 * @dev Custom interface for extra token information added in token upgrades
 */
interface ITokenUpgraded {
    /**
     * @dev MUST emit when the DID URI is updated for a token ID.
     */
    event DIDURI(string _value, uint256 indexed _id, address indexed _minter);

    /**
     * @dev Data structure that stores upgraded token extra information
     */
    struct TokenExtraInfo {
        string didUri; // The DID URI of the token minter
    }

    /**
     * @notice Get upgraded token extra information for a given token
     * @param _id The token identifier
     * @return The upgraded token extra information
     */
    function tokenExtraInfo(uint256 _id) external view returns (TokenExtraInfo memory);

    /**
     * @notice Get upgraded token extra information for multiple tokens
     * @param _ids The token identifiers
     * @return The upgraded token extra information array
     */
    function tokenExtraInfoBatch(uint256[] calldata _ids) external view returns (TokenExtraInfo[] memory);

    /**
     * @dev Either `TransferSingleWithMemo` or `TransferBatchWithMemo` MUST emit when tokens are transferred with memo, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
     * The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
     * The `_from` argument MUST be the address of the holder whose balance is decreased.
     * The `_to` argument MUST be the address of the recipient whose balance is increased.
     * The `_id` argument MUST be the token type being transferred.
     * The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
     * The `_memo` argument MUST be the memo message string attached to the transfer
     * When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
     * When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
     */
    event TransferSingleWithMemo(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value,
        string _memo
    );

    /**
     * @dev Either `TransferSingleWithMemo` or `TransferBatchWithMemo` MUST emit when tokens are transferred with memo, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
     * The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
     * The `_from` argument MUST be the address of the holder whose balance is decreased.
     * The `_to` argument MUST be the address of the recipient whose balance is increased.
     * The `_ids` argument MUST be the list of tokens being transferred.
     * The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
     * The `_memo` argument MUST be the memo message string attached to the transfer
     * When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
     * When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
     */
    event TransferBatchWithMemo(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values,
        string _memo
    );

    /**
     * @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call). With memo parameter.
     * @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
     * MUST revert if `_to` is the zero address.
     * MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
     * MUST revert on any other error.
     * MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
     * MUST emit the `TransferSingleWithMemo` event.
     * After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _value   Transfer amount
     * @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
     * @param _memo    Memo message string attached to the transfer
     */
    function safeTransferFromWithMemo(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data,
        string calldata _memo
    ) external;

    /**
     * @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call). With memo paramter.
     * @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
     * MUST revert if `_to` is the zero address.
     * MUST revert if length of `_ids` is not the same as length of `_values`.
     * MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
     * MUST revert on any other error.
     * MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
     * MUST emit the `TransferBatchWithMemo` event
     * Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
     * After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * @param _from    Source address
     * @param _to      Target address
     * @param _ids     IDs of each token type (order and length must match _values array)
     * @param _values  Transfer amounts per token type (order and length must match _ids array)
     * @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
     * @param _memo    Memo message string attached to the transfer
     */
    function safeBatchTransferFromWithMemo(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data,
        string calldata _memo
    ) external;

    /**
     * @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call). With memo parameter.
     * @dev This works identically to the other function with an extra data parameter, except this function just sets data to "".
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _value   Transfer amount
     * @param _memo    Memo message string attached to the transfer
     */
    function safeTransferFromWithMemo(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        string calldata _memo
    ) external;

    /**
     * @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call). With memo parameter.
     * @dev This works identically to the other function with an extra data parameter, except this function just sets data to "".
     * @param _from    Source address
     * @param _to      Target address
     * @param _ids     IDs of each token type (order and length must match _values array)
     * @param _values  Transfer amounts per token type (order and length must match _ids array)
     * @param _memo    Memo message string attached to the transfer
     */
    function safeBatchTransferFromWithMemo(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        string calldata _memo
    ) external;
}

/**
 * @dev Wrappers over Solidity's arithmetic operations to prevent overflow and underflow.
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }

        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
}

/**
 * @dev Methods related to the address type
 */
library AddressUtils {
    /**
     * @notice Check if an address is a contract
     * @dev This method actually checks if the address holds any code at the time of the function-call
     * @param _addr The address to be checked
     * @return `true` if the address holds code, `false` if otherwise
     */
    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}

/**
 * @dev Base contract for some basic common functionalities
 */
abstract contract BaseUtils is IFeedsContractProxiable {
    /**
     * @dev Constants for the interface identifiers, as specified in ERC-165
     */
    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61;
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81;
    bytes4 internal constant INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
    bytes4 internal constant INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;
    bytes4 internal constant INTERFACE_SIGNATURE_TokenRoyalty = 0x96f7b536;
    bytes4 internal constant INTERFACE_SIGNATURE_FeedsContractProxiable = 0xc1fdc5a0;

    uint256 internal constant RATE_BASE = 1000000;

    uint256 private guard;
    uint256 private constant GUARD_PASS = 1;
    uint256 private constant GUARD_BLOCK = 2;

    /**
     * @dev Proxied contracts cannot use contructor but must be intialized manually
     */
    address public owner = address(0x1);
    bool public initialized = false;

    function _initialize() internal {
        require(!initialized, "Contract already initialized");
        require(owner == address(0x0), "Logic contract cannot be initialized");
        initialized = true;
        guard = GUARD_PASS;
        owner = msg.sender;
    }

    function initialize() external {
        _initialize();
    }

    modifier inited() {
        require(initialized, "Contract not initialized");
        _;
    }

    /**
     * @dev Mutex to guard against re-entrancy exploits
     */
    modifier reentrancyGuard() {
        require(guard != GUARD_BLOCK, "Reentrancy blocked");
        guard = GUARD_BLOCK;
        _;
        guard = GUARD_PASS;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender must be owner");
        _;
    }

    function transferOwnership(address _owner) external inited onlyOwner {
        owner = _owner;
    }

    /**
     * @notice Upgrade the logic contract to one on the new code address
     * @dev Code position in storage is
     * keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
     * @param _newAddress New code address of the upgraded logic contract
     */
    function updateCodeAddress(address _newAddress) external override inited onlyOwner {
        /**
         * @dev ERC-165 identifier for the `FeedsContractProxiable` interface support, which is
         * bytes4(keccak256("updateCodeAddress(address)")) ^ bytes4(keccak256("getCodeAddress()")) = "0xc1fdc5a0"
         */
        require(IERC165(_newAddress).supportsInterface(0xc1fdc5a0), "Contract address not proxiable");

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, _newAddress)
        }

        emit CodeUpdated(_newAddress);
    }

    /**
     * @notice get the code address of the current logic contract
     * @dev Code position in storage is
     * keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
     * @return _codeAddress Logic contract address
     */
    function getCodeAddress() external view override returns (address _codeAddress) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            _codeAddress := sload(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7)
        }
    }
}

/**
 * @notice The implementation of the multi-token contract for Feeds sticker art tokens
 */
contract FeedsNFTSticker is
    IERC165,
    IERC1155,
    ISimpleTransfer,
    ITokenMetaData,
    ITokenEnumerable,
    ITokenRoyalty,
    ITokenMintable,
    ITokenBurnable,
    ITokenCompatibility,
    ITokenInfo,
    IVersion,
    ITokenUpgraded,
    BaseUtils
{
    using SafeMath for uint256;
    using AddressUtils for address;

    string internal constant name_ = "Feeds NFT Sticker";
    string internal constant symbol_ = "FSTK";
    string internal constant version = "v0.2";
    string internal constant magic = "20210930";

    mapping(uint256 => mapping(address => uint256)) internal balances;
    mapping(address => mapping(address => bool)) internal operatorApproval;

    mapping(uint256 => TokenInfo) internal tokenIdToToken;
    uint256[] internal tokenIds;

    mapping(address => uint256[]) internal ownerToTokenIds;
    mapping(uint256 => mapping(address => uint256)) internal tokenIdToIndexByOwner;

    mapping(uint256 => TokenExtraInfo) internal tokenIdToExtraInfo;

    /**
     * @notice Query if a contract implements an interface
     * @param _interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     * @return `true` if the contract implements `interfaceID` and
     * `interfaceID` is not 0xffffffff, `false` otherwise
     */
    function supportsInterface(bytes4 _interfaceId) external pure override returns (bool) {
        return
            _interfaceId == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceId == INTERFACE_SIGNATURE_ERC1155 ||
            _interfaceId == INTERFACE_SIGNATURE_TokenRoyalty ||
            _interfaceId == INTERFACE_SIGNATURE_FeedsContractProxiable;
    }

    /**
     * @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
     * MUST revert if `_to` is the zero address.
     * MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
     * MUST revert on any other error.
     * MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
     * After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _value   Transfer amount
     * @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external override inited reentrancyGuard {
        _safeTransferFrom(_from, _to, _id, _value, _data, "");
    }

    /**
     * @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
     * MUST revert if `_to` is the zero address.
     * MUST revert if length of `_ids` is not the same as length of `_values`.
     * MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
     * MUST revert on any other error.
     * MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
     * Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
     * After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * @param _from    Source address
     * @param _to      Target address
     * @param _ids     IDs of each token type (order and length must match _values array)
     * @param _values  Transfer amounts per token type (order and length must match _ids array)
     * @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external override inited reentrancyGuard {
        _safeBatchTransferFrom(_from, _to, _ids, _values, _data, "");
    }

    /**
     * @notice Get the balance of an account's tokens.
     * @param _owner  The address of the token holder
     * @param _id     ID of the token
     * @return        The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view override returns (uint256) {
        return balances[_id][_owner];
    }

    /**
     * @notice Get the balance of multiple account/token pairs
     * @param _owners The addresses of the token holders
     * @param _ids    ID of the tokens
     * @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        override
        returns (uint256[] memory)
    {
        require(_owners.length == _ids.length, "_owners and _ids length mismatch");

        uint256[] memory _balances = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            _balances[i] = balances[_ids[i]][_owners[i]];
        }

        return _balances;
    }

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
     * @dev MUST emit the ApprovalForAll event on success.
     * @param _operator  Address to add to the set of authorized operators
     * @param _approved  True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external override {
        operatorApproval[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @notice Queries the approval status of an operator for a given owner.
     * @param _owner     The owner of the tokens
     * @param _operator  Address of authorized operator
     * @return           True if the operator is approved, false if not
     */
    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
        return operatorApproval[_owner][_operator];
    }

    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes memory _data,
        string memory _memo
    ) internal {
        require(_to != address(0x0), "Receiver cannot be zero address");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Sender is not operator");
        require(balances[_id][_from] >= _value, "Not enough token balance");

        if (balances[_id][_to] <= 0 && _value > 0) {
            _addTokenToOwner(_id, _to);
        }

        balances[_id][_from] = balances[_id][_from].sub(_value);
        balances[_id][_to] = _value.add(balances[_id][_to]);
        tokenIdToToken[_id].updateTime = block.timestamp;

        if (balances[_id][_from] <= 0 && _value > 0) {
            _removeTokenFromOwner(_id, _from);
        }

        emit TransferSingle(msg.sender, _from, _to, _id, _value);
        emit TransferSingleWithMemo(msg.sender, _from, _to, _id, _value, _memo);

        if (_to.isContract()) {
            require(
                ERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _value, _data) ==
                    ERC1155_ACCEPTED,
                "Receiving contract not accepting ERC1155 tokens"
            );
        }
    }

    function _safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes memory _data,
        string memory _memo
    ) internal {
        require(_to != address(0x0), "Receiver cannot be zero address");
        require(_ids.length == _values.length, "_ids and _values length mismatch");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Sender is not operator");

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];
            require(balances[id][_from] >= value, "Not enough token balance");

            if (balances[id][_to] <= 0 && value > 0) {
                _addTokenToOwner(id, _to);
            }

            balances[id][_from] = balances[id][_from].sub(value);
            balances[id][_to] = value.add(balances[id][_to]);
            tokenIdToToken[id].updateTime = block.timestamp;

            if (balances[id][_from] <= 0 && value > 0) {
                _removeTokenFromOwner(id, _from);
            }
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);
        emit TransferBatchWithMemo(msg.sender, _from, _to, _ids, _values, _memo);

        if (_to.isContract()) {
            require(
                ERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _values, _data) ==
                    ERC1155_BATCH_ACCEPTED,
                "Receiving contract not accepting ERC1155 tokens"
            );
        }
    }

    function _addTokenToOwner(uint256 _id, address _owner) internal {
        require(tokenIdToIndexByOwner[_id][_owner] == 0, "Something is wrong with _addTokenToOwner");
        if (ownerToTokenIds[_owner].length > 0) {
            require(ownerToTokenIds[_owner][0] != _id, "Something is wrong with _addTokenToOwner");
        }
        ownerToTokenIds[_owner].push(_id);
        tokenIdToIndexByOwner[_id][_owner] = ownerToTokenIds[_owner].length.sub(1);
    }

    function _removeTokenFromOwner(uint256 _id, address _owner) internal {
        require(
            ownerToTokenIds[_owner][tokenIdToIndexByOwner[_id][_owner]] == _id,
            "Something is wrong with _removeTokenFromOwner"
        );
        uint256 lastId = ownerToTokenIds[_owner][ownerToTokenIds[_owner].length.sub(1)];
        if (lastId == _id) {
            tokenIdToIndexByOwner[_id][_owner] = 0;
            ownerToTokenIds[_owner].pop();
        } else {
            uint256 index = tokenIdToIndexByOwner[_id][_owner];
            tokenIdToIndexByOwner[_id][_owner] = 0;
            ownerToTokenIds[_owner][index] = lastId;
            ownerToTokenIds[_owner].pop();
            tokenIdToIndexByOwner[lastId][_owner] = index;
        }
    }

    /**
     * @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
     * @dev This works identically to the other function with an extra data parameter, except this function just sets data to "".
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _value   Transfer amount
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value
    ) external override inited reentrancyGuard {
        _safeTransferFrom(_from, _to, _id, _value, "", "");
    }

    /**
     * @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
     * @dev This works identically to the other function with an extra data parameter, except this function just sets data to "".
     * @param _from    Source address
     * @param _to      Target address
     * @param _ids     IDs of each token type (order and length must match _values array)
     * @param _values  Transfer amounts per token type (order and length must match _ids array)
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values
    ) external override inited reentrancyGuard {
        _safeBatchTransferFrom(_from, _to, _ids, _values, "", "");
    }

    /**
     * @notice Get the name of this multi-token contract
     * @return Name string
     */
    function name() external pure override returns (string memory) {
        return name_;
    }

    /**
     * @notice Get the symbol of this multi-token contract
     * @return Symbol string
     */
    function symbol() external pure override returns (string memory) {
        return symbol_;
    }

    /**
     * @notice Get distinct Uniform Resource Identifier (URI) for a given token.
     * @dev URIs are defined in RFC 3986.
     * The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
     * @param _id ID of the token
     * @return URI string
     */
    function uri(uint256 _id) external view override returns (string memory) {
        return tokenIdToToken[_id].tokenUri;
    }

    /**
     * @notice Get distinct Uniform Resource Identifier (URI) for multiple tokens.
     * @dev URIs are defined in RFC 3986.
     * The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
     * @param _ids ID of the tokens
     * @return URI strings
     */
    function uriBatch(uint256[] calldata _ids) external view override returns (string[] memory) {
        string[] memory _uris = new string[](_ids.length);

        for (uint256 i = 0; i < _ids.length; ++i) {
            _uris[i] = tokenIdToToken[_ids[i]].tokenUri;
        }

        return _uris;
    }

    /**
     * @notice Count token types tracked by this contract
     * @return A count of valid token types tracked by this contract, where each one of
     *  them has an assigned and queryable token id
     */
    function totalSupply() external view override returns (uint256) {
        return tokenIds.length;
    }

    /**
     * @notice Query number of tokens in a given token type
     * @param _id the ID of the token
     * @return Number of tokens
     */
    function tokenSupply(uint256 _id) external view override returns (uint256) {
        return tokenIdToToken[_id].tokenSupply;
    }

    /**
     * @notice Query number of tokens in multiple token types
     * @param _ids the ID of the tokens
     * @return Number of tokens array
     */
    function tokenSupplyBatch(uint256[] calldata _ids) external view override returns (uint256[] memory) {
        uint256[] memory _amounts = new uint256[](_ids.length);

        for (uint256 i = 0; i < _ids.length; ++i) {
            _amounts[i] = tokenIdToToken[_ids[i]].tokenSupply;
        }

        return _amounts;
    }

    /**
     * @notice Enumerate valid token ids
     * @param _index A counter less than `totalSupply()`
     * @return The token identifier for the `_index`th token type
     */
    function tokenIdByIndex(uint256 _index) external view override returns (uint256) {
        return tokenIds[_index];
    }

    /**
     * @notice Enumerate valid token ids for multiple indexes
     * @param _indexes An array of counters less than `totalSupply()`
     * @return The token identifiers for the `_index`th token types
     */
    function tokenIdByIndexBatch(uint256[] calldata _indexes) external view override returns (uint256[] memory) {
        uint256[] memory _ids = new uint256[](_indexes.length);

        for (uint256 i = 0; i < _indexes.length; ++i) {
            _ids[i] = tokenIds[_indexes[i]];
        }

        return _ids;
    }

    /**
     * @notice Query number of token types held by a given owner
     * @param _owner An address where we are interested in token types owned by them
     * @return Number of token types
     */
    function tokenCountOfOwner(address _owner) external view override returns (uint256) {
        return ownerToTokenIds[_owner].length;
    }

    /**
     * @notice Query number of token types held by multiple owners
     * @param _owners Addresses where we are interested in token types owned by them
     * @return Number of token types array
     */
    function tokenCountOfOwnerBatch(address[] calldata _owners) external view override returns (uint256[] memory) {
        uint256[] memory _counts = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            _counts[i] = ownerToTokenIds[_owners[i]].length;
        }

        return _counts;
    }

    /**
     * @notice Enumerate token ids held by a given owner
     * @param _owner An address where we are interested in token types owned by them
     * @param _index A counter less than `tokenCountOfOwner(_owner)`
     * @return The token identifier for the `_index`th token type held by the owner
     */
    function tokenIdOfOwnerByIndex(address _owner, uint256 _index) external view override returns (uint256) {
        return ownerToTokenIds[_owner][_index];
    }

    /**
     * @notice Enumerate multiple token ids held by a given owner
     * @param _owner An address where we are interested in token types owned by them
     * @param _indexes An array of counters less than `tokenCountOfOwner(_owner)`
     * @return The token identifiers for the `_index`th token types held by the owner
     */
    function tokenIdOfOwnerByIndexBatch(address _owner, uint256[] calldata _indexes)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory _ids = new uint256[](_indexes.length);

        for (uint256 i = 0; i < _indexes.length; ++i) {
            _ids[i] = ownerToTokenIds[_owner][_indexes[i]];
        }

        return _ids;
    }

    /**
     * @notice Get the royalty owner address of a given token type
     * @param _id The token identifier of a given token type
     * @return The royalty owner address
     */
    function tokenRoyaltyOwner(uint256 _id) external view override returns (address) {
        return tokenIdToToken[_id].royaltyOwner;
    }

    /**
     * @notice Get the royalty owner address of multiple token types
     * @param _ids The token identifiers of the token types
     * @return The royalty owner addresses
     */
    function tokenRoyaltyOwnerBatch(uint256[] calldata _ids) external view override returns (address[] memory) {
        address[] memory _owners = new address[](_ids.length);

        for (uint256 i = 0; i < _ids.length; ++i) {
            _owners[i] = tokenIdToToken[_ids[i]].royaltyOwner;
        }

        return _owners;
    }

    /**
     * @notice Get the royalty fee rate of a given token type
     * @param _id The token identifier of a given token type
     * @return The royalty fee rate in terms of parts per million
     */
    function tokenRoyaltyFee(uint256 _id) external view override returns (uint256) {
        return tokenIdToToken[_id].royaltyFee;
    }

    /**
     * @notice Get the royalty fee rate of multiple token types
     * @param _ids The token identifiers of the token types
     * @return The royalty fee rates in terms of parts per million
     */
    function tokenRoyaltyFeeBatch(uint256[] calldata _ids) external view override returns (uint256[] memory) {
        uint256[] memory _fees = new uint256[](_ids.length);

        for (uint256 i = 0; i < _ids.length; ++i) {
            _fees[i] = tokenIdToToken[_ids[i]].royaltyFee;
        }

        return _fees;
    }

    /**
     * @notice Create a new token type that is associated with a sticker art image
     * @dev The token minter is assigned as the royalty owner when minting a completely new token type
     * @param _id The token identifier which is the hash value of the sticker art image
     * @param _tokenSupply Number of tokens which represents number of copies of the sticker art image
     * @param _uri URI to the metadata description file for the sticker art image
     * @param _royaltyFee The royalty fee rate in terms of parts per million when trading the token
     * @param _didUri DID URI of the token minter
     */
    function mint(
        uint256 _id,
        uint256 _tokenSupply,
        string calldata _uri,
        uint256 _royaltyFee,
        string calldata _didUri
    ) external override inited {
        require(_id != 0, "New TokenID cannot be zero");
        require(_tokenSupply > 0, "New Token supply cannot be zero");
        require(tokenIdToToken[_id].tokenSupply == 0, "Cannot mint token with existing supply");
        require(
            tokenIdToToken[_id].tokenId == 0 || tokenIdToToken[_id].tokenId == _id,
            "Something is wrong with mint"
        );
        require(_royaltyFee <= RATE_BASE, "Fee rate error");

        if (tokenIdToToken[_id].tokenId == 0) {
            tokenIds.push(_id);
            tokenIdToToken[_id].tokenId = _id;
            tokenIdToToken[_id].tokenIndex = tokenIds.length.sub(1);
            tokenIdToToken[_id].royaltyOwner = msg.sender;
            emit RoyaltyOwner(msg.sender, _id);
            tokenIdToToken[_id].createTime = block.timestamp;
        }

        tokenIdToToken[_id].tokenSupply = _tokenSupply;
        tokenIdToToken[_id].tokenUri = _uri;
        tokenIdToToken[_id].royaltyFee = _royaltyFee;
        emit RoyaltyFee(_royaltyFee, _id);
        tokenIdToToken[_id].updateTime = block.timestamp;

        _addTokenToOwner(_id, msg.sender);
        balances[_id][msg.sender] = _tokenSupply;
        emit TransferSingle(msg.sender, address(0x0), msg.sender, _id, _tokenSupply);

        if (bytes(_uri).length > 0) {
            emit URI(_uri, _id);
        }

        tokenIdToExtraInfo[_id].didUri = _didUri;

        if (bytes(_didUri).length > 0) {
            emit DIDURI(_didUri, _id, msg.sender);
        }
    }

    /**
     * @notice Destroy tokens held by the caller
     * @param _id The identifier of the token type where tokens are to be destroyed
     * @param _value The amount of tokens to be destroyed
     */
    function burn(uint256 _id, uint256 _value) external override inited {
        _burnFrom(msg.sender, _id, _value);
    }

    /**
     * @notice Destroy tokens held by `_owner`
     * @dev The caller must be an operator for `owner`'s tokens
     * @param _owner The token holder address
     * @param _id The identifier of the token type where tokens are to be destroyed
     * @param _value The amount of tokens to be destroyed
     */
    function burnFrom(
        address _owner,
        uint256 _id,
        uint256 _value
    ) external override inited {
        _burnFrom(_owner, _id, _value);
    }

    function _burnFrom(
        address _owner,
        uint256 _id,
        uint256 _value
    ) internal {
        require(_owner == msg.sender || operatorApproval[_owner][msg.sender] == true, "Burner is not operator");
        require(_value > 0, "Cannot burn zero token");
        balances[_id][_owner] = balances[_id][_owner].sub(_value);
        emit TransferSingle(msg.sender, msg.sender, address(0x0), _id, _value);
        if (balances[_id][_owner] <= 0) {
            _removeTokenFromOwner(_id, _owner);
        }

        tokenIdToToken[_id].tokenSupply = tokenIdToToken[_id].tokenSupply.sub(_value);
        tokenIdToToken[_id].updateTime = block.timestamp;
    }

    /**
     * @notice Get aggregated token information for a given token
     * @param _id The token identifier
     * @return The aggregated token information
     */
    function tokenInfo(uint256 _id) external view override returns (TokenInfo memory) {
        return tokenIdToToken[_id];
    }

    /**
     * @notice Get aggregated token information for multiple tokens
     * @param _ids The token identifiers
     * @return The aggregated token information array
     */
    function tokenInfoBatch(uint256[] calldata _ids) external view override returns (TokenInfo[] memory) {
        TokenInfo[] memory _tokens = new TokenInfo[](_ids.length);

        for (uint256 i = 0; i < _ids.length; ++i) {
            _tokens[i] = tokenIdToToken[_ids[i]];
        }

        return _tokens;
    }

    /**
     * @dev Always returns zero for sticker art tokens
     * @return uint8(0)
     */
    function decimals() external pure override returns (uint8) {
        return uint8(0);
    }

    function getVersion() external pure override returns (string memory) {
        return version;
    }

    function getMagic() external pure override returns (string memory) {
        return magic;
    }

    /**
     * @notice Get upgraded token extra information for a given token
     * @param _id The token identifier
     * @return The upgraded token extra information
     */
    function tokenExtraInfo(uint256 _id) external view override returns (TokenExtraInfo memory) {
        return tokenIdToExtraInfo[_id];
    }

    /**
     * @notice Get upgraded token extra information for multiple tokens
     * @param _ids The token identifiers
     * @return The upgraded token extra information array
     */
    function tokenExtraInfoBatch(uint256[] calldata _ids) external view override returns (TokenExtraInfo[] memory) {
        TokenExtraInfo[] memory _extras = new TokenExtraInfo[](_ids.length);

        for (uint256 i = 0; i < _ids.length; ++i) {
            _extras[i] = tokenIdToExtraInfo[_ids[i]];
        }

        return _extras;
    }

    /**
     * @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call). With memo parameter.
     * @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
     * MUST revert if `_to` is the zero address.
     * MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
     * MUST revert on any other error.
     * MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
     * MUST emit the `TransferSingleWithMemo` event.
     * After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _value   Transfer amount
     * @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
     * @param _memo    Memo message string attached to the transaction
     */
    function safeTransferFromWithMemo(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data,
        string calldata _memo
    ) external override inited reentrancyGuard {
        _safeTransferFrom(_from, _to, _id, _value, _data, _memo);
    }

    /**
     * @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call). With memo paramter.
     * @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
     * MUST revert if `_to` is the zero address.
     * MUST revert if length of `_ids` is not the same as length of `_values`.
     * MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
     * MUST revert on any other error.
     * MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
     * MUST emit the `TransferBatchWithMemo` event
     * Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
     * After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * @param _from    Source address
     * @param _to      Target address
     * @param _ids     IDs of each token type (order and length must match _values array)
     * @param _values  Transfer amounts per token type (order and length must match _ids array)
     * @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
     * @param _memo    Memo message string attached to the transaction
     */
    function safeBatchTransferFromWithMemo(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data,
        string calldata _memo
    ) external override inited reentrancyGuard {
        _safeBatchTransferFrom(_from, _to, _ids, _values, _data, _memo);
    }

    /**
     * @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call). With memo parameter.
     * @dev This works identically to the other function with an extra data parameter, except this function just sets data to "".
     * @param _from    Source address
     * @param _to      Target address
     * @param _id      ID of the token type
     * @param _value   Transfer amount
     * @param _memo    Memo message string attached to the transaction
     */
    function safeTransferFromWithMemo(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        string calldata _memo
    ) external override inited reentrancyGuard {
        _safeTransferFrom(_from, _to, _id, _value, "", _memo);
    }

    /**
     * @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call). With memo parameter.
     * @dev This works identically to the other function with an extra data parameter, except this function just sets data to "".
     * @param _from    Source address
     * @param _to      Target address
     * @param _ids     IDs of each token type (order and length must match _values array)
     * @param _values  Transfer amounts per token type (order and length must match _ids array)
     * @param _memo    Memo message string attached to the transaction
     */
    function safeBatchTransferFromWithMemo(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        string calldata _memo
    ) external override inited reentrancyGuard {
        _safeBatchTransferFrom(_from, _to, _ids, _values, "", _memo);
    }
}