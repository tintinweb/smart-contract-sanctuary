// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./utils/SafeMath.sol";
import "./utils/Ownable.sol";
import "./interfaces/IClaimConfig.sol";
import "./interfaces/IProtocol.sol";

/**
 * @title Config for ClaimManagement contract
 * @author Alan
 */
contract ClaimConfig is IClaimConfig, Ownable {
    using SafeMath for uint256;
    
    bool public override allowPartialClaim = true;

    address public override auditor;
    address public override governance;
    address public override treasury;
    address public override protocolFactory;
    
    // The max time allowed from filing a claim to a decision made
    uint256 public override maxClaimDecisionWindow = 7 days;
    uint256 public override baseClaimFee = 10e18;
    uint256 public override forceClaimFee = 500e18;
    uint256 public override feeMultiplier = 2;

    // protocol => claim fee
    mapping(address => uint256) private protocolClaimFee;

    IERC20 public override feeCurrency = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    modifier onlyGovernance() {
        require(msg.sender == governance, "COVER_CC: !governance");
        _;
    }

    /**
     * @notice Set the address of governance
     * @dev Governance address cannot be set to owner or 0 address
     */
    function setGovernance(address _governance) external override onlyGovernance {
        require(_governance != address(0), "COVER_CC: governance cannot be 0");
        require(_governance != owner(), "COVER_CC: governance cannot be owner");
        governance = _governance;
    }

    /**
     * @notice Set the address of treasury
     */
    function setTreasury(address _treasury) external override onlyOwner {
        require(_treasury != address(0), "COVER_CC: treasury cannot be 0");
        treasury = _treasury;
    }

    /**
     * @notice Set max time window allowed to decide a claim after filed, requires at least 3 days for voting
     */
    function setMaxClaimDecisionWindow(uint256 _newTimeWindow) external override onlyOwner {
        require(_newTimeWindow < 3 days, "COVER_CC: window too short");
        maxClaimDecisionWindow = _newTimeWindow;
    }

    /**
     * @notice Set the status and address of auditor
     */
    function setAuditor(address _auditor) external override onlyOwner {
        auditor = _auditor;
    }

    /**
     * @notice Set the status of allowing partial claims
     */
    function setPartialClaimStatus(bool _allowPartialClaim) external override onlyOwner {
        allowPartialClaim = _allowPartialClaim;
    }

    /**
     * @notice Set fees and currency of filing a claim
     * @dev `_forceClaimFee` must be > `_baseClaimFee`
     */
    function setFeeAndCurrency(uint256 _baseClaimFee, uint256 _forceClaimFee, address _currency)
        external 
        override 
        onlyGovernance 
    {
        require(_baseClaimFee > 0, "COVER_CC: baseClaimFee <= 0");
        require(_forceClaimFee > _baseClaimFee, "COVER_CC: forceClaimFee <= baseClaimFee");
        require(_currency != address(0), "COVER_CC: feeCurrency cannot be 0");
        baseClaimFee = _baseClaimFee;
        forceClaimFee = _forceClaimFee;
        feeCurrency = IERC20(_currency);
    }

    /**
     * @notice Set the fee multiplier to `_multiplier`
     * @dev `_multiplier` must be atleast 1
     */
    function setFeeMultiplier(uint256 _multiplier) external override onlyGovernance {
        require(_multiplier >= 1, "COVER_CC: multiplier < 1");
        feeMultiplier = _multiplier;
    }

    /**
     * @notice Get status of auditor voting
     * @dev Returns false if `auditor` is 0
     * @return status of auditor voting in decideClaim
     */
    function isAuditorVoting() public view override returns (bool) {
        return auditor != address(0);
    }

    /**
     * @notice Get the claim fee for protocol `_protocol`
     * @dev Will return `baseClaimFee` if fee is 0
     * @return fee for filing a claim for protocol
     */
    function getProtocolClaimFee(address _protocol) public view override returns (uint256) {
        return protocolClaimFee[_protocol] == 0 ? baseClaimFee : protocolClaimFee[_protocol];
    }

    /**
     * @notice Get the time window allowed to file after an incident happened
     * @dev it is calculated based on the noclaimRedeemDelay of the protocol - (maxClaimDecisionWindow) - 1hour
     * @return time window
     */
    function getFileClaimWindow(address _protocol) public view override returns (uint256) {
        uint256 noclaimRedeemDelay = IProtocol(_protocol).noclaimRedeemDelay();
        return noclaimRedeemDelay.sub(maxClaimDecisionWindow).sub(1 hours);
    }

    /**
     * @notice Updates fee for protocol `_protocol` by multiplying current fee by `feeMultiplier`
     * @dev protocolClaimFee[protocol] cannot exceed `baseClaimFee`
     */
    function _updateProtocolClaimFee(address _protocol) internal {
        uint256 newFee = getProtocolClaimFee(_protocol).mul(feeMultiplier);
        if (newFee <= forceClaimFee) {
            protocolClaimFee[_protocol] = newFee;
        }
    }

    /**
     * @notice Resets fee for protocol `_protocol` to `baseClaimFee`
     */
    function _resetProtocolClaimFee(address _protocol) internal {
        protocolClaimFee[_protocol] = baseClaimFee;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

import "../interfaces/IOwnable.sol";
import "./Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 * @author [email protected]
 *
 * By initialization, the owner account will be the one that called initializeOwner. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable {
    address private _owner;
    address private _newOwner;

    event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferCompleted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev COVER: Initializes the contract setting the deployer as the initial owner.
     */
    function initializeOwner() internal initializer {
        _owner = msg.sender;
        emit OwnershipTransferCompleted(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferInitiated(_owner, newOwner);
        _newOwner = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function claimOwnership() public virtual {
        require(_newOwner == msg.sender, "Ownable: caller is not the owner");
        emit OwnershipTransferCompleted(_owner, _newOwner);
        _owner = _newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IERC20.sol";

/**
 * @dev ClaimConfg contract interface. See {ClaimConfig}.
 * @author Alan
 */
interface IClaimConfig {
    function allowPartialClaim() external view returns (bool);
    function auditor() external view returns (address);
    function governance() external view returns (address);
    function treasury() external view returns (address);
    function protocolFactory() external view returns (address);
    function maxClaimDecisionWindow() external view returns (uint256);
    function baseClaimFee() external view returns (uint256);
    function forceClaimFee() external view returns (uint256);
    function feeMultiplier() external view returns (uint256);
    function feeCurrency() external view returns (IERC20);
    function getFileClaimWindow(address _protocol) external view returns (uint256);
    function isAuditorVoting() external view returns (bool);
    function getProtocolClaimFee(address _protocol) external view returns (uint256);
    
    // @notice only dev
    function setMaxClaimDecisionWindow(uint256 _newTimeWindow) external;
    function setTreasury(address _treasury) external;
    function setAuditor(address _auditor) external;
    function setPartialClaimStatus(bool _allowPartialClaim) external;

    // @dev Only callable by governance
    function setGovernance(address _governance) external;
    function setFeeAndCurrency(uint256 _baseClaimFee, uint256 _forceClaimFee, address _currency) external;
    function setFeeMultiplier(uint256 _multiplier) external;
}

// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

/**
 * @dev Protocol contract interface. See {Protocol}.
 * @author [email protected]
 */
interface IProtocol {
  /// @notice emit when a claim against the protocol is accepted
  event ClaimAccepted(uint256 newClaimNonce);

  function getProtocolDetails()
    external view returns (
      bytes32 _name,
      bool _active,
      uint256 _claimNonce,
      uint256 _claimRedeemDelay,
      uint256 _noclaimRedeemDelay,
      address[] memory _collaterals,
      uint48[] memory _expirationTimestamps,
      address[] memory _allCovers,
      address[] memory _allActiveCovers
    );
  function active() external view returns (bool);
  function name() external view returns (bytes32);
  function claimNonce() external view returns (uint256);
  /// @notice delay # of seconds for redeem with accepted claim, redeemCollateral is not affected
  function claimRedeemDelay() external view returns (uint256);
  /// @notice delay # of seconds for redeem without accepted claim, redeemCollateral is not affected
  function noclaimRedeemDelay() external view returns (uint256);
  function activeCovers(uint256 _index) external view returns (address);
  function claimDetails(uint256 _claimNonce) external view returns (uint16 _payoutNumerator, uint16 _payoutDenominator, uint48 _incidentTimestamp, uint48 _timestamp);
  function collateralStatusMap(address _collateral) external view returns (uint8 _status);
  function expirationTimestampMap(uint48 _expirationTimestamp) external view returns (bytes32 _name, uint8 _status);
  function coverMap(address _collateral, uint48 _expirationTimestamp) external view returns (address);

  function collaterals(uint256 _index) external view returns (address);
  function collateralsLength() external view returns (uint256);
  function expirationTimestamps(uint256 _index) external view returns (uint48);
  function expirationTimestampsLength() external view returns (uint256);
  function activeCoversLength() external view returns (uint256);
  function claimsLength() external view returns (uint256);
  function addCover(address _collateral, uint48 _timestamp, uint256 _amount)
    external returns (bool);

  /// @notice access restriction - claimManager
  function enactClaim(uint16 _payoutNumerator, uint16 _payoutDenominator, uint48 _incidentTimestamp, uint256 _protocolNonce) external returns (bool);

  /// @notice access restriction - dev
  function setActive(bool _active) external returns (bool);
  function updateExpirationTimestamp(uint48 _expirationTimestamp, bytes32 _expirationTimestampName, uint8 _status) external returns (bool);
  function updateCollateral(address _collateral, uint8 _status) external returns (bool);

  /// @notice access restriction - governance
  function updateClaimRedeemDelay(uint256 _claimRedeemDelay) external returns (bool);
  function updateNoclaimRedeemDelay(uint256 _noclaimRedeemDelay) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

/**
 * @title Interface of Ownable
 */
interface IOwnable {
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

/**
 * @title Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function symbol() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./ClaimConfig.sol";
import "./interfaces/IProtocol.sol";
import "./interfaces/IProtocolFactory.sol";
import "./interfaces/IClaimManagement.sol";
import "./utils/SafeERC20.sol";

/**
 * @title Claim Management for claims filed for a COVER supported protocol
 * @author Alan
 */
contract ClaimManagement is IClaimManagement, ClaimConfig {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // protocol => nonce => Claim[]
    mapping(address => mapping(uint256 => Claim[])) public override protocolClaims;

    modifier onlyApprovedDecider() {
        if (isAuditorVoting()) {
            require(msg.sender == auditor, "COVER_CM: !auditor");
        } else {
            require(msg.sender == governance, "COVER_CM: !governance");
        }
        _;
    }

    modifier onlyWhenAuditorVoting() {
        require(isAuditorVoting(), "COVER_CM: !isAuditorVoting");
        _;
    }

    /**
     * @notice Initialize governance and treasury addresses
     * @dev Governance address cannot be set to owner address; `_auditor` can be 0.
     * @param _governance address: address of the governance account
     * @param _auditor address: address of the auditor account
     * @param _treasury address: address of the treasury account
     * @param _protocolFactory address: address of the protocol factory
     */
    constructor(address _governance, address _auditor, address _treasury, address _protocolFactory) {
        require(
            _governance != msg.sender && _governance != address(0), 
            "COVER_CC: governance cannot be owner or 0"
        );
        require(_treasury != address(0), "COVER_CM: treasury cannot be 0");
        require(_protocolFactory != address(0), "COVER_CM: protocol factory cannot be 0");
        governance = _governance;
        auditor = _auditor;
        treasury = _treasury;
        protocolFactory = _protocolFactory;

        initializeOwner();
    }

    /**
     * @notice File a claim for a COVER-supported contract `_protocol` 
     * by paying the `protocolClaimFee[_protocol]` fee
     * @dev `_incidentTimestamp` must be within the past 14 days
     * @param _protocol address: contract address of the protocol that COVER supports
     * @param _protocolName bytes32: protocol name for `_protocol`
     * @param _incidentTimestamp uint48: timestamp of the claim incident
     * 
     * Emits ClaimFiled
     */ 
    function fileClaim(address _protocol, bytes32 _protocolName, uint48 _incidentTimestamp) 
        external 
        override 
    {
        require(_protocol != address(0), "COVER_CM: protocol cannot be 0");
        require(
            _protocol == getAddressFromFactory(_protocolName), 
            "COVER_CM: invalid protocol address"
        );
        require(
            block.timestamp.sub(_incidentTimestamp) <= getFileClaimWindow(_protocol),
            "COVER_CM: block.timestamp - incidentTimestamp > fileClaimWindow"
        );
        uint256 nonce = getProtocolNonce(_protocol);
        uint256 claimFee = getProtocolClaimFee(_protocol);
        protocolClaims[_protocol][nonce].push(Claim({
            state: ClaimState.Filed,
            filedBy: msg.sender,
            payoutNumerator: 0,
            payoutDenominator: 1,
            filedTimestamp: uint48(block.timestamp),
            incidentTimestamp: _incidentTimestamp,
            decidedTimestamp: 0,
            feePaid: claimFee
        }));
        feeCurrency.safeTransferFrom(msg.sender, address(this), claimFee);
        _updateProtocolClaimFee(_protocol);
        emit ClaimFiled({
            isForced: false,
            filedBy: msg.sender,
            protocol: _protocol,
            incidentTimestamp: _incidentTimestamp,
            nonce: nonce,
            index: protocolClaims[_protocol][nonce].length - 1,
            feePaid: claimFee
        });
    }

    /**
     * @notice Force file a claim for a COVER-supported contract `_protocol`
     * that bypasses validateClaim by paying the `forceClaimFee` fee
     * @dev `_incidentTimestamp` must be within the past 14 days. 
     * Only callable when isAuditorVoting is true
     * @param _protocol address: contract address of the protocol that COVER supports
     * @param _protocolName bytes32: protocol name for `_protocol`
     * @param _incidentTimestamp uint48: timestamp of the claim incident
     * 
     * Emits ClaimFiled
     */
    function forceFileClaim(address _protocol, bytes32 _protocolName, uint48 _incidentTimestamp)
        external 
        override 
        onlyWhenAuditorVoting 
    {
        require(_protocol != address(0), "COVER_CM: protocol cannot be 0");
        require(
            _protocol == getAddressFromFactory(_protocolName), 
            "COVER_CM: invalid protocol address"
        );  
        require(
            block.timestamp.sub(_incidentTimestamp) <= getFileClaimWindow(_protocol),
            "COVER_CM: block.timestamp - incidentTimestamp > fileClaimWindow"
        );
        uint256 nonce = getProtocolNonce(_protocol);
        protocolClaims[_protocol][nonce].push(Claim({
            state: ClaimState.ForceFiled,
            filedBy: msg.sender,
            payoutNumerator: 0,
            payoutDenominator: 1,
            filedTimestamp: uint48(block.timestamp),
            incidentTimestamp: _incidentTimestamp,
            decidedTimestamp: 0,
            feePaid: forceClaimFee
        }));
        feeCurrency.safeTransferFrom(msg.sender, address(this), forceClaimFee);
        emit ClaimFiled({
            isForced: true,
            filedBy: msg.sender,
            protocol: _protocol,
            incidentTimestamp: _incidentTimestamp,
            nonce: nonce,
            index: protocolClaims[_protocol][nonce].length - 1,
            feePaid: forceClaimFee
        });
    }

    /**
     * @notice Validates whether claim will be passed to approvedDecider to decideClaim
     * @dev Only callable if isAuditorVoting is true
     * @param _protocol address: contract address of the protocol that COVER supports
     * @param _nonce uint256: nonce of the protocol
     * @param _index uint256: index of the claim
     * @param _claimIsValid bool: true if claim is valid and passed to auditor, false otherwise
     *     
     * Emits ClaimValidated
     */
    function validateClaim(address _protocol, uint256 _nonce, uint256 _index, bool _claimIsValid)
        external 
        override 
        onlyGovernance
        onlyWhenAuditorVoting 
    {
        Claim storage claim = protocolClaims[_protocol][_nonce][_index];
        require(
            _nonce == getProtocolNonce(_protocol), 
            "COVER_CM: input nonce != protocol nonce"
            );
        require(claim.state == ClaimState.Filed, "COVER_CM: claim not filed");
        if (_claimIsValid) {
            claim.state = ClaimState.Validated;
            _resetProtocolClaimFee(_protocol);
        } else {
            claim.state = ClaimState.Invalidated;
            claim.decidedTimestamp = uint48(block.timestamp);
            feeCurrency.safeTransfer(treasury, claim.feePaid);
        }
        emit ClaimValidated({
            claimIsValid: _claimIsValid,
            protocol: _protocol,
            nonce: _nonce,
            index: _index
        });
    }

    /**
     * @notice Decide whether claim for a protocol should be accepted(will payout) or denied
     * @dev Only callable by approvedDecider
     * @param _protocol address: contract address of the protocol that COVER supports
     * @param _nonce uint256: nonce of the protocol
     * @param _index uint256: index of the claim
     * @param _claimIsAccepted bool: true if claim is accepted and will payout, otherwise false
     * @param _payoutNumerator uint256: numerator of percent payout, 0 if _claimIsAccepted = false
     * @param _payoutDenominator uint256: denominator of percent payout
     *
     * Emits ClaimDecided
     */
    function decideClaim(
        address _protocol, 
        uint256 _nonce, 
        uint256 _index, 
        bool _claimIsAccepted, 
        uint16 _payoutNumerator, 
        uint16 _payoutDenominator
    )   
        external
        override 
        onlyApprovedDecider
    {
        require(
            _nonce == getProtocolNonce(_protocol), 
            "COVER_CM: input nonce != protocol nonce"
        );
        Claim storage claim = protocolClaims[_protocol][_nonce][_index];
        if (isAuditorVoting()) {
            require(
                claim.state == ClaimState.Validated || 
                claim.state == ClaimState.ForceFiled, 
                "COVER_CM: claim not validated or forceFiled"
            );
        } else {
            require(claim.state == ClaimState.Filed, "COVER_CM: claim not filed");
        }

        if (_isDecisionWindowPassed(claim)) {
            // Max decision claim window passed, claim is default to Denied
            _claimIsAccepted = false;
        }
        if (_claimIsAccepted) {
            require(_payoutNumerator > 0, "COVER_CM: claim accepted, but payoutNumerator == 0");
            if (allowPartialClaim) {
                require(
                    _payoutNumerator <= _payoutDenominator, 
                    "COVER_CM: payoutNumerator > payoutDenominator"
                );
            } else {
                require(
                    _payoutNumerator == _payoutDenominator, 
                    "COVER_CM: payoutNumerator != payoutDenominator"
                );
            }
            claim.state = ClaimState.Accepted;
            claim.payoutNumerator = _payoutNumerator;
            claim.payoutDenominator = _payoutDenominator;
            feeCurrency.safeTransfer(claim.filedBy, claim.feePaid);
            _resetProtocolClaimFee(_protocol);
            IProtocol(_protocol).enactClaim(_payoutNumerator, _payoutDenominator, claim.incidentTimestamp, _nonce);
        } else {
            require(_payoutNumerator == 0, "COVER_CM: claim denied (default if passed window), but payoutNumerator != 0");
            claim.state = ClaimState.Denied;
            feeCurrency.safeTransfer(treasury, claim.feePaid);
        }
        claim.decidedTimestamp = uint48(block.timestamp);
        emit ClaimDecided({
            claimIsAccepted: _claimIsAccepted, 
            protocol: _protocol, 
            nonce: _nonce, 
            index: _index, 
            payoutNumerator: _payoutNumerator, 
            payoutDenominator: _payoutDenominator
        });
    }

    /**
     * @notice Get all claims for protocol `_protocol` and nonce `_nonce` in state `_state`
     * @param _protocol address: contract address of the protocol that COVER supports
     * @param _nonce uint256: nonce of the protocol
     * @param _state ClaimState: state of claim
     * @return all claims for protocol and nonce in given state
     */
    function getAllClaimsByState(address _protocol, uint256 _nonce, ClaimState _state)
        external 
        view 
        override 
        returns (Claim[] memory) 
    {
        Claim[] memory allClaims = protocolClaims[_protocol][_nonce];
        uint256 count;
        Claim[] memory temp = new Claim[](allClaims.length);
        for (uint i = 0; i < allClaims.length; i++) {
            if (allClaims[i].state == _state) {
                temp[count] = allClaims[i];
                count++;
            }
        }
        Claim[] memory claimsByState = new Claim[](count);
        for (uint i = 0; i < count; i++) {
            claimsByState[i] = temp[i];
        }
        return claimsByState;
    }

    /**
     * @notice Get all claims for protocol `_protocol` and nonce `_nonce`
     * @param _protocol address: contract address of the protocol that COVER supports
     * @param _nonce uint256: nonce of the protocol
     * @return all claims for protocol and nonce
     */
    function getAllClaimsByNonce(address _protocol, uint256 _nonce) 
        external 
        view 
        override 
        returns (Claim[] memory) 
    {
        return protocolClaims[_protocol][_nonce];
    }

    /**
     * @notice Get the protocol address from the protocol factory
     * @param _protocolName bytes32: protocol name
     * @return address corresponding to the protocol name `_protocolName`
     */
    function getAddressFromFactory(bytes32 _protocolName) public view override returns (address) {
        return IProtocolFactory(protocolFactory).protocols(_protocolName);
    }

    /**
     * @notice Get the current nonce for protocol `_protocol`
     * @param _protocol address: contract address of the protocol that COVER supports
     * @return the current nonce for protocol `_protocol`
     */
    function getProtocolNonce(address _protocol) public view override returns (uint256) {
        return IProtocol(_protocol).claimNonce();
    }

    /**
     * The times passed since the claim was filed has to be less than the max claim decision window
     */
    function _isDecisionWindowPassed(Claim memory claim) private view returns (bool) {
        return block.timestamp.sub(claim.filedTimestamp) > maxClaimDecisionWindow.sub(1 hours);
    }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

/**
 * @dev ProtocolFactory contract interface. See {ProtocolFactory}.
 * @author [email protected]
 */
interface IProtocolFactory {
  /// @notice emit when a new protocol is supported in COVER
  event ProtocolInitiation(address protocolAddress);

  function getAllProtocolAddresses() external view returns (address[] memory);
  function getRedeemFees() external view returns (uint16 _numerator, uint16 _denominator);
  function redeemFeeNumerator() external view returns (uint16);
  function redeemFeeDenominator() external view returns (uint16);
  function protocolImplementation() external view returns (address);
  function coverImplementation() external view returns (address);
  function coverERC20Implementation() external view returns (address);
  function treasury() external view returns (address);
  function governance() external view returns (address);
  function claimManager() external view returns (address);
  function protocols(bytes32 _protocolName) external view returns (address);

  function getProtocolsLength() external view returns (uint256);
  function getProtocolNameAndAddress(uint256 _index) external view returns (bytes32, address);
  /// @notice return contract address, the contract may not be deployed yet
  function getProtocolAddress(bytes32 _name) external view returns (address);
  /// @notice return contract address, the contract may not be deployed yet
  function getCoverAddress(bytes32 _protocolName, uint48 _timestamp, address _collateral, uint256 _claimNonce) external view returns (address);
  /// @notice return contract address, the contract may not be deployed yet
  function getCovTokenAddress(bytes32 _protocolName, uint48 _timestamp, address _collateral, uint256 _claimNonce, bool _isClaimCovToken) external view returns (address);

  /// @notice access restriction - owner (dev)
  /// @dev update this will only affect contracts deployed after
  function updateProtocolImplementation(address _newImplementation) external returns (bool);
  /// @dev update this will only affect contracts deployed after
  function updateCoverImplementation(address _newImplementation) external returns (bool);
  /// @dev update this will only affect contracts deployed after
  function updateCoverERC20Implementation(address _newImplementation) external returns (bool);
  function addProtocol(
    bytes32 _name,
    bool _active,
    address _collateral,
    uint48[] calldata _timestamps,
    bytes32[] calldata _timestampNames
  ) external returns (address);
  function updateTreasury(address _address) external returns (bool);
  function updateClaimManager(address _address) external returns (bool);

  /// @notice access restriction - governance
  function updateFees(uint16 _redeemFeeNumerator, uint16 _redeemFeeDenominator) external returns (bool);
  function updateGovernance(address _address) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

/**
 * @dev ClaimManagement contract interface. See {ClaimManagement}.
 * @author Alan
 */
 interface IClaimManagement {
    enum ClaimState { Filed, ForceFiled, Validated, Invalidated, Accepted, Denied }
    struct Claim {
        ClaimState state; // Current state of claim
        address filedBy; // Address of user who filed claim
        uint16 payoutNumerator; // Numerator of percent to payout
        uint16 payoutDenominator; // Denominator of percent to payout
        uint48 filedTimestamp; // Timestamp of submitted claim
        uint48 incidentTimestamp; // Timestamp of the incident the claim is filed for
        uint48 decidedTimestamp; // Timestamp when claim outcome is decided
        uint256 feePaid; // Fee paid to file the claim
    }

    function protocolClaims(address _protocol, uint256 _nonce, uint256 _index) external view returns (        
        ClaimState state,
        address filedBy,
        uint16 payoutNumerator,
        uint16 payoutDenominator,
        uint48 filedTimestamp,
        uint48 incidentTimestamp,
        uint48 decidedTimestamp,
        uint256 feePaid
    );
    
    function fileClaim(address _protocol, bytes32 _protocolName, uint48 _incidentTimestamp) external;
    function forceFileClaim(address _protocol, bytes32 _protocolName, uint48 _incidentTimestamp) external;
    
    // @dev Only callable by owner when auditor is voting
    function validateClaim(address _protocol, uint256 _nonce, uint256 _index, bool _claimIsValid) external;

    // @dev Only callable by approved decider, governance or auditor (isAuditorVoting == true)
    function decideClaim(address _protocol, uint256 _nonce, uint256 _index, bool _claimIsAccepted, uint16 _payoutNumerator, uint16 _payoutDenominator) external;

    function getAllClaimsByState(address _protocol, uint256 _nonce, ClaimState _state) external view returns (Claim[] memory);
    function getAllClaimsByNonce(address _protocol, uint256 _nonce) external view returns (Claim[] memory);
    function getAddressFromFactory(bytes32 _protocolName) external view returns (address);
    function getProtocolNonce(address _protocol) external view returns (uint256);
    
    event ClaimFiled(
        bool indexed isForced,
        address indexed filedBy, 
        address indexed protocol, 
        uint48 incidentTimestamp,
        uint256 nonce, 
        uint256 index, 
        uint256 feePaid
    );
    event ClaimValidated(
        bool indexed claimIsValid,
        address indexed protocol, 
        uint256 nonce, 
        uint256 index
    );
    event ClaimDecided(
        bool indexed claimIsAccepted,
        address indexed protocol, 
        uint256 nonce, 
        uint256 index, 
        uint16 payoutNumerator, 
        uint16 payoutDenominator
    );
 }

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "../interfaces/IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

pragma solidity ^0.7.3;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

import "./proxy/InitializableAdminUpgradeabilityProxy.sol";
import "./utils/Create2.sol";
import "./utils/Initializable.sol";
import "./utils/Ownable.sol";
import "./utils/SafeMath.sol";
import "./utils/SafeERC20.sol";
import "./utils/ReentrancyGuard.sol";
import "./interfaces/ICover.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IOwnable.sol";
import "./interfaces/IProtocol.sol";
import "./interfaces/IProtocolFactory.sol";

/**
 * @title Protocol contract
 * @author [email protected]
 */
contract Protocol is IProtocol, Initializable, ReentrancyGuard, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct ClaimDetails {
    uint16 payoutNumerator; // 0 to 65,535
    uint16 payoutDenominator; // 0 to 65,535
    uint48 incidentTimestamp;
    uint48 claimEnactedTimestamp;
  }

  struct ExpirationTimestampInfo {
    bytes32 name;
    uint8 status; // 0 never set; 1 active, 2 inactive
  }

  bytes4 private constant COVER_INIT_SIGNITURE = bytes4(keccak256("initialize(string,uint48,address,uint256)"));

  /// @notice only active (true) protocol allows adding more covers
  bool public override active;

  bytes32 public override name;

  // nonce of for the protocol's claim status, it also indicates count of accepted claim in the past
  uint256 public override claimNonce;

  // delay # of seconds for redeem with accepted claim, redeemCollateral is not affected
  uint256 public override claimRedeemDelay;
  // delay # of seconds for redeem without accepted claim, redeemCollateral is not affected
  uint256 public override noclaimRedeemDelay;

  // only active covers, once there is an accepted claim (enactClaim called successfully), this sets to [].
  address[] public override activeCovers;
  address[] private allCovers;

  /// @notice list of every supported expirationTimestamp, all may not be active.
  uint48[] public override expirationTimestamps;

  /// @notice list of every supported collateral, all may not be active.
  address[] public override collaterals;

  // [claimNonce] => accepted ClaimDetails
  ClaimDetails[] public override claimDetails;

  // @notice collateral => status. 0 never set; 1 active, 2 inactive
  mapping(address => uint8) public override collateralStatusMap;

  mapping(uint48 => ExpirationTimestampInfo) public override expirationTimestampMap;

  // collateral => timestamp => coverAddress, most recent cover created for the collateral and timestamp combination
  mapping(address => mapping(uint48 => address)) public override coverMap;

  modifier onlyActive() {
    require(active, "COVER: protocol not active");
    _;
  }

  modifier onlyDev() {
    require(msg.sender == _dev(), "COVER: caller not dev");
    _;
  }

  modifier onlyGovernance() {
    require(msg.sender == IProtocolFactory(owner()).governance(), "COVER: caller not governance");
    _;
  }

  /// @dev Initialize, called once
  function initialize (
    bytes32 _protocolName,
    bool _active,
    address _collateral,
    uint48[] calldata _expirationTimestamps,
    bytes32[] calldata _expirationTimestampNames
  )
    external initializer
  {
    name = _protocolName;
    collaterals.push(_collateral);
    active = _active;
    expirationTimestamps = _expirationTimestamps;

    collateralStatusMap[_collateral] = 1;

    for (uint i = 0; i < _expirationTimestamps.length; i++) {
      if (block.timestamp < _expirationTimestamps[i]) {
        expirationTimestampMap[_expirationTimestamps[i]] = ExpirationTimestampInfo(
          _expirationTimestampNames[i],
          1
        );
      }
    }

    // set default delay for redeem
    claimRedeemDelay = 2 days;
    noclaimRedeemDelay = 10 days;

    initializeOwner();
  }

  function getProtocolDetails()
    external view override returns (
      bytes32 _name,
      bool _active,
      uint256 _claimNonce,
      uint256 _claimRedeemDelay,
      uint256 _noclaimRedeemDelay,
      address[] memory _collaterals,
      uint48[] memory _expirationTimestamps,
      address[] memory _allCovers,
      address[] memory _allActiveCovers
    )
  {
    return (
      name,
      active,
      claimNonce,
      claimRedeemDelay,
      noclaimRedeemDelay,
      getCollaterals(),
      getExpirationTimestamps(),
      getAllCovers(),
      getAllActiveCovers()
    );
  }

  function collateralsLength() external view override returns (uint256) {
    return collaterals.length;
  }

  function expirationTimestampsLength() external view override returns (uint256) {
    return expirationTimestamps.length;
  }

  function activeCoversLength() external view override returns (uint256) {
    return activeCovers.length;
  }

  function claimsLength() external view override returns (uint256) {
    return claimDetails.length;
  }

  /**
   * @notice add cover for sender
   *  - transfer collateral from sender to cover contract
   *  - mint the same amount CLAIM covToken to sender
   *  - mint the same amount NOCLAIM covToken to sender
   */
  function addCover(address _collateral, uint48 _timestamp, uint256 _amount)
    external override onlyActive nonReentrant returns (bool)
  {
    require(_amount > 0, "COVER: amount <= 0");
    require(collateralStatusMap[_collateral] == 1, "COVER: invalid collateral");
    require(block.timestamp < _timestamp && expirationTimestampMap[_timestamp].status == 1, "COVER: invalid expiration date");

    // Validate sender collateral balance is > amount
    IERC20 collateral = IERC20(_collateral);
    require(collateral.balanceOf(msg.sender) >= _amount, "COVER: amount > collateral balance");

    address addr = coverMap[_collateral][_timestamp];

    // Deploy new cover contract if not exist or if claim accepted
    if (addr == address(0) || ICover(addr).claimNonce() != claimNonce) {
      string memory coverName = _generateCoverName(_timestamp, collateral.symbol());

      bytes memory bytecode = type(InitializableAdminUpgradeabilityProxy).creationCode;
      bytes32 salt = keccak256(abi.encodePacked(name, _timestamp, _collateral, claimNonce));
      addr = Create2.deploy(0, salt, bytecode);

      bytes memory initData = abi.encodeWithSelector(COVER_INIT_SIGNITURE, coverName, _timestamp, _collateral, claimNonce);
      address coverImplementation = IProtocolFactory(owner()).coverImplementation();
      InitializableAdminUpgradeabilityProxy(payable(addr)).initialize(
        coverImplementation,
        IOwnable(owner()).owner(),
        initData
      );

      activeCovers.push(addr);
      allCovers.push(addr);
      coverMap[_collateral][_timestamp] = addr;
    }

    // move collateral to the cover contract and mint CovTokens to sender
    uint256 coverBalanceBefore = collateral.balanceOf(addr);
    collateral.safeTransferFrom(msg.sender, addr, _amount);
    uint256 coverBalanceAfter = collateral.balanceOf(addr);
    require(coverBalanceAfter > coverBalanceBefore, "COVER: collateral transfer failed");
    ICover(addr).mint(coverBalanceAfter.sub(coverBalanceBefore), msg.sender);
    return true;
  }

  /// @notice update status or add new expiration timestamp
  function updateExpirationTimestamp(uint48 _expirationTimestamp, bytes32 _expirationTimestampName, uint8 _status) external override onlyDev returns (bool) {
    require(block.timestamp < _expirationTimestamp, "COVER: invalid expiration date");
    require(_status > 0 && _status < 3, "COVER: status not in (0, 2]");

    if (expirationTimestampMap[_expirationTimestamp].status == 0) {
      expirationTimestamps.push(_expirationTimestamp);
    }
    expirationTimestampMap[_expirationTimestamp] = ExpirationTimestampInfo(
      _expirationTimestampName,
      _status
    );
    return true;
  }

  /// @notice update status or add new collateral
  function updateCollateral(address _collateral, uint8 _status) external override onlyDev returns (bool) {
    require(_collateral != address(0), "COVER: address cannot be 0");
    require(_status > 0 && _status < 3, "COVER: status not in (0, 2]");

    if (collateralStatusMap[_collateral] == 0) {
      collaterals.push(_collateral);
    }
    collateralStatusMap[_collateral] = _status;
    return true;
  }

  /**
   * @dev enact accepted claim, all covers are to be paid out
   *  - increment claimNonce
   *  - delete activeCovers list
   *  - only COVER claim manager can call this function
   *
   * Emit ClaimAccepted
   */
  function enactClaim(
    uint16 _payoutNumerator,
    uint16 _payoutDenominator,
    uint48 _incidentTimestamp,
    uint256 _protocolNonce
  )
   external override returns (bool)
  {
    require(_protocolNonce == claimNonce, "COVER: nonces do not match");
    require(_payoutNumerator <= _payoutDenominator && _payoutNumerator > 0, "COVER: payout % is not in (0%, 100%]");
    require(msg.sender == IProtocolFactory(owner()).claimManager(), "COVER: caller not claimManager");

    claimNonce = claimNonce.add(1);
    delete activeCovers;
    claimDetails.push(ClaimDetails(
      _payoutNumerator,
      _payoutDenominator,
      _incidentTimestamp,
      uint48(block.timestamp)
    ));
    emit ClaimAccepted(_protocolNonce);
    return true;
  }

  // update status of protocol, if false, will pause new cover creation
  function setActive(bool _active) external override onlyDev returns (bool) {
    active = _active;
    return true;
  }

  function updateClaimRedeemDelay(uint256 _claimRedeemDelay)
   external override onlyGovernance returns (bool)
  {
    claimRedeemDelay = _claimRedeemDelay;
    return true;
  }

  function updateNoclaimRedeemDelay(uint256 _noclaimRedeemDelay)
   external override onlyGovernance returns (bool)
  {
    noclaimRedeemDelay = _noclaimRedeemDelay;
    return true;
  }

  function getAllCovers() private view returns (address[] memory) {
    return allCovers;
  }

  function getAllActiveCovers() private view returns (address[] memory) {
    return activeCovers;
  }

  function getCollaterals() private view returns (address[] memory) {
    return collaterals;
  }

  function getExpirationTimestamps() private view returns (uint48[] memory) {
    return expirationTimestamps;
  }

  /// @dev the owner of this contract is ProtocolFactory contract. The owner of ProtocolFactory is dev
  function _dev() private view returns (address) {
    return IOwnable(owner()).owner();
  }

  /// @dev generate the cover name. Example: COVER_CURVE_2020_12_31_DAI_0
  function _generateCoverName(uint48 _expirationTimestamp, string memory _collateralSymbol)
   internal view returns (string memory) 
  {
    return string(abi.encodePacked(
      "COVER",
      "_",
      bytes32ToString(name),
      "_",
      bytes32ToString(expirationTimestampMap[_expirationTimestamp].name),
      "_",
      _collateralSymbol,
      "_",
      uintToString(claimNonce)
    ));
  }

  // string helper
  function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
    uint8 i = 0;
    while(i < 32 && _bytes32[i] != 0) {
        i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
        bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
  }

  // string helper
  function uintToString(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len - 1;
    while (_i != 0) {
      bstr[k--] = byte(uint8(48 + _i % 10));
      _i /= 10;
    }
    return string(bstr);
  }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

import './BaseAdminUpgradeabilityProxy.sol';

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends from BaseAdminUpgradeabilityProxy with an initializer for 
 * initializing the implementation, admin, and init data.
 */
contract InitializableAdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy {
  /**
   * Contract initializer.
   * @param _logic address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, address _admin, bytes memory _data) public payable {
    require(_implementation() == address(0));

    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }

    assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));
    _setAdmin(_admin);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address payable) {
        address payable addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint256(_data));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

import "./ICoverERC20.sol";

/**
 * @title Cover contract interface. See {Cover}.
 * @author [email protected]
 */
interface ICover {
  event NewCoverERC20(address);

  function getCoverDetails()
    external view returns (string memory _name, uint48 _expirationTimestamp, address _collateral, uint256 _claimNonce, ICoverERC20 _claimCovToken, ICoverERC20 _noclaimCovToken);
  function expirationTimestamp() external view returns (uint48);
  function collateral() external view returns (address);
  function claimCovToken() external view returns (ICoverERC20);
  function noclaimCovToken() external view returns (ICoverERC20);
  function name() external view returns (string memory);
  function claimNonce() external view returns (uint256);

  function redeemClaim() external;
  function redeemNoclaim() external;
  function redeemCollateral(uint256 _amount) external;

  /// @notice access restriction - owner (Protocol)
  function mint(uint256 _amount, address _receiver) external;

  /// @notice access restriction - dev
  function setCovTokenSymbol(string calldata _name) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title BaseAdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */

  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @return The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address) {
    return _admin();
  }

  /**
   * @return The address of the implementation.
   */
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    (bool success,) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @return adm The admin slot.
   */
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "../utils/Address.sol";
import "./Proxy.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 * 
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract BaseUpgradeabilityProxy is Proxy {

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal override view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     * 
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) internal {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 * 
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 * 
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal virtual view returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () payable external {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () payable external {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     * 
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

import "./IERC20.sol";

/**
 * @title CoverERC20 contract interface, implements {IERC20}. See {CoverERC20}.
 * @author [email protected]
 */
interface ICoverERC20 is IERC20 {
    function burn(uint256 _amount) external returns (bool);

    /// @notice access restriction - owner (Cover)
    function mint(address _account, uint256 _amount) external returns (bool);
    function setSymbol(string calldata _symbol) external returns (bool);
    function burnByCover(address _account, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

import "./proxy/InitializableAdminUpgradeabilityProxy.sol";
import "./utils/Address.sol";
import "./utils/Create2.sol";
import "./utils/Ownable.sol";
import "./interfaces/IProtocolFactory.sol";

/**
 * @title ProtocolFactory contract
 * @author [email protected]
 */
contract ProtocolFactory is IProtocolFactory, Ownable {

  bytes4 private constant PROTOCOL_INIT_SIGNITURE = bytes4(keccak256("initialize(bytes32,bool,address,uint48[],bytes32[])"));

  uint16 public override redeemFeeNumerator = 10; // 0 to 65,535
  uint16 public override redeemFeeDenominator = 10000; // 0 to 65,535

  address public override protocolImplementation;
  address public override coverImplementation;
  address public override coverERC20Implementation;

  address public override treasury;
  address public override governance;
  address public override claimManager;

  // not all protocols are active
  bytes32[] private protocolNames;

  mapping(bytes32 => address) public override protocols;

  modifier onlyGovernance() {
    require(msg.sender == governance, "COVER: caller not governance");
    _;
  }

  constructor (
    address _protocolImplementation,
    address _coverImplementation,
    address _coverERC20Implementation,
    address _governance,
    address _treasury
  ) {
    protocolImplementation = _protocolImplementation;
    coverImplementation = _coverImplementation;
    coverERC20Implementation = _coverERC20Implementation;
    governance = _governance;
    treasury = _treasury;

    initializeOwner();
  }

  function getAllProtocolAddresses() external view override returns (address[] memory) {
    bytes32[] memory protocolNamesCopy = protocolNames;
    address[] memory protocolAddresses = new address[](protocolNamesCopy.length);
    for (uint i = 0; i < protocolNamesCopy.length; i++) {
      protocolAddresses[i] = protocols[protocolNamesCopy[i]];
    }
    return protocolAddresses;
  }

  function getRedeemFees() external view override returns (uint16 _numerator, uint16 _denominator) {
    return (redeemFeeNumerator, redeemFeeDenominator);
  }

  function getProtocolsLength() external view override returns (uint256) {
    return protocolNames.length;
  }

  function getProtocolNameAndAddress(uint256 _index)
   external view override returns (bytes32, address)
  {
    bytes32 name = protocolNames[_index];
    return (name, protocols[name]);
  }

  /// @notice return protocol contract address, the contract may not be deployed yet
  function getProtocolAddress(bytes32 _name) public view override returns (address) {
    return _computeAddress(keccak256(abi.encodePacked(_name)), address(this));
  }

  /// @notice return cover contract address, the contract may not be deployed yet
  function getCoverAddress(
    bytes32 _protocolName,
    uint48 _timestamp,
    address _collateral,
    uint256 _claimNonce
  )
   public view override returns (address)
  {
    return _computeAddress(
      keccak256(abi.encodePacked(_protocolName, _timestamp, _collateral, _claimNonce)),
      getProtocolAddress(_protocolName)
    );
  }

  /// @notice return covToken contract address, the contract may not be deployed yet
  function getCovTokenAddress(
    bytes32 _protocolName,
    uint48 _timestamp,
    address _collateral,
    uint256 _claimNonce,
    bool _isClaimCovToken
  )
   external view override returns (address) 
  {
    return _computeAddress(
      keccak256(abi.encodePacked(
        _protocolName,
        _timestamp,
        _collateral,
        _claimNonce,
        _isClaimCovToken ? "CLAIM" : "NOCLAIM")
      ),
      getCoverAddress(_protocolName, _timestamp, _collateral, _claimNonce)
    );
  }

  /// @dev Emits ProtocolInitiation, add a supported protocol in COVER
  function addProtocol(
    bytes32 _name,
    bool _active,
    address _collateral,
    uint48[] calldata _timestamps,
    bytes32[] calldata _timestampNames
  )
    external override onlyOwner returns (address)
  {
    require(protocols[_name] == address(0), "COVER: protocol exists");
    require(_timestamps.length == _timestampNames.length, "COVER: timestamp lengths don't match");
    protocolNames.push(_name);

    bytes memory bytecode = type(InitializableAdminUpgradeabilityProxy).creationCode;
    // unique salt required for each protocol, salt + deployer decides contract address
    bytes32 salt = keccak256(abi.encodePacked(_name));
    address payable proxyAddr = Create2.deploy(0, salt, bytecode);
    emit ProtocolInitiation(proxyAddr);

    bytes memory initData = abi.encodeWithSelector(PROTOCOL_INIT_SIGNITURE, _name, _active, _collateral, _timestamps, _timestampNames);
    InitializableAdminUpgradeabilityProxy(proxyAddr).initialize(protocolImplementation, owner(), initData);

    protocols[_name] = proxyAddr;

    return proxyAddr;
  }

  /// @dev update this will only affect protocols deployed after
  function updateProtocolImplementation(address _newImplementation)
   external override onlyOwner returns (bool)
  {
    require(Address.isContract(_newImplementation), "COVER: new implementation is not a contract");
    protocolImplementation = _newImplementation;
    return true;
  }

  /// @dev update this will only affect covers of protocols deployed after
  function updateCoverImplementation(address _newImplementation)
   external override onlyOwner returns (bool)
  {
    require(Address.isContract(_newImplementation), "COVER: new implementation is not a contract");
    coverImplementation = _newImplementation;
    return true;
  }

  /// @dev update this will only affect covTokens of covers of protocols deployed after
  function updateCoverERC20Implementation(address _newImplementation)
   external override onlyOwner returns (bool)
  {
    require(Address.isContract(_newImplementation), "COVER: new implementation is not a contract");
    coverERC20Implementation = _newImplementation;
    return true;
  }

  function updateFees(
    uint16 _redeemFeeNumerator,
    uint16 _redeemFeeDenominator
  )
    external override onlyGovernance returns (bool)
  {
    require(_redeemFeeDenominator > 0, "COVER: denominator cannot be 0");
    redeemFeeNumerator = _redeemFeeNumerator;
    redeemFeeDenominator = _redeemFeeDenominator;
    return true;
  }

  function updateClaimManager(address _address)
   external override onlyOwner returns (bool)
  {
    require(_address != address(0), "COVER: address cannot be 0");
    claimManager = _address;
    return true;
  }

  function updateGovernance(address _address)
   external override onlyGovernance returns (bool)
  {
    require(_address != address(0), "COVER: address cannot be 0");
    require(_address != owner(), "COVER: governance cannot be owner");
    governance = _address;
    return true;
  }

  function updateTreasury(address _address)
   external override onlyOwner returns (bool)
  {
    require(_address != address(0), "COVER: address cannot be 0");
    treasury = _address;
    return true;
  }

  function _computeAddress(bytes32 salt, address deployer) private pure returns (address) {
    bytes memory bytecode = type(InitializableAdminUpgradeabilityProxy).creationCode;
    return Create2.computeAddress(salt, keccak256(bytecode), deployer);
  }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

import "./utils/Initializable.sol";
import "./utils/Ownable.sol";
import "./utils/SafeMath.sol";
import "./interfaces/ICoverERC20.sol";

/**
 * @title CoverERC20 implements {ERC20} standards with expended features for COVER
 * @author [email protected]
 *
 * COVER's covToken Features:
 *  - Has mint and burn by owner (Cover contract) only feature.
 *  - No limit on the totalSupply.
 *  - Should only be created from Cover contract. See {Cover}
 */
contract CoverERC20 is ICoverERC20, Initializable, Ownable {
  using SafeMath for uint256;

  uint8 public constant decimals = 18;
  string public constant name = "covToken";

  // The symbol of  the contract
  string public override symbol;
  uint256 private _totalSupply;

  mapping(address => uint256) private balances;
  mapping(address => mapping (address => uint256)) private allowances;

  /// @notice Initialize, called once
  function initialize (string calldata _symbol) external initializer {
    symbol = _symbol;
    initializeOwner();
  }

  /// @notice Standard ERC20 function
  function balanceOf(address account) external view override returns (uint256) {
    return balances[account];
  }

  /// @notice Standard ERC20 function
  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  /// @notice Standard ERC20 function
  function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  /// @notice Standard ERC20 function
  function allowance(address owner, address spender) external view virtual override returns (uint256) {
    return allowances[owner][spender];
  }

  /// @notice Standard ERC20 function
  function approve(address spender, uint256 amount) external virtual override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  /// @notice Standard ERC20 function
  function transferFrom(address sender, address recipient, uint256 amount)
    external virtual override returns (bool)
  {
    _transfer(sender, recipient, amount);
    _approve(sender, msg.sender, allowances[sender][msg.sender].sub(amount, "CoverERC20: transfer amount exceeds allowance"));
    return true;
  }

  /// @notice New ERC20 function
  function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
    _approve(msg.sender, spender, allowances[msg.sender][spender].add(addedValue));
    return true;
  }

  /// @notice New ERC20 function
  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
    _approve(msg.sender, spender, allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
  }

  /// @notice COVER specific function
  function mint(address _account, uint256 _amount)
    external override onlyOwner returns (bool)
  {
    require(_account != address(0), "CoverERC20: mint to the zero address");

    _totalSupply = _totalSupply.add(_amount);
    balances[_account] = balances[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);
    return true;
  }

  /// @notice COVER specific function
  function setSymbol(string calldata _symbol)
    external override onlyOwner returns (bool)
  {
    symbol = _symbol;
    return true;
  }

  /// @notice COVER specific function
  function burnByCover(address _account, uint256 _amount) external override onlyOwner returns (bool) {
    _burn(_account, _amount);
    return true;
  }

  /// @notice COVER specific function
  function burn(uint256 _amount) external override returns (bool) {
    _burn(msg.sender, _amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "CoverERC20: transfer from the zero address");
    require(recipient != address(0), "CoverERC20: transfer to the zero address");

    balances[sender] = balances[sender].sub(amount, "CoverERC20: transfer amount exceeds balance");
    balances[recipient] = balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "CoverERC20: burn from the zero address");

    balances[account] = balances[account].sub(amount, "CoverERC20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "CoverERC20: approve from the zero address");
    require(spender != address(0), "CoverERC20: approve to the zero address");

    allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

import "./proxy/InitializableAdminUpgradeabilityProxy.sol";
import "./utils/Create2.sol";
import "./utils/Initializable.sol";
import "./utils/Ownable.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/SafeMath.sol";
import "./utils/SafeERC20.sol";
import "./interfaces/ICover.sol";
import "./interfaces/ICoverERC20.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IOwnable.sol";
import "./interfaces/IProtocol.sol";
import "./interfaces/IProtocolFactory.sol";

/**
 * @title Cover contract
 * @author [email protected]
 *
 * The contract
 *  - Holds collateral funds
 *  - Mints and burns CovTokens (CoverERC20)
 *  - Allows redeem from collateral pool with or without an accepted claim
 */
contract Cover is ICover, Initializable, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  bytes4 private constant COVERERC20_INIT_SIGNITURE = bytes4(keccak256("initialize(string)"));
  uint48 public override expirationTimestamp;
  address public override collateral;
  ICoverERC20 public override claimCovToken;
  ICoverERC20 public override noclaimCovToken;
  string public override name;
  uint256 public override claimNonce;

  modifier onlyNotExpired() {
    require(block.timestamp < expirationTimestamp, "COVER: cover expired");
    _;
  }

  /// @dev Initialize, called once
  function initialize (
    string calldata _name,
    uint48 _timestamp,
    address _collateral,
    uint256 _claimNonce
  ) public initializer {
    name = _name;
    expirationTimestamp = _timestamp;
    collateral = _collateral;
    claimNonce = _claimNonce;

    initializeOwner();

    claimCovToken = _createCovToken("CLAIM");
    noclaimCovToken = _createCovToken("NOCLAIM");
  }

  function getCoverDetails()
    external view override returns (string memory _name, uint48 _expirationTimestamp, address _collateral, uint256 _claimNonce, ICoverERC20 _claimCovToken, ICoverERC20 _noclaimCovToken)
  {
    return (name, expirationTimestamp, collateral, claimNonce, claimCovToken, noclaimCovToken);
  }

  /// @notice only owner (covered protocol) can mint, collateral is transfered in Protocol
  function mint(uint256 _amount, address _receiver) external override onlyOwner onlyNotExpired {
    _noClaimAcceptedCheck(); // save gas than modifier

    claimCovToken.mint(_receiver, _amount);
    noclaimCovToken.mint(_receiver, _amount);
  }

  /// @notice redeem CLAIM covToken, only if there is a claim accepted and delayWithClaim period passed
  function redeemClaim() external override {
    IProtocol protocol = IProtocol(owner());
    require(protocol.claimNonce() > claimNonce, "COVER: no claim accepted");

    (uint16 _payoutNumerator, uint16 _payoutDenominator, uint48 _incidentTimestamp, uint48 _claimEnactedTimestamp) = _claimDetails();
    require(_incidentTimestamp <= expirationTimestamp, "COVER: cover expired before incident");
    require(block.timestamp >= uint256(_claimEnactedTimestamp) + protocol.claimRedeemDelay(), "COVER: not ready");

    _paySender(
      claimCovToken,
      uint256(_payoutNumerator),
      uint256(_payoutDenominator)
    );
  }

  /**
   * @notice redeem NOCLAIM covToken, accept
   * - if no claim accepted, cover is expired, and delayWithoutClaim period passed
   * - if claim accepted, but payout % < 1, and delayWithClaim period passed
   */
  function redeemNoclaim() external override {
    IProtocol protocol = IProtocol(owner());
    if (protocol.claimNonce() > claimNonce) {
      // protocol has an accepted claim

      (uint16 _payoutNumerator, uint16 _payoutDenominator, uint48 _incidentTimestamp, uint48 _claimEnactedTimestamp) = _claimDetails();

      if (_incidentTimestamp > expirationTimestamp) {
        // incident happened after expiration date, redeem back full collateral

        require(block.timestamp >= uint256(expirationTimestamp) + protocol.noclaimRedeemDelay(), "COVER: not ready");
        _paySender(noclaimCovToken, 1, 1);
      } else {
        // incident happened before expiration date, pay 1 - payout%

        // If claim payout is 100%, nothing is left for NOCLAIM covToken holders
        require(_payoutNumerator < _payoutDenominator, "COVER: claim payout 100%");

        require(block.timestamp >= uint256(_claimEnactedTimestamp) + protocol.claimRedeemDelay(), "COVER: not ready");
        _paySender(
          noclaimCovToken,
          uint256(_payoutDenominator).sub(uint256(_payoutNumerator)),
          uint256(_payoutDenominator)
        );
      }
    } else {
      // protocol has no accepted claim

      require(block.timestamp >= uint256(expirationTimestamp) + protocol.noclaimRedeemDelay(), "COVER: not ready");
      _paySender(noclaimCovToken, 1, 1);
    }
  }

  /// @notice redeem collateral, only when no claim accepted and not expired
  function redeemCollateral(uint256 _amount) external override onlyNotExpired {
    require(_amount > 0, "COVER: amount is 0");
    _noClaimAcceptedCheck(); // save gas than modifier

    ICoverERC20 _claimCovToken = claimCovToken; // save gas
    ICoverERC20 _noclaimCovToken = noclaimCovToken; // save gas

    require(_amount <= _claimCovToken.balanceOf(msg.sender), "COVER: low CLAIM balance");
    require(_amount <= _noclaimCovToken.balanceOf(msg.sender), "COVER: low NOCLAIM balance");

    _claimCovToken.burnByCover(msg.sender, _amount);
    _noclaimCovToken.burnByCover(msg.sender, _amount);
    _payCollateral(msg.sender, _amount);
  }

  /**
   * @notice set CovTokenSymbol, will update symbols for both covTokens, only dev account (factory owner)
   * For example:
   *  - COVER_CURVE_2020_12_31_DAI_0
   */
  function setCovTokenSymbol(string calldata _name) external override {
    require(_dev() == msg.sender, "COVER: not dev");

    claimCovToken.setSymbol(string(abi.encodePacked(_name, "_CLAIM")));
    noclaimCovToken.setSymbol(string(abi.encodePacked(_name, "_NOCLAIM")));
  }

  /// @notice the owner of this contract is Protocol contract, the owner of Protocol is ProtocolFactory contract
  function _factory() private view returns (address) {
    return IOwnable(owner()).owner();
  }

  // get the claim details for the corresponding nonce from protocol contract
  function _claimDetails() private view returns (uint16 _payoutNumerator, uint16 _payoutDenominator, uint48 _incidentTimestamp, uint48 _claimEnactedTimestamp) {
    return IProtocol(owner()).claimDetails(claimNonce);
  }

  /// @notice the owner of ProtocolFactory contract is dev, also see {_factory}
  function _dev() private view returns (address) {
    return IOwnable(_factory()).owner();
  }

  /// @notice make sure no claim is accepted
  function _noClaimAcceptedCheck() private view {
    require(IProtocol(owner()).claimNonce() == claimNonce, "COVER: claim accepted");
  }

  /// @notice transfer collateral (amount - fee) from this contract to recevier, transfer fee to COVER treasury
  function _payCollateral(address _receiver, uint256 _amount) private nonReentrant {
    IProtocolFactory factory = IProtocolFactory(_factory());
    uint256 redeemFeeNumerator = factory.redeemFeeNumerator();
    uint256 redeemFeeDenominator = factory.redeemFeeDenominator();
    uint256 fee = _amount.mul(redeemFeeNumerator).div(redeemFeeDenominator);
    address treasury = factory.treasury();
    IERC20 collateralToken = IERC20(collateral);

    collateralToken.safeTransfer(_receiver, _amount.sub(fee));
    collateralToken.safeTransfer(treasury, fee);
  }

  /// @notice burn covToken and pay sender
  function _paySender(
    ICoverERC20 _covToken,
    uint256 _payoutNumerator,
    uint256 _payoutDenominator
  ) private {
    require(_payoutNumerator <= _payoutDenominator, "COVER: payout % is > 100%");
    require(_payoutNumerator > 0, "COVER: payout % < 0%");

    uint256 amount = _covToken.balanceOf(msg.sender);
    require(amount > 0, "COVER: low covToken balance");

    _covToken.burnByCover(msg.sender, amount);

    uint256 payoutAmount = amount.mul(_payoutNumerator).div(_payoutDenominator);
    _payCollateral(msg.sender, payoutAmount);
  }

  /// @dev Emits NewCoverERC20
  function _createCovToken(string memory _suffix) private returns (ICoverERC20) {
    bytes memory bytecode = type(InitializableAdminUpgradeabilityProxy).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(IProtocol(owner()).name(), expirationTimestamp, collateral, claimNonce, _suffix));
    address payable proxyAddr = Create2.deploy(0, salt, bytecode);

    bytes memory initData = abi.encodeWithSelector(COVERERC20_INIT_SIGNITURE, string(abi.encodePacked(name, "_", _suffix)));
    address coverERC20Implementation = IProtocolFactory(_factory()).coverERC20Implementation();
    InitializableAdminUpgradeabilityProxy(proxyAddr).initialize(
      coverERC20Implementation,
      IOwnable(_factory()).owner(),
      initData
    );

    emit NewCoverERC20(proxyAddr);
    return ICoverERC20(proxyAddr);
  }
}

