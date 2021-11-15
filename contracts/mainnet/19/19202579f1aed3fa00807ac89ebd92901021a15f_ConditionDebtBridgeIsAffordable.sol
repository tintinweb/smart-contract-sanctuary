// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.6.10;

import "./IGelatoCondition.sol";

abstract contract GelatoConditionsStandard is IGelatoCondition {
    string internal constant OK = "OK";
}

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.6.10;
pragma experimental ABIEncoderV2;

/// @title IGelatoCondition - solidity interface of GelatoConditionsStandard
/// @notice all the APIs of GelatoConditionsStandard
/// @dev all the APIs are implemented inside GelatoConditionsStandard
interface IGelatoCondition {

    /// @notice GelatoCore calls this to verify securely the specified Condition securely
    /// @dev Be careful only to encode a Task's condition.data as is and not with the
    ///  "ok" selector or _taskReceiptId, since those two things are handled by GelatoCore.
    /// @param _taskReceiptId This is passed by GelatoCore so we can rely on it as a secure
    ///  source of Task identification.
    /// @param _conditionData This is the Condition.data field developers must encode their
    ///  Condition's specific parameters in.
    /// @param _cycleId For Tasks that are executed as part of a cycle.
    function ok(uint256 _taskReceiptId, bytes calldata _conditionData, uint256 _cycleId)
        external
        view
        returns(string memory);
}

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.6.10;
pragma experimental ABIEncoderV2;

import {IGelatoProviderModule} from "../../provider_modules/IGelatoProviderModule.sol";
import {IGelatoCondition} from "../../conditions/IGelatoCondition.sol";

struct Provider {
    address addr;  //  if msg.sender == provider => self-Provider
    IGelatoProviderModule module;  //  can be IGelatoProviderModule(0) for self-Providers
}

struct Condition {
    IGelatoCondition inst;  // can be AddressZero for self-conditional Actions
    bytes data;  // can be bytes32(0) for self-conditional Actions
}

enum Operation { Call, Delegatecall }

enum DataFlow { None, In, Out, InAndOut }

struct Action {
    address addr;
    bytes data;
    Operation operation;
    DataFlow dataFlow;
    uint256 value;
    bool termsOkCheck;
}

struct Task {
    Condition[] conditions;  // optional
    Action[] actions;
    uint256 selfProviderGasLimit;  // optional: 0 defaults to gelatoMaxGas
    uint256 selfProviderGasPriceCeil;  // optional: 0 defaults to NO_CEIL
}

struct TaskReceipt {
    uint256 id;
    address userProxy;
    Provider provider;
    uint256 index;
    Task[] tasks;
    uint256 expiryDate;
    uint256 cycleId;  // auto-filled by GelatoCore. 0 for non-cyclic/chained tasks
    uint256 submissionsLeft;
}

interface IGelatoCore {
    event LogTaskSubmitted(
        uint256 indexed taskReceiptId,
        bytes32 indexed taskReceiptHash,
        TaskReceipt taskReceipt
    );

    event LogExecSuccess(
        address indexed executor,
        uint256 indexed taskReceiptId,
        uint256 executorSuccessFee,
        uint256 sysAdminSuccessFee
    );
    event LogCanExecFailed(
        address indexed executor,
        uint256 indexed taskReceiptId,
        string reason
    );
    event LogExecReverted(
        address indexed executor,
        uint256 indexed taskReceiptId,
        uint256 executorRefund,
        string reason
    );

    event LogTaskCancelled(uint256 indexed taskReceiptId, address indexed cancellor);

    /// @notice API to query whether Task can be submitted successfully.
    /// @dev In submitTask the msg.sender must be the same as _userProxy here.
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _userProxy The userProxy from which the task will be submitted.
    /// @param _task Selected provider, conditions, actions, expiry date of the task
    function canSubmitTask(
        address _userProxy,
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    )
        external
        view
        returns(string memory);

