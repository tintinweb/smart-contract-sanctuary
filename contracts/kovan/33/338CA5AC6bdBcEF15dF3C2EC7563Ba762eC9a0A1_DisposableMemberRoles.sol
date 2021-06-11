pragma solidity ^0.5.0;

import "../../modules/governance/MemberRoles.sol";
import "../../interfaces/ITokenController.sol";

contract DisposableMemberRoles is MemberRoles {

  function initialize(
    address _owner,
    address _masterAddress,
    address _tokenControllerAddress,
    address[] calldata _initialMembers,
    uint[] calldata _initialMemberTokens,
    address[] calldata _initialABMembers
  ) external {

    require(!constructorCheck);
    constructorCheck = true;
    launched = true;
    launchedOn = now;

    require(
      _initialMembers.length == _initialMemberTokens.length,
      "initial members and member tokens arrays should have the same length"
    );

    tc = ITokenController(_tokenControllerAddress);
    changeMasterAddress(_masterAddress);

    _addInitialMemberRoles(_owner, _owner);

    for (uint i = 0; i < _initialMembers.length; i++) {
      _updateRole(_initialMembers[i], uint(Role.Member), true);
      tc.addToWhitelist(_initialMembers[i]);
      tc.mint(_initialMembers[i], _initialMemberTokens[i]);
    }

    require(_initialABMembers.length <= maxABCount);

    for (uint i = 0; i < _initialABMembers.length; i++) {
      _updateRole(_initialABMembers[i], uint(Role.AdvisoryBoard), true);
    }
  }

}

