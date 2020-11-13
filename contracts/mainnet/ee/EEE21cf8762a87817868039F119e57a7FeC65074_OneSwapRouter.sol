// File: contracts/interfaces/IOneSwapRouter.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IOneSwapRouter {
    event AddLiquidity(uint stockAmount, uint moneyAmount, uint liquidity);
    event PairCreated(address indexed pair, address stock, address money, bool isOnlySwap);

    function factory() external pure returns (address);

    // liquidity
    function addLiquidity(
        address stock,
        address money,
        bool isOnlySwap,
        uint amountStockDesired,
        uint amountMoneyDesired,
        uint amountStockMin,
        uint amountMoneyMin,
        address to,
        uint deadline
    ) external payable returns (uint amountStock, uint amountMoney, uint liquidity);
    function removeLiquidity(
        address pair,
        uint liquidity,
        uint amountStockMin,
        uint amountMoneyMin,
        address to,
        uint deadline
    ) external returns (uint amountStock, uint amountMoney);

    // swap token
    function swapToken(
        address token,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    // limit order
    function limitOrder(
        bool isBuy,
        address pair,
        uint prevKey,
        uint price,
        uint32 id,
        uint stockAmount,
        uint deadline
    ) external payable;
}

// File: contracts/interfaces/IOneSwapFactory.sol

pragma solidity 0.6.12;

interface IOneSwapFactory {
    event PairCreated(address indexed pair, address stock, address money, bool isOnlySwap);

    function createPair(address stock, address money, bool isOnlySwap) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setFeeBPS(uint32 bps) external;
    function setPairLogic(address implLogic) external;

    function allPairsLength() external view returns (uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function feeBPS() external view returns (uint32);
    function pairLogic() external returns (address);
    function getTokensFromPair(address pair) external view returns (address stock, address money);
    function tokensToPair(address stock, address money, bool isOnlySwap) external view returns (address pair);
}

// File: contracts/interfaces/IOneSwapPair.sol

pragma solidity 0.6.12;

interface IOneSwapERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IOneSwapPool {
    // more liquidity was minted
    event Mint(address indexed sender, uint stockAndMoneyAmount, address indexed to);
    // liquidity was burned
    event Burn(address indexed sender, uint stockAndMoneyAmount, address indexed to);
    // amounts of reserved stock and money in this pair changed
    event Sync(uint reserveStockAndMoney);

    function internalStatus() external view returns(uint[3] memory res);
    function getReserves() external view returns (uint112 reserveStock, uint112 reserveMoney, uint32 firstSellID);
    function getBooked() external view returns (uint112 bookedStock, uint112 bookedMoney, uint32 firstBuyID);
    function stock() external returns (address);
    function money() external returns (address);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint stockAmount, uint moneyAmount);
    function skim(address to) external;
    function sync() external;
}

interface IOneSwapPair {
    event NewLimitOrder(uint data); // new limit order was sent by an account
    event NewMarketOrder(uint data); // new market order was sent by an account
    event OrderChanged(uint data); // old orders in orderbook changed
    event DealWithPool(uint data); // new order deal with the AMM pool
    event RemoveOrder(uint data); // an order was removed from the orderbook
    
    // Return three prices in rational number form, i.e., numerator/denominator.
    // They are: the first sell order's price; the first buy order's price; the current price of the AMM pool.
    function getPrices() external returns (
        uint firstSellPriceNumerator,
        uint firstSellPriceDenominator,
        uint firstBuyPriceNumerator,
        uint firstBuyPriceDenominator,
        uint poolPriceNumerator,
        uint poolPriceDenominator);

    // This function queries a list of orders in orderbook. It starts from 'id' and iterates the single-linked list, util it reaches the end, 
    // or until it has found 'maxCount' orders. If 'id' is 0, it starts from the beginning of the single-linked list.
    // It may cost a lot of gas. So you'd not to call in on chain. It is mainly for off-chain query.
    // The first uint256 returned by this function is special: the lowest 24 bits is the first order's id and the the higher bits is block height.
    // THe other uint256s are all corresponding to an order record of the single-linked list.
    function getOrderList(bool isBuy, uint32 id, uint32 maxCount) external view returns (uint[] memory);

    // remove an order from orderbook and return its booked (i.e. frozen) money to maker
    // 'id' points to the order to be removed
    // prevKey points to 3 previous orders in the single-linked list
    function removeOrder(bool isBuy, uint32 id, uint72 positionID) external;

    function removeOrders(uint[] calldata rmList) external;

