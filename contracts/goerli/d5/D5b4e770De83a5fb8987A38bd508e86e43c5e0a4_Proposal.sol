// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {GovernanceV2} from "./GovernanceV2.sol";
import {LoopbackProxy} from "../tornado-governance/contracts/LoopbackProxy.sol";

/// @title Proposal contract which Governance v1 should execute
contract Proposal {
    // the new governance contract to be upgraded to
    GovernanceV2 public newGovernanceContract;

    /// @notice This function upgrades the LoopbackProxy logic to the GovernanceV2 contract.
    /// @dev the proxy admin is the governance contract itself
    function executeProposal() public {
        newGovernanceContract = new GovernanceV2();

        LoopbackProxy(payable(address(this))).upgradeTo(
            address(newGovernanceContract)
        );

        newGovernanceContract = GovernanceV2(payable(address(this)));

        require(
            stringCompare(newGovernanceContract.version(), "2.vault-migration"),
            "Something went wrong after proxy logic upgrade failed!"
        );

        require(
            newGovernanceContract.deployVault(),
            "Something went wrong with vault deployment!"
        );
    }

    /// @notice This function compares two strings by hashing them to comparable format
    /// @param a first string to compare
    /// @param b second string to compare
    /// @return true if a == b, false otherwise
    function stringCompare(string memory a, string memory b)
        internal
	pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {TornVault} from "./TornVault.sol";
import {Governance} from "../tornado-governance/contracts/Governance.sol";

/// @title Version 2 Governance contract of the tornado.cash governance
contract GovernanceV2 is Governance {
    // vault which stores user TORN
    TornVault public userVault;

    // information on whether someone's tokens are still in governance
    mapping(address => bool) public isBalanceMigrated;

    // call Governance v1 constructor
    constructor() public Governance() {}

    /// @notice Deploys the vault to hold user tokens
    /// @return Boolean, if true, deployment succeeded
    function deployVault() external returns (bool) {
        require(address(userVault) == address(0), "vault already deployed");
        userVault = new TornVault();
        assert(address(userVault) != address(0));
        torn.approve(address(userVault), type(uint256).max);
        return true;
    }

    /// @notice Withdraws TORN from governance if conditions permit
    /// @param amount the amount of TORN to withdraw
    function unlock(uint256 amount) external override {
        if (!isBalanceMigrated[msg.sender]) {
            if (lockedBalance[msg.sender] == 0) {
                isBalanceMigrated[msg.sender] = true;
            } else {
                migrateTORN();
            }
        }
        require(
            getBlockTimestamp() > canWithdrawAfter[msg.sender],
            "Governance: tokens are locked"
        );
        lockedBalance[msg.sender] = lockedBalance[msg.sender].sub(
            amount,
            "Governance: insufficient balance"
        );
        require(userVault.withdrawTorn(amount), "withdrawTorn failed");
        require(torn.transfer(msg.sender, amount), "TORN: transfer failed");
    }

    /// @notice checker for success on deployment
    /// @return returns precise version of governance
    function version() external pure virtual returns (string memory) {
        return "2.vault-migration";
    }

    /// @notice transfers tokens from the contract to the vault, withdrawals are unlock()
    /// @param owner account/contract which (this) spender will send to the user vault
    /// @param amount amount which spender will send to the user vault
    function _transferTokens(address owner, uint256 amount) internal override {
        if (!isBalanceMigrated[msg.sender]) {
            if (lockedBalance[msg.sender] == 0) {
                isBalanceMigrated[msg.sender] = true;
            } else {
                migrateTORN();
            }
        }
        require(
            torn.transferFrom(owner, address(userVault), amount),
            "TORN: transferFrom failed"
        );
        lockedBalance[owner] = lockedBalance[owner].add(amount);
    }

    /// @notice migrates TORN for both unlock() and _transferTokens (which is part of 2 lock functions)
    function migrateTORN() internal {
        require(!isBalanceMigrated[msg.sender], "cannot migrate twice");
        require(
            torn.transfer(address(userVault), lockedBalance[msg.sender]),
            "TORN: transfer failed"
        );
        isBalanceMigrated[msg.sender] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import "torn-token/contracts/ENS.sol";

/**
 * @dev TransparentUpgradeableProxy that sets its admin to the implementation itself.
 * It is also allowed to call implementation methods.
 */
contract LoopbackProxy is TransparentUpgradeableProxy, EnsResolve {
  /**
   * @dev Initializes an upgradeable proxy backed by the implementation at `_logic`.
   */
  constructor(bytes32 _logic, bytes memory _data)
    public
    payable
    TransparentUpgradeableProxy(resolve(_logic), address(this), _data)
  {}

  /**
   * @dev Override to allow admin (itself) access the fallback function.
   */
  function _beforeFallback() internal override {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/// @title Vault which holds user funds
contract TornVault {
    using SafeERC20 for IERC20;

    address public governance =
        address(0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce);
    address public constant tornTokenAddress =
        address(0x77777FeDdddFfC19Ff86DB637967013e6C6A116C);

    /// @notice withdraws TORN from the contract
    /// @param amount amount to withdraw
    /// @return returns true on success
    function withdrawTorn(uint256 amount) external returns (bool) {
        require(msg.sender == governance, "only gov");
        IERC20(tornTokenAddress).safeTransfer(governance, amount);
        return true;
    }

    /// @notice upgrades contract governance address
    /// @dev upgradeability function just-in-case of a governance proxy switch if there ever will be one
    /// @param _governance new governance address
    /// @return true on success of setting new governance
    function setGovernance(address _governance) external returns (bool) {
        require(msg.sender == governance, "only gov");
        governance = _governance;
        return true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/upgrades-core/contracts/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "torn-token/contracts/ENS.sol";
import "torn-token/contracts/TORN.sol";
import "./Delegation.sol";
import "./Configuration.sol";

contract Governance is Initializable, Configuration, Delegation, EnsResolve {
  using SafeMath for uint256;
  /// @notice Possible states that a proposal may be in
  enum ProposalState { Pending, Active, Defeated, Timelocked, AwaitingExecution, Executed, Expired }

  struct Proposal {
    // Creator of the proposal
    address proposer;
    // target addresses for the call to be made
    address target;
    // The block at which voting begins
    uint256 startTime;
    // The block at which voting ends: votes must be cast prior to this block
    uint256 endTime;
    // Current number of votes in favor of this proposal
    uint256 forVotes;
    // Current number of votes in opposition to this proposal
    uint256 againstVotes;
    // Flag marking whether the proposal has been executed
    bool executed;
    // Flag marking whether the proposal voting time has been extended
    // Voting time can be extended once, if the proposal outcome has changed during CLOSING_PERIOD
    bool extended;
    // Receipts of ballots for the entire set of voters
    mapping(address => Receipt) receipts;
  }

  /// @notice Ballot receipt record for a voter
  struct Receipt {
    // Whether or not a vote has been cast
    bool hasVoted;
    // Whether or not the voter supports the proposal
    bool support;
    // The number of votes the voter had, which were cast
    uint256 votes;
  }

  /// @notice The official record of all proposals ever proposed
  Proposal[] public proposals;
  /// @notice The latest proposal for each proposer
  mapping(address => uint256) public latestProposalIds;
  /// @notice Timestamp when a user can withdraw tokens
  mapping(address => uint256) public canWithdrawAfter;

  TORN public torn;

  /// @notice An event emitted when a new proposal is created
  event ProposalCreated(
    uint256 indexed id,
    address indexed proposer,
    address target,
    uint256 startTime,
    uint256 endTime,
    string description
  );

  /// @notice An event emitted when a vote has been cast on a proposal
  event Voted(uint256 indexed proposalId, address indexed voter, bool indexed support, uint256 votes);

  /// @notice An event emitted when a proposal has been executed
  event ProposalExecuted(uint256 indexed proposalId);

  /// @notice Makes this instance inoperable to prevent selfdestruct attack
  /// Proxy will still be able to properly initialize its storage
  constructor() public initializer {
    torn = TORN(0x000000000000000000000000000000000000dEaD);
    _initializeConfiguration();
  }

  function initialize(bytes32 _torn) public initializer {
    torn = TORN(resolve(_torn));
    // Create a dummy proposal so that indexes start from 1
    proposals.push(
      Proposal({
        proposer: address(this),
        target: 0x000000000000000000000000000000000000dEaD,
        startTime: 0,
        endTime: 0,
        forVotes: 0,
        againstVotes: 0,
        executed: true,
        extended: false
      })
    );
    _initializeConfiguration();
  }

  function lock(
    address owner,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    torn.permit(owner, address(this), amount, deadline, v, r, s);
    _transferTokens(owner, amount);
  }

  function lockWithApproval(uint256 amount) external {
    _transferTokens(msg.sender, amount);
  }

  function unlock(uint256 amount) virtual external {
    require(getBlockTimestamp() > canWithdrawAfter[msg.sender], "Governance: tokens are locked");
    lockedBalance[msg.sender] = lockedBalance[msg.sender].sub(amount, "Governance: insufficient balance");
    require(torn.transfer(msg.sender, amount), "TORN: transfer failed");
  }

  function propose(address target, string memory description) external returns (uint256) {
    return _propose(msg.sender, target, description);
  }

  /**
   * @notice Propose implementation
   * @param proposer proposer address
   * @param target smart contact address that will be executed as result of voting
   * @param description description of the proposal
   * @return the new proposal id
   */
  function _propose(
    address proposer,
    address target,
    string memory description
  ) internal override(Delegation) returns (uint256) {
    uint256 votingPower = lockedBalance[proposer];
    require(votingPower >= PROPOSAL_THRESHOLD, "Governance::propose: proposer votes below proposal threshold");
    // target should be a contract
    require(Address.isContract(target), "Governance::propose: not a contract");

    uint256 latestProposalId = latestProposalIds[proposer];
    if (latestProposalId != 0) {
      ProposalState proposersLatestProposalState = state(latestProposalId);
      require(
        proposersLatestProposalState != ProposalState.Active && proposersLatestProposalState != ProposalState.Pending,
        "Governance::propose: one live proposal per proposer, found an already active proposal"
      );
    }

    uint256 startTime = getBlockTimestamp().add(VOTING_DELAY);
    uint256 endTime = startTime.add(VOTING_PERIOD);

    Proposal memory newProposal = Proposal({
      proposer: proposer,
      target: target,
      startTime: startTime,
      endTime: endTime,
      forVotes: 0,
      againstVotes: 0,
      executed: false,
      extended: false
    });

    proposals.push(newProposal);
    uint256 proposalId = proposalCount();
    latestProposalIds[newProposal.proposer] = proposalId;

    _lockTokens(proposer, endTime.add(VOTE_EXTEND_TIME).add(EXECUTION_EXPIRATION).add(EXECUTION_DELAY));
    emit ProposalCreated(proposalId, proposer, target, startTime, endTime, description);
    return proposalId;
  }

  function execute(uint256 proposalId) external virtual payable {
    require(state(proposalId) == ProposalState.AwaitingExecution, "Governance::execute: invalid proposal state");
    Proposal storage proposal = proposals[proposalId];
    proposal.executed = true;

    address target = proposal.target;
    require(Address.isContract(target), "Governance::execute: not a contract");
    (bool success, bytes memory data) = target.delegatecall(abi.encodeWithSignature("executeProposal()"));
    if (!success) {
      if (data.length > 0) {
        revert(string(data));
      } else {
        revert("Proposal execution failed");
      }
    }

    emit ProposalExecuted(proposalId);
  }

  function castVote(uint256 proposalId, bool support) external {
    _castVote(msg.sender, proposalId, support);
  }

  function _castVote(
    address voter,
    uint256 proposalId,
    bool support
  ) internal override(Delegation) {
    require(state(proposalId) == ProposalState.Active, "Governance::_castVote: voting is closed");
    Proposal storage proposal = proposals[proposalId];
    Receipt storage receipt = proposal.receipts[voter];
    bool beforeVotingState = proposal.forVotes <= proposal.againstVotes;
    uint256 votes = lockedBalance[voter];
    require(votes > 0, "Governance: balance is 0");
    if (receipt.hasVoted) {
      if (receipt.support) {
        proposal.forVotes = proposal.forVotes.sub(receipt.votes);
      } else {
        proposal.againstVotes = proposal.againstVotes.sub(receipt.votes);
      }
    }

    if (support) {
      proposal.forVotes = proposal.forVotes.add(votes);
    } else {
      proposal.againstVotes = proposal.againstVotes.add(votes);
    }

    if (!proposal.extended && proposal.endTime.sub(getBlockTimestamp()) < CLOSING_PERIOD) {
      bool afterVotingState = proposal.forVotes <= proposal.againstVotes;
      if (beforeVotingState != afterVotingState) {
        proposal.extended = true;
        proposal.endTime = proposal.endTime.add(VOTE_EXTEND_TIME);
      }
    }

    receipt.hasVoted = true;
    receipt.support = support;
    receipt.votes = votes;
    _lockTokens(voter, proposal.endTime.add(VOTE_EXTEND_TIME).add(EXECUTION_EXPIRATION).add(EXECUTION_DELAY));
    emit Voted(proposalId, voter, support, votes);
  }

  function _lockTokens(address owner, uint256 timestamp) internal {
    if (timestamp > canWithdrawAfter[owner]) {
      canWithdrawAfter[owner] = timestamp;
    }
  }

  function _transferTokens(address owner, uint256 amount) virtual internal {
    require(torn.transferFrom(owner, address(this), amount), "TORN: transferFrom failed");
    lockedBalance[owner] = lockedBalance[owner].add(amount);
  }

  function getReceipt(uint256 proposalId, address voter) public view returns (Receipt memory) {
    return proposals[proposalId].receipts[voter];
  }

  function state(uint256 proposalId) public view returns (ProposalState) {
    require(proposalId <= proposalCount() && proposalId > 0, "Governance::state: invalid proposal id");
    Proposal storage proposal = proposals[proposalId];
    if (getBlockTimestamp() <= proposal.startTime) {
      return ProposalState.Pending;
    } else if (getBlockTimestamp() <= proposal.endTime) {
      return ProposalState.Active;
    } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes + proposal.againstVotes < QUORUM_VOTES) {
      return ProposalState.Defeated;
    } else if (proposal.executed) {
      return ProposalState.Executed;
    } else if (getBlockTimestamp() >= proposal.endTime.add(EXECUTION_DELAY).add(EXECUTION_EXPIRATION)) {
      return ProposalState.Expired;
    } else if (getBlockTimestamp() >= proposal.endTime.add(EXECUTION_DELAY)) {
      return ProposalState.AwaitingExecution;
    } else {
      return ProposalState.Timelocked;
    }
  }

  function proposalCount() public view returns (uint256) {
    return proposals.length - 1;
  }

  function getBlockTimestamp() internal virtual view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ENS {
  function resolver(bytes32 node) external view returns (Resolver);
}

interface Resolver {
  function addr(bytes32 node) external view returns (address);
}

contract EnsResolve {
  function resolve(bytes32 node) public view virtual returns (address) {
    ENS Registry = ENS(
      getChainId() == 1 ? 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e : 0x8595bFb0D940DfEDC98943FA8a907091203f25EE
    );
    return Registry.resolver(node).addr(node);
  }

  function bulkResolve(bytes32[] memory domains) public view returns (address[] memory result) {
    result = new address[](domains.length);
    for (uint256 i = 0; i < domains.length; i++) {
      result[i] = resolve(domains[i]);
    }
  }

  function getChainId() internal pure returns (uint256) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    return chainId;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "./ERC20Permit.sol";
import "./ENS.sol";

contract TORN is ERC20("TornadoCash", "TORN"), ERC20Burnable, ERC20Permit, Pausable, EnsResolve {
  using SafeERC20 for IERC20;

  uint256 public immutable canUnpauseAfter;
  address public immutable governance;
  mapping(address => bool) public allowedTransferee;

  event Allowed(address target);
  event Disallowed(address target);

  struct Recipient {
    bytes32 to;
    uint256 amount;
  }

  constructor(
    bytes32 _governance,
    uint256 _pausePeriod,
    Recipient[] memory _vestings
  ) public {
    address _resolvedGovernance = resolve(_governance);
    governance = _resolvedGovernance;
    allowedTransferee[_resolvedGovernance] = true;

    for (uint256 i = 0; i < _vestings.length; i++) {
      address to = resolve(_vestings[i].to);
      _mint(to, _vestings[i].amount);
      allowedTransferee[to] = true;
    }

    canUnpauseAfter = blockTimestamp().add(_pausePeriod);
    _pause();
    require(totalSupply() == 10000000 ether, "TORN: incorrect distribution");
  }

  modifier onlyGovernance() {
    require(_msgSender() == governance, "TORN: only governance can perform this action");
    _;
  }

  function changeTransferability(bool decision) public onlyGovernance {
    require(blockTimestamp() > canUnpauseAfter, "TORN: cannot change transferability yet");
    if (decision) {
      _unpause();
    } else {
      _pause();
    }
  }

  function addToAllowedList(address[] memory target) public onlyGovernance {
    for (uint256 i = 0; i < target.length; i++) {
      allowedTransferee[target[i]] = true;
      emit Allowed(target[i]);
    }
  }

  function removeFromAllowedList(address[] memory target) public onlyGovernance {
    for (uint256 i = 0; i < target.length; i++) {
      allowedTransferee[target[i]] = false;
      emit Disallowed(target[i]);
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    super._beforeTokenTransfer(from, to, amount);
    require(!paused() || allowedTransferee[from] || allowedTransferee[to], "TORN: paused");
    require(to != address(this), "TORN: invalid recipient");
  }

  /// @dev Method to claim junk and accidentally sent tokens
  function rescueTokens(
    IERC20 _token,
    address payable _to,
    uint256 _balance
  ) external onlyGovernance {
    require(_to != address(0), "TORN: can not send to zero address");

    if (_token == IERC20(0)) {
      // for Ether
      uint256 totalBalance = address(this).balance;
      uint256 balance = _balance == 0 ? totalBalance : Math.min(totalBalance, _balance);
      _to.transfer(balance);
    } else {
      // any other erc20
      uint256 totalBalance = _token.balanceOf(address(this));
      uint256 balance = _balance == 0 ? totalBalance : Math.min(totalBalance, _balance);
      require(balance > 0, "TORN: trying to send 0 balance");
      _token.safeTransfer(_to, balance);
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Core.sol";

abstract contract Delegation is Core {
  /// @notice Delegatee records
  mapping(address => address) public delegatedTo;

  event Delegated(address indexed account, address indexed to);
  event Undelegated(address indexed account, address indexed from);

  function delegate(address to) external {
    address previous = delegatedTo[msg.sender];
    require(to != msg.sender && to != address(this) && to != address(0) && to != previous, "Governance: invalid delegatee");
    if (previous != address(0)) {
      emit Undelegated(msg.sender, previous);
    }
    delegatedTo[msg.sender] = to;
    emit Delegated(msg.sender, to);
  }

  function undelegate() external {
    address previous = delegatedTo[msg.sender];
    require(previous != address(0), "Governance: tokens are already undelegated");

    delegatedTo[msg.sender] = address(0);
    emit Undelegated(msg.sender, previous);
  }

  function proposeByDelegate(
    address from,
    address target,
    string memory description
  ) external returns (uint256) {
    require(delegatedTo[from] == msg.sender, "Governance: not authorized");
    return _propose(from, target, description);
  }

  function _propose(
    address proposer,
    address target,
    string memory description
  ) internal virtual returns (uint256);

  function castDelegatedVote(
    address[] memory from,
    uint256 proposalId,
    bool support
  ) external {
    for (uint256 i = 0; i < from.length; i++) {
      require(delegatedTo[from[i]] == msg.sender, "Governance: not authorized");
      _castVote(from[i], proposalId, support);
    }
    if (lockedBalance[msg.sender] > 0) {
      _castVote(msg.sender, proposalId, support);
    }
  }

  function _castVote(
    address voter,
    uint256 proposalId,
    bool support
  ) internal virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Configuration {
  /// @notice Time delay between proposal vote completion and its execution
  uint256 public EXECUTION_DELAY;
  /// @notice Time before a passed proposal is considered expired
  uint256 public EXECUTION_EXPIRATION;
  /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
  uint256 public QUORUM_VOTES;
  /// @notice The number of votes required in order for a voter to become a proposer
  uint256 public PROPOSAL_THRESHOLD;
  /// @notice The delay before voting on a proposal may take place, once proposed
  /// It is needed to prevent reorg attacks that replace the proposal
  uint256 public VOTING_DELAY;
  /// @notice The duration of voting on a proposal
  uint256 public VOTING_PERIOD;
  /// @notice If the outcome of a proposal changes during CLOSING_PERIOD, the vote will be extended by VOTE_EXTEND_TIME (no more than once)
  uint256 public CLOSING_PERIOD;
  /// @notice If the outcome of a proposal changes during CLOSING_PERIOD, the vote will be extended by VOTE_EXTEND_TIME (no more than once)
  uint256 public VOTE_EXTEND_TIME;

  modifier onlySelf {
    require(msg.sender == address(this), "Governance: unauthorized");
    _;
  }

  function _initializeConfiguration() internal {
    EXECUTION_DELAY = 2 days;
    EXECUTION_EXPIRATION = 3 days;
    QUORUM_VOTES = 25000e18; // 0.25% of TORN
    PROPOSAL_THRESHOLD = 1000e18; // 0.01% of TORN
    VOTING_DELAY = 75 seconds;
    VOTING_PERIOD = 3 days;
    CLOSING_PERIOD = 1 hours;
    VOTE_EXTEND_TIME = 6 hours;
  }

  function setExecutionDelay(uint256 executionDelay) external onlySelf {
    EXECUTION_DELAY = executionDelay;
  }

  function setExecutionExpiration(uint256 executionExpiration) external onlySelf {
    EXECUTION_EXPIRATION = executionExpiration;
  }

  function setQuorumVotes(uint256 quorumVotes) external onlySelf {
    QUORUM_VOTES = quorumVotes;
  }

  function setProposalThreshold(uint256 proposalThreshold) external onlySelf {
    PROPOSAL_THRESHOLD = proposalThreshold;
  }

  function setVotingDelay(uint256 votingDelay) external onlySelf {
    VOTING_DELAY = votingDelay;
  }

  function setVotingPeriod(uint256 votingPeriod) external onlySelf {
    VOTING_PERIOD = votingPeriod;
  }

  function setClosingPeriod(uint256 closingPeriod) external onlySelf {
    CLOSING_PERIOD = closingPeriod;
  }

  function setVoteExtendTime(uint256 voteExtendTime) external onlySelf {
    // VOTE_EXTEND_TIME should be less EXECUTION_DELAY to prevent double voting
    require(voteExtendTime < EXECUTION_DELAY, "Governance: incorrect voteExtendTime");
    VOTE_EXTEND_TIME = voteExtendTime;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// Adapted copy from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/files

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ECDSA.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to use their tokens
 * without sending any transactions by setting {IERC20-allowance} with a
 * signature using the {permit} method, and then spend them via
 * {IERC20-transferFrom}.
 *
 * The {permit} signature mechanism conforms to the {IERC2612Permit} interface.
 */
abstract contract ERC20Permit is ERC20 {
  mapping(address => uint256) private _nonces;

  bytes32 private constant _PERMIT_TYPEHASH = keccak256(
    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
  );

  // Mapping of ChainID to domain separators. This is a very gas efficient way
  // to not recalculate the domain separator on every call, while still
  // automatically detecting ChainID changes.
  mapping(uint256 => bytes32) private _domainSeparators;

  constructor() internal {
    _updateDomainSeparator();
  }

  /**
   * @dev See {IERC2612Permit-permit}.
   *
   * If https://eips.ethereum.org/EIPS/eip-1344[ChainID] ever changes, the
   * EIP712 Domain Separator is automatically recalculated.
   */
  function permit(
    address owner,
    address spender,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    require(blockTimestamp() <= deadline, "ERC20Permit: expired deadline");

    bytes32 hashStruct = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, amount, _nonces[owner], deadline));

    bytes32 hash = keccak256(abi.encodePacked(uint16(0x1901), _domainSeparator(), hashStruct));

    address signer = ECDSA.recover(hash, v, r, s);
    require(signer == owner, "ERC20Permit: invalid signature");

    _nonces[owner]++;
    _approve(owner, spender, amount);
  }

  /**
   * @dev See {IERC2612Permit-nonces}.
   */
  function nonces(address owner) public view returns (uint256) {
    return _nonces[owner];
  }

  function _updateDomainSeparator() private returns (bytes32) {
    uint256 _chainID = chainID();

    bytes32 newDomainSeparator = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes(name())),
        keccak256(bytes("1")), // Version
        _chainID,
        address(this)
      )
    );

    _domainSeparators[_chainID] = newDomainSeparator;

    return newDomainSeparator;
  }

  // Returns the domain separator, updating it if chainID changes
  function _domainSeparator() private returns (bytes32) {
    bytes32 domainSeparator = _domainSeparators[chainID()];
    if (domainSeparator != 0x00) {
      return domainSeparator;
    } else {
      return _updateDomainSeparator();
    }
  }

  function chainID() public view virtual returns (uint256 _chainID) {
    assembly {
      _chainID := chainid()
    }
  }

  function blockTimestamp() public view virtual returns (uint256) {
    return block.timestamp;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// A copy from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/files

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
  /**
   * @dev Returns the address that signed a hashed message (`hash`) with
   * `signature`. This address can then be used for verification purposes.
   *
   * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
   * this function rejects them by requiring the `s` value to be in the lower
   * half order, and the `v` value to be either 27 or 28.
   *
   * IMPORTANT: `hash` _must_ be the result of a hash operation for the
   * verification to be secure: it is possible to craft signatures that
   * recover to arbitrary addresses for non-hashed data. A safe way to ensure
   * this is by receiving a hash of the original message (which may otherwise
   * be too long), and then calling {toEthSignedMessageHash} on it.
   */
  function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
    // Check the signature length
    if (signature.length != 65) {
      revert("ECDSA: invalid signature length");
    }

    // Divide the signature in r, s and v variables
    bytes32 r;
    bytes32 s;
    uint8 v;

    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solhint-disable-next-line no-inline-assembly
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := mload(add(signature, 0x41))
    }

    return recover(hash, v, r, s);
  }

  /**
   * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
   * `r` and `s` signature fields separately.
   */
  function recover(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal pure returns (address) {
    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
    // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
    //
    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
    // these malleable signatures as well.
    require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
    require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

    // If the signature is valid (and not malleable), return the signer address
    address signer = ecrecover(hash, v, r, s);
    require(signer != address(0), "ECDSA: invalid signature");

    return signer;
  }

  /**
   * @dev Returns an Ethereum Signed Message, created from a `hash`. This
   * replicates the behavior of the
   * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
   * JSON-RPC method.
   *
   * See {recover}.
   */
  function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

abstract contract Core {
  /// @notice Locked token balance for each account
  mapping(address => uint256) public lockedBalance;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

