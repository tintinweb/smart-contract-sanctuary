// SPDX-License-Identifier: None
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRewardDistributionRecipient.sol";
import "./VotingPowerFees.sol";
import "./VotingPowerFeesAndRewards.sol";
import "../interfaces/yearn/IGovernance.sol";

contract Governance is VotingPowerFeesAndRewards {
    uint256 internal proposalCount;
    uint256 internal period = 3 days; // voting period in blocks ~ 17280 3 days for 15s/block
    uint256 internal minimum = 1e18;
    address internal governance;
    mapping(address => uint256) public voteLock; // period that your sake it locked to keep it for voting

    struct Proposal {
        uint256 id;
        address proposer;
        string ipfsCid;
        mapping(address => uint256) forVotes;
        mapping(address => uint256) againstVotes;
        uint256 totalForVotes;
        uint256 totalAgainstVotes;
        uint256 start; // block start;
        uint256 end; // start + period
    }

    mapping(uint256 => Proposal) public proposals;

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    /* Getters */

    /// @notice Returns proposalCount value.
    /// @return _proposalCount - uint256 value
    function getProposalCount() external view returns (uint256 _proposalCount) {
        return proposalCount;
    }

    /// @notice Returns period value.
    /// @dev Voting period in seconds
    /// @return _period - uint256 value
    function getPeriod() external view returns (uint256 _period) {
        return period;
    }

    /// @notice Returns minimum value.
    /// @dev minimum value is the value of the voting power which user must have to create proposal.
    /// @return _minimum - uint256 value
    function getMinimum() external view returns (uint256 _minimum) {
        return minimum;
    }

    /// @notice Returns governance address.
    /// @return _governance - address value
    function getGovernance() external view returns (address _governance) {
        return governance;
    }

    /// @notice Returns vote lockFor the specified user
    /// @param _user user for whom to get voteLock value.
    /// @return _voteLock - user's uint256 vote lock timestamp
    function getVoteLock(address _user) external view returns (uint256 _voteLock) {
        return voteLock[_user];
    }

    /// @notice Returns proposal's data with the specified proposal id.
    /// @param _proposalId - an index (count number) in the proposals mapping.
    /// @return id - proposal id
    /// @return proposer - proposal author address
    /// @return ipfsCid - ipfs cid of the proposal text
    /// @return totalForVotes - total amount of the voting power used for voting **for** proposal
    /// @return totalAgainstVotes - total amount of the voting power used for voting **against** proposal
    /// @return start - timestamp when proposal was created
    /// @return end - timestamp when proposal will be ended and disabled for voting (end = start + period)
    function getProposal(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory ipfsCid,
            uint256 totalForVotes,
            uint256 totalAgainstVotes,
            uint256 start,
            uint256 end
        )
    {
        return (
            proposals[_proposalId].id,
            proposals[_proposalId].proposer,
            proposals[_proposalId].ipfsCid,
            proposals[_proposalId].totalForVotes,
            proposals[_proposalId].totalAgainstVotes,
            proposals[_proposalId].start,
            proposals[_proposalId].end
        );
    }

    /// @notice Returns proposals' data in the range of ids.
    /// @dev Revert will be thrown if _fromId >= _toId
    /// @param _fromId - proposal id/index at which to start extraction.
    /// @param _toId - proposal id/index *before* which to end extraction.
    /// @return id - proposals ids
    /// @return proposer - proposals authors addresses
    /// @return ipfsCid - ipfs cids of the proposals' texts
    /// @return totalForVotes - total amount of the voting power used for voting **for** proposals
    /// @return totalAgainstVotes - total amount of the voting power used for voting **against** proposals
    /// @return start - timestamps when proposals was created
    /// @return end - timestamps when proposals will be ended and disabled for voting (end = start + period)
    function getProposals(uint256 _fromId, uint256 _toId)
        external
        view
        returns (
            uint256[] memory id,
            address[] memory proposer,
            string[] memory ipfsCid,
            uint256[] memory totalForVotes,
            uint256[] memory totalAgainstVotes,
            uint256[] memory start,
            uint256[] memory end
        )
    {
        require(_fromId < _toId, "invalid range");
        uint256 numberOfProposals = _toId.sub(_fromId);
        id = new uint256[](numberOfProposals);
        proposer = new address[](numberOfProposals);
        ipfsCid = new string[](numberOfProposals);
        totalForVotes = new uint256[](numberOfProposals);
        totalAgainstVotes = new uint256[](numberOfProposals);
        start = new uint256[](numberOfProposals);
        end = new uint256[](numberOfProposals);
        for (uint256 i = 0; i < numberOfProposals; i = i.add(1)) {
            uint256 proposalId = _fromId.add(i);
            id[i] = proposals[proposalId].id;
            proposer[i] = proposals[proposalId].proposer;
            ipfsCid[i] = proposals[proposalId].ipfsCid;
            totalForVotes[i] = proposals[proposalId].totalForVotes;
            totalAgainstVotes[i] = proposals[proposalId].totalAgainstVotes;
            start[i] = proposals[proposalId].start;
            end[i] = proposals[proposalId].end;
        }
    }

    /// @notice Returns user's votes for the specified proposal id.
    /// @param _proposalId - an index (count number) in the proposals mapping.
    /// @param _user - user for which votes are requested
    /// @return forVotes - uint256 value
    function getProposalForVotes(uint256 _proposalId, address _user) external view returns (uint256 forVotes) {
        return (proposals[_proposalId].forVotes[_user]);
    }

    /// @notice Returns user's votes against the specified proposal id.
    /// @param _proposalId - an index (count number) in the proposals mapping.
    /// @param _user - user for which votes are requested
    /// @return againstVotes - uint256 value
    function getProposalAgainstVotes(uint256 _proposalId, address _user) external view returns (uint256 againstVotes) {
        return (proposals[_proposalId].againstVotes[_user]);
    }

    /// @notice Contract's constructor
    /// @param _stakingToken Sets staking token
    /// @param _feesToken Sets fees token
    /// @param _rewardsToken Sets rewards token
    /// @param _governance Sets governance address
    constructor(
        IERC20 _stakingToken,
        IERC20 _feesToken,
        IERC20 _rewardsToken,
        address _governance
    ) public VotingPowerFeesAndRewards(_stakingToken, _feesToken, _rewardsToken) {
        governance = _governance;
    }

    /* Administration functionality */

    /// @notice Fee collection for any other token
    /// @dev Transfers token to the governance address
    /// @param _token Token address
    /// @param _amount Amount for transferring to the governance
    function seize(IERC20 _token, uint256 _amount) external onlyGovernance {
        require(_token != feesToken, "feesToken");
        require(_token != rewardsToken, "rewardsToken");
        require(_token != stakingToken, "stakingToken");
        _token.safeTransfer(governance, _amount);
    }

    /// @notice Sets staking token.
    /// @param _stakingToken new staking token address.
    function setStakingToken(IERC20 _stakingToken) external onlyGovernance {
        stakingToken = _stakingToken;
    }

    /// @notice Sets governance.
    /// @param _governance new governance value.
    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
    }

    /// @notice Sets minimum.
    /// @param _minimum new minimum value.
    function setMinimum(uint256 _minimum) external onlyGovernance {
        minimum = _minimum;
    }

    /// @notice Sets period.
    /// @param _period new period value.
    function setPeriod(uint256 _period) external onlyGovernance {
        period = _period;
    }

    /* Proposals and voting functionality */
    /// @notice Creates new proposal without text, proposal settings are default on the contract.
    /// @param _ipfsCid ipfs cid of the proposal's text
    /// @dev User must have voting power >= minimum in order to create proposal. New proposal will be added to the proposals mapping.
    function propose(string calldata _ipfsCid) external {
        require(balanceOf(msg.sender) >= minimum, "<minimum");
        proposals[proposalCount++] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            ipfsCid: _ipfsCid,
            totalForVotes: 0,
            totalAgainstVotes: 0,
            start: block.timestamp,
            end: period.add(block.timestamp)
        });

        voteLock[msg.sender] = period.add(block.timestamp);
    }

    function revokeProposal(uint256 _id) external {
        require(proposals[_id].proposer == msg.sender, "!proposer");
        proposals[_id].end = 0;
    }

    /// @notice Votes for the proposal using voting power.
    /// @dev After voting function withdraws fee for the user(if breaker == false).
    /// @param id proposal's id
    function voteFor(uint256 id) external {
        require(proposals[id].start < block.timestamp, "<start");
        require(proposals[id].end > block.timestamp, ">end");
        uint256 votes = balanceOf(msg.sender).sub(proposals[id].forVotes[msg.sender]);
        proposals[id].totalForVotes = proposals[id].totalForVotes.add(votes);
        proposals[id].forVotes[msg.sender] = balanceOf(msg.sender);
        // check that we will not reduce user's lock time (if he voted for another, newer proposal)
        if (voteLock[msg.sender] < proposals[id].end) {
            voteLock[msg.sender] = proposals[id].end;
        }
    }

    /// @notice Votes against the proposal using voting power.
    /// @dev After voting function withdraws fee for the user.
    /// @param id proposal's id
    function voteAgainst(uint256 id) external {
        require(proposals[id].start < block.timestamp, "<start");
        require(proposals[id].end > block.timestamp, ">end");
        uint256 votes = balanceOf(msg.sender).sub(proposals[id].againstVotes[msg.sender]);
        proposals[id].totalAgainstVotes = proposals[id].totalAgainstVotes.add(votes);
        proposals[id].againstVotes[msg.sender] = balanceOf(msg.sender);

        if (voteLock[msg.sender] < proposals[id].end) {
            voteLock[msg.sender] = proposals[id].end;
        }
    }

    /* Staking, voting power functionality */
    /// @notice Stakes token and adds voting power (with a 1:1 ratio)
    /// @dev Token amount must be approved to this contract before staking. Before staking contract withdraws fee for the user.
    /// @param amount Amount to stake
    function stake(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    /// @notice Withdraws token and subtracts voting power (with a 1:1 ratio)
    /// @dev Tokens must be unlocked to withdraw (voteLock[msg.sender] < block.timestamp). Before withdraw contract withdraws fee for the user.
    /// @param amount Amount to withdraw
    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(voteLock[msg.sender] < block.timestamp, "!locked");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
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

// SPDX-License-Identifier: None
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract IRewardDistributionRecipient is Ownable {
    address rewardDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution) external onlyOwner {
        rewardDistribution = _rewardDistribution;
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRewardDistributionRecipient.sol";
import "./TokenToVotePowerStaking.sol";

/// @title Fees functionality for the voting power.
/// @notice Fees are paid to this contracts in the erc20 token. This contract distributes fees between voting power holders.
/// @dev Fees value is claimable.
contract VotingPowerFees is TokenToVotePowerStaking {
    /// @dev Token in which fees are paid.
    IERC20 internal feesToken;

    /// @dev Accumulated ratio of the voting power to the fees. This is used to calculate
    uint256 internal accumulatedRatio = 0;

    /// @dev Fees savings amount fixed by the contract after the last claim.
    uint256 internal lastBal = 0;

    /// @notice User => accumulated ratio fixed after the last user's claim
    mapping(address => uint256) public userAccumulatedRatio;

    /// @notice Token in which fees are paid.
    function getFeesToken() external view returns (IERC20 _feesToken) {
        return feesToken;
    }

    /// @notice Accumulated ratio of the voting power to the fees. This is used to calculate
    function getAccumulatedRatio() external view returns (uint256 _accumulatedRatio) {
        return accumulatedRatio;
    }

    /// @notice Fees savings amount fixed by the contract after the last claim.
    function getLastBal() external view returns (uint256 _lastBal) {
        return lastBal;
    }

    /// @notice User => accumulated ratio fixed after the last user's claim
    function getUserAccumulatedRatio(address _user) external view returns (uint256 _userAccumulatedRatio) {
        return userAccumulatedRatio[_user];
    }

    /// @notice Contract's constructor
    /// @param _stakingToken Sets staking token
    /// @param _feesToken Sets fees token
    constructor(IERC20 _stakingToken, IERC20 _feesToken) public TokenToVotePowerStaking(_stakingToken) {
        feesToken = _feesToken;
    }

    /// @notice Makes contract update its fee (token) balance
    /// @dev Updates accumulatedRatio and lastBal
    function updateFees() public {
        if (totalSupply() > 0) {
            uint256 _lastBal = IERC20(feesToken).balanceOf(address(this));
            if (_lastBal > 0) {
                uint256 _diff = _lastBal.sub(lastBal);
                if (_diff > 0) {
                    uint256 _ratio = _diff.mul(1e18).div(totalSupply());
                    if (_ratio > 0) {
                        accumulatedRatio = accumulatedRatio.add(_ratio);
                        lastBal = _lastBal;
                    }
                }
            }
        }
    }

    /// @notice Transfers fees part (token amount) to the user accordingly to the user's voting power share
    function withdrawFees() public {
        _withdrawFeesFor(msg.sender);
    }

    /// @dev bug WIP: Looks like it won't work properly if all of the users will claim their rewards (balance will be 0) and then new user will receive voting power and try to claim (revert). Or new user will claim reward after
    /// @param recipient User who will receive its fee part.
    function _withdrawFeesFor(address recipient) internal {
        updateFees();
        uint256 _supplied = balanceOf(recipient);
        if (_supplied > 0) {
            uint256 _supplyIndex = userAccumulatedRatio[recipient];
            userAccumulatedRatio[recipient] = accumulatedRatio;
            uint256 _delta = accumulatedRatio.sub(_supplyIndex);
            if (_delta > 0) {
                uint256 _share = _supplied.mul(_delta).div(1e18);

                IERC20(feesToken).safeTransfer(recipient, _share);
                lastBal = IERC20(feesToken).balanceOf(address(this));
            }
        } else {
            userAccumulatedRatio[recipient] = accumulatedRatio;
        }
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "./IRewardDistributionRecipient.sol";
import "./VotingPowerFees.sol";

/// @title Rewards functionality for the voting power.
/// @notice Rewards are paid by some centralized treasury. Then this contract distributes rewards to the voting power holders.
contract VotingPowerFeesAndRewards is IRewardDistributionRecipient, VotingPowerFees {
    uint256 internal constant DURATION = 7 days;

    uint256 internal periodFinish = 0;

    uint256 internal rewardRate = 0;

    IERC20 internal rewardsToken;

    uint256 internal lastUpdateTime;

    uint256 internal rewardPerTokenStored;

    mapping(address => uint256) internal userRewardPerTokenPaid;

    mapping(address => uint256) internal rewards;

    /// @notice Returns DURATION value
    /// @return _DURATION - uint256 value
    function getDuration() external pure returns (uint256 _DURATION) {
        return DURATION;
    }

    /// @notice Returns periodFinish value
    /// @return _periodFinish - uint256 value
    function getPeriodFinish() external view returns (uint256 _periodFinish) {
        return periodFinish;
    }

    /// @notice Returns rewardRate value
    /// @return _rewardRate - uint256 value
    function getRewardRate() external view returns (uint256 _rewardRate) {
        return rewardRate;
    }

    /// @notice Returns rewardsToken value
    /// @return _rewardsToken - IERC20 value
    function getRewardsToken() external view returns (IERC20 _rewardsToken) {
        return rewardsToken;
    }

    /// @notice Returns lastUpdateTime value
    /// @return _lastUpdateTime - uint256 value
    function getLastUpdateTime() external view returns (uint256 _lastUpdateTime) {
        return lastUpdateTime;
    }

    /// @notice Returns rewardPerTokenStored value
    /// @return _rewardPerTokenStored - uint256 value
    function getRewardPerTokenStored() external view returns (uint256 _rewardPerTokenStored) {
        return rewardPerTokenStored;
    }

    /// @notice Returns user's reward per token paid
    /// @param _user address of the user for whom data are requested
    /// @return _userRewardPerTokenPaid - uint256 value
    function getUserRewardPerTokenPaid(address _user) external view returns (uint256 _userRewardPerTokenPaid) {
        return userRewardPerTokenPaid[_user];
    }

    /// @notice Returns user's available rewards
    /// @param _user address of the user for whom data are requested
    /// @return _rewards - uint256 value
    function getRewards(address _user) external view returns (uint256 _rewards) {
        return rewards[_user];
    }

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    /// @notice Contract's constructor
    /// @param _stakingToken Sets staking token
    /// @param _feesToken Sets fees token
    /// @param _rewardsToken Sets rewards token
    constructor(
        IERC20 _stakingToken,
        IERC20 _feesToken,
        IERC20 _rewardsToken
    ) public VotingPowerFees(_stakingToken, _feesToken) {
        rewardsToken = _rewardsToken;
    }

    /// @notice Claims reward for user
    /// @param account user for which to claim
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /// @notice Return timestamp last time reward applicable
    /// @return lastTimeRewardApplicable - uint256
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /// @notice Returns reward per full (10^18) token.
    /// @return rewardPerToken - uint256
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalSupply())
            );
    }

    /// @notice Returns earned reward fot account
    /// @param account user for which reward amount is requested
    /// @return earned - uint256
    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account).mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(
                rewards[account]
            );
    }

    /// @notice Pays earned reward to the user
    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /// @notice Notifies contract about the reward amount
    /// @param reward reward amount
    function notifyRewardAmount(uint256 reward) external override onlyRewardDistribution updateReward(address(0)) {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IGovernance {
    function withdraw(uint256) external;

    function getReward() external;

    function stake(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function exit() external;

    function voteFor(uint256) external;

    function voteAgainst(uint256) external;
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

// SPDX-License-Identifier: None
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/// @title ERC20 token staking to receive voting power
/// @notice This contracts allow to get voting power for DAO voting
/// @dev Voting power non-transferable, user can't send or receive it from another user, only get it from staking.
contract TokenToVotePowerStaking {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev Token which can be staked in exchange for voting power
    IERC20 internal stakingToken;
    /// @dev Total amount of the voting power in the system
    uint256 private _totalSupply;
    /// @dev Voting power balances
    mapping(address => uint256) private _balances;

    /// @notice Returns staking token address
    /// @return _stakingToken - staking token address
    function getStakingToken() external view returns(IERC20 _stakingToken){
        return stakingToken;
    }

    /// @notice Contract constructor
    /// @param _stakingToken Sets staking token
    constructor(IERC20 _stakingToken) public {
        stakingToken = _stakingToken;
    }

    /// @notice Returns amount of the voting power in the system
    /// @dev Returns _totalSupply variable
    /// @return Voting power amount
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Returns account's voting power balance
    /// @param account The address of the user
    /// @return Voting power balance of the user
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /// @notice Stakes token and adds voting power (with a 1:1 ratio)
    /// @dev Token amount must be approved to this contract before staking.
    /// @param amount Amount to stake
    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @notice Withdraws token and subtracts voting power (with a 1:1 ratio)
    /// @param amount Amount to withdraw
    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
    }
}