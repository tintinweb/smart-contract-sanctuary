/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-23
*/

// File: contracts/IRebaser.sol

pragma solidity 0.5.16;

interface IRebaser {

  function checkRebase() external;

}

// File: contracts/token/GovernanceStorage.sol

pragma solidity 0.5.16;


/* Copyright 2020 Compound Labs, Inc.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */


contract GovernanceStorage {
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
}

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: contracts/token/TokenStorage.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;


contract TokenStorage {

  using SafeMath for uint256;

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
   * @notice Total supply of YAMs
   */
  uint256 public totalSupply;

  /**
   * @notice Internal decimals used to handle scaling factor
   */
  uint256 public constant internalDecimals = 10 ** 24;

  /**
   * @notice Used for percentage maths
   */
  uint256 public constant BASE = 10 ** 18;

  /**
   * @notice Scaling factor that adjusts everyone's balances
   */
  uint256 public auscsScalingFactor;

  mapping(address => uint256) internal _auscBalances;

  mapping(address => mapping(address => uint256)) internal _allowedFragments;

  uint256 public initSupply;
}

// File: contracts/token/TokenInterface.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;



contract TokenInterface is TokenStorage, GovernanceStorage {

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Event emitted when tokens are rebased
     */
    event Rebase(uint256 epoch, uint256 prevAuscsScalingFactor, uint256 newAuscsScalingFactor);

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
    event Burn(address from, uint256 amount);

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
    function auscToFragment(uint256 ausc) external view returns (uint256);
    function fragmentToAusc(uint256 value) external view returns (uint256);

    /* - Governance Functions - */
    function getPriorVotes(address account, uint blockNumber) external view returns (uint256);
//    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;
    function delegate(address delegatee) external;
    function delegates(address delegator) external view returns (address);
    function getCurrentVotes(address account) external view returns (uint256);

    /* - Permissioned/Governance functions - */
    function mint(address to, uint256 amount) external returns (bool);
    function rebase(uint256 epoch, uint256 indexDelta, bool positive) external returns (uint256);
    function _setRebaser(address rebaser_) external;
    function _setPendingGov(address pendingGov_) external;
    function _acceptGov() external;
}

// File: contracts/token/Governance.sol

pragma solidity 0.5.16;


/* Copyright 2020 Compound Labs, Inc.

Redistribution and use in source and binary forms, with or without modification, are permitted
provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions
and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions
and the following disclaimer in the documentation and/or other materials provided with the
distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse
or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */



