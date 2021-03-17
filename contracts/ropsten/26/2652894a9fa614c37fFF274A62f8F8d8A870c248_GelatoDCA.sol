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

import {IChainlinkOracle} from "../interfaces/chainlink/IChainlinkOracle.sol";

IChainlinkOracle constant GELATO_GAS_PRICE_ORACLE = IChainlinkOracle(
    0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C
);

string constant OK = "OK";

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

// InstaDapp
address constant INSTA_INDEX = 0x2971AdFa57b20E5a416aE5a708A8655A9c74f723;
address constant INSTA_LIST = 0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb;
address constant INSTA_MEMORY = 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F;

// Connectors
address constant CONNECT_MAKER = 0xac02030d8a8F49eD04b2f52C394D3F901A10F8A9;
address constant CONNECT_COMPOUND = 0x07F81230d73a78f63F0c2A3403AD281b067d28F8;
address constant CONNECT_AAVE_V2 = 0xBF6E4331ffd02F7043e62788FD272aeFc712f5ee;
address constant CONNECT_UNISWAP = 0x62EbfF47B2Ba3e47796efaE7C51676762dC961c0;
address constant CONNECT_KYBER = 0x7043FC2E21865c091EEaE37C38E3d82BcCDF5D5C;
address constant INSTA_POOL_V2 = 0xeB4bf86589f808f90EEC8e964dBF16Bd4D284905;

// Tokens
address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

// Resolvers
address constant INSTA_MAKER_RESOLVER = 0x0A7008B38E7015F8C36A49eEbc32513ECA8801E5;
address constant KYBER_RESOLVER = 0x8240b601d9B565e2BefaA3DA82Cc984E76cB3499;

// Insta Mapping
address constant INSTA_MAPPING = 0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88;

uint256 constant ROUTE_1_TOLERANCE = 1005e15;

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

address constant ORACLE_AGGREGATOR = 0x64f31D46C52bBDe223D863B11dAb9327aB1414E9;

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

import {IDiamondCut} from "./standard/IDiamondCut.sol";
import {IDiamondLoupe} from "./standard/IDiamondLoupe.sol";
import {
    TaskReceipt
} from "@gelatonetwork/core/contracts/gelato_core/interfaces/IGelatoCore.sol";

// solhint-disable ordering

/// @dev includes the interfaces of all facets
interface IGelatoDiamond {
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

    function concurrentCanExec(address _service, uint256 _buffer)
        external
        view
        returns (bool);

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
    event LogExecSuccess(address indexed _service, uint256 _fee);
    event LogExecFailed(address indexed _service, string indexed revertMsg);

    function addExecutors(address[] calldata _executors) external;

    function removeExecutors(address[] calldata _executors) external;

    function setGasMargin(uint256 _gasMargin) external;

    function setExecProfitMargin(uint256 _gasMargin) external;

    function exec(
        address _service,
        bytes calldata _data,
        address _feeToken
    ) external;

    function gasEstimateInToken(
        address _service,
        bytes calldata _data,
        address _feeToken
    ) external returns (uint256, uint256);

    function canExec(address _service, address _executor)
        external
        view
        returns (bool);

    function isExecutor(address _executor) external view returns (bool);

    function executors() external view returns (address[] memory);

    // ########## ServiceFacet #########
    event LogList(address indexed _service);
    event LogUnlist(address indexed _service);

    function listServices(address[] calldata _services) external;

    function unlistServices(address[] calldata _services) external;

    function isListedService(address _service) external view returns (bool);

    function listedServices() external view returns (address[] memory);

    // ########## V1ConcurrentMultiCanExecFacet #########
    struct Response {
        uint256 taskReceiptId;
        uint256 taskGasLimit;
        string response;
    }

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    IERC20,
    SafeERC20
} from "../../vendor/openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {
    ReentrancyGuard
} from "../../vendor/openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {UniAndKyberSwaps} from "./UniAndKyberSwaps.sol";
import {
    IChainlinkOracle
} from "../../interfaces/chainlink/IChainlinkOracle.sol";
import {IOracleAggregator} from "../../interfaces/gelato/IOracleAggregator.sol";
import {ITaskStorage} from "../../interfaces/gelato/ITaskStorage.sol";
import {
    IUniswapV2Router02
} from "../../interfaces/dapps/Uniswap/IUniswapV2Router02.sol";
import {SimpleServiceStandard} from "../standards/SimpleServiceStandard.sol";
import {
    ReentrancyGuard
} from "../../vendor/openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {_transferEthAndToken} from "../../functions/gelato/FPayment.sol";
import {ETH} from "../../constants/CTokens.sol";
import {Fee} from "../../structs/SGelato.sol";
import {IGelatoDiamond} from "../diamond/interfaces/IGelatoDiamond.sol";

