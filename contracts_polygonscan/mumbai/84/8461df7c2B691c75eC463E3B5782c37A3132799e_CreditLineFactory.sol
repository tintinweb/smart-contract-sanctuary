// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (metatx/ERC2771Context.sol)

pragma solidity ^0.8.0;

import {Context} from '../../../../@openzeppelin/contracts/utils/Context.sol';

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
  function isTrustedForwarder(address forwarder)
    public
    view
    virtual
    returns (bool);

  function _msgSender()
    internal
    view
    virtual
    override
    returns (address sender)
  {
    if (isTrustedForwarder(msg.sender)) {
      // The assembly code is more direct than the Solidity version using `abi.decode`.
      assembly {
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else {
      return super._msgSender();
    }
  }

  function _msgData() internal view virtual override returns (bytes calldata) {
    if (isTrustedForwarder(msg.sender)) {
      return msg.data[0:msg.data.length - 20];
    } else {
      return super._msgData();
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import {ICreditLineStorage} from './interfaces/ICreditLineStorage.sol';
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableERC20
} from '../../tokens/interfaces/IMintableBurnableERC20.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {ICreditLine} from './interfaces/ICreditLine.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {CreditLineLib} from './CreditLineLib.sol';
import {
  ReentrancyGuard
} from '../../../@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {
  ERC2771Context
} from '../../../@jarvis-network/synthereum-contracts/contracts/common/ERC2771Context.sol';
import {
  FixedPoint
} from '../../../@uma/core/contracts/common/implementation/FixedPoint.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

/**
 * @title
 * @notice
 */
contract CreditLine is
  ICreditLine,
  ICreditLineStorage,
  ReentrancyGuard,
  ERC2771Context
{
  using FixedPoint for FixedPoint.Unsigned;
  using SafeERC20 for IERC20;
  using SafeERC20 for IMintableBurnableERC20;
  using CreditLineLib for PositionData;
  using CreditLineLib for PositionManagerData;

  //----------------------------------------
  // Constants
  //----------------------------------------

  string public constant override typology = 'SELF-MINTING';

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //----------------------------------------
  // Storage
  //----------------------------------------

  // Maps sponsor addresses to their positions. Each sponsor can have only one position.
  mapping(address => PositionData) private positions;
  // uint256 tokenSponsorsCount; // each new token sponsor will be identified with an incremental uint

  GlobalPositionData private globalPositionData;

  PositionManagerData private positionManagerData;

  FeeStatus private feeStatus;

  //----------------------------------------
  // Events
  //----------------------------------------

  event Deposit(address indexed sponsor, uint256 indexed collateralAmount);
  event Withdrawal(address indexed sponsor, uint256 indexed collateralAmount);
  event PositionCreated(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount,
    uint256 feeAmount
  );
  event NewSponsor(address indexed sponsor);
  event EndedSponsorPosition(address indexed sponsor);
  event Redeem(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount,
    uint256 feeAmount
  );
  event Repay(
    address indexed sponsor,
    uint256 indexed numTokensRepaid,
    uint256 indexed newTokenCount,
    uint256 feeAmount
  );
  event EmergencyShutdown(
    address indexed caller,
    uint256 settlementPrice,
    uint256 shutdowntimestamp
  );
  event SettleEmergencyShutdown(
    address indexed caller,
    uint256 indexed collateralReturned,
    uint256 indexed tokensBurned
  );
  event Liquidation(
    address indexed sponsor,
    address indexed liquidator,
    uint256 liquidatedTokens,
    uint256 liquidatedCollateral,
    uint256 collateralReward,
    uint256 liquidationTime
  );

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier notEmergencyShutdown() {
    require(
      positionManagerData.emergencyShutdownTimestamp == 0,
      'Contract emergency shutdown'
    );
    _;
  }

  modifier isEmergencyShutdown() {
    require(
      positionManagerData.emergencyShutdownTimestamp != 0,
      'Contract not emergency shutdown'
    );
    _;
  }

  modifier onlyCollateralisedPosition(address sponsor) {
    require(
      positions[sponsor].rawCollateral.isGreaterThan(0),
      'Position has no collateral'
    );
    _;
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------

  constructor(PositionManagerParams memory _positionManagerData) nonReentrant {
    positionManagerData.initialize(
      _positionManagerData.synthereumFinder,
      _positionManagerData.collateralToken,
      _positionManagerData.syntheticToken,
      _positionManagerData.priceFeedIdentifier,
      _positionManagerData.minSponsorTokens,
      _positionManagerData.excessTokenBeneficiary,
      _positionManagerData.version
    );
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  function deposit(uint256 collateralAmount)
    external
    override
    notEmergencyShutdown
  {
    PositionData storage positionData = _getPositionData(_msgSender());

    positionData.depositTo(
      globalPositionData,
      positionManagerData,
      FixedPoint.Unsigned(collateralAmount),
      _msgSender(),
      _msgSender()
    );
  }

  function depositTo(address sponsor, uint256 collateralAmount)
    external
    override
    notEmergencyShutdown
    nonReentrant
  {
    PositionData storage positionData = _getPositionData(sponsor);

    positionData.depositTo(
      globalPositionData,
      positionManagerData,
      FixedPoint.Unsigned(collateralAmount),
      sponsor,
      _msgSender()
    );
  }

  function withdraw(uint256 collateralAmount)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 amountWithdrawn)
  {
    PositionData storage positionData = _getPositionData(_msgSender());

    amountWithdrawn = positionData
      .withdraw(
      globalPositionData,
      positionManagerData,
      FixedPoint.Unsigned(collateralAmount),
      _msgSender()
    )
      .rawValue;
  }

  function create(uint256 collateralAmount, uint256 numTokens)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 feeAmount)
  {
    PositionData storage positionData = positions[_msgSender()];
    feeAmount = positionData
      .create(
      globalPositionData,
      positionManagerData,
      FixedPoint.Unsigned(collateralAmount),
      FixedPoint.Unsigned(numTokens),
      feeStatus,
      _msgSender()
    )
      .rawValue;
  }

  function redeem(uint256 numTokens)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 amountWithdrawn, uint256 feeAmount)
  {
    PositionData storage positionData = _getPositionData(_msgSender());

    (
      FixedPoint.Unsigned memory collateralAmount,
      FixedPoint.Unsigned memory uFeeAmount
    ) =
      positionData.redeem(
        globalPositionData,
        positionManagerData,
        FixedPoint.Unsigned(numTokens),
        feeStatus,
        _msgSender()
      );

    amountWithdrawn = collateralAmount.rawValue;
    feeAmount = uFeeAmount.rawValue;
  }

  function repay(uint256 numTokens)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 feeAmount)
  {
    PositionData storage positionData = _getPositionData(_msgSender());
    feeAmount = (
      positionData.repay(
        globalPositionData,
        positionManagerData,
        FixedPoint.Unsigned(numTokens),
        feeStatus,
        _msgSender()
      )
    )
      .rawValue;
  }

  function liquidate(address sponsor, uint256 maxTokensToLiquidate)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (
      uint256 tokensLiquidated,
      uint256 collateralLiquidated,
      uint256 collateralReward
    )
  {
    // Retrieve Position data for sponsor
    PositionData storage positionToLiquidate = _getPositionData(sponsor);

    // try to liquidate it - reverts if is properly collateralised
    (
      collateralLiquidated,
      tokensLiquidated,
      collateralReward
    ) = positionToLiquidate.liquidate(
      positionManagerData,
      globalPositionData,
      FixedPoint.Unsigned(maxTokensToLiquidate),
      _msgSender()
    );

    emit Liquidation(
      sponsor,
      _msgSender(),
      tokensLiquidated,
      collateralLiquidated,
      collateralReward,
      block.timestamp
    );
  }

  function settleEmergencyShutdown()
    external
    override
    isEmergencyShutdown()
    nonReentrant
    returns (uint256 amountWithdrawn)
  {
    PositionData storage positionData = positions[_msgSender()];
    amountWithdrawn = positionData
      .settleEmergencyShutdown(
      globalPositionData,
      positionManagerData,
      _msgSender()
    )
      .rawValue;
  }

  function emergencyShutdown()
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 timestamp, uint256 price)
  {
    return positionManagerData.emergencyShutdown();
  }

  function claimFee()
    external
    override
    nonReentrant
    returns (uint256 feeClaimed)
  {
    feeClaimed = positionManagerData.claimFee(feeStatus, _msgSender());
  }

  function trimExcess(IERC20 token)
    external
    override
    nonReentrant
    returns (uint256 amount)
  {
    amount = positionManagerData
      .trimExcess(globalPositionData, feeStatus, token)
      .rawValue;
  }

  function deleteSponsorPosition(address sponsor) external override {
    require(
      _msgSender() == address(this),
      'Only the contract can invoke this function'
    );
    delete positions[sponsor];
  }

  function minSponsorTokens() external view override returns (uint256 amount) {
    amount = positionManagerData.minSponsorTokens.rawValue;
  }

  function excessTokensBeneficiary()
    external
    view
    override
    returns (address beneficiary)
  {
    beneficiary = positionManagerData.excessTokenBeneficiary;
  }

  function capMintAmount() external view override returns (uint256 capMint) {
    capMint = positionManagerData.capMintAmount().rawValue;
  }

  function feeInfo() external view override returns (Fee memory fee) {
    fee = positionManagerData.feeInfo();
  }

  function totalFeeAmount() external view override returns (uint256 totalFee) {
    totalFee = feeStatus.totalFeeAmount.rawValue;
  }

  function userFeeGained(address feeGainer)
    external
    view
    override
    returns (uint256 feeGained)
  {
    feeGained = feeStatus.feeGained[feeGainer].rawValue;
  }

  function liquidationReward()
    external
    view
    override
    returns (uint256 rewardPct)
  {
    rewardPct = positionManagerData.liquidationRewardPercentage().rawValue;
  }

  function collateralRequirement()
    external
    view
    override
    returns (uint256 collReq)
  {
    collReq = positionManagerData.collateralRequirement().rawValue;
  }

  function getPositionData(address sponsor)
    external
    view
    override
    returns (uint256 collateralAmount, uint256 tokensAmount)
  {
    return (
      positions[sponsor].rawCollateral.rawValue,
      positions[sponsor].tokensOutstanding.rawValue
    );
  }

  function getGlobalPositionData()
    external
    view
    override
    returns (uint256 totCollateral, uint256 totTokensOutstanding)
  {
    totCollateral = globalPositionData.rawTotalPositionCollateral.rawValue;
    totTokensOutstanding = globalPositionData.totalTokensOutstanding.rawValue;
  }

  function collateralCoverage(address sponsor)
    external
    view
    override
    returns (bool, uint256)
  {
    return positionManagerData.collateralCoverage(positions[sponsor]);
  }

  function synthereumFinder()
    external
    view
    override
    returns (ISynthereumFinder finder)
  {
    finder = positionManagerData.synthereumFinder;
  }

  function syntheticToken() external view override returns (IERC20 synthToken) {
    synthToken = positionManagerData.tokenCurrency;
  }

  function collateralToken() public view override returns (IERC20 collateral) {
    collateral = positionManagerData.collateralToken;
  }

  function syntheticTokenSymbol()
    external
    view
    override
    returns (string memory symbol)
  {
    symbol = IStandardERC20(address(positionManagerData.tokenCurrency))
      .symbol();
  }

  function version() external view override returns (uint8 contractVersion) {
    contractVersion = positionManagerData.version;
  }

  function priceIdentifier()
    external
    view
    override
    returns (bytes32 identifier)
  {
    identifier = positionManagerData.priceIdentifier;
  }

  function emergencyShutdownPrice()
    external
    view
    override
    isEmergencyShutdown()
    returns (uint256 price)
  {
    price = positionManagerData.emergencyShutdownPrice.rawValue;
  }

  function emergencyShutdownTime()
    external
    view
    override
    isEmergencyShutdown()
    returns (uint256 time)
  {
    time = positionManagerData.emergencyShutdownTimestamp;
  }

  /**
   * @notice Check if an address is the trusted forwarder
   * @param  forwarder Address to check
   * @return True is the input address is the trusted forwarder, otherwise false
   */
  function isTrustedForwarder(address forwarder)
    public
    view
    override
    returns (bool)
  {
    try
      positionManagerData.synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.TrustedForwarder
      )
    returns (address trustedForwarder) {
      if (forwarder == trustedForwarder) {
        return true;
      } else {
        return false;
      }
    } catch {
      return false;
    }
  }

  //----------------------------------------
  // Internal functions
  //----------------------------------------
  function _getPositionData(address sponsor)
    internal
    view
    onlyCollateralisedPosition(sponsor)
    returns (PositionData storage)
  {
    return positions[sponsor];
  }

  function _msgSender()
    internal
    view
    override(ERC2771Context)
    returns (address sender)
  {
    return ERC2771Context._msgSender();
  }

  function _msgData()
    internal
    view
    override(ERC2771Context)
    returns (bytes calldata)
  {
    return ERC2771Context._msgData();
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {IStandardERC20} from '../../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableERC20
} from '../../../tokens/interfaces/IMintableBurnableERC20.sol';
import {
  FixedPoint
} from '../../../../@uma/core/contracts/common/implementation/FixedPoint.sol';

