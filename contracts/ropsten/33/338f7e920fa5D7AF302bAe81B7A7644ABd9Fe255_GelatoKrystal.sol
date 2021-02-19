// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

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

import {IDiamondCut} from "./IDiamondCut.sol";
import {IDiamondLoupe} from "./IDiamondLoupe.sol";

/// @dev includes the interfaces of all facets
interface IGelatoDiamond {
    event LogExecSuccess(address indexed _service);
    event LogExecFailed(address indexed _service, string indexed revertMsg);
    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setOracleAggregator(address _oracleAggregator)
        external
        returns (address);

    function setGasPriceOracle(address _gasPriceOracle)
        external
        returns (address);

    function diamondCut(
        IDiamondCut.FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    function exec(address _service, bytes calldata _data) external;

    function addExecutor(address _executor) external;

    function removeExecutor(address _executor) external;

    function transferOwnership(address _newOwner) external;

    function requestService(address _newService) external;

    function acceptService(address _service) external;

    function stopService(address _service) external;

    function blacklistService(address _service) external;

    function deblacklistService(address _service) external;

    function canExecutorExec(address _service, address _executor)
        external
        view
        returns (bool);

    function isExecutor(address _executor) external view returns (bool);

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

    function owner() external view returns (address owner_);

    function getOracleAggregator() external view returns (address);

    function getGasPriceOracle() external view returns (address);

    function serviceRequested(address _service) external view returns (bool);

    function serviceAccepted(address _service) external view returns (bool);

    function serviceBlacklisted(address _service) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    IERC20,
    SafeERC20
} from "../../vendor/openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "../../vendor/openzeppelin/contracts/math/SafeMath.sol";
import {
    ISmartWalletSwapImplementation
} from "../../interfaces/krystal/ISmartWalletSwapImplementation.sol";
import {
    IChainlinkOracle
} from "../../interfaces/chainlink/IChainlinkOracle.sol";
import {IOracleAggregator} from "../../interfaces/gelato/IOracleAggregator.sol";
import {ITaskStorage} from "../../interfaces/gelato/ITaskStorage.sol";
import {
    IUniswapV2Router02
} from "../../interfaces/dapps/Uniswap/IUniswapV2Router02.sol";
import {ServicePostExecFee} from "../standards/ServicePostExecFee.sol";

// import "hardhat/console.sol";

contract GelatoKrystal is ServicePostExecFee {
    using SafeMath for uint256;
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
        uint256 maxTxFeeBPS;
        bytes32 cycleId;
    }

    bytes public constant HINT = "";
    uint256 public constant PLATFORM_FEE_BPS = 8;

    ISmartWalletSwapImplementation public immutable smartWalletSwap;
    IUniswapV2Router02 public immutable uniRouterV2;
    IUniswapV2Router02 public immutable sushiRouterV2;
    address payable public immutable platformWallet;

    event LogTaskSubmitted(uint256 indexed taskId, Order order);
    event LogTaskCanceled(uint256 indexed taskId, Order order);
    event LogTaskUpdated(uint256 indexed taskId, Order order);

    constructor(
        ISmartWalletSwapImplementation _smartWalletSwap,
        IUniswapV2Router02 _uniRouterV2,
        IUniswapV2Router02 _sushiRouterV2,
        address payable _platformWallet,
        address gelato
    ) ServicePostExecFee(gelato) {
        smartWalletSwap = _smartWalletSwap;
        platformWallet = _platformWallet;
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
        uint256 maxTxFeeBPS,
        bytes32 cycleId
    ) external payable {
        if (inToken == _ETH) {
            require(
                msg.value == amountPerTrade * nTradesLeft,
                "GelatoKrystal: mismatching amount of ETH deposited"
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
                delay: delay,
                maxTxFeeBPS: maxTxFeeBPS, // solhint-disable-next-line not-rely-on-time
                lastExecutionTime: block.timestamp,
                cycleId: cycleId
            });

        // store order
        _storeOrder(order, msg.sender);
    }

    function cancel(Order calldata _order, uint256 _id) external {
        _removeTask(abi.encode(_order), _id, msg.sender);
        if (_order.inToken == _ETH) {
            uint256 refundAmount = _order.amountPerTrade * _order.nTradesLeft;
            (bool success, ) =
                _order.user.call{value: refundAmount, gas: 2300}("");
            require(success, "GelatoKrystal: cancel: refund reverted");
        }

        emit LogTaskCanceled(_id, _order);
    }

