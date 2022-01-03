// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IPancakePair.sol";

contract FMBPriceTracker is Ownable {
  using SafeMath for uint256;

  IPancakePair public bnbBusdPair;
  IPancakePair public bnbFmbPair;

  address public bnbToken;

  constructor(address _bnbBusdPair, address _bnbFmbPair, address _bnbToken) {
    bnbBusdPair = IPancakePair(_bnbBusdPair);
    bnbFmbPair = IPancakePair(_bnbFmbPair);
    bnbToken = _bnbToken;
  }

  function setBnbBusdPair(address _bnbBusdPair) external onlyOwner {
    bnbBusdPair = IPancakePair(_bnbBusdPair);
  }

  function setBnbFmbPair(address _bnbFmbPair) external onlyOwner {
    bnbFmbPair = IPancakePair(_bnbFmbPair);
  }

  function setBnbToken(address _bnbToken) external onlyOwner {
    bnbToken = _bnbToken;
  }

  // Converts a value in FMB to BUSD
  function fmbToBusd(uint256 fmb) external view returns(uint256 value) {
    value = _token0ToToken1(fmb, bnbFmbPair, bnbBusdPair);
  }

  // Returns the value of 1 FMB in BUSD
  function oneFmbInBusd() external view returns(uint256 value) {
    value = _token0ToToken1(10 ** bnbFmbPair.decimals(), bnbFmbPair, bnbBusdPair);
  }

  // Converts a value in BUSD to FMB
  function busdToFmb(uint256 busd) external view returns(uint256 value) {
    value = _token0ToToken1(busd, bnbBusdPair, bnbFmbPair);
  }

  // Returns the value of 1 BUSD in FMB
  function oneBusdToFmb() external view returns(uint256 value) {
    value = _token0ToToken1(10 ** bnbBusdPair.decimals(), bnbBusdPair, bnbFmbPair);
  }

  // Returns the value of 1 FMB in BNB
  function oneFmbInBnb() external view returns(uint256 value) {
    value = _tokenToBnb(10 ** bnbFmbPair.decimals(), bnbFmbPair);
  }

  // Converts a value in FMB to BNB
  function fmbToBnb(uint256 fmb) external view returns(uint256 value) {
    value = _tokenToBnb(fmb, bnbFmbPair);
  }

  // Converts a value in BNB to FMB
  function bnbToFmb(uint256 bnb) external view returns(uint256 value) {
    uint256 decimals = 10 ** bnbFmbPair.decimals();
    value = bnb.div(_tokenToBnb(decimals, bnbFmbPair)).mul(decimals);
  }

  // Returns the value of 1 BNB in FMB
  function oneBnbInFmb() external view returns(uint256 value) {
    uint256 decimals = 10 ** bnbFmbPair.decimals();
    value = (decimals).div(_tokenToBnb(decimals, bnbFmbPair)).mul(decimals);
  }

  function _isBnbToken0(IPancakePair pair) private view returns(bool) {
    return pair.token0() == bnbToken;
  }

  function _convertToken0ToToken1(uint256 token0, uint256 token0ToBnb, uint256 bnbToToken1, 
    uint256 decimals) private pure returns (uint256) {
    return token0ToBnb.mul(token0).mul(bnbToToken1).div(decimals).div(decimals);
  }

  // Converts token0 to token1 given the pairs of both tokens to BNB
  function _token0ToToken1(uint256 token0, IPancakePair bnbToken0Pair, IPancakePair bnbToken1Pair) 
    private view returns(uint256 value) {
    
    // First get the value of a BNB in token1
    (uint256 reserve0, uint256 reserve1,) = bnbToken1Pair.getReserves();
    uint256 decimals0 = 10 ** bnbToken0Pair.decimals();
    uint256 decimals1 = 10 ** bnbToken1Pair.decimals();

    uint256 bnbToToken1 = 0;
    if (_isBnbToken0(bnbToken1Pair)) {
      reserve1 = reserve1.mul(decimals1);
      bnbToToken1 = reserve1.div(reserve0);
    } else {
      reserve0 = reserve0.mul(decimals1);
      bnbToToken1 = reserve0.div(reserve1);
    }

    // Get the value of token0 in a BNB
    (reserve0, reserve1,) = bnbToken0Pair.getReserves();
    
    uint256 token0ToBnb = 0;
    if (_isBnbToken0(bnbToken0Pair)) {
      reserve0 = reserve0.mul(decimals0);
      token0ToBnb = reserve0.div(reserve1);
    } else {
      reserve1 = reserve1.mul(decimals0);
      token0ToBnb = reserve1.div(reserve0);
    }

    // Convert token0 to token1
    value = _convertToken0ToToken1(token0, token0ToBnb, bnbToToken1, decimals0);
  }

  // Converts a token to BNB given a pair of the token to BNB
  function _tokenToBnb(uint256 token, IPancakePair bnbTokenPair) 
    private view returns(uint256 value) {
    
    // Get the value of BNB in a token
    (uint256 reserve0, uint256 reserve1,) = bnbTokenPair.getReserves();
    uint256 decimals = 10 ** bnbTokenPair.decimals();

    uint256 tokenToBnb = 0;
    if (_isBnbToken0(bnbTokenPair)) {
      reserve0 = reserve0.mul(decimals);
      tokenToBnb = reserve0.div(reserve1);
    } else {
      reserve1 = reserve1.mul(decimals);
      tokenToBnb = reserve1.div(reserve0);
    }

    // Convert token0 to token1
    value = tokenToBnb.mul(token).div(decimals);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IPancakePair {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}