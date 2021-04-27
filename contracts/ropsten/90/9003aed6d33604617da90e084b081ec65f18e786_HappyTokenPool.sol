/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// Sources flattened with hardhat v2.2.0 https://hardhat.org
// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/utils/[email protected]


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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


pragma solidity ^0.8.0;


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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File contracts/IQLF.sol


/**
 * @author          Yisi Liu
 * @contact         [email protected]
 * @author_time     01/06/2021
**/

pragma solidity >= 0.8.0;

abstract contract IQLF is IERC165 {
    /**
     * @dev Returns if the given address is qualified, implemented on demand.
     */
    function ifQualified (address account) virtual external view returns (bool);

    /**
     * @dev Logs if the given address is qualified, implemented on demand.
     */
    function logQualified (address account, uint256 ito_start_time) virtual external returns (bool);

    /**
     * @dev Ensure that custom contract implements `ifQualified` amd `logQualified` correctly.
     */
    function supportsInterface(bytes4 interfaceId) virtual external override pure returns (bool) {
        return interfaceId == this.supportsInterface.selector || 
            interfaceId == (this.ifQualified.selector ^ this.logQualified.selector);
    }

    /**
     * @dev Emit when `ifQualified` is called to decide if the given `address`
     * is `qualified` according to the preset rule by the contract creator and 
     * the current block `number` and the current block `timestamp`.
     */
    event Qualification(address account, bool qualified, uint256 blockNumber, uint256 timestamp);
}


// File contracts/ito.sol


/**
 * @author          Yisi Liu
 * @contact         [email protected]
 * @author_time     01/06/2021
 * @maintainer      Hancheng Zhou, Yisi Liu
 * @maintain_time   04/15/2021
**/

pragma solidity >= 0.8.0;