    // solhint-disable-next-line function-max-lines
    function editNumTrades(
        Order calldata _order,
        uint256 _id,
        uint256 _newNumTradesLeft
    ) external payable {
        require(
            _order.nTradesLeft != _newNumTradesLeft,
            "GelatoKrystal: order does not need update"
        );
        Order memory newOrder =
            Order({
                user: _order.user,
                inToken: _order.inToken,
                outToken: _order.outToken,
                amountPerTrade: _order.amountPerTrade,
                nTradesLeft: _newNumTradesLeft, // the only changable field for now
                minSlippage: _order.minSlippage,
                maxSlippage: _order.maxSlippage,
                delay: _order.delay,
                maxTxFeeBPS: _order.maxTxFeeBPS,
                lastExecutionTime: _order.lastExecutionTime,
                cycleId: _order.cycleId
            });
        _updateTask(abi.encode(_order), abi.encode(newOrder), _id, msg.sender);
        if (_order.inToken == _ETH) {
            if (_order.nTradesLeft > _newNumTradesLeft) {
                uint256 refundAmount =
                    _order.amountPerTrade.mul(
                        _order.nTradesLeft.sub(_newNumTradesLeft)
                    );
                _order.user.call{value: refundAmount, gas: 2300}("");
            } else {
                uint256 topUpAmount =
                    _order.amountPerTrade.mul(
                        _newNumTradesLeft.sub(_order.nTradesLeft)
                    );
                require(
                    topUpAmount == msg.value,
                    "GelatoKrystal: mismatching amount of ETH deposited"
                );
            }
        }

        emit LogTaskUpdated(_id, _order);
    }

    function execUniOrSushi(
        Order calldata _order,
        uint256 _id,
        address[] calldata _uniswapTradePath,
        bool isUni
    )
        external
        gelatofy(
            _order.outToken,
            _order.user,
            abi.encode(_order),
            _id,
            _order.maxTxFeeBPS
        )
    {
        // action exec
        _actionUniOrSushi(_order, _uniswapTradePath, isUni);

        // task cycle logic
        if (_order.nTradesLeft > 0) _updateAndSubmitNextTask(_order);
    }

    // solhint-enable max-line-length

    function execKyber(Order calldata _order, uint256 _id)
        external
        gelatofy(
            _order.outToken,
            _order.user,
            abi.encode(_order),
            _id,
            _order.maxTxFeeBPS
        )
    {
        // action exec
        _actionKyber(_order);

        // task cycle logic
        if (_order.nTradesLeft > 0) _updateAndSubmitNextTask(_order);
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
            IOracleAggregator(gelato.getOracleAggregator())
                .getExpectedReturnAmount(
                _order.amountPerTrade,
                _order.inToken,
                _order.outToken
            );

        // check time (reverts if block.timestamp is below execTime)
        uint256 timeSinceCanExec =
            block.timestamp - (_order.lastExecutionTime + _order.delay); // solhint-disable-line not-rely-on-time, max-line-length

        uint256 minSlippageFactor = TOTAL_BPS.sub(_order.minSlippage);
        uint256 maxSlippageFactor = TOTAL_BPS.sub(_order.maxSlippage);
        uint256 slippage;
        if (minSlippageFactor > timeSinceCanExec) {
            slippage = minSlippageFactor.sub(timeSinceCanExec);
        }

        if (maxSlippageFactor > slippage) {
            slippage = maxSlippageFactor;
        }

        minReturn = idealReturn.sub(idealReturn.mul(slippage).div(TOTAL_BPS));
    }

    // ############# PRIVATE #############
    function _actionKyber(Order memory _order) private {
        //uint256 startGas = gasleft();
        (uint256 ethToSend, uint256 minReturn) = _preExec(_order);
        //console.log("Gas Used in getMinReturn: %s", startGas-gasleft()));
        //startGas = gasleft();

        smartWalletSwap.swapKyber{value: ethToSend}(
            IERC20(_order.inToken),
            IERC20(_order.outToken),
            _order.amountPerTrade,
            minReturn / _order.amountPerTrade,
            payable(address(this)),
            PLATFORM_FEE_BPS,
            platformWallet,
            HINT,
            false
        );
        //console.log("Gas used in swapKyber: %s", startGas-gasleft()));
    }

