// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


// 
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

// 
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

// 
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

// 
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

// 
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

// 
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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// 
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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// 
// Using these will cause _mint to be not found in Pool
// Using these seems to work
//import "./interfaces/IERC20.sol";
//import "./libraries/SafeERC20.sol";
contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakingToken;
    uint256 public startTime;
    // Developer fund
    uint256 public devFund;
    uint256 public devCount;
    mapping(uint256 => address) public devIDs;
    mapping(address => uint256) public devAllocations;
    // Staking balances
    uint256 public _totalSupply;
    mapping(address => uint256) public _balances;
    uint256 public _totalSupplyAccounting;
    mapping(address => uint256) public _balancesAccounting;

    constructor(uint256 _startTime) public {
        startTime = _startTime;

        devCount = 8;
        // Set dev fund allocation percentages
        devIDs[0] = 0xAd1CC47416C2c8C9a1B91BFf41Ea627718e80074;
        devAllocations[0xAd1CC47416C2c8C9a1B91BFf41Ea627718e80074] = 16;
        devIDs[1] = 0x8EDac59Ea229a52380D181498C5901a764ad1c40;
        devAllocations[0x8EDac59Ea229a52380D181498C5901a764ad1c40] = 16;
        devIDs[2] = 0xeBc3992D9a2ef845224F057637da84927FDACf95;
        devAllocations[0xeBc3992D9a2ef845224F057637da84927FDACf95] = 9;
        devIDs[3] = 0x59Cc100B954f609c21dA917d6d4A1bD1e50dFE93;
        devAllocations[0x59Cc100B954f609c21dA917d6d4A1bD1e50dFE93] = 8;
        devIDs[4] = 0x416C75cFE45b951a411B23FC55904aeC383FFd6F;
        devAllocations[0x416C75cFE45b951a411B23FC55904aeC383FFd6F] = 9;
        devIDs[5] = 0xA103D9a54E0dE29886b077654e01D15F80Dad20c;
        devAllocations[0xA103D9a54E0dE29886b077654e01D15F80Dad20c] = 16;
        devIDs[6] = 0x73b6f43c9c86E7746a582EBBcB918Ab1Ad49bBD8;
        devAllocations[0x73b6f43c9c86E7746a582EBBcB918Ab1Ad49bBD8] = 16;
        devIDs[7] = 0x1A345cb683B3CB6F62F5A882022849eeAF47DFB3;
        devAllocations[0x1A345cb683B3CB6F62F5A882022849eeAF47DFB3] = 10;
    }

    // Returns the total staked tokens within the contract
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // Returns staking balance of the account
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    // Set the staking token for the contract
    function setStakingToken(address stakingTokenAddress) internal {
        stakingToken = IERC20(stakingTokenAddress);
    }

    // Stake funds into the pool
    function stake(uint256 amount) public virtual {
        // Calculate tax and after-tax amount
        uint256 taxRate = calculateTax();
        uint256 taxedAmount = amount.mul(taxRate).div(100);
        uint256 stakedAmount = amount.sub(taxedAmount);

        // Increment sender's balances and total supply
        _balances[msg.sender] = _balances[msg.sender].add(stakedAmount);
        _totalSupply = _totalSupply.add(stakedAmount);
        // Increment dev fund by tax
        devFund = devFund.add(taxedAmount);

        // Transfer funds
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    // Withdraw staked funds from the pool
    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
    }

    // Distributes the dev fund to the developer addresses, callable by anyone
    function distributeDevFund() public virtual {
        // Reset dev fund to 0 before distributing any funds
        uint256 totalDistributionAmount = devFund;
        devFund = 0;
        // Distribute dev fund according to percentages
        for (uint256 i = 0; i < devCount; i++) {
            uint256 devPercentage = devAllocations[devIDs[i]];
            uint256 allocation = totalDistributionAmount.mul(devPercentage).div(
                100
            );
            if (allocation > 0) {
                stakingToken.safeTransfer(devIDs[i], allocation);
            }
        }
    }

    // Return the tax amount according to current block time
    function calculateTax() public view returns (uint256) {
        // Pre-pool start time = 3% tax
        if (block.timestamp < startTime) {
            return 3;
            // 0-60 minutes after pool start time = 5% tax
        } else if (
            block.timestamp.sub(startTime) >= 0 minutes &&
            block.timestamp.sub(startTime) <= 60 minutes
        ) {
            return 5;
            // 60-90 minutes after pool start time = 3% tax
        } else if (
            block.timestamp.sub(startTime) > 60 minutes &&
            block.timestamp.sub(startTime) <= 90 minutes
        ) {
            return 3;
            // 90+ minutes after pool start time = 1% tax
        } else if (block.timestamp.sub(startTime) > 90 minutes) {
            return 1;
        }
    }
}

