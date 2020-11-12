// File: contracts/interfaces/IOneSwapFactory.sol

// SPDX-License-Identifier: MIT
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

// File: contracts/libraries/Math.sol

pragma solidity 0.6.12;

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

// File: contracts/libraries/ProxyData.sol

pragma solidity 0.6.12;

library ProxyData {
    uint public constant COUNT = 5;
    uint public constant INDEX_FACTORY = 0;
    uint public constant INDEX_MONEY_TOKEN = 1;
    uint public constant INDEX_STOCK_TOKEN = 2;
    uint public constant INDEX_ONES = 3;
    uint public constant INDEX_OTHER = 4;
    uint public constant OFFSET_PRICE_DIV = 0;
    uint public constant OFFSET_PRICE_MUL = 64;
    uint public constant OFFSET_STOCK_UNIT = 64+64;
    uint public constant OFFSET_IS_ONLY_SWAP = 64+64+64;

    function factory(uint[5] memory proxyData) internal pure returns (address) {
         return address(proxyData[INDEX_FACTORY]);
    }

    function money(uint[5] memory proxyData) internal pure returns (address) {
         return address(proxyData[INDEX_MONEY_TOKEN]);
    }

    function stock(uint[5] memory proxyData) internal pure returns (address) {
         return address(proxyData[INDEX_STOCK_TOKEN]);
    }

    function ones(uint[5] memory proxyData) internal pure returns (address) {
         return address(proxyData[INDEX_ONES]);
    }

    function priceMul(uint[5] memory proxyData) internal pure returns (uint64) {
        return uint64(proxyData[INDEX_OTHER]>>OFFSET_PRICE_MUL);
    }

    function priceDiv(uint[5] memory proxyData) internal pure returns (uint64) {
        return uint64(proxyData[INDEX_OTHER]>>OFFSET_PRICE_DIV);
    }

    function stockUnit(uint[5] memory proxyData) internal pure returns (uint64) {
        return uint64(proxyData[INDEX_OTHER]>>OFFSET_STOCK_UNIT);
    }

    function isOnlySwap(uint[5] memory proxyData) internal pure returns (bool) {
        return uint8(proxyData[INDEX_OTHER]>>OFFSET_IS_ONLY_SWAP) != 0;
    }

    function fill(uint[5] memory proxyData, uint expectedCallDataSize) internal pure {
        uint size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := calldatasize()
        }
        require(size == expectedCallDataSize, "INVALID_CALLDATASIZE");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let offset := sub(size, 160)
            calldatacopy(proxyData, offset, 160)
        }
    }
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

// File: contracts/interfaces/IOneSwapToken.sol

pragma solidity 0.6.12;


interface IOneSwapBlackList {
    event OwnerChanged(address);
    event AddedBlackLists(address[]);
    event RemovedBlackLists(address[]);

    function owner()external view returns (address);
    function newOwner()external view returns (address);
    function isBlackListed(address)external view returns (bool);

    function changeOwner(address ownerToSet) external;
    function updateOwner() external;
    function addBlackLists(address[] calldata  accounts)external;
    function removeBlackLists(address[] calldata  accounts)external;
}

interface IOneSwapToken is IERC20, IOneSwapBlackList{
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function multiTransfer(uint256[] calldata mixedAddrVal) external returns (bool);
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

// File: contracts/OneSwapPair.sol

pragma solidity 0.6.12;









abstract contract OneSwapERC20 is IOneSwapERC20 {
    using SafeMath256 for uint;

    uint internal _unusedVar0;
    uint internal _unusedVar1;
    uint internal _unusedVar2;
    uint internal _unusedVar3;
    uint internal _unusedVar4;
    uint internal _unusedVar5;
    uint internal _unusedVar6;
    uint internal _unusedVar7;
    uint internal _unusedVar8;
    uint internal _unusedVar9;
    uint internal _unlocked = 1;

    modifier lock() {
        require(_unlocked == 1, "OneSwap: LOCKED");
        _unlocked = 0;
        _;
        _unlocked = 1;
    }

    string private constant _NAME = "OneSwap-Liquidity-Share";
    uint8 private constant _DECIMALS = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    function symbol() virtual external override returns (string memory);

    function name() external view override returns (string memory) {
        return _NAME;
    }

    function decimals() external view override returns (uint8) {
        return _DECIMALS;
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
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
        if (allowance[from][msg.sender] != uint(- 1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}

// An order can be compressed into 256 bits and saved using one SSTORE instruction
// The orders form a single-linked list. The preceding order points to the following order with nextID
struct Order { //total 256 bits
    address sender; //160 bits, sender creates this order
    uint32 price; // 32-bit decimal floating point number
    uint64 amount; // 42 bits are used, the stock amount to be sold or bought
    uint32 nextID; // 22 bits are used
}

// When the match engine of orderbook runs, it uses follow context to cache data in memory
struct Context {
    // this order is a limit order
    bool isLimitOrder;
    // the new order's id, it is only used when a limit order is not fully dealt
    uint32 newOrderID;
    // for buy-order, it's remained money amount; for sell-order, it's remained stock amount
    uint remainAmount;
    // it points to the first order in the opposite order book against current order
    uint32 firstID;
    // it points to the first order in the buy-order book
    uint32 firstBuyID;
    // it points to the first order in the sell-order book
    uint32 firstSellID;
    // the amount goes into the pool, for buy-order, it's money amount; for sell-order, it's stock amount
    uint amountIntoPool;
    // the total dealt money and stock in the order book
    uint dealMoneyInBook;
    uint dealStockInBook;
    // cache these values from storage to memory
    uint reserveMoney;
    uint reserveStock;
    uint bookedMoney;
    uint bookedStock;
    // reserveMoney or reserveStock is changed
    bool reserveChanged;
    // the taker has dealt in the orderbook
    bool hasDealtInOrderBook;
    // the current taker order
    Order order;
    // the following data come from proxy
    uint64 stockUnit;
    uint64 priceMul;
    uint64 priceDiv;
    address stockToken;
    address moneyToken;
    address ones;
    address factory;
}

// OneSwapPair combines a Uniswap-like AMM and an orderbook
abstract contract OneSwapPool is OneSwapERC20, IOneSwapPool {
    using SafeMath256 for uint;

    uint private constant _MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 internal constant _SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    // reserveMoney and reserveStock are both uint112, id is 22 bits; they are compressed into a uint256 word
    uint internal _reserveStockAndMoneyAndFirstSellID;
    // bookedMoney and bookedStock are both uint112, id is 22 bits; they are compressed into a uint256 word
    uint internal _bookedStockAndMoneyAndFirstBuyID;

    uint private _kLast;

    uint32 private constant _OS = 2; // owner's share
    uint32 private constant _LS = 3; // liquidity-provider's share

    function internalStatus() external override view returns(uint[3] memory res) {
        res[0] = _reserveStockAndMoneyAndFirstSellID;
        res[1] = _bookedStockAndMoneyAndFirstBuyID;
        res[2] = _kLast;
    }

    function stock() external override returns (address) {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+0));
        return ProxyData.stock(proxyData);
    }

    function money() external override returns (address) {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+0));
        return ProxyData.money(proxyData);
    }

