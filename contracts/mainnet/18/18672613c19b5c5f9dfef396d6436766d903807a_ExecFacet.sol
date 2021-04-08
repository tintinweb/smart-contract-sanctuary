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

import {IGelatoProviderModule} from "../../gelato_provider_modules/IGelatoProviderModule.sol";
import {IGelatoCondition} from "../../gelato_conditions/IGelatoCondition.sol";

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
pragma solidity 0.8.0;

uint256 constant DECIMALS_USD = 8;

uint256 constant DECIMALS_USDT = 6;

uint256 constant DECIMALS_USDC = 6;

uint256 constant DECIMALS_DAI = 18;

uint256 constant DECIMALS_BUSD = 18;

uint256 constant DECIMALS_SUSD = 18;

uint256 constant DECIMALS_TUSD = 18;

address constant USD = 0x7354C81fbCb229187480c4f497F945C6A312d5C3; // Random address

address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

address constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;

address constant SUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;

address constant TUSD = 0x0000000000085d4780B73119b644AE5ecd22b376;

address constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

address constant ADX = 0xADE00C28244d5CE17D72E40330B1c318cD12B7c3;

address constant BAT = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;

address constant BNB = 0xB8c77482e45F1F44dE1745F52C74426C631bDD52;

address constant BNT = 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C;

address constant BZRX = 0x56d811088235F11C8920698a204A5010a788f4b3;

address constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;

address constant CRO = 0xA0b73E1Ff0B80914AB6fe0444E65848C4C34450b;

address constant DMG = 0xEd91879919B71bB6905f23af0A68d231EcF87b14;

address constant ENJ = 0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c;

address constant KNC = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200;

address constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

address constant LRC = 0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD;

address constant MANA = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942;

address constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;

address constant NMR = 0x1776e1F26f98b1A5dF9cD347953a26dd3Cb46671;

address constant REN = 0x408e41876cCCDC0F92210600ef50372656052a38;

address constant REP = 0x221657776846890989a759BA2973e427DfF5C9bB;

address constant SNX = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;

address constant SXP = 0x8CE9137d39326AD0cD6491fb5CC0CbA0e089b6A9;

address constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

address constant WOM = 0xa982B2e19e90b2D9F7948e9C1b65D119F1CE88D6;

address constant YFI = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;

address constant ZRX = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

address constant UNISWAPV2_ROUTER02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {BFacetOwner} from "../facets/base/BFacetOwner.sol";
import {LibAddress} from "../libraries/LibAddress.sol";
import {LibDiamond} from "../libraries/standard/LibDiamond.sol";
import {LibExecutor} from "../libraries/LibExecutor.sol";
import {
    EnumerableSet
} from "../../../vendor/openzeppelin/contracts/utils/EnumerableSet.sol";
import {GelatoBytes} from "../../../lib/GelatoBytes.sol";
import {GelatoString} from "../../../lib/GelatoString.sol";
import {_getBalance} from "../../../functions/gelato/FPayment.sol";
import {_getCappedGasPrice} from "../../../functions/gelato/FGelato.sol";
import {IGelatoV1} from "../../../interfaces/gelato/IGelatoV1.sol";
import {ETH} from "../../../constants/CTokens.sol";
import {
    IOracleAggregator
} from "../../../interfaces/gelato/IOracleAggregator.sol";

