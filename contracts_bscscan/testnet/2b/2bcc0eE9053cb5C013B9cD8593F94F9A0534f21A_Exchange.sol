/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//pragma experimental ABIEncoderV2;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}



/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IMozikERC721Token is IERC721Enumerable {
   

    function getBaseTokenURI() external view returns (string memory); 

    function setBaseTokenURI(string memory url) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function isMozikNftToken(address tokenAddress) external view returns(bool);

    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);

    function exists(uint256 tokenId) external view returns (bool);

}

/**
 * @dev Implementation of royalties for 721s
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-2981.md
 */
interface IERC2981 {
    // ERC165 bytes to add to interface array - set in parent contract
    // implementing this standard
    //
    // bytes4(keccak256("royaltyInfo(uint256)")) == 0xcef6d368
    // bytes4(keccak256("onRoyaltiesReceived(address,address,uint256,address,uint256,bytes32)")) == 0xe8cb9d99
    // bytes4(0xcef6d368) ^ bytes4(0xe8cb9d99) == 0x263d4ef1
    // bytes4 private constant _INTERFACE_ID_ERC721ROYALTIES = 0x263d4ef1;
    // _registerInterface(_INTERFACE_ID_ERC721ROYALTIES);

    // @notice Called to return both the creator's address and the royalty percentage
    // @param _tokenId - the NFT asset queried for royalty information
    // @return receiver - address of who should be sent the royalty payment
    // @return amount - a percentage calculated as a fixed point
    //         with a scaling factor of 100000 (5 decimals), such that
    //         100% would be the value 10000000, as 10000000/100000 = 100.
    //         1% would be the value 100000, as 100000/100000 = 1
    function royaltyInfo(uint256 _tokenId) external view 
    returns (address receiver, uint256 amount);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );


    // @notice Called when royalty is transferred to the receiver. This
    //         emits the RoyaltiesReceived event as we want the NFT contract
    //         itself to contain the event for easy tracking by royalty receivers.
    // @param _royaltyRecipient - The address of who is entitled to the
    //                            royalties as specified by royaltyInfo().
    // @param _buyer - If known, the address buying the NFT on a secondary
    //                 sale. 0x0 if not known.
    // @param _tokenId - the ID of the ERC-721 token that was sold
    // @param _tokenPaid - The address of the ERC-20 token used to pay the
    //                     royalty fee amount. Set to 0x0 if paid in the
    //                     native asset (ETH).
    // @param _amount - The amount being paid to the creator using the
    //                  correct decimals from _tokenPaid's ERC-20 contract
    //                  (i.e. if 7 decimals, 10000000 for 1 token paid)
    // @param _metadata - Arbitrary data attached to this payment
    // @return `bytes4(keccak256("onRoyaltiesReceived(address,address,uint256,address,uint256,bytes32)"))`
    function onRoyaltiesReceived(address _royaltyRecipient, address _buyer, uint256 _tokenId, address _tokenPaid, uint256 _amount, bytes32 _metadata) external returns (bytes4);

    // @dev This event MUST be emitted by `onRoyaltiesReceived()`.
    event RoyaltiesReceived(
        address indexed _royaltyRecipient,
        address indexed _buyer,
        uint256 indexed _tokenId,
        address _tokenPaid,
        uint256 _amount,
        bytes32 _metadata
    );

}