contract HappyTokenPool {

    struct Pool {
        uint256 packed1;            // qualification_address(160) the smart contract address to verify qualification
                                    // hash(40) start_time_delta(28) 
                                    // expiration_time_delta(28) BIG ENDIAN
        uint256 packed2;            // total_tokens(128) limit(128)
        uint48  unlock_time;        // unlock_time + base_time = real_time
        address creator;
        address token_address;      // the target token address
        address[] exchange_addrs;   // a list of ERC20 addresses for swapping
        uint128[] exchanged_tokens; // a list of amounts of swapped tokens
        uint128[] ratios;           // a list of swap ratios
                                    // length = 2 * exchange_addrs.length
                                    // [address1, target, address2, target, ...]
                                    // e.g. [1, 10]
                                    // represents 1 tokenA to swap 10 target token
                                    // note: each ratio pair needs to be coprime
        mapping(address => uint256) swapped_map;      // swapped amount of an address
    }

    struct Packed {
        uint256 packed1;
        uint256 packed2;
    }

    // swap pool filling success event
    event FillSuccess (
        uint256 total,
        bytes32 id,
        address creator,
        uint256 creation_time,
        address token_address,
        string message
    );

    // swap success event
    event SwapSuccess (
        bytes32 id,
        address swapper,
        address from_address,
        address to_address,
        uint256 from_value,
        uint256 to_value
    );

    // claim success event
    event ClaimSuccess (
        bytes32 id,
        address claimer,
        uint256 timestamp,
        uint256 to_value,
        address token_address
    );

    // swap pool destruct success event
    event DestructSuccess (
        bytes32 id,
        address token_address,
        uint256 remaining_balance,
        uint128[] exchanged_values
    );

    // single token withdrawl from a swap pool success even
    event WithdrawSuccess (
        bytes32 id,
        address token_address,
        uint256 withdraw_balance
    );

    modifier creatorOnly {
        require(msg.sender == contract_creator, "Contract Creator Only");
        _;
    }

    using SafeERC20 for IERC20;
    uint32 nonce;
    uint224 base_time;                 // timestamp = base_time + delta to save gas
    address public contract_creator;
    mapping(bytes32 => Pool) pool_by_id;    // maps an id to a Pool instance
    string constant private magic = "Prince Philip, Queen Elizabeth II's husband, has died aged 99, \
    Buckingham Palace has announced. A statement issued by the palace just after midday spoke of the \
    Queen's deep sorrow following his death at Windsor Castle on Friday morning. The Duke of Edinbur";
    bytes32 private seed;
    address DEFAULT_ADDRESS = 0x0000000000000000000000000000000000000000;       // a universal address

    constructor() {
        contract_creator = msg.sender;
        seed = keccak256(abi.encodePacked(magic, block.timestamp, contract_creator));
        base_time = 1616976000;                                    // 00:00:00 03/30/2021 GMT(UTC+0)
    }

    /**
     * @dev 
     * fill_pool() creates a swap pool with specific parameters from input
     * _hash                sha3-256(password)
     * _start               start time delta, real start time = base_time + _start
     * _end                 end time delta, real end time = base_time + _end
     * message              swap pool creation message, only stored in FillSuccess event
     * _exchange_addrs      swap token list (0x0 for ETH, only supports ETH and ERC20 now)
     * _ratios              swap pair ratio list
     * _unlock_time         unlock time delta real unlock time = base_time + _unlock_time
     * _token_addr          swap target token address
     * _total_tokens        target token total swap amount
     * _limit               target token single swap limit
     * _qualification       the qualification contract address based on IQLF to determine qualification
     * This function takes the above parameters and creates the pool. _total_tokens of the target token
     * will be successfully transferred to this contract securely on a successful run of this function.
    **/
    function fill_pool (bytes32 _hash, uint256 _start, uint256 _end, string memory message,
                        address[] memory _exchange_addrs, uint128[] memory _ratios, uint256 _unlock_time,
                        address _token_addr, uint256 _total_tokens, uint256 _limit, address _qualification)
    public payable {
        nonce ++;
        require(_start < _end, "Start time should be earlier than end time.");
        require(_end < _unlock_time || _unlock_time == 0, "End time should be earlier than unlock time");
        require(_limit <= _total_tokens, "Limit needs to be less than or equal to the total supply");
        require(_total_tokens < 2 ** 128, "No more than 2^128 tokens(incluidng decimals) allowed");
        require(IERC20(_token_addr).allowance(msg.sender, address(this)) >= _total_tokens, "Insuffcient allowance");
        require(_exchange_addrs.length > 0, "Exchange token addresses need to be set");
        require(_ratios.length == 2 * _exchange_addrs.length, "Size of ratios = 2 * size of exchange_addrs");

        bytes32 _id = keccak256(abi.encodePacked(msg.sender, block.timestamp, nonce, seed));
        Pool storage pool = pool_by_id[_id];
        pool.packed1 = wrap1(_qualification, _hash, _start, _end);      // 256 bytes    detail in wrap1()
        pool.packed2 = wrap2(_total_tokens, _limit);                    // 256 bytes    detail in wrap2()
        pool.unlock_time = uint48(_unlock_time);                        // 48  bytes    unlock_time 0 -> unlocked
        pool.creator = msg.sender;                                      // 160 bytes    pool creator
        pool.exchange_addrs = _exchange_addrs;                          // 160 bytes    target token
        pool.token_address = _token_addr;                               // 160 bytes    target token address

        // Init each token swapped amount to 0
        for (uint256 i = 0; i < _exchange_addrs.length; i++) {
            if (_exchange_addrs[i] != DEFAULT_ADDRESS) {
                // TODO: Is there a better way to validate an ERC20?
                require(IERC20(_exchange_addrs[i]).totalSupply() > 0, "Not a valid ERC20");
            }
            pool.exchanged_tokens.push(0); 
        }

        // Make sure each ratio is co-prime to prevent overflow
        for (uint256 i = 0; i < _ratios.length; i+= 2) {
            uint256 divA = SafeMath.div(_ratios[i], _ratios[i+1]);      // Non-zero checked by SafteMath.div
            uint256 divB = SafeMath.div(_ratios[i+1], _ratios[i]);      // Non-zero checked by SafteMath.div
            
            if (_ratios[i] == 1) {
                require(divB == _ratios[i+1]);
            } else if (_ratios[i+1] == 1) {
                require(divA == _ratios[i]);
            } else {
                // if a and b are co-prime, then a / b * b != a and b / a * a != b
                require(divA * _ratios[i+1] != _ratios[i]);
                require(divB * _ratios[i] != _ratios[i+1]);
            }
        }
        pool.ratios = _ratios;                                          // 256 * k
        IERC20(_token_addr).safeTransferFrom(msg.sender, address(this), _total_tokens);

        emit FillSuccess(_total_tokens, _id, msg.sender, block.timestamp, _token_addr, message);
    }

    /**
     * @dev
     * swap() allows users to swap tokens in a swap pool
     * id                   swap pool id
     * verification         sha3-256(sha3-256(password)[:40]+swapper_address)
     * validation           sha3-256(swapper_address)
     * exchange_addr_i     the index of the exchange address of the list
     * input_total          the input amount of the specific token
     * This function is called by the swapper who approves the specific ERC20 or directly transfer the ETH
     * first and wants to swap the desired amount of the target token. The swapped amount is calculated
     * based on the pool ratio. After swap successfully, the same account can not swap the same pool again.
    **/

    function swap (bytes32 id, bytes32 verification, 
                   bytes32 validation, uint256 exchange_addr_i, uint128 input_total) 
    public payable returns (uint256 swapped) {

        Pool storage pool = pool_by_id[id];
        Packed memory packed = Packed(pool.packed1, pool.packed2);
        require (
            IQLF(
                address(
                    uint160(unbox(packed.packed1, 0, 160)))
                ).logQualified(msg.sender, uint256(unbox(packed.packed1, 200, 28) + base_time)
            ) == true, 
            "Not Qualified"
        );
        require (unbox(packed.packed1, 200, 28) + base_time < block.timestamp, "Not started.");
        require (unbox(packed.packed1, 228, 28) + base_time > block.timestamp, "Expired.");
        // sha3(sha3(passowrd)[:40] + msg.sender) so that the raw password will never appear in the contract
        require (verification == keccak256(abi.encodePacked(unbox(packed.packed1, 160, 40), msg.sender)), 
                 'Wrong Password');
        // sha3(msg.sender) to protect from front runs (but this is kinda naive since the contract is open sourced)
        require (validation == keccak256(abi.encodePacked(msg.sender)), "Validation Failed");

        uint256 total_tokens = unbox(packed.packed2, 0, 128);
        // revert if the pool is empty
        require (total_tokens > 0, "Out of Stock");

        address exchange_addr = pool.exchange_addrs[exchange_addr_i];
        uint256 ratioA = pool.ratios[exchange_addr_i*2];
        uint256 ratioB = pool.ratios[exchange_addr_i*2 + 1];
        // check if the input is enough for the desired transfer
        if (exchange_addr == DEFAULT_ADDRESS) {
            require(msg.value == input_total, 'No enough ether.');
        } else {
            uint256 allowance = IERC20(exchange_addr).allowance(msg.sender, address(this));
            require(allowance >= input_total, 'No enough allowance.');
        }

        uint256 swapped_tokens;
        // this calculation won't be overflow thanks to the SafeMath and the co-prime test
        swapped_tokens = SafeMath.div(SafeMath.mul(input_total, ratioB), ratioA);       // 2^256=10e77 >> 10e18 * 10e18
        require(swapped_tokens > 0, "Better not draw water with a sieve");

        uint256 limit = unbox(packed.packed2, 128, 128);
        if (swapped_tokens > limit) {
            // don't be greedy - you can only get at most limit tokens
            swapped_tokens = limit;
            input_total = uint128(SafeMath.div(SafeMath.mul(limit, ratioA), ratioB));           // Update input_total
        } else if (swapped_tokens > total_tokens) {
            // if the left tokens are not enough
            swapped_tokens = total_tokens;
            input_total = uint128(SafeMath.div(SafeMath.mul(total_tokens, ratioA), ratioB));    // Update input_total
            // return the eth
            if (exchange_addr == DEFAULT_ADDRESS)
                payable(msg.sender).transfer(msg.value - input_total);
        }
        require(swapped_tokens <= limit);                                                       // make sure again
        pool.exchanged_tokens[exchange_addr_i] = uint128(SafeMath.add(pool.exchanged_tokens[exchange_addr_i], 
                                                                      input_total));            // update exchanged

        // penalize greedy attackers by placing duplication check at the very last
        require (pool.swapped_map[msg.sender] == 0, "Already swapped");

        // update the remaining tokens and swapped token mapping
        pool.packed2 = rewriteBox(packed.packed2, 0, 128, SafeMath.sub(total_tokens, swapped_tokens));
        pool.swapped_map[msg.sender] = swapped_tokens;

        // transfer the token after state changing
        // ETH comes with the tx, but ERC20 does not - INPUT
        if (exchange_addr != DEFAULT_ADDRESS) {
            IERC20(exchange_addr).safeTransferFrom(msg.sender, address(this), input_total);
        }

        // Swap success event
        emit SwapSuccess(id, msg.sender, exchange_addr, pool.token_address, input_total, swapped_tokens);

        // if unlock_time == 0, transfer the swapped tokens to the recipient address (msg.sender) - OUTPUT
        // if not, claim() needs to be called to get the token
        if (pool.unlock_time == 0) {
            transfer_token(pool.token_address, address(this), msg.sender, swapped_tokens);
            emit ClaimSuccess(id, msg.sender, block.timestamp, swapped_tokens, pool.token_address);
        }
            
        return swapped_tokens;
    }

    /**
     * check_availability() returns a bunch of pool info given a pool id
     * id                    swap pool id
     * this function returns 1. exchange_addrs that can be used to determine the index
     *                       2. remaining target tokens
     *                       3. if started
     *                       4. if ended
     *                       5. swapped amount of the query address
     *                       5. exchanged amount of each token
    **/

    function check_availability (bytes32 id) external view 
        returns (address[] memory exchange_addrs, uint256 remaining, 
                 bool started, bool expired, bool unlocked, uint256 unlock_time,
                 uint256 swapped, uint128[] memory exchanged_tokens) {
        Pool storage pool = pool_by_id[id];
        return (
            pool.exchange_addrs,                                                // exchange_addrs 0x0 means destructed
            unbox(pool.packed2, 0, 128),                                        // remaining
            block.timestamp > unbox(pool.packed1, 200, 28) + base_time,         // started
            block.timestamp > unbox(pool.packed1, 228, 28) + base_time,         // expired
            block.timestamp > pool.unlock_time + base_time,                     // unlocked
            pool.unlock_time + base_time,                                       // unlock_time
            pool.swapped_map[msg.sender],                                       // swapped number 
            pool.exchanged_tokens                                               // exchanged tokens
        );
    }

    function claim(bytes32[] memory ito_ids) public {
        uint256 claimed_amount;
        for (uint256 i = 0; i < ito_ids.length; i++) {
            Pool storage pool = pool_by_id[ito_ids[i]];
            if (pool.unlock_time + base_time > block.timestamp)
                continue;
            claimed_amount = pool.swapped_map[msg.sender];
            if (claimed_amount == 0)
                continue;
            pool.swapped_map[msg.sender] = 0;
            transfer_token(pool.token_address, address(this), msg.sender, claimed_amount);

            emit ClaimSuccess(ito_ids[i], msg.sender, block.timestamp, claimed_amount, pool.token_address);
        }
    }

    function setUnlockTime(bytes32 id, uint256 _unlock_time) public {
        Pool storage pool = pool_by_id[id];
        require(pool.creator == msg.sender, "Pool Creator Only");
        pool.unlock_time = uint48(_unlock_time);
    }

    /**
     * destruct() destructs the given pool given the pool id
     * id                    swap pool id
     * this function can only be called by the pool creator. after validation, it transfers all the remaining token 
     * (if any) and all the swapped tokens to the pool creator. it will then destruct the pool by reseting almost 
     * all the variables to zero to get the gas refund.
     * note that this function may not work if a pool needs to transfer over ~200 tokens back to the address due to 
     * the block gas limit. we have another function withdraw() to help the pool creator to withdraw a single token 
    **/

    function destruct (bytes32 id) public {
        Pool storage pool = pool_by_id[id];
        require(msg.sender == pool.creator, "Only the pool creator can destruct.");

        uint256 expiration = unbox(pool.packed1, 228, 28) + base_time;
        uint256 remaining_tokens = unbox(pool.packed2, 0, 128);
        // only after expiration or the pool is empty
        require(expiration <= block.timestamp || remaining_tokens == 0, "Not expired yet");

        // if any left in the pool
        if (remaining_tokens != 0) {
            transfer_token(pool.token_address, address(this), msg.sender, remaining_tokens);
        }
        
        // transfer the swapped tokens accordingly
        // note this loop may exceed the block gas limit so if >200 exchange_addrs this may not work
        for (uint256 i = 0; i < pool.exchange_addrs.length; i++) {
            if (pool.exchanged_tokens[i] > 0) {
                // ERC20
                if (pool.exchange_addrs[i] != DEFAULT_ADDRESS)
                    transfer_token(pool.exchange_addrs[i], address(this), msg.sender, pool.exchanged_tokens[i]);
                // ETH
                else
                    payable(msg.sender).transfer(pool.exchanged_tokens[i]);
            }
        }
        emit DestructSuccess(id, pool.token_address, remaining_tokens, pool.exchanged_tokens);

        // Gas Refund
        pool.packed1 = 0;
        pool.packed2 = 0;
        pool.creator = DEFAULT_ADDRESS;
        for (uint256 i = 0; i < pool.exchange_addrs.length; i++) {
            pool.exchange_addrs[i] = DEFAULT_ADDRESS;
            pool.exchanged_tokens[i] = 0;
            pool.ratios[i*2] = 0;
            pool.ratios[i*2+1] = 0;
        }
    }

    /**
     * withdraw() transfers out a single token after a pool is expired or empty 
     * id                    swap pool id
     * addr_i                withdraw token index
     * this function can only be called by the pool creator. after validation, it transfers the addr_i th token 
     * out to the pool creator address.
    **/

    function withdraw (bytes32 id, uint256 addr_i) public {
        Pool storage pool = pool_by_id[id];
        require(msg.sender == pool.creator, "Only the pool creator can withdraw.");

        uint256 withdraw_balance = pool.exchanged_tokens[addr_i];
        require(withdraw_balance > 0, "None of this token left");
        uint256 expiration = unbox(pool.packed1, 228, 28) + base_time;
        uint256 remaining_tokens = unbox(pool.packed2, 0, 128);
        // only after expiration or the pool is empty
        require(expiration <= block.timestamp || remaining_tokens == 0, "Not expired yet");
        address token_address = pool.exchange_addrs[addr_i];

        // ERC20
        if (token_address != DEFAULT_ADDRESS)
            transfer_token(token_address, address(this), msg.sender, withdraw_balance);
        // ETH
        else
            payable(msg.sender).transfer(withdraw_balance);
        // clear the record
        pool.exchanged_tokens[addr_i] = 0;
        emit WithdrawSuccess(id, token_address, withdraw_balance);
    }

    // helper functions TODO: migrate this to a helper file

    /**
     * _qualification the smart contract address to verify qualification      160
     * _hash          sha3-256(password)                                      40
     * _start         start time delta                                        28
     * _end           end time  delta                                         28
     * wrap1() inserts the above variables into a 32-word block
    **/

    function wrap1 (address _qualification, bytes32 _hash, uint256 _start, uint256 _end) internal pure 
                    returns (uint256 packed1) {
        uint256 _packed1 = 0;
        _packed1 |= box(0, 160,  uint256(uint160(_qualification)));     // _qualification = 160 bits
        _packed1 |= box(160, 40, uint256(_hash) >> 216);                // hash = 40 bits (safe?)
        _packed1 |= box(200, 28, _start);                               // start_time = 28 bits 
        _packed1 |= box(228, 28, _end);                                 // expiration_time = 28 bits
        return _packed1;
    }

    /**
     * _total_tokens   target remaining         128
     * _limit          single swap limit        128
     * wrap2() inserts the above variables into a 32-word block
    **/

    function wrap2 (uint256 _total_tokens, uint256 _limit) internal pure returns (uint256 packed2) {
        uint256 _packed2 = 0;
        _packed2 |= box(0, 128, _total_tokens);             // total_tokens = 128 bits ~= 3.4e38
        _packed2 |= box(128, 128, _limit);                  // limit = 128 bits
        return _packed2;
    }

    /**
     * position      position in a memory block
     * size          data size
     * data          data
     * box() inserts the data in a 256bit word with the given position and returns it
     * data is checked by validRange() to make sure it is not over size 
    **/

    function box (uint16 position, uint16 size, uint256 data) internal pure returns (uint256 boxed) {
        require(validRange(size, data), "Value out of range BOX");
        assembly {
            // data << position
            boxed := shl(position, data)
        }
    }

    /**
     * position      position in a memory block
     * size          data size
     * base          base data
     * unbox() extracts the data out of a 256bit word with the given position and returns it
     * base is checked by validRange() to make sure it is not over size 
    **/

    function unbox (uint256 base, uint16 position, uint16 size) internal pure returns (uint256 unboxed) {
        require(validRange(256, base), "Value out of range UNBOX");
        assembly {
            // (((1 << size) - 1) & base >> position)
            unboxed := and(sub(shl(size, 1), 1), shr(position, base))

        }
    }

    /**
     * size          data size
     * data          data
     * validRange()  checks if the given data is over the specified data size
    **/

    function validRange (uint16 size, uint256 data) internal pure returns(bool ifValid) { 
        assembly {
            // 2^size > data or size ==256
            ifValid := or(eq(size, 256), gt(shl(size, 1), data))
        }
    }

    /**
     * _box          32byte data to be modified
     * position      position in a memory block
     * size          data size
     * data          data to be inserted
     * rewriteBox() updates a 32byte word with a data at the given position with the specified size
    **/

    function rewriteBox (uint256 _box, uint16 position, uint16 size, uint256 data) 
                        internal pure returns (uint256 boxed) {
        assembly {
            // mask = ~((1 << size - 1) << position)
            // _box = (mask & _box) | ()data << position)
            boxed := or( and(_box, not(shl(position, sub(shl(size, 1), 1)))), shl(position, data))
        }
    }

    /**
     * token_address      ERC20 address
     * sender_address     sender address
     * recipient_address  recipient address
     * amount             transfer amount
     * transfer_token() transfers a given amount of ERC20 from the sender address to the recipient address
    **/
   
    function transfer_token (address token_address, address sender_address,
                             address recipient_address, uint256 amount) internal {
        require(IERC20(token_address).balanceOf(sender_address) >= amount, "Balance not enough");
        IERC20(token_address).safeTransfer(recipient_address, amount);
    }
    
}