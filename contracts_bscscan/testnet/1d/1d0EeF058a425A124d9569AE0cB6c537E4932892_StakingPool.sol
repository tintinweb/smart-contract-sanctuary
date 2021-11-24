/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

// File: contracts/utils/SignatureUtils.sol


pragma solidity 0.6.12;

contract SignatureUtils {
    function getMessageHash(
        uint256 tokenId,
        uint256 price,
        uint256 salt,
        address owner,
        address signer
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId, price, salt, owner, signer));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verify(
        uint256 tokenId,
        uint256 price,
        uint256 salt,
        address owner,
        address signer,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(
            tokenId,
            price,
            salt,
            owner,
            signer
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function recoverSigner(bytes32 hash, bytes memory signature)
        public
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }
}
// File: contracts/interfaces/IERC165.sol



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
// File: contracts/interfaces/IERC721.sol



pragma solidity >=0.6.0 <0.8.0;


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
// File: @pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol



pragma solidity >=0.4.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: @pancakeswap/pancake-swap-lib/contracts/utils/ReentrancyGuard.sol



pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
// File: @pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol



pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// File: @pancakeswap/pancake-swap-lib/contracts/GSN/Context.sol



pragma solidity >=0.4.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol



pragma solidity >=0.4.0;


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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/handlers/StakingPool.sol


pragma solidity 0.6.12;







