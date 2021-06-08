/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// File: localhost/mint/openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: localhost/mint/openzeppelin/contracts/access/Ownable.sol

 

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    //constructor () internal {
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: localhost/mint/openzeppelin/contracts/math/SafeMath.sol

 

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: localhost/mint/tripartitePlatform/test/AssetPriceTest.sol

 

pragma solidity 0.7.4;


contract AssetPriceTest {
    
    using SafeMath for uint256;

    mapping(address => bool) public exists;
    mapping(address => uint256) public prices;
    mapping(address => uint8) public decimals;
    
    function getPrice(address pair, uint8 decimal) external view returns (uint256) {
        require(exists[pair], "publics:price_not_set");
        uint256 price = prices[pair];
        uint256 _decimal = decimals[pair];
        if (decimal < _decimal) {
            return price.div(10 ** uint256(_decimal - decimal));
        }else if (_decimal < decimal){
            return price.mul(10 ** uint256(decimal - _decimal));
        }else {
            return price;
        }
    }

    function setPrice(address pair, uint256 price, uint8 decimal) external {
        exists[pair] = true;
        prices[pair] = price;
        decimals[pair] = decimal;
    }
}
// File: localhost/mint/tripartitePlatform/chainlink/AggregatorV3Interface.sol

 

pragma solidity 0.7.4;

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
// File: localhost/mint/interface/IAssetPrice.sol

 

pragma solidity 0.7.4;

/**
资产价格
 */
interface IAssetPrice {
    
    /**
    查询资产价格
    
    tokenQuote:报价资产合约地址
    tokenBase:计价资产合约地址
    price:报价
    decimal:精度
     */
    function getPrice(address tokenQuote, address tokenBase) external view returns (uint256, uint8);

    /**
    查询资产对USD价格
    
    token:报价资产合约地址
    price:报价
    decimal:精度
     */
    function getPriceUSD(address token) external view returns (uint256, uint8);

    /**
    查询价格精度
    tokenQuote:报价资产合约地址
    tokenBase:计价资产合约地址
     */
    function decimal(address tokenQuote, address tokenBase) external view returns (uint8);

}
// File: localhost/mint/implement/AssetPrice.sol

 

pragma solidity 0.7.4;





