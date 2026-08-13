/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-05-22
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// Sources flattened with hardhat v2.9.6 https://hardhat.org

// File contracts/Fraxswap/core/interfaces/IUniswapV2FactoryV5.sol


interface IUniswapV2FactoryV5 {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File contracts/Fraxswap/core/interfaces/IUniswapV2PairPartialV5.sol


interface IUniswapV2PairPartialV5 {
    //    event Approval(address indexed owner, address indexed spender, uint value);
    //    event Transfer(address indexed from, address indexed to, uint value);
    //
    //    function name() external pure returns (string memory);
    //    function symbol() external pure returns (string memory);
    //    function decimals() external pure returns (uint8);
    //    function totalSupply() external view returns (uint);
    //    function balanceOf(address owner) external view returns (uint);
    //    function allowance(address owner, address spender) external view returns (uint);
    //
    //    function approve(address spender, uint value) external returns (bool);
    //    function transfer(address to, uint value) external returns (bool);
    //    function transferFrom(address from, address to, uint value) external returns (bool);
    //
    //    function DOMAIN_SEPARATOR() external view returns (bytes32);
    //    function PERMIT_TYPEHASH() external pure returns (bytes32);
    //    function nonces(address owner) external view returns (uint);
    //
    //    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;

    // TWAMM

    function longTermSwapFrom0To1(uint256 amount0In, uint256 numberOfTimeIntervals) external returns (uint256 orderId);
    function longTermSwapFrom1To0(uint256 amount1In, uint256 numberOfTimeIntervals) external returns (uint256 orderId);
    function cancelLongTermSwap(uint256 orderId) external;
    function withdrawProceedsFromLongTermSwap(uint256 orderId) external returns (bool is_expired, address rewardTkn, uint256 totalReward);
    function executeVirtualOrders(uint256 blockTimestamp) external;

    function orderTimeInterval() external returns (uint256);
    function getTWAPHistoryLength() external view returns (uint);
    function getTwammReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast, uint112 _twammReserve0, uint112 _twammReserve1);
    function getReserveAfterTwamm(uint256 blockTimestamp) external view returns (uint112 _reserve0, uint112 _reserve1, uint256 lastVirtualOrderTimestamp, uint112 _twammReserve0, uint112 _twammReserve1);
    function getNextOrderID() external view returns (uint256);
    function getOrderIDsForUser(address user) external view returns (uint256[] memory);
    function getOrderIDsForUserLength(address user) external view returns (uint256);
    //    function getDetailedOrdersForUser(address user, uint256 offset, uint256 limit) external view returns (LongTermOrdersLib.Order[] memory detailed_orders);
    function twammUpToDate() external view returns (bool);
    function getTwammState() external view returns (uint256 token0Rate, uint256 token1Rate, uint256 lastVirtualOrderTimestamp, uint256 orderTimeInterval_rtn, uint256 rewardFactorPool0, uint256 rewardFactorPool1);
    function getTwammSalesRateEnding(uint256 _blockTimestamp) external view returns (uint256 orderPool0SalesRateEnding, uint256 orderPool1SalesRateEnding);
    function getTwammRewardFactor(uint256 _blockTimestamp) external view returns (uint256 rewardFactorPool0AtTimestamp, uint256 rewardFactorPool1AtTimestamp);
    function getTwammOrder(uint256 orderId) external view returns (uint256 id, uint256 expirationTimestamp, uint256 saleRate, address owner, address sellTokenAddr, address buyTokenAddr);
    function getTwammOrderProceedsView(uint256 orderId, uint256 blockTimestamp) external view returns (bool orderExpired, uint256 totalReward);
    function getTwammOrderProceeds(uint256 orderId) external returns (bool orderExpired, uint256 totalReward);


    function togglePauseNewSwaps() external;
}


// File contracts/Fraxswap/core/interfaces/IUniswapV2ERC20V5.sol


interface IUniswapV2ERC20V5 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}


// File contracts/Fraxswap/core/FraxswapERC20.sol


// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================== FraxswapERC20 ===========================
// ====================================================================
// Fraxswap ERC-20
// Inspired by https://www.paradigm.xyz/2021/07/twamm
// https://github.com/para-dave/twamm

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Rich Gee: https://github.com/zer0blockchain
// Dennis: https://github.com/denett

// Logic / Algorithm Ideas
// FrankieIsLost: https://github.com/FrankieIsLost

// Reviewer(s) / Contributor(s)
// Travis Moore: https://github.com/FortisFortuna
// Sam Kazemian: https://github.com/samkazemian
// Drake Evans: https://github.com/DrakeEvans
// Jack Corddry: https://github.com/corddry
// Justin Moore: https://github.com/0xJM
contract FraxswapERC20 is IUniswapV2ERC20V5 {

    string public constant override name = 'Fraxswap V1';
    string public constant override symbol = 'FS-V1';
    uint8 public constant override decimals = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public override nonces;

    constructor() public {
        uint chainId = block.chainid;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(deadline >= block.timestamp); // EXPIRED
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner); // INVALID_SIGNATURE
        _approve(owner, spender, value);
    }
}


// File contracts/Fraxswap/core/libraries/Math.sol


// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


// File contracts/Fraxswap/core/libraries/UQ112x112.sol


// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}


// File contracts/Fraxswap/core/interfaces/IERC20V5.sol


interface IERC20V5 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


// File contracts/Fraxswap/core/interfaces/IUniswapV2CalleeV5.sol


interface IUniswapV2CalleeV5 {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}


// File contracts/Fraxswap/libraries/TransferHelper.sol



// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}


// File contracts/Fraxswap/twamm/ExecVirtualOrders.sol


// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================= ExecVirtualOrdersLib =======================
// ====================================================================
// TWAMM logic for executing the virtual orders
// Inspired by https://www.paradigm.xyz/2021/07/twamm
// https://github.com/para-dave/twamm

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Rich Gee: https://github.com/zer0blockchain
// Dennis: https://github.com/denett

// Logic / Algorithm Ideas
// FrankieIsLost: https://github.com/FrankieIsLost

// Reviewer(s) / Contributor(s)
// Travis Moore: https://github.com/FortisFortuna
// Sam Kazemian: https://github.com/samkazemian
// Drake Evans: https://github.com/DrakeEvans
// Jack Corddry: https://github.com/corddry
// Justin Moore: https://github.com/0xJM

