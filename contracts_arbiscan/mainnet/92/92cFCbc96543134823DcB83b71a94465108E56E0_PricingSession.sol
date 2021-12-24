/**
 *Submitted for verification at arbiscan.io on 2021-12-24
*/

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File contracts/helpers/ReentrancyGuard.sol

pragma solidity ^0.8.0;

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /// @dev counter to allow mutex lock with only one SSTORE operation
  uint256 private _guardCounter = 1;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one `nonReentrant` function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and an `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}


// File contracts/interfaces/IABCTreasury.sol

pragma solidity ^0.8.0;

interface IABCTreasury {
    function sendABCToken(address recipient, uint _amount) external;

    function getTokensClaimed() external view returns(uint);
    
    function updateNftPriced() external;
    
    function updateProfitGenerated(uint _amount) external;

}


// File contracts/libraries/SafeMath.sol

pragma solidity ^0.8.0;

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File contracts/libraries/sqrtLibrary.sol

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library sqrtLibrary {
    
    function sqrt(uint x) pure internal returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}


// File hardhat/[email protected]
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}


// File contracts/libraries/PostSessionLibrary.sol

pragma solidity ^0.8.0;


library PostSessionLibrary {

    using sqrtLibrary for *;


    function collusionCheck(uint correct, uint incorrect, uint spread) pure internal returns (bool) {
        if(correct * 100 / (correct + incorrect) >= (95-spread)) {
            return true;
        }
        else {
            return false;
        }
    }

    /////////////////////
    /// Session Bound ///
    /////////////////////

    function calculateTotalValue(
        uint values,
        uint[] memory appraisals, 
        uint finalAppraisal
    ) pure internal returns (uint totalValue) {
        for(uint j = 0; j < 30; j++) {
            if (j == values) { 
                break;
            }
            if(appraisals[j] > finalAppraisal) {
                totalValue += (appraisals[j] - finalAppraisal) ** 2;
            }
            else {
                totalValue += (finalAppraisal - appraisals[j]) ** 2;
            }
        }
    }

    function calculateBound(uint finalAppraisalValue, uint stdev, uint defender) pure internal returns (uint upperBound) {
        upperBound = finalAppraisalValue + (3 * (stdev + 20e18/finalAppraisalValue) / (defender + 1) * 2);
    }

    /////////////////////
    ///      Base     ///
    /////////////////////

    function calculateBase(uint finalAppraisalValue, uint userAppraisalValue, uint spread) pure internal returns(uint){
        uint base = 1;
        uint userVal = 100 * userAppraisalValue;
        for(uint i=spread; i >= 1; i--) {
            uint lowerOver = (100 + (i - 1)) * finalAppraisalValue;
            uint upperOver = (100 + i) * finalAppraisalValue;
            uint lowerUnder = (100 - i) * finalAppraisalValue;
            uint upperUnder = (100 - i + 1) * finalAppraisalValue;
            if (lowerOver < userVal && userVal <= upperOver) {
                return base; 
            }
            if (lowerUnder < userVal && userVal <= upperUnder) {
                return base;
            }
            base += 1;
        }
        if(userVal == 100*finalAppraisalValue) {
            return spread + 1;
        }
        return 0;
    }

    /////////////////////
    ///    Harvest    ///
    /////////////////////

    // function harvestUserOver(uint _stake, uint _userAppraisal, uint _finalAppraisal) pure internal returns(uint) {
    //     return _stake * (_userAppraisal*100 - 105*_finalAppraisal)/(_finalAppraisal*100);
    // }
    
    // function harvestUserUnder(uint _stake, uint _userAppraisal, uint _finalAppraisal) pure internal returns(uint) {
    //     return _stake * (95*_finalAppraisal - 100*_userAppraisal)/(_finalAppraisal*100);
    // }

    function harvest(uint _stake, uint _userAppraisal, uint _finalAppraisal, uint riskFactor, uint spread) pure internal returns(uint) {
        if(_userAppraisal*100 > (100 + spread)*_finalAppraisal && (_userAppraisal*100 - (100 + spread)*_finalAppraisal)/(_finalAppraisal) > (100 + spread)) {
            return _stake;
        }
        else if(_userAppraisal*100 > (100 + spread)*_finalAppraisal) {
            if (_stake * (_userAppraisal*100 - (100 + spread)*_finalAppraisal)/(_finalAppraisal*100) * riskFactor > _stake) {
                return _stake;
            }
            else {
                return _stake * (_userAppraisal*100 - (100 + spread)*_finalAppraisal)/(_finalAppraisal*100) * riskFactor;
            }
        }
        else if(_userAppraisal*100 < (100 - spread)*_finalAppraisal) {
            if (_stake * ((100 - spread)*_finalAppraisal - 100*_userAppraisal)/(_finalAppraisal*100) * riskFactor > _stake) {
                return _stake;
            }
            else {
                return _stake * ((100 - spread)*_finalAppraisal - 100*_userAppraisal)/(_finalAppraisal*100) * riskFactor;
            }
        }
        else {
            return 0;
        }
    }

    /////////////////////
    ///   Commission  ///
    /////////////////////   
    function setCommission(uint _treasurySize) pure internal returns(uint) {
        if (_treasurySize < 25000 ether) {
            return 500;
        }
        else if(_treasurySize >= 25000 ether && _treasurySize < 50000 ether) {
            return 400;
        }
        else if(_treasurySize >= 50000 ether && _treasurySize < 100000 ether) {
            return 300;
        }
        else if(_treasurySize >= 100000 ether && _treasurySize < 2000000 ether) {
            return 200;
        }
        else if(_treasurySize >= 200000 ether && _treasurySize < 400000 ether) {
            return 100;
        }
        else if(_treasurySize >= 400000 ether && _treasurySize < 700000 ether) {
            return 50;
        }
        else {
            return 25;
        }
    }


}


// File contracts/interfaces/IERC20.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/ABCTreasury.sol

pragma solidity ^0.8.0;


/// @author Medici
/// @title Treasury contract for Abacus
contract ABCTreasury is  ReentrancyGuard {
    
    /* ======== UINT ======== */

    uint public nftsPriced;
    uint public profitGenerated;
    uint public tokensClaimed;
    uint public riskFactor;
    uint public spread;
    uint public defender;
    uint public commissionRate;
    uint public payoutMultiplier;

    /* ======== BOOL ======== */

    bool public tokenStatus;
    bool public auctionStatus;

    /* ======== ADDRESS ======== */

    address public auction;
    address public pricingSession;
    address public admin;
    address public ABCToken;
    address public multisig;
    address public creditStore;

    /* ======== EVENTS ======== */

    event ethClaimedByUser(address user_, uint ethClaimed);
    event ethToABCExchange(address user_, uint ethExchanged, uint ppSent);

    /* ======== CONSTRUCTOR ======== */

    constructor(address _creditStore) {
        admin = msg.sender;
        creditStore = _creditStore;
        auctionStatus = true;
        riskFactor = 2;
        spread = 10;
        defender = 2;
        commissionRate = 500;
        payoutMultiplier = 200;
    }

    /* ======== ADMIN FUNCTIONS ======== */

    /// @notice set the auction status based on the active/inactive status of the bounty auction
    /// @param status desired auction status to be stored and referenced in contract
    function setAuctionStatus(bool status) onlyAdmin external {
        auctionStatus = status;
    }

    /// @notice set the auction status based on the active/inactive status of the bounty auction
    /// @param _commissionRate desired commission percentage the protocol would like to take
    function setCommissionRate(uint _commissionRate) onlyAdmin external {
        commissionRate = _commissionRate;
    }

    function setPayoutMultiplier(uint _multiplier) onlyAdmin external {
        payoutMultiplier = _multiplier;
    }

    /// @notice set protocol risk factor
    /// @param _risk the protocol risk factor is a multiplier applied to any losses harvested
    function setRiskFactor(uint _risk) onlyAdmin external {
        riskFactor = _risk;
    }

    /// @notice set the protocol spread
    /// @param _spread the protocol spread is the margin of error that correctness is based on
    function setSpread(uint _spread) onlyAdmin external {
        spread = _spread;
    }

    /// @notice set the protocol defender level
    /** @dev the defender is used to determined the amount of
    recursive bound exclusions enforced per session. 
    
    For example, in times of a high volume of extreme value attacks,
    the community can set the defender to level 3 in which case every session
    will have the _boundCheck happen 3 times. What this means is there will be
    one bound check, the final appraisal will be adjusted, then a second check,
    final appraisal will be re-adjusted, then a third, and final appraisal will
    be adjusted one final time. 

    Any values that are removed result in removal from final appraisal affect 
    AND their stake is completely lost. 
    */
    /// @param _defender the defender is a value that determines the amount of recursive bound exclusions enforced per session
    function setDefender(uint _defender) onlyAdmin external {
        defender = _defender;
    }

    /// @notice set ABC token contract address 
    /// @param _ABCToken desired ABC token to be stored and referenced in contract
    function setABCTokenAddress(address _ABCToken) onlyAdmin external {
        ABCToken = _ABCToken;
    }

    function setMultisig(address _multisig) onlyAdmin external {
        multisig = _multisig;
    }

    /// @notice allow admin to withdraw funds to multisig in the case of emergency (ONLY USED IN THE CASE OF EMERGENCY)
    /// @param _amountEth value of ETH to be withdrawn from the treasury to multisig (ONLY USED IN THE CASE OF EMERGENCY)
    function withdrawEth(uint _amountEth) onlyAdmin external {
        (bool sent, ) = payable(multisig).call{value: _amountEth}("");
        require(sent, "Failed to send Ether");
    }

    /// @notice allow admin to withdraw funds to multisig in the case of emergency (ONLY USED IN THE CASE OF EMERGENCY)
    /// @param _amountAbc value of ABC to be withdrawn from the treasury to multisig (ONLY USED IN THE CASE OF EMERGENCY)
    function withdrawAbc(uint _amountAbc) onlyAdmin external {
        bool sent = IERC20(ABCToken).transfer(multisig, _amountAbc);
        require(sent);
    }

    /// @notice set newAdmin (or burn admin when the time comes)
    /// @param _newAdmin desired admin address to be stored and referenced in contract
    function setAdmin(address _newAdmin) onlyAdmin external {
        admin = _newAdmin;
    }

    /// @notice set pricing factory address to allow for updates
    /// @param _pricingFactory desired pricing session principle address to be stored and referenced in contract
    function setPricingSession(address _pricingFactory) onlyAdmin external {
        pricingSession = _pricingFactory;
    }

    /// @notice set auction contract for bounty auction period
    /// @param _auction desired auction address to be stored and referenced in contract
    function setAuction(address _auction) onlyAdmin external {
        auction = _auction;
    }

    function setCreditStore(address _creditStore) onlyAdmin external {
        creditStore = _creditStore;
    }

    /* ======== CHILD FUNCTIONS ======== */
    
    /// @notice send ABC to users that earn 
    /// @param recipient the user that will be receiving ABC 
    /// @param _amount the amount of ABC to be transferred to the recipient
    function sendABCToken(address recipient, uint _amount) public {
        require(msg.sender == creditStore || msg.sender == admin);
        if(msg.sender == creditStore) {
            IERC20(ABCToken).transfer(recipient, payoutMultiplier * _amount / 100);
        }
        else {
            IERC20(ABCToken).transfer(recipient, _amount);
        }
    }

    /// @notice track amount of nfts priced
    function updateNftPriced() isFactory external {
        nftsPriced++;
    }

    /// @notice track total profits generated by the protocol through fees
    function updateTotalProfitsGenerated(uint _amount) isFactory external {
        profitGenerated += _amount;
    }

    /* ======== FALLBACKS ======== */

    receive() external payable {}
    fallback() external payable {}

    /* ======== MODIFIERS ======== */

    ///@notice check that msg.sender is admin
    modifier onlyAdmin() {
        require(admin == msg.sender, "not admin");
        _;
    }
    
    ///@notice check that msg.sender is factory
    modifier isFactory() {
        require(msg.sender == pricingSession, "not session contract");
        _;
    }

    ///@notice check that msg.sender is factory
    modifier isCreditStore() {
        require(msg.sender == creditStore, "not credit store contract");
        _;
    }
}


// File contracts/CreditVault.sol

pragma solidity ^0.8.0;



/// @author Medici
/// @title Treasury contract for Abacus
contract CreditVault is  ReentrancyGuard {

    /* ======== UINT ======== */

    uint public tokensClaimed;

    /* ======== BOOL ======== */

    bool public tokenStatus;

    /* ======== ADDRESS ======== */

    address public auction;
    address public pricingSession;
    address public admin;
    address public token;
    address public multisig;
    address public treasury;

    /* ======== MAPPING ======== */

    /// @notice maps each user to their total profit earned
    mapping(address => uint) public profitStored;

    /// @notice maps each user to their principal stored
    mapping(address => uint) public principalStored;

    /// @notice maps each user to their history of profits earned 
    mapping(address => uint) public totalProfitEarned;

    /* ======== EVENTS ======== */

    event ethClaimedByUser(address user_, uint ethClaimed);
    event ethToABCExchange(address user_, uint ethExchanged, uint ppSent);

    /* ======== CONSTRUCTOR ======== */

    constructor() {
        admin = msg.sender;
    }

    /* ======== ADMIN FUNCTIONS ======== */

    function setTokenStatus(bool _status) onlyAdmin external {
        tokenStatus = _status;
    }

    /// @notice set ABC token contract address 
    /// @param _ABCToken desired ABC token to be stored and referenced in contract
    function setABCTokenAddress(address _ABCToken) onlyAdmin external {
        token = _ABCToken;
    }

    function setMultisig(address _multisig) onlyAdmin external {
        multisig = _multisig;
    }

    function setTreasury(address _treasury) onlyAdmin external {
        treasury = _treasury;
    }

    /// @notice set newAdmin (or burn admin when the time comes)
    /// @param _newAdmin desired admin address to be stored and referenced in contract
    function setAdmin(address _newAdmin) onlyAdmin external {
        admin = _newAdmin;
    }

    /// @notice set pricing factory address to allow for updates
    /// @param _pricingFactory desired pricing session principle address to be stored and referenced in contract
    function setPricingSession(address _pricingFactory) onlyAdmin external {
        pricingSession = _pricingFactory;
    }

    /// @notice set auction contract for bounty auction period
    /// @param _auction desired auction address to be stored and referenced in contract
    function setAuction(address _auction) onlyAdmin external {
        auction = _auction;
    }

    /* ======== USER FUNCTIONS ======== */

    /// @notice user deposits principal
    function depositPrincipal() nonReentrant payable external {
        principalStored[msg.sender] += msg.value;
    }

    /// @notice allows user to reclaim principalUsed in batches
    function claimPrincipalUsed(uint _amount) nonReentrant external {
        require(_amount <= principalStored[msg.sender]);
        principalStored[msg.sender] -= _amount;
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    /// @notice allows user to claim batched earnings
    /// @param trigger denotes whether the user desires it in ETH (1) or ABC (2)
    function claimProfitsEarned(uint trigger, uint _amount) nonReentrant external {
        require(trigger == 1 || trigger == 2);
        require(profitStored[msg.sender] >= _amount);
        if(trigger == 1) {
            (bool sent, ) = msg.sender.call{value: _amount}("");
            require(sent, "Failed to send Ether");
            profitStored[msg.sender] -= _amount;
            emit ethClaimedByUser(msg.sender, _amount);
        }
        else if(trigger == 2) {
            require(tokenStatus);
            uint abcAmount = _amount * ethToAbc();
            tokensClaimed += abcAmount;
            profitStored[msg.sender] -= _amount;
            ABCTreasury(payable(treasury)).sendABCToken(msg.sender, abcAmount);
            emit ethToABCExchange(msg.sender, _amount, abcAmount);
        }
    } 

    /* ======== CHILD FUNCTIONS ======== */

    /// @notice Allows Factory contract to update the profit generated value
    /// @param _amount the amount of profit to update profitGenerated count
    function increasePrincipalStored(address _user, uint _amount) isFactory external { 
        principalStored[_user] += _amount;
    }

    /// @notice decrease credit stored
    function decreasePrincipalStored(address _user, uint _amount) isFactory external {
        require(principalStored[_user] >= _amount);
        principalStored[_user] -= _amount;
    }
    
    /// @notice track profits earned by a user
    function updateProfitStored(address _user, uint _amount) isFactory external {
        profitStored[_user] += _amount;
        totalProfitEarned[_user] += _amount;
    }

    function sendToTreasury(uint _amount) isFactory external {
        payable(treasury).transfer(_amount);
    }

    /* ======== VIEW FUNCTIONS ======== */

    /// @notice returns the current spot exchange rate of ETH to ABC
    function ethToAbc() view public returns(uint) {
        return 1e18 / (0.00005 ether + 0.000015 ether * ((ABCTreasury(payable(treasury)).tokensClaimed()/2) / (1000000*1e18)));
    }

    /* ======== FALLBACKS ======== */

    receive() external payable {}
    fallback() external payable {}

    /* ======== MODIFIERS ======== */

    ///@notice check that msg.sender is admin
    modifier onlyAdmin() {
        require(admin == msg.sender, "not admin");
        _;
    }
    
    ///@notice check that msg.sender is factory
    modifier isFactory() {
        require(msg.sender == pricingSession, "not session contract");
        _;
    }
}


// File contracts/PricingSession.sol

pragma solidity ^0.8.0;









/// @author Medici
/// @title Pricing session contract for Abacus
contract PricingSession is ReentrancyGuard {

    using SafeMath for uint;

    /* ======== ADDRESS ======== */

    address ABCToken;
    ABCTreasury Treasury;
    address admin;
    address auction;
    address creditStore;
    
    /* ======== MAPPINGS ======== */

    /// @notice maps each NFT to its current nonce value
    mapping(address => mapping (uint => uint)) public nftNonce; 

    mapping(uint => mapping(address => mapping(uint => address[]))) NftSessionVoters;

    mapping(uint => mapping(address => mapping(uint => VotingSessionMapping))) NftSessionMap;

    /// @notice maps each NFT pricing session (nonce dependent) to its necessary session checks (i.e. checking session progression)
    /// @dev nonce => tokenAddress => tokenId => session metadata
    mapping(uint => mapping(address => mapping(uint => VotingSessionChecks))) public NftSessionCheck;

    /// @notice maps each NFT pricing session (nonce dependent) to its necessary session core values (i.e. total participants, total stake, etc...)
    mapping(uint => mapping(address => mapping(uint => VotingSessionCore))) public NftSessionCore;

    /// @notice maps each NFT pricing session (nonce dependent) to its final appraisal value output
    mapping(uint => mapping(address => mapping(uint => uint))) public finalAppraisalValue;
    
    /* ======== STRUCTS ======== */

    /// @notice tracks all of the mappings necessary to operate a session
    struct VotingSessionMapping {

        mapping (uint => address) tempList;
        mapping (address => uint) voterCheck;
        mapping (address => uint) winnerPoints;
        mapping (address => uint) secondaryPoint;
        mapping (address => uint) amountHarvested;
        mapping (address => Voter) nftVotes;
    }

    /// @notice track necessary session checks (i.e. whether its time to weigh votes or harvest)
    struct VotingSessionChecks {

        uint sessionProgression;
        uint calls;
        uint correct;
        uint incorrect;
        uint defender;
        uint spread;
        uint riskFactor;
        uint finalStdev;
        uint secondaryPoints;
    }

    /// @notice track the core values of a session (max appraisal value, total session stake, etc...)
    struct VotingSessionCore {

        uint endTime;
        uint bounty;
        uint keeperReward;
        uint lowestStake;
        uint maxAppraisal;
        uint totalAppraisalValue;
        uint totalSessionStake;
        uint totalProfit;
        uint totalWinnerPoints;
        uint totalVotes;
        uint uniqueVoters;
        uint votingTime;
    }

    /// @notice track voter information
    struct Voter {

        bytes32 concealedAppraisal;
        uint base;
        uint appraisal;
        uint stake;
    }

    /* ======== EVENTS ======== */

    event PricingSessionCreated(address creator_, uint nonce, address nftAddress_, uint tokenid_, uint initialAppraisal_, uint bounty_);
    event newAppraisalAdded(address voter_, uint nonce, address nftAddress_, uint tokenid_, uint stake_, bytes32 userHash_);
    event voteWeighed(address user_, uint nonce, address nftAddress_, uint tokenid_, uint appraisal);
    event finalAppraisalDetermined(uint nonce, address nftAddress_, uint tokenid_, uint finalAppraisal, uint amountOfParticipants, uint totalStake);
    event sessionEnded(address nftAddress, uint tokenid, uint nonce);

    /* ======== CONSTRUCTOR ======== */

    constructor(address _treasury, address _auction, address _creditStore) {
        Treasury = ABCTreasury(payable(_treasury));
        auction = _auction;
        admin = msg.sender;
        creditStore = _creditStore;
    }

    /// @notice set the auction address to be referenced throughout the contract
    /// @param _auction desired auction address to be stored and referenced in contract
    function setAuction(address _auction) onlyAdmin external {
        auction = _auction;
    }

    /// @notice set the treasury address
    /// @param treasury desired treasury address to be stored and referenced in contract
    function setTreasury(address treasury) onlyAdmin external {
        Treasury = ABCTreasury(payable(treasury));
    }

    /// @notice set ABC token address
    function setABCToken(address _token) onlyAdmin external {
        ABCToken = _token;
    }

    /// @notice Allow user to create new session and attach initial bounty
    /**
    @dev NFT sessions are indexed using a nonce per specific nft.
    The mapping is done by mapping a nonce to an NFT address to the 
    NFT token id. 
    */ 
    /// @param nftAddress NFT contract address of desired NFT to be priced
    /// @param tokenid NFT token id of desired NFT to be priced 
    /// @param _initialAppraisal appraisal value for max value to be instantiated against
    /// @param _votingTime voting window duration
    function createNewSession(
        address nftAddress,
        uint tokenid,
        uint _initialAppraisal,
        uint _votingTime
    ) stopOverwrite(nftAddress, tokenid) external payable {
        require(_votingTime <= 1 days && (!Treasury.auctionStatus() || msg.sender == auction));
        VotingSessionCore storage sessionCore = NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        if(msg.sender == auction) {}
        else {
            uint abcCost = 0.005 ether *(CreditVault(payable(creditStore)).ethToAbc());
            (bool abcSent) = IERC20(ABCToken).transferFrom(msg.sender, address(Treasury), abcCost);
            require(abcSent);
        }
        if(nftNonce[nftAddress][tokenid] == 0 || getStatus(nftAddress, tokenid) == 5) {}
        else if(block.timestamp > sessionCore.endTime + sessionCore.votingTime * 3) {
            CreditVault(payable(creditStore)).sendToTreasury(sessionCore.totalSessionStake);
            sessionCore.totalSessionStake = 0;
            emit sessionEnded(nftAddress, tokenid, nftNonce[nftAddress][tokenid]);
        }
        nftNonce[nftAddress][tokenid]++;
        VotingSessionCore storage sessionCoreNew = NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        sessionCoreNew.votingTime = _votingTime;
        sessionCoreNew.maxAppraisal = 69420 * _initialAppraisal / 1000;
        sessionCoreNew.lowestStake = 100000 ether;
        sessionCoreNew.endTime = block.timestamp + _votingTime;
        sessionCoreNew.bounty = msg.value;
        sessionCheck.defender = Treasury.defender();
        sessionCheck.spread = Treasury.spread();
        sessionCheck.riskFactor = Treasury.riskFactor();
        payable(creditStore).transfer(sessionCoreNew.bounty);
        emit PricingSessionCreated(msg.sender, nftNonce[nftAddress][tokenid], nftAddress, tokenid, _initialAppraisal, msg.value);
    }

    /* ======== USER VOTE FUNCTIONS ======== */
    
    /// @notice Allows user to set vote in party 
    /** 
    @dev Users appraisal is hashed so users can't track final appraisal and submit vote right before session ends.
    Therefore, users must remember their appraisal in order to reveal their appraisal in the next function.
    */
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    /// @param concealedAppraisal concealed bid that is a hash of the appraisooooors appraisal value, wallet address, and seed number
    function setVote(
        address nftAddress,
        uint tokenid,
        uint stake,
        bytes32 concealedAppraisal
    ) properVote(nftAddress, tokenid, stake) external {
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nonce][nftAddress][tokenid];
        require(sessionCore.endTime > block.timestamp && stake <= CreditVault(payable(creditStore)).principalStored(msg.sender));
        sessionMap.voterCheck[msg.sender] = 1;
        CreditVault(payable(creditStore)).decreasePrincipalStored(msg.sender, stake);
        stake -= 0.004 ether;
        sessionCore.keeperReward += 0.002 ether;
        sessionCore.bounty += 0.002 ether;
        if (stake < sessionCore.lowestStake) {
            sessionCore.lowestStake = stake;
        }
        sessionCore.uniqueVoters++;
        sessionCore.totalSessionStake = sessionCore.totalSessionStake.add(stake);
        sessionMap.nftVotes[msg.sender].concealedAppraisal = concealedAppraisal;
        sessionMap.nftVotes[msg.sender].stake = stake;
        emit newAppraisalAdded(msg.sender, nonce, nftAddress, tokenid, stake, concealedAppraisal);
    }

    /// @notice allow user to update value inputs of their vote while voting is still active
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    /// @param concealedAppraisal concealed bid that is a hash of the appraisooooors new appraisal value, wallet address, and seed number
    function updateVote(
        address nftAddress,
        uint tokenid,
        bytes32 concealedAppraisal
    ) external {
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nonce][nftAddress][tokenid];
        require(sessionMap.voterCheck[msg.sender] == 1);
        require(sessionCore.endTime > block.timestamp);
        sessionMap.nftVotes[msg.sender].concealedAppraisal = concealedAppraisal;
    }

    /// @notice Reveals user vote and weights based on the sessions lowest stake
    /**
    @dev calculation can be found in the weightVoteLibrary.sol file. 
    Votes are weighted as sqrt(userStake/lowestStake). Depending on a votes weight
    it is then added as multiple votes of that appraisal (i.e. if someoneone has
    voting weight of 8, 8 votes are submitted using their appraisal).
    */
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    /// @param appraisal appraisooooor appraisal value used to unlock concealed appraisal
    /// @param seedNum appraisooooor seed number used to unlock concealed appraisal
    function weightVote(address nftAddress, uint tokenid, uint appraisal, uint seedNum) checkParticipation(nftAddress, tokenid) nonReentrant external {
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nonce][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nonce][nftAddress][tokenid];
        address[] storage voters = NftSessionVoters[nonce][nftAddress][tokenid];
        require(sessionCheck.sessionProgression < 2
                && sessionCore.endTime < block.timestamp
                && sessionMap.voterCheck[msg.sender] == 1
                && sessionMap.nftVotes[msg.sender].concealedAppraisal == keccak256(abi.encodePacked(appraisal, msg.sender, seedNum))
                && sessionCore.maxAppraisal >= appraisal
        );
        sessionMap.voterCheck[msg.sender] = 2;
        if(sessionCheck.sessionProgression == 0) {
            sessionCheck.sessionProgression = 1;
        }
        voters.push(msg.sender);
        _weigh(nftAddress, tokenid, appraisal);
        emit voteWeighed(msg.sender, nonce, nftAddress, tokenid, appraisal);
        if(sessionCheck.calls == sessionCore.uniqueVoters || block.timestamp > sessionCore.endTime + 2*sessionCore.votingTime/3) {
            sessionCheck.sessionProgression = 2;
            sessionCore.uniqueVoters = sessionCheck.calls;
            sessionCheck.calls = 0;
        }
    }
    
    /// @notice takes average of appraisals and outputs a final appraisal value.
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    function setFinalAppraisal(address nftAddress, uint tokenid) public {
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nonce][nftAddress][tokenid];
        require(
            (block.timestamp > sessionCore.endTime + 2*sessionCore.votingTime/3 || sessionCheck.sessionProgression == 2)
            && sessionCheck.sessionProgression <= 2
        );
        CreditVault(payable(creditStore)).updateProfitStored(msg.sender, sessionCore.keeperReward/2 ether);
        _boundCheck(nftAddress, tokenid);
        sessionCore.totalProfit += sessionCore.bounty;
        sessionCheck.calls = 0;
        // sessionCheck.timeFinalAppraisalSet = block.timestamp;
        finalAppraisalValue[nonce][nftAddress][tokenid] = (sessionCore.totalAppraisalValue)/(sessionCore.totalVotes);
        sessionCheck.sessionProgression = 3;
        emit finalAppraisalDetermined(nftNonce[nftAddress][tokenid], nftAddress, tokenid, finalAppraisalValue[nftNonce[nftAddress][tokenid]][nftAddress][tokenid], sessionCore.uniqueVoters, sessionCore.totalSessionStake);
    }

    /// @notice Calculates users base and harvests their loss before returning remaining stake
    /**
    @dev A couple notes:
    1. Base is calculated based on margin of error.
        > +/- 5% = 1
        > +/- 4% = 2
        > +/- 3% = 3
        > +/- 2% = 4
        > +/- 1% = 5
        > Exact = 6
    2. winnerPoints are calculated based on --> base * stake
    3. Losses are harvested based on --> (margin of error - 5%) * stake
    */
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    function harvest(address nftAddress, uint tokenid) checkParticipation(nftAddress, tokenid) nonReentrant external returns(uint256){
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nonce][nftAddress][tokenid];
        address[] storage voters = NftSessionVoters[nonce][nftAddress][tokenid];
        require(sessionCheck.sessionProgression == 3);
        address user;
        for(uint i = 0; i < 20; i++) {
            user = voters[sessionCheck.calls];
            CreditVault(payable(creditStore)).updateProfitStored(msg.sender, 0.0005 ether);
            sessionCheck.calls++;
            _harvest(user, nftAddress, tokenid);
            if(sessionCheck.calls == sessionCore.uniqueVoters) {
                sessionCheck.sessionProgression = 4;
                sessionCore.uniqueVoters = sessionCheck.calls;
                sessionCheck.calls = 0;
                return 1;
            }
        }
        return 1;
    }

    /// @notice User claims principal stake along with any earned profits in ETH or ABC form
    /**
    @dev 
    1. Calculates user principal return value
    2. Enacts sybil defense mechanism
    3. Edits totalProfits and totalSessionStake to reflect claim
    5. Pays out principal
    6. Adds profit credit to profitStored
    */
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    function claim(address nftAddress, uint tokenid) checkParticipation(nftAddress, tokenid) nonReentrant external returns(uint) {
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nonce][nftAddress][tokenid];
        address[] storage voters = NftSessionVoters[nonce][nftAddress][tokenid];
        require(sessionCheck.sessionProgression == 4);
        address user;
        for(uint i = 0; i < 20; i++) {
            user = voters[sessionCheck.calls];
            CreditVault(payable(creditStore)).updateProfitStored(msg.sender, 0.0005 ether);
            sessionCheck.calls++;
            _claim(user, nftAddress, tokenid);
            if(sessionCheck.calls == sessionCore.uniqueVoters) {
                CreditVault(payable(creditStore)).sendToTreasury(sessionCore.totalSessionStake);
                sessionCore.totalSessionStake = 0;
                sessionCheck.sessionProgression = 5;
                emit sessionEnded(nftAddress, tokenid, nonce);
                return 1;
            }
        }
        return 1;
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    ///@notice user vote is weighed
    /**
    @dev a voters weight is determined by the following formula:
        sqrt(voterStake/lowestStake)
    this value is then used to
    */
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    /// @param appraisal the voters appraisal value 
    function _weigh(address nftAddress, uint tokenid, uint appraisal) internal {
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nonce][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nonce][nftAddress][tokenid];
        sessionMap.nftVotes[msg.sender].appraisal = appraisal;
        uint weight = sqrtLibrary.sqrt(sessionMap.nftVotes[msg.sender].stake/sessionCore.lowestStake);
        sessionCore.totalVotes += weight;
        sessionCheck.calls++;
        
        sessionCore.totalAppraisalValue = sessionCore.totalAppraisalValue.add((weight) * appraisal);
    }

    /// @notice user vote is checked against the post-determined lower and upper bound 
    /**
    @dev the upper bound for acceptable votes are set using the following equation:

    Calculate margin
        uint256 margin = 3 * stdev + 20e18 / final_appraisal;

    Calculate inclusion bound
        uint256 upper_bound = final_appraisal + margin;
    
    This function is used to root out extreme entries that may be malicious or accidental.
    */
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    function _boundCheck(address nftAddress, uint tokenid) internal {
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nonce][nftAddress][tokenid];
        address[] storage voters = NftSessionVoters[nonce][nftAddress][tokenid];
        if(sessionCheck.calls != 0) {
            sessionCore.uniqueVoters = sessionCheck.calls;
        }
        uint rounds = sessionCore.uniqueVoters / 20 + 1;
        uint totalValue;
        uint voterCount;
        uint invalidCount; 
        for(uint a = 0; a <= sessionCheck.defender; a++) {
            uint finalAppraisal = (sessionCore.totalAppraisalValue)/(sessionCore.totalVotes);
            voterCount = 0;
            for(uint i = 0; i < rounds; i++) {
                for(uint j = 0; j < 20; j++) {
                    if (voterCount == sessionCore.uniqueVoters) { 
                        break; 
                    }
                    if(sessionMap.nftVotes[voters[voterCount]].appraisal == 0) {}
                    else if(sessionMap.nftVotes[voters[voterCount]].appraisal > finalAppraisal) { 
                        totalValue += (sessionMap.nftVotes[voters[voterCount]].appraisal - finalAppraisal) ** 2;
                    }
                    else { 
                        totalValue += (finalAppraisal - sessionMap.nftVotes[voters[voterCount]].appraisal) ** 2;
                    }
                    voterCount++;
                }
            }
            uint stdev = sqrtLibrary.sqrt(totalValue/(sessionCore.uniqueVoters - invalidCount));
            totalValue = 0;
            sessionCheck.finalStdev = stdev;
            voterCount = 0;
            uint upper = PostSessionLibrary.calculateBound(finalAppraisal, stdev, sessionCheck.defender);
            uint weight;
            for(uint i = 0; i < rounds; i++) {
                for(uint j = 0; j < 20; j++) {
                    if (voterCount == sessionCore.uniqueVoters) {
                        break;
                    }
                    weight = sqrtLibrary.sqrt(sessionMap.nftVotes[voters[voterCount]].stake/sessionCore.lowestStake);
                    if(sessionMap.nftVotes[voters[voterCount]].appraisal > upper) {
                        sessionCore.totalVotes -= weight;
                        sessionCore.totalAppraisalValue -= weight * sessionMap.nftVotes[voters[voterCount]].appraisal;
                        sessionMap.nftVotes[voters[voterCount]].appraisal = 0;
                        sessionMap.nftVotes[voters[voterCount]].stake = 0;
                        invalidCount++;
                    }
                    voterCount++;
                }
            }
        }
    }

    /// @notice Calculates users base and harvests their loss before returning remaining stake
    /**
    @dev A couple notes:
    1. Base is calculated based on margin of error.
        > +/- 5% = 1
        > +/- 4% = 2
        > +/- 3% = 3
        > +/- 2% = 4
        > +/- 1% = 5
        > Exact = 6
    2. winnerPoints are calculated based on --> base * stake
    3. Losses are harvested based on --> (margin of error - 5%) * stake
    */
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    /// @param _user the user that harvest is being called on
    function _harvest(address _user, address nftAddress, uint tokenid) internal {
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nonce][nftAddress][tokenid];
        uint finalAppraisal = finalAppraisalValue[nftNonce[nftAddress][tokenid]][nftAddress][tokenid];
        sessionMap.nftVotes[_user].base = 
            PostSessionLibrary.calculateBase(
                finalAppraisal, 
                sessionMap.nftVotes[_user].appraisal,
                sessionCheck.spread
            );
        // sessionMap.voterCheck[_user] = 3;
        uint weight = sqrtLibrary.sqrt(sessionMap.nftVotes[_user].stake/sessionCore.lowestStake);
        if(sessionMap.nftVotes[_user].base > 0) {
            sessionCore.totalWinnerPoints += sessionMap.nftVotes[_user].base * weight;
            sessionMap.winnerPoints[_user] = sessionMap.nftVotes[_user].base * weight;
            sessionCheck.correct += weight;
        }
        else if(
            sessionMap.nftVotes[_user].appraisal < finalAppraisal + sessionCheck.finalStdev 
            && sessionMap.nftVotes[_user].appraisal > finalAppraisal - sessionCheck.finalStdev
        ) {
            sessionMap.secondaryPoint[_user] += sessionMap.nftVotes[_user].stake;
            sessionCheck.secondaryPoints += sessionMap.nftVotes[_user].stake;
            sessionCheck.incorrect += weight;
        }
        else {
            sessionCheck.incorrect += weight;
        }
        
        sessionMap.amountHarvested[_user] = PostSessionLibrary.harvest( 
            sessionMap.nftVotes[_user].stake, 
            sessionMap.nftVotes[_user].appraisal,
            finalAppraisalValue[nftNonce[nftAddress][tokenid]][nftAddress][tokenid],
            sessionCheck.riskFactor,
            sessionCheck.spread
        );

        sessionMap.nftVotes[_user].stake -= sessionMap.amountHarvested[_user];
        uint commission = sessionMap.amountHarvested[_user] * Treasury.commissionRate() / 10000;
        sessionCore.totalSessionStake -= commission;
        sessionMap.amountHarvested[_user] -= commission;
        sessionCore.totalProfit += sessionMap.amountHarvested[_user];
        CreditVault(payable(creditStore)).sendToTreasury(commission);
    }


    /// @notice User claims principal stake along with any earned profits in ETH or ABC form
    /**
    @dev 
    1. Calculates user principal return value
    2. Enacts sybil defense mechanism
    3. Edits totalProfits and totalSessionStake to reflect claim
    5. Pays out principal
    6. Adds profit credit to profitStored
    */
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    /// @param _user the user that harvest is being called on
    function _claim(address _user, address nftAddress, uint tokenid) internal {
        uint nonce = nftNonce[nftAddress][tokenid];
        VotingSessionCore storage sessionCore = NftSessionCore[nonce][nftAddress][tokenid];
        VotingSessionChecks storage sessionCheck = NftSessionCheck[nonce][nftAddress][tokenid];
        VotingSessionMapping storage sessionMap = NftSessionMap[nonce][nftAddress][tokenid];
        // if (sessionCheck.timeFinalAppraisalSet == 0) {
        //     revert();
        // }
        // require(
        //         (block.timestamp > sessionCore.endTime + 2 * sessionCore.votingTime / 3 || sessionCheck.sessionProgression == 4)
        //         && sessionCheck.sessionProgression <= 4
        //     );
        // sessionMap.voterCheck[_user] = 4;
        uint principalReturn;
        if(sessionCheck.correct * 100 / (sessionCheck.correct + sessionCheck.incorrect) >= (95-sessionCheck.spread)) {
            principalReturn += sessionMap.nftVotes[_user].stake + sessionMap.amountHarvested[_user];
        }
        else {
            principalReturn += sessionMap.nftVotes[_user].stake;
        }
        uint payout;
        if(sessionCheck.secondaryPoints + sessionCore.totalWinnerPoints == 0) {
            payout = 0;
        }
        else if (sessionCore.totalWinnerPoints == 0) {
            payout = sessionCore.totalProfit * sessionMap.secondaryPoint[_user] / sessionCheck.secondaryPoints;
            sessionCheck.secondaryPoints -= sessionMap.secondaryPoint[_user];
            sessionMap.secondaryPoint[_user] = 0;
        }
        else {
            payout = sessionCore.totalProfit * sessionMap.winnerPoints[_user] / sessionCore.totalWinnerPoints;
            sessionCore.totalWinnerPoints -= sessionMap.winnerPoints[_user];
            sessionMap.winnerPoints[_user] = 0;
        }
        sessionCore.totalProfit -= payout;
        sessionCore.totalSessionStake -= principalReturn;
        CreditVault(payable(creditStore)).increasePrincipalStored(_user, principalReturn);
        CreditVault(payable(creditStore)).updateProfitStored(_user, payout);
    }

    /* ======== VIEW FUNCTIONS ======== */

    /// @notice returns the status of the session in question
    /// @param nftAddress NFT contract address of NFT being appraised
    /// @param tokenid NFT tokenid of NFT being appraised
    function getStatus(address nftAddress, uint tokenid) view public returns(uint) {
        return NftSessionCheck[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].sessionProgression;
    }

    // /// @notice check the users status in terms of session interaction
    // /// @param nftAddress NFT contract address of NFT being appraised
    // /// @param tokenid NFT tokenid of NFT being appraised
    // /// @param _user appraisooooor who's session progress is of interest
    function getVoterCheck(address nftAddress, uint tokenid, address _user) view external returns(uint) {
        return NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].voterCheck[_user];
    }

    /* ======== FALLBACK FUNCTIONS ======== */

    receive() external payable {}
    fallback() external payable {}

    /* ======== MODIFIERS ======== */

    /// @notice stop users from being able to create multiple sessions for the same NFT at the same time
    modifier stopOverwrite(
        address nftAddress, 
        uint tokenid
    ) {
        require(
            nftNonce[nftAddress][tokenid] == 0 
            || getStatus(nftAddress, tokenid) == 5
            || block.timestamp > NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].endTime + 2 * NftSessionCore[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].votingTime
        );
        _;
    }
    
    /// @notice makes sure that a user that submits a vote satisfies the proper voting parameters
    modifier properVote(
        address nftAddress,
        uint tokenid,
        uint stake
    ) {
        require(
            NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].voterCheck[msg.sender] == 0
            && stake >= 0.009 ether
        );
        _;
    }
    
    /// @notice checks the participation of the msg.sender 
    modifier checkParticipation(
        address nftAddress,
        uint tokenid
    ) {
        require(NftSessionMap[nftNonce[nftAddress][tokenid]][nftAddress][tokenid].voterCheck[msg.sender] > 0);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
}