    function _actionUniOrSushi(
        Order memory _order,
        address[] memory _uniswapTradePath,
        bool _isUni
    ) private {
        //uint256 startGas = gasleft();
        (uint256 ethToSend, uint256 minReturn) = _preExec(_order);
        //console.log("Gas Used in getMinReturn: %s", startGas-gasleft()));
        //startGas = gasleft();

        require(
            _order.inToken == _uniswapTradePath[0] &&
                _order.outToken ==
                _uniswapTradePath[_uniswapTradePath.length - 1],
            "GelatoKrystal: Uniswap trade path does not match order."
        );
        smartWalletSwap.swapUniswap{value: ethToSend}(
            _isUni ? uniRouterV2 : sushiRouterV2,
            _order.amountPerTrade,
            minReturn,
            _uniswapTradePath,
            payable(address(this)),
            PLATFORM_FEE_BPS,
            platformWallet,
            false,
            false
        );

        //console.log("Gas used in swapKyber: %s", startGas-gasleft()));
    }

    function _preExec(Order memory _order)
        private
        returns (uint256 ethToSend, uint256 minReturn)
    {
        if (_order.inToken != _ETH) {
            IERC20(_order.inToken).safeTransferFrom(
                _order.user,
                address(this),
                _order.amountPerTrade
            );
            IERC20(_order.inToken).safeApprove(
                address(smartWalletSwap),
                _order.amountPerTrade
            );
        } else {
            ethToSend = _order.amountPerTrade;
        }
        //uint256 startGas = gasleft();
        minReturn = getMinReturn(_order);
    }

    function _updateAndSubmitNextTask(Order memory _order) private {
        // update next order
        _order.nTradesLeft = _order.nTradesLeft - 1;
        _order.lastExecutionTime = block.timestamp; // solhint-disable-line not-rely-on-time

        _storeOrder(_order, _order.user);
    }

    function _storeOrder(Order memory _order, address _user) private {
        uint256 id = _storeTask(abi.encode(_order), _user);
        emit LogTaskSubmitted(id, _order);
    }

    // ############# Fallback #############
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
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

contract ServicePostExecFee is TaskStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 internal constant _GAS_OVERHEAD = 50000;
    uint256 public constant TOTAL_BPS = 10000;

    IGelatoDiamond public immutable gelato;

    event LogExecSuccess(
        uint256 indexed taskId,
        address indexed executor,
        uint256 postExecFee,
        address feeToken
    );

    constructor(address _gelato) {
        gelato = IGelatoDiamond(_gelato);
    }

    modifier gelatofy(
        address _outToken,
        address _user,
        bytes memory _bytesBlob,
        uint256 _id,
        uint256 _maxTxFeeBPS
    ) {
        // start gas measurement and check if msg.sender is Gelato
        uint256 gasStart = gasleft();

        // Check only Gelato is calling
        require(
            address(gelato) == msg.sender,
            "GelatoServiceStandard: Caller is not the executorModule"
        );

        // Verify tasks actually exists
        require(
            verifyTask(_bytesBlob, _id, _user),
            "GelatoServiceStandard: invalid task"
        );

        // update TaskStorage state before execution
        _removeTask(_bytesBlob, _id, _user);

        // query Balance
        uint256 preBalance;
        if (_outToken == _ETH) {
            preBalance = address(this).balance;
        } else {
            // query Balance
            preBalance = IERC20(_outToken).balanceOf(address(this));
        }
        //console.log("Gas Used in preExec: %s", gasStart.sub(gasleft()));

        // Execute Logic
        _;

        //uint256 gasLast = gasleft();

        // handle payment
        uint256 received;
        if (_outToken == _ETH) {
            received = address(this).balance.sub(preBalance);
        } else {
            received = IERC20(_outToken).balanceOf(address(this)).sub(
                preBalance
            );
        }

        uint256 fee =
            _handlePayments(received, _outToken, gasStart, _user, _maxTxFeeBPS);

        // emit event
        emit LogExecSuccess(_id, tx.origin, fee, _outToken);
        //console.log("Gas Used in postExec: %s", gasLast.sub(gasleft()));
    }

