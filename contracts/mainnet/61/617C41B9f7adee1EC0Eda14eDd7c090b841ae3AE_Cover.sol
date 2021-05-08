// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./ERC20/SafeERC20.sol";
import "./ERC20/IERC20.sol";
import "./proxy/Clones.sol";
import "./utils/Create2.sol";
import "./utils/Initializable.sol";
import "./utils/Ownable.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/StringHelper.sol";
import "./interfaces/ICover.sol";
import "./interfaces/ICoverERC20.sol";
import "./interfaces/IOwnable.sol";
import "./interfaces/ICoverPool.sol";
import "./interfaces/ICoverPoolFactory.sol";
import "./interfaces/ICovTokenProxy.sol";

/**
 * @title Cover contract
 * @author crypto-pumpkin
 *  - Holds collateral funds
 *  - Mints and burns CovTokens (CoverERC20)
 *  - Handles redeem with or without an accepted claim
 */
contract Cover is ICover, Initializable, ReentrancyGuard, Ownable {
  using SafeERC20 for IERC20;

  uint256 public override constant BASE_SCALE = 1e18;

  bool public override deployComplete; // once true, never false
  uint48 public override expiry;
  address public override collateral;
  ICoverERC20 public override noclaimCovToken;
  string public override name; // Yearn_0_DAI_12_31_21
  uint256 public override feeRate; // BASE_SCALE, cannot be changed
  uint256 public override mintRatio; // BASE_SCALE, cannot be changed, 1 collateral mint mintRatio * 1 covTokens
  uint256 public override totalCoverage; // in covTokens
  uint256 public override claimNonce;

  ICoverERC20[] public override futureCovTokens;
  mapping(bytes32 => ICoverERC20) public override claimCovTokenMap;
  // future token => CLAIM Token
  mapping(ICoverERC20 => ICoverERC20) public override futureCovTokenMap;

  modifier onlyNotPaused() {
    require(!_factory().paused(), "Cover: paused");
    _;
  }

  /// @dev Initialize, called once
  function initialize (
    string calldata _name,
    uint48 _expiry,
    address _collateral,
    uint256 _mintRatio,
    uint256 _claimNonce
  ) public initializer {
    initializeOwner();
    name = _name;
    expiry = _expiry;
    collateral = _collateral;
    mintRatio = _mintRatio;
    claimNonce = _claimNonce;
    uint256 yearlyFeeRate = _factory().yearlyFeeRate();
    feeRate = yearlyFeeRate * (uint256(_expiry) - block.timestamp) / 365 days;

    noclaimCovToken = _createCovToken("NC_");
    if (_coverPool().extendablePool()) {
      futureCovTokens.push(_createCovToken("C_FUT0_"));
    }
    deploy();
  }

  /// @notice only CoverPool can mint, collateral is transfered in CoverPool
  function mint(uint256 _receivedColAmt, address _receiver) external override onlyOwner nonReentrant {
    require(deployComplete, "Cover: deploy incomplete");
    ICoverPool coverPool = _coverPool();
    require(coverPool.claimNonce() == claimNonce, "Cover: nonces dont match");

    // mintAmount has same decimals of covTokens == collateral decimals
    uint256 mintAmount = _receivedColAmt * mintRatio / BASE_SCALE;
    totalCoverage = totalCoverage + mintAmount;

    (bytes32[] memory _riskList) = coverPool.getRiskList();
    for (uint i = 0; i < _riskList.length; i++) {
      claimCovTokenMap[_riskList[i]].mint(_receiver, mintAmount);
    }
    noclaimCovToken.mint(_receiver, mintAmount);
    _handleLatestFutureToken(_receiver, mintAmount, true /* mint */);
  }

  /// @notice normal redeem (no claim accepted), but always allow redeem back collateral with all covTokens (must converted all eligible future token to claim tokens)
  function redeem(uint256 _amount) external override nonReentrant onlyNotPaused {
    ICoverPool coverPool = _coverPool();

    if (coverPool.claimNonce() > claimNonce) { // accepted claim, should only redeem for not affected cover
      ICoverPool.ClaimDetails memory claim = _claimDetails();
      uint256 defaultRedeemDelay = _factory().defaultRedeemDelay();
      if (claim.incidentTimestamp > expiry && block.timestamp >= uint256(expiry) + defaultRedeemDelay) {
        // not affected cover, default delay passed, redeem with noclaim tokens only
        _burnNoclaimAndPay(_amount);
      } else { // redeem with all covTokens is always allowed
        _redeemWithAllCovTokens(coverPool, _amount);
      }
    } else if (block.timestamp >= uint256(expiry) + coverPool.noclaimRedeemDelay()) {
      // no accepted claim, expired and noclaim delay passed, redeem with noclaim tokens only. Use noclaimRedeemDelay (>= default delay) in case there are pending claims
      _burnNoclaimAndPay(_amount);
    } else { // redeem with all covTokens is always allowed
      _redeemWithAllCovTokens(coverPool, _amount);
    }
    emit Redeemed('Normal', msg.sender, _amount);
  }

  /**
   * @notice convert future tokens to associated CLAIM tokens and next future tokens
   * Once a new risk is added into the CoverPool, the latest futureToken can be converted to the related CLAIM Token and next futureToken (both are created while adding risk to the pool).
   * @dev Never covert the lastest future tokens, it will revert
   */
  function convert(ICoverERC20[] calldata _futureTokens) external override onlyNotPaused {
    for (uint256 i = 0; i < _futureTokens.length; i++) {
      _convert(_futureTokens[i]);
    }
  }

  /**
   * @notice called by owner (CoverPool) only, when a new risk is added to pool the first time
   * - create a new claim token for risk
   * - point the current latest (last one in futureCovTokens) future token to newly created claim token
   * - create a new future token and push to futureCovTokens
   */
  function addRisk(bytes32 _risk) external override onlyOwner {
    if (block.timestamp >= expiry) return;
    // if risk is added, return, so owner (CoverPool) can continue
    if (address(claimCovTokenMap[_risk]) != address(0)) return;

    ICoverERC20[] memory futureCovTokensCopy = futureCovTokens;
    uint256 len = futureCovTokensCopy.length;
    ICoverERC20 latestFutureCovToken = futureCovTokensCopy[len - 1];

    string memory riskName = StringHelper.bytes32ToString(_risk);
    ICoverERC20 claimToken = _createCovToken(string(abi.encodePacked("C_", riskName, "_")));
    claimCovTokenMap[_risk] = claimToken;
    futureCovTokenMap[latestFutureCovToken] = claimToken;

    string memory nextFutureTokenName = string(abi.encodePacked("C_FUT", StringHelper.uintToString(len), "_"));
    futureCovTokens.push(_createCovToken(nextFutureTokenName));
  }

  /// @notice redeem when there is an accepted claim
  function redeemClaim() external override nonReentrant onlyNotPaused {
    ICoverPool coverPool = _coverPool();
    require(coverPool.claimNonce() > claimNonce, "Cover: no claim accepted");
    ICoverPool.ClaimDetails memory claim = _claimDetails();
    require(claim.incidentTimestamp <= expiry, "Cover: not eligible");
    uint256 defaultRedeemDelay = _factory().defaultRedeemDelay();
    require(block.timestamp >= uint256(claim.claimEnactedTimestamp) + defaultRedeemDelay, "Cover: not ready");

    // get all claim tokens eligible amount to payout
    uint256 eligibleAmount;
    for (uint256 i = 0; i < claim.payoutRiskList.length; i++) {
      ICoverERC20 covToken = claimCovTokenMap[claim.payoutRiskList[i]];
      uint256 amount = covToken.balanceOf(msg.sender);
      if (amount > 0) {
        eligibleAmount = eligibleAmount + amount * claim.payoutRates[i] / BASE_SCALE;
        covToken.burnByCover(msg.sender, amount);
      }
    }

    // if total claim payout rate < 1, get noclaim token eligible amount to payout
    if (claim.totalPayoutRate < BASE_SCALE) {
      uint256 amount = noclaimCovToken.balanceOf(msg.sender);
      if (amount > 0) {
        uint256 payoutAmount = amount * (BASE_SCALE - claim.totalPayoutRate) / BASE_SCALE;
        eligibleAmount = eligibleAmount + payoutAmount;
        noclaimCovToken.burnByCover(msg.sender, amount);
      }
    }

    require(eligibleAmount > 0, "Cover: low covToken balance");
    _payCollateral(msg.sender, eligibleAmount);
    emit Redeemed('Claim', msg.sender, eligibleAmount);
  }

  /// @notice multi-tx/block deployment solution. Only called (1+ times depend on size of pool) at creation. Deploy covTokens as many as possible in one tx till not enough gas left.
  function deploy() public override {
    require(!deployComplete, "Cover: deploy completed");
    (bytes32[] memory _riskList) = _coverPool().getRiskList();
    uint256 startGas = gasleft();
    for (uint256 i = 0; i < _riskList.length; i++) {
      if (startGas < _factory().deployGasMin()) return;
      ICoverERC20 claimToken = claimCovTokenMap[_riskList[i]];
      if (address(claimToken) == address(0)) {
        string memory riskName = StringHelper.bytes32ToString(_riskList[i]);
        claimToken = _createCovToken(string(abi.encodePacked("C_", riskName, "_")));
        claimCovTokenMap[_riskList[i]] = claimToken;
        startGas = gasleft();
      }
    }
    deployComplete = true;
    emit CoverDeployCompleted();
  }

  /// @notice coverageAmt is not respected if there is a claim
  function viewRedeemable(address _account, uint256 _coverageAmt) external view override returns (uint256 redeemableAmt) {
    ICoverPool coverPool = _coverPool();
    if (coverPool.claimNonce() == claimNonce) {
      IERC20 colToken = IERC20(collateral);
      uint256 colBal = colToken.balanceOf(address(this));
      uint256 payoutColAmt = _coverageAmt * BASE_SCALE / mintRatio;
      uint256 payoutColAmtAfterFees = payoutColAmt - payoutColAmt * feeRate / BASE_SCALE;
      redeemableAmt = colBal > payoutColAmtAfterFees ? payoutColAmtAfterFees : colBal;
    } else {
      ICoverPool.ClaimDetails memory claim = _claimDetails();
      for (uint256 i = 0; i < claim.payoutRiskList.length; i++) {
        ICoverERC20 covToken = claimCovTokenMap[claim.payoutRiskList[i]];
        uint256 amount = covToken.balanceOf(_account);
        redeemableAmt = redeemableAmt + amount * claim.payoutRates[i] / BASE_SCALE;
      }
      if (claim.totalPayoutRate < BASE_SCALE) {
        uint256 amount = noclaimCovToken.balanceOf(_account);
        uint256 payoutAmount = amount * (BASE_SCALE - claim.totalPayoutRate) / BASE_SCALE;
        redeemableAmt = redeemableAmt + payoutAmount;
      }
    }
  }

  function getCovTokens() external view override
    returns (
      ICoverERC20 _noclaimCovToken,
      ICoverERC20[] memory _claimCovTokens,
      ICoverERC20[] memory _futureCovTokens)
  {
    (bytes32[] memory _riskList) = _coverPool().getRiskList();
    ICoverERC20[] memory claimCovTokens = new ICoverERC20[](_riskList.length);
    for (uint256 i = 0; i < _riskList.length; i++) {
      claimCovTokens[i] = ICoverERC20(claimCovTokenMap[_riskList[i]]);
    }
    return (noclaimCovToken, claimCovTokens, futureCovTokens);
  }

  /// @notice collectFees send fees to treasury, anyone can call
  function collectFees() public override {
    IERC20 colToken = IERC20(collateral);
    uint256 collateralBal = colToken.balanceOf(address(this));
    if (collateralBal == 0) return;
    if (totalCoverage == 0) {
      colToken.safeTransfer(_factory().treasury(), collateralBal);
    } else {
      uint256 totalCoverageInCol = totalCoverage * BASE_SCALE / mintRatio;
      uint256 feesInTheory = totalCoverageInCol * feeRate / BASE_SCALE;
      if (collateralBal > totalCoverageInCol - feesInTheory) {
        uint256 feesToCollect = feesInTheory + collateralBal - totalCoverageInCol;
        colToken.safeTransfer(_factory().treasury(), feesToCollect);
      }
    }
  }

  // transfer collateral (amount - fee) from this contract to recevier
  function _payCollateral(address _receiver, uint256 _coverageAmt) private {
    collectFees();
    totalCoverage = totalCoverage - _coverageAmt;

    IERC20 colToken = IERC20(collateral);
    uint256 colBal = colToken.balanceOf(address(this));
    uint256 payoutColAmt = _coverageAmt * BASE_SCALE / mintRatio;
    uint256 payoutColAmtAfterFees = payoutColAmt - payoutColAmt * feeRate / BASE_SCALE;
    if (colBal > payoutColAmtAfterFees) {
      colToken.safeTransfer(_receiver, payoutColAmtAfterFees);
    } else {
      colToken.safeTransfer(_receiver, colBal);
    }
  }

  // must convert all future tokens to claim tokens to be able to redeem with all covTokens
  function _redeemWithAllCovTokens(ICoverPool coverPool, uint256 _amount) private {
    noclaimCovToken.burnByCover(msg.sender, _amount);
    _handleLatestFutureToken(msg.sender, _amount, false /* burn */);

    (bytes32[] memory riskList) = coverPool.getRiskList();
    for (uint i = 0; i < riskList.length; i++) {
      claimCovTokenMap[riskList[i]].burnByCover(msg.sender, _amount);
    }
    _payCollateral(msg.sender, _amount);
  }

  // note: futureCovTokens can be [] if the pool is not expendable. In that case, nothing to do.
  function _handleLatestFutureToken(address _receiver, uint256 _amount, bool _isMint) private {
    ICoverERC20[] memory futureCovTokensCopy = futureCovTokens;
    uint256 len = futureCovTokensCopy.length;
    if (len == 0) return;
    ICoverERC20 latestFutureCovToken = futureCovTokensCopy[len - 1];
    _isMint
      ? latestFutureCovToken.mint(_receiver, _amount)
      : latestFutureCovToken.burnByCover(_receiver, _amount);
  }

  // burn noclaim covToken and pay sender
  function _burnNoclaimAndPay(uint256 _amount) private {
    noclaimCovToken.burnByCover(msg.sender, _amount);
    _payCollateral(msg.sender, _amount);
  }

  // convert the future token to claim token and mint next future token
  function _convert(ICoverERC20 _futureToken) private {
    ICoverERC20 claimCovToken = futureCovTokenMap[_futureToken];
    require(address(claimCovToken) != address(0), "Cover: nothing to convert");
    uint256 amount = _futureToken.balanceOf(msg.sender);
    require(amount > 0, "Cover: insufficient balance");
    _futureToken.burnByCover(msg.sender, amount);
    claimCovToken.mint(msg.sender, amount);
    emit FutureTokenConverted(address(_futureToken), address(claimCovToken), amount);

    // mint next future covTokens (the last future token points to no tokens)
    ICoverERC20[] memory futureCovTokensCopy = futureCovTokens;
    for (uint256 i = 0; i < futureCovTokensCopy.length - 1; i++) {
      if (futureCovTokensCopy[i] == _futureToken) {
        ICoverERC20 futureCovToken = futureCovTokensCopy[i + 1];
        futureCovToken.mint(msg.sender, amount);
        return;
      }
    }
  }

  /// @dev Emits CovTokenCreated
  function _createCovToken(string memory _prefix) private returns (ICoverERC20) {
    uint8 decimals = uint8(IERC20(collateral).decimals());
    require(decimals > 0, "Cover: col decimals is 0");

    address coverERC20Impl = _factory().coverERC20Impl();
    bytes32 salt = keccak256(abi.encodePacked(_coverPool().name(), expiry, collateral, claimNonce, _prefix));
    address proxyAddr = Clones.cloneDeterministic(coverERC20Impl, salt);
    ICovTokenProxy(proxyAddr).initialize("Cover Protocol covToken", string(abi.encodePacked(_prefix, name)), decimals);

    emit CovTokenCreated(proxyAddr);
    return ICoverERC20(proxyAddr);
  }

  function _coverPool() private view returns (ICoverPool) {
    return ICoverPool(owner());
  }

  // the owner of this contract is CoverPool, the owner of CoverPool is CoverPoolFactory contract
  function _factory() private view returns (ICoverPoolFactory) {
    return ICoverPoolFactory(IOwnable(owner()).owner());
  }

  // get the claim details for the corresponding nonce from coverPool contract
  function _claimDetails() private view returns (ICoverPool.ClaimDetails memory) {
    return _coverPool().getClaimDetails(claimNonce);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Interface of Ownable
 */
interface IOwnable {
    function owner() external view returns (address);
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

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

/**
 * @title Interface of the CovTokens Proxy.
 */
interface ICovTokenProxy {
  function initialize(string calldata _name, string calldata _symbol, uint8 _decimals) external;
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