interface ICreditLineStorage {
  // Describe fee structure
  struct Fee {
    // Fees charged when a user mints, redeem and exchanges tokens
    uint256 feePercentage;
    // Recipient receiving fees
    address[] feeRecipients;
    // Proportion for each recipient
    uint32[] feeProportions;
    // Used with individual proportions to scale values
    uint256 totalFeeProportions;
  }

  struct FeeStatus {
    // Track the fee gained to be withdrawn by an address
    mapping(address => FixedPoint.Unsigned) feeGained;
    // Total amount of fees to be withdrawn
    FixedPoint.Unsigned totalFeeAmount;
  }

  // Represents a single sponsor's position. All collateral is held by this contract.
  // This struct acts as bookkeeping for how much of that collateral is allocated to each sponsor.
  struct PositionData {
    FixedPoint.Unsigned tokensOutstanding;
    FixedPoint.Unsigned rawCollateral;
  }

  struct GlobalPositionData {
    // Keep track of the total collateral and tokens across all positions
    FixedPoint.Unsigned totalTokensOutstanding;
    // Similar to the rawCollateral in PositionData, this value should not be used directly.
    //_getFeeAdjustedCollateral(), _addCollateral() and _removeCollateral() must be used to access and adjust.
    FixedPoint.Unsigned rawTotalPositionCollateral;
  }

  struct PositionManagerData {
    // SynthereumFinder contract
    ISynthereumFinder synthereumFinder;
    // Collateral token
    IStandardERC20 collateralToken;
    // Synthetic token created by this contract.
    IMintableBurnableERC20 tokenCurrency;
    // Unique identifier for DVM price feed ticker.
    bytes32 priceIdentifier;
    // Minimum number of tokens in a sponsor's position.
    FixedPoint.Unsigned minSponsorTokens;
    // Expiry price pulled from Chainlink in the case of an emergency shutdown.
    FixedPoint.Unsigned emergencyShutdownPrice;
    // Timestamp used in case of emergency shutdown.
    uint256 emergencyShutdownTimestamp;
    // The excessTokenBeneficiary of any excess tokens added to the contract.
    address excessTokenBeneficiary;
    // Version of the self-minting derivative
    uint8 version;
  }

  /**
   * @notice Construct the PerpetualPositionManager.
   * @dev Deployer of this contract should consider carefully which parties have ability to mint and burn
   * the synthetic tokens referenced by `_tokenAddress`. This contract's security assumes that no external accounts
   * can mint new tokens, which could be used to steal all of this contract's locked collateral.
   * We recommend to only use synthetic token contracts whose sole Owner role (the role capable of adding & removing roles)
   * is assigned to this contract, whose sole Minter role is assigned to this contract, and whose
   * total supply is 0 prior to construction of this contract.
   * @param collateralAddress ERC20 token used as collateral for all positions.
   * @param tokenAddress ERC20 token used as synthetic token.
   * @param priceFeedIdentifier registered in the ChainLink Oracle for the synthetic.
   * @param minSponsorTokens minimum amount of collateral that must exist at any time in a position.
   * @param timerAddress Contract that stores the current time in a testing environment. Set to 0x0 for production.
   * @param excessTokenBeneficiary Beneficiary to send all excess token balances that accrue in the contract.
   * @param version Version of the self-minting derivative
   * @param synthereumFinder The SynthereumFinder contract
   */
  struct PositionManagerParams {
    IStandardERC20 collateralToken;
    IMintableBurnableERC20 syntheticToken;
    bytes32 priceFeedIdentifier;
    FixedPoint.Unsigned minSponsorTokens;
    address excessTokenBeneficiary;
    uint8 version;
    ISynthereumFinder synthereumFinder;
  }

  struct LiquidationData {
    address sponsor;
    address liquidator;
    uint256 liquidationTime;
    uint256 numTokensBurnt;
    uint256 liquidatedCollateral;
  }