    /// ################# VIEW ################
    function currentTaskId() public view returns (uint256) {
        return taskId;
    }

    function getGasPrice() public view returns (uint256) {
        uint256 oracleGasPrice =
            uint256(
                IChainlinkOracle(gelato.getGasPriceOracle()).latestAnswer()
            );

        // Use tx.gasprice capped at 1.3x Chainlink Oracle
        return
            tx.gasprice <= oracleGasPrice.mul(130).div(100)
                ? tx.gasprice
                : oracleGasPrice.mul(130).div(100);
    }

    function verifyTask(
        bytes memory _bytesBlob,
        uint256 _id,
        address _user
    ) public view returns (bool) {
        // Check whether order is valid
        bytes32 execTaskHash = hashTask(_bytesBlob, _id);
        return taskOwner[execTaskHash] == _user;
    }

    /// ############## INTERNAL ##############
    function _getGelatoFee(
        uint256 _gasStart,
        address _outToken,
        uint256 // _received
    ) private view returns (uint256 gelatoFee) {
        uint256 gasFeeEth =
            _gasStart.sub(gasleft()).add(_GAS_OVERHEAD).mul(getGasPrice());

        // returns purely the ethereum tx fee
        (uint256 gasFeeTokenAmount, ) =
            IOracleAggregator(gelato.getOracleAggregator())
                .getExpectedReturnAmount(gasFeeEth, _ETH, _outToken);

        // add 7 bps on top of Ethereum tx fee
        // gelatoFee = ethTxFee.add(_received.mul(7).div(10000));

        gelatoFee = gasFeeTokenAmount;
    }

    function _handlePayments(
        uint256 _received,
        address _outToken,
        uint256 _gasStart,
        address _user,
        uint256 _maxTxFeeBPS
    ) private returns (uint256) {
        // Get fee payable to Gelato
        uint256 txFee = _getGelatoFee(_gasStart, _outToken, _received);
        require(
            _received.mul(_maxTxFeeBPS).div(TOTAL_BPS) >= txFee,
            "Transaction fee exceeds user specified maximum"
        );
        if (_outToken == _ETH) {
            // Pay Gelato
            (bool success, ) = tx.origin.call{value: txFee}("");
            require(success, "ServicePostExecFee: _handlePayments: Revert 1");

            // Send remaining tokens to user
            uint256 userAmt = _received.sub(txFee);
            (success, ) = _user.call{value: userAmt}("");
            require(success, "ServicePostExecFee: _handlePayments: Revert 2");
        } else {
            // Pay Gelato
            IERC20(_outToken).safeTransfer(tx.origin, txFee);

            // Send remaining tokens to user
            IERC20(_outToken).safeTransfer(_user, _received.sub(txFee));
        }

        return txFee;
    }
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

