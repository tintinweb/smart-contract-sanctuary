/**
 *Submitted for verification at FtmScan.com on 2021-12-07
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;


// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/IOwnable.sol

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)


interface IOwnable {
    function owner() external view returns (address);
    
    function pushOwnership(address newOwner) external;
    
    function pullOwnership() external;
    
    function renounceOwnership() external;
    
    function transferOwnership(address newOwner) external;
}


// File @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
abstract contract Ownable is IOwnable, Context {
    address private _owner;
    address private _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual override returns (address) {
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
     * @dev Sets up a push of the ownership of the contract to the specified
     * address which must subsequently pull the ownership to accept it.
     */
    function pushOwnership(address newOwner) public virtual override onlyOwner {
        require( newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner );
        _newOwner = newOwner;
    }

    /**
     * @dev Accepts the push of ownership of the contract. Must be called by
     * the new owner.
     */
    function pullOwnership() public override virtual {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual override onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/BondPriceHelper/BondPriceHelper.sol



interface IBond {
  function initializeBondTerms(
    uint256 _controlVariable,
    uint256 _vestingTerm,
    uint256 _minimumPrice,
    uint256 _maxPayout,
    uint256 _fee,
    uint256 _maxDebt,
    uint256 _initialDebt
  ) external;

  function totalDebt() external view returns (uint256);

  function isLiquidityBond() external view returns (bool);

  function bondPrice() external view returns (uint256);

  function terms()
    external
    view
    returns (
      uint256 controlVariable, // scaling variable for price
      uint256 vestingTerm, // in blocks
      uint256 minimumPrice, // vs principle value
      uint256 maxPayout, // in thousandths of a %. i.e. 500 = 0.5%
      uint256 fee, // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
      uint256 maxDebt // 9 decimal debt ratio, max % total supply created as debt
    );
}

contract BondPriceHelper is Ownable {
  using SafeMath for uint256;

  address public realOwner;
  mapping(address => bool) public executors;
  mapping(address => bool) public bonds;

  constructor(address _realOwner) {
    require(_realOwner != address(0));
    realOwner = _realOwner;
    transferOwnership(_realOwner);
  }

  function addExecutor(address executor) external onlyOwner {
    executors[executor] = true;
  }

  function removeExecutor(address executor) external onlyOwner {
    delete executors[executor];
  }

  function addBond(address bond) external onlyOwner {
    //IBond(bond).bondPrice();
    IBond(bond).terms();
    IBond(bond).isLiquidityBond();
    bonds[bond] = true;
  }

  function removeBond(address bond) external onlyOwner {
    delete bonds[bond];
  }

  function recalculate(address bond, uint256 percent)
    internal
    view
    returns (uint256)
  {
    if (IBond(bond).isLiquidityBond()) return percent;
    else {
      uint256 price = IBond(bond).bondPrice();
      return price.mul(percent).sub(1000000).div(price.sub(100));
    }
  }

  function viewPriceAdjust(address bond, uint256 percent)
    external
    view
    returns (
      uint256 _controlVar,
      uint256 _oldControlVar,
      uint256 _minPrice,
      uint256 _oldMinPrice,
      uint256 _price
    )
  {
    uint256 price = IBond(bond).bondPrice();
    (uint256 controlVariable, , uint256 minimumPrice, , , ) = IBond(bond)
      .terms();
    if (minimumPrice == 0) {
      return (
        controlVariable.mul(recalculate(bond, percent)).div(10000),
        controlVariable,
        minimumPrice,
        minimumPrice,
        price
      );
    } else
      return (
        controlVariable,
        controlVariable,
        minimumPrice.mul(percent).div(10000),
        minimumPrice,
        price
      );
  }

  function adjustPrice(address bond, uint256 percent) external {
    if (percent == 0) return;
    require(
      percent > 8000 && percent < 12000,
      "price adjustment can't be more than 20%"
    );
    require(executors[msg.sender] == true, "access deny for price adjustment");
    (
      uint256 controlVariable,
      uint256 vestingTerm,
      uint256 minimumPrice,
      uint256 maxPayout,
      uint256 fee,
      uint256 maxDebt
    ) = IBond(bond).terms();
    if (minimumPrice == 0) {
      IBond(bond).initializeBondTerms(
        controlVariable.mul(recalculate(bond, percent)).div(10000),
        vestingTerm,
        minimumPrice,
        maxPayout,
        fee,
        maxDebt,
        IBond(bond).totalDebt()
      );
    } else
      IBond(bond).initializeBondTerms(
        controlVariable,
        vestingTerm,
        minimumPrice.mul(percent).div(10000),
        maxPayout,
        fee,
        maxDebt,
        IBond(bond).totalDebt()
      );
  }

  function returnOwnership(address bond) external onlyOwner {
    IOwnable(bond).pushOwnership(realOwner);
  }

  function receiveOwnership(address bond) external onlyOwner {
    IOwnable(bond).pullOwnership();
  }
}