  struct ExecuteLiquidationData {
    FixedPoint.Unsigned tokensToLiquidate;
    FixedPoint.Unsigned collateralValueLiquidatedTokens;
    FixedPoint.Unsigned collateralLiquidated;
    FixedPoint.Unsigned liquidatorReward;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IStandardERC20 is IERC20 {
  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() external view returns (string memory);

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
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title ERC20 interface that includes burn mint and roles methods.
 */
interface IMintableBurnableERC20 is IERC20 {
  /**
   * @notice Burns a specific amount of the caller's tokens.
   * @dev This method should be permissioned to only allow designated parties to burn tokens.
   */
  function burn(uint256 value) external;

  /**
   * @notice Mints tokens and adds them to the balance of the `to` address.
   * @dev This method should be permissioned to only allow designated parties to mint tokens.
   */
  function mint(address to, uint256 value) external returns (bool);

  /**
   * @notice Returns the number of decimals used to get its user representation.
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

/**
 * @title Provides addresses of the contracts implementing certain interfaces.
 */
interface ISynthereumFinder {
  /**
   * @notice Updates the address of the contract that implements `interfaceName`.
   * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
   * @param implementationAddress address of the deployed contract that implements the interface.
   */
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external;

  /**
   * @notice Gets the address of the contract that implements the given `interfaceName`.
   * @param interfaceName queried interface.
   * @return implementationAddress Address of the deployed contract that implements the interface.
   */
  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {
  IStandardERC20,
  IERC20
} from '../../../base/interfaces/IStandardERC20.sol';
import {
  ISynthereumDeployment
} from '../../../common/interfaces/IDeployment.sol';
import {
  IEmergencyShutdown
} from '../../../common/interfaces/IEmergencyShutdown.sol';
import {ICreditLineStorage} from './ICreditLineStorage.sol';
import {ITypology} from '../../../common/interfaces/ITypology.sol';
import {
  FixedPoint
} from '../../../../@uma/core/contracts/common/implementation/FixedPoint.sol';

interface ICreditLine is ITypology, IEmergencyShutdown, ISynthereumDeployment {
  /**
   * @notice Transfers `collateralAmount` into the caller's position.
   * @dev Increases the collateralization level of a position after creation. This contract must be approved to spend
   * at least `collateralAmount` of collateral token
   * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
   */
  function deposit(uint256 collateralAmount) external;

  /**
   * @notice Transfers `collateralAmount` into the specified sponsor's position.
   * @dev Increases the collateralization level of a position after creation. This contract must be approved to spend
   * at least `collateralAmount` of collateralCurrency.
   * @param sponsor the sponsor to credit the deposit to.
   * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
   */
  function depositTo(address sponsor, uint256 collateralAmount) external;

  /**
   * @notice Transfers `collateralAmount` from the sponsor's position to the sponsor.
   * @dev Reverts if the withdrawal puts this position's collateralization ratio below the collateral requirement
   * @param collateralAmount is the amount of collateral to withdraw.
   * @return amountWithdrawn The actual amount of collateral withdrawn.
   */
  function withdraw(uint256 collateralAmount)
    external
    returns (uint256 amountWithdrawn);

  /**
   * @notice Pulls `collateralAmount` into the sponsor's position and mints `numTokens` of `tokenCurrency`.
   * Mints new debt tokens by creating a new position or by augmenting an existing position.
   * @dev Can only be called by a token sponsor. This contract must be approved to spend at least `collateralAmount` of
   * `collateralCurrency`.
   * @param collateralAmount is the number of collateral tokens to collateralize the position with
   * @param numTokens is the number of debt tokens to mint to sponsor.
   */
  function create(uint256 collateralAmount, uint256 numTokens)
    external
    returns (uint256 feeAmount);

  /**
   * @notice Burns `numTokens` of `tokenCurrency` and sends back the proportional amount of collateral
   * @dev Can only be called by a token sponsor- This contract must be approved to spend at least `numTokens` of
   * `tokenCurrency`.
   * @param numTokens is the number of tokens to be burnt.
   * @return amountWithdrawn The actual amount of collateral withdrawn.
   * @return feeAmount incurred fees in collateral token.
   */
  function redeem(uint256 numTokens)
    external
    returns (uint256 amountWithdrawn, uint256 feeAmount);

  /**
   * @notice Burns `numTokens` of `tokenCurrency` to decrease sponsors position size, without sending back collateral.
   * This is done by a sponsor to increase position CR.
   * @dev Can only be called by token sponsor. This contract must be approved to spend `numTokens` of `tokenCurrency`.
   * @param numTokens is the number of tokens to be burnt.
   */
  function repay(uint256 numTokens) external returns (uint256 daoFeeAmount);

  /**
   * @notice Liquidate sponsor position for an amount of synthetic tokens undercollateralized
   * @notice Revert if position is not undercollateralized
   * @param sponsor Address of sponsor to be liquidated.
   * @param maxTokensToLiquidate Max number of synthetic tokens to be liquidated
   * @return tokensLiquidated Amount of debt tokens burned
   * @return collateralLiquidated Amount of received collateral equal to the value of tokens liquidated
   * @return collateralReward Amount of received collateral as reward for the liquidation
   */
  function liquidate(address sponsor, uint256 maxTokensToLiquidate)
    external
    returns (
      uint256 tokensLiquidated,
      uint256 collateralLiquidated,
      uint256 collateralReward
    );

  /**
   * @notice When in emergency shutdown state all token holders and sponsor can redeem their tokens and
   * remaining collateral at the prevailing price defined by the on-chain oracle
   * @dev This burns all tokens from the caller of `tokenCurrency` and sends back the resolved settlement value of
   * collateral. This contract must be approved to spend `tokenCurrency` at least up to the caller's full balance.
   * @dev This contract must have the Burner role for the `tokenCurrency`.
   * @return amountWithdrawn The actual amount of collateral withdrawn.
   */
  function settleEmergencyShutdown() external returns (uint256 amountWithdrawn);

  /**
   * @notice Withdraw fees gained by the sender
   * @return feeClaimed Amount of fee claimed
   */
  function claimFee() external returns (uint256 feeClaimed);

  /**
   * @notice trim any excess funds in the contract to the excessTokenBeneficiary address
   * @return amount the amount of tokens trimmed
   */
  function trimExcess(IERC20 token) external returns (uint256 amount);

  /**
   * @notice Delete a TokenSponsor position. This function can only be called by the contract itself.
   * @param sponsor address of the TokenSponsor.
   */
  function deleteSponsorPosition(address sponsor) external;

  /**
   * @notice Returns the minimum amount of tokens a sponsor must mint
   * @return amount the value
   */
  function minSponsorTokens() external view returns (uint256 amount);

  /**
   * @notice Returns the address of the trim excess tokens receiver
   * @return beneficiary the addess
   */
  function excessTokensBeneficiary()
    external
    view
    returns (address beneficiary);

  /**
   * @notice Returns the cap mint amount of the derivative contract
   * @return capMint cap mint amount
   */
  function capMintAmount() external view returns (uint256 capMint);

  /**
   * @notice Returns the fee parameters of the derivative contract
   * @return fee Fee struct
   */
  function feeInfo() external view returns (ICreditLineStorage.Fee memory fee);

  /**
   * @notice Returns the total fee produced by the contract
   * @return totalFee total amount of fees
   */
  function totalFeeAmount() external view returns (uint256 totalFee);

  /**
   * @notice Returns the total fee gained by the input address
   * @param feeGainer address to check claimable fees
   * @return feeGained amount of fess claimable by feeGainer
   */
  function userFeeGained(address feeGainer)
    external
    view
    returns (uint256 feeGained);

  /**
   * @notice Returns the liquidation rewrd percentage of the derivative contract
   * @return rewardPct liquidator reward percentage
   */
  function liquidationReward() external view returns (uint256 rewardPct);

  /**
   * @notice Returns the over collateralization percentage of the derivative contract
   * @return collReq percentage of overcollateralization
   */
  function collateralRequirement() external view returns (uint256 collReq);

  /**
   * @notice Accessor method for a sponsor's position.
   * @param sponsor address whose position data is retrieved.
   * @return collateralAmount amount of collateral of the sponsor's position.
   * @return tokensAmount amount of outstanding tokens of the sponsor's position.
   */
  function getPositionData(address sponsor)
    external
    view
    returns (uint256 collateralAmount, uint256 tokensAmount);

  /**
   * @notice Accessor method for contract's global position (aggregate).
   * @return totCollateral total amount of collateral deposited by lps
   * @return totTokensOutstanding total amount of outstanding tokens.
   */
  function getGlobalPositionData()
    external
    view
    returns (uint256 totCollateral, uint256 totTokensOutstanding);

  /**
   * @notice Returns if sponsor position is overcollateralized and thepercentage of coverage of the collateral according to the last price
   * @return True if position is overcollaterlized, otherwise false + percentage of coverage (totalCollateralAmount / (price * tokensCollateralized))
   */
  function collateralCoverage(address sponsor)
    external
    view
    returns (bool, uint256);

  /**
   * @notice Get synthetic token price identifier as represented by the oracle interface
   * @return identifier Synthetic token price identifier
   */
  function priceIdentifier() external view returns (bytes32 identifier);

  /**
   * @notice Get the price of synthetic token set by DVM after emergencyShutdown call
   * @return price Price of synthetic token
   */
  function emergencyShutdownPrice() external view returns (uint256 price);

  /**
   * @notice Get the block number when the emergency shutdown was called
   * @return time Block time
   */
  function emergencyShutdownTime() external view returns (uint256 time);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

/**
 * @title Stores common interface names used throughout Synthereum.
 */
library SynthereumInterfaces {
  bytes32 public constant Deployer = 'Deployer';
  bytes32 public constant FactoryVersioning = 'FactoryVersioning';
  bytes32 public constant TokenFactory = 'TokenFactory';
  bytes32 public constant PoolRegistry = 'PoolRegistry';
  bytes32 public constant SelfMintingRegistry = 'SelfMintingRegistry';
  bytes32 public constant PriceFeed = 'PriceFeed';
  bytes32 public constant Manager = 'Manager';
  bytes32 public constant CreditLineController = 'CreditLineController';
  bytes32 public constant CollateralWhitelist = 'CollateralWhitelist';
  bytes32 public constant IdentifierWhitelist = 'IdentifierWhitelist';
  bytes32 public constant TrustedForwarder = 'TrustedForwarder';
}

library FactoryInterfaces {
  bytes32 public constant PoolFactory = 'PoolFactory';
  bytes32 public constant SelfMintingFactory = 'SelfMintingFactory';
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import {ICreditLineStorage} from './interfaces/ICreditLineStorage.sol';
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableERC20
} from '../../tokens/interfaces/IMintableBurnableERC20.sol';
import {ICreditLineController} from './interfaces/ICreditLineController.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumPriceFeed
} from '../../oracle/common/interfaces/IPriceFeed.sol';
import {
  FixedPoint
} from '../../../@uma/core/contracts/common/implementation/FixedPoint.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {CreditLine} from './CreditLine.sol';

library CreditLineLib {
  using FixedPoint for FixedPoint.Unsigned;
  using SafeERC20 for IERC20;
  using SafeERC20 for IStandardERC20;
  using SafeERC20 for IMintableBurnableERC20;
  using CreditLineLib for ICreditLineStorage.PositionData;
  using CreditLineLib for ICreditLineStorage.PositionManagerData;
  using CreditLineLib for ICreditLineStorage.FeeStatus;
  using CreditLineLib for FixedPoint.Unsigned;

  //----------------------------------------
  // Events
  //----------------------------------------

  event Deposit(address indexed sponsor, uint256 indexed collateralAmount);
  event Withdrawal(address indexed sponsor, uint256 indexed collateralAmount);
  event PositionCreated(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount,
    uint256 feeAmount
  );
  event NewSponsor(address indexed sponsor);
  event EndedSponsorPosition(address indexed sponsor);
  event Redeem(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount,
    uint256 feeAmount
  );

  event ClaimFee(
    address indexed claimer,
    uint256 feeAmount,
    uint256 totalRemainingFees
  );

  event Repay(
    address indexed sponsor,
    uint256 indexed numTokensRepaid,
    uint256 indexed newTokenCount,
    uint256 feeAmount
  );
  event EmergencyShutdown(
    address indexed caller,
    uint256 settlementPrice,
    uint256 shutdownTimestamp
  );
  event SettleEmergencyShutdown(
    address indexed caller,
    uint256 indexed collateralReturned,
    uint256 indexed tokensBurned
  );

  event SetFeePercentage(uint256 feePercentage);
  event SetFeeRecipients(address[] feeRecipients, uint32[] feeProportions);

  //----------------------------------------
  // External functions
  //----------------------------------------

  function initialize(
    ICreditLineStorage.PositionManagerData storage self,
    ISynthereumFinder _finder,
    IStandardERC20 _collateralToken,
    IMintableBurnableERC20 _tokenCurrency,
    bytes32 _priceIdentifier,
    FixedPoint.Unsigned memory _minSponsorTokens,
    address _excessTokenBeneficiary,
    uint8 _version
  ) external {
    ISynthereumPriceFeed priceFeed =
      ISynthereumPriceFeed(
        _finder.getImplementationAddress(SynthereumInterfaces.PriceFeed)
      );

    require(
      priceFeed.isPriceSupported(_priceIdentifier),
      'Price identifier not supported'
    );
    require(
      _collateralToken.decimals() <= 18,
      'Collateral has more than 18 decimals'
    );
    require(
      _tokenCurrency.decimals() == 18,
      'Synthetic token has more or less than 18 decimals'
    );
    self.priceIdentifier = _priceIdentifier;
    self.synthereumFinder = _finder;
    self.collateralToken = _collateralToken;
    self.tokenCurrency = _tokenCurrency;
    self.minSponsorTokens = _minSponsorTokens;
    self.excessTokenBeneficiary = _excessTokenBeneficiary;
    self.version = _version;
  }

  function depositTo(
    ICreditLineStorage.PositionData storage positionData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    FixedPoint.Unsigned memory collateralAmount,
    address sponsor,
    address msgSender
  ) external {
    require(collateralAmount.isGreaterThan(0), 'Invalid collateral amount');

    // Increase the position and global collateral balance by collateral amount.
    positionData._incrementCollateralBalances(
      globalPositionData,
      collateralAmount
    );

    emit Deposit(sponsor, collateralAmount.rawValue);

    positionManagerData.collateralToken.safeTransferFrom(
      msgSender,
      address(this),
      collateralAmount.rawValue
    );
  }

  function withdraw(
    ICreditLineStorage.PositionData storage positionData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    FixedPoint.Unsigned memory collateralAmount,
    address msgSender
  ) external returns (FixedPoint.Unsigned memory) {
    require(collateralAmount.isGreaterThan(0), 'Invalid collateral amount');

    // Decrement the sponsor's collateral and global collateral amounts.
    // Reverts if the resulting position is not properly collateralized
    _decrementCollateralBalancesCheckCR(
      positionData,
      globalPositionData,
      positionManagerData,
      collateralAmount
    );

    emit Withdrawal(msgSender, collateralAmount.rawValue);

    // Move collateral currency from contract to sender.
    positionManagerData.collateralToken.safeTransfer(
      msgSender,
      collateralAmount.rawValue
    );

    return collateralAmount;
  }

  function create(
    ICreditLineStorage.PositionData storage positionData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens,
    ICreditLineStorage.FeeStatus storage feeStatus,
    address msgSender
  ) external returns (FixedPoint.Unsigned memory feeAmount) {
    // Update fees status - percentage is retrieved from Credit Line Controller
    FixedPoint.Unsigned memory priceRate = _getOraclePrice(positionManagerData);
    uint256 collateralDecimals =
      getCollateralDecimals(positionManagerData.collateralToken);
    feeAmount = calculateCollateralAmount(
      numTokens,
      priceRate,
      collateralDecimals
    )
      .mul(
      FixedPoint.Unsigned(positionManagerData._getFeeInfo().feePercentage)
    );
    positionManagerData.updateFees(feeStatus, feeAmount);

    if (positionData.tokensOutstanding.isEqual(0)) {
      require(
        _checkCollateralization(
          positionManagerData,
          collateralAmount.sub(feeAmount),
          numTokens,
          priceRate,
          collateralDecimals
        ),
        'Insufficient Collateral'
      );
      require(
        numTokens.isGreaterThanOrEqual(positionManagerData.minSponsorTokens),
        'Below minimum sponsor position'
      );
      emit NewSponsor(msgSender);
    } else {
      require(
        _checkCollateralization(
          positionManagerData,
          positionData.rawCollateral.add(collateralAmount).sub(feeAmount),
          positionData.tokensOutstanding.add(numTokens),
          priceRate,
          collateralDecimals
        ),
        'Insufficient Collateral'
      );
    }

    // Increase or decrease the position and global collateral balance by collateral amount or fee amount.
    collateralAmount.isGreaterThanOrEqual(feeAmount)
      ? positionData._incrementCollateralBalances(
        globalPositionData,
        collateralAmount.sub(feeAmount)
      )
      : positionData._decrementCollateralBalances(
        globalPositionData,
        feeAmount.sub(collateralAmount)
      );

    // Add the number of tokens created to the position's outstanding tokens and global.
    positionData.tokensOutstanding = positionData.tokensOutstanding.add(
      numTokens
    );

    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .add(numTokens);

    checkMintLimit(globalPositionData, positionManagerData);

    if (collateralAmount.isGreaterThan(FixedPoint.Unsigned(0))) {
      // pull collateral
      IERC20 collateralCurrency = positionManagerData.collateralToken;

      // Transfer tokens into the contract from caller
      collateralCurrency.safeTransferFrom(
        msgSender,
        address(this),
        (collateralAmount).rawValue
      );
    }

    // mint corresponding synthetic tokens to the caller's address.
    positionManagerData.tokenCurrency.mint(msgSender, numTokens.rawValue);

    emit PositionCreated(
      msgSender,
      collateralAmount.rawValue,
      numTokens.rawValue,
      feeAmount.rawValue
    );
  }

  function redeem(
    ICreditLineStorage.PositionData storage positionData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    FixedPoint.Unsigned memory numTokens,
    ICreditLineStorage.FeeStatus storage feeStatus,
    address sponsor
  )
    external
    returns (
      FixedPoint.Unsigned memory amountWithdrawn,
      FixedPoint.Unsigned memory feeAmount
    )
  {
    require(
      numTokens.isLessThanOrEqual(positionData.tokensOutstanding),
      'Invalid token amount'
    );

    FixedPoint.Unsigned memory collateralRedeemed =
      positionData.rawCollateral.mul(numTokens).div(
        positionData.tokensOutstanding
      );

    FixedPoint.Unsigned memory priceRate = _getOraclePrice(positionManagerData);

    // Update fee status
    feeAmount = calculateCollateralAmount(
      numTokens,
      priceRate,
      getCollateralDecimals(positionManagerData.collateralToken)
    )
      .mul(
      FixedPoint.Unsigned(positionManagerData._getFeeInfo().feePercentage)
    );
    positionManagerData.updateFees(feeStatus, feeAmount);

    // If redemption returns all tokens the sponsor has then we can delete their position. Else, downsize.
    if (positionData.tokensOutstanding.isEqual(numTokens)) {
      positionData._deleteSponsorPosition(globalPositionData, sponsor);
    } else {
      // Decrement the sponsor's collateral and global collateral amounts.
      positionData._decrementCollateralBalances(
        globalPositionData,
        collateralRedeemed
      );

      // Decrease the sponsors position tokens size. Ensure it is above the min sponsor size.
      FixedPoint.Unsigned memory newTokenCount =
        positionData.tokensOutstanding.sub(numTokens);
      require(
        newTokenCount.isGreaterThanOrEqual(
          positionManagerData.minSponsorTokens
        ),
        'Below minimum sponsor position'
      );
      positionData.tokensOutstanding = newTokenCount;
      // Update the totalTokensOutstanding after redemption.
      globalPositionData.totalTokensOutstanding = globalPositionData
        .totalTokensOutstanding
        .sub(numTokens);
    }
    // adjust the fees from collateral to withdraws
    amountWithdrawn = collateralRedeemed.sub(feeAmount);

    // transfer collateral to user
    IERC20 collateralCurrency = positionManagerData.collateralToken;

    {
      collateralCurrency.safeTransfer(sponsor, amountWithdrawn.rawValue);

      // Pull and burn callers synthetic tokens.
      positionManagerData.tokenCurrency.safeTransferFrom(
        sponsor,
        address(this),
        numTokens.rawValue
      );
      positionManagerData.tokenCurrency.burn(numTokens.rawValue);
    }

    emit Redeem(
      sponsor,
      amountWithdrawn.rawValue,
      numTokens.rawValue,
      feeAmount.rawValue
    );
  }

  function repay(
    ICreditLineStorage.PositionData storage positionData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    FixedPoint.Unsigned memory numTokens,
    ICreditLineStorage.FeeStatus storage feeStatus,
    address msgSender
  ) external returns (FixedPoint.Unsigned memory feeAmount) {
    require(
      numTokens.isLessThanOrEqual(positionData.tokensOutstanding),
      'Invalid token amount'
    );

    // Decrease the sponsors position tokens size. Ensure it is above the min sponsor size.
    FixedPoint.Unsigned memory newTokenCount =
      positionData.tokensOutstanding.sub(numTokens);
    require(
      newTokenCount.isGreaterThanOrEqual(positionManagerData.minSponsorTokens),
      'Below minimum sponsor position'
    );

    FixedPoint.Unsigned memory priceRate = _getOraclePrice(positionManagerData);

    // Update fee status
    feeAmount = calculateCollateralAmount(
      numTokens,
      priceRate,
      getCollateralDecimals(positionManagerData.collateralToken)
    )
      .mul(
      FixedPoint.Unsigned(positionManagerData._getFeeInfo().feePercentage)
    );
    positionManagerData.updateFees(feeStatus, feeAmount);

    // update position
    positionData.tokensOutstanding = newTokenCount;
    _decrementCollateralBalances(positionData, globalPositionData, feeAmount);

    // Update the totalTokensOutstanding after redemption.
    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(numTokens);

    // Transfer the tokens back from the sponsor and burn them.
    positionManagerData.tokenCurrency.safeTransferFrom(
      msgSender,
      address(this),
      numTokens.rawValue
    );
    positionManagerData.tokenCurrency.burn(numTokens.rawValue);

    emit Repay(
      msgSender,
      numTokens.rawValue,
      newTokenCount.rawValue,
      feeAmount.rawValue
    );
  }

  function liquidate(
    ICreditLineStorage.PositionData storage positionToLiquidate,
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    FixedPoint.Unsigned calldata numSynthTokens,
    address msgSender
  )
    external
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    // to avoid stack too deep
    ICreditLineStorage.ExecuteLiquidationData memory executeLiquidationData;
    uint256 collateralDecimals =
      getCollateralDecimals(positionManagerData.collateralToken);

    FixedPoint.Unsigned memory priceRate = _getOraclePrice(positionManagerData);

    // make sure position is undercollateralised
    require(
      !positionManagerData._checkCollateralization(
        positionToLiquidate.rawCollateral,
        positionToLiquidate.tokensOutstanding,
        priceRate,
        collateralDecimals
      ),
      'Position is properly collateralised'
    );

    // calculate tokens to liquidate
    executeLiquidationData.tokensToLiquidate.rawValue = positionToLiquidate
      .tokensOutstanding
      .isGreaterThan(numSynthTokens)
      ? numSynthTokens.rawValue
      : positionToLiquidate.tokensOutstanding.rawValue;

    // calculate collateral value of those tokens
    executeLiquidationData
      .collateralValueLiquidatedTokens = calculateCollateralAmount(
      executeLiquidationData.tokensToLiquidate,
      priceRate,
      collateralDecimals
    );

    // calculate proportion of collateral liquidated from position
    executeLiquidationData.collateralLiquidated = executeLiquidationData
      .tokensToLiquidate
      .div(positionToLiquidate.tokensOutstanding)
      .mul(positionToLiquidate.rawCollateral);

    // compute final liquidation outcome
    if (
      executeLiquidationData.collateralLiquidated.isGreaterThan(
        executeLiquidationData.collateralValueLiquidatedTokens
      )
    ) {
      // position is still capitalised - liquidator profits
      executeLiquidationData.liquidatorReward = (
        executeLiquidationData.collateralLiquidated.sub(
          executeLiquidationData.collateralValueLiquidatedTokens
        )
      )
        .mul(positionManagerData._getLiquidationReward());
      executeLiquidationData.collateralLiquidated = executeLiquidationData
        .collateralValueLiquidatedTokens
        .add(executeLiquidationData.liquidatorReward);
    }

    // reduce position
    positionToLiquidate._reducePosition(
      globalPositionData,
      executeLiquidationData.tokensToLiquidate,
      executeLiquidationData.collateralLiquidated
    );

    // transfer tokens from liquidator to here and burn them
    _burnLiquidatedTokens(
      positionManagerData,
      msgSender,
      executeLiquidationData.tokensToLiquidate.rawValue
    );

    // pay sender with collateral unlocked + rewards
    positionManagerData.collateralToken.safeTransfer(
      msgSender,
      executeLiquidationData.collateralLiquidated.rawValue
    );

    // return values
    return (
      executeLiquidationData.collateralLiquidated.rawValue,
      executeLiquidationData.tokensToLiquidate.rawValue,
      executeLiquidationData.liquidatorReward.rawValue
    );
  }

  function emergencyShutdown(
    ICreditLineStorage.PositionManagerData storage self
  ) external returns (uint256 timestamp, uint256 price) {
    require(
      msg.sender ==
        self.synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.Manager
        ),
      'Caller must be a Synthereum manager'
    );

    timestamp = block.timestamp;
    FixedPoint.Unsigned memory _price = self._getOraclePrice();

    // store timestamp and last price
    self.emergencyShutdownTimestamp = timestamp;
    self.emergencyShutdownPrice = _price;

    price = _price.rawValue;

    emit EmergencyShutdown(msg.sender, price, timestamp);
  }

  function settleEmergencyShutdown(
    ICreditLineStorage.PositionData storage positionData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    address msgSender
  ) external returns (FixedPoint.Unsigned memory amountWithdrawn) {
    // copy value
    FixedPoint.Unsigned memory emergencyShutdownPrice =
      positionManagerData.emergencyShutdownPrice;
    IMintableBurnableERC20 tokenCurrency = positionManagerData.tokenCurrency;
    FixedPoint.Unsigned memory rawCollateral = positionData.rawCollateral;
    FixedPoint.Unsigned memory totalCollateral =
      globalPositionData.rawTotalPositionCollateral;

    // Get caller's tokens balance
    FixedPoint.Unsigned memory tokensToRedeem =
      FixedPoint.Unsigned(tokenCurrency.balanceOf(msgSender));

    // calculate amount of underlying collateral entitled to them, with oracle emergency price
    FixedPoint.Unsigned memory totalRedeemableCollateral =
      tokensToRedeem.mul(emergencyShutdownPrice);

    // If the caller is a sponsor with outstanding collateral they are also entitled to their excess collateral after their debt.
    if (rawCollateral.isGreaterThan(0)) {
      // Calculate the underlying entitled to a token sponsor. This is collateral - debt
      FixedPoint.Unsigned memory tokenDebtValueInCollateral =
        positionData.tokensOutstanding.mul(emergencyShutdownPrice);

      // accrued to withdrawable collateral eventual excess collateral after debt
      if (tokenDebtValueInCollateral.isLessThan(rawCollateral)) {
        totalRedeemableCollateral = totalRedeemableCollateral.add(
          rawCollateral.sub(tokenDebtValueInCollateral)
        );
      }

      CreditLine(address(this)).deleteSponsorPosition(msgSender);
      emit EndedSponsorPosition(msgSender);
    }

    // Take the min of the remaining collateral and the collateral "owed". If the contract is undercapitalized,
    // the caller will get as much collateral as the contract can pay out.
    amountWithdrawn = FixedPoint.min(
      totalCollateral,
      totalRedeemableCollateral
    );

    // Decrement total contract collateral and outstanding debt.
    globalPositionData.rawTotalPositionCollateral = totalCollateral.sub(
      amountWithdrawn
    );
    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(tokensToRedeem);

    emit SettleEmergencyShutdown(
      msgSender,
      amountWithdrawn.rawValue,
      tokensToRedeem.rawValue
    );

    // Transfer tokens & collateral and burn the redeemed tokens.
    positionManagerData.collateralToken.safeTransfer(
      msgSender,
      amountWithdrawn.rawValue
    );
    tokenCurrency.safeTransferFrom(
      msgSender,
      address(this),
      tokensToRedeem.rawValue
    );
    tokenCurrency.burn(tokensToRedeem.rawValue);
  }

  /**
   * @notice Withdraw fees gained by the sender
   * @param self Data type the library is attached to
   * @param feeStatus Actual status of fee gained (see FeeStatus struct)
   * @return feeClaimed Amount of fee claimed
   */
  function claimFee(
    ICreditLineStorage.PositionManagerData storage self,
    ICreditLineStorage.FeeStatus storage feeStatus,
    address msgSender
  ) external returns (uint256 feeClaimed) {
    // Fee to claim
    FixedPoint.Unsigned memory _feeClaimed = feeStatus.feeGained[msgSender];

    // Check that fee is available
    require(_feeClaimed.isGreaterThanOrEqual(0), 'No fee to claim');

    // Update fee status
    delete feeStatus.feeGained[msgSender];

    FixedPoint.Unsigned memory _totalRemainingFees =
      feeStatus.totalFeeAmount.sub(_feeClaimed);

    feeStatus.totalFeeAmount = _totalRemainingFees;

    // Transfer amount to the sender
    feeClaimed = _feeClaimed.rawValue;

    self.collateralToken.safeTransfer(msgSender, _feeClaimed.rawValue);

    emit ClaimFee(msgSender, feeClaimed, _totalRemainingFees.rawValue);
  }

  /**
   * @notice Update fee gained by the fee recipients
   * @param feeStatus Actual status of fee gained to be withdrawn
   * @param feeAmount Collateral fee charged
   */
  function updateFees(
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    ICreditLineStorage.FeeStatus storage feeStatus,
    FixedPoint.Unsigned memory feeAmount
  ) internal {
    FixedPoint.Unsigned memory feeCharged;

    ICreditLineStorage.Fee memory feeStruct = positionManagerData._getFeeInfo();
    address[] memory feeRecipients = feeStruct.feeRecipients;
    uint32[] memory feeProportions = feeStruct.feeProportions;
    uint256 totalFeeProportions = feeStruct.totalFeeProportions;
    uint256 numberOfRecipients = feeRecipients.length;
    mapping(address => FixedPoint.Unsigned) storage feeGained =
      feeStatus.feeGained;

    for (uint256 i = 0; i < numberOfRecipients - 1; i++) {
      address feeRecipient = feeRecipients[i];
      FixedPoint.Unsigned memory feeReceived =
        FixedPoint.Unsigned(
          (feeAmount.rawValue * feeProportions[i]) / totalFeeProportions
        );
      feeGained[feeRecipient] = feeGained[feeRecipient].add(feeReceived);
      feeCharged = feeCharged.add(feeReceived);
    }

    address lastRecipient = feeRecipients[numberOfRecipients - 1];

    feeGained[lastRecipient] = feeGained[lastRecipient].add(feeAmount).sub(
      feeCharged
    );

    feeStatus.totalFeeAmount = feeStatus.totalFeeAmount.add(feeAmount);
  }

  function trimExcess(
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    ICreditLineStorage.FeeStatus storage feeStatus,
    IERC20 token
  ) external returns (FixedPoint.Unsigned memory amount) {
    FixedPoint.Unsigned memory balance =
      FixedPoint.Unsigned(token.balanceOf(address(this)));
    if (address(token) == address(positionManagerData.collateralToken)) {
      FixedPoint.Unsigned memory rawTotalPositionCollateral =
        globalPositionData.rawTotalPositionCollateral;
      FixedPoint.Unsigned memory totalFeeAmount = feeStatus.totalFeeAmount;
      // If it is the collateral currency, send only the amount that the contract is not tracking (ie minus fees and positions)
      balance.isGreaterThan(rawTotalPositionCollateral.add(totalFeeAmount))
        ? amount = balance.sub(rawTotalPositionCollateral).sub(totalFeeAmount)
        : amount = FixedPoint.Unsigned(0);
    } else {
      // If it's not the collateral currency, send the entire balance.
      amount = balance;
    }
    token.safeTransfer(
      positionManagerData.excessTokenBeneficiary,
      amount.rawValue
    );
  }

  /**
   * @notice Returns if position is overcollateralized and thepercentage of coverage of the collateral according to the last price
   * @param self Data type the library is attached to
   * @param positionData Position of the LP
   * @return True if position is overcollaterlized, otherwise false + percentage of coverage (totalCollateralAmount / (price * tokensCollateralized))
   */
  function collateralCoverage(
    ICreditLineStorage.PositionManagerData storage self,
    ICreditLineStorage.PositionData storage positionData
  ) external view returns (bool, uint256) {
    FixedPoint.Unsigned memory priceRate = _getOraclePrice(self);
    uint256 collateralDecimals = getCollateralDecimals(self.collateralToken);
    bool _isOverCollateralised =
      _checkCollateralization(
        self,
        positionData.rawCollateral,
        positionData.tokensOutstanding,
        priceRate,
        collateralDecimals
      );

    FixedPoint.Unsigned memory _collateralCoverage =
      positionData.rawCollateral.div(
        calculateCollateralAmount(
          positionData.tokensOutstanding,
          priceRate,
          collateralDecimals
        )
      );

    return (_isOverCollateralised, _collateralCoverage.rawValue);
  }

  //Calls to the CreditLine controller
  function capMintAmount(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) external view returns (FixedPoint.Unsigned memory capMint) {
    capMint = positionManagerData._getCapMintAmount();
  }

  function liquidationRewardPercentage(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) external view returns (FixedPoint.Unsigned memory liqRewardPercentage) {
    liqRewardPercentage = positionManagerData._getLiquidationReward();
  }

  function feeInfo(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) external view returns (ICreditLineStorage.Fee memory fee) {
    fee = positionManagerData._getFeeInfo();
  }

  function collateralRequirement(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) external view returns (FixedPoint.Unsigned memory) {
    return positionManagerData._getCollateralRequirement();
  }

  //----------------------------------------
  // Internal functions
  //----------------------------------------
  function _burnLiquidatedTokens(
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    address liquidator,
    uint256 amount
  ) internal {
    positionManagerData.tokenCurrency.safeTransferFrom(
      liquidator,
      address(this),
      amount
    );
    positionManagerData.tokenCurrency.burn(amount);
  }

  function _incrementCollateralBalances(
    ICreditLineStorage.PositionData storage positionData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    FixedPoint.Unsigned memory collateralAmount
  ) internal {
    positionData.rawCollateral = positionData.rawCollateral.add(
      collateralAmount
    );
    globalPositionData.rawTotalPositionCollateral = globalPositionData
      .rawTotalPositionCollateral
      .add(collateralAmount);
  }

  function _decrementCollateralBalances(
    ICreditLineStorage.PositionData storage positionData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    FixedPoint.Unsigned memory collateralAmount
  ) internal {
    positionData.rawCollateral = positionData.rawCollateral.sub(
      collateralAmount
    );
    globalPositionData.rawTotalPositionCollateral = globalPositionData
      .rawTotalPositionCollateral
      .sub(collateralAmount);
  }

  //remove the withdrawn collateral from the position and then check its CR
  function _decrementCollateralBalancesCheckCR(
    ICreditLineStorage.PositionData storage positionData,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    FixedPoint.Unsigned memory collateralAmount
  ) internal {
    FixedPoint.Unsigned memory newRawCollateral =
      positionData.rawCollateral.sub(collateralAmount);

    positionData.rawCollateral = newRawCollateral;

    globalPositionData.rawTotalPositionCollateral = globalPositionData
      .rawTotalPositionCollateral
      .sub(collateralAmount);

    require(
      _checkCollateralization(
        positionManagerData,
        newRawCollateral,
        positionData.tokensOutstanding,
        _getOraclePrice(positionManagerData),
        getCollateralDecimals(positionManagerData.collateralToken)
      ),
      'CR is not sufficiently high after the withdraw - try less amount'
    );
  }

  // Deletes a sponsor's position and updates global counters. Does not make any external transfers.
  function _deleteSponsorPosition(
    ICreditLineStorage.PositionData storage positionToLiquidate,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    address sponsor
  ) internal returns (FixedPoint.Unsigned memory) {
    // Remove the collateral and outstanding from the overall total position.
    globalPositionData.rawTotalPositionCollateral = globalPositionData
      .rawTotalPositionCollateral
      .sub(positionToLiquidate.rawCollateral);
    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(positionToLiquidate.tokensOutstanding);

    // delete position entry from storage
    CreditLine(address(this)).deleteSponsorPosition(sponsor);

    emit EndedSponsorPosition(sponsor);

    // Return unlocked amount of collateral
    return positionToLiquidate.rawCollateral;
  }

  function _reducePosition(
    ICreditLineStorage.PositionData storage positionToLiquidate,
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    FixedPoint.Unsigned memory tokensToLiquidate,
    FixedPoint.Unsigned memory collateralToLiquidate
  ) internal {
    // reduce position
    positionToLiquidate.tokensOutstanding = positionToLiquidate
      .tokensOutstanding
      .sub(tokensToLiquidate);
    positionToLiquidate.rawCollateral = positionToLiquidate.rawCollateral.sub(
      collateralToLiquidate
    );

    // update global position data
    globalPositionData.totalTokensOutstanding = globalPositionData
      .totalTokensOutstanding
      .sub(tokensToLiquidate);
    globalPositionData.rawTotalPositionCollateral = globalPositionData
      .rawTotalPositionCollateral
      .sub(collateralToLiquidate);
  }

  function _checkCollateralization(
    ICreditLineStorage.PositionManagerData storage positionManagerData,
    FixedPoint.Unsigned memory collateral,
    FixedPoint.Unsigned memory numTokens,
    FixedPoint.Unsigned memory oraclePrice,
    uint256 collateralDecimals
  ) internal view returns (bool) {
    // calculate the min collateral of numTokens with chainlink
    FixedPoint.Unsigned memory thresholdValue =
      numTokens.mul(oraclePrice).div(10**(18 - collateralDecimals));

    thresholdValue = thresholdValue.mul(
      positionManagerData._getCollateralRequirement()
    );

    return collateral.isGreaterThanOrEqual(thresholdValue);
  }

  // Check new total number of tokens does not overcome mint limit
  function checkMintLimit(
    ICreditLineStorage.GlobalPositionData storage globalPositionData,
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) internal view {
    require(
      globalPositionData.totalTokensOutstanding.isLessThanOrEqual(
        positionManagerData._getCapMintAmount()
      ),
      'Total amount minted overcomes mint limit'
    );
  }

  /**
   * @notice Retrun the on-chain oracle price for a pair
   * @return priceRate Latest rate of the pair
   */
  function _getOraclePrice(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) internal view returns (FixedPoint.Unsigned memory priceRate) {
    ISynthereumPriceFeed priceFeed =
      ISynthereumPriceFeed(
        positionManagerData.synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.PriceFeed
        )
      );
    priceRate = FixedPoint.Unsigned(
      priceFeed.getLatestPrice(positionManagerData.priceIdentifier)
    );
  }

  /// @notice calls CreditLineController to retrieve liquidation reward percentage
  function _getLiquidationReward(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) internal view returns (FixedPoint.Unsigned memory liqRewardPercentage) {
    liqRewardPercentage = FixedPoint.Unsigned(
      positionManagerData
        .getCreditLineController()
        .getLiquidationRewardPercentage(address(this))
    );
  }

  function _getFeeInfo(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) internal view returns (ICreditLineStorage.Fee memory fee) {
    fee = positionManagerData.getCreditLineController().getFeeInfo(
      address(this)
    );
  }

  function _getCollateralRequirement(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) internal view returns (FixedPoint.Unsigned memory) {
    return
      FixedPoint.Unsigned(
        positionManagerData.getCreditLineController().getCollateralRequirement(
          address(this)
        )
      );
  }

  // Get mint amount limit from CreditLineController
  function _getCapMintAmount(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) internal view returns (FixedPoint.Unsigned memory capMint) {
    capMint = FixedPoint.Unsigned(
      positionManagerData.getCreditLineController().getCapMintAmount(
        address(this)
      )
    );
  }

  // Get self-minting controller instance
  function getCreditLineController(
    ICreditLineStorage.PositionManagerData storage positionManagerData
  ) internal view returns (ICreditLineController creditLineController) {
    creditLineController = ICreditLineController(
      positionManagerData.synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.CreditLineController
      )
    );
  }

