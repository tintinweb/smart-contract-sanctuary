// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.5.0;

import "../../modules/governance/NXMaster.sol";

contract DisposableNXMaster is NXMaster {

  function initialize(
    address _owner,
    address _tokenAddress,
    address _emergencyAdmin,
    bytes2[] calldata _contractNames,
    uint8[] calldata _contractTypes, // 0 - eternal storage, 1 - "upgradable", 2 - proxy
    address payable[] calldata _contractAddresses
  ) external {

    require(!masterInitialized, "!init");
    masterInitialized = true;

    owner = _owner;
    tokenAddress = _tokenAddress;
    emergencyAdmin = _emergencyAdmin;

    masterAddress = address(this);
    contractsActive[address(this)] = true;

    require(
      _contractNames.length == _contractTypes.length,
      "check names & types arrays length"
    );

    for (uint i = 0; i < _contractNames.length; i++) {

      bytes2 name = _contractNames[i];
      address payable contractAddress = _contractAddresses[i];

      contractCodes.push(name);
      contractAddresses[name] = contractAddress;
      contractsActive[contractAddress] = true;

      if (_contractTypes[i] == 1) {
        isReplaceable[name] = true;
      } else if (_contractTypes[i] == 2) {
        isProxy[name] = true;
      }
    }
  }

  function switchGovernanceAddress(address payable newGV) external {

    {// change governance address
      address currentGV = contractAddresses["GV"];
      contractAddresses["GV"] = newGV;
      contractsActive[currentGV] = false;
      contractsActive[newGV] = true;
    }

    // notify all contracts about address change
    for (uint i = 0; i < contractCodes.length; i++) {
      address _address = contractAddresses[contractCodes[i]];
      IMasterAware up = IMasterAware(_address);
      up.changeMasterAddress(address(this));
      up.changeDependentContractAddress();
    }
  }

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../abstract/MasterAware.sol";
import "../../interfaces/IMasterAware.sol";
import "../../interfaces/ILegacyClaims.sol";
import "../../interfaces/ILegacyClaimsData.sol";
import "../../interfaces/ILegacyClaimsReward.sol";
import "../../interfaces/IMemberRoles.sol";
import "../../interfaces/IPool.sol";
import "../../interfaces/IQuotation.sol";
import "../../interfaces/IQuotationData.sol";
import "../../interfaces/ITokenController.sol";
import "../../interfaces/ITokenData.sol";
import "./external/Governed.sol";
import "./external/OwnedUpgradeabilityProxy.sol";

contract NXMaster is INXMMaster, Governed {
  using SafeMath for uint;

  uint public _unused0;

  bytes2[] public contractCodes;
  mapping(address => bool) public contractsActive;
  mapping(bytes2 => address payable) public contractAddresses;
  mapping(bytes2 => bool) public isProxy;
  mapping(bytes2 => bool) public isReplaceable;

  address public tokenAddress;
  bool internal reentrancyLock;
  bool public masterInitialized;
  address public owner;
  uint public _unused1;

  address public emergencyAdmin;
  bool public paused;

  enum ContractType { Undefined, Replaceable, Proxy }

  event InternalContractAdded(bytes2 indexed code, address contractAddress, ContractType indexed contractType);
  event ContractUpgraded(bytes2 indexed code, address newAddress, address previousAddress, ContractType indexed contractType);
  event ContractRemoved(bytes2 indexed code, address contractAddress);
  event PauseConfigured(bool paused);


  function initializeEmergencyAdmin() external {
    if (emergencyAdmin == address(0)) {
      emergencyAdmin = 0x422D71fb8040aBEF53f3a05d21A9B85eebB2995D;
    }
  }

  modifier noReentrancy() {
    require(!reentrancyLock, "Reentrant call.");
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

  modifier onlyEmergencyAdmin() {
    require(msg.sender == emergencyAdmin, "NXMaster: Not emergencyAdmin");
    _;
  }

  function addNewInternalContracts(
    bytes2[] calldata newContractCodes,
    address payable[] calldata newAddresses,
    uint[] calldata _types
  )
  external
  onlyAuthorizedToGovern
  {
    require(newContractCodes.length == newAddresses.length, "NXMaster: newContractCodes.length != newAddresses.length.");
    require(newContractCodes.length == _types.length, "NXMaster: newContractCodes.length != _types.length");
    for (uint i = 0; i < newContractCodes.length; i++) {
      addNewInternalContract(newContractCodes[i], newAddresses[i], _types[i]);
    }
  }

  /// @dev Adds new internal contract
  /// @param contractCode contract code for new contract
  /// @param contractAddress contract address for new contract
  /// @param _type pass 1 if contract is replaceable, 2 if contract is proxy
  function addNewInternalContract(
    bytes2 contractCode,
    address payable contractAddress,
    uint _type
  ) internal {

    require(contractAddresses[contractCode] == address(0), "NXMaster: Code already in use");
    require(contractAddress != address(0), "NXMaster: Contract address is 0");

    contractCodes.push(contractCode);

    address newInternalContract;
    if (_type == uint(ContractType.Replaceable)) {

      newInternalContract = contractAddress;
      isReplaceable[contractCode] = true;
    } else if (_type == uint(ContractType.Proxy)) {

      newInternalContract = address(new OwnedUpgradeabilityProxy(contractAddress));
      isProxy[contractCode] = true;
    } else {
      revert("NXMaster: Unsupported contract type");
    }

    contractAddresses[contractCode] = address(uint160(newInternalContract));
    contractsActive[newInternalContract] = true;

    IMasterAware up = IMasterAware(newInternalContract);
    up.changeMasterAddress(address(this));
    up.changeDependentContractAddress();

    emit InternalContractAdded(contractCode, contractAddress, ContractType(_type));
  }

  /// @dev upgrades multiple contracts at a time
  function upgradeMultipleContracts(
    bytes2[] calldata _contractCodes,
    address payable[] calldata newAddresses
  )
  external
  onlyAuthorizedToGovern
  {
    require(_contractCodes.length == newAddresses.length, "NXMaster: _contractCodes.length != newAddresses.length");

    for (uint i = 0; i < _contractCodes.length; i++) {
      address payable newAddress = newAddresses[i];
      bytes2 code = _contractCodes[i];
      require(newAddress != address(0), "NXMaster: Contract address is 0");

      if (isProxy[code]) {
        OwnedUpgradeabilityProxy proxy = OwnedUpgradeabilityProxy(contractAddresses[code]);
        address previousAddress = proxy.implementation();
        proxy.upgradeTo(newAddress);
        emit ContractUpgraded(code, newAddress, previousAddress, ContractType.Proxy);
        continue;
      }

      if (isReplaceable[code]) {
        address previousAddress = getLatestAddress(code);
        replaceContract(code, newAddress);
        emit ContractUpgraded(code, newAddress, previousAddress, ContractType.Replaceable);
        continue;
      }

      revert("NXMaster: Non-existant or non-upgradeable contract code");
    }

    updateAllDependencies();
  }

  function replaceContract(bytes2 code, address payable newAddress) internal {
    if (code == "CR") {
      ITokenController tc = ITokenController(getLatestAddress("TC"));
      tc.addToWhitelist(newAddress);
      tc.removeFromWhitelist(contractAddresses["CR"]);
      ILegacyClaimsReward cr = ILegacyClaimsReward(contractAddresses["CR"]);
      cr.upgrade(newAddress);

    } else if (code == "P1") {
      IPool p1 = IPool(contractAddresses["P1"]);
      p1.upgradeCapitalPool(newAddress);
    }

    address payable oldAddress = contractAddresses[code];
    contractsActive[oldAddress] = false;
    contractAddresses[code] = newAddress;
    contractsActive[newAddress] = true;

    IMasterAware up = IMasterAware(contractAddresses[code]);
    up.changeMasterAddress(address(this));
  }

  function removeContracts(bytes2[] calldata contractCodesToRemove)
  external
  onlyAuthorizedToGovern
  {

    for (uint i = 0; i < contractCodesToRemove.length; i++) {
      bytes2 code = contractCodesToRemove[i];
      address contractAddress = contractAddresses[code];
      require(contractAddress != address(0), "NXMaster: Address is 0");
      require(isInternal(contractAddress), "NXMaster: Contract not internal");
      contractsActive[contractAddress] = false;
      contractAddresses[code] = address(0);

      if (isProxy[code]) {
        isProxy[code] = false;
      }

      if (isReplaceable[code]) {
        isReplaceable[code] = false;
      }
      emit ContractRemoved(code, contractAddress);
    }

    // delete elements from contractCodes
    for (uint i = 0; i < contractCodes.length; i++) {
      for (uint j = 0; j < contractCodesToRemove.length; j++) {
        if (contractCodes[i] == contractCodesToRemove[j]) {
          contractCodes[i] = contractCodes[contractCodes.length - 1];
          contractCodes.pop();
          i = i == 0 ? 0 : i - 1;
        }
      }
    }

    updateAllDependencies();
  }

  function updateAllDependencies() internal {
    for (uint i = 0; i < contractCodes.length; i++) {
      IMasterAware up = IMasterAware(contractAddresses[contractCodes[i]]);
      up.changeDependentContractAddress();
    }
  }

  /**
   * @dev set Emergency pause
   * @param _paused to toggle emergency pause ON/OFF
   */
  function setEmergencyPause(bool _paused) public onlyEmergencyAdmin {
    paused = _paused;
    emit PauseConfigured(_paused);
  }

  /// @dev checks whether the address is an internal contract address.
  function isInternal(address _contractAddress) public view returns (bool) {
    return contractsActive[_contractAddress];
  }

  /// @dev checks whether the address is the Owner or not.
  function isOwner(address _address) public view returns (bool) {
    return owner == _address;
  }

  /// @dev Checks whether emergency pause is on/not.
  function isPause() public view returns (bool) {
    return paused;
  }

  /// @dev checks whether the address is a member of the mutual or not.
  function isMember(address _add) public view returns (bool) {
    IMemberRoles mr = IMemberRoles(getLatestAddress("MR"));
    return mr.checkRole(_add, uint(IMemberRoles.Role.Member));
  }

  /// @dev Gets current contract codes and their addresses
  /// @return contractCodes
  /// @return contractAddresses
  function getInternalContracts()
  public
  view
  returns (
    bytes2[] memory _contractCodes,
    address[] memory _contractAddresses
  )
  {
    _contractCodes = contractCodes;
    _contractAddresses = new address[](contractCodes.length);

    for (uint i = 0; i < _contractCodes.length; i++) {
      _contractAddresses[i] = contractAddresses[contractCodes[i]];
    }
  }

  /**
   * @dev returns the address of token controller
   * @return address is returned
   */
  function dAppLocker() public view returns (address) {
    return getLatestAddress("TC");
  }

  /// @dev Gets latest contract address
  /// @param _contractName Contract name to fetch
  function getLatestAddress(bytes2 _contractName) public view returns (address payable contractAddress) {
    contractAddress = contractAddresses[_contractName];
  }

  /**
   * @dev to check if the address is authorized to govern or not
   * @param _add is the address in concern
   * @return the boolean status status for the check
   */
  function checkIsAuthToGoverned(address _add) public view returns (bool) {
    return isAuthorizedToGovern(_add);
  }

  /**
   * @dev to update the owner parameters
   * @param code is the associated code
   * @param val is value to be set
   */
  function updateOwnerParameters(bytes8 code, address payable val) public onlyAuthorizedToGovern {
    IQuotationData qd;
    if (code == "MSWALLET") {

      ITokenData td;
      td = ITokenData(getLatestAddress("TD"));
      td.changeWalletAddress(val);

    } else if (code == "OWNER") {

      IMemberRoles mr = IMemberRoles(getLatestAddress("MR"));
      mr.swapOwner(val);
      owner = val;

    } else if (code == "QUOAUTH") {

      qd = IQuotationData(getLatestAddress("QD"));
      qd.changeAuthQuoteEngine(val);

    } else if (code == "KYCAUTH") {

      qd = IQuotationData(getLatestAddress("QD"));
      qd.setKycAuthAddress(val);

    } else if (code == "EMADMIN") {

      emergencyAdmin = val;

    } else {
      revert("Invalid param code");
    }
  }
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

import "../interfaces/INXMMaster.sol";

contract MasterAware {

  INXMMaster public master;

  modifier onlyMember {
    require(master.isMember(msg.sender), "Caller is not a member");
    _;
  }

  modifier onlyInternal {
    require(master.isInternal(msg.sender), "Caller is not an internal contract");
    _;
  }

  modifier onlyMaster {
    if (address(master) != address(0)) {
      require(address(master) == msg.sender, "Not master");
    }
    _;
  }

  modifier onlyGovernance {
    require(
      master.checkIsAuthToGoverned(msg.sender),
      "Caller is not authorized to govern"
    );
    _;
  }

  modifier whenPaused {
    require(master.isPause(), "System is not paused");
    _;
  }

  modifier whenNotPaused {
    require(!master.isPause(), "System is paused");
    _;
  }

  function changeMasterAddress(address masterAddress) public onlyMaster {
    master = INXMMaster(masterAddress);
  }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IMasterAware {

  function changeMasterAddress(address masterAddress) external;

  function changeDependentContractAddress() external;

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface ILegacyClaims {

  function setClaimStatus(uint claimId, uint stat) external;

  function getCATokens(uint claimId, uint member) external view returns (uint tokens);

  function submitClaimAfterEPOff() external pure;

  function submitCAVote(uint claimId, int8 verdict) external;

  function submitMemberVote(uint claimId, int8 verdict) external;

  function pauseAllPendingClaimsVoting() external pure;

  function startAllPendingClaimsVoting() external pure;

  function checkVoteClosing(uint claimId) external view returns (int8 close);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface ILegacyClaimsData {

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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface ILegacyClaimsReward {

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

  function getAllPendingRewardOfUser(address _add) external view returns (uint);

  function unlockCoverNote(uint coverId) external;
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

import "./IPriceFeedOracle.sol";

interface IPool {

  struct SwapDetails {
    uint104 minAmount;
    uint104 maxAmount;
    uint32 lastSwapTime;
    // 2 decimals of precision. 0.01% -> 0.0001 -> 1e14
    uint16 maxSlippageRatio;
  }

  struct Asset {
    address assetAddress;
    uint8 decimals;
    bool deprecated;
  }

  function assets(uint index) external view returns (
    address assetAddress,
    uint8 decimals,
    bool deprecated
  );

  function buyNXM(uint minTokensOut) external payable;

  function sellNXM(uint tokenAmount, uint minEthOut) external;

  function sellNXMTokens(uint tokenAmount) external returns (bool);

  function minPoolEth() external returns (uint);

  function transferAssetToSwapOperator(address asset, uint amount) external;

  function setSwapDetailsLastSwapTime(address asset, uint32 lastSwapTime) external;

  function getAssets() external view returns (
    address[] memory assetAddresses,
    uint8[] memory decimals,
    bool[] memory deprecated
  );

  function getAssetSwapDetails(address assetAddress) external view returns (
    uint104 min,
    uint104 max,
    uint32 lastAssetSwapTime,
    uint16 maxSlippageRatio
  );

  function getNXMForEth(uint ethAmount) external view returns (uint);

  function sendPayout (
    uint assetIndex,
    address payable payoutAddress,
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

  function getTokenPrice(uint assetId) external view returns (uint tokenPrice);

  function getMCRRatio() external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IQuotation {
  function verifyCoverDetails(
    address payable from,
    address scAddress,
    bytes4 coverCurr,
    uint[] calldata coverDetails,
    uint16 coverPeriod,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;

  function createCover(
    address payable from,
    address scAddress,
    bytes4 currency,
    uint[] calldata coverDetails,
    uint16 coverPeriod,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;
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

pragma solidity ^0.5.0;

import "./UpgradeabilityProxy.sol";

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {
  /**
  * @dev Event to show ownership has been transferred
  * @param previousOwner representing the address of the previous owner
  * @param newOwner representing the address of the new owner
  */
  event ProxyOwnershipTransferred(address previousOwner, address newOwner);

  // Storage position of the owner of the contract
  bytes32 private constant PROXY_OWNER_POSITION = keccak256("org.govblocks.proxy.owner");

  /**
  * @dev the constructor sets the original owner of the contract to the sender account.
  */
  constructor(address _implementation) public {
    _setUpgradeabilityOwner(msg.sender);
    _upgradeTo(_implementation);
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner());
    _;
  }

  /**
  * @dev Tells the address of the owner
  * @return the address of the owner
  */
  function proxyOwner() public view returns (address owner) {
    bytes32 position = PROXY_OWNER_POSITION;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      owner := sload(position)
    }
  }

  /**
  * @dev Allows the current owner to transfer control of the contract to a newOwner.
  * @param _newOwner The address to transfer ownership to.
  */
  function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
    require(_newOwner != address(0));
    _setUpgradeabilityOwner(_newOwner);
    emit ProxyOwnershipTransferred(proxyOwner(), _newOwner);
  }

  /**
  * @dev Allows the proxy owner to upgrade the current version of the proxy.
  * @param _implementation representing the address of the new implementation to be set.
  */
  function upgradeTo(address _implementation) public onlyProxyOwner {
    _upgradeTo(_implementation);
  }

  /**
   * @dev Sets the address of the owner
  */
  function _setUpgradeabilityOwner(address _newProxyOwner) internal {
    bytes32 position = PROXY_OWNER_POSITION;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(position, _newProxyOwner)
    }
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IPriceFeedOracle {

  function daiAddress() external view returns (address);
  function stETH() external view returns (address);
  function ETH() external view returns (address);

  function getAssetToEthRate(address asset) external view returns (uint);
  function getAssetForEth(address asset, uint ethIn) external view returns (uint);

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

pragma solidity ^0.5.0;

import "./Proxy.sol";

/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {
  /**
  * @dev This event will be emitted every time the implementation gets upgraded
  * @param implementation representing the address of the upgraded implementation
  */
  event Upgraded(address indexed implementation);

  // Storage position of the address of the current implementation
  bytes32 private constant IMPLEMENTATION_POSITION = keccak256("org.govblocks.proxy.implementation");

  /**
  * @dev Constructor function
  */
  // solhint-disable-next-line no-empty-blocks
  constructor() public {}

  /**
  * @dev Tells the address of the current implementation
  * @return address of the current implementation
  */
  function implementation() public view returns (address impl) {
    bytes32 position = IMPLEMENTATION_POSITION;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      impl := sload(position)
    }
  }

  /**
  * @dev Sets the address of the current implementation
  * @param _newImplementation address representing the new implementation to be set
  */
  function _setImplementation(address _newImplementation) internal {
    bytes32 position = IMPLEMENTATION_POSITION;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(position, _newImplementation)
    }
  }

  /**
  * @dev Upgrades the implementation address
  * @param _newImplementation representing the address of the new implementation to be set
  */
  function _upgradeTo(address _newImplementation) internal {
    address currentImplementation = implementation();
    require(currentImplementation != _newImplementation);
    _setImplementation(_newImplementation);
    emit Upgraded(_newImplementation);
  }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.5.0;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy {

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  // solhint-disable-next-line no-complex-fallback
  function() external payable {
    address _impl = implementation();
    require(_impl != address(0));

    // solhint-disable-next-line no-inline-assembly
    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize)
      let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
      let size := returndatasize
      returndatacopy(ptr, 0, size)

      switch result
      case 0 {revert(ptr, size)}
      default {return (ptr, size)}
    }
  }

  /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * @return address of the implementation to which it will be delegated
  */
  function implementation() public view returns (address);
}