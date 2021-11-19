// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'IERC20.sol';

interface IIntegralERC20 is IERC20 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface IReserves {
    event Sync(uint112 reserve0, uint112 reserve1);
    event Fees(uint256 fee0, uint256 fee1);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 lastTimestamp
        );

    function getReferences()
        external
        view
        returns (
            uint112 reference0,
            uint112 reference1,
            uint32 epoch
        );

    function getFees() external view returns (uint256 fee0, uint256 fee1);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'IIntegralERC20.sol';
import 'IReserves.sol';

interface IIntegralPair is IIntegralERC20, IReserves {
    event Mint(address indexed sender, address indexed to);
    event Burn(address indexed sender, address indexed to);
    event Swap(address indexed sender, address indexed to);
    event SetMintFee(uint256 fee);
    event SetBurnFee(uint256 fee);
    event SetSwapFee(uint256 fee);
    event SetOracle(address account);
    event SetTrader(address trader);
    event SetToken0AbsoluteLimit(uint256 limit);
    event SetToken1AbsoluteLimit(uint256 limit);
    event SetToken0RelativeLimit(uint256 limit);
    event SetToken1RelativeLimit(uint256 limit);
    event SetPriceDeviationLimit(uint256 limit);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function oracle() external view returns (address);

    function trader() external view returns (address);

    function mintFee() external view returns (uint256);

    function setMintFee(uint256 fee) external;

    function mint(address to) external returns (uint256 liquidity);

    function burnFee() external view returns (uint256);

    function setBurnFee(uint256 fee) external;

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swapFee() external view returns (uint256);

    function setSwapFee(uint256 fee) external;

    function setOracle(address account) external;

    function setTrader(address account) external;

    function token0AbsoluteLimit() external view returns (uint256);

    function setToken0AbsoluteLimit(uint256 limit) external;

    function token1AbsoluteLimit() external view returns (uint256);

    function setToken1AbsoluteLimit(uint256 limit) external;

    function token0RelativeLimit() external view returns (uint256);

    function setToken0RelativeLimit(uint256 limit) external;

    function token1RelativeLimit() external view returns (uint256);

    function setToken1RelativeLimit(uint256 limit) external;

    function priceDeviationLimit() external view returns (uint256);

    function setPriceDeviationLimit(uint256 limit) external;

    function collect(address to) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external;

    function sync() external;

    function initialize(
        address _token0,
        address _token1,
        address _oracle,
        address _trader
    ) external;

    function syncWithOracle() external;

    function fullSync() external;

    function getSpotPrice() external view returns (uint256 spotPrice);

    function getSwapAmount0In(uint256 amount1Out) external view returns (uint256 swapAmount0In);

    function getSwapAmount1In(uint256 amount0Out) external view returns (uint256 swapAmount1In);

    function getSwapAmount0Out(uint256 amount1In) external view returns (uint256 swapAmount0Out);

    function getSwapAmount1Out(uint256 amount0In) external view returns (uint256 swapAmount1Out);

    function getDepositAmount0In(uint256 amount0) external view returns (uint256 depositAmount0In);

