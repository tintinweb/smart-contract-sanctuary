// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "../../interfaces/IPriceDiscovery.sol";
import "../../interfaces/IStore.sol";
import "../Recoverable.sol";

contract PriceDiscovery is IPriceDiscovery, Recoverable {
  constructor(IStore store) Recoverable(store) {
    this;
  }

  function getTokenPriceInLiquidityToken(
    address, /*token*/
    address, /*liquidityToken*/
    uint256 /*multiplier*/
  ) external view override returns (uint256) {
    this;
    // Todo: Implement this
    return 1 ether;
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
    return ProtoUtilV1.CNAME_PRICE_DISCOVERY;
  }
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