// 
/*
 * Copyright (c) 2020 Synthetix
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject tog the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */
/*
    ______                                          __    __
   / ________ __________ ___  ____ _____ ____  ____/ ____/ ____  ____
  / /_  / __ `/ ___/ __ `__ \/ __ `/ __ `/ _ \/ __  / __  / __ \/ __ \
 / __/ / /_/ / /  / / / / / / /_/ / /_/ /  __/ /_/ / /_/ / /_/ / / / /
/_/    \__,_/_/  /_/ /_/ /_/\__,_/\__, /\___/\__,_/\__,_/\____/_/ /_/
                                 /____/

*   FARMAFINANCE: MintablePool.sol
*   https://farma.finance
*   telegram: TBA
*/
contract GrowFarma is LPTokenWrapper, Ownable {
    using SafeERC20 for IERC20;
    IERC20 public rewardToken;
    IERC20 public multiplierToken;

    uint256 public DURATION;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public deployedTime;
    uint256 public multiplierTokenDevFund;

    uint256 public constant boostLevelOneCost = 250000000000000000;
    uint256 public constant boostLevelTwoCost = 500000000000000000;
    uint256 public constant boostLevelThreeCost = 1 * 1e18;
    uint256 public constant boostLevelFourCost = 2 * 1e18;

    uint256 public constant FivePercentBonus = 50000000000000000;
    uint256 public constant TwentyPercentBonus = 200000000000000000;
    uint256 public constant FourtyPercentBonus = 400000000000000000;
    uint256 public constant HundredPercentBonus = 1000000000000000000;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public spentMultiplierTokens;
    mapping(address => uint256) public boostLevel;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Boost(uint256 level);

    constructor(
        address _stakingToken,
        address _rewardToken,
        address _multiplierToken,
        uint256 _startTime,
        uint256 _duration
    ) public LPTokenWrapper(_startTime) {
        setStakingToken(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        multiplierToken = IERC20(_multiplierToken);
        deployedTime = block.timestamp;
        DURATION = _duration;
    }

    function setOwner(address _newOwner) external onlyOwner {
        super.transferOwnership(_newOwner);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    // Returns the current rate of rewards per token (doh)
    function rewardPerToken() public view returns (uint256) {
        // Do not distribute rewards before games begin
        if (block.timestamp < startTime) {
            return 0;
        }
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        // Effective total supply takes into account all the multipliers bought.
        uint256 effectiveTotalSupply = _totalSupply.add(_totalSupplyAccounting);
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(effectiveTotalSupply)
            );
    }

    // Returns the current reward tokens that the user can claim.
    function earned(address account) public view returns (uint256) {
        // Each user has it's own effective balance which is just the staked balance multiplied by boost level multiplier.
        uint256 effectiveBalance = _balances[account].add(
            _balancesAccounting[account]
        );
        return
            effectiveBalance
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    // Staking function which updates the user balances in the parent contract
    function stake(uint256 amount) public override {
        updateReward(msg.sender);
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);

        // Users that have bought multipliers will have an extra balance added to their stake according to the boost multiplier.
        if (boostLevel[msg.sender] > 0) {
            uint256 prevBalancesAccounting = _balancesAccounting[msg.sender];
            // Calculate and set user's new accounting balance
            uint256 accTotalMultiplier = getTotalMultiplier(msg.sender);
            uint256 newBalancesAccounting = _balances[msg.sender]
                .mul(accTotalMultiplier)
                .div(1e18)
                .sub(_balances[msg.sender]);
            _balancesAccounting[msg.sender] = newBalancesAccounting;
            // Adjust total accounting supply accordingly
            uint256 diffBalancesAccounting = newBalancesAccounting.sub(
                prevBalancesAccounting
            );
            _totalSupplyAccounting = _totalSupplyAccounting.add(
                diffBalancesAccounting
            );
        }

        emit Staked(msg.sender, amount);
    }

    // Withdraw function to remove stake from the pool
    function withdraw(uint256 amount) public override {
        require(amount > 0, "Cannot withdraw 0");
        updateReward(msg.sender);
        super.withdraw(amount);

        // Users who have bought multipliers will have their accounting balances readjusted.
        if (boostLevel[msg.sender] > 0) {
            // The previous extra balance user had
            uint256 prevBalancesAccounting = _balancesAccounting[msg.sender];
            // Calculate and set user's new accounting balance
            uint256 accTotalMultiplier = getTotalMultiplier(msg.sender);
            uint256 newBalancesAccounting = _balances[msg.sender]
                .mul(accTotalMultiplier)
                .div(1e18)
                .sub(_balances[msg.sender]);
            _balancesAccounting[msg.sender] = newBalancesAccounting;
            // Subtract the withdrawn amount from the accounting balance
            // If all tokens are withdrawn the balance will be 0.
            uint256 diffBalancesAccounting = prevBalancesAccounting.sub(
                newBalancesAccounting
            );
            _totalSupplyAccounting = _totalSupplyAccounting.sub(
                diffBalancesAccounting
            );
        }

        emit Withdrawn(msg.sender, amount);
    }

    // Get the earned rewards and withdraw staked tokens
    function exit() external {
        getReward();
        withdraw(balanceOf(msg.sender));
    }

    // Sends out the reward tokens to the user.
    function getReward() public {
        updateReward(msg.sender);
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    // Called to start the pool with the reward amount it should distribute
    // The reward period will be the duration of the pool.
    function notifyRewardAmount(uint256 reward) external onlyOwner {
        updateRewardPerTokenStored();
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }

    // Notify the reward amount without updating time;
    function notifyRewardAmountWithoutUpdateTime(uint256 reward)
        external
        onlyOwner
    {
        updateRewardPerTokenStored();
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        emit RewardAdded(reward);
    }

    // Returns the users current multiplier level
    function getLevel(address account) external view returns (uint256) {
        return boostLevel[account];
    }

    // Return the amount spent on multipliers, used for subtracting for future purchases.
    function getSpent(address account) external view returns (uint256) {
        return spentMultiplierTokens[account];
    }

    // Calculate the cost for purchasing a boost.
    function calculateCost(uint256 level) public pure returns (uint256) {
        if (level == 1) {
            return boostLevelOneCost;
        } else if (level == 2) {
            return boostLevelTwoCost;
        } else if (level == 3) {
            return boostLevelThreeCost;
        } else if (level == 4) {
            return boostLevelFourCost;
        }
    }

    // Purchase a multiplier level, same level cannot be purchased twice.
    function purchase(uint256 level) external {
        require(
            boostLevel[msg.sender] <= level,
            "Cannot downgrade level or same level"
        );
        uint256 cost = calculateCost(level);
        // Cost will be reduced by the amount already spent on multipliers.
        uint256 finalCost = cost.sub(spentMultiplierTokens[msg.sender]);

        // Transfer tokens to the contract
        multiplierToken.safeTransferFrom(msg.sender, address(this), finalCost);

        // Update balances and level
        multiplierTokenDevFund = multiplierTokenDevFund.add(finalCost);
        spentMultiplierTokens[msg.sender] = spentMultiplierTokens[msg.sender]
            .add(finalCost);
        boostLevel[msg.sender] = level;

        // If user has staked balances, then set their new accounting balance
        if (_balances[msg.sender] > 0) {
            // Get the previous accounting balance
            uint256 prevBalancesAccounting = _balancesAccounting[msg.sender];
            // Get the new multiplier
            uint256 accTotalMultiplier = getTotalMultiplier(msg.sender);
            // Calculate new accounting  balance
            uint256 newBalancesAccounting = _balances[msg.sender]
                .mul(accTotalMultiplier)
                .div(1e18)
                .sub(_balances[msg.sender]);
            // Set the accounting balance
            _balancesAccounting[msg.sender] = newBalancesAccounting;
            // Get the difference for adjusting the total accounting balance
            uint256 diffBalancesAccounting = newBalancesAccounting.sub(
                prevBalancesAccounting
            );
            // Adjust the global accounting balance.
            _totalSupplyAccounting = _totalSupplyAccounting.add(
                diffBalancesAccounting
            );
        }

        emit Boost(level);
    }

    // Returns the multiplier for user.
    function getTotalMultiplier(address account) public view returns (uint256) {
        uint256 boostMultiplier = 0;
        if (boostLevel[account] == 1) {
            boostMultiplier = FivePercentBonus;
        } else if (boostLevel[account] == 2) {
            boostMultiplier = TwentyPercentBonus;
        } else if (boostLevel[account] == 3) {
            boostMultiplier = FourtyPercentBonus;
        } else if (boostLevel[account] == 4) {
            boostMultiplier = HundredPercentBonus;
        }
        return boostMultiplier.add(1 * 10**18);
    }

    // Distributes the dev fund for accounts
    function distributeDevFund() public override {
        uint256 totalMulitplierDistributionAmount = multiplierTokenDevFund;
        multiplierTokenDevFund = 0;
        // Distribute multiplier dev fund according to percentages
        for (uint256 i = 0; i < devCount; i++) {
            uint256 devPercentage = devAllocations[devIDs[i]];
            uint256 allocation = totalMulitplierDistributionAmount
                .mul(devPercentage)
                .div(100);
            if (allocation > 0) {
                multiplierToken.safeTransfer(devIDs[i], allocation);
            }
        }
        // Distribute the staking token rewards
        super.distributeDevFund();
    }

    // Ejects any remaining tokens from the pool.
    // Callable only after the pool has started and the pools reward distribution period has finished.
    function eject() external onlyOwner {
        require(
            startTime < block.timestamp && block.timestamp >= periodFinish,
            "Cannot eject before period finishes or pool has started"
        );
        uint256 currBalance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(msg.sender, currBalance);
    }

    // Forcefully retire a pool
    // Only sets the period finish to 0
    // This will prevent more rewards from being disbursed
    function kill() external onlyOwner {
        periodFinish = block.timestamp;
    }

    function updateRewardPerTokenStored() internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
    }

    function updateReward(address account) internal {
        updateRewardPerTokenStored();
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
}