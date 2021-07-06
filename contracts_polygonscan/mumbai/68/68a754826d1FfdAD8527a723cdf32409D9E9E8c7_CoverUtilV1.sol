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

library CoverUtilV1 {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;

  /**
   * @dev Reverts if the key does not resolve in a valid cover contract.
   * @param key Enter the cover key to check
   */
  function mustBeValidCover(IStore s, bytes32 key) external view {
    require(_getStatus(s, key) != 1, "Cover on Maintenance");
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
  ) external view {
    bool isCoverOwner = _getCoverOwner(s, key) == sender;
    bool isOwner = sender == owner;

    require(isOwner || isCoverOwner, "Forbidden");
  }

  function getCoverOwner(IStore s, bytes32 key) external view returns (address) {
    return _getCoverOwner(s, key);
  }

  /**
   * @dev Gets the current status of the protocol
   *
   * 0 - normal
   * 1 - stopped, can not purchase covers or add liquidity
   * 2 - reporting, incident happened
   * 3 - reporting, false reporting
   * 4 - claimable, claims accepted for payout
   *
   */
  function getStatus(IStore s, bytes32 key) external view returns (uint256) {
    return _getStatus(s, key);
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
    require(_getStatus(s, key) != 1, "Invalid cover");
    IPriceDiscovery discovery = getPriceDiscoveryContract(s);

    _values = new uint256[](7);

    _values[0] = s.getUintByKeys(ProtoUtilV1.NS_COVER_LIQUIDITY, key);
    _values[1] = s.getUintByKeys(ProtoUtilV1.NS_COVER_LIQUIDITY_COMMITMENT, key); // <-- Todo: liquidity commitment should expire as policies expire
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

  function getPriceDiscoveryContract(IStore s) public view returns (IPriceDiscovery) {
    return IPriceDiscovery(ProtoUtilV1.getContract(s, ProtoUtilV1.NS_PRICE_DISCOVERY));
  }

  function getStakingContract(IStore s) public view returns (ICoverStake) {
    return ICoverStake(ProtoUtilV1.getContract(s, ProtoUtilV1.NS_COVER_STAKE));
  }

  function getCTokenFactory(IStore s) public view returns (ICTokenFactory) {
    return ICTokenFactory(ProtoUtilV1.getContract(s, ProtoUtilV1.NS_COVER_CTOKEN_FACTORY));
  }

  function getPolicyContract(IStore s) public view returns (IPolicy) {
    return IPolicy(ProtoUtilV1.getContract(s, ProtoUtilV1.NS_COVER_POLICY));
  }

  function getAssuranceContract(IStore s) public view returns (ICoverAssurance) {
    return ICoverAssurance(ProtoUtilV1.getContract(s, ProtoUtilV1.NS_COVER_ASSURANCE));
  }

  function getVault(IStore s, bytes32 key) public view returns (IVault) {
    address vault = s.getAddressByKeys(ProtoUtilV1.NS_COVER_VAULT, key);
    return IVault(vault);
  }

  function getVaultFactoryContract(IStore s) public view returns (IVaultFactory) {
    address factory = ProtoUtilV1.getContract(s, ProtoUtilV1.NS_COVER_VAULT_FACTORY);
    return IVaultFactory(factory);
  }

  function _getCoverOwner(IStore s, bytes32 key) private view returns (address) {
    return s.getAddressByKeys(ProtoUtilV1.NS_COVER_OWNER, key);
  }

  function _getClaimable(IStore s, bytes32 key) private view returns (uint256) {
    // Todo: deduct the expired cover amounts
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_CLAIMABLE, key);
  }

  function _getStatus(IStore s, bytes32 key) private view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_STATUS, key);
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

interface IPolicy is IMember {
  /**
   * Gets the sum total of cover commitment that haven't expired yet.
   */
  function getCommitment(bytes32 key) external view returns (uint256);