contract ExecFacet is BFacetOwner {
    using LibDiamond for address;
    using LibExecutor for address;
    using GelatoBytes for bytes;
    using EnumerableSet for EnumerableSet.AddressSet;
    using GelatoString for string;

    // solhint-disable var-name-mixedcase
    uint256 public constant GAS_OVERHEAD = 40000;
    IGelatoV1 public immutable GELATO_V1;
    address public immutable GELATO_PROVIDER;

    // solhint-enable var-name-mixedcase

    event LogExecSuccess(
        address indexed executor,
        address indexed service,
        bool indexed wasExecutorPaid
    );

    event LogSetGasMargin(uint256 oldGasMargin, uint256 newGasMargin);

    constructor(IGelatoV1 _gelatoV1, address _gelatoProvider) {
        GELATO_V1 = _gelatoV1;
        GELATO_PROVIDER = _gelatoProvider;
    }

    // ################ Callable by Gov ################
    function addExecutors(address[] calldata _executors) external onlyOwner {
        for (uint256 i; i < _executors.length; i++)
            require(_executors[i].addExecutor(), "ExecFacet.addExecutors");
    }

    function removeExecutors(address[] calldata _executors) external {
        for (uint256 i; i < _executors.length; i++) {
            require(
                msg.sender == _executors[i] || msg.sender.isContractOwner(),
                "ExecFacet.removeExecutors: msg.sender ! executor || owner"
            );
            require(
                _executors[i].removeExecutor(),
                "ExecFacet.removeExecutors"
            );
        }
    }

    function setGasMargin(uint256 _gasMargin) external onlyOwner {
        emit LogSetGasMargin(gasMargin(), _gasMargin);
        LibExecutor.setGasMargin(_gasMargin);
    }

    // solhint-disable function-max-lines
    // ################ Callable by Executor ################
    /// @dev * reverts if Executor overcharges users
    ///      * assumes honest executors
    ///      * verifying correct fee can be removed after staking/slashing
    ///        was introduced
    // solhint-disable-next-line code-complexity
    function exec(
        address _service,
        bytes calldata _data,
        address _creditToken
    ) external {
        uint256 startGas = gasleft();

        require(msg.sender.isExecutor(), "ExecFacet.exec: onlyExecutors");

        if (_service == address(GELATO_V1)) _creditToken = ETH;

        uint256 preCreditTokenBalance =
            _getBalance(_creditToken, address(this));

        (bool success, bytes memory returndata) = _service.call(_data);
        if (!success) returndata.revertWithError("ExecFacet.exec:");

        // Needs to be here in case service relies on GelatoV1 built-in provider ETH payments
        if (_service == address(GELATO_V1))
            GELATO_V1.withdrawExcessExecutorStake(type(uint256).max);

        uint256 postCreditTokenBalance =
            _getBalance(_creditToken, address(this));

        // TO DO: remove and replace with executor payments based on what services paid out
        require(
            postCreditTokenBalance > preCreditTokenBalance,
            "ExecFacet.exec: postCreditTokenBalance < preCreditTokenBalance"
        );

        uint256 credit = postCreditTokenBalance - preCreditTokenBalance;

        uint256 gasDebitInETH =
            (startGas - gasleft() + GAS_OVERHEAD) *
                _getCappedGasPrice(LibAddress.getGasPriceOracle());

        uint256 gasDebitInCreditToken;
        if (_creditToken == ETH) gasDebitInCreditToken = gasDebitInETH;
        else {
            (gasDebitInCreditToken, ) = IOracleAggregator(
                LibAddress.getOracleAggregator()
            )
                .getExpectedReturnAmount(gasDebitInETH, ETH, _creditToken);
        }

        require(
            gasDebitInCreditToken != 0,
            "ExecFacet.exec:  _creditToken not on OracleAggregator"
        );

        uint256 _gasMargin_ = gasMargin();

        require(
            credit <=
                gasDebitInCreditToken +
                    (gasDebitInCreditToken * _gasMargin_) /
                    100,
            "ExecFacet.exec: Executor Overcharged"
        );

        if (_service == address(GELATO_V1))
            if (abi.decode(_data[68:100], (address)) == GELATO_PROVIDER) {
                // solhint-disable no-empty-blocks
                try
                    GELATO_V1.provideFunds{value: credit}(GELATO_PROVIDER)
                {} catch {}
                // solhint-enable no-empty-blocks
            }

        /// TO DO: pay executors based 1:1 on what services paid gelato in ETH equivalents
        (success, ) = msg.sender.call{
            value: gasDebitInETH + (gasDebitInETH * _gasMargin_) / 100
        }("");

        emit LogExecSuccess(msg.sender, _service, success);
    }

    function estimateExecGasDebit(
        address _service,
        bytes calldata _data,
        address _creditToken
    ) external returns (uint256 gasDebitInETH, uint256 gasDebitInCreditToken) {
        uint256 startGas = gasleft();

        require(msg.sender.isExecutor(), "ExecFacet.exec: onlyExecutors");

        if (_service == address(GELATO_V1)) _creditToken = ETH;

        uint256 preCreditTokenBalance =
            _getBalance(_creditToken, address(this));

        (bool success, bytes memory returndata) = _service.call(_data);
        if (!success) returndata.revertWithError("ExecFacet.exec:");

        // Needs to be here in case service relies on GelatoV1 built-in provider ETH payments
        if (_service == address(GELATO_V1))
            GELATO_V1.withdrawExcessExecutorStake(type(uint256).max);

        uint256 postCreditTokenBalance =
            _getBalance(_creditToken, address(this));

        uint256 credit = postCreditTokenBalance - preCreditTokenBalance;
        credit;

        gasDebitInETH =
            (startGas - gasleft() + GAS_OVERHEAD) *
            _getCappedGasPrice(LibAddress.getGasPriceOracle());

        if (_creditToken == ETH) gasDebitInCreditToken = gasDebitInETH;
        else {
            (gasDebitInCreditToken, ) = IOracleAggregator(
                LibAddress.getOracleAggregator()
            )
                .getExpectedReturnAmount(gasDebitInETH, ETH, _creditToken);
        }
    }

    function canExec(address _executor) external view returns (bool) {
        return _executor.canExec();
    }

    function isExecutor(address _executor) external view returns (bool) {
        return _executor.isExecutor();
    }

    function executors() external view returns (address[] memory) {
        return LibExecutor.executors();
    }

    function numberOfExecutors() external view returns (uint256) {
        return LibExecutor.numberOfExecutors();
    }

    function gasMargin() public view returns (uint256) {
        return LibExecutor.gasMargin();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {LibDiamond} from "../../libraries/standard/LibDiamond.sol";

abstract contract BFacetOwner {
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {IDiamondCut} from "./standard/IDiamondCut.sol";
import {IDiamondLoupe} from "./standard/IDiamondLoupe.sol";
import {
    TaskReceipt
} from "@gelatonetwork/core/contracts/gelato_core/interfaces/IGelatoCore.sol";
import {IGelatoV1} from "../../../interfaces/gelato/IGelatoV1.sol";

// solhint-disable ordering

/// @dev includes the interfaces of all facets
interface IGelato {
    // ########## Diamond Cut Facet #########
    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    function diamondCut(
        IDiamondCut.FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    // ########## DiamondLoupeFacet #########
    function facets()
        external
        view
        returns (IDiamondLoupe.Facet[] memory facets_);

    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);

    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool);

    // ########## Ownership Facet #########
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function transferOwnership(address _newOwner) external;

    function owner() external view returns (address owner_);

    // ########## AddressFacet #########
    event LogSetOracleAggregator(address indexed oracleAggregator);
    event LogSetGasPriceOracle(address indexed gasPriceOracle);

    function setOracleAggregator(address _oracleAggregator)
        external
        returns (address);

    function setGasPriceOracle(address _gasPriceOracle)
        external
        returns (address);

    function getOracleAggregator() external view returns (address);

    function getGasPriceOracle() external view returns (address);

    // ########## ConcurrentCanExecFacet #########
    enum SlotStatus {Open, Closing, Closed}

    function setSlotLength(uint256 _slotLength) external;

    function slotLength() external view returns (uint256);

    function concurrentCanExec(uint256 _buffer) external view returns (bool);

    function getCurrentExecutorIndex()
        external
        view
        returns (uint256 executorIndex, uint256 remainingBlocksInSlot);

    function currentExecutor()
        external
        view
        returns (
            address executor,
            uint256 executorIndex,
            uint256 remainingBlocksInSlot
        );

    function mySlotStatus(uint256 _buffer) external view returns (SlotStatus);

    function calcExecutorIndex(
        uint256 _currentBlock,
        uint256 _blocksPerSlot,
        uint256 _numberOfExecutors
    )
        external
        pure
        returns (uint256 executorIndex, uint256 remainingBlocksInSlot);

    // ########## ExecFacet #########

    // solhint-disable-next-line func-name-mixedcase
    function GAS_OVERHEAD() external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function GELATO_V1() external view returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function GELATO_PROVIDER() external view returns (address);

    event LogExecSuccess(
        address indexed executor,
        address indexed service,
        bool indexed wasExecutorPaid
    );

    event LogSetGasMargin(uint256 oldGasMargin, uint256 newGasMargin);

    function addExecutors(address[] calldata _executors) external;

    function removeExecutors(address[] calldata _executors) external;

    function setGasMargin(uint256 _gasMargin) external;

    function exec(
        address _service,
        bytes calldata _data,
        address _creditToken
    ) external;

    function estimateExecGasDebit(
        address _service,
        bytes calldata _data,
        address _creditToken
    ) external returns (uint256 gasDebitInETH, uint256 gasDebitInCreditToken);

    function canExec(address _executor) external view returns (bool);

    function isExecutor(address _executor) external view returns (bool);

    function executors() external view returns (address[] memory);

    function numberOfExecutors() external view returns (uint256);

    function gasMargin() external view returns (uint256);

    // ########## GelatoV1Facet #########
    struct Response {
        uint256 taskReceiptId;
        uint256 taskGasLimit;
        string response;
    }

    function stakeExecutor(IGelatoV1 _gelatoCore) external payable;

    function unstakeExecutor(IGelatoV1 _gelatoCore, address payable _to)
        external;

    function multiReassignProviders(
        IGelatoV1 _gelatoCore,
        address[] calldata _providers,
        address _newExecutor
    ) external;

    function providerRefund(
        IGelatoV1 _gelatoCore,
        address _provider,
        uint256 _amount
    ) external;

    function withdrawExcessExecutorStake(
        IGelatoV1 _gelatoCore,
        uint256 _withdrawAmount,
        address payable _to
    ) external;

    function v1ConcurrentMultiCanExec(
        address _gelatoCore,
        TaskReceipt[] calldata _taskReceipts,
        uint256 _gelatoGasPrice,
        uint256 _buffer
    )
        external
        view
        returns (
            bool canExecRes,
            uint256 blockNumber,
            Response[] memory responses
        );

    function v1MultiCanExec(
        address _gelatoCore,
        TaskReceipt[] calldata _taskReceipts,
        uint256 _gelatoGasPrice
    ) external view returns (uint256 blockNumber, Response[] memory responses);

    function getGasLimit(
        TaskReceipt calldata _taskReceipt,
        uint256 _gelatoMaxGas
    ) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

library LibAddress {
    struct AddressStorage {
        address oracleAggregator;
        address gasPriceOracle;
    }

    bytes32 private constant _ADDRESS_STORAGE =
        keccak256("gelato.diamond.address.storage");

    function setOracleAggregator(address _oracleAggregator) internal {
        LibAddress.addressStorage().oracleAggregator = _oracleAggregator;
    }

    function setGasPriceOracle(address _gasPriceOracle) internal {
        LibAddress.addressStorage().gasPriceOracle = _gasPriceOracle;
    }

    function getOracleAggregator() internal view returns (address) {
        return addressStorage().oracleAggregator;
    }

    function getGasPriceOracle() internal view returns (address) {
        return addressStorage().gasPriceOracle;
    }

    function addressStorage()
        internal
        pure
        returns (AddressStorage storage ads)
    {
        bytes32 position = _ADDRESS_STORAGE;
        assembly {
            ads.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {
    EnumerableSet
} from "../../../vendor/openzeppelin/contracts/utils/EnumerableSet.sol";

library LibExecutor {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct ExecutorStorage {
        EnumerableSet.AddressSet executors;
        uint256 gasMargin;
    }

    bytes32 private constant _EXECUTOR_STORAGE_POSITION =
        keccak256("gelato.diamond.executor.storage");

    function addExecutor(address _executor) internal returns (bool) {
        return executorStorage().executors.add(_executor);
    }

    function removeExecutor(address _executor) internal returns (bool) {
        return executorStorage().executors.remove(_executor);
    }

    function setGasMargin(uint256 _gasMargin) internal {
        executorStorage().gasMargin = _gasMargin;
    }

    function canExec(address _executor) internal view returns (bool) {
        return isExecutor(_executor);
    }

    function isExecutor(address _executor) internal view returns (bool) {
        return executorStorage().executors.contains(_executor);
    }

    function executorAt(uint256 _index) internal view returns (address) {
        return executorStorage().executors.at(_index);
    }

    function executors() internal view returns (address[] memory executors_) {
        uint256 length = numberOfExecutors();
        executors_ = new address[](length);
        for (uint256 i; i < length; i++) executors_[i] = executorAt(i);
    }

    function numberOfExecutors() internal view returns (uint256) {
        return executorStorage().executors.length();
    }

    function gasMargin() internal view returns (uint256) {
        return executorStorage().gasMargin;
    }

    function executorStorage()
        internal
        pure
        returns (ExecutorStorage storage es)
    {
        bytes32 position = _EXECUTOR_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

// https://github.com/mudgen/diamond-3/blob/b009cd08b7822bad727bbcc47aa1b50d8b50f7f0/contracts/libraries/LibDiamond.sol#L1

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import "../../interfaces/standard/IDiamondCut.sol";

// Custom due to incorrect string casting (non UTF-8 formatted)
import {GelatoBytes} from "../../../../lib/GelatoBytes.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function isContractOwner(address _guy) internal view returns (bool) {
        return _guy == contractOwner();
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint16 selectorPosition =
            uint16(
                ds.facetFunctionSelectors[_facetAddress]
                    .functionSelectors
                    .length
            );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(
                _facetAddress,
                "LibDiamondCut: New facet has no code"
            );
            ds.facetFunctionSelectors[_facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress =
                ds.selectorToFacetAndPosition[selector].facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
                selector
            );
            ds.selectorToFacetAndPosition[selector]
                .facetAddress = _facetAddress;
            ds.selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint16 selectorPosition =
            uint16(
                ds.facetFunctionSelectors[_facetAddress]
                    .functionSelectors
                    .length
            );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(
                _facetAddress,
                "LibDiamondCut: New facet has no code"
            );
            ds.facetFunctionSelectors[_facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress =
                ds.selectorToFacetAndPosition[selector].facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(oldFacetAddress, selector);
            // add function
            ds.selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
                selector
            );
            ds.selectorToFacetAndPosition[selector]
                .facetAddress = _facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress =
                ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition =
            ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition =
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length -
                1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector =
                ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    lastSelectorPosition
                ];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                selectorPosition
            ] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition =
                ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress =
                    ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    GelatoBytes.revertWithError(error, "LibDiamondCut:_init:");
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    IChainlinkOracle
} from "../../interfaces/chainlink/IChainlinkOracle.sol";
import {ETH} from "../../constants/CTokens.sol";
import {IOracleAggregator} from "../../interfaces/gelato/IOracleAggregator.sol";
import {IGelato} from "../../core/diamond/interfaces/IGelato.sol";
import {
    ExecutionData,
    SubmissionData,
    MerkleTreePath
} from "../../structs/TaskData.sol";

function _getGelatoGasPrice(address _gasPriceOracle) view returns (uint256) {
    return uint256(IChainlinkOracle(_gasPriceOracle).latestAnswer());
}

// Gelato Oracle price aggregator
function _getExpectedReturnAmount(
    address _inToken,
    address _outToken,
    uint256 _amt,
    address _gelato
) view returns (uint256 buyAmt) {
    (buyAmt, ) = IOracleAggregator(IGelato(_gelato).getOracleAggregator())
        .getExpectedReturnAmount(_amt, _inToken, _outToken);
}

function _getGelatoFee(
    uint256 _gasOverhead,
    uint256 _gasStart,
    address _payToken,
    address _gelato
) view returns (uint256 gelatoFee) {
    gelatoFee =
        (_gasStart - gasleft() + _gasOverhead) *
        _getCappedGasPrice(IGelato(_gelato).getGasPriceOracle());

    if (_payToken == ETH) return gelatoFee;

    // returns purely the ethereum tx fee
    (gelatoFee, ) = IOracleAggregator(IGelato(_gelato).getOracleAggregator())
        .getExpectedReturnAmount(gelatoFee, ETH, _payToken);
}

function _getCappedGasPrice(address _gasPriceOracle) view returns (uint256) {
    uint256 oracleGasPrice = _getGelatoGasPrice(_gasPriceOracle);

    // Use tx.gasprice capped by 1.3x Chainlink Oracle
    return
        tx.gasprice <= ((oracleGasPrice * 130) / 100)
            ? tx.gasprice
            : ((oracleGasPrice * 130) / 100);
}

function _returnFuncSigs(bytes[] memory _datas)
    pure
    returns (bytes4[] memory funcSigs)
{
    funcSigs = new bytes4[](_datas.length);
    for (uint256 i = 0; i < _datas.length; i++) {
        bytes4 selector;
        bytes memory bytesToProcess = _datas[i];
        assembly {
            selector := mload(add(0x20, bytesToProcess))
        }
        funcSigs[i] = selector;
    }
}

function _convertActionDataToSubData(ExecutionData memory _executionData)
    pure
    returns (SubmissionData memory receipt)
{
    return
        SubmissionData(
            _executionData.targets,
            _returnFuncSigs(_executionData.datas),
            _executionData.preCondTargets,
            _executionData.preCondDatas,
            _executionData.postCondTargets,
            _executionData.postCondDatas,
            _executionData.paymentToken,
            _executionData.withFlashloan
        );
}

function _encodeSubmissionData(SubmissionData memory _submissionData)
    pure
    returns (bytes32)
{
    return keccak256(abi.encode(_submissionData));
}

function _computeRootHash(
    bytes32 _receiptHash,
    MerkleTreePath memory _merkleTreePath
) pure returns (bytes32) {
    if (_merkleTreePath.pathHash.length == 0) return _receiptHash;

    _merkleTreePath.pathHash[_merkleTreePath.index] = _receiptHash;

    bytes32 rootHash = _getRootHash(_merkleTreePath.pathHash);
    return rootHash;
}

function _getRootHash(bytes32[] memory _hashes) pure returns (bytes32) {
    bytes32 rootHash = _hashes[0];

    for (uint256 i = 1; i < _hashes.length; i++) {
        rootHash = keccak256(abi.encode(rootHash, _hashes[i]));
    }

    return rootHash;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {ETH, WETH} from "../../constants/CTokens.sol";
import {UNISWAPV2_ROUTER02} from "../../constants/CUniswap.sol";
import {
    IUniswapV2Router02
} from "../../interfaces/dapps/Uniswap/IUniswapV2Router02.sol";
import {
    SafeERC20
} from "../../vendor/openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {
    IERC20
} from "../../vendor/openzeppelin/contracts/token/ERC20/IERC20.sol";

function _transferEthOrToken(
    address payable _to,
    address _paymentToken,
    uint256 _amt
) {
    if (_paymentToken == ETH) {
        (bool success, ) = _to.call{value: _amt}("");
        require(success, "_transfer: fail");
    } else {
        SafeERC20.safeTransfer(IERC20(_paymentToken), _to, _amt);
    }
}

function _swapTokenToEthTransfer(
    address _gelato,
    address _creditToken,
    uint256 _feeAmount,
    uint256 _swapRate
) {
    address[] memory path = new address[](2);
    path[0] = _creditToken;
    path[1] = IUniswapV2Router02(UNISWAPV2_ROUTER02).WETH();
    SafeERC20.safeIncreaseAllowance(
        IERC20(_creditToken),
        UNISWAPV2_ROUTER02,
        _feeAmount
    );
    IUniswapV2Router02(UNISWAPV2_ROUTER02).swapExactTokensForETH(
        _feeAmount, // amountIn
        _swapRate, // amountOutMin
        path, // path
        _gelato, // receiver
        // solhint-disable-next-line not-rely-on-time
        block.timestamp // deadline
    );
}

function _getBalance(address _token, address _account)
    view
    returns (uint256 balance)
{
    return
        _token == ETH ? _account.balance : IERC20(_token).balanceOf(_account);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IChainlinkOracle {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint256);
}

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

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.0;

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function factory() external pure returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function WETH() external pure returns (address);
}

// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity >=0.6.10;
pragma experimental ABIEncoderV2;

import {
    Action,
    Provider,
    Task,
    DataFlow,
    TaskReceipt
} from "@gelatonetwork/core/contracts/gelato_core/interfaces/IGelatoCore.sol";

// TaskSpec - Will be whitelised by providers and selected by users
struct TaskSpec {
    IGelatoCondition[] conditions; // Address: optional AddressZero for self-conditional actions
    Action[] actions;
    uint256 gasPriceCeil;
}

interface IGelatoV1 {
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
    ) external view returns (string memory);

    /// @notice API to submit a single Task.
    /// @dev You can let users submit multiple tasks at once by batching calls to this.
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _task A Gelato Task object: provider, conditions, actions.
    /// @param _expiryDate From then on the task cannot be executed. 0 for infinity.
    function submitTask(
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    ) external;

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
    ) external;

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
    ) external;

    // ================  Exec Suite =========================
    /// @notice Off-chain API for executors to check, if a TaskReceipt is executable
    /// @dev GelatoCore checks this during execution, in order to safeguard the Conditions
    /// @param _TR TaskReceipt, consisting of user task, user proxy address and id
    /// @param _gasLimit Task.selfProviderGasLimit is used for SelfProviders. All other
    ///  Providers must use gelatoMaxGas. If the _gasLimit is used by an Executor and the
    ///  tx reverts, a refund is paid by the Provider and the TaskReceipt is annulated.
    /// @param _execTxGasPrice Must be used by Executors. Gas Price fed by gelatoCore's
    ///  Gas Price Oracle. Executors can query the current gelatoGasPrice from events.
    function canExec(
        TaskReceipt calldata _TR,
        uint256 _gasLimit,
        uint256 _execTxGasPrice
    ) external view returns (string memory);

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
    function hashTaskReceipt(TaskReceipt calldata _TR)
        external
        pure
        returns (bytes32);

    // ================  Getters =========================
    /// @notice Returns the taskReceiptId of the last TaskReceipt submitted
    /// @return currentId currentId, last TaskReceiptId submitted
    function currentTaskReceiptId() external view returns (uint256);

    /// @notice Returns computed taskReceipt hash, used to check for taskReceipt validity
    /// @param _taskReceiptId Id of taskReceipt emitted in submission event
    /// @return hash of taskReceipt
    function taskReceiptHash(uint256 _taskReceiptId)
        external
        view
        returns (bytes32);

    /// @notice Stake on Gelato to become a whitelisted executor
    /// @dev Msg.value has to be >= minExecutorStake
    function stakeExecutor() external payable;

    /// @notice Unstake on Gelato to become de-whitelisted and withdraw minExecutorStake
    function unstakeExecutor() external;

    /// @notice Re-assigns multiple providers to other executors
    /// @dev Executors must re-assign all providers before being able to unstake
    /// @param _providers List of providers to re-assign
    /// @param _newExecutor Address of new executor to assign providers to
    function multiReassignProviders(
        address[] calldata _providers,
        address _newExecutor
    ) external;

    /// @notice Withdraw excess Execur Stake
    /// @dev Can only be called if executor is isExecutorMinStaked
    /// @param _withdrawAmount Amount to withdraw
    /// @return Amount that was actually withdrawn
    function withdrawExcessExecutorStake(uint256 _withdrawAmount)
        external
        returns (uint256);

    // =========== GELATO PROVIDER APIs ==============

    /// @notice Validation that checks whether Task Spec is being offered by the selected provider
    /// @dev Checked in submitTask(), unless provider == userProxy
    /// @param _provider Address of selected provider
    /// @param _taskSpec Task Spec
    /// @return Expected to return "OK"
    function isTaskSpecProvided(address _provider, TaskSpec calldata _taskSpec)
        external
        view
        returns (string memory);

    /// @notice Validates that provider has provider module whitelisted + conducts isProvided check in ProviderModule
    /// @dev Checked in submitTask() if provider == userProxy
    /// @param _userProxy userProxy passed by GelatoCore during submission and exec
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _task Task defined in IGelatoCore
    /// @return Expected to return "OK"
    function providerModuleChecks(
        address _userProxy,
        Provider calldata _provider,
        Task calldata _task
    ) external view returns (string memory);

    /// @notice Validate if provider module and seleced TaskSpec is whitelisted by provider
    /// @dev Combines "isTaskSpecProvided" and providerModuleChecks
    /// @param _userProxy userProxy passed by GelatoCore during submission and exec
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _task Task defined in IGelatoCore
    /// @return res Expected to return "OK"
    function isTaskProvided(
        address _userProxy,
        Provider calldata _provider,
        Task calldata _task
    ) external view returns (string memory res);

    /// @notice Validate if selected TaskSpec is whitelisted by provider and that current gelatoGasPrice is below GasPriceCeil
    /// @dev If gasPriceCeil is != 0, Task Spec is whitelisted
    /// @param _userProxy userProxy passed by GelatoCore during submission and exec
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _task Task defined in IGelatoCore
    /// @param _gelatoGasPrice Task Receipt defined in IGelatoCore
    /// @return res Expected to return "OK"
    function providerCanExec(
        address _userProxy,
        Provider calldata _provider,
        Task calldata _task,
        uint256 _gelatoGasPrice
    ) external view returns (string memory res);

    // =========== PROVIDER STATE WRITE APIs ==============
    // Provider Funding
    /// @notice Deposit ETH as provider on Gelato
    /// @param _provider Address of provider who receives ETH deposit
    function provideFunds(address _provider) external payable;

    /// @notice Withdraw provider funds from gelato
    /// @param _withdrawAmount Amount
    /// @return amount that will be withdrawn
    function unprovideFunds(uint256 _withdrawAmount) external returns (uint256);

    /// @notice Assign executor as provider
    /// @param _executor Address of new executor
    function providerAssignsExecutor(address _executor) external;

    /// @notice Assign executor as previous selected executor
    /// @param _provider Address of provider whose executor to change
    /// @param _newExecutor Address of new executor
    function executorAssignsExecutor(address _provider, address _newExecutor)
        external;

    // (Un-)provide Task Spec

    /// @notice Whitelist TaskSpecs (A combination of a Condition, Action(s) and a gasPriceCeil) that users can select from
    /// @dev If gasPriceCeil is == 0, Task Spec will be executed at any gas price (no ceil)
    /// @param _taskSpecs Task Receipt List defined in IGelatoCore
    function provideTaskSpecs(TaskSpec[] calldata _taskSpecs) external;

    /// @notice De-whitelist TaskSpecs (A combination of a Condition, Action(s) and a gasPriceCeil) that users can select from
    /// @dev If gasPriceCeil was set to NO_CEIL, Input NO_CEIL constant as GasPriceCeil
    /// @param _taskSpecs Task Receipt List defined in IGelatoCore
    function unprovideTaskSpecs(TaskSpec[] calldata _taskSpecs) external;

    /// @notice Update gasPriceCeil of selected Task Spec
    /// @param _taskSpecHash Result of hashTaskSpec()
    /// @param _gasPriceCeil New gas price ceil for Task Spec
    function setTaskSpecGasPriceCeil(
        bytes32 _taskSpecHash,
        uint256 _gasPriceCeil
    ) external;

    // Provider Module
    /// @notice Whitelist new provider Module(s)
    /// @param _modules Addresses of the modules which will be called during providerModuleChecks()
    function addProviderModules(IGelatoProviderModule[] calldata _modules)
        external;

    /// @notice De-Whitelist new provider Module(s)
    /// @param _modules Addresses of the modules which will be removed
    function removeProviderModules(IGelatoProviderModule[] calldata _modules)
        external;

    // Batch (un-)provide

    /// @notice Whitelist new executor, TaskSpec(s) and Module(s) in one tx
    /// @param _executor Address of new executor of provider
    /// @param _taskSpecs List of Task Spec which will be whitelisted by provider
    /// @param _modules List of module addresses which will be whitelisted by provider
    function multiProvide(
        address _executor,
        TaskSpec[] calldata _taskSpecs,
        IGelatoProviderModule[] calldata _modules
    ) external payable;

    /// @notice De-Whitelist TaskSpec(s), Module(s) and withdraw funds from gelato in one tx
    /// @param _withdrawAmount Amount to withdraw from ProviderFunds
    /// @param _taskSpecs List of Task Spec which will be de-whitelisted by provider
    /// @param _modules List of module addresses which will be de-whitelisted by provider
    function multiUnprovide(
        uint256 _withdrawAmount,
        TaskSpec[] calldata _taskSpecs,
        IGelatoProviderModule[] calldata _modules
    ) external;

    // =========== PROVIDER STATE READ APIs ==============
    // Provider Funding

    /// @notice Get balance of provider
    /// @param _provider Address of provider
    /// @return Provider Balance
    function providerFunds(address _provider) external view returns (uint256);

    /// @notice Get min stake required by all providers for executors to call exec
    /// @param _gelatoMaxGas Current gelatoMaxGas
    /// @param _gelatoGasPrice Current gelatoGasPrice
    /// @return How much provider balance is required for executor to submit exec tx
    function minExecProviderFunds(
        uint256 _gelatoMaxGas,
        uint256 _gelatoGasPrice
    ) external view returns (uint256);

    /// @notice Check if provider has sufficient funds for executor to call exec
    /// @param _provider Address of provider
    /// @param _gelatoMaxGas Currentt gelatoMaxGas
    /// @param _gelatoGasPrice Current gelatoGasPrice
    /// @return Whether provider is liquid (true) or not (false)
    function isProviderLiquid(
        address _provider,
        uint256 _gelatoMaxGas,
        uint256 _gelatoGasPrice
    ) external view returns (bool);

    // Executor Stake

    /// @notice Get balance of executor
    /// @param _executor Address of executor
    /// @return Executor Balance
    function executorStake(address _executor) external view returns (uint256);

    /// @notice Check if executor has sufficient stake on gelato
    /// @param _executor Address of provider
    /// @return Whether executor has sufficient stake (true) or not (false)
    function isExecutorMinStaked(address _executor)
        external
        view
        returns (bool);

    /// @notice Get executor of provider
    /// @param _provider Address of provider
    /// @return Provider's executor
    function executorByProvider(address _provider)
        external
        view
        returns (address);

    /// @notice Get num. of providers which haved assigned an executor
    /// @param _executor Address of executor
    /// @return Count of how many providers assigned the executor
    function executorProvidersCount(address _executor)
        external
        view
        returns (uint256);

    /// @notice Check if executor has one or more providers assigned
    /// @param _executor Address of provider
    /// @return Where 1 or more providers have assigned the executor
    function isExecutorAssigned(address _executor) external view returns (bool);

    // Task Spec and Gas Price Ceil
    /// @notice The maximum gas price the transaction will be executed with
    /// @param _provider Address of provider
    /// @param _taskSpecHash Hash of provider TaskSpec
    /// @return Max gas price an executor will execute the transaction with in wei
    function taskSpecGasPriceCeil(address _provider, bytes32 _taskSpecHash)
        external
        view
        returns (uint256);

    /// @notice Returns the hash of the formatted TaskSpec.
    /// @dev The action.data field of each Action is stripped before hashing.
    /// @param _taskSpec TaskSpec
    /// @return keccak256 hash of encoded condition address and Action List
    function hashTaskSpec(TaskSpec calldata _taskSpec)
        external
        view
        returns (bytes32);

    /// @notice Constant used to specify the highest gas price available in the gelato system
    /// @dev Input 0 as gasPriceCeil and it will be assigned to NO_CEIL
    /// @return MAX_UINT
    function NO_CEIL() external pure returns (uint256);

    // Providers' Module Getters

    /// @notice Check if inputted module is whitelisted by provider
    /// @param _provider Address of provider
    /// @param _module Address of module
    /// @return true if it is whitelisted
    function isModuleProvided(address _provider, IGelatoProviderModule _module)
        external
        view
        returns (bool);

    /// @notice Get all whitelisted provider modules from a given provider
    /// @param _provider Address of provider
    /// @return List of whitelisted provider modules
    function providerModules(address _provider)
        external
        view
        returns (IGelatoProviderModule[] memory);

    // State Writing

    /// @notice Assign new gas price oracle
    /// @dev Only callable by sysAdmin
    /// @param _newOracle Address of new oracle
    function setGelatoGasPriceOracle(address _newOracle) external;

    /// @notice Assign new gas price oracle
    /// @dev Only callable by sysAdmin
    /// @param _requestData The encoded payload for the staticcall to the oracle.
    function setOracleRequestData(bytes calldata _requestData) external;

    /// @notice Assign new maximum gas limit providers can consume in executionWrapper()
    /// @dev Only callable by sysAdmin
    /// @param _newMaxGas New maximum gas limit
    function setGelatoMaxGas(uint256 _newMaxGas) external;

    /// @notice Assign new interal gas limit requirement for exec()
    /// @dev Only callable by sysAdmin
    /// @param _newRequirement New internal gas requirement
    function setInternalGasRequirement(uint256 _newRequirement) external;

    /// @notice Assign new minimum executor stake
    /// @dev Only callable by sysAdmin
    /// @param _newMin New minimum executor stake
    function setMinExecutorStake(uint256 _newMin) external;

    /// @notice Assign new success share for executors to receive after successful execution
    /// @dev Only callable by sysAdmin
    /// @param _percentage New % success share of total gas consumed
    function setExecutorSuccessShare(uint256 _percentage) external;

    /// @notice Assign new success share for sysAdmin to receive after successful execution
    /// @dev Only callable by sysAdmin
    /// @param _percentage New % success share of total gas consumed
    function setSysAdminSuccessShare(uint256 _percentage) external;

    /// @notice Withdraw sysAdmin funds
    /// @dev Only callable by sysAdmin
    /// @param _amount Amount to withdraw
    /// @param _to Address to receive the funds
    function withdrawSysAdminFunds(uint256 _amount, address payable _to)
        external
        returns (uint256);

    // State Reading
    /// @notice Unaccounted tx overhead that will be refunded to executors
    function EXEC_TX_OVERHEAD() external pure returns (uint256);

    /// @notice Addess of current Gelato Gas Price Oracle
    function gelatoGasPriceOracle() external view returns (address);

    /// @notice Getter for oracleRequestData state variable
    function oracleRequestData() external view returns (bytes memory);

    /// @notice Gas limit an executor has to submit to get refunded even if actions revert
    function gelatoMaxGas() external view returns (uint256);

    /// @notice Internal gas limit requirements ti ensure executor payout
    function internalGasRequirement() external view returns (uint256);

    /// @notice Minimum stake required from executors
    function minExecutorStake() external view returns (uint256);

    /// @notice % Fee executors get as a reward for a successful execution
    function executorSuccessShare() external view returns (uint256);

    /// @notice Total % Fee executors and sysAdmin collectively get as a reward for a successful execution
    /// @dev Saves a state read
    function totalSuccessShare() external view returns (uint256);

    /// @notice Get total fee providers pay executors for a successful execution
    /// @param _gas Gas consumed by transaction
    /// @param _gasPrice Current gelato gas price
    function executorSuccessFee(uint256 _gas, uint256 _gasPrice)
        external
        view
        returns (uint256);

    /// @notice % Fee sysAdmin gets as a reward for a successful execution
    function sysAdminSuccessShare() external view returns (uint256);

    /// @notice Get total fee providers pay sysAdmin for a successful execution
    /// @param _gas Gas consumed by transaction
    /// @param _gasPrice Current gelato gas price
    function sysAdminSuccessFee(uint256 _gas, uint256 _gasPrice)
        external
        view
        returns (uint256);

    /// @notice Get sysAdminds funds
    function sysAdminFunds() external view returns (uint256);
}

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
    function ok(
        uint256 _taskReceiptId,
        bytes calldata _conditionData,
        uint256 _cycleId
    ) external view returns (string memory);
}

