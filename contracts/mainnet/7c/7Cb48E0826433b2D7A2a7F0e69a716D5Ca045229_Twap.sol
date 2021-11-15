// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./Staged.sol";
import "./AuctionHouseMath.sol";

import "./interfaces/IAuctionHouse.sol";

import "../funds/interfaces/basket/IBasketReader.sol";
import "../oracle/interfaces/ITwap.sol";
import "../policy/interfaces/IMonetaryPolicy.sol";
import "../tokens/interfaces/ISupplyControlledERC20.sol";

import "../lib/BasisMath.sol";
import "../lib/BlockNumber.sol";
import "../lib/Recoverable.sol";
import "../external-lib/SafeDecimalMath.sol";
import "../tokens/SafeSupplyControlledERC20.sol";

/**
 * @title Float Protocol Auction House
 * @notice The contract used to sell or buy FLOAT
 * @dev This contract does not store any assets, except for protocol fees, hence
 * it implements an asset recovery functionality (Recoverable).
 */
contract AuctionHouse is
  IAuctionHouse,
  BlockNumber,
  AuctionHouseMath,
  AccessControl,
  Staged,
  Recoverable
{
  using SafeMath for uint256;
  using SafeDecimalMath for uint256;
  using SafeERC20 for IERC20;
  using SafeERC20 for ISupplyControlledERC20;
  using SafeSupplyControlledERC20 for ISupplyControlledERC20;
  using BasisMath for uint256;

  /* ========== CONSTANTS ========== */
  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

  IERC20 internal immutable weth;
  ISupplyControlledERC20 internal immutable bank;
  ISupplyControlledERC20 internal immutable float;
  IBasketReader internal immutable basket;

  /* ========== STATE VARIABLES ========== */
  // Monetary Policy Contract that decides the target price
  IMonetaryPolicy internal monetaryPolicy;
  // Provides the BANK-ETH Time Weighted Average Price (TWAP) [e27]
  ITwap internal bankEthOracle;
  // Provides the FLOAT-ETH Time Weighted Average Price (TWAP) [e27]
  ITwap internal floatEthOracle;

  /// @inheritdoc IAuctionHouseState
  uint16 public override buffer = 10_00; // 10% default

  /// @inheritdoc IAuctionHouseState
  uint16 public override protocolFee = 5_00; // 5% / 500 bps

  /// @inheritdoc IAuctionHouseState
  uint32 public override allowanceCap = 10_00; // 10% / 1000 bps

  /// @inheritdoc IAuctionHouseVariables
  uint64 public override round;

  /**
   * @notice Allows for monetary policy updates to be enabled and disabled.
   */
  bool public shouldUpdatePolicy = true;

  /**
   * Note that we choose to freeze all price values at the start of an auction.
   * These values are stale _by design_. The burden of price checking
   * is moved to the arbitrager, already vital for them to make a profit.
   * We don't mind these values being out of date, as we start the auctions from a position generously in favour of the protocol (assuming our target price is correct). If these market values are stale, then profit opportunity will start earlier / later, and hence close out a mispriced auction early.
   * We also start the auctions at `buffer`% of the price.
   */

  /// @inheritdoc IAuctionHouseVariables
  mapping(uint64 => Auction) public override auctions;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    // Dependencies
    address _weth,
    address _bank,
    address _float,
    address _basket,
    address _monetaryPolicy,
    address _gov,
    address _bankEthOracle,
    address _floatEthOracle,
    // Parameters
    uint16 _auctionDuration,
    uint32 _auctionCooldown,
    uint256 _firstAuctionBlock
  ) Staged(_auctionDuration, _auctionCooldown, _firstAuctionBlock) {
    // Tokens
    weth = IERC20(_weth);
    bank = ISupplyControlledERC20(_bank);
    float = ISupplyControlledERC20(_float);

    // Basket
    basket = IBasketReader(_basket);

    // Monetary Policy
    monetaryPolicy = IMonetaryPolicy(_monetaryPolicy);
    floatEthOracle = ITwap(_floatEthOracle);
    bankEthOracle = ITwap(_bankEthOracle);

    emit ModifyParameters("monetaryPolicy", _monetaryPolicy);
    emit ModifyParameters("floatEthOracle", _floatEthOracle);
    emit ModifyParameters("bankEthOracle", _bankEthOracle);

    emit ModifyParameters("auctionDuration", _auctionDuration);
    emit ModifyParameters("auctionCooldown", _auctionCooldown);
    emit ModifyParameters("lastAuctionBlock", lastAuctionBlock);
    emit ModifyParameters("buffer", buffer);
    emit ModifyParameters("protocolFee", protocolFee);
    emit ModifyParameters("allowanceCap", allowanceCap);

    // Roles
    _setupRole(DEFAULT_ADMIN_ROLE, _gov);
    _setupRole(GOVERNANCE_ROLE, _gov);
    _setupRole(RECOVER_ROLE, _gov);
  }

  /* ========== MODIFIERS ========== */

  modifier onlyGovernance {
    require(
      hasRole(GOVERNANCE_ROLE, _msgSender()),
      "AuctionHouse/GovernanceRole"
    );
    _;
  }

  modifier inExpansion {
    require(
      latestAuction().stabilisationCase == Cases.Up ||
        latestAuction().stabilisationCase == Cases.Restock,
      "AuctionHouse/NotInExpansion"
    );
    _;
  }

  modifier inContraction {
    require(
      latestAuction().stabilisationCase == Cases.Confidence ||
        latestAuction().stabilisationCase == Cases.Down,
      "AuctionHouse/NotInContraction"
    );
    _;
  }

  /* ========== VIEWS ========== */

  /// @inheritdoc IAuctionHouseDerivedState
  function price()
    public
    view
    override(IAuctionHouseDerivedState)
    returns (uint256 wethPrice, uint256 bankPrice)
  {
    Auction memory _latestAuction = latestAuction();
    uint256 _step = step();

    wethPrice = lerp(
      _latestAuction.startWethPrice,
      _latestAuction.endWethPrice,
      _step,
      auctionDuration
    );
    bankPrice = lerp(
      _latestAuction.startBankPrice,
      _latestAuction.endBankPrice,
      _step,
      auctionDuration
    );
    return (wethPrice, bankPrice);
  }

  /// @inheritdoc IAuctionHouseDerivedState
  function step()
    public
    view
    override(IAuctionHouseDerivedState)
    atStage(Stages.AuctionActive)
    returns (uint256)
  {
    // .sub is unnecessary here - block number >= lastAuctionBlock.
    return _blockNumber() - lastAuctionBlock;
  }

  function _startPrice(
    bool expansion,
    Cases stabilisationCase,
    uint256 targetFloatInEth,
    uint256 marketFloatInEth,
    uint256 bankInEth,
    uint256 basketFactor
  ) internal view returns (uint256 wethStart, uint256 bankStart) {
    uint256 bufferedMarketPrice =
      _bufferedMarketPrice(expansion, marketFloatInEth);

    if (stabilisationCase == Cases.Up) {
      uint256 bankProportion =
        bufferedMarketPrice.sub(targetFloatInEth).divideDecimalRoundPrecise(
          bankInEth
        );

      return (targetFloatInEth, bankProportion);
    }

    if (
      stabilisationCase == Cases.Restock ||
      stabilisationCase == Cases.Confidence
    ) {
      return (bufferedMarketPrice, 0);
    }

    assert(stabilisationCase == Cases.Down);
    assert(basketFactor < SafeDecimalMath.PRECISE_UNIT);
    uint256 invertedBasketFactor =
      SafeDecimalMath.PRECISE_UNIT.sub(basketFactor);

    uint256 basketFactorAdjustedEth =
      bufferedMarketPrice.multiplyDecimalRoundPrecise(basketFactor);

    // Note that the PRECISE_UNIT factors itself out
    uint256 basketFactorAdjustedBank =
      bufferedMarketPrice.mul(invertedBasketFactor).div(bankInEth);
    return (basketFactorAdjustedEth, basketFactorAdjustedBank);
  }

  function _endPrice(
    Cases stabilisationCase,
    uint256 targetFloatInEth,
    uint256 bankInEth,
    uint256 basketFactor
  ) internal pure returns (uint256 wethEnd, uint256 bankEnd) {
    if (stabilisationCase == Cases.Down) {
      assert(basketFactor < SafeDecimalMath.PRECISE_UNIT);
      uint256 invertedBasketFactor =
        SafeDecimalMath.PRECISE_UNIT.sub(basketFactor);

      uint256 basketFactorAdjustedEth =
        targetFloatInEth.multiplyDecimalRoundPrecise(basketFactor);

      // Note that the PRECISE_UNIT factors itself out.
      uint256 basketFactorAdjustedBank =
        targetFloatInEth.mul(invertedBasketFactor).div(bankInEth);
      return (basketFactorAdjustedEth, basketFactorAdjustedBank);
    }

    return (targetFloatInEth, 0);
  }

  /// @inheritdoc IAuctionHouseDerivedState
  function latestAuction()
    public
    view
    override(IAuctionHouseDerivedState)
    returns (Auction memory)
  {
    return auctions[round];
  }

  /// @dev Returns a buffered [e27] market price, note that buffer is still [e18], so can use divideDecimal.
  function _bufferedMarketPrice(bool expansion, uint256 marketPrice)
    internal
    view
    returns (uint256)
  {
    uint256 factor =
      expansion
        ? BasisMath.FULL_PERCENT.add(buffer)
        : BasisMath.FULL_PERCENT.sub(buffer);
    return marketPrice.percentageOf(factor);
  }

  /// @dev Calculates the current case based on if we're expanding and basket factor.
  function _currentCase(bool expansion, uint256 basketFactor)
    internal
    pure
    returns (Cases)
  {
    bool underlyingDemand = basketFactor >= SafeDecimalMath.PRECISE_UNIT;

    if (expansion) {
      return underlyingDemand ? Cases.Up : Cases.Restock;
    }

    return underlyingDemand ? Cases.Confidence : Cases.Down;
  }

  /* |||||||||| AuctionPending |||||||||| */

  // solhint-disable function-max-lines
  /// @inheritdoc IAuctionHouseActions
  function start()
    external
    override(IAuctionHouseActions)
    timedTransition
    atStage(Stages.AuctionPending)
    returns (uint64 newRound)
  {
    // Check we have up to date oracles, this also ensures we don't have
    // auctions too close together (reverts based upon timeElapsed < periodSize).
    bankEthOracle.update(address(bank), address(weth));
    floatEthOracle.update(address(float), address(weth));

    // [e27]
    uint256 frozenBankInEth =
      bankEthOracle.consult(
        address(bank),
        SafeDecimalMath.PRECISE_UNIT,
        address(weth)
      );
    // [e27]
    uint256 frozenFloatInEth =
      floatEthOracle.consult(
        address(float),
        SafeDecimalMath.PRECISE_UNIT,
        address(weth)
      );

    // Update Monetary Policy with previous auction results
    if (round != 0 && shouldUpdatePolicy) {
      uint256 oldTargetPriceInEth = monetaryPolicy.consult();
      uint256 oldBasketFactor = basket.getBasketFactor(oldTargetPriceInEth);

      monetaryPolicy.updateGivenAuctionResults(
        round,
        lastAuctionBlock,
        frozenFloatInEth,
        oldBasketFactor
      );
    }

    // Round only increments by one on start, given auction period of restriction of 150 blocks
    // this means we'd need 2**64 / 150 blocks or ~3.7 lifetimes of the universe to overflow.
    // Likely, we'd have upgraded the contract by this point.
    round++;

    // Calculate target price [e27]
    uint256 frozenTargetPriceInEth = monetaryPolicy.consult();

    // STC: Pull out to ValidateOracles
    require(frozenTargetPriceInEth != 0, "AuctionHouse/TargetSenseCheck");
    require(frozenBankInEth != 0, "AuctionHouse/BankSenseCheck");
    require(frozenFloatInEth != 0, "AuctionHouse/FloatSenseCheck");
    uint256 basketFactor = basket.getBasketFactor(frozenTargetPriceInEth);

    bool expansion = frozenFloatInEth >= frozenTargetPriceInEth;
    Cases stabilisationCase = _currentCase(expansion, basketFactor);

    // Calculate Auction Price points
    (uint256 wethStart, uint256 bankStart) =
      _startPrice(
        expansion,
        stabilisationCase,
        frozenTargetPriceInEth,
        frozenFloatInEth,
        frozenBankInEth,
        basketFactor
      );

    (uint256 wethEnd, uint256 bankEnd) =
      _endPrice(
        stabilisationCase,
        frozenTargetPriceInEth,
        frozenBankInEth,
        basketFactor
      );

    // Calculate Allowance
    uint256 allowance =
      AuctionHouseMath.allowance(
        expansion,
        allowanceCap,
        float.totalSupply(),
        frozenFloatInEth,
        frozenTargetPriceInEth
      );

    require(allowance != 0, "AuctionHouse/NoAllowance");

    auctions[round].stabilisationCase = stabilisationCase;
    auctions[round].targetFloatInEth = frozenTargetPriceInEth;
    auctions[round].marketFloatInEth = frozenFloatInEth;
    auctions[round].bankInEth = frozenBankInEth;

    auctions[round].basketFactor = basketFactor;
    auctions[round].allowance = allowance;

    auctions[round].startWethPrice = wethStart;
    auctions[round].startBankPrice = bankStart;
    auctions[round].endWethPrice = wethEnd;
    auctions[round].endBankPrice = bankEnd;

    lastAuctionBlock = _blockNumber();
    _setStage(Stages.AuctionActive);

    emit NewAuction(round, allowance, frozenTargetPriceInEth, lastAuctionBlock);

    return round;
  }

  // solhint-enable function-max-lines

  /* |||||||||| AuctionActive |||||||||| */

  function _updateDelta(uint256 floatDelta) internal {
    Auction memory _currentAuction = latestAuction();

    require(
      floatDelta <= _currentAuction.allowance.sub(_currentAuction.delta),
      "AuctionHouse/WithinAllowedDelta"
    );

    auctions[round].delta = _currentAuction.delta.add(floatDelta);
  }

  /* |||||||||| AuctionActive:inExpansion |||||||||| */

  /// @inheritdoc IAuctionHouseActions
  function buy(
    uint256 wethInMax,
    uint256 bankInMax,
    uint256 floatOutMin,
    address to,
    uint256 deadline
  )
    external
    override(IAuctionHouseActions)
    timedTransition
    atStage(Stages.AuctionActive)
    inExpansion
    returns (
      uint256 usedWethIn,
      uint256 usedBankIn,
      uint256 usedFloatOut
    )
  {
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp <= deadline, "AuctionHouse/TransactionTooOld");

    (uint256 wethPrice, uint256 bankPrice) = price();

    usedFloatOut = Math.min(
      wethInMax.divideDecimalRoundPrecise(wethPrice),
      bankPrice == 0
        ? type(uint256).max
        : bankInMax.divideDecimalRoundPrecise(bankPrice)
    );

    require(usedFloatOut != 0, "AuctionHouse/ZeroFloatBought");
    require(usedFloatOut >= floatOutMin, "AuctionHouse/RequestedTooMuch");

    usedWethIn = wethPrice.multiplyDecimalRoundPrecise(usedFloatOut);
    usedBankIn = bankPrice.multiplyDecimalRoundPrecise(usedFloatOut);

    require(wethInMax >= usedWethIn, "AuctionHouse/MinimumWeth");
    require(bankInMax >= usedBankIn, "AuctionHouse/MinimumBank");

    _updateDelta(usedFloatOut);

    emit Buy(round, _msgSender(), usedWethIn, usedBankIn, usedFloatOut);

    _interactBuy(usedWethIn, usedBankIn, usedFloatOut, to);

    return (usedWethIn, usedBankIn, usedFloatOut);
  }

  function _interactBuy(
    uint256 usedWethIn,
    uint256 usedBankIn,
    uint256 usedFloatOut,
    address to
  ) internal {
    weth.safeTransferFrom(_msgSender(), address(basket), usedWethIn);

    if (usedBankIn != 0) {
      (uint256 bankToSave, uint256 bankToBurn) =
        usedBankIn.splitBy(protocolFee);

      bank.safeTransferFrom(_msgSender(), address(this), bankToSave);
      bank.safeBurnFrom(_msgSender(), bankToBurn);
    }

    float.safeMint(to, usedFloatOut);
  }

  /* |||||||||| AuctionActive:inContraction |||||||||| */

  /// @inheritdoc IAuctionHouseActions
  function sell(
    uint256 floatIn,
    uint256 wethOutMin,
    uint256 bankOutMin,
    address to,
    uint256 deadline
  )
    external
    override(IAuctionHouseActions)
    timedTransition
    atStage(Stages.AuctionActive)
    inContraction
    returns (
      uint256 usedfloatIn,
      uint256 usedWethOut,
      uint256 usedBankOut
    )
  {
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp <= deadline, "AuctionHouse/TransactionTooOld");
    require(floatIn != 0, "AuctionHouse/ZeroFloatSold");

    (uint256 wethPrice, uint256 bankPrice) = price();

    usedWethOut = wethPrice.multiplyDecimalRoundPrecise(floatIn);
    usedBankOut = bankPrice.multiplyDecimalRoundPrecise(floatIn);

    require(wethOutMin <= usedWethOut, "AuctionHouse/ExpectedTooMuchWeth");
    require(bankOutMin <= usedBankOut, "AuctionHouse/ExpectedTooMuchBank");

    _updateDelta(floatIn);

    emit Sell(round, _msgSender(), floatIn, usedWethOut, usedBankOut);

    _interactSell(floatIn, usedWethOut, usedBankOut, to);

    return (floatIn, usedWethOut, usedBankOut);
  }

  function _interactSell(
    uint256 floatIn,
    uint256 usedWethOut,
    uint256 usedBankOut,
    address to
  ) internal {
    float.safeBurnFrom(_msgSender(), floatIn);

    if (usedWethOut != 0) {
      weth.safeTransferFrom(address(basket), to, usedWethOut);
    }

    if (usedBankOut != 0) {
      // STC: Maximum mint checks relative to allowance
      bank.safeMint(to, usedBankOut);
    }
  }

  /* |||||||||| AuctionCooldown, AuctionPending, AuctionActive |||||||||| */

  /* ========== RESTRICTED FUNCTIONS ========== */

  /* ----- onlyGovernance ----- */

  /// @inheritdoc IAuctionHouseGovernedActions
  function modifyParameters(bytes32 parameter, uint256 data)
    external
    override(IAuctionHouseGovernedActions)
    onlyGovernance
  {
    if (parameter == "auctionDuration") {
      require(data <= type(uint16).max, "AuctionHouse/ModADMax");
      require(data != 0, "AuctionHouse/ModADZero");
      auctionDuration = uint16(data);
    } else if (parameter == "auctionCooldown") {
      require(data <= type(uint32).max, "AuctionHouse/ModCMax");
      auctionCooldown = uint32(data);
    } else if (parameter == "buffer") {
      // 0% <= buffer <= 1000%
      require(data <= 10 * BasisMath.FULL_PERCENT, "AuctionHouse/ModBMax");
      buffer = uint16(data);
    } else if (parameter == "protocolFee") {
      // 0% <= protocolFee <= 100%
      require(data <= BasisMath.FULL_PERCENT, "AuctionHouse/ModPFMax");
      protocolFee = uint16(data);
    } else if (parameter == "allowanceCap") {
      // 0% < allowanceCap <= N ~ 1_000%
      require(data <= type(uint32).max, "AuctionHouse/ModACMax");
      require(data != 0, "AuctionHouse/ModACMin");
      allowanceCap = uint32(data);
    } else if (parameter == "shouldUpdatePolicy") {
      require(data == 1 || data == 0, "AuctionHouse/ModUP");
      shouldUpdatePolicy = data == 1;
    } else if (parameter == "lastAuctionBlock") {
      // We wouldn't want to disable auctions for more than ~4.3 weeks
      // A longer period should result in a "burnt" auction house and redeploy.
      require(data <= block.number + 2e5, "AuctionHouse/ModLABMax");
      require(data != 0, "AuctionHouse/ModLABMin");
      // Can be used to pause auctions if set in the future.
      lastAuctionBlock = data;
    } else revert("AuctionHouse/InvalidParameter");

    emit ModifyParameters(parameter, data);
  }

  /// @inheritdoc IAuctionHouseGovernedActions
  function modifyParameters(bytes32 parameter, address data)
    external
    override(IAuctionHouseGovernedActions)
    onlyGovernance
  {
    if (parameter == "monetaryPolicy") {
      // STC: Sense check
      monetaryPolicy = IMonetaryPolicy(data);
    } else if (parameter == "bankEthOracle") {
      // STC: Sense check
      bankEthOracle = ITwap(data);
    } else if (parameter == "floatEthOracle") {
      // STC: Sense check
      floatEthOracle = ITwap(data);
    } else revert("AuctionHouse/InvalidParameter");

    emit ModifyParameters(parameter, data);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
pragma solidity =0.7.6;

import "../lib/BlockNumber.sol";

contract Staged is BlockNumber {
  /**
   * @dev The current auction stage.
   * - AuctionCooling - We cannot start an auction due to Cooling Period.
   * - AuctionPending - We can start an auction at any time.
   * - AuctionActive - Auction is ongoing.
   */
  enum Stages {AuctionCooling, AuctionPending, AuctionActive}

  /* ========== STATE VARIABLES ========== */

  /**
   * @dev The cooling period between each auction in blocks.
   */
  uint32 internal auctionCooldown;

  /**
   * @dev The length of the auction in blocks.
   */
  uint16 internal auctionDuration;

  /**
   * @notice The current stage
   */
  Stages public stage;

  /**
   * @notice Block number when the last auction started.
   */
  uint256 public lastAuctionBlock;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    uint16 _auctionDuration,
    uint32 _auctionCooldown,
    uint256 _firstAuctionBlock
  ) {
    require(
      _firstAuctionBlock >= _auctionDuration + _auctionCooldown,
      "Staged/InvalidAuctionStart"
    );

    auctionDuration = _auctionDuration;
    auctionCooldown = _auctionCooldown;
    lastAuctionBlock = _firstAuctionBlock - _auctionDuration - _auctionCooldown;
    stage = Stages.AuctionCooling;
  }

  /* ============ Events ============ */

  event StageChanged(uint8 _prevStage, uint8 _newStage);

  /* ========== MODIFIERS ========== */

  modifier atStage(Stages _stage) {
    require(stage == _stage, "Staged/InvalidStage");
    _;
  }

  /**
   * @dev Modify the stages as necessary on call.
   */
  modifier timedTransition() {
    uint256 _blockNumber = _blockNumber();

    if (
      stage == Stages.AuctionActive &&
      _blockNumber > lastAuctionBlock + auctionDuration
    ) {
      stage = Stages.AuctionCooling;
      emit StageChanged(uint8(Stages.AuctionActive), uint8(stage));
    }
    // Note that this can cascade so AuctionActive -> AuctionPending in one update, when auctionCooldown = 0.
    if (
      stage == Stages.AuctionCooling &&
      _blockNumber > lastAuctionBlock + auctionDuration + auctionCooldown
    ) {
      stage = Stages.AuctionPending;
      emit StageChanged(uint8(Stages.AuctionCooling), uint8(stage));
    }

    _;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice Updates the stage, even if a function with timedTransition modifier has not yet been called
   * @return Returns current auction stage
   */
  function updateStage() external timedTransition returns (Stages) {
    return stage;
  }

  /**
   * @dev Set the stage manually.
   */
  function _setStage(Stages _stage) internal {
    Stages priorStage = stage;
    stage = _stage;
    emit StageChanged(uint8(priorStage), uint8(_stage));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/math/Math.sol";

import "../lib/BasisMath.sol";
import "../external-lib/SafeDecimalMath.sol";

contract AuctionHouseMath {
  using SafeMath for uint256;
  using SafeDecimalMath for uint256;
  using BasisMath for uint256;

  /**
   * @notice Calculate the maximum allowance for this action to do a price correction
   * This is normally an over-estimate as it assumes all Float is circulating
   * and the market cap is constant through supply changes.
   */
  function allowance(
    bool expansion,
    uint256 capBasisPoint,
    uint256 floatSupply,
    uint256 marketFloatPrice,
    uint256 targetFloatPrice
  ) internal pure returns (uint256) {
    uint256 targetSupply =
      marketFloatPrice.mul(floatSupply).div(targetFloatPrice);
    uint256 allowanceForAdjustment =
      expansion ? targetSupply.sub(floatSupply) : floatSupply.sub(targetSupply);

    // Cap Allowance per auction; e.g. with 10% of total supply => ~20% price move.
    uint256 allowanceByCap = floatSupply.percentageOf(capBasisPoint);

    return Math.min(allowanceForAdjustment, allowanceByCap);
  }

  /**
   * @notice Linear interpolation: start + (end - start) * (step/duration)
   * @dev For 150 steps, duration = 149, start / end can be in any format
   * as long as <= 10 ** 49.
   * @param start The starting value
   * @param end The ending value
   * @param step Number of blocks into interpolation
   * @param duration Total range
   */
  function lerp(
    uint256 start,
    uint256 end,
    uint256 step,
    uint256 duration
  ) internal pure returns (uint256 result) {
    require(duration != 0, "AuctionHouseMath/ZeroDuration");
    require(step <= duration, "AuctionHouseMath/InvalidStep");

    // Max value <= 2^256 / 10^27 of which 10^49 is.
    require(start <= 10**49, "AuctionHouseMath/StartTooLarge");
    require(end <= 10**49, "AuctionHouseMath/EndTooLarge");

    // 0 <= t <= PRECISE_UNIT
    uint256 t = step.divideDecimalRoundPrecise(duration);

    // result = start + (end - start) * t
    //        = end * t + start - start * t
    return
      result = end.multiplyDecimalRoundPrecise(t).add(start).sub(
        start.multiplyDecimalRoundPrecise(t)
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./ah/IAuctionHouseState.sol";
import "./ah/IAuctionHouseVariables.sol";
import "./ah/IAuctionHouseDerivedState.sol";
import "./ah/IAuctionHouseActions.sol";
import "./ah/IAuctionHouseGovernedActions.sol";
import "./ah/IAuctionHouseEvents.sol";

/**
 * @title The interface for a Float Protocol Auction House
 * @notice The Auction House enables the sale and buy of FLOAT tokens from the
 * market in order to stabilise price.
 * @dev The Auction House interface is broken up into many smaller pieces
 */
interface IAuctionHouse is
  IAuctionHouseState,
  IAuctionHouseVariables,
  IAuctionHouseDerivedState,
  IAuctionHouseActions,
  IAuctionHouseGovernedActions,
  IAuctionHouseEvents
{

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IBasketReader {
  /**
   * @notice Underlying token that is kept in this Basket
   */
  function underlying() external view returns (address);

  /**
   * @notice Given a target price, what is the basket factor
   * @param targetPriceInUnderlying the current target price to calculate the
   * basket factor for in the units of the underlying token.
   */
  function getBasketFactor(uint256 targetPriceInUnderlying)
    external
    view
    returns (uint256 basketFactor);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

interface ITwap {
  /**
   * @notice Returns the amount out corresponding to the amount in for a given token using the moving average over time range [`block.timestamp` - [`windowSize`, `windowSize - periodSize * 2`], `block.timestamp`].
   * E.g. with a windowSize = 24hrs, periodSize = 6hrs.
   * [24hrs ago to 12hrs ago, now]
   * @dev Update must have been called for the bucket corresponding to the timestamp `now - windowSize`
   * @param tokenIn the address of the token we are offering
   * @param amountIn the quantity of tokens we are pricing
   * @param tokenOut the address of the token we want
   * @return amountOut the `tokenOut` amount corresponding to the `amountIn` for `tokenIn` over the time range
   */
  function consult(
    address tokenIn,
    uint256 amountIn,
    address tokenOut
  ) external view returns (uint256 amountOut);

  /**
   * @notice Checks if a particular pair can be updated
   * @param tokenA Token A of pair (any order)
   * @param tokenB Token B of pair (any order)
   * @return If an update call will succeed
   */
  function updateable(address tokenA, address tokenB)
    external
    view
    returns (bool);

  /**
   * @notice Update the cumulative price for the observation at the current timestamp. Each observation is updated at most once per epoch period.
   * @param tokenA the first token to create pair from
   * @param tokenB the second token to create pair from
   * @return if the observation was updated or not.
   */
  function update(address tokenA, address tokenB) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

interface IMonetaryPolicy {
  /**
   * @notice Consult the monetary policy for the target price in eth
   */
  function consult() external view returns (uint256 targetPriceInEth);

  /**
   * @notice Update the Target price given the auction results.
   * @dev 0 values are used to indicate missing data.
   */
  function updateGivenAuctionResults(
    uint256 round,
    uint256 lastAuctionBlock,
    uint256 floatMarketPrice,
    uint256 basketFactor
  ) external returns (uint256 targetPriceInEth);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISupplyControlledERC20 is IERC20 {
  /**
   * @dev Creates `amount` new tokens for `to`.
   *
   * See {ERC20-_mint}.
   *
   * Requirements:
   * - the caller must have the `MINTER_ROLE`.
   */
  function mint(address to, uint256 amount) external;

  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {ERC20-_burn}.
   */
  function burn(uint256 amount) external;

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * See {ERC20-_burn}.
   */
  function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

/**
 * @title Basis Mathematics
 * @notice Provides helpers to perform percentage calculations
 * @dev Percentages are [e2] i.e. with 2 decimals precision / basis point.
 */
library BasisMath {
  uint256 internal constant FULL_PERCENT = 1e4; // 100.00% / 1000 bp
  uint256 internal constant HALF_ONCE_SCALED = FULL_PERCENT / 2;

  /**
   * @dev Percentage pct, round 0.5+ up.
   * @param self The value to take a percentage pct
   * @param percentage The percentage to be calculated [e2]
   * @return pct self * percentage
   */
  function percentageOf(uint256 self, uint256 percentage)
    internal
    pure
    returns (uint256 pct)
  {
    if (self == 0 || percentage == 0) {
      pct = 0;
    } else {
      require(
        self <= (type(uint256).max - HALF_ONCE_SCALED) / percentage,
        "BasisMath/Overflow"
      );

      pct = (self * percentage + HALF_ONCE_SCALED) / FULL_PERCENT;
    }
  }

  /**
   * @dev Split value into percentage, round 0.5+ up.
   * @param self The value to split
   * @param percentage The percentage to be calculated [e2]
   * @return pct The percentage of the value
   * @return rem Anything leftover from the value
   */
  function splitBy(uint256 self, uint256 percentage)
    internal
    pure
    returns (uint256 pct, uint256 rem)
  {
    require(percentage <= FULL_PERCENT, "BasisMath/ExcessPercentage");
    pct = percentageOf(self, percentage);
    rem = self - pct;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

/// @title Function for getting block number
/// @dev Base contract that is overridden for tests
abstract contract BlockNumber {
  /// @dev Method that exists purely to be overridden for tests
  /// @return The current block number
  function _blockNumber() internal view virtual returns (uint256) {
    return block.number;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Recoverable feature
 * @dev should _only_ be used with contracts that should not store assets,
 * but instead interacted with value so there is potential to lose assets.
 */
abstract contract Recoverable is AccessControl {
  using SafeERC20 for IERC20;
  using Address for address payable;

  /* ========== CONSTANTS ========== */
  bytes32 public constant RECOVER_ROLE = keccak256("RECOVER_ROLE");

  /* ============ Events ============ */

  event Recovered(address onBehalfOf, address tokenAddress, uint256 amount);

  /* ========== MODIFIERS ========== */

  modifier isRecoverer {
    require(hasRole(RECOVER_ROLE, _msgSender()), "Recoverable/RecoverRole");
    _;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */
  /* ----- RECOVER_ROLE ----- */

  /**
   * @notice Provide accidental token retrieval.
   * @dev Sourced from synthetix/contracts/StakingRewards.sol
   */
  function recoverERC20(
    address to,
    address tokenAddress,
    uint256 tokenAmount
  ) external isRecoverer {
    emit Recovered(to, tokenAddress, tokenAmount);

    IERC20(tokenAddress).safeTransfer(to, tokenAmount);
  }

  /**
   * @notice Provide accidental ETH retrieval.
   */
  function recoverETH(address to) external isRecoverer {
    uint256 contractBalance = address(this).balance;

    emit Recovered(to, address(0), contractBalance);

    payable(to).sendValue(contractBalance);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

// https://docs.synthetix.io/contracts/source/libraries/safedecimalmath
library SafeDecimalMath {
  using SafeMath for uint256;

  /* Number of decimal places in the representations. */
  uint8 public constant decimals = 18;
  uint8 public constant highPrecisionDecimals = 27;

  /* The number representing 1.0. */
  uint256 public constant UNIT = 10**uint256(decimals);

  /* The number representing 1.0 for higher fidelity numbers. */
  uint256 public constant PRECISE_UNIT = 10**uint256(highPrecisionDecimals);
  uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR =
    10**uint256(highPrecisionDecimals - decimals);

  /**
   * @return Provides an interface to UNIT.
   */
  function unit() external pure returns (uint256) {
    return UNIT;
  }

  /**
   * @return Provides an interface to PRECISE_UNIT.
   */
  function preciseUnit() external pure returns (uint256) {
    return PRECISE_UNIT;
  }

  /**
   * @return The result of multiplying x and y, interpreting the operands as fixed-point
   * decimals.
   *
   * @dev A unit factor is divided out after the product of x and y is evaluated,
   * so that product must be less than 2**256. As this is an integer division,
   * the internal division always rounds down. This helps save on gas. Rounding
   * is more expensive on gas.
   */
  function multiplyDecimal(uint256 x, uint256 y)
    internal
    pure
    returns (uint256)
  {
    /* Divide by UNIT to remove the extra factor introduced by the product. */
    return x.mul(y) / UNIT;
  }

  /**
   * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of the specified precision unit.
   *
   * @dev The operands should be in the form of a the specified unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
  function _multiplyDecimalRound(
    uint256 x,
    uint256 y,
    uint256 precisionUnit
  ) private pure returns (uint256) {
    /* Divide by UNIT to remove the extra factor introduced by the product. */
    uint256 quotientTimesTen = x.mul(y) / (precisionUnit / 10);

    if (quotientTimesTen % 10 >= 5) {
      quotientTimesTen += 10;
    }

    return quotientTimesTen / 10;
  }

  /**
   * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of a precise unit.
   *
   * @dev The operands should be in the precise unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
  function multiplyDecimalRoundPrecise(uint256 x, uint256 y)
    internal
    pure
    returns (uint256)
  {
    return _multiplyDecimalRound(x, y, PRECISE_UNIT);
  }

  /**
   * @return The result of safely multiplying x and y, interpreting the operands
   * as fixed-point decimals of a standard unit.
   *
   * @dev The operands should be in the standard unit factor which will be
   * divided out after the product of x and y is evaluated, so that product must be
   * less than 2**256.
   *
   * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
   * Rounding is useful when you need to retain fidelity for small decimal numbers
   * (eg. small fractions or percentages).
   */
  function multiplyDecimalRound(uint256 x, uint256 y)
    internal
    pure
    returns (uint256)
  {
    return _multiplyDecimalRound(x, y, UNIT);
  }

  /**
   * @return The result of safely dividing x and y. The return value is a high
   * precision decimal.
   *
   * @dev y is divided after the product of x and the standard precision unit
   * is evaluated, so the product of x and UNIT must be less than 2**256. As
   * this is an integer division, the result is always rounded down.
   * This helps save on gas. Rounding is more expensive on gas.
   */
  function divideDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
    /* Reintroduce the UNIT factor that will be divided out by y. */
    return x.mul(UNIT).div(y);
  }

  /**
   * @return The result of safely dividing x and y. The return value is as a rounded
   * decimal in the precision unit specified in the parameter.
   *
   * @dev y is divided after the product of x and the specified precision unit
   * is evaluated, so the product of x and the specified precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
  function _divideDecimalRound(
    uint256 x,
    uint256 y,
    uint256 precisionUnit
  ) private pure returns (uint256) {
    uint256 resultTimesTen = x.mul(precisionUnit * 10).div(y);

    if (resultTimesTen % 10 >= 5) {
      resultTimesTen += 10;
    }

    return resultTimesTen / 10;
  }

  /**
   * @return The result of safely dividing x and y. The return value is as a rounded
   * standard precision decimal.
   *
   * @dev y is divided after the product of x and the standard precision unit
   * is evaluated, so the product of x and the standard precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
  function divideDecimalRound(uint256 x, uint256 y)
    internal
    pure
    returns (uint256)
  {
    return _divideDecimalRound(x, y, UNIT);
  }

  /**
   * @return The result of safely dividing x and y. The return value is as a rounded
   * high precision decimal.
   *
   * @dev y is divided after the product of x and the high precision unit
   * is evaluated, so the product of x and the high precision unit must
   * be less than 2**256. The result is rounded to the nearest increment.
   */
  function divideDecimalRoundPrecise(uint256 x, uint256 y)
    internal
    pure
    returns (uint256)
  {
    return _divideDecimalRound(x, y, PRECISE_UNIT);
  }

  /**
   * @dev Convert a standard decimal representation to a high precision one.
   */
  function decimalToPreciseDecimal(uint256 i) internal pure returns (uint256) {
    return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
  }

  /**
   * @dev Convert a high precision decimal to a standard decimal representation.
   */
  function preciseDecimalToDecimal(uint256 i) internal pure returns (uint256) {
    uint256 quotientTimesTen =
      i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

    if (quotientTimesTen % 10 >= 5) {
      quotientTimesTen += 10;
    }

    return quotientTimesTen / 10;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "../tokens/interfaces/ISupplyControlledERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @title SafeSupplyControlledERC20
 * @dev Wrappers around Supply Controlled ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 */
library SafeSupplyControlledERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeBurnFrom(
    ISupplyControlledERC20 token,
    address from,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.burnFrom.selector, from, value)
    );
  }

  function safeMint(
    ISupplyControlledERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.mint.selector, to, value)
    );
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

    bytes memory returndata =
      address(token).functionCall(
        data,
        "SafeSupplyControlled/LowlevelCallFailed"
      );
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(
        abi.decode(returndata, (bool)),
        "SafeSupplyControlled/ERC20Failed"
      );
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
pragma solidity >=0.5.0;

/// @title Auction House state that can change by governance.
/// @notice These methods provide vision on specific state that could be used in wrapper contracts.
interface IAuctionHouseState {
  /**
   * @notice The buffer around the starting price to handle mispriced / stale oracles.
   * @dev Basis point
   * Starts at 10% / 1e3 so market price is buffered by 110% or 90%
   */
  function buffer() external view returns (uint16);

  /**
   * @notice The fee taken by the protocol.
   * @dev Basis point
   */
  function protocolFee() external view returns (uint16);

  /**
   * @notice The cap based on total FLOAT supply to change in a single auction. E.g. 10% cap => absolute max of 10% of total supply can be minted / burned
   * @dev Basis point
   */
  function allowanceCap() external view returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./ICases.sol";

/// @title Auction House state that can change
/// @notice These methods compose the auctions state, and will change per action.
interface IAuctionHouseVariables is ICases {
  /**
   * @notice The number of auctions since inception.
   */
  function round() external view returns (uint64);

  /**
   * @notice Returns data about a specific auction.
   * @param roundNumber The round number for the auction array to fetch
   * @return stabilisationCase The Auction struct including case
   */
  function auctions(uint64 roundNumber)
    external
    view
    returns (
      Cases stabilisationCase,
      uint256 targetFloatInEth,
      uint256 marketFloatInEth,
      uint256 bankInEth,
      uint256 startWethPrice,
      uint256 startBankPrice,
      uint256 endWethPrice,
      uint256 endBankPrice,
      uint256 basketFactor,
      uint256 delta,
      uint256 allowance
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IAuction.sol";

/// @title Auction House state that can change
/// @notice These methods are derived from the IAuctionHouseState.
interface IAuctionHouseDerivedState is IAuction {
  /**
   * @notice The price (that the Protocol with expect on expansion, and give on Contraction) for 1 FLOAT
   * @dev Under cases, this value is used differently:
   * - Contraction, Protocol buys FLOAT for pair.
   * - Expansion, Protocol sells FLOAT for pair.
   * @return wethPrice [e27] Expected price in wETH.
   * @return bankPrice [e27] Expected price in BANK.
   */
  function price() external view returns (uint256 wethPrice, uint256 bankPrice);

  /**
   * @notice The current step through the auction.
   * @dev block numbers since auction start (0 indexed)
   */
  function step() external view returns (uint256);

  /**
   * @notice Latest Auction alias
   */
  function latestAuction() external view returns (Auction memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

/// @title Open Auction House actions
/// @notice Contains all actions that can be called by anyone
interface IAuctionHouseActions {
  /**
   * @notice Starts an auction
   * @dev This will:
   * - update the oracles
   * - calculate the target price
   * - check stabilisation case
   * - create allowance.
   * - Set start / end prices of the auction
   */
  function start() external returns (uint64 newRound);

  /**
   * @notice Buy for an amount of <WETH, BANK> for as much FLOAT tokens as possible.
   * @dev Expansion, Protocol sells FLOAT for pair.
    As the price descends there should be no opportunity for slippage causing failure
    `msg.sender` should already have given the auction allowance for at least `wethIn` and `bankIn`.
   * `wethInMax` / `bankInMax` < 2**256 / 10**18, assumption is that totalSupply
   * doesn't exceed type(uint128).max
   * @param wethInMax The max amount of WETH to send (takes maximum from given ratio).
   * @param bankInMax The max amount of BANK to send (takes maximum from given ratio).
   * @param floatOutMin The minimum amount of FLOAT that must be received for this transaction not to revert.
   * @param to Recipient of the FLOAT.
   * @param deadline Unix timestamp after which the transaction will revert.
   */
  function buy(
    uint256 wethInMax,
    uint256 bankInMax,
    uint256 floatOutMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 usedWethIn,
      uint256 usedBankIn,
      uint256 usedFloatOut
    );

  /**
   * @notice Sell an amount of FLOAT for the given reward tokens.
   * @dev Contraction, Protocol buys FLOAT for pair. `msg.sender` should already have given the auction allowance for at least `floatIn`.
   * @param floatIn The amount of FLOAT to sell.
   * @param wethOutMin The minimum amount of WETH that can be received before the transaction reverts.
   * @param bankOutMin The minimum amount of BANK that can be received before the tranasction reverts.
   * @param to Recipient of <WETH, BANK>.
   * @param deadline Unix timestamp after which the transaction will revert.
   */
  function sell(
    uint256 floatIn,
    uint256 wethOutMin,
    uint256 bankOutMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 usedfloatIn,
      uint256 usedWethOut,
      uint256 usedBankOut
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

/// @title Auction House actions that require certain level of privilege
/// @notice Contains Auction House methods that may only be called by controller
interface IAuctionHouseGovernedActions {
  /**
   * @notice Modify a uint256 parameter
   * @param parameter The parameter name to modify
   * @param data New value for the parameter
   */
  function modifyParameters(bytes32 parameter, uint256 data) external;

  /**
   * @notice Modify an address parameter
   * @param parameter The parameter name to modify
   * @param data New address for the parameter
   */
  function modifyParameters(bytes32 parameter, address data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

/// @title Events emitted by the auction house
/// @notice Contains all events emitted by the auction house
interface IAuctionHouseEvents {
  event NewAuction(
    uint256 indexed round,
    uint256 allowance,
    uint256 targetFloatInEth,
    uint256 startBlock
  );
  event Buy(
    uint256 indexed round,
    address indexed buyer,
    uint256 wethIn,
    uint256 bankIn,
    uint256 floatOut
  );
  event Sell(
    uint256 indexed round,
    address indexed seller,
    uint256 floatIn,
    uint256 wethOut,
    uint256 bankOut
  );
  event ModifyParameters(bytes32 parameter, uint256 data);
  event ModifyParameters(bytes32 parameter, address data);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

interface ICases {
  /**
   * @dev The Stabilisation Cases
   * Up (Expansion) - Estimated market price >= target price & Basket Factor >= 1.
   * Restock (Expansion) - Estimated market price >= target price & Basket Factor < 1.
   * Confidence (Contraction) - Estimated market price < target price & Basket Factor >= 1.
   * Down (Contraction) - Estimated market price < target price & Basket Factor < 1.
   */
  enum Cases {Up, Restock, Confidence, Down}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./ICases.sol";

interface IAuction is ICases {
  /**
   * The current Stabilisation Case
   * Auction's target price.
   * Auction's floatInEth price.
   * Auction's bankInEth price.
   * Auction's basket factor.
   * Auction's used float delta.
   * Auction's allowed float delta (how much FLOAT can be created or burned).
   */
  struct Auction {
    Cases stabilisationCase;
    uint256 targetFloatInEth;
    uint256 marketFloatInEth;
    uint256 bankInEth;
    uint256 startWethPrice;
    uint256 startBankPrice;
    uint256 endWethPrice;
    uint256 endBankPrice;
    uint256 basketFactor;
    uint256 delta;
    uint256 allowance;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import "../AuctionHouse.sol";

contract AuctionHouseHarness is AuctionHouse {
  uint256 public blockNumber;

  constructor(
    // Dependencies
    address _weth,
    address _bank,
    address _float,
    address _basket,
    address _monetaryPolicy,
    address _gov,
    address _bankEthOracle,
    address _floatEthOracle,
    // Parameters
    uint16 _auctionDuration,
    uint32 _auctionCooldown,
    uint256 _firstAuctionBlock
  )
    AuctionHouse(
      _weth,
      _bank,
      _float,
      _basket,
      _monetaryPolicy,
      _gov,
      _bankEthOracle,
      _floatEthOracle,
      _auctionDuration,
      _auctionCooldown,
      _firstAuctionBlock
    )
  {}

  function _blockNumber() internal view override returns (uint256) {
    return blockNumber;
  }

  // Private Var checkers

  function __weth() external view returns (address) {
    return address(weth);
  }

  function __bank() external view returns (address) {
    return address(bank);
  }

  function __float() external view returns (address) {
    return address(float);
  }

  function __basket() external view returns (address) {
    return address(basket);
  }

  function __monetaryPolicy() external view returns (address) {
    return address(monetaryPolicy);
  }

  function __bankEthOracle() external view returns (address) {
    return address(bankEthOracle);
  }

  function __floatEthOracle() external view returns (address) {
    return address(floatEthOracle);
  }

  function __auctionDuration() external view returns (uint16) {
    return auctionDuration;
  }

  function __auctionCooldown() external view returns (uint32) {
    return auctionCooldown;
  }

  function __mine(uint256 _blocks) external {
    blockNumber = blockNumber + _blocks;
  }

  function __setBlock(uint256 _number) external {
    blockNumber = _number;
  }

  function __setCap(uint256 _cap) external {
    allowanceCap = uint32(_cap);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "./interfaces/basket/IBasketReader.sol";
import "./interfaces/IMintingCeremony.sol";

import "../external-lib/SafeDecimalMath.sol";
import "../lib/Recoverable.sol";
import "../lib/Windowed.sol";
import "../tokens/SafeSupplyControlledERC20.sol";
import "../tokens/interfaces/ISupplyControlledERC20.sol";
import "../policy/interfaces/IMonetaryPolicy.sol";

/**
 * @title Minting Ceremony
 * @dev Note that this is recoverable as it should never store any tokens.
 */
contract MintingCeremony is
  IMintingCeremony,
  Windowed,
  Recoverable,
  ReentrancyGuard
{
  using SafeMath for uint256;
  using SafeDecimalMath for uint256;
  using SafeERC20 for IERC20;
  using SafeERC20 for ISupplyControlledERC20;
  using SafeSupplyControlledERC20 for ISupplyControlledERC20;

  /* ========== CONSTANTS ========== */
  uint8 public constant ALLOWANCE_FACTOR = 100;
  uint32 private constant CEREMONY_DURATION = 6 days;

  /* ========== STATE VARIABLES ========== */
  // Monetary Policy Contract that decides the target price
  IMonetaryPolicy internal immutable monetaryPolicy;
  ISupplyControlledERC20 internal immutable float;
  IBasketReader internal immutable basket;

  // Tokens that set allowance
  IERC20[] internal allowanceTokens;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  /**
   * @notice Constructs a new Minting Ceremony
   */
  constructor(
    address governance_,
    address monetaryPolicy_,
    address basket_,
    address float_,
    address[] memory allowanceTokens_,
    uint256 ceremonyStart
  ) Windowed(ceremonyStart, ceremonyStart + CEREMONY_DURATION) {
    require(governance_ != address(0), "MC/ZeroAddress");
    require(monetaryPolicy_ != address(0), "MC/ZeroAddress");
    require(basket_ != address(0), "MC/ZeroAddress");
    require(float_ != address(0), "MC/ZeroAddress");

    monetaryPolicy = IMonetaryPolicy(monetaryPolicy_);
    basket = IBasketReader(basket_);
    float = ISupplyControlledERC20(float_);

    for (uint256 i = 0; i < allowanceTokens_.length; i++) {
      IERC20 allowanceToken = IERC20(allowanceTokens_[i]);
      allowanceToken.balanceOf(address(0)); // Check that this is a valid token

      allowanceTokens.push(allowanceToken);
    }

    _setupRole(RECOVER_ROLE, governance_);
  }

  /* ========== EVENTS ========== */

  event Committed(address indexed user, uint256 amount);
  event Minted(address indexed user, uint256 amount);

  /* ========== VIEWS ========== */

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  function underlying()
    public
    view
    override(IMintingCeremony)
    returns (address)
  {
    return basket.underlying();
  }

  /**
   * @notice The allowance remaining for an account.
   * @dev Based on the current staked balance in `allowanceTokens` and the existing allowance.
   */
  function allowance(address account)
    public
    view
    override(IMintingCeremony)
    returns (uint256 remainingAllowance)
  {
    uint256 stakedBalance = 0;
    for (uint256 i = 0; i < allowanceTokens.length; i++) {
      stakedBalance = stakedBalance.add(allowanceTokens[i].balanceOf(account));
    }
    remainingAllowance = stakedBalance.mul(ALLOWANCE_FACTOR).sub(
      _balances[account]
    );
  }

  /**
   * @notice Simple conversion using monetary policy.
   */
  function quote(uint256 wethIn) public view returns (uint256) {
    uint256 targetPriceInEth = monetaryPolicy.consult();

    require(targetPriceInEth != 0, "MC/MPFailure");

    return wethIn.divideDecimalRoundPrecise(targetPriceInEth);
  }

  /**
   * @notice The amount out accounting for quote & allowance.
   */
  function amountOut(address recipient, uint256 underlyingIn)
    public
    view
    returns (uint256 floatOut)
  {
    // External calls occur here, but trusted
    uint256 floatOutFromPrice = quote(underlyingIn);
    uint256 floatOutFromAllowance = allowance(recipient);

    floatOut = Math.min(floatOutFromPrice, floatOutFromAllowance);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice Commit a quanity of wETH at the current price
   * @dev This is marked non-reentrancy to protect against a malicious
   * allowance token or monetary policy (these are trusted however).
   *
   * - Expects `msg.sender` to give approval to this contract from `basket.underlying()` for at least `underlyingIn`
   *
   * @param recipient The eventual receiver of the float
   * @param underlyingIn The underlying token amount to commit to mint
   * @param floatOutMin The minimum amount of FLOAT that must be received for this transaction not to revert.
   */
  function commit(
    address recipient,
    uint256 underlyingIn,
    uint256 floatOutMin
  )
    external
    override(IMintingCeremony)
    nonReentrant
    inWindow
    returns (uint256 floatOut)
  {
    floatOut = amountOut(recipient, underlyingIn);
    require(floatOut >= floatOutMin, "MC/SlippageOrLowAllowance");
    require(floatOut != 0, "MC/NoAllowance");

    _totalSupply = _totalSupply.add(floatOut);
    _balances[recipient] = _balances[recipient].add(floatOut);

    emit Committed(recipient, floatOut);

    IERC20(underlying()).safeTransferFrom(
      msg.sender,
      address(basket),
      underlyingIn
    );
  }

  /**
   * @notice Release the float to market which has been committed.
   */
  function mint() external override(IMintingCeremony) afterWindow {
    uint256 balance = balanceOf(msg.sender);
    require(balance != 0, "MC/NotDueFloat");

    _totalSupply = _totalSupply.sub(balance);
    _balances[msg.sender] = _balances[msg.sender].sub(balance);

    emit Minted(msg.sender, balance);

    float.safeMint(msg.sender, balance);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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
pragma solidity =0.7.6;

/**
 * @title Minting Ceremony
 */
interface IMintingCeremony {
  function allowance(address account)
    external
    view
    returns (uint256 remainingAllowance);

  function underlying() external view returns (address);

  function commit(
    address recipient,
    uint256 underlyingIn,
    uint256 floatOutMin
  ) external returns (uint256 floatOut);

  function mint() external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

// The Window is time-based so will rely on time, however period > 30 minutes
// minimise the risk of oracle manipulation.
// solhint-disable not-rely-on-time

/**
 * @title A windowed contract
 * @notice Provides a window for actions to occur
 */
contract Windowed {
  /* ========== STATE VARIABLES ========== */

  /**
   * @notice The timestamp of the window start
   */
  uint256 public startWindow;

  /**
   * @notice The timestamp of the window end
   */
  uint256 public endWindow;

  /* ========== CONSTRUCTOR ========== */

  constructor(uint256 _startWindow, uint256 _endWindow) {
    require(_startWindow > block.timestamp, "Windowed/StartInThePast");
    require(_endWindow > _startWindow + 1 days, "Windowed/MustHaveDuration");

    startWindow = _startWindow;
    endWindow = _endWindow;
  }

  /* ========== MODIFIERS ========== */

  modifier inWindow() {
    require(block.timestamp >= startWindow, "Windowed/HasNotStarted");
    require(block.timestamp <= endWindow, "Windowed/HasEnded");
    _;
  }

  modifier afterWindow() {
    require(block.timestamp > endWindow, "Windowed/NotEnded");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../MintingCeremony.sol";

contract MintingCeremonyHarness is MintingCeremony {
  constructor(
    address governance_,
    address monetaryPolicy_,
    address basket_,
    address float_,
    address[] memory allowanceTokens_,
    uint256 ceremonyStart
  )
    MintingCeremony(
      governance_,
      monetaryPolicy_,
      basket_,
      float_,
      allowanceTokens_,
      ceremonyStart
    )
  {}

  function __monetaryPolicy() external view returns (address) {
    return address(monetaryPolicy);
  }

  function __basket() external view returns (address) {
    return address(basket);
  }

  function __float() external view returns (address) {
    return address(float);
  }

  function __allowanceTokens(uint256 idx) external view returns (address) {
    return address(allowanceTokens[idx]);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IMonetaryPolicy.sol";

import "../lib/BlockNumber.sol";
import "../lib/MathHelper.sol";
import "../external-lib/SafeDecimalMath.sol";
import "../oracle/interfaces/IEthUsdOracle.sol";

contract MonetaryPolicyV1 is IMonetaryPolicy, BlockNumber, AccessControl {
  using SafeMath for uint256;
  using SafeDecimalMath for uint256;

  /* ========== CONSTANTS ========== */
  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  bytes32 public constant AUCTION_HOUSE_ROLE = keccak256("AUCTION_HOUSE_ROLE");
  // 0.001$ <= Target Price <= 1000$ as a basic sense check
  uint256 private constant MAX_TARGET_PRICE = 1000e27;
  uint256 private constant MIN_TARGET_PRICE = 0.001e27;

  uint256 private constant MAX_PRICE_DELTA_BOUND = 1e27;
  uint256 private constant DEFAULT_MAX_PRICE_DELTA = 4e27;

  uint256 private constant DEFAULT_MAX_ADJ_PERIOD = 1e6;
  uint256 private constant DEFAULT_MIN_ADJ_PERIOD = 2e5;
  // 150 blocks (auction duration) < T_min < T_max < 10 000 000 (~4yrs)
  uint256 private constant CAP_MAX_ADJ_PERIOD = 1e7;
  uint256 private constant CAP_MIN_ADJ_PERIOD = 150;
  /**
   * @notice The default FLOAT starting price, golden ratio
   * @dev [e27]
   */
  uint256 public constant STARTING_PRICE = 1.618033988749894848204586834e27;

  /* ========== STATE VARIABLES ========== */
  /**
   * @notice The FLOAT target price in USD.
   * @dev [e27]
   */
  uint256 public targetPrice = STARTING_PRICE;

  /**
   * @notice If dynamic pricing is enabled.
   */
  bool public dynamicPricing = true;

  /**
   * @notice Maximum price Delta of 400%
   */
  uint256 public maxPriceDelta = DEFAULT_MAX_PRICE_DELTA;

  /**
   * @notice Maximum adjustment period T_max (Blocks)
   * @dev "How long it takes us to normalise"
   * - T_max => T_min, quicker initial response with higher price changes.
   */
  uint256 public maxAdjustmentPeriod = DEFAULT_MAX_ADJ_PERIOD;

  /**
   * @notice Minimum adjustment period T_min (Blocks)
   * @dev "How quickly we respond to market price changes"
   * - Low T_min, increased tracking.
   */
  uint256 public minAdjustmentPeriod = DEFAULT_MIN_ADJ_PERIOD;

  /**
   * @notice Provides the ETH-USD exchange rate e.g. 1.5e27 would mean 1 ETH = $1.5
   * @dev [e27] decimal fixed point number
   */
  IEthUsdOracle public ethUsdOracle;

  /* ========== CONSTRUCTOR ========== */
  /**
   * @notice Construct a new Monetary Policy
   * @param _governance Governance address (can add new roles & parameter control)
   * @param _ethUsdOracle The [e27] ETH USD price feed.
   */
  constructor(address _governance, address _ethUsdOracle) {
    ethUsdOracle = IEthUsdOracle(_ethUsdOracle);

    // Roles
    _setupRole(DEFAULT_ADMIN_ROLE, _governance);
    _setupRole(GOVERNANCE_ROLE, _governance);
  }

  /* ========== MODIFIERS ========== */

  modifier onlyGovernance {
    require(hasRole(GOVERNANCE_ROLE, msg.sender), "MonetaryPolicy/OnlyGovRole");
    _;
  }

  modifier onlyAuctionHouse {
    require(
      hasRole(AUCTION_HOUSE_ROLE, msg.sender),
      "MonetaryPolicy/OnlyAuctionHouse"
    );
    _;
  }

  /* ========== VIEWS ========== */

  /**
   * @notice Consult monetary policy to get the current target price of FLOAT in ETH
   * @dev [e27]
   */
  function consult() public view override(IMonetaryPolicy) returns (uint256) {
    if (!dynamicPricing) return _toEth(STARTING_PRICE);

    return _toEth(targetPrice);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /* ----- onlyGovernance ----- */

  /**
   * @notice Updates the EthUsdOracle
   * @param _ethUsdOracle The address of the ETH-USD price oracle.
   */
  function setEthUsdOracle(address _ethUsdOracle) external onlyGovernance {
    require(_ethUsdOracle != address(0), "MonetaryPolicyV1/ValidAddress");
    ethUsdOracle = IEthUsdOracle(_ethUsdOracle);
  }

  /**
   * @notice Set the target price of FLOAT
   * @param _targetPrice [e27]
   */
  function setTargetPrice(uint256 _targetPrice) external onlyGovernance {
    require(_targetPrice <= MAX_TARGET_PRICE, "MonetaryPolicyV1/MaxTarget");
    require(_targetPrice >= MIN_TARGET_PRICE, "MonetaryPolicyV1/MinTarget");
    targetPrice = _targetPrice;
  }

  /**
   * @notice Allows dynamic pricing to be turned on / off.
   */
  function setDynamicPricing(bool _dynamicPricing) external onlyGovernance {
    dynamicPricing = _dynamicPricing;
  }

  /**
   * @notice Allows monetary policy parameters to be adjusted.
   */
  function setPolicyParameters(
    uint256 _minAdjustmentPeriod,
    uint256 _maxAdjustmentPeriod,
    uint256 _maxPriceDelta
  ) external onlyGovernance {
    require(
      _minAdjustmentPeriod < _maxAdjustmentPeriod,
      "MonetaryPolicyV1/MinAdjLTMaxAdj"
    );
    require(
      _maxAdjustmentPeriod <= CAP_MAX_ADJ_PERIOD,
      "MonetaryPolicyV1/MaxAdj"
    );
    require(
      _minAdjustmentPeriod >= CAP_MIN_ADJ_PERIOD,
      "MonetaryPolicyV1/MinAdj"
    );
    require(
      _maxPriceDelta >= MAX_PRICE_DELTA_BOUND,
      "MonetaryPolicyV1/MaxDeltaBound"
    );
    minAdjustmentPeriod = _minAdjustmentPeriod;
    maxAdjustmentPeriod = _maxAdjustmentPeriod;
    maxPriceDelta = _maxPriceDelta;
  }

  /* ----- onlyAuctionHouse ----- */

  /**
   * @notice Updates with previous auctions result
   * @dev future:param round Round number
   * @param lastAuctionBlock The last time an auction started.
   * @param floatMarketPriceInEth [e27] The current float market price (ETH)
   * @param basketFactor [e27] The basket factor given the prior target price
   * @return targetPriceInEth [e27]
   */
  function updateGivenAuctionResults(
    uint256,
    uint256 lastAuctionBlock,
    uint256 floatMarketPriceInEth,
    uint256 basketFactor
  ) external override(IMonetaryPolicy) onlyAuctionHouse returns (uint256) {
    // Exit early if this is the first auction
    if (lastAuctionBlock == 0) {
      return consult();
    }

    return
      _updateTargetPrice(lastAuctionBlock, floatMarketPriceInEth, basketFactor);
  }

  /**
   * @dev Converts [e27] USD price, to an [e27] ETH Price
   */
  function _toEth(uint256 price) internal view returns (uint256) {
    uint256 ethInUsd = ethUsdOracle.consult();
    return price.divideDecimalRoundPrecise(ethInUsd);
  }

  /**
   * @dev Updates the $ valued target price, returns the eth valued target price.
   */
  function _updateTargetPrice(
    uint256 _lastAuctionBlock,
    uint256 _floatMarketPriceInEth,
    uint256 _basketFactor
  ) internal returns (uint256) {
    // _toEth pulled out as we do a _fromEth later.
    uint256 ethInUsd = ethUsdOracle.consult();
    uint256 priorTargetPriceInEth =
      targetPrice.divideDecimalRoundPrecise(ethInUsd);

    // Check if basket and FLOAT are moving the same direction
    bool basketFactorDown = _basketFactor < SafeDecimalMath.PRECISE_UNIT;
    bool floatDown = _floatMarketPriceInEth < priorTargetPriceInEth;
    if (basketFactorDown != floatDown) {
      return priorTargetPriceInEth;
    }

    // N.B: block number will always be >= _lastAuctionBlock
    uint256 auctionTimePeriod = _blockNumber().sub(_lastAuctionBlock);

    uint256 normDelta =
      _normalisedDelta(_floatMarketPriceInEth, priorTargetPriceInEth);
    uint256 adjustmentPeriod = _adjustmentPeriod(normDelta);

    // [e27]
    uint256 basketFactorDiff =
      MathHelper.diff(_basketFactor, SafeDecimalMath.PRECISE_UNIT);

    uint256 targetChange =
      priorTargetPriceInEth.multiplyDecimalRoundPrecise(
        basketFactorDiff.mul(auctionTimePeriod).div(adjustmentPeriod)
      );

    // If we have got this far, then we know that market and basket are
    // in the same direction, so basketFactor can be used to choose direction.
    uint256 targetPriceInEth =
      basketFactorDown
        ? priorTargetPriceInEth.sub(targetChange)
        : priorTargetPriceInEth.add(targetChange);

    targetPrice = targetPriceInEth.multiplyDecimalRoundPrecise(ethInUsd);

    return targetPriceInEth;
  }

  function _adjustmentPeriod(uint256 _normDelta)
    internal
    view
    returns (uint256)
  {
    // calculate T, 'the adjustment period', similar to "lookback" as it controls the length of the tail
    // T = T_max - d (T_max - T_min).
    //   = d * T_min + T_max - d * T_max
    // TBC: This doesn't need safety checks
    // T_min <= T <= T_max
    return
      minAdjustmentPeriod
        .multiplyDecimalRoundPrecise(_normDelta)
        .add(maxAdjustmentPeriod)
        .sub(maxAdjustmentPeriod.multiplyDecimalRoundPrecise(_normDelta));
  }

  /**
   * @notice Obtain normalised delta between market and target price
   */
  function _normalisedDelta(
    uint256 _floatMarketPriceInEth,
    uint256 _priorTargetPriceInEth
  ) internal view returns (uint256) {
    uint256 delta =
      MathHelper.diff(_floatMarketPriceInEth, _priorTargetPriceInEth);
    uint256 scaledDelta =
      delta.divideDecimalRoundPrecise(_priorTargetPriceInEth);

    // Invert delta if contraction to flip curve from concave increasing to convex decreasing
    // Also allows for a greater response in expansions than contractions.
    if (_floatMarketPriceInEth < _priorTargetPriceInEth) {
      scaledDelta = scaledDelta.divideDecimalRoundPrecise(
        SafeDecimalMath.PRECISE_UNIT.sub(scaledDelta)
      );
    }

    // Normalise delta based on Dmax -> 0 <= d <= X
    uint256 normDelta = scaledDelta.divideDecimalRoundPrecise(maxPriceDelta);

    // Cap normalised delta 0 <= d <= 1
    if (normDelta > SafeDecimalMath.PRECISE_UNIT) {
      normDelta = SafeDecimalMath.PRECISE_UNIT;
    }

    return normDelta;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

library MathHelper {
  function diff(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x > y ? x - y : y - x;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

interface IEthUsdOracle {
  /**
   * @notice Spot price
   * @return price The latest price as an [e27]
   */
  function consult() external view returns (uint256 price);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/IEthUsdOracle.sol";

contract ChainlinkEthUsdConsumer is IEthUsdOracle {
  using SafeMath for uint256;

  /// @dev Number of decimal places in the representations. */
  uint8 private constant AGGREGATOR_DECIMALS = 8;
  uint8 private constant PRICE_DECIMALS = 27;

  uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR =
    10**uint256(PRICE_DECIMALS - AGGREGATOR_DECIMALS);

  AggregatorV3Interface internal immutable priceFeed;

  /**
   * @notice Construct a new price consumer
   * @dev Source: https://docs.chain.link/docs/ethereum-addresses#config
   */
  constructor(address aggregatorAddress) {
    priceFeed = AggregatorV3Interface(aggregatorAddress);
  }

  /// @inheritdoc IEthUsdOracle
  function consult()
    external
    view
    override(IEthUsdOracle)
    returns (uint256 price)
  {
    (, int256 _price, , , ) = priceFeed.latestRoundData();
    require(_price >= 0, "ChainlinkConsumer/StrangeOracle");
    return (price = uint256(_price).mul(
      UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR
    ));
  }

  /**
   * @notice Retrieves decimals of price feed
   * @dev (`AGGREGATOR_DECIMALS` for ETH-USD by default, scaled up to `PRICE_DECIMALS` here)
   */
  function getDecimals() external pure returns (uint8 decimals) {
    return (decimals = PRICE_DECIMALS);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";
import "../../utils/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

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
    constructor () internal {
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
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "synthetix/contracts/interfaces/IStakingRewards.sol";

import "./RewardDistributionRecipient.sol";

/**
 * @title Phase 2 BANK Reward Pool for Float Protocol
 * @notice This contract is used to reward `rewardToken` when `stakeToken` is staked.
 */
contract Phase2Pool is
  IStakingRewards,
  Context,
  AccessControl,
  RewardDistributionRecipient,
  ReentrancyGuard
{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== CONSTANTS ========== */
  uint256 public constant DURATION = 7 days;
  bytes32 public constant RECOVER_ROLE = keccak256("RECOVER_ROLE");

  /* ========== STATE VARIABLES ========== */
  IERC20 public rewardToken;
  IERC20 public stakeToken;

  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  /* ========== CONSTRUCTOR ========== */

  /**
   * @notice Construct a new Phase2Pool
   * @param _admin The default role controller for
   * @param _rewardDistribution The reward distributor (can change reward rate)
   * @param _rewardToken The reward token to distribute
   * @param _stakingToken The staking token used to qualify for rewards
   */
  constructor(
    address _admin,
    address _rewardDistribution,
    address _rewardToken,
    address _stakingToken
  ) RewardDistributionRecipient(_admin) {
    rewardDistribution = _rewardDistribution;
    rewardToken = IERC20(_rewardToken);
    stakeToken = IERC20(_stakingToken);

    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    _setupRole(RECOVER_ROLE, _admin);
  }

  /* ========== EVENTS ========== */

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event Recovered(address token, uint256 amount);

  /* ========== MODIFIERS ========== */

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  /* ========== VIEWS ========== */

  function totalSupply()
    public
    view
    override(IStakingRewards)
    returns (uint256)
  {
    return _totalSupply;
  }

  function balanceOf(address account)
    public
    view
    override(IStakingRewards)
    returns (uint256)
  {
    return _balances[account];
  }

  function lastTimeRewardApplicable()
    public
    view
    override(IStakingRewards)
    returns (uint256)
  {
    return Math.min(block.timestamp, periodFinish);
  }

  function rewardPerToken()
    public
    view
    override(IStakingRewards)
    returns (uint256)
  {
    if (totalSupply() == 0) {
      return rewardPerTokenStored;
    }

    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable()
          .sub(lastUpdateTime)
          .mul(rewardRate)
          .mul(1e18)
          .div(totalSupply())
      );
  }

  function earned(address account)
    public
    view
    override(IStakingRewards)
    returns (uint256)
  {
    return
      balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
  }

  function getRewardForDuration()
    external
    view
    override(IStakingRewards)
    returns (uint256)
  {
    return rewardRate.mul(DURATION);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */
  function stake(uint256 amount)
    public
    virtual
    override(IStakingRewards)
    updateReward(msg.sender)
  {
    require(amount > 0, "Phase2Pool::stake: Cannot stake 0");

    _totalSupply = _totalSupply.add(amount);
    _balances[msg.sender] = _balances[msg.sender].add(amount);

    stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    emit Staked(msg.sender, amount);
  }

  function withdraw(uint256 amount)
    public
    override(IStakingRewards)
    updateReward(msg.sender)
  {
    require(amount > 0, "Phase2Pool::withdraw: Cannot withdraw 0");
    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    stakeToken.safeTransfer(msg.sender, amount);
    emit Withdrawn(msg.sender, amount);
  }

  function exit() external override(IStakingRewards) {
    withdraw(balanceOf(msg.sender));
    getReward();
  }

  function getReward()
    public
    virtual
    override(IStakingRewards)
    updateReward(msg.sender)
  {
    uint256 reward = earned(msg.sender);
    if (reward > 0) {
      rewards[msg.sender] = 0;
      rewardToken.safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /* ----- Reward Distributor ----- */

  /**
   * @notice Should be called after the amount of reward tokens has
     been sent to the contract.
     Reward should be divisible by duration.
   * @param reward number of tokens to be distributed over the duration.
   */
  function notifyRewardAmount(uint256 reward)
    external
    override
    onlyRewardDistribution
    updateReward(address(0))
  {
    if (block.timestamp >= periodFinish) {
      rewardRate = reward.div(DURATION);
    } else {
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate);
      rewardRate = reward.add(leftover).div(DURATION);
    }

    // Ensure provided reward amount is not more than the balance in the contract.
    // Keeps reward rate within the right range to prevent overflows in earned or rewardsPerToken
    // Reward + leftover < 1e18
    uint256 balance = rewardToken.balanceOf(address(this));
    require(
      rewardRate <= balance.div(DURATION),
      "Phase2Pool::notifyRewardAmount: Insufficent balance for reward rate"
    );

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(DURATION);
    emit RewardAdded(reward);
  }

  /* ----- RECOVER_ROLE ----- */

  /**
   * @notice Provide accidental token retrieval.
   * @dev Sourced from synthetix/contracts/StakingRewards.sol
   */
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external {
    require(
      hasRole(RECOVER_ROLE, _msgSender()),
      "Phase2Pool::recoverERC20: You must possess the recover role to recover erc20"
    );
    require(
      tokenAddress != address(stakeToken),
      "Phase2Pool::recoverERC20: Cannot recover the staking token"
    );
    require(
      tokenAddress != address(rewardToken),
      "Phase2Pool::recoverERC20: Cannot recover the reward token"
    );

    IERC20(tokenAddress).safeTransfer(_msgSender(), tokenAmount);
    emit Recovered(tokenAddress, tokenAmount);
  }
}

pragma solidity >=0.4.24;


// https://docs.synthetix.io/contracts/source/interfaces/istakingrewards
interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";

abstract contract RewardDistributionRecipient is Context, AccessControl {
    bytes32 public constant DISTRIBUTION_ASSIGNER_ROLE = keccak256("DISTRIBUTION_ASSIGNER_ROLE");

    address public rewardDistribution;

    constructor(address assigner) {
        _setupRole(DISTRIBUTION_ASSIGNER_ROLE, assigner);
    }

    modifier onlyRewardDistribution() {
        require(
            _msgSender() == rewardDistribution,
            "RewardDisributionRecipient::onlyRewardDistribution: Caller is not RewardsDistribution contract"
        );
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /* ----- rewardDistribution ----- */

    function notifyRewardAmount(uint256 reward) external virtual;

    /* ----- DISTRIBUTION_ASSIGNER_ROLE ----- */

    function setRewardDistribution(address _rewardDistribution)
        external
    {
        require(
            hasRole(DISTRIBUTION_ASSIGNER_ROLE, _msgSender()),
            "RewardDistributionRecipient::setRewardDistribution: must have distribution assigner role"
        );
        rewardDistribution = _rewardDistribution;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./RewardDistributionRecipient.sol";
import "./interfaces/IStakingRewardWhitelisted.sol";
import "./Whitelisted.sol";
import "./Phase2Pool.sol";

contract Phase1Pool is Phase2Pool, Whitelisted, IStakingRewardWhitelisted {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */
  uint256 public maximumContribution;

  /* ========== CONSTRUCTOR ========== */

  /**
   * @notice Construct a new Phase1Pool
   * @param _admin The default role controller for
   * @param _rewardDistribution The reward distributor (can change reward rate)
   * @param _whitelist The address of the deployed whitelist contract
   * @param _rewardToken The reward token to distribute
   * @param _stakingToken The staking token used to qualify for rewards
   * @param _maximumContribution The maximum contribution for this token (in the unit of the respective contract)
   */
  constructor(
    address _admin,
    address _rewardDistribution,
    address _whitelist,
    address _rewardToken,
    address _stakingToken,
    uint256 _maximumContribution
  ) Phase2Pool(_admin, _rewardDistribution, _rewardToken, _stakingToken) {
    whitelist = IWhitelist(_whitelist);
    maximumContribution = _maximumContribution;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */
  function stake(uint256) public pure override(Phase2Pool, IStakingRewards) {
    revert(
      "Phase1Pool::stake: Cannot stake on Phase1Pool directly due to whitelist"
    );
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /* ----- onlyWhitelisted ----- */

  function stakeWithProof(uint256 amount, bytes32[] calldata proof)
    public
    override(IStakingRewardWhitelisted)
    onlyWhitelisted(proof)
    updateReward(msg.sender)
  {
    require(
      balanceOf(msg.sender).add(amount) <= maximumContribution,
      "Phase1Pool::stake: Cannot exceed maximum contribution"
    );

    super.stake(amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "synthetix/contracts/interfaces/IStakingRewards.sol";

interface IStakingRewardWhitelisted is IStakingRewards {
  function stakeWithProof(uint256 amount, bytes32[] calldata proof) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '@openzeppelin/contracts/GSN/Context.sol';

import './interfaces/IWhitelist.sol';

abstract contract Whitelisted is Context {
    IWhitelist public whitelist;

    modifier onlyWhitelisted(bytes32[] calldata proof) {
        require(
            whitelist.whitelisted(_msgSender(), proof),
            "Whitelisted::onlyWhitelisted: Caller is not whitelisted / proof invalid"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.2;

interface IWhitelist {
  // Views
  function root() external view returns (bytes32);
  function uri() external view returns (string memory);
  function whitelisted(address account, bytes32[] memory proof) external view returns (bool);

  // Mutative
  function updateWhitelist(bytes32 _root, string memory _uri) external; 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";

import "./interfaces/IWhitelist.sol";

contract MerkleWhitelist is IWhitelist, Context, AccessControl {
  /* ========== CONSTANTS ========== */
  bytes32 public constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");

  /* ========== STATE VARIABLES ========== */
  bytes32 public merkleRoot;
  string public sourceUri;

  /* ========== CONSTRUCTOR ========== */

  /**
   * @notice Construct a new MerkleWhitelist
   * @param _admin The default role controller and whitelister for the contract.
   * @param _root The default merkleRoot.
   * @param _uri The link to the full whitelist.
   */
  constructor(
    address _admin,
    bytes32 _root,
    string memory _uri
  ) {
    merkleRoot = _root;
    sourceUri = _uri;

    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    _setupRole(WHITELISTER_ROLE, _admin);
  }

  /* ========== EVENTS ========== */

  event UpdatedWhitelist(bytes32 root, string uri);

  /* ========== VIEWS ========== */

  function root() external view override(IWhitelist) returns (bytes32) {
    return merkleRoot;
  }

  function uri() external view override(IWhitelist) returns (string memory) {
    return sourceUri;
  }

  function whitelisted(address account, bytes32[] memory proof)
    public
    view
    override(IWhitelist)
    returns (bool)
  {
    // Need to include bytes1(0x00) in order to prevent pre-image attack.
    bytes32 leafHash = keccak256(abi.encodePacked(bytes1(0x00), account));
    return checkProof(merkleRoot, proof, leafHash);
  }

  /* ========== PURE ========== */

  function checkProof(
    bytes32 _root,
    bytes32[] memory _proof,
    bytes32 _leaf
  ) internal pure returns (bool) {
    bytes32 computedHash = _leaf;

    for (uint256 i = 0; i < _proof.length; i++) {
      bytes32 proofElement = _proof[i];

      if (computedHash < proofElement) {
        computedHash = keccak256(
          abi.encodePacked(bytes1(0x01), computedHash, proofElement)
        );
      } else {
        computedHash = keccak256(
          abi.encodePacked(bytes1(0x01), proofElement, computedHash)
        );
      }
    }

    return computedHash == _root;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /* ----- WHITELISTER_ROLE ----- */

  function updateWhitelist(bytes32 root_, string memory uri_)
    public
    override(IWhitelist)
  {
    require(
      hasRole(WHITELISTER_ROLE, _msgSender()),
      "MerkleWhitelist::updateWhitelist: only whitelister may update the whitelist"
    );

    merkleRoot = root_;
    sourceUri = uri_;

    emit UpdatedWhitelist(merkleRoot, sourceUri);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * This has an open mint functionality
 */
contract TokenMock is Context, AccessControl, ERC20Burnable, ERC20Pausable {
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /**
   * @dev Grants `DEFAULT_ADMIN_ROLE`, and `PAUSER_ROLE` to the
   * account that deploys the contract.
   *
   * See {ERC20-constructor}.
   */
  constructor(
    address _admin,
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) ERC20(_name, _symbol) {
    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    _setupRole(PAUSER_ROLE, _admin);

    _setupDecimals(_decimals);
  }

  /**
   * @dev Creates `amount` new tokens for `to`.
   *
   * See {ERC20-_mint}.
   *
   */
  function mint(address to, uint256 amount) external virtual {
    _mint(to, amount);
  }

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() external virtual {
    require(hasRole(PAUSER_ROLE, _msgSender()), "TokenMock/PauserRole");
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() external virtual {
    require(hasRole(PAUSER_ROLE, _msgSender()), "TokenMock/PauserRole");
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20, ERC20Pausable) {
    super._beforeTokenTransfer(from, to, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
pragma solidity =0.7.6;

import "../Recoverable.sol";

contract RecoverableHarness is Recoverable {
  constructor(address governance) {
    _setupRole(RECOVER_ROLE, governance);
  }

  receive() external payable {
    // Blindly accept ETH.
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./RewardDistributionRecipient.sol";
import "./interfaces/IETHStakingRewards.sol";

/**
 * @title Phase 2 BANK Reward Pool for Float Protocol, specifically for ETH.
 * @notice This contract is used to reward `rewardToken` when ETH is staked.
 */
contract ETHPhase2Pool is
  IETHStakingRewards,
  Context,
  AccessControl,
  RewardDistributionRecipient,
  ReentrancyGuard
{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== CONSTANTS ========== */
  uint256 public constant DURATION = 7 days;
  bytes32 public constant RECOVER_ROLE = keccak256("RECOVER_ROLE");

  /* ========== STATE VARIABLES ========== */
  IERC20 public rewardToken;

  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  /* ========== CONSTRUCTOR ========== */

  /**
   * @notice Construct a new Phase2Pool for ETH
   * @param _admin The default role controller for
   * @param _rewardDistribution The reward distributor (can change reward rate)
   * @param _rewardToken The reward token to distribute
   */
  constructor(
    address _admin,
    address _rewardDistribution,
    address _rewardToken
  ) RewardDistributionRecipient(_admin) {
    rewardDistribution = _rewardDistribution;
    rewardToken = IERC20(_rewardToken);

    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    _setupRole(RECOVER_ROLE, _admin);
  }

  /* ========== EVENTS ========== */

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event Recovered(address token, uint256 amount);

  /* ========== MODIFIERS ========== */

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  /* ========== VIEWS ========== */

  function totalSupply()
    public
    view
    override(IETHStakingRewards)
    returns (uint256)
  {
    return _totalSupply;
  }

  function balanceOf(address account)
    public
    view
    override(IETHStakingRewards)
    returns (uint256)
  {
    return _balances[account];
  }

  function lastTimeRewardApplicable()
    public
    view
    override(IETHStakingRewards)
    returns (uint256)
  {
    return Math.min(block.timestamp, periodFinish);
  }

  function rewardPerToken()
    public
    view
    override(IETHStakingRewards)
    returns (uint256)
  {
    if (totalSupply() == 0) {
      return rewardPerTokenStored;
    }

    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable()
          .sub(lastUpdateTime)
          .mul(rewardRate)
          .mul(1e18)
          .div(totalSupply())
      );
  }

  function earned(address account)
    public
    view
    override(IETHStakingRewards)
    returns (uint256)
  {
    return
      balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
  }

  function getRewardForDuration()
    external
    view
    override(IETHStakingRewards)
    returns (uint256)
  {
    return rewardRate.mul(DURATION);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @dev Fallback, `msg.value` of ETH sent to this contract grants caller account a matching stake in contract.
   * Emits {Staked} event to reflect this.
   */
  receive() external payable {
    stake(msg.value);
  }

  function stake(uint256 amount)
    public
    payable
    virtual
    override(IETHStakingRewards)
    updateReward(msg.sender)
  {
    require(amount > 0, "ETHPhase2Pool/ZeroStake");
    require(amount == msg.value, "ETHPhase2Pool/IncorrectEth");

    _totalSupply = _totalSupply.add(amount);
    _balances[msg.sender] = _balances[msg.sender].add(amount);

    emit Staked(msg.sender, amount);
  }

  function withdraw(uint256 amount)
    public
    override(IETHStakingRewards)
    updateReward(msg.sender)
  {
    require(amount > 0, "ETHPhase2Pool/ZeroWithdraw");
    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);

    emit Withdrawn(msg.sender, amount);
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "ETHPhase2Pool/EthTransferFail");
  }

  function exit() external override(IETHStakingRewards) {
    withdraw(balanceOf(msg.sender));
    getReward();
  }

  function getReward()
    public
    virtual
    override(IETHStakingRewards)
    updateReward(msg.sender)
  {
    uint256 reward = earned(msg.sender);
    if (reward > 0) {
      rewards[msg.sender] = 0;
      rewardToken.safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /* ----- Reward Distributor ----- */

  /**
   * @notice Should be called after the amount of reward tokens has
     been sent to the contract.
     Reward should be divisible by duration.
   * @param reward number of tokens to be distributed over the duration.
   */
  function notifyRewardAmount(uint256 reward)
    external
    override
    onlyRewardDistribution
    updateReward(address(0))
  {
    if (block.timestamp >= periodFinish) {
      rewardRate = reward.div(DURATION);
    } else {
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate);
      rewardRate = reward.add(leftover).div(DURATION);
    }

    // Ensure provided reward amount is not more than the balance in the contract.
    // Keeps reward rate within the right range to prevent overflows in earned or rewardsPerToken
    // Reward + leftover < 1e18
    uint256 balance = rewardToken.balanceOf(address(this));
    require(
      rewardRate <= balance.div(DURATION),
      "ETHPhase2Pool/LowRewardBalance"
    );

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(DURATION);
    emit RewardAdded(reward);
  }

  /* ----- RECOVER_ROLE ----- */

  /**
   * @notice Provide accidental token retrieval.
   * @dev Sourced from synthetix/contracts/StakingRewards.sol
   */
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external {
    require(
      hasRole(RECOVER_ROLE, _msgSender()),
      "ETHPhase2Pool/HasRecoverRole"
    );
    require(tokenAddress != address(rewardToken), "ETHPhase2Pool/NotReward");

    IERC20(tokenAddress).safeTransfer(_msgSender(), tokenAmount);
    emit Recovered(tokenAddress, tokenAmount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IETHStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function getRewardForDuration() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    // Mutative
    function stake(uint256 amount) external payable;
    function withdraw(uint256 amount) external;
    function getReward() external;
    function exit() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "synthetix/contracts/interfaces/IStakingRewards.sol";

import "./RewardDistributionRecipient.sol";

/**
 * @title Base Reward Pool for Float Protocol
 * @notice This contract is used to reward `rewardToken` when `stakeToken` is staked.
 * @dev The Pools are based on the original Synthetix rewards contract (https://etherscan.io/address/0xDCB6A51eA3CA5d3Fd898Fd6564757c7aAeC3ca92#code) developed by @k06a which is battled tested and widely used.
 * Alterations:
 * - duration set on constructor (immutable)
 * - Internal properties rather than private
 * - Add virtual marker to functions
 * - Change stake / withdraw to external and provide internal equivalents
 * - Change require messages to match convention
 * - Add hooks for _beforeWithdraw and _beforeStake
 * - Emit events before external calls in line with best practices.
 */
abstract contract BasePool is
  IStakingRewards,
  AccessControl,
  RewardDistributionRecipient
{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== CONSTANTS ========== */
  bytes32 public constant RECOVER_ROLE = keccak256("RECOVER_ROLE");
  uint256 public immutable duration;

  /* ========== STATE VARIABLES ========== */
  IERC20 public rewardToken;
  IERC20 public stakeToken;

  uint256 public periodFinish;
  uint256 public rewardRate;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;

  uint256 internal _totalSupply;
  mapping(address => uint256) internal _balances;

  /* ========== CONSTRUCTOR ========== */

  /**
   * @notice Construct a new BasePool
   * @param _admin The default role controller
   * @param _rewardDistribution The reward distributor (can change reward rate)
   * @param _rewardToken The reward token to distribute
   * @param _stakingToken The staking token used to qualify for rewards
   */
  constructor(
    address _admin,
    address _rewardDistribution,
    address _rewardToken,
    address _stakingToken,
    uint256 _duration
  ) RewardDistributionRecipient(_admin) {
    rewardDistribution = _rewardDistribution;
    rewardToken = IERC20(_rewardToken);
    stakeToken = IERC20(_stakingToken);

    duration = _duration;

    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    _setupRole(RECOVER_ROLE, _admin);
  }

  /* ========== EVENTS ========== */

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event Recovered(address token, uint256 amount);

  /* ========== MODIFIERS ========== */

  modifier updateReward(address account) virtual {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  /* ========== VIEWS ========== */

  /**
   * @notice The total reward producing staked supply (total quantity to distribute)
   */
  function totalSupply()
    public
    view
    virtual
    override(IStakingRewards)
    returns (uint256)
  {
    return _totalSupply;
  }

  /**
   * @notice The total reward producing balance of the account.
   */
  function balanceOf(address account)
    public
    view
    virtual
    override(IStakingRewards)
    returns (uint256)
  {
    return _balances[account];
  }

  function lastTimeRewardApplicable()
    public
    view
    virtual
    override(IStakingRewards)
    returns (uint256)
  {
    return Math.min(block.timestamp, periodFinish);
  }

  function rewardPerToken()
    public
    view
    virtual
    override(IStakingRewards)
    returns (uint256)
  {
    if (totalSupply() == 0) {
      return rewardPerTokenStored;
    }

    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable()
          .sub(lastUpdateTime)
          .mul(rewardRate)
          .mul(1e18)
          .div(totalSupply())
      );
  }

  function earned(address account)
    public
    view
    virtual
    override(IStakingRewards)
    returns (uint256)
  {
    return
      balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
  }

  function getRewardForDuration()
    external
    view
    override(IStakingRewards)
    returns (uint256)
  {
    return rewardRate.mul(duration);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function stake(uint256 amount)
    external
    virtual
    override(IStakingRewards)
    updateReward(msg.sender)
  {
    require(amount > 0, "BasePool/NonZeroStake");

    _stake(msg.sender, msg.sender, amount);
  }

  function withdraw(uint256 amount)
    external
    virtual
    override(IStakingRewards)
    updateReward(msg.sender)
  {
    require(amount > 0, "BasePool/NonZeroWithdraw");

    _withdraw(msg.sender, amount);
  }

  /**
   * @notice Exit the pool, taking any rewards due and staked
   */
  function exit()
    external
    virtual
    override(IStakingRewards)
    updateReward(msg.sender)
  {
    _withdraw(msg.sender, _balances[msg.sender]);
    getReward();
  }

  /**
   * @notice Retrieve any rewards due
   */
  function getReward()
    public
    virtual
    override(IStakingRewards)
    updateReward(msg.sender)
  {
    uint256 reward = earned(msg.sender);
    if (reward > 0) {
      rewards[msg.sender] = 0;

      emit RewardPaid(msg.sender, reward);

      rewardToken.safeTransfer(msg.sender, reward);
    }
  }

  /**
   * @dev Stakes `amount` tokens from `staker` to `recipient`, increasing the total supply.
   *
   * Emits a {Staked} event.
   *
   * Requirements:
   * - `recipient` cannot be zero address.
   * - `staker` must have at least `amount` tokens
   * - `staker` must approve this contract for at least `amount`
   */
  function _stake(
    address staker,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(recipient != address(0), "BasePool/ZeroAddressS");

    _beforeStake(staker, recipient, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[recipient] = _balances[recipient].add(amount);

    emit Staked(recipient, amount);
    stakeToken.safeTransferFrom(staker, address(this), amount);
  }

  /**
   * @dev Withdraws `amount` tokens from `account`, reducing the total supply.
   *
   * Emits a {Withdrawn} event.
   *
   * Requirements:
   * - `account` cannot be zero address.
   * - `account` must have at least `amount` staked.
   */
  function _withdraw(address account, uint256 amount) internal virtual {
    require(account != address(0), "BasePool/ZeroAddressW");

    _beforeWithdraw(account, amount);

    _balances[account] = _balances[account].sub(
      amount,
      "BasePool/WithdrawExceedsBalance"
    );
    _totalSupply = _totalSupply.sub(amount);

    emit Withdrawn(account, amount);
    stakeToken.safeTransfer(account, amount);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /* ----- Reward Distributor ----- */

  /**
   * @notice Should be called after the amount of reward tokens has
     been sent to the contract.
     Reward should be divisible by duration.
   * @param reward number of tokens to be distributed over the duration.
   */
  function notifyRewardAmount(uint256 reward)
    public
    virtual
    override
    onlyRewardDistribution
    updateReward(address(0))
  {
    if (block.timestamp >= periodFinish) {
      rewardRate = reward.div(duration);
    } else {
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate);
      rewardRate = reward.add(leftover).div(duration);
    }

    // Ensure provided reward amount is not more than the balance in the contract.
    // Keeps reward rate within the right range to prevent overflows in earned or rewardsPerToken
    // Reward + leftover < 1e18
    uint256 balance = rewardToken.balanceOf(address(this));
    require(rewardRate <= balance.div(duration), "BasePool/InsufficentBalance");

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(duration);
    emit RewardAdded(reward);
  }

  /* ----- RECOVER_ROLE ----- */

  /**
   * @notice Provide accidental token retrieval.
   * @dev Sourced from synthetix/contracts/StakingRewards.sol
   */
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external {
    require(hasRole(RECOVER_ROLE, _msgSender()), "BasePool/RecoverRole");
    require(tokenAddress != address(stakeToken), "BasePool/NoRecoveryOfStake");
    require(
      tokenAddress != address(rewardToken),
      "BasePool/NoRecoveryOfReward"
    );

    emit Recovered(tokenAddress, tokenAmount);

    IERC20(tokenAddress).safeTransfer(_msgSender(), tokenAmount);
  }

  /* ========== HOOKS ========== */

  /**
   * @dev Hook that is called before any staking of tokens.
   *
   * Calling conditions:
   *
   * - `amount` of ``staker``'s tokens will be staked into the pool
   * - `recipient` can withdraw.
   */
  function _beforeStake(
    address staker,
    address recipient,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev Hook that is called before any staking of tokens.
   *
   * Calling conditions:
   *
   * - `amount` of ``from``'s tokens will be withdrawn into the pool
   */
  function _beforeWithdraw(address from, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./BasePool.sol";
import "./extensions/DeadlinePool.sol";

import "./extensions/LockInPool.sol";

/**
 * Phase 4a Pool - is a special ceremony pool that can only be joined within the window period and has a Lock in period for the tokens
 */
contract Phase4aPool is DeadlinePool, LockInPool {
  /* ========== CONSTRUCTOR ========== */

  /**
   * @notice Construct a new BasePool
   * @param _admin The default role controller
   * @param _rewardDistribution The reward distributor (can change reward rate)
   * @param _rewardToken The reward token to distribute
   * @param _stakingToken The staking token used to qualify for rewards
   * @param _startWindow When ceremony starts
   * @param _endWindow When ceremony ends
   */
  constructor(
    address _admin,
    address _rewardDistribution,
    address _rewardToken,
    address _stakingToken,
    uint256 _duration,
    uint256 _startWindow,
    uint256 _endWindow
  )
    DeadlinePool(
      _admin,
      _rewardDistribution,
      _rewardToken,
      _stakingToken,
      _duration,
      _startWindow,
      _endWindow
    )
  {}

  // COMPILER HINTS for overrides

  function _beforeStake(
    address staker,
    address recipient,
    uint256 amount
  ) internal virtual override(LockInPool, DeadlinePool) {
    super._beforeStake(staker, recipient, amount);
  }

  function _beforeWithdraw(address from, uint256 amount)
    internal
    virtual
    override(BasePool, LockInPool)
  {
    super._beforeWithdraw(from, amount);
  }

  function balanceOf(address account)
    public
    view
    virtual
    override(BasePool, LockInPool)
    returns (uint256)
  {
    return super.balanceOf(account);
  }

  function totalSupply()
    public
    view
    virtual
    override(BasePool, LockInPool)
    returns (uint256)
  {
    return super.totalSupply();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../BasePool.sol";
import "../../lib/Windowed.sol";

/**
 * @notice Only allow staking before the deadline.
 */
abstract contract DeadlinePool is BasePool, Windowed {
  constructor(
    address _admin,
    address _rewardDistribution,
    address _rewardToken,
    address _stakingToken,
    uint256 _duration,
    uint256 _startWindow,
    uint256 _endWindow
  )
    BasePool(
      _admin,
      _rewardDistribution,
      _rewardToken,
      _stakingToken,
      _duration
    )
    Windowed(_startWindow, _endWindow)
  {}

  function _beforeStake(
    address staker,
    address recipient,
    uint256 amount
  ) internal virtual override(BasePool) inWindow {
    super._beforeStake(staker, recipient, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../BasePool.sol";

/**
 * Integrates a timelock of `LOCK_DURATION` on the Pool.
 * Can only withdraw from the pool if:
 * - not started
 * - or requested an unlock and waited the `LOCK_DURATION`
 * - or the rewards have finished for `REFILL_ALLOWANCE`.
 */
abstract contract LockInPool is BasePool {
  using SafeMath for uint256;

  uint256 private constant REFILL_ALLOWANCE = 2 hours;
  uint256 private constant LOCK_DURATION = 8 days;

  mapping(address => uint256) public unlocks;
  uint256 private _unlockingSupply;

  event Unlock(address indexed account);

  /* ========== VIEWS ========== */

  /**
   * @notice The balance that is currently being unlocked
   * @param account The account we're interested in.
   */
  function inLimbo(address account) public view returns (uint256) {
    if (unlocks[account] == 0) {
      return 0;
    }
    return super.balanceOf(account);
  }

  /// @inheritdoc BasePool
  function balanceOf(address account)
    public
    view
    virtual
    override(BasePool)
    returns (uint256)
  {
    if (unlocks[account] != 0) {
      return 0;
    }
    return super.balanceOf(account);
  }

  /// @inheritdoc BasePool
  function totalSupply()
    public
    view
    virtual
    override(BasePool)
    returns (uint256)
  {
    return super.totalSupply().sub(_unlockingSupply);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice Request unlock of the token, removing this senders reward accural by:
   * - Setting balanceOf to return 0 (used for reward calculation) and adjusting total supply by amount unlocking.
   */
  function unlock() external updateReward(msg.sender) {
    require(unlocks[msg.sender] == 0, "LockIn/UnlockOnce");

    _unlockingSupply = _unlockingSupply.add(balanceOf(msg.sender));
    unlocks[msg.sender] = block.timestamp;

    emit Unlock(msg.sender);
  }

  /* ========== HOOKS ========== */

  /**
   * @notice Handle unlocks when staking, resets lock if was unlocking
   */
  function _beforeStake(
    address staker,
    address recipient,
    uint256 amount
  ) internal virtual override(BasePool) {
    super._beforeStake(staker, recipient, amount);

    if (unlocks[recipient] != 0) {
      // If we are resetting an unlock, reset the unlockingSupply
      _unlockingSupply = _unlockingSupply.sub(inLimbo(recipient));
      unlocks[recipient] = 0;
    }
  }

  /**
   * @dev Prevent withdrawal if:
   * - has started (i.e. rewards have entered the pool)
   * - before finished (+ allowance)
   * - not unlocked `LOCK_DURATION` ago
   *
   * - reset the unlock, so you can re-enter.
   */
  function _beforeWithdraw(address recipient, uint256 amount)
    internal
    virtual
    override(BasePool)
  {
    super._beforeWithdraw(recipient, amount);

    // Before rewards have been added / after + `REFILL`
    bool releaseWithoutLock =
      block.timestamp >= periodFinish.add(REFILL_ALLOWANCE);

    // A lock has been requested and the `LOCK_DURATION` has passed.
    bool releaseWithLock =
      (unlocks[recipient] != 0) &&
        (unlocks[recipient] <= block.timestamp.sub(LOCK_DURATION));

    require(releaseWithoutLock || releaseWithLock, "LockIn/NotReleased");

    if (unlocks[recipient] != 0) {
      // Reduce unlocking supply (so we don't keep discounting total supply when
      // it is reduced). Amount will be validated in withdraw proper.
      _unlockingSupply = _unlockingSupply.sub(amount);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./extensions/LockInPool.sol";

/**
 * Phase4Pool that acts as a SNX Reward Contract, with an 8 day token lock.
 */
contract Phase4Pool is LockInPool {
  /* ========== CONSTRUCTOR ========== */

  /**
   * @notice Construct a new Phase4Pool
   * @param _admin The default role controller
   * @param _rewardDistribution The reward distributor (can change reward rate)
   * @param _rewardToken The reward token to distribute
   * @param _stakingToken The staking token used to qualify for rewards
   * @param _duration Duration for token
   */
  constructor(
    address _admin,
    address _rewardDistribution,
    address _rewardToken,
    address _stakingToken,
    uint256 _duration
  )
    BasePool(
      _admin,
      _rewardDistribution,
      _rewardToken,
      _stakingToken,
      _duration
    )
  {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/IMasterChefRewarder.sol";

import "../BasePool.sol";

// !!!! WIP !!!!!
// This code doesn't work. You can deposit via sushi, withdraw through normal functions.
// Must separate the balances and only keep them the same for the rewards.

/**
 * Provides adapters to allow this reward contract to be used as a MASTERCHEF V2 Rewards contract
 */
abstract contract MasterChefV2Pool is BasePool, IMasterChefRewarder {
  using SafeMath for uint256;

  address private immutable masterchefV2;

  /* ========== CONSTRUCTOR ========== */

  /**
   * @notice Construct a new MasterChefV2Pool
   * @param _admin The default role controller
   * @param _rewardDistribution The reward distributor (can change reward rate)
   * @param _rewardToken The reward token to distribute
   * @param _stakingToken The staking token used to qualify for rewards
   * @param _duration The duration for each reward distribution
   * @param _masterchefv2 The trusted masterchef contract
   */
  constructor(
    address _admin,
    address _rewardDistribution,
    address _rewardToken,
    address _stakingToken,
    uint256 _duration,
    address _masterchefv2
  )
    BasePool(
      _admin,
      _rewardDistribution,
      _rewardToken,
      _stakingToken,
      _duration
    )
  {
    masterchefV2 = _masterchefv2;
  }

  /* ========== MODIFIERS ========== */

  modifier onlyMCV2 {
    require(msg.sender == masterchefV2, "MasterChefV2Pool/OnlyMCV2");
    _;
  }

  /* ========== VIEWS ========== */

  function pendingTokens(
    uint256,
    address user,
    uint256
  )
    external
    view
    override(IMasterChefRewarder)
    returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts)
  {
    IERC20[] memory _rewardTokens = new IERC20[](1);
    _rewardTokens[0] = (rewardToken);
    uint256[] memory _rewardAmounts = new uint256[](1);
    _rewardAmounts[0] = earned(user);
    return (_rewardTokens, _rewardAmounts);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * Adds to the internal balance record,
   */
  function onSushiReward(
    uint256,
    address _user,
    address,
    uint256,
    uint256 newLpAmount
  ) external override(IMasterChefRewarder) onlyMCV2 updateReward(_user) {
    uint256 internalBalance = _balances[_user];
    if (internalBalance > newLpAmount) {
      // _withdrawWithoutPush(_user, internalBalance.sub(newLpAmount));
    } else if (internalBalance < newLpAmount) {
      // _stakeWithoutPull(_user, _user, newLpAmount.sub(internalBalance));
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMasterChefRewarder {
  function onSushiReward(
    uint256 pid,
    address user,
    address recipient,
    uint256 sushiAmount,
    uint256 newLpAmount
  ) external;

  function pendingTokens(
    uint256 pid,
    address user,
    uint256 sushiAmount
  ) external view returns (IERC20[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

import "../interfaces/ISupplyControlledERC20.sol";

import "hardhat/console.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * This has an open mint functionality
 */
// ISupplyControlledERC20,
contract SupplyControlledTokenMock is AccessControl, ERC20Burnable {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  /**
   * @dev Grants `DEFAULT_ADMIN_ROLE` to the
   * account that deploys the contract.
   *
   * See {ERC20-constructor}.
   */
  constructor(
    address _admin,
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) ERC20(_name, _symbol) {
    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    _setupRole(MINTER_ROLE, _admin);

    _setupDecimals(_decimals);
  }

  /**
   * @dev Creates `amount` new tokens for `to`.
   *
   * See {ERC20-_mint}.
   *
   */
  function mint(address to, uint256 amount) external {
    require(hasRole(MINTER_ROLE, _msgSender()), "SCTokenMock/MinterRole");
    _mint(to, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20) {
    // console.log(symbol(), from, "->", to);
    // console.log(symbol(), ">", amount);
    super._beforeTokenTransfer(from, to, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: BSD-3-Clause
// Copyright 2020 Compound Labs, Inc.

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "hardhat/console.sol";

contract TimeLock {
  using SafeMath for uint256;

  event NewAdmin(address indexed newAdmin);
  event NewPendingAdmin(address indexed newPendingAdmin);
  event NewDelay(uint256 indexed newDelay);
  event CancelTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event ExecuteTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event QueueTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );

  uint256 public constant GRACE_PERIOD = 14 days;
  uint256 public constant MINIMUM_DELAY = 2 days;
  uint256 public constant MAXIMUM_DELAY = 30 days;

  address public admin;
  address public pendingAdmin;
  uint256 public delay;

  mapping(bytes32 => bool) public queuedTransactions;

  constructor(address admin_, uint256 delay_) public {
    require(
      delay_ >= MINIMUM_DELAY,
      "TimeLock::constructor: Delay must exceed minimum delay."
    );
    require(
      delay_ <= MAXIMUM_DELAY,
      "TimeLock::constructor: Delay must not exceed maximum delay."
    );

    admin = admin_;
    delay = delay_;
  }

  fallback() external {}

  function setDelay(uint256 delay_) public {
    require(
      msg.sender == address(this),
      "TimeLock::setDelay: Call must come from TimeLock."
    );
    require(
      delay_ >= MINIMUM_DELAY,
      "TimeLock::setDelay: Delay must exceed minimum delay."
    );
    require(
      delay_ <= MAXIMUM_DELAY,
      "TimeLock::setDelay: Delay must not exceed maximum delay."
    );
    delay = delay_;

    emit NewDelay(delay);
  }

  function acceptAdmin() public {
    require(
      msg.sender == pendingAdmin,
      "TimeLock::acceptAdmin: Call must come from pendingAdmin."
    );
    admin = msg.sender;
    pendingAdmin = address(0);

    emit NewAdmin(admin);
  }

  function setPendingAdmin(address pendingAdmin_) public {
    require(
      msg.sender == address(this),
      "TimeLock::setPendingAdmin: Call must come from TimeLock."
    );
    pendingAdmin = pendingAdmin_;

    emit NewPendingAdmin(pendingAdmin);
  }

  function queueTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public returns (bytes32) {
    require(
      msg.sender == admin,
      "TimeLock::queueTransaction: Call must come from admin."
    );
    require(
      eta >= getBlockTimestamp().add(delay),
      "TimeLock::queueTransaction: Estimated execution block must satisfy delay."
    );

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = true;

    emit QueueTransaction(txHash, target, value, signature, data, eta);
    return txHash;
  }

  function cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public {
    require(
      msg.sender == admin,
      "TimeLock::cancelTransaction: Call must come from admin."
    );

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    queuedTransactions[txHash] = false;

    emit CancelTransaction(txHash, target, value, signature, data, eta);
  }

  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 eta
  ) public payable returns (bytes memory) {
    require(
      msg.sender == admin,
      "TimeLock::executeTransaction: Call must come from admin."
    );

    bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
    require(
      queuedTransactions[txHash],
      "TimeLock::executeTransaction: Transaction hasn't been queued."
    );
    require(
      getBlockTimestamp() >= eta,
      "TimeLock::executeTransaction: Transaction hasn't surpassed time lock."
    );
    require(
      getBlockTimestamp() <= eta.add(GRACE_PERIOD),
      "TimeLock::executeTransaction: Transaction is stale."
    );

    queuedTransactions[txHash] = false;

    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    // solium-disable-next-line security/no-call-value
    (bool success, bytes memory returnData) =
      target.call{value: value}(callData);
    require(
      success,
      "TimeLock::executeTransaction: Transaction execution reverted."
    );

    emit ExecuteTransaction(txHash, target, value, signature, data, eta);

    return returnData;
  }

  function getBlockTimestamp() internal view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }
}

// SPDX-License-Identifier: BSD-3-Clause
// Copyright 2020 Compound Labs, Inc.

pragma solidity ^0.7.6;

import "../TimeLock.sol";

contract TimeLockMock is TimeLock {
  constructor(address admin_, uint256 delay_)
    TimeLock(admin_, TimeLock.MINIMUM_DELAY)
  {
    admin = admin_;
    delay = delay_;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "synthetix/contracts/interfaces/IStakingRewards.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract EarnedAggregator {
  /// @notice The address of the Float Protocol Timelock
  address public timelock;

  /// @notice addresses of pools (Staking Rewards Contracts)
  address[] public pools;

  constructor(address timelock_, address[] memory pools_) {
    timelock = timelock_;
    pools = pools_;
  }

  function getPools() public view returns (address[] memory) {
    address[] memory pls = pools;
    return pls;
  }

  function addPool(address pool) public {
    // Sanity check for function and no error
    IStakingRewards(pool).earned(timelock);

    for (uint256 i = 0; i < pools.length; i++) {
      require(pools[i] != pool, "already added");
    }

    require(msg.sender == address(timelock), "EarnedAggregator: !timelock");
    pools.push(pool);
  }

  function removePool(uint256 index) public {
    require(msg.sender == address(timelock), "EarnedAggregator: !timelock");
    if (index >= pools.length) return;

    if (index != pools.length - 1) {
      pools[index] = pools[pools.length - 1];
    }

    pools.pop();
  }

  function getCurrentEarned(address account) public view returns (uint256) {
    uint256 votes = 0;
    for (uint256 i = 0; i < pools.length; i++) {
      // get tokens earned for staking
      votes = SafeMath.add(votes, IStakingRewards(pools[i]).earned(account));
    }
    return votes;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../AuctionHouseMath.sol";

contract AuctionHouseMathTest is AuctionHouseMath {
  function _lerp(
    uint256 start,
    uint256 end,
    uint16 step,
    uint16 maxStep
  ) public pure returns (uint256 result) {
    return lerp(start, end, step, maxStep);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../external-lib/SafeDecimalMath.sol";

import "./interfaces/IBasket.sol";
import "./BasketMath.sol";

/**
 * @title Float Protocol Basket
 * @notice The logic contract for storing underlying ETH (as wETH)
 */
contract BasketV1 is IBasket, Initializable, AccessControlUpgradeable {
  using SafeMath for uint256;
  using SafeDecimalMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== CONSTANTS ========== */
  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  bytes32 public constant AUCTION_HOUSE_ROLE = keccak256("AUCTION_HOUSE_ROLE");

  /* ========== STATE VARIABLES ========== */
  IERC20 public float;
  IERC20 private weth;

  /**
   * @notice The target ratio for "collateralisation"
   * @dev [e27] Start at 100%
   */
  uint256 public targetRatio;

  function initialize(
    address _admin,
    address _weth,
    address _float
  ) external initializer {
    weth = IERC20(_weth);
    float = IERC20(_float);
    targetRatio = SafeDecimalMath.PRECISE_UNIT;

    _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    _setupRole(GOVERNANCE_ROLE, _admin);
  }

  /* ========== MODIFIERS ========== */

  modifier onlyGovernance {
    require(
      hasRole(GOVERNANCE_ROLE, _msgSender()),
      "AuctionHouse/GovernanceRole"
    );
    _;
  }

  /* ========== VIEWS ========== */

  /// @inheritdoc IBasketReader
  function underlying() public view override(IBasketReader) returns (address) {
    return address(weth);
  }

  /// @inheritdoc IBasketReader
  function getBasketFactor(uint256 targetPriceInEth)
    external
    view
    override(IBasketReader)
    returns (uint256 basketFactor)
  {
    uint256 wethInBasket = weth.balanceOf(address(this));
    uint256 floatTotalSupply = float.totalSupply();

    return
      basketFactor = BasketMath.calcBasketFactor(
        targetPriceInEth,
        wethInBasket,
        floatTotalSupply,
        targetRatio
      );
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /* ----- onlyGovernance ----- */

  /// @inheritdoc IBasketGovernedActions
  function buildAuctionHouse(address _auctionHouse, uint256 _allowance)
    external
    override(IBasketGovernedActions)
    onlyGovernance
  {
    grantRole(AUCTION_HOUSE_ROLE, _auctionHouse);
    weth.safeApprove(_auctionHouse, 0);
    weth.safeApprove(_auctionHouse, _allowance);
  }

  /// @inheritdoc IBasketGovernedActions
  function burnAuctionHouse(address _auctionHouse)
    external
    override(IBasketGovernedActions)
    onlyGovernance
  {
    revokeRole(AUCTION_HOUSE_ROLE, _auctionHouse);
    weth.safeApprove(_auctionHouse, 0);
  }

  /// @inheritdoc IBasketGovernedActions
  function setTargetRatio(uint256 _targetRatio)
    external
    override(IBasketGovernedActions)
    onlyGovernance
  {
    require(
      _targetRatio <= BasketMath.MAX_TARGET_RATIO,
      "BasketV1/RatioTooHigh"
    );
    require(
      _targetRatio >= BasketMath.MIN_TARGET_RATIO,
      "BasketV1/RatioTooLow"
    );
    targetRatio = _targetRatio;

    emit NewTargetRatio(_targetRatio);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

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
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./basket/IBasketReader.sol";
import "./basket/IBasketGovernedActions.sol";

/**
 * @title The interface for a Float Protocol Asset Basket
 * @notice A Basket stores value used to stabilise price and assess the
 * the movement of the underlying assets we're trying to track.
 * @dev The Basket interface is broken up into many smaller pieces to allow only
 * relevant parts to be imported
 */
interface IBasket is IBasketReader, IBasketGovernedActions {

}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../external-lib/SafeDecimalMath.sol";

library BasketMath {
  using SafeMath for uint256;
  using SafeDecimalMath for uint256;

  // SafeDecimalMath.PRECISE_UNIT = 1e27
  uint256 internal constant MIN_TARGET_RATIO = 0.1e27;
  uint256 internal constant MAX_TARGET_RATIO = 2e27;

  /**
   * @dev bF = ( eS / (fS * tP) ) / Q
   * @param targetPriceInEth [e27] target price (tP).
   * @param ethStored [e18] denoting total eth stored in basket (eS).
   * @param floatSupply [e18] denoting total floatSupply (fS).
   * @param targetRatio [e27] target ratio (Q)
   * @return basketFactor an [e27] decimal (bF)
   */
  function calcBasketFactor(
    uint256 targetPriceInEth,
    uint256 ethStored,
    uint256 floatSupply,
    uint256 targetRatio
  ) internal pure returns (uint256 basketFactor) {
    // Note that targetRatio should already be checked on set
    assert(targetRatio >= MIN_TARGET_RATIO);
    assert(targetRatio <= MAX_TARGET_RATIO);
    uint256 floatValue =
      floatSupply.multiplyDecimalRoundPrecise(targetPriceInEth);
    uint256 basketRatio = ethStored.divideDecimalRoundPrecise(floatValue);
    return basketFactor = basketRatio.divideDecimalRoundPrecise(targetRatio);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

/**
 * @title Basket Actions with suitable access control
 * @notice Contains actions which can only be called by governance.
 */
interface IBasketGovernedActions {
  event NewTargetRatio(uint256 targetRatio);

  /**
   * @notice Sets the basket target factor, initially "1"
   * @dev Expects an [e27] fixed point decimal value.
   * Target Ratio is what the basket factor is "aiming for",
   * i.e. target ratio = 0.8 then an 80% support from the basket
   * results in a 100% Basket Factor.
   * @param _targetRatio [e27] The new Target ratio
   */
  function setTargetRatio(uint256 _targetRatio) external;

  /**
   * @notice Connect and approve a new auction house to spend from the basket.
   * @dev Note that any allowance can be set, and even type(uint256).max will
   * slowly be eroded.
   * @param _auctionHouse The Auction House address to approve
   * @param _allowance The amount of the underlying token it can spend
   */
  function buildAuctionHouse(address _auctionHouse, uint256 _allowance)
    external;

  /**
   * @notice Remove an auction house, allows easy upgrades.
   * @param _auctionHouse The Auction House address to revoke.
   */
  function burnAuctionHouse(address _auctionHouse) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../BasketMath.sol";

contract BasketMathHarness {
  function _calcBasketFactor(
    uint256 targetPriceInEth,
    uint256 ethStored,
    uint256 floatSupply,
    uint256 targetRatio
  ) external pure returns (uint256 basketFactor) {
    return
      BasketMath.calcBasketFactor(
        targetPriceInEth,
        ethStored,
        floatSupply,
        targetRatio
      );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * @title {ERC20} Pausable token through the PAUSER_ROLE
 *
 * @dev This contract uses OpenZeppelin {AccessControlUpgradeable} to lock permissioned functions using the different roles.
 */
abstract contract ERC20PausableUpgradeable is
  Initializable,
  PausableUpgradeable,
  AccessControlUpgradeable,
  ERC20Upgradeable
{
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  // solhint-disable-next-line func-name-mixedcase
  function __ERC20Pausable_init_unchained(address pauser) internal initializer {
    _setupRole(PAUSER_ROLE, pauser);
  }

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() external {
    require(
      hasRole(PAUSER_ROLE, _msgSender()),
      "ERC20Pausable/PauserRoleRequired"
    );
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() external {
    require(
      hasRole(PAUSER_ROLE, _msgSender()),
      "ERC20Pausable/PauserRoleRequired"
    );
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20Upgradeable) {
    super._beforeTokenTransfer(from, to, amount);

    require(!paused(), "ERC20Pausable/Paused");
  }

  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "./ERC20PermitUpgradeable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./ERC20SupplyControlledUpgradeable.sol";

/**
 * @dev {ERC20} FLOAT token, including:
 *
 * - a minter role that allows for token minting (necessary for stabilisation)
 * - the ability to burn tokens (necessary for stabilisation)
 * - the use of permits to reduce gas costs
 * - a pauser role that allows to stop all token transfers
 *
 * This contract uses OpenZeppelin {AccessControlUpgradeable} to lock permissioned functions
 * using the different roles.
 * This contract is upgradable.
 */
contract FloatTokenV1 is
  ERC20PausableUpgradeable,
  ERC20PermitUpgradeable,
  ERC20SupplyControlledUpgradeable
{
  /**
   * @notice Construct a FloatTokenV1 instance
   * @param governance The default role controller, minter and pauser for the contract.
   * @param minter An additional minter (useful for quick launches, check this is revoked)
   * @dev We expect minters to be defined on deploy, e.g. AuctionHouse should get minter role
   */
  function initialize(address governance, address minter) external initializer {
    __Context_init_unchained();
    __ERC20_init_unchained("Float Protocol: FLOAT", "FLOAT");
    __ERC20Permit_init_unchained("Float Protocol: FLOAT", "1");
    __ERC20Pausable_init_unchained(governance);
    __ERC20SupplyControlled_init_unchained(governance);

    _setupRole(DEFAULT_ADMIN_ROLE, governance);

    // Quick launches
    _setupRole(MINTER_ROLE, minter);
  }

  /// @dev Hint to compiler, that this override has already occured.
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
    super._beforeTokenTransfer(from, to, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "../external-lib/Counters.sol";
import "../external-lib/EIP712.sol";
import "./interfaces/IERC20Permit.sol";

/**
 * @dev Wrapper implementation for ERC20 Permit extension allowing approvals
 * via signatures, as defined in https://eips.ethereum.org/EIPS/eip-2612.
 */
contract ERC20PermitUpgradeable is
  IERC20Permit,
  Initializable,
  ERC20Upgradeable
{
  using Counters for Counters.Counter;

  bytes32 private constant PERMIT_TYPEHASH =
    keccak256(
      "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

  bytes32 internal _domainSeparator;

  mapping(address => Counters.Counter) private _nonces;

  // solhint-disable-next-line func-name-mixedcase
  function __ERC20Permit_init_unchained(
    string memory domainName,
    string memory version
  ) internal initializer {
    _domainSeparator = EIP712.domainSeparatorV4(domainName, version);
  }

  /// @inheritdoc IERC20Permit
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR()
    external
    view
    override(IERC20Permit)
    returns (bytes32)
  {
    return _domainSeparator;
  }

  /**
   * @dev See {IERC20Permit-permit}.
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override(IERC20Permit) {
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp <= deadline, "ERC20Permit/ExpiredDeadline");

    bytes32 structHash =
      keccak256(
        abi.encode(
          PERMIT_TYPEHASH,
          owner,
          spender,
          value,
          _useNonce(owner),
          deadline
        )
      );

    bytes32 hash = EIP712.hashTypedDataV4(_domainSeparator, structHash);

    address signer = ECDSA.recover(hash, v, r, s);
    require(signer == owner, "ERC20Permit/InvalidSignature");

    _approve(owner, spender, value);
  }

  /// @inheritdoc IERC20Permit
  function nonces(address owner)
    external
    view
    virtual
    override(IERC20Permit)
    returns (uint256)
  {
    return _nonces[owner].current();
  }

  /**
   * @dev "Consume a nonce": return the current value and increment.
   */
  function _useNonce(address owner) internal virtual returns (uint256 current) {
    Counters.Counter storage nonce = _nonces[owner];
    current = nonce.current();
    nonce.increment();
  }

  uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title {ERC20} Supply Controlled token that allows burning (by all), and minting
 * by MINTER_ROLE
 *
 * @dev This contract uses OpenZeppelin {AccessControlUpgradeable} to lock permissioned functions using the different roles.
 */
abstract contract ERC20SupplyControlledUpgradeable is
  Initializable,
  AccessControlUpgradeable,
  ERC20Upgradeable
{
  using SafeMath for uint256;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  // solhint-disable-next-line func-name-mixedcase
  function __ERC20SupplyControlled_init_unchained(address minter)
    internal
    initializer
  {
    _setupRole(MINTER_ROLE, minter);
  }

  /**
   * @dev Creates `amount` new tokens for `to`.
   *
   * See {ERC20-_mint}.
   *
   * Requirements:
   *
   * - the caller must have the `MINTER_ROLE`.
   */
  function mint(address to, uint256 amount) external virtual {
    require(
      hasRole(MINTER_ROLE, _msgSender()),
      "ERC20SupplyControlled/MinterRole"
    );
    _mint(to, amount);
  }

  /**
   * @dev Destroys `amount` tokens from the caller.
   *
   * See {ERC20-_burn}.
   */
  function burn(uint256 amount) external virtual {
    _burn(_msgSender(), amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, deducting from the caller's
   * allowance.
   *
   * See {ERC20-_burn} and {ERC20-allowance}.
   *
   * Requirements:
   *
   * - the caller must have allowance for `accounts`'s tokens of at least
   * `amount`.
   */
  function burnFrom(address account, uint256 amount) external virtual {
    uint256 decreasedAllowance =
      allowance(account, _msgSender()).sub(
        amount,
        "ERC20SupplyControlled/Overburn"
      );

    _approve(account, _msgSender(), decreasedAllowance);
    _burn(account, amount);
  }

  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

/**
 * @title Counters
 * @author Matt Condon (@shrugs) https://github.com/OpenZeppelin/openzeppelin-contracts
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
  struct Counter {
    // This variable should never be directly accessed by users of the library: interactions must be restricted to
    // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
    // this feature: see https://github.com/ethereum/solidity/issues/4637
    uint256 _value; // default: 0
  }

  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }

  function increment(Counter storage counter) internal {
    counter._value += 1;
  }

  function decrement(Counter storage counter) internal {
    uint256 value = counter._value;
    require(value > 0, "Counter: decrement overflow");
    counter._value = value - 1;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./ECDSA.sol";

// Based on OpenZeppelin's draft EIP712, with updates to remove storage variables.

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 */
library EIP712 {
  bytes32 private constant _TYPE_HASH =
    keccak256(
      "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

  /**
   * @dev Returns the domain separator for the current chain.
   */
  function domainSeparatorV4(string memory name, string memory version)
    internal
    view
    returns (bytes32)
  {
    return
      _buildDomainSeparator(
        _TYPE_HASH,
        keccak256(bytes(name)),
        keccak256(bytes(version))
      );
  }

  function _buildDomainSeparator(
    bytes32 typeHash,
    bytes32 name,
    bytes32 version
  ) private view returns (bytes32) {
    uint256 chainId;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      chainId := chainid()
    }
    return
      keccak256(abi.encode(typeHash, name, version, chainId, address(this)));
  }

  /**
   * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
   * function returns the hash of the fully encoded EIP712 message for the given domain.
   *
   * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
   *
   * ```solidity
   * bytes32 digest = EIP712.hashTypedDataV4(
   *   EIP712.domainSeparatorV4("DApp Name", "1"),
   *   keccak256(abi.encode(
   *     keccak256("Mail(address to,string contents)"),
   *     mailTo,
   *     keccak256(bytes(mailContents))
   * )));
   * address signer = ECDSA.recover(digest, signature);
   * ```
   */
  function hashTypedDataV4(bytes32 domainSeparator, bytes32 structHash)
    internal
    pure
    returns (bytes32)
  {
    return ECDSA.toTypedDataHash(domainSeparator, structHash);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
  /**
   * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
   * given ``owner``'s signed approval.
   *
   * IMPORTANT: The same issues {IERC20-approve} has related to transaction
   * ordering also apply here.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `deadline` must be a timestamp in the future.
   * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
   * over the EIP712-formatted function arguments.
   * - the signature must use ``owner``'s current nonce (see {nonces}).
   *
   * For more information on the signature format, see the
   * https://eips.ethereum.org/EIPS/eip-2612.
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Returns the current nonce for `owner`. This value must be
   * included whenever a signature is generated for {permit}.
   *
   * Every successful call to {permit} increases ``owner``'s nonce by one. This
   * prevents a signature from being used multiple times.
   */
  function nonces(address owner) external view returns (uint256);

  /**
   * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
   */
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
  /**
   * @dev Returns the address that signed a hashed message (`hash`) with
   * `signature`. This address can then be used for verification purposes.
   *
   * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
   * this function rejects them by requiring the `s` value to be in the lower
   * half order, and the `v` value to be either 27 or 28.
   *
   * IMPORTANT: `hash` _must_ be the result of a hash operation for the
   * verification to be secure: it is possible to craft signatures that
   * recover to arbitrary addresses for non-hashed data. A safe way to ensure
   * this is by receiving a hash of the original message (which may otherwise
   * be too long), and then calling {toEthSignedMessageHash} on it.
   */
  function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
  {
    // Divide the signature in r, s and v variables
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    // - case 65: r,s,v signature (standard)
    // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
    if (signature.length == 65) {
      // ecrecover takes the signature parameters, and the only way to get them
      // currently is to use assembly.
      // solhint-disable-next-line no-inline-assembly
      assembly {
        r := mload(add(signature, 0x20))
        s := mload(add(signature, 0x40))
        v := byte(0, mload(add(signature, 0x60)))
      }
    } else if (signature.length == 64) {
      // ecrecover takes the signature parameters, and the only way to get them
      // currently is to use assembly.
      // solhint-disable-next-line no-inline-assembly
      assembly {
        let vs := mload(add(signature, 0x40))
        r := mload(add(signature, 0x20))
        s := and(
          vs,
          0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        )
        v := add(shr(255, vs), 27)
      }
    } else {
      revert("ECDSA: invalid signature length");
    }

    return recover(hash, v, r, s);
  }

  /**
   * @dev Overload of {ECDSA-recover} that receives the `v`,
   * `r` and `s` signature fields separately.
   */
  function recover(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal pure returns (address) {
    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
    // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
    //
    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
    // these malleable signatures as well.
    require(
      uint256(s) <=
        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
      "ECDSA: invalid signature 's' value"
    );
    require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

    // If the signature is valid (and not malleable), return the signer address
    address signer = ecrecover(hash, v, r, s);
    require(signer != address(0), "ECDSA: invalid signature");

    return signer;
  }

  /**
   * @dev Returns an Ethereum Signed Message, created from a `hash`. This
   * produces hash corresponding to the one signed with the
   * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
   * JSON-RPC method as part of EIP-191.
   *
   * See {recover}.
   */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return
      keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }

  /**
   * @dev Returns an Ethereum Signed Typed Data, created from a
   * `domainSeparator` and a `structHash`. This produces hash corresponding
   * to the one signed with the
   * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
   * JSON-RPC method as part of EIP-712.
   *
   * See {recover}.
   */
  function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * @dev {ERC20} BANK token, including:
 * 
 * - a minter role that allows for token minting (creation)
 * - a pauser role that allows to stop all token transfers
 *
 * This contract uses OpenZeppelin {AccessControlUpgradeable} to lock permissioned functions
 * using the different roles.
 * This contract is upgradable.
 */
contract BankToken is Initializable, PausableUpgradeable, AccessControlUpgradeable, ERC20Upgradeable {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /**
    @notice Construct a BankToken instance
    @param admin The default role controller, minter and pauser for the contract.
    @param minter An additional minter (for quick launch of epoch 1).
   */
  function initialize(address admin, address minter) public initializer {
    __ERC20_init("Float Bank", "BANK");
    _setupRole(DEFAULT_ADMIN_ROLE, admin);

    _setupRole(MINTER_ROLE, admin);
    _setupRole(MINTER_ROLE, minter);
    _setupRole(PAUSER_ROLE, admin);
  }

  /**
    * @dev Creates `amount` new tokens for `to`.
    *
    * See {ERC20-_mint}.
    *
    * Requirements:
    *
    * - the caller must have the `MINTER_ROLE`.
    */
  function mint(address to, uint256 amount) public virtual {
    require(hasRole(MINTER_ROLE, _msgSender()), "Bank::mint: must have minter role to mint");
    _mint(to, amount);
  }

  /**
    * @dev Pauses all token transfers.
    *
    * See {ERC20Pausable} and {Pausable-_pause}.
    *
    * Requirements:
    *
    * - the caller must have the `PAUSER_ROLE`.
    */
  function pause() public virtual {
    require(hasRole(PAUSER_ROLE, _msgSender()), "Bank::pause: must have pauser role to pause");
    _pause();
  }

  /**
    * @dev Unpauses all token transfers.
    *
    * See {ERC20Pausable} and {Pausable-_unpause}.
    *
    * Requirements:
    *
    * - the caller must have the `PAUSER_ROLE`.
    */
  function unpause() public virtual {
    require(hasRole(PAUSER_ROLE, _msgSender()), "Bank::unpause: must have pauser role to unpause");
    _unpause();
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual
    override(ERC20Upgradeable) {
      super._beforeTokenTransfer(from, to, amount);

      require(!paused(), "ERC20Pausable: token transfer while paused");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "../lib/Upgradeable.sol";
import "./ERC20PermitUpgradeable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./ERC20SupplyControlledUpgradeable.sol";

/**
 * @dev {ERC20} BANK token, including:
 *
 * - a minter role that allows for token minting (necessary for stabilisation)
 * - the ability to burn tokens (necessary for stabilisation)
 * - the use of permits to reduce gas costs
 * - a pauser role that allows to stop all token transfers
 *
 * This contract uses OpenZeppelin {AccessControlUpgradeable} to lock permissioned functions
 * using the different roles.
 * This contract is upgradable.
 */
contract BankTokenV2 is
  ERC20PausableUpgradeable,
  ERC20PermitUpgradeable,
  ERC20SupplyControlledUpgradeable,
  Upgradeable
{
  /**
   * @notice Construct a brand new BankTokenV2 instance
   * @param governance The default role controller, minter and pauser for the contract.
   * @dev We expect minters to be defined after deploy, e.g. AuctionHouse should get minter role
   */
  function initialize(address governance) external initializer {
    _version = 2;

    __Context_init_unchained();
    __ERC20_init_unchained("Float Bank", "BANK");
    __ERC20Permit_init_unchained("Float Protocol: BANK", "2");
    __ERC20Pausable_init_unchained(governance);
    __ERC20SupplyControlled_init_unchained(governance);
    _setupRole(DEFAULT_ADMIN_ROLE, governance);
  }

  /**
   * @notice Upgrade from V1, and initialise the relevant "new" state
   * @dev Uses upgradeAndCall in the ProxyAdmin, to call upgradeToAndCall, which will delegatecall this function.
   * _version keeps this single use
   * onlyProxyAdmin ensures this only occurs on upgrade
   */
  function upgrade() external onlyProxyAdmin {
    require(_version < 2, "BankTokenV2/AlreadyUpgraded");
    _version = 2;
    _domainSeparator = EIP712.domainSeparatorV4("Float Protocol: BANK", "2");
  }

  /// @dev Hint to compiler that this override has already occured.
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
    super._beforeTokenTransfer(from, to, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

/**
 * @title Upgradeable
 * @dev This contract provides special helper functions when using the upgradeability proxy.
 */
abstract contract Upgradeable {
  uint256 internal _version;

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
   */
  bytes32 internal constant ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  modifier onlyProxyAdmin() {
    address proxyAdmin;
    bytes32 slot = ADMIN_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      proxyAdmin := sload(slot)
    }
    require(msg.sender == proxyAdmin, "Upgradeable/MustBeProxyAdmin");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../BasisMath.sol";

contract BasisMathMock {
  using BasisMath for uint256;

  function _splitBy(uint256 value, uint256 percentage)
    public
    pure
    returns (uint256, uint256)
  {
    return value.splitBy(percentage);
  }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
// SPDX-License-Identifier: GPLv2

// Changes:
// - Conversion to 0.7.6
//   - library imports throughout
//   - remove revert fallback as now default

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

pragma solidity ^0.7.6;

contract ZapBaseV1 is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  bool public stopped = false;

  // if true, goodwill is not deducted
  mapping(address => bool) public feeWhitelist;

  uint256 public goodwill;
  // % share of goodwill (0-100 %)
  uint256 affiliateSplit;
  // restrict affiliates
  mapping(address => bool) public affiliates;
  // affiliate => token => amount
  mapping(address => mapping(address => uint256)) public affiliateBalance;
  // token => amount
  mapping(address => uint256) public totalAffiliateBalance;

  address internal constant ETHAddress =
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  constructor(uint256 _goodwill, uint256 _affiliateSplit) {
    goodwill = _goodwill;
    affiliateSplit = _affiliateSplit;
  }

  // circuit breaker modifiers
  modifier stopInEmergency {
    if (stopped) {
      revert("Temporarily Paused");
    } else {
      _;
    }
  }

  function _getBalance(address token) internal view returns (uint256 balance) {
    if (token == address(0)) {
      balance = address(this).balance;
    } else {
      balance = IERC20(token).balanceOf(address(this));
    }
  }

  function _approveToken(address token, address spender) internal {
    IERC20 _token = IERC20(token);
    if (_token.allowance(address(this), spender) > 0) return;
    else {
      _token.safeApprove(spender, uint256(-1));
    }
  }

  function _approveToken(
    address token,
    address spender,
    uint256 amount
  ) internal {
    IERC20 _token = IERC20(token);
    _token.safeApprove(spender, 0);
    _token.safeApprove(spender, amount);
  }

  // - to Pause the contract
  function toggleContractActive() public onlyOwner {
    stopped = !stopped;
  }

  function set_feeWhitelist(address zapAddress, bool status)
    external
    onlyOwner
  {
    feeWhitelist[zapAddress] = status;
  }

  function set_new_goodwill(uint256 _new_goodwill) public onlyOwner {
    require(
      _new_goodwill >= 0 && _new_goodwill <= 100,
      "GoodWill Value not allowed"
    );
    goodwill = _new_goodwill;
  }

  function set_new_affiliateSplit(uint256 _new_affiliateSplit)
    external
    onlyOwner
  {
    require(_new_affiliateSplit <= 100, "Affiliate Split Value not allowed");
    affiliateSplit = _new_affiliateSplit;
  }

  function set_affiliate(address _affiliate, bool _status) external onlyOwner {
    affiliates[_affiliate] = _status;
  }

  ///@notice Withdraw goodwill share, retaining affilliate share
  function withdrawTokens(address[] calldata tokens) external onlyOwner {
    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 qty;

      if (tokens[i] == ETHAddress) {
        qty = address(this).balance.sub(totalAffiliateBalance[tokens[i]]);
        Address.sendValue(payable(owner()), qty);
      } else {
        qty = IERC20(tokens[i]).balanceOf(address(this)).sub(
          totalAffiliateBalance[tokens[i]]
        );
        IERC20(tokens[i]).safeTransfer(owner(), qty);
      }
    }
  }

  ///@notice Withdraw affilliate share, retaining goodwill share
  function affilliateWithdraw(address[] calldata tokens) external {
    uint256 tokenBal;
    for (uint256 i = 0; i < tokens.length; i++) {
      tokenBal = affiliateBalance[msg.sender][tokens[i]];
      affiliateBalance[msg.sender][tokens[i]] = 0;
      totalAffiliateBalance[tokens[i]] = totalAffiliateBalance[tokens[i]].sub(
        tokenBal
      );

      if (tokens[i] == ETHAddress) {
        Address.sendValue(msg.sender, tokenBal);
      } else {
        IERC20(tokens[i]).safeTransfer(msg.sender, tokenBal);
      }
    }
  }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
// SPDX-License-Identifier: GPLv2

// Changes:
// - Conversion to 0.7.6
//   - abstract type
//   - library imports throughout

pragma solidity ^0.7.6;

import "./ZapBaseV1.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

abstract contract ZapInBaseV2 is ZapBaseV1 {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  function _pullTokens(
    address token,
    uint256 amount,
    address affiliate,
    bool enableGoodwill,
    bool shouldSellEntireBalance
  ) internal returns (uint256 value) {
    uint256 totalGoodwillPortion;

    if (token == address(0)) {
      require(msg.value > 0, "No eth sent");

      // subtract goodwill
      totalGoodwillPortion = _subtractGoodwill(
        ETHAddress,
        msg.value,
        affiliate,
        enableGoodwill
      );

      return msg.value.sub(totalGoodwillPortion);
    }
    require(amount > 0, "Invalid token amount");
    require(msg.value == 0, "Eth sent with token");

    //transfer token
    if (shouldSellEntireBalance) {
      require(
        Address.isContract(msg.sender),
        "ERR: shouldSellEntireBalance is true for EOA"
      );
      amount = IERC20(token).allowance(msg.sender, address(this));
    }
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

    // subtract goodwill
    totalGoodwillPortion = _subtractGoodwill(
      token,
      amount,
      affiliate,
      enableGoodwill
    );

    return amount.sub(totalGoodwillPortion);
  }

  function _subtractGoodwill(
    address token,
    uint256 amount,
    address affiliate,
    bool enableGoodwill
  ) internal returns (uint256 totalGoodwillPortion) {
    bool whitelisted = feeWhitelist[msg.sender];
    if (enableGoodwill && !whitelisted && goodwill > 0) {
      totalGoodwillPortion = SafeMath.div(
        SafeMath.mul(amount, goodwill),
        10000
      );

      if (affiliates[affiliate]) {
        if (token == address(0)) {
          token = ETHAddress;
        }

        uint256 affiliatePortion =
          totalGoodwillPortion.mul(affiliateSplit).div(100);
        affiliateBalance[affiliate][token] = affiliateBalance[affiliate][token]
          .add(affiliatePortion);
        totalAffiliateBalance[token] = totalAffiliateBalance[token].add(
          affiliatePortion
        );
      }
    }
  }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
// SPDX-License-Identifier: GPLv2

// Changes:
// - Uses msg.sender / removes the transfer from the zap contract.
// - Uses IMintingCeremony over IVault
pragma solidity =0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../funds/interfaces/IMintingCeremony.sol";
import "../external-lib/zapper/ZapInBaseV2.sol";

contract FloatMintingCeremonyZapInV1 is ZapInBaseV2 {
  using SafeMath for uint256;

  // calldata only accepted for approved zap contracts
  mapping(address => bool) public approvedTargets;

  event zapIn(address sender, address pool, uint256 tokensRec);

  constructor(uint256 _goodwill, uint256 _affiliateSplit)
    ZapBaseV1(_goodwill, _affiliateSplit)
  {}

  /**
    @notice This function commits to the Float Minting Ceremony with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param ceremony Float Protocol: Minting Ceremony address
    @param minFloatTokens The minimum acceptable quantity Float tokens to receive. Reverts otherwise
    @param intermediateToken Token to swap fromToken to before entering ceremony
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return tokensReceived - Quantity of FLOAT that will be received
     */
  function ZapIn(
    address fromToken,
    uint256 amountIn,
    address ceremony,
    uint256 minFloatTokens,
    address intermediateToken,
    address swapTarget,
    bytes calldata swapData,
    address affiliate,
    bool shouldSellEntireBalance
  ) external payable stopInEmergency returns (uint256 tokensReceived) {
    require(
      approvedTargets[swapTarget] || swapTarget == address(0),
      "Target not Authorized"
    );

    // get incoming tokens
    uint256 toInvest =
      _pullTokens(
        fromToken,
        amountIn,
        affiliate,
        true,
        shouldSellEntireBalance
      );

    // get intermediate token
    uint256 intermediateAmt =
      _fillQuote(fromToken, intermediateToken, toInvest, swapTarget, swapData);

    // Deposit to Minting Ceremony
    tokensReceived = _ceremonyCommit(intermediateAmt, ceremony, minFloatTokens);
  }

  function _ceremonyCommit(
    uint256 amount,
    address toCeremony,
    uint256 minTokensRec
  ) internal returns (uint256 tokensReceived) {
    address underlyingVaultToken = IMintingCeremony(toCeremony).underlying();

    _approveToken(underlyingVaultToken, toCeremony);

    uint256 initialBal = IERC20(toCeremony).balanceOf(msg.sender);
    IMintingCeremony(toCeremony).commit(msg.sender, amount, minTokensRec);
    tokensReceived = IERC20(toCeremony).balanceOf(msg.sender).sub(initialBal);
    require(tokensReceived >= minTokensRec, "Err: High Slippage");

    // Note that tokens are gifted directly, so we don't transfer from vault.
    // IERC20(toCeremony).safeTransfer(msg.sender, tokensReceived);
    emit zapIn(msg.sender, toCeremony, tokensReceived);
  }

  function _fillQuote(
    address _fromTokenAddress,
    address toToken,
    uint256 _amount,
    address _swapTarget,
    bytes memory swapCallData
  ) internal returns (uint256 amtBought) {
    uint256 valueToSend;

    if (_fromTokenAddress == toToken) {
      return _amount;
    }

    if (_fromTokenAddress == address(0)) {
      valueToSend = _amount;
    } else {
      _approveToken(_fromTokenAddress, _swapTarget);
    }

    uint256 iniBal = _getBalance(toToken);
    (bool success, ) = _swapTarget.call{value: valueToSend}(swapCallData);
    require(success, "Error Swapping Tokens 1");
    uint256 finalBal = _getBalance(toToken);

    amtBought = finalBal.sub(iniBal);
  }

  function setApprovedTargets(
    address[] calldata targets,
    bool[] calldata isApproved
  ) external onlyOwner {
    require(targets.length == isApproved.length, "Invalid Input length");

    for (uint256 i = 0; i < targets.length; i++) {
      approvedTargets[targets[i]] = isApproved[i];
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../external-lib/UniswapV2Library.sol";
import "../external-lib/UniswapV2OracleLibrary.sol";
import "../lib/SushiswapLibrary.sol";

import "./interfaces/ITwap.sol";

// As these are "Time"-Weighted Average Price contracts, they necessarily rely on time.
// solhint-disable not-rely-on-time

/**
 * @title A sliding window for AMMs (specifically Sushiswap)
 * @notice Uses observations collected over a window to provide moving price averages in the past
 * @dev This is a singleton TWAP that only needs to be deployed once per desired parameters. `windowSize` has a precision of `windowSize / granularity`
 * Errors:
 * MissingPastObsr   - We do not have suffient past observations.
 * UnexpectedElapsed - We have an unexpected time elapsed.
 * EarlyUpdate       - Tried to update the TWAP before the period has elapsed.
 * InvalidToken      - Cannot consult an invalid token pair.
 */
contract Twap is ITwap {
  using FixedPoint for *;
  using SafeMath for uint256;

  struct Observation {
    uint256 timestamp;
    uint256 price0Cumulative;
    uint256 price1Cumulative;
  }

  /* ========== IMMUTABLE VARIABLES ========== */

  /// @notice the Uniswap Factory contract for tracking exchanges
  address public immutable factory;

  /// @notice The desired amount of time over which the moving average should be computed, e.g. 24 hours
  uint256 public immutable windowSize;

  /// @notice The number of observations stored for each pair, i.e. how many price observations are stored for the window
  /// @dev As granularity increases from, more frequent updates are needed; but precision increases [`windowSize - (windowSize / granularity) * 2`, `windowSize`]
  uint8 public immutable granularity;

  /// @dev Redundant with `granularity` and `windowSize`, but has gas savings & easy read
  uint256 public immutable periodSize;

  /* ========== STATE VARIABLES ========== */

  /// @notice Mapping from pair address to a list of price observations of that pair
  mapping(address => Observation[]) public pairObservations;

  /* ========== EVENTS ========== */

  event NewObservation(
    uint256 timestamp,
    uint256 price0Cumulative,
    uint256 price1Cumulative
  );

  /* ========== CONSTRUCTOR ========== */

  /**
   * @notice Construct a new Sliding Window TWAP
   * @param factory_ The AMM factory
   * @param windowSize_ The window size for this TWAP
   * @param granularity_ The granularity required for the TWAP
   */
  constructor(
    address factory_,
    uint256 windowSize_,
    uint8 granularity_
  ) {
    require(factory_ != address(0), "Twap/InvalidFactory");
    require(granularity_ > 1, "Twap/Granularity");
    require(
      (periodSize = windowSize_ / granularity_) * granularity_ == windowSize_,
      "Twap/WindowSize"
    );
    factory = factory_;
    windowSize = windowSize_;
    granularity = granularity_;
  }

  /* ========== PURE ========== */

  /**
   * @notice Given the cumulative prices of the start and end of a period, and the length of the period, compute the average price in terms of the amount in
   * @param priceCumulativeStart the cumulative price for the start of the period
   * @param priceCumulativeEnd the cumulative price for the end of the period
   * @param timeElapsed the time from now to the first observation
   * @param amountIn the amount of tokens in
   * @return amountOut amount out received for the amount in
   */
  function _computeAmountOut(
    uint256 priceCumulativeStart,
    uint256 priceCumulativeEnd,
    uint256 timeElapsed,
    uint256 amountIn
  ) private pure returns (uint256 amountOut) {
    // overflow is desired.
    FixedPoint.uq112x112 memory priceAverage =
      FixedPoint.uq112x112(
        uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
      );
    amountOut = priceAverage.mul(amountIn).decode144();
  }

  /* ========== VIEWS ========== */

  /**
   * @notice Calculates the index of the observation for the given `timestamp`
   * @param timestamp the observation for the timestamp
   * @return index The index of the observation
   */
  function observationIndexOf(uint256 timestamp)
    public
    view
    returns (uint8 index)
  {
    uint256 epochPeriod = timestamp / periodSize;
    return uint8(epochPeriod % granularity);
  }

  /// @inheritdoc ITwap
  function updateable(address tokenA, address tokenB)
    external
    view
    override(ITwap)
    returns (bool)
  {
    address pair = SushiswapLibrary.pairFor(factory, tokenA, tokenB);

    uint8 observationIndex = observationIndexOf(block.timestamp);
    Observation storage observation = pairObservations[pair][observationIndex];

    // We only want to commit updates once per period (i.e. windowSize / granularity).
    uint256 timeElapsed = block.timestamp - observation.timestamp;

    return timeElapsed > periodSize;
  }

  /// @inheritdoc ITwap
  function consult(
    address tokenIn,
    uint256 amountIn,
    address tokenOut
  ) external view override(ITwap) returns (uint256 amountOut) {
    address pair = SushiswapLibrary.pairFor(factory, tokenIn, tokenOut);
    Observation storage firstObservation = _getFirstObservationInWindow(pair);

    uint256 timeElapsed = block.timestamp - firstObservation.timestamp;
    require(timeElapsed <= windowSize, "Twap/MissingPastObsr");
    require(
      timeElapsed >= windowSize - periodSize * 2,
      "Twap/UnexpectedElapsed"
    );

    (uint256 price0Cumulative, uint256 price1Cumulative, ) =
      UniswapV2OracleLibrary.currentCumulativePrices(pair);
    (address token0, address token1) =
      UniswapV2Library.sortTokens(tokenIn, tokenOut);

    if (token0 == tokenIn) {
      return
        _computeAmountOut(
          firstObservation.price0Cumulative,
          price0Cumulative,
          timeElapsed,
          amountIn
        );
    }

    require(token1 == tokenIn, "Twap/InvalidToken");

    return
      _computeAmountOut(
        firstObservation.price1Cumulative,
        price1Cumulative,
        timeElapsed,
        amountIn
      );
  }

  /**
   * @notice Observation from the oldest epoch (at the beginning of the window) relative to the current time
   * @param pair the Uniswap pair address
   * @return firstObservation The observation from the oldest epoch relative to current time.
   */
  function _getFirstObservationInWindow(address pair)
    private
    view
    returns (Observation storage firstObservation)
  {
    uint8 observationIndex = observationIndexOf(block.timestamp);
    // No overflow issues; if observationIndex + 1 overflows, result is still zero.
    uint8 firstObservationIndex = (observationIndex + 1) % granularity;
    firstObservation = pairObservations[pair][firstObservationIndex];
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /// @inheritdoc ITwap
  function update(address tokenA, address tokenB)
    external
    override(ITwap)
    returns (bool)
  {
    address pair = SushiswapLibrary.pairFor(factory, tokenA, tokenB);

    // Populate the array with empty observations for the first call.
    for (uint256 i = pairObservations[pair].length; i < granularity; i++) {
      pairObservations[pair].push();
    }

    // Get the observation for the current period.
    uint8 observationIndex = observationIndexOf(block.timestamp);
    Observation storage observation = pairObservations[pair][observationIndex];

    // We only want to commit updates once per period (i.e. windowSize / granularity).
    uint256 timeElapsed = block.timestamp - observation.timestamp;

    if (timeElapsed <= periodSize) {
      // Skip update as we're in the same observation slot.
      return false;
    }

    (uint256 price0Cumulative, uint256 price1Cumulative, ) =
      UniswapV2OracleLibrary.currentCumulativePrices(pair);
    observation.timestamp = block.timestamp;
    observation.price0Cumulative = price0Cumulative;
    observation.price1Cumulative = price1Cumulative;

    emit NewObservation(
      observation.timestamp,
      observation.price0Cumulative,
      observation.price1Cumulative
    );

    return true;
  }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.4.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

library UniswapV2Library {
  using SafeMath for uint256;

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
          )
        )
      )
    );
  }

  // fetches and sorts the reserves for a pair
  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) =
      IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = tokenA == token0
      ? (reserve0, reserve1)
      : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) internal pure returns (uint256 amountB) {
    require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
    require(
      reserveA > 0 && reserveB > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    amountB = amountA.mul(reserveB) / reserveA;
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountIn) {
    require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 numerator = reserveIn.mul(amountOut).mul(1000);
    uint256 denominator = reserveOut.sub(amountOut).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(
    address factory,
    uint256 amountIn,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[0] = amountIn;
    for (uint256 i; i < path.length - 1; i++) {
      (uint256 reserveIn, uint256 reserveOut) =
        getReserves(factory, path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(
    address factory,
    uint256 amountOut,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) =
        getReserves(factory, path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
  using FixedPoint for *;

  // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
  function currentBlockTimestamp() internal view returns (uint32) {
    return uint32(block.timestamp % 2**32);
  }

  // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
  function currentCumulativePrices(address pair)
    internal
    view
    returns (
      uint256 price0Cumulative,
      uint256 price1Cumulative,
      uint32 blockTimestamp
    )
  {
    blockTimestamp = currentBlockTimestamp();
    price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
    price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

    // if time has elapsed since the last update on the pair, mock the accumulated price values
    (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) =
      IUniswapV2Pair(pair).getReserves();
    if (blockTimestampLast != blockTimestamp) {
      // subtraction overflow is desired
      uint32 timeElapsed = blockTimestamp - blockTimestampLast;
      // addition overflow is desired
      // counterfactual
      price0Cumulative +=
        uint256(FixedPoint.fraction(reserve1, reserve0)._x) *
        timeElapsed;
      // counterfactual
      price1Cumulative +=
        uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
        timeElapsed;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../external-lib/UniswapV2Library.sol";

library SushiswapLibrary {
  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal pure returns (address pair) {
    (address token0, address token1) =
      UniswapV2Library.sortTokens(tokenA, tokenB);
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
          )
        )
      )
    );
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import "../MonetaryPolicyV1.sol";

contract MonetaryPolicyV1Harness is MonetaryPolicyV1 {
  uint256 public blockNumber;

  constructor(address _governance, address _ethUsdOracle)
    MonetaryPolicyV1(_governance, _ethUsdOracle)
  {}

  function _blockNumber() internal view override returns (uint256) {
    return blockNumber;
  }

  function __setBlock(uint256 _number) external {
    blockNumber = _number;
  }
}

