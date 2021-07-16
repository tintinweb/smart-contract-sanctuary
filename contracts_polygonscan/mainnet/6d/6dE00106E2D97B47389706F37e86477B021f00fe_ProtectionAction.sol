// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {FlashLoanReceiverBase} from "../FlashLoanReceiverBase.sol";
import {
    ILendingPoolAddressesProvider
} from "../../../interfaces/aave/ILendingPoolAddressesProvider.sol";
import {
    ProtectionPayload,
    FlashLoanData,
    FlashLoanParamsData
} from "../../../structs/SProtection.sol";
import {
    IProtectionAction
} from "../../../interfaces/services/actions/IProtectionAction.sol";
import {
    _getProtectionPayload,
    _flashLoan,
    _isPositionSafe,
    _isPositionUnSafe,
    _paybackToLendingPool,
    _withdrawCollateral,
    _swap,
    _approveERC20Token,
    _transferDust,
    _transferFees
} from "../../../functions/FProtectionAction.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MATIC} from "../../../constants/CTokens.sol";
import {
    DISCREPANCY_BPS_CAP,
    PROTECTION_FEE_BPS_CAP,
    TEN_THOUSAND_BPS
} from "../../../constants/CProtectionAction.sol";

/// @author Gelato Digital
/// @title Protection Action Contract.
/// @dev Perform protection by repaying the debt with collateral token.
contract ProtectionAction is FlashLoanReceiverBase, IProtectionAction, Ownable {
    uint256 public discrepancyBps;
    uint256 public override protectionFeeBps;
    address internal immutable _aaveServices;

    event LogProtectionAction(
        bytes32 taskHash,
        uint256 healthFactorBefore,
        uint256 protectionFee,
        uint256 flashloanFee,
        uint256 colNeededForProtection,
        uint256 debtRepaid,
        address onBehalfOf
    );

    modifier onlyLendingPool() {
        require(
            msg.sender == address(LENDING_POOL),
            "Only Lending Pool can call this function"
        );
        _;
    }

    modifier onlyAaveServices() {
        require(
            msg.sender == _aaveServices,
            "Only Aave Services can call this function"
        );
        _;
    }

    // solhint-disable no-empty-blocks
    constructor(
        ILendingPoolAddressesProvider _addressProvider,
        address __aaveServices
    ) FlashLoanReceiverBase(_addressProvider) {
        _aaveServices = __aaveServices;
        discrepancyBps = 200;
        protectionFeeBps = 10;
    }

    /// @dev Set discrepancy of how far the final HF can be to the one wanted.
    function setDiscrepancyBps(uint256 _discrepancyBps) external onlyOwner {
        require(
            _discrepancyBps <= DISCREPANCY_BPS_CAP,
            "ProtectionAction.setDiscrepancyBps: _discrepancyBps > 5%"
        );
        discrepancyBps = _discrepancyBps;
    }

    ///@dev Set protectionFeeBps, capped to 0.1%
    function setProtectionFeeBps(uint256 _protectionFeeBps) external onlyOwner {
        require(
            _protectionFeeBps <= PROTECTION_FEE_BPS_CAP,
            "ProtectionAction.setProtectionFeeBps: protectionFeeBps > 0.1%"
        );
        protectionFeeBps = _protectionFeeBps;
    }

    /// @dev Safety function for testing.
    function retrieveFunds(address _token, address _to) external onlyOwner {
        if (_token == MATIC) payable(_to).transfer(address(this).balance);
        else
            IERC20(_token).transfer(
                _to,
                IERC20(_token).balanceOf(address(this))
            );
    }

    /// Execution of Protection.
    /// @param _taskHash Task identifier.
    /// @param _data Data needed to perform Protection.
    /// @dev _data is on-chain data, one of the input to produce Task hash of Aave services.
    /// @param _offChainData Data computed off-chain and needed to perform Protection.
    /// @dev _offChainData include the amount of collateral to withdraw
    /// and the amount of debt token to repay, cannot be computed on-chain.
    // solhint-disable function-max-lines
    function exec(
        bytes32 _taskHash,
        bytes memory _data,
        bytes memory _offChainData
    ) external override onlyAaveServices {
        ProtectionPayload memory protectionPayload =
            _getProtectionPayload(_taskHash, _data, _offChainData);

        // Cannot give to executeOperation the path array through params bytes
        // => Stack too Deep error.

        _flashLoan(LENDING_POOL, address(this), protectionPayload);

        // Fetch User Data After Refinancing

        (, , , , , uint256 healthFactor) =
            LENDING_POOL.getUserAccountData(protectionPayload.onBehalfOf);

        // Check if position is safe.

        // // Check if the service didn't keep any dust amt.
        _transferDust(
            address(this),
            protectionPayload.colToken,
            protectionPayload.onBehalfOf
        );
        _transferDust(
            address(this),
            protectionPayload.debtToken,
            protectionPayload.onBehalfOf
        );

        _isPositionSafe(
            healthFactor,
            discrepancyBps,
            protectionPayload.wantedHealthFactor
        );
    }

    /// @dev function called by LendingPool after flash borrow.
    /// @param _assets borrowed tokens.
    /// @param _amounts borrowed amounts associated to borrowed tokens.
    /// @param _premiums premiums to repay.
    /// @param _params custom parameters.
    /// @dev _params contains collateral token, amount of Collateral to
    /// wiithdraw, borrow rate mode, the user who need protection and
    /// swap module used to swap collateral token into debt token.
    function executeOperation(
        address[] calldata _assets,
        uint256[] calldata _amounts,
        uint256[] calldata _premiums,
        address,
        bytes calldata _params
    ) external override onlyLendingPool returns (bool) {
        FlashLoanData memory flashloanData =
            FlashLoanData(_assets, _amounts, _premiums, _params);
        return _executeOperation(flashloanData);
    }

    // solhint-disable function-max-lines
    // repay logic should be here.
    function _executeOperation(FlashLoanData memory _flashloanData)
        internal
        returns (bool)
    {
        FlashLoanParamsData memory paramsData =
            abi.decode(_flashloanData.params, (FlashLoanParamsData));

        /// @notice Check if current health factor is below minimum health factor.
        (, , , , , uint256 healthFactorBefore) =
            LENDING_POOL.getUserAccountData(paramsData.onBehalfOf);
        _isPositionUnSafe(healthFactorBefore, paramsData.minimumHealthFactor);

        /// @notice Payback debt.

        _paybackToLendingPool(
            LENDING_POOL,
            _flashloanData.assets[0],
            _flashloanData.amounts[0],
            paramsData.rateMode,
            paramsData.onBehalfOf
        );

        /// @notice Withdraw collateral (including fees).

        uint256 fees =
            (paramsData.amtOfColToWithdraw * protectionFeeBps) /
                TEN_THOUSAND_BPS;

        _withdrawCollateral(
            LENDING_POOL,
            address(this),
            paramsData.colToken,
            paramsData.amtOfColToWithdraw + fees,
            paramsData.onBehalfOf
        );

        /// @notice Transfer Fees

        _transferFees(paramsData.colToken, fees);

        /// @notice Swap Collateral token to debt token.

        _swap(
            address(this),
            paramsData.swapActions,
            paramsData.swapDatas,
            IERC20(_flashloanData.assets[0]),
            _flashloanData.amounts[0] + _flashloanData.premiums[0]
        );

        /// @notice Approve to retrieve.

        _approveERC20Token(
            _flashloanData.assets[0],
            address(LENDING_POOL),
            _flashloanData.amounts[0] + _flashloanData.premiums[0]
        );

        emit LogProtectionAction(
            paramsData.taskHash,
            healthFactorBefore,
            fees,
            _flashloanData.premiums[0],
            paramsData.amtOfColToWithdraw,
            _flashloanData.amounts[0],
            paramsData.onBehalfOf
        );

        return true;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IFlashLoanReceiver} from "../../interfaces/aave/IFlashLoanReceiver.sol";
import {ILendingPool} from "../../interfaces/aave/ILendingPool.sol";
import {
    ILendingPoolAddressesProvider
} from "../../interfaces/aave/ILendingPoolAddressesProvider.sol";
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // solhint-disable-next-line var-name-mixedcase
    ILendingPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
    // solhint-disable-next-line var-name-mixedcase
    ILendingPool public immutable override LENDING_POOL;

    constructor(ILendingPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
        LENDING_POOL = ILendingPool(provider.getLendingPool());
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol,
 * including permissioned roles
 * - Acting also as factory of proxies and admin of those,
 *   so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
    event MarketIdSet(string newMarketId);
    event LendingPoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolCollateralManagerUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function getMarketId() external view returns (string memory);

    function setMarketId(string calldata marketId) external;

    function setAddress(bytes32 id, address newAddress) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);

    function setLendingPoolImpl(address pool) external;

    function getLendingPoolConfigurator() external view returns (address);

    function setLendingPoolConfiguratorImpl(address configurator) external;

    function getLendingPoolCollateralManager() external view returns (address);

    function setLendingPoolCollateralManager(address manager) external;

    function getPoolAdmin() external view returns (address);

    function setPoolAdmin(address admin) external;

    function getEmergencyAdmin() external view returns (address);

    function setEmergencyAdmin(address admin) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getLendingRateOracle() external view returns (address);

    function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Path} from "../structs/SParaswap.sol";