/// @notice all the APIs and events of GelatoActionsStandard
/// @dev all the APIs are implemented inside GelatoActionsStandard
interface IGelatoAction {
    /// @notice Providers can use this for pre-execution sanity checks, to prevent reverts.
    /// @dev GelatoCore checks this in canExec and passes the parameters.
    /// @param _taskReceiptId The id of the task from which all arguments are passed.
    /// @param _userProxy The userProxy of the task. Often address(this) for delegatecalls.
    /// @param _actionData The encoded payload to be used in the Action.
    /// @param _dataFlow The dataFlow of the Action.
    /// @param _value A special param for ETH sending Actions. If the Action sends ETH
    ///  in its Action function implementation, one should expect msg.value therein to be
    ///  equal to _value. So Providers can check in termsOk that a valid ETH value will
    ///  be used because they also have access to the same value when encoding the
    ///  execPayload on their ProviderModule.
    /// @param _cycleId For tasks that are part of a Cycle.
    /// @return Returns OK, if Task can be executed safely according to the Provider's
    ///  terms laid out in this function implementation.
    function termsOk(
        uint256 _taskReceiptId,
        address _userProxy,
        bytes calldata _actionData,
        DataFlow _dataFlow,
        uint256 _value,
        uint256 _cycleId
    ) external view returns (string memory);
}