    function hashTask(bytes memory _bytesBlob, uint256 _taskId)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_bytesBlob, _taskId));
    }

    function _storeTask(bytes memory _bytesBlob, address _owner)
        internal
        returns (uint256 newTaskId)
    {
        newTaskId = taskId + 1;
        taskId = newTaskId;

        bytes32 taskHash = hashTask(_bytesBlob, taskId);
        taskOwner[taskHash] = _owner;

        emit LogTaskStored(taskId, _owner, taskHash, _bytesBlob);
    }

    function _removeTask(
        bytes memory _bytesBlob,
        uint256 _taskId,
        address _owner
    ) internal {
        // Only address which created task can delete it
        bytes32 taskHash = hashTask(_bytesBlob, _taskId);
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

library DataTypes {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IAaveLendingPoolV1 {
    function deposit(
        address _reserve,
        uint256 _amount,
        uint16 _referralCode
    ) external payable;

    function borrow(
        address _reserve,
        uint256 _amount,
        uint256 _interestRateMode,
        uint16 _referralCode
    ) external;

    function repay(
        address _reserve,
        uint256 _amount,
        address payable _onBehalfOf
    ) external payable;

    function core() external view returns (address);
}

interface IAToken {
    function redeem(uint256 _amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./DataTypes.sol";
import "./IProtocolDataProvider.sol";

// solhint-disable max-line-length
interface IAaveLendingPoolV2 {
    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
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
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
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
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
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
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface ICompErc20 {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external view returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function totalBorrowsCurrent() external view returns (uint256);

    function borrowBalanceCurrent(address account)
        external
        view
        returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function exchangeRateCurrent() external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function underlying() external view returns (address);
}

interface ICompEth {
    function mint() external payable;

    function repayBorrowBehalf(address borrower) external payable;

    function repayBorrow() external payable;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.0;

interface IProtocolDataProvider {
    struct TokenData {
        string symbol;
        address tokenAddress;
    }

    function getAllReservesTokens() external view returns (TokenData[] memory);

    function getAllATokens() external view returns (TokenData[] memory);

    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );

    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    IERC20
} from "../../vendor/openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAaveLendingPoolV2.sol";
import "./IAaveLendingPoolV1.sol";
import "./IWeth.sol";
import "./ICompErc20.sol";

interface ISmartWalletLending {
    enum LendingPlatform {AAVE_V1, AAVE_V2, COMPOUND}
    event ClaimedComp(
        address[] holders,
        ICompErc20[] cTokens,
        bool borrowers,
        bool suppliers
    );

    function updateAaveLendingPoolData(
        IAaveLendingPoolV2 poolV2,
        IAaveLendingPoolV1 poolV1,
        uint16 referalCode,
        IWeth weth,
        IERC20[] calldata tokens
    ) external;

    function updateCompoundData(
        address _comToken,
        address _cEth,
        address[] calldata _cTokens
    ) external;

    function depositTo(
        LendingPlatform platform,
        address payable onBehalfOf,
        IERC20 token,
        uint256 amount
    ) external;

    function withdrawFrom(
        LendingPlatform platform,
        address payable onBehalfOf,
        IERC20 token,
        uint256 amount,
        uint256 minReturn
    ) external returns (uint256 returnedAmount);

    function repayBorrowTo(
        LendingPlatform platform,
        address payable onBehalfOf,
        IERC20 token,
        uint256 amount,
        uint256 payAmount,
        uint256 rateMode // only for aave v2
    ) external;

    function claimComp(
        address[] calldata holders,
        ICompErc20[] calldata cTokens,
        bool borrowers,
        bool suppliers
    ) external;

    function getLendingToken(LendingPlatform platform, IERC20 token)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./ISmartWalletLending.sol";
import {
    IERC20
} from "../../vendor/openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "../dapps/Uniswap/IUniswapV2Router02.sol";

interface ISmartWalletSwapImplementation {
    event KyberTrade(
        address indexed trader,
        IERC20 indexed src,
        IERC20 indexed dest,
        uint256 srcAmount,
        uint256 destAmount,
        address recipient,
        uint256 platformFeeBps,
        address platformWallet,
        bytes hint,
        bool useGasToken,
        uint256 numGasBurns
    );

    event UniswapTrade(
        address indexed trader,
        address indexed router,
        address[] tradePath,
        uint256 srcAmount,
        uint256 destAmount,
        address recipient,
        uint256 platformFeeBps,
        address platformWallet,
        bool feeInSrc,
        bool useGasToken,
        uint256 numGasBurns
    );

    event KyberTradeAndDeposit(
        address indexed trader,
        ISmartWalletLending.LendingPlatform indexed platform,
        IERC20 src,
        IERC20 indexed dest,
        uint256 srcAmount,
        uint256 destAmount,
        uint256 platformFeeBps,
        address platformWallet,
        bytes hint,
        bool useGasToken,
        uint256 numGasBurns
    );

    event UniswapTradeAndDeposit(
        address indexed trader,
        ISmartWalletLending.LendingPlatform indexed platform,
        IUniswapV2Router02 indexed router,
        address[] tradePath,
        uint256 srcAmount,
        uint256 destAmount,
        uint256 platformFeeBps,
        address platformWallet,
        bool useGasToken,
        uint256 numGasBurns
    );

    event WithdrawFromLending(
        ISmartWalletLending.LendingPlatform indexed platform,
        IERC20 token,
        uint256 amount,
        uint256 minReturn,
        uint256 actualReturnAmount,
        bool useGasToken,
        uint256 numGasBurns
    );

    event KyberTradeAndRepay(
        address indexed trader,
        ISmartWalletLending.LendingPlatform indexed platform,
        IERC20 src,
        IERC20 indexed dest,
        uint256 srcAmount,
        uint256 destAmount,
        uint256 payAmount,
        uint256 feeAndRateMode,
        address platformWallet,
        bytes hint,
        bool useGasToken,
        uint256 numGasBurns
    );

    event UniswapTradeAndRepay(
        address indexed trader,
        ISmartWalletLending.LendingPlatform indexed platform,
        IUniswapV2Router02 indexed router,
        address[] tradePath,
        uint256 srcAmount,
        uint256 destAmount,
        uint256 payAmount,
        uint256 feeAndRateMode,
        address platformWallet,
        bool useGasToken,
        uint256 numGasBurns
    );

    function swapKyber(
        IERC20 src,
        IERC20 dest,
        uint256 srcAmount,
        uint256 minConversionRate,
        address payable recipient,
        uint256 platformFeeBps,
        address payable platformWallet,
        bytes calldata hint,
        bool useGasToken
    ) external payable returns (uint256 destAmount);

    function swapUniswap(
        IUniswapV2Router02 router,
        uint256 srcAmount,
        uint256 minDestAmount,
        address[] calldata tradePath,
        address payable recipient,
        uint256 platformFeeBps,
        address payable platformWallet,
        bool feeInSrc,
        bool useGasToken
    ) external payable returns (uint256 destAmount);

    function swapKyberAndDeposit(
        ISmartWalletLending.LendingPlatform platform,
        IERC20 src,
        IERC20 dest,
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 platformFeeBps,
        address payable platformWallet,
        bytes calldata hint,
        bool useGasToken
    ) external payable returns (uint256 destAmount);

    function swapUniswapAndDeposit(
        ISmartWalletLending.LendingPlatform platform,
        IUniswapV2Router02 router,
        uint256 srcAmount,
        uint256 minDestAmount,
        address[] calldata tradePath,
        uint256 platformFeeBps,
        address payable platformWallet,
        bool useGasToken
    ) external payable returns (uint256 destAmount);

    function withdrawFromLendingPlatform(
        ISmartWalletLending.LendingPlatform platform,
        IERC20 token,
        uint256 amount,
        uint256 minReturn,
        bool useGasToken
    ) external returns (uint256 returnedAmount);

    // solhint-disable max-line-length
    function swapKyberAndRepay(
        ISmartWalletLending.LendingPlatform platform,
        IERC20 src,
        IERC20 dest,
        uint256 srcAmount,
        uint256 payAmount,
        uint256 feeAndRateMode, // in case aave v2, fee: feeAndRateMode % BPS, rateMode: feeAndRateMode / BPS
        address payable platformWallet,
        bytes calldata hint,
        bool useGasToken
    ) external payable returns (uint256 destAmount);

    function swapUniswapAndRepay(
        ISmartWalletLending.LendingPlatform platform,
        IUniswapV2Router02 router,
        uint256 srcAmount,
        uint256 payAmount,
        address[] calldata tradePath,
        uint256 feeAndRateMode, // in case aave v2, fee: feeAndRateMode % BPS, rateMode: feeAndRateMode / BPS
        address payable platformWallet,
        bool useGasToken
    ) external payable returns (uint256 destAmount);

    // solhint-enable max-line-length

    function claimComp(
        address[] calldata holders,
        ICompErc20[] calldata cTokens,
        bool borrowers,
        bool suppliers,
        bool useGasToken
    ) external;

    function claimPlatformFees(
        address[] calldata plaftformWallets,
        IERC20[] calldata tokens
    ) external;

    function getExpectedReturnKyber(
        IERC20 src,
        IERC20 dest,
        uint256 srcAmount,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external view returns (uint256 destAmount, uint256 expectedRate);

    function getExpectedReturnUniswap(
        IUniswapV2Router02 router,
        uint256 srcAmount,
        address[] calldata tradePath,
        uint256 platformFeeBps
    ) external view returns (uint256 destAmount, uint256 expectedRate);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {
    IERC20
} from "../../vendor/openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWeth is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
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