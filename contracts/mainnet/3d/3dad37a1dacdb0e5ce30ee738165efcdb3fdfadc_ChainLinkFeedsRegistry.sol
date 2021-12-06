// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "@chainlink/contracts/src/v0.7/interfaces/AggregatorInterface.sol";
import "@chainlink/contracts/src/v0.7/Denominations.sol";

import "../interfaces/yang/IChainLinkFeedsRegistry.sol";
import "../libraries/BinaryExp.sol";

contract ChainLinkFeedsRegistry is IChainLinkFeedsRegistry {
    using SafeMath for uint256;
    using SafeMath for uint256;

    mapping(address => Registry) public assets2USD;
    mapping(address => Registry) public assets2ETH;

    address public nextgov;
    address public governance;
    address public immutable USD;
    address public immutable WETH;

    modifier onlyGov() {
        require(msg.sender == governance, "gov");
        _;
    }

    function transferGovernance(address _nextgov) external onlyGov {
        nextgov = _nextgov;
    }

    function acceptGovrnance() external {
        require(msg.sender == nextgov, "nextgov");
        governance = nextgov;
        nextgov = address(0);
    }

    constructor(
        address _governance,
        address _weth,
        InputInitParam[] memory params
    ) {
        governance = _governance;
        WETH = _weth;
        USD = Denominations.USD;
        for (uint256 i = 0; i < params.length; i++) {
            if (params[i].isUSD) {
                assets2USD[params[i].asset] = Registry({
                    index: params[i].registry,
                    decimals: params[i].decimals
                });
            } else {
                assets2ETH[params[i].asset] = Registry({
                    index: params[i].registry,
                    decimals: params[i].decimals
                });
            }
        }
    }

    // VIEW
    // All USD registry decimals is 8, all ETH registry decimals is 18

    // Return 1e8
    function getUSDPrice(address asset)
        external
        view
        override
        returns (uint256)
    {
        uint256 price = 0;
        if (assets2USD[asset].index != address(0)) {
            price = uint256(
                AggregatorInterface(assets2USD[asset].index).latestAnswer()
            );
        } else if (
            assets2ETH[asset].index != address(0) &&
            assets2USD[WETH].index != address(0)
        ) {
            uint256 tokenETHPrice = uint256(
                AggregatorInterface(assets2ETH[asset].index).latestAnswer()
            );
            uint256 ethUSDPrice = uint256(
                AggregatorInterface(assets2USD[WETH].index).latestAnswer()
            );
            price = tokenETHPrice.mul(ethUSDPrice).div(
                BinaryExp.pow(10, assets2ETH[asset].decimals)
            );
        }
        return price;
    }

    // Returns 1e18
    function getETHPrice(address asset)
        external
        view
        override
        returns (uint256)
    {
        uint256 price = 0;
        if (assets2ETH[asset].index != address(0)) {
            price = uint256(
                AggregatorInterface(assets2ETH[asset].index).latestAnswer()
            );
        }
        return price;
    }

    function addUSDFeed(
        address asset,
        address index,
        uint256 decimals
    ) external override onlyGov {
        assets2USD[asset] = Registry({index: index, decimals: decimals});
    }

    function addETHFeed(
        address asset,
        address index,
        uint256 decimals
    ) external override onlyGov {
        assets2ETH[asset] = Registry({index: index, decimals: decimals});
    }

    function removeUSDFeed(address asset) external override onlyGov {
        delete assets2USD[asset];
    }

    function removeETHFeed(address asset) external override onlyGov {
        delete assets2ETH[asset];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
pragma solidity ^0.7.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

library Denominations {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
  address public constant USD = address(840);
  address public constant GBP = address(826);
  address public constant EUR = address(978);
  address public constant JPY = address(392);
  address public constant KRW = address(410);
  address public constant CNY = address(156);
  address public constant AUD = address(36);
  address public constant CAD = address(124);
  address public constant CHF = address(756);
  address public constant ARS = address(32);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

interface IChainLinkFeedsRegistry {
    struct Registry {
        address index;
        uint256 decimals;
    }

    struct InputInitParam {
        address asset;
        bool isUSD;
        address registry;
        uint256 decimals;
    }

    function getUSDPrice(address asset) external view returns (uint256);

    function getETHPrice(address asset) external view returns (uint256);

    function addUSDFeed(
        address asset,
        address index,
        uint256 decimals
    ) external;

    function addETHFeed(
        address asset,
        address index,
        uint256 decimals
    ) external;

    function removeUSDFeed(address asset) external;

    function removeETHFeed(address asset) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

library BinaryExp {
    using SafeMath for uint256;

    function pow(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            return 1;
        } else if (b == 1) {
            return a;
        } else {
            uint256 ret = 1;
            for (; b > 0; ) {
                if (b.mod(2) == 1) {
                    ret = ret.mul(a);
                }
                a = a.mul(a);
                b = b.div(2);
            }
            return ret;
        }
    }
}