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

