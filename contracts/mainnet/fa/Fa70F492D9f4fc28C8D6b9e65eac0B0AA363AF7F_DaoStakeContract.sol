pragma solidity ^0.6.0;
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
        return sub(a, b, "SafeMath: subtraction overflow");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
        return div(a, b, "SafeMath: division by zero");
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        return mod(a, b, "SafeMath: modulo by zero");
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
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
    constructor () internal {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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

contract DaoStakeContract is Ownable, Pausable {
    // Library for safely handling uint256
    using SafeMath for uint256;

    uint256 ONE_DAY;
    uint256 public stakeDays;
    uint256 public maxStakedQuantity;
    address public phnxContractAddress;
    uint256 public ratio;
    uint256 public totalStakedTokens;

    mapping(address => uint256) public stakerBalance;
    mapping(uint256 => StakerData) public stakerData;

    struct StakerData {
        uint256 altQuantity;
        uint256 initiationTimestamp;
        uint256 durationTimestamp;
        uint256 rewardAmount;
        address staker;
    }
    event StakeCompleted(
        uint256 altQuantity,
        uint256 initiationTimestamp,
        uint256 durationTimestamp,
        uint256 rewardAmount,
        address staker,
        address phnxContractAddress,
        address portalAddress
    );

    event Unstake(
        address staker,
        address stakedToken,
        address portalAddress,
        uint256 altQuantity,
        uint256 durationTimestamp
    ); // When ERC20s are withdrawn
    event BaseInterestUpdated(uint256 _newRate, uint256 _oldRate);

    constructor() public {
        ratio = 821917808219178;
        phnxContractAddress = 0x38A2fDc11f526Ddd5a607C1F251C065f40fBF2f7;
        maxStakedQuantity = 10000000000000000000000;
        stakeDays = 365;
        ONE_DAY = 60;
    }

    /* @dev stake function which enable the user to stake PHNX Tokens.
     *  @param _altQuantity, PHNX amount to be staked.
     *  @param _days, how many days PHNX tokens are staked for (in days)
     */
    function stakeALT(uint256 _altQuantity, uint256 _days)
        public
        whenNotPaused
        returns (uint256 rewardAmount)
    {
        require(_days <= stakeDays && _days > 0, "Invalid Days"); // To check days
        require(
            _altQuantity <= maxStakedQuantity && _altQuantity > 0,
            "Invalid PHNX quantity"
        ); // To verify PHNX quantity

        IERC20(phnxContractAddress).transferFrom(
            msg.sender,
            address(this),
            _altQuantity
        );

        rewardAmount = _calculateReward(_altQuantity, ratio, _days);

        uint256 _timestamp = block.timestamp;

        if (stakerData[_timestamp].staker != address(0)) {
            _timestamp = _timestamp.add(1);
        }

        stakerData[_timestamp] = StakerData(
            _altQuantity,
            _timestamp,
            _days.mul(ONE_DAY),
            rewardAmount,
            msg.sender
        );

        stakerBalance[msg.sender] = stakerBalance[msg.sender].add(_altQuantity);

        totalStakedTokens = totalStakedTokens.add(_altQuantity);

        IERC20(phnxContractAddress).transfer(msg.sender, rewardAmount);

        emit StakeCompleted(
            _altQuantity,
            _timestamp,
            _days.mul(ONE_DAY),
            rewardAmount,
            msg.sender,
            phnxContractAddress,
            address(this)
        );
    }

    /*  @dev unStake function which enable the user to withdraw his PHNX Tokens.
     *  @param _expiredTimestamps, time when PHNX tokens are unlocked.
     *  @param _amount, amount to be withdrawn by the user.
     */
    function unstakeALT(uint256[] calldata _expiredTimestamps, uint256 _amount)
        external
        whenNotPaused
        returns (uint256)
    {
        require(_amount > 0, "Amount should be greater than 0");
        uint256 withdrawAmount = 0;
        uint256 burnAmount = 0;
        for (uint256 i = 0; i < _expiredTimestamps.length; i = i.add(1)) {
            require(
                stakerData[_expiredTimestamps[i]].durationTimestamp != 0,
                "Nothing staked"
            );
            if (
                _expiredTimestamps[i].add(
                    stakerData[_expiredTimestamps[i]].durationTimestamp //if timestamp is not expired
                ) >= block.timestamp
            ) {
                uint256 _remainingDays = (
                    stakerData[_expiredTimestamps[i]]
                        .durationTimestamp
                        .add(_expiredTimestamps[i])
                        .sub(block.timestamp)
                )
                    .div(ONE_DAY);
                uint256 _totalDays = stakerData[_expiredTimestamps[i]]
                    .durationTimestamp
                    .div(ONE_DAY);
                if (_amount >= stakerData[_expiredTimestamps[i]].altQuantity) {
                    uint256 stakeBurn = _calculateBurn(
                        stakerData[_expiredTimestamps[i]].altQuantity,
                        _remainingDays,
                        _totalDays
                    );
                    burnAmount = burnAmount.add(stakeBurn);
                    withdrawAmount = withdrawAmount.add(
                        stakerData[_expiredTimestamps[i]].altQuantity.sub(
                            stakeBurn
                        )
                    );
                    _amount = _amount.sub(
                        stakerData[_expiredTimestamps[i]].altQuantity
                    );
                    emit Unstake(
                        msg.sender,
                        phnxContractAddress,
                        address(this),
                        stakerData[_expiredTimestamps[i]].altQuantity,
                        _expiredTimestamps[i]
                    );
                    stakerData[_expiredTimestamps[i]].altQuantity = 0;
                } else if (
                    (_amount < stakerData[_expiredTimestamps[i]].altQuantity) &&
                    _amount > 0 // if timestamp is expired
                ) {
                    stakerData[_expiredTimestamps[i]]
                        .altQuantity = stakerData[_expiredTimestamps[i]]
                        .altQuantity
                        .sub(_amount);
                    uint256 stakeBurn = _calculateBurn(
                        _amount,
                        _remainingDays,
                        _totalDays
                    );
                    burnAmount = burnAmount.add(stakeBurn);
                    withdrawAmount = withdrawAmount.add(_amount.sub(stakeBurn));
                    emit Unstake(
                        msg.sender,
                        phnxContractAddress,
                        address(this),
                        _amount,
                        _expiredTimestamps[i]
                    );
                    _amount = 0;
                }
            } else {
                if (_amount >= stakerData[_expiredTimestamps[i]].altQuantity) {
                    _amount = _amount.sub(
                        stakerData[_expiredTimestamps[i]].altQuantity
                    );
                    withdrawAmount = withdrawAmount.add(
                        stakerData[_expiredTimestamps[i]].altQuantity
                    );
                    emit Unstake(
                        msg.sender,
                        phnxContractAddress,
                        address(this),
                        stakerData[_expiredTimestamps[i]].altQuantity,
                        _expiredTimestamps[i]
                    );
                    stakerData[_expiredTimestamps[i]].altQuantity = 0;
                } else if (
                    (_amount < stakerData[_expiredTimestamps[i]].altQuantity) &&
                    _amount > 0
                ) {
                    stakerData[_expiredTimestamps[i]]
                        .altQuantity = stakerData[_expiredTimestamps[i]]
                        .altQuantity
                        .sub(_amount);
                    withdrawAmount = withdrawAmount.add(_amount);
                    emit Unstake(
                        msg.sender,
                        phnxContractAddress,
                        address(this),
                        _amount,
                        _expiredTimestamps[i]
                    );
                    break;
                }
            }
        }
        require(withdrawAmount != 0, "Not Transferred");

        if (burnAmount > 0) {
            IERC20(phnxContractAddress).transfer(
                0x0000000000000000000000000000000000000001,
                burnAmount
            );
        }

        stakerBalance[msg.sender] = stakerBalance[msg.sender].sub(
            withdrawAmount
        );

        totalStakedTokens = totalStakedTokens.sub(withdrawAmount);

        IERC20(phnxContractAddress).transfer(msg.sender, withdrawAmount);
        return withdrawAmount;
    }

    /* @dev to calculate reward Amount
     *  @param _altQuantity , amount of ALT tokens staked.
     *@param _baseInterest rate
     */
    function _calculateReward(
        uint256 _altQuantity,
        uint256 _ratio,
        uint256 _days
    ) internal pure returns (uint256 rewardAmount) {
        rewardAmount = (_altQuantity.mul(_ratio).mul(_days)).div(
            1000000000000000000
        );
    }

    /* @dev function to calculate the amount of PHNX token burned incase of early unstake.
     *@param _amount, The amount of Tokens user is unstaking.
     *@param _remainingDays, remaining time before the tokens will be unlocked.
     *@param _totalDays, total days tokens were staked for.
     */
    function _calculateBurn(
        uint256 _amount,
        uint256 _remainingDays,
        uint256 _totalDays
    ) internal pure returns (uint256 burnAmount) {
        burnAmount = ((_amount * _remainingDays) / _totalDays);
    }

    /* @dev to set base interest rate. Can only be called by owner
     *  @param _rate, interest rate (in wei)
     */
    function updateRatio(uint256 _rate) public onlyOwner whenNotPaused {
        ratio = _rate;
    }

    function updateTime(uint256 _time) public onlyOwner whenNotPaused {
        ONE_DAY = _time;
    }

    function updateQuantity(uint256 _quantity) public onlyOwner whenNotPaused {
        maxStakedQuantity = _quantity;
    }

    /* @dev function to update stakeDays.
     *@param _stakeDays, updated Days .
     */
    function updatestakeDays(uint256 _stakeDays) public onlyOwner {
        stakeDays = _stakeDays;
    }

    /* @dev Funtion to withdraw all PHNX from contract incase of emergency, can only be called by owner.*/
    function withdrawTokens() public onlyOwner {
        IERC20(phnxContractAddress).transfer(
            owner(),
            IERC20(phnxContractAddress).balanceOf(address(this))
        );
        pause();
    }

    function getTotalrewardTokens() external view returns(uint256){
        return IERC20(phnxContractAddress).balanceOf(address(this)).sub(totalStakedTokens);
    }

    /* @dev function to update Phoenix contract address.
     *@param _address, new address of the contract.
     */
    function setPheonixContractAddress(address _address) public onlyOwner {
        phnxContractAddress = _address;
    }

    /* @dev function which restricts the user from stakng PHNX tokens. */
    function pause() public onlyOwner {
        _pause();
    }

    /* @dev function which disables the Pause function. */
    function unPause() public onlyOwner {
        _unpause();
    }
}