    // Try to deal a new limit order or insert it into orderbook
    // its suggested order id is 'id' and suggested positions are in 'prevKey'
    // prevKey points to 3 existing orders in the single-linked list
    // the order's sender is 'sender'. the order's amount is amount*stockUnit, which is the stock amount to be sold or bought.
    // the order's price is 'price32', which is decimal floating point value.
    function addLimitOrder(bool isBuy, address sender, uint64 amount, uint32 price32, uint32 id, uint72 prevKey) external payable;

    // Try to deal a new market order. 'sender' pays 'inAmount' of 'inputToken', in exchange of the other token kept by this pair
    function addMarketOrder(address inputToken, address sender, uint112 inAmount) external payable returns (uint);

    // Given the 'amount' of stock and decimal floating point price 'price32', calculate the 'stockAmount' and 'moneyAmount' to be traded
    function calcStockAndMoney(uint64 amount, uint32 price32) external pure returns (uint stockAmount, uint moneyAmount);
}

// File: contracts/interfaces/IERC20.sol

pragma solidity 0.6.12;

interface IERC20 {
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

// File: contracts/libraries/SafeMath256.sol

pragma solidity 0.6.12;

library SafeMath256 {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/libraries/DecFloat32.sol

pragma solidity 0.6.12;

/*
This library defines a decimal floating point number. It has 8 decimal significant digits. Its maximum value is 9.9999999e+15.
And its minimum value is 1.0e-16. The following golang code explains its detail implementation.

func buildPrice(significant int, exponent int) uint32 {
	if !(10000000 <= significant && significant <= 99999999) {
		panic("Invalid significant")
	}
	if !(-16 <= exponent && exponent <= 15) {
		panic("Invalid exponent")
	}
	return uint32(((exponent+16)<<27)|significant);
}

func priceToFloat(price uint32) float64 {
	exponent := int(price>>27)
	significant := float64(price&((1<<27)-1))
	return significant * math.Pow10(exponent-23)
}

*/

// A price presented as a rational number
struct RatPrice {
    uint numerator;   // at most 54bits
    uint denominator; // at most 76bits
}

library DecFloat32 {
    uint32 public constant MANTISSA_MASK = (1<<27) - 1;
    uint32 public constant MAX_MANTISSA = 9999_9999;
    uint32 public constant MIN_MANTISSA = 1000_0000;
    uint32 public constant MIN_PRICE = MIN_MANTISSA;
    uint32 public constant MAX_PRICE = (31<<27)|MAX_MANTISSA;

    // 10 ** (i + 1)
    function powSmall(uint32 i) internal pure returns (uint) {
        uint x = 2695994666777834996822029817977685892750687677375768584125520488993233305610;
        return (x >> (32*i)) & ((1<<32)-1);
    }

    // 10 ** (i * 8)
    function powBig(uint32 i) internal pure returns (uint) {
        uint y = 3402823669209384634633746076162356521930955161600000001;
        return (y >> (64*i)) & ((1<<64)-1);
    }

    // if price32=( 0<<27)|12345678 then numerator=12345678 denominator=100000000000000000000000
    // if price32=( 1<<27)|12345678 then numerator=12345678 denominator=10000000000000000000000
    // if price32=( 2<<27)|12345678 then numerator=12345678 denominator=1000000000000000000000
    // if price32=( 3<<27)|12345678 then numerator=12345678 denominator=100000000000000000000
    // if price32=( 4<<27)|12345678 then numerator=12345678 denominator=10000000000000000000
    // if price32=( 5<<27)|12345678 then numerator=12345678 denominator=1000000000000000000
    // if price32=( 6<<27)|12345678 then numerator=12345678 denominator=100000000000000000
    // if price32=( 7<<27)|12345678 then numerator=12345678 denominator=10000000000000000
    // if price32=( 8<<27)|12345678 then numerator=12345678 denominator=1000000000000000
    // if price32=( 9<<27)|12345678 then numerator=12345678 denominator=100000000000000
    // if price32=(10<<27)|12345678 then numerator=12345678 denominator=10000000000000
    // if price32=(11<<27)|12345678 then numerator=12345678 denominator=1000000000000
    // if price32=(12<<27)|12345678 then numerator=12345678 denominator=100000000000
    // if price32=(13<<27)|12345678 then numerator=12345678 denominator=10000000000
    // if price32=(14<<27)|12345678 then numerator=12345678 denominator=1000000000
    // if price32=(15<<27)|12345678 then numerator=12345678 denominator=100000000
    // if price32=(16<<27)|12345678 then numerator=12345678 denominator=10000000
    // if price32=(17<<27)|12345678 then numerator=12345678 denominator=1000000
    // if price32=(18<<27)|12345678 then numerator=12345678 denominator=100000
    // if price32=(19<<27)|12345678 then numerator=12345678 denominator=10000
    // if price32=(20<<27)|12345678 then numerator=12345678 denominator=1000
    // if price32=(21<<27)|12345678 then numerator=12345678 denominator=100
    // if price32=(22<<27)|12345678 then numerator=12345678 denominator=10
    // if price32=(23<<27)|12345678 then numerator=12345678 denominator=1
    // if price32=(24<<27)|12345678 then numerator=123456780 denominator=1
    // if price32=(25<<27)|12345678 then numerator=1234567800 denominator=1
    // if price32=(26<<27)|12345678 then numerator=12345678000 denominator=1
    // if price32=(27<<27)|12345678 then numerator=123456780000 denominator=1
    // if price32=(28<<27)|12345678 then numerator=1234567800000 denominator=1
    // if price32=(29<<27)|12345678 then numerator=12345678000000 denominator=1
    // if price32=(30<<27)|12345678 then numerator=123456780000000 denominator=1
    // if price32=(31<<27)|12345678 then numerator=1234567800000000 denominator=1
    function expandPrice(uint32 price32) internal pure returns (RatPrice memory) {
        uint s = price32&((1<<27)-1);
        uint32 a = price32 >> 27;
        RatPrice memory price;
        if(a >= 24) {
            uint32 b = a - 24;
            price.numerator = s * powSmall(b);
            price.denominator = 1;
        } else if(a == 23) {
            price.numerator = s;
            price.denominator = 1;
        } else {
            uint32 b = 22 - a;
            price.numerator = s;
            price.denominator = powSmall(b&0x7) * powBig(b>>3);
        }
        return price;
    }

    function getExpandPrice(uint price) internal pure returns(uint numerator, uint denominator) {
        uint32 m = uint32(price) & MANTISSA_MASK;
        require(MIN_MANTISSA <= m && m <= MAX_MANTISSA, "Invalid Price");
        RatPrice memory actualPrice = expandPrice(uint32(price));
        return (actualPrice.numerator, actualPrice.denominator);
    }

}

// File: contracts/OneSwapRouter.sol

pragma solidity 0.6.12;








contract OneSwapRouter is IOneSwapRouter {
    using SafeMath256 for uint;
    address public immutable override factory;

    modifier ensure(uint deadline) {
        // solhint-disable-next-line not-rely-on-time,
        require(deadline >= block.timestamp, "OneSwapRouter: EXPIRED");
        _;
    }

    constructor(address _factory) public {
        factory = _factory;
    }

    function _addLiquidity(address pair, uint amountStockDesired, uint amountMoneyDesired,
        uint amountStockMin, uint amountMoneyMin) private view returns (uint amountStock, uint amountMoney) {

        (uint reserveStock, uint reserveMoney, ) = IOneSwapPool(pair).getReserves();
        if (reserveStock == 0 && reserveMoney == 0) {
            (amountStock, amountMoney) = (amountStockDesired, amountMoneyDesired);
        } else {
            uint amountMoneyOptimal = _quote(amountStockDesired, reserveStock, reserveMoney);
            if (amountMoneyOptimal <= amountMoneyDesired) {
                require(amountMoneyOptimal >= amountMoneyMin, "OneSwapRouter: INSUFFICIENT_MONEY_AMOUNT");
                (amountStock, amountMoney) = (amountStockDesired, amountMoneyOptimal);
            } else {
                uint amountStockOptimal = _quote(amountMoneyDesired, reserveMoney, reserveStock);
                assert(amountStockOptimal <= amountStockDesired);
                require(amountStockOptimal >= amountStockMin, "OneSwapRouter: INSUFFICIENT_STOCK_AMOUNT");
                (amountStock, amountMoney) = (amountStockOptimal, amountMoneyDesired);
            }
        }
    }

    function addLiquidity(address stock, address money, bool isOnlySwap, uint amountStockDesired,
        uint amountMoneyDesired, uint amountStockMin, uint amountMoneyMin, address to, uint deadline) external
        payable override ensure(deadline) returns (uint amountStock, uint amountMoney, uint liquidity) {

        if (stock != address(0) && money != address(0)) {
            require(msg.value == 0, 'OneSwapRouter: NOT_ENTER_ETH_VALUE');
        }
        address pair = IOneSwapFactory(factory).tokensToPair(stock, money, isOnlySwap);
        if (pair == address(0)) {
            pair = IOneSwapFactory(factory).createPair(stock, money, isOnlySwap);
        }
        (amountStock, amountMoney) = _addLiquidity(pair, amountStockDesired,
            amountMoneyDesired, amountStockMin, amountMoneyMin);
        _safeTransferFrom(stock, msg.sender, pair, amountStock);
        _safeTransferFrom(money, msg.sender, pair, amountMoney);
        liquidity = IOneSwapPool(pair).mint(to);
        emit AddLiquidity(amountStock, amountMoney, liquidity);
    }

    function _removeLiquidity(address pair, uint liquidity, uint amountStockMin,
        uint amountMoneyMin, address to) private returns (uint amountStock, uint amountMoney) {
        IERC20(pair).transferFrom(msg.sender, pair, liquidity);
        (amountStock, amountMoney) = IOneSwapPool(pair).burn(to);
        require(amountStock >= amountStockMin, "OneSwapRouter: INSUFFICIENT_STOCK_AMOUNT");
        require(amountMoney >= amountMoneyMin, "OneSwapRouter: INSUFFICIENT_MONEY_AMOUNT");
    }

    function removeLiquidity(address pair, uint liquidity, uint amountStockMin, uint amountMoneyMin,
        address to, uint deadline) external override ensure(deadline) returns (uint amountStock, uint amountMoney) {
        // ensure pair exist
        _getTokensFromPair(pair);
        (amountStock, amountMoney) = _removeLiquidity(pair, liquidity, amountStockMin, amountMoneyMin, to);
    }

    function _swap(address input, uint amountIn, address[] memory path, address _to) internal virtual returns (uint[] memory amounts) {
        amounts = new uint[](path.length + 1);
        amounts[0] = amountIn;

        for (uint i = 0; i < path.length; i++) {
            (address to, bool isLastSwap) = i < path.length - 1 ? (path[i+1], false) : (_to, true);
            amounts[i + 1] = IOneSwapPair(path[i]).addMarketOrder(input, to, uint112(amounts[i]));
            if (!isLastSwap) {
                (address stock, address money) = _getTokensFromPair(path[i]);
                input = (stock != input) ? stock : money;
            }
        }
    }

    function swapToken(address token, uint amountIn, uint amountOutMin, address[] calldata path,
        address to, uint deadline) external payable override ensure(deadline) returns (uint[] memory amounts) {

        if (token != address(0)) { require(msg.value == 0, 'OneSwapRouter: NOT_ENTER_ETH_VALUE'); }
        require(path.length >= 1, "OneSwapRouter: INVALID_PATH");
        // ensure pair exist
        _getTokensFromPair(path[0]);
        _safeTransferFrom(token, msg.sender, path[0], amountIn);
        amounts = _swap(token, amountIn, path, to);
        require(amounts[path.length] >= amountOutMin, "OneSwapRouter: INSUFFICIENT_OUTPUT_AMOUNT");
    }

    function limitOrder(bool isBuy, address pair, uint prevKey, uint price, uint32 id,
        uint stockAmount, uint deadline) external payable override ensure(deadline) {

        (address stock, address money) = _getTokensFromPair(pair);
        {
            (uint _stockAmount, uint _moneyAmount) = IOneSwapPair(pair).calcStockAndMoney(uint64(stockAmount), uint32(price));
            if (isBuy) {
                if (money != address(0)) { require(msg.value == 0, 'OneSwapRouter: NOT_ENTER_ETH_VALUE'); }
                _safeTransferFrom(money, msg.sender, pair, _moneyAmount);
            } else {
                if (stock != address(0)) { require(msg.value == 0, 'OneSwapRouter: NOT_ENTER_ETH_VALUE'); }
                _safeTransferFrom(stock, msg.sender, pair, _stockAmount);
            }
        }
        IOneSwapPair(pair).addLimitOrder(isBuy, msg.sender, uint64(stockAmount), uint32(price), id, uint72(prevKey));
    }

    // todo. add encoded bytes interface for limitOrder.

    function _safeTransferFrom(address token, address from, address to, uint value) internal {
        if (token == address(0)) {
            _safeTransferETH(to, value);
            uint inputValue = msg.value;
            if (inputValue > value) { _safeTransferETH(msg.sender, inputValue - value); }
            return;
        }

        uint beforeAmount = IERC20(token).balanceOf(to);
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "OneSwapRouter: TRANSFER_FROM_FAILED");
        uint afterAmount = IERC20(token).balanceOf(to);
        require(afterAmount == beforeAmount + value, "OneSwapRouter: TRANSFER_FAILED");
    }

    function _safeTransferETH(address to, uint value) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }

    function _quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, "OneSwapRouter: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "OneSwapRouter: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function _getTokensFromPair(address pair) internal view returns(address stock, address money) {
        (stock, money) = IOneSwapFactory(factory).getTokensFromPair(pair);
        require(stock != address(0) || money != address(0), "OneSwapRouter: PAIR_NOT_EXIST");
    }
}