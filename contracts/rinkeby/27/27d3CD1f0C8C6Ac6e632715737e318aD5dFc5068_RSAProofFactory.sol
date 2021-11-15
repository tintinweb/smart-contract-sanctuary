pragma solidity >=0.4.22 <0.7.0;
    
import "./SafeMath.sol"; 

contract RSAProofFactory {
        
  using SafeMath for uint256;
    
  function createProof(uint256[2] memory _K, bytes memory _alphaString) public view returns (bytes memory) {
    // 1.
    bytes memory oneString = I2OSP(1, 1);

    // 2.
    uint256 k = deriveK(_K[0]);
    bytes memory EM = MGF1(abi.encodePacked(oneString, I2OSP(k, 4), I2OSP(_K[0], k), _alphaString), k - 1);

    // 3.
    uint256 m = OS2IP(EM);

    // 4.
    uint256 s = RSASP1(_K, m);

    // 5.
    bytes memory piString = I2OSP(s, k);

    // 6.
    return piString;
  }

  function proofToHash(bytes memory _piString) public pure returns (bytes32) {

    // 1.
    bytes memory twoString = I2OSP(2, 1);

    // 2.
    bytes32 betaString = sha256(abi.encodePacked(twoString, _piString));

    // 3.
    return betaString;
  }

  function verifyProof(uint256[2] memory _publicKey, bytes memory _alphaString, bytes memory _piString) public view returns (bool) {

    // 1.
    uint256 s = OS2IP(_piString);

    // 2.
    uint256 m = RSAVP1(_publicKey, s);

    // 3.
    uint256 k = deriveK(_publicKey[0]);
    bytes memory EM = I2OSP(m, k - 1);

    // 4.
    bytes memory oneString = I2OSP(1, 1);

    // 5.
    bytes memory EM2 = MGF1(abi.encodePacked(oneString, I2OSP(k, 4), I2OSP(_publicKey[0], k), _alphaString), k - 1);

    // 6.
    return keccak256(EM) == keccak256(EM2);
  }

  function I2OSP(uint256 _x, uint256 _xLen) public pure returns (bytes memory) {
    require(32 >= _xLen, "_xLen too large.");

    // 1.
    if ( 32 == _xLen) {
      require(115792089237316195423570985008687907853269984665640564039457584007913129639935 >= _x, "integer too large");
    } else {
      require((256**_xLen) > _x, "integer too large");
    }

    // 2.
    bytes memory intAsBytes = abi.encodePacked(_x);

    // 3.
    bytes memory octetString;
    for(uint i=32-_xLen; i<32; i++) {
      octetString = abi.encodePacked(octetString, intAsBytes[i]);
    }

    return octetString;
  }

  function deriveK(uint256 _modulus) public pure returns (uint256) {
    for(uint i=0; i<32; i++) {
      if(2**(i*8) > _modulus) { return i; }
    }
    return 32;
  }

  // Assuming sha256 is used as Hash
  function MGF1(bytes memory _mgfSeed, uint256 _maskLen) public pure returns (bytes memory) {
    uint256 hLen = 32; // sha256 hLen

    // 1.
    require(_maskLen <= (2**32)*hLen, "mask too long");

    // 2.
    bytes memory T;

    // 3.
    uint256 upperLimit = ceil(_maskLen, hLen);
    uint256 i=0;
    bytes memory c;
    do {
      c = I2OSP(i, 4);
      T = abi.encodePacked(T, sha256(abi.encodePacked(_mgfSeed, c)));
      i++;
    } while(i < upperLimit);

    // 4.
    return leadingOctets(_maskLen, T);
  }

  function ceil(uint256 _num, uint256 _denum) public pure returns (uint256) {
    require(0 != _denum, "_denum must not be zero");
    return ((_num + _denum - 1) / _denum);
  }

  function leadingOctets(uint256 _nmbr, bytes memory _octetString) public pure returns (bytes memory) {
    require(_octetString.length >= _nmbr, "Cannot return more _nmbr of octets than _octetString contains");

    bytes memory firstOctets;
    for(uint i=0; i<_nmbr; i++) {
      firstOctets = abi.encodePacked(firstOctets, _octetString[i]);
    }
    return firstOctets;
  }

  function OS2IP(bytes memory _octetString) public pure returns (uint256) {
    require(32 >= _octetString.length, "_octetString must be no longer than 32 octets.");

    // 1. & 2.
    bytes32 octetString32;
    uint256 lengthDifference = 32 - _octetString.length;
    for(uint i=0; i<_octetString.length; i++) {
      octetString32 |= bytes32(_octetString[i] & 0xFF) >> ((i + lengthDifference)  * 8);
    }

    // 3.
    return uint256(octetString32);
  }

  function RSASP1(uint256[2] memory _K, uint256 _m) public view returns (uint256) {
    // 1.
    require(_m < _K[0], "message representative out of range");

    // 2.
    uint256 s = modularExp(_m, _K[1], _K[0]);

    // 3.
    return s;
  }

  function RSAVP1(uint256[2] memory _K, uint256 _s) public view returns (uint256) {

    // 1.
    require(_s < _K[0], "signature representative out of range");

    // 2.
    uint256 m = modularExp(_s, _K[1], _K[0]);

    // 3.
    return m;
  }

  function modularExp(uint base, uint e, uint m) public view returns (uint o) {
    assembly {
      // define pointer
      let p := mload(0x40)
      // store data assembly-favouring ways
      mstore(p, 0x20)             // Length of Base
      mstore(add(p, 0x20), 0x20)  // Length of Exponent
      mstore(add(p, 0x40), 0x20)  // Length of Modulus
      mstore(add(p, 0x60), base)  // Base
      mstore(add(p, 0x80), e)     // Exponent
      mstore(add(p, 0xa0), m)     // Modulus
      //if iszero(staticcall(sub(gas, 2000), 0x05, p, 0xc0, p, 0x20)) {
      if iszero(staticcall(not(0), 0x05, p, 0xc0, p, 0x20)) {
        revert(0, 0)
      }
      // data
      o := mload(p)
      }
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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

