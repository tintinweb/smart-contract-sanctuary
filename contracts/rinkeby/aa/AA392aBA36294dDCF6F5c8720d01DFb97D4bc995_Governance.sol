// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
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
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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

interface Token {
    function approve(address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

interface LegacyToken {
    function transfer(address, uint) external;
}

interface SwissToken {
    function setSwissFeePercentX100(uint) external;
    function setDeshFeePercentX100(uint) external;
    function setSwissFeeWallet(address) external;
    function setDecashFeeWallet(address) external;
    function transferOwnership(address) external;
    function transferAnyERC20Token(address, address, uint) external;
    function transferAnyOldERC20Token(address, address, uint) external;
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }
    
    /**
   * @dev Throws if called by any account other than the owner.
   */
    modifier onlyPendingOwner() {
        assert(msg.sender != address(0));
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        pendingOwner = _newOwner;
    }
  
    /**
    * @dev Allows the pendingOwner address to finalize the transfer.
    */
    function claimOwnership() onlyPendingOwner public {
        _transferOwnership(pendingOwner);
        pendingOwner = address(0);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable {
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
        emit Paused(msg.sender);
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
        emit Unpaused(msg.sender);
    }
}


/**
 * @title Governance
 * @dev Governance smart contract
 * Takes in Governance Token as votes
 * Allows addition and removal of votes during a proposal is open
 * Allows withdrawal of all Governance Token once the latest voted proposal of a user is closed
 * Has a QUORUM requirement for proposals to be executed
 * CONTRACT VARIABLES must be changed to appropriate values before live deployment
 */
contract Governance is Ownable, Pausable {
    using SafeMath for uint;
    using Address for address;
    // Contracts are not allowed to deposit, claim or withdraw
    modifier noContractsAllowed() {
        require(!(address(msg.sender).isContract()) && tx.origin == msg.sender, "No Contracts Allowed!");
        _;
    }
    
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }
    
    // ============== CONTRACT VARIABLES ==============
    
    // voting token contract address
    address public constant TRUSTED_TOKEN_ADDRESS = 0x5A0fDD515a4dA3aa5705261D546cD22152d93f26;
    
    // minimum number of votes required for a result to be valid
    // 1 token = 1 vote
    uint public QUORUM = 50e18;
 
    // minimum number of tokens required to initialize a proposal
    uint public MIN_BALANCE_TO_INIT_PROPOSAL = 100e18;
    uint public MIN_BALANCE_TO_VOTE = 10e18;
    
    uint public constant MIN_FEES_X_100 = 0.5e2;
    uint public constant MAX_FEES_X_100 = 20e2;
    uint public constant MIN_USERS_FOR_VALID_PROPOSAL_EXECUTION = 5;
    
    // duration since proposal creation till users can vote
    uint public constant VOTE_DURATION = 3 days;
    
    // duration after voting, since a proposal has passed
    // during which the proposed action may be executed
    uint public constant RESULT_EXECUTION_ALLOWANCE_PERIOD = 3 days;
    
    // ============ END CONTRACT VARIABLES ============
    
    uint public immutable contractStartTime;
    uint public lastProposalStartTime;
  
    
    constructor() public {
        contractStartTime = now;
    }
    
    enum Action {
        CHANGE_SWISS_FEE,
        CHANGE_DESH_FEE,
        
        CHANGE_QUORUM,
        CHANGE_MIN_BALANCE_TO_INIT_PROPOSAL,
        CHANGE_MIN_BALANCE_TO_VOTE,
        UPGRADE_GOVERNANCE,
        
        TEXT_PROPOSAL
    }
    
    enum Option {
        ONE, // option 1 | yes
        TWO // option 2 | no
    }
    
    // proposal id => action
    mapping (uint => Action) public actions;
    
    // proposal id => option one votes
    mapping (uint => uint) public optionOneVotes;
    
    // proposal id => option two votes
    mapping (uint => uint) public optionTwoVotes;

    
    // proposal id => newGovernance
    mapping (uint => address) public newGovernances;
    
    // proposal id => unix time for proposal start
    mapping (uint => uint) public proposalStartTime;
    
    // proposal id => bool
    mapping (uint => bool) public isProposalExecuted;
    
    mapping (uint => uint) public newQuorums;
    mapping (uint => uint) public newMinBalancesToVote;
    mapping (uint => uint) public newMinBalancesToInitProposal;
    mapping (uint => string) public proposalTexts;
    mapping (uint => uint) public newSwissFees;
    mapping (uint => uint) public newDeshFees;
    
    // address user => total deposited Governance tokens
    mapping (address => uint) public totalDepositedTokens;
    
    // address user => uint proposal id => uint vote amounts
    mapping (address => mapping (uint => uint)) public votesForProposalByAddress;
    
    // address user => uint proposal id => Option voted for option
    mapping (address => mapping (uint => Option)) public votedForOption;
    
    // address user => uint timestamp for the latest proposal the user voted on
    mapping (address => uint) public lastVotedProposalStartTime;
    
    mapping (uint => uint) public proposalYesVotersCount;
    mapping (address => mapping (uint => bool)) public hasVotedForProposal;
    
    // uint last proposal id
    // proposal ids start at 1
    uint public lastIndex = 0;
    
    // view function to get proposal details
    function getProposal(uint proposalId) external view returns (
        uint _proposalId, 
        Action _proposalAction,
        uint _optionOneVotes,
        uint _optionTwoVotes,
        address _newGovernance,
        uint _proposalStartTime,
        bool _isProposalExecuted,
        uint _newQuorum,
        string memory _proposalText,
        uint _newMinBalanceToInitProposal,
        uint _newMinBalanceToVote,
        uint _newSwissFee,
        uint _newDeshFee
        ) {
        _proposalId = proposalId;
        _proposalAction = actions[proposalId];
        _optionOneVotes = optionOneVotes[proposalId];
        _optionTwoVotes = optionTwoVotes[proposalId];

        _newGovernance = newGovernances[proposalId];
        _proposalStartTime = proposalStartTime[proposalId];
        _isProposalExecuted = isProposalExecuted[proposalId];
        _newQuorum = newQuorums[proposalId];
        _proposalText = proposalTexts[proposalId];
        _newMinBalanceToInitProposal = newMinBalancesToInitProposal[proposalId];
        _newMinBalanceToVote = newMinBalancesToVote[proposalId];
        
        _newSwissFee = newSwissFees[proposalId];
        _newDeshFee = newDeshFees[proposalId];
    }
    
    modifier canPropose() {
        require(now > lastProposalStartTime.add(VOTE_DURATION), "Cannot initiate a proposal, please wait for current proposal to be closed.");
        _;
    }
    
    
    // Any Governance Token holder with a minimum required Governance Token balance may initiate a proposal
    // with the TEXT_PROPOSAL action
    function proposeText(string memory text) external noContractsAllowed canPropose whenNotPaused {
        require(Token(TRUSTED_TOKEN_ADDRESS).balanceOf(msg.sender) >= MIN_BALANCE_TO_INIT_PROPOSAL, "Insufficient Governance Token Balance");
        lastIndex = lastIndex.add(1);
        
        proposalTexts[lastIndex] = text;
        
        proposalStartTime[lastIndex] = now;
        lastProposalStartTime = now;
        actions[lastIndex] = Action.TEXT_PROPOSAL;
        
    }
    
    // Any Governance Token holder with a minimum required Governance Token balance may initiate a proposal
    // with the CHANGE_SWISS_FEE action
    function proposeNewSwissFee(uint newSwissFee) external noContractsAllowed canPropose whenNotPaused {
        require(newSwissFee >= MIN_FEES_X_100 && newSwissFee <= MAX_FEES_X_100, "Fee outside bounds!");
        require(Token(TRUSTED_TOKEN_ADDRESS).balanceOf(msg.sender) >= MIN_BALANCE_TO_INIT_PROPOSAL, "Insufficient Governance Token Balance");
        lastIndex = lastIndex.add(1);
        
        newSwissFees[lastIndex] = newSwissFee;
        
        proposalStartTime[lastIndex] = now;
        lastProposalStartTime = now;
        actions[lastIndex] = Action.CHANGE_SWISS_FEE;
    }
    
    // Any Governance Token holder with a minimum required Governance Token balance may initiate a proposal
    // with the CHANGE_DESH_FEE action
    function proposeNewDeshFee(uint newDeshFee) external noContractsAllowed canPropose whenNotPaused {
        require(newDeshFee >= MIN_FEES_X_100 && newDeshFee <= MAX_FEES_X_100, "Fee outside bounds!");
        require(Token(TRUSTED_TOKEN_ADDRESS).balanceOf(msg.sender) >= MIN_BALANCE_TO_INIT_PROPOSAL, "Insufficient Governance Token Balance");
        lastIndex = lastIndex.add(1);
        
        newDeshFees[lastIndex] = newDeshFee;
        
        proposalStartTime[lastIndex] = now;
        lastProposalStartTime = now;
        actions[lastIndex] = Action.CHANGE_DESH_FEE;
    }
    
    // Admin may initiate a proposal
    // with the UPGRADE_GOVERNANCE action
    function proposeUpgradeGovernance(address newGovernance) external noContractsAllowed onlyOwner canPropose whenNotPaused {
        require(Token(TRUSTED_TOKEN_ADDRESS).balanceOf(msg.sender) >= MIN_BALANCE_TO_INIT_PROPOSAL, "Insufficient Governance Token Balance");
        lastIndex = lastIndex.add(1);
        
        newGovernances[lastIndex] = newGovernance;
        
        proposalStartTime[lastIndex] = now;
        lastProposalStartTime = now;
        actions[lastIndex] = Action.UPGRADE_GOVERNANCE;
    }
    
    // Admin may initiate a proposal
    // with the CHANGE_QUORUM action for the Governance
    function proposeNewQuorum(uint newQuorum) external noContractsAllowed onlyOwner canPropose whenNotPaused {
        require(Token(TRUSTED_TOKEN_ADDRESS).balanceOf(msg.sender) >= MIN_BALANCE_TO_INIT_PROPOSAL, "Insufficient Governance Token Balance");
        lastIndex = lastIndex.add(1);
        
        newQuorums[lastIndex] = newQuorum;
        
        proposalStartTime[lastIndex] = now;
        lastProposalStartTime = now;
        actions[lastIndex] = Action.CHANGE_QUORUM;
    }
    
    // Admin may initiate a proposal
    // with the CHANGE_MIN_BALANCE_TO_INIT_PROPOSAL action for the Governance
    function proposeNewMinBalanceToInitProposal(uint newMinBalance) external noContractsAllowed onlyOwner canPropose whenNotPaused {
        require(Token(TRUSTED_TOKEN_ADDRESS).balanceOf(msg.sender) >= MIN_BALANCE_TO_INIT_PROPOSAL, "Insufficient Governance Token Balance");
        lastIndex = lastIndex.add(1);
        
        newMinBalancesToInitProposal[lastIndex] = newMinBalance;
        
        proposalStartTime[lastIndex] = now;
        lastProposalStartTime = now;
        actions[lastIndex] = Action.CHANGE_MIN_BALANCE_TO_INIT_PROPOSAL;
    }
    
    // Admin may initiate a proposal
    // with the CHANGE_MIN_BALANCE_TO_VOTE action for the Governance
    function proposeNewMinBalanceToVote(uint newMinBalance) external noContractsAllowed onlyOwner canPropose whenNotPaused {
        require(Token(TRUSTED_TOKEN_ADDRESS).balanceOf(msg.sender) >= MIN_BALANCE_TO_INIT_PROPOSAL, "Insufficient Governance Token Balance");
        lastIndex = lastIndex.add(1);
        
        newMinBalancesToVote[lastIndex] = newMinBalance;
        
        proposalStartTime[lastIndex] = now;
        lastProposalStartTime = now;
        actions[lastIndex] = Action.CHANGE_MIN_BALANCE_TO_VOTE;
    }
    
    // Any Governance Token holder may add votes for a particular open proposal, 
    // with options YES / NO | ONE / TWO
    // with `amount` Governance Token, each Governance Token unit corresponds to one vote unit
    
    // If user has already voted for a proposal with an option,
    // user may not add votes with another option, 
    // they will need to add votes for the same option
    function addVotes(uint proposalId, Option option, uint amount) external noContractsAllowed whenNotPaused {
        require(amount > 0, "Cannot add 0 votes!");
        require(Token(TRUSTED_TOKEN_ADDRESS).balanceOf(msg.sender) >= MIN_BALANCE_TO_VOTE, "Insufficient Governance Token Balance to Vote");
        require(isProposalOpen(proposalId), "Proposal is closed!");
        
        require(Token(TRUSTED_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), amount), "transferFrom failed!");
        
        // if user is voting for this proposal first time
        if (votesForProposalByAddress[msg.sender][proposalId] == 0) {
            votedForOption[msg.sender][proposalId] = option;
        } else {
            if (votedForOption[msg.sender][proposalId] != option) {
                revert("Cannot vote for both options!");
            }
        }
        
        if (option == Option.ONE) {
            optionOneVotes[proposalId] = optionOneVotes[proposalId].add(amount);
        } else {
            optionTwoVotes[proposalId] = optionTwoVotes[proposalId].add(amount);
        }
        totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].add(amount);
        votesForProposalByAddress[msg.sender][proposalId] = votesForProposalByAddress[msg.sender][proposalId].add(amount);
        
