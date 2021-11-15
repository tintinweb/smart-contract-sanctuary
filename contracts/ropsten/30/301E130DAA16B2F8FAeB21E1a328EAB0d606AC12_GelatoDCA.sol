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

import {wdiv} from "./vendor/DSMath.sol";
import {
    IERC20,
    SafeERC20
} from "./vendor/openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {
    ReentrancyGuard
} from "./vendor/openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Utils} from "./vendor/kyber/utils/Utils.sol";
import {IKyberProxy} from "./vendor/kyber/utils/IKyberProxy.sol";
import {
    IChainlinkOracle
} from "./interfaces/chainlink/IChainlinkOracle.sol";
import {IOracleAggregator} from "./interfaces/gelato/IOracleAggregator.sol";
import {ITaskStorage} from "./interfaces/gelato/ITaskStorage.sol";
import {
    IUniswapV2Router02
} from "./interfaces/uniswap/IUniswapV2Router02.sol";
import {_to18Decimals} from "./gelato/functions/FToken.sol";
import {SimpleServiceStandard} from "./gelato/standards/SimpleServiceStandard.sol";
import {_transferEthOrToken} from "./gelato/functions/FPayment.sol";
import {ETH} from "./gelato/constants/CTokens.sol";
import {Fee} from "./gelato/structs/SGelato.sol";
import {IGelato} from "./interfaces/gelato/IGelato.sol";

