/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

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

// File: contracts/abstract/INXMMaster.sol

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

pragma solidity ^0.5.0;

contract INXMMaster {

  address public tokenAddress;

  address public owner;

  uint public pauseTime;

  function delegateCallBack(bytes32 myid) external;

  function masterInitialized() public view returns (bool);

  function isInternal(address _add) public view returns (bool);

  function isPause() public view returns (bool check);

  function isOwner(address _add) public view returns (bool);

  function isMember(address _add) public view returns (bool);

  function checkIsAuthToGoverned(address _add) public view returns (bool);

  function updatePauseTime(uint _time) public;

  function dAppLocker() public view returns (address _add);

  function dAppToken() public view returns (address _add);

  function getLatestAddress(bytes2 _contractName) public view returns (address payable contractAddress);
}

// File: contracts/abstract/Iupgradable.sol

pragma solidity ^0.5.0;


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

// File: contracts/modules/claims/ClaimsData.sol

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

pragma solidity ^0.5.0;



contract ClaimsData is Iupgradable {
  using SafeMath for uint;

  struct Claim {
    uint coverId;
    uint dateUpd;
  }

  struct Vote {
    address voter;
    uint tokens;
    uint claimId;
    int8 verdict;
    bool rewardClaimed;
  }

  struct ClaimsPause {
    uint coverid;
    uint dateUpd;
    bool submit;
  }

  struct ClaimPauseVoting {
    uint claimid;
    uint pendingTime;
    bool voting;
  }

  struct RewardDistributed {
    uint lastCAvoteIndex;
    uint lastMVvoteIndex;

  }

  struct ClaimRewardDetails {
    uint percCA;
    uint percMV;
    uint tokenToBeDist;

  }

  struct ClaimTotalTokens {
    uint accept;
    uint deny;
  }

  struct ClaimRewardStatus {
    uint percCA;
    uint percMV;
  }

  ClaimRewardStatus[] internal rewardStatus;

  Claim[] internal allClaims;
  Vote[] internal allvotes;
  ClaimsPause[] internal claimPause;
  ClaimPauseVoting[] internal claimPauseVotingEP;

  mapping(address => RewardDistributed) internal voterVoteRewardReceived;
  mapping(uint => ClaimRewardDetails) internal claimRewardDetail;
  mapping(uint => ClaimTotalTokens) internal claimTokensCA;
  mapping(uint => ClaimTotalTokens) internal claimTokensMV;
  mapping(uint => int8) internal claimVote;
  mapping(uint => uint) internal claimsStatus;
  mapping(uint => uint) internal claimState12Count;
  mapping(uint => uint[]) internal claimVoteCA;
  mapping(uint => uint[]) internal claimVoteMember;
  mapping(address => uint[]) internal voteAddressCA;
  mapping(address => uint[]) internal voteAddressMember;
  mapping(address => uint[]) internal allClaimsByAddress;
  mapping(address => mapping(uint => uint)) internal userClaimVoteCA;
  mapping(address => mapping(uint => uint)) internal userClaimVoteMember;
  mapping(address => uint) public userClaimVotePausedOn;

  uint internal claimPauseLastsubmit;
  uint internal claimStartVotingFirstIndex;
  uint public pendingClaimStart;
  uint public claimDepositTime;
  uint public maxVotingTime;
  uint public minVotingTime;
  uint public payoutRetryTime;
  uint public claimRewardPerc;
  uint public minVoteThreshold;
  uint public maxVoteThreshold;
  uint public majorityConsensus;
  uint public pauseDaysCA;

  event ClaimRaise(
    uint indexed coverId,
    address indexed userAddress,
    uint claimId,
    uint dateSubmit
  );

  event VoteCast(
    address indexed userAddress,
    uint indexed claimId,
    bytes4 indexed typeOf,
    uint tokens,
    uint submitDate,
    int8 verdict
  );

  constructor() public {
    pendingClaimStart = 1;
    maxVotingTime = 48 * 1 hours;
    minVotingTime = 12 * 1 hours;
    payoutRetryTime = 24 * 1 hours;
    allvotes.push(Vote(address(0), 0, 0, 0, false));
    allClaims.push(Claim(0, 0));
    claimDepositTime = 7 days;
    claimRewardPerc = 20;
    minVoteThreshold = 5;
    maxVoteThreshold = 10;
    majorityConsensus = 70;
    pauseDaysCA = 3 days;
    _addRewardIncentive();
  }

  /**
   * @dev Updates the pending claim start variable,
   * the lowest claim id with a pending decision/payout.
   */
  function setpendingClaimStart(uint _start) external onlyInternal {
    require(pendingClaimStart <= _start);
    pendingClaimStart = _start;
  }

  /**
   * @dev Updates the max vote index for which claim assessor has received reward
   * @param _voter address of the voter.
   * @param caIndex last index till which reward was distributed for CA
   */
  function setRewardDistributedIndexCA(address _voter, uint caIndex) external onlyInternal {
    voterVoteRewardReceived[_voter].lastCAvoteIndex = caIndex;

  }

  /**
   * @dev Used to pause claim assessor activity for 3 days
   * @param user Member address whose claim voting ability needs to be paused
   */
  function setUserClaimVotePausedOn(address user) external {
    require(ms.checkIsAuthToGoverned(msg.sender));
    userClaimVotePausedOn[user] = now;
  }

  /**
   * @dev Updates the max vote index for which member has received reward
   * @param _voter address of the voter.
   * @param mvIndex last index till which reward was distributed for member
   */
  function setRewardDistributedIndexMV(address _voter, uint mvIndex) external onlyInternal {

    voterVoteRewardReceived[_voter].lastMVvoteIndex = mvIndex;
  }

  /**
   * @param claimid claim id.
   * @param percCA reward Percentage reward for claim assessor
   * @param percMV reward Percentage reward for members
   * @param tokens total tokens to be rewarded
   */
  function setClaimRewardDetail(
    uint claimid,
    uint percCA,
    uint percMV,
    uint tokens
  )
  external
  onlyInternal
  {
    claimRewardDetail[claimid].percCA = percCA;
    claimRewardDetail[claimid].percMV = percMV;
    claimRewardDetail[claimid].tokenToBeDist = tokens;
  }

  /**
   * @dev Sets the reward claim status against a vote id.
   * @param _voteid vote Id.
   * @param claimed true if reward for vote is claimed, else false.
   */
  function setRewardClaimed(uint _voteid, bool claimed) external onlyInternal {
    allvotes[_voteid].rewardClaimed = claimed;
  }

  /**
   * @dev Sets the final vote's result(either accepted or declined)of a claim.
   * @param _claimId Claim Id.
   * @param _verdict 1 if claim is accepted,-1 if declined.
   */
  function changeFinalVerdict(uint _claimId, int8 _verdict) external onlyInternal {
    claimVote[_claimId] = _verdict;
  }

  /**
   * @dev Creates a new claim.
   */
  function addClaim(
    uint _claimId,
    uint _coverId,
    address _from,
    uint _nowtime
  )
  external
  onlyInternal
  {
    allClaims.push(Claim(_coverId, _nowtime));
    allClaimsByAddress[_from].push(_claimId);
  }

  /**
   * @dev Add Vote's details of a given claim.
   */
  function addVote(
    address _voter,
    uint _tokens,
    uint claimId,
    int8 _verdict
  )
  external
  onlyInternal
  {
    allvotes.push(Vote(_voter, _tokens, claimId, _verdict, false));
  }

  /**
   * @dev Stores the id of the claim assessor vote given to a claim.
   * Maintains record of all votes given by all the CA to a claim.
   * @param _claimId Claim Id to which vote has given by the CA.
   * @param _voteid Vote Id.
   */
  function addClaimVoteCA(uint _claimId, uint _voteid) external onlyInternal {
    claimVoteCA[_claimId].push(_voteid);
  }

  /**
   * @dev Sets the id of the vote.
   * @param _from Claim assessor's address who has given the vote.
   * @param _claimId Claim Id for which vote has been given by the CA.
   * @param _voteid Vote Id which will be stored against the given _from and claimid.
   */
  function setUserClaimVoteCA(
    address _from,
    uint _claimId,
    uint _voteid
  )
  external
  onlyInternal
  {
    userClaimVoteCA[_from][_claimId] = _voteid;
    voteAddressCA[_from].push(_voteid);
  }

  /**
   * @dev Stores the tokens locked by the Claim Assessors during voting of a given claim.
   * @param _claimId Claim Id.
   * @param _vote 1 for accept and increases the tokens of claim as accept,
   * -1 for deny and increases the tokens of claim as deny.
   * @param _tokens Number of tokens.
   */
  function setClaimTokensCA(uint _claimId, int8 _vote, uint _tokens) external onlyInternal {
    if (_vote == 1)
      claimTokensCA[_claimId].accept = claimTokensCA[_claimId].accept.add(_tokens);
    if (_vote == - 1)
      claimTokensCA[_claimId].deny = claimTokensCA[_claimId].deny.add(_tokens);
  }

  /**
   * @dev Stores the tokens locked by the Members during voting of a given claim.
   * @param _claimId Claim Id.
   * @param _vote 1 for accept and increases the tokens of claim as accept,
   * -1 for deny and increases the tokens of claim as deny.
   * @param _tokens Number of tokens.
   */
  function setClaimTokensMV(uint _claimId, int8 _vote, uint _tokens) external onlyInternal {
    if (_vote == 1)
      claimTokensMV[_claimId].accept = claimTokensMV[_claimId].accept.add(_tokens);
    if (_vote == - 1)
      claimTokensMV[_claimId].deny = claimTokensMV[_claimId].deny.add(_tokens);
  }

  /**
   * @dev Stores the id of the member vote given to a claim.
   * Maintains record of all votes given by all the Members to a claim.
   * @param _claimId Claim Id to which vote has been given by the Member.
   * @param _voteid Vote Id.
   */
  function addClaimVotemember(uint _claimId, uint _voteid) external onlyInternal {
    claimVoteMember[_claimId].push(_voteid);
  }

  /**
   * @dev Sets the id of the vote.
   * @param _from Member's address who has given the vote.
   * @param _claimId Claim Id for which vote has been given by the Member.
   * @param _voteid Vote Id which will be stored against the given _from and claimid.
   */
  function setUserClaimVoteMember(
    address _from,
    uint _claimId,
    uint _voteid
  )
  external
  onlyInternal
  {
    userClaimVoteMember[_from][_claimId] = _voteid;
    voteAddressMember[_from].push(_voteid);

  }

  /**
   * @dev Increases the count of failure until payout of a claim is successful.
   */
  function updateState12Count(uint _claimId, uint _cnt) external onlyInternal {
    claimState12Count[_claimId] = claimState12Count[_claimId].add(_cnt);
  }

  /**
   * @dev Sets status of a claim.
   * @param _claimId Claim Id.
   * @param _stat Status number.
   */
  function setClaimStatus(uint _claimId, uint _stat) external onlyInternal {
    claimsStatus[_claimId] = _stat;
  }

  /**
   * @dev Sets the timestamp of a given claim at which the Claim's details has been updated.
   * @param _claimId Claim Id of claim which has been changed.
   * @param _dateUpd timestamp at which claim is updated.
   */
  function setClaimdateUpd(uint _claimId, uint _dateUpd) external onlyInternal {
    allClaims[_claimId].dateUpd = _dateUpd;
  }

  /**
   @dev Queues Claims during Emergency Pause.
   */
  function setClaimAtEmergencyPause(
    uint _coverId,
    uint _dateUpd,
    bool _submit
  )
  external
  onlyInternal
  {
    claimPause.push(ClaimsPause(_coverId, _dateUpd, _submit));
  }

  /**
   * @dev Set submission flag for Claims queued during emergency pause.
   * Set to true after EP is turned off and the claim is submitted .
   */
  function setClaimSubmittedAtEPTrue(uint _index, bool _submit) external onlyInternal {
    claimPause[_index].submit = _submit;
  }

  /**
   * @dev Sets the index from which claim needs to be
   * submitted when emergency pause is swithched off.
   */
  function setFirstClaimIndexToSubmitAfterEP(
    uint _firstClaimIndexToSubmit
  )
  external
  onlyInternal
  {
    claimPauseLastsubmit = _firstClaimIndexToSubmit;
  }

  /**
   * @dev Sets the pending vote duration for a claim in case of emergency pause.
   */
  function setPendingClaimDetails(
    uint _claimId,
    uint _pendingTime,
    bool _voting
  )
  external
  onlyInternal
  {
    claimPauseVotingEP.push(ClaimPauseVoting(_claimId, _pendingTime, _voting));
  }

  /**
   * @dev Sets voting flag true after claim is reopened for voting after emergency pause.
   */
  function setPendingClaimVoteStatus(uint _claimId, bool _vote) external onlyInternal {
    claimPauseVotingEP[_claimId].voting = _vote;
  }

  /**
   * @dev Sets the index from which claim needs to be
   * reopened when emergency pause is swithched off.
   */
  function setFirstClaimIndexToStartVotingAfterEP(
    uint _claimStartVotingFirstIndex
  )
  external
  onlyInternal
  {
    claimStartVotingFirstIndex = _claimStartVotingFirstIndex;
  }

  /**
   * @dev Calls Vote Event.
   */
  function callVoteEvent(
    address _userAddress,
    uint _claimId,
    bytes4 _typeOf,
    uint _tokens,
    uint _submitDate,
    int8 _verdict
  )
  external
  onlyInternal
  {
    emit VoteCast(
      _userAddress,
      _claimId,
      _typeOf,
      _tokens,
      _submitDate,
      _verdict
    );
  }

  /**
   * @dev Calls Claim Event.
   */
  function callClaimEvent(
    uint _coverId,
    address _userAddress,
    uint _claimId,
    uint _datesubmit
  )
  external
  onlyInternal
  {
    emit ClaimRaise(_coverId, _userAddress, _claimId, _datesubmit);
  }

  /**
   * @dev Gets Uint Parameters by parameter code
   * @param code whose details we want
   * @return string value of the parameter
   * @return associated amount (time or perc or value) to the code
   */
  function getUintParameters(bytes8 code) external view returns (bytes8 codeVal, uint val) {
    codeVal = code;
    if (code == "CAMAXVT") {
      val = maxVotingTime / (1 hours);

    } else if (code == "CAMINVT") {

      val = minVotingTime / (1 hours);

    } else if (code == "CAPRETRY") {

      val = payoutRetryTime / (1 hours);

    } else if (code == "CADEPT") {

      val = claimDepositTime / (1 days);

    } else if (code == "CAREWPER") {

      val = claimRewardPerc;

    } else if (code == "CAMINTH") {

      val = minVoteThreshold;

    } else if (code == "CAMAXTH") {

      val = maxVoteThreshold;

    } else if (code == "CACONPER") {

      val = majorityConsensus;

    } else if (code == "CAPAUSET") {
      val = pauseDaysCA / (1 days);
    }

  }

  /**
   * @dev Get claim queued during emergency pause by index.
   */
  function getClaimOfEmergencyPauseByIndex(
    uint _index
  )
  external
  view
  returns (
    uint coverId,
    uint dateUpd,
    bool submit
  )
  {
    coverId = claimPause[_index].coverid;
    dateUpd = claimPause[_index].dateUpd;
    submit = claimPause[_index].submit;
  }

  /**
   * @dev Gets the Claim's details of given claimid.
   */
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
  )
  {
    return (
    allClaims[_claimId].coverId,
    claimVote[_claimId],
    claimsStatus[_claimId],
    allClaims[_claimId].dateUpd,
    claimState12Count[_claimId]
    );
  }

  /**
   * @dev Gets the vote id of a given claim of a given Claim Assessor.
   */
  function getUserClaimVoteCA(
    address _add,
    uint _claimId
  )
  external
  view
  returns (uint idVote)
  {
    return userClaimVoteCA[_add][_claimId];
  }

  /**
   * @dev Gets the vote id of a given claim of a given member.
   */
  function getUserClaimVoteMember(
    address _add,
    uint _claimId
  )
  external
  view
  returns (uint idVote)
  {
    return userClaimVoteMember[_add][_claimId];
  }

  /**
   * @dev Gets the count of all votes.
   */
  function getAllVoteLength() external view returns (uint voteCount) {
    return allvotes.length.sub(1); // Start Index always from 1.
  }

  /**
   * @dev Gets the status number of a given claim.
   * @param _claimId Claim id.
   * @return statno Status Number.
   */
  function getClaimStatusNumber(uint _claimId) external view returns (uint claimId, uint statno) {
    return (_claimId, claimsStatus[_claimId]);
  }

  /**
   * @dev Gets the reward percentage to be distributed for a given status id
   * @param statusNumber the number of type of status
   * @return percCA reward Percentage for claim assessor
   * @return percMV reward Percentage for members
   */
  function getRewardStatus(uint statusNumber) external view returns (uint percCA, uint percMV) {
    return (rewardStatus[statusNumber].percCA, rewardStatus[statusNumber].percMV);
  }

  /**
   * @dev Gets the number of tries that have been made for a successful payout of a Claim.
   */
  function getClaimState12Count(uint _claimId) external view returns (uint num) {
    num = claimState12Count[_claimId];
  }

  /**
   * @dev Gets the last update date of a claim.
   */
  function getClaimDateUpd(uint _claimId) external view returns (uint dateupd) {
    dateupd = allClaims[_claimId].dateUpd;
  }

  /**
   * @dev Gets all Claims created by a user till date.
   * @param _member user's address.
   * @return claimarr List of Claims id.
   */
  function getAllClaimsByAddress(address _member) external view returns (uint[] memory claimarr) {
    return allClaimsByAddress[_member];
  }

  /**
   * @dev Gets the number of tokens that has been locked
   * while giving vote to a claim by  Claim Assessors.
   * @param _claimId Claim Id.
   * @return accept Total number of tokens when CA accepts the claim.
   * @return deny Total number of tokens when CA declines the claim.
   */
  function getClaimsTokenCA(
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint accept,
    uint deny
  )
  {
    return (
    _claimId,
    claimTokensCA[_claimId].accept,
    claimTokensCA[_claimId].deny
    );
  }

  /**
   * @dev Gets the number of tokens that have been
   * locked while assessing a claim as a member.
   * @param _claimId Claim Id.
   * @return accept Total number of tokens in acceptance of the claim.
   * @return deny Total number of tokens against the claim.
   */
  function getClaimsTokenMV(
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint accept,
    uint deny
  )
  {
    return (
    _claimId,
    claimTokensMV[_claimId].accept,
    claimTokensMV[_claimId].deny
    );
  }

  /**
   * @dev Gets the total number of votes cast as Claims assessor for/against a given claim
   */
  function getCaClaimVotesToken(uint _claimId) external view returns (uint claimId, uint cnt) {
    claimId = _claimId;
    cnt = 0;
    for (uint i = 0; i < claimVoteCA[_claimId].length; i++) {
      cnt = cnt.add(allvotes[claimVoteCA[_claimId][i]].tokens);
    }
  }

  /**
   * @dev Gets the total number of tokens cast as a member for/against a given claim
   */
  function getMemberClaimVotesToken(
    uint _claimId
  )
  external
  view
  returns (uint claimId, uint cnt)
  {
    claimId = _claimId;
    cnt = 0;
    for (uint i = 0; i < claimVoteMember[_claimId].length; i++) {
      cnt = cnt.add(allvotes[claimVoteMember[_claimId][i]].tokens);
    }
  }

  /**
   * @dev Provides information of a vote when given its vote id.
   * @param _voteid Vote Id.
   */
  function getVoteDetails(uint _voteid)
  external view
  returns (
    uint tokens,
    uint claimId,
    int8 verdict,
    bool rewardClaimed
  )
  {
    return (
    allvotes[_voteid].tokens,
    allvotes[_voteid].claimId,
    allvotes[_voteid].verdict,
    allvotes[_voteid].rewardClaimed
    );
  }

  /**
   * @dev Gets the voter's address of a given vote id.
   */
  function getVoterVote(uint _voteid) external view returns (address voter) {
    return allvotes[_voteid].voter;
  }

  /**
   * @dev Provides information of a Claim when given its claim id.
   * @param _claimId Claim Id.
   */
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
  )
  {
    return (
    _claimId,
    allClaims[_claimId].coverId,
    claimVote[_claimId],
    claimsStatus[_claimId],
    allClaims[_claimId].dateUpd,
    claimState12Count[_claimId]
    );
  }

  /**
   * @dev Gets the total number of votes of a given claim.
   * @param _claimId Claim Id.
   * @param _ca if 1: votes given by Claim Assessors to a claim,
   * else returns the number of votes of given by Members to a claim.
   * @return len total number of votes for/against a given claim.
   */
  function getClaimVoteLength(
    uint _claimId,
    uint8 _ca
  )
  external
  view
  returns (uint claimId, uint len)
  {
    claimId = _claimId;
    if (_ca == 1)
      len = claimVoteCA[_claimId].length;
    else
      len = claimVoteMember[_claimId].length;
  }

  /**
   * @dev Gets the verdict of a vote using claim id and index.
   * @param _ca 1 for vote given as a CA, else for vote given as a member.
   * @return ver 1 if vote was given in favour,-1 if given in against.
   */
  function getVoteVerdict(
    uint _claimId,
    uint _index,
    uint8 _ca
  )
  external
  view
  returns (int8 ver)
  {
    if (_ca == 1)
      ver = allvotes[claimVoteCA[_claimId][_index]].verdict;
    else
      ver = allvotes[claimVoteMember[_claimId][_index]].verdict;
  }

  /**
   * @dev Gets the Number of tokens of a vote using claim id and index.
   * @param _ca 1 for vote given as a CA, else for vote given as a member.
   * @return tok Number of tokens.
   */
  function getVoteToken(
    uint _claimId,
    uint _index,
    uint8 _ca
  )
  external
  view
  returns (uint tok)
  {
    if (_ca == 1)
      tok = allvotes[claimVoteCA[_claimId][_index]].tokens;
    else
      tok = allvotes[claimVoteMember[_claimId][_index]].tokens;
  }

  /**
   * @dev Gets the Voter's address of a vote using claim id and index.
   * @param _ca 1 for vote given as a CA, else for vote given as a member.
   * @return voter Voter's address.
   */
  function getVoteVoter(
    uint _claimId,
    uint _index,
    uint8 _ca
  )
  external
  view
  returns (address voter)
  {
    if (_ca == 1)
      voter = allvotes[claimVoteCA[_claimId][_index]].voter;
    else
      voter = allvotes[claimVoteMember[_claimId][_index]].voter;
  }

  /**
   * @dev Gets total number of Claims created by a user till date.
   * @param _add User's address.
   */
  function getUserClaimCount(address _add) external view returns (uint len) {
    len = allClaimsByAddress[_add].length;
  }

  /**
   * @dev Calculates number of Claims that are in pending state.
   */
  function getClaimLength() external view returns (uint len) {
    len = allClaims.length.sub(pendingClaimStart);
  }

  /**
   * @dev Gets the Number of all the Claims created till date.
   */
  function actualClaimLength() external view returns (uint len) {
    len = allClaims.length;
  }

  /**
   * @dev Gets details of a claim.
   * @param _index claim id = pending claim start + given index
   * @param _add User's address.
   * @return coverid cover against which claim has been submitted.
   * @return claimId Claim  Id.
   * @return voteCA verdict of vote given as a Claim Assessor.
   * @return voteMV verdict of vote given as a Member.
   * @return statusnumber Status of claim.
   */
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
  )
  {
    uint i = pendingClaimStart.add(_index);
    coverid = allClaims[i].coverId;
    claimId = i;
    if (userClaimVoteCA[_add][i] > 0)
      voteCA = allvotes[userClaimVoteCA[_add][i]].verdict;
    else
      voteCA = 0;

    if (userClaimVoteMember[_add][i] > 0)
      voteMV = allvotes[userClaimVoteMember[_add][i]].verdict;
    else
      voteMV = 0;

    statusnumber = claimsStatus[i];
  }

  /**
   * @dev Gets details of a claim of a user at a given index.
   */
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
  )
  {
    claimId = allClaimsByAddress[_add][_index];
    status = claimsStatus[claimId];
    coverid = allClaims[claimId].coverId;
  }

  /**
   * @dev Gets Id of all the votes given to a claim.
   * @param _claimId Claim Id.
   * @return ca id of all the votes given by Claim assessors to a claim.
   * @return mv id of all the votes given by members to a claim.
   */
  function getAllVotesForClaim(
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint[] memory ca,
    uint[] memory mv
  )
  {
    return (_claimId, claimVoteCA[_claimId], claimVoteMember[_claimId]);
  }

  /**
   * @dev Gets Number of tokens deposit in a vote using
   * Claim assessor's address and claim id.
   * @return tokens Number of deposited tokens.
   */
  function getTokensClaim(
    address _of,
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint tokens
  )
  {
    return (_claimId, allvotes[userClaimVoteCA[_of][_claimId]].tokens);
  }

  /**
   * @param _voter address of the voter.
   * @return lastCAvoteIndex last index till which reward was distributed for CA
   * @return lastMVvoteIndex last index till which reward was distributed for member
   */
  function getRewardDistributedIndex(
    address _voter
  )
  external
  view
  returns (
    uint lastCAvoteIndex,
    uint lastMVvoteIndex
  )
  {
    return (
    voterVoteRewardReceived[_voter].lastCAvoteIndex,
    voterVoteRewardReceived[_voter].lastMVvoteIndex
    );
  }

  /**
   * @param claimid claim id.
   * @return perc_CA reward Percentage for claim assessor
   * @return perc_MV reward Percentage for members
   * @return tokens total tokens to be rewarded
   */
  function getClaimRewardDetail(
    uint claimid
  )
  external
  view
  returns (
    uint percCA,
    uint percMV,
    uint tokens
  )
  {
    return (
    claimRewardDetail[claimid].percCA,
    claimRewardDetail[claimid].percMV,
    claimRewardDetail[claimid].tokenToBeDist
    );
  }

  /**
   * @dev Gets cover id of a claim.
   */
  function getClaimCoverId(uint _claimId) external view returns (uint claimId, uint coverid) {
    return (_claimId, allClaims[_claimId].coverId);
  }

  /**
   * @dev Gets total number of tokens staked during voting by Claim Assessors.
   * @param _claimId Claim Id.
   * @param _verdict 1 to get total number of accept tokens, -1 to get total number of deny tokens.
   * @return token token Number of tokens(either accept or deny on the basis of verdict given as parameter).
   */
  function getClaimVote(uint _claimId, int8 _verdict) external view returns (uint claimId, uint token) {
    claimId = _claimId;
    token = 0;
    for (uint i = 0; i < claimVoteCA[_claimId].length; i++) {
      if (allvotes[claimVoteCA[_claimId][i]].verdict == _verdict)
        token = token.add(allvotes[claimVoteCA[_claimId][i]].tokens);
    }
  }

  /**
   * @dev Gets total number of tokens staked during voting by Members.
   * @param _claimId Claim Id.
   * @param _verdict 1 to get total number of accept tokens,
   *  -1 to get total number of deny tokens.
   * @return token token Number of tokens(either accept or
   * deny on the basis of verdict given as parameter).
   */
  function getClaimMVote(uint _claimId, int8 _verdict) external view returns (uint claimId, uint token) {
    claimId = _claimId;
    token = 0;
    for (uint i = 0; i < claimVoteMember[_claimId].length; i++) {
      if (allvotes[claimVoteMember[_claimId][i]].verdict == _verdict)
        token = token.add(allvotes[claimVoteMember[_claimId][i]].tokens);
    }
  }

  /**
   * @param _voter address  of voteid
   * @param index index to get voteid in CA
   */
  function getVoteAddressCA(address _voter, uint index) external view returns (uint) {
    return voteAddressCA[_voter][index];
  }

  /**
   * @param _voter address  of voter
   * @param index index to get voteid in member vote
   */
  function getVoteAddressMember(address _voter, uint index) external view returns (uint) {
    return voteAddressMember[_voter][index];
  }

  /**
   * @param _voter address  of voter
   */
  function getVoteAddressCALength(address _voter) external view returns (uint) {
    return voteAddressCA[_voter].length;
  }

  /**
   * @param _voter address  of voter
   */
  function getVoteAddressMemberLength(address _voter) external view returns (uint) {
    return voteAddressMember[_voter].length;
  }

  /**
   * @dev Gets the Final result of voting of a claim.
   * @param _claimId Claim id.
   * @return verdict 1 if claim is accepted, -1 if declined.
   */
  function getFinalVerdict(uint _claimId) external view returns (int8 verdict) {
    return claimVote[_claimId];
  }

  /**
   * @dev Get number of Claims queued for submission during emergency pause.
   */
  function getLengthOfClaimSubmittedAtEP() external view returns (uint len) {
    len = claimPause.length;
  }

  /**
   * @dev Gets the index from which claim needs to be
   * submitted when emergency pause is swithched off.
   */
  function getFirstClaimIndexToSubmitAfterEP() external view returns (uint indexToSubmit) {
    indexToSubmit = claimPauseLastsubmit;
  }

  /**
   * @dev Gets number of Claims to be reopened for voting post emergency pause period.
   */
  function getLengthOfClaimVotingPause() external view returns (uint len) {
    len = claimPauseVotingEP.length;
  }

  /**
   * @dev Gets claim details to be reopened for voting after emergency pause.
   */
  function getPendingClaimDetailsByIndex(
    uint _index
  )
  external
  view
  returns (
    uint claimId,
    uint pendingTime,
    bool voting
  )
  {
    claimId = claimPauseVotingEP[_index].claimid;
    pendingTime = claimPauseVotingEP[_index].pendingTime;
    voting = claimPauseVotingEP[_index].voting;
  }

  /**
   * @dev Gets the index from which claim needs to be reopened when emergency pause is swithched off.
   */
  function getFirstClaimIndexToStartVotingAfterEP() external view returns (uint firstindex) {
    firstindex = claimStartVotingFirstIndex;
  }

  /**
   * @dev Updates Uint Parameters of a code
   * @param code whose details we want to update
   * @param val value to set
   */
  function updateUintParameters(bytes8 code, uint val) public {
    require(ms.checkIsAuthToGoverned(msg.sender));
    if (code == "CAMAXVT") {
      _setMaxVotingTime(val * 1 hours);

    } else if (code == "CAMINVT") {

      _setMinVotingTime(val * 1 hours);

    } else if (code == "CAPRETRY") {

      _setPayoutRetryTime(val * 1 hours);

    } else if (code == "CADEPT") {

      _setClaimDepositTime(val * 1 days);

    } else if (code == "CAREWPER") {

      _setClaimRewardPerc(val);

    } else if (code == "CAMINTH") {

      _setMinVoteThreshold(val);

    } else if (code == "CAMAXTH") {

      _setMaxVoteThreshold(val);

    } else if (code == "CACONPER") {

      _setMajorityConsensus(val);

    } else if (code == "CAPAUSET") {
      _setPauseDaysCA(val * 1 days);
    } else {

      revert("Invalid param code");
    }

  }

  /**
   * @dev Iupgradable Interface to update dependent contract address
   */
  function changeDependentContractAddress() public onlyInternal {}

  /**
   * @dev Adds status under which a claim can lie.
   * @param percCA reward percentage for claim assessor
   * @param percMV reward percentage for members
   */
  function _pushStatus(uint percCA, uint percMV) internal {
    rewardStatus.push(ClaimRewardStatus(percCA, percMV));
  }

  /**
   * @dev adds reward incentive for all possible claim status for Claim assessors and members
   */
  function _addRewardIncentive() internal {
    _pushStatus(0, 0); // 0  Pending-Claim Assessor Vote
    _pushStatus(0, 0); // 1 Pending-Claim Assessor Vote Denied, Pending Member Vote
    _pushStatus(0, 0); // 2 Pending-CA Vote Threshold not Reached Accept, Pending Member Vote
    _pushStatus(0, 0); // 3 Pending-CA Vote Threshold not Reached Deny, Pending Member Vote
    _pushStatus(0, 0); // 4 Pending-CA Consensus not reached Accept, Pending Member Vote
    _pushStatus(0, 0); // 5 Pending-CA Consensus not reached Deny, Pending Member Vote
    _pushStatus(100, 0); // 6 Final-Claim Assessor Vote Denied
    _pushStatus(100, 0); // 7 Final-Claim Assessor Vote Accepted
    _pushStatus(0, 100); // 8 Final-Claim Assessor Vote Denied, MV Accepted
    _pushStatus(0, 100); // 9 Final-Claim Assessor Vote Denied, MV Denied
    _pushStatus(0, 0); // 10 Final-Claim Assessor Vote Accept, MV Nodecision
    _pushStatus(0, 0); // 11 Final-Claim Assessor Vote Denied, MV Nodecision
    _pushStatus(0, 0); // 12 Claim Accepted Payout Pending
    _pushStatus(0, 0); // 13 Claim Accepted No Payout
    _pushStatus(0, 0); // 14 Claim Accepted Payout Done
  }

  /**
   * @dev Sets Maximum time(in seconds) for which claim assessment voting is open
   */
  function _setMaxVotingTime(uint _time) internal {
    maxVotingTime = _time;
  }

  /**
   *  @dev Sets Minimum time(in seconds) for which claim assessment voting is open
   */
  function _setMinVotingTime(uint _time) internal {
    minVotingTime = _time;
  }

  /**
   *  @dev Sets Minimum vote threshold required
   */
  function _setMinVoteThreshold(uint val) internal {
    minVoteThreshold = val;
  }

  /**
   *  @dev Sets Maximum vote threshold required
   */
  function _setMaxVoteThreshold(uint val) internal {
    maxVoteThreshold = val;
  }

  /**
   *  @dev Sets the value considered as Majority Consenus in voting
   */
  function _setMajorityConsensus(uint val) internal {
    majorityConsensus = val;
  }

  /**
   * @dev Sets the payout retry time
   */
  function _setPayoutRetryTime(uint _time) internal {
    payoutRetryTime = _time;
  }

  /**
   *  @dev Sets percentage of reward given for claim assessment
   */
  function _setClaimRewardPerc(uint _val) internal {

    claimRewardPerc = _val;
  }

  /**
   * @dev Sets the time for which claim is deposited.
   */
  function _setClaimDepositTime(uint _time) internal {

    claimDepositTime = _time;
  }

  /**
   *  @dev Sets number of days claim assessment will be paused
   */
  function _setPauseDaysCA(uint val) internal {
    pauseDaysCA = val;
  }
}