///@notice This library handles the execution of long term orders.
library ExecVirtualOrdersLib {

    ///@notice computes the result of virtual trades by the token pools
    function computeVirtualBalances(
        uint256 token0Start,
        uint256 token1Start,
        uint256 token0In,
        uint256 token1In)
    internal pure returns (uint256 token0Out, uint256 token1Out)
    {
        token0Out = 0;
        token1Out = 0;
        //if no tokens are sold to the pool, we don't need to execute any orders
        if (token0In <= 1 && token1In <= 1) {
            // do nothing
        }
        //in the case where only one pool is selling, we just perform a normal swap
        else if (token0In <= 1) {
            //constant product formula
            uint token1InWithFee = token1In * 997;
            token0Out = token0Start * token1InWithFee / ((token1Start * 1000) + token1InWithFee);
        }
        else if (token1In <= 1) {
            //contant product formula
            uint token0InWithFee = token0In * 997;
            token1Out = token1Start * token0InWithFee / ((token0Start * 1000) + token0InWithFee);
        }
        //when both pools sell, we use the TWAMM formula
        else {
            uint256 newToken0 = token0Start + (token0In * 997 / 1000);
            uint256 newToken1 = token1Start + (token1In * 997 / 1000);
            token0Out = newToken0 - (token1Start * (newToken0) / (newToken1));
            token1Out = newToken1 - (token0Start * (newToken1) / (newToken0));
        }
    }
}


// File contracts/Fraxswap/twamm/LongTermOrders.sol


// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================= LongTermOrdersLib ========================
// ====================================================================
// TWAMM long term order execution logic
// Inspired by https://www.paradigm.xyz/2021/07/twamm
// https://github.com/para-dave/twamm

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Rich Gee: https://github.com/zer0blockchain
// Dennis: https://github.com/denett

// Logic / Algorithm Ideas
// FrankieIsLost: https://github.com/FrankieIsLost

// Reviewer(s) / Contributor(s)
// Travis Moore: https://github.com/FortisFortuna
// Sam Kazemian: https://github.com/samkazemian
// Drake Evans: https://github.com/DrakeEvans
// Jack Corddry: https://github.com/corddry
// Justin Moore: https://github.com/0xJM