/* Copyright (C) 2017 GovBlocks.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

import "../claims/ClaimsReward.sol";
import "./external/Governed.sol";
import "../../interfaces/IClaimsReward.sol";
import "../../interfaces/ITokenData.sol";
import "../../interfaces/ITokenController.sol";
import "../../interfaces/IMemberRoles.sol";
import "../../interfaces/ITokenFunctions.sol";
import "../../interfaces/IQuotationData.sol";
import "../../interfaces/IGovernance.sol";

contract MemberRoles is Governed, Iupgradable, IMemberRoles {

  ITokenController public tc;
  ITokenData internal td;
  IQuotationData internal qd;
  IClaimsReward internal cr;
  IGovernance internal gv;
  ITokenFunctions internal tf;
  INXMToken public tk;

  struct MemberRoleDetails {
    uint memberCounter;
    mapping(address => bool) memberActive;
    address[] memberAddress;
    address authorized;
  }

  event MemberRole(uint256 indexed roleId, bytes32 roleName, string roleDescription);

  event switchedMembership(address indexed previousMember, address indexed newMember, uint timeStamp);

  event ClaimPayoutAddressSet(address indexed member, address indexed payoutAddress);

  MemberRoleDetails[] internal memberRoleData;
  bool internal constructorCheck;
  uint public maxABCount;
  bool public launched;
  uint public launchedOn;

  mapping (address => address payable) internal claimPayoutAddress;

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
  external {
    require(msg.sender == address(ms));
    _updateRole(ms.owner(), uint(Role.Owner), false);
    _updateRole(_newOwnerAddress, uint(Role.Owner), true);
  }

  /**
   * @dev is used to add initital advisory board members
   * @param abArray is the list of initial advisory board members
   */
  function addInitialABMembers(address[] calldata abArray) external onlyOwner {

    //Ensure that NXMaster has initialized.
    require(ms.masterInitialized());

    require(maxABCount >=
      SafeMath.add(numberOfMembers(uint(Role.AdvisoryBoard)), abArray.length)
    );
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
    cr = IClaimsReward(ms.getLatestAddress("CR"));
    qd = IQuotationData(ms.getLatestAddress("QD"));
    gv = IGovernance(ms.getLatestAddress("GV"));
    tf = ITokenFunctions(ms.getLatestAddress("TF"));
    tk = INXMToken(ms.tokenAddress());
    tc = ITokenController(ms.getLatestAddress("TC"));
  }

  /**
   * @dev to change the master address
   * @param _masterAddress is the new master address
   */
  function changeMasterAddress(address _masterAddress) public {

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
    launchedOn = now;

  }

  /**
    * @dev Called by user to pay joining membership fee
    */
  function payJoiningFee(address _userAddress) public payable {
    require(_userAddress != address(0));
    require(!ms.isPause(), "Emergency Pause Applied");
    if (msg.sender == address(ms.getLatestAddress("QT"))) {
      require(td.walletAddress() != address(0), "No walletAddress present");
      tc.addToWhitelist(_userAddress);
      _updateRole(_userAddress, uint(Role.Member), true);
      td.walletAddress().transfer(msg.value);
    } else {
      require(!qd.refundEligible(_userAddress));
      require(!ms.isMember(_userAddress));
      require(msg.value == td.joiningFee());
      qd.setRefundEligible(_userAddress, true);
    }
  }

  /**
   * @dev to perform kyc verdict
   * @param _userAddress whose kyc is being performed
   * @param verdict of kyc process
   */
  function kycVerdict(address payable _userAddress, bool verdict) public {

    require(msg.sender == qd.kycAuthAddress());
    require(!ms.isPause());
    require(_userAddress != address(0));
    require(!ms.isMember(_userAddress));
    require(qd.refundEligible(_userAddress));
    if (verdict) {
      qd.setRefundEligible(_userAddress, false);
      uint fee = td.joiningFee();
      tc.addToWhitelist(_userAddress);
      _updateRole(_userAddress, uint(Role.Member), true);
      td.walletAddress().transfer(fee); // solhint-disable-line

    } else {
      qd.setRefundEligible(_userAddress, false);
      _userAddress.transfer(td.joiningFee()); // solhint-disable-line
    }
  }

  /**
   * @dev withdraws membership for msg.sender if currently a member.
   */
  function withdrawMembership() public {

    require(!ms.isPause() && ms.isMember(msg.sender));
    require(tc.totalLockedBalance(msg.sender) == 0); // solhint-disable-line
    require(!tf.isLockedForMemberVote(msg.sender)); // No locked tokens for Member/Governance voting
    require(cr.getAllPendingRewardOfUser(msg.sender) == 0); // No pending reward to be claimed(claim assesment).

    gv.removeDelegation(msg.sender);
    tc.burnFrom(msg.sender, tk.balanceOf(msg.sender));
    _updateRole(msg.sender, uint(Role.Member), false);
    tc.removeFromWhitelist(msg.sender); // need clarification on whitelist

    if (claimPayoutAddress[msg.sender] != address(0)) {
      claimPayoutAddress[msg.sender] = address(0);
      emit ClaimPayoutAddressSet(msg.sender, address(0));
    }
  }

  /**
   * @dev switches membership for msg.sender to the specified address.
   * @param newAddress address of user to forward membership.
   */
  function switchMembership(address newAddress) external {
    _switchMembership(msg.sender, newAddress);
    tk.transferFrom(msg.sender, newAddress, tk.balanceOf(msg.sender));
  }

  function switchMembershipOf(address member, address newAddress) external onlyInternal {
    _switchMembership(member, newAddress);
  }

  /**
   * @dev switches membership for member to the specified address.
   * @param newAddress address of user to forward membership.
   */
  function _switchMembership(address member, address newAddress) internal {

    require(!ms.isPause() && ms.isMember(member) && !ms.isMember(newAddress));
    require(tc.totalLockedBalance(member) == 0); // solhint-disable-line
    require(!tf.isLockedForMemberVote(member)); // No locked tokens for Member/Governance voting
    require(cr.getAllPendingRewardOfUser(member) == 0); // No pending reward to be claimed(claim assesment).

    gv.removeDelegation(member);
    tc.addToWhitelist(newAddress);
    _updateRole(newAddress, uint(Role.Member), true);
    _updateRole(member, uint(Role.Member), false);
    tc.removeFromWhitelist(member);

    address payable previousPayoutAddress = claimPayoutAddress[member];

    if (previousPayoutAddress != address(0)) {

      address payable storedAddress = previousPayoutAddress == newAddress ? address(0) : previousPayoutAddress;

      claimPayoutAddress[member] = address(0);
      claimPayoutAddress[newAddress] = storedAddress;

      // emit event for old address reset
      emit ClaimPayoutAddressSet(member, address(0));

      if (storedAddress != address(0)) {
        // emit event for setting the payout address on the new member address if it's non zero
        emit ClaimPayoutAddressSet(newAddress, storedAddress);
      }
    }

    emit switchedMembership(member, newAddress, now);
  }

  function getClaimPayoutAddress(address payable _member) external view returns (address payable) {
    address payable payoutAddress = claimPayoutAddress[_member];
    return payoutAddress != address(0) ? payoutAddress : _member;
  }

  function setClaimPayoutAddress(address payable _address) external {

    require(!ms.isPause(), "system is paused");
    require(ms.isMember(msg.sender), "sender is not a member");
    require(_address != msg.sender, "should be different than the member address");

    claimPayoutAddress[msg.sender] = _address;
    emit ClaimPayoutAddressSet(msg.sender, _address);
  }

  /// @dev Return number of member roles
  function totalRoles() public view returns (uint256) {//solhint-disable-line
    return memberRoleData.length;
  }

  /// @dev Change Member Address who holds the authority to Add/Delete any member from specific role.
  /// @param _roleId roleId to update its Authorized Address
  /// @param _newAuthorized New authorized address against role id
  function changeAuthorized(uint _roleId, address _newAuthorized) public checkRoleAuthority(_roleId) {//solhint-disable-line
    memberRoleData[_roleId].authorized = _newAuthorized;
  }

  /// @dev Gets the member addresses assigned by a specific role
  /// @param _memberRoleId Member role id
  /// @return roleId Role id
  /// @return allMemberAddress Member addresses of specified role id
  function members(uint _memberRoleId) public view returns (uint, address[] memory memberArray) {//solhint-disable-line
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
  function numberOfMembers(uint _memberRoleId) public view returns (uint) {//solhint-disable-line
    return memberRoleData[_memberRoleId].memberCounter;
  }

  /// @dev Return member address who holds the right to add/remove any member from specific role.
  function authorized(uint _memberRoleId) public view returns (address) {//solhint-disable-line
    return memberRoleData[_memberRoleId].authorized;
  }

  /// @dev Get All role ids array that has been assigned to a member so far.
  function roles(address _memberAddress) public view returns (uint[] memory) {//solhint-disable-line
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
  function checkRole(address _memberAddress, uint _roleId) public view returns (bool) {//solhint-disable-line
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
  function getMemberLengthForAllRoles() public view returns (uint[] memory totalMembers) {//solhint-disable-line
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
      memberRoleData[_roleId].memberCounter = SafeMath.add(memberRoleData[_roleId].memberCounter, 1);
      memberRoleData[_roleId].memberActive[_memberAddress] = true;
      memberRoleData[_roleId].memberAddress.push(_memberAddress);
    } else {
      require(memberRoleData[_roleId].memberActive[_memberAddress]);
      memberRoleData[_roleId].memberCounter = SafeMath.sub(memberRoleData[_roleId].memberCounter, 1);
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
    memberRoleData.push(MemberRoleDetails(0, new address[](0), _authorized));
  }

  /**
   * @dev to check if member is in the given member array
   * @param _memberAddress in concern
   * @param memberArray in concern
   * @return boolean to represent the presence
   */
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

  function memberAtIndex(uint _memberRoleId, uint index) external view returns (address, bool) {
    address memberAddress = memberRoleData[_memberRoleId].memberAddress[index];
    return (memberAddress, memberRoleData[_memberRoleId].memberActive[memberAddress]);
  }

  function membersLength(uint _memberRoleId) external view returns (uint) {
    return memberRoleData[_memberRoleId].memberAddress.length;
  }
}

// SPDX-License-Identifier: GPL-3.0

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface ITokenController {

  function coverInfo(uint id) external view returns (uint16 claimCount, bool hasOpenClaim, bool hasAcceptedClaim);

  function claimSubmissionGracePeriod() external view returns (uint);

  function withdrawCoverNote(
    address _of,
    uint[] calldata _coverIds,
    uint[] calldata _indexes
  ) external;

  function markCoverClaimOpen(uint coverId) external;

  function markCoverClaimClosed(uint coverId, bool isAccepted) external;

  function changeOperator(address _newOperator) external;

  function operatorTransfer(address _from, address _to, uint _value) external returns (bool);

  function lockClaimAssessmentTokens(uint256 _amount, uint256 _time) external;

  function lockOf(address _of, bytes32 _reason, uint256 _amount, uint256 _time) external returns (bool);

  function mintCoverNote(
    address _of,
    bytes32 _reason,
    uint256 _amount,
    uint256 _time
  ) external;

  function extendClaimAssessmentLock(uint256 _time) external;

  function extendLockOf(address _of, bytes32 _reason, uint256 _time) external returns (bool);

  function increaseClaimAssessmentLock(uint256 _amount) external;

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
}

/* Copyright (C) 2020 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

//Claims Reward Contract contains the functions for calculating number of tokens
// that will get rewarded, unlocked or burned depending upon the status of claim.

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../governance/Governance.sol";
import "../../abstract/Iupgradable.sol";

import "../../interfaces/IPooledStaking.sol";
import "../../interfaces/IMCR.sol";
import "../../interfaces/IClaimsReward.sol";
import "../../interfaces/IClaimsData.sol";
import "../../interfaces/IClaims.sol";
import "../../interfaces/ITokenData.sol";
import "../../interfaces/IQuotationData.sol";
import "../../interfaces/ITokenController.sol";
import "../../interfaces/IPool.sol";
import "../../interfaces/IMemberRoles.sol";
import "../../abstract/INXMToken.sol";


contract ClaimsReward is Iupgradable, IClaimsReward {
  using SafeMath for uint;

  INXMToken internal tk;
  ITokenController internal tc;
  ITokenData internal td;
  IQuotationData internal qd;
  IClaims internal c1;
  IClaimsData internal cd;
  IPool internal pool;
  Governance internal gv;
  IPooledStaking internal pooledStaking;
  IMemberRoles internal memberRoles;
  IMCR public mcr;

  // assigned in constructor
  address public DAI;

  // constants
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  uint private constant DECIMAL1E18 = uint(10) ** 18;

  constructor (address masterAddress, address _daiAddress) public {
    changeMasterAddress(masterAddress);
    DAI = _daiAddress;
  }

  function changeDependentContractAddress() public onlyInternal {
    c1 = IClaims(ms.getLatestAddress("CL"));
    cd = IClaimsData(ms.getLatestAddress("CD"));
    tk = INXMToken(ms.tokenAddress());
    tc = ITokenController(ms.getLatestAddress("TC"));
    td = ITokenData(ms.getLatestAddress("TD"));
    qd = IQuotationData(ms.getLatestAddress("QD"));
    gv = Governance(ms.getLatestAddress("GV"));
    pooledStaking = IPooledStaking(ms.getLatestAddress("PS"));
    memberRoles = IMemberRoles(ms.getLatestAddress("MR"));
    pool = IPool(ms.getLatestAddress("P1"));
    mcr = IMCR(ms.getLatestAddress("MC"));
  }

  /// @dev Decides the next course of action for a given claim.
  function changeClaimStatus(uint claimid) public checkPause onlyInternal {

    (, uint coverid) = cd.getClaimCoverId(claimid);
    (, uint status) = cd.getClaimStatusNumber(claimid);

    // when current status is "Pending-Claim Assessor Vote"
    if (status == 0) {
      _changeClaimStatusCA(claimid, coverid, status);
    } else if (status >= 1 && status <= 5) {
      _changeClaimStatusMV(claimid, coverid, status);
    } else if (status == 12) {// when current status is "Claim Accepted Payout Pending"

      bool payoutSucceeded = attemptClaimPayout(coverid);

      if (payoutSucceeded) {
        c1.setClaimStatus(claimid, 14);
      } else {
        c1.setClaimStatus(claimid, 12);
      }
    }
  }

  function getCurrencyAssetAddress(bytes4 currency) public view returns (address) {

    if (currency == "ETH") {
      return ETH;
    }

    if (currency == "DAI") {
      return DAI;
    }

    revert("ClaimsReward: unknown asset");
  }

  function attemptClaimPayout(uint coverId) internal returns (bool success) {

    uint sumAssured = qd.getCoverSumAssured(coverId);
    // TODO: when adding new cover currencies, fetch the correct decimals for this multiplication
    uint sumAssuredWei = sumAssured.mul(1e18);

    // get asset address
    bytes4 coverCurrency = qd.getCurrencyOfCover(coverId);
    address asset = getCurrencyAssetAddress(coverCurrency);

    // get payout address
    address payable coverHolder = qd.getCoverMemberAddress(coverId);
    address payable payoutAddress = memberRoles.getClaimPayoutAddress(coverHolder);

    // execute the payout
    bool payoutSucceeded = pool.sendClaimPayout(asset, payoutAddress, sumAssuredWei);

    if (payoutSucceeded) {

      // burn staked tokens
      (, address scAddress) = qd.getscAddressOfCover(coverId);
      uint tokenPrice = pool.getTokenPrice(asset);

      // note: for new assets "18" needs to be replaced with target asset decimals
      uint burnNXMAmount = sumAssuredWei.mul(1e18).div(tokenPrice);
      pooledStaking.pushBurn(scAddress, burnNXMAmount);

      // adjust total sum assured
      (, address coverContract) = qd.getscAddressOfCover(coverId);
      qd.subFromTotalSumAssured(coverCurrency, sumAssured);
      qd.subFromTotalSumAssuredSC(coverContract, coverCurrency, sumAssured);

      // update MCR since total sum assured and MCR% change
      mcr.updateMCRInternal(pool.getPoolValueInEth(), true);
      return true;
    }

    return false;
  }

  /// @dev Amount of tokens to be rewarded to a user for a particular vote id.
  /// @param check 1 -> CA vote, else member vote
  /// @param voteid vote id for which reward has to be Calculated
  /// @param flag if 1 calculate even if claimed,else don't calculate if already claimed
  /// @return tokenCalculated reward to be given for vote id
  /// @return lastClaimedCheck true if final verdict is still pending for that voteid
  /// @return tokens number of tokens locked under that voteid
  /// @return perc percentage of reward to be given.
  function getRewardToBeGiven(
    uint check,
    uint voteid,
    uint flag
  )
  public
  view
  returns (
    uint tokenCalculated,
    bool lastClaimedCheck,
    uint tokens,
    uint perc
  )

  {
    uint claimId;
    int8 verdict;
    bool claimed;
    uint tokensToBeDist;
    uint totalTokens;
    (tokens, claimId, verdict, claimed) = cd.getVoteDetails(voteid);
    lastClaimedCheck = false;
    int8 claimVerdict = cd.getFinalVerdict(claimId);
    if (claimVerdict == 0) {
      lastClaimedCheck = true;
    }

    if (claimVerdict == verdict && (claimed == false || flag == 1)) {

      if (check == 1) {
        (perc, , tokensToBeDist) = cd.getClaimRewardDetail(claimId);
      } else {
        (, perc, tokensToBeDist) = cd.getClaimRewardDetail(claimId);
      }

      if (perc > 0) {
        if (check == 1) {
          if (verdict == 1) {
            (, totalTokens,) = cd.getClaimsTokenCA(claimId);
          } else {
            (,, totalTokens) = cd.getClaimsTokenCA(claimId);
          }
        } else {
          if (verdict == 1) {
            (, totalTokens,) = cd.getClaimsTokenMV(claimId);
          } else {
            (,, totalTokens) = cd.getClaimsTokenMV(claimId);
          }
        }
        tokenCalculated = (perc.mul(tokens).mul(tokensToBeDist)).div(totalTokens.mul(100));


      }
    }
  }

  /// @dev Transfers all tokens held by contract to a new contract in case of upgrade.
  function upgrade(address _newAdd) public onlyInternal {
    uint amount = tk.balanceOf(address(this));
    if (amount > 0) {
      require(tk.transfer(_newAdd, amount));
    }

  }

  /// @dev Total reward in token due for claim by a user.
  /// @return total total number of tokens
  function getRewardToBeDistributedByUser(address _add) public view returns (uint total) {
    uint lengthVote = cd.getVoteAddressCALength(_add);
    uint lastIndexCA;
    uint lastIndexMV;
    uint tokenForVoteId;
    uint voteId;
    (lastIndexCA, lastIndexMV) = cd.getRewardDistributedIndex(_add);

    for (uint i = lastIndexCA; i < lengthVote; i++) {
      voteId = cd.getVoteAddressCA(_add, i);
      (tokenForVoteId,,,) = getRewardToBeGiven(1, voteId, 0);
      total = total.add(tokenForVoteId);
    }

    lengthVote = cd.getVoteAddressMemberLength(_add);

    for (uint j = lastIndexMV; j < lengthVote; j++) {
      voteId = cd.getVoteAddressMember(_add, j);
      (tokenForVoteId,,,) = getRewardToBeGiven(0, voteId, 0);
      total = total.add(tokenForVoteId);
    }
    return (total);
  }

  /// @dev Gets reward amount and claiming status for a given claim id.
  /// @return reward amount of tokens to user.
  /// @return claimed true if already claimed false if yet to be claimed.
  function getRewardAndClaimedStatus(uint check, uint claimId) public view returns (uint reward, bool claimed) {
    uint voteId;
    uint claimid;
    uint lengthVote;

    if (check == 1) {
      lengthVote = cd.getVoteAddressCALength(msg.sender);
      for (uint i = 0; i < lengthVote; i++) {
        voteId = cd.getVoteAddressCA(msg.sender, i);
        (, claimid, , claimed) = cd.getVoteDetails(voteId);
        if (claimid == claimId) {break;}
      }
    } else {
      lengthVote = cd.getVoteAddressMemberLength(msg.sender);
      for (uint j = 0; j < lengthVote; j++) {
        voteId = cd.getVoteAddressMember(msg.sender, j);
        (, claimid, , claimed) = cd.getVoteDetails(voteId);
        if (claimid == claimId) {break;}
      }
    }
    (reward,,,) = getRewardToBeGiven(check, voteId, 1);

  }

  /**
   * @dev Function used to claim all pending rewards : Claims Assessment + Risk Assessment + Governance
   * Claim assesment, Risk assesment, Governance rewards
   */
  function claimAllPendingReward(uint records) public isMemberAndcheckPause {
    _claimRewardToBeDistributed(records);
    pooledStaking.withdrawReward(msg.sender);
    uint governanceRewards = gv.claimReward(msg.sender, records);
    if (governanceRewards > 0) {
      require(tk.transfer(msg.sender, governanceRewards));
    }
  }

  /**
   * @dev Function used to get pending rewards of a particular user address.
   * @param _add user address.
   * @return total reward amount of the user
   */
  function getAllPendingRewardOfUser(address _add) public view returns (uint) {
    uint caReward = getRewardToBeDistributedByUser(_add);
    uint pooledStakingReward = pooledStaking.stakerReward(_add);
    uint governanceReward = gv.getPendingReward(_add);
    return caReward.add(pooledStakingReward).add(governanceReward);
  }

  /// @dev Rewards/Punishes users who  participated in Claims assessment.
  //    Unlocking and burning of the tokens will also depend upon the status of claim.
  /// @param claimid Claim Id.
  function _rewardAgainstClaim(uint claimid, uint coverid, uint status) internal {

    uint premiumNXM = qd.getCoverPremiumNXM(coverid);
    uint distributableTokens = premiumNXM.mul(cd.claimRewardPerc()).div(100); // 20% of premium

    uint percCA;
    uint percMV;

    (percCA, percMV) = cd.getRewardStatus(status);
    cd.setClaimRewardDetail(claimid, percCA, percMV, distributableTokens);

    if (percCA > 0 || percMV > 0) {
      tc.mint(address(this), distributableTokens);
    }

    // denied
    if (status == 6 || status == 9 || status == 11) {

      cd.changeFinalVerdict(claimid, -1);
      tc.markCoverClaimClosed(coverid, false);
      _burnCoverNoteDeposit(coverid);

    // accepted
    } else if (status == 7 || status == 8 || status == 10) {

      cd.changeFinalVerdict(claimid, 1);
      tc.markCoverClaimClosed(coverid, true);
      _unlockCoverNote(coverid);

      bool payoutSucceeded = attemptClaimPayout(coverid);

      // 12 = payout pending, 14 = payout succeeded
      uint nextStatus = payoutSucceeded ? 14 : 12;
      c1.setClaimStatus(claimid, nextStatus);
    }
  }

  function _burnCoverNoteDeposit(uint coverId) internal {

    address _of = qd.getCoverMemberAddress(coverId);
    bytes32 reason = keccak256(abi.encodePacked("CN", _of, coverId));
    uint lockedAmount = tc.tokensLocked(_of, reason);

    (uint amount,) = td.depositedCN(coverId);
    amount = amount.div(2);

    // limit burn amount to actual amount locked
    uint burnAmount = lockedAmount < amount ? lockedAmount : amount;

    if (burnAmount != 0) {
      tc.burnLockedTokens(_of, reason, amount);
    }
  }

  function _unlockCoverNote(uint coverId) internal {

    address coverHolder = qd.getCoverMemberAddress(coverId);
    bytes32 reason = keccak256(abi.encodePacked("CN", coverHolder, coverId));
    uint lockedCN = tc.tokensLocked(coverHolder, reason);

    if (lockedCN != 0) {
      tc.releaseLockedTokens(coverHolder, reason, lockedCN);
    }
  }

  /// @dev Computes the result of Claim Assessors Voting for a given claim id.
  function _changeClaimStatusCA(uint claimid, uint coverid, uint status) internal {
    // Check if voting should be closed or not
    if (c1.checkVoteClosing(claimid) == 1) {
      uint caTokens = c1.getCATokens(claimid, 0); // converted in cover currency.
      uint accept;
      uint deny;
      uint acceptAndDeny;
      bool rewardOrPunish;
      uint sumAssured;
      (, accept) = cd.getClaimVote(claimid, 1);
      (, deny) = cd.getClaimVote(claimid, - 1);
      acceptAndDeny = accept.add(deny);
      accept = accept.mul(100);
      deny = deny.mul(100);

      if (caTokens == 0) {
        status = 3;
      } else {
        sumAssured = qd.getCoverSumAssured(coverid).mul(DECIMAL1E18);
        // Min threshold reached tokens used for voting > 5* sum assured
        if (caTokens > sumAssured.mul(5)) {

          if (accept.div(acceptAndDeny) > 70) {
            status = 7;
            qd.changeCoverStatusNo(coverid, uint8(IQuotationData.CoverStatus.ClaimAccepted));
            rewardOrPunish = true;
          } else if (deny.div(acceptAndDeny) > 70) {
            status = 6;
            qd.changeCoverStatusNo(coverid, uint8(IQuotationData.CoverStatus.ClaimDenied));
            rewardOrPunish = true;
          } else if (accept.div(acceptAndDeny) > deny.div(acceptAndDeny)) {
            status = 4;
          } else {
            status = 5;
          }

        } else {

          if (accept.div(acceptAndDeny) > deny.div(acceptAndDeny)) {
            status = 2;
          } else {
            status = 3;
          }
        }
      }

      c1.setClaimStatus(claimid, status);

      if (rewardOrPunish) {
        _rewardAgainstClaim(claimid, coverid, status);
      }
    }
  }

  /// @dev Computes the result of Member Voting for a given claim id.
  function _changeClaimStatusMV(uint claimid, uint coverid, uint status) internal {

    // Check if voting should be closed or not
    if (c1.checkVoteClosing(claimid) == 1) {
      uint8 coverStatus;
      uint statusOrig = status;
      uint mvTokens = c1.getCATokens(claimid, 1); // converted in cover currency.

      // If tokens used for acceptance >50%, claim is accepted
      uint sumAssured = qd.getCoverSumAssured(coverid).mul(DECIMAL1E18);
      uint thresholdUnreached = 0;
      // Minimum threshold for member voting is reached only when
      // value of tokens used for voting > 5* sum assured of claim id
      if (mvTokens < sumAssured.mul(5)) {
        thresholdUnreached = 1;
      }

      uint accept;
      (, accept) = cd.getClaimMVote(claimid, 1);
      uint deny;
      (, deny) = cd.getClaimMVote(claimid, - 1);

      if (accept.add(deny) > 0) {
        if (accept.mul(100).div(accept.add(deny)) >= 50 && statusOrig > 1 &&
        statusOrig <= 5 && thresholdUnreached == 0) {
          status = 8;
          coverStatus = uint8(IQuotationData.CoverStatus.ClaimAccepted);
        } else if (deny.mul(100).div(accept.add(deny)) >= 50 && statusOrig > 1 &&
        statusOrig <= 5 && thresholdUnreached == 0) {
          status = 9;
          coverStatus = uint8(IQuotationData.CoverStatus.ClaimDenied);
        }
      }

      if (thresholdUnreached == 1 && (statusOrig == 2 || statusOrig == 4)) {
        status = 10;
        coverStatus = uint8(IQuotationData.CoverStatus.ClaimAccepted);
      } else if (thresholdUnreached == 1 && (statusOrig == 5 || statusOrig == 3 || statusOrig == 1)) {
        status = 11;
        coverStatus = uint8(IQuotationData.CoverStatus.ClaimDenied);
      }

      c1.setClaimStatus(claimid, status);
      qd.changeCoverStatusNo(coverid, uint8(coverStatus));
      // Reward/Punish Claim Assessors and Members who participated in Claims assessment
      _rewardAgainstClaim(claimid, coverid, status);
    }
  }

  /// @dev Allows a user to claim all pending  Claims assessment rewards.
  function _claimRewardToBeDistributed(uint _records) internal {
    uint lengthVote = cd.getVoteAddressCALength(msg.sender);
    uint voteid;
    uint lastIndex;
    (lastIndex,) = cd.getRewardDistributedIndex(msg.sender);
    uint total = 0;
    uint tokenForVoteId = 0;
    bool lastClaimedCheck;
    uint _days = td.lockCADays();
    bool claimed;
    uint counter = 0;
    uint claimId;
    uint perc;
    uint i;
    uint lastClaimed = lengthVote;

    for (i = lastIndex; i < lengthVote && counter < _records; i++) {
      voteid = cd.getVoteAddressCA(msg.sender, i);
      (tokenForVoteId, lastClaimedCheck, , perc) = getRewardToBeGiven(1, voteid, 0);
      if (lastClaimed == lengthVote && lastClaimedCheck == true) {
        lastClaimed = i;
      }
      (, claimId, , claimed) = cd.getVoteDetails(voteid);

      if (perc > 0 && !claimed) {
        counter++;
        cd.setRewardClaimed(voteid, true);
      } else if (perc == 0 && cd.getFinalVerdict(claimId) != 0 && !claimed) {
        (perc,,) = cd.getClaimRewardDetail(claimId);
        if (perc == 0) {
          counter++;
        }
        cd.setRewardClaimed(voteid, true);
      }
      if (tokenForVoteId > 0) {
        total = tokenForVoteId.add(total);
      }
    }
    if (lastClaimed == lengthVote) {
      cd.setRewardDistributedIndexCA(msg.sender, i);
    }
    else {
      cd.setRewardDistributedIndexCA(msg.sender, lastClaimed);
    }
    lengthVote = cd.getVoteAddressMemberLength(msg.sender);
    lastClaimed = lengthVote;
    _days = _days.mul(counter);
    if (tc.tokensLockedAtTime(msg.sender, "CLA", now) > 0) {
      tc.reduceLock(msg.sender, "CLA", _days);
    }
    (, lastIndex) = cd.getRewardDistributedIndex(msg.sender);
    lastClaimed = lengthVote;
    counter = 0;
    for (i = lastIndex; i < lengthVote && counter < _records; i++) {
      voteid = cd.getVoteAddressMember(msg.sender, i);
      (tokenForVoteId, lastClaimedCheck,,) = getRewardToBeGiven(0, voteid, 0);
      if (lastClaimed == lengthVote && lastClaimedCheck == true) {
        lastClaimed = i;
      }
      (, claimId, , claimed) = cd.getVoteDetails(voteid);
      if (claimed == false && cd.getFinalVerdict(claimId) != 0) {
        cd.setRewardClaimed(voteid, true);
        counter++;
      }
      if (tokenForVoteId > 0) {
        total = tokenForVoteId.add(total);
      }
    }
    if (total > 0) {
      require(tk.transfer(msg.sender, total));
    }
    if (lastClaimed == lengthVote) {
      cd.setRewardDistributedIndexMV(msg.sender, i);
    }
    else {
      cd.setRewardDistributedIndexMV(msg.sender, lastClaimed);
    }
  }
}

/* Copyright (C) 2017 GovBlocks.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;


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

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface IClaimsReward {

  /// @dev Decides the next course of action for a given claim.
  function changeClaimStatus(uint claimid) external;

  function getCurrencyAssetAddress(bytes4 currency) external view returns (address);

  function getRewardToBeGiven(
    uint check,
    uint voteid,
    uint flag
  )
  external
  view
  returns (
    uint tokenCalculated,
    bool lastClaimedCheck,
    uint tokens,
    uint perc
  );

  function upgrade(address _newAdd) external;

  function getRewardToBeDistributedByUser(address _add) external view returns (uint total);

  function getRewardAndClaimedStatus(uint check, uint claimId) external view returns (uint reward, bool claimed);


  function claimAllPendingReward(uint records) external;

  function getAllPendingRewardOfUser(address _add) external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

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

// SPDX-License-Identifier: GPL-3.0

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface IMemberRoles {

  enum Role {UnAssigned, AdvisoryBoard, Member, Owner}

  function payJoiningFee(address _userAddress) external payable;

  function switchMembership(address _newAddress) external;

  function switchMembershipOf(address member, address _newAddress) external;

  function swapOwner(address _newOwnerAddress) external;

  function kycVerdict(address payable _userAddress, bool verdict) external;

  function getClaimPayoutAddress(address payable _member) external view returns (address payable);

  function setClaimPayoutAddress(address payable _address) external;

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
}

// SPDX-License-Identifier: GPL-3.0

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface ITokenFunctions {

  function getUserAllLockedCNTokens(address _of) external view returns (uint);

  function changeDependentContractAddress() external;

  function burnCAToken(uint claimid, uint _value, address _of) external;

  function isLockedForMemberVote(address _of) external view returns (bool);
}

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

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

/* Copyright (C) 2017 GovBlocks.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

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

}

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

// /* Copyright (C) 2017 GovBlocks.io

//   This program is free software: you can redistribute it and/or modify
//     it under the terms of the GNU General Public License as published by
//     the Free Software Foundation, either version 3 of the License, or
//     (at your option) any later version.

//   This program is distributed in the hope that it will be useful,
//     but WITHOUT ANY WARRANTY; without even the implied warranty of
//     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//     GNU General Public License for more details.

//   You should have received a copy of the GNU General Public License
//     along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../abstract/Iupgradable.sol";

import "../../interfaces/IMemberRoles.sol";
import "../../interfaces/ITokenController.sol";
import "../../interfaces/IGovernance.sol";
import "../../interfaces/IProposalCategory.sol";

contract Governance is IGovernance, Iupgradable {

  using SafeMath for uint;

  enum ProposalStatus {
    Draft,
    AwaitingSolution,
    VotingStarted,
    Accepted,
    Rejected,
    Majority_Not_Reached_But_Accepted,
    Denied
  }

  struct ProposalData {
    uint propStatus;
    uint finalVerdict;
    uint category;
    uint commonIncentive;
    uint dateUpd;
    address owner;
  }

  struct ProposalVote {
    address voter;
    uint proposalId;
    uint dateAdd;
  }

  struct VoteTally {
    mapping(uint => uint) memberVoteValue;
    mapping(uint => uint) abVoteValue;
    uint voters;
  }

  struct DelegateVote {
    address follower;
    address leader;
    uint lastUpd;
  }

  ProposalVote[] internal allVotes;
  DelegateVote[] public allDelegation;

  mapping(uint => ProposalData) internal allProposalData;
  mapping(uint => bytes[]) internal allProposalSolutions;
  mapping(address => uint[]) internal allVotesByMember;
  mapping(uint => mapping(address => bool)) public rewardClaimed;
  mapping(address => mapping(uint => uint)) public memberProposalVote;
  mapping(address => uint) public followerDelegation;
  mapping(address => uint) internal followerCount;
  mapping(address => uint[]) internal leaderDelegation;
  mapping(uint => VoteTally) public proposalVoteTally;
  mapping(address => bool) public isOpenForDelegation;
  mapping(address => uint) public lastRewardClaimed;

  bool internal constructorCheck;
  uint public tokenHoldingTime;
  uint internal roleIdAllowedToCatgorize;
  uint internal maxVoteWeigthPer;
  uint internal specialResolutionMajPerc;
  uint internal maxFollowers;
  uint internal totalProposals;
  uint internal maxDraftTime;

  IMemberRoles internal memberRole;
  IProposalCategory internal proposalCategory;
  ITokenController internal tokenInstance;

  mapping(uint => uint) public proposalActionStatus;
  mapping(uint => uint) internal proposalExecutionTime;
  mapping(uint => mapping(address => bool)) public proposalRejectedByAB;
  mapping(uint => uint) internal actionRejectedCount;

  bool internal actionParamsInitialised;
  uint internal actionWaitingTime;
  uint constant internal AB_MAJ_TO_REJECT_ACTION = 3;

  enum ActionStatus {
    Pending,
    Accepted,
    Rejected,
    Executed,
    NoAction
  }

  /**
  * @dev Called whenever an action execution is failed.
  */
  event ActionFailed (
    uint256 proposalId
  );

  /**
  * @dev Called whenever an AB member rejects the action execution.
  */
  event ActionRejected (
    uint256 indexed proposalId,
    address rejectedBy
  );

  /**
  * @dev Checks if msg.sender is proposal owner
  */
  modifier onlyProposalOwner(uint _proposalId) {
    require(msg.sender == allProposalData[_proposalId].owner, "Not allowed");
    _;
  }

  /**
  * @dev Checks if proposal is opened for voting
  */
  modifier voteNotStarted(uint _proposalId) {
    require(allProposalData[_proposalId].propStatus < uint(ProposalStatus.VotingStarted));
    _;
  }

  /**
  * @dev Checks if msg.sender is allowed to create proposal under given category
  */
  modifier isAllowed(uint _categoryId) {
    require(allowedToCreateProposal(_categoryId), "Not allowed");
    _;
  }

  /**
  * @dev Checks if msg.sender is allowed categorize proposal under given category
  */
  modifier isAllowedToCategorize() {
    require(memberRole.checkRole(msg.sender, roleIdAllowedToCatgorize), "Not allowed");
    _;
  }

  /**
  * @dev Checks if msg.sender had any pending rewards to be claimed
  */
  modifier checkPendingRewards {
    require(getPendingReward(msg.sender) == 0, "Claim reward");
    _;
  }

  /**
  * @dev Event emitted whenever a proposal is categorized
  */
  event ProposalCategorized(
    uint indexed proposalId,
    address indexed categorizedBy,
    uint categoryId
  );

  /**
   * @dev Removes delegation of an address.
   * @param _add address to undelegate.
   */
  function removeDelegation(address _add) external onlyInternal {
    _unDelegate(_add);
  }

  /**
  * @dev Creates a new proposal
  * @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
  * @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
  */
  function createProposal(
    string calldata _proposalTitle,
    string calldata _proposalSD,
    string calldata _proposalDescHash,
    uint _categoryId
  )
  external isAllowed(_categoryId)
  {
    require(ms.isMember(msg.sender), "Not Member");

    _createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _categoryId);
  }

  /**
  * @dev Edits the details of an existing proposal
  * @param _proposalId Proposal id that details needs to be updated
  * @param _proposalDescHash Proposal description hash having long and short description of proposal.
  */
  function updateProposal(
    uint _proposalId,
    string calldata _proposalTitle,
    string calldata _proposalSD,
    string calldata _proposalDescHash
  )
  external onlyProposalOwner(_proposalId)
  {
    require(
      allProposalSolutions[_proposalId].length < 2,
      "Not allowed"
    );
    allProposalData[_proposalId].propStatus = uint(ProposalStatus.Draft);
    allProposalData[_proposalId].category = 0;
    allProposalData[_proposalId].commonIncentive = 0;
    emit Proposal(
      allProposalData[_proposalId].owner,
      _proposalId,
      now,
      _proposalTitle,
      _proposalSD,
      _proposalDescHash
    );
  }

  /**
  * @dev Categorizes proposal to proceed further. Categories shows the proposal objective.
  */
  function categorizeProposal(
    uint _proposalId,
    uint _categoryId,
    uint _incentive
  )
  external
  voteNotStarted(_proposalId) isAllowedToCategorize
  {
    _categorizeProposal(_proposalId, _categoryId, _incentive);
  }

  /**
  * @dev Submit proposal with solution
  * @param _proposalId Proposal id
  * @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
  */
  function submitProposalWithSolution(
    uint _proposalId,
    string calldata _solutionHash,
    bytes calldata _action
  )
  external
  onlyProposalOwner(_proposalId)
  {

    require(allProposalData[_proposalId].propStatus == uint(ProposalStatus.AwaitingSolution));

    _proposalSubmission(_proposalId, _solutionHash, _action);
  }

  /**
  * @dev Creates a new proposal with solution
  * @param _proposalDescHash Proposal description hash through IPFS having Short and long description of proposal
  * @param _categoryId This id tells under which the proposal is categorized i.e. Proposal's Objective
  * @param _solutionHash Solution hash contains  parameters, values and description needed according to proposal
  */
  function createProposalwithSolution(
    string calldata _proposalTitle,
    string calldata _proposalSD,
    string calldata _proposalDescHash,
    uint _categoryId,
    string calldata _solutionHash,
    bytes calldata _action
  )
  external isAllowed(_categoryId)
  {


    uint proposalId = totalProposals;

    _createProposal(_proposalTitle, _proposalSD, _proposalDescHash, _categoryId);

    require(_categoryId > 0);

    _proposalSubmission(
      proposalId,
      _solutionHash,
      _action
    );
  }

  /**
   * @dev Submit a vote on the proposal.
   * @param _proposalId to vote upon.
   * @param _solutionChosen is the chosen vote.
   */
  function submitVote(uint _proposalId, uint _solutionChosen) external {

    require(allProposalData[_proposalId].propStatus ==
      uint(Governance.ProposalStatus.VotingStarted), "Not allowed");

    require(_solutionChosen < allProposalSolutions[_proposalId].length);


    _submitVote(_proposalId, _solutionChosen);
  }

  /**
   * @dev Closes the proposal.
   * @param _proposalId of proposal to be closed.
   */
  function closeProposal(uint _proposalId) external {
    uint category = allProposalData[_proposalId].category;


    uint _memberRole;
    if (allProposalData[_proposalId].dateUpd.add(maxDraftTime) <= now &&
      allProposalData[_proposalId].propStatus < uint(ProposalStatus.VotingStarted)) {
      _updateProposalStatus(_proposalId, uint(ProposalStatus.Denied));
    } else {
      require(canCloseProposal(_proposalId) == 1);
      (, _memberRole,,,,,) = proposalCategory.category(allProposalData[_proposalId].category);
      if (_memberRole == uint(IMemberRoles.Role.AdvisoryBoard)) {
        _closeAdvisoryBoardVote(_proposalId, category);
      } else {
        _closeMemberVote(_proposalId, category);
      }
    }

  }

  /**
   * @dev Claims reward for member.
   * @param _memberAddress to claim reward of.
   * @param _maxRecords maximum number of records to claim reward for.
   _proposals list of proposals of which reward will be claimed.
   * @return amount of pending reward.
   */
  function claimReward(address _memberAddress, uint _maxRecords)
  external returns (uint pendingDAppReward)
  {

    uint voteId;
    address leader;
    uint lastUpd;

    require(msg.sender == ms.getLatestAddress("CR"));

    uint delegationId = followerDelegation[_memberAddress];
    DelegateVote memory delegationData = allDelegation[delegationId];
    if (delegationId > 0 && delegationData.leader != address(0)) {
      leader = delegationData.leader;
      lastUpd = delegationData.lastUpd;
    } else
      leader = _memberAddress;

    uint proposalId;
    uint totalVotes = allVotesByMember[leader].length;
    uint lastClaimed = totalVotes;
    uint j;
    uint i;
    for (i = lastRewardClaimed[_memberAddress]; i < totalVotes && j < _maxRecords; i++) {
      voteId = allVotesByMember[leader][i];
      proposalId = allVotes[voteId].proposalId;
      if (proposalVoteTally[proposalId].voters > 0 && (allVotes[voteId].dateAdd > (
      lastUpd.add(tokenHoldingTime)) || leader == _memberAddress)) {
        if (allProposalData[proposalId].propStatus > uint(ProposalStatus.VotingStarted)) {
          if (!rewardClaimed[voteId][_memberAddress]) {
            pendingDAppReward = pendingDAppReward.add(
              allProposalData[proposalId].commonIncentive.div(
                proposalVoteTally[proposalId].voters
              )
            );
            rewardClaimed[voteId][_memberAddress] = true;
            j++;
          }
        } else {
          if (lastClaimed == totalVotes) {
            lastClaimed = i;
          }
        }
      }
    }

    if (lastClaimed == totalVotes) {
      lastRewardClaimed[_memberAddress] = i;
    } else {
      lastRewardClaimed[_memberAddress] = lastClaimed;
    }

    if (j > 0) {
      emit RewardClaimed(
        _memberAddress,
        pendingDAppReward
      );
    }
  }

  /**
   * @dev Sets delegation acceptance status of individual user
   * @param _status delegation acceptance status
   */
  function setDelegationStatus(bool _status) external isMemberAndcheckPause checkPendingRewards {
    isOpenForDelegation[msg.sender] = _status;
  }

  /**
   * @dev Delegates vote to an address.
   * @param _add is the address to delegate vote to.
   */
  function delegateVote(address _add) external isMemberAndcheckPause checkPendingRewards {

    require(ms.masterInitialized());

    require(allDelegation[followerDelegation[_add]].leader == address(0));

    if (followerDelegation[msg.sender] > 0) {
      require((allDelegation[followerDelegation[msg.sender]].lastUpd).add(tokenHoldingTime) < now);
    }

    require(!alreadyDelegated(msg.sender));
    require(!memberRole.checkRole(msg.sender, uint(IMemberRoles.Role.Owner)));
    require(!memberRole.checkRole(msg.sender, uint(IMemberRoles.Role.AdvisoryBoard)));


    require(followerCount[_add] < maxFollowers);

    if (allVotesByMember[msg.sender].length > 0) {
      require((allVotes[allVotesByMember[msg.sender][allVotesByMember[msg.sender].length - 1]].dateAdd).add(tokenHoldingTime)
        < now);
    }

    require(ms.isMember(_add));

    require(isOpenForDelegation[_add]);

    allDelegation.push(DelegateVote(msg.sender, _add, now));
    followerDelegation[msg.sender] = allDelegation.length - 1;
    leaderDelegation[_add].push(allDelegation.length - 1);
    followerCount[_add]++;
    lastRewardClaimed[msg.sender] = allVotesByMember[_add].length;
  }

  /**
   * @dev Undelegates the sender
   */
  function unDelegate() external isMemberAndcheckPause checkPendingRewards {
    _unDelegate(msg.sender);
  }

  /**
   * @dev Triggers action of accepted proposal after waiting time is finished
   */
  function triggerAction(uint _proposalId) external {
    require(proposalActionStatus[_proposalId] == uint(ActionStatus.Accepted) && proposalExecutionTime[_proposalId] <= now, "Cannot trigger");
    _triggerAction(_proposalId, allProposalData[_proposalId].category);
  }

  /**
   * @dev Provides option to Advisory board member to reject proposal action execution within actionWaitingTime, if found suspicious
   */
  function rejectAction(uint _proposalId) external {
    require(memberRole.checkRole(msg.sender, uint(IMemberRoles.Role.AdvisoryBoard)) && proposalExecutionTime[_proposalId] > now);

    require(proposalActionStatus[_proposalId] == uint(ActionStatus.Accepted));

    require(!proposalRejectedByAB[_proposalId][msg.sender]);

    require(
      keccak256(proposalCategory.categoryActionHashes(allProposalData[_proposalId].category))
      != keccak256(abi.encodeWithSignature("swapABMember(address,address)"))
    );

    proposalRejectedByAB[_proposalId][msg.sender] = true;
    actionRejectedCount[_proposalId]++;
    emit ActionRejected(_proposalId, msg.sender);
    if (actionRejectedCount[_proposalId] == AB_MAJ_TO_REJECT_ACTION) {
      proposalActionStatus[_proposalId] = uint(ActionStatus.Rejected);
    }
  }

  /**
   * @dev Sets intial actionWaitingTime value
   * To be called after governance implementation has been updated
   */
  function setInitialActionParameters() external onlyOwner {
    require(!actionParamsInitialised);
    actionParamsInitialised = true;
    actionWaitingTime = 24 * 1 hours;
  }

  /**
   * @dev Gets Uint Parameters of a code
   * @param code whose details we want
   * @return string value of the code
   * @return associated amount (time or perc or value) to the code
   */
  function getUintParameters(bytes8 code) external view returns (bytes8 codeVal, uint val) {

    codeVal = code;

    if (code == "GOVHOLD") {

      val = tokenHoldingTime / (1 days);

    } else if (code == "MAXFOL") {

      val = maxFollowers;

    } else if (code == "MAXDRFT") {

      val = maxDraftTime / (1 days);

    } else if (code == "EPTIME") {

      val = ms.pauseTime() / (1 days);

    } else if (code == "ACWT") {

      val = actionWaitingTime / (1 hours);

    }
  }

  /**
   * @dev Gets all details of a propsal
   * @param _proposalId whose details we want
   * @return proposalId
   * @return category
   * @return status
   * @return finalVerdict
   * @return totalReward
   */
  function proposal(uint _proposalId)
  external
  view
  returns (
    uint proposalId,
    uint category,
    uint status,
    uint finalVerdict,
    uint totalRewar
  )
  {
    return (
    _proposalId,
    allProposalData[_proposalId].category,
    allProposalData[_proposalId].propStatus,
    allProposalData[_proposalId].finalVerdict,
    allProposalData[_proposalId].commonIncentive
    );
  }

  /**
   * @dev Gets some details of a propsal
   * @param _proposalId whose details we want
   * @return proposalId
   * @return number of all proposal solutions
   * @return amount of votes
   */
  function proposalDetails(uint _proposalId) external view returns (uint, uint, uint) {
    return (
    _proposalId,
    allProposalSolutions[_proposalId].length,
    proposalVoteTally[_proposalId].voters
    );
  }

  /**
   * @dev Gets solution action on a proposal
   * @param _proposalId whose details we want
   * @param _solution whose details we want
   * @return action of a solution on a proposal
   */
  function getSolutionAction(uint _proposalId, uint _solution) external view returns (uint, bytes memory) {
    return (
    _solution,
    allProposalSolutions[_proposalId][_solution]
    );
  }

  /**
   * @dev Gets length of propsal
   * @return length of propsal
   */
  function getProposalLength() external view returns (uint) {
    return totalProposals;
  }

  /**
   * @dev Get followers of an address
   * @return get followers of an address
   */
  function getFollowers(address _add) external view returns (uint[] memory) {
    return leaderDelegation[_add];
  }

  /**
   * @dev Gets pending rewards of a member
   * @param _memberAddress in concern
   * @return amount of pending reward
   */
  function getPendingReward(address _memberAddress)
  public view returns (uint pendingDAppReward)
  {
    uint delegationId = followerDelegation[_memberAddress];
    address leader;
    uint lastUpd;
    DelegateVote memory delegationData = allDelegation[delegationId];

    if (delegationId > 0 && delegationData.leader != address(0)) {
      leader = delegationData.leader;
      lastUpd = delegationData.lastUpd;
    } else
      leader = _memberAddress;

    uint proposalId;
    for (uint i = lastRewardClaimed[_memberAddress]; i < allVotesByMember[leader].length; i++) {
      if (allVotes[allVotesByMember[leader][i]].dateAdd > (
      lastUpd.add(tokenHoldingTime)) || leader == _memberAddress) {
        if (!rewardClaimed[allVotesByMember[leader][i]][_memberAddress]) {
          proposalId = allVotes[allVotesByMember[leader][i]].proposalId;
          if (proposalVoteTally[proposalId].voters > 0 && allProposalData[proposalId].propStatus
          > uint(ProposalStatus.VotingStarted)) {
            pendingDAppReward = pendingDAppReward.add(
              allProposalData[proposalId].commonIncentive.div(
                proposalVoteTally[proposalId].voters
              )
            );
          }
        }
      }
    }
  }

  /**
   * @dev Updates Uint Parameters of a code
   * @param code whose details we want to update
   * @param val value to set
   */
  function updateUintParameters(bytes8 code, uint val) public {

    require(ms.checkIsAuthToGoverned(msg.sender));
    if (code == "GOVHOLD") {

      tokenHoldingTime = val * 1 days;

    } else if (code == "MAXFOL") {

      maxFollowers = val;

    } else if (code == "MAXDRFT") {

      maxDraftTime = val * 1 days;

    } else if (code == "EPTIME") {

      ms.updatePauseTime(val * 1 days);

    } else if (code == "ACWT") {

      actionWaitingTime = val * 1 hours;

    } else {

      revert("Invalid code");

    }
  }

  /**
  * @dev Updates all dependency addresses to latest ones from Master
  */
  function changeDependentContractAddress() public {
    tokenInstance = ITokenController(ms.dAppLocker());
    memberRole = IMemberRoles(ms.getLatestAddress("MR"));
    proposalCategory = IProposalCategory(ms.getLatestAddress("PC"));
  }

  /**
  * @dev Checks if msg.sender is allowed to create a proposal under given category
  */
  function allowedToCreateProposal(uint category) public view returns (bool check) {
    if (category == 0)
      return true;
    uint[] memory mrAllowed;
    (,,,, mrAllowed,,) = proposalCategory.category(category);
    for (uint i = 0; i < mrAllowed.length; i++) {
      if (mrAllowed[i] == 0 || memberRole.checkRole(msg.sender, mrAllowed[i]))
        return true;
    }
  }

  /**
   * @dev Checks if an address is already delegated
   * @param _add in concern
   * @return bool value if the address is delegated or not
   */
  function alreadyDelegated(address _add) public view returns (bool delegated) {
    for (uint i = 0; i < leaderDelegation[_add].length; i++) {
      if (allDelegation[leaderDelegation[_add][i]].leader == _add) {
        return true;
      }
    }
  }

  /**
  * @dev Checks If the proposal voting time is up and it's ready to close
  *      i.e. Closevalue is 1 if proposal is ready to be closed, 2 if already closed, 0 otherwise!
  * @param _proposalId Proposal id to which closing value is being checked
  */
  function canCloseProposal(uint _proposalId)
  public
  view
  returns (uint)
  {
    uint dateUpdate;
    uint pStatus;
    uint _closingTime;
    uint _roleId;
    uint majority;
    pStatus = allProposalData[_proposalId].propStatus;
    dateUpdate = allProposalData[_proposalId].dateUpd;
    (, _roleId, majority, , , _closingTime,) = proposalCategory.category(allProposalData[_proposalId].category);
    if (
      pStatus == uint(ProposalStatus.VotingStarted)
    ) {
      uint numberOfMembers = memberRole.numberOfMembers(_roleId);
      if (_roleId == uint(IMemberRoles.Role.AdvisoryBoard)) {
        if (proposalVoteTally[_proposalId].abVoteValue[1].mul(100).div(numberOfMembers) >= majority
        || proposalVoteTally[_proposalId].abVoteValue[1].add(proposalVoteTally[_proposalId].abVoteValue[0]) == numberOfMembers
          || dateUpdate.add(_closingTime) <= now) {

          return 1;
        }
      } else {
        if (numberOfMembers == proposalVoteTally[_proposalId].voters
          || dateUpdate.add(_closingTime) <= now)
          return 1;
      }
    } else if (pStatus > uint(ProposalStatus.VotingStarted)) {
      return 2;
    } else {
      return 0;
    }
  }

  /**
   * @dev Gets Id of member role allowed to categorize the proposal
   * @return roleId allowed to categorize the proposal
   */
  function allowedToCatgorize() public view returns (uint roleId) {
    return roleIdAllowedToCatgorize;
  }

  /**
   * @dev Gets vote tally data
   * @param _proposalId in concern
   * @param _solution of a proposal id
   * @return member vote value
   * @return advisory board vote value
   * @return amount of votes
   */
  function voteTallyData(uint _proposalId, uint _solution) public view returns (uint, uint, uint) {
    return (proposalVoteTally[_proposalId].memberVoteValue[_solution],
    proposalVoteTally[_proposalId].abVoteValue[_solution], proposalVoteTally[_proposalId].voters);
  }

  /**
   * @dev Internal call to create proposal
   * @param _proposalTitle of proposal
   * @param _proposalSD is short description of proposal
   * @param _proposalDescHash IPFS hash value of propsal
   * @param _categoryId of proposal
   */
  function _createProposal(
    string memory _proposalTitle,
    string memory _proposalSD,
    string memory _proposalDescHash,
    uint _categoryId
  )
  internal
  {
    require(proposalCategory.categoryABReq(_categoryId) == 0 || _categoryId == 0);
    uint _proposalId = totalProposals;
    allProposalData[_proposalId].owner = msg.sender;
    allProposalData[_proposalId].dateUpd = now;
    allProposalSolutions[_proposalId].push("");
    totalProposals++;

    emit Proposal(
      msg.sender,
      _proposalId,
      now,
      _proposalTitle,
      _proposalSD,
      _proposalDescHash
    );

    if (_categoryId > 0)
      _categorizeProposal(_proposalId, _categoryId, 0);
  }

  /**
   * @dev Internal call to categorize a proposal
   * @param _proposalId of proposal
   * @param _categoryId of proposal
   * @param _incentive is commonIncentive
   */
  function _categorizeProposal(
    uint _proposalId,
    uint _categoryId,
    uint _incentive
  )
  internal
  {
    require(
      _categoryId > 0 && _categoryId < proposalCategory.totalCategories(),
      "Invalid category"
    );
    allProposalData[_proposalId].category = _categoryId;
    allProposalData[_proposalId].commonIncentive = _incentive;
    allProposalData[_proposalId].propStatus = uint(ProposalStatus.AwaitingSolution);

    emit ProposalCategorized(_proposalId, msg.sender, _categoryId);
  }

  /**
   * @dev Internal call to add solution to a proposal
   * @param _proposalId in concern
   * @param _action on that solution
   * @param _solutionHash string value
   */
  function _addSolution(uint _proposalId, bytes memory _action, string memory _solutionHash)
  internal
  {
    allProposalSolutions[_proposalId].push(_action);
    emit Solution(_proposalId, msg.sender, allProposalSolutions[_proposalId].length - 1, _solutionHash, now);
  }

  /**
  * @dev Internal call to add solution and open proposal for voting
  */
  function _proposalSubmission(
    uint _proposalId,
    string memory _solutionHash,
    bytes memory _action
  )
  internal
  {

    uint _categoryId = allProposalData[_proposalId].category;
    if (proposalCategory.categoryActionHashes(_categoryId).length == 0) {
      require(keccak256(_action) == keccak256(""));
      proposalActionStatus[_proposalId] = uint(ActionStatus.NoAction);
    }

    _addSolution(
      _proposalId,
      _action,
      _solutionHash
    );

    _updateProposalStatus(_proposalId, uint(ProposalStatus.VotingStarted));
    (, , , , , uint closingTime,) = proposalCategory.category(_categoryId);
    emit CloseProposalOnTime(_proposalId, closingTime.add(now));

  }

  /**
   * @dev Internal call to submit vote
   * @param _proposalId of proposal in concern
   * @param _solution for that proposal
   */
  function _submitVote(uint _proposalId, uint _solution) internal {

    uint delegationId = followerDelegation[msg.sender];
    uint mrSequence;
    uint majority;
    uint closingTime;
    (, mrSequence, majority, , , closingTime,) = proposalCategory.category(allProposalData[_proposalId].category);

    require(allProposalData[_proposalId].dateUpd.add(closingTime) > now, "Closed");

    require(memberProposalVote[msg.sender][_proposalId] == 0, "Not allowed");
    require((delegationId == 0) || (delegationId > 0 && allDelegation[delegationId].leader == address(0) &&
    _checkLastUpd(allDelegation[delegationId].lastUpd)));

    require(memberRole.checkRole(msg.sender, mrSequence), "Not Authorized");
    uint totalVotes = allVotes.length;

    allVotesByMember[msg.sender].push(totalVotes);
    memberProposalVote[msg.sender][_proposalId] = totalVotes;

    allVotes.push(ProposalVote(msg.sender, _proposalId, now));

    emit Vote(msg.sender, _proposalId, totalVotes, now, _solution);
    if (mrSequence == uint(IMemberRoles.Role.Owner)) {
      if (_solution == 1)
        _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), allProposalData[_proposalId].category, 1, IMemberRoles.Role.Owner);
      else
        _updateProposalStatus(_proposalId, uint(ProposalStatus.Rejected));

    } else {
      uint numberOfMembers = memberRole.numberOfMembers(mrSequence);
      _setVoteTally(_proposalId, _solution, mrSequence);

      if (mrSequence == uint(IMemberRoles.Role.AdvisoryBoard)) {
        if (proposalVoteTally[_proposalId].abVoteValue[1].mul(100).div(numberOfMembers)
        >= majority
          || (proposalVoteTally[_proposalId].abVoteValue[1].add(proposalVoteTally[_proposalId].abVoteValue[0])) == numberOfMembers) {
          emit VoteCast(_proposalId);
        }
      } else {
        if (numberOfMembers == proposalVoteTally[_proposalId].voters)
          emit VoteCast(_proposalId);
      }
    }

  }

  /**
   * @dev Internal call to set vote tally of a proposal
   * @param _proposalId of proposal in concern
   * @param _solution of proposal in concern
   * @param mrSequence number of members for a role
   */
  function _setVoteTally(uint _proposalId, uint _solution, uint mrSequence) internal
  {
    uint categoryABReq;
    uint isSpecialResolution;
    (, categoryABReq, isSpecialResolution) = proposalCategory.categoryExtendedData(allProposalData[_proposalId].category);
    if (memberRole.checkRole(msg.sender, uint(IMemberRoles.Role.AdvisoryBoard)) && (categoryABReq > 0) ||
      mrSequence == uint(IMemberRoles.Role.AdvisoryBoard)) {
      proposalVoteTally[_proposalId].abVoteValue[_solution]++;
    }
    tokenInstance.lockForMemberVote(msg.sender, tokenHoldingTime);
    if (mrSequence != uint(IMemberRoles.Role.AdvisoryBoard)) {
      uint voteWeight;
      uint voters = 1;
      uint tokenBalance = tokenInstance.totalBalanceOf(msg.sender);
      uint totalSupply = tokenInstance.totalSupply();
      if (isSpecialResolution == 1) {
        voteWeight = tokenBalance.add(10 ** 18);
      } else {
        voteWeight = (_minOf(tokenBalance, maxVoteWeigthPer.mul(totalSupply).div(100))).add(10 ** 18);
      }
      DelegateVote memory delegationData;
      for (uint i = 0; i < leaderDelegation[msg.sender].length; i++) {
        delegationData = allDelegation[leaderDelegation[msg.sender][i]];
        if (delegationData.leader == msg.sender &&
          _checkLastUpd(delegationData.lastUpd)) {
          if (memberRole.checkRole(delegationData.follower, mrSequence)) {
            tokenBalance = tokenInstance.totalBalanceOf(delegationData.follower);
            tokenInstance.lockForMemberVote(delegationData.follower, tokenHoldingTime);
            voters++;
            if (isSpecialResolution == 1) {
              voteWeight = voteWeight.add(tokenBalance.add(10 ** 18));
            } else {
              voteWeight = voteWeight.add((_minOf(tokenBalance, maxVoteWeigthPer.mul(totalSupply).div(100))).add(10 ** 18));
            }
          }
        }
      }
      proposalVoteTally[_proposalId].memberVoteValue[_solution] = proposalVoteTally[_proposalId].memberVoteValue[_solution].add(voteWeight);
      proposalVoteTally[_proposalId].voters = proposalVoteTally[_proposalId].voters + voters;
    }
  }

  /**
   * @dev Gets minimum of two numbers
   * @param a one of the two numbers
   * @param b one of the two numbers
   * @return minimum number out of the two
   */
  function _minOf(uint a, uint b) internal pure returns (uint res) {
    res = a;
    if (res > b)
      res = b;
  }

  /**
   * @dev Check the time since last update has exceeded token holding time or not
   * @param _lastUpd is last update time
   * @return the bool which tells if the time since last update has exceeded token holding time or not
   */
  function _checkLastUpd(uint _lastUpd) internal view returns (bool) {
    return (now - _lastUpd) > tokenHoldingTime;
  }

  /**
  * @dev Checks if the vote count against any solution passes the threshold value or not.
  */
  function _checkForThreshold(uint _proposalId, uint _category) internal view returns (bool check) {
    uint categoryQuorumPerc;
    uint roleAuthorized;
    (, roleAuthorized, , categoryQuorumPerc, , ,) = proposalCategory.category(_category);
    check = ((proposalVoteTally[_proposalId].memberVoteValue[0]
    .add(proposalVoteTally[_proposalId].memberVoteValue[1]))
    .mul(100))
    .div(
      tokenInstance.totalSupply().add(
        memberRole.numberOfMembers(roleAuthorized).mul(10 ** 18)
      )
    ) >= categoryQuorumPerc;
  }

  /**
   * @dev Called when vote majority is reached
   * @param _proposalId of proposal in concern
   * @param _status of proposal in concern
   * @param category of proposal in concern
   * @param max vote value of proposal in concern
   */
  function _callIfMajReached(uint _proposalId, uint _status, uint category, uint max, IMemberRoles.Role role) internal {

    allProposalData[_proposalId].finalVerdict = max;
    _updateProposalStatus(_proposalId, _status);
    emit ProposalAccepted(_proposalId);
    if (proposalActionStatus[_proposalId] != uint(ActionStatus.NoAction)) {
      if (role == IMemberRoles.Role.AdvisoryBoard) {
        _triggerAction(_proposalId, category);
      } else {
        proposalActionStatus[_proposalId] = uint(ActionStatus.Accepted);
        proposalExecutionTime[_proposalId] = actionWaitingTime.add(now);
      }
    }
  }

  /**
   * @dev Internal function to trigger action of accepted proposal
   */
  function _triggerAction(uint _proposalId, uint _categoryId) internal {
    proposalActionStatus[_proposalId] = uint(ActionStatus.Executed);
    bytes2 contractName;
    address actionAddress;
    bytes memory _functionHash;
    (, actionAddress, contractName, , _functionHash) = proposalCategory.categoryActionDetails(_categoryId);
    if (contractName == "MS") {
      actionAddress = address(ms);
    } else if (contractName != "EX") {
      actionAddress = ms.getLatestAddress(contractName);
    }
    // solhint-disable-next-line avoid-low-level-calls
    (bool actionStatus,) = actionAddress.call(abi.encodePacked(_functionHash, allProposalSolutions[_proposalId][1]));
    if (actionStatus) {
      emit ActionSuccess(_proposalId);
    } else {
      proposalActionStatus[_proposalId] = uint(ActionStatus.Accepted);
      emit ActionFailed(_proposalId);
    }
  }

  /**
   * @dev Internal call to update proposal status
   * @param _proposalId of proposal in concern
   * @param _status of proposal to set
   */
  function _updateProposalStatus(uint _proposalId, uint _status) internal {
    if (_status == uint(ProposalStatus.Rejected) || _status == uint(ProposalStatus.Denied)) {
      proposalActionStatus[_proposalId] = uint(ActionStatus.NoAction);
    }
    allProposalData[_proposalId].dateUpd = now;
    allProposalData[_proposalId].propStatus = _status;
  }

  /**
   * @dev Internal call to undelegate a follower
   * @param _follower is address of follower to undelegate
   */
  function _unDelegate(address _follower) internal {

    uint delegationId = followerDelegation[_follower];
    DelegateVote memory delegation = allDelegation[delegationId];

    if (delegation.leader != address(0)) {

      uint currentFollowerCount = followerCount[delegation.leader];

      if (currentFollowerCount > 0) {
        followerCount[delegation.leader] = currentFollowerCount.sub(1);
      }

      allDelegation[delegationId].leader = address(0);
      allDelegation[delegationId].lastUpd = now;
      lastRewardClaimed[_follower] = allVotesByMember[_follower].length;
    }
  }

  /**
   * @dev Internal call to close member voting
   * @param _proposalId of proposal in concern
   * @param category of proposal in concern
   */
  function _closeMemberVote(uint _proposalId, uint category) internal {
    uint isSpecialResolution;
    uint abMaj;
    (, abMaj, isSpecialResolution) = proposalCategory.categoryExtendedData(category);
    if (isSpecialResolution == 1) {
      uint acceptedVotePerc = proposalVoteTally[_proposalId].memberVoteValue[1].mul(100)
      .div(
        tokenInstance.totalSupply().add(
          memberRole.numberOfMembers(uint(IMemberRoles.Role.Member)).mul(10 ** 18)
        ));
      if (acceptedVotePerc >= specialResolutionMajPerc) {
        _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), category, 1, IMemberRoles.Role.Member);
      } else {
        _updateProposalStatus(_proposalId, uint(ProposalStatus.Denied));
      }
    } else {
      if (_checkForThreshold(_proposalId, category)) {
        uint majorityVote;
        (,, majorityVote,,,,) = proposalCategory.category(category);
        if (
          ((proposalVoteTally[_proposalId].memberVoteValue[1].mul(100))
          .div(proposalVoteTally[_proposalId].memberVoteValue[0]
          .add(proposalVoteTally[_proposalId].memberVoteValue[1])
          ))
          >= majorityVote
        ) {
          _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), category, 1, IMemberRoles.Role.Member);
        } else {
          _updateProposalStatus(_proposalId, uint(ProposalStatus.Rejected));
        }
      } else {
        if (abMaj > 0 && proposalVoteTally[_proposalId].abVoteValue[1].mul(100)
        .div(memberRole.numberOfMembers(uint(IMemberRoles.Role.AdvisoryBoard))) >= abMaj) {
          _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), category, 1, IMemberRoles.Role.Member);
        } else {
          _updateProposalStatus(_proposalId, uint(ProposalStatus.Denied));
        }
      }
    }

    if (proposalVoteTally[_proposalId].voters > 0) {
      tokenInstance.mint(ms.getLatestAddress("CR"), allProposalData[_proposalId].commonIncentive);
    }
  }

  /**
   * @dev Internal call to close advisory board voting
   * @param _proposalId of proposal in concern
   * @param category of proposal in concern
   */
  function _closeAdvisoryBoardVote(uint _proposalId, uint category) internal {
    uint _majorityVote;
    IMemberRoles.Role _roleId = IMemberRoles.Role.AdvisoryBoard;
    (,, _majorityVote,,,,) = proposalCategory.category(category);
    if (proposalVoteTally[_proposalId].abVoteValue[1].mul(100)
    .div(memberRole.numberOfMembers(uint(_roleId))) >= _majorityVote) {
      _callIfMajReached(_proposalId, uint(ProposalStatus.Accepted), category, 1, _roleId);
    } else {
      _updateProposalStatus(_proposalId, uint(ProposalStatus.Denied));
    }

  }

}

