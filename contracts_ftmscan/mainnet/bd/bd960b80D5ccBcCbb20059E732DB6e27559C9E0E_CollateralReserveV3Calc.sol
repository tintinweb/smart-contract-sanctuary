// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface ITokenOracle {
    function getPrice() external view returns (uint256, uint8);
}
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view  returns (uint8) ;

}

interface ICollateralReserveV3 {
    function getPool(address _token) external view returns (address) ;

}
contract CollateralReserveV3Calc is Ownable {
    // using SafeERC20 for ERC20;
    using SafeMath for uint256;

    address public collateralReserveV3 = 0xb2Ed02492cEdE773a7cAbd7aCD37de6438d29496; // bydefault

    //wftm
    address public wftm = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    //
    address public usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address public dai = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;
    address public mim = 0x82f0B8B456c1A451378467398982d4834b6829c1;
    address public wmemo = 0xDDc0385169797937066bBd8EF409b5B3c0dFEB52;
    address public weth = 0x74b23882a30290451A17c44f4F05243b6b58C76d;
    address public yvdai = 0x637eC617c86D24E421328e6CAEa1d92114892439;
    address public xboo = 0xa48d959AE2E88f1dAA7D5F611E01908106dE7598;
    address public yvusdc = 0xEF0210eB96c7EB36AF8ed1c20306462764935607;
    
    uint256 private constant PRICE_PRECISION = 1e6;

    constructor(){

    }

    address[] public collaterals;
    mapping(address=>address) public collateralOracles;

    receive() external payable {
        payable(collateralReserveV3).transfer(msg.value);
    }

    // add a collatereal 
    function addCollateral(address _token, ITokenOracle _token_oracle) public onlyOwner{
        require(_token != address(0), "invalid token");
        require(address(_token_oracle) != address(0), "invalid token");
        if (collateralOracles[_token] != address(0)) {
            // aready;
            return;
        }
        collateralOracles[_token] = address(_token_oracle);
        collaterals.push(_token);

        emit CollateralAdded(_token);
    }

    // Remove a collatereal 
    function removeCollateral(address _token) public onlyOwner {
        require(_token != address(0), "invalid token");
        // Delete from the mapping
        delete collateralOracles[_token];

        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < collaterals.length; i++){ 
            if (collaterals[i] == _token) {
                // coffin_pools_array[i] = address(0); 
                // This will leave a null in the array and keep the indices the same
                delete collaterals[i];
                break;
            }
        }
        emit CollateralRemoved(_token);
    }
    
    
    function getGlobalCollateralValue() public view  returns (uint256) {
        uint256 val = 0;
        for (uint i = 0; i < collaterals.length; i++){ 
            if (address(collaterals[i])!=address(0)
                &&
                collateralOracles[collaterals[i]]!=address(0))
            {
                val += getCollateralValue(collaterals[i]);
            }
        }
        return val;
    }

    // 6 decimals  
    function getCollateralValue(address _token) public view  returns (uint256) {
        require(address(collateralOracles[_token])!=address(0), "err0");
        return getCollateralBalance(_token).mul(getCollateralPrice(_token)).div(1e18);
    }
    
    // 6 decimals 
    function getValue(address _token, uint256 _amt) public view  returns (uint256) {
        require(address(collateralOracles[_token])!=address(0), "err0");
        return _amt.mul(getCollateralPrice(_token)).div(1e18);
    }

    // // 6 decimals  
    function getCollateralPrice(address _token) public view  returns (uint256) {
        require(address(collateralOracles[_token])!=address(0), "err0");
        ( uint256 price, uint8 d ) = ITokenOracle(collateralOracles[_token]).getPrice();
        return price.mul(PRICE_PRECISION).div(10**d); 
    }


    function getCollateralBalance(address _token) public view  returns (uint256) {
        require(address(_token)!=address(0), "err1");
        uint256 missing_decimals = 18 - IERC20(_token).decimals();

        address pool = ICollateralReserveV3(collateralReserveV3).getPool(_token);
        if (pool!=address(0)) {
            return IERC20(_token).balanceOf(address(pool)).mul(10**missing_decimals);
        }
        return 0;
    }
    

    function setCollateralReserve(address _collateralReserveV3) public onlyOwner {
        require(_collateralReserveV3 != address(0), "invalidAddress");
        collateralReserveV3 = _collateralReserveV3;
        emit NewCollateralReserve(collateralReserveV3);
    }

    event CollateralRemoved(address _token);
    event CollateralAdded(address _token);
    event NewCollateralReserve(address _token);

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