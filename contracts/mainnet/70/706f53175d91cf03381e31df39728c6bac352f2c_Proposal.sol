/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

pragma solidity ^0.5.15;
pragma experimental ABIEncoderV2;

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
        (bool success, ) = recipient.call.value(amount)("");
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
        (bool success, bytes memory returndata) = target.call.value(weiValue)(data);
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

/* Copyright 2020 Compound Labs, Inc.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */


contract YAMGovernanceStorage {
    /// @notice A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;
}

// Storage for a YAM token
contract YAMTokenStorage {

    using SafeMath for uint256;

    /**
     * @dev Guard variable for re-entrancy checks. Not currently used
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Governor for this contract
     */
    address public gov;

    /**
     * @notice Pending governance for this contract
     */
    address public pendingGov;

    /**
     * @notice Approved rebaser for this contract
     */
    address public rebaser;

    /**
     * @notice Approved migrator for this contract
     */
    address public migrator;

    /**
     * @notice Incentivizer address of YAM protocol
     */
    address public incentivizer;

    /**
     * @notice Total supply of YAMs
     */
    uint256 public totalSupply;

    /**
     * @notice Internal decimals used to handle scaling factor
     */
    uint256 public constant internalDecimals = 10**24;

    /**
     * @notice Used for percentage maths
     */
    uint256 public constant BASE = 10**18;

    /**
     * @notice Scaling factor that adjusts everyone's balances
     */
    uint256 public yamsScalingFactor;

    mapping (address => uint256) internal _yamBalances;

    mapping (address => mapping (address => uint256)) internal _allowedFragments;

    uint256 public initSupply;


    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    bytes32 public DOMAIN_SEPARATOR;
}