contract StakingPool is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    
    /* GLOBAL VARIABLES */
    mapping(address => bool) private adminList; // admin list for modifying pool
    mapping(address => bool) private blackList; // blocked users
    mapping(address => bool) private signers; // signers list
    uint256 private constant ONE_YEAR_IN_SECONDS = 31536000;
    uint256 private constant ONE_DAY_IN_SECONDS = 86400;
    IERC721 private immutable nftCollection; // the collection of minted nfts
    SignatureUtils private immutable signatureUtils; // used for signature verification

    /* POOL VARIABLES */
    uint256 public totalAmountStaked;
    uint256 public totalRewardClaimed;
    uint256 public totalPoolCreated;
    uint256 public totalRewardFund;
    uint256 public totalUserStaked;
    
    mapping(string => PoolInfo) public poolInfo; // pools info
    mapping(address => uint256) public totalNftStakedPerUser; // total amount of nft users staked to the pool
    mapping(address => uint256) public totalNftStakedBalancePerUser; // total value of nft users staked to the pool
    mapping(address => uint256) public totalRewardClaimedPerUser; // total reward users claimed
    mapping(string => mapping(address => mapping(uint256 => NFTStakingData))) public nftStaked; // owner => tokenId => data
    mapping(string => mapping(address => uint256)) public nftStakedBalancePerUser; // total value each user staked to the pool
    mapping(string => mapping(address => uint256)) public rewardClaimedPerUser; // reward each user has claimed
    mapping(string => mapping(address => uint256)) public totalNftStakedInPool; // totalNftStakedInPool by user
    
    constructor(SignatureUtils _signatureUtils, IERC721 _nftCollection) public {
        signatureUtils = _signatureUtils;
        nftCollection = _nftCollection;
        adminList[msg.sender] = true;
    }
    
    /*================================ MODIFIERS ================================*/
    
    modifier onlyAdmins() {
        require(adminList[msg.sender], "Only admins");
        _;
    }
    
    modifier poolExist(string memory poolId) {
        require(poolInfo[poolId].initialFund != 0, "Pool is not exist");
        _;
    }
    
    modifier updateReward(string memory poolId, uint256 tokenId) {
        PoolInfo storage pool = poolInfo[poolId];
        pool.rewardPerTokenStored = rewardPerToken(poolId);
        pool.lastUpdateTime = block.timestamp;
        NFTStakingData storage nft = nftStaked[poolId][msg.sender][tokenId];
        nft.reward = earned(poolId, msg.sender, tokenId);
        nft.rewardPerTokenPaid = pool.rewardPerTokenStored;
        _;
    }
    
    /*================================ EVENTS ================================*/
    
    event Staked( 
        uint256 indexed _tokenId,
        uint256 price,
        uint256 lockedTime,
        address indexed account,
        string poolId,
        string internalTxID
    );

    event Unstaked(
        uint256 indexed _tokenId,
        uint256 rewardAmount,
        uint256 unlockedTime,
        address indexed account,
        string poolId,
        string internalTxID
    );
    
    event Claimed(
        uint256 indexed _tokenId,
        uint256 rewardAmount,
        address indexed account,
        string poolId,
        string internalTxID
    );
    
    /*================================ STRUCTS ================================*/
     
    struct NFTStakingData {
        uint256 balance; // staked value of nft
        uint256 stakedTime; // the time nft was staked
        uint256 unstakedTime; // the time nft was unstaked
        uint256 reward; // the total reward claimed by nft
        uint256 rewardPerTokenPaid; // reward per token paid
        uint256 finalReward; // reward at the time nft was unstaked, will not calculate after unstaked time
        address owner; // owner of nft
    }
    
    struct PoolInfo {
        address rewardToken; // reward token of the pool
        uint256 nftStakedAmount; // amount of nft staked to the pool
        uint256 nftStakedBalance; // total value of nfts which were staked to the pool
        uint256 totalRewardClaimed; // total reward user has claimed
        uint256 rewardFund; // pool amount for reward token available
        uint256 initialFund; // initial reward fund
        uint256 lastUpdateTime; // last update time
        uint256 rewardPerTokenStored; // reward distributed
        uint256 startDate;
        uint256 endDate;
        uint256 duration;
        uint256 endStakeDate;
        uint256 totalUserStaked;
    }
    
    /*================================ MAIN FUNCTIONS ================================*/
    
    // data: tokenId(0), price(1), salt(2)
    // addr: signer(0)
    function stake(
        string memory poolId,
        uint256[] memory data,
        address[] memory addr,
        bytes memory signature,
        string memory internalTxID
    ) external nonReentrant poolExist(poolId) {
        PoolInfo storage pool = poolInfo[poolId];
        
        // check if staking time is valid
        require(block.timestamp >= pool.startDate, "Pool is not activated");
        require(block.timestamp <= pool.endStakeDate, "Staking time is ended"); 
        require(signers[addr[0]], "Only signers");
        require(!blackList[msg.sender], "In blacklist");

        // verify signature for nft price
        require(
            signatureUtils.verify(
                data[0],
                data[1],
                data[2],
                msg.sender,
                addr[0],
                signature
            ),
            "NFT is invalid"
        );

        pool.rewardPerTokenStored = rewardPerToken(poolId);
        pool.lastUpdateTime = block.timestamp;
        
        NFTStakingData memory nft = NFTStakingData(
            data[1],
            block.timestamp,
            0,
            0,
            pool.rewardPerTokenStored,
            0,
            msg.sender
        );

        nftCollection.transferFrom(msg.sender, address(this), data[0]);

        if (totalNftStakedPerUser[msg.sender] == 0) {
            totalUserStaked = totalUserStaked.add(1);
        }
        totalNftStakedPerUser[msg.sender] = totalNftStakedPerUser[msg.sender].add(1);
        
        if (totalNftStakedInPool[poolId][msg.sender] == 0) {
            pool.totalUserStaked = pool.totalUserStaked.add(1);
        }
        totalNftStakedInPool[poolId][msg.sender] = totalNftStakedInPool[poolId][msg.sender].add(1);
    
        nftStaked[poolId][msg.sender][data[0]] = nft;
        pool.nftStakedAmount = pool.nftStakedAmount.add(1);
        pool.nftStakedBalance = pool.nftStakedBalance.add(data[1]);
        totalAmountStaked = totalAmountStaked.add(data[1]);
        
        nftStakedBalancePerUser[poolId][msg.sender] = nftStakedBalancePerUser[poolId][
            msg.sender
        ].add(data[1]);
        
        totalNftStakedBalancePerUser[msg.sender] = totalNftStakedBalancePerUser[msg.sender].add(data[1]);

        emit Staked(
            data[0],
            data[1],
            block.timestamp,
            msg.sender,
            poolId,
            internalTxID
        );
    }

    function unstake(string memory poolId, uint256 tokenId, string memory internalTxID)
        external
        nonReentrant
        poolExist(poolId)
        updateReward(poolId, tokenId)
    {
        PoolInfo storage pool = poolInfo[poolId];
        
        NFTStakingData storage nft = nftStaked[poolId][msg.sender][tokenId];
        require(nft.unstakedTime == 0, "NFT was unstaked");
        require(nft.owner == msg.sender, "Caller not own this token");

        nftCollection.transferFrom(address(this), msg.sender, tokenId);

        totalNftStakedPerUser[msg.sender] = totalNftStakedPerUser[msg.sender].sub(1);
        if (totalNftStakedPerUser[msg.sender] == 0) {
            totalUserStaked = totalUserStaked.sub(1);
        }
        
        totalNftStakedInPool[poolId][msg.sender] = totalNftStakedInPool[poolId][msg.sender].sub(1);
        if (totalNftStakedInPool[poolId][msg.sender] == 0) {
            pool.totalUserStaked = pool.totalUserStaked.sub(1);
        }
        
        pool.nftStakedAmount = pool.nftStakedAmount.sub(1);
        pool.nftStakedBalance = pool.nftStakedBalance.sub(nft.balance); 
        totalAmountStaked = totalAmountStaked.sub(nft.balance);
        nft.finalReward = nft.reward;
        nft.unstakedTime = block.timestamp;
        nftStakedBalancePerUser[poolId][msg.sender] = nftStakedBalancePerUser[poolId][msg.sender].sub(nft.balance);
        totalNftStakedBalancePerUser[msg.sender] = totalNftStakedBalancePerUser[msg.sender].sub(nft.balance);

        emit Unstaked(
            tokenId,
            nft.finalReward,
            block.timestamp,
            msg.sender,
            poolId,
            internalTxID
        );
    }
    
    function getReward(string memory poolId, uint256 tokenId, string memory internalTxID)
        external
        nonReentrant
        poolExist(poolId)
        updateReward(poolId, tokenId)
    {
        PoolInfo storage pool = poolInfo[poolId];
        NFTStakingData storage nft = nftStaked[poolId][msg.sender][tokenId];
        uint256 availableAmount = nft.reward;
        require(availableAmount > 0, "Reward is 0");
        require(
            IBEP20(pool.rewardToken).balanceOf(address(this)) >= availableAmount,
            "Pool not has enough available amount for rewarding"
        );

        require(canGetReward(poolId, tokenId), "Staking time is not enough to get reward");

        IBEP20(pool.rewardToken).transfer(msg.sender, availableAmount);

        nft.reward = 0;
        pool.totalRewardClaimed = pool.totalRewardClaimed.add(availableAmount);
        totalRewardClaimed = totalRewardClaimed.add(availableAmount);
        rewardClaimedPerUser[poolId][msg.sender] = rewardClaimedPerUser[poolId][msg.sender].add(
            availableAmount
        );
        totalRewardClaimedPerUser[msg.sender] = totalRewardClaimedPerUser[msg.sender].add(availableAmount);

        emit Claimed(tokenId, availableAmount, msg.sender, poolId, internalTxID);
    }
    
    function canGetReward(string memory poolId, uint256 tokenId) public view returns (bool) {
        PoolInfo storage pool = poolInfo[poolId];
        if (pool.duration == 0) return true;
        
        NFTStakingData storage nft = nftStaked[poolId][msg.sender][tokenId];
        return nft.stakedTime.add(pool.duration.mul(ONE_DAY_IN_SECONDS)) >= block.timestamp;
    }

    function earned(string memory poolId, address account, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        NFTStakingData storage nft = nftStaked[poolId][account][tokenId];
        if (nft.unstakedTime != 0) return nft.finalReward;
        
        PoolInfo storage pool = poolInfo[poolId];
        uint256 amount = (nft.balance.mul(rewardPerToken(poolId).sub(nft.rewardPerTokenPaid))).add(nft.reward);
        
        return pool.rewardFund > amount ? amount : pool.rewardFund;
    }
    
    function rewardPerToken(string memory poolId) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[poolId];
        uint256 poolDuration = pool.endDate.sub(pool.startDate);
        if (pool.nftStakedBalance == 0 || poolDuration == 0) return 0;
        uint256 currentTimestamp = block.timestamp < pool.endDate ? block.timestamp : pool.endDate;

        return pool.rewardFund.mul(currentTimestamp.sub(pool.lastUpdateTime)).div(poolDuration).div(pool.nftStakedBalance).add(pool.rewardPerTokenStored);
    }
    
    function apr(string memory poolId) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[poolId];
        uint256 poolDuration = pool.endDate.sub(pool.startDate);
        return
            (pool.nftStakedBalance == 0 || poolDuration == 0)
                ? 0
                : (
                    ONE_YEAR_IN_SECONDS.mul(pool.rewardFund).div(poolDuration).sub(
                        pool.totalRewardClaimed
                    )
                ).mul(100).div(pool.nftStakedBalance); // (initialFund * 1 year / duration - rewardClaimed) / totalValueLocked
    }

    /*================================ ADMINISTRATOR FUNCTIONS ================================*/
      
    function createPool(
        string memory _poolId,
        address _rewardToken,
        uint256[] memory _configs
        ) external onlyAdmins {
        require(poolInfo[_poolId].initialFund == 0, "Pool already exists");
        
        // rewardFund, startDate, endDate, duration, endStakedTime
        PoolInfo memory pool = PoolInfo(_rewardToken, 0, 0, 0, _configs[0], _configs[0], 0, 0, _configs[1], _configs[2], _configs[3], _configs[4], 0);
        poolInfo[_poolId] = pool;
        totalPoolCreated = totalPoolCreated.add(1);
        totalRewardFund = totalRewardFund.add(_configs[0]);
    }

    function updatePool(string memory poolId, uint256[] memory _newConfigs)
        external
        onlyAdmins
        poolExist(poolId)
    {
        PoolInfo storage pool = poolInfo[poolId];
        if (_newConfigs[0] != 0) {
            require(pool.startDate > block.timestamp, "Pool is already published");
            pool.startDate = _newConfigs[0];
        }
        if (_newConfigs[1] != 0) {
            require(_newConfigs[1] > pool.startDate, "End date must be greater than start date");
            require(_newConfigs[1] >= block.timestamp, "End date must not be the past");
            pool.endDate = _newConfigs[1];
        }
        if (_newConfigs[2] != 0) {
            require(
                _newConfigs[2] >= pool.initialFund,
                "New reward fund must be greater than or equals to existing reward fund"
            );
            
            totalRewardFund = totalRewardFund.sub(pool.initialFund).add(_newConfigs[2]);
            pool.rewardFund = _newConfigs[2];
            pool.initialFund = _newConfigs[2];
        }
        if (_newConfigs[3] != 0) {
            require(_newConfigs[3] > pool.startDate, "End staking date must be greater than start date");
            pool.endStakeDate = _newConfigs[3];
        }
    }
    
    function withdraw(address tokenId, address _to, uint256 _amount) external onlyAdmins {
        IBEP20(tokenId).transfer(_to, _amount);
    }
    
    function setAdmin(address _address, bool _value) external onlyOwner {
        adminList[_address] = _value;
    } 

    function isAdmin(address _address) external view returns (bool) {
        return adminList[_address];
    }

    function setBlacklist(address _address, bool _value) external onlyAdmins {
        blackList[_address] = _value;
    }

    function isBlackList(address _address) external view returns (bool) {
        return blackList[_address];
    }
    
    function setSigner(address _address, bool _value) public onlyOwner {
        signers[_address] = _value;
    }

    function isSigner(address _address) external view returns (bool) {
        return signers[_address];
    }
}