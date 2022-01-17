// https://eips.ethereum.org/EIPS/eip-20

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import './Burnable.sol';
import './Mintable.sol';
import './HodlRewardsDistributor.sol';

contract RocketToken is Ownable, Burnable {
    using SafeMath for uint256;

    struct Tax {
        uint8 burn;
        uint8 hodl;
    }

    uint256 constant BASE = 10 ** 18;
    uint256 constant TOTAL_SUPPLY = 1_000_000_000 * BASE;

    mapping(address => bool) isLP;

    bool public taxEnabled = true;
    mapping(address => bool) public whitelisted;

    Tax public buyTax = Tax(1,1);
    Tax public sellTax = Tax(1,1);
    Tax public transferTax = Tax(1,1);

    HODLRewardsDistributor public distributor;
    uint256 public minimumShareForRewards;
    bool public autoBatchProcess = true;
    uint256 public processingGasLimit = 500000;

    uint256 totalBurned;

    constructor(
        string memory name_,
        string memory symbol_,
        address owner_
    ) ERC20(name_ , symbol_){
        _mint(owner_, TOTAL_SUPPLY);
        addBurner(owner_);
        _transferOwnership(owner_);
        distributor = new HODLRewardsDistributor();
        distributor.excludedFromRewards(owner_);
        whitelisted[owner_] = true;
        whitelisted[address(distributor)] = true;
    }

    /** Transfer */
    function transfer(
        address to_,
        uint256 amount_
    ) public virtual override returns (bool) {
        return _customTransfer(_msgSender(), to_, amount_);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) public virtual override returns (bool) {
        // check allowance
        require(allowance(from_, _msgSender()) >= amount_, "> allowance");
        bool success = _customTransfer(from_, to_, amount_);
        approve(from_, allowance(from_, _msgSender()).sub(amount_));
        return success;
    }

    function _customTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal returns(bool) {
        if (whitelisted[from_]) {
            _transfer(from_, to_, amount_);
        } else {
            uint256 netTransfer = amount_;

            if (taxEnabled) {
                Tax memory currentAppliedTax = isLP[from_] ? buyTax : isLP[to_] ? sellTax : transferTax;
                
                uint256 burnAmount = amount_.mul(currentAppliedTax.burn).div(100);
                uint hodlAmount = amount_.mul(currentAppliedTax.hodl).div(100);
                uint256 currentTax = burnAmount.add(hodlAmount);
                
                netTransfer = amount_.sub(currentTax);

                if(hodlAmount > 0){
                    _transfer(from_, address(distributor), hodlAmount);
                    distributor.depositRewardsByOwner(hodlAmount);
                }
                if(burnAmount > 0){ 
                    _burn(from_,burnAmount);
                    totalBurned += burnAmount;
                }
            }
            // transfer 
            _transfer(from_, to_, netTransfer);
        }
        return true;
    }

    function _afterTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override {
        super._afterTokenTransfer(from_,to_,amount_);
        if (address(distributor) != address(0)) {
            _updateShare(from_);
            _updateShare(to_);
            _massProcess();
        }
    }
    /** END transfer functions */

    /** TAX Functions */
    function enableTax(
        bool enable_
    ) external onlyOwner{
        taxEnabled = enable_;
    }

    function whitelist(
        address wallet_,
        bool isWHitelisted_
    ) external onlyOwner{
        whitelisted[wallet_] = isWHitelisted_;
    }

    function setBuyTax(
        uint8 burn_,
        uint8 hodl_
    ) external onlyOwner {
        buyTax = Tax(burn_,hodl_);
    }  

    function setSellTax(
        uint8 burn_,
        uint8 hodl_
    ) external onlyOwner{
        sellTax = Tax(burn_,hodl_);
    }  

    function setTransferTax(
        uint8 burn_,
        uint8 hodl_
    ) external onlyOwner{
        transferTax = Tax(burn_,hodl_);
    }
    /** End Tax Functions */


    /** Rewards destribution */
    function setMinimumShareForHodlRewards(
        uint256 minAmount_
    ) external onlyOwner{
        minimumShareForRewards = minAmount_;
    }

    function setAutoBatchProcess(
        bool enabled_
    ) external onlyOwner{
            autoBatchProcess = enabled_;
    }

    function setIncludedInRewards(
        address wallet_,
         bool included_ 
    ) external onlyOwner{
        if(included_)
            distributor.includeInRewards(wallet_);
        else
            distributor.excludeFromRewards(wallet_);
    }

    function setPeocessingGasLimit(
        uint256 maxAmount_
    ) external onlyOwner {
        processingGasLimit = maxAmount_;
    }



    /* */
    function setIsLPPair(
        address pairAddess_,
        bool isPair_
    ) external onlyOwner {
        isLP[pairAddess_] = isPair_;
    }

    /**
        prevents accidental renouncement of owner ship 
        can sill renounce if set explicitly to dead address
     */
    function renounceOwnership() public virtual override onlyOwner {}


    function _massProcess() internal {
        if(autoBatchProcess)
            distributor.batchProcessClaims(
                gasleft() > processingGasLimit ? processingGasLimit : gasleft().mul(80).div(100)
            );
    }



    function _updateShare(
        address wallet_
    ) internal {
        if (!distributor.excludedFromRewards(wallet_))
            distributor.setShare(wallet_, balanceOf(wallet_) > minimumShareForRewards ? balanceOf(wallet_) : 0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

pragma solidity ^0.8.4;

interface IMintable {

    /**
        @dev mints amount to account balance
        only if caller is allowed to mint
     */
    function mint(address account_,uint256 amount_) external;

    /**
        @dev adds allowedMinter to users who can mint 
        only owner can call this
     */
    function addminter(address allowedMinter) external;

    /**
        @dev removes MinterToBeRemoved from users who can mint 
        only owner can call this
     */
    function removeMinter(address MinterToBeRemoved) external;

    /**
        @dev checks if potentialBurner is a user who can mint 
     */
    function isMinter(address potentialMinter) external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IBurnable {

    /**
        @dev Burns amount from msg.sender balance
        only if balance allows to burn amount
        only caller is allowed to burn
     */
    function burn(uint256 amount) external;

    /**
        @dev adds allowedBurner to users who can burn 
        allowed users can only burn from their own balance
        only owner can call this
     */
    function addBurner(address allowedBurner) external;

    /**
        @dev removes BurnerToBeRemoved from users who can burn 
        allowed users can only burn from their own balance
        only owner can call this
     */
    function removeBurner(address BurnerToBeRemoved) external;

    /**
        @dev checks if potentialBurner is a user who can burn 
     */
    function isBurner(address potentialBurner) external view returns(bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct ShareHolder {
    uint256 shares;
    uint256 rewardDebt;
    uint256 claimed;
    uint256 pending;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import './interfaces/IMintable.sol';

abstract contract Mintable is Ownable, IMintable , ERC20 {
    mapping(address => bool) minters;
    
    modifier onlyMinters () {
        require(minters[_msgSender()], 'NOT_MINTER');
        _;
    }

    function mint(address account_,uint256 amount_) override external onlyMinters {
        _mint(account_, amount_);
    }  
    /**
        @dev adds allowedMinter to users who can mint 
        only owner can call this
     */
    function addminter(address allowedMinter) onlyOwner override public {
        minters[allowedMinter] = true;
    }

    /**
        @dev removes MinterToBeRemoved from users who can mint 
        only owner can call this
     */
    function removeMinter(address MinterToBeRemoved) onlyOwner override public{
        minters[MinterToBeRemoved] = false;
    }

    /**
        @dev checks if potentialBurner is a user who can mint 
     */
    function isMinter(address potentialMinter) external override view returns(bool){
        return minters[potentialMinter];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./data/ShareHolder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract HODLRewardsDistributor is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 immutable public rewardsToken;

    uint256 public accPerShare;   // Accumulated per share, times 1e36.
    uint256 public totalShares;   // total number of shares
    uint256 public totalClaimed;  // total amount claimed
    uint256 public totalRewardsDebt;  // total amount claimed

    // use getShare-holderInfo function to get this data
    mapping (address => ShareHolder) shareHolders;
    address[] public allShareHolders;
    mapping (address => uint256) indexOfShareHolders;

    uint256 private _lastProccessedIndex = 1;

    mapping (address => bool) public excludedFromRewards;

    // events
    event Claimed(address indexed claimer, uint256 indexed amount);
    event RewardsAdded(uint256 indexed amount);
    event ShareUpdated(address indexed shareHolder, uint256 indexed sharesAmount);
    event IncludedInRewards(address indexed shareHolder);
    event ExcludedFromRewards(address indexed shareHolder);

    modifier onlyIncluded (address shareHolderAddress_) {
        require(!excludedFromRewards[shareHolderAddress_],"HODLRewardsDistributor: excluded from rewards");
        _;
    }

    /**
        can be called by anyone, this function distributes the rewards received here
     */
    function depositRewards(uint256 amount_) external {
        uint256 balanceBefore = rewardsToken.balanceOf(address(this));
        rewardsToken.safeTransferFrom(_msgSender(),address(this),amount_);
        _updateGlobalShares(rewardsToken.balanceOf(address(this)).sub(balanceBefore));
    }

    /**
        only called by owner aka the token it self
     */
    function depositRewardsByOwner(uint256 amount_) external onlyOwner{
        _updateGlobalShares(amount_);
    }

    constructor (){
        rewardsToken = IERC20(msg.sender);
        excludedFromRewards[address(this)] = true;
    }

    /**
        retruns the pending rewards amount
        */
    function pending(
        address sharholderAddress_
    ) public view returns (uint256 pendingAmount) {
        ShareHolder storage user = shareHolders[sharholderAddress_];
        pendingAmount = user.shares.mul(accPerShare).div(1e36).sub(user.rewardDebt);
    }

    function totalPending () public view returns (uint256 ) {
        return accPerShare.mul(totalShares).div(1e36).sub(totalRewardsDebt);
    }

    /**
        returns information about the share holder
        */
    function shareHolderInfo (
        address shareHoldr_
    ) external view returns(ShareHolder memory){
        ShareHolder storage user = shareHolders[shareHoldr_];
        return ShareHolder (
            user.shares,     // How many tokens the user is holding.
            user.rewardDebt, // see @masterChef contract for more details
            user.claimed,
            pending(shareHoldr_)
        );
    }


    function setShare(
        address sharholderAddress_,
        uint256 amount_
    ) onlyOwner onlyIncluded(sharholderAddress_) external {
        ShareHolder storage user = shareHolders[sharholderAddress_];

        // pay any pending rewards
        if(user.shares > 0)
            claimPending(sharholderAddress_);

        // update total shares
        _updateUserShares(sharholderAddress_, amount_);
    }

    /*
        excludes shareHolderToBeExcluded_ from participating in rewards
    */
    function excludeFromRewards (
        address shareHolderToBeExcluded_ 
    ) external onlyOwner {
        if(excludedFromRewards[shareHolderToBeExcluded_])
            return;

        uint256 amountPending = pending(shareHolderToBeExcluded_);
        // update this user's shares to 0
        _updateUserShares(shareHolderToBeExcluded_, 0);
        // distribute his pending share to all shareholders
        if(amountPending > 0)
            _updateGlobalShares(amountPending);
        excludedFromRewards[shareHolderToBeExcluded_] = true;
        emit ExcludedFromRewards(shareHolderToBeExcluded_);
    }

    /*
        allow shareHolderToBeExcluded_ to participating in rewards
    */
    function includeInRewards(
        address shareHolderToBeIncluded_
    ) external onlyOwner {
        require(excludedFromRewards[shareHolderToBeIncluded_],"HODLRewardsDistributor: not excluded");
        
        _updateUserShares(shareHolderToBeIncluded_, IERC20(owner()).balanceOf(shareHolderToBeIncluded_));
        excludedFromRewards[shareHolderToBeIncluded_] = false;
        emit IncludedInRewards(shareHolderToBeIncluded_);
    }

    /** 
        @dev
        claim pending rewards for sharholderAddress_
        can be called by anyone but only sharholderAddress_
        can receive the reward
    */
    function claimPending(
        address sharholderAddress_
    ) public {
        ShareHolder storage user = shareHolders[sharholderAddress_];

        uint256 pendingAmount = user.shares.mul(accPerShare).div(1e36).sub(user.rewardDebt);

        if(pendingAmount <= 0) return;
        
        rewardsToken.safeTransfer(sharholderAddress_, pendingAmount);
        emit Claimed(sharholderAddress_, pendingAmount);

        user.claimed = user.claimed.add(pendingAmount);
        totalClaimed = totalClaimed.add(pendingAmount);
        
        totalRewardsDebt = totalRewardsDebt.sub(user.rewardDebt);
        user.rewardDebt = user.shares.mul(accPerShare).div(1e36);
        totalRewardsDebt = totalRewardsDebt.add(user.rewardDebt);
    }

    function batchProcessClaims(uint256 gas) public {
        if(gasleft() < gas) return;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 1; // index 0 is ocupied by address(0) 

        // we
        while(gasUsed < gas && iterations < allShareHolders.length) {
            claimPending(allShareHolders[_lastProccessedIndex]);
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            _incrementLastProccessed();
            iterations++;
        }
    }

    /**
        prevents accidental renouncement of owner ship 
        can sill renounce if set explicitly to dead address 
     */
    function renounceOwnership() public virtual override onlyOwner {}

    /**
        updates the accumulatedPerShare amount based on the new amount and total shares
        */
    function _updateGlobalShares(
        uint256 amount_
    ) internal {
        accPerShare = accPerShare.add(amount_.mul(1e36).div(totalShares));
        emit RewardsAdded(amount_);
    }

    /**
        updates a user share
        */
    function _updateUserShares(
        address sharholderAddress_,
        uint256 newAmount_
    ) internal {
        ShareHolder storage user = shareHolders[sharholderAddress_];

        totalShares = totalShares.sub(user.shares).add(newAmount_);
        totalRewardsDebt = totalRewardsDebt.sub(user.rewardDebt);
        user.shares = newAmount_;
        user.rewardDebt = user.shares.mul(accPerShare).div(1e36);
        totalRewardsDebt = totalRewardsDebt.add(user.rewardDebt);
        if(user.shares > 0 && indexOfShareHolders[sharholderAddress_] == 0 ){
            // add this shareHolder to array 
            allShareHolders.push(sharholderAddress_);
            indexOfShareHolders[sharholderAddress_] = allShareHolders.length-1;

        } else if(user.shares == 0 && indexOfShareHolders[sharholderAddress_] != 0){
            // remove this share holder from array
            uint256 indexOfRemoved = indexOfShareHolders[sharholderAddress_];
            allShareHolders[indexOfRemoved] = allShareHolders[allShareHolders.length-1]; // last item to the removed item's index
            indexOfShareHolders[sharholderAddress_] = 0;
            indexOfShareHolders[allShareHolders[indexOfRemoved]] = indexOfRemoved;
            allShareHolders.pop(); // remove the last item
        }
        emit ShareUpdated(sharholderAddress_, newAmount_);
    }

    function _incrementLastProccessed() internal {
        _lastProccessedIndex++;
        if(_lastProccessedIndex >= allShareHolders.length)
            _lastProccessedIndex = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IBurnable.sol';

abstract contract Burnable is Ownable, IBurnable, ERC20 {
    event BurnForReason(address indexed burner, uint256 indexed amount, string indexed reason);

    mapping(address => bool) burners;

    modifier onlyBurners(){
        require(burners[_msgSender()], 'NOT_BURNER');
        _;
    }

    function burn(uint256 amount_) override external onlyBurners {
        _burn(_msgSender(), amount_);
    }

    function burn(uint256 amount_, string calldata burnReason_) external onlyBurners {
        _burn(_msgSender(), amount_);
        emit BurnForReason(_msgSender(), amount_, burnReason_);
    }

    /**
        @dev adds allowedBurner to users who can burn 
        allowed users can only burn from their own balance
        only owner can call this
     */
    function addBurner(address allowedBurner) onlyOwner override public{
        burners[allowedBurner] = true;
    }

    /**
        @dev removes BurnerToBeRemoved from users who can burn 
        allowed users can only burn from their own balance
        only owner can call this
     */
    function removeBurner(address BurnerToBeRemoved) onlyOwner override public {
        burners[BurnerToBeRemoved] = false;
    }

    /**
        @dev checks if potentialBurner is a user who can burn 
     */
    function isBurner(address potentialBurner) external override view returns(bool) {
        return burners[potentialBurner];
    }
    
}