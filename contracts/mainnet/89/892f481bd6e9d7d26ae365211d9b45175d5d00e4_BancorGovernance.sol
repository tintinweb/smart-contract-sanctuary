// File: @bancor/contracts-solidity/solidity/contracts/utility/interfaces/IOwned.sol

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/*
    Owned contract interface
*/
interface IOwned {
    // this function isn't since the compiler emits automatically generated getter functions as external
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;
    function acceptOwnership() external;
}

// File: @bancor/contracts-solidity/solidity/contracts/utility/Owned.sol


pragma solidity 0.6.12;


/**
  * @dev Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public override owner;
    address public newOwner;

    /**
      * @dev triggered when the owner is updated
      *
      * @param _prevOwner previous owner
      * @param _newOwner  new owner
    */
    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
      * @dev initializes a new Owned instance
    */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        _ownerOnly();
        _;
    }

    // error message binary size optimization
    function _ownerOnly() internal view {
        require(msg.sender == owner, "ERR_ACCESS_DENIED");
    }

    /**
      * @dev allows transferring the contract ownership
      * the new owner still needs to accept the transfer
      * can only be called by the contract owner
      *
      * @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public override ownerOnly {
        require(_newOwner != owner, "ERR_SAME_OWNER");
        newOwner = _newOwner;
    }

    /**
      * @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() override public {
        require(msg.sender == newOwner, "ERR_ACCESS_DENIED");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// File: @openzeppelin/contracts/math/Math.sol



pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.6.2;

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity ^0.6.0;




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

// File: contracts/interfaces/IExecutor.sol


pragma solidity 0.6.12;

interface IExecutor {
    function execute(
        uint256 _id,
        uint256 _for,
        uint256 _against,
        uint256 _quorum
    ) external;
}

// File: contracts/BancorGovernance.sol



/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: YFIRewards.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
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
pragma solidity 0.6.12;






/**
 * @title The Bancor Governance Contract
 *
 * Big thanks to synthetix / yearn.finance for the initial version!
 */
