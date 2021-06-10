/**
 *Submitted for verification at Etherscan.io on 2021-06-10
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

// File: contracts/interfaces/INXMMaster.sol

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

// File: contracts/interfaces/ITokenController.sol

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

// File: contracts/interfaces/IMemberRoles.sol

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

// File: contracts/interfaces/IGovernance.sol

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

// File: contracts/interfaces/IProposalCategory.sol

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

// File: contracts/mocks/Disposables/DisposableGovernance.sol

pragma solidity ^0.5.0;

/*
 * Due to the bytecode size limit on the Governance contract,
 * we don't inherit it but just copy the state variables here instead
 * to allow a safe upgrade from the disposable to the normal contract
 */







contract DisposableGovernance is IGovernance, Iupgradable {

  /* disposable initialization function */

  // mainnet param values added in comments
  function initialize(
    uint _tokenHoldingTime, // 3 days
    uint _maxDraftTime, // 14 days
    uint _maxVoteWeigthPer, // 5
    uint _maxFollowers, // 40
    uint _specialResolutionMajPerc, // 75
    uint _actionWaitingTime // 1 day
  ) external {

    require(!constructorCheck);
    constructorCheck = true;

    totalProposals = 1;
    allVotes.push(ProposalVote(address(0), 0, 0));
    allDelegation.push(DelegateVote(address(0), address(0), now));
    roleIdAllowedToCatgorize = uint(IMemberRoles.Role.AdvisoryBoard);

    tokenHoldingTime = _tokenHoldingTime;
    maxDraftTime = _maxDraftTime;
    maxVoteWeigthPer = _maxVoteWeigthPer;
    maxFollowers = _maxFollowers;
    specialResolutionMajPerc = _specialResolutionMajPerc;
    actionWaitingTime = _actionWaitingTime;
  }

  /* structs used in state variables */

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

  /* copied state variables */

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

  function changeDependentContractAddress() public {
    tokenInstance = ITokenController(ms.dAppLocker());
    memberRole = IMemberRoles(ms.getLatestAddress("MR"));
    proposalCategory = IProposalCategory(ms.getLatestAddress("PC"));
  }

  /* function required for Iupgradable and IGovernance implementation */

  function createProposal(string calldata, string calldata, string calldata, uint) external {}

  function updateProposal(uint, string calldata, string calldata, string calldata) external {}

  function categorizeProposal(uint, uint, uint) external {}

  function submitProposalWithSolution(uint, string calldata, bytes calldata) external {}

  function createProposalwithSolution(string calldata, string calldata, string calldata, uint, string calldata, bytes calldata) external {}

  function submitVote(uint, uint) external {}

  function closeProposal(uint) external {}

  function claimReward(address, uint) external returns (uint) {return 0;}

  function proposal(uint) external view returns (uint, uint, uint, uint, uint) {return (0, 0, 0, 0, 0);}

  function canCloseProposal(uint) public view returns (uint) {return 0;}

  function allowedToCatgorize() public view returns (uint) {return 0;}

  function removeDelegation(address _add) external {}
}