contract YAMTokenInterface is YAMTokenStorage, YAMGovernanceStorage {

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Event emitted when tokens are rebased
     */
    event Rebase(uint256 epoch, uint256 prevYamsScalingFactor, uint256 newYamsScalingFactor);

    /*** Gov Events ***/

    /**
     * @notice Event emitted when pendingGov is changed
     */
    event NewPendingGov(address oldPendingGov, address newPendingGov);

    /**
     * @notice Event emitted when gov is changed
     */
    event NewGov(address oldGov, address newGov);

    /**
     * @notice Sets the rebaser contract
     */
    event NewRebaser(address oldRebaser, address newRebaser);

    /**
     * @notice Sets the migrator contract
     */
    event NewMigrator(address oldMigrator, address newMigrator);

    /**
     * @notice Sets the incentivizer contract
     */
    event NewIncentivizer(address oldIncentivizer, address newIncentivizer);

    /* - ERC20 Events - */

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /* - Extra Events - */
    /**
     * @notice Tokens minted event
     */
    event Mint(address to, uint256 amount);

    // Public functions
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function balanceOf(address who) external view returns(uint256);
    function balanceOfUnderlying(address who) external view returns(uint256);
    function allowance(address owner_, address spender) external view returns(uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function maxScalingFactor() external view returns (uint256);
    function yamToFragment(uint256 yam) external view returns (uint256);
    function fragmentToYam(uint256 value) external view returns (uint256);

    /* - Governance Functions - */
    function getPriorVotes(address account, uint blockNumber) external view returns (uint256);
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;
    function delegate(address delegatee) external;
    function delegates(address delegator) external view returns (address);
    function getCurrentVotes(address account) external view returns (uint256);

    /* - Permissioned/Governance functions - */
    function mint(address to, uint256 amount) external returns (bool);
    function rebase(uint256 epoch, uint256 indexDelta, bool positive) external returns (uint256);
    function _setRebaser(address rebaser_) external;
    function _setIncentivizer(address incentivizer_) external;
    function _setPendingGov(address pendingGov_) external;
    function _acceptGov() external;
}

/* Copyright 2020 Compound Labs, Inc.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */



contract YAMGovernanceToken is YAMTokenInterface {

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Get delegatee for an address delegating
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "YAM::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "YAM::delegateBySig: invalid nonce");
        require(now <= expiry, "YAM::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "YAM::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = _yamBalances[delegator]; // balance of underlying YAMs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "YAM::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}



contract YAMToken is YAMGovernanceToken {
    // Modifiers
    modifier onlyGov() {
        require(msg.sender == gov);
        _;
    }

    modifier onlyRebaser() {
        require(msg.sender == rebaser);
        _;
    }

    modifier onlyMinter() {
        require(
            msg.sender == rebaser
            || msg.sender == gov
            || msg.sender == incentivizer
            || msg.sender == migrator,
            "not minter"
        );
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    )
        public
    {
        require(yamsScalingFactor == 0, "already initialized");
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }


    /**
    * @notice Computes the current max scaling factor
    */
    function maxScalingFactor()
        external
        view
        returns (uint256)
    {
        return _maxScalingFactor();
    }

    function _maxScalingFactor()
        internal
        view
        returns (uint256)
    {
        // scaling factor can only go up to 2**256-1 = initSupply * yamsScalingFactor
        // this is used to check if yamsScalingFactor will be too high to compute balances when rebasing.
        return uint256(-1) / initSupply;
    }

    /**
    * @notice Mints new tokens, increasing totalSupply, initSupply, and a users balance.
    * @dev Limited to onlyMinter modifier
    */
    function mint(address to, uint256 amount)
        external
        onlyMinter
        returns (bool)
    {
        _mint(to, amount);
        return true;
    }

    function _mint(address to, uint256 amount)
        internal
    {
      if (msg.sender == migrator) {
        // migrator directly uses v2 balance for the amount

        // increase initSupply
        initSupply = initSupply.add(amount);

        // get external value
        uint256 scaledAmount = _yamToFragment(amount);

        // increase totalSupply
        totalSupply = totalSupply.add(scaledAmount);

        // make sure the mint didnt push maxScalingFactor too low
        require(yamsScalingFactor <= _maxScalingFactor(), "max scaling factor too low");

        // add balance
        _yamBalances[to] = _yamBalances[to].add(amount);

        // add delegates to the minter
        _moveDelegates(address(0), _delegates[to], amount);
        emit Mint(to, scaledAmount);
        emit Transfer(address(0), to, scaledAmount);
      } else {
        // increase totalSupply
        totalSupply = totalSupply.add(amount);

        // get underlying value
        uint256 yamValue = _fragmentToYam(amount);

        // increase initSupply
        initSupply = initSupply.add(yamValue);

        // make sure the mint didnt push maxScalingFactor too low
        require(yamsScalingFactor <= _maxScalingFactor(), "max scaling factor too low");

        // add balance
        _yamBalances[to] = _yamBalances[to].add(yamValue);

        // add delegates to the minter
        _moveDelegates(address(0), _delegates[to], yamValue);
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
      }
    }

    /**
    * @notice Mints new tokens using underlying amount, increasing totalSupply, initSupply, and a users balance.
    * @dev Limited to onlyMinter modifier
    */
    function mintUnderlying(address to, uint256 amount)
        external
        onlyMinter
        returns (bool)
    {
        _mintUnderlying(to, amount);
        return true;
    }

    function _mintUnderlying(address to, uint256 amount)
        internal
    {

        // increase initSupply
        initSupply = initSupply.add(amount);

        // get external value
        uint256 scaledAmount = _yamToFragment(amount);

        // increase totalSupply
        totalSupply = totalSupply.add(scaledAmount);

        // make sure the mint didnt push maxScalingFactor too low
        require(yamsScalingFactor <= _maxScalingFactor(), "max scaling factor too low");

        // add balance
        _yamBalances[to] = _yamBalances[to].add(amount);

        // add delegates to the minter
        _moveDelegates(address(0), _delegates[to], amount);
        emit Mint(to, scaledAmount);
        emit Transfer(address(0), to, scaledAmount);
   
    }

    /**
     * @dev Transfer underlying balance to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transferUnderlying(address to, uint256 value)
        external
        validRecipient(to)
        returns (bool)
    {
        // sub from balance of sender
        _yamBalances[msg.sender] = _yamBalances[msg.sender].sub(value);

        // add to balance of receiver
        _yamBalances[to] = _yamBalances[to].add(value);
        emit Transfer(msg.sender, to, _yamToFragment(value));

        _moveDelegates(_delegates[msg.sender], _delegates[to], value);
        return true;
    }
    
    /* - ERC20 functionality - */

    /**
    * @dev Transfer tokens to a specified address.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    * @return True on success, false otherwise.
    */
    function transfer(address to, uint256 value)
        external
        validRecipient(to)
        returns (bool)
    {
        // underlying balance is stored in yams, so divide by current scaling factor

        // note, this means as scaling factor grows, dust will be untransferrable.
        // minimum transfer value == yamsScalingFactor / 1e24;

        // get amount in underlying
        uint256 yamValue = _fragmentToYam(value);

        // sub from balance of sender
        _yamBalances[msg.sender] = _yamBalances[msg.sender].sub(yamValue);

        // add to balance of receiver
        _yamBalances[to] = _yamBalances[to].add(yamValue);
        emit Transfer(msg.sender, to, value);

        _moveDelegates(_delegates[msg.sender], _delegates[to], yamValue);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another.
    * @param from The address you want to send tokens from.
    * @param to The address you want to transfer to.
    * @param value The amount of tokens to be transferred.
    */
    function transferFrom(address from, address to, uint256 value)
        external
        validRecipient(to)
        returns (bool)
    {
        // decrease allowance
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

        // get value in yams
        uint256 yamValue = _fragmentToYam(value);

        // sub from from
        _yamBalances[from] = _yamBalances[from].sub(yamValue);
        _yamBalances[to] = _yamBalances[to].add(yamValue);
        emit Transfer(from, to, value);

        _moveDelegates(_delegates[from], _delegates[to], yamValue);
        return true;
    }

    /**
    * @param who The address to query.
    * @return The balance of the specified address.
    */
    function balanceOf(address who)
      external
      view
      returns (uint256)
    {
      return _yamToFragment(_yamBalances[who]);
    }

    /** @notice Currently returns the internal storage amount
    * @param who The address to query.
    * @return The underlying balance of the specified address.
    */
    function balanceOfUnderlying(address who)
      external
      view
      returns (uint256)
    {
      return _yamBalances[who];
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        external
        view
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        external
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] =
            _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }


    // --- Approve by signature ---
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        require(now <= deadline, "YAM/permit-expired");

        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );

        require(owner != address(0), "YAM/invalid-address-0");
        require(owner == ecrecover(digest, v, r, s), "YAM/invalid-permit");
        _allowedFragments[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /* - Governance Functions - */

    /** @notice sets the rebaser
     * @param rebaser_ The address of the rebaser contract to use for authentication.
     */
    function _setRebaser(address rebaser_)
        external
        onlyGov
    {
        address oldRebaser = rebaser;
        rebaser = rebaser_;
        emit NewRebaser(oldRebaser, rebaser_);
    }

    /** @notice sets the migrator
     * @param migrator_ The address of the migrator contract to use for authentication.
     */
    function _setMigrator(address migrator_)
        external
        onlyGov
    {
        address oldMigrator = migrator_;
        migrator = migrator_;
        emit NewMigrator(oldMigrator, migrator_);
    }

    /** @notice sets the incentivizer
     * @param incentivizer_ The address of the rebaser contract to use for authentication.
     */
    function _setIncentivizer(address incentivizer_)
        external
        onlyGov
    {
        address oldIncentivizer = incentivizer;
        incentivizer = incentivizer_;
        emit NewIncentivizer(oldIncentivizer, incentivizer_);
    }

    /** @notice sets the pendingGov
     * @param pendingGov_ The address of the rebaser contract to use for authentication.
     */
    function _setPendingGov(address pendingGov_)
        external
        onlyGov
    {
        address oldPendingGov = pendingGov;
        pendingGov = pendingGov_;
        emit NewPendingGov(oldPendingGov, pendingGov_);
    }

    /** @notice allows governance to assign delegate to self
     *
     */
    function _acceptGov()
        external
    {
        require(msg.sender == pendingGov, "!pending");
        address oldGov = gov;
        gov = pendingGov;
        pendingGov = address(0);
        emit NewGov(oldGov, gov);
    }

    function assignSelfDelegate(address nonvotingContract)
        external
        onlyGov
    {
        address delegate = _delegates[nonvotingContract];
        require( delegate == address(0), "!address(0)" );
        // assigns delegate to self only
        _delegate(nonvotingContract, nonvotingContract);
    }

    /* - Extras - */

    /**
    * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
    *
    * @dev The supply adjustment equals (totalSupply * DeviationFromTargetRate) / rebaseLag
    *      Where DeviationFromTargetRate is (MarketOracleRate - targetRate) / targetRate
    *      and targetRate is CpiOracleRate / baseCpi
    */
    function rebase(
        uint256 epoch,
        uint256 indexDelta,
        bool positive
    )
        external
        onlyRebaser
        returns (uint256)
    {
        // no change
        if (indexDelta == 0) {
          emit Rebase(epoch, yamsScalingFactor, yamsScalingFactor);
          return totalSupply;
        }

        // for events
        uint256 prevYamsScalingFactor = yamsScalingFactor;


        if (!positive) {
            // negative rebase, decrease scaling factor
            yamsScalingFactor = yamsScalingFactor.mul(BASE.sub(indexDelta)).div(BASE);
        } else {
            // positive reabse, increase scaling factor
            uint256 newScalingFactor = yamsScalingFactor.mul(BASE.add(indexDelta)).div(BASE);
            if (newScalingFactor < _maxScalingFactor()) {
                yamsScalingFactor = newScalingFactor;
            } else {
                yamsScalingFactor = _maxScalingFactor();
            }
        }

        // update total supply, correctly
        totalSupply = _yamToFragment(initSupply);

        emit Rebase(epoch, prevYamsScalingFactor, yamsScalingFactor);
        return totalSupply;
    }

    function yamToFragment(uint256 yam)
        external
        view
        returns (uint256)
    {
        return _yamToFragment(yam);
    }

    function fragmentToYam(uint256 value)
        external
        view
        returns (uint256)
    {
        return _fragmentToYam(value);
    }

    function _yamToFragment(uint256 yam)
        internal
        view
        returns (uint256)
    {
        return yam.mul(yamsScalingFactor).div(internalDecimals);
    }

    function _fragmentToYam(uint256 value)
        internal
        view
        returns (uint256)
    {
        return value.mul(internalDecimals).div(yamsScalingFactor);
    }

    // Rescue tokens
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    )
        external
        onlyGov
        returns (bool)
    {
        // transfer to
        SafeERC20.safeTransfer(IERC20(token), to, amount);
        return true;
    }
}

contract YAMLogic3 is YAMToken {
    /**
     * @notice Initialize the new money market
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address initial_owner,
        uint256 initTotalSupply_
    )
        public
    {
        super.initialize(name_, symbol_, decimals_);

        yamsScalingFactor = BASE;
        initSupply = _fragmentToYam(initTotalSupply_);
        totalSupply = initTotalSupply_;
        _yamBalances[initial_owner] = initSupply;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );
    }
}

/* Copyright 2020 Compound Labs, Inc.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */


contract YAMDelegationStorage {
    /**
     * @notice Implementation address for this contract
     */
    address public implementation;
}

contract YAMDelegatorInterface is YAMDelegationStorage {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Called by the gov to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) public;
}

contract YAMDelegateInterface is YAMDelegationStorage {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public;
}


contract YAMDelegate3 is YAMLogic3, YAMDelegateInterface {
    /**
     * @notice Construct an empty delegate
     */
    constructor() public {}

    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public {
        // Shh -- currently unused
        data;

        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == gov, "only the gov may call _becomeImplementation");
    }

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public {
        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == gov, "only the gov may call _resignImplementation");
    }
}