///@notice This library handles the state and execution of long term orders. 
library LongTermOrdersLib {

    using LongTermOrdersLib for OrderPool;

    /// ---------------------------
    /// ----- LongTerm Orders -----
    /// ---------------------------

    uint112 internal constant SELL_RATE_ADDITIONAL_PRECISION = 1000000;

    ///@notice information associated with a long term order
    ///fields should NOT be changed after Order struct is created
    struct Order {
        uint256 id;
        uint256 expirationTimestamp;
        uint256 saleRate;
        address owner;
        address sellTokenAddr;
        address buyTokenAddr;
        bool isComplete;
    }

    ///@notice structure contains full state related to long term orders
    struct LongTermOrders {

        ///@notice minimum time interval between order expiries
        uint256 orderTimeInterval;

        ///@notice last virtual orders were executed immediately before this block.timestamp
        uint256 lastVirtualOrderTimestamp;

        ///@notice token pair being traded in embedded amm
        address token0;
        address token1;

        ///@notice mapping from token address to pool that is selling that token
        ///we maintain two order pools, one for each token that is tradable in the AMM
        OrderPool OrderPool0;
        OrderPool OrderPool1;

        ///@notice incrementing counter for order ids, this is the next order id
        uint256 orderId;

        ///@notice mapping from order ids to Orders
        mapping(uint256 => Order) orderMap;
    }

    struct ExecuteVirtualOrdersResult {
        uint112 newReserve0;
        uint112 newReserve1;
        uint256 newTwammReserve0;
        uint256 newTwammReserve1;
        uint256 token0Bought;
        uint256 token1Bought;
        uint256 token0Sold;
        uint256 token1Sold;
        uint256 expiries;
    }

    ///@notice initialize state
    function initialize(LongTermOrders storage longTermOrders,
        address token0,
        address token1,
        uint256 lastVirtualOrderTimestamp,
        uint256 orderTimeInterval) internal {
        longTermOrders.token0 = token0;
        longTermOrders.token1 = token1;
        longTermOrders.lastVirtualOrderTimestamp = lastVirtualOrderTimestamp;
        longTermOrders.orderTimeInterval = orderTimeInterval;
    }

    ///@notice get the OrderPool for this token
    function getOrderPool(LongTermOrders storage longTermOrders, address token) internal view returns (OrderPool storage orderPool) {
        orderPool = token == longTermOrders.token0 ? longTermOrders.OrderPool0 : longTermOrders.OrderPool1;
    }

    ///@notice swap token 0 for token 1. Amount represents total amount being sold, numberOfTimeIntervals determines when order expires
    function longTermSwapFrom0To1(LongTermOrders storage longTermOrders, uint256 amount0, uint256 numberOfTimeIntervals) internal returns (uint256) {
        return performLongTermSwap(longTermOrders, longTermOrders.token0, longTermOrders.token1, amount0, numberOfTimeIntervals);
    }

    ///@notice swap token 1 for token 0. Amount represents total amount being sold, numberOfTimeIntervals determines when order expires
    function longTermSwapFrom1To0(LongTermOrders storage longTermOrders, uint256 amount1, uint256 numberOfTimeIntervals) internal returns (uint256) {
        return performLongTermSwap(longTermOrders, longTermOrders.token1, longTermOrders.token0, amount1, numberOfTimeIntervals);
    }

    ///@notice adds long term swap to order pool
    function performLongTermSwap(LongTermOrders storage longTermOrders, address from, address to, uint256 amount, uint256 numberOfTimeIntervals) private returns (uint256) {
        // make sure to update virtual order state (before calling this function)

        //determine the selling rate based on number of blocks to expiry and total amount
        uint256 currentTime = block.timestamp;
        uint256 lastExpiryTimestamp = currentTime - (currentTime % longTermOrders.orderTimeInterval);
        uint256 orderExpiry = longTermOrders.orderTimeInterval * (numberOfTimeIntervals + 1) + lastExpiryTimestamp;
        uint256 sellingRate = SELL_RATE_ADDITIONAL_PRECISION * amount / (orderExpiry - currentTime);

        require(sellingRate > 0); // tokenRate cannot be zero

        //add order to correct pool
        OrderPool storage orderPool = getOrderPool(longTermOrders, from);
        orderPoolDepositOrder(orderPool, longTermOrders.orderId, sellingRate, orderExpiry);

        //add to order map
        longTermOrders.orderMap[longTermOrders.orderId] = Order(longTermOrders.orderId, orderExpiry, sellingRate, msg.sender, from, to, false);
        return longTermOrders.orderId++;
    }

    ///@notice cancel long term swap, pay out unsold tokens and well as purchased tokens
    function cancelLongTermSwap(LongTermOrders storage longTermOrders, uint256 orderId) internal returns (address sellToken, uint256 unsoldAmount, address buyToken, uint256 purchasedAmount) {
        // make sure to update virtual order state (before calling this function)

        Order storage order = longTermOrders.orderMap[orderId];
        buyToken = order.buyTokenAddr;
        sellToken = order.sellTokenAddr;

        OrderPool storage orderPool = getOrderPool(longTermOrders, sellToken);
        (unsoldAmount, purchasedAmount) = orderPoolCancelOrder(orderPool, orderId, longTermOrders.lastVirtualOrderTimestamp);

        require(order.owner == msg.sender && (unsoldAmount > 0 || purchasedAmount > 0)); // owner and amounts check

    }

    ///@notice withdraw proceeds from a long term swap (can be expired or ongoing)
    function withdrawProceedsFromLongTermSwap(LongTermOrders storage longTermOrders, uint256 orderId) internal returns (address proceedToken, uint256 proceeds, bool orderExpired) {
        // make sure to update virtual order state (before calling this function)

        Order storage order = longTermOrders.orderMap[orderId];
        proceedToken = order.buyTokenAddr;

        OrderPool storage orderPool = getOrderPool(longTermOrders, order.sellTokenAddr);
        (proceeds, orderExpired) = orderPoolWithdrawProceeds(orderPool, orderId, longTermOrders.lastVirtualOrderTimestamp);

        require(order.owner == msg.sender && proceeds > 0); // owner and amounts check
    }

    ///@notice executes all virtual orders between current lastVirtualOrderTimestamp and blockTimestamp
    //also handles orders that expire at end of final blockTimestamp. This assumes that no orders expire inside the given interval
    function executeVirtualTradesAndOrderExpiries(
        ExecuteVirtualOrdersResult memory reserveResult,
        uint256 token0SellAmount,
        uint256 token1SellAmount
    ) private view returns (uint256 token0Out, uint256 token1Out) {

        //initial amm balance
        uint256 bal0 = reserveResult.newReserve0 + reserveResult.newTwammReserve0;
        uint256 bal1 = reserveResult.newReserve1 + reserveResult.newTwammReserve1;

        //updated balances from sales
        (token0Out, token1Out) = ExecVirtualOrdersLib.computeVirtualBalances(
            reserveResult.newReserve0,
            reserveResult.newReserve1,
            token0SellAmount,
            token1SellAmount
        );

        //update balances reserves
        reserveResult.newTwammReserve0 = reserveResult.newTwammReserve0 + token0Out - token0SellAmount;
        reserveResult.newTwammReserve1 = reserveResult.newTwammReserve1 + token1Out - token1SellAmount;
        reserveResult.newReserve0 = uint112(bal0 - reserveResult.newTwammReserve0); // calculate reserve0 incl LP fees
        reserveResult.newReserve1 = uint112(bal1 - reserveResult.newTwammReserve1); // calculate reserve1 incl LP fees
        reserveResult.token0Bought += token0Out;
        reserveResult.token1Bought += token1Out;
        reserveResult.token0Sold += token0SellAmount;
        reserveResult.token1Sold += token1SellAmount;
        reserveResult.expiries += 1;
    }

    ///@notice executes all virtual orders until blockTimestamp is reached.
    function executeVirtualOrdersUntilTimestamp(LongTermOrders storage longTermOrders, uint256 blockTimestamp, ExecuteVirtualOrdersResult memory reserveResult) internal {

        uint256 lastVirtualOrderTimestampLocal = longTermOrders.lastVirtualOrderTimestamp; // save gas
        uint256 orderTimeInterval = longTermOrders.orderTimeInterval; // save gas
        uint256 nextExpiryBlockTimestamp = lastVirtualOrderTimestampLocal - (lastVirtualOrderTimestampLocal % orderTimeInterval) + orderTimeInterval;
        //iterate through time intervals eligible for order expiries, moving state forward

        OrderPool storage orderPool0 = longTermOrders.OrderPool0;
        OrderPool storage orderPool1 = longTermOrders.OrderPool1;

        while (nextExpiryBlockTimestamp < blockTimestamp) {
            // Optimization for skipping blocks with no expiry
            if (orderPool0.salesRateEndingPerTimeInterval[nextExpiryBlockTimestamp] > 0
                || orderPool1.salesRateEndingPerTimeInterval[nextExpiryBlockTimestamp] > 0) {

                //amount sold from virtual trades
                uint256 blockTimestampElapsed = nextExpiryBlockTimestamp - lastVirtualOrderTimestampLocal;
                uint256 token0SellAmount = orderPool0.currentSalesRate * blockTimestampElapsed / SELL_RATE_ADDITIONAL_PRECISION;
                uint256 token1SellAmount = orderPool1.currentSalesRate * blockTimestampElapsed / SELL_RATE_ADDITIONAL_PRECISION;

                (uint256 token0Out, uint256 token1Out) = executeVirtualTradesAndOrderExpiries(reserveResult, token0SellAmount, token1SellAmount);

                //distribute proceeds to pools. make sure to call this before orderPoolUpdateStateFromTimestampExpiry.
                orderPoolDistributePayment(orderPool0, token1Out);
                orderPoolDistributePayment(orderPool1, token0Out);

                //handle orders expiring at end of interval. call orderPoolDistributePayment before calling this.
                orderPoolUpdateStateFromTimestampExpiry(orderPool0, nextExpiryBlockTimestamp);
                orderPoolUpdateStateFromTimestampExpiry(orderPool1, nextExpiryBlockTimestamp);

                lastVirtualOrderTimestampLocal = nextExpiryBlockTimestamp;
            }
            nextExpiryBlockTimestamp += orderTimeInterval;
        }
        //finally, move state to current blockTimestamp if necessary
        if (lastVirtualOrderTimestampLocal != blockTimestamp) {

            //amount sold from virtual trades
            uint256 blockTimestampElapsed = blockTimestamp - lastVirtualOrderTimestampLocal;
            uint256 token0SellAmount = orderPool0.currentSalesRate * blockTimestampElapsed / SELL_RATE_ADDITIONAL_PRECISION;
            uint256 token1SellAmount = orderPool1.currentSalesRate * blockTimestampElapsed / SELL_RATE_ADDITIONAL_PRECISION;

            (uint256 token0Out, uint256 token1Out) = executeVirtualTradesAndOrderExpiries(reserveResult, token0SellAmount, token1SellAmount);

            //distribute proceeds to pools
            orderPoolDistributePayment(orderPool0, token1Out);
            orderPoolDistributePayment(orderPool1, token0Out);

            // skip call to orderPoolUpdateStateFromTimestampExpiry, this will not be an expiry timestamp. save gas
        }

        longTermOrders.lastVirtualOrderTimestamp = blockTimestamp;
    }

    ///@notice executes all virtual orders until blockTimestamp is reached (AS A VIEW)
    function executeVirtualOrdersUntilTimestampView(LongTermOrders storage longTermOrders, uint256 blockTimestamp, ExecuteVirtualOrdersResult memory reserveResult) internal view {

        uint256 lastVirtualOrderTimestampLocal = longTermOrders.lastVirtualOrderTimestamp; // save gas
        uint256 orderTimeInterval = longTermOrders.orderTimeInterval; // save gas
        uint256 nextExpiryBlockTimestamp = lastVirtualOrderTimestampLocal - (lastVirtualOrderTimestampLocal % orderTimeInterval) + orderTimeInterval;
        //iterate through time intervals eligible for order expiries, moving state forward

        OrderPool storage orderPool0 = longTermOrders.OrderPool0;
        OrderPool storage orderPool1 = longTermOrders.OrderPool1;

        // currentSales for each pool is mutated in the non-view (mutate locally)
        uint256 currentSalesRate0 = orderPool0.currentSalesRate;
        uint256 currentSalesRate1 = orderPool1.currentSalesRate;

        while (nextExpiryBlockTimestamp < blockTimestamp) {
            // Optimization for skipping blocks with no expiry
            if (orderPool0.salesRateEndingPerTimeInterval[nextExpiryBlockTimestamp] > 0
                || orderPool1.salesRateEndingPerTimeInterval[nextExpiryBlockTimestamp] > 0) {

                //amount sold from virtual trades
                uint256 blockTimestampElapsed = nextExpiryBlockTimestamp - lastVirtualOrderTimestampLocal;
                uint256 token0SellAmount = currentSalesRate0 * blockTimestampElapsed / SELL_RATE_ADDITIONAL_PRECISION;
                uint256 token1SellAmount = currentSalesRate1 * blockTimestampElapsed / SELL_RATE_ADDITIONAL_PRECISION;

                executeVirtualTradesAndOrderExpiries(reserveResult, token0SellAmount, token1SellAmount);

                currentSalesRate0 -= orderPool0.salesRateEndingPerTimeInterval[nextExpiryBlockTimestamp];
                currentSalesRate1 -= orderPool1.salesRateEndingPerTimeInterval[nextExpiryBlockTimestamp];

                lastVirtualOrderTimestampLocal = nextExpiryBlockTimestamp;
            }
            nextExpiryBlockTimestamp += orderTimeInterval;
        }
        //finally, move state to current blockTimestamp if necessary
        if (lastVirtualOrderTimestampLocal != blockTimestamp) {

            //amount sold from virtual trades
            uint256 blockTimestampElapsed = blockTimestamp - lastVirtualOrderTimestampLocal;
            uint256 token0SellAmount = currentSalesRate0 * blockTimestampElapsed / SELL_RATE_ADDITIONAL_PRECISION;
            uint256 token1SellAmount = currentSalesRate1 * blockTimestampElapsed / SELL_RATE_ADDITIONAL_PRECISION;

            executeVirtualTradesAndOrderExpiries(reserveResult, token0SellAmount, token1SellAmount);

        }
    }

    /// ---------------------------
    /// -------- OrderPool --------
    /// ---------------------------

    ///@notice An Order Pool is an abstraction for a pool of long term orders that sells a token at a constant rate to the embedded AMM.
    ///the order pool handles the logic for distributing the proceeds from these sales to the owners of the long term orders through a modified
    ///version of the staking algorithm from  https://uploads-ssl.webflow.com/5ad71ffeb79acc67c8bcdaba/5ad8d1193a40977462982470_scalable-reward-distribution-paper.pdf

    uint256 constant Q112 = 2**112;

    ///@notice you can think of this as a staking pool where all long term orders are staked.
    /// The pool is paid when virtual long term orders are executed, and each order is paid proportionally
    /// by the order's sale rate per time intervals
    struct OrderPool {
        ///@notice current rate that tokens are being sold (per time interval)
        uint256 currentSalesRate;

        ///@notice sum of (salesProceeds_k / salesRate_k) over every period k. Stored as a fixed precision floating point number
        uint256 rewardFactor;

        ///@notice this maps time interval numbers to the cumulative sales rate of orders that expire on that block (time interval)
        mapping(uint256 => uint256) salesRateEndingPerTimeInterval;

        ///@notice map order ids to the block timestamp in which they expire
        mapping(uint256 => uint256) orderExpiry;

        ///@notice map order ids to their sales rate
        mapping(uint256 => uint256) salesRate;

        ///@notice reward factor per order at time of submission
        mapping(uint256 => uint256) rewardFactorAtSubmission;

        ///@notice reward factor at a specific time interval
        mapping(uint256 => uint256) rewardFactorAtTimestamp;
    }

    ///@notice distribute payment amount to pool (in the case of TWAMM, proceeds from trades against amm)
    function orderPoolDistributePayment(OrderPool storage orderPool, uint256 amount) internal {
        if (orderPool.currentSalesRate != 0) {
            unchecked { // Addition is with overflow
                orderPool.rewardFactor += amount * Q112 * SELL_RATE_ADDITIONAL_PRECISION / orderPool.currentSalesRate;
            }
        }
    }

    ///@notice deposit an order into the order pool.
    function orderPoolDepositOrder(OrderPool storage orderPool, uint256 orderId, uint256 amountPerInterval, uint256 orderExpiry) internal {
        orderPool.currentSalesRate += amountPerInterval;
        orderPool.rewardFactorAtSubmission[orderId] = orderPool.rewardFactor;
        orderPool.orderExpiry[orderId] = orderExpiry;
        orderPool.salesRate[orderId] = amountPerInterval;
        orderPool.salesRateEndingPerTimeInterval[orderExpiry] += amountPerInterval;
    }

    ///@notice when orders expire after a given timestamp, we need to update the state of the pool
    function orderPoolUpdateStateFromTimestampExpiry(OrderPool storage orderPool, uint256 blockTimestamp) internal {
        orderPool.currentSalesRate -= orderPool.salesRateEndingPerTimeInterval[blockTimestamp];
        orderPool.rewardFactorAtTimestamp[blockTimestamp] = orderPool.rewardFactor;
    }

    ///@notice cancel order and remove from the order pool
    function orderPoolCancelOrder(OrderPool storage orderPool, uint256 orderId, uint256 blockTimestamp) internal returns (uint256 unsoldAmount, uint256 purchasedAmount) {
        uint256 expiry = orderPool.orderExpiry[orderId];
        require(expiry > blockTimestamp);

        //calculate amount that wasn't sold, and needs to be returned
        uint256 salesRate = orderPool.salesRate[orderId];
        unsoldAmount = (expiry - blockTimestamp) * salesRate / SELL_RATE_ADDITIONAL_PRECISION;

        //calculate amount of other token that was purchased
        unchecked { // subtraction is with underflow
            purchasedAmount = ((orderPool.rewardFactor - orderPool.rewardFactorAtSubmission[orderId]) * salesRate / SELL_RATE_ADDITIONAL_PRECISION) / Q112;
        }

        //update state
        orderPool.currentSalesRate -= salesRate;
        orderPool.salesRate[orderId] = 0;
        orderPool.orderExpiry[orderId] = 0;
        orderPool.salesRateEndingPerTimeInterval[expiry] -= salesRate;
    }

    ///@notice withdraw proceeds from pool for a given order. This can be done before or after the order has expired.
    //If the order has expired, we calculate the reward factor at time of expiry. If order has not yet expired, we
    //use current reward factor, and update the reward factor at time of staking (effectively creating a new order)
    function orderPoolWithdrawProceeds(OrderPool storage orderPool, uint256 orderId, uint256 blockTimestamp) internal returns (uint256 totalReward, bool orderExpired) {
        (orderExpired, totalReward) = orderPoolGetProceeds(orderPool, orderId, blockTimestamp);

        if (orderExpired) {
            //remove stake
            orderPool.salesRate[orderId] = 0;
        }
        //if order has not yet expired, we just adjust the start
        else {
            orderPool.rewardFactorAtSubmission[orderId] = orderPool.rewardFactor;
        }
    }

    ///@notice view function for getting the current proceeds for the given order
    function orderPoolGetProceeds(OrderPool storage orderPool, uint256 orderId, uint256 blockTimestamp) internal view returns (bool orderExpired, uint256 totalReward) {
        uint256 stakedAmount = orderPool.salesRate[orderId];
        require(stakedAmount > 0);
        uint256 orderExpiry = orderPool.orderExpiry[orderId];
        uint256 rewardFactorAtSubmission = orderPool.rewardFactorAtSubmission[orderId];

        //if order has expired, we need to calculate the reward factor at expiry
        if (blockTimestamp > orderExpiry) {
            uint256 rewardFactorAtExpiry = orderPool.rewardFactorAtTimestamp[orderExpiry];
            unchecked { // subtraction is with underflow
                totalReward = ((rewardFactorAtExpiry - rewardFactorAtSubmission) * stakedAmount / SELL_RATE_ADDITIONAL_PRECISION) / Q112;
            }
            orderExpired = true;
        }
        else {
            unchecked { // subtraction is with underflow
                totalReward = ((orderPool.rewardFactor - rewardFactorAtSubmission) * stakedAmount / SELL_RATE_ADDITIONAL_PRECISION) / Q112;
            }
            orderExpired = false;
        }
    }
}