contract GelatoDCA is SimpleServiceStandard, ReentrancyGuard, Utils {
    using SafeERC20 for IERC20;

    struct SubmitOrder {
        address inToken;
        address outToken;
        uint256 amountPerTrade;
        uint256 numTrades;
        uint256 minSlippage;
        uint256 maxSlippage;
        uint256 delay;
        address platformWallet;
        uint256 platformFeeBps;
    }

    struct ExecOrder {
        address user;
        address inToken;
        address outToken;
        uint256 amountPerTrade;
        uint256 nTradesLeft;
        uint256 minSlippage;
        uint256 maxSlippage;
        uint256 delay;
        uint256 lastExecutionTime;
        address platformWallet;
        uint256 platformFeeBps;
    }

    enum Dex {KYBER, UNISWAP, SUSHISWAP}

    bytes public constant HINT = "";
    uint256 internal constant _MAX_AMOUNT = type(uint256).max;

    IUniswapV2Router02 public immutable uniRouterV2;
    IUniswapV2Router02 public immutable sushiRouterV2;
    IKyberProxy public immutable kyberProxy;

    mapping(address => mapping(address => uint256)) public platformWalletFees;

    event LogTaskSubmitted(uint256 indexed id, ExecOrder order);
    event LogTaskCancelled(uint256 indexed id, ExecOrder order);
    event LogTaskUpdated(uint256 indexed id, ExecOrder order);
    event LogDCATrade(uint256 indexed id, ExecOrder order, uint256 outAmount);
    event ClaimedPlatformFees(
        address[] wallets,
        address[] tokens,
        address claimer
    );

    constructor(
        IKyberProxy _kyberProxy,
        IUniswapV2Router02 _uniRouterV2,
        IUniswapV2Router02 _sushiRouterV2,
        address _gelato
    ) SimpleServiceStandard(_gelato) {
        kyberProxy = _kyberProxy;
        uniRouterV2 = _uniRouterV2;
        sushiRouterV2 = _sushiRouterV2;
    }

    function submit(SubmitOrder memory _order, bool _isSubmitAndExec)
        public
        payable
    {
        if (_order.inToken == ETH) {
            uint256 value =
                _isSubmitAndExec
                    ? _order.amountPerTrade * (_order.numTrades + 1)
                    : _order.amountPerTrade * _order.numTrades;
            require(
                msg.value == value,
                "GelatoDCA.submit: mismatching amount of ETH deposited"
            );
        }
        ExecOrder memory order =
            ExecOrder({
                user: msg.sender,
                inToken: _order.inToken,
                outToken: _order.outToken,
                amountPerTrade: _order.amountPerTrade,
                nTradesLeft: _order.numTrades,
                minSlippage: _order.minSlippage,
                maxSlippage: _order.maxSlippage,
                delay: _order.delay, // solhint-disable-next-line not-rely-on-time
                lastExecutionTime: block.timestamp,
                platformWallet: _order.platformWallet,
                platformFeeBps: _order.platformFeeBps
            });

        // store order
        _storeOrder(order);
    }

    // solhint-disable-next-line function-max-lines
    function submitAndExec(
        SubmitOrder memory _order,
        Dex _protocol,
        uint256 _minReturnOrRate,
        address[] calldata _tradePath
    ) external payable {
        require(
            _order.numTrades > 1,
            "GelatoDCA.submitAndExec: cycle must have 2 or more trades"
        );

        // 1. Submit future orders
        _order.numTrades = _order.numTrades - 1;
        submit(_order, true);

        // 2. Exec 1st Trade now
        if (_order.inToken != ETH) {
            IERC20(_order.inToken).safeTransferFrom(
                msg.sender,
                address(this),
                _order.amountPerTrade
            );
            IERC20(_order.inToken).safeIncreaseAllowance(
                getProtocolAddress(_protocol),
                _order.amountPerTrade
            );
        }

        if (_protocol == Dex.KYBER) {
            _doKyberTrade(
                _order.inToken,
                _order.outToken,
                _order.amountPerTrade,
                _minReturnOrRate,
                payable(msg.sender),
                payable(_order.platformWallet),
                _order.platformFeeBps
            );
        } else {
            _doUniswapTrade(
                _protocol == Dex.UNISWAP ? uniRouterV2 : sushiRouterV2,
                _tradePath,
                _order.amountPerTrade,
                _minReturnOrRate,
                payable(msg.sender),
                payable(_order.platformWallet),
                _order.platformFeeBps
            );
        }
    }

    function cancel(ExecOrder calldata _order, uint256 _id)
        external
        nonReentrant
    {
        _removeTask(abi.encode(_order), _id, msg.sender);
        if (_order.inToken == ETH) {
            uint256 refundAmount = _order.amountPerTrade * _order.nTradesLeft;
            (bool success, ) = _order.user.call{value: refundAmount}("");
            require(success, "GelatoDCA.cancel: Could not refund ETH");
        }

        emit LogTaskCancelled(_id, _order);
    }

    function claimPlatformFees(
        address[] calldata _platformWallets,
        address[] calldata _tokens
    ) external nonReentrant {
        for (uint256 i = 0; i < _platformWallets.length; i++) {
            for (uint256 j = 0; j < _tokens.length; j++) {
                uint256 fee =
                    platformWalletFees[_platformWallets[i]][_tokens[j]];
                if (fee > 1) {
                    platformWalletFees[_platformWallets[i]][_tokens[j]] = 1;
                    _transferEthOrToken(
                        payable(_platformWallets[i]),
                        _tokens[j],
                        fee - 1
                    );
                }
            }
        }
        emit ClaimedPlatformFees(_platformWallets, _tokens, msg.sender);
    }

    // solhint-disable-next-line function-max-lines
    function exec(
        ExecOrder calldata _order,
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
        if (_order.nTradesLeft > 1) {
            _updateAndSubmitNextTask(_order, _id);
        } else {
            _removeTask(abi.encode(_order), _id, _order.user);
        }

        // action exec
        uint256 outAmount;
        if (_protocol == Dex.KYBER) {
            outAmount = _actionKyber(_order, _fee.amount, _fee.isOutToken);
        } else {
            outAmount = _actionUniOrSushi(
                _order,
                _protocol,
                _tradePath,
                _fee.amount,
                _fee.isOutToken
            );
        }

        if (_fee.isOutToken) {
            _transferEthOrToken(
                payable(_order.user),
                _order.outToken,
                outAmount
            );
        }

        emit LogDCATrade(_id, _order, outAmount);
    }

    function isTaskSubmitted(ExecOrder calldata _order, uint256 _id)
        external
        view
        returns (bool)
    {
        return verifyTask(abi.encode(_order), _id, _order.user);
    }

    function getMinReturn(ExecOrder memory _order)
        public
        view
        returns (uint256 minReturn)
    {
        // 4. Rate Check
        (uint256 idealReturn, ) =
            IOracleAggregator(IGelato(gelato).getOracleAggregator())
                .getExpectedReturnAmount(
                _order.amountPerTrade,
                _order.inToken,
                _order.outToken
            );

        require(
            idealReturn > 0,
            "GelatoKrystal.getMinReturn: idealReturn cannot be 0"
        );

        // check time (reverts if block.timestamp is below execTime)
        uint256 timeSinceCanExec =
            // solhint-disable-next-line not-rely-on-time
            block.timestamp - (_order.lastExecutionTime + _order.delay);

        uint256 minSlippageFactor = BPS - _order.minSlippage;
        uint256 maxSlippageFactor = BPS - _order.maxSlippage;
        uint256 slippage;
        if (minSlippageFactor > timeSinceCanExec) {
            slippage = minSlippageFactor - timeSinceCanExec;
        }

        if (maxSlippageFactor > slippage) {
            slippage = maxSlippageFactor;
        }

        minReturn = (idealReturn * slippage) / BPS;
    }

    function isSwapPossible(address _inToken, address _outToken)
        external
        view
        returns (bool isPossible)
    {
        (uint256 idealReturn, ) =
            IOracleAggregator(IGelato(gelato).getOracleAggregator())
                .getExpectedReturnAmount(1e18, _inToken, _outToken);
        isPossible = idealReturn == 0 ? false : true;
    }

    // ############# PRIVATE #############
    function _actionKyber(
        ExecOrder memory _order,
        uint256 _fee,
        bool _outTokenFee
    ) private returns (uint256 received) {
        (uint256 inAmount, uint256 minReturn, address payable receiver) =
            _preExec(_order, _fee, _outTokenFee, Dex.KYBER);

        received = _doKyberTrade(
            _order.inToken,
            _order.outToken,
            inAmount,
            _getKyberRate(inAmount, minReturn, _order.inToken, _order.outToken),
            receiver,
            payable(_order.platformWallet),
            _order.platformFeeBps
        );

        if (_outTokenFee) {
            received = received - _fee;
        }
    }

    function _doKyberTrade(
        address _inToken,
        address _outToken,
        uint256 _inAmount,
        uint256 _minRate,
        address payable _receiver,
        address payable _platformWallet,
        uint256 _platformFeeBps
    ) private returns (uint256 received) {
        uint256 ethToSend = _inToken == ETH ? _inAmount : uint256(0);

        received = kyberProxy.tradeWithHintAndFee{value: ethToSend}(
            IERC20(_inToken),
            _inAmount,
            IERC20(_outToken),
            _receiver,
            _MAX_AMOUNT,
            _minRate,
            _platformWallet,
            _platformFeeBps,
            HINT
        );
    }

    function _actionUniOrSushi(
        ExecOrder memory _order,
        Dex _protocol,
        address[] memory _tradePath,
        uint256 _fee,
        bool _outTokenFee
    ) private returns (uint256 received) {
        (uint256 inAmount, uint256 minReturn, address payable receiver) =
            _preExec(_order, _fee, _outTokenFee, _protocol);

        require(
            _order.inToken == _tradePath[0] &&
                _order.outToken == _tradePath[_tradePath.length - 1],
            "GelatoDCA.action: trade path does not match order."
        );

        received = _doUniswapTrade(
            _protocol == Dex.UNISWAP ? uniRouterV2 : sushiRouterV2,
            _tradePath,
            inAmount,
            minReturn,
            receiver,
            payable(_order.platformWallet),
            _order.platformFeeBps
        );

        if (_outTokenFee) {
            received = received - _fee;
        }
    }

    // @dev fee will always be paid be srcToken
    // solhint-disable-next-line function-max-lines
    function _doUniswapTrade(
        IUniswapV2Router02 _router,
        address[] memory _tradePath,
        uint256 _inAmount,
        uint256 _minReturn,
        address payable _receiver,
        address payable _platformWallet,
        uint256 _platformFeeBps
    ) private returns (uint256 received) {
        uint256 feeAmount = (_inAmount * _platformFeeBps) / BPS;
        uint256 actualSellAmount = _inAmount - feeAmount;
        address actualInToken;
        address actualOutToken;
        {
            uint256 tradeLen = _tradePath.length;
            actualInToken = _tradePath[0];
            actualOutToken = _tradePath[tradeLen - 1];
            if (_tradePath[0] == address(ETH)) {
                _tradePath[0] = _router.WETH();
            }
            if (_tradePath[tradeLen - 1] == address(ETH)) {
                _tradePath[tradeLen - 1] = _router.WETH();
            }

            // add platform fee to platform wallet account
            _addFeeToPlatform(_platformWallet, actualInToken, feeAmount);
        }

        uint256[] memory amounts;
        if (actualInToken == ETH) {
            amounts = _router.swapExactETHForTokens{value: actualSellAmount}(
                _minReturn,
                _tradePath,
                _receiver,
                _MAX_AMOUNT
            );
        } else {
            if (actualOutToken == address(ETH)) {
                amounts = _router.swapExactTokensForETH(
                    actualSellAmount,
                    _minReturn,
                    _tradePath,
                    _receiver,
                    _MAX_AMOUNT
                );
            } else {
                amounts = _router.swapExactTokensForTokens(
                    actualSellAmount,
                    _minReturn,
                    _tradePath,
                    _receiver,
                    _MAX_AMOUNT
                );
            }
        }

        return amounts[amounts.length - 1];
    }

    // solhint-disable function-max-lines
    function _preExec(
        ExecOrder memory _order,
        uint256 _fee,
        bool _outTokenFee,
        Dex _protocol
    )
        private
        returns (
            uint256 inAmount,
            uint256 minReturn,
            address payable receiver
        )
    {
        if (_outTokenFee) {
            receiver = payable(this);
            minReturn = getMinReturn(_order) + _fee;
            inAmount = _order.amountPerTrade;
        } else {
            receiver = payable(_order.user);
            minReturn = getMinReturn(_order);
            inAmount = _order.amountPerTrade - _fee;
        }

        if (_order.inToken != ETH) {
            IERC20(_order.inToken).safeTransferFrom(
                _order.user,
                address(this),
                _order.amountPerTrade
            );
            IERC20(_order.inToken).safeIncreaseAllowance(
                getProtocolAddress(_protocol),
                inAmount
            );
        }
    }

    function _updateAndSubmitNextTask(ExecOrder memory _order, uint256 _id)
        private
    {
        bytes memory lastOrder = abi.encode(_order);
        // update next order
        _order.nTradesLeft = _order.nTradesLeft - 1;
        // solhint-disable-next-line not-rely-on-time
        _order.lastExecutionTime = block.timestamp;

        _updateTask(lastOrder, abi.encode(_order), _id, _order.user);
        emit LogTaskSubmitted(_id, _order);
    }

    function _storeOrder(ExecOrder memory _order) private {
        uint256 id = _storeTask(abi.encode(_order), _order.user);
        emit LogTaskSubmitted(id, _order);
    }

    function _getKyberRate(
        uint256 _amountIn,
        uint256 _minReturn,
        address _inToken,
        address _outToken
    ) private view returns (uint256) {
        uint256 newAmountIn =
            _to18Decimals(
                _inToken,
                _amountIn,
                "GelatoDCA:_getKyberRate: newAmountIn revert"
            );
        uint256 newMinReturn =
            _to18Decimals(
                _outToken,
                _minReturn,
                "GelatoDCA:_getKyberRate: newMinReturn revert"
            );
        return wdiv(newMinReturn, newAmountIn);
    }

    function _addFeeToPlatform(
        address _wallet,
        address _token,
        uint256 _amount
    ) private {
        if (_amount > 0) {
            platformWalletFees[_wallet][_token] =
                platformWalletFees[_wallet][_token] +
                _amount;
        }
    }

    function getProtocolAddress(Dex _dex) public view returns (address) {
        if (_dex == Dex.KYBER) return address(kyberProxy);
        if (_dex == Dex.UNISWAP) return address(uniRouterV2);
        if (_dex == Dex.SUSHISWAP) return address(sushiRouterV2);
        revert("GelatoDCA: getProtocolAddress: Dex not found");
    }

    function getExpectedReturnKyber(
        IERC20 _src,
        IERC20 _dest,
        uint256 _inAmount,
        uint256 _platformFee,
        bytes calldata _hint
    ) external view returns (uint256 outAmount, uint256 expectedRate) {
        try
            kyberProxy.getExpectedRateAfterFee(
                _src,
                _dest,
                _inAmount,
                _platformFee,
                _hint
            )
        returns (uint256 rate) {
            expectedRate = rate;
        } catch {
            expectedRate = 0;
        }
        outAmount = calcDestAmount(_src, _dest, _inAmount, expectedRate);
    }

    function getExpectedReturnUniswap(
        IUniswapV2Router02 _router,
        uint256 _inAmount,
        address[] calldata _tradePath,
        uint256 _platformFee
    ) external view returns (uint256 outAmount, uint256 expectedRate) {
        if (_platformFee >= BPS) return (0, 0);
        uint256 srcAmountAfterFee = (_inAmount * (BPS - _platformFee)) / BPS;
        if (srcAmountAfterFee == 0) return (0, 0);

        try _router.getAmountsOut(srcAmountAfterFee, _tradePath) returns (
            uint256[] memory amounts
        ) {
            outAmount = amounts[_tradePath.length - 1];
        } catch {
            outAmount = 0;
        }
        expectedRate = calcRateFromQty(
            srcAmountAfterFee,
            outAmount,
            getDecimals(IERC20(_tradePath[0])),
            getDecimals(IERC20(_tradePath[_tradePath.length - 1]))
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {IChainlinkOracle} from "../../interfaces/chainlink/IChainlinkOracle.sol";

IChainlinkOracle constant GELATO_GAS_PRICE_ORACLE = IChainlinkOracle(
    0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C
);

string constant OK = "OK";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {GELATO_GAS_PRICE_ORACLE} from "../constants/CGelato.sol";
import {
    IChainlinkOracle
} from "../../interfaces/chainlink/IChainlinkOracle.sol";
import {ETH} from "../constants/CTokens.sol";
import {mul, wmul} from "../../vendor/DSMath.sol";
import {IOracleAggregator} from "../../interfaces/gelato/IOracleAggregator.sol";
import {ORACLE_AGGREGATOR} from "../constants/COracle.sol";
import {IGelato} from "../../interfaces/gelato/IGelato.sol";

function _getGelatoGasPrice(address _gasPriceOracle) view returns (uint256) {
    return uint256(IChainlinkOracle(_gasPriceOracle).latestAnswer());
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {ETH, WETH} from "../constants/CTokens.sol";
import {UNISWAPV2_ROUTER02} from "../constants/CUniswap.sol";
import {
    IUniswapV2Router02
} from "../../interfaces/uniswap/IUniswapV2Router02.sol";
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
    path[1] = WETH;
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

import {
    SafeERC20
} from "../../vendor/openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {
    IERC20
} from "../../vendor/openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ETH} from "../constants/CTokens.sol";

function _to18Decimals(
    address _token,
    uint256 _amount,
    string memory _revertMsg
) view returns (uint256) {
    if (_token == ETH) return _amount;

    try IERC20(_token).decimals() returns (uint8 _decimals) {
        return (_amount * (10**18)) / (10**uint256(_decimals));
    } catch {
        revert(_revertMsg);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {TaskStorage} from "./TaskStorage.sol";
import {
    _transferEthOrToken,
    _swapTokenToEthTransfer
} from "../functions/FPayment.sol";
import {_getExpectedReturnAmount} from "../functions/FGelato.sol";
import {ETH} from "../constants/CTokens.sol";

abstract contract SimpleServiceStandard is TaskStorage {
    address public immutable gelato;

    event LogExecSuccess(
        uint256 indexed taskId,
        address indexed executor,
        uint256 postExecFee,
        uint256 rate,
        address creditToken
    );

    modifier gelatofy(
        address _creditToken,
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

        // _removeTask(_bytes, _id, _user);

        // Execute Logic
        _;

        // Pay Gelato
        if (_swapRate == 0)
            _transferEthOrToken(payable(gelato), _creditToken, _fee);
        else if (
            _getExpectedReturnAmount(_creditToken, ETH, _fee, gelato) == 0
        ) {
            _swapTokenToEthTransfer(gelato, _creditToken, _fee, _swapRate);
        }

        emit LogExecSuccess(_id, tx.origin, _fee, _swapRate, _creditToken);
    }

    constructor(address _gelato) {
        gelato = _gelato;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function verifyTask(
        bytes memory _bytes,
        uint256 _id,
        address _user
    ) public view returns (bool) {
        // Check whether owner is valid
        return taskOwner[hashTask(_bytes, _id)] == _user;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

abstract contract TaskStorage {
    uint256 public taskId;
    mapping(bytes32 => address) public taskOwner;

    event LogTaskStored(
        uint256 indexed id,
        address indexed user,
        bytes32 indexed taskHash,
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
        newTaskId = ++taskId;

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
        require(
            _owner == taskOwner[taskHash],
            "Task Storage: Only Owner can remove tasks"
        );

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

struct Fee {
    uint256 amount;
    uint256 swapRate;
    bool isOutToken;
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

import {IDiamondCut} from "../diamond/IDiamondCut.sol";
import {IDiamondLoupe} from "../diamond/IDiamondLoupe.sol";
import {
    TaskReceipt
} from "@gelatonetwork/core/contracts/gelato_core/interfaces/IGelatoCore.sol";
import {IGelatoV1} from "./IGelatoV1.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ITaskStorage {
    function storeTask(bytes calldata _bytesBlob) external returns (uint256);

    function removeTask(bytes32 _taskHash) external;

    function taskId() external view returns (uint256);

    function taskOwner(bytes32 _taskHash) external view returns (address);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    IERC20
} from "../../openzeppelin/contracts/token/ERC20/IERC20.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "../../openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title Kyber utility file
 * mostly shared constants and rate calculation helpers
 * inherited by most of kyber contracts.
 * previous utils implementations are for previous solidity versions.
 */
// solhint-disable private-vars-leading-underscore
contract Utils {
    // Declared constants below to be used in tandem with
    // getDecimalsConstant(), for gas optimization purposes
    // which return decimals from a constant list of popular
    // tokens.
    IERC20 internal constant ETH_TOKEN_ADDRESS = IERC20(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );
    IERC20 internal constant USDT_TOKEN_ADDRESS = IERC20(
        0xdAC17F958D2ee523a2206206994597C13D831ec7
    );
    IERC20 internal constant DAI_TOKEN_ADDRESS = IERC20(
        0x6B175474E89094C44Da98b954EedeAC495271d0F
    );
    IERC20 internal constant USDC_TOKEN_ADDRESS = IERC20(
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    );
    IERC20 internal constant WBTC_TOKEN_ADDRESS = IERC20(
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
    );
    IERC20 internal constant KNC_TOKEN_ADDRESS = IERC20(
        0xdd974D5C2e2928deA5F71b9825b8b646686BD200
    );
    uint256 public constant BPS = 10000; // Basic Price Steps. 1 step = 0.01%
    uint256 internal constant PRECISION = (10**18);
    uint256 internal constant MAX_QTY = (10**28); // 10B tokens
    uint256 internal constant MAX_RATE = (PRECISION * 10**7); // up to 10M tokens per eth
    uint256 internal constant MAX_DECIMALS = 18;
    uint256 internal constant ETH_DECIMALS = 18;
    uint256 internal constant MAX_ALLOWANCE = type(uint).max; // token.approve inifinite

    mapping(IERC20 => uint256) internal decimals;

    /// @dev Sets the decimals of a token to storage if not already set, and returns
    ///      the decimals value of the token. Prefer using this function over
    ///      getDecimals(), to avoid forgetting to set decimals in local storage.
    /// @param token The token type
    /// @return tokenDecimals The decimals of the token
    function getSetDecimals(IERC20 token) internal returns (uint256 tokenDecimals) {
        tokenDecimals = getDecimalsConstant(token);
        if (tokenDecimals > 0) return tokenDecimals;

        tokenDecimals = decimals[token];
        if (tokenDecimals == 0) {
            tokenDecimals = token.decimals();
            decimals[token] = tokenDecimals;
        }
    }

    /// @dev Get the balance of a user
    /// @param token The token type
    /// @param user The user's address
    /// @return The balance
    function getBalance(IERC20 token, address user) internal view returns (uint256) {
        if (token == ETH_TOKEN_ADDRESS) {
            return user.balance;
        } else {
            return token.balanceOf(user);
        }
    }

    /// @dev Get the decimals of a token, read from the constant list, storage,
    ///      or from token.decimals(). Prefer using getSetDecimals when possible.
    /// @param token The token type
    /// @return tokenDecimals The decimals of the token
    function getDecimals(IERC20 token) internal view returns (uint256 tokenDecimals) {
        // return token decimals if has constant value
        tokenDecimals = getDecimalsConstant(token);
        if (tokenDecimals > 0) return tokenDecimals;

        // handle case where token decimals is not a declared decimal constant
        tokenDecimals = decimals[token];
        // moreover, very possible that old tokens have decimals 0
        // these tokens will just have higher gas fees.
        return (tokenDecimals > 0) ? tokenDecimals : token.decimals();
    }

    function calcDestAmount(
        IERC20 src,
        IERC20 dest,
        uint256 srcAmount,
        uint256 rate
    ) internal view returns (uint256) {
        return calcDstQty(srcAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcSrcAmount(
        IERC20 src,
        IERC20 dest,
        uint256 destAmount,
        uint256 rate
    ) internal view returns (uint256) {
        return calcSrcQty(destAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcDstQty(
        uint256 srcQty,
        uint256 srcDecimals,
        uint256 dstDecimals,
        uint256 rate
    ) internal pure returns (uint256) {
        require(srcQty <= MAX_QTY, "srcQty > MAX_QTY");
        require(rate <= MAX_RATE, "rate > MAX_RATE");

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS, "dst - src > MAX_DECIMALS");
            return (srcQty * rate * (10**(dstDecimals - srcDecimals))) / PRECISION;
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS, "src - dst > MAX_DECIMALS");
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals - dstDecimals)));
        }
    }

    function calcSrcQty(
        uint256 dstQty,
        uint256 srcDecimals,
        uint256 dstDecimals,
        uint256 rate
    ) internal pure returns (uint256) {
        require(dstQty <= MAX_QTY, "dstQty > MAX_QTY");
        require(rate <= MAX_RATE, "rate > MAX_RATE");

        //source quantity is rounded up. to avoid dest quantity being too low.
        uint256 numerator;
        uint256 denominator;
        if (srcDecimals >= dstDecimals) {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS, "src - dst > MAX_DECIMALS");
            numerator = (PRECISION * dstQty * (10**(srcDecimals - dstDecimals)));
            denominator = rate;
        } else {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS, "dst - src > MAX_DECIMALS");
            numerator = (PRECISION * dstQty);
            denominator = (rate * (10**(dstDecimals - srcDecimals)));
        }
        return (numerator + denominator - 1) / denominator; //avoid rounding down errors
    }

    function calcRateFromQty(
        uint256 srcAmount,
        uint256 destAmount,
        uint256 srcDecimals,
        uint256 dstDecimals
    ) internal pure returns (uint256) {
        require(srcAmount <= MAX_QTY, "srcAmount > MAX_QTY");
        require(destAmount <= MAX_QTY, "destAmount > MAX_QTY");

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS, "dst - src > MAX_DECIMALS");
            return ((destAmount * PRECISION) / ((10**(dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS, "src - dst > MAX_DECIMALS");
            return ((destAmount * PRECISION * (10**(srcDecimals - dstDecimals))) / srcAmount);
        }
    }

    /// @dev save storage access by declaring token decimal constants
    /// @param token The token type
    /// @return token decimals
    function getDecimalsConstant(IERC20 token) internal pure returns (uint256) {
        if (token == ETH_TOKEN_ADDRESS) {
            return ETH_DECIMALS;
        } else if (token == USDT_TOKEN_ADDRESS) {
            return 6;
        } else if (token == DAI_TOKEN_ADDRESS) {
            return 18;
        } else if (token == USDC_TOKEN_ADDRESS) {
            return 6;
        } else if (token == WBTC_TOKEN_ADDRESS) {
            return 8;
        } else if (token == KNC_TOKEN_ADDRESS) {
            return 18;
        } else {
            return 0;
        }
    }

    function minOf(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
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

