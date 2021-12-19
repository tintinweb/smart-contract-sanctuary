/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/// @title Staking
/// @author Maajid
/// @notice Contract for staking tokens and get 25% interest on staking
/// @dev Staking contract for stake token for one year.
contract Staking is Ownable {
    IERC20 public erc20Token;
    using SafeMath for uint256;

    // contract states
    uint256 private constant divider = 100;
    uint256 private interestPercentage = 1500;
    uint256 private percDecreaser = 10;
    uint256 private withDrawalTimes = 12;
    uint256 private monthlyPercentage = 8;
    uint256 private minimumDays = 28 days;
    uint256 private lockTime = 30 days;
    uint256 public _totalStakedTokens;
    uint256 public _totalStakedUsers;

    struct Stake {
        uint256 amount;
        uint256 bonus;
        uint256 totalWithdrawn;
        uint256 time;
        uint256 lastWithdrawTime;
        bool withdrawn;
        bool unstaked;
    }

    struct User {
        uint256 totalStakedTokens;
        uint256 stakecount;
        mapping(uint256 => Stake) stakerecord;
    }

    mapping(address => User) public users;

    // Events
    event Staked(address indexed _user, uint256 indexed _amount, uint256 _time);

    event Withdrawn(
        address indexed _user,
        uint256 indexed _amount,
        uint256 _time
    );

    event Unstake(
        address indexed _user,
        uint256 indexed _amount,
        uint256 _time
    );

    constructor(address tokenAddress) {
        erc20Token = IERC20(tokenAddress);
    }

    /// @notice Function used to stake tokens
    /// @dev Purpose of this function is to stake tokens and locked for one year.
    /// @param tokens a parameter for send number of tokens to stake.
    function stake(uint256 tokens) public {
        require(tokens > 0, "Stake: Bad Amount");

        User storage user = users[msg.sender];
        uint256 _bonus = interestPercentage.sub(
            percDecreaser.mul(_totalStakedUsers)
        );
        if (user.stakecount == 0) {
            _totalStakedUsers += 1;
        }

        erc20Token.transferFrom(msg.sender, owner(), tokens);
        user.totalStakedTokens = user.totalStakedTokens.add(tokens);
        user.stakerecord[user.stakecount].time = block.timestamp;
        user.stakerecord[user.stakecount].amount = tokens;
        user.stakerecord[user.stakecount].lastWithdrawTime =
            block.timestamp +
            lockTime;
        user.stakerecord[user.stakecount].bonus = tokens.mul(_bonus).div(
            divider
        );
        user.stakecount++;

        _totalStakedTokens = _totalStakedTokens.add(tokens);

        emit Staked(msg.sender, tokens, block.timestamp);
    }

    /// @notice Function used to withdraw interest on his staked coins on monthly basis.
    /// @dev Function used to withdraw interest on his staked coins on monthly basis.
    /// @param _stakeCount count/index of stake by user.
    function withdraw(uint256 _stakeCount) public {
        User storage user = users[msg.sender];
        require(user.stakecount > _stakeCount, "Invalid Stake index");
        require(!user.stakerecord[_stakeCount].withdrawn, "Already withdrawn.");
        require(
            block.timestamp >=
                user.stakerecord[_stakeCount].lastWithdrawTime + minimumDays,
            "Withdraw cant be done before time."
        );

        uint256 totalAvailableWithdraw = block
            .timestamp
            .sub(user.stakerecord[_stakeCount].lastWithdrawTime)
            .div(minimumDays);
        uint256 totalBonus = (
            user.stakerecord[_stakeCount].bonus.mul(monthlyPercentage).div(
                divider
            )
        ).mul(totalAvailableWithdraw);

        uint256 totalWithdrawn = (
            monthlyPercentage
                .mul(user.stakerecord[_stakeCount].totalWithdrawn)
                .mul(user.stakerecord[_stakeCount].bonus)
        ).div(divider);

        if (
            user.stakerecord[_stakeCount].totalWithdrawn +
                totalAvailableWithdraw >
            withDrawalTimes
        ) {
            erc20Token.transferFrom(
                owner(),
                msg.sender,
                user.stakerecord[_stakeCount].bonus.sub(totalWithdrawn)
            );
            user.stakerecord[_stakeCount].totalWithdrawn = 12;
            user.stakerecord[_stakeCount].withdrawn = true;
        } else {
            erc20Token.transferFrom(owner(), msg.sender, totalBonus);
            user.stakerecord[_stakeCount].totalWithdrawn = user
                .stakerecord[_stakeCount]
                .totalWithdrawn
                .add(totalAvailableWithdraw);
        }
        user.stakerecord[_stakeCount].lastWithdrawTime = block.timestamp;

        emit Withdrawn(msg.sender, totalBonus, block.timestamp);
    }

    /// @notice Function used to withdraw all his staked coins.
    /// @dev Function used to withdraw all his staked coins.
    /// @param _stakeCount count/index of stake by user.
    function unstake(uint256 _stakeCount) public {
        User storage user = users[msg.sender];
        require(user.stakecount > _stakeCount, "Invalid Stake index");
        require(
            block.timestamp >= user.stakerecord[_stakeCount].time + lockTime,
            "Stake: Tokens not unlocked yet."
        );
        require(!user.stakerecord[_stakeCount].unstaked, "Already unstaked.");

        erc20Token.transferFrom(
            owner(),
            msg.sender,
            user.stakerecord[_stakeCount].amount
        );
        user.stakerecord[_stakeCount].unstaked = true;

        emit Unstake(
            msg.sender,
            user.stakerecord[_stakeCount].amount,
            block.timestamp
        );
    }

    // Read Functions
    function totalStakedTokens() external view returns (uint256) {
        return _totalStakedTokens;
    }

    function getCurrentAPY() external view returns (uint256) {
        return interestPercentage.sub(percDecreaser.mul(_totalStakedUsers));
    }

    function totalStakedUsers() external view returns (uint256) {
        return _totalStakedUsers;
    }

    function getLastStakeOfUser(address userAddress)
        external
        view
        returns (uint256)
    {
        User storage user = users[userAddress];
        return (user.stakecount - 1);
    }

    function getTotalInfo(address _user)
        external
        view
        returns (
            uint256 totalAmount,
            uint256 totalBonus,
            uint256 availableToClaim,
            uint256 totalWithdrawn
        )
    {
        User storage user = users[_user];

        for (uint256 i = 0; i < user.stakecount; i++) {
            if (user.stakerecord[i].lastWithdrawTime != 0) {
                uint256 dividends = block
                    .timestamp
                    .sub(user.stakerecord[i].lastWithdrawTime)
                    .div(minimumDays);
                availableToClaim = (
                    user.stakerecord[i].bonus.mul(monthlyPercentage).div(
                        divider
                    )
                ).mul(dividends);
            }

            totalAmount = totalAmount.add(user.stakerecord[i].amount);
            totalBonus = totalBonus.add(user.stakerecord[i].bonus);
            totalWithdrawn = totalWithdrawn.add(
                user.stakerecord[i].totalWithdrawn
            );
        }
    }

    function getUserStakeDetail(address _user, uint256 _stakeCount)
        external
        view
        returns (
            uint256 amount,
            uint256 bonus,
            uint256 totalWithdrawn,
            uint256 time,
            uint256 lastWithdrawTime
        )
    {
        User storage user = users[_user];
        require(user.stakecount >= _stakeCount, "Invalid Stake index");
        return (
            user.stakerecord[_stakeCount].amount,
            user.stakerecord[_stakeCount].bonus,
            user.stakerecord[_stakeCount].totalWithdrawn,
            user.stakerecord[_stakeCount].time,
            user.stakerecord[_stakeCount].lastWithdrawTime
        );
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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