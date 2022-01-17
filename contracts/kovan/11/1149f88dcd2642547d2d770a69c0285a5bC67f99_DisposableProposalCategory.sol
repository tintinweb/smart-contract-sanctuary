// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.5.0;

import "../../interfaces/IMemberRoles.sol";
import "../../interfaces/IProposalCategory.sol";
import "../../abstract/LegacyMasterAware.sol";
import "../../modules/governance/external/Governed.sol";

contract DisposableProposalCategory is Governed, LegacyMasterAware {
  bool public constructorCheck;
  IMemberRoles internal mr;

  struct CategoryStruct {
    uint memberRoleToVote;
    uint majorityVotePerc;
    uint quorumPerc;
    uint[] allowedToCreateProposal;
    uint closingTime;
    uint minStake;
  }

  struct CategoryAction {
    uint defaultIncentive;
    address contractAddress;
    bytes2 contractName;
  }

  CategoryStruct[] internal allCategory;
  mapping(uint => CategoryAction) internal categoryActionData;
  mapping(uint => uint) public categoryABReq;
  mapping(uint => uint) public isSpecialResolution;
  mapping(uint => bytes) public categoryActionHashes;

  bool public categoryActionHashUpdated;

  function initialize(address _memberRolesAddress) external {

    require(!constructorCheck);
    constructorCheck = true;
    categoryActionHashUpdated = true;

    mr = IMemberRoles(_memberRolesAddress);
  }

  function _verifyMemberRoles(uint _memberRoleToVote, uint[] memory _allowedToCreateProposal)
  internal view returns (uint) {
    uint totalRoles = mr.totalRoles();
    if (_memberRoleToVote >= totalRoles) {
      return 0;
    }
    for (uint i = 0; i < _allowedToCreateProposal.length; i++) {
      if (_allowedToCreateProposal[i] >= totalRoles) {
        return 0;
      }
    }
    return 1;
  }

  function _addCategory(
    string memory _name,
    uint _memberRoleToVote,
    uint _majorityVotePerc,
    uint _quorumPerc,
    uint[] memory _allowedToCreateProposal,
    uint _closingTime,
    string memory _actionHash,
    address _contractAddress,
    bytes2 _contractName,
    uint[] memory _incentives
  )
  internal
  {
    require(_verifyMemberRoles(_memberRoleToVote, _allowedToCreateProposal) == 1, "Invalid Role");
    allCategory.push(
      CategoryStruct(
        _memberRoleToVote,
        _majorityVotePerc,
        _quorumPerc,
        _allowedToCreateProposal,
        _closingTime,
        _incentives[0]
      )
    );
    uint categoryId = allCategory.length - 1;
    categoryActionData[categoryId] = CategoryAction(_incentives[1], _contractAddress, _contractName);
    categoryABReq[categoryId] = _incentives[2];
    isSpecialResolution[categoryId] = _incentives[3];
    emit Category(categoryId, _name, _actionHash);
  }

  function addInitialCategory (
    string memory name,
    uint memberRoleToVote,
    uint majorityVotePerc,
    uint quorumPerc,
    uint[] memory allowedToCreateProposal,
    uint closingTime,
    string memory actionIpfsHash,
    address contractAddress,
    bytes2 contractName,
    uint[] memory stakeIncentive,
    string memory functionHash
  ) public {

    _addCategory(
      name,
      memberRoleToVote,
      majorityVotePerc,
      quorumPerc,
      allowedToCreateProposal,
      closingTime,
      actionIpfsHash,
      contractAddress,
      contractName,
      stakeIncentive
    );

    if (bytes(functionHash).length > 0 && abi.encodeWithSignature(functionHash).length == 4) {
      categoryActionHashes[allCategory.length - 1] = abi.encodeWithSignature(functionHash);
    }
  }

  function changeMasterAddress(address _masterAddress) public {
    if (masterAddress != address(0))
      require(masterAddress == msg.sender);
    masterAddress = _masterAddress;
    ms = INXMMaster(_masterAddress);
    nxMasterAddress = _masterAddress;

  }

  /**
  * @dev Updates dependant contract addresses
  */
  function changeDependentContractAddress() public {
    mr = IMemberRoles(ms.getLatestAddress("MR"));
  }


  event Category(
    uint indexed categoryId,
    string categoryName,
    string actionHash
  );

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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

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
  function changeMasterAddress(address _masterAddress) public {
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