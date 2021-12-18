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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../common/PeaMinterContract.sol";
import {MathLibrary} from "../common/MathLibrary.sol";

/**
 * Control executor fee
 */
contract NFTFeeManager is Ownable {
    uint256 _globalFeePercent;
    address _globalReceiver;

    mapping(address => uint256) _executorFeePercent;
    mapping(address => mapping(address => uint256)) _executorTokenFeePercent;

    mapping(address => address) _executorReceiver;

    constructor() {
        //_globalFeePercent = 100; // 1%
        _globalFeePercent = 0;
        _globalReceiver = _msgSender();
    }

    function setGlobalFee(uint256 feePercent) public onlyOwner {
        _globalFeePercent = feePercent;
    }

    function setExecutorFee(address executor, uint256 feePercent)
        public
        onlyOwner
    {
        _executorFeePercent[executor] = feePercent;
    }

    function setExecutorTokenFee(
        address executor,
        address token,
        uint256 feePercent
    ) public onlyOwner {
        _executorTokenFeePercent[executor][token] = feePercent;
    }

    function setGlobalReceiver(address receiver) public onlyOwner {
        _globalReceiver = receiver;
    }

    function setExecutorReceiver(address executor, address receiver)
        public
        onlyOwner
    {
        _executorReceiver[executor] = receiver;
    }

    function getGlobalFee() public view returns (uint256) {
        return _globalFeePercent;
    }

    function getExecutorFee(address executor) public view returns (uint256) {
        return _executorFeePercent[executor];
    }

    function getExecutorTokenFee(address executor, address token)
        public
        view
        returns (uint256)
    {
        return _executorTokenFeePercent[executor][token];
    }

    function getGlobalReceiver() public view returns (address) {
        return _globalReceiver;
    }

    function getExecutorReceiver(address executor)
        public
        view
        returns (address)
    {
        return _executorReceiver[executor];
    }

    function getCurrentFeePercent(address executor, address token)
        public
        view
        returns (uint256)
    {
        if (_executorTokenFeePercent[executor][token] != 0)
            return _executorTokenFeePercent[executor][token];

        if (_executorFeePercent[executor] != 0)
            return _executorFeePercent[executor];

        return _globalFeePercent;
    }

    function getCurrentReceiver(address executor)
        public
        view
        returns (address)
    {
        if (_executorReceiver[executor] != address(0))
            return _executorReceiver[executor];

        return _globalReceiver;
    }

    function calculateFee(
        address executor,
        address token,
        uint256 amount
    ) public view returns (uint256) {
        uint256 feePercent = getCurrentFeePercent(executor, token);
        if(feePercent == 0) return 0;
        return MathLibrary.calculatePercent(amount, feePercent);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library MathLibrary {

    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = SafeMath.add(a,m);
        uint256 d = SafeMath.sub(c,1);
        return SafeMath.mul(SafeMath.div(d,m),m);
    }   

    /**
     * Percent have to mul with 100
     * Example: 1% = 100, 0.1% = 10, 0.01% = 1
     */    
    function calculatePercent(uint256 _value, uint256 percent) internal pure returns (uint256)  {
        uint256 BASEPERCENT = 100;
        uint256 roundValue = ceil(_value, BASEPERCENT);
        uint256 mulRoundValue = SafeMath.mul(roundValue, BASEPERCENT);
        uint256 result = SafeMath.div(SafeMath.mul(mulRoundValue, percent), 1000000);
        return result;
    }    
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PeaMinterContract is Ownable {

    mapping(address => bool) private _minters;

    function addMinter(address minter) public onlyOwner {
        _minters[minter] = true;
    }
    
    function removeMinter(address minter) public onlyOwner {
        delete _minters[minter];
    }
    
    function isMinter(address minter) public view returns(bool){
        return _minters[minter];
    }
    
    /**
     * @dev Throws if called by any account other than the setup minter.
     */
    modifier onlyMinter() {
        require(_minters[_msgSender()], "PeaMinterContract: caller is not the minter");
        _;
    }    
}