contract AssetPrice is IAssetPrice, Ownable {
    
    using SafeMath for uint256;

    /**
    修改价格数据源

    tokenQuote:报价资产合约地址
    tokenBase:计价资产合约地址
    template:
    oracle:预言机合约地址
    ratio:价格占比权重，A/(A+B+C+D)
    decimal:精度
     */
    event UpdateOracleSource(address indexed tokenQuote, address indexed tokenBase, uint8 template, address indexed oracle, uint8 ratio, uint8 decimal);

    struct OracleSource {
        uint8 template;//ChainLink:0
        address oracle;//预言机合约地址
        uint8 ratio;//价格占比权重，A/(A+B+C+D)
    }

    address public constant USD = address(1);
    // address public constant EUR = address(2);
    // address public constant CNY = address(3);    
    mapping(address => mapping(address => uint8)) public decimals;
    mapping(address => mapping(address => mapping(address => bool))) public oracleSourcesV1;
    mapping(address => mapping(address => OracleSource[])) public oracleSourcesV2;
    
    /**
    查询资产价格
    
    tokenQuote:报价资产合约地址
    tokenBase:计价资产合约地址
    price:报价
    decimal:精度
     */
    function getPrice(address tokenQuote, address tokenBase) override external view returns (uint256, uint8) {
        return _getPrice(tokenQuote, tokenBase);
    }
    
    /**
    查询资产对USD价格
    
    token:报价资产合约地址
    price:报价
    decimal:精度
     */
    function getPriceUSD(address token) override external view returns (uint256, uint8) {
        return _getPrice(token, USD);
    }
    
    function decimal(address tokenQuote, address tokenBase) override external view returns (uint8) {
        return decimals[tokenQuote][tokenBase];
    }

    /**
    修改价格数据源

    tokenQuote:报价资产合约地址
    tokenBase:计价资产合约地址
    template:模板
    oracle:预言机合约地址
    ratio:价格占比权重，A/(A+B+C+D)
     */
    function updateOracleSource(address tokenQuote, address tokenBase, uint8 template, address oracle, uint8 ratio, uint8 _decimal) external onlyOwner {
        decimals[tokenQuote][tokenBase] = _decimal;
        OracleSource[] storage oracleSources = oracleSourcesV2[tokenQuote][tokenBase];
        uint256 count = oracleSources.length;            
        if (oracleSourcesV1[tokenQuote][tokenBase][oracle] && 0 < count) {
            if (0 == ratio) {
                OracleSource storage oracleSource = oracleSources[count.sub(1)];
                for (uint256 i = 0; i < count; i++) {
                    if (oracleSources[i].oracle == oracle) {
                        oracleSources[i] = oracleSource;
                        break;
                    }
                }
                oracleSources.pop();
                oracleSourcesV1[tokenQuote][tokenBase][oracle] = false;
            }else {
                for (uint256 i = 0; i < count; i++) {
                    if (oracleSources[i].oracle == oracle) {                        
                        oracleSources[i].template = template;
                        oracleSources[i].ratio = ratio;
                        break;
                    }
                }
            }
            emit UpdateOracleSource(tokenQuote, tokenBase, template, oracle, ratio, _decimal);
        }else {
            if (0 < ratio) {
                oracleSources.push(OracleSource({ template: template, oracle: oracle, ratio: ratio }));
                oracleSourcesV1[tokenQuote][tokenBase][oracle] = true;
                emit UpdateOracleSource(tokenQuote, tokenBase, template, oracle, ratio, _decimal);
            }
        }
    }

    function _getPrice(address tokenQuote, address tokenBase) internal view returns (uint256, uint8) {
        uint256 price;
        uint256 ratio;
        uint256 errorCount;
        uint8 _decimal = decimals[tokenQuote][tokenBase];
        OracleSource[] memory oracleSources = oracleSourcesV2[tokenQuote][tokenBase];
        uint256 count = oracleSources.length;
        uint256[] memory ratios = new uint256[](count);
        uint256[] memory prices = new uint256[](count);
        OracleSource memory oracleSource;
        for (uint256 i = 0; i < count; i++) {
            oracleSource = oracleSources[i];
            ratios[i] = oracleSource.ratio;
            if (0 < oracleSource.ratio) {
                if (0 == oracleSource.template) {
                    prices[i] = getPriceLink(oracleSource.oracle, _decimal);
                    ratio = ratio.add(oracleSource.ratio);
                }else if (100 == oracleSource.template) {
                    prices[i] = AssetPriceTest(0x37929b9A9D8F2a6dff6021D13622A1c372EB9E0c).getPrice(oracleSource.oracle, _decimal);
                    ratio = ratio.add(oracleSource.ratio);
                }else {
                    errorCount++;
                }
            }else {
                prices[i] = 0;
                errorCount++;
            }
        }
        require((0 < ratio) && (errorCount < count), "publics:invalid_price");
        for (uint256 i = 0; i < count; i++) {
            price = price.add(prices[i].mul(ratios[i]).div(ratio));
        }
        return (price, _decimal);
    }
    
    function getPriceLink(address pair, uint8 _decimal) internal view returns (uint256) {
        AggregatorV3Interface oracle = AggregatorV3Interface(pair);
        uint8 _decimals = oracle.decimals();
        (, int256 answer,,,) = oracle.latestRoundData();
        if (_decimal < _decimals) {
            return uint256(answer).div(10 ** uint256(_decimals - _decimal));
        }else if (_decimals < _decimal){
            return uint256(answer).mul(10 ** uint256(_decimal - _decimals));
        }else {
            return uint256(answer);
        }
    }

}