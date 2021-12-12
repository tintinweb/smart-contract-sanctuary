// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;

contract DataStorage {

	uint256 public WIHDRAW_FEE = 15;
	uint256 public UNSTAKE_FEE = 10;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 public TIME_STEP = 1;

    struct Pool {
		uint256 poolId;
        uint256 fromTime;
        uint256 toTime;
		uint256 totalAmount;
		address tokenAddress;
		uint256 rewardPerBlock;
		uint256 finalAmount;
		bool locked;
    }

	struct UserInfo {
		uint256 totalPayout;
		uint256 registerTime;
		uint256 poolId;
		uint256 nftId;
		uint256 start;
		uint256 amount;
		uint256 rewardDebt;
        bool isUnStake;
		uint256 checkpoint;
	}

	mapping (uint256 => Pool) public pools;
	mapping (uint256 => mapping(address => UserInfo)) userInfos;

	UserInfo[] internal totalUser;
	uint256 public totalPool = 1;
	address payable public commissionWallet;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;

contract Events {
  event Newbie(address user, uint256 registerTime);
  event NewDeposit(address indexed user, uint8 poolId, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event UnStake(address indexed user, uint256 poolId, uint256 amount);
  event UnStakeNFT(address indexed user, uint256 poolId, uint256 nftId);
  event FeePayed(address indexed user, uint256 totalAmount);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.8.0;
pragma abicoder v2;

interface IUltisProxy {
    function getUserDividends(uint256 start, uint256 checkpoint, uint256 amount, uint256 poolTotalAmount, uint256 rewardPerBlock, uint256 poolTime, uint256 timeStep, uint256 nftId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <=0.8.0;
pragma abicoder v2;

import "./SafeMath.sol";
import "./DataStorage.sol";
import "./Events.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IUltisProxy.sol";
import "./IERC721.sol";

contract NFTStaking is ReentrancyGuard, DataStorage, Events, Ownable, Pausable {
    using SafeMath for uint256;
    address public nftToken = 0x283c77E48DB2C8DEb7412fEebBA2cBEa67AF54f1;
    address public nft = 0xAE8cBb2a21b01E15BeD62d3c386930133dE7FAb1;
    address public iUltisProxy = 0x3C769E93efCdeC28416102Ee0EDa1f572Ff94Ac8;

    /**
     * @dev Constructor function
     */
    constructor(address payable wallet) public {
        commissionWallet = wallet;
        pools[1] = Pool(
            1,
            1638946800,
            1639581000,
            0,
            0x7A1afa8397429d44c21d37d39026427C599c8c18,
            1000000000000000000,
            0,
            false
        );
    }

    function deposit(uint8 poolId, uint256 _amount)
        external
        nonReentrant
        whenNotPaused
    {
        require(_amount > 0, "Invest amount isn't enough");
        require(poolId != 0, "Invalid plan");
        Pool memory pool = pools[poolId];
        require(pool.fromTime <= block.timestamp, "Pool not start");
        require(block.timestamp <= pool.toTime, "Pool stopped");
        require(
            IERC20(pool.tokenAddress).allowance(_msgSender(), address(this)) >=
                _amount,
            "Token allowance too low"
        );
        _deposit(poolId, _msgSender(), _amount);
    }

    function depositNFT(uint8 poolId, uint256 _nftId)
        external
        nonReentrant
        whenNotPaused
    {
        require(poolId != 0, "Invalid plan");
        require(IERC721(nft).ownerOf(_nftId) == _msgSender(), "not owner");
        UserInfo storage user = userInfos[poolId][_msgSender()];
        Pool memory pool = pools[poolId];
        require(pool.fromTime <= block.timestamp, "Pool not start");
        require(block.timestamp <= pool.toTime, "Pool stopped");
        require(user.amount > 0, "deposit token before");
        user.nftId = _nftId;
        IERC721(nft).transferFrom(_msgSender(), address(this), _nftId);
    }

    function _deposit(
        uint8 poolId,
        address userAddress,
        uint256 _amount
    ) internal {
        UserInfo storage user = userInfos[poolId][_msgSender()];
        Pool storage pool = pools[poolId];
        uint256 currentTime = block.timestamp;
        _safeTransferFrom(
            userAddress,
            address(this),
            _amount,
            pool.tokenAddress
        );
        if (user.amount == 0) {
            user.checkpoint = currentTime;
            totalUser.push(user);
            emit Newbie(userAddress, currentTime);
        }
        if (user.amount > 0) {
            uint256 currentDividends = IUltisProxy(iUltisProxy)
                .getUserDividends(
                    user.start,
                    user.checkpoint,
                    user.amount,
                    pool.totalAmount,
                    pool.rewardPerBlock,
                    pool.toTime,
                    TIME_STEP,
                    user.nftId
                );
            user.rewardDebt = user.rewardDebt.add(currentDividends);
        }
        user.start = currentTime;
        user.registerTime = currentTime;
        user.amount = user.amount.add(_amount);
        if (user.isUnStake == true) {
            user.isUnStake = false;
        }
        pool.totalAmount = pool.totalAmount.add(_amount);

        emit NewDeposit(userAddress, poolId, _amount);
    }

    function _safeTransferFrom(
        address _sender,
        address _recipient,
        uint256 _amount,
        address _token
    ) private {
        bool sent = IERC20(_token).transferFrom(_sender, _recipient, _amount);
        require(sent, "Token transfer failed");
    }

    function withdraw(uint256 poolId) external nonReentrant whenNotPaused {
        uint256 feeWithdraw = 0;
        UserInfo storage user = userInfos[poolId][_msgSender()];
        Pool storage pool = pools[poolId];
        if (user.amount > 0) {
            uint256 poolAmount = pool.totalAmount;
            if (block.timestamp >= pool.toTime && pool.finalAmount == 0) {
                pool.finalAmount = pool.totalAmount;
            }
            if (block.timestamp >= pool.toTime) {
                poolAmount = pool.finalAmount;
            }
            uint256 currentDividends = IUltisProxy(iUltisProxy)
                .getUserDividends(
                    user.start,
                    user.checkpoint,
                    user.amount,
                    poolAmount,
                    pool.rewardPerBlock,
                    pool.toTime,
                    TIME_STEP,
                    user.nftId
                );
            user.checkpoint = block.timestamp;

            if (block.timestamp < pool.toTime) {
                feeWithdraw = currentDividends
                    .add(user.rewardDebt)
                    .mul(WIHDRAW_FEE)
                    .div(PERCENTS_DIVIDER);
            }
            IERC20(nftToken).transfer(
                _msgSender(),
                currentDividends.add(user.rewardDebt).sub(feeWithdraw)
            );
            if (feeWithdraw > 0) {
                IERC20(nftToken).transfer(commissionWallet, feeWithdraw);
                emit FeePayed(_msgSender(), feeWithdraw);
            }
            user.totalPayout = user.totalPayout.add(currentDividends).add(
                user.rewardDebt
            );
            user.rewardDebt = 0;
            emit Withdrawn(_msgSender(), currentDividends);
        }
    }

    function unStake(uint256 poolId) external nonReentrant whenNotPaused {
        uint256 feeUnlock = 0;
        UserInfo storage user = userInfos[poolId][_msgSender()];
        Pool storage pool = pools[poolId];
        if (
            user.isUnStake == false &&
            user.amount > 0 &&
            ((pool.locked && block.timestamp >= pool.toTime) || !pool.locked)
        ) {
            user.isUnStake = true;
            uint256 poolAmount = pool.totalAmount;
            if (block.timestamp >= pool.toTime && pool.finalAmount == 0) {
                pool.finalAmount = pool.totalAmount;
            }
            if (block.timestamp >= pool.toTime) {
                poolAmount = pool.finalAmount;
            }
            uint256 currentDividends = IUltisProxy(iUltisProxy)
                .getUserDividends(
                    user.start,
                    user.checkpoint,
                    user.amount,
                    poolAmount,
                    pool.rewardPerBlock,
                    pool.toTime,
                    TIME_STEP,
                    user.nftId
                );
            IERC20(pool.tokenAddress).transfer(_msgSender(), user.amount);
            if (block.timestamp < pool.toTime) {
                feeUnlock = currentDividends
                    .add(user.rewardDebt)
                    .mul(UNSTAKE_FEE)
                    .div(PERCENTS_DIVIDER);
            }
            if (feeUnlock > 0) {
                IERC20(nftToken).transfer(commissionWallet, feeUnlock);
                emit FeePayed(_msgSender(), feeUnlock);
            }
            IERC20(nftToken).transfer(
                _msgSender(),
                currentDividends.add(user.rewardDebt).sub(feeUnlock)
            );
            pool.totalAmount = pool.totalAmount.sub(user.amount);
            user.amount = 0;
            user.totalPayout = user.totalPayout.add(
                currentDividends.add(user.rewardDebt)
            );
            user.rewardDebt = 0;
            emit UnStake(_msgSender(), poolId, user.amount);
        }
    }

    function unStakeNFT(uint256 poolId) external nonReentrant whenNotPaused {
        UserInfo storage user = userInfos[poolId][_msgSender()];
        Pool memory pool = pools[poolId];
        uint256 _nftId = user.nftId;
        require(user.nftId > 0, "not owner");
        if (block.timestamp >= pool.toTime) {
            require(user.isUnStake, "unStake token before");
        }
        user.nftId = 0;
        IERC721(nft).transferFrom(address(this), _msgSender(), _nftId);
        emit UnStakeNFT(_msgSender(), poolId, _nftId);
    }

    function setNFTToken(address _token) external onlyOwner {
        nftToken = _token;
    }

    function setNFT(address _nft) external onlyOwner {
        nft = _nft;
    }

    function setUtilsProxy(address _utils) external onlyOwner {
        iUltisProxy = _utils;
    }

    function setCommissionsWallet(address payable _addr) external onlyOwner {
        commissionWallet = _addr;
    }

    function handleForfeitedBalance(
        address coinAddress,
        uint256 value,
        address payable to
    ) external onlyOwner {
        if (coinAddress == address(0)) {
            return to.transfer(value);
        }
        IERC20(coinAddress).transfer(to, value);
    }

    function setUnStakeFee(uint256 _fee) external onlyOwner {
        UNSTAKE_FEE = _fee;
    }

    function setWithdrawFee(uint256 _fee) external onlyOwner {
        WIHDRAW_FEE = _fee;
    }

    function setTimeStep(uint256 _time) external onlyOwner {
        TIME_STEP = _time;
    }

    function addPool(Pool memory pool) external onlyOwner {
        pools[pool.poolId] = pool;
        totalPool = totalPool.add(1);
    }

    function updatePoolInfo(Pool memory pool) external onlyOwner {
        pools[pool.poolId] = pool;
    }

    function getUserInfo(address userAddress, uint256 poolId)
        external
        view
        returns (UserInfo memory user)
    {
        user = userInfos[poolId][userAddress];
    }

    function getUserDividends(address userAddress, uint256 poolId)
        external
        view
        returns (uint256)
    {
        UserInfo memory user = userInfos[poolId][userAddress];
        Pool memory pool = pools[poolId];
        uint256 currentDividends = 0;
        uint256 poolAmount = pool.totalAmount;
        if (block.timestamp >= pool.toTime && pool.finalAmount > 0) {
            poolAmount = pool.finalAmount;
        }
        if (pool.totalAmount > 0) {
            currentDividends = IUltisProxy(iUltisProxy).getUserDividends(
                user.start,
                user.checkpoint,
                user.amount,
                poolAmount,
                pool.rewardPerBlock,
                pool.toTime,
                TIME_STEP,
                user.nftId
            );
        }
        return currentDividends;
    }

    function getAllUser(uint256 fromRegisterTime, uint256 toRegisterTime)
        external
        view
        returns (UserInfo[] memory)
    {
        UserInfo[] memory allUser = new UserInfo[](totalUser.length);
        uint256 count = 0;
        for (uint256 index = 0; index < totalUser.length; index++) {
            if (
                totalUser[index].registerTime >= fromRegisterTime &&
                totalUser[index].registerTime <= toRegisterTime
            ) {
                allUser[count] = totalUser[index];
                ++count;
            }
        }
        return allUser;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "./Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }    
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "./Ownable.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() external onlyOwner whenNotPaused returns (bool) {
    paused = true;
    emit Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() external onlyOwner whenPaused returns (bool) {
    paused = false;
    emit Unpause();
    return true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}