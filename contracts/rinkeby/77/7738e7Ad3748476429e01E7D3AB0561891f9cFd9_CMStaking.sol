// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICMStaking.sol";
import "./interfaces/IUtils.sol";

contract CMStaking is ICMStaking, Ownable {
    struct Stake {
        address staker;
        uint256 share;
        uint256 lockupEndTime;
    }

    address public immutable override stakingToken;
    address public utils;

    Stake[] public stakes;
    uint256 public totalShare;

    modifier notifyReward() {
        IUtils(utils).notifyReward();
        _;
    }

    constructor(address _token) {
        require(_token != address(0), "Token cannot be zero address");
        stakingToken = _token;
    }

    function setHelper(address _utils) external onlyOwner {
        require(_utils != address(0), "Helper cannot be zero address");
        utils = _utils;
    }

    function stake(uint256 amount, uint256 lockupPeriod) external notifyReward {
        require(IUtils(utils).isActive(), "Not active season");
        require(amount > 0, "Amount should be bigger than zero");
        require(lockupPeriod > 0, "Lockup period should be bigger than zero");

        IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);

        uint256 share = totalShare == 0
            ? amount
            : ((totalShare * amount) /
                (IERC20(stakingToken).balanceOf(address(this))));
        uint256 lockupEndTime = block.timestamp + lockupPeriod;

        stakes.push(
            Stake({
                staker: msg.sender,
                share: share,
                lockupEndTime: lockupEndTime
            })
        );
        totalShare += share;

        emit Staked(msg.sender, share, lockupEndTime);
    }

    function withdraw(uint256 stakeId, uint256 amount)
        external
        notifyReward
        returns (uint256 amountOut)
    {
        amountOut = _withdraw(msg.sender, stakeId, amount);
        IERC20(stakingToken).transfer(msg.sender, amountOut);
    }

    function withdrawBatch(
        uint256[] calldata stakeIds,
        uint256[] calldata amounts
    ) external notifyReward returns (uint256[] memory amountOuts) {
        require(stakeIds.length == amounts.length, "Invalid argument");

        uint256 amount;
        for (uint256 i = 0; i < stakeIds.length; i++) {
            amountOuts[i] = _withdraw(msg.sender, stakeIds[i], amounts[i]);
            amount += amountOuts[i];
        }
        IERC20(stakingToken).transfer(msg.sender, amount);
    }

    function _withdraw(
        address account,
        uint256 stakeId,
        uint256 share
    ) private returns (uint256 amount) {
        Stake storage _stake = stakes[stakeId];
        require(_stake.staker == account, "Caller is not staker");
        require(
            block.timestamp >= _stake.lockupEndTime,
            "Lockup duration not passed yet"
        );

        uint256 balance = IERC20(stakingToken).balanceOf(address(this));
        uint256 availableShare = _stake.share > share ? share : _stake.share;

        amount = (balance * availableShare) / totalShare;
        totalShare -= availableShare;
        _stake.share -= availableShare;

        emit Withdraw(stakeId, share);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IUtils {
    function startSeason(
        uint256,
        uint256,
        uint256
    ) external;

    function isActive() external view returns (bool);

    function notifyReward() external;

    event SeasonStarted(uint256 reward, uint256 startTime, uint256 endTime);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface ICMStaking {
    function stakingToken() external view returns (address);

    event Staked(address indexed account, uint256 share, uint256 lockupEndTime);
    event Withdraw(uint256 indexed stakeId, uint256 share);
}