contract VestingPool {
    using SafeMath for uint256;
    using SafeMath for uint128;

    struct Stream {
        address recipient;
        uint128 startTime;
        uint128 length;
        uint256 totalAmount;
        uint256 amountPaidOut;
    }

    /**
     * @notice Governor for this contract
     */
    address public gov;

    /**
     * @notice Pending governance for this contract
     */
    address public pendingGov;

    /// @notice Mapping containing valid stream managers
    mapping(address => bool) public isSubGov;

    /// @notice Amount of tokens allocated to streams that hasn't yet been claimed
    uint256 public totalUnclaimedInStreams;

    /// @notice The number of streams created so far
    uint256 public streamCount;

    /// @notice All streams
    mapping(uint256 => Stream) public streams;

    /// @notice YAM token
    YAMDelegate3 public yam;

    /**
     * @notice Event emitted when a sub gov is enabled/disabled
     */
    event SubGovModified(
        address account, 
        bool isSubGov
    );

    /**
     * @notice Event emitted when stream is opened
     */
    event StreamOpened(
        address indexed account,
        uint256 indexed streamId,
        uint256 length,
        uint256 totalAmount
    );

    /**
     * @notice Event emitted when stream is closed
     */
    event StreamClosed(uint256 indexed streamId);

    /**
     * @notice Event emitted on payout
     */
    event Payout(
        uint256 indexed streamId,
        address indexed recipient,
        uint256 amount
    );

    /**
     * @notice Event emitted when pendingGov is changed
     */
    event NewPendingGov(
        address oldPendingGov, 
        address newPendingGov
    );

    /**
     * @notice Event emitted when gov is changed
     */
    event NewGov(
        address oldGov, 
        address newGov
    );

    constructor(YAMDelegate3 _yam)
        public
    {
        gov = msg.sender;
        yam = _yam;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "VestingPool::onlyGov: account is not gov");
        _;
    }

    modifier canManageStreams() {
        require(
            isSubGov[msg.sender] || (msg.sender == gov),
            "VestingPool::canManageStreams: account cannot manage streams"
        );
        _;
    }

    /**
     * @dev Set whether an account can open/close streams. Only callable by the current gov contract
     * @param account The account to set permissions for.
     * @param _isSubGov Whether or not this account can manage streams
     */
    function setSubGov(address account, bool _isSubGov)
        public
        onlyGov
    {
        isSubGov[account] = _isSubGov;
        emit SubGovModified(account, _isSubGov);
    }

    /** @notice sets the pendingGov
     * @param pendingGov_ The address of the contract to use for authentication.
     */
    function _setPendingGov(address pendingGov_)
        external
        onlyGov
    {
        address oldPendingGov = pendingGov;
        pendingGov = pendingGov_;
        emit NewPendingGov(oldPendingGov, pendingGov_);
    }

    /** @notice accepts governance over this contract
     *
     */
    function _acceptGov()
        external
    {
        require(msg.sender == pendingGov, "!pending");
        address oldGov = gov;
        gov = pendingGov;
        pendingGov = address(0);
        emit NewGov(oldGov, gov);
    }

    /**
     * @dev Opens a new stream that continuously pays out.
     * @param recipient Account that will receive the funds.
     * @param length The amount of time in seconds that the stream lasts
     * @param totalAmount The total amount to payout in the stream
     */
    function openStream(
        address recipient,
        uint128 length,
        uint256 totalAmount
    )
        public
        canManageStreams
        returns (uint256 streamIndex)
    {
        streamIndex = streamCount++;
        streams[streamIndex] = Stream({
            recipient: recipient,
            length: length,
            startTime: uint128(block.timestamp),
            totalAmount: totalAmount,
            amountPaidOut: 0
        });
        totalUnclaimedInStreams = totalUnclaimedInStreams.add(totalAmount);
        require(
            totalUnclaimedInStreams <= yam.balanceOfUnderlying(address(this)),
            "VestingPool::payout: Total streaming is greater than pool's YAM balance"
        );
        emit StreamOpened(recipient, streamIndex, length, totalAmount);
    }

    /**
     * @dev Closes the specified stream. Pays out pending amounts, clears out the stream, and emits a StreamClosed event.
     * @param streamId The id of the stream to close.
     */
    function closeStream(uint256 streamId)
        public
        canManageStreams
    {
        payout(streamId);
        streams[streamId] = Stream(
            address(0x0000000000000000000000000000000000000000),
            0,
            0,
            0,
            0
        );
        emit StreamClosed(streamId);
    }

    /**
     * @dev Pays out pending amount in a stream
     * @param streamId The id of the stream to payout.
     * @return The amount paid out in underlying
     */
    function payout(uint256 streamId)
        public
        returns (uint256 paidOut)
    {
        uint128 currentTime = uint128(block.timestamp);
        Stream memory stream = streams[streamId];
        require(
            stream.startTime <= currentTime,
            "VestingPool::payout: Stream hasn't started yet"
        );
        uint256 claimableUnderlying = _claimable(stream);
        streams[streamId].amountPaidOut = stream.amountPaidOut.add(
            claimableUnderlying
        );

        totalUnclaimedInStreams = totalUnclaimedInStreams.sub(
            claimableUnderlying
        );

        yam.transferUnderlying(stream.recipient, claimableUnderlying);

        emit Payout(streamId, stream.recipient, claimableUnderlying);
        return claimableUnderlying;
    }


    /**
     * @dev The amount that is claimable for a stream
     * @param streamId The stream to get the claimabout amount for.
     * @return The amount that is claimable for this stream
     */
    function claimable(uint256 streamId)
        external
        view
        returns (uint256 claimableUnderlying)
    {
        Stream memory stream = streams[streamId];
        return _claimable(stream);
    }

    function _claimable(Stream memory stream)
        internal
        view
        returns (uint256 claimableUnderlying)
    {
        uint128 currentTime = uint128(block.timestamp);
        uint128 elapsedTime = currentTime - stream.startTime;
        if (currentTime >= stream.startTime + stream.length) {
            claimableUnderlying = stream.totalAmount - stream.amountPaidOut;
        } else {
            claimableUnderlying = elapsedTime
                .mul(stream.totalAmount)
                .div(stream.length)
                .sub(stream.amountPaidOut);
        }
    }

}