contract BancorGovernance is Owned {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint32 internal constant PPM_RESOLUTION = 1000000;

    struct Proposal {
        uint256 id;
        mapping(address => uint256) votesFor;
        mapping(address => uint256) votesAgainst;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        uint256 start; // start timestmp;
        uint256 end; // start + voteDuration
        uint256 totalAvailableVotes;
        uint256 quorum;
        uint256 quorumRequired;
        bool open;
        bool executed;
        address proposer;
        address executor;
        string hash;
    }

    /**
     * @notice triggered when a new proposal is created
     *
     * @param _id       proposal id
     * @param _start    voting start timestamp
     * @param _duration voting duration
     * @param _proposer proposal creator
     * @param _executor contract that will exeecute the proposal once it passes
     */
    event NewProposal(
        uint256 indexed _id,
        uint256 _start,
        uint256 _duration,
        address _proposer,
        address _executor
    );

    /**
     * @notice triggered when voting on a proposal has ended
     *
     * @param _id               proposal id
     * @param _for              number of votes for the proposal
     * @param _against          number of votes against the proposal
     * @param _quorumReached    true if quorum was reached, false otherwise
     */
    event ProposalFinished(
        uint256 indexed _id,
        uint256 _for,
        uint256 _against,
        bool _quorumReached
    );

    /**
     * @notice triggered when a proposal was successfully executed
     *
     * @param _id       proposal id
     * @param _executor contract that will execute the proposal once it passes
     */
    event ProposalExecuted(uint256 indexed _id, address indexed _executor);

    /**
     * @notice triggered when a stake has been added to the contract
     *
     * @param _user     staker address
     * @param _amount   staked amount
     */
    event Staked(address indexed _user, uint256 _amount);

    /**
     * @notice triggered when a stake has been removed from the contract
     *
     * @param _user     staker address
     * @param _amount   unstaked amount
     */
    event Unstaked(address indexed _user, uint256 _amount);

    /**
     * @notice triggered when a user votes on a proposal
     *
     * @param _id       proposal id
     * @param _voter    voter addrerss
     * @param _vote     true if the vote is for the proposal, false otherwise
     * @param _weight   number of votes
     */
    event Vote(uint256 indexed _id, address indexed _voter, bool _vote, uint256 _weight);

    /**
     * @notice triggered when the quorum is updated
     *
     * @param _quorum   new quorum
     */
    event QuorumUpdated(uint256 _quorum);

    /**
     * @notice triggered when the minimum stake required to create a new proposal is updated
     *
     * @param _minimum  new minimum
     */
    event NewProposalMinimumUpdated(uint256 _minimum);

    /**
     * @notice triggered when the vote duration is updated
     *
     * @param _voteDuration new vote duration
     */
    event VoteDurationUpdated(uint256 _voteDuration);

    /**
     * @notice triggered when the vote lock duration is updated
     *
     * @param _duration new vote lock duration
     */
    event VoteLockDurationUpdated(uint256 _duration);

    // PROPOSALS

    // voting duration in seconds
    uint256 public voteDuration = 3 days;
    // vote lock in seconds
    uint256 public voteLockDuration = 3 days;
    // the fraction of vote lock used to lock voter to avoid rapid unstaking
    uint256 public constant voteLockFraction = 10;
    // minimum stake required to propose
    uint256 public newProposalMinimum = 1e18;
    // quorum needed for a proposal to pass, default = 20%
    uint256 public quorum = 200000;
    // sum of current total votes
    uint256 public totalVotes;
    // number of proposals
    uint256 public proposalCount;
    // proposals by id
    mapping(uint256 => Proposal) public proposals;

    // VOTES

    // governance token used for votes
    IERC20 public immutable govToken;

    // lock duration for each voter stake by voter address
    mapping(address => uint256) public voteLocks;
    // number of votes for each user
    mapping(address => uint256) private votes;

    /**
     * @notice used to initialize a new BancorGovernance contract
     *
     * @param _govToken token used to represents votes
     */
    constructor(IERC20 _govToken) public {
        require(address(_govToken) != address(0), "ERR_NO_TOKEN");
        govToken = _govToken;
    }

    /**
     * @notice allows execution by staker only
     */
    modifier onlyStaker() {
        require(votes[msg.sender] > 0, "ERR_NOT_STAKER");
        _;
    }

    /**
     * @notice allows execution only when the proposal exists
     *
     * @param _id   proposal id
     */
    modifier proposalExists(uint256 _id) {
        Proposal memory proposal = proposals[_id];
        require(proposal.start > 0 && proposal.start < block.timestamp, "ERR_INVALID_ID");
        _;
    }

    /**
     * @notice allows execution only when the proposal is still open
     *
     * @param _id   proposal id
     */
    modifier proposalOpen(uint256 _id) {
        Proposal memory proposal = proposals[_id];
        require(proposal.open, "ERR_NOT_OPEN");
        _;
    }

    /**
     * @notice allows execution only when the proposal with given id is open
     *
     * @param _id   proposal id
     */
    modifier proposalNotEnded(uint256 _id) {
        Proposal memory proposal = proposals[_id];
        require(proposal.end >= block.timestamp, "ERR_ENDED");
        _;
    }

    /**
     * @notice allows execution only when the proposal with given id has ended
     *
     * @param _id   proposal id
     */
    modifier proposalEnded(uint256 _id) {
        Proposal memory proposal = proposals[_id];
        require(proposal.end <= block.timestamp, "ERR_NOT_ENDED");
        _;
    }

    /**
     * @notice verifies that a value is greater than zero
     *
     * @param _value    value to check for zero
     */
    modifier greaterThanZero(uint256 _value) {
        require(_value > 0, "ERR_ZERO_VALUE");
        _;
    }

    /**
     * @notice Updates the vote lock on the sender
     *
     * @param _proposalEnd  proposal end time
     */
    function updateVoteLock(uint256 _proposalEnd) private onlyStaker {
        voteLocks[msg.sender] = Math.max(
            voteLocks[msg.sender],
            Math.max(_proposalEnd, voteLockDuration.add(block.timestamp))
        );
    }

    /**
     * @notice does the common vote finalization
     *
     * @param _id the id of the proposal to vote
     * @param _for is this vote for or against the proposal
     */
    function vote(uint256 _id, bool _for)
        private
        onlyStaker
        proposalExists(_id)
        proposalOpen(_id)
        proposalNotEnded(_id)
    {
        Proposal storage proposal = proposals[_id];

        if (_for) {
            uint256 votesAgainst = proposal.votesAgainst[msg.sender];
            // do we have against votes for this sender?
            if (votesAgainst > 0) {
                // yes, remove the against votes first
                proposal.totalVotesAgainst = proposal.totalVotesAgainst.sub(votesAgainst);
                proposal.votesAgainst[msg.sender] = 0;
            }
        } else {
            // get against votes for this sender
            uint256 votesFor = proposal.votesFor[msg.sender];
            // do we have for votes for this sender?
            if (votesFor > 0) {
                proposal.totalVotesFor = proposal.totalVotesFor.sub(votesFor);
                proposal.votesFor[msg.sender] = 0;
            }
        }

        // calculate voting power in case voting against twice
        uint256 voteAmount = votesOf(msg.sender).sub(
            _for ? proposal.votesFor[msg.sender] : proposal.votesAgainst[msg.sender]
        );

        if (_for) {
            // increase total for votes of the proposal
            proposal.totalVotesFor = proposal.totalVotesFor.add(voteAmount);
            // set for votes to the votes of the sender
            proposal.votesFor[msg.sender] = votesOf(msg.sender);
        } else {
            // increase total against votes of the proposal
            proposal.totalVotesAgainst = proposal.totalVotesAgainst.add(voteAmount);
            // set against votes to the votes of the sender
            proposal.votesAgainst[msg.sender] = votesOf(msg.sender);
        }

        // update total votes available on the proposal
        proposal.totalAvailableVotes = totalVotes;
        // recalculate quorum based on overall votes
        proposal.quorum = calculateQuorumRatio(proposal);
        // update vote lock
        updateVoteLock(proposal.end);

        // emit vote event
        emit Vote(proposal.id, msg.sender, _for, voteAmount);
    }

    /**
     * @notice returns the quorum ratio of a proposal
     *
     * @param _proposal   proposal
     * @return quorum ratio
     */
    function calculateQuorumRatio(Proposal memory _proposal) internal view returns (uint256) {
        // calculate overall votes
        uint256 totalProposalVotes = _proposal.totalVotesFor.add(_proposal.totalVotesAgainst);

        return totalProposalVotes.mul(PPM_RESOLUTION).div(totalVotes);
    }

    /**
     * @notice removes the caller's entire stake
     */
    function exit() external {
        unstake(votesOf(msg.sender));
    }

    /**
     * @notice returns the voting stats of a proposal
     *
     * @param _id   proposal id
     * @return votes for ratio
     * @return votes against ratio
     * @return quorum ratio
     */
    function proposalStats(uint256 _id)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        Proposal memory proposal = proposals[_id];

        uint256 forRatio = proposal.totalVotesFor;
        uint256 againstRatio = proposal.totalVotesAgainst;

        // calculate overall total votes
        uint256 totalProposalVotes = forRatio.add(againstRatio);
        // calculate for votes ratio
        forRatio = forRatio.mul(PPM_RESOLUTION).div(totalProposalVotes);
        // calculate against votes ratio
        againstRatio = againstRatio.mul(PPM_RESOLUTION).div(totalProposalVotes);
        // calculate quorum ratio
        uint256 quorumRatio = totalProposalVotes.mul(PPM_RESOLUTION).div(
            proposal.totalAvailableVotes
        );

        return (forRatio, againstRatio, quorumRatio);
    }

    /**
     * @notice returns the voting power of a given address
     *
     * @param _voter    voter address
     * @return votes of given address
     */
    function votesOf(address _voter) public view returns (uint256) {
        return votes[_voter];
    }

    /**
     * @notice returns the voting power of a given address against a given proposal
     *
     * @param _voter    voter address
     * @param _id       proposal id
     * @return votes of given address against given proposal
     */
    function votesAgainstOf(address _voter, uint256 _id) public view returns (uint256) {
        return proposals[_id].votesAgainst[_voter];
    }

    /**
     * @notice returns the voting power of a given address for a given proposal
     *
     * @param _voter    voter address
     * @param _id       proposal id
     * @return votes of given address for given proposal
     */
    function votesForOf(address _voter, uint256 _id) public view returns (uint256) {
        return proposals[_id].votesFor[_voter];
    }

    /**
     * @notice updates the quorum needed for proposals to pass
     *
     * @param _quorum required quorum
     */
    function setQuorum(uint256 _quorum) public ownerOnly greaterThanZero(_quorum) {
        // check quorum for not being above 100
        require(_quorum <= PPM_RESOLUTION, "ERR_QUORUM_TOO_HIGH");

        quorum = _quorum;
        emit QuorumUpdated(_quorum);
    }

    /**
     * @notice updates the minimum stake required to create a new proposal
     *
     * @param _minimum minimum stake
     */
    function setNewProposalMinimum(uint256 _minimum) public ownerOnly greaterThanZero(_minimum) {
        require(_minimum <= govToken.totalSupply(), "ERR_EXCEEDS_TOTAL_SUPPLY");
        newProposalMinimum = _minimum;
        emit NewProposalMinimumUpdated(_minimum);
    }

    /**
     * @notice updates the proposals voting duration
     *
     * @param _voteDuration vote duration
     */
    function setVoteDuration(uint256 _voteDuration)
        public
        ownerOnly
        greaterThanZero(_voteDuration)
    {
        voteDuration = _voteDuration;
        emit VoteDurationUpdated(_voteDuration);
    }

    /**
     * @notice updates the post vote lock duration
     *
     * @param _duration new vote lock duration
     */
    function setVoteLockDuration(uint256 _duration) public ownerOnly greaterThanZero(_duration) {
        voteLockDuration = _duration;
        emit VoteLockDurationUpdated(_duration);
    }

    /**
     * @notice creates a new proposal
     *
     * @param _executor the address of the contract that will execute the proposal after it passes
     * @param _hash ipfs hash of the proposal description
     */
    function propose(address _executor, string memory _hash) public {
        require(votesOf(msg.sender) > newProposalMinimum, "ERR_INSUFFICIENT_STAKE");

        uint256 id = proposalCount;

        // increment proposal count so next proposal gets the next higher id
        proposalCount = proposalCount.add(1);

        // create new proposal
        Proposal memory proposal = Proposal({
            id: id,
            proposer: msg.sender,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            start: block.timestamp,
            end: voteDuration.add(block.timestamp),
            executor: _executor,
            hash: _hash,
            totalAvailableVotes: totalVotes,
            quorum: 0,
            quorumRequired: quorum,
            open: true,
            executed: false
        });

        proposals[id] = proposal;

        // lock proposer
        updateVoteLock(proposal.end);

        // emit proposal event
        emit NewProposal(id, proposal.start, voteDuration, proposal.proposer, proposal.executor);
    }

    /**
     * @notice executes a proposal
     *
     * @param _id id of the proposal to execute
     */
    function execute(uint256 _id) public proposalExists(_id) proposalEnded(_id) {
        // check for executed status
        require(!proposals[_id].executed, "ERR_ALREADY_EXECUTED");

        // get voting info of proposal
        (uint256 forRatio, uint256 againstRatio, uint256 quorumRatio) = proposalStats(_id);
        // check proposal state
        require(quorumRatio >= proposals[_id].quorumRequired, "ERR_NO_QUORUM");

        // if the proposal is still open
        if (proposals[_id].open) {
            // tally votes
            tallyVotes(_id);
        }

        // set executed
        proposals[_id].executed = true;

        // do execution on the contract to be executed
        // note that this is a safe call as it was part of the proposal that was voted on
        IExecutor(proposals[_id].executor).execute(_id, forRatio, againstRatio, quorumRatio);

        // emit proposal executed event
        emit ProposalExecuted(_id, proposals[_id].executor);
    }

    /**
     * @notice tallies votes of proposal with given id
     *
     * @param _id id of the proposal to tally votes for
     */
    function tallyVotes(uint256 _id)
        public
        proposalExists(_id)
        proposalOpen(_id)
        proposalEnded(_id)
    {
        // get voting info of proposal
        (uint256 forRatio, uint256 againstRatio, ) = proposalStats(_id);

        // do we have a quorum?
        bool quorumReached = proposals[_id].quorum >= proposals[_id].quorumRequired;
        // close proposal
        proposals[_id].open = false;

        // emit proposal finished event
        emit ProposalFinished(_id, forRatio, againstRatio, quorumReached);
    }

    /**
     * @notice stakes vote tokens
     *
     * @param _amount amount of vote tokens to stake
     */
    function stake(uint256 _amount) public greaterThanZero(_amount) {
        // increase vote power
        votes[msg.sender] = votesOf(msg.sender).add(_amount);
        // increase total votes
        totalVotes = totalVotes.add(_amount);
        // transfer tokens to this contract
        govToken.safeTransferFrom(msg.sender, address(this), _amount);

        // lock staker to avoid flashloans messing around with total votes
        voteLocks[msg.sender] = Math.max(
            voteLocks[msg.sender],
            Math.max(voteLockDuration.div(voteLockFraction), 10 minutes).add(block.timestamp)
        );

        // emit staked event
        emit Staked(msg.sender, _amount);
    }

    /**
     * @notice unstakes vote tokens
     *
     * @param _amount amount of vote tokens to unstake
     */
    function unstake(uint256 _amount) public greaterThanZero(_amount) {
        require(voteLocks[msg.sender] < block.timestamp, "ERR_LOCKED");

        // reduce votes for user
        votes[msg.sender] = votesOf(msg.sender).sub(_amount);
        // reduce total votes
        totalVotes = totalVotes.sub(_amount);
        // transfer tokens back
        govToken.safeTransfer(msg.sender, _amount);

        // emit unstaked event
        emit Unstaked(msg.sender, _amount);
    }

    /**
     * @notice votes for a proposal
     *
     * @param _id id of the proposal to vote for
     */
    function voteFor(uint256 _id) public {
        vote(_id, true);
    }

    /**
     * @notice votes against a proposal
     *
     * @param _id id of the proposal to vote against
     */
    function voteAgainst(uint256 _id) public {
        vote(_id, false);
    }
}