        if (lastVotedProposalStartTime[msg.sender] < proposalStartTime[proposalId]) {
            lastVotedProposalStartTime[msg.sender] = proposalStartTime[proposalId];
        }
        
        // counting yes voters
        if (!hasVotedForProposal[msg.sender][proposalId] && option == Option.ONE) {
            hasVotedForProposal[msg.sender][proposalId] = true;
            proposalYesVotersCount[proposalId] = proposalYesVotersCount[proposalId].add(1);
        }
    }
    
    // Any voter may remove their votes (Governance Token) from any proposal they voted for 
    // only when the proposal is open - removing votes refund Governance Token to user and deduct their votes
    function removeVotes(uint proposalId, uint amount) external noContractsAllowed {
        require(amount > 0, "Cannot remove 0 votes!");
        require(isProposalOpen(proposalId), "Proposal is closed!");
        
        require(amount <= votesForProposalByAddress[msg.sender][proposalId], "Cannot remove more tokens than deposited!");
        
        votesForProposalByAddress[msg.sender][proposalId] = votesForProposalByAddress[msg.sender][proposalId].sub(amount);
        totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].sub(amount);
        
        uint userVoteCount = votesForProposalByAddress[msg.sender][proposalId];
        
        if (votedForOption[msg.sender][proposalId] == Option.ONE) {
            optionOneVotes[proposalId] = optionOneVotes[proposalId].sub(amount);
        } else {
            optionTwoVotes[proposalId] = optionTwoVotes[proposalId].sub(amount);
        }
        
        require(Token(TRUSTED_TOKEN_ADDRESS).transfer(msg.sender, amount), "transfer failed");
        
        if (userVoteCount == 0 && hasVotedForProposal[msg.sender][proposalId]) {
            hasVotedForProposal[msg.sender][proposalId] = false;
            proposalYesVotersCount[proposalId] = proposalYesVotersCount[proposalId].sub(1);
        }
    }

    // After the latest proposal the user voted for, is closed for voting,
    // The user may remove all Governance Token they added to this contract
    function withdrawAllTokens() external noContractsAllowed {
        require(now > lastVotedProposalStartTime[msg.sender].add(VOTE_DURATION), "Tokens are still in voting!");
        require(Token(TRUSTED_TOKEN_ADDRESS).transfer(msg.sender, totalDepositedTokens[msg.sender]), "transfer failed!");
        totalDepositedTokens[msg.sender] = 0;
    }
    
    // After votes for a proposal are closed, the proposal may be executed by anyone
    // If QUORUM is not reached, transaction must revert
    // If winning option has more votes than losing option, winning action is executed
    // Else losing action is executed
    // Each proposal may be executed only once
    function executeProposal(uint proposalId) external noContractsAllowed whenNotPaused {
        require (proposalYesVotersCount[proposalId] >= MIN_USERS_FOR_VALID_PROPOSAL_EXECUTION, "Minimum Yes voters not reached");
        require (actions[proposalId] != Action.TEXT_PROPOSAL, "Cannot programmatically execute text proposals");
        require (optionOneVotes[proposalId] != optionTwoVotes[proposalId], "This is a TIE! Cannot execute!");
        require (isProposalExecutible(proposalId), "Proposal Expired!");
        
        isProposalExecuted[proposalId] = true;
    
        Option winningOption;
        uint winningOptionVotes;
        
        if (optionOneVotes[proposalId] > optionTwoVotes[proposalId]) {
            winningOption = Option.ONE;
            winningOptionVotes = optionOneVotes[proposalId];
        } else {
            winningOption = Option.TWO;
            winningOptionVotes = optionTwoVotes[proposalId];
        }
        
        // no action will be taken if winningOptionVotes are less than QUORUM
        if (winningOptionVotes < QUORUM) {
            revert("QUORUM not reached!");
        }
        
        // Do not proceed if proposal did not pass
        if (winningOption != Option.ONE) return;
        
        
        
        Action _action = actions[proposalId];
        
        if (_action == Action.CHANGE_SWISS_FEE) {
            SwissToken(TRUSTED_TOKEN_ADDRESS).setSwissFeePercentX100(newSwissFees[proposalId]);
            
        } else if (_action == Action.CHANGE_DESH_FEE) {
            SwissToken(TRUSTED_TOKEN_ADDRESS).setDeshFeePercentX100(newDeshFees[proposalId]);
            
        } else if (_action == Action.CHANGE_QUORUM) {
            QUORUM = newQuorums[proposalId];
            
        } else if (_action == Action.CHANGE_MIN_BALANCE_TO_VOTE) {
            MIN_BALANCE_TO_VOTE = newMinBalancesToVote[proposalId];
            
        } else if (_action == Action.CHANGE_MIN_BALANCE_TO_INIT_PROPOSAL) {
            MIN_BALANCE_TO_INIT_PROPOSAL = newMinBalancesToInitProposal[proposalId];
            
        } else if (_action == Action.UPGRADE_GOVERNANCE) {
            SwissToken(TRUSTED_TOKEN_ADDRESS).transferOwnership(newGovernances[proposalId]);
            
        }
    }
    
    // view function to know whether voting for a particular proposal is open
    function isProposalOpen(uint proposalId) public view returns (bool) {
        if (now < proposalStartTime[proposalId].add(VOTE_DURATION)) {
            return true;
        }
        return false;
    }
    
    // View function to know whether voting for a proposal is closed AND 
    // The proposal is within the RESULT_EXECUTION_ALLOWANCE_PERIOD AND
    // Has not been executed yet
    function isProposalExecutible(uint proposalId) public view returns (bool) {
        if ((!isProposalOpen(proposalId)) && 
            (now < proposalStartTime[proposalId].add(VOTE_DURATION).add(RESULT_EXECUTION_ALLOWANCE_PERIOD)) &&
            !isProposalExecuted[proposalId] &&
            optionOneVotes[proposalId] != optionTwoVotes[proposalId] && 
            proposalYesVotersCount[proposalId] >= MIN_USERS_FOR_VALID_PROPOSAL_EXECUTION) {
                return true;
            }
        return false;
    }
    
    function changeSwissFeeWallet(address newSwissFeeWallet) external onlyOwner {
        SwissToken(TRUSTED_TOKEN_ADDRESS).setSwissFeeWallet(newSwissFeeWallet);
    }
    function changeDeshFeeWallet(address newDeshFeeWallet) external onlyOwner {
        SwissToken(TRUSTED_TOKEN_ADDRESS).setDecashFeeWallet(newDeshFeeWallet);
    }
    
    // function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    // Admin cannot transfer out reward tokens from this smart contract
    function transferAnyERC20Token(address tokenAddress, address recipient, uint amount) external onlyOwner {
        require (tokenAddress != TRUSTED_TOKEN_ADDRESS, "Cannot Transfer Out main tokens!");
        require (Token(tokenAddress).transfer(recipient, amount), "Transfer failed!");
    }
    
    // function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    // Admin cannot transfer out reward tokens from this smart contract
    function transferAnyLegacyERC20Token(address tokenAddress, address recipient, uint amount) external onlyOwner {
        require (tokenAddress != TRUSTED_TOKEN_ADDRESS, "Cannot Transfer Out main tokens!");
        LegacyToken(tokenAddress).transfer(recipient, amount);
    }
    
    // function to allow admin to claim *other* ERC20 tokens sent to pool contract (by mistake)
    // Admin cannot transfer out reward tokens from this smart contract
    function transferAnyERC20TokenFromTokenContract(address tokenAddress, address recipient, uint amount) external onlyOwner {
        SwissToken(TRUSTED_TOKEN_ADDRESS).transferAnyERC20Token(tokenAddress, recipient, amount);
    }
    
    // function to allow admin to claim *other* ERC20 tokens sent to pool contract (by mistake)
    // Admin cannot transfer out reward tokens from this smart contract
    function transferAnyLegacyERC20TokenFromTokenContract(address tokenAddress, address recipient, uint amount) external onlyOwner {
        SwissToken(TRUSTED_TOKEN_ADDRESS).transferAnyOldERC20Token(tokenAddress, recipient, amount);
    }
    
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}