struct ProtectionPayload {
    bytes32 taskHash;
    address colToken;
    address debtToken;
    uint256 rateMode;
    uint256 amtToFlashBorrow;
    uint256 amtOfColToWithdraw;
    uint256 minimumHealthFactor;
    uint256 wantedHealthFactor;
    address onBehalfOf;
    address[] swapActions;
    bytes[] swapDatas;
}

struct ExecutionData {
    address user;
    address action;
    uint256 subBlockNumber;
    bytes data;
    bytes offChainData;
    bool isPermanent;
}

struct ProtectionDataCompute {
    address colToken;
    address debtToken;
    uint256 totalCollateralETH;
    uint256 totalBorrowsETH;
    uint256 currentLiquidationThreshold;
    uint256 colLiquidationThreshold;
    uint256 wantedHealthFactor;
    uint256 colPrice;
    uint256 debtPrice;
    uint256 colInETH;
    uint256 debtInETH;
    address onBehalfOf;
    uint256 protectionActionFee;
    uint256 flashloanPremium;
}

struct FlashLoanData {
    address[] assets;
    uint256[] amounts;
    uint256[] premiums;
    bytes params;
}

struct FlashLoanParamsData {
    uint256 minimumHealthFactor;
    bytes32 taskHash;
    address colToken;
    uint256 amtOfColToWithdraw;
    uint256 rateMode;
    address onBehalfOf;
    address[] swapActions;
    bytes[] swapDatas;
}