// File contracts/Fraxswap/core/FraxswapPair.sol


// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// =========================== FraxswapPair ===========================
// ====================================================================
// TWAMM LP Pair Token
// Inspired by https://www.paradigm.xyz/2021/07/twamm
// https://github.com/para-dave/twamm

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Rich Gee: https://github.com/zer0blockchain
// Dennis: https://github.com/denett

// Logic / Algorithm Ideas
// FrankieIsLost: https://github.com/FrankieIsLost

// Reviewer(s) / Contributor(s)
// Travis Moore: https://github.com/FortisFortuna
// Sam Kazemian: https://github.com/samkazemian
// Drake Evans: https://github.com/DrakeEvans
// Jack Corddry: https://github.com/corddry
// Justin Moore: https://github.com/0xJM









contract FraxswapPair is IUniswapV2PairPartialV5, FraxswapERC20 {
    using UQ112x112 for uint224;
    using LongTermOrdersLib for LongTermOrdersLib.LongTermOrders;
    using LongTermOrdersLib for LongTermOrdersLib.ExecuteVirtualOrdersResult;

    /// ---------------------------
    /// -----TWAMM Parameters -----
    /// ---------------------------

    // address public owner_address;

    ///@notice time interval that are eligible for order expiry (to align expiries)
    uint256 public orderTimeInterval = 3600;

    ///@notice data structure to handle long term orders
    LongTermOrdersLib.LongTermOrders internal longTermOrders;

    uint112 public twammReserve0;
    uint112 public twammReserve1;

    bool public newSwapsPaused;

    modifier execVirtualOrders() {
        executeVirtualOrdersInternal(block.timestamp);
        _;
    }

    /// ---------------------------
    /// -------- Modifiers --------
    /// ---------------------------

    ///@notice Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(IUniswapV2FactoryV5(factory).feeToSetter() == msg.sender); // NOT OWNER
        _;
    }

    ///@notice Checks if new swaps are paused. If they are, only allow closing of existing ones.
    modifier isNotPaused() {
        require(newSwapsPaused == false); // NEW LT ORDERS PAUSED
        _;
    }

    /// ---------------------------
    /// --------- Events ----------
    /// ---------------------------

    ///@notice An event emitted when a long term swap from token0 to token1 is performed
    event LongTermSwap0To1(address indexed addr, uint256 orderId, uint256 amount0In, uint256 numberOfTimeIntervals);

    ///@notice An event emitted when a long term swap from token1 to token0 is performed
    event LongTermSwap1To0(address indexed addr, uint256 orderId, uint256 amount1In, uint256 numberOfTimeIntervals);

    ///@notice An event emitted when a long term swap is cancelled
    event CancelLongTermOrder(address indexed addr, uint256 orderId, address sellToken, uint256 unsoldAmount, address buyToken, uint256 purchasedAmount);

    ///@notice An event emitted when a long term swap is withdrawn
    event WithdrawProceedsFromLongTermOrder(address indexed addr, uint256 orderId, address indexed proceedToken, uint256 proceeds, bool orderExpired);

    ///@notice An event emitted when virtual orders are executed
    event VirtualOrderExecution(uint256 blocktimestamp, uint256 newReserve0, uint256 newReserve1, uint256 newTwammReserve0, uint256 newTwammReserve1, uint256 token0Bought, uint256 token1Bought, uint256 token0Sold, uint256 token1Sold, uint256 expiries);

    /// -------------------------------
    /// -----UNISWAPV2 Parameters -----
    /// -------------------------------

    uint public constant override MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public override factory;
    address public override token0;
    address public override token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves

    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public override kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    // Track order IDs
    mapping(address => uint256[]) public orderIDsForUser;

    TWAPObservation[] public TWAPObservationHistory;

    struct TWAPObservation {
        uint timestamp;
        uint price0CumulativeLast;
        uint price1CumulativeLast;
    }
    function price0CumulativeLast() public view override returns (uint){
        return TWAPObservationHistory.length > 0 ? TWAPObservationHistory[TWAPObservationHistory.length - 1].price0CumulativeLast : 0;
    }
    function price1CumulativeLast() public view override returns (uint){
        return TWAPObservationHistory.length > 0 ? TWAPObservationHistory[TWAPObservationHistory.length - 1].price1CumulativeLast : 0;
    }
    function getTWAPHistoryLength() public view override returns (uint){
        return TWAPObservationHistory.length;
    }

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1); // LOCKED
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getOrderIDsForUser(address user) external view returns (uint256[] memory) {
        return orderIDsForUser[user];
    }

    function getOrderIDsForUserLength(address user) external view returns (uint256) {
        return orderIDsForUser[user].length;
    }

    function getDetailedOrdersForUser(address user, uint256 offset, uint256 limit) external view returns (LongTermOrdersLib.Order[] memory detailed_orders) {
        uint256[] memory order_ids = orderIDsForUser[user];
        uint256 length_remaining = order_ids.length - offset;
        uint256 limit_to_use = Math.min(limit, length_remaining);
        detailed_orders = new LongTermOrdersLib.Order[](limit_to_use);

        for (uint256 i = 0; i < limit_to_use; i++){ 
            detailed_orders[i] = longTermOrders.orderMap[order_ids[offset + i]];
        }
    }

    function getReserves() public override view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        return (reserve0, reserve1, blockTimestampLast);
    }

    function getTwammReserves() public override view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast, uint112 _twammReserve0, uint112 _twammReserve1) {
        return (reserve0, reserve1, blockTimestampLast, twammReserve0, twammReserve1);
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "EC01"); // TRANSFER_FAILED
    }

    constructor() public {
        factory = msg.sender;
        // owner_address = IUniswapV2FactoryV5(factory).feeToSetter();
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external override {
        require(msg.sender == factory); // FORBIDDEN
        // sufficient check
        token0 = _token0;
        token1 = _token1;

        // TWAMM
        longTermOrders.initialize(_token0, _token1, block.timestamp, orderTimeInterval);
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 + twammReserve0 <= type(uint112).max && balance1 + twammReserve1 <= type(uint112).max, "EC02"); // OVERFLOW
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);

        uint32 timeElapsed;
        unchecked{
            timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
            if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
                // * never overflows, and + overflow is desired
                TWAPObservationHistory.push(
                    TWAPObservation(
                        blockTimestamp,
                        price0CumulativeLast() + uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed,
                        price1CumulativeLast() + uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed
                    )
                );
            }
        }

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);

        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2FactoryV5(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0) * _reserve1);
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply * (rootK - rootKLast);
                    uint denominator = (rootK * 5) + rootKLast;
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external override lock execVirtualOrders returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20V5(token0).balanceOf(address(this)) - twammReserve0;
        uint balance1 = IERC20V5(token1).balanceOf(address(this)) - twammReserve1;
        uint amount0 = balance0 - _reserve0;
        uint amount1 = balance1 - _reserve1;

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0 * _totalSupply / _reserve0, amount1 * _totalSupply / _reserve1);
        }
        require(liquidity > 0); // INSUFFICIENT_LIQUIDITY_MINTED
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external override lock execVirtualOrders returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint balance0 = IERC20V5(_token0).balanceOf(address(this)) - twammReserve0;
        uint balance1 = IERC20V5(_token1).balanceOf(address(this)) - twammReserve1;
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity * balance0 / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity * balance1 / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0); // INSUFFICIENT_LIQUIDITY_BURNED
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20V5(_token0).balanceOf(address(this)) - twammReserve0;
        balance1 = IERC20V5(_token1).balanceOf(address(this)) - twammReserve1;

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0) * reserve1; // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external override lock execVirtualOrders {
        require(amount0Out > 0 || amount1Out > 0, "EC03"); // INSUFFICIENT_OUTPUT_AMOUNT
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "EC04"); // INSUFFICIENT_LIQUIDITY

        uint balance0;
        uint balance1;
        {// scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "EC05"); // INVALID_TO
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0) IUniswapV2CalleeV5(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20V5(_token0).balanceOf(address(this)) - twammReserve0;
            balance1 = IERC20V5(_token1).balanceOf(address(this)) - twammReserve1;
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "EC06"); // INSUFFICIENT_INPUT_AMOUNT
        {// scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
            uint balance1Adjusted = (balance1 * 1000) - (amount1In * 3);
            require(balance0Adjusted * balance1Adjusted >= uint(_reserve0) * _reserve1 * (1000 ** 2), 'K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external override lock execVirtualOrders {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20V5(_token0).balanceOf(address(this)) - (reserve0 + twammReserve0));
        _safeTransfer(_token1, to, IERC20V5(_token1).balanceOf(address(this)) - (reserve1 + twammReserve1));
    }

    // force reserves to match balances
    function sync() external override lock execVirtualOrders {
        _update(
            IERC20V5(token0).balanceOf(address(this)) - twammReserve0,
            IERC20V5(token1).balanceOf(address(this)) - twammReserve1,
            reserve0, reserve1
        );
    }

    // TWAMM

    ///@notice calculate the amount in for token0 using the balance diff to handle feeOnTransfer tokens
    function transferAmount0In(uint amount0In) internal returns(uint256){
        // prev balance
        uint bal0 = IERC20V5(token0).balanceOf(address(this));
        // transfer amount to contract
        TransferHelper.safeTransferFrom(token0, msg.sender, address(this), amount0In);
        // balance change
        return IERC20V5(token0).balanceOf(address(this)) - bal0;
    }

    ///@notice calculate the amount in for token1 using the balance diff to handle feeOnTransfer tokens
    function transferAmount1In(uint amount1In) internal returns(uint256){
        // prev balance
        uint bal1 = IERC20V5(token1).balanceOf(address(this));
        // transfer amount to contract
        TransferHelper.safeTransferFrom(token1, msg.sender, address(this), amount1In);
        // balance change
        return IERC20V5(token1).balanceOf(address(this)) - bal1;
    }

    ///@notice create a long term order to swap from token0
    ///@param amount0In total amount of token0 to swap
    ///@param numberOfTimeIntervals number of time intervals over which to execute long term order
    function longTermSwapFrom0To1(uint256 amount0In, uint256 numberOfTimeIntervals) external lock isNotPaused execVirtualOrders returns (uint256 orderId) {
        uint amount0 = transferAmount0In(amount0In);
        twammReserve0 += uint112(amount0);
        require(uint256(reserve0) + twammReserve0 <= type(uint112).max); // OVERFLOW
        orderId = longTermOrders.longTermSwapFrom0To1(amount0, numberOfTimeIntervals);
        orderIDsForUser[msg.sender].push(orderId);
        emit LongTermSwap0To1(msg.sender, orderId, amount0, numberOfTimeIntervals);
    }

    ///@notice create a long term order to swap from token1
    ///@param amount1In total amount of token1 to swap
    ///@param numberOfTimeIntervals number of time intervals over which to execute long term order
    function longTermSwapFrom1To0(uint256 amount1In, uint256 numberOfTimeIntervals) external lock isNotPaused execVirtualOrders returns (uint256 orderId) {
        uint amount1 = transferAmount1In(amount1In);
        twammReserve1 += uint112(amount1);
        require(uint256(reserve1) + twammReserve1 <= type(uint112).max); // OVERFLOW
        orderId = longTermOrders.longTermSwapFrom1To0(amount1, numberOfTimeIntervals);
        orderIDsForUser[msg.sender].push(orderId);
        emit LongTermSwap1To0(msg.sender, orderId, amount1, numberOfTimeIntervals);
    }

    ///@notice stop the execution of a long term order
    function cancelLongTermSwap(uint256 orderId) external lock execVirtualOrders {
        (address sellToken, uint256 unsoldAmount, address buyToken, uint256 purchasedAmount) = longTermOrders.cancelLongTermSwap(orderId);

        bool buyToken0 = buyToken == token0;
        twammReserve0 -= uint112(buyToken0 ? purchasedAmount : unsoldAmount);
        twammReserve1 -= uint112(buyToken0 ? unsoldAmount : purchasedAmount);

        // update order. Used for tracking / informational
        longTermOrders.orderMap[orderId].isComplete = true;

        // transfer to owner of order
        _safeTransfer(buyToken, msg.sender, purchasedAmount);
        _safeTransfer(sellToken, msg.sender, unsoldAmount);

        emit CancelLongTermOrder(msg.sender, orderId, sellToken, unsoldAmount, buyToken, purchasedAmount);
    }

    ///@notice withdraw proceeds from a long term swap
    function withdrawProceedsFromLongTermSwap(uint256 orderId) external lock execVirtualOrders returns (bool is_expired, address rewardTkn, uint256 totalReward) {
        (address proceedToken, uint256 proceeds, bool orderExpired) = longTermOrders.withdrawProceedsFromLongTermSwap(orderId);
        if (proceedToken == token0) {
            twammReserve0 -= uint112(proceeds);
        } else {
            twammReserve1 -= uint112(proceeds);
        }

        // update order. Used for tracking / informational
        if (orderExpired) longTermOrders.orderMap[orderId].isComplete = true;

        // transfer to owner of order
        _safeTransfer(proceedToken, msg.sender, proceeds);

        emit WithdrawProceedsFromLongTermOrder(msg.sender, orderId, proceedToken, proceeds, orderExpired);

        return (orderExpired, proceedToken, proceeds);
    }

    ///@notice execute virtual orders in the twamm, bring it up to the blockNumber passed in
    ///updates the TWAP if it is the first amm tx of the block
    function executeVirtualOrdersInternal(uint256 blockTimestamp) internal {

        if(newSwapsPaused) return; // skip twamm executions
        if(twammUpToDate()) return; // save gas

        LongTermOrdersLib.ExecuteVirtualOrdersResult memory result;
        result.newReserve0 = reserve0;
        result.newReserve1 = reserve1;
        result.newTwammReserve0 = twammReserve0;
        result.newTwammReserve1 = twammReserve1;

        longTermOrders.executeVirtualOrdersUntilTimestamp(blockTimestamp, result);

        twammReserve0 = uint112(result.newTwammReserve0);
        twammReserve1 = uint112(result.newTwammReserve1);
        
        uint112 newReserve0 = uint112(result.newReserve0);
        uint112 newReserve1 = uint112(result.newReserve1);

        uint32 _blockTimestamp = uint32(blockTimestamp % 2 ** 32);
        uint32 timeElapsed;
        unchecked{
            timeElapsed = _blockTimestamp - blockTimestampLast; // overflow is desired
        }
        // update reserve0 and reserve1
        if ( timeElapsed > 0 && (newReserve0 != reserve0 || newReserve1 != reserve1)) {
            emit VirtualOrderExecution(
                _blockTimestamp,
                result.newReserve0,
                result.newReserve1,
                result.newTwammReserve0,
                result.newTwammReserve1,
                result.token0Bought,
                result.token1Bought,
                result.token0Sold,
                result.token1Sold,
                result.expiries
            );
            _update(newReserve0, newReserve1, reserve0, reserve1);
        } else {
            reserve0 = newReserve0;
            reserve1 = newReserve1;
        }
    }

    ///@notice convenience function to execute virtual orders. Note that this already happens
    ///before most interactions with the AMM
    function executeVirtualOrders(uint256 blockTimestamp) public override lock {
        // blockTimestamp is valid
        require(longTermOrders.lastVirtualOrderTimestamp <= blockTimestamp && blockTimestamp <= block.timestamp); // INVALID TIMESTAMP
        executeVirtualOrdersInternal(blockTimestamp);
    }

    /// ---------------------------
    /// ------- TWAMM Views -------
    /// ---------------------------

    ///@notice util function for getting the next orderId
    function getNextOrderID() public override view returns (uint256){
        return longTermOrders.orderId;
    }

    ///@notice util function for checking if the twamm is up to date
    function twammUpToDate() public override view returns (bool) {
        return block.timestamp == longTermOrders.lastVirtualOrderTimestamp;
    }

    function getReserveAfterTwamm(uint256 blockTimestamp) public view returns (
        uint112 _reserve0, uint112 _reserve1,
        uint256 lastVirtualOrderTimestamp,
        uint112 _twammReserve0, uint112 _twammReserve1
    ) {

        lastVirtualOrderTimestamp = longTermOrders.lastVirtualOrderTimestamp;

        uint112 bal0 = reserve0 + twammReserve0; // save the balance of token0
        uint112 bal1 = reserve1 + twammReserve1; // save the balance of token1

        LongTermOrdersLib.ExecuteVirtualOrdersResult memory result;
        result.newReserve0 = reserve0;
        result.newReserve1 = reserve1;
        result.newTwammReserve0 = twammReserve0;
        result.newTwammReserve1 = twammReserve1;

        longTermOrders.executeVirtualOrdersUntilTimestampView(blockTimestamp, result);

        _reserve0 = uint112(bal0 - result.newTwammReserve0);
        _reserve1 = uint112(bal1 - result.newTwammReserve1);
        _twammReserve0 = uint112(result.newTwammReserve0);
        _twammReserve1 = uint112(result.newTwammReserve1);
    }

    ///@notice returns the current state of the twamm
    function getTwammState() public override view returns (
        uint256 token0Rate,
        uint256 token1Rate,
        uint256 lastVirtualOrderTimestamp,
        uint256 orderTimeInterval_rtn,
        uint256 rewardFactorPool0,
        uint256 rewardFactorPool1
    ){
        token0Rate = longTermOrders.OrderPool0.currentSalesRate;
        token1Rate = longTermOrders.OrderPool1.currentSalesRate;
        lastVirtualOrderTimestamp = longTermOrders.lastVirtualOrderTimestamp;
        orderTimeInterval_rtn = longTermOrders.orderTimeInterval;
        rewardFactorPool0 = longTermOrders.OrderPool0.rewardFactor;
        rewardFactorPool1 = longTermOrders.OrderPool1.rewardFactor;
    }

    ///@notice returns salesRates ending on this blockTimestamp
    function getTwammSalesRateEnding(uint256 _blockTimestamp) public override view returns (
        uint256 orderPool0SalesRateEnding,
        uint256 orderPool1SalesRateEnding
    ){
        uint256 lastExpiryTimestamp = _blockTimestamp - (_blockTimestamp % longTermOrders.orderTimeInterval);
        orderPool0SalesRateEnding = longTermOrders.OrderPool0.salesRateEndingPerTimeInterval[lastExpiryTimestamp];
        orderPool1SalesRateEnding = longTermOrders.OrderPool1.salesRateEndingPerTimeInterval[lastExpiryTimestamp];
    }

    ///@notice returns reward factors at this blockTimestamp
    function getTwammRewardFactor(uint256 _blockTimestamp) public override view returns (
        uint256 rewardFactorPool0AtTimestamp,
        uint256 rewardFactorPool1AtTimestamp
    ){
        uint256 lastExpiryTimestamp = _blockTimestamp - (_blockTimestamp % longTermOrders.orderTimeInterval);
        rewardFactorPool0AtTimestamp = longTermOrders.OrderPool0.rewardFactorAtTimestamp[lastExpiryTimestamp];
        rewardFactorPool1AtTimestamp = longTermOrders.OrderPool1.rewardFactorAtTimestamp[lastExpiryTimestamp];
    }

    ///@notice returns the twamm Order struct
    function getTwammOrder(uint256 orderId) public override view returns (
        uint256 id,
        uint256 expirationTimestamp,
        uint256 saleRate,
        address owner,
        address sellTokenAddr,
        address buyTokenAddr
    ){
        require(orderId < longTermOrders.orderId); // INVALID ORDERID
        LongTermOrdersLib.Order storage order = longTermOrders.orderMap[orderId];
        return (order.id, order.expirationTimestamp, order.saleRate, order.owner, order.sellTokenAddr, order.buyTokenAddr);
    }

    ///@notice returns the twamm Order withdrawable proceeds
    // IMPORTANT: Can be stale. Should call executeVirtualOrders first or use getTwammOrderProceeds below.
    // You can also .call() withdrawProceedsFromLongTermSwap
    // blockTimestamp should be <= current
    function getTwammOrderProceedsView(uint256 orderId, uint256 blockTimestamp) public override view returns (
        bool orderExpired,
        uint256 totalReward
    ){
        require(orderId < longTermOrders.orderId); // INVALID ORDERID
        LongTermOrdersLib.OrderPool storage orderPool = LongTermOrdersLib.getOrderPool(longTermOrders, longTermOrders.orderMap[orderId].sellTokenAddr);
        (orderExpired, totalReward) = LongTermOrdersLib.orderPoolGetProceeds(orderPool, orderId, blockTimestamp);
    }

    ///@notice returns the twamm Order withdrawable proceeds
    // Need to update the virtual orders first
    function getTwammOrderProceeds(uint256 orderId) public override returns (
        bool orderExpired,
        uint256 totalReward
    ){
        executeVirtualOrders(block.timestamp);
        return getTwammOrderProceedsView(orderId, block.timestamp);
    }


    /* ========== RESTRICTED FUNCTIONS - Owner only ========== */

    // Only callable once
    function togglePauseNewSwaps() external override onlyOwner {
        // Pause new swaps
        require(!newSwapsPaused);
        newSwapsPaused = true;
    }
}


