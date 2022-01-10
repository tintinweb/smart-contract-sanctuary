// SPDX-License-Identifier: MIT
// Sidus Heroes Staking 
pragma solidity 0.8.11;
import "Ownable.sol";
import "IERC721.sol";
import "IERC721Receiver.sol";



contract Sidus721Staking is Ownable, IERC721Receiver {
    //using ECDSA for bytes32;
    // pool struct
    struct PoolInfo {
        address contractAddress;  // erc721 contract address
        uint256 period;           // stake period.cant claim during stake!
        uint256 activeAfter;      // date of start staking
        uint256 closedAfter;      // date of end staking
    }

    // user struct
    struct UserInfo {
        uint256 tokenId;         // subj
        uint256 stakedAt;        // moment of stake
        uint256 period;          // period in seconds
        uint256 unStaked;        // date of unstaked 
    }

    PoolInfo[] public  pools;
    
    // maping from user  to poolId to tokenId
    mapping(address => mapping(uint256 => UserInfo[])) public userStakes;

    /// Emit in case of any changes: stake or unstake for now
    /// 0 - Staked
    /// 1 - Unstaked 
    event StakeChanged(
        address indexed user, 
        uint256 indexed poolId, 
        uint8   indexed changeType,
        uint256 tokenId, 
        uint256 timestamp
    );


    function deposit(uint256 poolId, uint256 tokenId) external {
        _deposit(msg.sender, poolId, tokenId);
    }

    function depositBatch(uint256 poolId, uint256[] memory tokenIds) external {
         _depositBatch(msg.sender, poolId, tokenIds);
    }

    function withdraw(uint256 _poolId, uint256 _tokenId) external {
        // lets get tokenId index
        uint256 _tokenIndex = _getTokenIndexByTokenId(msg.sender, _poolId, _tokenId);
        _withdraw(msg.sender, _poolId, _tokenIndex); 
    }

    function withdrawBatch(uint256 _poolId) external {
        for (uint256 i = 0; i < userStakes[msg.sender][_poolId].length; i ++) {
            if (userStakes[msg.sender][_poolId][i].unStaked == 0) {
                _withdraw(msg.sender, _poolId, i);        
            }
        }
    }

    
    function getUserStakeInfo(address _user, uint256 _poolId) public view returns(UserInfo[] memory) {
        return userStakes[_user][_poolId];
    }

    function getUserStakeByIndex(address _user, uint256 _poolId, uint256 _index) public view returns(UserInfo memory) {
        return userStakes[_user][_poolId][_index];
    }

    function getUserStakeCount(address _user, uint256 _poolId) public view returns(uint256) {
        return userStakes[_user][_poolId].length;
    }

    function getUserActiveStakesCount(address _user, uint256 _poolId) public view returns(uint256) {
        return _getUserActiveStakesCount(_user, _poolId);
    } 

    ////////////////////////////////////////////////////////////
    /////////// Admin only           ////////////////////////////
    ////////////////////////////////////////////////////////////
    function addPool(
        address _contract, 
        uint256 _period, 
        uint256 _activeAfter, 
        uint256 _closedAfter
    ) public onlyOwner {
        pools.push(
            PoolInfo({
              contractAddress: _contract,  // erc721 contract address
              period: _period,             // stake period.cant claim during stake!
              activeAfter: _activeAfter,   // date of start staking
              closedAfter: _closedAfter    // date of end staking
            })
        );
    }

    function editPool(
        uint256 _poolId, 
        address _contract, 
        uint256 _period, 
        uint256 _activeAfter, 
        uint256 _closedAfter
    ) public onlyOwner {
        pools[_poolId].contractAddress = _contract;    // erc721 contract address
        pools[_poolId].period = _period;               // stake period.cant claim during stake!
        pools[_poolId].activeAfter = _activeAfter;     // date of start staking
        pools[_poolId].closedAfter = _closedAfter;     // date of end staking
    }


    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }


     ////////////////////////////////////////////////////////////
    /////////// internal           /////////////////////////////
    ////////////////////////////////////////////////////////////

    function _depositBatch(address _user, uint256 _poolId, uint256[] memory _tokenId) internal {
        for(uint256 i = 0; i < _tokenId.length; i ++) {
            _deposit(_user, _poolId, _tokenId[i]);
        }
    }

    function _deposit(address _user, uint256 _poolId, uint256 _tokenId) internal {
        require(pools[_poolId].activeAfter < block.timestamp, "Pool not active yet");
        require(pools[_poolId].closedAfter > block.timestamp, "Pool is closed");
        //TokenInfo[] storage theS =  userStakes[_user][_poolId];
        userStakes[_user][_poolId].push(
            UserInfo({
               tokenId: _tokenId,
               stakedAt:block.timestamp,      // moment of stake
               period: pools[_poolId].period, // period in seconds
               unStaked: 0                    // date of unstaked(close stake flag) 
        }));
        IERC721 nft = IERC721(pools[_poolId].contractAddress);
        nft.transferFrom(address(_user), address(this), _tokenId);
        emit StakeChanged(_user, _poolId, 0, _tokenId, block.timestamp);
    }

    function _withdraw(address _user, uint256 _poolId, uint256 _tokenIndex) internal {
        require(
            userStakes[_user][_poolId][_tokenIndex].stakedAt 
            + userStakes[_user][_poolId][_tokenIndex].period < block.timestamp,
            "Sorry, too early for withdraw"
        );
        require(
            userStakes[_user][_poolId][_tokenIndex].unStaked == 0,
            "Already unstaked"
        );

        userStakes[_user][_poolId][_tokenIndex].unStaked = block.timestamp;
        IERC721 nft = IERC721(pools[_poolId].contractAddress);
        nft.transferFrom(address(this), _user, userStakes[_user][_poolId][_tokenIndex].tokenId);
        emit StakeChanged(_user, _poolId, 1, userStakes[_user][_poolId][_tokenIndex].tokenId, block.timestamp);
    }

    function _getUserActiveStakesCount(address _user, uint256 _poolId) 
        internal 
        view 
        returns (uint256 count) 
    {
        for (uint256 i = 0; i < userStakes[_user][_poolId].length; i ++) {
            if (userStakes[_user][_poolId][i].unStaked == 0) {
                count ++;
            }
        }
    }

    function _getTokenIndexByTokenId(address _user, uint256 _poolId, uint256 _tokenId) 
        internal 
        view 
        returns (uint256) 
    {
        for (uint256 i = 0; i < userStakes[_user][_poolId].length; i ++ ) {
            if (userStakes[_user][_poolId][i].tokenId == _tokenId &&
                userStakes[_user][_poolId][i].unStaked == 0 //only active stakes
                ) 
            {
                return i;
            }
        }
        revert("Token not found");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}