struct RepayAndWithdrawData {
    bytes32 id;
    address user;
    address colToken;
    address debtToken;
    uint256 wantedHealthFactor;
}

struct RepayAndWithdrawResult {
    bytes32 id;
    uint256 amtOfColToWithdraw;
    uint256 amtToFlashBorrow;
    string message;
}

struct CanExecData {
    bytes32 id;
    address user;
    uint256 minimumHF;
    address colToken;
    address spender;
}

struct CanExecResult {
    bytes32 id;
    bool isPositionSafe;
    bool isATokenAllowed;
    string message;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {IAction} from "./IAction.sol";

interface IProtectionAction is IAction {
    /// sohint-disable-next-line func-name-mixedcase
    function protectionFeeBps() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {ILendingPool} from "../interfaces/aave/ILendingPool.sol";
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DataTypes} from "../structs/SAave.sol";
import {_rdiv} from "../vendor/DSMath.sol";
import {GELATO} from "../constants/CAaveServices.sol";
import {TEN_THOUSAND_BPS} from "../constants/CProtectionAction.sol";
import {
    ProtectionPayload,
    FlashLoanParamsData
} from "../structs/SProtection.sol";
import {IHandler} from "../interfaces/services/handlers/IHandler.sol";
import {GelatoBytes} from "../lib/GelatoBytes.sol";

function _getProtectionPayload(
    bytes32 _taskHash,
    bytes memory _data,
    bytes memory _offChainData
) pure returns (ProtectionPayload memory) {
    ProtectionPayload memory protectionPayload;

    protectionPayload.taskHash = _taskHash;

    (
        protectionPayload.colToken,
        protectionPayload.debtToken,
        protectionPayload.rateMode,
        protectionPayload.wantedHealthFactor,
        protectionPayload.minimumHealthFactor,
        protectionPayload.onBehalfOf
    ) = abi.decode(
        _data,
        (address, address, uint256, uint256, uint256, address)
    );

    (
        protectionPayload.amtToFlashBorrow,
        protectionPayload.amtOfColToWithdraw,
        protectionPayload.swapActions,
        protectionPayload.swapDatas
    ) = abi.decode(_offChainData, (uint256, uint256, address[], bytes[]));

    return protectionPayload;
}

function _flashLoan(
    ILendingPool _lendingPool,
    address receiverAddress,
    ProtectionPayload memory _protectionPayload
) {
    address[] memory debtTokens = new address[](1);
    debtTokens[0] = _protectionPayload.debtToken;

    uint256[] memory amtToFlashBorrows = new uint256[](1);
    amtToFlashBorrows[0] = _protectionPayload.amtToFlashBorrow;

    _lendingPool.flashLoan(
        receiverAddress,
        debtTokens,
        amtToFlashBorrows,
        new uint256[](1),
        _protectionPayload.onBehalfOf,
        abi.encode(
            FlashLoanParamsData(
                _protectionPayload.minimumHealthFactor,
                _protectionPayload.taskHash,
                _protectionPayload.colToken,
                _protectionPayload.amtOfColToWithdraw,
                _protectionPayload.rateMode,
                _protectionPayload.onBehalfOf,
                _protectionPayload.swapActions,
                _protectionPayload.swapDatas
            )
        ),
        0
    );
}

function _approveERC20Token(
    address _asset,
    address _spender,
    uint256 _amount
) {
    // Approves 0 first to comply with tokens that implement the anti frontrunning approval fix
    SafeERC20.safeApprove(IERC20(_asset), _spender, 0);
    SafeERC20.safeApprove(IERC20(_asset), _spender, _amount);
}

function _paybackToLendingPool(
    ILendingPool _lendingPool,
    address _asset,
    uint256 _amount,
    uint256 _rateMode,
    address _onBehalf
) {
    _approveERC20Token(_asset, address(_lendingPool), _amount);
    _lendingPool.repay(_asset, _amount, _rateMode, _onBehalf);
}

function _withdrawCollateral(
    ILendingPool _lendingPool,
    address aaveService,
    address _asset,
    uint256 _amount,
    address _onBehalf
) {
    DataTypes.ReserveData memory reserve = _lendingPool.getReserveData(_asset);

    SafeERC20.safeTransferFrom(
        IERC20(reserve.aTokenAddress),
        _onBehalf,
        aaveService,
        _amount
    );

    _lendingPool.withdraw(_asset, _amount, aaveService);
}

function _transferDust(
    address _sender,
    address _asset,
    address _user
) {
    uint256 serviceBalance = IERC20(_asset).balanceOf(_sender);

    if (serviceBalance > 0) {
        SafeERC20.safeTransfer(IERC20(_asset), _user, serviceBalance);
    }
}

function _transferFees(address _asset, uint256 _amount) {
    SafeERC20.safeTransfer(IERC20(_asset), GELATO, _amount);
}

function _isPositionSafe(
    uint256 _healthFactor,
    uint256 _discrepancyBps,
    uint256 _wantedHealthFactor
) pure {
    uint256 discrepancy =
        (_wantedHealthFactor * _discrepancyBps) / TEN_THOUSAND_BPS;

    require(
        _healthFactor < _wantedHealthFactor + discrepancy &&
            _healthFactor > _wantedHealthFactor - discrepancy &&
            _wantedHealthFactor > 1e18,
        "The user position isn't safe after the protection of the debt."
    );
}

function _isPositionUnSafe(
    uint256 _currentHealthFactor,
    uint256 _minimumHealthFactor
) pure {
    require(
        _currentHealthFactor < _minimumHealthFactor,
        "The user position's health factor is above the minimum trigger health factor."
    );
}

function _swap(
    address _this,
    address[] memory _swapActions,
    bytes[] memory _swapDatas,
    IERC20 _outputToken,
    uint256 _minReturn
) returns (uint256 receivedAmt) {
    require(
        _swapActions.length == _swapDatas.length,
        "FProtectionAction._swap: actions length != datas length."
    );
    uint256 outputTokenbalanceBSwap = _outputToken.balanceOf(_this);

    for (uint256 i; i < _swapActions.length; i++) {
        {
            (bool success, bytes memory returnsData) =
                _swapActions[i].call(_swapDatas[i]);
            if (!success)
                GelatoBytes.revertWithError(
                    returnsData,
                    "ProtectionAction.swap: Failed."
                );
        }
    }

    receivedAmt = _outputToken.balanceOf(_this) - outputTokenbalanceBSwap;

    // To Do Auditor: our assumption is that we don't need this check because
    // if we don't get the minReturn we will revert when trying to repay the flashloan
    // Also we would like to assess slippage protection here. Our assumption is
    // that the slippage for the swap is bounded by the health factor discrepancy
    // allowance the contract gives.
    require(
        receivedAmt > _minReturn,
        "ProtectionAction.swap: received amount < minReturn."
    );
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
pragma solidity 0.8.4;

address constant MATIC = 0x0000000000000000000000000000000000001010;
address constant WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

uint256 constant PROTECTION_FEE_BPS_CAP = 10; // 0.1%
uint256 constant DISCREPANCY_BPS_CAP = 500; // 5%
uint256 constant TEN_THOUSAND_BPS = 1e4; // 100%

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {
    ILendingPoolAddressesProvider
} from "./ILendingPoolAddressesProvider.sol";
import {ILendingPool} from "./ILendingPool.sol";

/**
 * @title IFlashLoanReceiver interface
 * @notice Interface for the Aave fee IFlashLoanReceiver.
 * @author Aave
 * @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);

    // solhint-disable-next-line func-name-mixedcase
    function ADDRESSES_PROVIDER()
        external
        view
        returns (ILendingPoolAddressesProvider);

    // solhint-disable-next-line func-name-mixedcase
    function LENDING_POOL() external view returns (ILendingPool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {
    ILendingPoolAddressesProvider
} from "./ILendingPoolAddressesProvider.sol";
import {DataTypes} from "../../structs/SAave.sol";

interface ILendingPool {
    /**
     * @dev Emitted on deposit()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
     * @param amount The amount deposited
     * @param referral The referral code used
     **/
    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlyng asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(),
     * receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed
     * @param referral The referral code used
     **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     **/
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount
    );

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param rateMode The rate mode that the user wants to swap to
     **/
    event Swap(address indexed reserve, address indexed user, uint256 rateMode);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     **/
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium,
        uint16 referralCode
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
     * LendingPoolCollateral manager using a DELEGATECALL
     * This allows to have the events in the generated ABI for LendingPool.
     * @param collateralAsset The address of the underlying asset used as collateral,
     * to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the
     * liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens,
     * `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
     * in the ReserveLogic library and emitted in the updateInterestRates() function.
     * Since the function is internal, the event will actually be fired by the LendingPool contract.
     * The event is therefore replicated here so it
     * gets added to the LendingPool ABI
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The new liquidity rate
     * @param stableBorrowRate The new stable borrow rate
     * @param variableBorrowRate The new variable borrow rate
     * @param liquidityIndex The new liquidity index
     * @param variableBorrowIndex The new variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve,
     * receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     * wants to receive them on his own wallet,
     * or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation,
     * for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve,
     * burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset,
     * provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit
     * delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address,
     * receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow:
     * - 1 for Stable,
     * - 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation,
     * for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt.
     * Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral,
     * or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve,
     * burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt
     * tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt
     * for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay:
     * - 1 for Stable,
     * - 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed.
     * Should be the address of the user calling the function
     * if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
     * @param asset The address of the underlying asset borrowed
     * @param rateMode The rate mode that the user wants to swap to
     **/
    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    /**
     * @dev Rebalances the stable interest rate of a user to
     * the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate,
     *        which means that too much has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral,
     * `false` otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        external;

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt
     * of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral,
     * to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset
     * to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens,
     * `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * IMPORTANT There are security concerns for developers
     * of flashloan receiver contracts that must be kept into consideration.
     * For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds,
     * implementing the IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts amounts being flash-borrowed
     * @param modes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount
     *        flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed
     *        to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in
     * the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode Code used to register the integrator originating the operation,
     * for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function initReserve(
        address reserve,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function setReserveInterestRateStrategyAddress(
        address reserve,
        address rateStrategyAddress
    ) external;

    function setConfiguration(address reserve, uint256 configuration) external;

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user)
        external
        view
        returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getAddressesProvider()
        external
        view
        returns (ILendingPoolAddressesProvider);