    // the following 4 functions load&store compressed storage
    function getReserves() public override view returns (uint112 reserveStock, uint112 reserveMoney, uint32 firstSellID) {
        uint temp = _reserveStockAndMoneyAndFirstSellID;
        reserveStock = uint112(temp);
        reserveMoney = uint112(temp>>112);
        firstSellID = uint32(temp>>224);
    }
    function _setReserves(uint stockAmount, uint moneyAmount, uint32 firstSellID) internal {
        require(stockAmount < uint(1<<112) && moneyAmount < uint(1<<112), "OneSwap: OVERFLOW");
        uint temp = (moneyAmount<<112)|stockAmount;
        emit Sync(temp);
        temp = (uint(firstSellID)<<224)| temp;
        _reserveStockAndMoneyAndFirstSellID = temp;
    }
    function getBooked() public override view returns (uint112 bookedStock, uint112 bookedMoney, uint32 firstBuyID) {
        uint temp = _bookedStockAndMoneyAndFirstBuyID;
        bookedStock = uint112(temp);
        bookedMoney = uint112(temp>>112);
        firstBuyID = uint32(temp>>224);
    }
    function _setBooked(uint stockAmount, uint moneyAmount, uint32 firstBuyID) internal {
        require(stockAmount < uint(1<<112) && moneyAmount < uint(1<<112), "OneSwap: OVERFLOW");
        _bookedStockAndMoneyAndFirstBuyID = (uint(firstBuyID)<<224)|(moneyAmount<<112)|stockAmount;
    }

    function _myBalance(address token) internal view returns (uint) {
        if(token==address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    // safely transfer ERC20 tokens, or ETH (when token==0)
    function _safeTransfer(address token, address to, uint value, address ones) internal {
        if(token==address(0)) {
            // limit gas to 9000 to prevent gastoken attacks
            // solhint-disable-next-line avoid-low-level-calls 
            to.call{value: value, gas: 9000}(new bytes(0)); //we ignore its return value purposely
            return;
        }
        // solhint-disable-next-line avoid-low-level-calls 
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(_SELECTOR, to, value));
        success = success && (data.length == 0 || abi.decode(data, (bool)));
        if(!success) { // for failsafe
            address onesOwner = IOneSwapToken(ones).owner();
            // solhint-disable-next-line avoid-low-level-calls 
            (success, data) = token.call(abi.encodeWithSelector(_SELECTOR, onesOwner, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), "OneSwap: TRANSFER_FAILED");
        }
    }

    // Give feeTo some liquidity tokens if K got increased since last liquidity-changing
    function _mintFee(uint112 _reserve0, uint112 _reserve1, uint[5] memory proxyData) private returns (bool feeOn) {
        address feeTo = IOneSwapFactory(ProxyData.factory(proxyData)).feeTo();
        feeOn = feeTo != address(0);
        uint kLast = _kLast;
        // gas savings to use cached kLast
        if (feeOn) {
            if (kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast)).mul(_OS);
                    uint denominator = rootK.mul(_LS).add(rootKLast.mul(_OS));
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (kLast != 0) {
            _kLast = 0;
        }
    }

    // mint new liquidity tokens to 'to'
    function mint(address to) external override lock returns (uint liquidity) {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+1));
        (uint112 reserveStock, uint112 reserveMoney, uint32 firstSellID) = getReserves();
        (uint112 bookedStock, uint112 bookedMoney, ) = getBooked();
        uint stockBalance = _myBalance(ProxyData.stock(proxyData));
        uint moneyBalance = _myBalance(ProxyData.money(proxyData));
        require(stockBalance >= uint(bookedStock) + uint(reserveStock) &&
                moneyBalance >= uint(bookedMoney) + uint(reserveMoney), "OneSwap: INVALID_BALANCE");
        stockBalance -= uint(bookedStock);
        moneyBalance -= uint(bookedMoney);
        uint stockAmount = stockBalance - uint(reserveStock);
        uint moneyAmount = moneyBalance - uint(reserveMoney);

        bool feeOn = _mintFee(reserveStock, reserveMoney, proxyData);
        uint _totalSupply = totalSupply;
        // gas savings by caching totalSupply in memory,
        // must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(stockAmount.mul(moneyAmount)).sub(_MINIMUM_LIQUIDITY);
            _mint(address(0), _MINIMUM_LIQUIDITY);
            // permanently lock the first _MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(stockAmount.mul(_totalSupply) / uint(reserveStock),
                                 moneyAmount.mul(_totalSupply) / uint(reserveMoney));
        }
        require(liquidity > 0, "OneSwap: INSUFFICIENT_MINTED");
        _mint(to, liquidity);

        _setReserves(stockBalance, moneyBalance, firstSellID);
        if (feeOn) _kLast = stockBalance.mul(moneyBalance);
        emit Mint(msg.sender, (moneyAmount<<112)|stockAmount, to);
    }

    // burn liquidity tokens and send stock&money to 'to'
    function burn(address to) external override lock returns (uint stockAmount, uint moneyAmount) {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+1));
        (uint112 reserveStock, uint112 reserveMoney, uint32 firstSellID) = getReserves();
        (uint bookedStock, uint bookedMoney, ) = getBooked();
        uint stockBalance = _myBalance(ProxyData.stock(proxyData)).sub(bookedStock);
        uint moneyBalance = _myBalance(ProxyData.money(proxyData)).sub(bookedMoney);
        require(stockBalance >= uint(reserveStock) && moneyBalance >= uint(reserveMoney), "OneSwap: INVALID_BALANCE");

        bool feeOn = _mintFee(reserveStock, reserveMoney, proxyData);
        {
            uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
            uint liquidity = balanceOf[address(this)]; // we're sure liquidity < totalSupply
            stockAmount = liquidity.mul(stockBalance) / _totalSupply;
            moneyAmount = liquidity.mul(moneyBalance) / _totalSupply;
            require(stockAmount > 0 && moneyAmount > 0, "OneSwap: INSUFFICIENT_BURNED");

            //_burn(address(this), liquidity);
            balanceOf[address(this)] = 0;
            totalSupply = totalSupply.sub(liquidity);
            emit Transfer(address(this), address(0), liquidity);
        }

        address ones = ProxyData.ones(proxyData);
        _safeTransfer(ProxyData.stock(proxyData), to, stockAmount, ones);
        _safeTransfer(ProxyData.money(proxyData), to, moneyAmount, ones);

        stockBalance = stockBalance - stockAmount;
        moneyBalance = moneyBalance - moneyAmount;

        _setReserves(stockBalance, moneyBalance, firstSellID);
        if (feeOn) _kLast = stockBalance.mul(moneyBalance);
        emit Burn(msg.sender, (moneyAmount<<112)|stockAmount, to);
    }

    // take the extra money&stock in this pair to 'to'
    function skim(address to) external override lock {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+1));
        address stockToken = ProxyData.stock(proxyData);
        address moneyToken = ProxyData.money(proxyData);
        (uint112 reserveStock, uint112 reserveMoney, ) = getReserves();
        (uint bookedStock, uint bookedMoney, ) = getBooked();
        uint balanceStock = _myBalance(stockToken);
        uint balanceMoney = _myBalance(moneyToken);
        require(balanceStock >= uint(bookedStock) + uint(reserveStock) &&
                balanceMoney >= uint(bookedMoney) + uint(reserveMoney), "OneSwap: INVALID_BALANCE");
        address ones = ProxyData.ones(proxyData);
        _safeTransfer(stockToken, to, balanceStock-reserveStock-bookedStock, ones);
        _safeTransfer(moneyToken, to, balanceMoney-reserveMoney-bookedMoney, ones);
    }

    // sync-up reserve stock&money in pool according to real balance
    function sync() external override lock {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+0));
        (, , uint32 firstSellID) = getReserves();
        (uint bookedStock, uint bookedMoney, ) = getBooked();
        uint balanceStock = _myBalance(ProxyData.stock(proxyData));
        uint balanceMoney = _myBalance(ProxyData.money(proxyData));
        require(balanceStock >= bookedStock && balanceMoney >= bookedMoney, "OneSwap: INVALID_BALANCE");
        _setReserves(balanceStock-bookedStock, balanceMoney-bookedMoney, firstSellID);
    }

}