contract MonthlyAllowance {
    using SafeMath for uint256;


    /// @notice Monthly transfer limit - hardcoded to 100,000
    uint256 public constant MONTHLY_LIMIT = 100000 ether;

    /// @notice One month worth of seconds
    uint256 public constant ONE_MONTH = 30 days;

    /// @notice Asset used for payments
    IERC20 public paymentAsset;

    /// @notice Reserves contract to spend from
    address public reserves;

    /// @notice Amount spent per epoch
    mapping(uint256 => uint256) public spentPerEpoch;

    /// @notice Has been initialized
    bool public initialized;

    /// @notice Time initialization happened at - if not initialized, it's 0
    uint256 public timeInitialized;

    /// @notice One way breaker for closing payments from this contract
    bool public breaker;

    /// @notice sub governors
    mapping(address => bool) public isSubGov;

    /// @notice governor
    address public gov;

    /// @notice pending governor
    address public pendingGov;

    /**
     * @notice Event emitted when pendingGov is changed
     */
    event NewPendingGov(
        address oldPendingGov, 
        address newPendingGov
    );

    /**
     * @notice Event emitted when gov is changed
     */
    event NewGov(
        address oldGov, 
        address newGov
    );

    /**
     * @notice Event emitted when a sub gov is enabled/disabled
     */
    event SubGovModified(
        address account, 
        bool isSubGov
    );

    /**
     * @notice Event emitted when a payment is successfully made 
     */
    event Payment(
        address indexed recipient,
        uint256 assetAmount
    );

    modifier onlyGov() {
        require(msg.sender == gov, "MonthlyAllowance::onlyGov: account is not gov");
        _;
    }

    modifier onlyGovOrSubGov() {
        require(msg.sender == gov || isSubGov[msg.sender]);
        _;
    }

    modifier breakerNotSet() {
        require(!breaker, "MonthlyAllowance::breakerNotSet: breaker is set");
        _;
    }
    
    constructor(address _paymentAsset, address _reserves) public {
      gov = msg.sender;
      paymentAsset = IERC20(_paymentAsset);
      reserves = _reserves;
    }

    function initialize()
        public
        onlyGov
    {
        require(!initialized, "MonthlyAllowance::initialize: Contract is already initialized");
        timeInitialized = block.timestamp;
        initialized = true;
    }

    function pay(address recipient, uint256 amount)
        public
        onlyGovOrSubGov
        breakerNotSet
    {
        require(initialized, "MonthlyAllowance::pay: Contract not initialized");
        uint256 epoch = _currentEpoch();
        uint256 newPaidThisEpoch = spentPerEpoch[epoch].add(amount);
        require(newPaidThisEpoch <= MONTHLY_LIMIT, "MonthlyAllowance::pay: Monthly allowance exceeded");
        spentPerEpoch[epoch] = newPaidThisEpoch;
        SafeERC20.safeTransferFrom(paymentAsset, reserves, recipient, amount);
        emit Payment(recipient, amount);
    }

    function currentEpoch()
        public
        returns (uint256)
    {
        return _currentEpoch();
    }

    function _currentEpoch()
        internal
        returns (uint256)
    {
        uint256 timeSinceInitialization = block.timestamp - timeInitialized;
        uint256 epoch = timeSinceInitialization / ONE_MONTH;
        return epoch;
    }

    function flipBreaker()
        public
        onlyGov
        breakerNotSet
    {
        breaker = true;
    }

    function _setPendingGov(address pending)
        public
        onlyGov
    {
        require(pending != address(0));
        address oldPending = pendingGov;
        pendingGov = pending;
        emit NewPendingGov(oldPending, pending);
    }

    function acceptGov()
        public
    {
        require(msg.sender == pendingGov);
        address old = gov;
        gov = pendingGov;
        emit NewGov(old, pendingGov);
    }

    function setIsSubGov(address subGov, bool _isSubGov)
        public
        onlyGov
    {
        isSubGov[subGov] = _isSubGov;
        emit SubGovModified(subGov, _isSubGov);
    }


}

contract YamGoverned {
    event NewGov(address oldGov, address newGov);
    event NewPendingGov(address oldPendingGov, address newPendingGov);

    address public gov;
    address public pendingGov;

    modifier onlyGov {
        require(msg.sender == gov, "!gov");
        _;
    }

    function _setPendingGov(address who)
        public
        onlyGov
    {
        address old = pendingGov;
        pendingGov = who;
        emit NewPendingGov(old, who);
    }

    function _acceptGov()
        public
    {
        require(msg.sender == pendingGov, "!pendingGov");
        address oldgov = gov;
        gov = pendingGov;
        pendingGov = address(0);
        emit NewGov(oldgov, gov);
    }
}

contract YamSubGoverned is YamGoverned {
    /**
     * @notice Event emitted when a sub gov is enabled/disabled
     */
    event SubGovModified(
        address account,
        bool isSubGov
    );
    /// @notice sub governors
    mapping(address => bool) public isSubGov;

    modifier onlyGovOrSubGov() {
        require(msg.sender == gov || isSubGov[msg.sender]);
        _;
    }

    function setIsSubGov(address subGov, bool _isSubGov)
        public
        onlyGov
    {
        isSubGov[subGov] = _isSubGov;
        emit SubGovModified(subGov, _isSubGov);
    }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint private constant Q112 = uint(1) << RESOLUTION;
    uint private constant Q224 = Q112 << RESOLUTION;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint: ZERO_RECIPROCAL');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair,
        bool isToken0
    ) internal view returns (uint priceCumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (isToken0) {
          priceCumulative = IUniswapV2Pair(pair).price0CumulativeLast();

          // if time has elapsed since the last update on the pair, mock the accumulated price values
          if (blockTimestampLast != blockTimestamp) {
              // subtraction overflow is desired
              uint32 timeElapsed = blockTimestamp - blockTimestampLast;
              // addition overflow is desired
              // counterfactual
              priceCumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
          }
        } else {
          priceCumulative = IUniswapV2Pair(pair).price1CumulativeLast();
          // if time has elapsed since the last update on the pair, mock the accumulated price values
          if (blockTimestampLast != blockTimestamp) {
              // subtraction overflow is desired
              uint32 timeElapsed = blockTimestamp - blockTimestampLast;
              // addition overflow is desired
              // counterfactual
              priceCumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
          }
        }

    }
}

interface ExpandedERC20 {
  function decimals() external view returns (uint8);
}

