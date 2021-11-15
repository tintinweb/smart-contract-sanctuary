// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "../../interfaces/IStore.sol";
import "../../interfaces/ICoverAssurance.sol";
import "../../libraries/ProtoUtilV1.sol";
import "../../libraries/CoverUtilV1.sol";
import "../../libraries/ValidationLibV1.sol";
import "../../libraries/StoreKeyUtil.sol";
import "../../libraries/NTransferUtilV2.sol";
import "../Recoverable.sol";

/**
 * @title Cover Assurance
 * @dev Assurance tokens can be added by a covered project to demonstrate coverage support
 * for their project. This helps bring the cover fee down and enhances
 * liquidity provider confidence. Along with the NEP tokens, the assurance tokens are rewarded
 * as a support to the liquidity providers when a cover incident occurs.
 *
 * Without negatively affecting the price much,
 * the protocol will gradually convert the assurance tokens
 * to stablecoin liquidity.
 */
contract CoverAssurance is ICoverAssurance, Recoverable {
  using ProtoUtilV1 for bytes;
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using NTransferUtilV2 for IERC20;
  using CoverUtilV1 for IStore;
  using ValidationLibV1 for IStore;

  constructor(IStore store) Recoverable(store) {
    this;
  }

  /**
   * @dev Adds assurance to the specified cover contract
   * @param key Enter the cover key
   * @param amount Enter the amount you would like to supply
   */
  function addAssurance(
    bytes32 key,
    address account,
    uint256 amount
  ) external override nonReentrant {
    _mustBeUnpaused();
    s.mustBeValidCoverKey(key);

    require(amount > 0, "Provide valid amount");

    IERC20 assuranceToken = IERC20(s.getAddressByKeys(ProtoUtilV1.NS_COVER_ASSURANCE_TOKEN, key));
    address vault = s.getAssuranceVault();

    s.addUintByKeys(ProtoUtilV1.NS_COVER_ASSURANCE, key, amount);

    assuranceToken.ensureTransferFrom(account, vault, amount);

    emit AssuranceAdded(key, amount);
  }

  function setWeight(bytes32 key, uint256 weight) external override nonReentrant {
    _mustBeOwnerOrProtoOwner();
    _mustBeUnpaused();
    s.mustBeValidCoverKey(key);

    s.setUintByKeys(ProtoUtilV1.NS_COVER_ASSURANCE_WEIGHT, key, weight);
  }

  /**
   * @dev Gets the assurance amount of the specified cover contract
   * @param key Enter the cover key
   */
  function getAssurance(bytes32 key) external view override returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_ASSURANCE, key);
  }

  /**
   * @dev Version number of this contract
   */
  function version() external pure override returns (bytes32) {
    return "v0.1";
  }

  /**
   * @dev Name of this contract
   */
  function getName() public pure override returns (bytes32) {
    return ProtoUtilV1.CNAME_COVER_ASSURANCE;
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;

interface IStore {
  function setAddress(bytes32 k, address v) external;

  function setUint(bytes32 k, uint256 v) external;

  function addUint(bytes32 k, uint256 v) external;

  function subtractUint(bytes32 k, uint256 v) external;

  function setUints(bytes32 k, uint256[] memory v) external;

  function setString(bytes32 k, string calldata v) external;

  function setBytes(bytes32 k, bytes calldata v) external;

  function setBool(bytes32 k, bool v) external;

  function setInt(bytes32 k, int256 v) external;

  function setBytes32(bytes32 k, bytes32 v) external;

  function deleteAddress(bytes32 k) external;

  function deleteUint(bytes32 k) external;

  function deleteUints(bytes32 k) external;

  function deleteString(bytes32 k) external;

  function deleteBytes(bytes32 k) external;

  function deleteBool(bytes32 k) external;

  function deleteInt(bytes32 k) external;

  function deleteBytes32(bytes32 k) external;

  function getAddress(bytes32 k) external view returns (address);

  function getUint(bytes32 k) external view returns (uint256);

  function getUints(bytes32 k) external view returns (uint256[] memory);

  function getString(bytes32 k) external view returns (string memory);

  function getBytes(bytes32 k) external view returns (bytes memory);

  function getBool(bytes32 k) external view returns (bool);

  function getInt(bytes32 k) external view returns (int256);

  function getBytes32(bytes32 k) external view returns (bytes32);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "./IMember.sol";

interface ICoverAssurance is IMember {
  event AssuranceAdded(bytes32 key, uint256 amount);

  /**
   * @dev Adds assurance to the specified cover contract
   * @param key Enter the cover key
   * @param amount Enter the amount you would like to supply
   */
  function addAssurance(
    bytes32 key,
    address account,
    uint256 amount
  ) external;

  function setWeight(bytes32 key, uint256 weight) external;

  /**
   * @dev Gets the assurance amount of the specified cover contract
   * @param key Enter the cover key
   */
  function getAssurance(bytes32 key) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "../interfaces/IStore.sol";
import "../interfaces/IProtocol.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./StoreKeyUtil.sol";

library ProtoUtilV1 {
  using StoreKeyUtil for IStore;

  // Namespaces
  bytes32 public constant NS_ASSURANCE_VAULT = "proto:core:assurance:vault";
  bytes32 public constant NS_BURNER = "proto:core:burner";
  bytes32 public constant NS_CONTRACTS = "proto:contracts";
  bytes32 public constant NS_MEMBERS = "proto:members";
  bytes32 public constant NS_CORE = "proto:core";
  bytes32 public constant NS_COVER = "proto:cover";
  bytes32 public constant NS_GOVERNANCE = "proto:governance";
  bytes32 public constant NS_CLAIMS_PROCESSOR = "proto:claims:processor";
  bytes32 public constant NS_COVER_ASSURANCE = "proto:cover:assurance";
  bytes32 public constant NS_COVER_ASSURANCE_TOKEN = "proto:cover:assurance:token";
  bytes32 public constant NS_COVER_ASSURANCE_WEIGHT = "proto:cover:assurance:weight";
  bytes32 public constant NS_COVER_CLAIMABLE = "proto:cover:claimable";
  bytes32 public constant NS_COVER_FEE = "proto:cover:fee";
  bytes32 public constant NS_COVER_INFO = "proto:cover:info";
  bytes32 public constant NS_COVER_LIQUIDITY = "proto:cover:liquidity";
  bytes32 public constant NS_COVER_LIQUIDITY_COMMITTED = "proto:cover:liquidity:committed";
  bytes32 public constant NS_COVER_LIQUIDITY_NAME = "proto:cover:liquidityName";
  bytes32 public constant NS_COVER_LIQUIDITY_TOKEN = "proto:cover:liquidityToken";
  bytes32 public constant NS_COVER_LIQUIDITY_RELEASE_DATE = "proto:cover:liquidity:release";
  bytes32 public constant NS_COVER_OWNER = "proto:cover:owner";
  bytes32 public constant NS_COVER_POLICY = "proto:cover:policy";
  bytes32 public constant NS_COVER_POLICY_ADMIN = "proto:cover:policy:admin";
  bytes32 public constant NS_COVER_POLICY_MANAGER = "proto:cover:policy:manager";
  bytes32 public constant NS_COVER_POLICY_RATE_FLOOR = "proto:cover:policy:rate:floor";
  bytes32 public constant NS_COVER_POLICY_RATE_CEILING = "proto:cover:policy:rate:ceiling";
  bytes32 public constant NS_COVER_PROVISION = "proto:cover:provision";
  bytes32 public constant NS_COVER_STAKE = "proto:cover:stake";
  bytes32 public constant NS_COVER_STAKE_OWNED = "proto:cover:stake:owned";
  bytes32 public constant NS_COVER_STATUS = "proto:cover:status";
  bytes32 public constant NS_COVER_VAULT = "proto:cover:vault";
  bytes32 public constant NS_COVER_VAULT_FACTORY = "proto:cover:vault:factory";
  bytes32 public constant NS_COVER_CTOKEN = "proto:cover:ctoken";
  bytes32 public constant NS_COVER_CTOKEN_FACTORY = "proto:cover:ctoken:factory";
  bytes32 public constant NS_TREASURY = "proto:core:treasury";
  bytes32 public constant NS_PRICE_DISCOVERY = "proto:core:price:discovery";

  bytes32 public constant NS_REPORTING_PERIOD = "proto:reporting:period";
  bytes32 public constant NS_REPORTING_INCIDENT_DATE = "proto:reporting:incident:date";
  bytes32 public constant NS_RESOLUTION_TS = "proto:reporting:resolution:ts";
  bytes32 public constant NS_CLAIM_EXPIRY_TS = "proto:claim:expiry:ts";
  bytes32 public constant NS_REPORTING_WITNESS_YES = "proto:reporting:witness:yes";
  bytes32 public constant NS_REPORTING_WITNESS_NO = "proto:reporting:witness:no";
  bytes32 public constant NS_REPORTING_STAKE_OWNED_YES = "proto:reporting:stake:owned:yes";
  bytes32 public constant NS_REPORTING_STAKE_OWNED_NO = "proto:reporting:stake:owned:no";

  bytes32 public constant NS_SETUP_NEP = "proto:setup:nep";
  bytes32 public constant NS_SETUP_COVER_FEE = "proto:setup:cover:fee";
  bytes32 public constant NS_SETUP_MIN_STAKE = "proto:setup:min:stake";
  bytes32 public constant NS_SETUP_REPORTING_STAKE = "proto:setup:reporting:stake";
  bytes32 public constant NS_SETUP_MIN_LIQ_PERIOD = "proto:setup:min:liq:period";
  bytes32 public constant NS_SETUP_CLAIM_PERIOD = "proto:setup:claim:period";

  // Contract names
  bytes32 public constant CNAME_PROTOCOL = "Protocol";
  bytes32 public constant CNAME_TREASURY = "Treasury";
  bytes32 public constant CNAME_POLICY = "Policy";
  bytes32 public constant CNAME_POLICY_ADMIN = "PolicyAdmin";
  bytes32 public constant CNAME_POLICY_MANAGER = "PolicyManager";
  bytes32 public constant CNAME_CLAIMS_PROCESSOR = "ClaimsProcessor";
  bytes32 public constant CNAME_PRICE_DISCOVERY = "PriceDiscovery";
  bytes32 public constant CNAME_COVER = "Cover";
  bytes32 public constant CNAME_GOVERNANCE = "Governance";
  bytes32 public constant CNAME_VAULT_FACTORY = "VaultFactory";
  bytes32 public constant CNAME_CTOKEN_FACTORY = "cTokenFactory";
  bytes32 public constant CNAME_COVER_PROVISION = "CoverProvison";
  bytes32 public constant CNAME_COVER_STAKE = "CoverStake";
  bytes32 public constant CNAME_COVER_ASSURANCE = "CoverAssurance";
  bytes32 public constant CNAME_LIQUIDITY_VAULT = "Vault";

  function getProtocol(IStore s) external view returns (IProtocol) {
    return IProtocol(getProtocolAddress(s));
  }

  function getProtocolAddress(IStore s) public view returns (address) {
    return s.getAddressByKey(NS_CORE);
  }

  function getCoverFee(IStore s) external view returns (uint256 fee, uint256 minStake) {
    fee = s.getUintByKey(NS_SETUP_COVER_FEE);
    minStake = s.getUintByKey(NS_SETUP_MIN_STAKE);
  }

  function getMinCoverStake(IStore s) external view returns (uint256) {
    return s.getUintByKey(NS_SETUP_MIN_STAKE);
  }

  function getMinLiquidityPeriod(IStore s) external view returns (uint256) {
    return s.getUintByKey(NS_SETUP_MIN_LIQ_PERIOD);
  }

  function getContract(IStore s, bytes32 name) external view returns (address) {
    return _getContract(s, name);
  }

  function isProtocolMember(IStore s, address contractAddress) external view returns (bool) {
    return _isProtocolMember(s, contractAddress);
  }

  /**
   * @dev Reverts if the caller is one of the protocol members.
   */
  function mustBeProtocolMember(IStore s, address contractAddress) external view {
    bool isMember = _isProtocolMember(s, contractAddress);
    require(isMember, "Not a protocol member");
  }

  /**
   * @dev Ensures that the sender matches with the exact contract having the specified name.
   * @param name Enter the name of the contract
   * @param sender Enter the `msg.sender` value
   */
  function mustBeExactContract(
    IStore s,
    bytes32 name,
    address sender
  ) public view {
    address contractAddress = _getContract(s, name);
    require(sender == contractAddress, "Access denied");
  }

  /**
   * @dev Ensures that the sender matches with the exact contract having the specified name.
   * @param name Enter the name of the contract
   */
  function callerMustBeExactContract(IStore s, bytes32 name) external view {
    return mustBeExactContract(s, name, msg.sender);
  }

  function nepToken(IStore s) external view returns (IERC20) {
    address nep = s.getAddressByKey(NS_SETUP_NEP);
    return IERC20(nep);
  }

  function getTreasury(IStore s) external view returns (address) {
    return s.getAddressByKey(NS_TREASURY);
  }

  function getAssuranceVault(IStore s) external view returns (address) {
    return s.getAddressByKey(NS_ASSURANCE_VAULT);
  }

  function getLiquidityToken(IStore s) public view returns (address) {
    return s.getAddressByKey(NS_COVER_LIQUIDITY_TOKEN);
  }

  function getBurnAddress(IStore s) external view returns (address) {
    return s.getAddressByKey(NS_BURNER);
  }

  function toKeccak256(bytes memory value) external pure returns (bytes32) {
    return keccak256(value);
  }

  function _isProtocolMember(IStore s, address contractAddress) private view returns (bool) {
    return s.getBoolByKeys(ProtoUtilV1.NS_MEMBERS, contractAddress);
  }

  function _getContract(IStore s, bytes32 name) private view returns (address) {
    return s.getAddressByKeys(NS_CONTRACTS, name);
  }

  function addContract(
    IStore s,
    bytes32 namespace,
    address contractAddress
  ) external {
    _addContract(s, namespace, contractAddress);
  }

  function _addContract(
    IStore s,
    bytes32 namespace,
    address contractAddress
  ) private {
    s.setAddressByKeys(ProtoUtilV1.NS_CONTRACTS, namespace, contractAddress);
    _addMember(s, contractAddress);
  }

  function deleteContract(
    IStore s,
    bytes32 namespace,
    address contractAddress
  ) external {
    _deleteContract(s, namespace, contractAddress);
  }

  function _deleteContract(
    IStore s,
    bytes32 namespace,
    address contractAddress
  ) private {
    s.deleteAddressByKeys(ProtoUtilV1.NS_CONTRACTS, namespace);
    _removeMember(s, contractAddress);
  }

  function upgradeContract(
    IStore s,
    bytes32 namespace,
    address previous,
    address current
  ) external {
    bool isMember = _isProtocolMember(s, previous);
    require(isMember, "Not a protocol member");

    _deleteContract(s, namespace, previous);
    _addContract(s, namespace, current);
  }

  function addMember(IStore s, address member) external {
    _addMember(s, member);
  }

  function removeMember(IStore s, address member) external {
    _removeMember(s, member);
  }

  function _addMember(IStore s, address member) private {
    require(s.getBoolByKeys(ProtoUtilV1.NS_MEMBERS, member) == false, "Already exists");
    s.setBoolByKeys(ProtoUtilV1.NS_MEMBERS, member, true);
  }

  function _removeMember(IStore s, address member) private {
    s.deleteBoolByKeys(ProtoUtilV1.NS_MEMBERS, member);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "../interfaces/IStore.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./ProtoUtilV1.sol";
import "./StoreKeyUtil.sol";
import "./RegistryLibV1.sol";

library CoverUtilV1 {
  using RegistryLibV1 for IStore;
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;

  enum CoverStatus {
    Normal,
    Stopped,
    IncidentHappened,
    FalseReporting,
    Claimable
  }

  function getCoverOwner(IStore s, bytes32 key) external view returns (address) {
    return _getCoverOwner(s, key);
  }

  function _getCoverOwner(IStore s, bytes32 key) private view returns (address) {
    return s.getAddressByKeys(ProtoUtilV1.NS_COVER_OWNER, key);
  }

  function getReportingPeriod(IStore s, bytes32 key) external view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_REPORTING_PERIOD, key);
  }

  function getClaimPeriod(IStore s) external view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_SETUP_CLAIM_PERIOD);
  }

  function getResolutionTimestamp(IStore s, bytes32 key) external view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_RESOLUTION_TS, key);
  }

  /**
   * @dev Gets the current status of a given cover
   *
   * 0 - normal
   * 1 - stopped, can not purchase covers or add liquidity
   * 2 - reporting, incident happened
   * 3 - reporting, false reporting
   * 4 - claimable, claims accepted for payout
   *
   */
  function getReportingStatus(IStore s, bytes32 key) public view returns (CoverStatus) {
    return CoverStatus(getStatus(s, key));
  }

  /**
   * @dev Todo: Returns the values of the given cover key
   * @param _values[0] The total amount in the cover pool
   * @param _values[1] The total commitment amount
   * @param _values[2] The total amount of NEP provision
   * @param _values[3] NEP price
   * @param _values[4] The total amount of assurance tokens
   * @param _values[5] Assurance token price
   * @param _values[6] Assurance pool weight
   */
  function getCoverPoolSummary(IStore s, bytes32 key) external view returns (uint256[] memory _values) {
    require(getReportingStatus(s, key) == CoverStatus.Normal, "Invalid cover");
    IPriceDiscovery discovery = s.getPriceDiscoveryContract();

    _values = new uint256[](7);

    _values[0] = s.getUintByKeys(ProtoUtilV1.NS_COVER_LIQUIDITY, key);
    _values[1] = s.getUintByKeys(ProtoUtilV1.NS_COVER_LIQUIDITY_COMMITTED, key); // <-- Todo: liquidity commitment should expire as policies expire
    _values[2] = s.getUintByKeys(ProtoUtilV1.NS_COVER_PROVISION, key);
    _values[3] = discovery.getTokenPriceInLiquidityToken(address(s.nepToken()), s.getLiquidityToken(), 1 ether);
    _values[4] = s.getUintByKeys(ProtoUtilV1.NS_COVER_ASSURANCE, key);
    _values[5] = discovery.getTokenPriceInLiquidityToken(address(s.getAddressByKeys(ProtoUtilV1.NS_COVER_ASSURANCE_TOKEN, key)), s.getLiquidityToken(), 1 ether);
    _values[6] = s.getUintByKeys(ProtoUtilV1.NS_COVER_ASSURANCE_WEIGHT, key);
  }

  function getPolicyRates(IStore s, bytes32 key) external view returns (uint256 floor, uint256 ceiling) {
    floor = s.getUintByKeys(ProtoUtilV1.NS_COVER_POLICY_RATE_FLOOR, key);
    ceiling = s.getUintByKeys(ProtoUtilV1.NS_COVER_POLICY_RATE_CEILING, key);

    if (floor == 0) {
      // Fallback to default values
      floor = s.getUintByKey(ProtoUtilV1.NS_COVER_POLICY_RATE_FLOOR);
      ceiling = s.getUintByKey(ProtoUtilV1.NS_COVER_POLICY_RATE_CEILING);
    }
  }

  function getLiquidity(IStore s, bytes32 key) public view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_LIQUIDITY, key);
  }

  function getStake(IStore s, bytes32 key) public view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_STAKE, key);
  }

  function getClaimable(IStore s, bytes32 key) external view returns (uint256) {
    return _getClaimable(s, key);
  }

  function getCoverInfo(IStore s, bytes32 key)
    external
    view
    returns (
      address owner,
      bytes32 info,
      uint256[] memory values
    )
  {
    info = s.getBytes32ByKeys(ProtoUtilV1.NS_COVER_INFO, key);
    owner = s.getAddressByKeys(ProtoUtilV1.NS_COVER_OWNER, key);

    values = new uint256[](5);

    values[0] = s.getUintByKeys(ProtoUtilV1.NS_COVER_FEE, key);
    values[1] = s.getUintByKeys(ProtoUtilV1.NS_COVER_STAKE, key);
    values[2] = s.getUintByKeys(ProtoUtilV1.NS_COVER_LIQUIDITY, key);
    values[3] = s.getUintByKeys(ProtoUtilV1.NS_COVER_PROVISION, key);

    values[4] = _getClaimable(s, key);
  }

  /**
   * @dev Sets the current status of a given cover
   *
   * 0 - normal
   * 1 - stopped, can not purchase covers or add liquidity
   * 2 - reporting, incident happened
   * 3 - reporting, false reporting
   * 4 - claimable, claims accepted for payout
   *
   */
  function setStatus(
    IStore s,
    bytes32 key,
    CoverStatus status
  ) external {
    s.setUintByKeys(ProtoUtilV1.NS_COVER_STATUS, key, uint256(status));
  }

  function _getClaimable(IStore s, bytes32 key) private view returns (uint256) {
    // Todo: deduct the expired cover amounts
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_CLAIMABLE, key);
  }

  function getStatus(IStore s, bytes32 key) public view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_STATUS, key);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity >=0.4.22 <0.9.0;