interface IMozikERC721TokenWithRoyalty is IMozikERC721Token,IERC2981 {
    
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
    @title ERC-1155 Multi Token Standard
    @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 /* is ERC165 */ {
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
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

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
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absense of an event assumes disabled).
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
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
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

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
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

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
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IMozikERC1155Token is IERC1155 {

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function isMozikNftToken(address tokenAddress) external view returns(bool);

    function approve(address _spender, uint256 _id, uint256 _currentValue, uint256 _value) external;
    
    function allowance(address _owner, address _spender, uint256 _id) external view returns (uint256);

    function isApprovedOrOwner(address owner, address spender, uint256 tokenId,uint256 value) external view returns (bool);

    function exists(uint256 tokenId) external view returns (bool);

    function isOwner(address owner, uint256 tokenId) external view returns (bool);
}


/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface ERC1155TokenReceiver {
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
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

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
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
     /*
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }*/

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * @title Authentication 授权合约
 * Authentication - 用于控制市场/交易所的商品操作权限
 * @dev https://www.mozik.cc
 * @author duncanwang
 */
contract Authentication is Ownable {
    address private _owner;//合约拥有者
    mapping(address=>bool) _managers;//管理员

    /**
    * @dev constructor ： 构建函数
    */
    constructor() {    
        _owner = msg.sender;
    }

    /**
     * @dev onlyAuthorized 是否已授权？
       权限控制：修饰符
    * @param target 期望判断的目标地址;         
     */
    modifier onlyAuthorized(address target) {
        require(isOwner()||isManager(target),"Only for manager or owner!");
        _;
    }    

    /**
    * @dev addManager -增加管理员。不做判断，允许重复设置；
      权限控制：只有owner可以增加管理员；
    * @param manager 期望设置的地址;    
    */
    function addManager(address manager) public onlyOwner{    
        _managers[manager] = true;
    }    

    /**
    * @dev removeManager -删除管理员。不做判断，允许重复设置；
      权限控制：只有owner可以剔除管理员；
    * @param manager 期望设置的地址;        
    */
    function removeManager(address manager) public onlyOwner{    
        _managers[manager] = false;
    }  

    /**
    * @dev isManager - 判断是否是管理员；
      权限控制：任何人都可以访问； 
    */
    function isManager(address manager) public view returns (bool) {    
        return(_managers[manager]);
    }             

}    

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

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


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


enum TokenType {ETH, ERC20}
enum StandType {ERC721,ERC1155}
/**
 * @title Good 平台合约
 * Goods - contract which treat NFT for sale.
 * @dev https://www.mozik.cc
 * @author duncanwang
 */
contract Goods is Ownable {
    using Strings for string;
    using Address for address;    
    using SafeMath for *;
   
    string constant public _name = "GOODS contract as ERC721 & ERC1155 NFT for sale with version 2.0";

    /* 商品属性 */
    address private _nftContractAddress;
    StandType public _contractType;
    uint256 public _tokenID;
    uint256 public _values;
    TokenType public _expectedTokenType;
    address payable public _sellerAddress;
    address private _expectedTokenAddress;
    uint256 public _expectedAmount;
    uint private _startTime;
    bool private _isForSale = false;

    /* 处理函数 */
    /**
    * @dev constructor ： 构建函数
    * @param ContractAddress TOKEN address treated as goods.
    */
    constructor(address ContractAddress) {
        //require an contract address
        require(true == Address.isContract(ContractAddress), "ContractAddress is not a contract address!");

        //set _nftContractAddress if the address is a ERC721 token address.
        if(IERC721(ContractAddress).supportsInterface(0x80ac58cd))
        {
            _nftContractAddress = ContractAddress;
            _contractType = StandType.ERC721;
        }
        else if(IERC1155(ContractAddress).supportsInterface(0x0e89341c))
        {
            _nftContractAddress = ContractAddress;
            _contractType = StandType.ERC1155;
        }
        else
        {
            revert();
        }
        
    }  

/**
    * @dev getGoodsInfo : 获取商品信息
    * @return _nftContractAddress 对应的NFT的合约地址
    * @return _tokenID  对应的NFT的TOKENID
    * @return _expectedTokenType 对应售出获得的TOKEN是ETH还是其他类型的TOKEN： ERC20或者ERC721；
    * @return _sellerAddress 商品销售者地址
    * @return _expectedTokenAddress 期待售出获得的TOKEN合约地址
    * @return _expectedValue 期待售出获得的TOKEN数量
    * @return _startTime 开始销售的时间；
    * @return _isForSale 当前商品是否是待售状态；
    */
    function getGoodsInfo() external view returns (address, StandType, uint256, uint256, TokenType,address,address,uint256,uint,bool) {  
        //返回商品所有信息        
        return (_nftContractAddress,_contractType,_tokenID,_values,_expectedTokenType,_sellerAddress,_expectedTokenAddress,_expectedAmount,_startTime,_isForSale);
    }  

/**
    * @dev onSale : 设置商品销售属性 
    * 权限控制：goods合约的创建者才能设置商品属性；
    * @param saleTokenID 对应的销售NFT的token ID;
    * @param value 销售份数，721资产恒为1;
    * @param sellerAddress 销售者账号；
    * @param expectedTokenType 期望获得的TOKEN是ETH还是ERC20 ,ERC721TOKEN；
    * @param tokenAddress 如果期望获得的TOKEN不是ETH，则此处为期望的TOKEN合约地址
    * @param amount 期待售出获得的TOKEN数量(上架的定价);
    * @param startTime 开始销售的时间；
    * @return bool 设置商品状态为成功还是失败；
    */
    function onSale(uint256 saleTokenID, uint256 value,address payable sellerAddress,TokenType expectedTokenType, address tokenAddress, uint256 amount, uint256 startTime) external onlyOwner returns (bool) {  
        /*1. 该商品处于销售状态，或者销售账户地址为0，则不能设置销售参数 */
        //上架了_isForSale必定为true，这样控制无法修改上架的商品属性
        /*
        if(_isForSale|| sellerAddress == address(0) )
        {
            return false;
        }
        改为：
        */
        if(sellerAddress == address(0))
        {
            return false;
        }
        if(_contractType == StandType.ERC721){
            require(1 == value, "721 Asset value MUST be 1.");
        }
        /*2.销售者不是该NFT商品的拥有者，授权者，超级授权者，则返回失败*/
        if(!isApprovedOrOwner(sellerAddress,saleTokenID,value)) 
        {
            return false;
        }   

        /*3.当销售类型不为ETH时，tokenAddress必须是一个合约地址;
            此时adress(0)也是非法的，不是合约地址，不做单独判断；*/
        if((expectedTokenType != TokenType.ETH) && (!Address.isContract(tokenAddress)) )
        {
             return false;
        }

        //4.检查startTime值小于当前区块的时间，则返回失败；
        /*2021.8.18 这个限制去掉。
        if(startTime < block.timestamp)
        {
             return false;
        }
        */
        //5.商品赋值
        _tokenID = saleTokenID;
        _values = value;
        _expectedTokenType = expectedTokenType;
        _sellerAddress = sellerAddress;
        _expectedTokenAddress = tokenAddress;
        _expectedAmount = amount;
        _startTime = startTime;
        _isForSale = true;        

        //6.返回成功
        return true;
    }  

    /**
    * @dev offSale : 商品下架，设置该商品的属性为无效值
    * 权限控制：goods合约的创建者才能设置下架；
    */
    function offSale() external onlyOwner{ 
        _tokenID = 0;
        _values = 0;
        _expectedTokenType = TokenType.ETH;
        _sellerAddress = payable(address(0));
        _expectedTokenAddress = address(0);
        _expectedAmount = 0;
        _startTime = 0;        
        _isForSale = false;
    }  

    /**
     * @dev _isApprovedOrOwner ：判断该地址是否是该NFT商品的拥有者，授权者，超级授权者
     *
     * @param seller 销售者地址
     * @param tokenId 销售者想出售的tokenId       
     * Requirements:
     * - `tokenId` must exist.
     */
    function isApprovedOrOwner(address seller, uint256 tokenId, uint256 value) public view returns (bool) {
        
        if(_contractType == StandType.ERC721)
        {
            //如果tokenId不存在，则异常返回，赋值不会成功；
            address owner = IERC721(_nftContractAddress).ownerOf(tokenId);

            /*如果销售者是该tokenID的拥有者，授权者或者超级授权者(不同于单个授权)
            为了兼容所有的ERC721 TOKEN，只能使用IERC721的接口函数来判断。*/   
            return (seller == owner || IERC721(_nftContractAddress).getApproved(tokenId) == seller || IERC721(_nftContractAddress).isApprovedForAll(owner, seller));
        }
        else if(_contractType == StandType.ERC1155)
        {
            //只有seller是资产的Owner才能过，授权的不行。
            return IMozikERC1155Token(_nftContractAddress).isApprovedOrOwner(address(0),seller,tokenId,value);
        }
        else
        {
            revert();
        }
    }

    /**
     * @dev isOnSale: 从时间，状态等判断该商品是否处于销售状态
       权限：公开，任意人都可以访问
     * @return bool true or false;
     */
    function isOnSale() public view returns(bool) {
        return(_isForSale && (block.timestamp >= _startTime)
        //增加1155商品的份数判断
        && (_values > 0) 
        );
    }

    function onBuy(uint256 saleTokenID, uint256 value)
    external onlyOwner returns(bool) {
        require((saleTokenID == _tokenID) && (block.timestamp >= _startTime) && (_values >= value), "Buy Error.");
        _values = _values.sub(value);
        return isOnSale();
    }
}


enum BaseContractType {Contract721,Contract1155,Contract20}

/**
 * @title Exchange 交易合约
 * Exchange - 该合约用于处理mozik nft的交易，换取目标为MOZIK ERC20和ETH
 * @dev https://www.mozik.cc
 * @author duncanwang
 */
contract Exchange is Authentication {
    using Strings for string;
    using Address for address;    
    using SafeMath for *;

    string constant public _name = "Exchange contract as ERC721 NFT exchange with ETH or mozik ERC20 version 1.1";    
    
    struct NftPair {
        address nftContractaddr;
        uint256 goodsID;//商品ID，唯一标识上架的商品
        bool isUsed;
    }
    mapping(bytes32 => NftPair) private _saleGoodsSource;
    mapping(bytes32 => address) private _saleGoodsAddr;//nft pair对应的商品合约地址
    //mapping(uint256 => address) private _saleGoodsAddr;//token ID对应的商品合约地址
    address private _mozikNftAddress;//MOZIK NFT智能合约
    address private _mozikErc20Address;//MOZIK ERC20智能合约
    address private _mozikMultiNftAddress;//MOZIK 1155 NFT智能合约

    /* 处理函数 */
    /**
    * @dev constructor ： 构建函数
      权限：管理账户创建者
    * @param mozikNftAddress mozik ERC721 NFT token.
    * @param mozikErc20Address mozik ERC20 FT token.
    * @param mozikMultiNftAddress mozik ERC1155 NFT token.
    */
    constructor(address mozikNftAddress, address mozikErc20Address, address mozikMultiNftAddress) {
        //这2个地址必须是合约地址
        require(Address.isContract(mozikNftAddress), "the first parameter should be MozikERC721Token address!" );     
        require(Address.isContract(mozikErc20Address), "the second parameter should be mozik ERC20 address!" );     
        require(Address.isContract(mozikMultiNftAddress), "the third parameter should be mozik ERC1155Token address!" );

        //判断该合约地址是否是mozik ERC721 NFT token地址
        require(IMozikERC721TokenWithRoyalty(mozikNftAddress).isMozikNftToken(mozikNftAddress), "the first parameter should be MozikERC721Token address!");
        require(IMozikERC1155Token(mozikMultiNftAddress).isMozikNftToken(mozikMultiNftAddress), "the third parameter should be mozik ERC1155Token address!");
        //记录合约地址
        _mozikNftAddress = mozikNftAddress;
        _mozikMultiNftAddress = mozikMultiNftAddress;

        //固定交换合约对应的ERC20的地址，防止被人使用无价值token套利.
        _mozikErc20Address = mozikErc20Address;
        
    }  

    function migrationDefaultContract(address contractAddress,BaseContractType t)
    external onlyOwner {
        require(Address.isContract(contractAddress), "the parameter should be Contract  address!" );
        if(t == BaseContractType.Contract721)
        {
            require(IMozikERC721TokenWithRoyalty(contractAddress).isMozikNftToken(contractAddress), "the parameter should be Mozik ERC721Token address!");
            _mozikNftAddress = contractAddress;
        }
        else if(t == BaseContractType.Contract1155)
        {
            require(IMozikERC1155Token(contractAddress).isMozikNftToken(contractAddress), "the third parameter should be mozik ERC1155Token address!");
            _mozikMultiNftAddress = contractAddress;
        }
    }

    function keyByNFTPair(address nftContractaddr,uint256 goodsID) internal pure
             returns (bytes32 result) 
     {  
        result =  keccak256(abi.encodePacked(nftContractaddr, goodsID));
     }  

    function _existGoods(address nftContractaddr,uint256 goodsID) internal view
            returns(bool) {
        bytes32 key = keyByNFTPair(nftContractaddr,goodsID);
        return _saleGoodsSource[key].isUsed;
    }
    
    /**
     * @dev isOnSale: 判断某个tokenId是否作为商品在销售
       权限：公开，任意人都可以访问
     * @param goodsID 需要查询的商品标识。
     */
    function isOnSale(address nftContractaddr,uint256 goodsID) public view returns(bool) {
        bytes32 key = keyByNFTPair(nftContractaddr,goodsID);
        address goodsAddress = _saleGoodsAddr[key];

        //包括该商品的isForSale是true,当前时间大于销售开始时间
        if( address(0) != goodsAddress && Goods(goodsAddress).isOnSale() )
        {
            return true;
        }
        //其他情况下均返回false
        return false;
    }   

    /**
     * @dev getSaleGoodsInfo: 返回销售列表中的某一个商品信息；
       权限：公开，任意人都可以访问
     * @param goodsID 要查询的商品
     */
    function getSaleGoodsInfo(address nftContractaddr,uint256 goodsID) external view 
    returns (address nftContractAddress, StandType, uint256 tokenid, uint256 values, TokenType expectedTokenType,address sellerAddress,address expectedTokenAddress,uint256 expectedAmount,uint startTime,bool isForSale) {
        bytes32 key = keyByNFTPair(nftContractaddr,goodsID);
        address goodsAddress = _saleGoodsAddr[key];

        //商品地址不可能是0地址；
        require(address(0) != goodsAddress, "It's not an invalid goods.");

        return( Goods(goodsAddress).getGoodsInfo() );
    }    

   /**
     * @dev hasRightToSale: 判断账户是否有销售该token id的权限；
       权限：公开，任意人都可以访问
     * @param targetAddr : address,需要判断的账号地址；
     * @param tokenId : uint256, NFT tokenId；该token Id必须存在，否则失败回滚；
     * @return bool: 返回结果 true/false;
     */
    function hasRightToSale(address nftContractaddr,StandType stand,address owner, 
    address targetAddr, uint256 tokenId,uint256 value) public view returns(bool) {
  
        //该函数不会返回异常回退
        /*判断如果销售者是该tokenID的拥有者，授权者或者超级授权者(不同于单个授权)
            为了兼容所有的ERC721 TOKEN，只能使用IERC721的接口函数来判断。*/   
        if(stand == StandType.ERC721)
            return (IMozikERC721TokenWithRoyalty(nftContractaddr).isApprovedOrOwner(targetAddr, tokenId));
        else if(stand == StandType.ERC1155)
            return (IMozikERC1155Token(nftContractaddr).isApprovedOrOwner(owner,targetAddr, tokenId,value));
        else
            return false;
    }

/**
     * @dev IsTokenOwner: 判断账户是否是该token id的拥有者；
       权限：公开，任意人都可以访问
     * @param targetAddr : address,需要判断的账号地址；
     * @param tokenId : uint256, NFT tokenId；该token Id必须存在，否则失败回滚；
     * @return bool: 返回结果 true/false;
     */
    function IsTokenOwner(address nftContractaddr,StandType stand,address targetAddr, uint256 tokenId) public view returns(bool) {
        if(stand == StandType.ERC721){
            //如果tokenId不存在则返回失败
            if(!IMozikERC721TokenWithRoyalty(nftContractaddr).exists(tokenId)){
                return false;
            }
            /* 确认目标地址是不是该token的owner*/   
            return (targetAddr == IMozikERC721TokenWithRoyalty(nftContractaddr).ownerOf(tokenId) );
        }
        else if(stand == StandType.ERC1155){
            return IMozikERC1155Token(nftContractaddr).isOwner(targetAddr,tokenId);
        }
        else
            return false;       
    }

   /**
     * @dev hasEnoughTokenToBuy: 判断账户是否有足够的token来购买NFT；
       权限：公开，任意人都可以访问
     * @param buyer : address, 购买账户,不可以是0x0的地址；
     * @param goodsID 需要查询的商品标识。
     * @param value 意向购买的份数。
     * @return bool: 返回结果 true/false;
     */
    function hasEnoughTokenToBuy(address nftContractaddr,address buyer, 
    uint256 goodsID, uint256 value) public view returns(bool) {
        
        /* 地址为0，或者token id不存在则直接返回false */
        if( (address(0) == buyer) 
        //|| (!IMozikERC721TokenWithRoyalty(nftContractaddr).exists(tokenId))
        )
        {
            return false;
        }

        /* 该tokenid属于销售商品；不判断是否处于销售中，这个由外部函数判断 */
        bytes32 key = keyByNFTPair(nftContractaddr,goodsID);
        address goodsAddress = _saleGoodsAddr[key];
        /* 如果商品地址为0，那也是异常的*/
        if(address(0) == goodsAddress)
        {
            return false;
        }
        
        /* 卖家期望收获的是ETH */
        if(TokenType.ETH ==  Goods(goodsAddress)._expectedTokenType() )
        {
            if(Goods(goodsAddress)._contractType() == StandType.ERC721)
                return buyer.balance >= Goods(goodsAddress)._expectedAmount();
            else if(Goods(goodsAddress)._contractType() == StandType.ERC1155)
                return buyer.balance >= (Goods(goodsAddress)._expectedAmount()*value);
            else
                return false;
        }
        /* 卖家期望收获的是ERC20的TOKEN */
        else if(TokenType.ERC20 ==  Goods(goodsAddress)._expectedTokenType() )
        {
            if(Goods(goodsAddress)._contractType() == StandType.ERC721)
                return IERC20(_mozikErc20Address).balanceOf(buyer) >= Goods(goodsAddress)._expectedAmount();
            else if(Goods(goodsAddress)._contractType() == StandType.ERC1155)
                return IERC20(_mozikErc20Address).balanceOf(buyer) >= (Goods(goodsAddress)._expectedAmount().mul(value));
            else
                return false;
        }
        else
        {
            //其他都返回失败
            return false;
        }           
  
    }

    /**
    * @dev sellNFT: NFT拥有者发起销售设置；
       权限：TOKEN 拥有者才能发起销售
       前置条件：该NFT TOKEN拥有者需要把该TOKEN ID授权给EXCHANGE地址
    * @param goodsID 对应的销售NFT的商品标识;
    * @param saleTokenID 对应的销售NFT的token ID;
    * @param value 上架的资产份数，721资产恒为1;
    * @param expectedTokenType 期望获得的TOKEN是ETH还是ERC20 ,ERC721TOKEN；
    * @param tokenAddress 如果期望获得的TOKEN不是ETH，则此处为期望的TOKEN合约地址
    * @param amount 期待售出获得的TOKEN数量
    * @param startTime 开始销售的时间；
     */
    function sellNFT(address nftContractAddr,StandType stand,uint256 goodsID,uint256 saleTokenID, uint256 value, TokenType expectedTokenType, address tokenAddress, uint256 amount, uint256 startTime) external {
        Goods goods;
        bool result;

        /* 发送者必须是一个外部账户，不是合约地址；本版本先做限定，防止攻击 */
        require(!Address.isContract(msg.sender),"the sender should be a person, not a contract!");

        /* 目前限定销售者必须是token id的owner，同时表明该saleTokenID存在*/
        require(IsTokenOwner(nftContractAddr,stand,msg.sender, saleTokenID),"the sender isn't the owner of the token id nft!");

        /* expectedTokenType为有效值 */
        require((expectedTokenType == TokenType.ETH) || (expectedTokenType == TokenType.ERC20),
                "expectedTokenType must be ETH or ERC20 in this version!");

        /* tokenAddress为mozik ERC20的地址 */
        if(expectedTokenType == TokenType.ERC20)
        {
            require((tokenAddress == _mozikErc20Address), "the expected token must be mozik ERC20 token.");
        }
        
        /* startTime是否大于等于区块时间 */
        /*2021.8.18 如果提交上架时间早于块当前时间，以块上时间作为上架时间。
        require((startTime >= block.timestamp), "startTime for sale must be bigger than now.");
        */
        if(startTime < block.timestamp)
        {
            startTime = block.timestamp;
        }
        /*要不要考虑当前是否在销售状态？？？ */
        
        /*在上架前先显式的做一下授权操作 */
        //FIXME:是否采取这种授权方式呢？
        /*
        if(stand == StandType.ERC721){
            IERC721(nftContractAddr).approve(address(this), saleTokenID);
        }
        else if(stand == StandType.ERC1155){
            uint256 current_value = IMozikERC1155Token(nftContractAddr).allowance(msg.sender,address(this),saleTokenID);
            IMozikERC1155Token(nftContractAddr).approve(address(this),saleTokenID,
            current_value,current_value.add(value));
        }
        */
        /*该NFT TOKEN拥有者需要提前把该TOKEN ID授权给EXCHANGE地址，否者购买者会购买不成功的。
          为了备忘，提前确认当前合约是该NFT的授权者*/
        require(hasRightToSale(nftContractAddr,stand,msg.sender,address(this), 
            saleTokenID,value),"the exchange contracct is not the approved of the TOKEN.");

        bytes32 key = keyByNFTPair(nftContractAddr,goodsID);
        /* 判断token id是更新参数还是新建商品，然后调用GOODS销售设定 */
        /* 更新已有商品：对应的address值有效 */
        if( address(0) != _saleGoodsAddr[key] )
        {
            //确认下，这儿是引用还是COPY呢？引用
            goods = Goods(_saleGoodsAddr[key] );
            result = goods.onSale(saleTokenID,value,payable(msg.sender),expectedTokenType, tokenAddress, amount, startTime);
            require(result, "reset goods on sale is failed.");
        }
        else
        {
            /* 创建商品并设置商品属性 */
            goods = new Goods(nftContractAddr);
            result = goods.onSale(saleTokenID,value, payable(msg.sender), expectedTokenType, tokenAddress, amount, startTime);
            require(result, "set goods on sale is failed.");

            //更新商品地址            
            _saleGoodsAddr[key] = address(goods);
            _saleGoodsSource[key] = NftPair(nftContractAddr,saleTokenID,true);
            /* 设置当前合约Exchange为授权者,便于在购买时可以发起转移 */
            //IMozikERC721TokenWithRoyalty(_mozikNftAddress).approve(address(this),saleTokenID);
        }
    }    

    /**
    * @dev cancelSell: 取消销售货品
       权限：管理员和合约的owner才有此权限；
            销售者可以跟管理方协商后处理，无法擅自取消销售。
            这里是不是要改成销售者有权做下架呢？？？
            确认：销售者有此权限。
    * @param goodsID uint256;
    */
    function cancelSell(address nftContractAddr,uint256 goodsID) external {
        /* 发送者必须是一个外部账户，不是合约地址；本版本先做限定，防止攻击 */
        require(!Address.isContract(msg.sender),"the sender should be a person, not a contract!");
        bytes32 key = keyByNFTPair(nftContractAddr,goodsID);
        address goodsAddress = _saleGoodsAddr[key];
        /* 如果商品地址为0，那也是异常的*/
        require(address(0) != goodsAddress,"Must be a vaild goods");
        
        require(isOwner()||
        isManager(msg.sender)||
        (Goods(goodsAddress)._sellerAddress() == msg.sender),
        "the sender isn't the owner of the token id nft!");

        //不管销售状态，只要销售列表中有就删除掉。

        _saleGoodsAddr[key] = address(0);
        _saleGoodsSource[key].isUsed = false;
        //不触发Goods智能合约销毁接口了，要费GAS，没有什么价值；
        //ERC721没有取消授权的接口，也不取消授权了。
    } 

    /**
    * @dev buyNFT: 购买处于销售状态的NFT TOKEN
       权限：
       前置条件：如果是使用ERC20 MOZIK购买，需要把等额的TOKEN授权给exchange合约
    * @param goodsID 想购买的goodsID;
    * @param value 购买的资产份数
    */
    function buyNFT(address nftContractAddr,uint256 goodsID,uint256 value) payable external {  
        //判断该tokenId是否处于销售中，包含该token id是否存在  
        require(isOnSale(nftContractAddr,goodsID),"The nft token(tokenID) is not on sale.");

        //当前发起者是否有足够的余额购买
        require(hasEnoughTokenToBuy(nftContractAddr,msg.sender, goodsID, value), "No enough token to buy the NFT(tokenID)");
        
        //tokenid必须处于销售列表中,index必须是有效值
        bytes32 key = keyByNFTPair(nftContractAddr,goodsID);
        address goodsAddress = _saleGoodsAddr[key];
        //商品地址不可能是0地址；
        require(address(0) != goodsAddress, "The token ID isn't on sale status!");

        //不要出现同账号买卖现象，链上交易都费钱。想测试还请换个不同账号吧。
        require(msg.sender != Goods(goodsAddress)._sellerAddress(), "the buyer can't be same to the seller.");
        //当前合约是该NFT的授权者
        require(hasRightToSale(nftContractAddr,Goods(goodsAddress)._contractType(),
        Goods(goodsAddress)._sellerAddress(),
        address(this), Goods(goodsAddress)._tokenID(),value),
        "the exchange contracct is not the approved of the TOKEN.");

        if(Goods(goodsAddress)._contractType() == StandType.ERC721){
            //转移ERC721给购买者
            IMozikERC721TokenWithRoyalty(nftContractAddr).safeTransferFrom(Goods(goodsAddress)._sellerAddress(), msg.sender, Goods(goodsAddress)._tokenID());

            //根据期望的token类型做转账处理
            uint256 amount = Goods(goodsAddress)._expectedAmount();
            (address creator,uint256 royalty) = IMozikERC721TokenWithRoyalty(nftContractAddr).royaltyInfo(Goods(goodsAddress)._tokenID(),amount);

            /* 卖家期望收获的是ETH */
            if(TokenType.ETH == Goods(goodsAddress)._expectedTokenType())
            {
                //FIXME:这句require为什么会引起gas异常需要调查
                require(msg.value == amount, "No enough send token to buy the NFT(tokenID)");
                //转期望目标值的ETH
                if(creator != address(0) && royalty >0 && royalty < amount)
                {
                    Goods(goodsAddress)._sellerAddress().transfer(amount.sub(royalty));
                    payable(creator).transfer(royalty);
                }
                else
                {
                    Goods(goodsAddress)._sellerAddress().transfer(amount);
                }        
            }
            /* 卖家期望收获的是ERC20的TOKEN */
            else if(TokenType.ERC20 ==  Goods(goodsAddress)._expectedTokenType() )
            {
                //如果是使用ERC20 MOZIK购买，需要在调用该函数之前把等额的TOKEN授权给exchange合约
                require(IERC20(_mozikErc20Address).allowance(msg.sender, address(this)) >= amount, 
                        "the approved MOZ ERC20 tokens to the contract address should greater than the _expectedValue." );
                if(creator != address(0) && royalty > 0 && royalty < amount)
                {
                    IERC20(_mozikErc20Address).transferFrom(msg.sender, Goods(goodsAddress)._sellerAddress(), amount.sub(royalty));
                    IERC20(_mozikErc20Address).transferFrom(msg.sender, creator, royalty);
                }
                else
                {
                    IERC20(_mozikErc20Address).transferFrom(msg.sender, Goods(goodsAddress)._sellerAddress(), amount);
                }                                   
            }
            //移除商品.需要再次销售的话，拥有者要重新sellNFTkey
            _saleGoodsAddr[key] = address(0x0);
        }
        else if(Goods(goodsAddress)._contractType() == StandType.ERC1155){
            IMozikERC1155Token(nftContractAddr).safeTransferFrom(Goods(goodsAddress)._sellerAddress(), msg.sender, Goods(goodsAddress)._tokenID(),value,"");

            //根据期望的token类型做转账处理
            uint256 amount = Goods(goodsAddress)._expectedAmount().mul(value);
            /* 卖家期望收获的是ETH */
            if(TokenType.ETH == Goods(goodsAddress)._expectedTokenType())
            {
                //FIXME:这句require为什么会引起gas异常需要调查
                require(msg.value == amount, "No enough send token to buy the NFT(tokenID)");
                //转期望目标值的ETH
                Goods(goodsAddress)._sellerAddress().transfer(amount);
            }
            /* 卖家期望收获的是ERC20的TOKEN */
            else if(TokenType.ERC20 ==  Goods(goodsAddress)._expectedTokenType() )
            {
                //如果是使用ERC20 MOZIK购买，需要在调用该函数之前把等额的TOKEN授权给exchange合约
                require(IERC20(_mozikErc20Address).allowance(msg.sender, address(this)) >= amount, 
                        "the approved MOZ ERC20 tokens to the contract address should greater than the _expectedValue." );
                IERC20(_mozikErc20Address).transferFrom(msg.sender, Goods(goodsAddress)._sellerAddress(), amount);
            }
            //在商品合约内部减库存，同时判断是否还有库存销售，如已售完，做下架操作。
            bool onSale = Goods(goodsAddress).onBuy(Goods(goodsAddress)._tokenID(),value);
            if(!onSale)
            {
                _saleGoodsAddr[key] = address(0x0);
            }
        }
    }   

    /**
    * @dev getTokenAddress: 查看配置的3个合约地址
        权限：任何人都可查看
    * @return mozikNftAddress mozik ERC721 NFT token.
    * @return mozikErc20Address mozik ERC20 FT token.
    * @return mozikMultiNftAddress mozik ERC1155 NFT token.
    */
    function getTokenAddress() external view returns (address, address, address){
        //return(_mozikNftAddress, _mozikErc20Address);
        return(_mozikNftAddress, _mozikErc20Address, _mozikMultiNftAddress);
    }    

    /**
    * @dev destroyContract: 销毁合约。通过该函数可以把该合约的ETH返回给owner
        权限：任何人都可查看
    */
    function destroyContract() external onlyOwner {
        //该合约如果持有的MOZIK ERC20全部转给owner;
        uint256 amount = IERC20(_mozikErc20Address).balanceOf(address(this));
        IERC20(_mozikErc20Address).transfer(owner(), amount);

        //该合约如果持有的MOZIK ERC721全部转给owner
        //一般不会发送。如果要实现该功能，需要改造MoizikERC721Token多，暂不动。
            
        //该合约如果持有的ETH全部转给owner
        selfdestruct(payable(owner()));
    } 
}