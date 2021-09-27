/**
 *Submitted for verification at BscScan.com on 2021-09-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

contract MasterRef is Ownable {
	using SafeMath for uint256;

    // Info of each user.
    struct UserInfo {
        uint256[3]  medals;
        bool firstPlan;
    }

    struct UserPoolInfo {
        uint256[5]  refLevels;
		uint256[5]  refBonus;
		uint256     totalRefWithdrawn;
    }

    mapping (address => mapping (address => UserPoolInfo)) public userPoolInfo;
    mapping (address => UserInfo) public userInfo;
    mapping (address => bool) internal pools;
    address[] public poolList;
    

    event AddPools(address pool);
    event RemPools(address pool);
    event AddMedal(uint256 i, address user);
    event SetFirstPlan(address user);
    event AddRefLevel(uint256 i, address user);
    event AddRefBonus(uint256 i, address user, uint256 amount);
    event AddRefWithdrawn(address user, uint256 amount);

    modifier onlyPools() {
        require(pools[_msgSender()] == true, "Only Pools");
        _;
    }

    constructor() {
	}

    function addPools(address addr)  external onlyOwner {
        require( addr != address(0),"unvalid address");
        require( pools[addr] == false,"unvalid address");
        pools[addr] = true;
        poolList.push(addr);
        emit AddPools(addr);
    }

    function remPools(address addr)  external onlyOwner {
        require( addr != address(0),"unvalid address");
        require( pools[addr] == true,"unvalid address");
        pools[addr] = false;
        emit RemPools(addr);
    }

    function addMedal(uint256 i, address user) external onlyPools{
        userInfo[user].medals[i] = userInfo[user].medals[i].add(1);
        emit AddMedal(i,user);
    }

    function setFirstPlan(address user) external onlyPools{
        if(userInfo[user].firstPlan == false){
            userInfo[user].firstPlan = true;
            emit SetFirstPlan(user);
        }
    }

    function getUserInfo(address user) public view returns(uint256,uint256,uint256,bool){
        return (
            userInfo[user].medals[0],
            userInfo[user].medals[1],
            userInfo[user].medals[2],
            userInfo[user].firstPlan
            );
    }
    
    function addRefLevel(uint256 i, address user) external onlyPools{
        userPoolInfo[msg.sender][user].refLevels[i] = userPoolInfo[msg.sender][user].refLevels[i].add(1);
        emit AddRefLevel(i,user);
    }
    
    function addRefBonus(uint256 i, address user , uint256 amount) external onlyPools{
        userPoolInfo[msg.sender][user].refBonus[i] = userPoolInfo[msg.sender][user].refBonus[i].add(amount);
        emit AddRefBonus(i,user,amount);
    }
    
    function addRefWithdrawn(address user , uint256 amount) external onlyPools{
        userPoolInfo[msg.sender][user].totalRefWithdrawn = userPoolInfo[msg.sender][user].totalRefWithdrawn.add(amount);
        emit AddRefWithdrawn(user,amount);
    }

    function getReferralStats(address pool, address user) public view returns(uint256 [5] memory,uint256 [5] memory, uint256, uint256){

        uint256 available = 0;
        if(userInfo[user].firstPlan == true){
            available = available.add(userPoolInfo[pool][user].refBonus[0]).add(userPoolInfo[pool][user].refBonus[1]);
        }
        if(userInfo[user].medals[0] > 0){
            available = available.add(userPoolInfo[pool][user].refBonus[2]);
        }
        if(userInfo[user].medals[1] > 0){
            available = available.add(userPoolInfo[pool][user].refBonus[3]).add(userPoolInfo[pool][user].refBonus[4]);
        }

        if(available > userPoolInfo[pool][user].totalRefWithdrawn)
        {
            available = available.sub(userPoolInfo[pool][user].totalRefWithdrawn);
        }
        else{
            available = 0;
        }

        return (
            userPoolInfo[pool][user].refLevels,
            userPoolInfo[pool][user].refBonus,
            userPoolInfo[pool][user].totalRefWithdrawn,
            available
            );
    }


}

/* © 2021 by S&S8712943. All rights reserved. */