import "../interfaces/IStore.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./ProtoUtilV1.sol";
import "./StoreKeyUtil.sol";
import "./RegistryLibV1.sol";
import "./CoverUtilV1.sol";
import "./GovernanceUtilV1.sol";
import "../interfaces/ICToken.sol";

library ValidationLibV1 {
  using RegistryLibV1 for IStore;
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using CoverUtilV1 for IStore;
  using GovernanceUtilV1 for IStore;

  /*********************************************************************************************
    _______ ______    ________ ______
    |      |     |\  / |______|_____/
    |_____ |_____| \/  |______|    \_
                                  
   *********************************************************************************************/

  /**
   * @dev Reverts if the key does not resolve in a valid cover contract
   * or if the cover is under governance.
   * @param key Enter the cover key to check
   */
  function mustBeValidCover(IStore s, bytes32 key) public view {
    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER, key), "Cover does not exist");
    require(s.getReportingStatus(key) == CoverUtilV1.CoverStatus.Normal, "Actively Reporting");
  }

  /**
   * @dev Reverts if the key does not resolve in a valid cover contract.
   * @param key Enter the cover key to check
   */
  function mustBeValidCoverKey(IStore s, bytes32 key) public view {
    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER, key), "Cover does not exist");
  }

  /**
   * @dev Reverts if the sender is not the cover owner or owner
   * @param key Enter the cover key to check
   * @param sender The `msg.sender` value
   * @param owner Enter the owner address
   */
  function mustBeCoverOwner(
    IStore s,
    bytes32 key,
    address sender,
    address owner
  ) public view {
    bool isCoverOwner = s.getCoverOwner(key) == sender;
    bool isOwner = sender == owner;

    require(isOwner || isCoverOwner, "Forbidden");
  }

  function callerMustBePolicyContract(IStore s) external view {
    s.callerMustBeExactContract(ProtoUtilV1.NS_COVER_POLICY);
  }

  function callerMustBePolicyManagerContract(IStore s) external view {
    s.callerMustBeExactContract(ProtoUtilV1.NS_COVER_POLICY_MANAGER);
  }

  function callerMustBeCoverContract(IStore s) external view {
    s.callerMustBeExactContract(ProtoUtilV1.NS_COVER);
  }

  function callerMustBeGovernanceContract(IStore s) external view {
    s.callerMustBeExactContract(ProtoUtilV1.NS_GOVERNANCE);
  }

  function callerMustBeClaimsProcessorContract(IStore s) external view {
    s.callerMustBeExactContract(ProtoUtilV1.NS_CLAIMS_PROCESSOR);
  }

  /*********************************************************************************************
   ______  _____  _    _ _______  ______ __   _ _______ __   _ _______ _______
  |  ____ |     |  \  /  |______ |_____/ | \  | |_____| | \  | |       |______
  |_____| |_____|   \/   |______ |    \_ |  \_| |     | |  \_| |_____  |______

  *********************************************************************************************/

  function mustBeReporting(IStore s, bytes32 key) public view {
    require(s.getReportingStatus(key) == CoverUtilV1.CoverStatus.IncidentHappened, "Not reporting");
  }

  function mustBeDisputed(IStore s, bytes32 key) public view {
    require(s.getReportingStatus(key) == CoverUtilV1.CoverStatus.FalseReporting, "Not disputed");
  }

  function mustBeReportingOrDisputed(IStore s, bytes32 key) public view {
    CoverUtilV1.CoverStatus status = s.getReportingStatus(key);
    bool incidentHappened = status == CoverUtilV1.CoverStatus.IncidentHappened;
    bool falseReporting = status == CoverUtilV1.CoverStatus.FalseReporting;

    require(incidentHappened || falseReporting, "Not reporting or disputed");
  }

  function mustBeValidIncidentDate(
    IStore s,
    bytes32 key,
    uint256 incidentDate
  ) public view {
    require(s.getLatestIncidentDate(key) == incidentDate, "Invalid incident date");
  }

  function mustNotHaveDispute(IStore s, bytes32 key) public view {
    address reporter = s.getAddressByKeys(ProtoUtilV1.NS_REPORTING_WITNESS_NO, key);
    require(reporter == address(0), "Already disputed");
  }

  function mustBeDuringReportingPeriod(IStore s, bytes32 key) public view {
    require(s.getUintByKeys(ProtoUtilV1.NS_RESOLUTION_TS, key) >= block.timestamp, "Reporting window closed"); // solhint-disable-line
  }

  function mustBeAfterReportingPeriod(IStore s, bytes32 key) public view {
    require(block.timestamp > s.getUintByKeys(ProtoUtilV1.NS_RESOLUTION_TS, key), "Reporting still active"); // solhint-disable-line
  }

  function mustBeValidCToken(
    bytes32 key,
    address cToken,
    uint256 incidentDate
  ) public view {
    bytes32 coverKey = ICToken(cToken).coverKey();
    require(coverKey == key, "Invalid cToken");

    uint256 expires = ICToken(cToken).expiresOn();
    require(expires > incidentDate, "Invalid or expired cToken");
  }

  function mustBeValidClaim(
    IStore s,
    bytes32 key,
    address cToken,
    uint256 incidentDate
  ) public view {
    require(s.getReportingStatus(key) == CoverUtilV1.CoverStatus.IncidentHappened, "Your claim is denied");

    s.mustBeProtocolMember(cToken);
    mustBeValidIncidentDate(s, key, incidentDate);
    mustBeValidCToken(key, cToken, incidentDate);
    mustBeDuringClaimPeriod(s, key);
  }

  function mustBeDuringClaimPeriod(IStore s, bytes32 key) public view {
    uint256 resolutionDate = s.getUintByKeys(ProtoUtilV1.NS_RESOLUTION_TS, key);
    require(block.timestamp >= resolutionDate, "Reporting still active"); // solhint-disable-line

    uint256 claimExpiry = s.getUintByKeys(ProtoUtilV1.NS_CLAIM_EXPIRY_TS, key);
    require(block.timestamp <= claimExpiry, "Claim period has expired"); // solhint-disable-line
  }

  function mustBeAfterClaimExpiry(IStore s, bytes32 key) public view {
    require(block.timestamp > s.getUintByKeys(ProtoUtilV1.NS_CLAIM_EXPIRY_TS, key), "Claim still active"); // solhint-disable-line
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
// solhint-disable func-order
pragma solidity >=0.4.22 <0.9.0;
import "../interfaces/IStore.sol";

library StoreKeyUtil {
  function setUintByKey(
    IStore s,
    bytes32 key,
    uint256 value
  ) external {
    require(key > 0, "Invalid key");
    return s.setUint(keccak256(abi.encodePacked(key)), value);
  }

  function setUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 value
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.setUint(keccak256(abi.encodePacked(key1, key2)), value);
  }

  function setUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account,
    uint256 value
  ) external {
    require(key1 > 0 && key2 > 0 && account != address(0), "Invalid key(s)");
    return s.setUint(keccak256(abi.encodePacked(key1, key2, account)), value);
  }

  function addUintByKey(
    IStore s,
    bytes32 key,
    uint256 value
  ) external {
    require(key > 0, "Invalid key");
    return s.addUint(keccak256(abi.encodePacked(key)), value);
  }

  function addUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 value
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.addUint(keccak256(abi.encodePacked(key1, key2)), value);
  }

  function addUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account,
    uint256 value
  ) external {
    require(key1 > 0 && key2 > 0 && account != address(0), "Invalid key(s)");
    return s.addUint(keccak256(abi.encodePacked(key1, key2, account)), value);
  }

  function subtractUintByKey(
    IStore s,
    bytes32 key,
    uint256 value
  ) external {
    require(key > 0, "Invalid key");
    return s.subtractUint(keccak256(abi.encodePacked(key)), value);
  }

  function subtractUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 value
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.subtractUint(keccak256(abi.encodePacked(key1, key2)), value);
  }

  function subtractUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account,
    uint256 value
  ) external {
    require(key1 > 0 && key2 > 0 && account != address(0), "Invalid key(s)");
    return s.subtractUint(keccak256(abi.encodePacked(key1, key2, account)), value);
  }

  function setBytes32ByKey(
    IStore s,
    bytes32 key,
    bytes32 value
  ) external {
    require(key > 0, "Invalid key");
    s.setBytes32(keccak256(abi.encodePacked(key)), value);
  }

  function setBytes32ByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 value
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.setBytes32(keccak256(abi.encodePacked(key1, key2)), value);
  }

  function setBoolByKey(
    IStore s,
    bytes32 key,
    bool value
  ) external {
    require(key > 0, "Invalid key");
    return s.setBool(keccak256(abi.encodePacked(key)), value);
  }

  function setBoolByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bool value
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.setBool(keccak256(abi.encodePacked(key1, key2)), value);
  }

  function setBoolByKeys(
    IStore s,
    bytes32 key,
    address account,
    bool value
  ) external {
    require(key > 0 && account != address(0), "Invalid key(s)");
    return s.setBool(keccak256(abi.encodePacked(key, account)), value);
  }

  function setAddressByKey(
    IStore s,
    bytes32 key,
    address value
  ) external {
    require(key > 0, "Invalid key");
    return s.setAddress(keccak256(abi.encodePacked(key)), value);
  }

  function setAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address value
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.setAddress(keccak256(abi.encodePacked(key1, key2)), value);
  }

  function setAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address value
  ) external {
    require(key1 > 0 && key2 > 0 && key3 > 0, "Invalid key(s)");
    return s.setAddress(keccak256(abi.encodePacked(key1, key2, key3)), value);
  }

  function deleteUintByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    return s.deleteUint(keccak256(abi.encodePacked(key)));
  }

  function deleteUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.deleteUint(keccak256(abi.encodePacked(key1, key2)));
  }

  function deleteBytes32ByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    s.deleteBytes32(keccak256(abi.encodePacked(key)));
  }

  function deleteBytes32ByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.deleteBytes32(keccak256(abi.encodePacked(key1, key2)));
  }

  function deleteBoolByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    return s.deleteBool(keccak256(abi.encodePacked(key)));
  }

  function deleteBoolByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.deleteBool(keccak256(abi.encodePacked(key1, key2)));
  }

  function deleteBoolByKeys(
    IStore s,
    bytes32 key,
    address account
  ) external {
    require(key > 0 && account != address(0), "Invalid key(s)");
    return s.deleteBool(keccak256(abi.encodePacked(key, account)));
  }

  function deleteAddressByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    return s.deleteAddress(keccak256(abi.encodePacked(key)));
  }

  function deleteAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.deleteAddress(keccak256(abi.encodePacked(key1, key2)));
  }

  function getUintByKey(IStore s, bytes32 key) external view returns (uint256) {
    require(key > 0, "Invalid key");
    return s.getUint(keccak256(abi.encodePacked(key)));
  }

  function getUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (uint256) {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.getUint(keccak256(abi.encodePacked(key1, key2)));
  }

  function getUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account
  ) external view returns (uint256) {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.getUint(keccak256(abi.encodePacked(key1, key2, account)));
  }

  function getBytes32ByKey(IStore s, bytes32 key) external view returns (bytes32) {
    require(key > 0, "Invalid key");
    return s.getBytes32(keccak256(abi.encodePacked(key)));
  }

  function getBytes32ByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (bytes32) {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.getBytes32(keccak256(abi.encodePacked(key1, key2)));
  }

  function getBoolByKey(IStore s, bytes32 key) external view returns (bool) {
    require(key > 0, "Invalid key");
    return s.getBool(keccak256(abi.encodePacked(key)));
  }

  function getBoolByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (bool) {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.getBool(keccak256(abi.encodePacked(key1, key2)));
  }

  function getBoolByKeys(
    IStore s,
    bytes32 key,
    address account
  ) external view returns (bool) {
    require(key > 0 && account != address(0), "Invalid key(s)");
    return s.getBool(keccak256(abi.encodePacked(key, account)));
  }

  function getAddressByKey(IStore s, bytes32 key) external view returns (address) {
    require(key > 0, "Invalid key");
    return s.getAddress(keccak256(abi.encodePacked(key)));
  }

  function getAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (address) {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.getAddress(keccak256(abi.encodePacked(key1, key2)));
  }

  function getAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (address) {
    require(key1 > 0 && key2 > 0 && key3 > 0, "Invalid key(s)");
    return s.getAddress(keccak256(abi.encodePacked(key1, key2, key3)));
  }
}

