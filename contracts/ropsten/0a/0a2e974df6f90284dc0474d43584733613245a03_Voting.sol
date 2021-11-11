/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

/**
 *Submitted for verification at Etherscan.io on 2020-04-22
*/

pragma solidity 0.5.13;



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


/**
 * @title Synthetix Grants DAO
 * @notice This contract allows for grants to be proposed and voted on by community members
 * and the Synthetix team. All proposals must receive at least one approving vote by a
 * Synthetix member before funds will transfer.
 */
contract Voting {

  using SafeMath for uint256;

  uint256 public constant VOTING_PHASE = 600;
  uint256 public toPass;
  uint256 public counter = 1;

  IERC20 public DRY;

  struct Proposal {
    bool teamApproval;
    address receiver;
    uint256 amount;
    uint256 createdAt;
    uint256 approvals;
    string description;
    string url;
    mapping(address => bool) voted;
  }

  mapping(uint256 => Proposal) public proposals;
  mapping(uint256 => Proposal) public completeProposals;
  mapping(address => bool) public teamMembers;
  mapping(address => bool) public communityMembers;

  address[] private teamAddresses;
  address[] private communityAddresses;
  uint256[] private validProposals;
  uint256[] private completeProposalIds;

  event NewProposal(address receiver, uint256 amount, uint256 proposalNumber);
  event VoteProposal(uint256 proposal, address member, bool vote);
  event ExecuteProposal(address receiver, uint256 amount);
  event DeleteProposal(uint256 proposalNumber);

  /**
   * @notice Contract is created with an initial array of team and community members
   * which will be stored in mappings
   * @param _DRY The address of the DRY token
   * @param _teamMembers An array of addresses for the team members
   * @param _communityMembers An array of addresses for the community members
   * @param _toPass The number of votes each proposal is required in order to execute
   */
  constructor(
    address _DRY,
    address[] memory _teamMembers,
    address[] memory _communityMembers,
    uint256 _toPass
  ) public {
    require(_teamMembers.length > 0, "Need at least one teamMember");
    require(_toPass <= (_teamMembers.length + _communityMembers.length), "Invalid value to pass proposals");

    // Add members to their respective mappings and increase members count
    for (uint i = 0; i < _teamMembers.length; i++) {
      teamMembers[_teamMembers[i]] = true;
      teamAddresses.push(_teamMembers[i]);
    }
    for (uint i = 0; i < _communityMembers.length; i++) {
      communityMembers[_communityMembers[i]] = true;
      communityAddresses.push(_communityMembers[i]);
    }

    toPass = _toPass;
    DRY = IERC20(_DRY);
  }

  /**
   * @notice Called by proposers (team or community) to propose funding for an address.
   * Emits NewProposal event.
   * @param _receiver The address to receive funds if proposal executes
   * @param _amount The amount that the receiver will receive
   * @param _description The description of the proposal
   * @return The proposal number for reference
   */
  function createProposal(
    address _receiver,
    uint256 _amount,
    string calldata _description,
    string calldata _url
  ) external onlyProposer() returns (uint256) {
    require(_amount > 0, "Amount must be greater than 0");
    require(_receiver != address(0), "Receiver cannot be zero address");

    uint256 _counter = counter; // Pull counter into memory to save gas
    counter = _counter.add(1);

    proposals[_counter] = Proposal(
      false,
      _receiver,
      _amount,
      block.timestamp,
      1,
      _description,
      _url
    );

    // If a proposal is created by a team member, mark it as approved by the team
    if (teamMembers[msg.sender]) {
      proposals[_counter].teamApproval = true;
    }

    proposals[_counter].voted[msg.sender] = true;
    validProposals.push(_counter);

    emit NewProposal(_receiver, _amount, _counter);

    return _counter;
  }

  /**
   * @notice Called by proposers (team or community) to vote for a specified proposal.
   * Emits VoteProposal event.
   * @param _proposal The proposal number to vote on
   * @param _vote Boolean to indicate whether or not they approve of the proposal
   */
  function voteProposal(uint256 _proposal, bool _vote) external onlyProposer() {
    require(votingPhase(_proposal), "Proposal not in voting phase");
    require(!proposals[_proposal].voted[msg.sender], "Already voted");
    proposals[_proposal].voted[msg.sender] = true;

    if (_vote) {
      if (teamMembers[msg.sender]) {
        proposals[_proposal].teamApproval = true;
      }
      proposals[_proposal].approvals = proposals[_proposal].approvals.add(1);

      // Only execute if enough approvals AND the proposal has at least one teamApproval
      if (proposals[_proposal].approvals >= toPass && proposals[_proposal].teamApproval) {
        _executeProposal(_proposal);
      }
    } else {
      // Allows a team member to automatically kill a proposal
      if (teamMembers[msg.sender]) {
        _deleteProposal(_proposal);
        // Do not emit VoteProposal if deleting
        return;
      }
    }

    emit VoteProposal(_proposal, msg.sender, _vote);
  }

  /**
   * @notice Called by proposers to clean up storage and unlock funds.
   * Emits DeleteProposal event.
   * @param _proposal The proposal number to delete
   */
  function deleteProposal(uint256 _proposal) external onlyProposer() {
    require(block.timestamp > proposals[_proposal].createdAt.add(VOTING_PHASE), "Proposal not expired");
    _deleteProposal(_proposal);
  }

  /**
   * @notice Returns the addresses for the active community members
   * @return Array of community member addresses
   */
  function getCommunityMembers() external view returns (address[] memory) {
    return communityAddresses;
  }

  /**
   * @notice Gets the addresses for the active team members
   * @return Array of team member addresses
   */
  function getTeamMembers() external view returns (address[] memory) {
    return teamAddresses;
  }

  /**
   * @notice Gets the proposal IDs of active proposals
   * @return Unsorted array of proposal IDs
   */
  function getProposals() external view returns (uint256[] memory) {
    return validProposals;
  }

  /**
   * @notice Gets the proposal IDs of complete proposals
   * @return Unsorted array of proposal IDs
   */
  function getCompleteProposals() external view returns (uint256[] memory) {
    return completeProposalIds;
  }

  /**
   * @notice Called by team members to withdraw extra tokens in the contract
   * @param _receiver The address to receive tokens
   * @param _amount The amount to withdraw
   */
  function withdraw(address _receiver, uint256 _amount) external onlyTeamMember() {
    require(_amount <= withdrawable(), "Unable to withdraw amount");
    assert(DRY.transfer(_receiver, _amount));
  }

  /**
  * @notice Allows team members to withdraw any tokens from the contract
  * @param _receiver The address to receive tokens
  * @param _amount The amount to withdraw
  * @param _erc20 The address of the ERC20 token being transferred
  *
  */
  function withdrawERC20(address _receiver, uint256 _amount, address _erc20) external onlyTeamMember() {
    if (_erc20 == address(DRY)) {
      require(_amount <= withdrawable(), "Unable to withdraw amount");
    }
    assert(IERC20(_erc20).transfer(_receiver, _amount));
  }

  /**
   * @notice Allows community members to be added as proposers and voters
   * @param _member The address of the community member
   */
  function addCommunityMember(address[] calldata  _member) external onlyTeamMember() {
          for (uint i = 0; i < _member.length; i++) {
    communityMembers[_member[i]] = true;
    communityAddresses.push(_member[i]);
  }
}
  /**
   * @notice Allows community members to be removed
   * @dev The caller can specify an array of proposals to have the member's vote removed
   * @param _member The address of the community member
   * @param _proposals The array of proposals to have the member's vote removed from
   */
  function removeCommunityMember(address _member, uint256[] calldata _proposals) external onlyTeamMember() {
    delete communityMembers[_member];
    for (uint i = 0; i < communityAddresses.length; i++) {
      if (communityAddresses[i] == _member) {
        communityAddresses[i] = communityAddresses[communityAddresses.length - 1];
        communityAddresses.length--;
      }
    }
    for (uint i = 0; i < _proposals.length; i++) {
      require(proposals[_proposals[i]].voted[_member], "Member did not vote for proposal");
      delete proposals[_proposals[i]].voted[_member];
      proposals[_proposals[i]].approvals = proposals[_proposals[i]].approvals.sub(1);
    }
  }

  /**
   * @notice Allows team members to be added
   * @param _member The address of the team member
   */
  function addTeamMember(address _member) external onlyTeamMember() {
    teamMembers[_member] = true;
    teamAddresses.push(_member);
  }

  /**
   * @notice Allows team members to be removed
   * @param _member The address of the team member
   */
  function removeTeamMember(address _member) external onlyTeamMember() {
    // Prevents the possibility of there being no team members
    require(msg.sender != _member, "Cannot remove self");
    delete teamMembers[_member];
    for (uint i = 0; i < teamAddresses.length; i++) {
      if (teamAddresses[i] == _member) {
        teamAddresses[i] = teamAddresses[teamAddresses.length - 1];
        teamAddresses.length--;
      }
    }
  }

  /**
   * @notice Allows the number of votes required to pass a proposal to be updated
   * @param _toPass The new value for the number of votes to pass a proposal
   */
  function updateToPass(uint256 _toPass) external onlyTeamMember() {
    require(_toPass > 0, "Invalid value to pass proposals");
    toPass = _toPass;
  }

  /**
  * @notice Allows team members to update the DRY proxy address being used
  * @param _proxy The new proxy address to be used
  */
  function updateProxyAddress(address _proxy) external onlyTeamMember() {
    require(_proxy != address(DRY), "Cannot set proxy address to the current proxy address");
    DRY = IERC20(_proxy);
  }

  /**
   * @notice Shows the balance of the contract which can be withdrawn by team members
   * @return The withdrawable balance
   */
  function withdrawable() public view returns (uint256) {
    return DRY.balanceOf(address(this));
  }

  /**
   * @notice Displays the total balance of the contract
   * @return The balance of the contract
   */
  function totalBalance() external view returns (uint256) {
    return DRY.balanceOf(address(this));
  }

  /**
   * @notice Checks to see whether an address has voted on a proposal
   * @return Boolean indicating if the address has voted
   */
  function voted(address _member, uint256 _proposal) external view returns (bool) {
    return proposals[_proposal].voted[_member];
  }

  /**
   * @notice Check to see whether a proposal is in the voting phase
   * @param _proposal The proposal number to check
   * @return Boolean indicating if the proposal is in the voting phase
   */
  function votingPhase(uint256 _proposal) public view returns (bool) {
    uint256 createdAt = proposals[_proposal].createdAt;
    return block.timestamp <= createdAt.add(VOTING_PHASE);
  }

  /**
   * @dev Private method to delete a proposal
   * @param _proposal The proposal number to delete
   */
  function _deleteProposal(uint256 _proposal) private {
    delete proposals[_proposal];
    for (uint i = 0; i < validProposals.length; i++) {
      if (validProposals[i] == _proposal) {
        validProposals[i] = validProposals[validProposals.length - 1];
        validProposals.length--;
      }
    }
    emit DeleteProposal(_proposal);
  }

  /**
   * @dev Private method to execute a proposal
   * @param _proposal The proposal number to delete
   */
  function _executeProposal(uint256 _proposal) private {
    Proposal memory proposal = proposals[_proposal];
    require(withdrawable() >= proposal.amount, "Not enough DRY to execute proposal");
    completeProposalIds.push(_proposal);
    completeProposals[_proposal] = proposal;
    _deleteProposal(_proposal);
    for (uint i = 0; i < validProposals.length; i++) {
      if (validProposals[i] == _proposal) {
        validProposals[i] = validProposals[validProposals.length - 1];
        validProposals.length--;
      }
    }
    assert(DRY.transfer(proposal.receiver, proposal.amount));
    emit ExecuteProposal(proposal.receiver, proposal.amount);
  }

  /**
   * @dev Reverts if caller is not a team member
   */
  modifier onlyTeamMember() {
    require(teamMembers[msg.sender], "Not team member");
    _;
  }

  /**
   * @dev Reverts if caller is not a proposer (team or community member)
   */
  modifier onlyProposer() {
    require(
      teamMembers[msg.sender] ||
      communityMembers[msg.sender],
      "Not proposer"
    );
    _;
  }
}