contract OneSwapPair is OneSwapPool, IOneSwapPair {
    // the orderbooks. Gas is saved when using array to store them instead of mapping
    uint[1<<22] private _sellOrders;
    uint[1<<22] private _buyOrders;

    uint32 private constant _MAX_ID = (1<<22)-1; // the maximum value of an order ID

    function _expandPrice(uint32 price32, uint[5] memory proxyData) private pure returns (RatPrice memory price) {
        price = DecFloat32.expandPrice(price32);
        price.numerator *= ProxyData.priceMul(proxyData);
        price.denominator *= ProxyData.priceDiv(proxyData);
    }

    function _expandPrice(Context memory ctx, uint32 price32) private pure returns (RatPrice memory price) {
        price = DecFloat32.expandPrice(price32);
        price.numerator *= ctx.priceMul;
        price.denominator *= ctx.priceDiv;
    }

    function symbol() external override returns (string memory) {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+0));
        string memory s = IERC20(ProxyData.stock(proxyData)).symbol();
        string memory m = IERC20(ProxyData.money(proxyData)).symbol();
        return string(abi.encodePacked(s, "/", m, "-Share"));  //to concat strings
    }

    // when emitting events, solidity's ABI pads each entry to uint256, which is so wasteful
    // we compress the entries into one uint256 to save gas
    function _emitNewLimitOrder(
        uint64 addressLow, /*255~192*/
        uint64 totalStockAmount, /*191~128*/
        uint64 remainedStockAmount, /*127~64*/
        uint32 price, /*63~32*/
        uint32 orderID, /*31~8*/
        bool isBuy /*7~0*/) private {
        uint data = uint(addressLow);
        data = (data<<64) | uint(totalStockAmount);
        data = (data<<64) | uint(remainedStockAmount);
        data = (data<<32) | uint(price);
        data = (data<<32) | uint(orderID<<8);
        if(isBuy) {
            data = data | 1;
        }
        emit NewLimitOrder(data);
    }
    function _emitNewMarketOrder(
        uint136 addressLow, /*255~120*/
        uint112 amount, /*119~8*/
        bool isBuy /*7~0*/) private {
        uint data = uint(addressLow);
        data = (data<<112) | uint(amount);
        data = data<<8;
        if(isBuy) {
            data = data | 1;
        }
        emit NewMarketOrder(data);
    }
    function _emitOrderChanged(
        uint64 makerLastAmount, /*159~96*/
        uint64 makerDealAmount, /*95~32*/
        uint32 makerOrderID, /*31~8*/
        bool isBuy /*7~0*/) private {
        uint data = uint(makerLastAmount);
        data = (data<<64) | uint(makerDealAmount);
        data = (data<<32) | uint(makerOrderID<<8);
        if(isBuy) {
            data = data | 1;
        }
        emit OrderChanged(data);
    }
    function _emitDealWithPool(
        uint112 inAmount, /*131~120*/
        uint112 outAmount,/*119~8*/
        bool isBuy/*7~0*/) private {
        uint data = uint(inAmount);
        data = (data<<112) | uint(outAmount);
        data = data<<8;
        if(isBuy) {
            data = data | 1;
        }
        emit DealWithPool(data);
    }
    function _emitRemoveOrder(
        uint64 remainStockAmount, /*95~32*/
        uint32 orderID, /*31~8*/
        bool isBuy /*7~0*/) private {
        uint data = uint(remainStockAmount);
        data = (data<<32) | uint(orderID<<8);
        if(isBuy) {
            data = data | 1;
        }
        emit RemoveOrder(data);
    }

    // compress an order into a 256b integer
    function _order2uint(Order memory order) internal pure returns (uint) {
        uint n = uint(order.sender);
        n = (n<<32) | order.price;
        n = (n<<42) | order.amount;
        n = (n<<22) | order.nextID;
        return n;
    }

    // extract an order from a 256b integer
    function _uint2order(uint n) internal pure returns (Order memory) {
        Order memory order;
        order.nextID = uint32(n & ((1<<22)-1));
        n = n >> 22;
        order.amount = uint64(n & ((1<<42)-1));
        n = n >> 42;
        order.price = uint32(n & ((1<<32)-1));
        n = n >> 32;
        order.sender = address(n);
        return order;
    }

    // returns true if this order exists
    function _hasOrder(bool isBuy, uint32 id) internal view returns (bool) {
        if(isBuy) {
            return _buyOrders[id] != 0;
        } else {
            return _sellOrders[id] != 0;
        }
    }

    // load an order from storage, converting its compressed form into an Order struct
    function _getOrder(bool isBuy, uint32 id) internal view returns (Order memory order, bool findIt) {
        if(isBuy) {
            order = _uint2order(_buyOrders[id]);
            return (order, order.price != 0);
        } else {
            order = _uint2order(_sellOrders[id]);
            return (order, order.price != 0);
        }
    }

    // save an order to storage, converting it into compressed form
    function _setOrder(bool isBuy, uint32 id, Order memory order) internal {
        if(isBuy) {
            _buyOrders[id] = _order2uint(order);
        } else {
            _sellOrders[id] = _order2uint(order);
        }
    }

    // delete an order from storage
    function _deleteOrder(bool isBuy, uint32 id) internal {
        if(isBuy) {
            delete _buyOrders[id];
        } else {
            delete _sellOrders[id];
        }
    }

    function _getFirstOrderID(Context memory ctx, bool isBuy) internal pure returns (uint32) {
        if(isBuy) {
            return ctx.firstBuyID;
        }
        return ctx.firstSellID;
    }

    function _setFirstOrderID(Context memory ctx, bool isBuy, uint32 id) internal pure {
        if(isBuy) {
            ctx.firstBuyID = id;
        } else {
            ctx.firstSellID = id;
        }
    }

    function removeOrders(uint[] calldata rmList) external override lock {
        uint[5] memory proxyData;
        uint expectedCallDataSize = 4+32*(ProxyData.COUNT+2+rmList.length);
        ProxyData.fill(proxyData, expectedCallDataSize);
        for(uint i = 0; i < rmList.length; i++) {
            uint rmInfo = rmList[i];
            bool isBuy = uint8(rmInfo) != 0;
            uint32 id = uint32(rmInfo>>8);
            uint72 prevKey = uint72(rmInfo>>40);
            _removeOrder(isBuy, id, prevKey, proxyData);
        }
    }

    function removeOrder(bool isBuy, uint32 id, uint72 prevKey) external override lock {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+3));
        _removeOrder(isBuy, id, prevKey, proxyData);
    }

    function _removeOrder(bool isBuy, uint32 id, uint72 prevKey, uint[5] memory proxyData) private {
        Context memory ctx;
        (ctx.bookedStock, ctx.bookedMoney, ctx.firstBuyID) = getBooked();
        if(!isBuy) {
            (ctx.reserveStock, ctx.reserveMoney, ctx.firstSellID) = getReserves();
        }
        Order memory order = _removeOrderFromBook(ctx, isBuy, id, prevKey); // this is the removed order
        require(msg.sender == order.sender, "OneSwap: NOT_OWNER");
        uint64 stockUnit = ProxyData.stockUnit(proxyData);
        uint stockAmount = uint(order.amount)/*42bits*/ * uint(stockUnit);
        address ones = ProxyData.ones(proxyData);
        if(isBuy) {
            RatPrice memory price = _expandPrice(order.price, proxyData);
            uint moneyAmount = stockAmount * price.numerator/*54+64bits*/ / price.denominator;
            ctx.bookedMoney -= moneyAmount;
            _safeTransfer(ProxyData.money(proxyData), order.sender, moneyAmount, ones);
        } else {
            ctx.bookedStock -= stockAmount;
            _safeTransfer(ProxyData.stock(proxyData), order.sender, stockAmount, ones);
        }
        _setBooked(ctx.bookedStock, ctx.bookedMoney, ctx.firstBuyID);
    }

    // remove an order from orderbook and return it
    function _removeOrderFromBook(Context memory ctx, bool isBuy,
                                 uint32 id, uint72 prevKey) internal returns (Order memory) {
        (Order memory order, bool ok) = _getOrder(isBuy, id);
        require(ok, "OneSwap: NO_SUCH_ORDER");
        if(prevKey == 0) {
            uint32 firstID = _getFirstOrderID(ctx, isBuy);
            require(id == firstID, "OneSwap: NOT_FIRST");
            _setFirstOrderID(ctx, isBuy, order.nextID);
            if(!isBuy) {
                _setReserves(ctx.reserveStock, ctx.reserveMoney, ctx.firstSellID);
            }
        } else {
            (uint32 currID, Order memory prevOrder, bool findIt) = _getOrder3Times(isBuy, prevKey);
            require(findIt, "OneSwap: INVALID_POSITION");
            while(prevOrder.nextID != id) {
                currID = prevOrder.nextID;
                require(currID != 0, "OneSwap: REACH_END");
                (prevOrder, ) = _getOrder(isBuy, currID);
            }
            prevOrder.nextID = order.nextID;
            _setOrder(isBuy, currID, prevOrder);
        }
        _emitRemoveOrder(order.amount, id, isBuy);
        _deleteOrder(isBuy, id);
        return order;
    }

    // insert an order at the head of single-linked list
    // this function does not check price, use it carefully
    function _insertOrderAtHead(Context memory ctx, bool isBuy, Order memory order, uint32 id) private {
        order.nextID = _getFirstOrderID(ctx, isBuy);
        _setOrder(isBuy, id, order);
        _setFirstOrderID(ctx, isBuy, id);
    }

    // prevKey contains 3 orders. try to get the first existing order
    function _getOrder3Times(bool isBuy, uint72 prevKey) private view returns (
        uint32 currID, Order memory prevOrder, bool findIt) {
        currID = uint32(prevKey&_MAX_ID);
        (prevOrder, findIt) = _getOrder(isBuy, currID);
        if(!findIt) {
            currID = uint32((prevKey>>24)&_MAX_ID);
            (prevOrder, findIt) = _getOrder(isBuy, currID);
            if(!findIt) {
                currID = uint32((prevKey>>48)&_MAX_ID);
                (prevOrder, findIt) = _getOrder(isBuy, currID);
            }
        }
    }

    // Given a valid start position, find a proper position to insert order
    // prevKey contains three suggested order IDs, each takes 24 bits.
    // We try them one by one to find a valid start position
    // can not use this function to insert at head! if prevKey is all zero, it will return false
    function _insertOrderFromGivenPos(bool isBuy, Order memory order,
                                     uint32 id, uint72 prevKey) private returns (bool inserted) {
        (uint32 currID, Order memory prevOrder, bool findIt) = _getOrder3Times(isBuy, prevKey);
        if(!findIt) {
            return false;
        }
        return _insertOrder(isBuy, order, prevOrder, id, currID);
    }
    
    // Starting from the head of orderbook, find a proper position to insert order
    function _insertOrderFromHead(Context memory ctx, bool isBuy, Order memory order,
                                 uint32 id) private returns (bool inserted) {
        uint32 firstID = _getFirstOrderID(ctx, isBuy);
        bool canBeFirst = (firstID == 0);
        Order memory firstOrder;
        if(!canBeFirst) {
            (firstOrder, ) = _getOrder(isBuy, firstID);
            canBeFirst = (isBuy && (firstOrder.price < order.price)) ||
                (!isBuy && (firstOrder.price > order.price));
        }
        if(canBeFirst) {
            order.nextID = firstID;
            _setOrder(isBuy, id, order);
            _setFirstOrderID(ctx, isBuy, id);
            return true;
        }
        return _insertOrder(isBuy, order, firstOrder, id, firstID);
    }

    // starting from 'prevOrder', whose id is 'currID', find a proper position to insert order
    function _insertOrder(bool isBuy, Order memory order, Order memory prevOrder,
                         uint32 id, uint32 currID) private returns (bool inserted) {
        while(currID != 0) {
            bool canFollow = (isBuy && (order.price <= prevOrder.price)) ||
                (!isBuy && (order.price >= prevOrder.price));
            if(!canFollow) {break;} 
            Order memory nextOrder;
            if(prevOrder.nextID != 0) {
                (nextOrder, ) = _getOrder(isBuy, prevOrder.nextID);
                bool canPrecede = (isBuy && (nextOrder.price < order.price)) ||
                    (!isBuy && (nextOrder.price > order.price));
                canFollow = canFollow && canPrecede;
            }
            if(canFollow) {
                order.nextID = prevOrder.nextID;
                _setOrder(isBuy, id, order);
                prevOrder.nextID = id;
                _setOrder(isBuy, currID, prevOrder);
                return true;
            }
            currID = prevOrder.nextID;
            prevOrder = nextOrder;
        }
        return false;
    }

    // to query the first sell price, the first buy price and the price of pool
    function getPrices() external override returns (
        uint firstSellPriceNumerator,
        uint firstSellPriceDenominator,
        uint firstBuyPriceNumerator,
        uint firstBuyPriceDenominator,
        uint poolPriceNumerator,
        uint poolPriceDenominator) {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+0));
        (uint112 reserveStock, uint112 reserveMoney, uint32 firstSellID) = getReserves();
        poolPriceNumerator = uint(reserveMoney);
        poolPriceDenominator = uint(reserveStock);
        firstSellPriceNumerator = 0;
        firstSellPriceDenominator = 0;
        firstBuyPriceNumerator = 0;
        firstBuyPriceDenominator = 0;
        if(firstSellID!=0) {
            uint order = _sellOrders[firstSellID];
            RatPrice memory price = _expandPrice(uint32(order>>64), proxyData);
            firstSellPriceNumerator = price.numerator;
            firstSellPriceDenominator = price.denominator;
        }
        uint32 id = uint32(_bookedStockAndMoneyAndFirstBuyID>>224);
        if(id!=0) {
            uint order = _buyOrders[id];
            RatPrice memory price = _expandPrice(uint32(order>>64), proxyData);
            firstBuyPriceNumerator = price.numerator;
            firstBuyPriceDenominator = price.denominator;
        }
    }

    // Get the orderbook's content, starting from id, to get no more than maxCount orders
    function getOrderList(bool isBuy, uint32 id, uint32 maxCount) external override view returns (uint[] memory) {
        if(id == 0) {
            if(isBuy) {
                id = uint32(_bookedStockAndMoneyAndFirstBuyID>>224);
            } else {
                id = uint32(_reserveStockAndMoneyAndFirstSellID>>224);
            }
        }
        uint[1<<22] storage orderbook;
        if(isBuy) {
            orderbook = _buyOrders;
        } else {
            orderbook = _sellOrders;
        }
        //record block height at the first entry
        uint order = (block.number<<24) | id;
        uint addrOrig; // start of returned data
        uint addrLen; // the slice's length is written at this address
        uint addrStart; // the address of the first entry of returned slice
        uint addrEnd; // ending address to write the next order
        uint count = 0; // the slice's length
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addrOrig := mload(0x40) // There is a “free memory pointer” at address 0x40 in memory
            mstore(addrOrig, 32) //the meaningful data start after offset 32
        }
        addrLen = addrOrig + 32;
        addrStart = addrLen + 32;
        addrEnd = addrStart;
        while(count < maxCount) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(addrEnd, order) //write the order
            }
            addrEnd += 32;
            count++;
            if(id == 0) {break;}
            order = orderbook[id];
            require(order!=0, "OneSwap: INCONSISTENT_BOOK");
            id = uint32(order&_MAX_ID);
        }
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(addrLen, count) // record the returned slice's length
            let byteCount := sub(addrEnd, addrOrig)
            return(addrOrig, byteCount)
        }
    }

    // Get an unused id to be used with new order
    function _getUnusedOrderID(bool isBuy, uint32 id) internal view returns (uint32) {
        if(id == 0) { // 0 is reserved
            // solhint-disable-next-line avoid-tx-origin
            id = uint32(uint(blockhash(block.number-1))^uint(tx.origin)) & _MAX_ID; //get a pseudo random number
        }
        for(uint32 i = 0; i < 100 && id <= _MAX_ID; i++) { //try 100 times
            if(!_hasOrder(isBuy, id)) {
                return id;
            }
            id++;
        }
        require(false, "OneSwap: CANNOT_FIND_VALID_ID");
        return 0;
    }

    function calcStockAndMoney(uint64 amount, uint32 price32) external pure override returns (uint stockAmount, uint moneyAmount) {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+2));
        (stockAmount, moneyAmount, ) = _calcStockAndMoney(amount, price32, proxyData);
    }

    function _calcStockAndMoney(uint64 amount, uint32 price32, uint[5] memory proxyData) private pure returns (uint stockAmount, uint moneyAmount, RatPrice memory price) {
        price = _expandPrice(price32, proxyData);
        uint64 stockUnit = ProxyData.stockUnit(proxyData);
        stockAmount = uint(amount)/*42bits*/ * uint(stockUnit);
        moneyAmount = stockAmount * price.numerator/*54+64bits*/ /price.denominator;
    }

    function addLimitOrder(bool isBuy, address sender, uint64 amount, uint32 price32,
                           uint32 id, uint72 prevKey) external payable override lock {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+6));
        require(ProxyData.isOnlySwap(proxyData)==false, "OneSwap: LIMIT_ORDER_NOT_SUPPORTED");
        Context memory ctx;
        ctx.stockUnit = ProxyData.stockUnit(proxyData);
        ctx.ones = ProxyData.ones(proxyData);
        ctx.factory = ProxyData.factory(proxyData);
        ctx.stockToken = ProxyData.stock(proxyData);
        ctx.moneyToken = ProxyData.money(proxyData);
        ctx.priceMul = ProxyData.priceMul(proxyData);
        ctx.priceDiv = ProxyData.priceDiv(proxyData);
        ctx.hasDealtInOrderBook = false;
        ctx.isLimitOrder = true;
        ctx.order.sender = sender;
        ctx.order.amount = amount;
        ctx.order.price = price32;

        ctx.newOrderID = _getUnusedOrderID(isBuy, id);
        RatPrice memory price;
    
        {// to prevent "CompilerError: Stack too deep, try removing local variables."
            require((amount >> 42) == 0, "OneSwap: INVALID_AMOUNT");
            uint32 m = price32 & DecFloat32.MANTISSA_MASK;
            require(DecFloat32.MIN_MANTISSA <= m && m <= DecFloat32.MAX_MANTISSA, "OneSwap: INVALID_PRICE");

            uint stockAmount;
            uint moneyAmount;
            (stockAmount, moneyAmount, price) = _calcStockAndMoney(amount, price32, proxyData);
            if(isBuy) {
                ctx.remainAmount = moneyAmount;
            } else {
                ctx.remainAmount = stockAmount;
            }
        }

        require(ctx.remainAmount < uint(1<<112), "OneSwap: OVERFLOW");
        (ctx.reserveStock, ctx.reserveMoney, ctx.firstSellID) = getReserves();
        (ctx.bookedStock, ctx.bookedMoney, ctx.firstBuyID) = getBooked();
        _checkRemainAmount(ctx, isBuy);
        if(prevKey != 0) { // try to insert it
            bool inserted = _insertOrderFromGivenPos(isBuy, ctx.order, ctx.newOrderID, prevKey);
            if(inserted) { //  if inserted successfully, record the booked tokens
                _emitNewLimitOrder(uint64(ctx.order.sender), amount, amount, price32, ctx.newOrderID, isBuy);
                if(isBuy) {
                    ctx.bookedMoney += ctx.remainAmount;
                } else {
                    ctx.bookedStock += ctx.remainAmount;
                }
                _setBooked(ctx.bookedStock, ctx.bookedMoney, ctx.firstBuyID);
                if(ctx.reserveChanged) {
                    _setReserves(ctx.reserveStock, ctx.reserveMoney, ctx.firstSellID);
                }
                return;
            }
            // if insertion failed, we try to match this order and make it deal
        }
        _addOrder(ctx, isBuy, price);
    }

    function addMarketOrder(address inputToken, address sender,
                            uint112 inAmount) external payable override lock returns (uint) {
        uint[5] memory proxyData;
        ProxyData.fill(proxyData, 4+32*(ProxyData.COUNT+3));
        Context memory ctx;
        ctx.moneyToken = ProxyData.money(proxyData);
        ctx.stockToken = ProxyData.stock(proxyData);
        require(inputToken == ctx.moneyToken || inputToken == ctx.stockToken, "OneSwap: INVALID_TOKEN");
        bool isBuy = inputToken == ctx.moneyToken;
        ctx.stockUnit = ProxyData.stockUnit(proxyData);
        ctx.priceMul = ProxyData.priceMul(proxyData);
        ctx.priceDiv = ProxyData.priceDiv(proxyData);
        ctx.ones = ProxyData.ones(proxyData);
        ctx.factory = ProxyData.factory(proxyData);
        ctx.hasDealtInOrderBook = false;
        ctx.isLimitOrder = false;
        ctx.remainAmount = inAmount;
        (ctx.reserveStock, ctx.reserveMoney, ctx.firstSellID) = getReserves();
        (ctx.bookedStock, ctx.bookedMoney, ctx.firstBuyID) = getBooked();
        _checkRemainAmount(ctx, isBuy);
        ctx.order.sender = sender;
        if(isBuy) {
            ctx.order.price = DecFloat32.MAX_PRICE;
        } else {
            ctx.order.price = DecFloat32.MIN_PRICE;
        }

        RatPrice memory price; // leave it to zero, actually it will not be used;
        _emitNewMarketOrder(uint136(ctx.order.sender), inAmount, isBuy);
        return _addOrder(ctx, isBuy, price);
    }

    // Check router contract did send me enough tokens.
    // If Router sent to much tokens, take them as reserve money&stock
    function _checkRemainAmount(Context memory ctx, bool isBuy) private view {
        ctx.reserveChanged = false;
        uint diff;
        if(isBuy) {
            uint balance = _myBalance(ctx.moneyToken);
            require(balance >= ctx.bookedMoney + ctx.reserveMoney, "OneSwap: MONEY_MISMATCH");
            diff = balance - ctx.bookedMoney - ctx.reserveMoney;
            if(ctx.remainAmount < diff) {
                ctx.reserveMoney += (diff - ctx.remainAmount);
                ctx.reserveChanged = true;
            }
        } else {
            uint balance = _myBalance(ctx.stockToken);
            require(balance >= ctx.bookedStock + ctx.reserveStock, "OneSwap: STOCK_MISMATCH");
            diff = balance - ctx.bookedStock - ctx.reserveStock;
            if(ctx.remainAmount < diff) {
                ctx.reserveStock += (diff - ctx.remainAmount);
                ctx.reserveChanged = true;
            }
        }
        require(ctx.remainAmount <= diff, "OneSwap: DEPOSIT_NOT_ENOUGH");
    }

    // internal helper function to add new limit order & market order
    // returns the amount of tokens which were sent to the taker (from AMM pool and booked tokens)
    function _addOrder(Context memory ctx, bool isBuy, RatPrice memory price) private returns (uint) {
        (ctx.dealMoneyInBook, ctx.dealStockInBook) = (0, 0);
        ctx.firstID = _getFirstOrderID(ctx, !isBuy);
        uint32 currID = ctx.firstID;
        ctx.amountIntoPool = 0;
        while(currID != 0) { // while not reaching the end of single-linked 
            (Order memory orderInBook, ) = _getOrder(!isBuy, currID);
            bool canDealInOrderBook = (isBuy && (orderInBook.price <= ctx.order.price)) ||
                (!isBuy && (orderInBook.price >= ctx.order.price));
            if(!canDealInOrderBook) {break;} // no proper price in orderbook, stop here

            // Deal in liquid pool
            RatPrice memory priceInBook = _expandPrice(ctx, orderInBook.price);
            bool allDeal = _tryDealInPool(ctx, isBuy, priceInBook);
            if(allDeal) {break;}

            // Deal in orderbook
            _dealInOrderBook(ctx, isBuy, currID, orderInBook, priceInBook);

            // if the order in book did NOT fully deal, then this new order DID fully deal, so stop here
            if(orderInBook.amount != 0) {
                _setOrder(!isBuy, currID, orderInBook);
                break;
            }
            // if the order in book DID fully deal, then delete this order from storage and move to the next
            _deleteOrder(!isBuy, currID);
            currID = orderInBook.nextID;
        }
        // Deal in liquid pool
        if(ctx.isLimitOrder) {
            // use current order's price to deal with pool
            _tryDealInPool(ctx, isBuy, price);
            // If a limit order did NOT fully deal, we add it into orderbook
            // Please note a market order always fully deals
            _insertOrderToBook(ctx, isBuy, price);
        } else {
            // the AMM pool can deal with orders with any amount
            ctx.amountIntoPool += ctx.remainAmount; // both of them are less than 112 bits
            ctx.remainAmount = 0;
        }
        uint amountToTaker = _dealWithPoolAndCollectFee(ctx, isBuy);
        if(isBuy) {
            ctx.bookedStock -= ctx.dealStockInBook; //If this subtraction overflows, _setBooked will fail
        } else {
            ctx.bookedMoney -= ctx.dealMoneyInBook; //If this subtraction overflows, _setBooked will fail
        }
        if(ctx.firstID != currID) { //some orders DID fully deal, so the head of single-linked list change
            _setFirstOrderID(ctx, !isBuy, currID);
        }
        // write the cached values to storage
        _setBooked(ctx.bookedStock, ctx.bookedMoney, ctx.firstBuyID);
        _setReserves(ctx.reserveStock, ctx.reserveMoney, ctx.firstSellID);
        return amountToTaker;
    }

    // Given reserveMoney and reserveStock in AMM pool, calculate how much tokens will go into the pool if the
    // final price is 'price'
    function _intopoolAmountTillPrice(bool isBuy, uint reserveMoney, uint reserveStock,
                                     RatPrice memory price) private pure returns (uint result) {
        // sqrt(Pold/Pnew) = sqrt((2**32)*M_old*PnewDenominator / (S_old*PnewNumerator)) / (2**16)
        // sell, stock-into-pool, Pold > Pnew
        uint numerator = reserveMoney/*112bits*/ * price.denominator/*76+64bits*/;
        uint denominator = reserveStock/*112bits*/ * price.numerator/*54+64bits*/;
        if(isBuy) { // buy, money-into-pool, Pold < Pnew
            // sqrt(Pnew/Pold) = sqrt((2**32)*S_old*PnewNumerator / (M_old*PnewDenominator)) / (2**16)
            (numerator, denominator) = (denominator, numerator);
        }
        while(numerator >= (1<<192)) { // can not equal to (1<<192) !!!
            numerator >>= 16;
            denominator >>= 16;
        }
        require(denominator != 0, "OneSwapPair: DIV_BY_ZERO");
        numerator = numerator * (1<<64);
        uint quotient = numerator / denominator;
        if(quotient <= (1<<64)) {
            return 0;
        } else if(quotient <= ((1<<64)*5/4)) {
            // Taylor expansion: x/2 - x*x/8 + x*x*x/16
            uint x = quotient - (1<<64);
            uint y = x*x;
            y = x/2 - y/(8*(1<<64)) + y*x/(16*(1<<128));
            if(isBuy) {
                result = reserveMoney * y;
            } else {
                result = reserveStock * y;
            }
            result /= (1<<64);
            return result;
        }
        uint root = Math.sqrt(quotient); //root is at most 110bits
        uint diff =  root - (1<<32);  //at most 110bits
        if(isBuy) {
            result = reserveMoney * diff;
        } else {
            result = reserveStock * diff;
        }
        result /= (1<<32);
        return result;
    }

    // Current order tries to deal against the AMM pool. Returns whether current order fully deals.
    function _tryDealInPool(Context memory ctx, bool isBuy, RatPrice memory price) private pure returns (bool) {
        uint currTokenCanTrade = _intopoolAmountTillPrice(isBuy, ctx.reserveMoney, ctx.reserveStock, price);
        require(currTokenCanTrade < uint(1<<112), "OneSwap: CURR_TOKEN_TOO_LARGE");
        // all the below variables are less than 112 bits
        if(!isBuy) {
            currTokenCanTrade /= ctx.stockUnit; //to round
            currTokenCanTrade *= ctx.stockUnit;
        }
        if(currTokenCanTrade > ctx.amountIntoPool) {
            uint diffTokenCanTrade = currTokenCanTrade - ctx.amountIntoPool;
            bool allDeal = diffTokenCanTrade >= ctx.remainAmount;
            if(allDeal) {
                diffTokenCanTrade = ctx.remainAmount;
            }
            ctx.amountIntoPool += diffTokenCanTrade;
            ctx.remainAmount -= diffTokenCanTrade;
            return allDeal;
        }
        return false;
    }

    // Current order tries to deal against the orders in book
    function _dealInOrderBook(Context memory ctx, bool isBuy, uint32 currID,
                             Order memory orderInBook, RatPrice memory priceInBook) internal {
        ctx.hasDealtInOrderBook = true;
        uint stockAmount;
        if(isBuy) {
            uint a = ctx.remainAmount/*112bits*/ * priceInBook.denominator/*76+64bits*/;
            uint b = priceInBook.numerator/*54+64bits*/ * ctx.stockUnit/*64bits*/;
            stockAmount = a/b;
        } else {
            stockAmount = ctx.remainAmount/ctx.stockUnit;
        }
        if(uint(orderInBook.amount) < stockAmount) {
            stockAmount = uint(orderInBook.amount);
        }
        require(stockAmount < (1<<42), "OneSwap: STOCK_TOO_LARGE");
        uint stockTrans = stockAmount/*42bits*/ * ctx.stockUnit/*64bits*/;
        uint moneyTrans = stockTrans * priceInBook.numerator/*54+64bits*/ / priceInBook.denominator/*76+64bits*/;

        _emitOrderChanged(orderInBook.amount, uint64(stockAmount), currID, isBuy);
        orderInBook.amount -= uint64(stockAmount);
        if(isBuy) { //subtraction cannot overflow: moneyTrans and stockTrans are calculated from remainAmount
            ctx.remainAmount -= moneyTrans;
        } else {
            ctx.remainAmount -= stockTrans;
        }
        // following accumulations can not overflow, because stockTrans(moneyTrans) at most 106bits(160bits)
        // we know for sure that dealStockInBook and dealMoneyInBook are less than 192 bits
        ctx.dealStockInBook += stockTrans;
        ctx.dealMoneyInBook += moneyTrans;
        if(isBuy) {
            _safeTransfer(ctx.moneyToken, orderInBook.sender, moneyTrans, ctx.ones);
        } else {
            _safeTransfer(ctx.stockToken, orderInBook.sender, stockTrans, ctx.ones);
        }
    }

    // make real deal with the pool and then collect fee, which will be added to AMM pool
    function _dealWithPoolAndCollectFee(Context memory ctx, bool isBuy) internal returns (uint) {
        (uint outpoolTokenReserve, uint inpoolTokenReserve, uint otherToTaker) = (
              ctx.reserveMoney, ctx.reserveStock, ctx.dealMoneyInBook);
        if(isBuy) {
            (outpoolTokenReserve, inpoolTokenReserve, otherToTaker) = (
                ctx.reserveStock, ctx.reserveMoney, ctx.dealStockInBook);
        }

        // all these 4 varialbes are less than 112 bits
        // outAmount is sure to less than outpoolTokenReserve (which is ctx.reserveStock or ctx.reserveMoney)
        uint outAmount = (outpoolTokenReserve*ctx.amountIntoPool)/(inpoolTokenReserve+ctx.amountIntoPool);
        if(ctx.amountIntoPool > 0) {
            _emitDealWithPool(uint112(ctx.amountIntoPool), uint112(outAmount), isBuy);
        }
        uint32 feeBPS = IOneSwapFactory(ctx.factory).feeBPS();
        // the token amount that should go to the taker, 
        // for buy-order, it's stock amount; for sell-order, it's money amount
        uint amountToTaker = outAmount + otherToTaker;
        require(amountToTaker < uint(1<<112), "OneSwap: AMOUNT_TOO_LARGE");
        uint fee = (amountToTaker * feeBPS + 9999) / 10000;
        amountToTaker -= fee;

        if(isBuy) {
            ctx.reserveMoney = ctx.reserveMoney + ctx.amountIntoPool;
            ctx.reserveStock = ctx.reserveStock - outAmount + fee;
        } else {
            ctx.reserveMoney = ctx.reserveMoney - outAmount + fee;
            ctx.reserveStock = ctx.reserveStock + ctx.amountIntoPool;
        }

        address token = ctx.moneyToken;
        if(isBuy) {
            token = ctx.stockToken;
        }
        _safeTransfer(token, ctx.order.sender, amountToTaker, ctx.ones);
        return amountToTaker;
    }

    // Insert a not-fully-deal limit order into orderbook
    function _insertOrderToBook(Context memory ctx, bool isBuy, RatPrice memory price) internal {
        (uint smallAmount, uint moneyAmount, uint stockAmount) = (0, 0, 0);
        if(isBuy) {
            uint tempAmount1 = ctx.remainAmount /*112bits*/ * price.denominator /*76+64bits*/;
            uint temp = ctx.stockUnit * price.numerator/*54+64bits*/;
            stockAmount = tempAmount1 / temp;
            uint tempAmount2 = stockAmount * temp; // Now tempAmount1 >= tempAmount2
            moneyAmount = (tempAmount2+price.denominator-1)/price.denominator; // round up
            if(ctx.remainAmount > moneyAmount) {
                // smallAmount is the gap where remainAmount can not buy an integer of stocks
                smallAmount = ctx.remainAmount - moneyAmount;
            } else {
                moneyAmount = ctx.remainAmount;
            } //Now ctx.remainAmount >= moneyAmount
        } else {
            // for sell orders, remainAmount were always decreased by integral multiple of StockUnit
            // and we know for sure that ctx.remainAmount % StockUnit == 0
            stockAmount = ctx.remainAmount / ctx.stockUnit;
            smallAmount = ctx.remainAmount - stockAmount * ctx.stockUnit;
        }
        ctx.amountIntoPool += smallAmount; // Deal smallAmount with pool
        //ctx.reserveMoney += smallAmount; // If this addition overflows, _setReserves will fail
        _emitNewLimitOrder(uint64(ctx.order.sender), ctx.order.amount, uint64(stockAmount),
                           ctx.order.price, ctx.newOrderID, isBuy);
        if(stockAmount != 0) {
            ctx.order.amount = uint64(stockAmount);
            if(ctx.hasDealtInOrderBook) {
                // if current order has ever dealt, it has the best price and can be inserted at head
                _insertOrderAtHead(ctx, isBuy, ctx.order, ctx.newOrderID);
            } else {
                // if current order has NEVER dealt, we must find a proper position for it.
                // we may scan a lot of entries in the single-linked list and run out of gas
                _insertOrderFromHead(ctx, isBuy, ctx.order, ctx.newOrderID);
            }
        }
        // Any overflow/underflow in following calculation will be caught by _setBooked
        if(isBuy) {
            ctx.bookedMoney += moneyAmount;
        } else {
            ctx.bookedStock += (ctx.remainAmount - smallAmount);
        }
    }
}