    /// @notice API to submit a single Task.
    /// @dev You can let users submit multiple tasks at once by batching calls to this.
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _task A Gelato Task object: provider, conditions, actions.
    /// @param _expiryDate From then on the task cannot be executed. 0 for infinity.
    function submitTask(
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    )
        external;


    /// @notice A Gelato Task Cycle consists of 1 or more Tasks that automatically submit
    ///  the next one, after they have been executed.
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _tasks This can be a single task or a sequence of tasks.
    /// @param _expiryDate  After this no task of the sequence can be executed any more.
    /// @param _cycles How many full cycles will be submitted
    function submitTaskCycle(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    )
        external;


    /// @notice A Gelato Task Cycle consists of 1 or more Tasks that automatically submit
    ///  the next one, after they have been executed.
    /// @dev CAUTION: _sumOfRequestedTaskSubmits does not mean the number of cycles.
    /// @dev If _sumOfRequestedTaskSubmits = 1 && _tasks.length = 2, only the first task
    ///  would be submitted, but not the second
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _tasks This can be a single task or a sequence of tasks.
    /// @param _expiryDate  After this no task of the sequence can be executed any more.
    /// @param _sumOfRequestedTaskSubmits The TOTAL number of Task auto-submits
    ///  that should have occured once the cycle is complete:
    ///  _sumOfRequestedTaskSubmits = 0 => One Task will resubmit the next Task infinitly
    ///  _sumOfRequestedTaskSubmits = 1 => One Task will resubmit no other task
    ///  _sumOfRequestedTaskSubmits = 2 => One Task will resubmit 1 other task
    ///  ...
    function submitTaskChain(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    )
        external;

    // ================  Exec Suite =========================
    /// @notice Off-chain API for executors to check, if a TaskReceipt is executable
    /// @dev GelatoCore checks this during execution, in order to safeguard the Conditions
    /// @param _TR TaskReceipt, consisting of user task, user proxy address and id
    /// @param _gasLimit Task.selfProviderGasLimit is used for SelfProviders. All other
    ///  Providers must use gelatoMaxGas. If the _gasLimit is used by an Executor and the
    ///  tx reverts, a refund is paid by the Provider and the TaskReceipt is annulated.
    /// @param _execTxGasPrice Must be used by Executors. Gas Price fed by gelatoCore's
    ///  Gas Price Oracle. Executors can query the current gelatoGasPrice from events.
    function canExec(TaskReceipt calldata _TR, uint256 _gasLimit, uint256 _execTxGasPrice)
        external
        view
        returns(string memory);

    /// @notice Executors call this when Conditions allow it to execute submitted Tasks.
    /// @dev Executors get rewarded for successful Execution. The Task remains open until
    ///   successfully executed, or when the execution failed, despite of gelatoMaxGas usage.
    ///   In the latter case Executors are refunded by the Task Provider.
    /// @param _TR TaskReceipt: id, userProxy, Task.
    function exec(TaskReceipt calldata _TR) external;

    /// @notice Cancel task
    /// @dev Callable only by userProxy or selected provider
    /// @param _TR TaskReceipt: id, userProxy, Task.
    function cancelTask(TaskReceipt calldata _TR) external;

    /// @notice Cancel multiple tasks at once
    /// @dev Callable only by userProxy or selected provider
    /// @param _taskReceipts TaskReceipts: id, userProxy, Task.
    function multiCancelTasks(TaskReceipt[] calldata _taskReceipts) external;

    /// @notice Compute hash of task receipt
    /// @param _TR TaskReceipt, consisting of user task, user proxy address and id
    /// @return hash of taskReceipt
    function hashTaskReceipt(TaskReceipt calldata _TR) external pure returns(bytes32);

    // ================  Getters =========================
    /// @notice Returns the taskReceiptId of the last TaskReceipt submitted
    /// @return currentId currentId, last TaskReceiptId submitted
    function currentTaskReceiptId() external view returns(uint256);