    function setPause(bool val) external;

    function paused() external view returns (bool);

    /// solhint-disable-next-line func-name-mixedcase
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint256);
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

library DataTypes {
    // refer to the whitepaper,
    // section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {NONE, STABLE, VARIABLE}
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
pragma solidity 0.8.4;

struct Route {
    address payable exchange;
    address targetExchange;
    uint256 percent;
    bytes payload;
    uint256 networkFee; //Network fee is associated with 0xv3 trades
}

struct Path {
    address to;
    uint256 totalNetworkFee; //Network fee is associated with 0xv3 trades
    Route[] routes;
}

struct MegaSwapPath {
    uint256 fromAmountPercent;
    Path[] path;
}

struct SellData {
    address fromToken;
    uint256 fromAmount;
    uint256 toAmount;
    uint256 expectedAmount;
    address payable beneficiary;
    string referrer;
    bool useReduxToken;
    Path[] path;
}

struct MegaSwapSellData {
    address fromToken;
    uint256 fromAmount;
    uint256 toAmount;
    uint256 expectedAmount;
    address payable beneficiary;
    string referrer;
    bool useReduxToken;
    MegaSwapPath[] path;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IAction {
    function exec(
        bytes32 _taskHash,
        bytes memory _data,
        bytes memory _offChainData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// solhint-disable
function _add(uint256 x, uint256 y) pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
}

function _sub(uint256 x, uint256 y) pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
}

function _mul(uint256 x, uint256 y) pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
}

function _min(uint256 x, uint256 y) pure returns (uint256 z) {
    return x <= y ? x : y;
}

function _max(uint256 x, uint256 y) pure returns (uint256 z) {
    return x >= y ? x : y;
}

function _imin(int256 x, int256 y) pure returns (int256 z) {
    return x <= y ? x : y;
}

function _imax(int256 x, int256 y) pure returns (int256 z) {
    return x >= y ? x : y;
}

uint256 constant WAD = 10**18;
uint256 constant RAY = 10**27;
uint256 constant QUA = 10**4;

//rounds to zero if x*y < WAD / 2
function _wmul(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, y), WAD / 2) / WAD;
}

