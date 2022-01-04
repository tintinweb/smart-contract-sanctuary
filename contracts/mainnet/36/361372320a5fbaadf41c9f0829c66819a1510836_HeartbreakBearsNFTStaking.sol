/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


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

pragma solidity ^0.8.0;



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

pragma solidity ^0.8.0;


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

// File: contracts/Updated HeartbreakBearsNFTStaking.sol

pragma solidity ^0.8.2;






// import "hardhat/console.sol";

// ONE ISSUE ----> CHANGING MINTING AWARD
contract HeartbreakBearsNFTStaking is ERC1155Holder, Pausable, Ownable {
    IERC1155 private NFT;
    IERC20 private TOKEN;

    struct NftBundle {
        uint256[] tokenIds;
        uint256[] timestamps;
        uint256[] percentageBoost;
        bool isStaking;
    }

    mapping(address => NftBundle) private stakers;
    address[] private stakerList;
    uint256 public rate = 11574074074074;
    uint256 endTimestamp;
    bool hasEnded;

    constructor(address _nftAddress, address _tokenAddress) {
        NFT = IERC1155(_nftAddress);
        TOKEN = IERC20(_tokenAddress);
    }

    function percentageOf(uint256 pct, uint256 _number)
        public
        pure
        returns (uint256)
    {
        require(_number >= 10000, "Number is too small for calculation");
        uint256 bp = pct * 100;
        return (_number * bp) / 10000;
    }

    function endStaking() public onlyOwner {
        hasEnded = true;
        endTimestamp = block.timestamp;
    }

    function stakeIds(address _staker) public view returns (uint256[] memory) {
        return stakers[_staker].tokenIds;
    }

    function bonusRewards(address _staker)
        public
        view
        returns (uint256[] memory)
    {
        return stakers[_staker].percentageBoost;
    }

    function stakeTimestamps(address _staker)
        public
        view
        returns (uint256[] memory)
    {
        return stakers[_staker].timestamps;
    }

    function allowance() public view returns (uint256) {
        return TOKEN.balanceOf(address(this));
    }

    function stakeDuration(address _staker) public view returns (uint256) {
        uint256 startTime = stakers[_staker].timestamps[0];
        if (startTime > 0) {
            return block.timestamp - startTime;
        } else {
            return 0;
        }
    }

    function tokensAwarded(address _staker) public view returns (uint256) {
        NftBundle memory staker = stakers[_staker];
        uint256 totalReward;
        uint256 endTime;

        if (hasEnded) {
            endTime = endTimestamp;
        } else {
            endTime = block.timestamp;
        }

        for (uint256 i = 0; i < staker.tokenIds.length; i++) {
            uint256 _rate = rate +
                percentageOf(staker.percentageBoost[i], rate);
            totalReward += (_rate * (endTime - staker.timestamps[i]));
        }

        return totalReward;
    }

    function tokensRemaining() public view returns (uint256) {
        uint256 tokensSpent;
        for (uint256 i = 0; i < stakerList.length; i++) {
            tokensSpent += tokensAwarded(stakerList[i]);
        }
        return allowance() - tokensSpent;
    }

    function tokensAwardedForNFT(address _staker, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        NftBundle memory staker = stakers[_staker];
        uint256 endTime;

        if (hasEnded) {
            endTime = endTimestamp;
        } else {
            endTime = block.timestamp;
        }

        for (uint256 i = 0; i < staker.tokenIds.length; i++) {
            if (staker.tokenIds[i] == tokenId) {
                uint256 _rate = rate +
                    percentageOf(staker.percentageBoost[i], rate);
                return (_rate * (endTime - staker.timestamps[i]));
            }
        }

        return 0;
    }

    function stakeBatch(uint256[] memory _tokenIds) public whenNotPaused {
        require(_tokenIds.length > 0, "Must stake at least 1 NFT");
        require(hasEnded == false, "Staking has ended");
        require(allowance() > 10 ether, "No more rewards left for staking");

        if (!stakers[msg.sender].isStaking) {
            stakerList.push(msg.sender);
        }

        uint256[] memory _values = new uint256[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _values[i] = 1;
            // _timestamps[i] = block.timestamp;
            stakers[msg.sender].tokenIds.push(_tokenIds[i]);
            stakers[msg.sender].timestamps.push(block.timestamp);

            uint256 pctBoost = 0;
            uint256 id = _tokenIds[i];
            if (id >= 1 && id <= 1888) {
                pctBoost += 3; // Add 3%
            }
            if (
                id == 1 ||
                id == 5 ||
                id == 9 ||
                id == 13 ||
                id == 17 ||
                id == 23 ||
                id == 24 ||
                id == 25 ||
                id == 26 ||
                id == 71 ||
                id == 532 ||
                id == 777 ||
                id == 1144 ||
                id == 1707 ||
                id == 1482 ||
                id == 3888
            ) {
                pctBoost += 5; // Add 5%
            }
            if (_tokenIds.length == 2) {
                pctBoost += 1; // Add 1%
            } else if (_tokenIds.length >= 3) {
                pctBoost += 2; // Add 2%
            }
            stakers[msg.sender].percentageBoost.push(pctBoost);
        }

        stakers[msg.sender].isStaking = true;

        NFT.safeBatchTransferFrom(
            msg.sender,
            address(this),
            _tokenIds,
            _values,
            ""
        );
    }

    function claimTokens() public whenNotPaused {
        
        uint256 reward = tokensAwarded(msg.sender);
        require(reward > 0, "No rewards available");
        require(reward <= allowance(), "Reward exceeds tokens available");
        uint256[] memory _tokenIds = stakeIds(msg.sender);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            stakers[msg.sender].timestamps[i] = block.timestamp;
        }

        TOKEN.transfer(msg.sender, reward);

    }

    function withdraw() public whenNotPaused {
        uint256 reward = tokensAwarded(msg.sender);
        require(reward > 0, "No rewards available");
        require(reward <= allowance(), "Reward exceeds tokens available");
        uint256[] memory _tokenIds = stakeIds(msg.sender);
        uint256[] memory _values = new uint256[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _values[i] = 1;
        }
        delete stakers[msg.sender];
        TOKEN.transfer(msg.sender, reward);
        NFT.safeBatchTransferFrom(
            address(this),
            msg.sender,
            _tokenIds,
            _values,
            ""
        );
    }

    function withdrawSelected(uint256[] memory _tokenIds) public whenNotPaused {
        uint256 reward;

        uint256[] memory _values = new uint256[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _values[i] = 1;
            reward += tokensAwardedForNFT(msg.sender, _tokenIds[i]);

            uint256 index = getIndexOf(
                _tokenIds[i],
                stakers[msg.sender].tokenIds
            );

            remove(index, stakers[msg.sender].tokenIds);
            remove(index, stakers[msg.sender].timestamps);
            remove(index, stakers[msg.sender].percentageBoost);
        }

        require(reward > 0, "No rewards available");
        require(reward <= allowance(), "Reward exceeds tokens available");

        if (stakers[msg.sender].tokenIds.length == 0) {
            delete stakers[msg.sender];
        }

        TOKEN.transfer(msg.sender, reward);
        NFT.safeBatchTransferFrom(
            address(this),
            msg.sender,
            _tokenIds,
            _values,
            ""
        );
    }

    // uint[] array = [1,2,3,4,5];
    function remove(uint256 index, uint256[] storage array) internal {
        if (index >= array.length) return;

        for (uint256 i = index; i < array.length - 1; i++) {
            array[i] = array[i + 1];
        }
        array.pop();
    }

    function getIndexOf(uint256 item, uint256[] memory array)
        public
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == item) {
                return i;
            }
        }
        revert("Token not found");
    }

    function sweep() public onlyOwner {
        TOKEN.transfer(msg.sender, TOKEN.balanceOf(address(this)));
    }
}

// 1 - 1888 Additional benefit // x 1.5
// If stake two bears together you get another additional benefit of 10%
// If stake three bears you get 20% <----- BATCH STAKING
// 1/1 Bears - 15 special bears - x 2
//
// Take into account for the final token available
// Each NFT holder
// Function to change base rate

// Problem 1: There is no way to prevent a possible over promising of tokens when we have a stable rate.
// Unless we set a timeframe.