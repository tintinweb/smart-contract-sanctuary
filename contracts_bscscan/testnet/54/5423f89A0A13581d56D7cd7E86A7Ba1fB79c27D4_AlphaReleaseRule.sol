pragma solidity 0.6.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libraries/WadMath.sol";
import "../interfaces/IAlphaReleaseRule.sol";

/**
 * @title Alpha rule contract
 * @notice Implements the distribution of the Alpha token pool.
 * @author Alpha
 **/

contract AlphaReleaseRule is Ownable, IAlphaReleaseRule {
  using SafeMath for uint256;
  using WadMath for uint256;

  // number of block per week
  uint256 public blockPerWeek;
  // the start block of alpha distribution (week0 will start from startBlock + 1 )
  uint256 public startBlock;
  // week => number of token per block
  uint256[] public tokensPerBlock;

  constructor(
    uint256 _startBlock,
    uint256 _blockPerWeek,
    uint256[] memory _tokensPerBlock
  ) public {
    startBlock = _startBlock;
    blockPerWeek = _blockPerWeek;
    for (uint256 i = 0; i < _tokensPerBlock.length; i++) {
      tokensPerBlock.push(_tokensPerBlock[i]);
    }
  }

  /**
   * @dev set the amount of token to distribute per block of that week
   * @param _week the week to set
   * @param _amount the amount of alpha token to distribute on that week
   */
  function setTokenPerBlock(uint256 _week, uint256 _amount) external onlyOwner {
    tokensPerBlock[_week] = _amount;
  }

  /**
   * @dev get the amount of distributed token from _fromBlock + 1 to _toBlock
   * @param _fromBlock calculate from _fromBlock + 1 
   * @param _toBlock calculate to the _toBlock
   */
  function getReleaseAmount(uint256 _fromBlock, uint256 _toBlock)
    external
    override
    view
    returns (uint256)
  {
    uint256 lastBlock = startBlock.add(tokensPerBlock.length.mul(blockPerWeek));
    if (_fromBlock >= _toBlock || _toBlock <= startBlock || lastBlock <= _fromBlock) {
      return 0;
    }
    uint256 fromBlock = _fromBlock > startBlock ? _fromBlock : startBlock;
    uint256 toBlock = _toBlock < lastBlock ? _toBlock : lastBlock;
    uint256 week = findWeekByBlockNumber(fromBlock);
    uint256 nextWeekBlock = findNextWeekFirstBlock(fromBlock);
    uint256 totalAmount = 0;
    while (fromBlock < toBlock) {
      nextWeekBlock = toBlock < nextWeekBlock ? toBlock : nextWeekBlock;
      totalAmount = totalAmount.add(nextWeekBlock.sub(fromBlock).mul(tokensPerBlock[week]));
      week = week.add(1);
      fromBlock = nextWeekBlock;
      nextWeekBlock = nextWeekBlock.add(blockPerWeek);
    }
    return totalAmount;
  }

  /**
   * @dev find the week of that block (week0 starts from the startBlock + 1)
   * @param _block the block number to find week
   */
  function findWeekByBlockNumber(uint256 _block) public view returns (uint256) {
    require(_block >= startBlock, "the block number must more than or equal start block");
    return _block.sub(startBlock).div(blockPerWeek);
  }

  /**
   * @dev find the next week first block of this block.
   * |--------------------------|      |--------------------------|
   * 10                         20     21                         30
   *                       |--18
   * the next week first block of block#18 is block#20
   * @param _block the block number to find the next week first block
   */
  function findNextWeekFirstBlock(uint256 _block) public view returns (uint256) {
    require(_block >= startBlock, "the block number must more than or equal start block");
    return
      _block.sub(startBlock).div(blockPerWeek).mul(blockPerWeek).add(blockPerWeek).add(startBlock);
  }
}

pragma solidity 0.6.11;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title WadMath library
 * @notice The wad math library.
 * @author Alpha
 **/

library WadMath {
  using SafeMath for uint256;

  /**
   * @dev one WAD is equals to 10^18
   */
  uint256 internal constant WAD = 1e18;

  /**
   * @notice get wad
   */
  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /**
   * @notice a multiply by b in Wad unit
   * @return the result of multiplication
   */
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return a.mul(b).div(WAD);
  }

  /**
   * @notice a divided by b in Wad unit
   * @return the result of division
   */
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    return a.mul(WAD).div(b);
  }
}

pragma solidity 0.6.11;

/**
 * @title Alpha release rule
 * @notice The interface of Alpha release rule
 * @author Alpha
 **/

interface IAlphaReleaseRule {
  /**
   * @notice get the Alpha token release amount from _fromBlock to _toBlock
   * @param _fromBlock the start block to release Alpha token
   * @param _toBlock the end block to release Alpha token
   * @return the amount od Alpha token to release
   */
  function getReleaseAmount(uint256 _fromBlock, uint256 _toBlock) external view returns (uint256);
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