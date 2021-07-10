/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

// Sources flattened with hardhat v2.4.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]


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


// File contracts/interfaces/IApi3Pool.sol

pragma solidity 0.8.6;

interface IApi3Pool {
    struct Reward {
        uint32 atBlock;
        uint224 amount;
        uint256 totalSharesThen;
        uint256 totalStakeThen;
    }

    function EPOCH_LENGTH() external view returns (uint256);

    function REWARD_VESTING_PERIOD() external view returns (uint256);

    function genesisEpoch() external view returns (uint256);

    function epochIndexToReward(uint256) external view returns (Reward memory);
}


// File contracts/interfaces/ITimelockManager.sol

pragma solidity 0.8.6;

interface ITimelockManager {
    struct Timelock {
        uint256 totalAmount;
        uint256 remainingAmount;
        uint256 releaseStart;
        uint256 releaseEnd;
    }

    function timelocks(address) external view returns (Timelock memory);
}


// File contracts/LockedApi3.sol

pragma solidity 0.8.6;




contract LockedApi3 is Ownable {
    event SetVestingAddresses(address[] vestingAddresses);

    address public constant API3_TOKEN =
        0x0b38210ea11411557c13457D4dA7dC6ea731B88a;
    address public constant API3_POOL =
        0x6dd655f10d4b9E242aE186D9050B68F725c76d76;
    address public constant TIMELOCK_MANAGER =
        0xFaef86994a37F1c8b2A5c73648F07dd4eFF02baA;
    address public constant V1_TREASURY =
        0xe7aF7c5982e073aC6525a34821fe1B3e8E432099;
    address public constant PRIMARY_TREASURY =
        0xD9F80Bdb37E6Bad114D747E60cE6d2aaF26704Ae;
    address public constant SECONDARY_TREASURY =
        0x556ECbb0311D350491Ba0EC7E019c354D7723CE0;

    IERC20 public immutable api3Token;
    IApi3Pool public immutable api3Pool;
    ITimelockManager public immutable timelockManager;
    address[] public vestingAddresses;

    constructor() {
        api3Token = IERC20(API3_TOKEN);
        api3Pool = IApi3Pool(API3_POOL);
        timelockManager = ITimelockManager(TIMELOCK_MANAGER);
    }

    function setVestingAddresses(address[] memory _vestingAddresses)
        external
        onlyOwner()
    {
        vestingAddresses = _vestingAddresses;
        emit SetVestingAddresses(_vestingAddresses);
    }

    function getTotalLocked() external view returns (uint256 totalLocked) {
        totalLocked = getTimelocked() + getLockedByGovernance();
    }

    function getTimelocked() public view returns (uint256 timelocked) {
        timelocked = getLockedRewards() + getLockedVestings();
    }

    function getLockedByGovernance()
        public
        view
        returns (uint256 lockedByGoverance)
    {
        lockedByGoverance =
            api3Token.balanceOf(V1_TREASURY) +
            api3Token.balanceOf(PRIMARY_TREASURY) +
            api3Token.balanceOf(SECONDARY_TREASURY);
    }

    function getLockedRewards()
        public
        view
        returns (uint256 totalLockedRewards)
    {
        uint256 currentEpoch = block.timestamp / api3Pool.EPOCH_LENGTH();
        uint256 oldestLockedEpoch = currentEpoch -
            api3Pool.REWARD_VESTING_PERIOD() +
            1;
        if (oldestLockedEpoch < api3Pool.genesisEpoch() + 1) {
            oldestLockedEpoch = api3Pool.genesisEpoch() + 1;
        }
        for (
            uint256 indEpoch = currentEpoch;
            indEpoch >= oldestLockedEpoch;
            indEpoch--
        ) {
            IApi3Pool.Reward memory lockedReward = api3Pool.epochIndexToReward(
                indEpoch
            );
            if (lockedReward.atBlock != 0) {
                totalLockedRewards += lockedReward.amount;
            }
        }
    }

    function getLockedVestings()
        public
        view
        returns (uint256 totalLockedVestings)
    {
        for (
            uint256 indVesting = 0;
            indVesting < vestingAddresses.length;
            indVesting++
        ) {
            ITimelockManager.Timelock memory timelock = timelockManager
            .timelocks(vestingAddresses[indVesting]);
            if (block.timestamp <= timelock.releaseStart) {
                totalLockedVestings += timelock.totalAmount;
            } else if (block.timestamp >= timelock.releaseEnd) {
                continue;
            } else {
                uint256 totalTime = timelock.releaseEnd - timelock.releaseStart;
                uint256 passedTime = block.timestamp - timelock.releaseStart;
                uint256 unlocked = (timelock.totalAmount * passedTime) /
                    totalTime;
                totalLockedVestings += timelock.totalAmount - unlocked;
            }
        }
    }
}