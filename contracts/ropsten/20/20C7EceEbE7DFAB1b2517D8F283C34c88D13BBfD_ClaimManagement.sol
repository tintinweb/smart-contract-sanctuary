// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20/SafeERC20.sol";
import "./ClaimConfig.sol";
import "./interfaces/ICoverPool.sol";
import "./interfaces/ICoverPoolFactory.sol";
import "./interfaces/IClaimManagement.sol";

/**
 * @title Claim Management for claims filed for a COVER supported coverPool
 * @author Alan + crypto-pumpkin
 */
contract ClaimManagement is IClaimManagement, ClaimConfig {
  using SafeERC20 for IERC20;

  // the redeem delay for a cover when there is a pending claim
  uint256 public constant PENDING_CLAIM_REDEEM_DELAY = 10 days;
  // coverPool => nonce => Claim[]
  mapping(address => mapping(uint256 => Claim[])) private coverPoolClaims;

  constructor(
    address _feeCurrency,
    address _treasury,
    address _coverPoolFactory,
    address _defaultCVC
  ) {
    require(_feeCurrency != address(0), "CM: fee cannot be 0");
    require(_treasury != address(0), "CM: treasury cannot be 0");
    require(_coverPoolFactory != address(0), "CM: factory cannot be 0");
    require(_defaultCVC != address(0), "CM: defaultCVC cannot be 0");
    feeCurrency = IERC20(_feeCurrency);
    treasury = _treasury;
    coverPoolFactory = ICoverPoolFactory(_coverPoolFactory);
    defaultCVC = _defaultCVC;

    initializeOwner();
  }

  /// @notice File a claim for a Cover Pool, `_incidentTimestamp` must be within allowed time window
  function fileClaim(
    string calldata _coverPoolName,
    bytes32[] calldata _exploitRisks,
    uint48 _incidentTimestamp,
    string calldata _description,
    bool isForceFile
  ) external override {
    address coverPool = _getCoverPoolAddr(_coverPoolName);
    require(coverPool != address(0), "CM: pool not found");
    require(block.timestamp - _incidentTimestamp <= coverPoolFactory.defaultRedeemDelay() - TIME_BUFFER, "CM: time passed window");

    ICoverPool(coverPool).setNoclaimRedeemDelay(PENDING_CLAIM_REDEEM_DELAY);
    uint256 nonce = _getCoverPoolNonce(coverPool);
    uint256 claimFee = isForceFile ? forceClaimFee : getCoverPoolClaimFee(coverPool);
    feeCurrency.safeTransferFrom(msg.sender, address(this), claimFee);
    _updateCoverPoolClaimFee(coverPool);
    ClaimState state = isForceFile ? ClaimState.ForceFiled : ClaimState.Filed;
    coverPoolClaims[coverPool][nonce].push(Claim({
      filedBy: msg.sender,
      decidedBy: address(0),
      filedTimestamp: uint48(block.timestamp),
      incidentTimestamp: _incidentTimestamp,
      decidedTimestamp: 0,
      description: _description,
      state: state,
      feePaid: claimFee,
      payoutRiskList: _exploitRisks,
      payoutRates: new uint256[](_exploitRisks.length)
    }));
    emit ClaimUpdate(coverPool, state, nonce, coverPoolClaims[coverPool][nonce].length - 1);
  }

  /**
   * @notice Validates whether claim will be passed to CVC to decideClaim
   * @param _coverPool address: contract address of the coverPool that COVER supports
   * @param _nonce uint256: nonce of the coverPool
   * @param _index uint256: index of the claim
   * @param _claimIsValid bool: true if claim is valid and passed to CVC, false otherwise
   * Emits ClaimUpdate
   */
  function validateClaim(
    address _coverPool,
    uint256 _nonce,
    uint256 _index,
    bool _claimIsValid
  ) external override onlyOwner {
    Claim storage claim = coverPoolClaims[_coverPool][_nonce][_index];
    require(_index < coverPoolClaims[_coverPool][_nonce].length, "CM: bad index");
    require(_nonce == _getCoverPoolNonce(_coverPool), "CM: wrong nonce");
    require(claim.state == ClaimState.Filed, "CM: claim not filed");
    if (_claimIsValid) {
      claim.state = ClaimState.Validated;
      _resetCoverPoolClaimFee(_coverPool);
    } else {
      claim.state = ClaimState.Invalidated;
      claim.decidedTimestamp = uint48(block.timestamp);
      feeCurrency.safeTransfer(treasury, claim.feePaid);
      _resetNoclaimRedeemDelay(_coverPool, _nonce);
    }
    emit ClaimUpdate({
      coverPool: _coverPool,
      state: claim.state,
      nonce: _nonce,
      index: _index
    });
  }

  /// @notice Decide whether claim for a coverPool should be accepted(will payout) or denied, ignored _incidentTimestamp == 0
  function decideClaim(
    address _coverPool,
    uint256 _nonce,
    uint256 _index,
    uint48 _incidentTimestamp,
    bool _claimIsAccepted,
    bytes32[] calldata _exploitRisks,
    uint256[] calldata _payoutRates
  ) external override {
    require(_exploitRisks.length == _payoutRates.length, "CM: arrays len don't match");
    require(isCVCMember(_coverPool, msg.sender), "CM: !cvc");
    require(_nonce == _getCoverPoolNonce(_coverPool), "CM: wrong nonce");
    Claim storage claim = coverPoolClaims[_coverPool][_nonce][_index];
    require(claim.state == ClaimState.Validated || claim.state == ClaimState.ForceFiled, "CM: ! validated or forceFiled");
    if (_incidentTimestamp != 0) {
      require(claim.filedTimestamp - _incidentTimestamp <= coverPoolFactory.defaultRedeemDelay() - TIME_BUFFER, "CM: time passed window");
      claim.incidentTimestamp = _incidentTimestamp;
    }

    uint256 totalRates = _getTotalNum(_payoutRates);
    if (_claimIsAccepted && !_isDecisionWindowPassed(claim)) {
      require(totalRates > 0 && totalRates <= 1 ether, "CM: payout % not in (0%, 100%]");
      feeCurrency.safeTransfer(claim.filedBy, claim.feePaid);
      _resetCoverPoolClaimFee(_coverPool);
      claim.state = ClaimState.Accepted;
      claim.payoutRiskList = _exploitRisks;
      claim.payoutRates = _payoutRates;
      ICoverPool(_coverPool).enactClaim(claim.payoutRiskList, claim.payoutRates, claim.incidentTimestamp, _nonce);
    } else { // Max decision claim window passed, claim is default to Denied
      require(totalRates == 0, "CM: claim denied (default if passed window), but payoutNumerator != 0");
      feeCurrency.safeTransfer(treasury, claim.feePaid);
      claim.state = ClaimState.Denied;
    }
    _resetNoclaimRedeemDelay(_coverPool, _nonce);
    claim.decidedBy = msg.sender;
    claim.decidedTimestamp = uint48(block.timestamp);
    emit ClaimUpdate(_coverPool, claim.state, _nonce, _index);
  }

  function getCoverPoolClaims(address _coverPool, uint256 _nonce, uint256 _index) external view override returns (Claim memory) {
    return coverPoolClaims[_coverPool][_nonce][_index];
  }

  /// @notice Get all claims for coverPool `_coverPool` and nonce `_nonce` in state `_state`
  function getAllClaimsByState(address _coverPool, uint256 _nonce, ClaimState _state)
    external view override returns (Claim[] memory)
  {
    Claim[] memory allClaims = coverPoolClaims[_coverPool][_nonce];
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

  /// @notice Get all claims for coverPool `_coverPool` and nonce `_nonce`
  function getAllClaimsByNonce(address _coverPool, uint256 _nonce) external view override returns (Claim[] memory) {
    return coverPoolClaims[_coverPool][_nonce];
  }

  /// @notice Get whether a pending claim for coverPool `_coverPool` and nonce `_nonce` exists
  function hasPendingClaim(address _coverPool, uint256 _nonce) public view override returns (bool) {
    Claim[] memory allClaims = coverPoolClaims[_coverPool][_nonce];
    for (uint i = 0; i < allClaims.length; i++) {
      ClaimState state = allClaims[i].state;
      if (state == ClaimState.Filed || state == ClaimState.ForceFiled || state == ClaimState.Validated) {
        return true;
      }
    }
    return false;
  }

  function _resetNoclaimRedeemDelay(address _coverPool, uint256 _nonce) private {
    if (hasPendingClaim(_coverPool, _nonce)) return;
    uint256 defaultRedeemDelay = coverPoolFactory.defaultRedeemDelay();
    ICoverPool(_coverPool).setNoclaimRedeemDelay(defaultRedeemDelay);
  }

  function _getCoverPoolAddr(string calldata _coverPoolName) private view returns (address) {
    return coverPoolFactory.coverPools(_coverPoolName);
  }

  function _getCoverPoolNonce(address _coverPool) private view returns (uint256) {
    return ICoverPool(_coverPool).claimNonce();
  }

  // The times passed since the claim was filed has to be less than the max claim decision window
  function _isDecisionWindowPassed(Claim memory claim) private view returns (bool) {
    return block.timestamp - claim.filedTimestamp > maxClaimDecisionWindow;
  }

  function _getTotalNum(uint256[] calldata _payoutRates) private pure returns (uint256 _totalRates) {
    for (uint256 i = 0; i < _payoutRates.length; i++) {
      _totalRates = _totalRates + _payoutRates[i];
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) - value;
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
pragma solidity ^0.8.0;

import "./utils/Ownable.sol";
import "./interfaces/IClaimConfig.sol";
import "./interfaces/ICoverPool.sol";
import "./interfaces/ICoverPoolFactory.sol";

/**
 * @title Config for ClaimManagement contract
 * @author Alan + crypto-pumpkin
 */
contract ClaimConfig is IClaimConfig, Ownable {

  IERC20 public override feeCurrency;
  address public override treasury;
  ICoverPoolFactory public override coverPoolFactory;
  address public override defaultCVC; // if not specified, default to this

  uint256 internal constant TIME_BUFFER = 1 hours;
  // The max time allowed from filing a claim to a decision made, 1 hr buffer for calling
  uint256 public override maxClaimDecisionWindow = 7 days - TIME_BUFFER;
  uint256 public override baseClaimFee = 50e18;
  uint256 public override forceClaimFee = 500e18;
  uint256 public override feeMultiplier = 2;

  // coverPool => claim fee
  mapping(address => uint256) private coverPoolClaimFee;
  // coverPool => cvc addresses
  mapping(address => address[]) public override cvcMap;

  function setTreasury(address _treasury) external override onlyOwner {
    require(_treasury != address(0), "CC: treasury cannot be 0");
    treasury = _treasury;
  }

  /// @notice Set max time window allowed to decide a claim after filed
  function setMaxClaimDecisionWindow(uint256 _newTimeWindow) external override onlyOwner {
    require(_newTimeWindow > 0, "CC: window too short");
    maxClaimDecisionWindow = _newTimeWindow;
  }

  function setDefaultCVC(address _cvc) external override onlyOwner {
    require(_cvc != address(0), "CC: default CVC cannot be 0");
    defaultCVC = _cvc;
  }

  /// @notice Add CVC groups for multiple coverPools
  function addCVCForPools(address[] calldata _coverPools, address[] calldata _cvcs) external override onlyOwner {
    require(_coverPools.length == _cvcs.length, "CC: lengths don't match");
    for (uint256 i = 0; i < _coverPools.length; i++) {
      _addCVCForPool(_coverPools[i], _cvcs[i]);
    }
  }

  /// @notice Remove CVC groups for multiple coverPools
  function removeCVCForPools(address[] calldata _coverPools, address[] calldata _cvcs) external override onlyOwner {
    require(_coverPools.length == _cvcs.length, "CC: lengths don't match");
    for (uint256 i = 0; i < _coverPools.length; i++) {
      _removeCVCForPool(_coverPools[i], _cvcs[i]);
    }
  }

  function setFeeAndCurrency(uint256 _baseClaimFee, uint256 _forceClaimFee, address _currency) external override onlyOwner {
    require(_currency != address(0), "CC: feeCurrency cannot be 0");
    require(_baseClaimFee > 0, "CC: baseClaimFee <= 0");
    require(_forceClaimFee > _baseClaimFee, "CC: force Fee <= base Fee");
    baseClaimFee = _baseClaimFee;
    forceClaimFee = _forceClaimFee;
    feeCurrency = IERC20(_currency);
  }

  function setFeeMultiplier(uint256 _multiplier) external override onlyOwner {
    require(_multiplier >= 1, "CC: multiplier must be >= 1");
    feeMultiplier = _multiplier;
  }

  /// @notice return the whole list so dont need to query by index
  function getCVCList(address _coverPool) external view override returns (address[] memory) {	
    return cvcMap[_coverPool];	
  }

  function isCVCMember(address _coverPool, address _address) public view override returns (bool) {
    address[] memory cvcCopy = cvcMap[_coverPool];
    if (cvcCopy.length == 0 && _address == defaultCVC) return true;
    for (uint256 i = 0; i < cvcCopy.length; i++) {
      if (_address == cvcCopy[i]) {
        return true;
      }
    }
    return false;
  }

  function getCoverPoolClaimFee(address _coverPool) public view override returns (uint256) {
    return coverPoolClaimFee[_coverPool] < baseClaimFee ? baseClaimFee : coverPoolClaimFee[_coverPool];
  }

  // Add CVC group for a coverPool if `_cvc` isn't already added
  function _addCVCForPool(address _coverPool, address _cvc) private onlyOwner {
    address[] memory cvcCopy = cvcMap[_coverPool];
    for (uint256 i = 0; i < cvcCopy.length; i++) {
      require(cvcCopy[i] != _cvc, "CC: cvc exists");
    }
    cvcMap[_coverPool].push(_cvc);
  }

  function _removeCVCForPool(address _coverPool, address _cvc) private {
    address[] memory cvcCopy = cvcMap[_coverPool];
    uint256 len = cvcCopy.length;
    if (len < 1) return; // nothing to remove, no need to revert
    for (uint256 i = 0; i < len; i++) {
      if (_cvc == cvcCopy[i]) {
        cvcMap[_coverPool][i] = cvcCopy[len - 1];
        cvcMap[_coverPool].pop();
        break;
      }
    }
  }

  // Updates fee for coverPool `_coverPool` by multiplying current fee by `feeMultiplier`, capped at `forceClaimFee`
  function _updateCoverPoolClaimFee(address _coverPool) internal {
    uint256 newFee = getCoverPoolClaimFee(_coverPool) * feeMultiplier;
    if (newFee <= forceClaimFee) {
      coverPoolClaimFee[_coverPool] = newFee;
    }
  }

  // Resets fee for coverPool `_coverPool` to `baseClaimFee`
  function _resetCoverPoolClaimFee(address _coverPool) internal {
    coverPoolClaimFee[_coverPool] = baseClaimFee;
  }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

/**
 * @dev CoverPool contract interface. See {CoverPool}.
 * @author crypto-pumpkin
 */
interface ICoverPool {
  event CoverCreated(address indexed);
  event CoverAdded(address indexed _cover, address _acount, uint256 _amount);
  event NoclaimRedeemDelayUpdated(uint256 _oldDelay, uint256 _newDelay);
  event ClaimEnacted(uint256 _enactedClaimNonce);
  event RiskUpdated(bytes32 _risk, bool _isAddRisk);
  event PoolStatusUpdated(Status _old, Status _new);
  event ExpiryUpdated(uint48 _expiry, string _expiryStr,  Status _status);
  event CollateralUpdated(address indexed _collateral, uint256 _mintRatio,  Status _status);

  enum Status { Null, Active, Disabled }

  struct ExpiryInfo {
    string name;
    Status status;
  }
  struct CollateralInfo {
    uint256 mintRatio;
    Status status;
  }
  struct ClaimDetails {
    uint48 incidentTimestamp;
    uint48 claimEnactedTimestamp;
    uint256 totalPayoutRate;
    bytes32[] payoutRiskList;
    uint256[] payoutRates;
  }

  // state vars
  function name() external view returns (string memory);
  function extendablePool() external view returns (bool);
  function poolStatus() external view returns (Status _status);
  /// @notice only active (true) coverPool allows adding more covers (aka. minting more CLAIM and NOCLAIM tokens)
  function claimNonce() external view returns (uint256);
  function noclaimRedeemDelay() external view returns (uint256);
  function addingRiskWIP() external view returns (bool);
  function addingRiskIndex() external view returns (uint256);
  function activeCovers(uint256 _index) external view returns (address);
  function allCovers(uint256 _index) external view returns (address);
  function expiries(uint256 _index) external view returns (uint48);
  function collaterals(uint256 _index) external view returns (address);
  function riskList(uint256 _index) external view returns (bytes32);
  function deletedRiskList(uint256 _index) external view returns (bytes32);
  function riskMap(bytes32 _risk) external view returns (Status);
  function collateralStatusMap(address _collateral) external view returns (uint256 _mintRatio, Status _status);
  function expiryInfoMap(uint48 _expiry) external view returns (string memory _name, Status _status);
  function coverMap(address _collateral, uint48 _expiry) external view returns (address);

  // extra view
  function getRiskList() external view returns (bytes32[] memory _riskList);
  function getClaimDetails(uint256 _claimNonce) external view returns (ClaimDetails memory);
  function getCoverPoolDetails()
    external view returns (
      address[] memory _collaterals,
      uint48[] memory _expiries,
      bytes32[] memory _riskList,
      bytes32[] memory _deletedRiskList,
      address[] memory _allCovers
    );

  // user action
  /// @notice cover must be deployed first
  function addCover(
    address _collateral,
    uint48 _expiry,
    address _receiver,
    uint256 _colAmountIn,
    uint256 _amountOut,
    bytes calldata _data
  ) external;
  function deployCover(address _collateral, uint48 _expiry) external returns (address _coverAddress);

  // access restriction - claimManager
  function enactClaim(
    bytes32[] calldata _payoutRiskList,
    uint256[] calldata _payoutRates,
    uint48 _incidentTimestamp,
    uint256 _coverPoolNonce
  ) external;

  // CM and dev only
  function setNoclaimRedeemDelay(uint256 _noclaimRedeemDelay) external;

  // access restriction - dev
  function addRisk(string calldata _risk) external returns (bool);
  function deleteRisk(string calldata _risk) external;
  function setExpiry(uint48 _expiry, string calldata _expiryName, Status _status) external;
  function setCollateral(address _collateral, uint256 _mintRatio, Status _status) external;
  function setPoolStatus(Status _poolStatus) external;
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

/**
 * @dev CoverPoolFactory contract interface. See {CoverPoolFactory}.
 * @author crypto-pumpkin
 */
interface ICoverPoolFactory {
  event CoverPoolCreated(address indexed _addr);
  event IntUpdated(string _type, uint256 _old, uint256 _new);
  event AddressUpdated(string _type, address indexed _old, address indexed _new);
  event PausedStatusUpdated(bool _old, bool _new);

  // state vars
  function MAX_REDEEM_DELAY() external view returns (uint256);
  function defaultRedeemDelay() external view returns (uint256);
  // yearlyFeeRate is scaled 1e18
  function yearlyFeeRate() external view returns (uint256);
  function paused() external view returns (bool);
  function responder() external view returns (address);
  function coverPoolImpl() external view returns (address);
  function coverImpl() external view returns (address);
  function coverERC20Impl() external view returns (address);
  function treasury() external view returns (address);
  function claimManager() external view returns (address);
  /// @notice min gas left requirement before continue deployments (when creating new Cover or adding risks to CoverPool)
  function deployGasMin() external view returns (uint256);
  function coverPoolNames(uint256 _index) external view returns (string memory);
  function coverPools(string calldata _coverPoolName) external view returns (address);

  // extra view
  function getCoverPools() external view returns (address[] memory);
  /// @notice return contract address, the contract may not be deployed yet
  function getCoverPoolAddress(string calldata _name) external view returns (address);
  function getCoverAddress(string calldata _coverPoolName, uint48 _timestamp, address _collateral, uint256 _claimNonce) external view returns (address);
  /// @notice _prefix example: "C_CURVE", "C_FUT1", or "NC_"
  function getCovTokenAddress(string calldata _coverPoolName, uint48 _expiry, address _collateral, uint256 _claimNonce, string memory _prefix) external view returns (address);

  // access restriction - owner (dev) & responder
  function setPaused(bool _paused) external;

  // access restriction - owner (dev)
  function setYearlyFeeRate(uint256 _yearlyFeeRate) external;
  function setDefaultRedeemDelay(uint256 _defaultRedeemDelay) external;
  function setResponder(address _responder) external;
  function setDeployGasMin(uint256 _deployGasMin) external;
  /// @dev update Impl will only affect contracts deployed after
  function setCoverPoolImpl(address _newImpl) external;
  function setCoverImpl(address _newImpl) external;
  function setCoverERC20Impl(address _newImpl) external;
  function setTreasury(address _address) external;
  function setClaimManager(address _address) external;
  /**
   * @notice Create a new Cover Pool
   * @param _name name for pool, e.g. Yearn
   * @param _extendablePool open pools allow adding new risk
   * @param _riskList risk risks that are covered in this pool
   * @param _collateral the collateral of the pool
   * @param _mintRatio 18 decimals, in (0, + infinity) the deposit ratio for the collateral the pool, 1.5 means =  1 collateral mints 1.5 CLAIM/NOCLAIM tokens
   * @param _expiry expiration date supported for the pool
   * @param _expiryString MONTH_DATE_YEAR, used to create covToken symbols only
   * 
   * Emits CoverPoolCreated, add a supported coverPool in COVER
   */
  function createCoverPool(
    string calldata _name,
    bool _extendablePool,
    string[] calldata _riskList,
    address _collateral,
    uint256 _mintRatio,
    uint48 _expiry,
    string calldata _expiryString
  ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev ClaimManagement contract interface. See {ClaimManagement}.
 * @author Alan + crypto-pumpkin
 */
interface IClaimManagement {
  event ClaimUpdate(address indexed coverPool, ClaimState state, uint256 nonce, uint256 index);

  enum ClaimState { Filed, ForceFiled, Validated, Invalidated, Accepted, Denied }
  struct Claim {
    address filedBy; // Address of user who filed claim
    address decidedBy; // Address of the CVC who decided claim
    uint48 filedTimestamp; // Timestamp of submitted claim
    uint48 incidentTimestamp; // Timestamp of the incident the claim is filed for
    uint48 decidedTimestamp; // Timestamp when claim outcome is decided
    string description;
    ClaimState state; // Current state of claim
    uint256 feePaid; // Fee paid to file the claim
    bytes32[] payoutRiskList;
    uint256[] payoutRates; // Numerators of percent to payout
  }

  function getCoverPoolClaims(address _coverPool, uint256 _nonce, uint256 _index) external view returns (Claim memory);
  function getAllClaimsByState(address _coverPool, uint256 _nonce, ClaimState _state) external view returns (Claim[] memory);
  function getAllClaimsByNonce(address _coverPool, uint256 _nonce) external view returns (Claim[] memory);
  function hasPendingClaim(address _coverPool, uint256 _nonce) external view returns (bool);

  function fileClaim(
    string calldata _coverPoolName,
    bytes32[] calldata _exploitRisks,
    uint48 _incidentTimestamp,
    string calldata _description,
    bool _isForceFile
  ) external;
  
  // @dev Only callable by dev when auditor is voting
  function validateClaim(address _coverPool, uint256 _nonce, uint256 _index, bool _claimIsValid) external;

  // @dev Only callable by CVC
  function decideClaim(
    address _coverPool,
    uint256 _nonce,
    uint256 _index,
    uint48 _incidentTimestamp,
    bool _claimIsAccepted,
    bytes32[] calldata _exploitRisks,
    uint256[] calldata _payoutRates
  ) external;
 }

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

/**
 * @title Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "../interfaces/IOwnable.sol";
import "./Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 * @author crypto-pumpkin
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev COVER: Initializes the contract setting the deployer as the initial owner.
     */
    function initializeOwner() internal initializer {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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

import "../ERC20/IERC20.sol";
import "./ICoverPoolFactory.sol";

/**
 * @dev ClaimConfg contract interface. See {ClaimConfig}.
 * @author Alan + crypto-pumpkin
 */
interface IClaimConfig {
  function treasury() external view returns (address);
  function coverPoolFactory() external view returns (ICoverPoolFactory);
  function defaultCVC() external view returns (address);
  function maxClaimDecisionWindow() external view returns (uint256);
  function baseClaimFee() external view returns (uint256);
  function forceClaimFee() external view returns (uint256);
  function feeMultiplier() external view returns (uint256);
  function feeCurrency() external view returns (IERC20);
  function cvcMap(address _coverPool, uint256 _idx) external view returns (address);
  function getCVCList(address _coverPool) external returns (address[] memory);
  function isCVCMember(address _coverPool, address _address) external view returns (bool);
  function getCoverPoolClaimFee(address _coverPool) external view returns (uint256);
  
  // @notice only dev
  function setMaxClaimDecisionWindow(uint256 _newTimeWindow) external;
  function setTreasury(address _treasury) external;
  function addCVCForPools(address[] calldata _coverPools, address[] calldata _cvcs) external;
  function removeCVCForPools(address[] calldata _coverPools, address[] calldata _cvcs) external;
  function setDefaultCVC(address _cvc) external;
  function setFeeAndCurrency(uint256 _baseClaimFee, uint256 _forceClaimFee, address _currency) external;
  function setFeeMultiplier(uint256 _multiplier) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Interface of Ownable
 */
interface IOwnable {
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;


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