    /// @notice Returns computed taskReceipt hash, used to check for taskReceipt validity
    /// @param _taskReceiptId Id of taskReceipt emitted in submission event
    /// @return hash of taskReceipt
    function taskReceiptHash(uint256 _taskReceiptId) external view returns(bytes32);
}

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.6.10;
pragma experimental ABIEncoderV2;

import {Action, Task} from "../gelato_core/interfaces/IGelatoCore.sol";

interface IGelatoProviderModule {

    /// @notice Check if provider agrees to pay for inputted task receipt
    /// @dev Enables arbitrary checks by provider
    /// @param _userProxy The smart contract account of the user who submitted the Task.
    /// @param _provider The account of the Provider who uses the ProviderModule.
    /// @param _task Gelato Task to be executed.
    /// @return "OK" if provider agrees
    function isProvided(address _userProxy, address _provider, Task calldata _task)
        external
        view
        returns(string memory);

    /// @notice Convert action specific payload into proxy specific payload
    /// @dev Encoded multiple actions into a multisend
    /// @param _taskReceiptId Unique ID of Gelato Task to be executed.
    /// @param _userProxy The smart contract account of the user who submitted the Task.
    /// @param _provider The account of the Provider who uses the ProviderModule.
    /// @param _task Gelato Task to be executed.
    /// @param _cycleId For Tasks that form part of a cycle/chain.
    /// @return Encoded payload that will be used for low-level .call on user proxy
    /// @return checkReturndata if true, fwd returndata from userProxy.call to ProviderModule
    function execPayload(
        uint256 _taskReceiptId,
        address _userProxy,
        address _provider,
        Task calldata _task,
        uint256 _cycleId
    )
        external
        view
        returns(bytes memory, bool checkReturndata);