  function getCollateralDecimals(IStandardERC20 collateralToken)
    internal
    view
    returns (uint256 decimals)
  {
    decimals = collateralToken.decimals();
  }

  /**
   * @notice Calculate collateral amount starting from an amount of synthtic token
   * @param numTokens Amount of synthetic tokens from which you want to calculate collateral amount
   * @param priceRate On-chain price rate
   * @return collateralAmount Amount of collateral after on-chain oracle conversion
   */
  function calculateCollateralAmount(
    FixedPoint.Unsigned memory numTokens,
    FixedPoint.Unsigned memory priceRate,
    uint256 collateraDecimals
  ) internal view returns (FixedPoint.Unsigned memory collateralAmount) {
    collateralAmount = numTokens.mul(priceRate).div(
      10**(18 - collateraDecimals)
    );
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

    constructor() {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../../../../../@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../../../@openzeppelin/contracts/utils/math/SignedSafeMath.sol";

/**
 * @title Library for fixed point arithmetic on uints
 */
library FixedPoint {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
    uint256 private constant FP_SCALING_FACTOR = 10**18;

    // --------------------------------------- UNSIGNED -----------------------------------------------------------------------------
    struct Unsigned {
        uint256 rawValue;
    }

    /**
     * @notice Constructs an `Unsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a uint to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledUint(uint256 a) internal pure returns (Unsigned memory) {
        return Unsigned(a.mul(FP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the minimum of `a` and `b`.
     */
    function min(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the maximum of `a` and `b`.
     */
    function max(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Unsigned` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled uint256 from an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from an unscaled uint256, reverting on overflow.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return sub(fromUnscaledUint(a), b);
    }

    /**
     * @notice Multiplies two `Unsigned`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as a uint256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because FP_SCALING_FACTOR != 0.
        return Unsigned(a.rawValue.mul(b.rawValue) / FP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Unsigned`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 mulRaw = a.rawValue.mul(b.rawValue);
        uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
        uint256 mod = mulRaw.mod(FP_SCALING_FACTOR);
        if (mod != 0) {
            return Unsigned(mulFloor.add(1));
        } else {
            return Unsigned(mulFloor);
        }
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as a uint256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Unsigned(a.rawValue.mul(FP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled uint256 by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a uint256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return div(fromUnscaledUint(a), b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 aScaled = a.rawValue.mul(FP_SCALING_FACTOR);
        uint256 divFloor = aScaled.div(b.rawValue);
        uint256 mod = aScaled.mod(b.rawValue);
        if (mod != 0) {
            return Unsigned(divFloor.add(1));
        } else {
            return Unsigned(divFloor);
        }
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Unsigned(a.rawValue.div(b))"
        // similarly to mulCeil with a uint256 as the second parameter. Therefore we need to convert b into an Unsigned.
        // This creates the possibility of overflow if b is very large.
        return divCeil(a, fromUnscaledUint(b));
    }

    /**
     * @notice Raises an `Unsigned` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return output is `a` to the power of `b`.
     */
    function pow(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory output) {
        output = fromUnscaledUint(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }

    // ------------------------------------------------- SIGNED -------------------------------------------------------------
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
    int256 private constant SFP_SCALING_FACTOR = 10**18;

    struct Signed {
        int256 rawValue;
    }

    function fromSigned(Signed memory a) internal pure returns (Unsigned memory) {
        require(a.rawValue >= 0, "Negative value provided");
        return Unsigned(uint256(a.rawValue));
    }

    function fromUnsigned(Unsigned memory a) internal pure returns (Signed memory) {
        require(a.rawValue <= uint256(type(int256).max), "Unsigned too large");
        return Signed(int256(a.rawValue));
    }

    /**
     * @notice Constructs a `Signed` from an unscaled int, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a int to convert into a FixedPoint.Signed.
     * @return the converted FixedPoint.Signed.
     */
    function fromUnscaledInt(int256 a) internal pure returns (Signed memory) {
        return Signed(a.mul(SFP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a int256.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the minimum of `a` and `b`.
     */
    function min(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the maximum of `a` and `b`.
     */
    function max(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Signed` to an unscaled int, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return add(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled int256 from an `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return sub(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts an `Signed` from an unscaled int256, reverting on overflow.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return sub(fromUnscaledInt(a), b);
    }

    /**
     * @notice Multiplies two `Signed`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as an int256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because SFP_SCALING_FACTOR != 0.
        return Signed(a.rawValue.mul(b.rawValue) / SFP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Signed`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 mulRaw = a.rawValue.mul(b.rawValue);
        int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = mulRaw % SFP_SCALING_FACTOR;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(mulTowardsZero.add(valueToAdd));
        } else {
            return Signed(mulTowardsZero);
        }
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Signed` by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as an int256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Signed(a.rawValue.mul(SFP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled int256 by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a an int256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return div(fromUnscaledInt(a), b);
    }

    /**
     * @notice Divides one `Signed` by an `Signed` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 aScaled = a.rawValue.mul(SFP_SCALING_FACTOR);
        int256 divTowardsZero = aScaled.div(b.rawValue);
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = aScaled % b.rawValue;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(divTowardsZero.add(valueToAdd));
        } else {
            return Signed(divTowardsZero);
        }
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Signed(a.rawValue.div(b))"
        // similarly to mulCeil with an int256 as the second parameter. Therefore we need to convert b into an Signed.
        // This creates the possibility of overflow if b is very large.
        return divAwayFromZero(a, fromUnscaledInt(b));
    }

    /**
     * @notice Raises an `Signed` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint.Signed.
     * @param b a uint256 (negative exponents are not allowed).
     * @return output is `a` to the power of `b`.
     */
    function pow(Signed memory a, uint256 b) internal pure returns (Signed memory output) {
        output = fromUnscaledInt(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';

/**
 * @title Interface that a pool MUST have in order to be included in the deployer
 */
interface ISynthereumDeployment {
  /**
   * @notice Get Synthereum finder of the pool/self-minting derivative
   * @return finder Returns finder contract
   */
  function synthereumFinder() external view returns (ISynthereumFinder finder);

  /**
   * @notice Get Synthereum version
   * @return poolVersion Returns the version of this pool/self-minting derivative
   */
  function version() external view returns (uint8 poolVersion);

  /**
   * @notice Get the collateral token of this pool/self-minting derivative
   * @return collateralCurrency The ERC20 collateral token
   */
  function collateralToken() external view returns (IERC20 collateralCurrency);

  /**
   * @notice Get the synthetic token associated to this pool/self-minting derivative
   * @return syntheticCurrency The ERC20 synthetic token
   */
  function syntheticToken() external view returns (IERC20 syntheticCurrency);

  /**
   * @notice Get the synthetic token symbol associated to this pool/self-minting derivative
   * @return symbol The ERC20 synthetic token symbol
   */
  function syntheticTokenSymbol() external view returns (string memory symbol);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

interface IEmergencyShutdown {
  /**
   * @notice Shutdown the pool or self-minting-derivative in case of emergency
   * @notice Only Synthereum manager contract can call this function
   * @return timestamp Timestamp of emergency shutdown transaction
   * @return price Price of the pair at the moment of shutdown execution
   */
  function emergencyShutdown()
    external
    returns (uint256 timestamp, uint256 price);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

interface ITypology {
  /**
   * @notice Return typology of the contract
   */
  function typology() external view returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import {IERC20} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ICreditLineStorage} from './ICreditLineStorage.sol';
import {
  FixedPoint
} from '../../../../@uma/core/contracts/common/implementation/FixedPoint.sol';

/** @title Interface for interacting with the SelfMintingController
 */
interface ICreditLineController {
  /**
   * @notice Allow to set collateralRequirement percentage on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param collateralRequirements Over collateralization percentage for self-minting derivatives
   */
  function setCollateralRequirement(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata collateralRequirements
  ) external;

  /**
   * @notice Allow to set capMintAmount on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param capMintAmounts Mint cap amounts for self-minting derivatives
   */
  function setCapMintAmount(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata capMintAmounts
  ) external;

  /**
   * @notice Allow to set fee percentages on a list of registered self-minting derivatives
   * @param selfMintingDerivatives Self-minting derivatives
   * @param feePercentages fee percentages for self-minting derivatives
   */
  function setFeePercentage(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata feePercentages
  ) external;

  /**
   * @notice Update the addresses and weight of recipients for generated fees
   * @param selfMintingDerivatives Derivatives to update
   * @param feeRecipients A two-dimension array containing for each derivative the addresses of fee recipients
   * @param feeProportions An array of the proportions of fees generated each recipient will receive
   */
  function setFeeRecipients(
    address[] calldata selfMintingDerivatives,
    address[][] calldata feeRecipients,
    uint32[][] calldata feeProportions
  ) external;

  /**
   * @notice Update the liquidation reward percentage
   * @param selfMintingDerivatives Derivatives to update
   * @param _liquidationRewards Percentage of reward for correct liquidation by a liquidator
   */
  function setLiquidationRewardPercentage(
    address[] calldata selfMintingDerivatives,
    uint256[] calldata _liquidationRewards
  ) external;

  /**
   * @notice Gets the over collateralization percentage of a self-minting derivative
   * @param selfMintingDerivative Derivative to read value of
   * @return the collateralRequirement percentage
   */
  function getCollateralRequirement(address selfMintingDerivative)
    external
    view
    returns (uint256);

  /**
   * @notice Gets the set liquidtion reward percentage of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return liquidation Reward percentage
   */
  function getLiquidationRewardPercentage(address selfMintingDerivative)
    external
    view
    returns (uint256);

  /**
   * @notice Gets the set CapMintAmount of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return capMintAmount Limit amount for minting
   */
  function getCapMintAmount(address selfMintingDerivative)
    external
    view
    returns (uint256 capMintAmount);

  /**
   * @notice Gets the fee params of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return fee fee info (percent + recipient + proportions)
   */
  function getFeeInfo(address selfMintingDerivative)
    external
    view
    returns (ICreditLineStorage.Fee memory fee);

  /**
   * @notice Gets the fee percentage of a self-minting derivative
   * @param selfMintingDerivative Self-minting derivative
   * @return feePercentage value
   */
  function feePercentage(address selfMintingDerivative)
    external
    view
    returns (uint256);

  /**
   * @notice Returns fee recipients info
   * @return Addresses, weigths and total of weigtht
   */
  function feeRecipientsInfo(address selfMintingDerivative)
    external
    view
    returns (
      address[] memory,
      uint32[] memory,
      uint256
    );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

interface ISynthereumPriceFeed {
  /**
   * @notice Get last chainlink oracle price for a given price identifier
   * @param priceIdentifier Price feed identifier
   * @return price Oracle price
   */
  function getLatestPrice(bytes32 priceIdentifier)
    external
    view
    returns (uint256 price);

  /**
   * @notice Return if price identifier is supported
   * @param priceIdentifier Price feed identifier
   * @return isSupported True if price is supported otherwise false
   */
  function isPriceSupported(bytes32 priceIdentifier)
    external
    view
    returns (bool isSupported);
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  IDeploymentSignature
} from '../../core/interfaces/IDeploymentSignature.sol';
import {
  ISynthereumCollateralWhitelist
} from '../../core/interfaces/ICollateralWhitelist.sol';
import {
  ISynthereumIdentifierWhitelist
} from '../../core/interfaces/IIdentifierWhitelist.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {CreditLineCreator} from './CreditLineCreator.sol';
import {CreditLine} from './CreditLine.sol';
import {FactoryConditions} from '../../common/FactoryConditions.sol';
import {
  ReentrancyGuard
} from '../../../@openzeppelin/contracts/security/ReentrancyGuard.sol';

/** @title Contract factory of self-minting derivatives
 */
contract CreditLineFactory is
  IDeploymentSignature,
  ReentrancyGuard,
  FactoryConditions,
  CreditLineCreator
{
  //----------------------------------------
  // Storage
  //----------------------------------------

  bytes4 public immutable override deploymentSignature;

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs the CreditLineFactory contract
   * @param _synthereumFinder Synthereum Finder address used to discover other contracts
   */
  constructor(address _synthereumFinder) CreditLineCreator(_synthereumFinder) {
    deploymentSignature = this.createSelfMintingDerivative.selector;
  }

  /**
   * @notice Check if the sender is the deployer and deploy a new creditLine contract
   * @param params is a `ConstructorParams` object from creditLine.
   * @return creditLine address of the deployed contract.
   */
  function createSelfMintingDerivative(Params calldata params)
    public
    override
    nonReentrant
    returns (CreditLine creditLine)
  {
    checkDeploymentConditions(
      synthereumFinder,
      params.collateralToken,
      params.priceFeedIdentifier
    );
    creditLine = super.createSelfMintingDerivative(params);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

/**
 * @title Provides signature of function for deployment
 */
interface IDeploymentSignature {
  /**
   * @notice Returns the bytes4 signature of the function used for the deployment of a contract in a factory
   * @return signature returns signature of the deployment function
   */
  function deploymentSignature() external view returns (bytes4 signature);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title An interface to track a whitelist of addresses.
 */
interface ISynthereumCollateralWhitelist {
  /**
   * @notice Adds an address to the whitelist.
   * @param newCollateral the new address to add.
   */
  function addToWhitelist(address newCollateral) external;

  /**
   * @notice Removes an address from the whitelist.
   * @param collateralToRemove The existing address to remove.
   */
  function removeFromWhitelist(address collateralToRemove) external;

  /**
   * @notice Checks whether an address is on the whitelist.
   * @param collateralToCheck The address to check.
   * @return True if `collateralToCheck` is on the whitelist, or False.
   */
  function isOnWhitelist(address collateralToCheck)
    external
    view
    returns (bool);

  /**
   * @notice Gets all addresses that are currently included in the whitelist.
   * @return The list of addresses on the whitelist.
   */
  function getWhitelist() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title An interface to track a whitelist of identifiers.
 */
interface ISynthereumIdentifierWhitelist {
  /**
   * @notice Adds an identifier to the whitelist.
   * @param newIdentifier the new identifier to add.
   */
  function addToWhitelist(bytes32 newIdentifier) external;

  /**
   * @notice Removes an identifier from the whitelist.
   * @param identifierToRemove The existing identifier to remove.
   */
  function removeFromWhitelist(bytes32 identifierToRemove) external;

  /**
   * @notice Checks whether an address is on the whitelist.
   * @param identifierToCheck The address to check.
   * @return True if `identifierToCheck` is on the whitelist, or False.
   */
  function isOnWhitelist(bytes32 identifierToCheck)
    external
    view
    returns (bool);

  /**
   * @notice Gets all identifiers that are currently included in the whitelist.
   * @return The list of identifiers on the whitelist.
   */
  function getWhitelist() external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {ICreditLineController} from './interfaces/ICreditLineController.sol';
import {ICreditLineStorage} from './interfaces/ICreditLineStorage.sol';
import {
  IMintableBurnableERC20
} from '../../tokens/interfaces/IMintableBurnableERC20.sol';
import {
  BaseControlledMintableBurnableERC20
} from '../../tokens/interfaces/BaseControlledMintableBurnableERC20.sol';
import {CreditLineLib} from './CreditLineLib.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {
  FixedPoint
} from '../../../@uma/core/contracts/common/implementation/FixedPoint.sol';
import {CreditLine} from './CreditLine.sol';

/**
 * @title Self-Minting Contract creator.
 * @notice Factory contract to create new self-minting derivative
 */
contract CreditLineCreator {
  using FixedPoint for FixedPoint.Unsigned;

  struct Params {
    IStandardERC20 collateralToken;
    bytes32 priceFeedIdentifier;
    string syntheticName;
    string syntheticSymbol;
    address syntheticToken;
    ICreditLineStorage.Fee fee;
    uint256 liquidationPercentage;
    uint256 capMintAmount;
    uint256 collateralRequirement;
    FixedPoint.Unsigned minSponsorTokens;
    address excessTokenBeneficiary;
    uint8 version;
  }

  // Address of Synthereum Finder
  ISynthereumFinder public immutable synthereumFinder;

  //----------------------------------------
  // Events
  //----------------------------------------
  event CreatedSelfMintingDerivative(
    address indexed selfMintingAddress,
    uint8 indexed version,
    address indexed deployerAddress
  );

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs the Perpetual contract.
   * @param _synthereumFinder Synthereum Finder address used to discover other contracts
   */
  constructor(address _synthereumFinder) {
    synthereumFinder = ISynthereumFinder(_synthereumFinder);
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  /**
   * @notice Creates an instance of creditLine
   * @param params is a `ConstructorParams` object from creditLine.
   * @return creditLine address of the deployed contract.
   */
  function createSelfMintingDerivative(Params calldata params)
    public
    virtual
    returns (CreditLine creditLine)
  {
    // Create a new synthetic token using the params.
    require(bytes(params.syntheticName).length != 0, 'Missing synthetic name');
    require(
      bytes(params.syntheticSymbol).length != 0,
      'Missing synthetic symbol'
    );
    require(
      params.syntheticToken != address(0),
      'Synthetic token address cannot be 0x00'
    );

    BaseControlledMintableBurnableERC20 tokenCurrency =
      BaseControlledMintableBurnableERC20(params.syntheticToken);
    require(
      keccak256(abi.encodePacked(tokenCurrency.name())) ==
        keccak256(abi.encodePacked(params.syntheticName)),
      'Wrong synthetic token name'
    );
    require(
      keccak256(abi.encodePacked(tokenCurrency.symbol())) ==
        keccak256(abi.encodePacked(params.syntheticSymbol)),
      'Wrong synthetic token symbol'
    );

    creditLine = new CreditLine(_convertParams(params));

    _setControllerValues(
      address(creditLine),
      params.fee,
      params.liquidationPercentage,
      params.capMintAmount,
      params.collateralRequirement
    );

    emit CreatedSelfMintingDerivative(
      address(creditLine),
      params.version,
      msg.sender
    );
  }

  //----------------------------------------
  // Internal functions
  //----------------------------------------

  // Converts createPerpetual params to constructor params.
  function _convertParams(Params calldata params)
    internal
    view
    returns (CreditLine.PositionManagerParams memory constructorParams)
  {
    constructorParams.synthereumFinder = synthereumFinder;

    require(
      params.excessTokenBeneficiary != address(0),
      'Token Beneficiary cannot be 0x00'
    );

    constructorParams.syntheticToken = IMintableBurnableERC20(
      address(params.syntheticToken)
    );
    constructorParams.collateralToken = params.collateralToken;
    constructorParams.priceFeedIdentifier = params.priceFeedIdentifier;
    constructorParams.minSponsorTokens = params.minSponsorTokens;
    constructorParams.excessTokenBeneficiary = params.excessTokenBeneficiary;
    constructorParams.version = params.version;
  }

  /** @notice Sets the controller values for a self-minting derivative
   * @param derivative Address of the derivative to set controller values
   * @param feeStruct The fee config params
   * @param capMintAmount Cap on mint amount. How much synthetic tokens can be minted through a self-minting derivative.
   * This value is updatable
   */
  function _setControllerValues(
    address derivative,
    ICreditLineStorage.Fee memory feeStruct,
    uint256 liquidationRewardPercentage,
    uint256 capMintAmount,
    uint256 collateralRequirement
  ) internal {
    ICreditLineController creditLineController =
      ICreditLineController(
        synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.CreditLineController
        )
      );

    // prepare function calls args
    address[] memory derivatives = new address[](1);
    derivatives[0] = derivative;

    uint256[] memory capMintAmounts = new uint256[](1);
    capMintAmounts[0] = capMintAmount;

    uint256[] memory collateralRequirements = new uint256[](1);
    collateralRequirements[0] = collateralRequirement;

    uint256[] memory feePercentages = new uint256[](1);
    feePercentages[0] = feeStruct.feePercentage;

    uint256[] memory liqPercentages = new uint256[](1);
    liqPercentages[0] = liquidationRewardPercentage;

    address[][] memory feeRecipients = new address[][](1);
    feeRecipients[0] = feeStruct.feeRecipients;

    uint32[][] memory feeProportions = new uint32[][](1);
    feeProportions[0] = feeStruct.feeProportions;

    // set the derivative over collateralization percentage
    creditLineController.setCollateralRequirement(
      derivatives,
      collateralRequirements
    );

    // set the derivative fee configuration
    creditLineController.setFeePercentage(derivatives, feePercentages);
    creditLineController.setFeeRecipients(
      derivatives,
      feeRecipients,
      feeProportions
    );

    // set the derivative cap mint amount
    creditLineController.setCapMintAmount(derivatives, capMintAmounts);

    // set the derivative liquidation reward percentage
    creditLineController.setLiquidationRewardPercentage(
      derivatives,
      liqPercentages
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import {IStandardERC20} from '../base/interfaces/IStandardERC20.sol';
import {ISynthereumFinder} from '../core/interfaces/IFinder.sol';
import {
  ISynthereumCollateralWhitelist
} from '../core/interfaces/ICollateralWhitelist.sol';
import {
  ISynthereumIdentifierWhitelist
} from '../core/interfaces/IIdentifierWhitelist.sol';
import {SynthereumInterfaces} from '../core/Constants.sol';

/** @title Contract factory of self-minting derivatives
 */
contract FactoryConditions {
  /**
   * @notice Check if the sender is the deployer and if identifier and collateral are supported
   * @param synthereumFinder Synthereum finder
   * @param collateralToken Collateral token to check if it's in the whithelist
   * @param priceFeedIdentifier Identifier to check if it's in the whithelist
   */
  function checkDeploymentConditions(
    ISynthereumFinder synthereumFinder,
    IStandardERC20 collateralToken,
    bytes32 priceFeedIdentifier
  ) internal view {
    address deployer =
      synthereumFinder.getImplementationAddress(SynthereumInterfaces.Deployer);
    require(msg.sender == deployer, 'Sender must be Synthereum deployer');
    ISynthereumCollateralWhitelist collateralWhitelist =
      ISynthereumCollateralWhitelist(
        synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.CollateralWhitelist
        )
      );
    require(
      collateralWhitelist.isOnWhitelist(address(collateralToken)),
      'Collateral not supported'
    );
    ISynthereumIdentifierWhitelist identifierWhitelist =
      ISynthereumIdentifierWhitelist(
        synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.IdentifierWhitelist
        )
      );
    require(
      identifierWhitelist.isOnWhitelist(priceFeedIdentifier),
      'Identifier not supported'
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import {ERC20} from '../../../@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IMintableBurnableERC20} from './IMintableBurnableERC20.sol';

/**
 * @title ERC20 interface that includes burn mint and roles methods.
 */
abstract contract BaseControlledMintableBurnableERC20 is
  ERC20,
  IMintableBurnableERC20
{
  uint8 private _decimals;

  /**
   * @notice Constructs the ERC20 token contract
   * @param _tokenName Name of the token
   * @param _tokenSymbol Token symbol
   * @param _tokenDecimals Number of decimals for token
   */
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint8 _tokenDecimals
  ) ERC20(_tokenName, _tokenSymbol) {
    _setupDecimals(_tokenDecimals);
  }

  /**
   * @notice Add Minter role to an account
   * @param account Address to which Minter role will be added
   */
  function addMinter(address account) external virtual;

  /**
   * @notice Add Burner role to an account
   * @param account Address to which Burner role will be added
   */
  function addBurner(address account) external virtual;

  /**
   * @notice Add Admin role to an account
   * @param account Address to which Admin role will be added
   */
  function addAdmin(address account) external virtual;

  /**
   * @notice Add Admin, Minter and Burner roles to an account
   * @param account Address to which Admin, Minter and Burner roles will be added
   */
  function addAdminAndMinterAndBurner(address account) external virtual;

  /**
   * @notice Add Admin, Minter and Burner roles to an account
   * @param account Address to which Admin, Minter and Burner roles will be added
   */
  /**
   * @notice Self renounce the address calling the function from minter role
   */
  function renounceMinter() external virtual;

  /**
   * @notice Self renounce the address calling the function from burner role
   */
  function renounceBurner() external virtual;

  /**
   * @notice Self renounce the address calling the function from admin role
   */
  function renounceAdmin() external virtual;

  /**
   * @notice Self renounce the address calling the function from admin, minter and burner role
   */
  function renounceAdminAndMinterAndBurner() external virtual;

  /**
   * @notice Returns the number of decimals used to get its user representation.
   */
  function decimals()
    public
    view
    virtual
    override(ERC20, IMintableBurnableERC20)
    returns (uint8)
  {
    return _decimals;
  }

  /**
   * @dev Sets {decimals} to a value other than the default one of 18.
   *
   * WARNING: This function should only be called from the constructor. Most
   * applications that interact with token contracts will not expect
   * {decimals} to ever change, and may work incorrectly if it does.
   */
  function _setupDecimals(uint8 decimals_) internal {
    _decimals = decimals_;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function renounceRole(bytes32 role, address account) public virtual override {
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
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
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import {ISynthereumFinder} from './interfaces/IFinder.sol';
import {
  AccessControlEnumerable
} from '../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 * @title Provides addresses of contracts implementing certain interfaces.
 */
contract SynthereumFinder is ISynthereumFinder, AccessControlEnumerable {
  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------

  mapping(bytes32 => address) public interfacesImplemented;

  //----------------------------------------
  // Events
  //----------------------------------------

  event InterfaceImplementationChanged(
    bytes32 indexed interfaceName,
    address indexed newImplementationAddress
  );

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  //----------------------------------------
  // Constructors
  //----------------------------------------

  constructor(Roles memory roles) {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, roles.admin);
    _setupRole(MAINTAINER_ROLE, roles.maintainer);
  }

  //----------------------------------------
  // External view
  //----------------------------------------

  /**
   * @notice Updates the address of the contract that implements `interfaceName`.
   * @param interfaceName bytes32 of the interface name that is either changed or registered.
   * @param implementationAddress address of the implementation contract.
   */
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external override onlyMaintainer {
    interfacesImplemented[interfaceName] = implementationAddress;

    emit InterfaceImplementationChanged(interfaceName, implementationAddress);
  }

  /**
   * @notice Gets the address of the contract that implements the given `interfaceName`.
   * @param interfaceName queried interface.
   * @return implementationAddress Address of the defined interface.
   */
  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    override
    returns (address)
  {
    address implementationAddress = interfacesImplemented[interfaceName];
    require(implementationAddress != address(0x0), 'Implementation not found');
    return implementationAddress;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

import {
  ISynthereumFactoryVersioning
} from './interfaces/IFactoryVersioning.sol';
import {
  EnumerableMap
} from '../../@openzeppelin/contracts/utils/structs/EnumerableMap.sol';
import {
  AccessControlEnumerable
} from '../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 * @title Provides addresses of different versions of pools factory and derivative factory
 */
contract SynthereumFactoryVersioning is
  ISynthereumFactoryVersioning,
  AccessControlEnumerable
{
  using EnumerableMap for EnumerableMap.UintToAddressMap;

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------

  mapping(bytes32 => EnumerableMap.UintToAddressMap) private factories;

  //----------------------------------------
  // Events
  //----------------------------------------

  event AddFactory(
    bytes32 indexed factoryType,
    uint8 indexed version,
    address indexed factory
  );

  event SetFactory(
    bytes32 indexed factoryType,
    uint8 indexed version,
    address indexed factory
  );

  event RemoveFactory(
    bytes32 indexed factoryType,
    uint8 indexed version,
    address indexed factory
  );

  //----------------------------------------
  // Constructor
  //----------------------------------------
  constructor(Roles memory roles) {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, roles.admin);
    _setupRole(MAINTAINER_ROLE, roles.maintainer);
  }

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  /** @notice Sets a Factory
   * @param factoryType Type of factory
   * @param version Version of the factory to be set
   * @param factory The pool factory address to be set
   */
  function setFactory(
    bytes32 factoryType,
    uint8 version,
    address factory
  ) external override onlyMaintainer {
    require(factory != address(0), 'Factory cannot be address 0');
    bool isNewVersion = factories[factoryType].set(version, factory);
    if (isNewVersion == true) {
      emit AddFactory(factoryType, version, factory);
    } else {
      emit SetFactory(factoryType, version, factory);
    }
  }

  /** @notice Removes a factory
   * @param factoryType The type of factory to be removed
   * @param version Version of the factory to be removed
   */
  function removeFactory(bytes32 factoryType, uint8 version)
    external
    override
    onlyMaintainer
  {
    EnumerableMap.UintToAddressMap storage selectedFactories =
      factories[factoryType];
    address factoryToRemove = selectedFactories.get(version);
    selectedFactories.remove(version);
    emit RemoveFactory(factoryType, version, factoryToRemove);
  }

  //----------------------------------------
  // External view functions
  //----------------------------------------

  /** @notice Gets a factory contract address
   * @param factoryType The type of factory to be checked
   * @param version Version of the factory to be checked
   * @return factory Address of the factory contract
   */
  function getFactoryVersion(bytes32 factoryType, uint8 version)
    external
    view
    override
    returns (address factory)
  {
    factory = factories[factoryType].get(version);
  }

  /** @notice Gets the number of factory versions for a specific type
   * @param factoryType The type of factory to be checked
   * @return numberOfVersions Total number of versions for a specific factory
   */
  function numberOfVerisonsOfFactory(bytes32 factoryType)
    external
    view
    override
    returns (uint256 numberOfVersions)
  {
    numberOfVersions = factories[factoryType].length();
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

/**
 * @title Provides addresses of different versions of pools factory and derivative factory
 */
interface ISynthereumFactoryVersioning {
  /** @notice Sets a Factory
   * @param factoryType Type of factory
   * @param version Version of the factory to be set
   * @param factory The pool factory address to be set
   */
  function setFactory(
    bytes32 factoryType,
    uint8 version,
    address factory
  ) external;

  /** @notice Removes a factory
   * @param factoryType The type of factory to be removed
   * @param version Version of the factory to be removed
   */
  function removeFactory(bytes32 factoryType, uint8 version) external;

  /** @notice Gets a factory contract address
   * @param factoryType The type of factory to be checked
   * @param version Version of the factory to be checked
   * @return factory Address of the factory contract
   */
  function getFactoryVersion(bytes32 factoryType, uint8 version)
    external
    view
    returns (address factory);

  /** @notice Gets the number of factory versions for a specific type
   * @param factoryType The type of factory to be checked
   * @return numberOfVersions Total number of versions for a specific factory
   */
  function numberOfVerisonsOfFactory(bytes32 factoryType)
    external
    view
    returns (uint256 numberOfVersions);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), errorMessage);
        return value;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}