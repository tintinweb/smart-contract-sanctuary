/**
 *Submitted for verification at BscScan.com on 2021-12-25
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/math/SafeMath.sol



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

// File: contracts/TOSHIFLIP_NOW/FlipsTest.sol


pragma solidity >=0.8.0;
/*
****************      **************    ****************    ***            ***  ******************   **************      ****************  ***            ***  ****
*****************    ****************   *****************    ***          ***   ******************  ****************    ****************   ***            ***  ****
**             ***  ***            ***  **             ***    ***        ***    ****************** ******************  ****************    ***            ***  **** 
**              **  **              **  **              **     ***      ***            ****        **              **   ***********        ***            ***  ****
**              **  **              **  **              **      ***    ***             ****        **              **    ***********       ***            ***  
*****************   ******************  *****************        ********              ****        **              **     ***********      ******************  ****
*****************   ******************  *****************         ******               ****        **              **      ***********     ******************  ****     
**              **  **              **  **              **         ****                ****        **              **       ***********    ***            ***  ****
**              **  **              **  **              **         ****                ****        **              **        ***********   ***            ***  ****    
**             ***  **              **  **             ***         ****                ****        ******************    ****************  ***            ***  ****
*****************   **              **  *****************          ****                ****         ****************    ****************   ***            ***  ****
****************    **              **  ****************           ****                ****          **************    ****************    ***            ***  ****

******************   **************      ****************  ***            ***  ****  ******************  ***                 ***  ****************
******************  ****************    ****************   ***            ***  ****  ******************  ***                 ***  *****************
       ****        ******************  ****************    ***            ***  ****  ******************  ***                 ***  ******************
       ****        **              **   ***********        ***            ***  ****  ***                 ***                 ***  ***            ***
       ****        **              **    ***********       ***            ***        ***                 ***                 ***  ***            ***
       ****        **              **     ***********      ******************  ****  ******************  ***                 ***  *****************
       ****        **              **      ***********     ******************  ****  ******************  ***                 ***  **************** 
       ****        **              **       ***********    ***            ***  ****  ***                 ***                 ***  ***
       ****        **              **        ***********   ***            ***  ****  ***                 ***                 ***  ***
       ****        ******************    ****************  ***            ***  ****  ***                 ******************  ***  ***
       ****         ****************    ****************   ***            ***  ****  ***                 ******************  ***  ***
       ****          **************    ****************    ***            ***  ****  ***                 ******************  ***  ***
*/
/**
 * @dev Is library to manage flips.
 * 
 * This contract is linked with Toshiflip Contract.
 * Dont send funds to this contract !!!
**/


library FlipsMapping {
    using SafeMath for uint256;
    
    // Iterable mapping from address to uint;
    struct Flip{
        address key;
        address player1;
        address player2;
        address currency;
        uint256 amount;
        address commitment1;
        address commitment2;
        address winner;
        address looser;
        bool finished;
        uint256 balance;
        uint256 dateCreated;
        uint256 dateFinished;
    }

    // Struct of all flips
    struct Flips{
        address[] keys;
        mapping(address => Flip) flips;
        mapping(address => address) nonces;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    /**
     * @dev Create random address for a party
     */
    function createFlipAddress(uint nbRandomAddress) internal view returns (address randomPlayer) {
        return address(uint160(uint(keccak256(abi.encodePacked(nbRandomAddress, msg.sender, address(this), block.timestamp, block.difficulty, blockhash(block.number))))));
    }

    /**
     * @dev Create nonce for a party
     */
    function createNonce(address flipKey, uint nbNonce) internal view returns (address nonce) {
        return address(uint160(uint(keccak256(abi.encodePacked(flipKey, nbNonce, msg.sender, address(this), block.timestamp, block.difficulty, blockhash(block.number))))));
    }

    /**
     * @dev Create commitment for a player
     */
    function createCommitment(address flipKey, address nonce, bool choice) internal pure returns (address commitment) {
        return address(uint160(uint(keccak256(abi.encodePacked(flipKey, nonce, choice)))));
    }

    /**
     * @dev Get a flip
     */
    function get(Flips storage flips, address key) internal view returns(Flip memory flip) {
        if( !flips.inserted[key] )
            return Flip(address(0),address(0), address(0), address(0), 0, address(0), address(0), address(0), address(0), false, 0, 0, 0);

        return flips.flips[key];
    } 
    /**
     * @dev Get all flips
     */
    function getAll(Flips storage flips) external view returns(Flip[] memory flip) {
        uint _size = flips.keys.length;
        if( _size == 0 )
            return new Flip[](0);

        Flip[] memory _flips = new Flip[](_size);
        for( uint i=0; i < _size; i++){
            _flips[i] = get(flips, flips.keys[i]);
        }
        return _flips;
    } 

    /**
     * @dev Add a flip
     */
    function add(Flips storage flips, address currency, uint256 amount, bool choice) external returns (address _key){
        uint length = flips.keys.length;
        address key = createFlipAddress(length);
        if( flips.inserted[key] )
            return address(0);

        address nonce = createNonce(key, length);
        
        flips.flips[key] = Flip(key, msg.sender, address(0), currency, amount, createCommitment(key, nonce, choice), 
                    address(0), address(0), address(0), false, amount, block.timestamp, 0);
                    
        flips.nonces[key] = nonce;
        flips.indexOf[key] = flips.keys.length;
        flips.inserted[key] = true;
        flips.keys.push(key);   
        return key;
    }
    /**
     * @dev Join a flip
     */
    function join(Flips storage flips, address _key, uint256 amount, bool choice) external returns(Flip memory flip) {
        
        address key = _key;
        address nonce = flips.nonces[key];
        address commitment2 = createCommitment(key, nonce, choice);
        flips.flips[key].player2 = msg.sender;
        flips.flips[key].commitment2 = commitment2;
        
        flips.flips[key].winner = flips.flips[key].commitment1 == commitment2 ? msg.sender : flips.flips[key].player1; // if the same commitment, player2 wins !!!
        flips.flips[key].looser = flips.flips[key].commitment1 == commitment2 ? flips.flips[key].player1 : msg.sender; // if not the same commitment, player1 wins !!!

        flips.flips[key].finished = true;
        flips.flips[key].balance += amount;
        flips.flips[key].dateFinished = block.timestamp;
        delete flips.nonces[key];

        return flips.flips[key]; 
    }
    
    /**
     * @dev Remove a flip
     */
    function remove(Flips storage flips, address key) external returns (bool removed) {
        if( !flips.inserted[key] )
            return false;

        delete flips.flips[key];
        delete flips.nonces[key];
        delete flips.inserted[key];
        uint index = flips.indexOf[key];
        uint lastIndex = flips.keys.length - 1;
        address lastKey = flips.keys[lastIndex];

        flips.indexOf[lastKey] = index;
        delete flips.indexOf[key];

        flips.keys[index] = lastKey;
        flips.keys.pop();
        return true;
    }

    /**
     * @dev Verify if a flip exists
     */
    function contains(Flips storage flips, address key) external view returns(bool isFlip){
        return flips.inserted[key];
    }

    /**
     * @dev Get flips size
     */
    function size(Flips storage flips) external view returns (uint length) {
        return flips.keys.length;
    } 
    
}