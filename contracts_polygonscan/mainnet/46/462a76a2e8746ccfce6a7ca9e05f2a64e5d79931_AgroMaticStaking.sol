/**
 *Submitted for verification at polygonscan.com on 2021-12-03
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

// File: AgroMatic Staking.sol

//SPDX-License-Identifier: UNLICENSED




pragma solidity ^0.8.10;

contract AgroMaticStaking is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint16;

    struct User {
        uint256 total_invested;
        uint256 total_withdrawn;
        uint256 lastPayout;
        uint256 depositTime;
        uint256 totalClaimed;
        uint256 firstLevelEarning;
        uint256 secondLevelearning;
    }

    struct Pool {
        uint16 apy;
        uint16 lockPeriodInDays;
        uint256 totalDeposit;
        uint256 startDate;
        uint256 endDate;
        uint256 minContrib;
    }

    IERC20 private token; //Token address

    address private feeAddress; //Address which receives fee
    uint16 private depositFeePercent; //Percentage of fee deducted while depositing (/1000)
    uint16 private lockFeePercent; //Percentage of fee deducted while withdrawing on lock period (/1000)

    mapping(address => User) public users;
    mapping(address => address) public referrer;

    uint16[2] public referralPercent = [20,10]; // referral bonus 2%, 1%

    Pool public pool;

    event Stake(address indexed addr, uint256 amount);
    event Claim(address indexed addr, uint256 amount);

    constructor(
        address _token,
        uint16 _apy,
        uint16 _lockPeriod,
        uint256 _start,
        uint256 _end,
        uint256 _min
    ) {
        token = IERC20(_token);
        feeAddress = msg.sender;
        depositFeePercent = 20; // 2% deposit fee
        lockFeePercent = 350; // 35% withdraw fee, if withdrawn before locking period

        pool.apy = _apy;
        pool.lockPeriodInDays = _lockPeriod;
        pool.startDate = _start;
        pool.endDate = _end;
        pool.minContrib = _min;
    }

    receive() external payable {
        revert("BNB deposit not supported");
    }

    /**
     *
     * @dev update the pool's Info
     *
     */
    function set(
        uint16 _apy,
        uint16 _lockPeriodInDays,
        uint256 _endDate,
        uint256 _minContrib
    ) public onlyOwner {
        pool.apy = _apy;
        pool.lockPeriodInDays = _lockPeriodInDays;
        pool.endDate = _endDate;
        pool.minContrib = _minContrib;
    }

    /**
     *
     * @dev depsoit tokens to staking for  allocation
     *
     * @param {_amount} Amount to be staked
     *
     * @return {bool} Status of stake
     *
     */
    function stake(uint256 _amount, address _referrer) external returns (bool) {
        require(_amount >= pool.minContrib, "Invalid amount!");
        require(_referrer != msg.sender,"No self referring");
        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "Set allowance first!"
        );

        bool success = token.transferFrom(msg.sender, address(this), _amount);
        require(success, "Transfer failed");

        if(referrer[msg.sender] == address(0)){
            referrer[msg.sender] = _referrer;
        }

        _payReferral(msg.sender,_amount);

        uint256 fees = _amount.mul(depositFeePercent).div(1000);
        safeTransfer(feeAddress, fees);
        _amount = _amount.sub(fees);

        _stake(msg.sender, _amount);

        return success;
    }

    function _payReferral(address _user, uint256 _amount) internal {
        address firstReferrer = referrer[_user];
        address secondReferrer = referrer[firstReferrer];

        if(firstReferrer != address(0)){
            safeTransfer(firstReferrer, _amount.mul(referralPercent[0]).div(1000));
            users[firstReferrer].firstLevelEarning += _amount.mul(referralPercent[0]).div(1000);
        }

        if(secondReferrer != address(0)){
            safeTransfer(secondReferrer, _amount.mul(referralPercent[1]).div(1000));
            users[secondReferrer].secondLevelearning += _amount.mul(referralPercent[1]).div(1000);
        }
    }

    function _stake(address _sender, uint256 _amount) internal {
        User storage user = users[_sender];

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
     * @param {0} pool identifier
     *
     * @return {bool} status of claim
     */

    function claim() public returns (bool) {
        _claim(msg.sender);

        return true;
    }

    /**
     *
     * @dev check whether user can unstake or not
     *
     * @param {_addr} address of the user
     *
     * @return {bool} Status of claim
     *
     */

    function canUnstake(address _addr) public view returns (bool) {
        User storage user = users[_addr];

        return (block.timestamp >=
            user.depositTime.add(pool.lockPeriodInDays.mul(1 days)));
    }

    /**
     *
     * @dev withdraw tokens from Staking
     *
     * @param {_amount} amount to be unstaked
     *
     * @return {bool} Status of stake
     *
     */
    function unStake(uint256 _amount) external returns (bool) {
        User storage user = users[msg.sender];

        require(user.total_invested >= _amount, "You don't have enough funds");

        _claim(msg.sender);

        pool.totalDeposit = pool.totalDeposit.sub(_amount);
        user.total_invested = user.total_invested.sub(_amount);

        if (!canUnstake(msg.sender)) {
            uint256 fees = _amount.mul(lockFeePercent).div(1000);
            safeTransfer(feeAddress, fees);
            _amount = _amount.sub(fees);
        }

        safeTransfer(msg.sender, _amount);

        return true;
    }

    function _claim(address _addr) internal {
        User storage user = users[_addr];

        uint256 amount = payout(_addr);

        if (amount > 0) {
            user.total_withdrawn = user.total_withdrawn.add(amount);

            safeTransfer(_addr, amount);

            user.lastPayout = block.timestamp;

            user.totalClaimed = user.totalClaimed.add(amount);
        }

        emit Claim(_addr, amount);
    }

    function payout(address _addr) public view returns (uint256 value) {
        User storage user = users[_addr];

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
     * @dev safe transfer function, require to have enough  to transfer
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
    function updateFeeValues(
        uint8 _depositFeePercent,
        uint8 _lockFeePercent,
        address _feeWallet
    ) public onlyOwner {
        depositFeePercent = _depositFeePercent;
        lockFeePercent = _lockFeePercent;
        feeAddress = _feeWallet;
    }

    function getReferralEarnings(address addr) external view returns(uint256 first, uint256 second){
        return(users[addr].firstLevelEarning,users[addr].secondLevelearning);
    }

    /**
     *
     * @dev update referral values
     *
     */
    function updateReferral(uint16[2] memory values) external onlyOwner {
        referralPercent = values;
    }
}