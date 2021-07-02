// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import '../interfaces/IBaseOracle.sol';

interface IStake {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract ICHIOracleAggregator is Ownable {
    using SafeMath for uint256;

    mapping(address => mapping(uint => IBaseOracle)) public oracles; // Mapping from token to (mapping from index to oracle source)
    mapping(address => uint) public oracleCount; // Mapping from token to number of sources
    mapping(address => uint) public maxPriceDeviations; // Mapping from token to max price deviation max 1000 where 1000 = 10%
    mapping(address => mapping(uint => address)) public pairs; //mapping of Liquidity pairs
    mapping(address => mapping(uint => address)) public chainlinks; //mapping of chainlink oracles for USD pricing

    uint public constant MIN_PRICE_DEVIATION = 1; // min price deviation
    uint public constant MAX_PRICE_DEVIATION = 1e4; // max price deviation

    address public ICHI = 0x903bEF1736CDdf2A537176cf3C64579C3867A881;
    address public xICHI = 0x70605a6457B0A8fBf1EEE896911895296eAB467E;

    /// @notice Set oracle primary sources for the token
    /// @param token Token address to set oracle sources
    /// @param maxPriceDeviation Max price deviation (in 1e9) for token
    /// @param oracles_ Oracle sources for the token
    /// @param pairs_ The Liquidty Pairs
    /// @param chainlinks_ Chainlink oracles to get USD price
    function setOracles(
        address token,
        uint maxPriceDeviation,
        IBaseOracle[] memory oracles_,
        address[] memory pairs_,
        address[] memory chainlinks_
    ) external onlyOwner {
        oracleCount[token] = oracles_.length;
        require(
        maxPriceDeviation >= MIN_PRICE_DEVIATION && maxPriceDeviation <= MAX_PRICE_DEVIATION,
        'bad max deviation value'
        );
        require(oracles_.length <= 3, 'oracles length exceed 3');
        maxPriceDeviations[token] = maxPriceDeviation;
        for (uint idx = 0; idx < oracles_.length; idx++) {
            require(
                token == IBaseOracle(oracles_[idx]).getBaseToken(),
                'oracle must support token'
            );
            oracles[token][idx] = oracles_[idx];
            pairs[token][idx] = pairs_[idx];
            chainlinks[token][idx] = chainlinks_[idx];
        }
    }

    /// @notice Returs ICHI price based on oracles set min 1 oracle max 3 oracles required
    function ICHIPrice() public view returns(uint price) {
        uint count = oracleCount[ICHI];
        require(count > 0, ' no oracles set');
        uint[] memory prices = new uint[](count);

        for (uint idx = 0; idx < count; idx++) {
            try oracles[ICHI][idx].getICHIPrice(pairs[ICHI][idx],chainlinks[ICHI][idx]) returns (uint px) {
                prices[idx] = normalizedToTokens(ICHI,oracles[ICHI][idx].decimals(),px);
            } catch {}
        }

        for (uint i = 0; i < count - 1; i++) {
            for (uint j = 0; j < count - i - 1; j++) {
                if (prices[j] > prices[j + 1]) {
                    (prices[j], prices[j + 1]) = (prices[j + 1], prices[j]);
                }
            }
        }

        uint maxPriceDeviation = maxPriceDeviations[ICHI];

        if (count == 1) {
            price = prices[0];
        } else if (count == 2) {
            uint diff;
            if (prices[0] == prices[1]) {
                diff = 0;
            } else if (prices[0] > prices[1]) {
                diff = prices[0].mul(1e4).div(prices[1]).sub(1e4);
            } else {
                diff = prices[1].mul(1e4).div(prices[0]).sub(1e4);
            }
            require(
                diff <= maxPriceDeviation,
                'too much deviation (2 valid sources)'
            );
            price = prices[0].add(prices[1]) / 2;
        } else if (count == 3) {
            bool midMinOk = prices[1].mul(1e4).div(prices[0]).sub(1e4) <= maxPriceDeviation;
            bool maxMidOk = prices[2].mul(1e4).div(prices[1]).sub(1e4) <= maxPriceDeviation;
            if (midMinOk && maxMidOk) {
                price =  prices[1]; // if 3 valid sources, and each pair is within thresh, return median
            } else if (midMinOk) {
                price = prices[0].add(prices[1]) / 2; // return average of pair within thresh
            } else if (maxMidOk) {
                price =  prices[1].add(prices[2]) / 2; // return average of pair within thresh
            } else {
                revert('too much deviation (3 valid sources)');
            }
        } else {
            revert('more than 3 valid oracles not supported');
        }
    }

    /// @notice xICHIPrice() returns the price of ICHI * ratio of xichi/ichi
    function xICHIPrice() public view returns(uint price) {
        IStake stake = IStake(xICHI);
        IERC20 ichiToken = IERC20(ICHI);

        uint256 xICHI_totalICHI = ichiToken.balanceOf(address(stake));
        uint256 xICHI_total = stake.totalSupply();
        price = xICHI_totalICHI.mul(ICHIPrice()).div(xICHI_total);
    }

    /**
     @notice converts normalized precision 18 amounts to token native precision amounts, truncates low-order values
     @param token ERC20 token contract
     @param amountNormal quantity in precision-18
     @param amountTokens quantity scaled to token decimals()
     */    
    function normalizedToTokens(address token, uint256 decimals, uint256 amountNormal) private view returns(uint256 amountTokens) {
        IERC20 t = IERC20(token);
        uint256 nativeDecimals = t.decimals();

        if(nativeDecimals == decimals) return amountNormal;
        return amountNormal / ( 10 ** (decimals - nativeDecimals));
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IBaseOracle {
  
  function getICHIPrice(address pair_, address chainlink_) external view returns (uint256);
  function getBaseToken() external view returns (address);
  function decimals() external view returns (uint256);
}

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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}