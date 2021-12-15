//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './utils/TokenTimelock.sol';

contract Vesting is Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //TOKEN
    bool private _tokenAlreadeSetted = false;
    IERC20 private _token;
    uint private _totalSupply = 0;

    //PORTIONS
    uint256 private _platform_portion = 0; // 50
    uint256 private _ifo_portion = 0; // 20 
    uint256 private _pool_portion = 0; // 4
    uint256 private _boost_portion = 0; // 10
    uint256 private _developers_portion = 0; // 10
    uint256 private _investors_portion = 0; // 3
    uint256 private _partners_portion = 0; // 3
    
    //ADDRESSES
    address private _platform_address;
    uint256 public platform_tokens_permonth = 0;
    uint256 public platform_vesting_remaining = 0;
    TokenTimelock public platform_timelock;
    uint256 public platform_timelock_date = 0;
    bool private _platform_vested = false;

    TokenTimelock public boost_timelock;
    bool private _boost_vested = false;

    address private _developers_address;
    uint256 private _developers_tokens_permonth = 0;
    uint256 public developers_vesting_remaining = 0;
    TokenTimelock public developers_timelock;
    uint256 public developers_timelock_date = 0;
    bool private _developers_vested = false;

    address private _investors_address;
    uint256 private _investors_tokens_per_release = 0;
    uint256 public investors_vesting_remaining = 0;
    TokenTimelock public investors_timelock;
    bool private _investors_vested = false;

    address private _partners_address;
    uint256 private _partners_tokens_per_release = 0;
    uint256 public partners_vesting_remaining = 0;
    TokenTimelock public partners_timelock;
    bool private _partners_vested = false;

    //EVENTS
    event vested(string from, address previousOwner, uint amount, uint timestamp);
    event started(uint timestamp);

    /**
     * @dev Creates a vesting contract with the portion for each entity
     * @param platform portion
     * @param ifo portion
     * @param pool portion
     * @param boost portion
     * @param developers portion
     * @param investors portion
     * @param partners portion
     */
    constructor(uint256 platform, uint256 ifo, uint256 pool, uint256 boost, uint256 developers, uint256 investors, uint256 partners){

        require(platform+ifo+pool+boost+developers+investors+partners == 100, "Not 100% distribution");

        //PORCENTAGES
        _platform_portion = platform;
        _ifo_portion = ifo;
        _pool_portion = pool;
        _boost_portion = boost;
        _developers_portion = developers;
        _investors_portion = investors;
        _partners_portion = partners;

    }

    /**
     * @dev Starts the vesting process
     * @param token the address of the BEP20 tokens
     * @param platform_address the receiver address of the PLATFORM portion
     * @param platform_months the amount of time in months that the vesting for the PLATFORM will last
     * @param ifo_address the receiver address of the IFO portion
     * @param pool_address the receiver address of the POOL portion
     * @param developers_address the receiver address of the DEVELOPERS portion
     * @param developers_daysLocked the amount of time in months that the vesting for the DEVELOPERS will be locked
     * @param developers_months the amount of time in months that the vesting for the DEVELOPERS will last
     * @param investor_address the receiver address of the INVESTOR portion
     * @param partner_address the receiver address of the PARTNER portion
     */
    function startVesting(address token, address platform_address, uint platform_months, address ifo_address, address pool_address, address developers_address, uint developers_daysLocked, uint developers_months, address investor_address, address partner_address) public onlyOwner{
        require(!_tokenAlreadeSetted, "Token address already setted");
        _tokenAlreadeSetted = true;
        _token = IERC20(token);
        _totalSupply = _token.totalSupply();

        //PLATFORM VESTING
        startPlatformVesting(platform_address, platform_months);

        //IFO VESTING
        _token.transfer(ifo_address, _totalSupply.mul(_ifo_portion).div(100));

        //POOL VESTING
        _token.transfer(pool_address, _totalSupply.mul(_pool_portion).div(100));

        //DEVELOPERS VESTING
        startDevelopVesting(developers_address, developers_daysLocked, developers_months);

        //INVESTOR VESTING
        startInvestorsVesting(investor_address);

        //PARTNER VESTING
        startPartnersVesting(partner_address);

        emit started(block.timestamp);
    }

    /**
     * @dev Starts the vesting process for the PLATFORM
     * @param new_platform_address the receiver address of the PLATFORM portion
     * @param months the amount of time in months that the vesting for the PLATFORM will last
     */
    function startPlatformVesting(address new_platform_address, uint months) private {
        require(!_platform_vested, "Platform is already vesting");
        _platform_vested = true;
        _platform_address = new_platform_address;
        platform_tokens_permonth = _totalSupply.mul(_platform_portion).div(100).div(months);
        platform_vesting_remaining = months;
        platform_timelock_date = block.timestamp + 30 days;
        platform_timelock = new TokenTimelock(_token, _platform_address, platform_timelock_date);
        _token.transfer(address(platform_timelock), platform_tokens_permonth);
    }

    /**
     * @dev Release the vested tokens for PLATFORM
     */
    function releasePlatformVesting() public {
        require(msg.sender == _platform_address, "You are not the platform");
        platform_timelock.release();
        platform_vesting_remaining -= 1;
        if(platform_vesting_remaining > 0){
            platform_timelock_date += 30 days;
            platform_timelock = new TokenTimelock(_token, _platform_address, platform_timelock_date);
            _token.transfer(address(platform_timelock), platform_tokens_permonth);
        }
        emit vested("Platform", _platform_address, platform_tokens_permonth, block.timestamp);
    }

    /**
     * @dev Starts the vesting process for the BOOST
     * @param toAddress the receiver address of the BOOST portion
     */
    function startBoostVesting(address toAddress) public onlyOwner{
        require(!_boost_vested, "Boost is already vesting");
        _boost_vested = true;
        
        boost_timelock = new TokenTimelock(_token, toAddress, block.timestamp + 7 days);
        _token.transfer(address(boost_timelock), _totalSupply.mul(_boost_portion).div(100));
    }

    /**
     * @dev Release the vested tokens for BOOST
     */
    function releaseBoostVesting() public {
        uint balance = address(boost_timelock).balance;
        boost_timelock.release();
        emit vested("Boost", boost_timelock.beneficiary(), balance, block.timestamp);
    }

    /**
     * @dev Starts the vesting process for the DEVELOPERS
     * @param new_developers_address the receiver address of the DEVELOPERS portion
     * @param daysLocked the amount of time in days that the vesting for the DEVELOPERS will be locked
     * @param months the amount of time in months that the vesting for the DEVELOPERS will last
     */
    function startDevelopVesting(address new_developers_address, uint daysLocked, uint months) private {
        require(!_developers_vested, "Developers is already vesting");
        _developers_vested = true;
        _developers_address = new_developers_address;
        _developers_tokens_permonth = _totalSupply.mul(_developers_portion).div(100).div(months);
        developers_vesting_remaining = months;
        developers_timelock_date = block.timestamp + (daysLocked * 1 days);
        developers_timelock = new TokenTimelock(_token, _developers_address, developers_timelock_date);
        _token.transfer(address(developers_timelock), _developers_tokens_permonth);
    }

    /**
     * @dev Release the vested tokens for DEVELOPERS
     */
    function releaseDevelopVesting() public {
        developers_timelock.release();
        developers_vesting_remaining -= 1;
        if(developers_vesting_remaining > 0){
            developers_timelock_date += 30 days;
            developers_timelock = new TokenTimelock(_token, _developers_address, developers_timelock_date);
            _token.transfer(address(developers_timelock), _developers_tokens_permonth);
        }
        emit vested("Developer", _developers_address, _developers_tokens_permonth, block.timestamp);
    }

    /**
     * @dev Starts the vesting process for the INVESTOR
     * @param toAddress the receiver address of the INVESTOR portion
     */
    function startInvestorsVesting(address toAddress) private {
        require(!_investors_vested, "Investors is already vesting");
        _investors_vested = true;

        _investors_address = toAddress;
        _investors_tokens_per_release = _totalSupply.mul(_investors_portion).div(100).div(2);
        investors_vesting_remaining = 2;
        
        investors_timelock = new TokenTimelock(_token, toAddress, block.timestamp + 90 days);
        _token.transfer(address(investors_timelock), _investors_tokens_per_release);
    }

    /**
     * @dev Release the vested tokens for INVESTOR
     */
    function releaseInvestorsVesting() public {        
        investors_timelock.release();

        investors_vesting_remaining -= 1;
        if(investors_vesting_remaining > 0){
            investors_timelock = new TokenTimelock(_token, _investors_address, block.timestamp + 90 days);
            _token.transfer(address(investors_timelock), _investors_tokens_per_release);
        }
        
        emit vested("Investors", investors_timelock.beneficiary(), _investors_tokens_per_release, block.timestamp);
    }

    /**
     * @dev Starts the vesting process for the PARTNER
     * @param toAddress the receiver address of the PARTNER portion
     */
    function startPartnersVesting(address toAddress) private {
        require(!_partners_vested, "Partners is already vesting");
        _partners_vested = true;

        _partners_address = toAddress;
        _partners_tokens_per_release = _totalSupply.mul(_partners_portion).div(100).div(2);
        partners_vesting_remaining = 2;
        
        partners_timelock = new TokenTimelock(_token, toAddress, block.timestamp + 90 days);
        _token.transfer(address(partners_timelock), _partners_tokens_per_release);
    }

    /**
     * @dev Release the vested tokens for PARTNER
     */
    function releasePartnersVesting() public {
        partners_timelock.release();

        partners_vesting_remaining -= 1;
        if(partners_vesting_remaining > 0){
            partners_timelock = new TokenTimelock(_token, _partners_address, block.timestamp + 90 days);
            _token.transfer(address(partners_timelock), _partners_tokens_per_release);
        }
        
        emit vested("Investors", partners_timelock.beneficiary(), _partners_tokens_per_release, block.timestamp);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 immutable private _token;

    // beneficiary of tokens after they are released
    address immutable private _beneficiary;

    // timestamp when token release is enabled
    uint256 immutable private _releaseTime;

    constructor (IERC20 token_, address beneficiary_, uint256 releaseTime_) {
        // solhint-disable-next-line not-rely-on-time
        // require(releaseTime_ > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token_;
        _beneficiary = beneficiary_;
        _releaseTime = releaseTime_;
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view virtual returns (uint256) {
        return _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= releaseTime(), "TokenTimelock: current time is before release time");

        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        token().safeTransfer(beneficiary(), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}