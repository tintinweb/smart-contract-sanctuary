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

import "../../abstract/Iupgradable.sol";
import "./external/Governed.sol";
import "../../interfaces/IMemberRoles.sol";
import "../../interfaces/IProposalCategory.sol";

contract ProposalCategory is Governed, IProposalCategory, Iupgradable {

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

  /**
  * @dev Adds new category (Discontinued, moved functionality to newCategory)
  * @param _name Category name
  * @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
  * @param _majorityVotePerc Majority Vote threshold for Each voting layer
  * @param _quorumPerc minimum threshold percentage required in voting to calculate result
  * @param _allowedToCreateProposal Member roles allowed to create the proposal
  * @param _closingTime Vote closing time for Each voting layer
  * @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
  * @param _contractAddress address of contract to call after proposal is accepted
  * @param _contractName name of contract to be called after proposal is accepted
  * @param _incentives rewards to distributed after proposal is accepted
  */
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
  ) external {}

  /**
  * @dev Initiates Default settings for Proposal Category contract (Adding default categories)
  */
  function proposalCategoryInitiate() external {}

  /**
  * @dev Initiates Default action function hashes for existing categories
  * To be called after the contract has been upgraded by governance
  */
  function updateCategoryActionHashes() external onlyOwner {

    require(!categoryActionHashUpdated, "Category action hashes already updated");
    categoryActionHashUpdated = true;
    categoryActionHashes[1] = abi.encodeWithSignature("addRole(bytes32,string,address)");
    categoryActionHashes[2] = abi.encodeWithSignature("updateRole(address,uint256,bool)");
    categoryActionHashes[3] = abi.encodeWithSignature("newCategory(string,uint256,uint256,uint256,uint256[],uint256,string,address,bytes2,uint256[],string)"); // solhint-disable-line
    categoryActionHashes[4] = abi.encodeWithSignature("editCategory(uint256,string,uint256,uint256,uint256,uint256[],uint256,string,address,bytes2,uint256[],string)"); // solhint-disable-line
    categoryActionHashes[5] = abi.encodeWithSignature("upgradeContractImplementation(bytes2,address)");
    categoryActionHashes[6] = abi.encodeWithSignature("startEmergencyPause()");
    categoryActionHashes[7] = abi.encodeWithSignature("addEmergencyPause(bool,bytes4)");
    categoryActionHashes[8] = abi.encodeWithSignature("burnCAToken(uint256,uint256,address)");
    categoryActionHashes[9] = abi.encodeWithSignature("setUserClaimVotePausedOn(address)");
    categoryActionHashes[12] = abi.encodeWithSignature("transferEther(uint256,address)");
    categoryActionHashes[13] = abi.encodeWithSignature("addInvestmentAssetCurrency(bytes4,address,bool,uint64,uint64,uint8)"); // solhint-disable-line
    categoryActionHashes[14] = abi.encodeWithSignature("changeInvestmentAssetHoldingPerc(bytes4,uint64,uint64)");
    categoryActionHashes[15] = abi.encodeWithSignature("changeInvestmentAssetStatus(bytes4,bool)");
    categoryActionHashes[16] = abi.encodeWithSignature("swapABMember(address,address)");
    categoryActionHashes[17] = abi.encodeWithSignature("addCurrencyAssetCurrency(bytes4,address,uint256)");
    categoryActionHashes[20] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
    categoryActionHashes[21] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
    categoryActionHashes[22] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
    categoryActionHashes[23] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
    categoryActionHashes[24] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
    categoryActionHashes[25] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
    categoryActionHashes[26] = abi.encodeWithSignature("updateUintParameters(bytes8,uint256)");
    categoryActionHashes[27] = abi.encodeWithSignature("updateAddressParameters(bytes8,address)");
    categoryActionHashes[28] = abi.encodeWithSignature("updateOwnerParameters(bytes8,address)");
    categoryActionHashes[29] = abi.encodeWithSignature("upgradeMultipleContracts(bytes2[],address[])");
    categoryActionHashes[30] = abi.encodeWithSignature("changeCurrencyAssetAddress(bytes4,address)");
    categoryActionHashes[31] = abi.encodeWithSignature("changeCurrencyAssetBaseMin(bytes4,uint256)");
    categoryActionHashes[32] = abi.encodeWithSignature("changeInvestmentAssetAddressAndDecimal(bytes4,address,uint8)"); // solhint-disable-line
    categoryActionHashes[33] = abi.encodeWithSignature("externalLiquidityTrade()");
  }

  /**
  * @dev Gets Total number of categories added till now
  */
  function totalCategories() external view returns (uint) {
    return allCategory.length;
  }

  /**
  * @dev Gets category details
  */
  function category(uint _categoryId) external view returns (uint, uint, uint, uint, uint[] memory, uint, uint) {
    return (
    _categoryId,
    allCategory[_categoryId].memberRoleToVote,
    allCategory[_categoryId].majorityVotePerc,
    allCategory[_categoryId].quorumPerc,
    allCategory[_categoryId].allowedToCreateProposal,
    allCategory[_categoryId].closingTime,
    allCategory[_categoryId].minStake
    );
  }

  /**
  * @dev Gets category ab required and isSpecialResolution
  * @return the category id
  * @return if AB voting is required
  * @return is category a special resolution
  */
  function categoryExtendedData(uint _categoryId) external view returns (uint, uint, uint) {
    return (
    _categoryId,
    categoryABReq[_categoryId],
    isSpecialResolution[_categoryId]
    );
  }

  /**
   * @dev Gets the category acion details
   * @param _categoryId is the category id in concern
   * @return the category id
   * @return the contract address
   * @return the contract name
   * @return the default incentive
   */
  function categoryAction(uint _categoryId) external view returns (uint, address, bytes2, uint) {

    return (
    _categoryId,
    categoryActionData[_categoryId].contractAddress,
    categoryActionData[_categoryId].contractName,
    categoryActionData[_categoryId].defaultIncentive
    );
  }

  /**
   * @dev Gets the category acion details of a category id
   * @param _categoryId is the category id in concern
   * @return the category id
   * @return the contract address
   * @return the contract name
   * @return the default incentive
   * @return action function hash
   */
  function categoryActionDetails(uint _categoryId) external view returns (uint, address, bytes2, uint, bytes memory) {
    return (
    _categoryId,
    categoryActionData[_categoryId].contractAddress,
    categoryActionData[_categoryId].contractName,
    categoryActionData[_categoryId].defaultIncentive,
    categoryActionHashes[_categoryId]
    );
  }

  /**
  * @dev Updates dependant contract addresses
  */
  function changeDependentContractAddress() public {
    mr = IMemberRoles(ms.getLatestAddress("MR"));
  }

  /**
  * @dev Adds new category
  * @param _name Category name
  * @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
  * @param _majorityVotePerc Majority Vote threshold for Each voting layer
  * @param _quorumPerc minimum threshold percentage required in voting to calculate result
  * @param _allowedToCreateProposal Member roles allowed to create the proposal
  * @param _closingTime Vote closing time for Each voting layer
  * @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
  * @param _contractAddress address of contract to call after proposal is accepted
  * @param _contractName name of contract to be called after proposal is accepted
  * @param _incentives rewards to distributed after proposal is accepted
  * @param _functionHash function signature to be executed
  */
  function newCategory(
    string memory _name,
    uint _memberRoleToVote,
    uint _majorityVotePerc,
    uint _quorumPerc,
    uint[] memory _allowedToCreateProposal,
    uint _closingTime,
    string memory _actionHash,
    address _contractAddress,
    bytes2 _contractName,
    uint[] memory _incentives,
    string memory _functionHash
  )
  public
  onlyAuthorizedToGovern
  {

    require(_quorumPerc <= 100 && _majorityVotePerc <= 100, "Invalid percentage");

    require((_contractName == "EX" && _contractAddress == address(0)) || bytes(_functionHash).length > 0);

    require(_incentives[3] <= 1, "Invalid special resolution flag");

    //If category is special resolution role authorized should be member
    if (_incentives[3] == 1) {
      require(_memberRoleToVote == uint(IMemberRoles.Role.Member));
      _majorityVotePerc = 0;
      _quorumPerc = 0;
    }

    _addCategory(
      _name,
      _memberRoleToVote,
      _majorityVotePerc,
      _quorumPerc,
      _allowedToCreateProposal,
      _closingTime,
      _actionHash,
      _contractAddress,
      _contractName,
      _incentives
    );


    if (bytes(_functionHash).length > 0 && abi.encodeWithSignature(_functionHash).length == 4) {
      categoryActionHashes[allCategory.length - 1] = abi.encodeWithSignature(_functionHash);
    }
  }

  /**
   * @dev Changes the master address and update it's instance
   * @param _masterAddress is the new master address
   */
  function changeMasterAddress(address _masterAddress) public {
    if (masterAddress != address(0))
      require(masterAddress == msg.sender);
    masterAddress = _masterAddress;
    ms = INXMMaster(_masterAddress);
    nxMasterAddress = _masterAddress;

  }

  /**
  * @dev Updates category details (Discontinued, moved functionality to editCategory)
  * @param _categoryId Category id that needs to be updated
  * @param _name Category name
  * @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
  * @param _allowedToCreateProposal Member roles allowed to create the proposal
  * @param _majorityVotePerc Majority Vote threshold for Each voting layer
  * @param _quorumPerc minimum threshold percentage required in voting to calculate result
  * @param _closingTime Vote closing time for Each voting layer
  * @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
  * @param _contractAddress address of contract to call after proposal is accepted
  * @param _contractName name of contract to be called after proposal is accepted
  * @param _incentives rewards to distributed after proposal is accepted
  */
  function updateCategory(
    uint _categoryId,
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
  ) public {}

  /**
  * @dev Updates category details
  * @param _categoryId Category id that needs to be updated
  * @param _name Category name
  * @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
  * @param _allowedToCreateProposal Member roles allowed to create the proposal
  * @param _majorityVotePerc Majority Vote threshold for Each voting layer
  * @param _quorumPerc minimum threshold percentage required in voting to calculate result
  * @param _closingTime Vote closing time for Each voting layer
  * @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
  * @param _contractAddress address of contract to call after proposal is accepted
  * @param _contractName name of contract to be called after proposal is accepted
  * @param _incentives rewards to distributed after proposal is accepted
  * @param _functionHash function signature to be executed
  */
  function editCategory(
    uint _categoryId,
    string memory _name,
    uint _memberRoleToVote,
    uint _majorityVotePerc,
    uint _quorumPerc,
    uint[] memory _allowedToCreateProposal,
    uint _closingTime,
    string memory _actionHash,
    address _contractAddress,
    bytes2 _contractName,
    uint[] memory _incentives,
    string memory _functionHash
  )
  public
  onlyAuthorizedToGovern
  {
    require(_verifyMemberRoles(_memberRoleToVote, _allowedToCreateProposal) == 1, "Invalid Role");

    require(_quorumPerc <= 100 && _majorityVotePerc <= 100, "Invalid percentage");

    require((_contractName == "EX" && _contractAddress == address(0)) || bytes(_functionHash).length > 0);

    require(_incentives[3] <= 1, "Invalid special resolution flag");

    //If category is special resolution role authorized should be member
    if (_incentives[3] == 1) {
      require(_memberRoleToVote == uint(IMemberRoles.Role.Member));
      _majorityVotePerc = 0;
      _quorumPerc = 0;
    }

    delete categoryActionHashes[_categoryId];
    if (bytes(_functionHash).length > 0 && abi.encodeWithSignature(_functionHash).length == 4) {
      categoryActionHashes[_categoryId] = abi.encodeWithSignature(_functionHash);
    }
    allCategory[_categoryId].memberRoleToVote = _memberRoleToVote;
    allCategory[_categoryId].majorityVotePerc = _majorityVotePerc;
    allCategory[_categoryId].closingTime = _closingTime;
    allCategory[_categoryId].allowedToCreateProposal = _allowedToCreateProposal;
    allCategory[_categoryId].minStake = _incentives[0];
    allCategory[_categoryId].quorumPerc = _quorumPerc;
    categoryActionData[_categoryId].defaultIncentive = _incentives[1];
    categoryActionData[_categoryId].contractName = _contractName;
    categoryActionData[_categoryId].contractAddress = _contractAddress;
    categoryABReq[_categoryId] = _incentives[2];
    isSpecialResolution[_categoryId] = _incentives[3];
    emit Category(_categoryId, _name, _actionHash);
  }

  /**
  * @dev Internal call to add new category
  * @param _name Category name
  * @param _memberRoleToVote Voting Layer sequence in which the voting has to be performed.
  * @param _majorityVotePerc Majority Vote threshold for Each voting layer
  * @param _quorumPerc minimum threshold percentage required in voting to calculate result
  * @param _allowedToCreateProposal Member roles allowed to create the proposal
  * @param _closingTime Vote closing time for Each voting layer
  * @param _actionHash hash of details containing the action that has to be performed after proposal is accepted
  * @param _contractAddress address of contract to call after proposal is accepted
  * @param _contractName name of contract to be called after proposal is accepted
  * @param _incentives rewards to distributed after proposal is accepted
  */
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

  /**
  * @dev Internal call to check if given roles are valid or not
  */
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