contract GovernanceToken is TokenInterface {

    /// @notice An event emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event emitted when a delegate account's vote balance changes
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
        require(blockNumber < block.number, "AUSC::getPriorVotes: not yet determined");

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
        uint256 delegatorBalance = _auscBalances[delegator]; // balance of underlying YAMs (not scaled);
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
        uint32 blockNumber = safe32(block.number, "AUSC::_writeCheckpoint: block number exceeds 32 bits");

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
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

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

// File: contracts/AUSC.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.5.16;




contract AUSCToken is GovernanceToken {

  // Modifiers
  modifier onlyGov() {
    require(msg.sender == gov, "only governance");
    _;
  }

  modifier onlyRebaser() {
    require(msg.sender == rebaser);
    _;
  }

  modifier rebaseAtTheEnd() {
    _;
    if (msg.sender == tx.origin && rebaser != address(0)) {
      IRebaser(rebaser).checkRebase();
    }
  }

  modifier onlyMinter() {
    require(
      msg.sender == rebaser || msg.sender == gov,
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
    require(auscsScalingFactor == 0, "already initialized");
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
    // scaling factor can only go up to 2**256-1 = initSupply * auscsScalingFactor
    // this is used to check if auscsScalingFactor will be too high to compute balances when rebasing.
    return uint256(- 1) / initSupply;
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
    // increase totalSupply
    totalSupply = totalSupply.add(amount);

    // get underlying value
    uint256 auscValue = fragmentToAusc(amount);

    // increase initSupply
    initSupply = initSupply.add(auscValue);

    // make sure the mint didnt push maxScalingFactor too low
    require(auscsScalingFactor <= _maxScalingFactor(), "max scaling factor too low");

    // add balance
    _auscBalances[to] = _auscBalances[to].add(auscValue);

    // add delegates to the minter
    _moveDelegates(address(0), _delegates[to], auscValue);
    emit Mint(to, amount);
    emit Transfer(address(0), to, amount);
  }

  /**
  * @notice Burns tokens, decreasing totalSupply, initSupply, and a users balance.
  */
  function burn(uint256 amount)
  external
  returns (bool)
  { 
    _burn(msg.sender, amount);
    return true;
  }

  function _burn(address from, uint256 amount)
  internal
  {
    // increase totalSupply
    totalSupply = totalSupply.sub(amount);

    // get underlying value
    uint256 auscValue = fragmentToAusc(amount);

    // increase initSupply
    initSupply = initSupply.sub(auscValue);

    // make sure the burn didnt push maxScalingFactor too low
    require(auscsScalingFactor <= _maxScalingFactor(), "max scaling factor too low");

    // sub balance, will revert on underflow
    _auscBalances[from] = _auscBalances[from].sub(auscValue);

    // remove delegates from the minter
    _moveDelegates(_delegates[from], address(0), auscValue);
    emit Burn(from, amount);
    emit Transfer(from, address(0), amount);
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
  rebaseAtTheEnd
  returns (bool)
  {
    // underlying balance is stored in auscs, so divide by current scaling factor

    // note, this means as scaling factor grows, dust will be untransferrable.
    // minimum transfer value == auscsScalingFactor / 1e24;

    // get amount in underlying
    uint256 auscValue = fragmentToAusc(value);

    // sub from balance of sender
    _auscBalances[msg.sender] = _auscBalances[msg.sender].sub(auscValue);

    // add to balance of receiver
    _auscBalances[to] = _auscBalances[to].add(auscValue);
    emit Transfer(msg.sender, to, value);

    _moveDelegates(_delegates[msg.sender], _delegates[to], auscValue);
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
  rebaseAtTheEnd
  validRecipient(to)
  returns (bool)
  {
    // decrease allowance
    _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

    // get value in auscs
    uint256 auscValue = fragmentToAusc(value);

    // sub from from
    _auscBalances[from] = _auscBalances[from].sub(auscValue);
    _auscBalances[to] = _auscBalances[to].add(auscValue);
    emit Transfer(from, to, value);

    _moveDelegates(_delegates[from], _delegates[to], auscValue);
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
    return auscToFragment(_auscBalances[who]);
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
    return _auscBalances[who];
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
  rebaseAtTheEnd
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
  rebaseAtTheEnd
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
  rebaseAtTheEnd
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

  /** @notice lets msg.sender accept governance
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
      emit Rebase(epoch, auscsScalingFactor, auscsScalingFactor);
      return totalSupply;
    }

    // for events
    uint256 prevAuscsScalingFactor = auscsScalingFactor;


    if (!positive) {
      // negative rebase, decrease scaling factor
      auscsScalingFactor = auscsScalingFactor.mul(BASE.sub(indexDelta)).div(BASE);
    } else {
      // positive reabse, increase scaling factor
      uint256 newScalingFactor = auscsScalingFactor.mul(BASE.add(indexDelta)).div(BASE);
      if (newScalingFactor < _maxScalingFactor()) {
        auscsScalingFactor = newScalingFactor;
      } else {
        auscsScalingFactor = _maxScalingFactor();
      }
    }

    // update total supply, correctly
    totalSupply = auscToFragment(initSupply);

    emit Rebase(epoch, prevAuscsScalingFactor, auscsScalingFactor);
    return totalSupply;
  }

  function auscToFragment(uint256 ausc)
  public
  view
  returns (uint256)
  {
    return ausc.mul(auscsScalingFactor).div(internalDecimals);
  }

  function fragmentToAusc(uint256 value)
  public
  view
  returns (uint256)
  {
    return value.mul(internalDecimals).div(auscsScalingFactor);
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

contract AUSC is AUSCToken {

  constructor() public {}

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

    auscsScalingFactor = BASE;
    initSupply = fragmentToAusc(initTotalSupply_);
    totalSupply = initTotalSupply_;
    _auscBalances[initial_owner] = initSupply;
    gov = initial_owner;
  }
}