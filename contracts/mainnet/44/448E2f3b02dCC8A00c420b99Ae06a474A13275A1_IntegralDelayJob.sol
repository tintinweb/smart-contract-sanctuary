// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./interfaces/IIntegralDelay.sol";
import "./interfaces/IKeep3rV1.sol";
import "./interfaces/IERC20.sol";

contract IntegralDelayJob {
    address public governance;
    address public pendingGovernance;

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IKeep3rV1 public constant KP3R = IKeep3rV1(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);

    address public integralDelay; // 0x8743cc30727e9E460A5E69E217893f42DFad1650
    uint256 internal constant decimals = 10000;
    uint256 internal reducedPaymentPercent;
    uint256 internal n = 10;

    constructor(address _integralDelay, uint256 _reducedPaymentPercent) {
        governance = msg.sender;
        integralDelay = _integralDelay;
        reducedPaymentPercent = _reducedPaymentPercent;
    }

    receive() external payable {}

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!G");
        pendingGovernance = _governance;
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "!pG");
        governance = pendingGovernance;
    }

    function setIntegralDelay(address _integralDelay) external {
        require(msg.sender == governance, "!G");
        integralDelay = _integralDelay;
    }

    function setReducedPaymentPercent(uint256 _reducedPaymentPercent) external {
        require(msg.sender == governance, "!G");
        reducedPaymentPercent = _reducedPaymentPercent;
    }

    function setN(uint256 _n) external {
        require(msg.sender == governance, "!G");
        n = _n;
    }

    function getRewards(address erc20) external {
        require(msg.sender == governance, "!G");
        if (erc20 == ETH) return payable(governance).transfer(address(this).balance);
        IERC20(erc20).transfer(governance, IERC20(erc20).balanceOf(address(this)));
    }

    function work() external upkeep {
        require(workable(), "!W");
        IIntegralDelay(integralDelay).execute(n);
    }

    function workForFree() external keeper {
        IIntegralDelay(integralDelay).execute(n);
    }

    function workable() public view returns (bool canWork) {
        uint256 botExecuteTime = IIntegralDelay(integralDelay).botExecuteTime();
        for (uint256 i = 0; i < n; i++) {
            uint256 lastProcessedOrderId = IIntegralDelay(integralDelay).lastProcessedOrderId();
            if (IIntegralDelay(integralDelay).isOrderCanceled(lastProcessedOrderId + 1)) {
                continue;
            }
            (Orders.OrderType orderType, uint256 validAfterTimestamp) = IIntegralDelay(integralDelay).getOrder(lastProcessedOrderId + 1);
            if (orderType == Orders.OrderType.Empty || validAfterTimestamp >= block.timestamp) {
                break;
            }
            if (block.timestamp >= validAfterTimestamp + botExecuteTime) {
                return true;
            }
        }
        return false;
    }

    modifier keeper() {
        require(KP3R.keepers(msg.sender), "!K");
        _;
    }

    modifier upkeep() {
        uint256 _gasUsed = gasleft();
        require(KP3R.keepers(msg.sender), "!K");
        _;
        uint256 _received = KP3R.KPRH().getQuoteLimit(_gasUsed - gasleft());
        uint256 _fairPayment = (_received * decimals) / reducedPaymentPercent;
        KP3R.receipt(address(KP3R), msg.sender, _fairPayment);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "./IOrders.sol";

interface IIntegralDelay {
    function lastProcessedOrderId() external view returns (uint256);

    function isOrderCanceled(uint256 orderId) external view returns (bool);

    function getOrder(uint256 orderId) external view returns (Orders.OrderType orderType, uint256 validAfterTimestamp);

    function botExecuteTime() external view returns (uint256);

    function execute(uint256 n) external;

    // event OrderExecuted(uint256 indexed id, bool indexed success, bytes data, uint256 gasSpent, uint256 ethRefunded);
    // event RefundFailed(address indexed to, address indexed token, uint256 amount, bytes data);
    // event EthRefund(address indexed to, bool indexed success, uint256 value);
    // event OwnerSet(address owner);
    // event BotSet(address bot);
    // event DelaySet(uint256 delay);
    // event MaxGasLimitSet(uint256 maxGasLimit);
    // event GasPriceInertiaSet(uint256 gasPriceInertia);
    // event MaxGasPriceImpactSet(uint256 maxGasPriceImpact);
    // event TransferGasCostSet(address token, uint256 gasCost);
    // event OrderDisabled(address pair, Orders.OrderType orderType, bool disabled);
    // event UnwrapFailed(address to, uint256 amount);
    // event Execute(address sender, uint256 n);

    // function factory() external returns (address);

    // function owner() external returns (address);

    // function bot() external returns (address);

    // function gasPriceInertia() external returns (uint256);

    // function gasPrice() external returns (uint256);

    // function maxGasPriceImpact() external returns (uint256);

    // function maxGasLimit() external returns (uint256);

    // function delay() external returns (uint256);

    // function totalShares(address token) external returns (uint256);

    // function weth() external returns (address);

    // function getTransferGasCost(address token) external returns (uint256);

    // function getDepositOrder(uint256 orderId) external returns (Orders.DepositOrder memory order);

    // function getWithdrawOrder(uint256 orderId) external returns (Orders.WithdrawOrder memory order);

    // function getSellOrder(uint256 orderId) external returns (Orders.SellOrder memory order);

    // function getBuyOrder(uint256 orderId) external returns (Orders.BuyOrder memory order);

    // function getDepositDisabled(address pair) external returns (bool);

    // function getWithdrawDisabled(address pair) external returns (bool);

    // function getBuyDisabled(address pair) external returns (bool);

    // function getSellDisabled(address pair) external returns (bool);

    // function getOrderStatus(uint256 orderId) external returns (Orders.OrderStatus);

    // function setOrderDisabled(
    //     address pair,
    //     Orders.OrderType orderType,
    //     bool disabled
    // ) external;

    // function setOwner(address _owner) external;

    // function setBot(address _bot) external;

    // function setMaxGasLimit(uint256 _maxGasLimit) external;

    // function setDelay(uint256 _delay) external;

    // function setGasPriceInertia(uint256 _gasPriceInertia) external;

    // function setMaxGasPriceImpact(uint256 _maxGasPriceImpact) external;

    // function setTransferGasCost(address token, uint256 gasCost) external;

    // function deposit(Orders.DepositParams memory depositParams) external payable returns (uint256 orderId);

    // function withdraw(Orders.WithdrawParams memory withdrawParams) external payable returns (uint256 orderId);

    // function sell(Orders.SellParams memory sellParams) external payable returns (uint256 orderId);

    // function buy(Orders.BuyParams memory buyParams) external payable returns (uint256 orderId);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

interface IKeep3rV1Helper {
    function getQuoteLimit(uint256 gasUsed) external view returns (uint256);
}

interface IKeep3rV1 {
    function keepers(address keeper) external returns (bool);

    function KPRH() external view returns (IKeep3rV1Helper);

    function receipt(
        address credit,
        address keeper,
        uint256 amount
    ) external;

    function workReceipt(address keeper, uint256 amount) external;

    function addJob(address job) external;

    function addKPRCredit(address job, uint256 amount) external;

    function bond(address bonding, uint256 amount) external;

    function activate(address bonding) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

library Orders {
    enum OrderType {Empty, Deposit, Withdraw, Sell, Buy}
    enum OrderStatus {NonExistent, EnqueuedWaiting, EnqueuedReady, ExecutedSucceeded, ExecutedFailed, Canceled}

    event MaxGasLimitSet(uint256 maxGasLimit);
    event GasPriceInertiaSet(uint256 gasPriceInertia);
    event MaxGasPriceImpactSet(uint256 maxGasPriceImpact);
    event TransferGasCostSet(address token, uint256 gasCost);

    event DepositEnqueued(uint256 indexed orderId, uint128 validAfterTimestamp, uint256 gasPrice);
    event WithdrawEnqueued(uint256 indexed orderId, uint128 validAfterTimestamp, uint256 gasPrice);
    event SellEnqueued(uint256 indexed orderId, uint128 validAfterTimestamp, uint256 gasPrice);
    event BuyEnqueued(uint256 indexed orderId, uint128 validAfterTimestamp, uint256 gasPrice);

    struct PairInfo {
        address pair;
        address token0;
        address token1;
    }

    struct Data {
        uint256 delay;
        uint256 newestOrderId;
        uint256 lastProcessedOrderId;
        mapping(uint256 => StoredOrder) orderQueue;
        address factory;
        uint256 maxGasLimit;
        uint256 gasPrice;
        uint256 gasPriceInertia;
        uint256 maxGasPriceImpact;
        mapping(uint32 => PairInfo) pairs;
        mapping(address => uint256) transferGasCosts;
        mapping(uint256 => bool) canceled;
        mapping(address => bool) depositDisabled;
        mapping(address => bool) withdrawDisabled;
        mapping(address => bool) buyDisabled;
        mapping(address => bool) sellDisabled;
    }

    struct StoredOrder {
        // slot 1
        uint8 orderType;
        uint32 validAfterTimestamp;
        uint8 unwrapAndFailure;
        uint32 deadline;
        uint32 gasLimit;
        uint32 gasPrice;
        uint112 liquidityOrRatio;
        // slot 1
        uint112 value0;
        uint112 value1;
        uint32 pairId;
        // slot2
        address to;
        uint32 minRatioChangeToSwap;
        uint32 minSwapPrice;
        uint32 maxSwapPrice;
    }

    struct DepositOrder {
        uint32 pairId;
        uint256 share0;
        uint256 share1;
        uint256 initialRatio;
        uint256 minRatioChangeToSwap;
        uint256 minSwapPrice;
        uint256 maxSwapPrice;
        bool unwrap;
        address to;
        uint256 gasPrice;
        uint256 gasLimit;
        uint256 deadline;
    }

    struct WithdrawOrder {
        uint32 pairId;
        uint256 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        bool unwrap;
        address to;
        uint256 gasPrice;
        uint256 gasLimit;
        uint256 deadline;
    }

    struct SellOrder {
        uint32 pairId;
        bool inverse;
        uint256 shareIn;
        uint256 amountOutMin;
        bool unwrap;
        address to;
        uint256 gasPrice;
        uint256 gasLimit;
        uint256 deadline;
    }

    struct BuyOrder {
        uint32 pairId;
        bool inverse;
        uint256 shareInMax;
        uint256 amountOut;
        bool unwrap;
        address to;
        uint256 gasPrice;
        uint256 gasLimit;
        uint256 deadline;
    }

    struct DepositParams {
        address token0;
        address token1;
        uint256 amount0;
        uint256 amount1;
        uint256 initialRatio;
        uint256 minRatioChangeToSwap;
        uint256 minSwapPrice;
        uint256 maxSwapPrice;
        bool wrap;
        address to;
        uint256 gasLimit;
        uint256 submitDeadline;
        uint256 executionDeadline;
    }

    struct WithdrawParams {
        address token0;
        address token1;
        uint256 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        bool unwrap;
        address to;
        uint256 gasLimit;
        uint256 submitDeadline;
        uint256 executionDeadline;
    }

    struct SellParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        bool wrapUnwrap;
        address to;
        uint256 gasLimit;
        uint256 submitDeadline;
        uint256 executionDeadline;
    }

    struct BuyParams {
        address tokenIn;
        address tokenOut;
        uint256 amountInMax;
        uint256 amountOut;
        bool wrapUnwrap;
        address to;
        uint256 gasLimit;
        uint256 submitDeadline;
        uint256 executionDeadline;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
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