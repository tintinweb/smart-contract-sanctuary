/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)




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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)




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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)




/**
 * @dev _Available since v3.1._
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
    ) external returns (bytes4);

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
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)





/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)




/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)




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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)




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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



/**
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)




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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)



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

// File: Staking.sol

// Staking.sol

contract Staking is ERC1155Holder, Ownable {
    address public whaleMakerAddress = 0x27a067E01856e79ca0FC8198fF1798C5BCe20F9F;
    address public alphaPassAddress = 0x481aBF7ab850730D2b7142f5818E810642F28fa6;
    address public podAddress = 0x64092C8D14AaA8a08b94E50959Aa8714F4d47F6F;
    address nullAddress = 0x0000000000000000000000000000000000000000;

    uint256 public dailyRewards = 10 * 10 ** 18; // 10 PODs in a day
    uint256 public dailyRewardsChangedAt = block.timestamp;
    uint256 public maxWalletStaked = 10;

    // Mapping of WHALE/ALPHA TokenId to timestamp
    mapping(uint256 => uint256) _tokenIdToTimeStamp;

    // Mapping of WHALE/ALPHA TokenId to staker
    mapping(uint256 => address) _tokenIdToStaker;

    // Mapping of staker to WHALE/ALPHA TokenIds
    mapping(address => uint256[]) _stakerToTokenIds;

    // Mapping of WHALE/ALPHA Token Id to POD Rewards
    mapping(uint256 => uint256) _tokenIdToRewards;

    uint256[] private _stakedTokenIds;

    function stakedTokenIds() public view returns (uint256[] memory) {
        return _stakedTokenIds;
    }

    function getTokensStaked(address staker) public view returns (uint256[] memory) {
        return _stakerToTokenIds[staker];
    }

    function _remove(address staker, uint256 index) internal {
        if (index >= _stakerToTokenIds[staker].length) return;

        for (uint256 i = index; i < _stakerToTokenIds[staker].length - 1; i++) {
            _stakerToTokenIds[staker][i] = _stakerToTokenIds[staker][i + 1];
        }
        _stakerToTokenIds[staker].pop();
    }

    function _removeTokenIdFromStaker(address staker, uint256 tokenId) internal {
        for (uint256 i = 0; i < _stakerToTokenIds[staker].length; i++) {
            if (_stakerToTokenIds[staker][i] == tokenId) {
                //This is the tokenId to remove;
                _remove(staker, i);
            }
        }
    }

    function _removeItem(uint256 index) internal {
        if (index >= _stakedTokenIds.length) return;
        for (uint256 i = index; i < _stakedTokenIds.length - 1; i++) {
            _stakedTokenIds[i] = _stakedTokenIds[i+1];
        }
        _stakedTokenIds.pop();
    }

    function _removeStakedTokenId(uint256 tokenId) internal {
        for (uint256 i = 0; i < _stakedTokenIds.length; i++) {
            if (_stakedTokenIds[i] == tokenId) {
                _removeStakedTokenId(i);
            }
        }
    }

    function _calRewardsById(uint256 tokenId) internal view returns (uint256) {
        require (_tokenIdToStaker[tokenId] != nullAddress, "NOT_STAKED_TOKEN");
        uint256 rewards;
        uint256 startTimeStamp;
        if (_tokenIdToTimeStamp[tokenId] > dailyRewardsChangedAt) {
            startTimeStamp = _tokenIdToTimeStamp[tokenId];
        } else {
            startTimeStamp = dailyRewardsChangedAt;
        }
        rewards = _tokenIdToRewards[tokenId] + (block.timestamp - startTimeStamp) * dailyRewards / 86400;
        return rewards;
    }

    function stakeByIds(uint256[] memory tokenIds) public {
        require(_stakerToTokenIds[msg.sender].length + tokenIds.length <= maxWalletStaked, "EXCEED_MAX_WALLET_STAKED");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
            	IERC721(whaleMakerAddress).ownerOf(tokenIds[i]) == msg.sender && IERC1155(alphaPassAddress).balanceOf(msg.sender, tokenIds[i]) > 0 && _tokenIdToStaker[tokenIds[i]] == nullAddress,
            	"NOT_BOTH_TOKEN_OWNER"
            );
            IERC721(whaleMakerAddress).transferFrom(msg.sender, address(this), tokenIds[i]);
            IERC1155(alphaPassAddress).safeTransferFrom(msg.sender, address(this), tokenIds[i], 1, "");
            _stakerToTokenIds[msg.sender].push(tokenIds[i]);
            _tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
            _tokenIdToStaker[tokenIds[i]] = msg.sender;
            _stakedTokenIds.push(tokenIds[i]);
        }
    }

    function _unstakeTokenId(uint256 tokenId) internal {
        IERC721(whaleMakerAddress).transferFrom(address(this), msg.sender, tokenId);
        IERC1155(alphaPassAddress).safeTransferFrom(address(this), msg.sender, tokenId, 1, "");
        _removeTokenIdFromStaker(msg.sender, tokenId);
        _removeStakedTokenId(tokenId);
        _tokenIdToStaker[tokenId] = nullAddress;
        _tokenIdToRewards[tokenId] = 0;
    }
    
    function unstakeByIds(uint256[] memory tokenIds) public {
        // Get Total Rewards
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_tokenIdToStaker[tokenIds[i]] == msg.sender, "NOT_VALID_STAKER");
            totalRewards = totalRewards + _calRewardsById(tokenIds[i]);
        }
        
        require(totalRewards < IERC20(podAddress).balanceOf(address(this)), "NOT_ENOUGH_BALANCE_ON_CONTRACT");

        // Unstake all Whale/AP tokens
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstakeTokenId(tokenIds[i]);
        }

        // Transfer rewards
        IERC20(podAddress).transfer(msg.sender, totalRewards);
    }

    function unstakeAll() public {
        require(_stakerToTokenIds[msg.sender].length > 0, "ZERO_STAKED_TOKEN");
        unstakeByIds(_stakerToTokenIds[msg.sender]);
    }

    function claimByTokenIds(uint256[] memory tokenIds) public {
        // Get Total Claim ammount
        uint256 totalRewards = 0;
        for (uint256 i=0; i < tokenIds.length; i++) {
            require(_tokenIdToStaker[tokenIds[i]] == msg.sender, "NOT_VALID_STAKER");
            totalRewards = totalRewards + _calRewardsById(tokenIds[i]);
        }
        
        require(totalRewards < IERC20(podAddress).balanceOf(address(this)), "NOT_ENOUGH_BALANCE_ON_CONTRACT");
        IERC20(podAddress).transfer(msg.sender, totalRewards);

        for (uint256 i=0; i < tokenIds.length; i++) {
            _tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
            _tokenIdToRewards[tokenIds[i]] = 0;
        }
    }

    function claimAll() public {
        // require(block.timestamp < CLAIM_END_TIME, "Claim period is over!");
        require(_stakerToTokenIds[msg.sender].length > 0, "ZERO_STAKED_TOKEN");
        claimByTokenIds(_stakerToTokenIds[msg.sender]);
    }

    function getAllRewards(address staker) public view returns (uint256) {
        uint256[] memory tokenIds = _stakerToTokenIds[staker];
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalRewards = totalRewards + _calRewardsById(tokenIds[i]);
        }
        return totalRewards;
    }

    function getRewardsByTokenId(uint256 tokenId) public view returns (uint256) {
        require(_tokenIdToStaker[tokenId] != nullAddress, "Token is not staked!");
        return _calRewardsById(tokenId);
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return _tokenIdToStaker[tokenId];
    }
    
    function setWhaleMakerAddress(address newAddress) public onlyOwner {
        whaleMakerAddress = newAddress;
    }
    function setAlphaPassAddress(address newAddress) public onlyOwner {
        alphaPassAddress = newAddress;
    }
    function setPodAddress(address newAddress) public onlyOwner {
        podAddress = newAddress;
    }
    function setDailyRewards(uint256 newReward) public onlyOwner {
        // Calculate and Store the current total rewards of all tokens by old value whenever dailyRewards is updated
        if (_stakedTokenIds.length > 0) {
            for (uint256 i=0; i<_stakedTokenIds.length; i++) {
                _tokenIdToRewards[_stakedTokenIds[i]] = _calRewardsById(_stakedTokenIds[i]);
            }
        }
        dailyRewards = newReward;
        dailyRewardsChangedAt = block.timestamp;
    }
    function setMaxWalletStaked(uint256 newValue) public onlyOwner {
        maxWalletStaked = newValue;
    }
    function withdrawETH() external onlyOwner {
        require(address(this).balance > 0, "NO_BALANCE");
        payable(msg.sender).transfer(address(this).balance);
    }
    function withdrawPOD() external onlyOwner {
        require( IERC20(podAddress).balanceOf(address(this)) > 0, "NO_BALANCE");
        IERC20(podAddress).transfer(msg.sender, IERC20(podAddress).balanceOf(address(this)));
    }
}