/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// SPDX-License-Identifier: Apache-2.0 AND MIT

pragma solidity ^0.8.4;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor () {
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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

/**
 * @title UTREE token contract interface
 *
 * @dev UTREE token contract interface
 */
interface IUTREE is IERC20 {
    /**
     * @dev Burn `amount` of tokens from owner account, see {ERC20-_burn}
     *
     * @param amount Amount to burn
     */
    function burn(uint256 amount) external;

    /**
     * @dev Mint `amount` of tokens to owner account, see {ERC20-_mint}
     *
     * @param amount Amount to mint
     */
    function mint(uint256 amount) external;

    /**
     * @dev Set `staking` contract address, that could approve token transfers
     *
     * @param staking Staking contract address
     */
    function setStaking(address staking) external;

    /**
     * @dev Set `voting` contract address, that could approve token transfers
     *
     * @param voting Voting contract address
     */
    function setVoting(address voting) external;

    /**
     * @dev Approve allowance to transfer tokens `amount` from `owner` to `spender`, see {IERC20-_approve}
     *
     * @param owner Tokens owner from whom it is allowed to transfer tokens
     * @param spender Someone who can transfer tokens
     * @param amount Amount of tokens allowance to transfer
     */
    function approveTransfer(
        address owner,
        address spender,
        uint256 amount
    ) external;
}


/*
 * @title Staking contract
 *
 * @dev Staking contract extends by {Context} and {Ownable} contracts from OpenZeppelin
 */
contract Staking is Context, Ownable {
    using Math for uint256;
    using SafeMath for uint256;

    struct Option {
        uint256 duration;
        uint256 limit;
        uint256 minimal;
        uint256 percent;
    }

    struct Stake {
        uint256 amount;
        uint256 limit;
        uint256 percent;
        uint256 unlockAt;
        uint256 withdrawn;
    }

    IUTREE private _token;

    uint256 private _lastOption;

    mapping(uint256 => Option) private _options;
    mapping(address => uint256) private _lastStake;
    mapping(address => mapping(uint256 => Stake)) private _stakes;

    constructor(IUTREE token) {
        _token = token;
    }

    /**
     * @dev Set available options for creating new staking
     *
     * @param durations List of staking durations
     * @param percents List of staking percents
     * @param minimals List of minimal amount of tokens to create new staking
     * @param limits List of limits for reward of staking
     */
    function setOptions(
        uint256[] memory durations,
        uint256[] memory percents,
        uint256[] memory minimals,
        uint256[] memory limits
    ) external onlyOwner {
        require(
            durations.length > 0 && percents.length > 0 && minimals.length > 0 && limits.length > 0,
            "Arrays should be not empty"
        );
        require(
            durations.length == percents.length &&
                percents.length == minimals.length &&
                minimals.length == limits.length,
            "Arrays length should be equals"
        );

        for (uint256 i = 0; i < durations.length; i += 1) {
            require(durations[i] > 0, "Duration should be greater 0");
            require(percents[i] > 0, "Percent should be greater 0");
            require(minimals[i] > 0, "Minimal should be greater 0");
            require(limits[i] > 0, "Limit should be greater 0");

            Option storage option = _options[i];

            option.duration = durations[i];
            option.percent = percents[i];
            option.minimal = minimals[i];
            option.limit = limits[i];
        }

        _lastOption = durations.length;

        emit OptionsSet(_lastOption);
    }

    /**
     * @dev Create new stake by token holder by `optionIndex` from available options and holding `amount` tokens
     *
     * @notice Create new stake by option `optionIndex` from available options and holding `amount` tokens
     *
     * Emit {StakeCreated} event with stake option parameters
     *
     * @param optionIndex Option index of available options list
     * @param amount Tokens amount, that will be send for holding
     */
    function createStake(uint256 optionIndex, uint256 amount) external {
        address sender = _msgSender();

        require(sender != owner(), "Creating from owner account");
        require(sender != address(0), "Creating from zero account");

        require(_lastOption > optionIndex, "Wrong option index");

        Option memory option = _options[optionIndex];

        require(option.minimal <= amount, "Amount less than minimal");

        uint256 reward = amount.mul(option.percent).div(100).min(option.limit);

        _token.approveTransfer(owner(), address(this), reward);
        require(_token.transferFrom(owner(), address(this), reward), "Cannot transfer tokens");

        _token.approveTransfer(sender, address(this), amount);
        require(_token.transferFrom(sender, address(this), amount), "Cannot transfer tokens");

        // solhint-disable-next-line not-rely-on-time
        uint256 unlockAt = block.timestamp.add(option.duration);

        Stake storage stake = _stakes[sender][_lastStake[sender]];

        stake.amount = amount;
        stake.limit = option.limit;
        stake.percent = option.percent;
        stake.unlockAt = unlockAt;

        emit StakeCreated(_lastStake[sender], sender, amount, option.percent, unlockAt);

        _lastStake[sender] += 1;
    }

    /**
     * @dev Withdraw stake by token holder
     *
     * @notice Withdraw by stake `stakeIndex` and returns tokens with reward if it allowed by duration
     *
     * Emit {StakeWithdrawn} event with stake withdrawn parameters
     *
     * @param stakeIndex Index of stake from holder personal list
     */
    function withdrawStake(uint256 stakeIndex) external {
        address sender = _msgSender();

        require(_lastStake[sender] > stakeIndex, "Wrong stake index");

        Stake storage stake = _stakes[sender][stakeIndex];

        require(stake.withdrawn == 0, "Stake already withdrawn");

        // solhint-disable-next-line not-rely-on-time
        uint256 unlockAt = block.timestamp;

        uint256 withdrawn = stake.amount;
        uint256 reward = stake.amount.mul(stake.percent).div(100).min(stake.limit);

        if (unlockAt > stake.unlockAt) {
            withdrawn = withdrawn.add(reward);
        } else {
            _token.approve(address(this), reward);
            require(_token.transferFrom(address(this), owner(), reward), "Cannot transfer tokens");
        }

        _token.approve(address(this), withdrawn);
        require(_token.transferFrom(address(this), sender, withdrawn), "Cannot transfer tokens");

        stake.unlockAt = unlockAt;
        stake.withdrawn = withdrawn;

        emit StakeWithdrawn(stakeIndex, sender, withdrawn, unlockAt);
    }

    /**
     * @dev Finish stake by contract owner for specified `account`
     *
     * Emit {StakeWithdrawn} event with stake withdrawn parameters
     *
     * @param account Account address
     * @param stakeIndex Index of stake from account personal list
     * @param withReward Force returning tokens with reward
     */
    function finishStake(
        address account,
        uint256 stakeIndex,
        bool withReward
    ) external onlyOwner {
        require(_lastStake[account] > stakeIndex, "Wrong stake index");

        Stake storage stake = _stakes[account][stakeIndex];

        require(stake.withdrawn == 0, "Stake already finished");

        // solhint-disable-next-line not-rely-on-time
        uint256 unlockAt = block.timestamp;

        uint256 withdrawn = stake.amount;
        uint256 reward = stake.amount.mul(stake.percent).div(100).min(stake.limit);

        if (withReward && unlockAt > stake.unlockAt) {
            withdrawn = withdrawn.add(reward);
        } else {
            _token.approve(address(this), reward);
            require(_token.transferFrom(address(this), owner(), reward), "Cannot transfer tokens");
        }

        _token.approve(address(this), withdrawn);
        require(_token.transferFrom(address(this), account, withdrawn), "Cannot transfer tokens");

        stake.unlockAt = unlockAt;
        stake.withdrawn = withdrawn;

        emit StakeWithdrawn(stakeIndex, account, withdrawn, unlockAt);
    }

    /**
     * @dev Get a list of all available staking options
     *
     * @notice Get a list of all available staking options
     *
     * @return List of options
     */
    function listOptions() external view returns (Option[] memory) {
        Option[] memory options = new Option[](_lastOption);

        for (uint256 i = 0; i < _lastOption; i += 1) {
            options[i] = _options[i];
        }

        return options;
    }

    /**
     * @dev Get a list of account stakes for message sender
     *
     * @notice Get a personal list of opened stakes
     *
     * @return List of stakes
     */
    function listStakes() external view returns (Stake[] memory) {
        address sender = _msgSender();
        uint256 lastStake = _lastStake[sender];

        Stake[] memory stakes = new Stake[](lastStake);

        for (uint256 i = 0; i < lastStake; i += 1) {
            Stake memory stake = _stakes[sender][i];

            if (stake.withdrawn == 0) {
                stakes[i] = stake;
            }
        }

        return stakes;
    }

    /**
     * @dev Get a list of personal stakes for specified account
     *
     * @param account Account for getting stakes
     *
     * @return List of account stakes
     */
    function listAccountStakes(address account) external view onlyOwner returns (Stake[] memory) {
        uint256 lastStake = _lastStake[account];

        Stake[] memory stakes = new Stake[](lastStake);

        for (uint256 i = 0; i < lastStake; i += 1) {
            Stake memory stake = _stakes[account][i];

            if (stake.withdrawn == 0) {
                stakes[i] = stake;
            }
        }

        return stakes;
    }

    event OptionsSet(uint256 optionsCount);
    event StakeCreated(uint256 stakeIndex, address indexed account, uint256 amount, uint256 percent, uint256 unlockAt);
    event StakeWithdrawn(uint256 stakeIndex, address indexed account, uint256 withdrawn, uint256 unlockAt);
    event StakeFinished(uint256 stakeIndex, address indexed account, uint256 withdrawn, uint256 unlockAt);
}