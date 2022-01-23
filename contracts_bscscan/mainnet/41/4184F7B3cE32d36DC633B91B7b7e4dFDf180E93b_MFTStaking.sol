/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: contracts/MFTstaking

//SPDX-License-Identifier: UNLICENSED




pragma solidity ^0.8.10;

contract MFTStaking is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint16;

    /**
     *
     * @dev User reflects the info of each user
     *
     *
     * @param {total_invested} how many tokens the user staked
     * @param {total_withdrawn} how many tokens withdrawn so far
     * @param {lastPayout} time at which last claim was done
     * @param {depositTime} Time of last deposit
     * @param {totalClaimed} Total claimed by the user
     *
     */
    struct User {
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 lastPayout;
        uint256 depositTime;
        uint256 totalClaimed;
    }

    /**
     *
     * @dev PoolInfo reflects the info of each pools
     *
     * To improve precision, we provide APY with an additional zero. So if APY is 12%, we provide
     * 120 as input.lockPeriodInDays would be the number of days which the claim is locked. So if we want to
     * lock claim for 1 month, lockPeriodInDays would be 30.
     *
     * @param {apy} Percentage of yield produced by the pool
     * @param {lockPeriodInDays} Amount of time claim will be locked
     * @param {totalDeposit} Total deposit in the pool
     * @param {startDate} starting time of pool
     * @param {endDate} ending time of pool in unix timestamp
     * @param {minContrib} Minimum amount to be staked
     *
     */

    struct Pool {
        uint16 apy;
        uint16 lockPeriodInDays;
        uint256 totalDeposit;
        uint256 startDate;
        uint256 endDate;
        uint256 minContrib;
    }

    IERC20 private token; //Token address
    uint8 public depositFeePercent; //Percentage of fee deducted (/1000)
    uint8 public withdrawFeePercent;

    mapping(uint256 => mapping(address => User)) public users;

    Pool[] public poolInfo;

    event Stake(address indexed addr, uint256 amount);
    event Claim(address indexed addr, uint256 amount);

    constructor(address _token) {
        token = IERC20(_token);
        depositFeePercent = 20;
        withdrawFeePercent = 20;
    }

    receive() external payable {
        revert("BNB deposit not supported");
    }

    /**
     *
     * @dev get length of the pools
     *
     * @return {uint256} length of the pools
     *
     */
    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    /**
     *
     * @dev get info of all pools
     *
     * @return {PoolInfo[]} Pool info struct
     *
     */
    function getPools() internal view returns (Pool[] memory) {
        return poolInfo;
    }

    /**
     *
     * @dev add new period to the pool, only available for owner
     *
     */
    function add(
        uint16 _apy,
        uint16 _lockPeriodInDays,
        uint256 _endDate,
        uint256 _minContrib
    ) public onlyOwner {
        poolInfo.push(
            Pool({
                apy: _apy,
                lockPeriodInDays: _lockPeriodInDays,
                totalDeposit: 0,
                startDate: block.timestamp,
                endDate: _endDate,
                minContrib: _minContrib
            })
        );
    }

    /**
     *
     * @dev update the given pool's Info
     *
     */
    function set(
        uint256 _pid,
        uint16 _apy,
        uint16 _lockPeriodInDays,
        uint256 _endDate,
        uint256 _minContrib
    ) public onlyOwner {
        require(_pid < poolLength(), "Invalid pool Id");

        poolInfo[_pid].apy = _apy;
        poolInfo[_pid].lockPeriodInDays = _lockPeriodInDays;
        poolInfo[_pid].endDate = _endDate;
        poolInfo[_pid].minContrib = _minContrib;
    }

    /**
     *
     * @dev depsoit tokens to staking for  allocation
     *
     * @param {_pid} Id of the pool
     * @param {_amount} Amount to be staked
     *
     * @return {bool} Status of stake
     *
     */
    function stake(uint8 _pid, uint256 _amount) external returns (bool) {
        Pool memory pool = poolInfo[_pid];

        require(_amount >= pool.minContrib, "Invalid amount!");

        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "Staking : Set allowance first!"
        );

        bool success = token.transferFrom(msg.sender, address(this), _amount);
        require(success, "Staking : Transfer failed");

        uint256 fee = _amount.mul(depositFeePercent).div(1000);
        token.transfer(owner(), fee);
        _amount = _amount.sub(fee);

        _stake(_pid, msg.sender, _amount);

        return success;
    }

    function _stake(
        uint8 _pid,
        address _sender,
        uint256 _amount
    ) internal {
        User storage user = users[_pid][_sender];
        Pool storage pool = poolInfo[_pid];

        uint256 stopDepo = pool.endDate.sub(pool.lockPeriodInDays.mul(1 days));

        require(
            block.timestamp <= stopDepo,
            "Staking is disabled for this pool"
        );

        user.total_invested = user.total_invested.add(_amount);
        pool.totalDeposit = pool.totalDeposit.add(_amount);

        user.lastPayout = block.timestamp;
        user.depositTime = block.timestamp;

        emit Stake(_sender, _amount);
    }

    /**
     *
     * @dev claim accumulated  reward for a single pool
     *
     * @param {_pid} pool identifier
     *
     * @return {bool} status of claim
     */

    function claim(uint8 _pid) public returns (bool) {
        _claim(_pid, msg.sender);

        return true;
    }

    /**
     *
     * @dev claim accumulated  reward from all pools
     *
     * Beware of gas fee!
     *
     */
    function claimAll() public returns (bool) {
        uint256 length = poolInfo.length;

        for (uint8 pid = 0; pid < length; ++pid) {
            _claim(pid, msg.sender);
        }

        return true;
    }

    /**
     *
     * @dev check whether user can claim or not
     *
     * @param {_pid}  id of the pool
     * @param {_addr} address of the user
     *
     * @return {bool} Status of claim
     *
     */

    function canClaim(uint8 _pid, address _addr) public view returns (bool) {
        User storage user = users[_pid][_addr];
        Pool storage pool = poolInfo[_pid];

        return (block.timestamp >=
            user.depositTime.add(pool.lockPeriodInDays.mul(1 days)));
    }

    /**
     *
     * @dev withdraw tokens from Staking
     *
     * @param {_pid} id of the pool
     * @param {_amount} amount to be unstaked
     *
     * @return {bool} Status of stake
     *
     */
    function unStake(uint8 _pid, uint256 _amount) external returns (bool) {
        User storage user = users[_pid][msg.sender];
        Pool storage pool = poolInfo[_pid];

        require(user.total_invested >= _amount, "You don't have enough funds");

        require(canClaim(_pid, msg.sender), "Stake still in locked state");

        _claim(_pid, msg.sender);

        pool.totalDeposit = pool.totalDeposit.sub(_amount);
        user.total_invested = user.total_invested.sub(_amount);

        uint256 fee = _amount.mul(withdrawFeePercent).div(1000);
        token.transfer(owner(), fee);
        _amount = _amount.sub(fee);

        safeTransfer(msg.sender, _amount);

        return true;
    }

    function _claim(uint8 _pid, address _addr) internal {
        User storage user = users[_pid][_addr];

        uint256 amount = _payout(_pid, _addr);

        if (amount > 0) {
            user.total_withdrawn = user.total_withdrawn.add(amount);

            safeTransfer(_addr, amount);

            user.lastPayout = block.timestamp;

            user.totalClaimed = user.totalClaimed.add(amount);
        }

        emit Claim(_addr, amount);
    }

    function _payout(uint8 _pid, address _addr)
        public
        view
        returns (uint256 value)
    {
        User storage user = users[_pid][_addr];
        Pool storage pool = poolInfo[_pid];

        uint256 from = user.lastPayout > user.depositTime
            ? user.lastPayout
            : user.depositTime;
        uint256 to = block.timestamp > pool.endDate
            ? pool.endDate
            : block.timestamp;

        if (from < to) {
            value = value.add(
                user.total_invested.mul(to.sub(from)).mul(pool.apy).div(
                    365 days * 1000
                )
            );
        }

        return value;
    }

    /**
     *
     * @dev safe  transfer function, require to have enough  to transfer
     *
     */
    function safeTransfer(address _to, uint256 _amount) internal {
        uint256 Bal = token.balanceOf(address(this));
        if (_amount > Bal) {
            token.transfer(_to, Bal);
        } else {
            token.transfer(_to, _amount);
        }
    }

    /**
     *
     * @dev update fee values
     *
     */
    function updateFeeValues(uint8 _depositFee, uint8 _withdrawFee)
        public
        onlyOwner
    {
        depositFeePercent = _depositFee;
        withdrawFeePercent = _withdrawFee;
    }
}