//rounds to zero if x*y < WAD / 2
function _rmul(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, y), RAY / 2) / RAY;
}

//rounds to zero if x*y < WAD / 2
function _wdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, WAD), y / 2) / y;
}

//rounds to zero if x*y < RAY / 2
function _rdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, RAY), y / 2) / y;
}

// This famous algorithm is called "exponentiation by squaring"
// and calculates x^n with x as fixed-point and n as regular unsigned.
//
// It's O(log n), instead of O(n) for naive repeated multiplication.
//
// These facts are why it works:
//
//  If n is even, then x^n = (x^2)^(n/2).
//  If n is odd,  then x^n = x * x^(n-1),
//   and applying the equation for even x gives
//    x^n = x * (x^2)^((n-1) / 2).
//
//  Also, EVM division is flooring and
//    floor[(n-1) / 2] = floor[n / 2].
//
function _rpow(uint256 x, uint256 n) pure returns (uint256 z) {
    z = n % 2 != 0 ? x : RAY;

    for (n /= 2; n != 0; n /= 2) {
        x = _rmul(x, x);

        if (n % 2 != 0) {
            z = _rmul(z, x);
        }
    }
}

//rounds to zero if x*y < QUA / 2
function _qmul(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, y), QUA / 2) / QUA;
}

//rounds to zero if x*y < QUA / 2
function _qdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    z = _add(_mul(x, QUA), y / 2) / y;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