    /// @notice Called by GelatoCore.exec to verifiy that no revert happend on userProxy
    /// @dev If a caught revert is detected, this fn should revert with the detected error
    /// @param _proxyReturndata Data from GelatoCore._exec.userProxy.call(execPayload)
    function execRevertCheck(bytes calldata _proxyReturndata) external pure;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

function GAS_COSTS_FOR_FULL_REFINANCE() pure returns (uint256[4] memory) {
    return [uint256(2000000), 2400000, 2850000, 3500000];
}

uint256 constant PREMIUM = 20;
uint256 constant VAULT_CREATION_COST = 150000;

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import {
    IGelatoGasPriceOracle
} from "../interfaces/gelato/IGelatoGasPriceOracle.sol";

IGelatoGasPriceOracle constant GELATO_GAS_PRICE_ORACLE = IGelatoGasPriceOracle(
    0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C
);

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

// InstaDapp
address constant INSTA_MEMORY = 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F;

// Connectors
address constant CONNECT_MAKER = 0xac02030d8a8F49eD04b2f52C394D3F901A10F8A9;
address constant CONNECT_COMPOUND = 0x15FdD1e902cAC70786fe7D31013B1a806764B5a2;
address constant INSTA_POOL_V2 = 0xeB4bf86589f808f90EEC8e964dBF16Bd4D284905;

// Tokens
address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

// Insta Pool
address constant INSTA_POOL_RESOLVER = 0xa004a5afBa04b74037E9E52bA1f7eb02b5E61509;
uint256 constant ROUTE_1_TOLERANCE = 1005e15;

// Insta Mapping
address constant INSTA_MAPPING = 0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88;

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

address constant MCD_MANAGER = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import {
    GelatoConditionsStandard
} from "@gelatonetwork/core/contracts/conditions/GelatoConditionsStandard.sol";
import {
    IGelatoCore
} from "@gelatonetwork/core/contracts/gelato_core/interfaces/IGelatoCore.sol";
import {GelatoBytes} from "../../../lib/GelatoBytes.sol";
import {
    _getMakerVaultDebt,
    _getMakerVaultCollateralBalance
} from "../../../functions/dapps/FMaker.sol";
import {
    _getFlashLoanRoute,
    _getGasCostMakerToMaker,
    _getRealisedDebt
} from "../../../functions/gelato/FGelatoDebtBridge.sol";
import {_getGelatoExecutorFees} from "../../../functions/gelato/FGelato.sol";
import {DAI} from "../../../constants/CInstaDapp.sol";
import {wdiv} from "../../../vendor/DSMath.sol";

/// @title ConditionDebtBridgeIsAffordable
/// @notice Condition checking if Debt Refinance is affordable.
/// @author Gelato Team
contract ConditionDebtBridgeIsAffordable is GelatoConditionsStandard {
    using GelatoBytes for bytes;

    /// @notice Convenience function for off-chain _conditionData encoding
    /// @dev Use the return for your Task's Condition.data field off-chain.
    /// @dev WARNING _ratioLimit should be in wad standard.
    /// @return The encoded payload for your Task's Condition.data field.
    function getConditionData(uint256 _vaultId, uint256 _ratioLimit)
        public
        pure
        virtual
        returns (bytes memory)
    {
        return
            abi.encodeWithSelector(
                this.isAffordable.selector,
                _vaultId,
                _ratioLimit
            );
    }

    /// @notice Standard GelatoCore system function
    /// @dev A standard interface for GelatoCore to read Conditions
    /// @param _conditionData The data you get from `getConditionData()`
    /// @return OK if the Condition is there, else some error message.
    function ok(
        uint256,
        bytes calldata _conditionData,
        uint256
    ) public view virtual override returns (string memory) {
        (uint256 _vaultID, uint256 _ratioLimit) =
            abi.decode(_conditionData[4:], (uint256, uint256));

        return isAffordable(_vaultID, _ratioLimit);
    }

    /// @notice Specific implementation of this Condition's ok function
    /// @dev Check if the debt refinancing action is affordable.
    /// @dev WARNING _ratioLimit should be in wad standard.
    /// @param _vaultId The id of the Maker vault
    /// @param _ratioLimit the maximum limit define by the user up on which
    /// the debt is too expensive for him
    /// @return OK if the Debt Bridge is affordable, otherwise some error message.
    function isAffordable(uint256 _vaultId, uint256 _ratioLimit)
        public
        view
        returns (string memory)
    {
        uint256 wColToWithdrawFromMaker =
            _getMakerVaultCollateralBalance(_vaultId);
        uint256 gasFeesPaidFromCol =
            _getGelatoExecutorFees(
                _getGasCostMakerToMaker(
                    false,
                    _getFlashLoanRoute(
                        DAI,
                        _getRealisedDebt(_getMakerVaultDebt(_vaultId))
                    )
                )
            );
        if (wdiv(gasFeesPaidFromCol, wColToWithdrawFromMaker) >= _ratioLimit)
            return "DebtBridgeNotAffordable";
        return OK;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import {MCD_MANAGER} from "../../constants/CMaker.sol";
import {INSTA_MAPPING} from "../../constants/CInstaDapp.sol";
import {
    ITokenJoinInterface
} from "../../interfaces/dapps/Maker/ITokenJoinInterface.sol";
import {IMcdManager} from "../../interfaces/dapps/Maker/IMcdManager.sol";
import {InstaMapping} from "../../interfaces/InstaDapp/IInstaDapp.sol";
import {IVat} from "../../interfaces/dapps/Maker/IVat.sol";
import {RAY, add, sub, mul} from "../../vendor/DSMath.sol";
import {_stringToBytes32, _convertTo18} from "../../vendor/Convert.sol";

function _getMakerVaultDebt(uint256 _vaultId) view returns (uint256 wad) {
    IMcdManager manager = IMcdManager(MCD_MANAGER);

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);
    IVat vat = IVat(manager.vat());
    (, uint256 rate, , , ) = vat.ilks(ilk);
    (, uint256 art) = vat.urns(ilk, urn);
    uint256 dai = vat.dai(urn);

    uint256 rad = sub(mul(art, rate), dai);
    wad = rad / RAY;

    wad = mul(wad, RAY) < rad ? wad + 1 : wad;
}

function _getMakerRawVaultDebt(uint256 _vaultId) view returns (uint256 tab) {
    IMcdManager manager = IMcdManager(MCD_MANAGER);

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);
    IVat vat = IVat(manager.vat());
    (, uint256 rate, , , ) = vat.ilks(ilk);
    (, uint256 art) = vat.urns(ilk, urn);

    uint256 rad = mul(art, rate);

    tab = rad / RAY;
    tab = mul(tab, RAY) < rad ? tab + 1 : tab;
}

function _getMakerVaultCollateralBalance(uint256 _vaultId)
    view
    returns (uint256)
{
    IMcdManager manager = IMcdManager(MCD_MANAGER);

    IVat vat = IVat(manager.vat());
    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);
    (uint256 ink, ) = vat.urns(ilk, urn);