pragma solidity ^0.5.0;

import "../interfaces/INXMMaster.sol";

contract Iupgradable {

  INXMMaster public ms;
  address public nxMasterAddress;

  modifier onlyInternal {
    require(ms.isInternal(msg.sender));
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
   * @dev Iupgradable Interface to update dependent contract address
   */
  function changeDependentContractAddress() public;

  /**
   * @dev change master address
   * @param _masterAddress is the new address
   */
  function changeMasterAddress(address _masterAddress) public {
    if (address(ms) != address(0)) {
      require(address(ms) == msg.sender, "Not master");
    }

    ms = INXMMaster(_masterAddress);
    nxMasterAddress = _masterAddress;
  }

}

// SPDX-License-Identifier: GPL-3.0

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface IPooledStaking {

  function accumulateReward(address contractAddress, uint amount) external;

  function pushBurn(address contractAddress, uint amount) external;

  function hasPendingActions() external view returns (bool);

  function processPendingActions(uint maxIterations) external returns (bool finished);

  function contractStake(address contractAddress) external view returns (uint);

  function stakerReward(address staker) external view returns (uint);

  function stakerDeposit(address staker) external view returns (uint);

  function stakerContractStake(address staker, address contractAddress) external view returns (uint);

  function withdraw(uint amount) external;

  function stakerMaxWithdrawable(address stakerAddress) external view returns (uint);

  function withdrawReward(address stakerAddress) external;
}

// SPDX-License-Identifier: GPL-3.0

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface IMCR {

  function updateMCRInternal(uint poolValueInEth, bool forceUpdate) external;
  function getMCR() external view returns (uint);
}

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface IClaimsData {

  function pendingClaimStart() external view returns (uint);
  function claimDepositTime() external view returns (uint);
  function maxVotingTime() external view returns (uint);
  function minVotingTime() external view returns (uint);
  function payoutRetryTime() external view returns (uint);
  function claimRewardPerc() external view returns (uint);
  function minVoteThreshold() external view returns (uint);
  function maxVoteThreshold() external view returns (uint);
  function majorityConsensus() external view returns (uint);
  function pauseDaysCA() external view returns (uint);

  function userClaimVotePausedOn(address) external view returns (uint);

  function setpendingClaimStart(uint _start) external;

  function setRewardDistributedIndexCA(address _voter, uint caIndex) external;

  function setUserClaimVotePausedOn(address user) external;

  function setRewardDistributedIndexMV(address _voter, uint mvIndex) external;


  function setClaimRewardDetail(
    uint claimid,
    uint percCA,
    uint percMV,
    uint tokens
  ) external;

  function setRewardClaimed(uint _voteid, bool claimed) external;

  function changeFinalVerdict(uint _claimId, int8 _verdict) external;

  function addClaim(
    uint _claimId,
    uint _coverId,
    address _from,
    uint _nowtime
  ) external;

  function addVote(
    address _voter,
    uint _tokens,
    uint claimId,
    int8 _verdict
  ) external;

  function addClaimVoteCA(uint _claimId, uint _voteid) external;

  function setUserClaimVoteCA(
    address _from,
    uint _claimId,
    uint _voteid
  ) external;

  function setClaimTokensCA(uint _claimId, int8 _vote, uint _tokens) external;

  function setClaimTokensMV(uint _claimId, int8 _vote, uint _tokens) external;

  function addClaimVotemember(uint _claimId, uint _voteid) external;

  function setUserClaimVoteMember(
    address _from,
    uint _claimId,
    uint _voteid
  ) external;

  function updateState12Count(uint _claimId, uint _cnt) external;

  function setClaimStatus(uint _claimId, uint _stat) external;

  function setClaimdateUpd(uint _claimId, uint _dateUpd) external;

  function setClaimAtEmergencyPause(
    uint _coverId,
    uint _dateUpd,
    bool _submit
  ) external;

  function setClaimSubmittedAtEPTrue(uint _index, bool _submit) external;


  function setFirstClaimIndexToSubmitAfterEP(
    uint _firstClaimIndexToSubmit
  ) external;


  function setPendingClaimDetails(
    uint _claimId,
    uint _pendingTime,
    bool _voting
  ) external;

  function setPendingClaimVoteStatus(uint _claimId, bool _vote) external;

  function setFirstClaimIndexToStartVotingAfterEP(
    uint _claimStartVotingFirstIndex
  ) external;

  function callVoteEvent(
    address _userAddress,
    uint _claimId,
    bytes4 _typeOf,
    uint _tokens,
    uint _submitDate,
    int8 _verdict
  ) external;

  function callClaimEvent(
    uint _coverId,
    address _userAddress,
    uint _claimId,
    uint _datesubmit
  ) external;

  function getUintParameters(bytes8 code) external view returns (bytes8 codeVal, uint val);

  function getClaimOfEmergencyPauseByIndex(
    uint _index
  )
  external
  view
  returns (
    uint coverId,
    uint dateUpd,
    bool submit
  );

  function getAllClaimsByIndex(
    uint _claimId
  )
  external
  view
  returns (
    uint coverId,
    int8 vote,
    uint status,
    uint dateUpd,
    uint state12Count
  );

  function getUserClaimVoteCA(
    address _add,
    uint _claimId
  )
  external
  view
  returns (uint idVote);

  function getUserClaimVoteMember(
    address _add,
    uint _claimId
  )
  external
  view
  returns (uint idVote);

  function getAllVoteLength() external view returns (uint voteCount);

  function getClaimStatusNumber(uint _claimId) external view returns (uint claimId, uint statno);

  function getRewardStatus(uint statusNumber) external view returns (uint percCA, uint percMV);

  function getClaimState12Count(uint _claimId) external view returns (uint num);

  function getClaimDateUpd(uint _claimId) external view returns (uint dateupd);

  function getAllClaimsByAddress(address _member) external view returns (uint[] memory claimarr);


  function getClaimsTokenCA(
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint accept,
    uint deny
  );

  function getClaimsTokenMV(
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint accept,
    uint deny
  );
  function getCaClaimVotesToken(uint _claimId) external view returns (uint claimId, uint cnt);

  function getMemberClaimVotesToken(
    uint _claimId
  )
  external
  view
  returns (uint claimId, uint cnt);

  function getVoteDetails(uint _voteid)
  external view
  returns (
    uint tokens,
    uint claimId,
    int8 verdict,
    bool rewardClaimed
  );

  function getVoterVote(uint _voteid) external view returns (address voter);

  function getClaim(
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint coverId,
    int8 vote,
    uint status,
    uint dateUpd,
    uint state12Count
  );

  function getClaimVoteLength(
    uint _claimId,
    uint8 _ca
  )
  external
  view
  returns (uint claimId, uint len);

  function getVoteVerdict(
    uint _claimId,
    uint _index,
    uint8 _ca
  )
  external
  view
  returns (int8 ver);

  function getVoteToken(
    uint _claimId,
    uint _index,
    uint8 _ca
  )
  external
  view
  returns (uint tok);

  function getVoteVoter(
    uint _claimId,
    uint _index,
    uint8 _ca
  )
  external
  view
  returns (address voter);

  function getUserClaimCount(address _add) external view returns (uint len);

  function getClaimLength() external view returns (uint len);

  function actualClaimLength() external view returns (uint len);


  function getClaimFromNewStart(
    uint _index,
    address _add
  )
  external
  view
  returns (
    uint coverid,
    uint claimId,
    int8 voteCA,
    int8 voteMV,
    uint statusnumber
  );

  function getUserClaimByIndex(
    uint _index,
    address _add
  )
  external
  view
  returns (
    uint status,
    uint coverid,
    uint claimId
  );

  function getAllVotesForClaim(
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint[] memory ca,
    uint[] memory mv
  );


  function getTokensClaim(
    address _of,
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint tokens
  );

  function getRewardDistributedIndex(
    address _voter
  )
  external
  view
  returns (
    uint lastCAvoteIndex,
    uint lastMVvoteIndex
  );

  function getClaimRewardDetail(
    uint claimid
  )
  external
  view
  returns (
    uint percCA,
    uint percMV,
    uint tokens
  );

  function getClaimCoverId(uint _claimId) external view returns (uint claimId, uint coverid);

  function getClaimVote(uint _claimId, int8 _verdict) external view returns (uint claimId, uint token);

  function getClaimMVote(uint _claimId, int8 _verdict) external view returns (uint claimId, uint token);

  function getVoteAddressCA(address _voter, uint index) external view returns (uint);

  function getVoteAddressMember(address _voter, uint index) external view returns (uint);

  function getVoteAddressCALength(address _voter) external view returns (uint);

  function getVoteAddressMemberLength(address _voter) external view returns (uint);

  function getFinalVerdict(uint _claimId) external view returns (int8 verdict);

  function getLengthOfClaimSubmittedAtEP() external view returns (uint len);

  function getFirstClaimIndexToSubmitAfterEP() external view returns (uint indexToSubmit);

  function getLengthOfClaimVotingPause() external view returns (uint len);

  function getPendingClaimDetailsByIndex(
    uint _index
  )
  external
  view
  returns (
    uint claimId,
    uint pendingTime,
    bool voting
  );

  function getFirstClaimIndexToStartVotingAfterEP() external view returns (uint firstindex);

}

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface IClaims {

  function setClaimStatus(uint claimId, uint stat) external;

  function getCATokens(uint claimId, uint member) external view returns (uint tokens);

  function submitClaim(uint coverId) external;

  function submitClaimForMember(uint coverId, address member) external;

  function submitClaimAfterEPOff() external pure;

  function submitCAVote(uint claimId, int8 verdict) external;

  function submitMemberVote(uint claimId, int8 verdict) external;

  function pauseAllPendingClaimsVoting() external pure;

  function startAllPendingClaimsVoting() external pure;

  function checkVoteClosing(uint claimId) external view returns (int8 close);
}

// SPDX-License-Identifier: GPL-3.0

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

import "./IPriceFeedOracle.sol";

interface IPool {
  function sellNXM(uint tokenAmount, uint minEthOut) external;

  function sellNXMTokens(uint tokenAmount) external returns (bool);

  function minPoolEth() external returns (uint);

  function transferAssetToSwapOperator(address asset, uint amount) external;

  function setAssetDataLastSwapTime(address asset, uint32 lastSwapTime) external;

  function getAssetDetails(address _asset) external view returns (
    uint112 min,
    uint112 max,
    uint32 lastAssetSwapTime,
    uint maxSlippageRatio
  );

  function sendClaimPayout (
    address asset,
    address payable payoutAddress,
    uint amount
  ) external returns (bool success);

  function transferAsset(
    address asset,
    address payable destination,
    uint amount
  ) external;

  function upgradeCapitalPool(address payable newPoolAddress) external;

  function priceFeedOracle() external view returns (IPriceFeedOracle);

  function getPoolValueInEth() external view returns (uint);


  function transferAssetFrom(address asset, address from, uint amount) external;

  function getEthForNXM(uint nxmAmount) external view returns (uint ethAmount);

  function calculateEthForNXM(
    uint nxmAmount,
    uint currentTotalAssetValue,
    uint mcrEth
  ) external pure returns (uint);

  function calculateMCRRatio(uint totalAssetValue, uint mcrEth) external pure returns (uint);

  function calculateTokenSpotPrice(uint totalAssetValue, uint mcrEth) external pure returns (uint tokenPrice);

  function getTokenPrice(address asset) external view returns (uint tokenPrice);

  function getMCRRatio() external view returns (uint);
}

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract INXMToken is IERC20 {

  function burn(uint256 amount) public returns (bool);

  function burnFrom(address from, uint256 value) public returns (bool);

  function operatorTransfer(address from, uint256 value) public returns (bool);

  function mint(address account, uint256 amount) public;

  function isLockedForMV(address member) external view returns (uint);

  function addToWhiteList(address _member) external returns (bool);

  function removeFromWhiteList(address _member) external returns (bool);

  function changeOperator(address _newOperator) external returns (bool);

  function lockForMemberVote(address _of, uint _days) external;
}

/* Copyright (C) 2017 GovBlocks.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface IProposalCategory {

  event Category(
    uint indexed categoryId,
    string categoryName,
    string actionHash
  );

  function categoryABReq(uint) external view returns (uint);
  function isSpecialResolution(uint) external view returns (uint);
  function categoryActionHashes(uint) external view returns (bytes memory);

  function categoryExtendedData(uint _categoryId) external view returns (uint, uint, uint);

  /// @dev Adds new category
  /// @param _name Category name
  /// @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
  /// @param _allowedToCreateProposal Member roles allowed to create the proposal
  /// @param _majorityVotePerc Majority Vote threshold for Each voting layer
  /// @param _quorumPerc minimum threshold percentage required in voting to calculate result
  /// @param _closingTime Vote closing time for Each voting layer
  /// @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
  /// @param _contractAddress address of contract to call after proposal is accepted
  /// @param _contractName name of contract to be called after proposal is accepted
  /// @param _incentives rewards to distributed after proposal is accepted
  function addCategory(
    string calldata _name,
    uint _memberRoleToVote,
    uint _majorityVotePerc,
    uint _quorumPerc,
    uint[] calldata _allowedToCreateProposal,
    uint _closingTime,
    string calldata _actionHash,
    address _contractAddress,
    bytes2 _contractName,
    uint[] calldata _incentives
  )
  external;

  /// @dev gets category details
  function category(uint _categoryId)
  external
  view
  returns (
    uint categoryId,
    uint memberRoleToVote,
    uint majorityVotePerc,
    uint quorumPerc,
    uint[] memory allowedToCreateProposal,
    uint closingTime,
    uint minStake
  );

  ///@dev gets category action details
  function categoryAction(uint _categoryId)
  external
  view
  returns (
    uint categoryId,
    address contractAddress,
    bytes2 contractName,
    uint defaultIncentive
  );

  function categoryActionDetails(uint _categoryId) external view returns (uint, address, bytes2, uint, bytes memory);

  /// @dev Gets Total number of categories added till now
  function totalCategories() external view returns (uint numberOfCategories);

  /// @dev Updates category details
  /// @param _categoryId Category id that needs to be updated
  /// @param _name Category name
  /// @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
  /// @param _allowedToCreateProposal Member roles allowed to create the proposal
  /// @param _majorityVotePerc Majority Vote threshold for Each voting layer
  /// @param _quorumPerc minimum threshold percentage required in voting to calculate result
  /// @param _closingTime Vote closing time for Each voting layer
  /// @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
  /// @param _contractAddress address of contract to call after proposal is accepted
  /// @param _contractName name of contract to be called after proposal is accepted
  /// @param _incentives rewards to distributed after proposal is accepted
  function updateCategory(
    uint _categoryId,
    string calldata _name,
    uint _memberRoleToVote,
    uint _majorityVotePerc,
    uint _quorumPerc,
    uint[] calldata _allowedToCreateProposal,
    uint _closingTime,
    string calldata _actionHash,
    address _contractAddress,
    bytes2 _contractName,
    uint[] calldata _incentives
  ) external;

}

// SPDX-License-Identifier: GPL-3.0

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface INXMMaster {

  function tokenAddress() external view returns (address);

  function owner() external view returns (address);

  function pauseTime() external view returns (uint);

  function masterInitialized() external view returns (bool);

  function isInternal(address _add) external view returns (bool);

  function isPause() external view returns (bool check);

  function isOwner(address _add) external view returns (bool);

  function isMember(address _add) external view returns (bool);

  function checkIsAuthToGoverned(address _add) external view returns (bool);

  function updatePauseTime(uint _time) external;

  function dAppLocker() external view returns (address _add);

  function dAppToken() external view returns (address _add);

  function getLatestAddress(bytes2 _contractName) external view returns (address payable contractAddress);
}

// SPDX-License-Identifier: GPL-3.0

/* Copyright (C) 2021 NexusMutual.io

  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity >=0.5.0;

interface IPriceFeedOracle {

  function daiAddress() external view returns (address);
  function stETH() external view returns (address);
  function ETH() external view returns (address);

  function getAssetToEthRate(address asset) external view returns (uint);
  function getAssetForEth(address asset, uint ethIn) external view returns (uint);

}

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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}