address constant GELATO = 0x7598e84B2E114AB62CAB288CE5f7d5f6bad35BbA;
string constant OK = "OK";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHandler {
    /// @notice receive ETH
    receive() external payable;

    /**
     * @notice Handle an order execution
     * @param _inputToken - Address of the input token
     * @param _outputToken - Address of the output token
     * @param _inputAmount - uint256 of the input token amount
     * @param _minReturn - uint256 of the min return amount of output token
     * @param _data - Bytes of arbitrary data
     * @return bought - Amount of output token bought
     */
    function handle(
        IERC20 _inputToken,
        IERC20 _outputToken,
        uint256 _inputAmount,
        uint256 _minReturn,
        bytes calldata _data
    ) external payable returns (uint256 bought);

    /**
     * @notice Check whether can handle an order execution
     * @param _inputToken - Address of the input token
     * @param _outputToken - Address of the output token
     * @param _inputAmount - uint256 of the input token amount
     * @param _minReturn - uint256 of the min return amount of output token
     * @param _data - Bytes of arbitrary data
     * @return bool - Whether the execution can be handled or not
     */
    function canHandle(
        IERC20 _inputToken,
        IERC20 _outputToken,
        uint256 _inputAmount,
        uint256 _minReturn,
        bytes calldata _data
    ) external view returns (bool);
}

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.4;

library GelatoBytes {
    function calldataSliceSelector(bytes calldata _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function memorySliceSelector(bytes memory _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function revertWithError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                revert(string(abi.encodePacked(_tracingInfo, string(_bytes))));
            } else {
                revert(
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"))
                );
            }
        } else {
            revert(
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"))
            );
        }
    }

    function returnError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
        returns (string memory)
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                return string(abi.encodePacked(_tracingInfo, string(_bytes)));
            } else {
                return
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"));
            }
        } else {
            return
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"));
        }
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