// solhint-disable-next-line max-states-count
contract OneSwapPairProxy {
    uint internal _unusedVar0;
    uint internal _unusedVar1;
    uint internal _unusedVar2;
    uint internal _unusedVar3;
    uint internal _unusedVar4;
    uint internal _unusedVar5;
    uint internal _unusedVar6;
    uint internal _unusedVar7;
    uint internal _unusedVar8;
    uint internal _unusedVar9;
    uint internal _unlocked;

    uint internal immutable _immuFactory;
    uint internal immutable _immuMoneyToken;
    uint internal immutable _immuStockToken;
    uint internal immutable _immuOnes;
    uint internal immutable _immuOther;

    constructor(address stockToken, address moneyToken, bool isOnlySwap, uint64 stockUnit, uint64 priceMul, uint64 priceDiv, address ones) public {
        _immuFactory = uint(msg.sender);
        _immuMoneyToken = uint(moneyToken);
        _immuStockToken = uint(stockToken);
        _immuOnes = uint(ones);
        uint temp = 0;
        if(isOnlySwap) {
            temp = 1;
        }
        temp = (temp<<64) | stockUnit;
        temp = (temp<<64) | priceMul;
        temp = (temp<<64) | priceDiv;
        _immuOther = temp;
        _unlocked = 1;
    }

    receive() external payable { }
    // solhint-disable-next-line no-complex-fallback
    fallback() payable external {
        uint factory     = _immuFactory;
        uint moneyToken  = _immuMoneyToken;
        uint stockToken  = _immuStockToken;
        uint ones        = _immuOnes;
        uint other       = _immuOther;
        address impl = IOneSwapFactory(address(_immuFactory)).pairLogic();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            let size := calldatasize()
            calldatacopy(ptr, 0, size)
            let end := add(ptr, size)
            // append immutable variables to the end of calldata
            mstore(end, factory)
            end := add(end, 32)
            mstore(end, moneyToken)
            end := add(end, 32)
            mstore(end, stockToken)
            end := add(end, 32)
            mstore(end, ones)
            end := add(end, 32)
            mstore(end, other)
            size := add(size, 160)
            let result := delegatecall(gas(), impl, ptr, size, 0, 0)
            size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

// File: contracts/OneSwapFactory.sol

pragma solidity 0.6.12;



contract OneSwapFactory is IOneSwapFactory {
    struct TokensInPair {
        address stock;
        address money;
    }

    address public override feeTo;
    address public override feeToSetter;
    address public immutable gov;
    address public immutable ones;
    uint32 public override feeBPS = 50;
    address public override pairLogic;
    mapping(address => TokensInPair) private _pairWithToken;
    mapping(bytes32 => address) private _tokensToPair;
    address[] public allPairs;

    constructor(address _feeToSetter, address _gov, address _ones, address _pairLogic) public {
        feeToSetter = _feeToSetter;
        gov = _gov;
        ones = _ones;
        pairLogic = _pairLogic;
    }

    function createPair(address stock, address money, bool isOnlySwap) external override returns (address pair) {
        require(stock != money, "OneSwapFactory: IDENTICAL_ADDRESSES");
        // not necessary //require(stock != address(0) || money != address(0), "OneSwapFactory: ZERO_ADDRESS");
        uint moneyDec = _getDecimals(money);
        uint stockDec = _getDecimals(stock);
        require(23 >= stockDec && stockDec >= 0, "OneSwapFactory: STOCK_DECIMALS_NOT_SUPPORTED");
        uint dec = 0;
        if (stockDec >= 4) {
            dec = stockDec - 4; // now 19 >= dec && dec >= 0
        }
        // 10**19 = 10000000000000000000
        //  1<<64 = 18446744073709551616
        uint64 priceMul = 1;
        uint64 priceDiv = 1;
        bool differenceTooLarge = false;
        if (moneyDec > stockDec) {
            if (moneyDec > stockDec + 19) {
                differenceTooLarge = true;
            } else {
                priceMul = uint64(uint(10)**(moneyDec - stockDec));
            }
        }
        if (stockDec > moneyDec) {
            if (stockDec > moneyDec + 19) {
                differenceTooLarge = true;
            } else {
                priceDiv = uint64(uint(10)**(stockDec - moneyDec));
            }
        }
        require(!differenceTooLarge, "OneSwapFactory: DECIMALS_DIFF_TOO_LARGE");
        bytes32 salt = keccak256(abi.encodePacked(stock, money, isOnlySwap));
        require(_tokensToPair[salt] == address(0), "OneSwapFactory: PAIR_EXISTS");
        OneSwapPairProxy oneswap = new OneSwapPairProxy{salt: salt}(stock, money, isOnlySwap, uint64(uint(10)**dec), priceMul, priceDiv, ones);

        pair = address(oneswap);
        allPairs.push(pair);
        _tokensToPair[salt] = pair;
        _pairWithToken[pair] = TokensInPair(stock, money);
        emit PairCreated(pair, stock, money, isOnlySwap);
    }

    function _getDecimals(address token) private view returns (uint) {
        if (token == address(0)) { return 18; }
        return uint(IERC20(token).decimals());
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "OneSwapFactory: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "OneSwapFactory: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }

    function setPairLogic(address implLogic) external override {
        require(msg.sender == gov, "OneSwapFactory: SETTER_MISMATCH");
        pairLogic = implLogic;
    }

    function setFeeBPS(uint32 _bps) external override {
        require(msg.sender == gov, "OneSwapFactory: SETTER_MISMATCH");
        require(0 <= _bps && _bps <= 50 , "OneSwapFactory: BPS_OUT_OF_RANGE");
        feeBPS = _bps;
    }

    function getTokensFromPair(address pair) external view override returns (address stock, address money) {
        stock = _pairWithToken[pair].stock;
        money = _pairWithToken[pair].money;
    }

    function tokensToPair(address stock, address money, bool isOnlySwap) external view override returns (address pair) {
        bytes32 key = keccak256(abi.encodePacked(stock, money, isOnlySwap));
        return _tokensToPair[key];
    }
}