    function getDepositAmount1In(uint256 amount1) external view returns (uint256 depositAmount1In);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'SM_ADD_OVERFLOW');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = sub(x, y, 'SM_SUB_UNDERFLOW');
    }

    function sub(
        uint256 x,
        uint256 y,
        string memory message
    ) internal pure returns (uint256 z) {
        require((z = x - y) <= x, message);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'SM_MUL_OVERFLOW');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SM_DIV_BY_ZERO');
        uint256 c = a / b;
        return c;
    }

    function ceil_div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = div(a, b);
        if (c == mul(a, b)) {
            return c;
        } else {
            return add(c, 1);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface IIntegralFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    event OwnerSet(address owner);

    function owner() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        address oracle,
        address trader
    ) external returns (address pair);

    function setOwner(address) external;

    function setMintFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external;

    function setBurnFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external;

    function setSwapFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external;

    function setOracle(
        address tokenA,
        address tokenB,
        address oracle
    ) external;

    function setTrader(
        address tokenA,
        address tokenB,
        address trader
    ) external;

    function collect(
        address tokenA,
        address tokenB,
        address to
    ) external;

    function withdraw(
        address tokenA,
        address tokenB,
        uint256 amount,
        address to
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity =0.7.5;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH_APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH_TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH_TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, 'TH_ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'IERC20.sol';
import 'IWETH.sol';
import 'SafeMath.sol';
import 'TransferHelper.sol';

library TokenShares {
    using SafeMath for uint256;
    using TransferHelper for address;

    event UnwrapFailed(address to, uint256 amount);

    struct Data {
        mapping(address => uint256) totalShares;
        address weth;
    }

    function setWeth(Data storage data, address _weth) internal {
        data.weth = _weth;
    }

    function sharesToAmount(
        Data storage data,
        address token,
        uint256 share
    ) external returns (uint256) {
        if (share == 0) {
            return 0;
        }
        if (token == data.weth) {
            return share;
        }
        require(data.totalShares[token] >= share, 'TS_INSUFFICIENT_BALANCE');
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 value = balance.mul(share).div(data.totalShares[token]);
        data.totalShares[token] = data.totalShares[token].sub(share);
        return value;
    }

    function amountToShares(
        Data storage data,
        address token,
        uint256 amount,
        bool wrap
    ) external returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        if (token == data.weth) {
            if (wrap) {
                require(msg.value >= amount, 'TS_INSUFFICIENT_AMOUNT');
                IWETH(token).deposit{ value: amount }();
            } else {
                token.safeTransferFrom(msg.sender, address(this), amount);
            }
            return amount;
        } else {
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            require(balanceBefore > 0 || data.totalShares[token] == 0, 'TS_INVALID_SHARES');
            if (data.totalShares[token] == 0) {
                data.totalShares[token] = balanceBefore;
            }
            token.safeTransferFrom(msg.sender, address(this), amount);
            uint256 balanceAfter = IERC20(token).balanceOf(address(this));
            require(balanceAfter > balanceBefore, 'TS_INVALID_TRANSFER');
            if (balanceBefore > 0) {
                uint256 lastShares = data.totalShares[token];
                data.totalShares[token] = lastShares.mul(balanceAfter).div(balanceBefore);
                return data.totalShares[token] - lastShares;
            } else {
                data.totalShares[token] = balanceAfter;
                data.totalShares[token] = balanceAfter;
                return balanceAfter;
            }
        }
    }

    function onUnwrapFailed(
        Data storage data,
        address to,
        uint256 amount
    ) external {
        emit UnwrapFailed(to, amount);
        IWETH(data.weth).deposit{ value: amount }();
        TransferHelper.safeTransfer(data.weth, to, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import 'SafeMath.sol';
import 'Math.sol';
import 'IIntegralFactory.sol';
import 'IIntegralPair.sol';
import 'TokenShares.sol';

library Orders {
    using SafeMath for uint256;
    using TokenShares for TokenShares.Data;
    using TransferHelper for address;

    enum OrderType { Empty, Deposit, Withdraw, Sell, Buy }
    enum OrderStatus { NonExistent, EnqueuedWaiting, EnqueuedReady, ExecutedSucceeded, ExecutedFailed, Canceled }

    event MaxGasLimitSet(uint256 maxGasLimit);
    event GasPriceInertiaSet(uint256 gasPriceInertia);
    event MaxGasPriceImpactSet(uint256 maxGasPriceImpact);
    event TransferGasCostSet(address token, uint256 gasCost);

    event DepositEnqueued(uint256 indexed orderId, uint128 validAfterTimestamp, uint256 gasPrice);
    event WithdrawEnqueued(uint256 indexed orderId, uint128 validAfterTimestamp, uint256 gasPrice);
    event SellEnqueued(uint256 indexed orderId, uint128 validAfterTimestamp, uint256 gasPrice);
    event BuyEnqueued(uint256 indexed orderId, uint128 validAfterTimestamp, uint256 gasPrice);

    uint8 private constant DEPOSIT_TYPE = 1;
    uint8 private constant WITHDRAW_TYPE = 2;
    uint8 private constant BUY_TYPE = 3;
    uint8 private constant BUY_INVERTED_TYPE = 4;
    uint8 private constant SELL_TYPE = 5;
    uint8 private constant SELL_INVERTED_TYPE = 6;

    uint8 private constant UNWRAP_NOT_FAILED = 0;
    uint8 private constant KEEP_NOT_FAILED = 1;
    uint8 private constant UNWRAP_FAILED = 2;
    uint8 private constant KEEP_FAILED = 3;

    uint256 private constant ETHER_TRANSFER_COST = 2300;
    uint256 private constant BUFFER_COST = 10000;
    uint256 private constant EXECUTE_PREPARATION_COST = 55000; // dequeue + getPair in execute

    uint256 public constant ETHER_TRANSFER_CALL_COST = 10000;
    uint256 public constant PAIR_TRANSFER_COST = 55000;
    uint256 public constant REFUND_END_COST = 2 * ETHER_TRANSFER_COST + BUFFER_COST;
    uint256 public constant ORDER_BASE_COST = EXECUTE_PREPARATION_COST + REFUND_END_COST;

    uint256 private constant TIMESTAMP_OFFSET = 1609455600; // 2021 Jan 1

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

    function decodeType(uint256 internalType) internal pure returns (OrderType orderType) {
        if (internalType == DEPOSIT_TYPE) {
            orderType = OrderType.Deposit;
        } else if (internalType == WITHDRAW_TYPE) {
            orderType = OrderType.Withdraw;
        } else if (internalType == BUY_TYPE) {
            orderType = OrderType.Buy;
        } else if (internalType == BUY_INVERTED_TYPE) {
            orderType = OrderType.Buy;
        } else if (internalType == SELL_TYPE) {
            orderType = OrderType.Sell;
        } else if (internalType == SELL_INVERTED_TYPE) {
            orderType = OrderType.Sell;
        } else {
            orderType = OrderType.Empty;
        }
    }

    function getOrder(Data storage data, uint256 orderId)
        public
        view
        returns (OrderType orderType, uint256 validAfterTimestamp)
    {
        StoredOrder storage order = data.orderQueue[orderId];
        uint8 internalType = order.orderType;
        validAfterTimestamp = uint32ToTimestamp(order.validAfterTimestamp);
        orderType = decodeType(internalType);
    }

    function getOrderStatus(Data storage data, uint256 orderId) external view returns (OrderStatus orderStatus) {
        if (orderId > data.newestOrderId) {
            return OrderStatus.NonExistent;
        }
        if (data.canceled[orderId]) {
            return OrderStatus.Canceled;
        }
        if (isRefundFailed(data, orderId)) {
            return OrderStatus.ExecutedFailed;
        }
        (OrderType orderType, uint256 validAfterTimestamp) = getOrder(data, orderId);
        if (orderType == OrderType.Empty) {
            return OrderStatus.ExecutedSucceeded;
        }
        if (validAfterTimestamp >= block.timestamp) {
            return OrderStatus.EnqueuedWaiting;
        }
        return OrderStatus.EnqueuedReady;
    }

    function getPair(
        Data storage data,
        address tokenA,
        address tokenB
    )
        internal
        returns (
            address pair,
            uint32 pairId,
            bool inverted
        )
    {
        inverted = tokenA > tokenB;
        (address token0, address token1) = inverted ? (tokenB, tokenA) : (tokenA, tokenB);
        pair = IIntegralFactory(data.factory).getPair(token0, token1);
        pairId = uint32(bytes4(keccak256(abi.encodePacked((pair)))));
        require(pair != address(0), 'OS_PAIR_NONEXISTENT');
        if (data.pairs[pairId].pair == address(0)) {
            data.pairs[pairId] = PairInfo(pair, token0, token1);
        }
    }

    function getPairInfo(Data storage data, uint32 pairId)
        external
        view
        returns (
            address pair,
            address token0,
            address token1
        )
    {
        PairInfo storage info = data.pairs[pairId];
        pair = info.pair;
        token0 = info.token0;
        token1 = info.token1;
    }

    function getDepositOrder(Data storage data, uint256 index) public view returns (DepositOrder memory order) {
        StoredOrder memory stored = data.orderQueue[index];
        require(stored.orderType == DEPOSIT_TYPE, 'OS_INVALID_ORDER_TYPE');
        order.pairId = stored.pairId;
        order.share0 = stored.value0;
        order.share1 = stored.value1;
        order.initialRatio = stored.liquidityOrRatio;
        order.minRatioChangeToSwap = stored.minRatioChangeToSwap;
        order.minSwapPrice = float32ToUint(stored.minSwapPrice);
        order.maxSwapPrice = float32ToUint(stored.maxSwapPrice);
        order.unwrap = getUnwrap(stored.unwrapAndFailure);
        order.to = stored.to;
        order.gasPrice = uint32ToGasPrice(stored.gasPrice);
        order.gasLimit = stored.gasLimit;
        order.deadline = uint32ToTimestamp(stored.deadline);
    }

    function getWithdrawOrder(Data storage data, uint256 index) public view returns (WithdrawOrder memory order) {
        StoredOrder memory stored = data.orderQueue[index];
        require(stored.orderType == WITHDRAW_TYPE, 'OS_INVALID_ORDER_TYPE');
        order.pairId = stored.pairId;
        order.liquidity = stored.liquidityOrRatio;
        order.amount0Min = stored.value0;
        order.amount1Min = stored.value1;
        order.unwrap = getUnwrap(stored.unwrapAndFailure);
        order.to = stored.to;
        order.gasPrice = uint32ToGasPrice(stored.gasPrice);
        order.gasLimit = stored.gasLimit;
        order.deadline = uint32ToTimestamp(stored.deadline);
    }

    function getSellOrder(Data storage data, uint256 index) public view returns (SellOrder memory order) {
        StoredOrder memory stored = data.orderQueue[index];
        require(stored.orderType == SELL_TYPE || stored.orderType == SELL_INVERTED_TYPE, 'OS_INVALID_ORDER_TYPE');
        order.pairId = stored.pairId;
        order.inverse = stored.orderType == SELL_INVERTED_TYPE;
        order.shareIn = stored.value0;
        order.amountOutMin = stored.value1;
        order.unwrap = getUnwrap(stored.unwrapAndFailure);
        order.to = stored.to;
        order.gasPrice = uint32ToGasPrice(stored.gasPrice);
        order.gasLimit = stored.gasLimit;
        order.deadline = uint32ToTimestamp(stored.deadline);
    }

    function getBuyOrder(Data storage data, uint256 index) public view returns (BuyOrder memory order) {
        StoredOrder memory stored = data.orderQueue[index];
        require(stored.orderType == BUY_TYPE || stored.orderType == BUY_INVERTED_TYPE, 'OS_INVALID_ORDER_TYPE');
        order.pairId = stored.pairId;
        order.inverse = stored.orderType == BUY_INVERTED_TYPE;
        order.shareInMax = stored.value0;
        order.amountOut = stored.value1;
        order.unwrap = getUnwrap(stored.unwrapAndFailure);
        order.to = stored.to;
        order.gasPrice = uint32ToGasPrice(stored.gasPrice);
        order.gasLimit = stored.gasLimit;
        order.deadline = uint32ToTimestamp(stored.deadline);
    }

    function getFailedOrderType(Data storage data, uint256 orderId)
        external
        view
        returns (OrderType orderType, uint256 validAfterTimestamp)
    {
        require(isRefundFailed(data, orderId), 'OS_NO_POSSIBLE_REFUND');
        (orderType, validAfterTimestamp) = getOrder(data, orderId);
    }

    function getUnwrap(uint8 unwrapAndFailure) private pure returns (bool) {
        return unwrapAndFailure == UNWRAP_FAILED || unwrapAndFailure == UNWRAP_NOT_FAILED;
    }

    function getUnwrapAndFailure(bool unwrap) private pure returns (uint8) {
        return unwrap ? UNWRAP_NOT_FAILED : KEEP_NOT_FAILED;
    }

    function timestampToUint32(uint256 timestamp) private pure returns (uint32 timestamp32) {
        if (timestamp == uint256(-1)) {
            return uint32(-1);
        }
        timestamp32 = uintToUint32(timestamp.sub(TIMESTAMP_OFFSET));
    }

    function uint32ToTimestamp(uint32 timestamp32) private pure returns (uint256 timestamp) {
        if (timestamp32 == uint32(-1)) {
            return uint256(-1);
        }
        if (timestamp32 == 0) {
            return 0;
        }
        timestamp = uint256(timestamp32) + TIMESTAMP_OFFSET;
    }

    function gasPriceToUint32(uint256 gasPrice) private pure returns (uint32 gasPrice32) {
        require((gasPrice / 1e6) * 1e6 == gasPrice, 'OS_GAS_PRICE_PRECISION');
        gasPrice32 = uintToUint32(gasPrice / 1e6);
    }

    function uint32ToGasPrice(uint32 gasPrice32) public pure returns (uint256 gasPrice) {
        gasPrice = uint256(gasPrice32) * 1e6;
    }

    function uintToUint32(uint256 number) private pure returns (uint32 number32) {
        number32 = uint32(number);
        require(uint256(number32) == number, 'OS_OVERFLOW_32');
    }

    function uintToUint112(uint256 number) private pure returns (uint112 number112) {
        number112 = uint112(number);
        require(uint256(number112) == number, 'OS_OVERFLOW_112');
    }

    function uintToFloat32(uint256 number) internal pure returns (uint32 float32) {
        // Number is encoded on 4 bytes. 3 bytes for mantissa and 1 for exponent.
        // If the number fits in the mantissa we set the exponent to zero and return.
        if (number < 2 << 24) {
            return uint32(number << 8);
        }
        // We find the exponent by counting the number of trailing zeroes.
        // Simultaneously we remove those zeroes from the number.
        uint32 exponent;
        for (exponent = 0; exponent < 256 - 24; exponent++) {
            // Last bit is one.
            if (number & 1 == 1) {
                break;
            }
            number = number >> 1;
        }
        // The number must fit in the mantissa.
        require(number < 2 << 24, 'OS_OVERFLOW_FLOAT_ENCODE');
        // Set the first three bytes to the number and the fourth to the exponent.
        float32 = uint32(number << 8) | exponent;
    }

    function float32ToUint(uint32 float32) internal pure returns (uint256 number) {
        // Number is encoded on 4 bytes. 3 bytes for mantissa and 1 for exponent.
        // We get the exponent by extracting the last byte.
        uint256 exponent = float32 & 0xFF;
        // Sanity check. Only triggered for values not encoded with uintToFloat32.
        require(exponent <= 256 - 24, 'OS_OVERFLOW_FLOAT_DECODE');
        // We get the mantissa by extracting the first three bytes and removing the fourth.
        uint256 mantissa = (float32 & 0xFFFFFF00) >> 8;
        // We add exponent number zeroes after the mantissa.
        number = mantissa << exponent;
    }

    function enqueueDepositOrder(Data storage data, DepositOrder memory depositOrder) internal {
        data.newestOrderId++;
        uint128 validAfterTimestamp = uint128(block.timestamp + data.delay);
        emit DepositEnqueued(data.newestOrderId, validAfterTimestamp, depositOrder.gasPrice);
        data.orderQueue[data.newestOrderId] = StoredOrder(
            DEPOSIT_TYPE,
            timestampToUint32(validAfterTimestamp),
            getUnwrapAndFailure(depositOrder.unwrap),
            timestampToUint32(depositOrder.deadline),
            uintToUint32(depositOrder.gasLimit),
            gasPriceToUint32(depositOrder.gasPrice),
            uintToUint112(depositOrder.initialRatio),
            uintToUint112(depositOrder.share0),
            uintToUint112(depositOrder.share1),
            depositOrder.pairId,
            depositOrder.to,
            uint32(depositOrder.minRatioChangeToSwap),
            uintToFloat32(depositOrder.minSwapPrice),
            uintToFloat32(depositOrder.maxSwapPrice)
        );
    }

    function enqueueWithdrawOrder(Data storage data, WithdrawOrder memory withdrawOrder) internal {
        data.newestOrderId++;
        uint128 validAfterTimestamp = uint128(block.timestamp + data.delay);
        emit WithdrawEnqueued(data.newestOrderId, validAfterTimestamp, withdrawOrder.gasPrice);
        data.orderQueue[data.newestOrderId] = StoredOrder(
            WITHDRAW_TYPE,
            timestampToUint32(validAfterTimestamp),
            getUnwrapAndFailure(withdrawOrder.unwrap),
            timestampToUint32(withdrawOrder.deadline),
            uintToUint32(withdrawOrder.gasLimit),
            gasPriceToUint32(withdrawOrder.gasPrice),
            uintToUint112(withdrawOrder.liquidity),
            uintToUint112(withdrawOrder.amount0Min),
            uintToUint112(withdrawOrder.amount1Min),
            withdrawOrder.pairId,
            withdrawOrder.to,
            0, // maxRatioChange
            0, // minSwapPrice
            0 // maxSwapPrice
        );
    }

    function enqueueSellOrder(Data storage data, SellOrder memory sellOrder) internal {
        data.newestOrderId++;
        uint128 validAfterTimestamp = uint128(block.timestamp + data.delay);
        emit SellEnqueued(data.newestOrderId, validAfterTimestamp, sellOrder.gasPrice);
        data.orderQueue[data.newestOrderId] = StoredOrder(
            sellOrder.inverse ? SELL_INVERTED_TYPE : SELL_TYPE,
            timestampToUint32(validAfterTimestamp),
            getUnwrapAndFailure(sellOrder.unwrap),
            timestampToUint32(sellOrder.deadline),
            uintToUint32(sellOrder.gasLimit),
            gasPriceToUint32(sellOrder.gasPrice),
            0, // liquidityOrRatio
            uintToUint112(sellOrder.shareIn),
            uintToUint112(sellOrder.amountOutMin),
            sellOrder.pairId,
            sellOrder.to,
            0, // maxRatioChange
            0, // minSwapPrice
            0 // maxSwapPrice
        );
    }

    function enqueueBuyOrder(Data storage data, BuyOrder memory buyOrder) internal {
        data.newestOrderId++;
        uint128 validAfterTimestamp = uint128(block.timestamp + data.delay);
        emit BuyEnqueued(data.newestOrderId, validAfterTimestamp, buyOrder.gasPrice);
        data.orderQueue[data.newestOrderId] = StoredOrder(
            buyOrder.inverse ? BUY_INVERTED_TYPE : BUY_TYPE,
            timestampToUint32(validAfterTimestamp),
            getUnwrapAndFailure(buyOrder.unwrap),
            timestampToUint32(buyOrder.deadline),
            uintToUint32(buyOrder.gasLimit),
            gasPriceToUint32(buyOrder.gasPrice),
            0, // liquidityOrRatio
            uintToUint112(buyOrder.shareInMax),
            uintToUint112(buyOrder.amountOut),
            buyOrder.pairId,
            buyOrder.to,
            0, // maxRatioChange
            0, // minSwapPrice
            0 // maxSwapPrice
        );
    }

    function isRefundFailed(Data storage data, uint256 index) internal view returns (bool) {
        uint8 unwrapAndFailure = data.orderQueue[index].unwrapAndFailure;
        return unwrapAndFailure == UNWRAP_FAILED || unwrapAndFailure == KEEP_FAILED;
    }

    function markRefundFailed(Data storage data) internal {
        StoredOrder storage stored = data.orderQueue[data.lastProcessedOrderId];
        stored.unwrapAndFailure = stored.unwrapAndFailure == UNWRAP_NOT_FAILED ? UNWRAP_FAILED : KEEP_FAILED;
    }

    function getNextOrder(Data storage data) internal view returns (OrderType orderType, uint256 validAfterTimestamp) {
        return getOrder(data, data.lastProcessedOrderId + 1);
    }

    function dequeueCanceledOrder(Data storage data) external {
        data.lastProcessedOrderId++;
    }

    function dequeueDepositOrder(Data storage data) external returns (DepositOrder memory order) {
        data.lastProcessedOrderId++;
        order = getDepositOrder(data, data.lastProcessedOrderId);
    }

    function dequeueWithdrawOrder(Data storage data) external returns (WithdrawOrder memory order) {
        data.lastProcessedOrderId++;
        order = getWithdrawOrder(data, data.lastProcessedOrderId);
    }

    function dequeueSellOrder(Data storage data) external returns (SellOrder memory order) {
        data.lastProcessedOrderId++;
        order = getSellOrder(data, data.lastProcessedOrderId);
    }

    function dequeueBuyOrder(Data storage data) external returns (BuyOrder memory order) {
        data.lastProcessedOrderId++;
        order = getBuyOrder(data, data.lastProcessedOrderId);
    }

    function forgetOrder(Data storage data, uint256 orderId) internal {
        delete data.orderQueue[orderId];
    }

    function forgetLastProcessedOrder(Data storage data) internal {
        delete data.orderQueue[data.lastProcessedOrderId];
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

    function deposit(
        Data storage data,
        DepositParams calldata depositParams,
        TokenShares.Data storage tokenShares
    ) external {
        require(
            data.transferGasCosts[depositParams.token0] != 0 && data.transferGasCosts[depositParams.token1] != 0,
            'OS_TOKEN_TRANSFER_GAS_COST_UNSET'
        );
        checkOrderParams(
            data,
            depositParams.to,
            depositParams.gasLimit,
            depositParams.submitDeadline,
            depositParams.executionDeadline,
            ORDER_BASE_COST.add(data.transferGasCosts[depositParams.token0]).add(
                data.transferGasCosts[depositParams.token1]
            )
        );
        require(depositParams.amount0 != 0 || depositParams.amount1 != 0, 'OS_NO_AMOUNT');
        (address pair, uint32 pairId, bool inverted) = getPair(data, depositParams.token0, depositParams.token1);
        require(!data.depositDisabled[pair], 'OS_DEPOSIT_DISABLED');

        uint256 value = msg.value;

        // allocate gas refund
        if (depositParams.token0 == tokenShares.weth && depositParams.wrap) {
            value = value.sub(depositParams.amount0, 'OS_NOT_ENOUGH_FUNDS');
        } else if (depositParams.token1 == tokenShares.weth && depositParams.wrap) {
            value = value.sub(depositParams.amount1, 'OS_NOT_ENOUGH_FUNDS');
        }
        allocateGasRefund(data, value, depositParams.gasLimit);

        uint256 shares0 = tokenShares.amountToShares(depositParams.token0, depositParams.amount0, depositParams.wrap);
        uint256 shares1 = tokenShares.amountToShares(depositParams.token1, depositParams.amount1, depositParams.wrap);

        IIntegralPair(pair).syncWithOracle();
        enqueueDepositOrder(
            data,
            DepositOrder(
                pairId,
                inverted ? shares1 : shares0,
                inverted ? shares0 : shares1,
                depositParams.initialRatio,
                depositParams.minRatioChangeToSwap,
                depositParams.minSwapPrice,
                depositParams.maxSwapPrice,
                depositParams.wrap,
                depositParams.to,
                data.gasPrice,
                depositParams.gasLimit,
                depositParams.executionDeadline
            )
        );
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

    function withdraw(Data storage data, WithdrawParams calldata withdrawParams) external {
        (address pair, uint32 pairId, bool inverted) = getPair(data, withdrawParams.token0, withdrawParams.token1);
        require(!data.withdrawDisabled[pair], 'OS_WITHDRAW_DISABLED');
        checkOrderParams(
            data,
            withdrawParams.to,
            withdrawParams.gasLimit,
            withdrawParams.submitDeadline,
            withdrawParams.executionDeadline,
            ORDER_BASE_COST.add(PAIR_TRANSFER_COST)
        );
        require(withdrawParams.liquidity != 0, 'OS_NO_LIQUIDITY');

        allocateGasRefund(data, msg.value, withdrawParams.gasLimit);
        pair.safeTransferFrom(msg.sender, address(this), withdrawParams.liquidity);

        IIntegralPair(pair).syncWithOracle();
        enqueueWithdrawOrder(
            data,
            WithdrawOrder(
                pairId,
                withdrawParams.liquidity,
                inverted ? withdrawParams.amount1Min : withdrawParams.amount0Min,
                inverted ? withdrawParams.amount0Min : withdrawParams.amount1Min,
                withdrawParams.unwrap,
                withdrawParams.to,
                data.gasPrice,
                withdrawParams.gasLimit,
                withdrawParams.executionDeadline
            )
        );
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

    function sell(
        Data storage data,
        SellParams calldata sellParams,
        TokenShares.Data storage tokenShares
    ) external {
        require(data.transferGasCosts[sellParams.tokenIn] != 0, 'OS_TOKEN_TRANSFER_GAS_COST_UNSET');
        checkOrderParams(
            data,
            sellParams.to,
            sellParams.gasLimit,
            sellParams.submitDeadline,
            sellParams.executionDeadline,
            ORDER_BASE_COST.add(data.transferGasCosts[sellParams.tokenIn])
        );
        require(sellParams.amountIn != 0, 'OS_NO_AMOUNT_IN');
        (address pair, uint32 pairId, bool inverted) = getPair(data, sellParams.tokenIn, sellParams.tokenOut);
        require(!data.sellDisabled[pair], 'OS_SELL_DISABLED');
        uint256 value = msg.value;

        // allocate gas refund
        if (sellParams.tokenIn == tokenShares.weth && sellParams.wrapUnwrap) {
            value = value.sub(sellParams.amountIn, 'OS_NOT_ENOUGH_FUNDS');
        }
        allocateGasRefund(data, value, sellParams.gasLimit);

        uint256 shares = tokenShares.amountToShares(sellParams.tokenIn, sellParams.amountIn, sellParams.wrapUnwrap);

        IIntegralPair(pair).syncWithOracle();
        enqueueSellOrder(
            data,
            SellOrder(
                pairId,
                inverted,
                shares,
                sellParams.amountOutMin,
                sellParams.wrapUnwrap,
                sellParams.to,
                data.gasPrice,
                sellParams.gasLimit,
                sellParams.executionDeadline
            )
        );
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

    function buy(
        Data storage data,
        BuyParams calldata buyParams,
        TokenShares.Data storage tokenShares
    ) external {
        require(data.transferGasCosts[buyParams.tokenIn] != 0, 'OS_TOKEN_TRANSFER_GAS_COST_UNSET');
        checkOrderParams(
            data,
            buyParams.to,
            buyParams.gasLimit,
            buyParams.submitDeadline,
            buyParams.executionDeadline,
            ORDER_BASE_COST.add(data.transferGasCosts[buyParams.tokenIn])
        );
        require(buyParams.amountOut != 0, 'OS_NO_AMOUNT_OUT');
        (address pair, uint32 pairId, bool inverted) = getPair(data, buyParams.tokenIn, buyParams.tokenOut);
        require(!data.buyDisabled[pair], 'OS_BUY_DISABLED');

        uint256 value = msg.value;

        // allocate gas refund
        if (buyParams.tokenIn == tokenShares.weth && buyParams.wrapUnwrap) {
            value = value.sub(buyParams.amountInMax, 'OS_NOT_ENOUGH_FUNDS');
        }
        allocateGasRefund(data, value, buyParams.gasLimit);

        uint256 shares = tokenShares.amountToShares(buyParams.tokenIn, buyParams.amountInMax, buyParams.wrapUnwrap);

        IIntegralPair(pair).syncWithOracle();
        enqueueBuyOrder(
            data,
            BuyOrder(
                pairId,
                inverted,
                shares,
                buyParams.amountOut,
                buyParams.wrapUnwrap,
                buyParams.to,
                data.gasPrice,
                buyParams.gasLimit,
                buyParams.executionDeadline
            )
        );
    }

    function checkOrderParams(
        Data storage data,
        address to,
        uint256 gasLimit,
        uint256 submitDeadline,
        uint256 executionDeadline,
        uint256 minGasLimit
    ) private view {
        require(submitDeadline >= block.timestamp, 'OS_EXPIRED');
        require(executionDeadline > block.timestamp.add(data.delay), 'OS_INVALID_DEADLINE');
        require(gasLimit <= data.maxGasLimit, 'OS_GAS_LIMIT_TOO_HIGH');
        require(gasLimit >= minGasLimit, 'OS_GAS_LIMIT_TOO_LOW');
        require(to != address(0), 'OS_NO_ADDRESS');
    }

    function allocateGasRefund(
        Data storage data,
        uint256 value,
        uint256 gasLimit
    ) private returns (uint256 futureFee) {
        futureFee = data.gasPrice.mul(gasLimit);
        require(value >= futureFee, 'OS_NOT_ENOUGH_FUNDS');
        if (value > futureFee) {
            msg.sender.transfer(value.sub(futureFee));
        }
    }

    function updateGasPrice(Data storage data, uint256 gasUsed) external {
        uint256 scale = Math.min(gasUsed, data.maxGasPriceImpact);
        uint256 updated = data.gasPrice.mul(data.gasPriceInertia.sub(scale)).add(tx.gasprice.mul(scale)).div(
            data.gasPriceInertia
        );
        // we lower the precision for gas savings in order queue
        data.gasPrice = updated - (updated % 1e6);
    }

    function setMaxGasLimit(Data storage data, uint256 _maxGasLimit) external {
        require(_maxGasLimit <= 10000000, 'OS_MAX_GAS_LIMIT_TOO_HIGH');
        data.maxGasLimit = _maxGasLimit;
        emit MaxGasLimitSet(_maxGasLimit);
    }

    function setGasPriceInertia(Data storage data, uint256 _gasPriceInertia) external {
        require(_gasPriceInertia >= 1, 'OS_INVALID_INERTIA');
        data.gasPriceInertia = _gasPriceInertia;
        emit GasPriceInertiaSet(_gasPriceInertia);
    }

    function setMaxGasPriceImpact(Data storage data, uint256 _maxGasPriceImpact) external {
        require(_maxGasPriceImpact <= data.gasPriceInertia, 'OS_INVALID_MAX_GAS_PRICE_IMPACT');
        data.maxGasPriceImpact = _maxGasPriceImpact;
        emit MaxGasPriceImpactSet(_maxGasPriceImpact);
    }

    function setTransferGasCost(
        Data storage data,
        address token,
        uint256 gasCost
    ) external {
        data.transferGasCosts[token] = gasCost;
        emit TransferGasCostSet(token, gasCost);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import 'Orders.sol';

interface IIntegralDelay {
    event OrderExecuted(uint256 indexed id, bool indexed success, bytes data, uint256 gasSpent, uint256 ethRefunded);
    event RefundFailed(address indexed to, address indexed token, uint256 amount, bytes data);
    event EthRefund(address indexed to, bool indexed success, uint256 value);
    event OwnerSet(address owner);
    event BotSet(address bot, bool isBot);
    event DelaySet(uint256 delay);
    event MaxGasLimitSet(uint256 maxGasLimit);
    event GasPriceInertiaSet(uint256 gasPriceInertia);
    event MaxGasPriceImpactSet(uint256 maxGasPriceImpact);
    event TransferGasCostSet(address token, uint256 gasCost);
    event OrderDisabled(address pair, Orders.OrderType orderType, bool disabled);
    event UnwrapFailed(address to, uint256 amount);
    event Execute(address sender, uint256 n);

    function factory() external returns (address);

    function owner() external returns (address);

    function isBot(address bot) external returns (bool);

    function botExecuteTime() external returns (uint256);

    function gasPriceInertia() external returns (uint256);

    function gasPrice() external returns (uint256);

    function maxGasPriceImpact() external returns (uint256);

    function maxGasLimit() external returns (uint256);

    function delay() external returns (uint256);

    function totalShares(address token) external returns (uint256);

    function weth() external returns (address);

    function getTransferGasCost(address token) external returns (uint256);

    function getDepositOrder(uint256 orderId) external returns (Orders.DepositOrder memory order);

    function getWithdrawOrder(uint256 orderId) external returns (Orders.WithdrawOrder memory order);

    function getSellOrder(uint256 orderId) external returns (Orders.SellOrder memory order);

    function getBuyOrder(uint256 orderId) external returns (Orders.BuyOrder memory order);

    function getDepositDisabled(address pair) external returns (bool);

    function getWithdrawDisabled(address pair) external returns (bool);

    function getBuyDisabled(address pair) external returns (bool);

    function getSellDisabled(address pair) external returns (bool);

    function getOrderStatus(uint256 orderId) external returns (Orders.OrderStatus);

    function setOrderDisabled(
        address pair,
        Orders.OrderType orderType,
        bool disabled
    ) external;

    function setOwner(address _owner) external;

    function setBot(address _bot, bool _isBot) external;

    function setMaxGasLimit(uint256 _maxGasLimit) external;

    function setDelay(uint256 _delay) external;

    function setGasPriceInertia(uint256 _gasPriceInertia) external;

    function setMaxGasPriceImpact(uint256 _maxGasPriceImpact) external;

    function setTransferGasCost(address token, uint256 gasCost) external;

    function deposit(Orders.DepositParams memory depositParams) external payable returns (uint256 orderId);

    function withdraw(Orders.WithdrawParams memory withdrawParams) external payable returns (uint256 orderId);

    function sell(Orders.SellParams memory sellParams) external payable returns (uint256 orderId);

    function buy(Orders.BuyParams memory buyParams) external payable returns (uint256 orderId);

    function execute(uint256 n) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface IIntegralOracle {
    event OwnerSet(address owner);
    event UniswapPairSet(address uniswapPair);
    event PriceUpdateIntervalSet(uint32 interval);
    event ParametersSet(uint32 epoch, int256[] bidExponents, int256[] bidQs, int256[] askExponents, int256[] askQs);

    function owner() external view returns (address);

    function setOwner(address) external;

    function epoch() external view returns (uint32);

    function xDecimals() external view returns (uint8);

    function yDecimals() external view returns (uint8);

    function getParameters()
        external
        view
        returns (
            int256[] memory bidExponents,
            int256[] memory bidQs,
            int256[] memory askExponents,
            int256[] memory askQs
        );

    function setParameters(
        int256[] calldata bidExponents,
        int256[] calldata bidQs,
        int256[] calldata askExponents,
        int256[] calldata askQs
    ) external;

    function price() external view returns (int256);

    function priceUpdateInterval() external view returns (uint32);

    function updatePrice() external returns (uint32 _epoch);

    function setPriceUpdateInterval(uint32 interval) external;

    function price0CumulativeLast() external view returns (uint256);

    function blockTimestampLast() external view returns (uint32);

    function tradeX(
        uint256 xAfter,
        uint256 xBefore,
        uint256 yBefore
    ) external view returns (uint256 yAfter);

    function tradeY(
        uint256 yAfter,
        uint256 xBefore,
        uint256 yBefore
    ) external view returns (uint256 xAfter);

    function getSpotPrice(uint256 xCurrent, uint256 xBefore) external view returns (uint256 spotPrice);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'SafeMath.sol';

library Normalizer {
    using SafeMath for uint256;

    function normalize(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        if (decimals == 18) {
            return amount;
        } else if (decimals > 18) {
            return amount.div(10**(decimals - 18));
        } else {
            return amount.mul(10**(18 - decimals));
        }
    }

    function denormalize(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        if (decimals == 18) {
            return amount;
        } else if (decimals > 18) {
            return amount.mul(10**(decimals - 18));
        } else {
            return amount.div(10**(18 - decimals));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'TransferHelper.sol';
import 'SafeMath.sol';
import 'Math.sol';
import 'Normalizer.sol';
import 'IIntegralPair.sol';
import 'IIntegralOracle.sol';

library AddLiquidity {
    using SafeMath for uint256;

    function _quote(
        uint256 amount0,
        uint256 reserve0,
        uint256 reserve1
    ) private pure returns (uint256 amountB) {
        require(amount0 > 0, 'AL_INSUFFICIENT_AMOUNT');
        require(reserve0 > 0 && reserve1 > 0, 'AL_INSUFFICIENT_LIQUIDITY');
        amountB = amount0.mul(reserve1) / reserve0;
    }

    function addLiquidity(
        address pair,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external view returns (uint256 amount0, uint256 amount1) {
        if (amount0Desired == 0 || amount1Desired == 0) {
            return (0, 0);
        }
        (uint256 reserve0, uint256 reserve1, ) = IIntegralPair(pair).getReserves();
        if (reserve0 == 0 && reserve1 == 0) {
            (amount0, amount1) = (amount0Desired, amount1Desired);
        } else {
            uint256 amount1Optimal = _quote(amount0Desired, reserve0, reserve1);
            if (amount1Optimal <= amount1Desired) {
                (amount0, amount1) = (amount0Desired, amount1Optimal);
            } else {
                uint256 amount0Optimal = _quote(amount1Desired, reserve1, reserve0);
                assert(amount0Optimal <= amount0Desired);
                (amount0, amount1) = (amount0Optimal, amount1Desired);
            }
        }
    }

    function swapDeposit0(
        address pair,
        address token0,
        uint256 amount0,
        uint256 minSwapPrice
    ) external returns (uint256 amount0Left, uint256 amount1Left) {
        uint256 amount0In = IIntegralPair(pair).getDepositAmount0In(amount0);
        amount1Left = IIntegralPair(pair).getSwapAmount1Out(amount0In);
        if (amount1Left == 0) {
            return (amount0, amount1Left);
        }
        uint256 price = getPrice(amount0In, amount1Left, pair);
        require(minSwapPrice == 0 || price >= minSwapPrice, 'AL_PRICE_TOO_LOW');
        TransferHelper.safeTransfer(token0, pair, amount0In);
        IIntegralPair(pair).swap(0, amount1Left, address(this));
        amount0Left = amount0.sub(amount0In);
    }

    function swapDeposit1(
        address pair,
        address token1,
        uint256 amount1,
        uint256 maxSwapPrice
    ) external returns (uint256 amount0Left, uint256 amount1Left) {
        uint256 amount1In = IIntegralPair(pair).getDepositAmount1In(amount1);
        amount0Left = IIntegralPair(pair).getSwapAmount0Out(amount1In);
        if (amount0Left == 0) {
            return (amount0Left, amount1);
        }
        uint256 price = getPrice(amount0Left, amount1In, pair);
        require(maxSwapPrice == 0 || price <= maxSwapPrice, 'AL_PRICE_TOO_HIGH');
        TransferHelper.safeTransfer(token1, pair, amount1In);
        IIntegralPair(pair).swap(amount0Left, 0, address(this));
        amount1Left = amount1.sub(amount1In);
    }

    function getPrice(
        uint256 amount0,
        uint256 amount1,
        address pair
    ) internal view returns (uint256) {
        IIntegralOracle oracle = IIntegralOracle(IIntegralPair(pair).oracle());
        uint8 xDecimals = oracle.xDecimals();
        uint8 yDecimals = oracle.yDecimals();
        return Normalizer.normalize(amount1, yDecimals).mul(1e18).div(Normalizer.normalize(amount0, xDecimals));
    }

    function canSwap(
        uint256 initialRatio, // setting it to 0 disables swap
        uint256 minRatioChangeToSwap,
        address pairAddress
    ) external view returns (bool) {
        (uint256 reserve0, uint256 reserve1, ) = IIntegralPair(pairAddress).getReserves();
        if (reserve0 == 0 || reserve1 == 0 || initialRatio == 0) {
            return false;
        }
        uint256 ratio = reserve0.mul(1e18).div(reserve1);
        // ratioChange(before, after) = MAX(before, after) / MIN(before, after) - 1
        uint256 change = Math.max(initialRatio, ratio).mul(1e3).div(Math.min(initialRatio, ratio)).sub(1e3);
        return change >= minRatioChangeToSwap;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
// pragma abicoder v2;

import 'IIntegralOracle.sol';
import 'IIntegralPair.sol';
import 'SafeMath.sol';

library BuyHelper {
    using SafeMath for uint256;
    uint256 public constant PRECISION = 10**18;

    function getSwapAmount0In(address pair, uint256 amount1Out) external view returns (uint256 swapAmount0In) {
        (uint112 reserve0, uint112 reserve1, ) = IIntegralPair(pair).getReserves();
        (uint112 reference0, uint112 reference1, ) = IIntegralPair(pair).getReferences();
        uint256 balance1After = uint256(reserve1).sub(amount1Out);
        uint256 balance0After = IIntegralOracle(IIntegralPair(pair).oracle()).tradeY(
            balance1After,
            reference0,
            reference1
        );
        uint256 swapFee = IIntegralPair(pair).swapFee();
        return balance0After.sub(uint256(reserve0)).mul(PRECISION).ceil_div(PRECISION.sub(swapFee));
    }

    function getSwapAmount1In(address pair, uint256 amount0Out) external view returns (uint256 swapAmount1In) {
        (uint112 reserve0, uint112 reserve1, ) = IIntegralPair(pair).getReserves();
        (uint112 reference0, uint112 reference1, ) = IIntegralPair(pair).getReferences();
        uint256 balance0After = uint256(reserve0).sub(amount0Out);
        uint256 balance1After = IIntegralOracle(IIntegralPair(pair).oracle()).tradeX(
            balance0After,
            reference0,
            reference1
        );
        uint256 swapFee = IIntegralPair(pair).swapFee();
        return balance1After.add(1).sub(uint256(reserve1)).mul(PRECISION).ceil_div(PRECISION.sub(swapFee));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import 'IIntegralPair.sol';
import 'IWETH.sol';
import 'Orders.sol';

library WithdrawHelper {
    using SafeMath for uint256;

    function _transferToken(
        uint256 balanceBefore,
        address token,
        address to
    ) internal {
        uint256 tokenAmount = IERC20(token).balanceOf(address(this)).sub(balanceBefore);
        TransferHelper.safeTransfer(token, to, tokenAmount);
    }

    function _unwrapWeth(
        uint256 ethAmount,
        address weth,
        address to
    ) internal returns (bool) {
        IWETH(weth).withdraw(ethAmount);
        (bool success, ) = to.call{ value: ethAmount, gas: Orders.ETHER_TRANSFER_CALL_COST }('');
        return success;
    }

    function withdrawAndUnwrap(
        address token0,
        address token1,
        address pair,
        address weth,
        address to
    )
        external
        returns (
            bool,
            uint256,
            uint256,
            uint256
        )
    {
        bool isToken0Weth = token0 == weth;
        address otherToken = isToken0Weth ? token1 : token0;

        uint256 balanceBefore = IERC20(otherToken).balanceOf(address(this));
        (uint256 amount0, uint256 amount1) = IIntegralPair(pair).burn(address(this));
        _transferToken(balanceBefore, otherToken, to);

        bool success = _unwrapWeth(isToken0Weth ? amount0 : amount1, weth, to);

        return (success, isToken0Weth ? amount0 : amount1, amount0, amount1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import 'IIntegralPair.sol';
import 'IIntegralDelay.sol';
import 'IIntegralOracle.sol';
import 'IWETH.sol';
import 'SafeMath.sol';
import 'Normalizer.sol';
import 'Orders.sol';
import 'TokenShares.sol';
import 'AddLiquidity.sol';
import 'BuyHelper.sol';
import 'WithdrawHelper.sol';

contract IntegralDelay is IIntegralDelay {
    using SafeMath for uint256;
    using Normalizer for uint256;
    using Orders for Orders.Data;
    using TokenShares for TokenShares.Data;
    Orders.Data internal orders;
    TokenShares.Data internal tokenShares;

    uint256 public constant ORDER_CANCEL_TIME = 24 hours;
    uint256 private constant ORDER_EXECUTED_COST = 3700;

    address public override owner;
    mapping(address => bool) public override isBot;
    uint256 public override botExecuteTime;

    constructor(
        address _factory,
        address _weth,
        address _bot
    ) {
        orders.factory = _factory;
        owner = msg.sender;
        isBot[_bot] = true;
        orders.gasPrice = tx.gasprice - (tx.gasprice % 1e6);
        tokenShares.setWeth(_weth);
        orders.delay = 5 minutes;
        botExecuteTime = 4 * orders.delay;
        orders.maxGasLimit = 5000000;
        orders.gasPriceInertia = 20000000;
        orders.maxGasPriceImpact = 1000000;
    }

    function getTransferGasCost(address token) public view override returns (uint256 gasCost) {
        return orders.transferGasCosts[token];
    }

    function getDepositOrder(uint256 orderId) public view override returns (Orders.DepositOrder memory order) {
        return orders.getDepositOrder(orderId);
    }

    function getWithdrawOrder(uint256 orderId) public view override returns (Orders.WithdrawOrder memory order) {
        return orders.getWithdrawOrder(orderId);
    }

    function getSellOrder(uint256 orderId) public view override returns (Orders.SellOrder memory order) {
        return orders.getSellOrder(orderId);
    }

    function getBuyOrder(uint256 orderId) public view override returns (Orders.BuyOrder memory order) {
        return orders.getBuyOrder(orderId);
    }

    function getDepositDisabled(address pair) public view override returns (bool) {
        return orders.depositDisabled[pair];
    }

    function getWithdrawDisabled(address pair) public view override returns (bool) {
        return orders.withdrawDisabled[pair];
    }

    function getBuyDisabled(address pair) public view override returns (bool) {
        return orders.buyDisabled[pair];
    }

    function getSellDisabled(address pair) public view override returns (bool) {
        return orders.sellDisabled[pair];
    }

    function getOrderStatus(uint256 orderId) public view override returns (Orders.OrderStatus) {
        return orders.getOrderStatus(orderId);
    }

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'ID_LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function factory() public view override returns (address) {
        return orders.factory;
    }

    function totalShares(address token) public view override returns (uint256) {
        return tokenShares.totalShares[token];
    }

    function weth() public view override returns (address) {
        return tokenShares.weth;
    }

    function delay() public view override returns (uint256) {
        return orders.delay;
    }

    function lastProcessedOrderId() public view returns (uint256) {
        return orders.lastProcessedOrderId;
    }

    function newestOrderId() public view returns (uint256) {
        return orders.newestOrderId;
    }

    function getOrder(uint256 orderId) public view returns (Orders.OrderType orderType, uint256 validAfterTimestamp) {
        return orders.getOrder(orderId);
    }

    function isOrderCanceled(uint256 orderId) public view returns (bool) {
        return orders.canceled[orderId];
    }

    function maxGasLimit() public view override returns (uint256) {
        return orders.maxGasLimit;
    }

    function maxGasPriceImpact() public view override returns (uint256) {
        return orders.maxGasPriceImpact;
    }

    function gasPriceInertia() public view override returns (uint256) {
        return orders.gasPriceInertia;
    }

    function gasPrice() public view override returns (uint256) {
        return orders.gasPrice;
    }

    function setOrderDisabled(
        address pair,
        Orders.OrderType orderType,
        bool disabled
    ) public override {
        require(msg.sender == owner, 'ID_FORBIDDEN');
        require(orderType != Orders.OrderType.Empty, 'ID_INVALID_ORDER_TYPE');
        if (orderType == Orders.OrderType.Deposit) {
            orders.depositDisabled[pair] = disabled;
        } else if (orderType == Orders.OrderType.Withdraw) {
            orders.withdrawDisabled[pair] = disabled;
        } else if (orderType == Orders.OrderType.Sell) {
            orders.sellDisabled[pair] = disabled;
        } else if (orderType == Orders.OrderType.Buy) {
            orders.buyDisabled[pair] = disabled;
        }
        emit OrderDisabled(pair, orderType, disabled);
    }

    function setOwner(address _owner) public override {
        require(msg.sender == owner, 'ID_FORBIDDEN');
        owner = _owner;
        emit OwnerSet(owner);
    }

    function setBot(address _bot, bool _isBot) public override {
        require(msg.sender == owner, 'ID_FORBIDDEN');
        isBot[_bot] = _isBot;
        emit BotSet(_bot, _isBot);
    }

    function setMaxGasLimit(uint256 _maxGasLimit) public override {
        require(msg.sender == owner, 'ID_FORBIDDEN');
        orders.setMaxGasLimit(_maxGasLimit);
    }

    function setDelay(uint256 _delay) public override {
        require(msg.sender == owner, 'ID_FORBIDDEN');
        orders.delay = _delay;
        botExecuteTime = 4 * _delay;
        emit DelaySet(_delay);
    }

    function setGasPriceInertia(uint256 _gasPriceInertia) public override {
        require(msg.sender == owner, 'ID_FORBIDDEN');
        orders.setGasPriceInertia(_gasPriceInertia);
    }

    function setMaxGasPriceImpact(uint256 _maxGasPriceImpact) public override {
        require(msg.sender == owner, 'ID_FORBIDDEN');
        orders.setMaxGasPriceImpact(_maxGasPriceImpact);
    }

    function setTransferGasCost(address token, uint256 gasCost) public override {
        require(msg.sender == owner, 'ID_FORBIDDEN');
        orders.setTransferGasCost(token, gasCost);
    }

    function deposit(Orders.DepositParams calldata depositParams)
        external
        payable
        override
        lock
        returns (uint256 orderId)
    {
        orders.deposit(depositParams, tokenShares);
        return orders.newestOrderId;
    }

    function withdraw(Orders.WithdrawParams calldata withdrawParams)
        external
        payable
        override
        lock
        returns (uint256 orderId)
    {
        orders.withdraw(withdrawParams);
        return orders.newestOrderId;
    }

    function sell(Orders.SellParams calldata sellParams) external payable override lock returns (uint256 orderId) {
        orders.sell(sellParams, tokenShares);
        return orders.newestOrderId;
    }

    function buy(Orders.BuyParams calldata buyParams) external payable override lock returns (uint256 orderId) {
        orders.buy(buyParams, tokenShares);
        return orders.newestOrderId;
    }

    function execute(uint256 n) public override lock {
        emit Execute(msg.sender, n);
        uint256 gasBefore = gasleft();
        bool orderExecuted = false;
        for (uint256 i = 0; i < n; i++) {
            if (isOrderCanceled(orders.lastProcessedOrderId + 1)) {
                orders.dequeueCanceledOrder();
                continue;
            }
            (Orders.OrderType orderType, uint256 validAfterTimestamp) = orders.getNextOrder();
            if (orderType == Orders.OrderType.Empty || validAfterTimestamp >= block.timestamp) {
                break;
            }
            require(
                block.timestamp >= validAfterTimestamp + botExecuteTime || isBot[msg.sender] || isBot[address(0)],
                'ID_FORBIDDEN'
            );
            orderExecuted = true;
            if (orderType == Orders.OrderType.Deposit) {
                executeDeposit();
            } else if (orderType == Orders.OrderType.Withdraw) {
                executeWithdraw();
            } else if (orderType == Orders.OrderType.Sell) {
                executeSell();
            } else if (orderType == Orders.OrderType.Buy) {
                executeBuy();
            }
        }
        if (orderExecuted) {
            orders.updateGasPrice(gasBefore.sub(gasleft()));
        }
    }

    function executeDeposit() internal {
        uint256 gasStart = gasleft();
        Orders.DepositOrder memory depositOrder = orders.dequeueDepositOrder();
        (, address token0, address token1) = orders.getPairInfo(depositOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: depositOrder.gasLimit.sub(
                Orders.ORDER_BASE_COST.add(orders.transferGasCosts[token0]).add(orders.transferGasCosts[token1])
            )
        }(abi.encodeWithSelector(this._executeDeposit.selector, depositOrder));
        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundTokens(
                depositOrder.to,
                token0,
                depositOrder.share0,
                token1,
                depositOrder.share1,
                depositOrder.unwrap
            );
        }
        if (!refundSuccess) {
            orders.markRefundFailed();
        } else {
            orders.forgetLastProcessedOrder();
        }
        (uint256 gasUsed, uint256 ethRefund) = refund(
            depositOrder.gasLimit,
            depositOrder.gasPrice,
            gasStart,
            depositOrder.to
        );
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function executeWithdraw() internal {
        uint256 gasStart = gasleft();
        Orders.WithdrawOrder memory withdrawOrder = orders.dequeueWithdrawOrder();
        (address pair, , ) = orders.getPairInfo(withdrawOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: withdrawOrder.gasLimit.sub(Orders.ORDER_BASE_COST.add(Orders.PAIR_TRANSFER_COST))
        }(abi.encodeWithSelector(this._executeWithdraw.selector, withdrawOrder));
        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundLiquidity(pair, withdrawOrder.to, withdrawOrder.liquidity);
        }
        if (!refundSuccess) {
            orders.markRefundFailed();
        } else {
            orders.forgetLastProcessedOrder();
        }
        (uint256 gasUsed, uint256 ethRefund) = refund(
            withdrawOrder.gasLimit,
            withdrawOrder.gasPrice,
            gasStart,
            withdrawOrder.to
        );
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function executeSell() internal {
        uint256 gasStart = gasleft();
        Orders.SellOrder memory sellOrder = orders.dequeueSellOrder();
        (, address token0, address token1) = orders.getPairInfo(sellOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: sellOrder.gasLimit.sub(
                Orders.ORDER_BASE_COST.add(orders.transferGasCosts[sellOrder.inverse ? token1 : token0])
            )
        }(abi.encodeWithSelector(this._executeSell.selector, sellOrder));
        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundToken(
                sellOrder.inverse ? token1 : token0,
                sellOrder.to,
                sellOrder.shareIn,
                sellOrder.unwrap
            );
        }
        if (!refundSuccess) {
            orders.markRefundFailed();
        } else {
            orders.forgetLastProcessedOrder();
        }
        (uint256 gasUsed, uint256 ethRefund) = refund(sellOrder.gasLimit, sellOrder.gasPrice, gasStart, sellOrder.to);
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function executeBuy() internal {
        uint256 gasStart = gasleft();
        Orders.BuyOrder memory buyOrder = orders.dequeueBuyOrder();
        (, address token0, address token1) = orders.getPairInfo(buyOrder.pairId);
        (bool executionSuccess, bytes memory data) = address(this).call{
            gas: buyOrder.gasLimit.sub(
                Orders.ORDER_BASE_COST.add(orders.transferGasCosts[buyOrder.inverse ? token1 : token0])
            )
        }(abi.encodeWithSelector(this._executeBuy.selector, buyOrder));
        bool refundSuccess = true;
        if (!executionSuccess) {
            refundSuccess = refundToken(
                buyOrder.inverse ? token1 : token0,
                buyOrder.to,
                buyOrder.shareInMax,
                buyOrder.unwrap
            );
        }
        if (!refundSuccess) {
            orders.markRefundFailed();
        } else {
            orders.forgetLastProcessedOrder();
        }
        (uint256 gasUsed, uint256 ethRefund) = refund(buyOrder.gasLimit, buyOrder.gasPrice, gasStart, buyOrder.to);
        emit OrderExecuted(orders.lastProcessedOrderId, executionSuccess, data, gasUsed, ethRefund);
    }

    function refund(
        uint256 gasLimit,
        uint256 gasPriceInOrder,
        uint256 gasStart,
        address to
    ) private returns (uint256 gasUsed, uint256 leftOver) {
        uint256 feeCollected = gasLimit.mul(gasPriceInOrder);
        gasUsed = gasStart.sub(gasleft()).add(Orders.REFUND_END_COST).add(ORDER_EXECUTED_COST);
        uint256 actualRefund = Math.min(feeCollected, gasUsed.mul(orders.gasPrice));
        leftOver = feeCollected.sub(actualRefund);
        require(refundEth(msg.sender, actualRefund), 'ID_ETH_REFUND_FAILED');
        refundEth(payable(to), leftOver);
    }

    function refundEth(address payable to, uint256 value) internal returns (bool success) {
        if (value == 0) {
            return true;
        }
        success = to.send(value);
        emit EthRefund(to, success, value);
    }

    function refundToken(
        address token,
        address to,
        uint256 share,
        bool unwrap
    ) private returns (bool) {
        if (share == 0) {
            return true;
        }
        (bool success, bytes memory data) = address(this).call{ gas: orders.transferGasCosts[token] }(
            abi.encodeWithSelector(this._refundToken.selector, token, to, share, unwrap)
        );
        if (!success) {
            emit RefundFailed(to, token, share, data);
        }
        return success;
    }

    function refundTokens(
        address to,
        address token0,
        uint256 share0,
        address token1,
        uint256 share1,
        bool unwrap
    ) private returns (bool) {
        (bool success, bytes memory data) = address(this).call{
            gas: orders.transferGasCosts[token0].add(orders.transferGasCosts[token1])
        }(abi.encodeWithSelector(this._refundTokens.selector, to, token0, share0, token1, share1, unwrap));
        if (!success) {
            emit RefundFailed(to, token0, share0, data);
            emit RefundFailed(to, token1, share1, data);
        }
        return success;
    }

    function _refundTokens(
        address to,
        address token0,
        uint256 share0,
        address token1,
        uint256 share1,
        bool unwrap
    ) external {
        // no need to check sender, because it is checked in _refundToken
        _refundToken(token0, to, share0, unwrap);
        _refundToken(token1, to, share1, unwrap);
    }

    function _refundToken(
        address token,
        address to,
        uint256 share,
        bool unwrap
    ) public {
        require(msg.sender == address(this), 'ID_FORBIDDEN');
        if (token == tokenShares.weth && unwrap) {
            uint256 amount = tokenShares.sharesToAmount(token, share);
            IWETH(tokenShares.weth).withdraw(amount);
            payable(to).transfer(amount);
        } else {
            return TransferHelper.safeTransfer(token, to, tokenShares.sharesToAmount(token, share));
        }
    }

    function refundLiquidity(
        address pair,
        address to,
        uint256 liquidity
    ) private returns (bool) {
        if (liquidity == 0) {
            return true;
        }
        (bool success, bytes memory data) = address(this).call{ gas: Orders.PAIR_TRANSFER_COST }(
            abi.encodeWithSelector(this._refundLiquidity.selector, pair, to, liquidity, false)
        );
        if (!success) {
            emit RefundFailed(to, pair, liquidity, data);
        }
        return success;
    }

    function _refundLiquidity(
        address pair,
        address to,
        uint256 liquidity
    ) public {
        require(msg.sender == address(this), 'ID_FORBIDDEN');
        return TransferHelper.safeTransfer(pair, to, liquidity);
    }

    function _executeDeposit(Orders.DepositOrder memory depositOrder) public {
        require(msg.sender == address(this), 'ID_FORBIDDEN');
        require(depositOrder.deadline >= block.timestamp, 'ID_EXPIRED');

        (address pair, address token0, address token1, uint256 amount0Left, uint256 amount1Left) = _initialDeposit(
            depositOrder
        );
        if (
            (amount0Left != 0 || amount1Left != 0) &&
            AddLiquidity.canSwap(
                depositOrder.initialRatio,
                depositOrder.minRatioChangeToSwap,
                orders.pairs[depositOrder.pairId].pair
            )
        ) {
            if (amount0Left != 0) {
                (amount0Left, amount1Left) = AddLiquidity.swapDeposit0(
                    pair,
                    token0,
                    amount0Left,
                    depositOrder.minSwapPrice
                );
            } else if (amount1Left != 0) {
                (amount0Left, amount1Left) = AddLiquidity.swapDeposit1(
                    pair,
                    token1,
                    amount1Left,
                    depositOrder.maxSwapPrice
                );
            }
        }
        if (amount0Left != 0 && amount1Left != 0) {
            (amount0Left, amount1Left) = _addLiquidityAndMint(
                pair,
                depositOrder.to,
                token0,
                token1,
                amount0Left,
                amount1Left
            );
        }

        _refundDeposit(depositOrder.to, token0, token1, amount0Left, amount1Left);
    }

    function _initialDeposit(Orders.DepositOrder memory depositOrder)
        private
        returns (
            address pair,
            address token0,
            address token1,
            uint256 amount0Left,
            uint256 amount1Left
        )
    {
        (pair, token0, token1) = orders.getPairInfo(depositOrder.pairId);
        uint256 amount0Desired = tokenShares.sharesToAmount(token0, depositOrder.share0);
        uint256 amount1Desired = tokenShares.sharesToAmount(token1, depositOrder.share1);
        IIntegralPair(pair).fullSync();
        (amount0Left, amount1Left) = _addLiquidityAndMint(
            pair,
            depositOrder.to,
            token0,
            token1,
            amount0Desired,
            amount1Desired
        );
    }

    function _addLiquidityAndMint(
        address pair,
        address to,
        address token0,
        address token1,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) private returns (uint256 amount0Left, uint256 amount1Left) {
        (uint256 amount0, uint256 amount1) = AddLiquidity.addLiquidity(pair, amount0Desired, amount1Desired);
        if (amount0 == 0 || amount1 == 0) {
            return (amount0Desired, amount1Desired);
        }
        TransferHelper.safeTransfer(token0, pair, amount0);
        TransferHelper.safeTransfer(token1, pair, amount1);
        IIntegralPair(pair).mint(to);

        amount0Left = amount0Desired.sub(amount0);
        amount1Left = amount1Desired.sub(amount1);
    }

    function _refundDeposit(
        address to,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) private {
        if (amount0 > 0) {
            TransferHelper.safeTransfer(token0, to, amount0);
        }
        if (amount1 > 0) {
            TransferHelper.safeTransfer(token1, to, amount1);
        }
    }

    function _executeWithdraw(Orders.WithdrawOrder memory withdrawOrder) public {
        require(msg.sender == address(this), 'ID_FORBIDDEN');
        require(withdrawOrder.deadline >= block.timestamp, 'ID_EXPIRED');

        (address pair, address token0, address token1) = orders.getPairInfo(withdrawOrder.pairId);
        IIntegralPair(pair).fullSync();
        TransferHelper.safeTransfer(pair, pair, withdrawOrder.liquidity);

        (uint256 wethAmount, uint256 amount0, uint256 amount1) = (0, 0, 0);
        if (withdrawOrder.unwrap && (token0 == tokenShares.weth || token1 == tokenShares.weth)) {
            bool success;
            (success, wethAmount, amount0, amount1) = WithdrawHelper.withdrawAndUnwrap(
                token0,
                token1,
                pair,
                tokenShares.weth,
                withdrawOrder.to
            );
            if (!success) {
                tokenShares.onUnwrapFailed(withdrawOrder.to, wethAmount);
            }
        } else {
            (amount0, amount1) = IIntegralPair(pair).burn(withdrawOrder.to);
        }
        require(amount0 >= withdrawOrder.amount0Min && amount1 >= withdrawOrder.amount1Min, 'ID_INSUFFICIENT_AMOUNT');
    }

    function _executeBuy(Orders.BuyOrder memory buyOrder) public {
        require(msg.sender == address(this), 'ID_FORBIDDEN');
        require(buyOrder.deadline >= block.timestamp, 'ID_EXPIRED');

        (address pairAddress, address token0, address token1) = orders.getPairInfo(buyOrder.pairId);
        (address tokenIn, address tokenOut) = buyOrder.inverse ? (token1, token0) : (token0, token1);
        uint256 amountInMax = tokenShares.sharesToAmount(tokenIn, buyOrder.shareInMax);
        IIntegralPair pair = IIntegralPair(pairAddress);
        pair.fullSync();
        uint256 amountIn = buyOrder.inverse
            ? BuyHelper.getSwapAmount1In(pairAddress, buyOrder.amountOut)
            : BuyHelper.getSwapAmount0In(pairAddress, buyOrder.amountOut);
        require(amountInMax >= amountIn, 'ID_INSUFFICIENT_INPUT_AMOUNT');
        (uint256 amount0Out, uint256 amount1Out) = buyOrder.inverse
            ? (buyOrder.amountOut, uint256(0))
            : (uint256(0), buyOrder.amountOut);
        TransferHelper.safeTransfer(tokenIn, pairAddress, amountIn);
        if (tokenOut == tokenShares.weth && buyOrder.unwrap) {
            pair.swap(amount0Out, amount1Out, address(this));
            IWETH(tokenShares.weth).withdraw(buyOrder.amountOut);
            (bool success, ) = buyOrder.to.call{ value: buyOrder.amountOut, gas: Orders.ETHER_TRANSFER_CALL_COST }('');
            if (!success) {
                tokenShares.onUnwrapFailed(buyOrder.to, buyOrder.amountOut);
            }
        } else {
            pair.swap(amount0Out, amount1Out, buyOrder.to);
        }
    }

    function _executeSell(Orders.SellOrder memory sellOrder) public {
        require(msg.sender == address(this), 'ID_FORBIDDEN');
        require(sellOrder.deadline >= block.timestamp, 'ID_EXPIRED');

        (address pairAddress, address token0, address token1) = orders.getPairInfo(sellOrder.pairId);
        (address tokenIn, address tokenOut) = sellOrder.inverse ? (token1, token0) : (token0, token1);
        uint256 amountIn = tokenShares.sharesToAmount(tokenIn, sellOrder.shareIn);
        IIntegralPair pair = IIntegralPair(pairAddress);
        pair.fullSync();
        TransferHelper.safeTransfer(tokenIn, pairAddress, amountIn);
        uint256 amountOut = sellOrder.inverse ? pair.getSwapAmount0Out(amountIn) : pair.getSwapAmount1Out(amountIn);
        require(amountOut >= sellOrder.amountOutMin, 'ID_INSUFFICIENT_OUTPUT_AMOUNT');
        (uint256 amount0Out, uint256 amount1Out) = sellOrder.inverse
            ? (amountOut, uint256(0))
            : (uint256(0), amountOut);
        if (tokenOut == tokenShares.weth && sellOrder.unwrap) {
            pair.swap(amount0Out, amount1Out, address(this));
            IWETH(tokenShares.weth).withdraw(amountOut);
            (bool success, ) = sellOrder.to.call{ value: amountOut, gas: Orders.ETHER_TRANSFER_CALL_COST }('');
            if (!success) {
                tokenShares.onUnwrapFailed(sellOrder.to, amountOut);
            }
        } else {
            pair.swap(amount0Out, amount1Out, sellOrder.to);
        }
    }

    function performRefund(
        Orders.OrderType orderType,
        uint256 validAfterTimestamp,
        uint256 orderId,
        bool shouldRefundEth
    ) internal {
        bool canOwnerRefund = validAfterTimestamp.add(365 days) < block.timestamp;
        if (orderType == Orders.OrderType.Deposit) {
            Orders.DepositOrder memory depositOrder = orders.getDepositOrder(orderId);
            (, address token0, address token1) = orders.getPairInfo(depositOrder.pairId);
            address to = canOwnerRefund ? owner : depositOrder.to;
            require(
                refundTokens(to, token0, depositOrder.share0, token1, depositOrder.share1, depositOrder.unwrap),
                'ID_REFUND_FAILED'
            );
            if (shouldRefundEth) {
                uint256 value = depositOrder.gasPrice.mul(depositOrder.gasLimit);
                require(refundEth(payable(to), value), 'ID_ETH_REFUND_FAILED');
            }
        } else if (orderType == Orders.OrderType.Withdraw) {
            Orders.WithdrawOrder memory withdrawOrder = orders.getWithdrawOrder(orderId);
            (address pair, , ) = orders.getPairInfo(withdrawOrder.pairId);
            address to = canOwnerRefund ? owner : withdrawOrder.to;
            require(refundLiquidity(pair, to, withdrawOrder.liquidity), 'ID_REFUND_FAILED');
            if (shouldRefundEth) {
                uint256 value = withdrawOrder.gasPrice.mul(withdrawOrder.gasLimit);
                require(refundEth(payable(to), value), 'ID_ETH_REFUND_FAILED');
            }
        } else if (orderType == Orders.OrderType.Sell) {
            Orders.SellOrder memory sellOrder = orders.getSellOrder(orderId);
            (, address token0, address token1) = orders.getPairInfo(sellOrder.pairId);
            address to = canOwnerRefund ? owner : sellOrder.to;
            require(
                refundToken(sellOrder.inverse ? token1 : token0, to, sellOrder.shareIn, sellOrder.unwrap),
                'ID_REFUND_FAILED'
            );
            if (shouldRefundEth) {
                uint256 value = sellOrder.gasPrice.mul(sellOrder.gasLimit);
                require(refundEth(payable(to), value), 'ID_ETH_REFUND_FAILED');
            }
        } else if (orderType == Orders.OrderType.Buy) {
            Orders.BuyOrder memory buyOrder = orders.getBuyOrder(orderId);
            (, address token0, address token1) = orders.getPairInfo(buyOrder.pairId);
            address to = canOwnerRefund ? owner : buyOrder.to;
            require(
                refundToken(buyOrder.inverse ? token1 : token0, to, buyOrder.shareInMax, buyOrder.unwrap),
                'ID_REFUND_FAILED'
            );
            if (shouldRefundEth) {
                uint256 value = buyOrder.gasPrice.mul(buyOrder.gasLimit);
                require(refundEth(payable(to), value), 'ID_ETH_REFUND_FAILED');
            }
        }
        orders.forgetOrder(orderId);
    }

    function retryRefund(uint256 orderId) public lock {
        (Orders.OrderType orderType, uint256 validAfterTimestamp) = orders.getFailedOrderType(orderId);
        performRefund(orderType, validAfterTimestamp, orderId, false);
    }

    function cancelOrder(uint256 orderId) public lock {
        (Orders.OrderType orderType, uint256 validAfterTimestamp) = orders.getOrder(orderId);
        require(validAfterTimestamp.sub(delay()).add(ORDER_CANCEL_TIME) < block.timestamp, 'ID_ORDER_NOT_EXCEEDED');
        performRefund(orderType, validAfterTimestamp, orderId, true);
        orders.canceled[orderId] = true;
    }

    receive() external payable {}
}