contract GelatoDCA is SimpleServiceStandard, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Order {
        address user;
        address inToken;
        address outToken;
        uint256 amountPerTrade;
        uint256 nTradesLeft;
        uint256 minSlippage;
        uint256 maxSlippage;
        uint256 delay;
        uint256 lastExecutionTime;
        bytes32 cycleId;
    }

    enum Dex {KYBER, UNISWAP, SUSHISWAP}

    bytes public constant HINT = "";
    uint256 public constant TOTAL_BPS = 10000;

    UniAndKyberSwaps public immutable smartWalletSwap;
    IUniswapV2Router02 public immutable uniRouterV2;
    IUniswapV2Router02 public immutable sushiRouterV2;

    event LogTaskSubmitted(uint256 indexed taskId, Order order);
    event LogTaskCancelled(uint256 indexed taskId, Order order);
    event LogTaskUpdated(uint256 indexed taskId, Order order);
    event LogDCATrade(uint256 indexed taskId, Order order, uint256 amountOut);

    constructor(
        UniAndKyberSwaps _smartWalletSwap,
        IUniswapV2Router02 _uniRouterV2,
        IUniswapV2Router02 _sushiRouterV2,
        address _gelato
    ) SimpleServiceStandard(_gelato) {
        smartWalletSwap = _smartWalletSwap;
        uniRouterV2 = _uniRouterV2;
        sushiRouterV2 = _sushiRouterV2;
    }

    function submit(
        address inToken,
        address outToken,
        uint256 amountPerTrade,
        uint256 nTradesLeft,
        uint256 minSlippage,
        uint256 maxSlippage,
        uint256 delay,
        bytes32 cycleId
    ) external payable {
        if (inToken == ETH) {
            require(
                msg.value == amountPerTrade * nTradesLeft,
                "GelatoDCA.submit: mismatching amount of ETH deposited"
            );
        }
        Order memory order =
            Order({
                user: msg.sender,
                inToken: inToken,
                outToken: outToken,
                amountPerTrade: amountPerTrade,
                nTradesLeft: nTradesLeft,
                minSlippage: minSlippage,
                maxSlippage: maxSlippage,
                delay: delay, // solhint-disable-next-line not-rely-on-time
                lastExecutionTime: block.timestamp - delay,
                cycleId: cycleId
            });

        // store order
        _storeOrder(order, msg.sender);
    }

    function cancel(Order calldata _order, uint256 _id) external nonReentrant {
        _removeTask(abi.encode(_order), _id, msg.sender);
        if (_order.inToken == ETH) {
            uint256 refundAmount = _order.amountPerTrade * _order.nTradesLeft;
            (bool success, ) = _order.user.call{value: refundAmount}("");
            require(success, "GelatoDCA.cancel: Could not refund ETH");
        }

        emit LogTaskCancelled(_id, _order);
    }

    // solhint-disable-next-line function-max-lines
    function editNumTrades(
        Order calldata _order,
        uint256 _id,
        uint256 _newNumTradesLeft
    ) external payable nonReentrant {
        require(
            _order.nTradesLeft != _newNumTradesLeft,
            "GelatoDCA.editNumTrades: order does not need update"
        );
        Order memory newOrder =
            Order({
                user: _order.user,
                inToken: _order.inToken,
                outToken: _order.outToken,
                amountPerTrade: _order.amountPerTrade,
                nTradesLeft: _newNumTradesLeft, // the only updateable field for now
                minSlippage: _order.minSlippage,
                maxSlippage: _order.maxSlippage,
                delay: _order.delay,
                lastExecutionTime: _order.lastExecutionTime,
                cycleId: _order.cycleId
            });
        _updateTask(abi.encode(_order), abi.encode(newOrder), _id, msg.sender);
        if (_order.inToken == ETH) {
            if (_order.nTradesLeft > _newNumTradesLeft) {
                uint256 refundAmount =
                    _order.amountPerTrade *
                        (_order.nTradesLeft - _newNumTradesLeft);
                (bool success, ) = _order.user.call{value: refundAmount}("");
                require(success, "GelatoDCA.editNumTrades: revert on transfer");
            } else {
                uint256 topUpAmount =
                    _order.amountPerTrade *
                        (_newNumTradesLeft - _order.nTradesLeft);

                require(
                    topUpAmount == msg.value,
                    "GelatoDCA.editNumTrades: mismatching amount of ETH deposited"
                );
            }
        }

        emit LogTaskUpdated(_id, newOrder);
    }

    function exec(
        Order calldata _order,
        uint256 _id,
        Dex _protocol,
        Fee memory _fee,
        address[] calldata _tradePath
    )
        external
        gelatofy(
            _fee.isOutToken ? _order.outToken : _order.inToken,
            _order.user,
            abi.encode(_order),
            _id,
            _fee.amount,
            _fee.swapRate
        )
    {
        // task cycle logic
        if (_order.nTradesLeft > 0) _updateAndSubmitNextTask(_order);

        // action exec
        uint256 amountOut;
        if (_protocol == Dex.KYBER) {
            amountOut = _actionKyber(_order, _fee.amount, _fee.isOutToken);
        } else {
            amountOut = _actionUniOrSushi(
                _order,
                _protocol,
                _tradePath,
                _fee.amount,
                _fee.isOutToken
            );
        }

        if (_fee.isOutToken) {
            _transferEthAndToken(
                payable(_order.user),
                _order.outToken,
                amountOut
            );
        }

        emit LogDCATrade(_id, _order, amountOut);
    }

    function isTaskSubmitted(Order calldata _order, uint256 _id)
        external
        view
        returns (bool)
    {
        return verifyTask(abi.encode(_order), _id, _order.user);
    }

    function getMinReturn(Order memory _order)
        public
        view
        returns (uint256 minReturn)
    {
        // 4. Rate Check
        (uint256 idealReturn, ) =
            IOracleAggregator(IGelatoDiamond(gelato).getOracleAggregator())
                .getExpectedReturnAmount(
                _order.amountPerTrade,
                _order.inToken,
                _order.outToken
            );

        // check time (reverts if block.timestamp is below execTime)
        uint256 timeSinceCanExec =
            // solhint-disable-next-line not-rely-on-time
            block.timestamp - (_order.lastExecutionTime + _order.delay);

        uint256 minSlippageFactor = TOTAL_BPS - _order.minSlippage;
        uint256 maxSlippageFactor = TOTAL_BPS - _order.maxSlippage;
        uint256 slippage;
        if (minSlippageFactor > timeSinceCanExec) {
            slippage = minSlippageFactor - timeSinceCanExec;
        }

        if (maxSlippageFactor > slippage) {
            slippage = maxSlippageFactor;
        }

        minReturn = (idealReturn * slippage) / TOTAL_BPS;
    }

    // ############# PRIVATE #############
    function _actionKyber(
        Order memory _order,
        uint256 _fee,
        bool _outTokenFee
    ) private returns (uint256 received) {
        (
            uint256 ethToSend,
            uint256 sellAmount,
            uint256 minReturn,
            address payable receiver
        ) = _preExec(_order, _fee, _outTokenFee);

        received = smartWalletSwap.swapKyber{value: ethToSend}(
            IERC20(_order.inToken),
            IERC20(_order.outToken),
            sellAmount,
            minReturn / _order.amountPerTrade,
            receiver,
            HINT,
            false
        );

        if (_outTokenFee) {
            received = received - _fee;
        }
    }

    function _actionUniOrSushi(
        Order memory _order,
        Dex _protocol,
        address[] memory _tradePath,
        uint256 _fee,
        bool _outTokenFee
    ) private returns (uint256 received) {
        (
            uint256 ethToSend,
            uint256 sellAmount,
            uint256 minReturn,
            address payable receiver
        ) = _preExec(_order, _fee, _outTokenFee);

        require(
            _order.inToken == _tradePath[0] &&
                _order.outToken == _tradePath[_tradePath.length - 1],
            "GelatoDCA.action: trade path does not match order."
        );

        received = smartWalletSwap.swapUniswap{value: ethToSend}(
            _protocol == Dex.UNISWAP ? uniRouterV2 : sushiRouterV2,
            sellAmount,
            minReturn,
            _tradePath,
            receiver,
            false
        );

        if (_outTokenFee) {
            received = received - _fee;
        }
    }

    function _preExec(
        Order memory _order,
        uint256 _fee,
        bool _outTokenFee
    )
        private
        returns (
            uint256 ethToSend,
            uint256 sellAmount,
            uint256 minReturn,
            address payable receiver
        )
    {
        if (_outTokenFee) {
            receiver = payable(this);
            minReturn = getMinReturn(_order) + _fee;
            sellAmount = _order.amountPerTrade;
        } else {
            receiver = payable(_order.user);
            minReturn = getMinReturn(_order);
            sellAmount = _order.amountPerTrade - _fee;
        }

        if (_order.inToken != ETH) {
            IERC20(_order.inToken).safeTransferFrom(
                _order.user,
                address(this),
                _order.amountPerTrade
            );
            IERC20(_order.inToken).safeIncreaseAllowance(
                address(smartWalletSwap),
                sellAmount
            );
        } else {
            ethToSend = sellAmount;
        }
    }

    function _updateAndSubmitNextTask(Order memory _order) private {
        // update next order
        _order.nTradesLeft = _order.nTradesLeft - 1;
        // solhint-disable-next-line not-rely-on-time
        _order.lastExecutionTime = block.timestamp;

        _storeOrder(_order, _order.user);
    }

    function _storeOrder(Order memory _order, address _user) private {
        uint256 id = _storeTask(abi.encode(_order), _user);
        emit LogTaskSubmitted(id, _order);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    IERC20,
    SafeERC20
} from "../../vendor/openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "../../vendor/openzeppelin/contracts/math/SafeMath.sol";
import "../../dapps/krystal/burnHelper/IBurnGasHelper.sol";
import "../../interfaces/krystal/IKyberProxy.sol";
import "../../interfaces/dapps/Uniswap/IUniswapV2Router02.sol";
import "../../interfaces/krystal/IGasToken.sol";