    return ink;
}

function _vaultWillBeSafe(
    uint256 _vaultId,
    uint256 _amtToBorrow,
    uint256 _colToDeposit
) view returns (bool) {
    require(_vaultId != 0, "_vaultWillBeSafe: invalid vault id.");

    IMcdManager manager = IMcdManager(MCD_MANAGER);

    (bytes32 ilk, address urn) = _getVaultData(manager, _vaultId);

    ITokenJoinInterface tokenJoinContract =
        ITokenJoinInterface(InstaMapping(INSTA_MAPPING).gemJoinMapping(ilk));

    IVat vat = IVat(manager.vat());
    (, uint256 rate, uint256 spot, , ) = vat.ilks(ilk);
    (uint256 ink, uint256 art) = vat.urns(ilk, urn);
    uint256 dai = vat.dai(urn);

    uint256 dink = _convertTo18(tokenJoinContract.dec(), _colToDeposit);
    uint256 dart = _getBorrowAmt(_amtToBorrow, dai, rate);

    ink = add(ink, dink);
    art = add(art, dart);

    uint256 tab = mul(rate, art);

    return tab <= mul(ink, spot);
}

function _newVaultWillBeSafe(
    string memory _colType,
    uint256 _amtToBorrow,
    uint256 _colToDeposit
) view returns (bool) {
    IMcdManager manager = IMcdManager(MCD_MANAGER);
    IVat vat = IVat(manager.vat());

    bytes32 ilk = _stringToBytes32(_colType);

    (, uint256 rate, uint256 spot, , ) = vat.ilks(ilk);

    ITokenJoinInterface tokenJoinContract =
        ITokenJoinInterface(InstaMapping(INSTA_MAPPING).gemJoinMapping(ilk));

    uint256 ink = _convertTo18(tokenJoinContract.dec(), _colToDeposit);
    uint256 art = _getBorrowAmt(_amtToBorrow, 0, rate);

    uint256 tab = mul(rate, art);

    return tab <= mul(ink, spot);
}

function _getVaultData(IMcdManager manager, uint256 vault)
    view
    returns (bytes32 ilk, address urn)
{
    ilk = manager.ilks(vault);
    urn = manager.urns(vault);
}

function _getBorrowAmt(
    uint256 _amt,
    uint256 _dai,
    uint256 _rate
) pure returns (uint256 dart) {
    dart = sub(mul(_amt, RAY), _dai) / _rate;
    dart = mul(dart, _rate) < mul(_amt, RAY) ? dart + 1 : dart;
}