/* solhint-disable */

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";

library NTransferUtilV2 {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  function ensureTransfer(
    IERC20 malicious,
    address recipient,
    uint256 amount
  ) external {
    require(recipient != address(0), "Invalid recipient");
    require(amount > 0, "Invalid transfer amount");

    uint256 pre = malicious.balanceOf(recipient);
    malicious.safeTransfer(recipient, amount);

    uint256 post = malicious.balanceOf(recipient);

    // slither-disable-next-line incorrect-equality
    require(post.sub(pre) == amount, "Invalid transfer");
  }

  function ensureTransferFrom(
    IERC20 malicious,
    address sender,
    address recipient,
    uint256 amount
  ) external {
    require(recipient != address(0), "Invalid recipient");
    require(amount > 0, "Invalid transfer amount");

    uint256 pre = malicious.balanceOf(recipient);
    malicious.safeTransferFrom(sender, recipient, amount);
    uint256 post = malicious.balanceOf(recipient);

    // slither-disable-next-line incorrect-equality
    require(post.sub(pre) == amount, "Invalid transfer");
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "../libraries/ProtoUtilV1.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/security/Pausable.sol";

abstract contract Recoverable is Ownable, ReentrancyGuard, Pausable {
  using ProtoUtilV1 for IStore;
  IStore public s;

  constructor(IStore store) {
    require(address(store) != address(0), "Invalid Store");

    s = store;
  }

  /**
   * @dev Recover all Ether held by the contract.
   */
  function recoverEther(address sendTo) external {
    _mustBeOwnerOrProtoOwner();

    // slither-disable-next-line arbitrary-send
    payable(sendTo).transfer(address(this).balance);
  }

  /**
   * @dev Recover all BEP-20 compatible tokens sent to this address.
   * @param token BEP-20 The address of the token contract
   */
  function recoverToken(address token, address sendTo) external {
    _mustBeOwnerOrProtoOwner();

    IERC20 bep20 = IERC20(token);

    uint256 balance = bep20.balanceOf(address(this));
    require(bep20.transfer(sendTo, balance), "Transfer failed");
  }

  function pause() external {
    _mustBeUnpaused();
    _mustBeOwnerOrProtoOwner();

    super._pause();
  }

  function unpause() external whenPaused {
    _mustBeOwnerOrProtoOwner();

    super._unpause();
  }

  /**
   * @dev Reverts if the sender is not the contract owner or a protocol member.
   */
  function _mustBeOwnerOrProtoMember() internal view {
    bool isProtocol = s.isProtocolMember(super._msgSender());

    if (isProtocol == false) {
      require(super._msgSender() == super.owner(), "Forbidden");
    }
  }

  /**
   * @dev Reverts if the sender is not the contract owner or protocol owner.
   */
  function _mustBeOwnerOrProtoOwner() internal view {
    IProtocol protocol = ProtoUtilV1.getProtocol(s);

    if (address(protocol) == address(0)) {
      require(super._msgSender() == owner(), "Forbidden");
      return;
    }

    address protocolOwner = Ownable(address(protocol)).owner();
    require(super._msgSender() == owner() || super._msgSender() == protocolOwner, "Forbidden");
  }

  function _mustBeUnpaused() internal view {
    require(super.paused() == false, "Contract is paused");

    address protocol = ProtoUtilV1.getProtocolAddress(s);
    require(Pausable(protocol).paused() == false, "Protocol is paused");
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;

interface IMember {
  /**
   * @dev Version number of this contract
   */
  function version() external pure returns (bytes32);

  /**
   * @dev Name of this contract
   */
  function getName() external pure returns (bytes32);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./IMember.sol";

interface IProtocol is IMember {
  event ContractAdded(bytes32 namespace, address contractAddress);
  event ContractUpgraded(bytes32 namespace, address indexed previous, address indexed current);
  event MemberAdded(address member);
  event MemberRemoved(address member);
  event CoverFeeSet(uint256 previous, uint256 current);
  event MinStakeSet(uint256 previous, uint256 current);
  event MinReportingStakeSet(uint256 previous, uint256 current);
  event MinLiquidityPeriodSet(uint256 previous, uint256 current);
  event ClaimPeriodSet(uint256 previous, uint256 current);

  function addContract(bytes32 namespace, address contractAddress) external;

  function upgradeContract(
    bytes32 namespace,
    address previous,
    address current
  ) external;

  function addMember(address member) external;

  function removeMember(address member) external;
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

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;

import "./ProtoUtilV1.sol";
import "./StoreKeyUtil.sol";

import "../interfaces/IPolicy.sol";
import "../interfaces/ICoverStake.sol";
import "../interfaces/IPriceDiscovery.sol";
import "../interfaces/ICTokenFactory.sol";
import "../interfaces/ICoverAssurance.sol";
import "../interfaces/IGovernance.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultFactory.sol";

library RegistryLibV1 {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;

  function getPriceDiscoveryContract(IStore s) public view returns (IPriceDiscovery) {
    return IPriceDiscovery(_getContract(s, ProtoUtilV1.NS_PRICE_DISCOVERY));
  }

  function getGovernanceContract(IStore s) public view returns (IGovernance) {
    return IGovernance(_getContract(s, ProtoUtilV1.NS_GOVERNANCE));
  }

  function getStakingContract(IStore s) public view returns (ICoverStake) {
    return ICoverStake(_getContract(s, ProtoUtilV1.NS_COVER_STAKE));
  }

  function getCTokenFactory(IStore s) public view returns (ICTokenFactory) {
    return ICTokenFactory(_getContract(s, ProtoUtilV1.NS_COVER_CTOKEN_FACTORY));
  }

  function getPolicyContract(IStore s) public view returns (IPolicy) {
    return IPolicy(_getContract(s, ProtoUtilV1.NS_COVER_POLICY));
  }

  function getAssuranceContract(IStore s) public view returns (ICoverAssurance) {
    return ICoverAssurance(_getContract(s, ProtoUtilV1.NS_COVER_ASSURANCE));
  }

  function getVault(IStore s, bytes32 key) public view returns (IVault) {
    address vault = s.getAddressByKeys(ProtoUtilV1.NS_CONTRACTS, ProtoUtilV1.NS_COVER_VAULT, key);
    return IVault(vault);
  }

  function getVaultFactoryContract(IStore s) public view returns (IVaultFactory) {
    address factory = _getContract(s, ProtoUtilV1.NS_COVER_VAULT_FACTORY);
    return IVaultFactory(factory);
  }

  function _getContract(IStore s, bytes32 namespace) private view returns (address) {
    return s.getContract(namespace);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "./IMember.sol";

interface IPolicy is IMember {
  /**
   * @dev Purchase cover for the specified amount. <br /> <br />
   * When you purchase covers, you recieve equal amount of cTokens back.
   * You need the cTokens to claim the cover when resolution occurs.
   * Each unit of cTokens are fully redeemable at 1:1 ratio to the given
   * stablecoins (like wxDai, DAI, USDC, or BUSD) based on the chain.
   * @param key Enter the cover key you wish to purchase the policy for
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   * @param amountToCover Enter the amount of the stablecoin `liquidityToken` to cover.
   */
  function purchaseCover(
    bytes32 key,
    uint256 coverDuration,
    uint256 amountToCover
  ) external returns (address);

  /**
   * @dev Gets the cover fee info for the given cover key, duration, and amount
   * @param key Enter the cover key
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   * @param amountToCover Enter the amount of the stablecoin `liquidityToken` to cover.
   */
  function getCoverFee(
    bytes32 key,
    uint256 coverDuration,
    uint256 amountToCover
  )
    external
    view
    returns (
      uint256 fee,
      uint256 utilizationRatio,
      uint256 totalAvailableLiquidity,
      uint256 coverRatio,
      uint256 floor,
      uint256 ceiling,
      uint256 rate
    );

  /**
   * @dev Returns the values of the given cover key
   * @param _values[0] The total amount in the cover pool
   * @param _values[1] The total commitment amount
   * @param _values[2] The total amount of NEP provision
   * @param _values[3] NEP price
   * @param _values[4] The total amount of assurance tokens
   * @param _values[5] Assurance token price
   * @param _values[6] Assurance pool weight
   */
  function getCoverPoolSummary(bytes32 key) external view returns (uint256[] memory _values);

  function getCToken(bytes32 key, uint256 coverDuration) external view returns (address cToken, uint256 expiryDate);

  function getCTokenByExpiryDate(bytes32 key, uint256 expiryDate) external view returns (address cToken);

  /**
   * Gets the sum total of cover commitment that haven't expired yet.
   */
  function getCommitment(bytes32 key) external view returns (uint256);

  /**
   * Gets the available liquidity in the pool.
   */
  function getCoverable(bytes32 key) external view returns (uint256);

  /**
   * @dev Gets the expiry date based on cover duration
   * @param today Enter the current timestamp
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   */
  function getExpiryDate(uint256 today, uint256 coverDuration) external pure returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "./IMember.sol";

interface ICoverStake is IMember {
  event StakeAdded(bytes32 key, uint256 amount);
  event StakeRemoved(bytes32 key, uint256 amount);
  event FeeBurned(bytes32 key, uint256 amount);

  /**
   * @dev Increase the stake of the given cover pool
   * @param key Enter the cover key
   * @param account Enter the account from where the NEP tokens will be transferred
   * @param amount Enter the amount of stake
   * @param fee Enter the fee amount. Note: do not enter the fee if you are directly calling this function.
   */
  function increaseStake(
    bytes32 key,
    address account,
    uint256 amount,
    uint256 fee
  ) external;

  /**
   * @dev Decreases the stake from the given cover pool
   * @param key Enter the cover key
   * @param account Enter the account to decrease the stake of
   * @param amount Enter the amount of stake to decrease
   */
  function decreaseStake(
    bytes32 key,
    address account,
    uint256 amount
  ) external;

  /**
   * @dev Gets the stake of an account for the given cover key
   * @param key Enter the cover key
   * @param account Specify the account to obtain the stake of
   * @return Returns the total stake of the specified account on the given cover key
   */
  function stakeOf(bytes32 key, address account) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "./IMember.sol";

interface IPriceDiscovery is IMember {
  function getTokenPriceInLiquidityToken(
    address token,
    address liquidityToken,
    uint256 multiplier
  ) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "./IStore.sol";
import "./IMember.sol";

interface ICTokenFactory is IMember {
  event CTokenDeployed(bytes32 indexed key, address cToken, uint256 expiryDate);

  function deploy(
    IStore s,
    bytes32 key,
    uint256 expiryDate
  ) external returns (address);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "./IReporter.sol";
import "./IWitness.sol";
import "./IMember.sol";

interface IGovernance is IMember, IReporter, IWitness {
  event Finalized(bytes32 indexed key, address indexed finalizer, uint256 indexed incidentDate);

  function finalize(bytes32 key, uint256 incidentDate) external;
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "./IMember.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface IVault is IMember, IERC20 {
  event LiquidityAdded(bytes32 key, uint256 amount);
  event LiquidityRemoved(bytes32 key, uint256 amount);
  event GovernanceTransfer(bytes32 key, address to, uint256 amount);
  event PodsMinted(address indexed account, uint256 podsMinted, address indexed vault, uint256 liquidityAdded);

  /**
   * @dev Adds liquidity to the specified cover contract
   * @param coverKey Enter the cover key
   * @param account Specify the account on behalf of which the liquidity is being added.
   * @param amount Enter the amount of liquidity token to supply.
   */
  function addLiquidityInternal(
    bytes32 coverKey,
    address account,
    uint256 amount
  ) external;

  /**
   * @dev Adds liquidity to the specified cover contract
   * @param coverKey Enter the cover key
   * @param amount Enter the amount of liquidity token to supply.
   */
  function addLiquidity(bytes32 coverKey, uint256 amount) external;

  /**
   * @dev Removes liquidity from the specified cover contract
   * @param coverKey Enter the cover key
   * @param amount Enter the amount of liquidity token to remove.
   */
  function removeLiquidity(bytes32 coverKey, uint256 amount) external;

  /**
   * @dev Transfers liquidity to governance contract.
   * @param coverKey Enter the cover key
   * @param to Enter the destination account
   * @param amount Enter the amount of liquidity token to transfer.
   */
  function transferGovernance(
    bytes32 coverKey,
    address to,
    uint256 amount
  ) external;
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "./IStore.sol";
import "./IMember.sol";

interface IVaultFactory is IMember {
  event VaultDeployed(bytes32 indexed key, address vault);

  function deploy(IStore s, bytes32 key) external returns (address);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;

interface IReporter {
  event Reported(bytes32 indexed key, address indexed reporter, uint256 incidentDate, bytes32 info, uint256 initialStake);
  event Disputed(bytes32 indexed key, address indexed reporter, uint256 incidentDate, bytes32 info, uint256 initialStake);

  function report(
    bytes32 key,
    bytes32 info,
    uint256 stake
  ) external;

  function dispute(
    bytes32 key,
    uint256 incidentDate,
    bytes32 info,
    uint256 stake
  ) external;

  function getMinStake() external view returns (uint256);

  function getActiveIncidentDate(bytes32 key) external view returns (uint256);

  function getReporter(bytes32 key, uint256 incidentDate) external view returns (address);

  function getResolutionDate(bytes32 key) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;

interface IWitness {
  event Attested(bytes32 indexed key, address indexed witness, uint256 incidentDate, uint256 stake);
  event Refuted(bytes32 indexed key, address indexed witness, uint256 incidentDate, uint256 stake);

  function attest(
    bytes32 key,
    uint256 incidentDate,
    uint256 stake
  ) external;

  function refute(
    bytes32 key,
    uint256 incidentDate,
    uint256 stake
  ) external;

  function getStatus(bytes32 key) external view returns (uint256);

  function getStakes(bytes32 key, uint256 incidentDate) external view returns (uint256, uint256);

  function getStakesOf(
    bytes32 key,
    uint256 incidentDate,
    address account
  ) external view returns (uint256, uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "../interfaces/IStore.sol";
import "../interfaces/IPolicy.sol";
import "../interfaces/ICoverStake.sol";
import "../interfaces/IPriceDiscovery.sol";
import "../interfaces/ICTokenFactory.sol";
import "../interfaces/ICoverAssurance.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultFactory.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./ProtoUtilV1.sol";
import "./StoreKeyUtil.sol";
import "./CoverUtilV1.sol";

library GovernanceUtilV1 {
  using CoverUtilV1 for IStore;
  using StoreKeyUtil for IStore;

  function getMinReportingStake(IStore s) external view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_SETUP_REPORTING_STAKE);
  }

  function getLatestIncidentDate(IStore s, bytes32 key) external view returns (uint256) {
    return _getLatestIncidentDate(s, key);
  }

  function getReporter(
    IStore s,
    bytes32 key,
    uint256 incidentDate
  ) external view returns (address) {
    (uint256 yes, uint256 no) = getStakes(s, key, incidentDate);

    bytes32 prefix = yes >= no ? ProtoUtilV1.NS_REPORTING_WITNESS_YES : ProtoUtilV1.NS_REPORTING_WITNESS_NO;
    return s.getAddressByKeys(prefix, key);
  }

  function getStakes(
    IStore s,
    bytes32 key,
    uint256 incidentDate
  ) public view returns (uint256 yes, uint256 no) {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_WITNESS_NO, key, incidentDate));
    no = s.getUintByKey(k);

    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_WITNESS_YES, key, incidentDate));
    yes = s.getUintByKey(k);
  }

  function getStakesOf(
    IStore s,
    address account,
    bytes32 key,
    uint256 incidentDate
  ) public view returns (uint256 yes, uint256 no) {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_STAKE_OWNED_NO, key, incidentDate, account));
    no = s.getUintByKey(k);

    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_STAKE_OWNED_YES, key, incidentDate, account));
    yes = s.getUintByKey(k);
  }

  function updateCoverStatus(
    IStore s,
    bytes32 key,
    uint256 incidentDate
  ) public {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_WITNESS_YES, key, incidentDate));
    uint256 yes = s.getUintByKey(k);

    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_WITNESS_NO, key, incidentDate));
    uint256 no = s.getUintByKey(k);

    if (no > yes) {
      s.setStatus(key, CoverUtilV1.CoverStatus.FalseReporting);
      return;
    }

    s.setStatus(key, CoverUtilV1.CoverStatus.IncidentHappened);
  }

  function addAttestation(
    IStore s,
    bytes32 key,
    address who,
    uint256 incidentDate,
    uint256 stake
  ) external {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_STAKE_OWNED_YES, key, incidentDate, who));
    s.addUintByKey(k, stake);

    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_WITNESS_YES, key, incidentDate));
    uint256 currentStake = s.getUintByKey(k);

    if (currentStake == 0) {
      // The first user who reported
      s.setAddressByKeys(ProtoUtilV1.NS_REPORTING_WITNESS_YES, key, msg.sender);
    }

    s.addUintByKey(k, stake);
    updateCoverStatus(s, key, incidentDate);
  }

  function getAttestation(
    IStore s,
    bytes32 key,
    address who,
    uint256 incidentDate
  ) external view returns (uint256 myStake, uint256 totalStake) {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_STAKE_OWNED_YES, key, incidentDate, who));
    myStake = s.getUintByKey(k);

    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_WITNESS_YES, key, incidentDate));
    totalStake = s.getUintByKey(k);
  }

  function addDispute(
    IStore s,
    bytes32 key,
    address who,
    uint256 incidentDate,
    uint256 stake
  ) external {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_STAKE_OWNED_NO, key, incidentDate, who));
    s.addUintByKey(k, stake);

    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_WITNESS_NO, key, incidentDate));
    uint256 currentStake = s.getUintByKey(k);

    if (currentStake == 0) {
      // The first reporter who disputed
      s.setAddressByKeys(ProtoUtilV1.NS_REPORTING_WITNESS_NO, key, msg.sender);
    }

    s.addUintByKey(k, stake);

    updateCoverStatus(s, key, incidentDate);
  }

  function getDispute(
    IStore s,
    bytes32 key,
    address who,
    uint256 incidentDate
  ) external view returns (uint256 myStake, uint256 totalStake) {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_STAKE_OWNED_NO, key, incidentDate, who));
    myStake = s.getUintByKey(k);

    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_WITNESS_NO, key, incidentDate));
    totalStake = s.getUintByKey(k);
  }

  function _getLatestIncidentDate(IStore s, bytes32 key) private view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_REPORTING_INCIDENT_DATE, key);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

pragma solidity >=0.4.22 <0.9.0;

interface ICToken is IERC20 {
  event Finalized(uint256 amount);

  function mint(
    bytes32 key,
    address to,
    uint256 amount
  ) external;

  function burn(uint256 amount) external;

  function expiresOn() external view returns (uint256);

  function coverKey() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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
    constructor () {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () {
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
        emit Paused(_msgSender());
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
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

