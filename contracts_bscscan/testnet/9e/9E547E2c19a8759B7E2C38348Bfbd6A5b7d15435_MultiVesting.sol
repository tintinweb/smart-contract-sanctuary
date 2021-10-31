/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

pragma solidity ^0.5.0;

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
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: node_modules\@openzeppelin\contracts\math\SafeMath.sol

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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: node_modules\@openzeppelin\contracts\utils\Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol

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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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


pragma solidity ^0.5.12;



contract MultiVesting is Ownable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Vesting {
        uint256 startedAt; // Timestamp in seconds
        uint256 totalAmount; // Vested amount token
        uint256 releasedAmount; // Amount that beneficiary withdraw
    }
    
   // mapping(address => bool) public permittedContract;
    address public permittedContract;

    // ===============================================================================================================
    // Constants
    // ===============================================================================================================
    uint256 public constant STEPS_AMOUNT = 100; // 100 steps, each step unlock 1% of funds after 1 days

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
    
    function allowContract(address _addressContract) public onlyOwner {
       // permittedContract[_addressContract] = true;
        permittedContract = _addressContract;
    }
    
    function disallowContract(address _addressContract) public onlyOwner {
        //permittedContract[_addressContract] = false;
        permittedContract = _addressContract;
    }

    /// @notice Creates vesting for beneficiary, with a given amount of funds to allocate,
    /// and timestamp of the allocation.
    /// @param _beneficiary - address of beneficiary.
    /// @param _amount - amount of tokens to allocate
    /// @param _startedAt - timestamp (in seconds) when the allocation should start
    function addVesting(address _beneficiary, uint256 _amount, uint256 _startedAt) public {
        require(msg.sender == owner() || msg.sender == permittedContract);
     //   if( msg.sender == owner() || msg.sender == permittedContract){
        require(_startedAt >= now, "TIMESTAMP_CANNOT_BE_IN_THE_PAST");
        require(_startedAt <= (now + 180 days), "TIMESTAMP_CANNOT_BE_MORE_THAN_A_180_DAYS_IN_FUTURE");
        require(_amount >= STEPS_AMOUNT, "VESTING_AMOUNT_TO_LOW");
        uint256 debt = totalVestedAmount.sub(totalReleasedAmount);
        uint256 available = token.balanceOf(address(this)).sub(debt);

        require(available >= _amount, "DON_T_HAVE_ENOUGH_TOKEN");

        Vesting memory v = Vesting({
            startedAt : _startedAt,
            totalAmount : _amount,
            releasedAmount : 0
            });

        vestingMap[_beneficiary].push(v);
        totalVestedAmount = totalVestedAmount.add(_amount);
      //  }
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

    function getStartDate(address _beneficiary, uint256 _vestingId) public view returns (uint256) {
        Vesting memory vesting = vestingMap[_beneficiary][_vestingId];
        return vesting.startedAt;
    }
    
    function getTotalAmount(address _beneficiary, uint256 _vestingId) public view returns (uint256) {
        Vesting memory vesting = vestingMap[_beneficiary][_vestingId];
        return vesting.totalAmount;
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

        // 100 days (%1 per month)
        uint256 monthPassed = _timestamp
            .sub(vesting.startedAt)
            .div(1 days); 

        uint256 alreadyReleased = vesting.releasedAmount;

        // In 100 days 100% of tokens is already released:
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