function _isVaultOwner(uint256 _vaultId, address _owner) view returns (bool) {
    if (_vaultId == 0) return false;

    try IMcdManager(MCD_MANAGER).owns(_vaultId) returns (address owner) {
        return _owner == owner;
    } catch Error(string memory error) {
        revert(string(abi.encodePacked("FMaker._isVaultOwner:", error)));
    } catch {
        revert("FMaker._isVaultOwner:undefined");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import {GELATO_GAS_PRICE_ORACLE} from "../../constants/CGelato.sol";
import {mul} from "../../vendor/DSMath.sol";

function _getGelatoGasPrice() view returns (uint256) {
    int256 oracleGasPrice = GELATO_GAS_PRICE_ORACLE.latestAnswer();
    if (oracleGasPrice <= 0) revert("_getGelatoGasPrice:0orBelow");
    return uint256(oracleGasPrice);
}

function _getGelatoExecutorFees(uint256 _gas) view returns (uint256) {
    return mul(_gas, _getGelatoGasPrice());
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import {add, sub, mul, wmul, wdiv} from "../../vendor/DSMath.sol";
import {
    INSTA_POOL_RESOLVER,
    ROUTE_1_TOLERANCE
} from "../../constants/CInstaDapp.sol";
import {
    GAS_COSTS_FOR_FULL_REFINANCE,
    PREMIUM,
    VAULT_CREATION_COST
} from "../../constants/CDebtBridge.sol";
import {
    IInstaPoolResolver
} from "../../interfaces/InstaDapp/resolvers/IInstaPoolResolver.sol";

function _wCalcCollateralToWithdraw(
    uint256 _wMinColRatioA,
    uint256 _wMinColRatioB,
    uint256 _wColPrice,
    uint256 _wPricedCol,
    uint256 _wDebtOnA
) pure returns (uint256) {
    return
        wdiv(
            sub(
                _wPricedCol,
                wdiv(
                    sub(
                        wmul(_wMinColRatioA, _wPricedCol),
                        wmul(_wMinColRatioA, wmul(_wMinColRatioB, _wDebtOnA))
                    ),
                    sub(_wMinColRatioA, _wMinColRatioB)
                )
            ),
            _wColPrice
        );
}

function _wCalcDebtToRepay(
    uint256 _wMinColRatioA,
    uint256 _wMinColRatioB,
    uint256 _wPricedCol,
    uint256 _wDebtOnA
) pure returns (uint256) {
    return
        sub(
            _wDebtOnA,
            wmul(
                wdiv(1e18, _wMinColRatioA),
                wdiv(
                    sub(
                        wmul(_wMinColRatioA, _wPricedCol),
                        wmul(_wMinColRatioA, wmul(_wMinColRatioB, _wDebtOnA))
                    ),
                    sub(_wMinColRatioA, _wMinColRatioB)
                )
            )
        );
}

function _getFlashLoanRoute(address _tokenA, uint256 _wTokenADebtToMove)
    view
    returns (uint256)
{
    IInstaPoolResolver.RouteData memory rData =
        IInstaPoolResolver(INSTA_POOL_RESOLVER).getTokenLimit(_tokenA);

    if (rData.dydx > _wTokenADebtToMove) return 0;
    if (rData.maker > _wTokenADebtToMove) return 1;
    if (rData.compound > _wTokenADebtToMove) return 2;
    if (rData.aave > _wTokenADebtToMove) return 3;
    revert("FGelatoDebtBridge._getFlashLoanRoute: illiquid");
}

function _getGasCostMakerToMaker(bool _newVault, uint256 _route)
    pure
    returns (uint256)
{
    _checkRouteIndex(_route);
    return
        _getGasCostPremium(
            _newVault
                ? add(
                    GAS_COSTS_FOR_FULL_REFINANCE()[_route],
                    VAULT_CREATION_COST
                )
                : GAS_COSTS_FOR_FULL_REFINANCE()[_route]
        );
}

function _getGasCostMakerToCompound(uint256 _route) pure returns (uint256) {
    _checkRouteIndex(_route);
    return _getGasCostPremium(GAS_COSTS_FOR_FULL_REFINANCE()[_route]);
}

function _getGasCostPremium(uint256 _rawGasCost) pure returns (uint256) {
    return mul(_rawGasCost, add(100, PREMIUM)) / 100;
}

function _getRealisedDebt(uint256 _debtToMove) pure returns (uint256) {
    return wmul(_debtToMove, ROUTE_1_TOLERANCE);
}

function _checkRouteIndex(uint256 _route) pure {
    require(
        _route <= 4,
        "FGelatoDebtBridge._getGasCostMakerToMaker: invalid route index"
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

/// @notice Interface InstaDapp Index
interface IndexInterface {
    function connectors(uint256 version) external view returns (address);

    function list() external view returns (address);
}

/// @notice Interface InstaDapp List
interface ListInterface {
    function accountID(address _account) external view returns (uint64);
}

/// @notice Interface InstaDapp InstaMemory
interface MemoryInterface {
    function setUint(uint256 _id, uint256 _val) external;

    function getUint(uint256 _id) external returns (uint256);
}

/// @notice Interface InstaDapp Defi Smart Account wallet
interface AccountInterface {
    function cast(
        address[] calldata _targets,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32[] memory responses);

    function version() external view returns (uint256);

    function isAuth(address user) external view returns (bool);

    function shield() external view returns (bool);
}

interface ConnectorInterface {
    function connectorID() external view returns (uint256 _type, uint256 _id);

    function name() external view returns (string memory);
}

interface InstaMapping {
    function gemJoinMapping(bytes32) external view returns (address);
}

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IInstaPoolResolver {
    struct RouteData {
        uint256 dydx;
        uint256 maker;
        uint256 compound;
        uint256 aave;
    }

    function getTokenLimit(address token)
        external
        view
        returns (RouteData memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

interface IMcdManager {
    function ilks(uint256) external view returns (bytes32);

    function urns(uint256) external view returns (address);

    function vat() external view returns (address);

    function owns(uint256) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

interface ITokenJoinInterface {
    function dec() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

interface IVat {
    function ilks(bytes32)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function dai(address) external view returns (uint256);

    function urns(bytes32, address) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

interface IGelatoGasPriceOracle {
    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import {mul as _mul} from "./DSMath.sol";

function _stringToBytes32(string memory str) pure returns (bytes32 result) {
    require(bytes(str).length != 0, "string-empty");
    assembly {
        result := mload(add(str, 32))
    }
}

function _convertTo18(uint256 _dec, uint256 _amt) pure returns (uint256 amt) {
    amt = _mul(_amt, 10**(18 - _dec));
}

// "SPDX-License-Identifier: AGPL-3.0-or-later"
/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.7.4;

function add(uint256 x, uint256 y) pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
}

function sub(uint256 x, uint256 y) pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
}

function mul(uint256 x, uint256 y) pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
}

function min(uint256 x, uint256 y) pure returns (uint256 z) {
    return x <= y ? x : y;
}

function max(uint256 x, uint256 y) pure returns (uint256 z) {
    return x >= y ? x : y;
}

function imin(int256 x, int256 y) pure returns (int256 z) {
    return x <= y ? x : y;
}

function imax(int256 x, int256 y) pure returns (int256 z) {
    return x >= y ? x : y;
}

uint256 constant WAD = 10**18;
uint256 constant RAY = 10**27;

//rounds to zero if x*y < WAD / 2
function wmul(uint256 x, uint256 y) pure returns (uint256 z) {
    z = add(mul(x, y), WAD / 2) / WAD;
}

//rounds to zero if x*y < WAD / 2
function rmul(uint256 x, uint256 y) pure returns (uint256 z) {
    z = add(mul(x, y), RAY / 2) / RAY;
}

//rounds to zero if x*y < WAD / 2
function wdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    z = add(mul(x, WAD), y / 2) / y;
}

//rounds to zero if x*y < RAY / 2
function rdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    z = add(mul(x, RAY), y / 2) / y;
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
function rpow(uint256 x, uint256 n) pure returns (uint256 z) {
    z = n % 2 != 0 ? x : RAY;

    for (n /= 2; n != 0; n /= 2) {
        x = rmul(x, x);

        if (n % 2 != 0) {
            z = rmul(z, x);
        }
    }
}