// File contracts/Fraxswap/core/FraxswapFactory.sol


// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================== FraxswapFactory =========================
// ====================================================================
// TWAMM LP Pair Factory
// Inspired by https://www.paradigm.xyz/2021/07/twamm
// https://github.com/para-dave/twamm

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Rich Gee: https://github.com/zer0blockchain
// Dennis: https://github.com/denett

// Logic / Algorithm Ideas
// FrankieIsLost: https://github.com/FrankieIsLost

// Reviewer(s) / Contributor(s)
// Travis Moore: https://github.com/FortisFortuna
// Sam Kazemian: https://github.com/samkazemian
// Drake Evans: https://github.com/DrakeEvans
// Jack Corddry: https://github.com/corddry
// Justin Moore: https://github.com/0xJM
contract FraxswapFactory is IUniswapV2FactoryV5 {
    address public override feeTo;
    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    ///@notice Throws if called by any account other than the feeToSetter.
    modifier onlyFTS() {
        require(msg.sender == feeToSetter); // FORBIDDEN
        _;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES"); // IDENTICAL_ADDRESSES
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "ZERO_ADDRESS"); // ZERO_ADDRESS
        require(getPair[token0][token1] == address(0), "PAIR_EXISTS"); // PAIR_EXISTS // single check is sufficient
        bytes memory bytecode = type(FraxswapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        FraxswapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override onlyFTS {
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override onlyFTS {
        feeToSetter = _feeToSetter;
    }
}