contract TWAPBound is YamSubGoverned {
    using SafeMath for uint256;

    uint256 public constant BASE = 10**18;

    /// @notice For a sale of a specific amount
    uint256 public sell_amount;

    /// @notice For a purchase of a specific amount
    uint256 public purchase_amount;

    /// @notice Token to be sold
    address public sell_token;

    /// @notice Token to be puchased
    address public purchase_token;

    /// @notice Current uniswap pair for purchase & sale tokens
    address public uniswap_pair1;

    /// @notice Second uniswap pair for if TWAP uses two markets to determine price (for liquidity purposes)
    address public uniswap_pair2;

    /// @notice Flag for if purchase token is toke 0 in uniswap pair 2
    bool public purchaseTokenIs0;

    /// @notice Flag for if sale token is token 0 in uniswap pair
    bool public saleTokenIs0;

    /// @notice TWAP for first hop
    uint256 public priceAverageSell;

    /// @notice TWAP for second hop
    uint256 public priceAverageBuy;

    /// @notice last TWAP update time
    uint32 public blockTimestampLast;

    /// @notice last TWAP cumulative price;
    uint256 public priceCumulativeLastSell;

    /// @notice last TWAP cumulative price for two hop pairs;
    uint256 public priceCumulativeLastBuy;

    /// @notice Time between TWAP updates
    uint256 public period;

    /// @notice counts number of twaps
    uint256 public twap_counter;

    /// @notice Grace period after last twap update for a trade to occur
    uint256 public grace = 60 * 60; // 1 hour

    uint256 public constant MAX_BOUND = 10**17;

    /// @notice % bound away from TWAP price
    uint256 public twap_bounds;

    /// @notice denotes a trade as complete
    bool public complete;

    bool public isSale;

    function setup_twap_bound (
        address sell_token_,
        address purchase_token_,
        uint256 amount_,
        bool is_sale,
        uint256 twap_period,
        uint256 twap_bounds_,
        address uniswap1,
        address uniswap2, // if two hop
        uint256 grace_ // length after twap update that it can occur
    )
        public
        onlyGovOrSubGov
    {
        require(twap_bounds_ <= MAX_BOUND, "slippage too high");
        sell_token = sell_token_;
        purchase_token = purchase_token_;
        period = twap_period;
        twap_bounds = twap_bounds_;
        isSale = is_sale;
        if (is_sale) {
            sell_amount = amount_;
            purchase_amount = 0;
        } else {
            purchase_amount = amount_;
            sell_amount = 0;
        }

        complete = false;
        grace = grace_;
        reset_twap(uniswap1, uniswap2, sell_token, purchase_token);
    }

    function reset_twap(
        address uniswap1,
        address uniswap2,
        address sell_token_,
        address purchase_token_
    )
        internal
    {
        uniswap_pair1 = uniswap1;
        uniswap_pair2 = uniswap2;

        blockTimestampLast = 0;
        priceCumulativeLastSell = 0;
        priceCumulativeLastBuy = 0;
        priceAverageBuy = 0;

        if (IUniswapV2Pair(uniswap1).token0() == sell_token_) {
            saleTokenIs0 = true;
        } else {
            saleTokenIs0 = false;
        }

        if (uniswap2 != address(0)) {
            if (IUniswapV2Pair(uniswap2).token0() == purchase_token_) {
                purchaseTokenIs0 = true;
            } else {
                purchaseTokenIs0 = false;
            }
        }

        update_twap();
        twap_counter = 0;
    }

    function quote(
      uint256 purchaseAmount,
      uint256 saleAmount
    )
      public
      view
      returns (uint256)
    {
      uint256 decs = uint256(ExpandedERC20(sell_token).decimals());
      uint256 one = 10**decs;
      return purchaseAmount.mul(one).div(saleAmount);
    }

    function bounds()
        public
        view
        returns (uint256)
    {
        uint256 uniswap_quote = consult();
        uint256 minimum = uniswap_quote.mul(BASE.sub(twap_bounds)).div(BASE);
        return minimum;
    }

    function bounds_max()
        public
        view
        returns (uint256)
    {
        uint256 uniswap_quote = consult();
        uint256 maximum = uniswap_quote.mul(BASE.add(twap_bounds)).div(BASE);
        return maximum;
    }


    function withinBounds (
        uint256 purchaseAmount,
        uint256 saleAmount
    )
        internal
        view
        returns (bool)
    {
        uint256 quoted = quote(purchaseAmount, saleAmount);
        uint256 minimum = bounds();
        uint256 maximum = bounds_max();
        return quoted > minimum && quoted < maximum;
    }

    function withinBoundsWithQuote (
        uint256 quoted
    )
        internal
        view
        returns (bool)
    {
        uint256 minimum = bounds();
        uint256 maximum = bounds_max();
        return quoted > minimum && quoted < maximum;
    }

    // callable by anyone
    function update_twap()
        public
    {
        (uint256 sell_token_priceCumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(uniswap_pair1, saleTokenIs0);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // ensure that at least one full period has passed since the last update
        require(timeElapsed >= period, 'OTC: PERIOD_NOT_ELAPSED');

        // overflow is desired
        priceAverageSell = uint256(uint224((sell_token_priceCumulative - priceCumulativeLastSell) / timeElapsed));
        priceCumulativeLastSell = sell_token_priceCumulative;


        if (uniswap_pair2 != address(0)) {
            // two hop
            (uint256 buy_token_priceCumulative, ) =
                UniswapV2OracleLibrary.currentCumulativePrices(uniswap_pair2, !purchaseTokenIs0);
            priceAverageBuy = uint256(uint224((buy_token_priceCumulative - priceCumulativeLastBuy) / timeElapsed));

            priceCumulativeLastBuy = buy_token_priceCumulative;
        }

        twap_counter = twap_counter.add(1);

        blockTimestampLast = blockTimestamp;
    }

    function consult()
        public
        view
        returns (uint256)
    {
        if (uniswap_pair2 != address(0)) {
            // two hop
            uint256 purchasePrice;
            uint256 salePrice;
            uint256 one;
            if (saleTokenIs0) {
                uint8 decs = ExpandedERC20(sell_token).decimals();
                require(decs <= 18, "too many decimals");
                one = 10**uint256(decs);
            } else {
                uint8 decs = ExpandedERC20(sell_token).decimals();
                require(decs <= 18, "too many decimals");
                one = 10**uint256(decs);
            }

            if (priceAverageSell > uint192(-1)) {
               // eat loss of precision
               // effectively: (x / 2**112) * 1e18
               purchasePrice = (priceAverageSell >> 112) * one;
            } else {
              // cant overflow
              // effectively: (x * 1e18 / 2**112)
              purchasePrice = (priceAverageSell * one) >> 112;
            }

            if (purchaseTokenIs0) {
                uint8 decs = ExpandedERC20(IUniswapV2Pair(uniswap_pair2).token1()).decimals();
                require(decs <= 18, "too many decimals");
                one = 10**uint256(decs);
            } else {
                uint8 decs = ExpandedERC20(IUniswapV2Pair(uniswap_pair2).token0()).decimals();
                require(decs <= 18, "too many decimals");
                one = 10**uint256(decs);
            }

            if (priceAverageBuy > uint192(-1)) {
                salePrice = (priceAverageBuy >> 112) * one;
            } else {
                salePrice = (priceAverageBuy * one) >> 112;
            }

            return purchasePrice.mul(salePrice).div(one);

        } else {
            uint256 one;
            if (saleTokenIs0) {
                uint8 decs = ExpandedERC20(sell_token).decimals();
                require(decs <= 18, "too many decimals");
                one = 10**uint256(decs);
            } else {
                uint8 decs = ExpandedERC20(sell_token).decimals();
                require(decs <= 18, "too many decimals");
                one = 10**uint256(decs);
            }
            // single hop
            uint256 purchasePrice;
            if (priceAverageSell > uint192(-1)) {
               // eat loss of precision
               // effectively: (x / 2**112) * 1e18
               purchasePrice = (priceAverageSell >> 112) * one;
            } else {
                // cant overflow
                // effectively: (x * 1e18 / 2**112)
                purchasePrice = (priceAverageSell * one) >> 112;
            }
            return purchasePrice;
        }
    }

    function recencyCheck()
        internal
        returns (bool)
    {
        return (block.timestamp - blockTimestampLast < grace) && (twap_counter > 0);
    }
}

/// Helper for a reserve contract to perform uniswap, price bound actions
contract ReserveUniHelper is TWAPBound {

    event NewReserves(address oldReserves, address NewReserves);

    address public reserves;

    function _getLPToken()
        internal
    {
        require(!complete, "Action complete");

        uint256 amount_;
        if (isSale) {
          amount_ = sell_amount;
        } else {
          amount_ = purchase_amount;
        }
        // early return
        if (amount_ == 0) {
          complete = true;
          return;
        }

        require(recencyCheck(), "TWAP needs updating");

        uint256 bal_of_a = IERC20(sell_token).balanceOf(reserves);
        
        if (amount_ > bal_of_a) {
            // cap to bal
            amount_ = bal_of_a;
        }

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(uniswap_pair1).getReserves();
        uint256 quoted;
        if (saleTokenIs0) {
            quoted = quote(reserve1, reserve0);
            require(withinBoundsWithQuote(quoted), "!in_bounds, uni reserve manipulation");
        } else {
            quoted = quote(reserve0, reserve1);
            require(withinBoundsWithQuote(quoted), "!in_bounds, uni reserve manipulation");
        }

        uint256 amount_b;
        {
          uint256 decs = uint256(ExpandedERC20(sell_token).decimals());
          uint256 one = 10**decs;
          amount_b = quoted.mul(amount_).div(one);
        }


        uint256 bal_of_b = IERC20(purchase_token).balanceOf(reserves);
        if (amount_b > bal_of_b) {
            // we set the limit token as the sale token, but that could change
            // between proposal and execution.
            // limit amount_ and amount_b
            amount_b = bal_of_b;

            // reverse quote
            if (!saleTokenIs0) {
                quoted = quote(reserve1, reserve0);
            } else {
                quoted = quote(reserve0, reserve1);
            }
            // recalculate a
            uint256 decs = uint256(ExpandedERC20(purchase_token).decimals());
            uint256 one = 10**decs;
            amount_ = quoted.mul(amount_b).div(one);
        }

        IERC20(sell_token).transferFrom(reserves, uniswap_pair1, amount_);
        IERC20(purchase_token).transferFrom(reserves, uniswap_pair1, amount_b);
        IUniswapV2Pair(uniswap_pair1).mint(address(this));
        complete = true;
    }

    function _getUnderlyingToken(
        bool skip_this
    )
        internal
    {
        require(!complete, "Action complete");
        require(recencyCheck(), "TWAP needs updating");

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(uniswap_pair1).getReserves();
        uint256 quoted;
        if (saleTokenIs0) {
            quoted = quote(reserve1, reserve0);
            require(withinBoundsWithQuote(quoted), "!in_bounds, uni reserve manipulation");
        } else {
            quoted = quote(reserve0, reserve1);
            require(withinBoundsWithQuote(quoted), "!in_bounds, uni reserve manipulation");
        }

        // transfer lp tokens back, burn
        if (skip_this) {
          IERC20(uniswap_pair1).transfer(uniswap_pair1, IERC20(uniswap_pair1).balanceOf(address(this)));
          IUniswapV2Pair(uniswap_pair1).burn(reserves);
        } else {
          IERC20(uniswap_pair1).transfer(uniswap_pair1, IERC20(uniswap_pair1).balanceOf(address(this)));
          IUniswapV2Pair(uniswap_pair1).burn(address(this));
        }
        complete = true;
    }

    function _setReserves(address new_reserves)
        public
        onlyGovOrSubGov
    {
        address old_res = reserves;
        reserves = new_reserves;
        emit NewReserves(old_res, reserves);
    }
}

interface IndexStaker {
    function stake(uint256) external;
    function withdraw(uint256) external;
    function getReward() external;
    function exit() external;
    function balanceOf(address) external view returns (uint256);
}

contract IndexStaking2 is ReserveUniHelper {

    constructor(address pendingGov_, address reserves_) public {
        gov = msg.sender;
        pendingGov = pendingGov_;
        reserves = reserves_;
        IERC20(lp).approve(address(staking), uint256(-1));
    }

    IndexStaker public staking = IndexStaker(0xB93b505Ed567982E2b6756177ddD23ab5745f309);

    address public lp = address(0x4d5ef58aAc27d99935E5b6B4A6778ff292059991);

    function currentStake()
        public
        view
        returns (uint256)
    {
        return staking.balanceOf(address(this));
    }

    // callable by anyone assuming twap bounds checks
    function stake()
        public
    {
        _getLPToken();
        uint256 amount = IERC20(lp).balanceOf(address(this));
        staking.stake(amount);
    }

    // callable by anyone assuming twap bounds checks
    function getUnderlying()
        public
    {
        _getUnderlyingToken(true);
    }

    // ========= STAKING ========
    function _stakeCurrentLPBalance()
        public
        onlyGovOrSubGov
    {
        uint256 amount = IERC20(lp).balanceOf(address(this));
        staking.stake(amount);
    }

    function _approveStakingFromReserves(
        bool isToken0Limited,
        uint256 amount
    )
        public
        onlyGovOrSubGov
    {
        if (isToken0Limited) {
          setup_twap_bound(
              IUniswapV2Pair(lp).token0(), // The limiting asset
              IUniswapV2Pair(lp).token1(),
              amount, // amount of token0
              true, // is sale
              60 * 60, // 1 hour
              5 * 10**15, // .5%
              lp,
              address(0), // if two hop
              60 * 60 // length after twap update that it can occur
          );
        } else {
          setup_twap_bound(
              IUniswapV2Pair(lp).token1(), // The limiting asset
              IUniswapV2Pair(lp).token0(),
              amount, // amount of token1
              true, // is sale
              60 * 60, // 1 hour
              5 * 10**15, // .5%
              lp,
              address(0), // if two hop
              60 * 60 // length after twap update that it can occur
          );
        }
    }
    // ============================

    // ========= EXITING ==========
    function _exitStaking()
        public
        onlyGovOrSubGov
    {
        staking.exit();
    }

    function _exitAndApproveGetUnderlying()
        public
        onlyGovOrSubGov
    {
        staking.exit();
        setup_twap_bound(
            IUniswapV2Pair(lp).token0(), // doesnt really matter
            IUniswapV2Pair(lp).token1(), // doesnt really matter
            staking.balanceOf(address(this)), // amount of LP tokens
            true, // is sale
            60 * 60, // 1 hour
            5 * 10**15, // .5%
            lp,
            address(0), // if two hop
            60 * 60 // length after twap update that it can occur
        );
    }

    function _exitStakingEmergency()
        public
        onlyGovOrSubGov
    {
        staking.withdraw(staking.balanceOf(address(this)));
    }

    function _exitStakingEmergencyAndApproveGetUnderlying()
        public
        onlyGovOrSubGov
    {
        staking.withdraw(staking.balanceOf(address(this)));
        setup_twap_bound(
            IUniswapV2Pair(lp).token0(), // doesnt really matter
            IUniswapV2Pair(lp).token1(), // doesnt really matter
            staking.balanceOf(address(this)), // amount of LP tokens
            true, // is sale
            60 * 60, // 1 hour
            5 * 10**15, // .5%
            lp,
            address(0), // if two hop
            60 * 60 // length after twap update that it can occur
        );
    }
    // ============================


    function _getTokenFromHere(address token)
        public
        onlyGovOrSubGov
    {
        IERC20 t = IERC20(token);
        t.transfer(reserves, t.balanceOf(address(this)));
    }
}

interface UniRouter2 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

contract TWAPBoundLib {
    using SafeMath for uint256;

    uint256 public constant BASE = 10**18;

    function getCurrentDestinationAmount(
        IUniswapV2Pair pool1,
        IUniswapV2Pair pool2,
        address sourceToken,
        address destinationToken,
        uint256 sourceAmount
    ) internal view returns (uint256) {
        bool sourceIsToken0 = pool1.token0() == sourceToken;
        uint256 inReserves;
        uint256 outReserves;
        (inReserves, outReserves, ) = pool1.getReserves();
        uint256 destinationAmount = UniswapV2Library.getAmountOut(
            sourceAmount,
            sourceIsToken0 ? inReserves : outReserves,
            sourceIsToken0 ? outReserves : inReserves
        );
        if (address(pool2) != address(0x0)) {
            bool middleIsToken0 = pool2.token1() == destinationToken;
            (inReserves, outReserves, ) = pool2.getReserves();
            destinationAmount = UniswapV2Library.getAmountOut(
                destinationAmount,
                middleIsToken0 ? inReserves : outReserves,
                middleIsToken0 ? outReserves : inReserves
            );
        }
        return destinationAmount;
    }

    event TestTWAPDestinationAmount(
        uint256 twap,
        uint256 minimum,
        uint256 obtained
    );

    function withinBounds(
        IUniswapV2Pair pool1,
        IUniswapV2Pair pool2,
        address sourceToken,
        address destinationToken,
        uint256 sourceAmount,
        uint256 destinationAmount,
        uint256 lastCumulativePricePool1,
        uint256 lastCumulativePricePool2,
        uint256 timeSinceLastCumulativePriceUpdate,
        uint64 slippageLimit
    ) internal returns (bool) {
        uint256 twapDestinationAmount = getTWAPDestinationAmount(
            pool1,
            pool2,
            sourceToken,
            destinationToken,
            sourceAmount,
            lastCumulativePricePool1,
            lastCumulativePricePool2,
            timeSinceLastCumulativePriceUpdate
        );
        uint256 minimum = twapDestinationAmount.mul(BASE.sub(slippageLimit)).div(
            BASE
        );
        emit TestTWAPDestinationAmount(
            twapDestinationAmount,
            minimum,
            destinationAmount
        );
        return destinationAmount >= minimum;
    }

    // Returns the current cumulative prices for pool1 and pool2. cumulativePricePool2 will be 0 if there is no pool 2
    function getCumulativePrices(
        IUniswapV2Pair pool1,
        IUniswapV2Pair pool2,
        address sourceToken,
        address destinationToken
    )
        internal
        view
        returns (uint256 cumulativePricePool1, uint256 cumulativePricePool2)
    {
        (cumulativePricePool1, ) = UniswapV2OracleLibrary
            .currentCumulativePrices(
                address(pool1),
                pool1.token0() == sourceToken
            );

        if (address(pool2) != address(0x0)) {
            // For when 2 pools are used
            (cumulativePricePool2, ) = UniswapV2OracleLibrary
                .currentCumulativePrices(
                    address(pool2),
                    pool2.token1() == destinationToken
                );
        }
    }

    // Returns the current TWAP
    function getTWAPDestinationAmount(
        IUniswapV2Pair pool1,
        IUniswapV2Pair pool2,
        address sourceToken,
        address destinationToken,
        uint256 sourceAmount,
        uint256 lastCumulativePricePool1,
        uint256 lastCumulativePricePool2,
        uint256 timeSinceLastCumulativePriceUpdate
    ) internal view returns (uint256 price) {
        uint256 cumulativePricePool1;
        uint256 cumulativePricePool2;
        (cumulativePricePool1, cumulativePricePool2) = getCumulativePrices(
            pool1,
            pool2,
            sourceToken,
            destinationToken
        );
        uint256 priceAverageHop1 = uint256(
            uint224(
                (cumulativePricePool1 - lastCumulativePricePool1) /
                    timeSinceLastCumulativePriceUpdate
            )
        );

        if (priceAverageHop1 > uint192(-1)) {
            // eat loss of precision
            // effectively: (x / 2**112) * 1e18
            priceAverageHop1 = (priceAverageHop1 >> 112) * BASE;
        } else {
            // cant overflow
            // effectively: (x * 1e18 / 2**112)
            priceAverageHop1 = (priceAverageHop1 * BASE) >> 112;
        }

        uint256 outputAmount = sourceAmount.mul(priceAverageHop1).div(BASE);

        if (address(pool2) != address(0)) {
            uint256 priceAverageHop2 = uint256(
                uint224(
                    (cumulativePricePool2 - lastCumulativePricePool2) /
                        timeSinceLastCumulativePriceUpdate
                )
            );

            if (priceAverageHop2 > uint192(-1)) {
                // eat loss of precision
                // effectively: (x / 2**112) * 1e18
                priceAverageHop2 = (priceAverageHop2 >> 112) * BASE;
            } else {
                // cant overflow
                // effectively: (x * 1e18 / 2**112)
                priceAverageHop2 = (priceAverageHop2 * BASE) >> 112;
            }

            outputAmount = outputAmount.mul(priceAverageHop2).div(BASE);
        }
        return outputAmount;
    }
}

// Swapper allows the governor to create swaps
// A swap executes trustlessly and minimizes slippage to a set amount by using TWAPs
// Swaps can be broken up, TWAPs repeatedly updated, etc. 
// Anyone can update TWAPs or execute a swap
contract Swapper is YamSubGoverned, TWAPBoundLib {
    /** Structs */
    struct SwapParams {
        address sourceToken;
        address destinationToken;
        address router;
        address pool1;
        address pool2;
        uint128 sourceAmount;
        uint64 slippageLimit;
    }

    struct SwapState {
        SwapParams params;
        uint256 lastCumulativePriceUpdate;
        uint256 lastCumulativePricePool1;
        uint256 lastCumulativePricePool2;
    }

    /** Constants */
    uint64 private constant MIN_TWAP_TIME = 1 hours;
    uint64 private constant MAX_TWAP_TIME = 3 hours;

    /** State */
    SwapState[] public swaps;

    address public reserves;

    constructor(address _gov, address _reserves) public {
        gov = _gov;
        reserves = _reserves;
    }

    /** Gov functions */
    function addSwap(SwapParams calldata params) external onlyGovOrSubGov {
        swaps.push(
            SwapState({
                params: params,
                lastCumulativePriceUpdate: 0,
                lastCumulativePricePool1: 0,
                lastCumulativePricePool2: 0
            })
        );
    }
 
    function setReserves(address _reserves) external onlyGovOrSubGov {
        reserves = _reserves;
    }
    function removeSwap(uint16 index) external onlyGovOrSubGov {
        _removeSwap(index);
    }

    /** Execution functions */

    function execute(
        uint16 swapId,
        uint128 amountToTrade,
        uint256 minDestinationAmount
    ) external {
        SwapState memory swap = swaps[swapId];
        // Check if there is any left to trade
        require(swap.params.sourceAmount > 0);
        // Can't be trying to trade more than the remaining amount
        require(amountToTrade <= swap.params.sourceAmount);
        uint256 timestamp = block.timestamp;
        uint256 timeSinceLastCumulativePriceUpdate = timestamp -
            swap.lastCumulativePriceUpdate;
        // Require that the cumulative prices were last updated between MIN_TWAP_TIME and MAX_TWAP_TIME
        require(
            timeSinceLastCumulativePriceUpdate >= MIN_TWAP_TIME &&
                timeSinceLastCumulativePriceUpdate <= MAX_TWAP_TIME
        );
        IERC20(swap.params.sourceToken).transferFrom(
            reserves,
            address(this),
            amountToTrade
        );
        if (
            IERC20(swap.params.sourceToken).allowance(
                address(this),
                swap.params.router
            ) < amountToTrade
        ) {
            IERC20(swap.params.sourceToken).approve(
                swap.params.router,
                uint256(-1)
            );
        }
        address[] memory path;
        if (swap.params.pool2 == address(0x0)) {
            path = new address[](2);
            path[0] = swap.params.sourceToken;
            path[1] = swap.params.destinationToken;
        } else {
            address token0 = IUniswapV2Pair(swap.params.pool1).token0();
            path = new address[](3);
            path[0] = swap.params.sourceToken;
            path[1] = token0 == swap.params.sourceToken
                ? IUniswapV2Pair(swap.params.pool1).token1()
                : token0;
            path[2] = swap.params.destinationToken;
        }
        uint256[] memory amounts = UniRouter2(swap.params.router)
            .swapExactTokensForTokens(
                uint256(amountToTrade),
                minDestinationAmount,
                path,
                reserves,
                timestamp
            );

        require(
            TWAPBoundLib.withinBounds(
                IUniswapV2Pair(swap.params.pool1),
                IUniswapV2Pair(swap.params.pool2),
                swap.params.sourceToken,
                swap.params.destinationToken,
                uint256(amountToTrade),
                amounts[amounts.length - 1],
                swap.lastCumulativePricePool1,
                swap.lastCumulativePricePool2,
                timeSinceLastCumulativePriceUpdate,
                swap.params.slippageLimit
            )
        );
        if(amountToTrade == swap.params.sourceAmount){
            _removeSwap(swapId);
        } else {
            swaps[swapId].params.sourceAmount -= amountToTrade;
        }
    }

    function updateCumulativePrice(uint16 swapId) external {
        SwapState memory swap = swaps[swapId];
        uint256 timestamp = block.timestamp;
        require(timestamp - swap.lastCumulativePriceUpdate > MAX_TWAP_TIME);
        (
            swaps[swapId].lastCumulativePricePool1,
            swaps[swapId].lastCumulativePricePool2
        ) = TWAPBoundLib.getCumulativePrices(
            IUniswapV2Pair(swap.params.pool1),
            IUniswapV2Pair(swap.params.pool2),
            swap.params.sourceToken,
            swap.params.destinationToken
        );
        swaps[swapId].lastCumulativePriceUpdate = timestamp;
    }

    /** Internal functions */

    function _removeSwap(uint16 index) internal {
        swaps[index] = SwapState({
            params: SwapParams(
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000,
                0x0000000000000000000000000000000000000000,
                0,
                0
            ),
            lastCumulativePriceUpdate: 0,
            lastCumulativePricePool1: 0,
            lastCumulativePricePool2: 0
        });
    }
}

contract Proposal {
    VestingPool internal constant pool =
        VestingPool(0xDCf613db29E4d0B35e7e15e93BF6cc6315eB0b82);

    IERC20 internal constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    IERC20 internal constant YAM =
        IERC20(0x0AaCfbeC6a24756c20D41914F2caba817C0d8521);

    IERC20 internal constant INDEX =
        IERC20(0x0954906da0Bf32d5479e25f46056d22f08464cab);

    Swapper internal constant SWAPPER =
        Swapper(0xB4E5BaFf059C5CE3a0EE7ff8e9f16ca9dd91F1fE);

    address internal constant RESERVES =
        0x97990B693835da58A281636296D2Bf02787DEa17;

    IndexStaking2 internal constant INDEX_STAKING =
        IndexStaking2(0x205Cc7463267861002b27021C7108Bc230603d0F);

    function execute() public {
        USDC.transferFrom(
            0x97990B693835da58A281636296D2Bf02787DEa17,
            address(this),
            58250 * (10**6)
        ); // Monthly contributors
        USDC.transfer(
            0x8A8acf1cEcC4ed6Fe9c408449164CE2034AdC03f,
            yearlyUSDToMonthlyUSD(120000 * (10**6))
        );
        USDC.transfer(
            0xEC3281124d4c2FCA8A88e3076C1E7749CfEcb7F2,
            yearlyUSDToMonthlyUSD(105000 * (10**6))
        );
        USDC.transfer(
            0x01e0C7b70E0E05a06c7cC8deeb97Fa03d6a77c9C,
            yearlyUSDToMonthlyUSD(84000 * (10**6))
        );
        USDC.transfer(
            0xcc506b3c2967022094C3B00276617883167BF32B,
            yearlyUSDToMonthlyUSD(30000 * (10**6))
        );
        USDC.transfer(
            0x3FdcED6B5C1f176b543E5E0b841cB7224596C33C,
            yearlyUSDToMonthlyUSD(96000 * (10**6))
        );
        USDC.transfer(
            0x9098eab0a361D29Ea5c4b5d9d1f50694ac0E9e78,
            yearlyUSDToMonthlyUSD(36000 * (10**6))
        );
        USDC.transfer(
            0xFcB4f3a1710FefA583e7b003F3165f2E142bC725,
            yearlyUSDToMonthlyUSD(60000 * (10**6))
        );
        USDC.transfer(
            0x31920DF2b31B5f7ecf65BDb2c497DE31d299d472,
            yearlyUSDToMonthlyUSD(60000 * (10**6))
        );
        USDC.transfer(
            0x43fD74401B4BF04095590a5308B6A5e3Db44b9e3,
            yearlyUSDToMonthlyUSD(48000 * (10**6))
        );
        USDC.transfer(
            0xC45d45b54045074Ed12d1Fe127f714f8aCE46f8c,
            yearlyUSDToMonthlyUSD(60000 * (10**6))
        );

        // YIP-79v2 50k YAM to treasury multisig
        pool.payout(
            pool.openStream(
                0x744D16d200175d20E6D8e5f405AEfB4EB7A962d1,
                0,
                20000 * (10**24)
            )
        );

        // Designer backpay stream
        pool.payout(
            pool.openStream(
                0x3FdcED6B5C1f176b543E5E0b841cB7224596C33C,
                0,
                ((block.timestamp - 1626019344) * 1500 * (10**24)) / (30 days)
            )
        );

        // Designer new stream
        pool.openStream(
            0x3FdcED6B5C1f176b543E5E0b841cB7224596C33C,
            90 days,
            1500 * (10**24) * 3
        );

        // Sushiswap 2 hop SUSHI to ETH to USDC
        SWAPPER.addSwap(
            Swapper.SwapParams({
                sourceToken: 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2,
                destinationToken: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                router: 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F,
                pool1: 0x795065dCc9f64b5614C407a6EFDC400DA6221FB0,
                pool2: 0x397FF1542f962076d0BFE58eA045FfA2d347ACa0,
                sourceAmount: 33733 * (10**18),
                slippageLimit: 1 * (10**16)
            })
        );

        // Uniswap 1 hop WETH to USDC
        SWAPPER.addSwap(
            Swapper.SwapParams({
                sourceToken: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
                destinationToken: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                router: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
                pool1: 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc,
                pool2: address(0x0),
                sourceAmount: 120 * (10**18),
                slippageLimit: 1 * (10**16)
            })
        );

        // Uniswap 2 hop DPI to ETH to USDC
        SWAPPER.addSwap(
            Swapper.SwapParams({
                sourceToken: 0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b,
                destinationToken: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                router: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
                pool1: 0x4d5ef58aAc27d99935E5b6B4A6778ff292059991,
                pool2: 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc,
                sourceAmount: 928 * (10**18),
                slippageLimit:2 * (10**16)
            })
        );

        INDEX_STAKING._exitAndApproveGetUnderlying();
        INDEX_STAKING._getTokenFromHere(address(INDEX));
        selfdestruct(address(0x0));
    }

    function yearlyUSDToMonthlyUSD(uint256 yearlyUSD)
        internal
        pure
        returns (uint256)
    {
        return ((yearlyUSD / uint256(12)));
    }
}