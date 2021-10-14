/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// File: contracts/Address.sol

pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

// File: contracts/SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/MultiVesting.sol

pragma solidity ^0.5.12;




contract MultiVesting is Ownable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Vesting {
        uint256 startedAt; // Timestamp in seconds
        uint256 totalAmount; // Vested amount PMA in PMA
        uint256 releasedAmount; // Amount that beneficiary withdraw
    }

    // ===============================================================================================================
    // Constants
    // ===============================================================================================================
    uint256 public STEPS_AMOUNT = 12; // 25 steps, each step unlock 4% of funds after 30 days

    // ===============================================================================================================
    // Members
    // ===============================================================================================================
    uint256 public totalVestedAmount;
    uint256 public totalReleasedAmount;
    IERC20 public token;

    // Beneficiary address -> Array of Vesting params
    mapping(address => Vesting[]) vestingMap;

    // ===============================================================================================================
    // Constructor
    // ===============================================================================================================
    /// @notice Contract constructor - sets the token address that the contract facilitates.
    /// @param _token - ERC20 token address.
    constructor(IERC20 _token) public {
        token = _token;
    }

    /// @notice Creates vesting for beneficiary, with a given amount of tokens to allocate.
    /// The allocation will start when the method is called (now).
    /// @param _beneficiary - address of beneficiary.
    /// @param _amount - amount of tokens to allocate
    function addVestingFromNow(address _beneficiary, uint256 _amount) external onlyOwner {
        addVesting(_beneficiary, _amount, now);
    }

    /// @notice Creates vesting for beneficiary, with a given amount of funds to allocate,
    /// and timestamp of the allocation.
    /// @param _beneficiary - address of beneficiary.
    /// @param _amount - amount of tokens to allocate
    /// @param _startedAt - timestamp (in seconds) when the allocation should start
    function addVesting(address _beneficiary, uint256 _amount, uint256 _startedAt) public onlyOwner {
        require(_startedAt >= now, "TIMESTAMP_CANNOT_BE_IN_THE_PAST");
        require(_startedAt <= (now + 5 minutes), "TIMESTAMP_CANNOT_BE_MORE_THAN_A_180_DAYS_IN_FUTURE");
        require(_amount >= STEPS_AMOUNT, "VESTING_AMOUNT_TO_LOW");
        uint256 debt = totalVestedAmount.sub(totalReleasedAmount);
        uint256 available = token.balanceOf(address(this)).sub(debt);

        require(available >= _amount, "DON_T_HAVE_ENOUGH_PMA");

        Vesting memory v = Vesting({
            startedAt : _startedAt,
            totalAmount : _amount,
            releasedAmount : 0
            });

        vestingMap[_beneficiary].push(v);
        totalVestedAmount = totalVestedAmount.add(_amount);
    }

    /// @notice Method that allows a beneficiary to withdraw their allocated funds for a specific vesting ID.
    /// @param _vestingId - The ID of the vesting the beneficiary can withdraw their funds for.
    function withdraw(uint256 _vestingId) external {
        uint256 amount = getAvailableAmount(msg.sender, _vestingId);
        require(amount > 0, "DON_T_HAVE_RELEASED_TOKENS");

        // Increased released amount in in mapping
        vestingMap[msg.sender][_vestingId].releasedAmount
        = vestingMap[msg.sender][_vestingId].releasedAmount.add(amount);

        // Increased total released in contract
        totalReleasedAmount = totalReleasedAmount.add(amount);
        token.safeTransfer(msg.sender, amount);
    }

    /// @notice Method that allows a beneficiary to withdraw all their allocated funds.
    function withdrawAllAvailable() external {
        uint256 aggregatedAmount = 0;

        uint256 maxId = vestingMap[msg.sender].length;
        for (uint vestingId = 0; vestingId < maxId; vestingId++) {

            uint256 availableInSingleVesting = getAvailableAmount(msg.sender, vestingId);
            aggregatedAmount = aggregatedAmount.add(availableInSingleVesting);

            // Update released amount in specific vesting
            vestingMap[msg.sender][vestingId].releasedAmount
            = vestingMap[msg.sender][vestingId].releasedAmount.add(availableInSingleVesting);
        }

        // Increase released amount
        totalReleasedAmount = totalReleasedAmount.add(aggregatedAmount);

        // Transfer
        token.safeTransfer(msg.sender, aggregatedAmount);
    }

    /// @notice Method that allows the owner to withdraw unallocated funds to a specific address
    /// @param _receiver - address where the funds will be send
    function withdrawUnallocatedFunds(address _receiver) external onlyOwner {
        uint256 amount = getUnallocatedFundsAmount();
        require(amount > 0, "DON_T_HAVE_UNALLOCATED_TOKENS");
        token.safeTransfer(_receiver, amount);
    }
    
    
    function setSteps(uint256 steps)public onlyOwner{
        STEPS_AMOUNT = steps;
    }
    
    function setTokenAdd(IERC20 tokenadd)public onlyOwner{
        token = tokenadd;
    }

    // ===============================================================================================================
    // Getters
    // ===============================================================================================================

    /// @notice Returns smallest unused VestingId (unique per beneficiary).
    /// The next vesting ID can be used by the benficiary to see how many vestings / allocations has.
    /// @param _beneficiary - address of the beneficiary to return the next vesting ID
    function getNextVestingId(address _beneficiary) public view returns (uint256) {
        return vestingMap[_beneficiary].length;
    }

    /// @notice Returns amount of funds that beneficiary can withdraw using all vesting records of given beneficiary address
    /// @param _beneficiary - address of the beneficiary
    function getAvailableAmountAggregated(address _beneficiary) public view returns (uint256) {
        uint256 available = 0;
        uint256 maxId = vestingMap[_beneficiary].length;
        //
        for (uint vestingId = 0; vestingId < maxId; vestingId++) {

            // Optimization for gas saving in case vesting were already released
            if (vestingMap[_beneficiary][vestingId].totalAmount == vestingMap[_beneficiary][vestingId].releasedAmount) {
                continue;
            }

            available = available.add(
                getAvailableAmount(_beneficiary, vestingId)
            );
        }
        return available;
    }

    /// @notice Returns amount of funds that beneficiary can withdraw, vestingId should be specified (default is 0)
    /// @param _beneficiary - address of the beneficiary
    /// @param _vestingId - the ID of the vesting (default is 0)
    function getAvailableAmount(address _beneficiary, uint256 _vestingId) public view returns (uint256) {
        return getAvailableAmountAtTimestamp(_beneficiary, _vestingId, now);
    }

    /// @notice Returns amount of funds that beneficiary will be able to withdraw at the given timestamp per vesting ID (default is 0).
    /// @param _beneficiary - address of the beneficiary
    /// @param _vestingId - the ID of the vesting (default is 0)
    /// @param _timestamp - Timestamp (in seconds) on which the beneficiary wants to check the withdrawable amount.
    function getAvailableAmountAtTimestamp(address _beneficiary, uint256 _vestingId, uint256 _timestamp) public view returns (uint256) {
        if (_vestingId >= vestingMap[_beneficiary].length) {
            return 0;
        }

        Vesting memory vesting = vestingMap[_beneficiary][_vestingId];

        uint256 rewardPerMonth = vesting.totalAmount.div(STEPS_AMOUNT);

        // 25 Month (%4 per month)
        uint256 monthPassed = _timestamp
            .sub(vesting.startedAt)
            .div(5 minutes); // We say that 1 month is always 30 days

        uint256 alreadyReleased = vesting.releasedAmount;

        // In 25 month 100% of tokens is already released:
        if (monthPassed >= STEPS_AMOUNT) {
            return vesting.totalAmount.sub(alreadyReleased);
        }

        return rewardPerMonth.mul(monthPassed).sub(alreadyReleased);
    }

    /// @notice Returns amount of unallocated funds that contract owner can withdraw
    function getUnallocatedFundsAmount() public view returns (uint256) {
        uint256 debt = totalVestedAmount.sub(totalReleasedAmount);
        uint256 available = token.balanceOf(address(this)).sub(debt);
        return available;
    }
}