abstract contract Utils {
    uint256 internal constant _MAX_AMOUNT = 2**256 - 1;
    uint256 internal constant _MAX_DECIMALS = 18;
    uint256 internal constant _MAX_QTY = (10**28);
    uint256 internal constant _PRECISION = (10**18);
    uint256 internal constant _MAX_RATE = (_PRECISION * 10**7);

    IERC20 internal constant _ETH_TOKEN_ADDRESS =
        IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function _calcDestAmount(
        IERC20 src,
        IERC20 dest,
        uint256 srcAmount,
        uint256 rate
    ) internal view returns (uint256) {
        return
            _calcDstQty(srcAmount, _getDecimals(src), _getDecimals(dest), rate);
    }

    function _calcDstQty(
        uint256 srcQty,
        uint256 srcDecimals,
        uint256 dstDecimals,
        uint256 rate
    ) internal pure returns (uint256) {
        require(srcQty <= _MAX_QTY, "srcQty > _MAX_QTY");
        require(rate <= _MAX_RATE, "rate > _MAX_RATE");

        if (dstDecimals >= srcDecimals) {
            require(
                (dstDecimals - srcDecimals) <= _MAX_DECIMALS,
                "dst - src > _MAX_DECIMALS"
            );
            return
                (srcQty * rate * (10**(dstDecimals - srcDecimals))) /
                _PRECISION;
        } else {
            require(
                (srcDecimals - dstDecimals) <= _MAX_DECIMALS,
                "src - dst > _MAX_DECIMALS"
            );
            return
                (srcQty * rate) /
                (_PRECISION * (10**(srcDecimals - dstDecimals)));
        }
    }

    function _calcRateFromQty(
        uint256 srcAmount,
        uint256 destAmount,
        uint256 srcDecimals,
        uint256 dstDecimals
    ) internal pure returns (uint256) {
        require(srcAmount <= _MAX_QTY, "srcAmount > _MAX_QTY");
        require(destAmount <= _MAX_QTY, "destAmount > _MAX_QTY");

        if (dstDecimals >= srcDecimals) {
            require(
                (dstDecimals - srcDecimals) <= _MAX_DECIMALS,
                "dst - src > _MAX_DECIMALS"
            );
            return ((destAmount * _PRECISION) /
                ((10**(dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require(
                (srcDecimals - dstDecimals) <= _MAX_DECIMALS,
                "src - dst > _MAX_DECIMALS"
            );
            return ((destAmount *
                _PRECISION *
                (10**(srcDecimals - dstDecimals))) / srcAmount);
        }
    }

    function _getDecimals(IERC20 token)
        internal
        view
        returns (uint256 tokenDecimals)
    {
        // return token decimals if has constant value
        tokenDecimals = _getDecimalsConstant(token);
        if (tokenDecimals > 0) return tokenDecimals;

        // moreover, very possible that old tokens have decimals 0
        // these tokens will just have higher gas fees.
        return token.decimals();
    }

    function _getDecimalsConstant(IERC20 token)
        internal
        pure
        returns (uint256)
    {
        if (token == _ETH_TOKEN_ADDRESS) {
            return _MAX_DECIMALS;
        }

        return 0;
    }
}

contract UniAndKyberSwaps is Utils {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(address => bool) public uniRouters;
    IKyberProxy public immutable kyberProxy;
    IBurnGasHelper public immutable burnGasHelper;

    constructor(
        address _kyberProxy,
        address[] memory _uniRouters,
        address _burnGasHelper
    ) {
        kyberProxy = IKyberProxy(_kyberProxy);
        for (uint256 i = 0; i < _uniRouters.length; i++) {
            uniRouters[_uniRouters[i]] = true;
        }
        burnGasHelper = IBurnGasHelper(_burnGasHelper);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function swapKyber(
        IERC20 src,
        IERC20 dest,
        uint256 srcAmount,
        uint256 minConversionRate,
        address payable recipient,
        bytes calldata hint,
        bool useGasToken
    ) external payable returns (uint256 destAmount) {
        uint256 gasBefore = useGasToken ? gasleft() : 0;
        destAmount = _doKyberTrade(
            src,
            dest,
            srcAmount,
            minConversionRate,
            recipient,
            hint
        );
        uint256 numGasBurns = 0;
        // burn gas token if needed
        if (useGasToken) {
            numGasBurns = _burnGasTokensAfter(gasBefore);
        }
    }

    function swapUniswap(
        IUniswapV2Router02 router,
        uint256 srcAmount,
        uint256 minDestAmount,
        address[] calldata tradePath,
        address payable recipient,
        bool useGasToken
    ) external payable returns (uint256 destAmount) {
        require(uniRouters[address(router)], "router not supported");
        uint256 numGasBurns;
        {
            // prevent stack too deep
            uint256 gasBefore = useGasToken ? gasleft() : 0;
            destAmount = _swapUniswapInternal(
                router,
                srcAmount,
                minDestAmount,
                tradePath,
                recipient
            );
            if (useGasToken) {
                numGasBurns = _burnGasTokensAfter(gasBefore);
            }
        }
    }

    /// @dev get expected return and conversion rate if using Kyber
    function getExpectedReturnKyber(
        IERC20 src,
        IERC20 dest,
        uint256 srcAmount,
        bytes calldata hint
    ) external view returns (uint256 destAmount, uint256 expectedRate) {
        try
            kyberProxy.getExpectedRateAfterFee(src, dest, srcAmount, 0, hint)
        returns (uint256 rate) {
            expectedRate = rate;
        } catch {
            expectedRate = 0;
        }
        destAmount = _calcDestAmount(src, dest, srcAmount, expectedRate);
    }

    /// @dev get expected return and conversion rate if using a Uniswap router
    function getExpectedReturnUniswap(
        IUniswapV2Router02 router,
        uint256 srcAmount,
        address[] calldata tradePath
    ) external view returns (uint256 destAmount, uint256 expectedRate) {
        // in case router is not supported
        if (!uniRouters[address(router)]) {
            return (0, 0);
        }
        try router.getAmountsOut(srcAmount, tradePath) returns (
            uint256[] memory amounts
        ) {
            destAmount = amounts[tradePath.length - 1];
        } catch {
            destAmount = 0;
        }
        expectedRate = _calcRateFromQty(
            srcAmount,
            destAmount,
            _getDecimals(IERC20(tradePath[0])),
            _getDecimals(IERC20(tradePath[tradePath.length - 1]))
        );
    }

    function _doKyberTrade(
        IERC20 src,
        IERC20 dest,
        uint256 srcAmount,
        uint256 minConversionRate,
        address payable recipient,
        bytes memory hint
    ) internal returns (uint256 destAmount) {
        _validateAndPrepareSourceAmount(address(kyberProxy), src, srcAmount);
        uint256 callValue = src == _ETH_TOKEN_ADDRESS ? srcAmount : 0;
        destAmount = kyberProxy.tradeWithHintAndFee{value: callValue}(
            src,
            srcAmount,
            dest,
            recipient,
            _MAX_AMOUNT,
            minConversionRate,
            payable(0),
            0,
            hint
        );
    }

    function _swapUniswapInternal(
        IUniswapV2Router02 router,
        uint256 srcAmount,
        uint256 minDestAmount,
        address[] memory tradePath,
        address payable recipient
    ) internal returns (uint256 destAmount) {
        IERC20 src = IERC20(tradePath[0]);
        destAmount = _doUniswapTrade(
            router,
            src,
            srcAmount,
            minDestAmount,
            tradePath,
            recipient
        );
    }

    // solhint-disable-next-line function-max-lines
    function _doUniswapTrade(
        IUniswapV2Router02 router,
        IERC20 src,
        uint256 srcAmount,
        uint256 minDestAmount,
        address[] memory tradePath,
        address payable recipient
    ) internal returns (uint256 destAmount) {
        _validateAndPrepareSourceAmount(address(router), src, srcAmount);
        uint256 tradeLen = tradePath.length;
        IERC20 actualDest = IERC20(tradePath[tradeLen - 1]);
        {
            // convert eth -> weth address to trade on Uniswap
            if (tradePath[0] == address(_ETH_TOKEN_ADDRESS)) {
                tradePath[0] = router.WETH();
            }
            if (tradePath[tradeLen - 1] == address(_ETH_TOKEN_ADDRESS)) {
                tradePath[tradeLen - 1] = router.WETH();
            }
        }

        uint256[] memory amounts;
        if (src == _ETH_TOKEN_ADDRESS) {
            // swap eth -> token
            amounts = router.swapExactETHForTokens{value: srcAmount}(
                minDestAmount,
                tradePath,
                recipient,
                _MAX_AMOUNT
            );
        } else {
            if (actualDest == _ETH_TOKEN_ADDRESS) {
                // swap token -> eth
                amounts = router.swapExactTokensForETH(
                    srcAmount,
                    minDestAmount,
                    tradePath,
                    recipient,
                    _MAX_AMOUNT
                );
            } else {
                // swap token -> token
                amounts = router.swapExactTokensForTokens(
                    srcAmount,
                    minDestAmount,
                    tradePath,
                    recipient,
                    _MAX_AMOUNT
                );
            }
        }

        destAmount = amounts[amounts.length - 1];
    }

    function _validateAndPrepareSourceAmount(
        address protocol,
        IERC20 src,
        uint256 srcAmount
    ) internal {
        require(srcAmount > 0, "invalid src amount");
        if (src == _ETH_TOKEN_ADDRESS) {
            require(msg.value == srcAmount, "wrong msg value");
        } else {
            require(msg.value == 0, "wrong msg value");
            src.safeTransferFrom(msg.sender, address(this), srcAmount);
            src.safeApprove(protocol, srcAmount);
        }
    }

    function _burnGasTokensAfter(uint256 gasBefore)
        internal
        virtual
        returns (uint256 numGasBurns)
    {
        if (burnGasHelper == IBurnGasHelper(address(0))) return 0;
        IGasToken gasToken;
        uint256 gasAfter = gasleft();

        try
            burnGasHelper.getAmountGasTokensToBurn(
                gasBefore.sub(gasAfter),
                msg.data // forward all data
            )
        returns (uint256 _gasBurns, address _gasToken) {
            numGasBurns = _gasBurns;
            gasToken = IGasToken(_gasToken);
        } catch {
            numGasBurns = 0;
        }

        if (numGasBurns > 0 && gasToken != IGasToken(address(0))) {
            numGasBurns = gasToken.freeFromUpTo(msg.sender, numGasBurns);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    IERC20,
    SafeERC20
} from "../../vendor/openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "../../vendor/openzeppelin/contracts/math/SafeMath.sol";
import {
    IChainlinkOracle
} from "../../interfaces/chainlink/IChainlinkOracle.sol";
import {IOracleAggregator} from "../../interfaces/gelato/IOracleAggregator.sol";
import {TaskStorage} from "./TaskStorage.sol";
import {IGelatoDiamond} from "../diamond/interfaces/IGelatoDiamond.sol";
import {
    _transferEthAndToken,
    _swapTokenToEthTransfer
} from "../../functions/gelato/FPayment.sol";
import {_getExpectedReturnAmount} from "../../functions/gelato/FGelato.sol";
import {ETH} from "../../constants/CTokens.sol";

contract SimpleServiceStandard is TaskStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public immutable gelato;

    event LogExecSuccess(
        uint256 indexed taskId,
        address indexed executor,
        uint256 postExecFee,
        uint256 rate,
        address feeToken
    );

    constructor(address _gelato) {
        gelato = _gelato;
    }

    modifier gelatofy(
        address _feeToken,
        address _user,
        bytes memory _bytes,
        uint256 _id,
        uint256 _fee,
        uint256 _swapRate
    ) {
        // Check only Gelato is calling
        require(
            address(gelato) == msg.sender,
            "SimpleServiceStandard: Caller is not gelato"
        );

        // Verify tasks actually exists
        require(
            verifyTask(_bytes, _id, _user),
            "SimpleServiceStandard: invalid task"
        );

        // update TaskStorage state before execution
        _removeTask(_bytes, _id, _user);

        // Execute Logic
        _;

        // Pay Gelato
        if (_swapRate == 0)
            _transferEthAndToken(payable(gelato), _feeToken, _fee);
        else if (_getExpectedReturnAmount(_feeToken, ETH, _fee, gelato) == 0) {
            _swapTokenToEthTransfer(gelato, _feeToken, _fee, _swapRate);
        }

        // emit event
        emit LogExecSuccess(_id, tx.origin, _fee, _swapRate, _feeToken);
    }

    /// ################# VIEW ################
    function currentTaskId() public view returns (uint256) {
        return taskId;
    }

    function verifyTask(
        bytes memory _bytes,
        uint256 _id,
        address _user
    ) public view returns (bool) {
        // Check whether order is valid
        bytes32 execTaskHash = hashTask(_bytes, _id);
        return taskOwner[execTaskHash] == _user;
    }

    // ############# Fallback #############
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract TaskStorage {
    uint256 public taskId;
    mapping(bytes32 => address) public taskOwner;

    event LogTaskStored(
        uint256 indexed id,
        address indexed user,
        bytes32 indexed hash,
        bytes payload
    );
    event LogTaskRemoved(address indexed remover, bytes32 indexed taskHash);

    function hashTask(bytes memory _blob, uint256 _taskId)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_blob, _taskId));
    }

    function _storeTask(bytes memory _blob, address _owner)
        internal
        returns (uint256 newTaskId)
    {
        newTaskId = taskId + 1;
        taskId = newTaskId;

        bytes32 taskHash = hashTask(_blob, taskId);
        taskOwner[taskHash] = _owner;

        emit LogTaskStored(taskId, _owner, taskHash, _blob);
    }

    function _removeTask(
        bytes memory _blob,
        uint256 _taskId,
        address _owner
    ) internal {
        // Only address which created task can delete it
        bytes32 taskHash = hashTask(_blob, _taskId);
        address owner = taskOwner[taskHash];
        require(_owner == owner, "Task Storage: Only Owner can remove tasks");

        // delete task
        delete taskOwner[taskHash];
        emit LogTaskRemoved(msg.sender, taskHash);
    }

    function _updateTask(
        bytes memory _bytesBlob,
        bytes memory _newBytesBlob,
        uint256 _taskId,
        address _owner
    ) internal {
        _removeTask(_bytesBlob, _taskId, _owner);
        bytes32 taskHash = hashTask(_newBytesBlob, _taskId);
        taskOwner[taskHash] = _owner;

        emit LogTaskStored(_taskId, _owner, taskHash, _bytesBlob);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IBurnGasHelper {
    function getAmountGasTokensToBurn(
        uint256 gasConsumption,
        bytes calldata data
    ) external view returns (uint256 numGas, address gasToken);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {GELATO_GAS_PRICE_ORACLE} from "../../constants/CGelato.sol";
import {ETH} from "../../constants/CTokens.sol";
import {mul, wmul} from "../../vendor/DSMath.sol";
import {IOracleAggregator} from "../../interfaces/gelato/IOracleAggregator.sol";
import {ORACLE_AGGREGATOR} from "../../constants/COracle.sol";
import {ROUTE_1_TOLERANCE} from "../../constants/CInstaDapp.sol";
import {IGelatoDiamond} from "../../core/diamond/interfaces/IGelatoDiamond.sol";
import {ExecutionData, SubmissionData} from "../../structs/TaskData.sol";
import {GelatoBytes} from "../../lib/GelatoBytes.sol";
import {
    AccountInterface
} from "../../interfaces/instadapp/AccountInterface.sol";

function _getGelatoGasPrice() view returns (uint256) {
    return uint256(GELATO_GAS_PRICE_ORACLE.latestAnswer());
}

function _getGelatoProviderFees(uint256 _gas) view returns (uint256) {
    return mul(_gas, _getGelatoGasPrice());
}

function _getRealisedDebt(uint256 _debtToMove) pure returns (uint256) {
    return wmul(_debtToMove, ROUTE_1_TOLERANCE);
}

// Gelato Oracle price aggregator
function _getExpectedBuyAmountFromChainlink(
    address _buyAddr,
    address _sellAddr,
    uint256 _sellAmt
) view returns (uint256 buyAmt) {
    (buyAmt, ) = IOracleAggregator(ORACLE_AGGREGATOR).getExpectedReturnAmount(
        _sellAmt,
        _sellAddr,
        _buyAddr
    );
}

// Gelato Oracle price aggregator
function _getExpectedReturnAmount(
    address _inToken,
    address _outToken,
    uint256 _amt,
    address _gelato
) view returns (uint256 buyAmt) {
    (buyAmt, ) = IOracleAggregator(
        IGelatoDiamond(_gelato).getOracleAggregator()
    )
        .getExpectedReturnAmount(_amt, _inToken, _outToken);
}

function _getGelatoFee(
    uint256 _gasOverhead,
    uint256 _gasStart,
    address _payToken,
    address _gelato
) view returns (uint256 gelatoFee) {
    gelatoFee = (_gasStart - gasleft() + _gasOverhead) * _getGasPrice();

    if (_payToken == ETH) return gelatoFee;

    // returns purely the ethereum tx fee
    (gelatoFee, ) = IOracleAggregator(
        IGelatoDiamond(_gelato).getOracleAggregator()
    )
        .getExpectedReturnAmount(gelatoFee, ETH, _payToken);
}

function _getGelatoFeeAndExecRefund(
    uint256 _gasOverhead,
    uint256 _gasStart,
    address _feeToken,
    address _gelato
) view returns (uint256 gelatoFee, uint256 execRefund) {
    execRefund = (_gasStart - gasleft() + _gasOverhead) * _getGasPrice();

    if (_feeToken == ETH) {
        gelatoFee = execRefund;
        return (gelatoFee, execRefund);
    }

    // returns purely the ethereum tx fee
    (gelatoFee, ) = IOracleAggregator(
        IGelatoDiamond(_gelato).getOracleAggregator()
    )
        .getExpectedReturnAmount(execRefund, ETH, _feeToken);
}

function _getGasPrice() view returns (uint256) {
    uint256 oracleGasPrice = _getGelatoGasPrice();

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

function _hashProof(bytes32 _receiptHash, bytes32[] memory _pathHash)
    pure
    returns (bytes32 rootHash)
{
    rootHash = _receiptHash;
    for (uint256 i = 0; i < _pathHash.length; i++) {
        rootHash = keccak256(abi.encode(rootHash, _pathHash[i]));
    }
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

function _transferEthAndToken(
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
    address _feeToken,
    uint256 _feeAmount,
    uint256 _swapRate
) {
    address[] memory path = new address[](2);
    path[0] = _feeToken;
    path[1] = WETH;
    SafeERC20.safeIncreaseAllowance(
        IERC20(_feeToken),
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

function _getBalanceEthAndToken(address _paymentToken, address _account)
    view
    returns (uint256 balance)
{
    if (_paymentToken == ETH) {
        balance = _account.balance;
    } else {
        balance = IERC20(_paymentToken).balanceOf(_account);
    }
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

    function factory() external pure returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function WETH() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ITaskStorage {
    function storeTask(bytes calldata _bytesBlob) external returns (uint256);

    function removeTask(bytes32 _taskHash) external;

    function taskId() external view returns (uint256);

    function taskOwner(bytes32 _taskHash) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IGasToken {
    function mint(uint256 value) external;

    function freeUpTo(uint256 value) external returns (uint256 freed);

    function freeFromUpTo(address from, uint256 value)
        external
        returns (uint256 freed);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function balanceOf(address who) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    IERC20
} from "../../vendor/openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IKyberProxy {
    function tradeWithHintAndFee(
        IERC20 src,
        uint256 srcAmount,
        IERC20 dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external payable returns (uint256 destAmount);

    function getExpectedRateAfterFee(
        IERC20 src,
        IERC20 dest,
        uint256 srcQty,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external view returns (uint256 expectedRate);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

struct Fee {
    uint256 amount;
    uint256 swapRate;
    bool isOutToken;
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

pragma solidity 0.8.0;

function add(uint256 x, uint256 y) pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
}

function sub(uint256 x, uint256 y) pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
}

function mul(uint256 x, uint256 y) pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
}

function div(uint256 x, uint256 y) pure returns (uint256 z) {
    // Solidity only automatically asserts when dividing by 0
    require(y > 0, "ds-math-division-by-zero");
    z = x / y;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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