  /**
   * Gets the available liquidity in the pool.
   */
  function getCoverable(bytes32 key) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "./IMember.sol";

interface ICoverStake is IMember {
  function decreaseStake(
    bytes32 key,
    address account,
    uint256 amount
  ) external;

  function increaseStake(
    bytes32 key,
    address account,
    uint256 amount,
    uint256 fees
  ) external;

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
  function deploy(
    IStore s,
    bytes32 key,
    uint256 expiryDate
  ) external returns (address);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "./IMember.sol";

interface ICoverAssurance is IMember {
  function addAssurance(
    bytes32 key,
    address account,
    uint256 amount
  ) external;

  function setWeight(bytes32 key, uint256 weight) external;

  function getAssurance(bytes32 key) external returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "./IMember.sol";

interface IVault is IMember {
  function addLiquidityInternal(
    bytes32 key,
    address account,
    uint256 amount
  ) external;

  function addLiquidity(bytes32 coverKey, uint256 amount) external;

  function removeLiquidity(bytes32 coverKey, uint256 amount) external;
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "./IStore.sol";
import "./IMember.sol";

interface IVaultFactory is IMember {
  function deploy(IStore s, bytes32 key) external returns (address);
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
  bytes32 public constant NS_COVER_ASSURANCE = "proto:cover:assurance";
  bytes32 public constant NS_COVER_ASSURANCE_TOKEN = "proto:cover:assurancetoken";
  bytes32 public constant NS_COVER_ASSURANCE_WEIGHT = "proto:cover:assurance:weight";
  bytes32 public constant NS_COVER_CLAIMABLE = "proto:cover:claimable";
  bytes32 public constant NS_COVER_FEE = "proto:cover:fee";
  bytes32 public constant NS_COVER_INFO = "proto:cover:info";
  bytes32 public constant NS_COVER_LIQUIDITY = "proto:cover:liquidity";
  bytes32 public constant NS_COVER_LIQUIDITY_COMMITMENT = "proto:cover:liquidity:commitment";
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

  bytes32 public constant NS_SETUP_NEP = "proto:setup:nep";
  bytes32 public constant NS_SETUP_COVER_FEE = "proto:setup:cover:fee";
  bytes32 public constant NS_SETUP_MIN_STAKE = "proto:setup:min:stake";
  bytes32 public constant NS_SETUP_MIN_LIQ_PERIOD = "proto:setup:min:liq:period";

  // Contract names
  bytes32 public constant CNAME_PROTOCOL = "Protocol";
  bytes32 public constant CNAME_TREASURY = "Treasury";
  bytes32 public constant CNAME_POLICY = "Policy";
  bytes32 public constant CNAME_POLICY_ADMIN = "PolicyAdmin";
  bytes32 public constant CNAME_POLICY_MANAGER = "PolicyManager";
  bytes32 public constant CNAME_PRICE_DISCOVERY = "PriceDiscovery";
  bytes32 public constant CNAME_COVER = "Cover";
  bytes32 public constant CNAME_VAULT_FACTORY = "VaultFactory";
  bytes32 public constant CNAME_CTOKEN_FACTORY = "cTokenFactory";
  bytes32 public constant CNAME_COVER_PROVISION = "CoverProvison";
  bytes32 public constant CNAME_COVER_STAKE = "CoverStake";
  bytes32 public constant CNAME_COVER_ASSURANCE = "CoverAssurance";
  bytes32 public constant CNAME_LIQUIDITY_VAULT = "Vault";

  function getProtocol(IStore s) external view returns (IProtocol) {
    return _getProtocol(s);
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
  ) external view {
    address contractAddress = _getContract(s, name);
    require(sender == contractAddress, "Access denied");
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

  function _getProtocol(IStore s) private view returns (IProtocol) {
    address protocol = s.getAddressByKey(NS_CORE);
    return IProtocol(protocol);
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
  // function getCoverFee() external view returns (uint256);
  // function getMinCoverStake() external view returns (uint256);
  // function getMinLiquidityPeriod() external view returns (uint256);
}