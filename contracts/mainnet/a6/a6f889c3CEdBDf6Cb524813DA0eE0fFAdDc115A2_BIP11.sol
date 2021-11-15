// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import {Math} from '@openzeppelin/contracts/math/Math.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';

import {Operator} from '../access/Operator.sol';
import {Curve} from './Curve.sol';

contract BIP11 is Operator, Curve {
    using SafeMath for uint256;

    /* ============= STATE VARIABLES ============= */

    uint256[41] private slots;

    /* ============= CONSTRUCTOR ============= */

    constructor(
        uint256 _minSupply,
        uint256 _maxSupply,
        uint256 _minCeiling,
        uint256 _maxCeiling
    ) {
        minSupply = _minSupply; // minimum price == 0
        maxSupply = _maxSupply; // maximum price == 1
        minCeiling = _minCeiling; // minimum ceiling == 0
        maxCeiling = _maxCeiling; // maximum ceiling == 0

        slots[0] = 254991593906910240;
        slots[1] = 255656216913953120;
        slots[2] = 256409333446256384;
        slots[3] = 257262726279814880;
        slots[4] = 258229747049020032;
        slots[5] = 259325525137728320;
        slots[6] = 260567204383852672;
        slots[7] = 261974211300803616;
        slots[8] = 263568559012200928;
        slots[8] = 265375191655021440;
        slots[9] = 267422374639493536;
        slots[10] = 269742136871492800;
        slots[11] = 272370771856165600;
        slots[12] = 275349405522724960;
        slots[13] = 278724639654239424;
        slots[14] = 282549280989103488;
        slots[15] = 286883167401240032;
        slots[16] = 291794104084919936;
        slots[17] = 297358924391140992;
        slots[18] = 303664691912730176;
        slots[19] = 310810062625218048;
        slots[20] = 318906828394662656;
        slots[21] = 328081666001153216;
        slots[22] = 338478119042087424;
        slots[23] = 350258843722803840;
        slots[24] = 363608153670763840;
        slots[25] = 378734903587804416;
        slots[26] = 395875756856227584;
        slots[27] = 415298888221586752;
        slots[28] = 437308179481957312;
        slots[29] = 462247973826743424;
        slots[30] = 490508463208342656;
        slots[31] = 522531793034013184;
        slots[32] = 558818979688020544;
        slots[33] = 599937749111156096;
        slots[34] = 646531419074993792;
        slots[35] = 699328964117222656;
        slots[36] = 759156420607550464;
        slots[37] = 826949810380488320;
        slots[38] = 903769785129849216;
        slots[39] = 990818220681719680;
        slots[40] = 1015797020769208960;
    }

    /* ============= GOVERNANCE ============= */

    function setMinSupply(uint256 _newMinSupply) public override onlyOperator {
        super.setMinSupply(_newMinSupply);
    }

    function setMaxSupply(uint256 _newMaxSupply) public override onlyOperator {
        super.setMaxSupply(_newMaxSupply);
    }

    function setMinCeiling(uint256 _newMinCeiling)
        public
        override
        onlyOperator
    {
        super.setMinCeiling(_newMinCeiling);
    }

    function setMaxCeiling(uint256 _newMaxCeiling)
        public
        override
        onlyOperator
    {
        super.setMaxCeiling(_newMaxCeiling);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function calcCeiling(uint256 _price)
        public
        view
        override
        returns (uint256)
    {
        if (_price <= minSupply) {
            return minCeiling;
        }
        if (_price >= maxSupply) {
            return maxCeiling;
        }

        uint256 slotWidth = maxSupply.sub(minSupply).div(slots.length.sub(1));
        uint256 xa = _price.sub(minSupply).div(slotWidth);
        uint256 xb = xa.add(1);

        uint256 slope = slots[xb].sub(slots[xa]).mul(1e18).div(slotWidth);
        uint256 x = slope.mul(slotWidth.mul(xa)).div(1e18);
        uint256 y = slots[xa];

        uint256 wy = 0;
        uint256 percentage = 0;
        if (x > y) {
            wy = x.sub(y);
            percentage = slope.mul(_price).div(1e18).sub(wy);
        } else {
            wy = y.sub(x);
            percentage = slope.mul(_price).div(1e18);
        }

        return
            minCeiling.add(
                maxCeiling.sub(minCeiling).mul(percentage).div(1e18)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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
pragma solidity >=0.7.0 <0.8.0;

import {Context, Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

abstract contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );

    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(
            _operator == _msgSender(),
            'operator: caller is not the operator'
        );
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(
            newOperator_ != address(0),
            'operator: zero address given for new operator'
        );
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

interface ICurve {
    function minSupply() external view returns (uint256);

    function maxSupply() external view returns (uint256);

    function minCeiling() external view returns (uint256);

    function maxCeiling() external view returns (uint256);

    function calcCeiling(uint256 _supply) external view returns (uint256);
}

abstract contract Curve is ICurve {
    /* ========== EVENTS ========== */

    event MinSupplyChanged(
        address indexed operator,
        uint256 _old,
        uint256 _new
    );

    event MaxSupplyChanged(
        address indexed operator,
        uint256 _old,
        uint256 _new
    );

    event MinCeilingChanged(
        address indexed operator,
        uint256 _old,
        uint256 _new
    );

    event MaxCeilingChanged(
        address indexed operator,
        uint256 _old,
        uint256 _new
    );

    /* ========== STATE VARIABLES ========== */

    uint256 public override minSupply;
    uint256 public override maxSupply;

    uint256 public override minCeiling;
    uint256 public override maxCeiling;

    /* ========== GOVERNANCE ========== */

    function setMinSupply(uint256 _newMinSupply) public virtual {
        uint256 oldMinSupply = minSupply;
        minSupply = _newMinSupply;
        emit MinSupplyChanged(msg.sender, oldMinSupply, _newMinSupply);
    }

    function setMaxSupply(uint256 _newMaxSupply) public virtual {
        uint256 oldMaxSupply = maxSupply;
        maxSupply = _newMaxSupply;
        emit MaxSupplyChanged(msg.sender, oldMaxSupply, _newMaxSupply);
    }

    function setMinCeiling(uint256 _newMinCeiling) public virtual {
        uint256 oldMinCeiling = _newMinCeiling;
        minCeiling = _newMinCeiling;
        emit MinCeilingChanged(msg.sender, oldMinCeiling, _newMinCeiling);
    }

    function setMaxCeiling(uint256 _newMaxCeiling) public virtual {
        uint256 oldMaxCeiling = _newMaxCeiling;
        maxCeiling = _newMaxCeiling;
        emit MaxCeilingChanged(msg.sender, oldMaxCeiling, _newMaxCeiling);
    }

    function calcCeiling(uint256 _supply)
        external
        view
        virtual
        override
        returns (uint256);
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