interface IGelatoProviderModule {
    /// @notice Check if provider agrees to pay for inputted task receipt
    /// @dev Enables arbitrary checks by provider
    /// @param _userProxy The smart contract account of the user who submitted the Task.
    /// @param _provider The account of the Provider who uses the ProviderModule.
    /// @param _task Gelato Task to be executed.
    /// @return "OK" if provider agrees
    function isProvided(
        address _userProxy,
        address _provider,
        Task calldata _task
    ) external view returns (string memory);

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
    ) external view returns (bytes memory, bool checkReturndata);

    /// @notice Called by GelatoCore.exec to verifiy that no revert happend on userProxy
    /// @dev If a caught revert is detected, this fn should revert with the detected error
    /// @param _proxyReturndata Data from GelatoCore._exec.userProxy.call(execPayload)
    function execRevertCheck(bytes calldata _proxyReturndata) external pure;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Interface of the Oracle Aggregator Contract
 */
interface IOracleAggregator {
    function getExpectedReturnAmount(
        uint256 amount,
        address tokenAddressA,
        address tokenAddressB
    ) external view returns (uint256 returnAmount, uint256 decimals);
}

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.0;

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

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.0;

library GelatoString {
    function startsWithOK(string memory _str) internal pure returns (bool) {
        if (
            bytes(_str).length >= 2 &&
            bytes(_str)[0] == "O" &&
            bytes(_str)[1] == "K"
        ) return true;
        return false;
    }

    function revertWithInfo(string memory _error, string memory _tracingInfo)
        internal
        pure
    {
        revert(string(abi.encodePacked(_tracingInfo, _error)));
    }

    function prefix(string memory _second, string memory _first)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_first, _second));
    }

    function suffix(string memory _first, string memory _second)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_first, _second));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

struct SubmissionData {
    address[] targets;
    bytes4[] selectors;
    address[] preCondTargets;
    bytes[] preCondDatas;
    address[] postCondTargets;
    bytes[] postCondDatas;
    address paymentToken;
    bool withFlashloan;
}

struct MerkleTreePath {
    bytes32[] pathHash;
    uint256 index;
}

struct Routes {
    address[] targets;
    bytes4[] selectors;
    address[] preCondTargets;
    bytes4[] preCondDatasSelectors;
    address[] postCondTargets;
    bytes4[] postCondDatasSelectors;
}

struct ExecutionData {
    address[] targets;
    bytes[] datas;
    address[] preCondTargets;
    bytes[] preCondDatas;
    address[] postCondTargets;
    bytes[] postCondDatas;
    address paymentToken;
    bool withFlashloan;
    uint256 execFee;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    function decimals() external view returns (uint8 digits);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
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
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

pragma solidity >=0.6.0;

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
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
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
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
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
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
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
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
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
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
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
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
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
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
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
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}