/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
library UintLibrary {
    using SafeMath for uint;

    function toString(uint256 i) internal pure returns (string memory) {
        if (i == 0) {
            return "0";
        }
        uint j = i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0) {
            bstr[k--] = byte(uint8(48 + i % 10));
            i /= 10;
        }
        return string(bstr);
    }

    function bp(uint value, uint bpValue) internal pure returns (uint) {
        return value.mul(bpValue).div(10000);
    }
}

library StringLibrary {
    using UintLibrary for uint256;

    function append(string memory a, string memory b) internal pure returns (string memory) {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        bytes memory bab = new bytes(ba.length + bb.length);
        uint k = 0;
        for (uint i = 0; i < ba.length; i++) bab[k++] = ba[i];
        for (uint i = 0; i < bb.length; i++) bab[k++] = bb[i];
        return string(bab);
    }

    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        bytes memory bc = bytes(c);
        bytes memory bbb = new bytes(ba.length + bb.length + bc.length);
        uint k = 0;
        for (uint i = 0; i < ba.length; i++) bbb[k++] = ba[i];
        for (uint i = 0; i < bb.length; i++) bbb[k++] = bb[i];
        for (uint i = 0; i < bc.length; i++) bbb[k++] = bc[i];
        return string(bbb);
    }

    function recover(string memory message, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory msgBytes = bytes(message);
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0), new bytes(0), new bytes(0), new bytes(0)
        );
        return ecrecover(keccak256(fullMessage), v, r, s);
    }

    function concat(bytes memory ba, bytes memory bb, bytes memory bc, bytes memory bd, bytes memory be, bytes memory bf, bytes memory bg) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(ba.length + bb.length + bc.length + bd.length + be.length + bf.length + bg.length);
        uint k = 0;
        for (uint i = 0; i < ba.length; i++) resultBytes[k++] = ba[i];
        for (uint i = 0; i < bb.length; i++) resultBytes[k++] = bb[i];
        for (uint i = 0; i < bc.length; i++) resultBytes[k++] = bc[i];
        for (uint i = 0; i < bd.length; i++) resultBytes[k++] = bd[i];
        for (uint i = 0; i < be.length; i++) resultBytes[k++] = be[i];
        for (uint i = 0; i < bf.length; i++) resultBytes[k++] = bf[i];
        for (uint i = 0; i < bg.length; i++) resultBytes[k++] = bg[i];
        return resultBytes;
    }
}

contract Hash{
    using StringLibrary for string;
    constructor(){
        
    }
    
    function getHash(string memory message,uint8 v, bytes32 r, bytes32 s,address signer) public view returns(bool state){
         state = message.recover(v,r,s)==signer;
    }
    
}