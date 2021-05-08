// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./ERC20/SafeERC20.sol";
import "./ERC20/IERC20.sol";
import "./proxy/InitializableAdminUpgradeabilityProxy.sol";
import "./utils/Create2.sol";
import "./utils/Initializable.sol";
import "./utils/Ownable.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/StringHelper.sol";
import "./interfaces/ICover.sol";
import "./interfaces/IOwnable.sol";
import "./interfaces/IClaimManagement.sol";
import "./interfaces/ICoverPool.sol";
import "./interfaces/ICoverPoolCallee.sol";
import "./interfaces/ICoverPoolFactory.sol";

/**
 * @title CoverPool contract, manages risks, and covers for pool, handles adding coverage for user
 * @author crypto-pumpkin
 * CoverPool types:
 * - extendable pool: allowed to add and delete risk
 * - non-extendable pool: NOT allowed to add risk, but allowed to delete risk
 */
contract CoverPool is ICoverPool, Initializable, ReentrancyGuard, Ownable {
  using SafeERC20 for IERC20;

  bytes4 private constant COVER_INIT_SIGNITURE = bytes4(keccak256("initialize(string,uint48,address,uint256,uint256)"));
  bytes32 public constant CALLBACK_SUCCESS = keccak256("ICoverPoolCallee.onFlashMint");

  string public override name;
  bool public override extendablePool;
  Status public override poolStatus; // only Active coverPool status can addCover (aka. minting more covTokens)
  bool public override addingRiskWIP;
  uint256 public override addingRiskIndex; // index of the active cover array to continue adding risk
  uint256 public override claimNonce; // nonce of for the coverPool's accepted claims
  uint256 public override noclaimRedeemDelay; // delay for redeem with only noclaim tokens for expired cover with no accpeted claim

  ClaimDetails[] private claimDetails; // [claimNonce] => accepted ClaimDetails
  address[] public override activeCovers; // reset once claim accepted, may contain expired covers, used mostly for adding new risk to pool for faster deployment
  address[] public override allCovers; // all covers ever created
  uint48[] public override expiries; // all expiries ever added
  address[] public override collaterals; // all collaterals ever added
  bytes32[] public override riskList; // list of active risks in cover pool
  bytes32[] public override deletedRiskList;
  // riskMap is only used to check is a risk is already added or deleted
  mapping(bytes32 => Status) public override riskMap;
  mapping(address => CollateralInfo) public override collateralStatusMap;
  mapping(uint48 => ExpiryInfo) public override expiryInfoMap;
  // collateral => timestamp => coverAddress, most recent (might be expired) cover created for the collateral and timestamp combination
  mapping(address => mapping(uint48 => address)) public override coverMap;

  modifier onlyDev() {
    require(msg.sender == _dev(), "CP: caller not dev");
    _;
  }

  modifier onlyNotAddingRiskWIP() {
    require(!addingRiskWIP, "CP: adding risk WIP");
    _;
  }

  /// @dev Initialize, called once
  function initialize (
    string calldata _coverPoolName,
    bool _extendablePool,
    string[] calldata _riskList,
    address _collateral,
    uint256 _mintRatio,
    uint48 _expiry,
    string calldata _expiryString
  ) external initializer {
    require(_collateral != address(0), "CP: collateral cannot be 0");
    initializeOwner();
    name = _coverPoolName;
    extendablePool = _extendablePool;
    _setCollateral(_collateral, _mintRatio, Status.Active);
    _setExpiry(_expiry, _expiryString, Status.Active);

    for (uint256 j = 0; j < _riskList.length; j++) {
      bytes32 risk = StringHelper.stringToBytes32(_riskList[j]);
      require(riskMap[risk] == Status.Null, "CP: duplicated risks");
      riskList.push(risk);
      riskMap[risk] = Status.Active;
      emit RiskUpdated(risk, true);
    }

    noclaimRedeemDelay = _factory().defaultRedeemDelay(); // Claim manager can set it 10 days when claim filed
    emit NoclaimRedeemDelayUpdated(0, noclaimRedeemDelay);
    poolStatus = Status.Active;
    deployCover(_collateral, _expiry);
  }

  /**
   * @notice add coverage (with expiry) for sender, collateral is transferred here to optimize collateral approve tx for users
   * @param _collateral, collateral for cover, must be supported and active
   * @param _expiry, expiry for cover, must be supported and active
   * @param _receiver, receiver of the covTokens, must have _colAmountIn
   * @param _colAmountIn, the amount of collateral to transfer from msg.sender (must approve pool to transfer), should be > _amountOut for inflationary tokens
   * @param _amountOut, the amount of collateral to use to mint covTokens, equals to _colAmountIn if collateral is standard ERC20
   * @param _data, the data to use to call msg.sender, set to '0x' if normal mint
   */
  function addCover(
    address _collateral,
    uint48 _expiry,
    address _receiver,
    uint256 _colAmountIn,
    uint256 _amountOut,
    bytes calldata _data
  ) external override nonReentrant onlyNotAddingRiskWIP
  {
    require(!_factory().paused(), "CP: paused");
    require(poolStatus == Status.Active, "CP: pool not active");
    require(_colAmountIn > 0, "CP: amount <= 0");
    require(collateralStatusMap[_collateral].status == Status.Active, "CP: invalid collateral");
    require(block.timestamp < _expiry && expiryInfoMap[_expiry].status == Status.Active, "CP: invalid expiry");
    address coverAddr = coverMap[_collateral][_expiry];
    require(coverAddr != address(0), "CP: cover not deployed yet");
    ICover cover = ICover(coverAddr);

    // support flash mint
    cover.mint(_amountOut, _receiver);
    if (_data.length > 0) {
      require(
        ICoverPoolCallee(_receiver).onFlashMint(msg.sender, _collateral, _colAmountIn, _amountOut, _data) == CALLBACK_SUCCESS,
        "CP: Callback failed"
      );
    }

    IERC20 collateral = IERC20(_collateral);
    uint256 coverBalanceBefore = collateral.balanceOf(coverAddr);
    collateral.safeTransferFrom(_receiver, coverAddr, _colAmountIn);
    uint256 received = collateral.balanceOf(coverAddr) - coverBalanceBefore;
    require(received >= _amountOut, "CP: collateral transfer failed");

    emit CoverAdded(coverAddr, _receiver, _amountOut);
  }

  /**
   * @notice add risk to pool, true if add complete; false if incomplete.
   * - previously deleted risk not allowed.
   * - Can be called as much as needed till addingRiskWIP is false
   */
  function addRisk(string calldata _risk) external override onlyDev returns (bool) {
    require(extendablePool, "CP: not extendable pool");
    bytes32 risk = StringHelper.stringToBytes32(_risk);
    require(riskMap[risk] != Status.Disabled, "CP: deleted risk not allowed");

    if (riskMap[risk] == Status.Null) {
      // first time adding the risk, make sure no other risk adding in progress
      require(!addingRiskWIP, "CP: adding risk WIP");
      addingRiskWIP = true;
      riskMap[risk] = Status.Active;
      riskList.push(risk);
    }

    // update all active covers with new risk by deploying claim and new future covTokens for each cover contract
    address[] memory activeCoversCopy = activeCovers;

    uint256 startGas = gasleft();
    for (uint256 i = addingRiskIndex; i < activeCoversCopy.length; i++) {
      addingRiskIndex = i;
      // ensure enough gas left to avoid revert all the previous work
      if (startGas < _factory().deployGasMin()) return false;
      // below call deploys two covToken contracts, if cover already added, call will do nothing
      ICover(activeCoversCopy[i]).addRisk(risk);
      startGas = gasleft();
    }

    addingRiskWIP = false;
    addingRiskIndex = 0;
    emit RiskUpdated(risk, true);
    return true;
  }

  /// @notice delete risk from pool
  function deleteRisk(string calldata _risk) external override onlyDev onlyNotAddingRiskWIP {
    bytes32 risk = StringHelper.stringToBytes32(_risk);
    require(riskMap[risk] == Status.Active, "CP: not active risk");
    bytes32[] memory riskListCopy = riskList; // save gas
    uint256 len = riskListCopy.length;
    require(len > 1, "CP: only 1 risk left");
    IClaimManagement claimManager = IClaimManagement(_factory().claimManager());
    require(!claimManager.hasPendingClaim(address(this), claimNonce), "CP: pending claim");


    for (uint256 i = 0; i < len; i++) {
      if (risk == riskListCopy[i]) {
        riskMap[risk] = Status.Disabled;
        deletedRiskList.push(risk);
        riskList[i] = riskListCopy[len - 1];
        riskList.pop();
        emit RiskUpdated(risk, false);
        break;
      }
    }
  }

  /// @notice update status or add new expiry
  function setExpiry(uint48 _expiry, string calldata _expiryStr, Status _status) public override onlyDev {
    _setExpiry(_expiry, _expiryStr, _status);
  }

  /// @notice update status or add new collateral
  function setCollateral(address _collateral, uint256 _mintRatio, Status _status) public override onlyDev {
    _setCollateral(_collateral, _mintRatio, _status);
  }

  // update status of coverPool, if disabled, will pause new cover creation
  function setPoolStatus(Status _poolStatus) external override onlyDev {
    emit PoolStatusUpdated(poolStatus, _poolStatus);
    poolStatus = _poolStatus;
  }

  function setNoclaimRedeemDelay(uint256 _noclaimRedeemDelay) external override {
    ICoverPoolFactory factory = _factory();
    require(msg.sender == _dev() || msg.sender == factory.claimManager(), "CP: caller not gov/claimManager");
    require(_noclaimRedeemDelay >= factory.defaultRedeemDelay(), "CP: < default delay");
    require(_noclaimRedeemDelay <= factory.MAX_REDEEM_DELAY(), "CP: > max delay");
    if (_noclaimRedeemDelay != noclaimRedeemDelay) {
      emit NoclaimRedeemDelayUpdated(noclaimRedeemDelay, _noclaimRedeemDelay);
      noclaimRedeemDelay = _noclaimRedeemDelay;
    }
  }

  /**
   * @dev enact accepted claim, all covers are to be paid out
   *  - increment claimNonce
   *  - delete activeCovers list
   * Emit ClaimEnacted
   */
  function enactClaim(
    bytes32[] calldata _payoutRiskList,
    uint256[] calldata _payoutRates,
    uint48 _incidentTimestamp,
    uint256 _coverPoolNonce
  ) external override {
    require(msg.sender == _factory().claimManager(), "CP: caller not claimManager");
    require(_coverPoolNonce == claimNonce, "CP: nonces do not match");
    require(_payoutRiskList.length == _payoutRates.length, "CP: arrays length don't match");

    uint256 totalPayoutRate;
    for (uint256 i = 0; i < _payoutRiskList.length; i++) {
      require(riskMap[_payoutRiskList[i]] == Status.Active, "CP: has disabled risk");
      totalPayoutRate = totalPayoutRate + _payoutRates[i];
    }
    require(totalPayoutRate <= 1 ether && totalPayoutRate > 0, "CP: payout % not in (0%, 100%]");

    claimNonce = claimNonce + 1;
    delete activeCovers;
    claimDetails.push(ClaimDetails(
      _incidentTimestamp,
      uint48(block.timestamp),
      totalPayoutRate,
      _payoutRiskList,
      _payoutRates
    ));
    emit ClaimEnacted(_coverPoolNonce);
  }

  function getCoverPoolDetails() external view override
    returns (
      address[] memory _collaterals,
      uint48[] memory _expiries,
      bytes32[] memory _riskList,
      bytes32[] memory _deletedRiskList,
      address[] memory _allCovers)
  {
    return (collaterals, expiries, riskList, deletedRiskList, allCovers);
  }

  function getRiskList() external view override returns (bytes32[] memory) {
    return riskList;
  }

  function getClaimDetails(uint256 _nonce) external view override returns (ClaimDetails memory) {
    return claimDetails[_nonce];
  }

  /**
   * @notice deploy Cover contracts with all necessary covTokens
   * Will only deploy or complete existing deployment if necessary.
   * Safe to call by anyone, make it convinient operationally to deploy a new cover for pool
   */
  function deployCover(address _collateral, uint48 _expiry) public override returns (address addr) {
    addr = coverMap[_collateral][_expiry];

    // Deploy new cover contract if not exist or if claim accepted
    if (addr == address(0) || ICover(addr).claimNonce() < claimNonce) {
      require(collateralStatusMap[_collateral].status == Status.Active, "CP: invalid collateral");
      require(block.timestamp < _expiry && expiryInfoMap[_expiry].status == Status.Active, "CP: invalid expiry");

      string memory coverName = _getCoverName(_expiry, IERC20(_collateral).symbol());
      bytes memory bytecode = type(InitializableAdminUpgradeabilityProxy).creationCode;
      bytes32 salt = keccak256(abi.encodePacked(name, _expiry, _collateral, claimNonce));
      addr = Create2.deploy(0, salt, bytecode);
      bytes memory initData = abi.encodeWithSelector(COVER_INIT_SIGNITURE, coverName, _expiry, _collateral, collateralStatusMap[_collateral].mintRatio, claimNonce);
      address coverImpl = _factory().coverImpl();
      InitializableAdminUpgradeabilityProxy(payable(addr)).initialize(
        coverImpl,
        IOwnable(owner()).owner(),
        initData
      );
      activeCovers.push(addr);
      allCovers.push(addr);
      coverMap[_collateral][_expiry] = addr;
      emit CoverCreated(addr);
    } else if (!ICover(addr).deployComplete()) {
      ICover(addr).deploy();
    }
  }

  function _factory() private view returns (ICoverPoolFactory) {
    return ICoverPoolFactory(owner());
  }

  // the owner of this contract is CoverPoolFactory, whose owner is dev
  function _dev() private view returns (address) {
    return IOwnable(owner()).owner();
  }

  function _setExpiry(uint48 _expiry, string calldata _expiryStr, Status _status) private {
    require(block.timestamp < _expiry, "CP: expiry in the past");
    require(_status != Status.Null, "CP: status is null");

    if (expiryInfoMap[_expiry].status == Status.Null) {
      expiries.push(_expiry);
    }
    expiryInfoMap[_expiry] = ExpiryInfo(_expiryStr, _status);
    emit ExpiryUpdated(_expiry, _expiryStr, _status);
  }

  function _setCollateral(address _collateral, uint256 _mintRatio, Status _status) private {
    require(_collateral != address(0), "CP: address cannot be 0");
    require(_status != Status.Null, "CP: status is null");

    if (collateralStatusMap[_collateral].status == Status.Null) {
      collaterals.push(_collateral);
    }
    collateralStatusMap[_collateral] = CollateralInfo(_mintRatio, _status);
    emit CollateralUpdated(_collateral, _mintRatio,  _status);
  }

  // generate the cover name. Example: 3POOL_0_DAI_12_31_21
  function _getCoverName(uint48 _expiry, string memory _collateralSymbol)
   private view returns (string memory)
  {
    require(bytes(_collateralSymbol).length > 0, "CP: empty collateral symbol");
    return string(abi.encodePacked(
      name, "_",
      StringHelper.uintToString(claimNonce), "_",
      _collateralSymbol, "_",
      expiryInfoMap[_expiry].name
    ));
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

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

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
   * It should include the signature and the parameters of the function to be called, as -described in
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

pragma solidity ^0.8.0;

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
        return address(uint160(uint256(_data)));
    }
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

/**
 * @title Cover contract interface. See {Cover}.
 * @author crypto-pumpkin
 * Help convert other types to string
 */
library StringHelper {
  function stringToBytes32(string calldata str) internal pure returns (bytes32 result) {
    bytes memory strBytes = abi.encodePacked(str);
    assembly {
      result := mload(add(strBytes, 32))
    }
  }

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

  function uintToString(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return '0';
    } else {
      bytes32 ret;
      while (_i > 0) {
        ret = bytes32(uint(ret) / (2 ** 8));
        ret |= bytes32(((_i % 10) + 48) * 2 ** (8 * 31));
        _i /= 10;
      }
      _uintAsString = bytes32ToString(ret);
    }
  }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./ICoverERC20.sol";

/**
 * @title Cover interface
 * @author crypto-pumpkin
 */
interface ICover {
  event CovTokenCreated(address);
  event CoverDeployCompleted();
  event Redeemed(string _type, address indexed _account, uint256 _amount);
  event FutureTokenConverted(address indexed _futureToken, address indexed claimCovToken, uint256 _amount);

  // state vars
  function BASE_SCALE() external view returns (uint256);
  function deployComplete() external view returns (bool);
  function expiry() external view returns (uint48);
  function collateral() external view returns (address);
  function noclaimCovToken() external view returns (ICoverERC20);
  function name() external view returns (string memory);
  function feeRate() external view returns (uint256);
  function totalCoverage() external view returns (uint256);
  function mintRatio() external view returns (uint256);
  /// @notice created as initialization, cannot be changed
  function claimNonce() external view returns (uint256);
  function futureCovTokens(uint256 _index) external view returns (ICoverERC20);
  function claimCovTokenMap(bytes32 _risk) external view returns (ICoverERC20);
  function futureCovTokenMap(ICoverERC20 _futureCovToken) external view returns (ICoverERC20 _claimCovToken);

  // extra view
  function viewRedeemable(address _account, uint256 _coverageAmt) external view returns (uint256);
  function getCovTokens() external view
    returns (
      ICoverERC20 _noclaimCovToken,
      ICoverERC20[] memory _claimCovTokens,
      ICoverERC20[] memory _futureCovTokens);

  // user action
  function deploy() external;
  /// @notice convert futureTokens to claimTokens
  function convert(ICoverERC20[] calldata _futureTokens) external;
  /// @notice redeem func when there is a claim on the cover, aka. the cover is affected
  function redeemClaim() external;
  /// @notice redeem func when the cover is not affected by any accepted claim, _amount is respected only when when no claim accepted before expiry (for cover with expiry)
  function redeem(uint256 _amount) external;
  function collectFees() external;

  // access restriction - owner (CoverPool)
  function mint(uint256 _amount, address _receiver) external;
  function addRisk(bytes32 _risk) external;
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
 * @dev ICoverPoolCallee interface for flash mint
 * @author crypto-pumpkin
 */
interface ICoverPoolCallee {
  /// @notice must return keccak256("ICoverPoolCallee.onFlashMint")
  function onFlashMint(
    address _sender,
    address _paymentToken,
    uint256 _paymentAmount,
    uint256 _amountOut,
    bytes calldata _data
  ) external returns (bytes32);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
   * @return proxyAdmin The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address proxyAdmin) {
    proxyAdmin = _admin();
  }

  /**
   * @return impl The address of the implementation.
   */
  function implementation() external ifAdmin returns (address impl) {
    impl = _implementation();
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
   * It should include the signature and the parameters of the function to be called, as -described in
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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "../ERC20/IERC20.sol";

/**
 * @title CoverERC20 contract interface, implements {IERC20}. See {CoverERC20}.
 * @author crypto-pumpkin
 */
interface ICoverERC20 is IERC20 {
    /// @notice access restriction - owner (Cover)
    function mint(address _account, uint256 _amount) external returns (bool);
    function burnByCover(address _account, uint256 _amount) external returns (bool);
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