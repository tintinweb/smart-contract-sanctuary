// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-v4/token/ERC20/IERC20.sol";
import "../../interfaces/IGovernance.sol";
import "../../interfaces/IMemberRoles.sol";
import "../../interfaces/IQuotationData.sol";
import "../../interfaces/ITokenController.sol";
import "../../interfaces/ICover.sol";
import "../../interfaces/ITokenData.sol";
import "../../interfaces/INXMToken.sol";
import "../../interfaces/IStakingPool.sol";
import "../../abstract/LegacyMasterAware_sol0_8.sol";
import "./external/Governed.sol";

contract MemberRoles is IMemberRoles, Governed, LegacyMasterAware {
  ITokenController public tc;
  ITokenData internal td;
  IQuotationData internal qd;
  ICover internal cover;
  IGovernance internal gv;
  address internal _unused1;
  INXMToken public tk;

  struct MemberRoleDetails {
    uint memberCounter;
    mapping(address => bool) memberActive;
    address[] memberAddress;
    address authorized;
  }

  MemberRoleDetails[] internal memberRoleData;
  bool internal constructorCheck;
  uint public maxABCount;
  bool public launched;
  uint public launchedOn;

  mapping (address => address payable) public _unused2;

  modifier checkRoleAuthority(uint _memberRoleId) {
    if (memberRoleData[_memberRoleId].authorized != address(0))
      require(msg.sender == memberRoleData[_memberRoleId].authorized);
    else
      require(isAuthorizedToGovern(msg.sender), "Not Authorized");
    _;
  }

  /**
   * @dev to swap advisory board member
   * @param _newABAddress is address of new AB member
   * @param _removeAB is advisory board member to be removed
   */
  function swapABMember(
    address _newABAddress,
    address _removeAB
  )
  external
  checkRoleAuthority(uint(Role.AdvisoryBoard)) {

    _updateRole(_newABAddress, uint(Role.AdvisoryBoard), true);
    _updateRole(_removeAB, uint(Role.AdvisoryBoard), false);

  }

  /**
   * @dev to swap the owner address
   * @param _newOwnerAddress is the new owner address
   */
  function swapOwner(
    address _newOwnerAddress
  )
  external override {
    require(msg.sender == address(ms));
    _updateRole(ms.owner(), uint(Role.Owner), false);
    _updateRole(_newOwnerAddress, uint(Role.Owner), true);
  }

  /**
   * @dev is used to add initital advisory board members
   * @param abArray is the list of initial advisory board members
   */
  function addInitialABMembers(address[] calldata abArray) external override onlyOwner {

    //Ensure that NXMaster has initialized.
    require(ms.masterInitialized());

    require(maxABCount >= numberOfMembers(uint(Role.AdvisoryBoard)) + abArray.length);
    //AB count can't exceed maxABCount
    for (uint i = 0; i < abArray.length; i++) {
      require(checkRole(abArray[i], uint(Role.Member)));
      _updateRole(abArray[i], uint(Role.AdvisoryBoard), true);
    }
  }

  /**
   * @dev to change max number of AB members allowed
   * @param _val is the new value to be set
   */
  function changeMaxABCount(uint _val) external onlyInternal {
    maxABCount = _val;
  }

  /**
   * @dev Iupgradable Interface to update dependent contract address
   */
  function changeDependentContractAddress() public {
    td = ITokenData(ms.getLatestAddress("TD"));
    qd = IQuotationData(ms.getLatestAddress("QD"));
    gv = IGovernance(ms.getLatestAddress("GV"));
    tk = INXMToken(ms.tokenAddress());
    tc = ITokenController(ms.getLatestAddress("TC"));
    cover = ICover(ms.getLatestAddress("CO"));
  }

  /**
   * @dev to change the master address
   * @param _masterAddress is the new master address
   */
  function changeMasterAddress(address _masterAddress) public override {

    if (masterAddress != address(0)) {
      require(masterAddress == msg.sender);
    }

    masterAddress = _masterAddress;
    ms = INXMMaster(_masterAddress);
    nxMasterAddress = _masterAddress;
  }

  /**
   * @dev to initiate the member roles
   * @param _firstAB is the address of the first AB member
   * @param memberAuthority is the authority (role) of the member
   */
  function memberRolesInitiate(address _firstAB, address memberAuthority) public {
    require(!constructorCheck);
    _addInitialMemberRoles(_firstAB, memberAuthority);
    constructorCheck = true;
  }

  /// @dev Adds new member role
  /// @param _roleName New role name
  /// @param _roleDescription New description hash
  /// @param _authorized Authorized member against every role id
  function addRole(//solhint-disable-line
    bytes32 _roleName,
    string memory _roleDescription,
    address _authorized
  )
  public
  onlyAuthorizedToGovern {
    _addRole(_roleName, _roleDescription, _authorized);
  }

  /// @dev Assign or Delete a member from specific role.
  /// @param _memberAddress Address of Member
  /// @param _roleId RoleId to update
  /// @param _active active is set to be True if we want to assign this role to member, False otherwise!
  function updateRole(//solhint-disable-line
    address _memberAddress,
    uint _roleId,
    bool _active
  )
  public
  checkRoleAuthority(_roleId) {
    _updateRole(_memberAddress, _roleId, _active);
  }

  /**
   * @dev to add members before launch
   * @param userArray is list of addresses of members
   * @param tokens is list of tokens minted for each array element
   */
  function addMembersBeforeLaunch(address[] memory userArray, uint[] memory tokens) public onlyOwner {
    require(!launched);

    for (uint i = 0; i < userArray.length; i++) {
      require(!ms.isMember(userArray[i]));
      tc.addToWhitelist(userArray[i]);
      _updateRole(userArray[i], uint(Role.Member), true);
      tc.mint(userArray[i], tokens[i]);
    }
    launched = true;
    launchedOn = block.timestamp;

  }

  /**
    * @dev Called by user to pay joining membership fee
    */
  function payJoiningFee(address _userAddress) public override payable {
    require(_userAddress != address(0));
    require(!ms.isPause(), "Emergency Pause Applied");
    if (msg.sender == address(ms.getLatestAddress("QT"))) {
      // [todo] Add walletAddress as a MemberRoles gov param. Use call an reentrancy guard instead.
      require(td.walletAddress() != address(0), "No walletAddress present");
      tc.addToWhitelist(_userAddress);
      _updateRole(_userAddress, uint(Role.Member), true);
      td.walletAddress().transfer(msg.value);
    } else {
      require(!qd.refundEligible(_userAddress));
      require(!checkRole(_userAddress, uint(Role.Member)));
      require(msg.value == td.joiningFee());
      // [todo] Move refundEligible to MemberRoles
      qd.setRefundEligible(_userAddress, true);
    }
  }

  /**
   * @dev to perform kyc verdict
   * @param _userAddress whose kyc is being performed
   * @param verdict of kyc process
   */
  function kycVerdict(address payable _userAddress, bool verdict) public override {
  // [todo] Move kycAuthAddress to MemberRoles
    require(msg.sender == qd.kycAuthAddress());
    require(!ms.isPause());
    require(_userAddress != address(0));
    require(!ms.isMember(_userAddress));
    require(qd.refundEligible(_userAddress));
    if (verdict) {
      // [todo] Move refundEligible to MemberRoles
      qd.setRefundEligible(_userAddress, false);
      uint fee = td.joiningFee();
      tc.addToWhitelist(_userAddress);
      _updateRole(_userAddress, uint(Role.Member), true);
      // [todo] Add walletAddress as a MemberRoles gov param. Use call an reentrancy guard instead.
      td.walletAddress().transfer(fee); // solhint-disable-line

    } else {
      // [todo] Move refundEligible to MemberRoles
      qd.setRefundEligible(_userAddress, false);
      _userAddress.transfer(td.joiningFee()); // solhint-disable-line
    }
  }

  /**
   * @dev withdraws membership for msg.sender if currently a member.
   */
  function withdrawMembership() public {

    require(!ms.isPause() && ms.isMember(msg.sender));
    require(block.timestamp > tk.isLockedForMV(msg.sender)); // No locked tokens for Member/Governance voting

    gv.removeDelegation(msg.sender);
    tc.burnFrom(msg.sender, tk.balanceOf(msg.sender));
    _updateRole(msg.sender, uint(Role.Member), false);
    tc.removeFromWhitelist(msg.sender); // need clarification on whitelist
  }

  /**
   * @dev switches membership for msg.sender to the specified address.
   * @param newAddress address of user to forward membership.
   */
  function switchMembership(address newAddress) external override {
    _switchMembership(msg.sender, newAddress);
    tk.transferFrom(msg.sender, newAddress, tk.balanceOf(msg.sender));
  }

  /// Switches membership for msg.sender to the specified address and transfers the senders'
  /// assets in a single transaction.
  ///
  /// @param newAddress    Address of user to forward membership.
  /// @param coverIds      Array of cover ids to transfer to the new address.
  /// @param stakingPools  Array of staking pool addresses where the user has LP tokens.
  function switchMembershipAndAssets(
    address newAddress,
    uint[] calldata coverIds,
    address[] calldata stakingPools
  ) external override {
    _switchMembership(msg.sender, newAddress);
    tk.transferFrom(msg.sender, newAddress, tk.balanceOf(msg.sender));

    // Transfer the cover NFTs to the new address, if any were given
    cover.transferCovers(msg.sender, newAddress, coverIds);

    // Transfer the staking LP tokens to the new address, if any were given
    for (uint256 i = 0; i < stakingPools.length; i++) {
      IStakingPool stakingLPToken = IStakingPool(stakingPools[i]);
      uint fullAmount = stakingLPToken.balanceOf(msg.sender);
      stakingLPToken.operatorTransferFrom(msg.sender, newAddress, fullAmount);
    }
  }

  function switchMembershipOf(address member, address newAddress) external override onlyInternal {
    _switchMembership(member, newAddress);
  }

  function storageCleanup() external {
    _unused2[0x181Aea6936B407514ebFC0754A37704eB8d98F91] = payable(0x0000000000000000000000000000000000000000);
  }

  /**
   * @dev switches membership for member to the specified address.
   * @param newAddress address of user to forward membership.
   */
  function _switchMembership(address member, address newAddress) internal {

    require(!ms.isPause(), "System is paused");
    require(ms.isMember(member), "The current address is not a member");
    require(!ms.isMember(newAddress), "The new address is already a member");
    require(block.timestamp > tk.isLockedForMV(member), "Locked for governance voting"); // No locked tokens for Governance voting

    gv.removeDelegation(member);
    tc.addToWhitelist(newAddress);
    _updateRole(newAddress, uint(Role.Member), true);
    _updateRole(member, uint(Role.Member), false);
    tc.removeFromWhitelist(member);

    emit switchedMembership(member, newAddress, block.timestamp);
  }

  /// @dev Return number of member roles
  function totalRoles() public override view returns (uint256) {//solhint-disable-line
    return memberRoleData.length;
  }

  /// @dev Change Member Address who holds the authority to Add/Delete any member from specific role.
  /// @param _roleId roleId to update its Authorized Address
  /// @param _newAuthorized New authorized address against role id
  function changeAuthorized(
    uint _roleId,
    address _newAuthorized
  ) public override checkRoleAuthority(_roleId) {//solhint-disable-line
    memberRoleData[_roleId].authorized = _newAuthorized;
  }

  /// @dev Gets the member addresses assigned by a specific role
  /// @param _memberRoleId  Member role id
  /// @return roleId        Role id
  /// @return memberArray   Member addresses of specified role id
  function members(
    uint _memberRoleId
  ) public override view returns (uint, address[] memory memberArray) {//solhint-disable-line
    uint length = memberRoleData[_memberRoleId].memberAddress.length;
    uint i;
    uint j = 0;
    memberArray = new address[](memberRoleData[_memberRoleId].memberCounter);
    for (i = 0; i < length; i++) {
      address member = memberRoleData[_memberRoleId].memberAddress[i];
      if (memberRoleData[_memberRoleId].memberActive[member] && !_checkMemberInArray(member, memberArray)) {//solhint-disable-line
        memberArray[j] = member;
        j++;
      }
    }

    return (_memberRoleId, memberArray);
  }

  /// @dev Gets all members' length
  /// @param _memberRoleId Member role id
  /// @return memberRoleData[_memberRoleId].memberCounter Member length
  function numberOfMembers(
    uint _memberRoleId
  ) public override view returns (uint) {//solhint-disable-line
    return memberRoleData[_memberRoleId].memberCounter;
  }

  /// @dev Return member address who holds the right to add/remove any member from specific role.
  function authorized(
    uint _memberRoleId
  ) public override view returns (address) {//solhint-disable-line
    return memberRoleData[_memberRoleId].authorized;
  }

  /// @dev Get All role ids array that has been assigned to a member so far.
  function roles(
    address _memberAddress
  ) public override view returns (uint[] memory) {//solhint-disable-line
    uint length = memberRoleData.length;
    uint[] memory assignedRoles = new uint[](length);
    uint counter = 0;
    for (uint i = 1; i < length; i++) {
      if (memberRoleData[i].memberActive[_memberAddress]) {
        assignedRoles[counter] = i;
        counter++;
      }
    }
    return assignedRoles;
  }

  /// @dev Returns true if the given role id is assigned to a member.
  /// @param _memberAddress Address of member
  /// @param _roleId Checks member's authenticity with the roleId.
  /// i.e. Returns true if this roleId is assigned to member
  function checkRole(
    address _memberAddress,
    uint _roleId
  ) public override view returns (bool) {//solhint-disable-line
    if (_roleId == uint(Role.UnAssigned))
      return true;
    else
      if (memberRoleData[_roleId].memberActive[_memberAddress]) //solhint-disable-line
        return true;
      else
        return false;
  }

  /// @dev Return total number of members assigned against each role id.
  /// @return totalMembers Total members in particular role id
  function getMemberLengthForAllRoles() public override view returns (
    uint[] memory totalMembers
  ) {//solhint-disable-line
    totalMembers = new uint[](memberRoleData.length);
    for (uint i = 0; i < memberRoleData.length; i++) {
      totalMembers[i] = numberOfMembers(i);
    }
  }

  /**
   * @dev to update the member roles
   * @param _memberAddress in concern
   * @param _roleId the id of role
   * @param _active if active is true, add the member, else remove it
   */
  function _updateRole(address _memberAddress,
    uint _roleId,
    bool _active) internal {
    // require(_roleId != uint(Role.TokenHolder), "Membership to Token holder is detected automatically");
    if (_active) {
      require(!memberRoleData[_roleId].memberActive[_memberAddress]);
      memberRoleData[_roleId].memberCounter = memberRoleData[_roleId].memberCounter + 1;
      memberRoleData[_roleId].memberActive[_memberAddress] = true;
      memberRoleData[_roleId].memberAddress.push(_memberAddress);
    } else {
      require(memberRoleData[_roleId].memberActive[_memberAddress]);
      memberRoleData[_roleId].memberCounter = memberRoleData[_roleId].memberCounter - 1;
      delete memberRoleData[_roleId].memberActive[_memberAddress];
    }
  }

  /// @dev Adds new member role
  /// @param _roleName New role name
  /// @param _roleDescription New description hash
  /// @param _authorized Authorized member against every role id
  function _addRole(
    bytes32 _roleName,
    string memory _roleDescription,
    address _authorized
  ) internal {
    emit MemberRole(memberRoleData.length, _roleName, _roleDescription);
    MemberRoleDetails storage newMemberRoleData = memberRoleData.push();
    newMemberRoleData.memberCounter = 0;
    newMemberRoleData.memberAddress = new address[](0);
    newMemberRoleData.authorized = _authorized;
  }

  /// @dev Checks if a member address is in the given members array
  /// @param _memberAddress  The address that's checked against memberArray
  /// @param memberArray     Array of member addresses
  /// @return memberExists   True if the member exists
  function _checkMemberInArray(
    address _memberAddress,
    address[] memory memberArray
  )
  internal
  pure
  returns (bool memberExists)
  {
    uint i;
    for (i = 0; i < memberArray.length; i++) {
      if (memberArray[i] == _memberAddress) {
        memberExists = true;
        break;
      }
    }
  }

  /**
   * @dev to add initial member roles
   * @param _firstAB is the member address to be added
   * @param memberAuthority is the member authority(role) to be added for
   */
  function _addInitialMemberRoles(address _firstAB, address memberAuthority) internal {
    maxABCount = 5;
    _addRole("Unassigned", "Unassigned", address(0));
    _addRole(
      "Advisory Board",
      "Selected few members that are deeply entrusted by the dApp. An ideal advisory board should be a mix of skills of domain, governance, research, technology, consulting etc to improve the performance of the dApp.", //solhint-disable-line
      address(0)
    );
    _addRole(
      "Member",
      "Represents all users of Mutual.", //solhint-disable-line
      memberAuthority
    );
    _addRole(
      "Owner",
      "Represents Owner of Mutual.", //solhint-disable-line
      address(0)
    );
    // _updateRole(_firstAB, uint(Role.AdvisoryBoard), true);
    _updateRole(_firstAB, uint(Role.Owner), true);
    // _updateRole(_firstAB, uint(Role.Member), true);
    launchedOn = 0;
  }

  function memberAtIndex(
    uint _memberRoleId,
    uint index
  ) external override view returns (address, bool) {
    address memberAddress = memberRoleData[_memberRoleId].memberAddress[index];
    return (memberAddress, memberRoleData[_memberRoleId].memberActive[memberAddress]);
  }

  function membersLength(
    uint _memberRoleId
  ) external override view returns (uint) {
    return memberRoleData[_memberRoleId].memberAddress.length;
  }
}

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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IGovernance {

  event Proposal(
    address indexed proposalOwner,
    uint256 indexed proposalId,
    uint256 dateAdd,
    string proposalTitle,
    string proposalSD,
    string proposalDescHash
  );

  event Solution(
    uint256 indexed proposalId,
    address indexed solutionOwner,
    uint256 indexed solutionId,
    string solutionDescHash,
    uint256 dateAdd
  );

  event Vote(
    address indexed from,
    uint256 indexed proposalId,
    uint256 indexed voteId,
    uint256 dateAdd,
    uint256 solutionChosen
  );

  event RewardClaimed(
    address indexed member,
    uint gbtReward
  );

  /// @dev VoteCast event is called whenever a vote is cast that can potentially close the proposal.
  event VoteCast (uint256 proposalId);

  /// @dev ProposalAccepted event is called when a proposal is accepted so that a server can listen that can
  ///      call any offchain actions
  event ProposalAccepted (uint256 proposalId);

  /// @dev CloseProposalOnTime event is called whenever a proposal is created or updated to close it on time.
  event CloseProposalOnTime (
    uint256 indexed proposalId,
    uint256 time
  );

  /// @dev ActionSuccess event is called whenever an onchain action is executed.
  event ActionSuccess (
    uint256 proposalId
  );

  /// @dev Creates a new proposal
  /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
  /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
  function createProposal(
    string calldata _proposalTitle,
    string calldata _proposalSD,
    string calldata _proposalDescHash,
    uint _categoryId
  )
  external;

  /// @dev Edits the details of an existing proposal and creates new version
  /// @param _proposalId Proposal id that details needs to be updated
  /// @param _proposalDescHash Proposal description hash having long and short description of proposal.
  function updateProposal(
    uint _proposalId,
    string calldata _proposalTitle,
    string calldata _proposalSD,
    string calldata _proposalDescHash
  )
  external;

  /// @dev Categorizes proposal to proceed further. Categories shows the proposal objective.
  function categorizeProposal(
    uint _proposalId,
    uint _categoryId,
    uint _incentives
  )
  external;

  /// @dev Submit proposal with solution
  /// @param _proposalId Proposal id
  /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
  function submitProposalWithSolution(
    uint _proposalId,
    string calldata _solutionHash,
    bytes calldata _action
  )
  external;

  /// @dev Creates a new proposal with solution and votes for the solution
  /// @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
  /// @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
  /// @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
  function createProposalwithSolution(
    string calldata _proposalTitle,
    string calldata _proposalSD,
    string calldata _proposalDescHash,
    uint _categoryId,
    string calldata _solutionHash,
    bytes calldata _action
  )
  external;

  /// @dev Casts vote
  /// @param _proposalId Proposal id
  /// @param _solutionChosen solution chosen while voting. _solutionChosen[0] is the chosen solution
  function submitVote(uint _proposalId, uint _solutionChosen) external;

  function closeProposal(uint _proposalId) external;

  function claimReward(address _memberAddress, uint _maxRecords) external returns (uint pendingDAppReward);

  function proposal(uint _proposalId)
  external
  view
  returns (
    uint proposalId,
    uint category,
    uint status,
    uint finalVerdict,
    uint totalReward
  );

  function canCloseProposal(uint _proposalId) external view returns (uint closeValue);

  function allowedToCatgorize() external view returns (uint roleId);

  function removeDelegation(address _add) external;

  function getPendingReward(address _memberAddress) external view returns (uint pendingDAppReward);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IMemberRoles {

  enum Role {UnAssigned, AdvisoryBoard, Member, Owner}

  function payJoiningFee(address _userAddress) external payable;

  function switchMembership(address _newAddress) external;

  function switchMembershipAndAssets(
    address newAddress,
    uint[] calldata coverIds,
    address[] calldata stakingPools
  ) external;

  function switchMembershipOf(address member, address _newAddress) external;

  function swapOwner(address _newOwnerAddress) external;

  function addInitialABMembers(address[] calldata abArray) external;

  function kycVerdict(address payable _userAddress, bool verdict) external;

  function totalRoles() external view returns (uint256);

  function changeAuthorized(uint _roleId, address _newAuthorized) external;

  function members(uint _memberRoleId) external view returns (uint, address[] memory memberArray);

  function numberOfMembers(uint _memberRoleId) external view returns (uint);

  function authorized(uint _memberRoleId) external view returns (address);

  function roles(address _memberAddress) external view returns (uint[] memory);

  function checkRole(address _memberAddress, uint _roleId) external view returns (bool);

  function getMemberLengthForAllRoles() external view returns (uint[] memory totalMembers);

  function memberAtIndex(uint _memberRoleId, uint index) external view returns (address, bool);

  function membersLength(uint _memberRoleId) external view returns (uint);

  event MemberRole(uint256 indexed roleId, bytes32 roleName, string roleDescription);

  event switchedMembership(address indexed previousMember, address indexed newMember, uint timeStamp);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IQuotationData {

  function authQuoteEngine() external view returns (address);
  function stlp() external view returns (uint);
  function stl() external view returns (uint);
  function pm() external view returns (uint);
  function minDays() external view returns (uint);
  function tokensRetained() external view returns (uint);
  function kycAuthAddress() external view returns (address);

  function refundEligible(address) external view returns (bool);
  function holdedCoverIDStatus(uint) external view returns (uint);
  function timestampRepeated(uint) external view returns (bool);

  enum HCIDStatus {NA, kycPending, kycPass, kycFailedOrRefunded, kycPassNoCover}
  enum CoverStatus {Active, ClaimAccepted, ClaimDenied, CoverExpired, ClaimSubmitted, Requested}

  function addInTotalSumAssuredSC(address _add, bytes4 _curr, uint _amount) external;

  function subFromTotalSumAssuredSC(address _add, bytes4 _curr, uint _amount) external;

  function subFromTotalSumAssured(bytes4 _curr, uint _amount) external;

  function addInTotalSumAssured(bytes4 _curr, uint _amount) external;

  function setTimestampRepeated(uint _timestamp) external;

  /// @dev Creates a blank new cover.
  function addCover(
    uint16 _coverPeriod,
    uint _sumAssured,
    address payable _userAddress,
    bytes4 _currencyCode,
    address _scAddress,
    uint premium,
    uint premiumNXM
  ) external;


  function addHoldCover(
    address payable from,
    address scAddress,
    bytes4 coverCurr,
    uint[] calldata coverDetails,
    uint16 coverPeriod
  ) external;

  function setRefundEligible(address _add, bool status) external;

  function setHoldedCoverIDStatus(uint holdedCoverID, uint status) external;

  function setKycAuthAddress(address _add) external;

  function changeAuthQuoteEngine(address _add) external;

  function getUintParameters(bytes8 code) external view returns (bytes8 codeVal, uint val);

  function getProductDetails()
  external
  view
  returns (
    uint _minDays,
    uint _pm,
    uint _stl,
    uint _stlp
  );

  function getCoverLength() external view returns (uint len);

  function getAuthQuoteEngine() external view returns (address _add);

  function getTotalSumAssured(bytes4 _curr) external view returns (uint amount);

  function getAllCoversOfUser(address _add) external view returns (uint[] memory allCover);

  function getUserCoverLength(address _add) external view returns (uint len);

  function getCoverStatusNo(uint _cid) external view returns (uint8);

  function getCoverPeriod(uint _cid) external view returns (uint32 cp);

  function getCoverSumAssured(uint _cid) external view returns (uint sa);

  function getCurrencyOfCover(uint _cid) external view returns (bytes4 curr);

  function getValidityOfCover(uint _cid) external view returns (uint date);

  function getscAddressOfCover(uint _cid) external view returns (uint, address);

  function getCoverMemberAddress(uint _cid) external view returns (address payable _add);

  function getCoverPremiumNXM(uint _cid) external view returns (uint _premiumNXM);

  function getCoverDetailsByCoverID1(
    uint _cid
  )
  external
  view
  returns (
    uint cid,
    address _memberAddress,
    address _scAddress,
    bytes4 _currencyCode,
    uint _sumAssured,
    uint premiumNXM
  );

  function getCoverDetailsByCoverID2(
    uint _cid
  )
  external
  view
  returns (
    uint cid,
    uint8 status,
    uint sumAssured,
    uint16 coverPeriod,
    uint validUntil
  );

  function getHoldedCoverDetailsByID1(
    uint _hcid
  )
  external
  view
  returns (
    uint hcid,
    address scAddress,
    bytes4 coverCurr,
    uint16 coverPeriod
  );

  function getUserHoldedCoverLength(address _add) external view returns (uint);

  function getUserHoldedCoverByIndex(address _add, uint index) external view returns (uint);

  function getHoldedCoverDetailsByID2(
    uint _hcid
  )
  external
  view
  returns (
    uint hcid,
    address payable memberAddress,
    uint[] memory coverDetails
  );

  function getTotalSumAssuredSC(address _add, bytes4 _curr) external view returns (uint amount);

  function changeCoverStatusNo(uint _cid, uint8 _stat) external;

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

import "./INXMToken.sol";

interface ITokenController {

  struct CoverInfo {
    uint16 claimCount;
    bool hasOpenClaim;
    bool hasAcceptedClaim;
    // note: still 224 bits available here, can be used later
  }

  function coverInfo(uint id) external view returns (uint16 claimCount, bool hasOpenClaim, bool hasAcceptedClaim);

  function withdrawCoverNote(
    address _of,
    uint[] calldata _coverIds,
    uint[] calldata _indexes
  ) external;

  function changeOperator(address _newOperator) external;

  function operatorTransfer(address _from, address _to, uint _value) external returns (bool);

  function lockOf(address _of, bytes32 _reason, uint256 _amount, uint256 _time) external returns (bool);

  function extendLockOf(address _of, bytes32 _reason, uint256 _time) external returns (bool);

  function burnFrom(address _of, uint amount) external returns (bool);

  function burnLockedTokens(address _of, bytes32 _reason, uint256 _amount) external;

  function reduceLock(address _of, bytes32 _reason, uint256 _time) external;

  function releaseLockedTokens(address _of, bytes32 _reason, uint256 _amount) external;

  function addToWhitelist(address _member) external;

  function removeFromWhitelist(address _member) external;

  function mint(address _member, uint _amount) external;

  function lockForMemberVote(address _of, uint _days) external;
  function withdrawClaimAssessmentTokens(address _of) external;

  function getLockReasons(address _of) external view returns (bytes32[] memory reasons);

  function getLockedTokensValidity(address _of, bytes32 reason) external view returns (uint256 validity);

  function getUnlockableTokens(address _of) external view returns (uint256 unlockableTokens);

  function tokensLocked(address _of, bytes32 _reason) external view returns (uint256 amount);

  function tokensLockedWithValidity(address _of, bytes32 _reason)
  external
  view
  returns (uint256 amount, uint256 validity);

  function tokensUnlockable(address _of, bytes32 _reason) external view returns (uint256 amount);

  function totalSupply() external view returns (uint256);

  function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time) external view returns (uint256 amount);
  function totalBalanceOf(address _of) external view returns (uint256 amount);

  function totalLockedBalance(address _of) external view returns (uint256 amount);

  function token() external view returns (INXMToken);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface ICover {

  /* ========== DATA STRUCTURES ========== */

  enum RedeemMethod {
    Claim,
    Incident
  }

  // Basically CoverStatus from QuotationData.sol but with the extra Migrated status to avoid
  // polluting Cover.sol state layout with new status variables.
  enum LegacyCoverStatus {
    Active,
    ClaimAccepted,
    ClaimDenied,
    CoverExpired,
    ClaimSubmitted,
    Requested,
    Migrated
  }

  struct PoolAllocationRequest {
    uint64 poolId;
    uint coverAmountInAsset;
  }

  struct PoolAllocation {
    uint64 poolId;
    uint96 coverAmountInNXM;
    uint96 premiumInNXM;
  }

  struct CoverData {
    uint24 productId;
    uint8 payoutAsset;
    uint96 amountPaidOut;
  }

  struct CoverSegment {
    uint96 amount;
    uint32 start;
    uint32 period;  // seconds
    uint16 priceRatio;
  }

  struct BuyCoverParams {
    address owner;
    uint24 productId;
    uint8 payoutAsset;
    uint96 amount;
    uint32 period;
    uint maxPremiumInAsset;
    uint8 paymentAsset;
    bool payWithNXM;
    uint16 commissionRatio;
    address commissionDestination;
  }

  struct IncreaseAmountAndReducePeriodParams {
    uint coverId;
    uint32 periodReduction;
    uint96 amount;
    uint8 paymentAsset;
    uint maxPremiumInAsset;
  }

  struct ProductBucket {
    uint96 coverAmountExpiring;
  }

  struct IncreaseAmountParams {
    uint coverId;
    uint8 paymentAsset;
    PoolAllocationRequest[] coverChunkRequests;
  }

  struct Product {
    uint16 productType;
    address productAddress;
    /*
      cover assets bitmap. each bit in the base-2 representation represents whether the asset with the index
      of that bit is enabled as a cover asset for this product.
    */
    uint32 coverAssets;
    uint16 initialPriceRatio;
    uint16 capacityReductionRatio;
  }

  struct ProductType {
    string descriptionIpfsHash;
    uint8 redeemMethod;
    uint16 gracePeriodInDays;
  }

  /* ========== VIEWS ========== */

  function covers(uint id) external view returns (uint24, uint8, uint96, uint32, uint32, uint16);

  function products(uint id) external view returns (uint16, address, uint32, uint16, uint16);

  function productTypes(uint id) external view returns (string memory, uint8, uint16);

  /* === MUTATIVE FUNCTIONS ==== */

  function migrateCover(uint coverId, address toNewOwner) external;

  function migrateCoverFromOwner(uint coverId, address fromOwner, address toNewOwner) external;

  function buyCover(
    BuyCoverParams calldata params,
    PoolAllocationRequest[] calldata coverChunkRequests
  ) external payable returns (uint /*coverId*/);

  function createStakingPool(address manager) external;

  function setInitialPrices(
    uint[] calldata productId,
    uint16[] calldata initialPriceRatio
  ) external;

  function addProducts(Product[] calldata newProducts) external;

  function addProductTypes(ProductType[] calldata newProductTypes) external;

  function setCoverAssetsFallback(uint32 _coverAssetsFallback) external;

  function performPayoutBurn(uint coverId, uint amount) external returns (address /*owner*/);

  function coverNFT() external returns (address);

  function transferCovers(address from, address to, uint256[] calldata coverIds) external;

  /* ========== EVENTS ========== */

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface ITokenData {

  function walletAddress() external view returns (address payable);
  function lockTokenTimeAfterCoverExp() external view returns (uint);
  function bookTime() external view returns (uint);
  function lockCADays() external view returns (uint);
  function lockMVDays() external view returns (uint);
  function scValidDays() external view returns (uint);
  function joiningFee() external view returns (uint);
  function stakerCommissionPer() external view returns (uint);
  function stakerMaxCommissionPer() external view returns (uint);
  function tokenExponent() external view returns (uint);
  function priceStep() external view returns (uint);

  function depositedCN(uint) external view returns (uint amount, bool isDeposited);

  function lastCompletedStakeCommission(address) external view returns (uint);

  function changeWalletAddress(address payable _address) external;

  function getStakerStakedContractByIndex(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (address stakedContractAddress);

  function getStakerStakedBurnedByIndex(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint burnedAmount);

  function getStakerStakedUnlockableBeforeLastBurnByIndex(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint unlockable);

  function getStakerStakedContractIndex(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint scIndex);

  function getStakedContractStakerIndex(
    address _stakedContractAddress,
    uint _stakedContractIndex
  )
  external
  view
  returns (uint sIndex);

  function getStakerInitialStakedAmountOnContract(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint amount);

  function getStakerStakedContractLength(
    address _stakerAddress
  )
  external
  view
  returns (uint length);

  function getStakerUnlockedStakedTokens(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint amount);

  function pushUnlockedStakedTokens(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  ) external;


  function pushBurnedTokens(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  ) external;

  function pushUnlockableBeforeLastBurnTokens(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  ) external;

  function setUnlockableBeforeLastBurnTokens(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  ) external;

  function pushEarnedStakeCommissions(
    address _stakerAddress,
    address _stakedContractAddress,
    uint _stakedContractIndex,
    uint _commissionAmount
  ) external;

  function pushRedeemedStakeCommissions(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  ) external;

  function getStakerEarnedStakeCommission(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint);

  function getStakerRedeemedStakeCommission(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint);

  function getStakerTotalEarnedStakeCommission(
    address _stakerAddress
  )
  external
  view
  returns (uint totalCommissionEarned);

  function getStakerTotalReedmedStakeCommission(
    address _stakerAddress
  )
  external
  view
  returns (uint totalCommissionRedeemed);

  function setDepositCN(uint coverId, bool flag) external;

  function getStakedContractStakerByIndex(
    address _stakedContractAddress,
    uint _stakedContractIndex
  )
  external
  view
  returns (address stakerAddress);

  function getStakedContractStakersLength(
    address _stakedContractAddress
  ) external view returns (uint length);

  function addStake(
    address _stakerAddress,
    address _stakedContractAddress,
    uint _amount
  ) external returns (uint scIndex);

  function bookCATokens(address _of) external;

  function isCATokensBooked(address _of) external view returns (bool res);

  function setStakedContractCurrentCommissionIndex(
    address _stakedContractAddress,
    uint _index
  ) external;

  function setLastCompletedStakeCommissionIndex(
    address _stakerAddress,
    uint _index
  ) external;


  function setStakedContractCurrentBurnIndex(
    address _stakedContractAddress,
    uint _index
  ) external;

  function setDepositCNAmount(uint coverId, uint amount) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface INXMToken {

  function burn(uint256 amount) external returns (bool);

  function burnFrom(address from, uint256 value) external returns (bool);

  function operatorTransfer(address from, uint256 value) external returns (bool);

  function mint(address account, uint256 amount) external;

  function isLockedForMV(address member) external view returns (uint);

  function addToWhiteList(address _member) external returns (bool);

  function removeFromWhiteList(address _member) external returns (bool);

  function changeOperator(address _newOperator) external returns (bool);

  function lockForMemberVote(address _of, uint _days) external;

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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

import "@openzeppelin/contracts-v4/token/ERC20/IERC20.sol";

interface IStakingPool is IERC20 {

  struct AllocateCapacityParams {
    uint productId;
    uint coverAmount;
    uint rewardsDenominator;
    uint period;
    uint globalCapacityRatio;
    uint globalRewardsRatio;
    uint capacityReductionRatio;
    uint initialPrice;
  }

  function initialize(address _manager, uint _poolId) external;

  function operatorTransferFrom(address from, address to, uint256 amount) external;

  function allocateCapacity(AllocateCapacityParams calldata params) external returns (uint, uint);

  function freeCapacity(
    uint productId,
    uint previousPeriod,
    uint previousStartTime,
    uint previousRewardAmount,
    uint periodReduction,
    uint coveredAmount
  ) external;

  function getAvailableCapacity(uint productId, uint capacityFactor) external view returns (uint);
  function getCapacity(uint productId, uint capacityFactor) external view returns (uint);
  function getUsedCapacity(uint productId) external view returns (uint);
  function getTargetPrice(uint productId) external view returns (uint);
  function getStake(uint productId) external view returns (uint);
  function manager() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import "../interfaces/INXMMaster.sol";

contract LegacyMasterAware {

  INXMMaster public ms;
  address public nxMasterAddress;

  modifier onlyInternal {
    require(ms.isInternal(msg.sender));
    _;
  }

  modifier onlyGovernance {
    require(msg.sender == ms.getLatestAddress("GV"));
    _;
  }


  modifier isMemberAndcheckPause {
    require(ms.isPause() == false && ms.isMember(msg.sender) == true);
    _;
  }

  modifier onlyOwner {
    require(ms.isOwner(msg.sender));
    _;
  }

  modifier checkPause {
    require(ms.isPause() == false);
    _;
  }

  modifier isMember {
    require(ms.isMember(msg.sender), "Not member");
    _;
  }

  /**
   * @dev change master address
   * @param _masterAddress is the new address
   */
  function changeMasterAddress(address _masterAddress) virtual public {
    if (address(ms) != address(0)) {
      require(address(ms) == msg.sender, "Not master");
    }

    ms = INXMMaster(_masterAddress);
    nxMasterAddress = _masterAddress;
  }

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IMaster {
  function getLatestAddress(bytes2 _module) external view returns (address);
}

contract Governed {

  address public masterAddress; // Name of the dApp, needs to be set by contracts inheriting this contract

  /// @dev modifier that allows only the authorized addresses to execute the function
  modifier onlyAuthorizedToGovern() {
    IMaster ms = IMaster(masterAddress);
    require(ms.getLatestAddress("GV") == msg.sender, "Not authorized");
    _;
  }

  /// @dev checks if an address is authorized to govern
  function isAuthorizedToGovern(address _toCheck) public view returns (bool) {
    IMaster ms = IMaster(masterAddress);
    return (ms.getLatestAddress("GV") == _toCheck);
  }

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface INXMMaster {

  function tokenAddress() external view returns (address);

  function owner() external view returns (address);

  function masterInitialized() external view returns (bool);

  function isInternal(address _add) external view returns (bool);

  function isPause() external view returns (bool check);

  function isOwner(address _add) external view returns (bool);

  function isMember(address _add) external view returns (bool);

  function checkIsAuthToGoverned(address _add) external view returns (bool);

  function dAppLocker() external view returns (address _add);

  function getLatestAddress(bytes2 _contractName) external view returns (address payable contractAddress);

  function upgradeMultipleContracts(
    bytes2[] calldata _contractCodes,
    address payable[] calldata newAddresses
  ) external;

  function removeContracts(bytes2[] calldata contractCodesToRemove) external;

  function addNewInternalContracts(
    bytes2[] calldata _contractCodes,
    address payable[] calldata newAddresses,
    uint[] calldata _types
  ) external;

  function updateOwnerParameters(bytes8 code, address payable val) external;
}