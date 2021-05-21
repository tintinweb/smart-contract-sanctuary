// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


interface ICirculatingMarketCapOracle {
  function getCirculatingMarketCap(address) external view returns (uint256);

  function getCirculatingMarketCaps(address[] calldata) external view returns (uint256[] memory);

  function updateCirculatingMarketCaps(address[] calldata) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;


interface IScoringStrategy {
  function getTokenScores(address[] calldata tokens) external view returns (uint256[] memory scores);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

/* ========== External Interfaces ========== */
import "@openzeppelin/contracts/access/Ownable.sol";

/* ========== External Libraries ========== */
import "@openzeppelin/contracts/math/SafeMath.sol";

/* ========== Internal Interfaces ========== */
import "../interfaces/IScoringStrategy.sol";
import "../interfaces/ICirculatingMarketCapOracle.sol";


contract ScoreByCMCPegged20 is Ownable, IScoringStrategy {
  using SafeMath for uint256;

  // Chainlink or other circulating market cap oracle
  address public circulatingMarketCapOracle;

  constructor(address circulatingMarketCapOracle_) public Ownable() {
    circulatingMarketCapOracle = circulatingMarketCapOracle_;
  }

  function getTokenScores(address[] calldata tokens)
    external
    view
    override
    returns (uint256[] memory scores)
  {
    require(tokens.length >= 5, "Not enough tokens");
    uint256[] memory marketCaps = ICirculatingMarketCapOracle(circulatingMarketCapOracle).getCirculatingMarketCaps(tokens);
    uint256[] memory positions = sortAndReturnPositions(marketCaps);
    uint256 subscore = calculateIndexSum(marketCaps, positions);
    uint256 len = positions.length;
    scores = new uint256[](len);
    scores[positions[0]] = peggedScore(subscore);
    scores[positions[1]] = peggedScore(subscore);
    for (uint i = 2; i < 5; i++) {
      scores[positions[i]] = downscaledScore(marketCaps[i]);
    }
    for (uint256 j = 5; j < len; j++) {
      scores[positions[j]] = 0;
    }
  }

  /**
   * @dev Sort a list of market caps and return an array with the index each
   * sorted market cap occupied in the unsorted list.
   *
   * Example: [1, 2, 3] => [2, 1, 0]
   *
   * Note: This modifies the original list.
   */
  function sortAndReturnPositions(uint256[] memory marketCaps) internal pure returns(uint256[] memory positions) {
    uint256 len = marketCaps.length;
    positions = new uint256[](len);
    for (uint256 i = 0; i < len; i++) positions[i] = i;
    for (uint256 i = 0; i < len; i++) {
      uint256 marketCap = marketCaps[i];
      uint256 position = positions[i];
      uint256 j = i - 1;
      while (int(j) >= 0 && marketCaps[j] < marketCap) {
        marketCaps[j + 1] = marketCaps[j];
        positions[j+1] = positions[j];
        j--;
      }
      marketCaps[j+1] = marketCap;
      positions[j+1] = position;
    }
  }

  /**
   * @dev Update the address of the circulating market cap oracle.
   */
  function setCirculatingMarketCapOracle(address circulatingMarketCapOracle_) external onlyOwner {
    circulatingMarketCapOracle = circulatingMarketCapOracle_;
  }
  
  /**
   * @dev Returns the sum of the third, fourth and fifth highest market caps.
   * If WETH and WBTC are included, they're always going to be the top two, and we only want three others.
   * Require statement unnecessary: already included in caller function getTokenScores
   **/
  function calculateIndexSum(uint256[] memory marketCaps, uint256[] memory positions) internal pure returns(uint256 subtotal) {
    for (uint256 i = 2; i < 5; i++) {
      subtotal += marketCaps[positions[i]];
    }
  }

  /**
   * @dev Given a sum score corresponding to the total CMC of the top three non-WETH/WBTC elements (the three other
   * elements that we want to include), returns a value corresponding to 20% of said sum for pegged weights.
   **/
  function peggedScore(uint256 subscore) internal pure returns(uint256) {
    return (subscore.mul(20)).div(100e18);
  }
  
  /**
   * @dev Given a circulating market cap retrieved via oracle (a component of the result of calculateIndexSum),
   * scale the value down by 60% (the remnant after pegging WETH and WBTC to 20% each).
   **/
  function downscaledScore(uint256 oldScore) internal pure returns(uint256) {
    return (oldScore.mul(60)).div(100e18);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

{
  "metadata": {
    "useLiteralContent": false
  },
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
  }
}