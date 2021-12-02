// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import './SafeOwnable.sol';
import 'hardhat/console.sol';

abstract contract Random is Context, SafeOwnable {
    using SafeMath for uint256;
    
    uint private requestId = 0;
    mapping(bytes32 => bool) internal randomRequest;
    mapping(bytes32 => uint) internal randomResult;
    address public linkAccessor;

    event RequestRandom(bytes32 requestId, uint256 seed);
    event FulfillRandom(bytes32 requestId, uint256 randomness);
    event NewLinkAccessor(address oldLinkAccessor, address newLinkAccessor);

    constructor(address _linkAccessor) {
        require(_linkAccessor != address(0), "_linkAccessor is zero");
        linkAccessor = _linkAccessor;
        emit NewLinkAccessor(address(0), linkAccessor);
    }

    function setLinkAccessor(address _linkAccessor) external onlyOwner {
        require(_linkAccessor != address(0), "_linkAccessor is zero");
        emit NewLinkAccessor(linkAccessor, _linkAccessor);
        linkAccessor = _linkAccessor; 
    }

    function _requestRandom(uint256 _seed) internal returns (bytes32) {
        bytes32 _requestId = bytes32(requestId);
        emit RequestRandom(_requestId, _seed);
        randomRequest[_requestId] = true;
        requestId = requestId.add(1);
        return _requestId;
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) external {
        require(_msgSender() == address(linkAccessor), "Only linkAccessor can call");
        _randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, block.coinbase, block.number, _randomness)));
        randomResult[_requestId] = _randomness; 
        delete randomRequest[bytes32(requestId)];
        emit FulfillRandom(_requestId, _randomness);
        finishRandom(_requestId);
    }

    function finishRandom(bytes32 _requestId) internal virtual {
        delete randomResult[_requestId];
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

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/utils/Context.sol';

/**
 * This is a contract copied from 'Ownable.sol'
 * It has the same fundation of Ownable, besides it accept pendingOwner for mor Safe Use
 */
abstract contract SafeOwnable is Context {
    address private _owner;
    address private _pendingOwner;

    event ChangePendingOwner(address indexed previousPendingOwner, address indexed newPendingOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (address _ownerAddress) {
        if (_ownerAddress == address(0)) {
            _ownerAddress = _msgSender();
        }
        _owner = _ownerAddress;
        emit OwnershipTransferred(address(0), _ownerAddress);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyPendingOwner() {
        require(pendingOwner() == _msgSender(), "Ownable: caller is not the pendingOwner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
        if (_pendingOwner != address(0)) {
            emit ChangePendingOwner(_pendingOwner, address(0));
            _pendingOwner = address(0);
        }
    }

    function setPendingOwner(address pendingOwner_) public virtual onlyOwner {
        require(pendingOwner_ != address(0), "Ownable: pendingOwner is the zero address");
        emit ChangePendingOwner(_pendingOwner, pendingOwner_);
        _pendingOwner = pendingOwner_;
    }

    function acceptOwner() public virtual onlyPendingOwner {
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
        emit ChangePendingOwner(_pendingOwner, address(0));
        _pendingOwner = address(0);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '../core/SafeOwnable.sol';
import 'hardhat/console.sol';
import '../core/Random.sol';

contract RoomExtention is SafeOwnable {
    using SafeMath for uint256;
    using Strings for uint256;

    event NewRoomExtention(address roomManager, uint rid, bytes32 roomId, bytes32 name, string rules, string logo, uint position, bool display);

    struct RoomInfo {
        uint256 rid;
        bytes32 roomId;
        bytes32 name;
        string rules;
        string logo;
        uint position;
        bool display;
    }

    mapping(uint256 => RoomInfo) public roomInfo;
    address public roomManager;

    constructor(address _roomManager) SafeOwnable(msg.sender) {
        roomManager = _roomManager;
    }

    function addOrSetRoomInfo(
        uint rid, bytes32 roomId, bytes32 name, string memory rules, string memory logo, uint position, bool display
    ) external onlyOwner {
        RoomInfo storage room = roomInfo[rid];
        room.rid = rid;
        room.roomId = roomId;
        room.name = name;
        room.rules = rules;
        room.logo = logo;
        room.position = position;
        room.display = display;
        emit NewRoomExtention(roomManager, rid, roomId, name, rules, logo, position, display);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import "../interfaces/IP2EFactory.sol";
import "../libraries/P2ELibrary.sol";
import "../interfaces/IP2EPair.sol";
import '../interfaces/IOracle.sol';
import '../token/TokenLocker.sol';
import "../core/SafeOwnable.sol";
import '../token/P2EToken.sol';
import 'hardhat/console.sol';

contract SwapMining is SafeOwnable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _whitelist;

    event NewTokenLocker(TokenLocker oldTokenLocker, TokenLocker newTokenLocker);

    // P2E tokens created per block
    uint256 public rewardPerBlock;
    // The block number when P2E mining starts.
    uint256 public startBlock;
    // How many blocks are halved
    uint256 public halvingPeriod = 5256000;
    // Total allocation points
    uint256 public totalAllocPoint = 0;
    IOracle public oracle;
    // router address
    address public router;
    // factory address
    IP2EFactory public factory;
    // token address
    P2EToken public rewardToken;
    // Calculate price based on BUSD
    address public targetToken;
    // pair corresponding pid
    mapping(address => uint256) public pairOfPid;
    TokenLocker public tokenLocker;

    function setTokenLocker(TokenLocker _tokenLocker) external onlyOwner {
        //require(_tokenLocker != address(0), "token locker address is zero"); 
        emit NewTokenLocker(tokenLocker, _tokenLocker);
        tokenLocker = _tokenLocker;
    }

    constructor(
        P2EToken _rewardToken,
        IP2EFactory _factory,
        IOracle _oracle,
        address _router,
        address _targetToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock
    ) SafeOwnable(msg.sender) {
        require(address(_rewardToken) != address(0), "illegal address");
        rewardToken = _rewardToken;
        require(address(_factory) != address(0), "illegal address");
        factory = _factory;
        require(address(_oracle) != address(0), "illegal address");
        oracle = _oracle;
        require(_router != address(0), "illegal address");
        router = _router;
        targetToken = _targetToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
    }

    struct UserInfo {
        uint256 quantity;       // How many LP tokens the user has provided
        uint256 blockNumber;    // Last transaction block
    }

    struct PoolInfo {
        address pair;           // Trading pairs that can be mined
        uint256 quantity;       // Current amount of LPs
        uint256 totalQuantity;  // All quantity
        uint256 allocPoint;     // How many allocation points assigned to this pool
        uint256 allocP2EAmount; // How many P2Es
        uint256 lastRewardBlock;// Last transaction block
    }

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;


    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }


    function addPair(uint256 _allocPoint, address _pair, bool _withUpdate) public onlyOwner {
        require(_pair != address(0), "_pair is the zero address");
        if (_withUpdate) {
            massMintPools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
        pair : _pair,
        quantity : 0,
        totalQuantity : 0,
        allocPoint : _allocPoint,
        allocP2EAmount : 0,
        lastRewardBlock : lastRewardBlock
        }));
        pairOfPid[_pair] = poolLength() - 1;
    }

    // Update the allocPoint of the pool
    function setPair(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massMintPools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Set the number of token produced by each block
    function setP2EPerBlock(uint256 _newPerBlock) public onlyOwner {
        massMintPools();
        rewardPerBlock = _newPerBlock;
    }

    // Only tokens in the whitelist can be mined P2E
    function addWhitelist(address _addToken) public onlyOwner returns (bool) {
        require(_addToken != address(0), "SwapMining: token is the zero address");
        return EnumerableSet.add(_whitelist, _addToken);
    }

    function delWhitelist(address _delToken) public onlyOwner returns (bool) {
        require(_delToken != address(0), "SwapMining: token is the zero address");
        return EnumerableSet.remove(_whitelist, _delToken);
    }

    function getWhitelistLength() public view returns (uint256) {
        return EnumerableSet.length(_whitelist);
    }

    function isWhitelist(address _token) public view returns (bool) {
        return EnumerableSet.contains(_whitelist, _token);
    }

    function getWhitelist(uint256 _index) public view returns (address){
        require(_index <= getWhitelistLength() - 1, "SwapMining: index out of bounds");
        return EnumerableSet.at(_whitelist, _index);
    }

    function setHalvingPeriod(uint256 _block) public onlyOwner {
        halvingPeriod = _block;
    }

    function setRouter(address newRouter) public onlyOwner {
        require(newRouter != address(0), "SwapMining: new router is the zero address");
        router = newRouter;
    }

    function setOracle(IOracle _oracle) public onlyOwner {
        require(address(_oracle) != address(0), "SwapMining: new oracle is the zero address");
        oracle = _oracle;
    }

    // At what phase
    function phase(uint256 blockNumber) public view returns (uint256) {
        if (halvingPeriod == 0) {
            return 0;
        }
        if (blockNumber > startBlock) {
            return (blockNumber.sub(startBlock).sub(1)).div(halvingPeriod);
        }
        return 0;
    }

    function phase() public view returns (uint256) {
        return phase(block.number);
    }

    function reward(uint256 blockNumber) public view returns (uint256) {
        uint256 _phase = phase(blockNumber);
        return rewardPerBlock.div(2 ** _phase);
    }

    function reward() public view returns (uint256) {
        return reward(block.number);
    }

    // Rewards for the current block
    function getP2EReward(uint256 _lastRewardBlock) public view returns (uint256) {
        require(_lastRewardBlock <= block.number, "SwapMining: must little than the current block number");
        uint256 blockReward = 0;
        uint256 n = phase(_lastRewardBlock);
        uint256 m = phase(block.number);
        // If it crosses the cycle
        while (n < m) {
            n++;
            // Get the last block of the previous cycle
            uint256 r = n.mul(halvingPeriod).add(startBlock);
            // Get rewards from previous periods
            blockReward = blockReward.add((r.sub(_lastRewardBlock)).mul(reward(r)));
            _lastRewardBlock = r;
        }
        blockReward = blockReward.add((block.number.sub(_lastRewardBlock)).mul(reward(block.number)));
        return blockReward;
    }

    // Update all pools Called when updating allocPoint and setting new blocks
    function massMintPools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            mint(pid);
        }
    }

    function mint(uint256 _pid) public returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return false;
        }
        uint256 blockReward = getP2EReward(pool.lastRewardBlock);
        if (blockReward <= 0) {
            return false;
        }
        // Calculate the rewards obtained by the pool based on the allocPoint
        uint256 gibxReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);
        // Increase the number of tokens in the current pool
        pool.allocP2EAmount = pool.allocP2EAmount.add(gibxReward);
        pool.lastRewardBlock = block.number;
        rewardToken.mint(address(this), gibxReward);
        return true;
    }

    modifier onlyRouter() {
        require(msg.sender == router, "SwapMining: caller is not the router");
        _;
    }

    // swapMining only router
    function swap(address account, address input, address output, uint256 amount) public onlyRouter returns (bool) {
        require(account != address(0), "SwapMining: taker swap account is the zero address");
        require(input != address(0), "SwapMining: taker swap input is the zero address");
        require(output != address(0), "SwapMining: taker swap output is the zero address");

        if (poolLength() <= 0) {
            return false;
        }

        if (!isWhitelist(input) || !isWhitelist(output)) {
            return false;
        }

        address pair = P2ELibrary.pairFor(address(factory), input, output);
        PoolInfo storage pool = poolInfo[pairOfPid[pair]];
        // If it does not exist or the allocPoint is 0 then return
        if (pool.pair != pair || pool.allocPoint <= 0) {
            return false;
        }

        uint256 quantity = getQuantity(output, amount, targetToken);
        if (quantity <= 0) {
            return false;
        }

        mint(pairOfPid[pair]);

        pool.quantity = pool.quantity.add(quantity);
        pool.totalQuantity = pool.totalQuantity.add(quantity);
        UserInfo storage user = userInfo[pairOfPid[pair]][account];
        user.quantity = user.quantity.add(quantity);
        user.blockNumber = block.number;
        return true;
    }

    function getQuantity(address outputToken, uint256 outputAmount, address anchorToken) public view returns (uint256) {
        uint256 quantity = 0;
        if (outputToken == anchorToken) {
            quantity = outputAmount;
        } else if (IP2EFactory(factory).getPair(outputToken, anchorToken) != address(0)) {
            quantity = IOracle(oracle).consult(outputToken, outputAmount, anchorToken);
        } else {
            uint256 length = getWhitelistLength();
            for (uint256 index = 0; index < length; index++) {
                address intermediate = getWhitelist(index);
                if (factory.getPair(outputToken, intermediate) != address(0) && factory.getPair(intermediate, anchorToken) != address(0)) {
                    uint256 interQuantity = IOracle(oracle).consult(outputToken, outputAmount, intermediate);
                    quantity = IOracle(oracle).consult(intermediate, interQuantity, anchorToken);
                    break;
                }
            }
        }
        return quantity;
    }

    // The user withdraws all the transaction rewards of the pool
    function takerWithdraw() public {
        uint256 userSub;
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            UserInfo storage user = userInfo[pid][msg.sender];
            if (user.quantity > 0) {
                mint(pid);
                // The reward held by the user in this pool
                uint256 userReward = pool.allocP2EAmount.mul(user.quantity).div(pool.quantity);
                pool.quantity = pool.quantity.sub(user.quantity);
                pool.allocP2EAmount = pool.allocP2EAmount.sub(userReward);
                user.quantity = 0;
                user.blockNumber = block.number;
                userSub = userSub.add(userReward);
            }
        }
        if (userSub <= 0) {
            return;
        }
        //rewardToken.transfer(msg.sender, userSub);
        if (address(tokenLocker) == address(0)) {
            safeP2ETransfer(msg.sender, userSub);
        } else {
            rewardToken.approve(address(tokenLocker), userSub);
            tokenLocker.addReceiver(msg.sender, userSub);
        }
    }

    // Get rewards from users in the current pool
    function getUserReward(uint256 _pid, address _user) public view returns (uint256, uint256){
        require(_pid <= poolInfo.length - 1, "SwapMining: Not find this pool");
        uint256 userSub;
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        if (user.quantity > 0) {
            uint256 blockReward = getP2EReward(pool.lastRewardBlock);
            uint256 gibxReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);
            userSub = userSub.add((pool.allocP2EAmount.add(gibxReward)).mul(user.quantity).div(pool.quantity));
        }
        //P2E available to users, User transaction amount
        return (userSub, user.quantity);
    }

    // Get details of the pool
    function getPoolInfo(uint256 _pid) public view returns (address, address, uint256, uint256, uint256, uint256){
        require(_pid <= poolInfo.length - 1, "SwapMining: Not find this pool");
        PoolInfo memory pool = poolInfo[_pid];
        address token0 = IP2EPair(pool.pair).token0();
        address token1 = IP2EPair(pool.pair).token1();
        uint256 gibxAmount = pool.allocP2EAmount;
        uint256 blockReward = getP2EReward(pool.lastRewardBlock);
        uint256 gibxReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);
        gibxAmount = gibxAmount.add(gibxReward);
        //token0,token1,Pool remaining reward,Total /Current transaction volume of the pool
        return (token0, token1, gibxAmount, pool.totalQuantity, pool.quantity, pool.allocPoint);
    }

    function ownerWithdraw(address _to, uint256 _amount) public onlyOwner {
        safeP2ETransfer(_to, _amount);
    }

    function safeP2ETransfer(address _to, uint256 _amount) internal {
        uint256 balance = rewardToken.balanceOf(address(this));
        if (_amount > balance) {
            _amount = balance;
        }
        rewardToken.transfer(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IP2EFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function expectPairFor(address token0, address token1) external view returns (address);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '../interfaces/IP2EPair.sol';
import '../interfaces/IP2EFactory.sol';

library P2ELibrary {
    using SafeMath for uint;

    uint256 constant SWAP_FEE = 3;
    uint256 constant SWAP_FEE_BASE = 1000;
    uint256 constant SWAP_FEE_LP = 3;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'P2ELibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'P2ELibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                IP2EFactory(factory).INIT_CODE_PAIR_HASH()
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IP2EPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'P2ELibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'P2ELibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'P2ELibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'P2ELibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(SWAP_FEE_BASE.sub(SWAP_FEE));
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(SWAP_FEE_BASE).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'P2ELibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'P2ELibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(SWAP_FEE_BASE);
        uint denominator = reserveOut.sub(amountOut).mul(SWAP_FEE_BASE.sub(SWAP_FEE));
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'P2ELibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'P2ELibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IP2EPair {
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

pragma solidity 0.7.6;

interface IOracle {
    function update(address tokenA, address tokenB) external;

    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../interfaces/IP2EToken.sol';
import '../core/SafeOwnable.sol';
import 'hardhat/console.sol';

contract TokenLocker is ERC20, SafeOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event NewReceiver(address receiver, uint sendAmount, uint totalReleaseAmount, uint lastReleaseAt);
    event ReleaseToken(address receiver, uint releaseAmount, uint nextReleaseAmount, uint nextReleaseBlockNum);

    uint256 public immutable FIRST_LOCK_SECONDS;
    uint256 public immutable LOCK_PERIOD;
    uint256 public immutable LOCK_PERIOD_NUM;

    IERC20 public immutable token;
    uint256 public totalLockAmount;

    struct ReleaseInfo {
        address receiver;               //who will receive the release token
        uint256 totalReleaseAmount;     //the amount of the token total released for the receiver;
        bool firstUnlock;               //first unlock already done
        uint256 lastReleaseAt;          //the last seconds the the receiver get the released token
        uint256 alreadyReleasedAmount;  //the amount the token already released for the reciever
    }
    mapping(address => ReleaseInfo) public receivers;
    mapping(address => uint) public userPending;

    constructor(
        address _owner, string memory _name, string memory _symbol, IERC20 _token, uint256 _firstLockSeconds, uint256 _lockPeriod, uint256 _lockPeriodNum
    ) ERC20(_name, _symbol) SafeOwnable(_owner) {
        require(address(_token) != address(0), "token address is zero");
        token = _token;
        FIRST_LOCK_SECONDS = _firstLockSeconds;
        LOCK_PERIOD = _lockPeriod;
        LOCK_PERIOD_NUM = _lockPeriodNum;
    }

    uint public constant MAX_CLAIM_NUM = 100;

    function addReceiver(address _receiver, uint256 _amount) external onlyOwner {
        console.log("amount: ", _amount);
        for (uint i = 0; i < MAX_CLAIM_NUM; i ++) {
            if (claimInternal(_receiver) == 0) {
                break;
            }
        }
        console.log("userPending: ", userPending[_receiver]);
        require(_receiver != address(0), "receiver address is zero");
        require(_amount > 0, "release amount is zero");
        totalLockAmount = totalLockAmount.add(_amount);
        uint totalReleaseAmount = 0;
        ReleaseInfo storage receiver = receivers[_receiver];
        if (receiver.receiver == address(0)) {
            totalReleaseAmount = receiver.totalReleaseAmount.sub(receiver.alreadyReleasedAmount).add(_amount);
            receiver.receiver = _receiver;
            receiver.totalReleaseAmount = totalReleaseAmount;
            receiver.firstUnlock = false;
            receiver.lastReleaseAt = block.timestamp;
            receiver.alreadyReleasedAmount = 0;
            token.safeTransferFrom(msg.sender, address(this), _amount);
            _mint(_receiver, _amount);
        } else {
            uint releaseAmount = _amount.div(LOCK_PERIOD_NUM); 
            console.log("releaseAmount: ", releaseAmount);
            userPending[_receiver] = userPending[_receiver].add(releaseAmount);
            uint remainAmount = _amount.sub(releaseAmount);
            totalReleaseAmount = receiver.totalReleaseAmount.sub(receiver.alreadyReleasedAmount).add(remainAmount);
            receiver.totalReleaseAmount = totalReleaseAmount;
            receiver.lastReleaseAt = block.timestamp;
            receiver.alreadyReleasedAmount = 0;
            token.safeTransferFrom(msg.sender, address(this), _amount);
            _mint(_receiver, _amount);
        }
        emit NewReceiver(_receiver, _amount, totalReleaseAmount, receiver.lastReleaseAt);
    }

    function pending(address _receiver) public view returns (uint256, uint256, uint256) {
        ReleaseInfo storage receiver = receivers[_receiver];
        if (_receiver != receiver.receiver) {
            return (0, 0, 0);
        }
        uint current = block.timestamp;
        uint lastClaim = receiver.lastReleaseAt;
        bool firstUnlock = receiver.firstUnlock;
        uint pendingAmount = 0;
        while (true) {
            if (!firstUnlock) {
                lastClaim = lastClaim + FIRST_LOCK_SECONDS;
                firstUnlock = true;
            } else {
                lastClaim = lastClaim + LOCK_PERIOD;
            }
            if (current >= lastClaim) {
                uint currentPending = receiver.totalReleaseAmount.div(LOCK_PERIOD_NUM);
                if (receiver.totalReleaseAmount.sub(receiver.alreadyReleasedAmount) > currentPending.add(pendingAmount)) {
                    pendingAmount = pendingAmount + currentPending;
                } else {
                    pendingAmount = receiver.totalReleaseAmount.sub(receiver.alreadyReleasedAmount);
                    break;
                }
            } else {
                break;
            }
        }
        uint remain = receiver.totalReleaseAmount.sub(receiver.alreadyReleasedAmount).sub(pendingAmount);
        pendingAmount = pendingAmount + userPending[_receiver];
        return (lastClaim, pendingAmount, remain);
    }

    //response1: the timestamp for next release
    //response2: the amount for next release
    //response3: the total amount already released
    //response4: the remain amount for the receiver to release
    function getReleaseInfo(address _receiver) public view returns (uint256 nextReleaseAt, uint256 nextReleaseAmount, uint256 alreadyReleaseAmount, uint256 remainReleaseAmount) {
        ReleaseInfo storage receiver = receivers[_receiver];
        require(_receiver != address(0), "receiver not exist");
        if (_receiver != receiver.receiver) {
            return (0, 0, 0, 0);
        }
        if (!receiver.firstUnlock) {
            nextReleaseAt = receiver.lastReleaseAt + FIRST_LOCK_SECONDS;
        } else {
            nextReleaseAt = receiver.lastReleaseAt + LOCK_PERIOD;
        }
        nextReleaseAmount = receiver.totalReleaseAmount.div(LOCK_PERIOD_NUM);
        alreadyReleaseAmount = receiver.alreadyReleasedAmount;
        remainReleaseAmount = receiver.totalReleaseAmount.sub(receiver.alreadyReleasedAmount);
        if (nextReleaseAmount > remainReleaseAmount) {
            nextReleaseAmount = remainReleaseAmount;
        }
    }

    function claimInternal(address _receiver) internal returns(uint) {
        (uint nextReleaseSeconds, uint nextReleaseAmount, , ) = getReleaseInfo(_receiver);
        if (block.timestamp < nextReleaseSeconds || nextReleaseAmount <= 0) {
            return 0;
        }
        ReleaseInfo storage receiver = receivers[_receiver];
        if (!receiver.firstUnlock) {
            receiver.firstUnlock = true; 
        }
        receiver.lastReleaseAt = nextReleaseSeconds;
        receiver.alreadyReleasedAmount = receiver.alreadyReleasedAmount.add(nextReleaseAmount);
        totalLockAmount = totalLockAmount.sub(nextReleaseAmount);
        userPending[_receiver] = userPending[_receiver].add(nextReleaseAmount);
        (uint nextNextReleaseSeconds, uint nextNextReleaseAmount, , ) = getReleaseInfo(_receiver);
        emit ReleaseToken(_receiver, nextReleaseAmount, nextNextReleaseSeconds, nextNextReleaseAmount);
        return nextReleaseAmount;
    }

    function claim(address _receiver) external {
        for (uint i = 0; i < MAX_CLAIM_NUM; i ++) {
            if (claimInternal(_receiver) == 0) {
                break;
            }
        }
        if (userPending[_receiver] > 0) {
            uint _userPending = userPending[_receiver];
            userPending[_receiver] = 0;
            _burn(_receiver, _userPending);
            token.safeTransfer(_receiver, _userPending);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/ERC20Capped.sol';
import '../core/SafeOwnable.sol';

contract P2EToken is ERC20Capped, SafeOwnable {
    using SafeMath for uint256;

    event MinterChanged(address indexed minter, uint maxAmount);

    uint256 public constant MAX_SUPPLY = 10 * 10 ** 8 * 10 ** 18;
    mapping(address => uint) public minters;

    constructor() ERC20Capped(MAX_SUPPLY) ERC20("P2E Token", "P2E") SafeOwnable(msg.sender) {
        addMinter(msg.sender, uint(-1));
    }

    function addMinter(address _minter, uint _maxAmount) public onlyOwner {
        require(_minter != address(0), "illegal minter");
        require(minters[_minter] == 0, "already minter");
        minters[_minter] = _maxAmount;
        emit MinterChanged(_minter, _maxAmount);
    }

    function delMinter(address _minter) public onlyOwner {
        require(_minter != address(0), "illegal minter");
        require(minters[_minter] > 0, "not minter");
        delete minters[_minter];
        emit MinterChanged(_minter, 0);
    }

    modifier onlyMinter(uint _amount) {
        require(minters[msg.sender] >= _amount, "caller is not minter or not enough");
        _;
    }

    function mint(address to, uint256 amount) public onlyMinter(amount) returns (uint) {
        if (amount > MAX_SUPPLY.sub(totalSupply())) {
            return 0;
        }
        if (minters[msg.sender] < amount) {
            amount = minters[msg.sender];
        }
        minters[msg.sender] = minters[msg.sender].sub(amount);
        _mint(to, amount);
        return amount; 
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IP2EToken is IERC20 {

    function mint(address to, uint256 amount) external returns (uint);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    using SafeMath for uint256;

    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (uint256 cap_) internal {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) { // When minting tokens
            require(totalSupply().add(amount) <= cap(), "ERC20Capped: cap exceeded");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../token/TokenLocker.sol';
import '../core/SafeOwnable.sol';
import "../token/P2EToken.sol";
import "./P2EBar.sol";

contract PoolChef is SafeOwnable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;     
        uint256 rewardDebt; 
    }

    struct PoolInfo {
        IERC20 token;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that CAKEs distribution occurs.
        uint256 accP2EPerShare; // Accumulated CAKEs per share, times 1e12. See below.
    }

    P2EToken public rewardToken;
    P2EBar public bar;
    uint256 public rewardPerBlock;
    uint256 public BONUS_MULTIPLIER = 1;

    PoolInfo[] public poolInfo;
    mapping(address => uint256) public pidOfToken;
    mapping(address => bool) public existToken;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    uint256 public totalAllocPoint = 0;
    uint256 public startBlock;
    TokenLocker public tokenLocker;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event NewRewardPerBlock(uint oldReward, uint newReward);
    event NewMultiplier(uint oldMultiplier, uint newMultiplier);
    event NewTokenLocker(TokenLocker oldTokenLocker, TokenLocker newTokenLocker);

    modifier validatePoolByPid(uint256 _pid) {
        require (_pid < poolInfo.length, "Pool does not exist");
        _;
    }

    function setTokenLocker(TokenLocker _tokenLocker) external onlyOwner {
        //require(_tokenLocker != address(0), "token locker address is zero"); 
        emit NewTokenLocker(tokenLocker, _tokenLocker);
        tokenLocker = _tokenLocker;
    }

    constructor(
        P2EToken _rewardToken,
        P2EBar _bar,
        uint256 _rewardPerBlock,
        uint256 _startBlock
    ) SafeOwnable(msg.sender) {
        rewardToken = _rewardToken;
        bar = _bar;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
    }

    function updateMultiplier(uint256 multiplierNumber, bool withUpdate) external onlyOwner {
        if (withUpdate) {
            massUpdatePools();
        }
        emit NewMultiplier(BONUS_MULTIPLIER, multiplierNumber);
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function updateRewardPerBlock(uint256 _rewardPerBlock, bool _withUpdate) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        emit NewRewardPerBlock(rewardPerBlock, _rewardPerBlock);
        rewardPerBlock = _rewardPerBlock;
    }


    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(uint256 _allocPoint, IERC20 _token, bool _withUpdate) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        require(address(_token) != address(bar), "can not add bar");
        require(!existToken[address(_token)], "token not exist");
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        pidOfToken[address(_token)] = poolInfo.length;
        poolInfo.push(PoolInfo({
            token: _token,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accP2EPerShare: 0
        }));
        existToken[address(_token)] = true;
    }

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external validatePoolByPid(_pid) onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
        }
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function pendingP2E(uint256 _pid, address _user) external validatePoolByPid(_pid) view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accP2EPerShare = pool.accP2EPerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && tokenSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 reward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accP2EPerShare = accP2EPerShare.add(reward.mul(1e12).div(tokenSupply));
        }
        return user.amount.mul(accP2EPerShare).div(1e12).sub(user.rewardDebt);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 reward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        reward = rewardToken.mint(address(bar), reward);
        pool.accP2EPerShare = pool.accP2EPerShare.add(reward.mul(1e12).div(tokenSupply));
        pool.lastRewardBlock = block.number;
    }

    function safeP2ETransfer(address _to, uint256 _amount) internal {
        bar.safeP2ETransfer(_to, _amount);
    }

    function deposit(uint256 _pid, uint256 _amount) external validatePoolByPid(_pid) nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accP2EPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                if (address(tokenLocker) == address(0)) {
                    safeP2ETransfer(msg.sender, pending);
                } else {
                    safeP2ETransfer(address(this), pending);
                    rewardToken.approve(address(tokenLocker), pending);
                    tokenLocker.addReceiver(msg.sender, pending);
                }
            }
        }
        if (_amount > 0) {
            uint balanceBefore = pool.token.balanceOf(address(this));
            pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint balanceAfter = pool.token.balanceOf(address(this));
            _amount = balanceAfter.sub(balanceBefore);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accP2EPerShare).div(1e12);
        if (pool.token == rewardToken) {
            bar.mint(msg.sender, _amount);
        }
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) external validatePoolByPid(_pid) nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accP2EPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            if (address(tokenLocker) == address(0)) {
                safeP2ETransfer(msg.sender, pending);
            } else {
                safeP2ETransfer(address(this), pending);
                rewardToken.approve(address(tokenLocker), pending);
                tokenLocker.addReceiver(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accP2EPerShare).div(1e12);
        if (pool.token == rewardToken) {
            bar.burn(msg.sender, _amount);
        }
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) external validatePoolByPid(_pid) nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(address(msg.sender), amount);
        if (pool.token == rewardToken) {
            bar.burn(msg.sender, amount);
        }
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "../token/P2EToken.sol";

contract P2EBar is ERC20('P2EBar Token', 'FBAR'), Ownable {
    using SafeMath for uint256;

    P2EToken public gibx;

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function burn(address _from ,uint256 _amount) external onlyOwner {
        _burn(_from, _amount);
    }

    constructor(P2EToken _gibx) {
        require(address(_gibx) != address(0), "illegal gibx");
        gibx = _gibx;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        _moveDelegates(from, to, amount);
    }

    function safeP2ETransfer(address _to, uint256 _amount) external onlyOwner {
        uint256 gibxBal = gibx.balanceOf(address(this));
        if (_amount > gibxBal) {
            gibx.transfer(_to, gibxBal);
        } else {
            gibx.transfer(_to, _amount);
        }
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "CAKE::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "CAKE::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "CAKE::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "CAKE::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying CAKEs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "CAKE::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
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

pragma solidity >=0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../core/Timelock.sol';
import './PoolChef.sol';
import 'hardhat/console.sol';

contract PoolChefTimelock is Timelock {

    mapping(address => bool) public existsPools;
    mapping(address => uint) public pidOfPool;
    mapping(uint256 => bool) public isExcludedPidUpdate;
    PoolChef poolChef;

    struct SetPendingOwnerData {
        address pendingOwner;
        uint timestamp;
        bool exists;
    }
    SetPendingOwnerData setPendingOwnerData;

    constructor(PoolChef poolChef_, address admin_, uint delay_) Timelock(admin_, delay_) {
        require(address(poolChef_) != address(0), "illegal poolChef address");
        require(admin_ != address(0), "illegal admin address");
        poolChef = poolChef_;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");
        _;
    }

    function excludedPidUpdate(uint256 _pid) external onlyAdmin{
        isExcludedPidUpdate[_pid] = true;
    }
    
    function includePidUpdate(uint256 _pid) external onlyAdmin{
        isExcludedPidUpdate[_pid] = false;
    }
    

    function addExistsPools(address pool, uint pid) external onlyAdmin {
        require(existsPools[pool] == false, "Timelock:: pair already exists");
        existsPools[pool] = true;
        pidOfPool[pool] = pid;
    }

    function delExistsPools(address pool) external onlyAdmin {
        require(existsPools[pool] == true, "Timelock:: pair not exists");
        delete existsPools[pool];
        delete pidOfPool[pool];
    }

    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) external onlyAdmin {
        require(address(_lpToken) != address(0), "_lpToken address cannot be 0");
        require(existsPools[address(_lpToken)] == false, "Timelock:: pair already exists");
        _lpToken.balanceOf(msg.sender); //check if is a legal pair
        uint pid = poolChef.poolLength();
        poolChef.add(_allocPoint, _lpToken, false);
        if(_withUpdate){
            massUpdatePools();
        }
        pidOfPool[address(_lpToken)] = pid;
        existsPools[address(_lpToken)] = true;
    }

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyAdmin {
        require(_pid < poolChef.poolLength(), 'Pool does not exist');

        poolChef.set(_pid, _allocPoint, false);
        if(_withUpdate){
            massUpdatePools();
        }
    }

    function massUpdatePools() public {
        uint256 length = poolChef.poolLength();
        for (uint256 pid = 0; pid < length; ++pid) {
            if(!isExcludedPidUpdate[pid]){
                poolChef.updatePool(pid);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/GovernorAlpha.sol
// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Ctrl+f for XXX to see all the modifications.

// XXX: pragma solidity ^0.5.16;
pragma solidity ^0.7.6;

// XXX: import "./SafeMath.sol";
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../interfaces/ISafeOwnable.sol';

contract Timelock {
    using SafeMath for uint;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

    uint public constant GRACE_PERIOD = 14 days;
    uint public constant MINIMUM_DELAY = 6 hours;
    uint public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint public delay;
    bool public admin_initialized;

    mapping (bytes32 => bool) public queuedTransactions;


    constructor(address admin_, uint delay_) {
        require(delay_ >= MINIMUM_DELAY, "Timelock::constructor: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::constructor: Delay must not exceed maximum delay.");

        admin = admin_;
        delay = delay_;
        admin_initialized = false;
    }

    // XXX: function() external payable { }
    receive() external payable { }

    function setDelay(uint delay_) public {
        require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
        require(delay_ >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
        delay = delay_;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public {
        // allows one time setting of admin for deployment purposes
        if (admin_initialized) {
            require(msg.sender == address(this), "Timelock::setPendingAdmin: Call must come from Timelock.");
        } else {
            require(msg.sender == admin, "Timelock::setPendingAdmin: First call must come from admin.");
            admin_initialized = true;
        }
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public returns (bytes32) {
        require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
        require(eta >= getBlockTimestamp().add(delay), "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public {
        require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
        require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }

    function acceptOwner(ISafeOwnable target) external {
        require(msg.sender == admin, "Timelock::acceptAdmin: Call must come from admin.");
        target.acceptOwner();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ISafeOwnable {
    function acceptOwner() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../core/Timelock.sol';
import './MasterChef.sol';
import 'hardhat/console.sol';

contract MasterChefTimelock is Timelock {

    mapping(address => bool) public existsPools;
    mapping(address => uint) public pidOfPool;
    mapping(uint256 => bool) public isExcludedPidUpdate;
    MasterChef masterChef;

    struct SetPendingOwnerData {
        address pendingOwner;
        uint timestamp;
        bool exists;
    }
    SetPendingOwnerData setPendingOwnerData;

    constructor(MasterChef masterChef_, address admin_, uint delay_) Timelock(admin_, delay_) {
        require(address(masterChef_) != address(0), "illegal masterChef address");
        require(admin_ != address(0), "illegal admin address");
        masterChef = masterChef_;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");
        _;
    }

    function excludedPidUpdate(uint256 _pid) external onlyAdmin{
        isExcludedPidUpdate[_pid] = true;
    }
    
    function includePidUpdate(uint256 _pid) external onlyAdmin{
        isExcludedPidUpdate[_pid] = false;
    }
    

    function addExistsPools(address pool, uint pid) external onlyAdmin {
        require(existsPools[pool] == false, "Timelock:: pair already exists");
        existsPools[pool] = true;
        pidOfPool[pool] = pid;
    }

    function delExistsPools(address pool) external onlyAdmin {
        require(existsPools[pool] == true, "Timelock:: pair not exists");
        delete existsPools[pool];
        delete pidOfPool[pool];
    }

    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) external onlyAdmin {
        require(address(_lpToken) != address(0), "_lpToken address cannot be 0");
        require(existsPools[address(_lpToken)] == false, "Timelock:: pair already exists");
        _lpToken.balanceOf(msg.sender); //check if is a legal pair
        uint pid = masterChef.poolLength();
        masterChef.add(_allocPoint, _lpToken, false);
        if(_withUpdate){
            massUpdatePools();
        }
        pidOfPool[address(_lpToken)] = pid;
        existsPools[address(_lpToken)] = true;
    }

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyAdmin {
        require(_pid < masterChef.poolLength(), 'Pool does not exist');

        masterChef.set(_pid, _allocPoint, false);
        if(_withUpdate){
            massUpdatePools();
        }
    }

    function massUpdatePools() public {
        uint256 length = masterChef.poolLength();
        for (uint256 pid = 0; pid < length; ++pid) {
            if(!isExcludedPidUpdate[pid]){
                masterChef.updatePool(pid);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../token/TokenLocker.sol';
import '../core/SafeOwnable.sol';
import "../token/P2EToken.sol";

contract MasterChef is SafeOwnable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;     
        uint256 rewardDebt; 
    }

    struct PoolInfo {
        IERC20 lpToken;           
        uint256 allocPoint;       
        uint256 lastRewardBlock;  
        uint256 accP2EPerShare; 
    }

    P2EToken public rewardToken;
    uint256 public rewardPerBlock;
    uint256 public BONUS_MULTIPLIER;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => uint256) public pidOfLP;
    mapping(address => bool) public existsLP;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when CAKE mining starts.
    uint256 public startBlock;
    TokenLocker public tokenLocker;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event NewRewardPerBlock(uint oldReward, uint newReward);
    event NewMultiplier(uint oldMultiplier, uint newMultiplier);
    event NewPool(uint pid, address lpToken, uint allocPoint, uint totalPoint);
    event NewTokenLocker(TokenLocker oldTokenLocker, TokenLocker newTokenLocker);

    modifier validatePoolByPid(uint256 _pid) {
        require (_pid < poolInfo.length, "Pool does not exist");
        _;
    }

    function setTokenLocker(TokenLocker _tokenLocker) external onlyOwner {
        //require(_tokenLocker != address(0), "token locker address is zero"); 
        emit NewTokenLocker(tokenLocker, _tokenLocker);
        tokenLocker = _tokenLocker;
    }

    constructor(
        P2EToken _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock
    ) SafeOwnable(msg.sender) {
        require(address(_rewardToken) != address(0), "illegal rewardToken");
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        BONUS_MULTIPLIER = 1;
    }

    function updateMultiplier(uint256 multiplierNumber, bool withUpdate) external onlyOwner {
        if (withUpdate) {
            massUpdatePools();
        }
        emit NewMultiplier(BONUS_MULTIPLIER, multiplierNumber);
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function updateP2EPerBlock(uint256 _rewardPerBlock, bool _withUpdate) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        emit NewRewardPerBlock(rewardPerBlock, _rewardPerBlock);
        rewardPerBlock = _rewardPerBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) external onlyOwner {
        require(address(_lpToken) != address(rewardToken), "can not add reward");
        require(!existsLP[address(_lpToken)], "lp already exist");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        pidOfLP[address(_lpToken)] = poolInfo.length;
        existsLP[address(_lpToken)] = true;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accP2EPerShare: 0
        }));
        emit NewPool(poolInfo.length - 1, address(_lpToken), _allocPoint, totalAllocPoint);
    }

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyOwner validatePoolByPid(_pid) {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
        }
        emit NewPool(_pid, address(poolInfo[_pid].lpToken), _allocPoint, totalAllocPoint);
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function pendingP2E(uint256 _pid, address _user) external validatePoolByPid(_pid) view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accP2EPerShare = pool.accP2EPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 rewardReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accP2EPerShare = accP2EPerShare.add(rewardReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accP2EPerShare).div(1e12).sub(user.rewardDebt);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 rewardReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        rewardReward = rewardToken.mint(address(this), rewardReward);
        pool.accP2EPerShare = pool.accP2EPerShare.add(rewardReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount) external nonReentrant validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accP2EPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                if (address(tokenLocker) == address(0)) {
                    safeP2ETransfer(msg.sender, pending);
                } else {
                    rewardToken.approve(address(tokenLocker), pending);
                    tokenLocker.addReceiver(msg.sender, pending);
                }
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accP2EPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accP2EPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            if (address(tokenLocker) == address(0)) {
                safeP2ETransfer(msg.sender, pending);
            } else {
                rewardToken.approve(address(tokenLocker), pending);
                tokenLocker.addReceiver(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accP2EPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) external nonReentrant validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function safeP2ETransfer(address _to, uint256 _amount) internal {
        uint currentBalance = IERC20(rewardToken).balanceOf(address(this));
        if (currentBalance < _amount) {
            _amount = currentBalance;
        }
        IERC20(rewardToken).safeTransfer(_to, _amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../libraries/OracleLibrary.sol";
import "../interfaces/IP2EFactory.sol";
import "../libraries/P2ELibrary.sol";
import '../libraries/FixedPoint.sol';
import "../interfaces/IP2EPair.sol";
import '../core/SafeOwnable.sol';
import '../swap/P2EFactory.sol';
import './Oracle.sol';

contract OracleCaller is SafeOwnable {
    
    event Update(address tokenA, address tokenB);

    Oracle oracle;
    uint constant CRYCLE = 30 minutes;
    P2EFactory factory;

    function setOracle(Oracle _oracle) external {
        oracle = _oracle;
    }

    function setFactory(P2EFactory _factory) external {
        factory = _factory;
    }

    constructor(Oracle _oracle, P2EFactory _factory) SafeOwnable(msg.sender) {
        oracle = _oracle;
        factory = _factory;
    }

    address[] tokenA;
    address[] tokenB;
    address[] pairs;
    mapping(address => bool) pairMap;
    mapping(address => uint) timestamp;

    function pairExists(address pair) external view returns(bool) {
        return pairMap[pair];
    }

    function pairLength() external view returns (uint) {
        return pairs.length;
    }

    function addPair(address _tokenA, address _tokenB) external onlyOwner {
        address pair = factory.expectPairFor(_tokenA, _tokenB);
        require(!pairMap[pair], "pair already exist");
        tokenA.push(_tokenA);
        tokenB.push(_tokenB);
        pairs.push(pair);
        pairMap[pair] = true;
    }

    function delPair(uint _id) external onlyOwner {
        require(_id < tokenA.length && tokenA.length != tokenB.length, "illegal id");
        uint lastIndex = tokenA.length - 1;
        if (lastIndex > _id) {
            tokenA[_id] = tokenA[lastIndex];
            tokenB[_id] = tokenB[lastIndex];
            pairs[_id] = pairs[lastIndex];
        }
        tokenA.pop();
        tokenB.pop();
        pairs.pop();
    }

    function update() external {
        uint current = block.timestamp;
        for(uint i = 0; i < tokenA.length; i ++) {
            if (current - timestamp[pairs[i]] < CRYCLE) {
                continue;
            }
            oracle.update(tokenA[i], tokenB[i]);
            //timestamp[pairs[i]] = current;
            //emit Update(tokenA[i], tokenB[i]);
        }
    }

    /*
    function update(address tokenA, address tokenB) external {
        if (IP2EFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            return;
        }
        address pair = IP2EFactory(factory).expectPairFor(tokenA, tokenB);

        Observation storage observation = pairObservations[pair];
        uint timeElapsed = block.timestamp - observation.timestamp;
        require(timeElapsed >= CYCLE, 'Oracle: PERIOD_NOT_ELAPSED');
        (uint price0Cumulative, uint price1Cumulative,) = OracleLibrary.currentCumulativePrices(pair);
        observation.timestamp = block.timestamp;
        observation.price0Cumulative = price0Cumulative;
        observation.price1Cumulative = price1Cumulative;
    }

    function computeAmountOut(
        uint priceCumulativeStart, uint priceCumulativeEnd,
        uint timeElapsed, uint amountIn
    ) private pure returns (uint amountOut) {
        // overflow is desired.
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
        );
        amountOut = priceAverage.mul(amountIn).decode144();
    }


    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut) {
        address pair = IP2EFactory(factory).expectPairFor(tokenIn, tokenOut);
        Observation storage observation = pairObservations[pair];
        uint timeElapsed = block.timestamp - observation.timestamp;
        (uint price0Cumulative, uint price1Cumulative,) = OracleLibrary.currentCumulativePrices(pair);
        (address token0,) = P2ELibrary.sortTokens(tokenIn, tokenOut);

        if (token0 == tokenIn) {
            return computeAmountOut(observation.price0Cumulative, price0Cumulative, timeElapsed, amountIn);
        } else {
            return computeAmountOut(observation.price1Cumulative, price1Cumulative, timeElapsed, amountIn);
        }
    }
    */
}

// SPDX-License-Identifier: MIT


pragma solidity 0.7.6;

import '../interfaces/IP2EPair.sol';
import './FixedPoint.sol';

library OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IP2EPair(pair).price0CumulativeLast();
        price1Cumulative = IP2EPair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IP2EPair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

// SPDX-License-Identifier: MIT


pragma solidity 0.7.6;

library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '../libraries/P2ELibrary.sol';
import './P2EPair.sol';

contract P2EFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(P2EPair).creationCode));

    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function expectPairFor(address token0, address token1) public view returns (address) {
        return P2ELibrary.pairFor(address(this), token0, token1);
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'P2E: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'P2E: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'P2E: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(P2EPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IP2EPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'P2E: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'P2E: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../libraries/OracleLibrary.sol";
import "../interfaces/IP2EFactory.sol";
import "../libraries/P2ELibrary.sol";
import '../libraries/FixedPoint.sol';
import "../interfaces/IP2EPair.sol";

contract Oracle {
    using FixedPoint for *;
    using SafeMath for uint;

    struct Observation {
        uint timestamp;
        uint price0Cumulative;
        uint price1Cumulative;
    }

    address public immutable factory;
    uint public constant CYCLE = 30 minutes;

    // mapping from pair address to a list of price observations of that pair
    mapping(address => Observation) public pairObservations;

    constructor(address factory_) {
        factory = factory_;
    }


    function update(address tokenA, address tokenB) external {
        if (IP2EFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            return;
        }
        address pair = IP2EFactory(factory).expectPairFor(tokenA, tokenB);

        Observation storage observation = pairObservations[pair];
        uint timeElapsed = block.timestamp - observation.timestamp;
        require(timeElapsed >= CYCLE, 'Oracle: PERIOD_NOT_ELAPSED');
        (uint price0Cumulative, uint price1Cumulative,) = OracleLibrary.currentCumulativePrices(pair);
        observation.timestamp = block.timestamp;
        observation.price0Cumulative = price0Cumulative;
        observation.price1Cumulative = price1Cumulative;
    }


    function computeAmountOut(
        uint priceCumulativeStart, uint priceCumulativeEnd,
        uint timeElapsed, uint amountIn
    ) private pure returns (uint amountOut) {
        // overflow is desired.
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
        );
        amountOut = priceAverage.mul(amountIn).decode144();
    }


    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut) {
        address pair = IP2EFactory(factory).expectPairFor(tokenIn, tokenOut);
        Observation storage observation = pairObservations[pair];
        uint timeElapsed = block.timestamp - observation.timestamp;
        (uint price0Cumulative, uint price1Cumulative,) = OracleLibrary.currentCumulativePrices(pair);
        (address token0,) = P2ELibrary.sortTokens(tokenIn, tokenOut);

        if (token0 == tokenIn) {
            return computeAmountOut(observation.price0Cumulative, price0Cumulative, timeElapsed, amountIn);
        } else {
            return computeAmountOut(observation.price1Cumulative, price1Cumulative, timeElapsed, amountIn);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/math/Math.sol';
import '../interfaces/IP2EFactory.sol';
import '../interfaces/IP2ECallee.sol';
import '../libraries/UQ112x112.sol';
import '../libraries/P2ELibrary.sol';
import '../interfaces/IP2EPair.sol';
import '../libraries/SqrtMath.sol';
import '../token/P2EERC20.sol';

contract P2EPair is P2EERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'P2E: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'P2E: TRANSFER_FAILED');
    }

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

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'P2E: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'P2E: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IP2EFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = SqrtMath.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = SqrtMath.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(P2ELibrary.SWAP_FEE_LP.sub(1)).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = SqrtMath.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'P2E: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        require(_totalSupply != 0, "influence balance");
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'P2E: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'P2E: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'P2E: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'P2E: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IP2ECallee(to).gibxCall(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'P2E: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(P2ELibrary.SWAP_FEE));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(P2ELibrary.SWAP_FEE));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'P2E: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
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

pragma solidity 0.7.6;

interface IP2ECallee {
    function gibxCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

// a library for performing various math operations

library SqrtMath {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '../interfaces/IP2EERC20.sol';

contract P2EERC20 is IP2EERC20 {
    using SafeMath for uint256;

    string public override constant name = 'P2E LPs';
    string public override constant symbol = 'P2E-LP';
    uint8 public override constant decimals = 18;
    uint  public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    bytes32 public override constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    mapping(address => uint) public override nonces;

    constructor() {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(deadline >= block.timestamp, 'P2E: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'P2E: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IP2EERC20 {
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../interfaces/IP2EFactory.sol';
import '../interfaces/IP2ERouter.sol';
import '../libraries/P2ELibrary.sol';
import '../interfaces/IP2EPair.sol';
import '../core/SafeOwnable.sol';
import 'hardhat/console.sol';

contract P2ESwapFee is SafeOwnable {
    using SafeMath for uint;
    using Address for address;
    using SafeERC20 for IERC20;

    event NewBoardroomReceiver(address oldReceiver, address newReceiver);
    event NewReceiver(address receiver, uint percent);
    event NewCaller(address oldCaller, address newCaller);
    event NewSupportToken(address token);
    event DelSupportToken(address token);
    event NewDestroyPercent(uint oldPercent, uint newPercent);

    IP2EFactory public immutable factory;
    IP2ERouter public immutable router;
    address public immutable middleToken;
    address[] public supportTokenList;
    mapping(address => bool) public supportToken;

    address public constant hole = 0x000000000000000000000000000000000000dEaD;  //destroy address
    address[] public receivers;
    mapping(address => uint) public receiverFees;
    uint public totalPercent;
    uint public constant FEE_BASE = 1e6;
    address public immutable ownerReceiver;                                               //any token can be got by this address

    address public caller;
    address public immutable destroyToken;
    uint public destroyPercent;

    function addSupportToken(address _token) external onlyOwner {
        require(_token != address(0), "token address is zero");
        for (uint i = 0; i < supportTokenList.length; i ++) {
            require(supportTokenList[i] != _token, "token already exist");
        }
        //require(!supportToken[_token], "token already supported");
        supportTokenList.push(_token);
        supportToken[_token] = true;
        emit NewSupportToken(_token);
    }

    function delSupportToken(address _token) external onlyOwner {
        uint currentId = 0;
        for (; currentId < supportTokenList.length; currentId ++) {
            if (supportTokenList[currentId] == _token) {
                break;
            }
        }
        require(currentId < supportTokenList.length, "receiver not exist");
        delete supportToken[_token];
        supportTokenList[currentId] = supportTokenList[supportTokenList.length - 1];
        supportTokenList.pop();
        emit DelSupportToken(_token);
    }

    function addReceiver(address _receiver, uint _percent) external onlyOwner {
        require(_receiver != address(0), "receiver address is zero");
        require(_percent <= FEE_BASE, "illegal percent");
        for (uint i = 0; i < receivers.length; i ++) {
            require(receivers[i] != _receiver, "receiver already exist");
        }
        require(totalPercent <= FEE_BASE.sub(_percent), "illegal percent");
        totalPercent = totalPercent.add(_percent);
        receivers.push(_receiver);
        receiverFees[_receiver] = _percent;
        emit NewReceiver(_receiver, _percent);
    }

    function delReceiver(address _receiver) external onlyOwner {
        uint currentId = 0;
        for (; currentId < receivers.length; currentId ++) {
            if (receivers[currentId] == _receiver) {
                break;
            }
        }
        require(currentId < receivers.length, "receiver not exist");
        totalPercent = totalPercent.sub(receiverFees[_receiver]);
        delete receiverFees[_receiver];
        receivers[currentId] = receivers[receivers.length - 1];
        receivers.pop();
        emit NewReceiver(_receiver, 0);
    }

    function setCaller(address _caller) external onlyOwner {
        emit NewCaller(caller, _caller);
        caller = _caller; 
    }

    function setDestroyPercent(uint _percent) external onlyOwner {
        require(_percent <= FEE_BASE, "illegam percent");
        emit NewDestroyPercent(destroyPercent, _percent);
        destroyPercent = _percent;
    }

    modifier onlyOwnerOrCaller() {
        require(owner() == _msgSender() || caller == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor(IP2EFactory _factory, IP2ERouter _router, address _middleToken, address _destroyToken, address _ownerReceiver) SafeOwnable(msg.sender) {
        require(address(_factory) != address(0), "factory address is zero");
        factory = _factory;
        require(address(_router) != address(0), "router address is zero");
        router = _router;
        require(_middleToken != address(0), "middleToken address is zero");
        middleToken = _middleToken;
        require(_destroyToken != address(0), "destroyToken address is zero");
        destroyToken = _destroyToken;
        require(_ownerReceiver != address(0), "ownerReceiver address is zero");
        ownerReceiver = _ownerReceiver;
    }

    function canRemove(IP2EPair pair) internal view returns (bool) {
        address token0 = pair.token0();
        address token1 = pair.token1();
        uint balance0 = IERC20(token0).balanceOf(address(pair));
        uint balance1 = IERC20(token1).balanceOf(address(pair));
        uint totalSupply = pair.totalSupply();
        if (totalSupply == 0) {
            return false;
        }
        uint liquidity = pair.balanceOf(address(this));
        uint amount0 = liquidity.mul(balance0) / totalSupply; // using balances ensures pro-rata distribution
        uint amount1 = liquidity.mul(balance1) / totalSupply; // using balances ensures pro-rata distribution
        if (amount0 == 0 || amount1 == 0) {
            return false;
        }
        return true;
    }

    function doHardwork(address[] calldata pairs, uint minAmount) external onlyOwnerOrCaller {
        for (uint i = 0; i < pairs.length; i ++) {
            IP2EPair pair = IP2EPair(pairs[i]);
            if (!supportToken[pair.token0()] && !supportToken[pair.token1()]) {
                continue;
            }
            uint balance = pair.balanceOf(address(this));
            if (balance == 0) {
                continue;
            }
            if (balance < minAmount) {
                continue;
            }
            if (!canRemove(pair)) {
                continue;
            }
            pair.approve(address(router), balance);
            router.removeLiquidity(
                pair.token0(),
                pair.token1(),
                balance,
                0,
                0,
                address(this),
                block.timestamp
            );
            address swapToken = supportToken[pair.token0()] ? pair.token1() : pair.token0();
            address targetToken = supportToken[pair.token0()] ? pair.token0() : pair.token1();
            address[] memory path = new address[](2);
            path[0] = swapToken; path[1] = targetToken;
            balance = IERC20(swapToken).balanceOf(address(this));
            IERC20(swapToken).approve(address(router), balance);
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                balance,
                0,
                path,
                address(this),
                block.timestamp
            );
        }
    }

    function destroyAll() external onlyOwner {
        address[] memory path = new address[](2);
        uint balance = 0;
        for (uint i = 0; i < supportTokenList.length; i ++) {
            IERC20 token = IERC20(supportTokenList[i]);
            balance = token.balanceOf(address(this));
            if (balance == 0) {
                continue;
            }
            if (address(token) != middleToken) {
                path[0] = address(token);path[1] = middleToken;
                IERC20(token).approve(address(router), balance);
                router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    balance,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
            }
        }
        balance = IERC20(middleToken).balanceOf(address(this));
        uint feeAmount = balance.mul(FEE_BASE.sub(destroyPercent)).div(FEE_BASE);
        for (uint i = 0; i < receivers.length; i ++) {
            uint amount = feeAmount.mul(receiverFees[receivers[i]]).div(FEE_BASE);
            if (amount > 0) {
                IERC20(middleToken).safeTransfer(receivers[i], amount);
            }
        }
        uint destroyAmount = balance.sub(feeAmount);
        path[0] = middleToken;path[1] = destroyToken;
        IERC20(middleToken).approve(address(router), destroyAmount);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            destroyAmount,
            0,
            path,
            hole,
            block.timestamp
        );
    }

    function transferOut(address token, uint amount) external onlyOwner {
        IERC20 erc20 = IERC20(token);
        uint balance = erc20.balanceOf(address(this));
        if (balance < amount) {
            amount = balance;
        }
        require(ownerReceiver != address(0), "ownerReceiver is zero");
        SafeERC20.safeTransfer(erc20, ownerReceiver, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IP2ERouter {
    function factory() external view returns (address);
    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "../core/SafeOwnable.sol";
import '../libraries/TransferHelper.sol';
import '../interfaces/ISwapMining.sol';
import '../interfaces/IP2EFactory.sol';
import '../interfaces/IP2ERouter.sol';
import '../libraries/P2ELibrary.sol';
import '../interfaces/IWETH.sol';

contract P2ERouter is IP2ERouter, SafeOwnable {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WETH;
    address public swapMining;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'P2ERouter: EXPIRED');
        _;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function setSwapMining(address _swapMining) public onlyOwner {
        swapMining = _swapMining;
    }

    constructor(address _factory, address _WETH) SafeOwnable(msg.sender) {
        require(_factory != address(0), "illegal address");
        require(_WETH != address(0), "illegal WETH");
        factory = _factory;
        WETH = _WETH;
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IP2EFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IP2EFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = P2ELibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = P2ELibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'P2ERouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = P2ELibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'P2ERouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = P2ELibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IP2EPair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = P2ELibrary.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IP2EPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = P2ELibrary.pairFor(factory, tokenA, tokenB);
        IP2EPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IP2EPair(pair).burn(to);
        (address token0,) = P2ELibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'P2ERouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'P2ERouter: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = P2ELibrary.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        IP2EPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = P2ELibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IP2EPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
        address pair = P2ELibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IP2EPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = P2ELibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            if (swapMining != address(0)) {
                ISwapMining(swapMining).swap(msg.sender, input, output, amountOut);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? P2ELibrary.pairFor(factory, output, path[i + 2]) : _to;
            IP2EPair(P2ELibrary.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = P2ELibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'P2ERouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, P2ELibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = P2ELibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'P2ERouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, P2ELibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'P2ERouter: INVALID_PATH');
        amounts = P2ELibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'P2ERouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(P2ELibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'P2ERouter: INVALID_PATH');
        amounts = P2ELibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'P2ERouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, P2ELibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'P2ERouter: INVALID_PATH');
        amounts = P2ELibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'P2ERouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, P2ELibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'P2ERouter: INVALID_PATH');
        amounts = P2ELibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'P2ERouter: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(P2ELibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = P2ELibrary.sortTokens(input, output);
            IP2EPair pair = IP2EPair(P2ELibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = P2ELibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            if (swapMining != address(0)) {
                ISwapMining(swapMining).swap(msg.sender, input, output, amountOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? P2ELibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, P2ELibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'P2ERouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        require(path[0] == WETH, 'P2ERouter: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(P2ELibrary.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'P2ERouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'P2ERouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, P2ELibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'P2ERouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return P2ELibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return P2ELibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return P2ELibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return P2ELibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return P2ELibrary.getAmountsIn(factory, amountOut, path);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        SafeERC20.safeApprove(IERC20(token), to, value);
    }

    function safeTransfer(address token, address to, uint value) internal {
        SafeERC20.safeTransfer(IERC20(token), to, value);
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        SafeERC20.safeTransferFrom(IERC20(token), from, to, value);
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ISwapMining {
    function swap(address account, address input, address output, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '../libraries/TransferHelper.sol';
import '../interfaces/IP2EERC1155.sol';
import '../interfaces/IInvite.sol';
import '../interfaces/IWETH.sol';
import '../core/SafeOwnable.sol';
import '../core/Random.sol';
import 'hardhat/console.sol';


contract CollectRoomManager is SafeOwnable, Random {
    using SafeMath for uint256;
    using Strings for uint256;
    using SafeERC20 for IERC20;

    event NewCollectRoom(uint rid, IERC20 rewardToken, uint rewardAmount, uint startSeconds, uint endSeconds);
    event RoomValue(uint rid, IERC20 valueToken, uint valueAmount);
    event RoomRange(uint rid, uint nftType, uint nftID, uint startIndex, uint endIndex);
    event NFTCreated(IP2EERC1155 nftToken, uint rid, uint[] ids, uint[] types, uint[] values);
    event BuyBlindBox(uint rid, address user, IERC20 token, uint num, uint payAmount, uint payFee, bytes32 requestId);
    event OpenBlindBox(uint rid, address to, uint rangeIndex, uint num, bytes32 requestId);
    event Claim(uint rid, address to, uint num, uint reward);
    event NewMaxOpenNum(uint256 oldMaxOpenNum, uint256 newMaxOpenNum);
    event RewardPoolDeposit(uint rid, address from, IERC20 token, uint256 amount);
    event RewardPoolWithdraw(uint rid, address to, IERC20 token, uint256 amount);

    event NewTokenReceiver(address oldReceiver, address newReceiver);
    event NewFeeReceiver(address oldReceiver, address newReceiver);
    event NewRewardReceiver(address oldReceiver, address newReceiver);
    event TokenWithdraw(IERC20 token, uint amount);
    event FeeWithdraw(IERC20 token, uint amount);
    event RewardWithdraw(uint rid, IERC20 token, uint amount);

    uint256 constant MAX_END_INDEX = 1000000;
    uint256 constant VALUE_FEE_BASE = 10000;
    address immutable WETH;
    uint256 constant MAX_INVITE_HEIGHT = 3;
    function getInvitePercent(uint height) internal pure returns (uint) {
        if (height == 0) {
            return 2000;
        } else if (height == 1) {
            return 1000;
        } else if (height == 2) {
            return 500;
        } else {
            return 0;
        }
    }
    uint256 constant PERCENT_BASE = 10000;

    struct RoomInfo {
        IERC20 rewardToken;
        uint256 rewardAmount;
        uint256 startSeconds;
        uint256 endSeconds;
        uint256 rewardPool;
        uint256 valueFee;
        uint256 maxOpenNum;
    }

    struct RangeInfo {
        uint256 nftType;
        uint256 nftId;
        uint256 startIndex;
        uint256 endIndex;
    }

    struct RandomInfo {
        address to;
        uint256 rid;
        uint256 num;
    }

    RoomInfo[] public roomInfo;
    mapping(uint256 => IERC20[]) public valueTokenList;
    mapping(uint256 => mapping(IERC20 => bool)) public valueTokens;
    mapping(uint256 => mapping(IERC20 => uint256)) public valueAmount;
    mapping(uint256 => RangeInfo[]) public rangeInfo;
    IInvite public invite;
    IP2EERC1155 public nftToken;

    address public tokenReceiver;
    address public feeReceiver;
    address public rewardReceiver;
    mapping(IERC20 => uint) public totalTokenAmount;
    mapping(IERC20 => uint) public totalFeeAmount;

    mapping(bytes32 => RandomInfo) public randomInfo;
    mapping(uint256 => mapping(address => uint256)) public blindBoxNum;

    function setTokenReceiver(address _tokenReceiver) external onlyOwner {
        require(_tokenReceiver != address(0), "tokenReceiver is zero");
        emit NewTokenReceiver(tokenReceiver, _tokenReceiver);
        tokenReceiver = _tokenReceiver;
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0), "tokenReceiver is zero");
        emit NewFeeReceiver(feeReceiver, _feeReceiver);
        feeReceiver = _feeReceiver;
    }

    function setRewardReceiver(address _rewardReceiver) external onlyOwner {
        require(_rewardReceiver != address(0), "tokenReceiver is zero");
        emit NewRewardReceiver(_rewardReceiver, rewardReceiver);
        rewardReceiver = _rewardReceiver;
    }

    function tokenTransfer(IERC20 _token, address _to, uint _amount) internal returns (uint) {
        if (_amount == 0) {
            return 0;
        }
        if (address(_token) == WETH) {
            IWETH(address(_token)).withdraw(_amount);
            TransferHelper.safeTransferETH(_to, _amount);
        } else {
            _token.safeTransfer(_to, _amount);
        }
        return _amount;
    }

    function tokenWithdraw(IERC20 _token, uint _amount) external onlyOwner {
        if (_amount > totalTokenAmount[_token]) {
            _amount = totalTokenAmount[_token];
        }
        totalTokenAmount[_token] = totalTokenAmount[_token].sub(_amount);
        require(tokenReceiver != address(0), "tokenReceiver is zero");
        tokenTransfer(_token, tokenReceiver, _amount);
        emit TokenWithdraw(_token, _amount);
    }

    function feeWithdraw(IERC20 _token, uint _amount) external onlyOwner {
        if (_amount > totalFeeAmount[_token]) {
            _amount = totalFeeAmount[_token];
        }
        totalFeeAmount[_token] = totalFeeAmount[_token].sub(_amount);
        require(feeReceiver != address(0), "feeReceiver is zero");
        tokenTransfer(_token, feeReceiver, _amount);
        emit FeeWithdraw(_token, _amount);
    }

    function roomInfoLength() external view returns (uint256) {
        return roomInfo.length;
    }

    function valueInfoLength(uint256 rid) external view returns (uint256) {
        return valueTokenList[rid].length;
    }

    function rangeInfoLength(uint256 rid) external view returns (uint256) {
        return rangeInfo[rid].length;
    }

    function setMaxOpenNum(uint rid, uint256 newOpenNum) external onlyOwner {
        require(rid < roomInfo.length, "illegal rid");
        emit NewMaxOpenNum(roomInfo[rid].maxOpenNum, newOpenNum);
        roomInfo[rid].maxOpenNum = newOpenNum;
    }

    function setRoomTime(uint rid, uint _startSeconds, uint _endSeconds) external RoomNotBegin(rid) {
        require(msg.sender == owner(), "Caller not owner");
        require(_endSeconds > _startSeconds, "illegal time");
        roomInfo[rid].startSeconds = _startSeconds;
        roomInfo[rid].endSeconds = _endSeconds;
    }

    constructor(address _WETH, IInvite _invite, IP2EERC1155 _nftToken, address _tokenReceiver, address _feeReceiver, address _rewardReceiver, address _linkAccessor) Random(_linkAccessor) SafeOwnable(msg.sender) {
        require(_WETH != address(0), "WETH is zero");
        WETH = _WETH;
        require(address(_invite) != address(0), "invite address is zero");
        invite = _invite;
        require(address(_nftToken) != address(0), "nftToken is zero");
        nftToken = _nftToken;
        require(_tokenReceiver != address(0), "receiver is zero");
        tokenReceiver = _tokenReceiver;
        emit NewTokenReceiver(address(0), tokenReceiver);
        require(_feeReceiver != address(0), "fee reciever is zero");
        feeReceiver = _feeReceiver;
        emit NewFeeReceiver(address(0), feeReceiver);
        require(_rewardReceiver != address(0), "rewardReceiver is zero");
        rewardReceiver = _rewardReceiver;
        emit NewRewardReceiver(address(0), rewardReceiver);
    }

    modifier RoomNotBegin(uint rid) {
        require(rid < roomInfo.length, "illegal rid");
        require(block.timestamp < roomInfo[rid].startSeconds || block.timestamp > roomInfo[rid].endSeconds, "Room Already Begin");
        _;
    }

    modifier RoomBegin(uint rid) {
        require(block.timestamp >= roomInfo[rid].startSeconds && block.timestamp <= roomInfo[rid].endSeconds, "Room Already Finish");
        _;
    }

    function add(
        IERC20 _rewardToken, uint256 _rewardAmount, uint256 _startSeconds, uint256 _endSeconds, uint256 _valueFee, 
        IERC20[] memory _tokens, uint256[] memory _amounts, uint256[] memory _nftTypes, uint256[] memory _nftValues, uint256[] memory _nftPercents
    ) external onlyOwner {
        require(address(_rewardToken) != address(0), "rewardToken is zero address");
        require(_endSeconds > _startSeconds, "illegal time");
        roomInfo.push(RoomInfo({
            rewardToken: _rewardToken,
            rewardAmount: _rewardAmount,
            startSeconds: _startSeconds,
            endSeconds: _endSeconds,
            rewardPool: 0,
            valueFee: _valueFee,
            maxOpenNum: 5
        }));
        uint rid = roomInfo.length - 1;
        emit NewCollectRoom(rid, _rewardToken, _rewardAmount, _startSeconds, _endSeconds);
        require(_nftTypes.length == _nftPercents.length && _nftTypes.length > 0, "illegal type percent info");
        uint lastEndIndex = 0;
        for (uint i = 0; i < rangeInfo[rid].length; i ++) {
            lastEndIndex = rangeInfo[rid][i].endIndex;
        }
        uint[] memory nftIDs = nftToken.createBatchDefault(_nftTypes, _nftValues);
        emit NFTCreated(nftToken, rid, nftIDs, _nftTypes, _nftValues);
        for (uint i = 0; i < _nftTypes.length; i ++) {
            rangeInfo[rid].push(RangeInfo({
                nftType : _nftTypes[i],
                startIndex: lastEndIndex,
                endIndex: lastEndIndex.add(_nftPercents[i]),
                nftId: nftIDs[i]
            }));
            lastEndIndex = lastEndIndex.add(_nftPercents[i]);
        }
        require(lastEndIndex == MAX_END_INDEX, "illegal percent info");
        require(_tokens.length == _amounts.length && _tokens.length > 0, "illegal token amount info");
        for (uint i = 0; i < _tokens.length; i ++) {
            require(address(_tokens[i]) != address(0), "token address is zero");
            require(_amounts[i] > 0, "illegal amount value");
            require(!valueTokens[rid][_tokens[i]], "token already exists");
            valueTokens[rid][_tokens[i]] = true;
            valueTokenList[rid].push(_tokens[i]);
            valueAmount[rid][_tokens[i]] = _amounts[i];
            emit RoomValue(rid, _tokens[i], _amounts[i]);
        }
    }

    function doRandom() internal returns (bytes32){
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, block.coinbase, block.number)));
        bytes32 requestId = _requestRandom(seed);
        require(randomInfo[requestId].to == address(0), "random already exists");
        return requestId;
    }

    function buyBlindBox(uint256 _rid, IERC20 _token, uint256 _num, address _to) external payable {
        require(_rid < roomInfo.length, "illegal rid"); 
        RoomInfo storage room = roomInfo[_rid];
        require(_num <= roomInfo[_rid].maxOpenNum, "illegal open num");
        require(block.timestamp >= room.startSeconds && block.timestamp <= room.endSeconds, "room not begin or already finish");
        require(valueTokens[_rid][_token], "token not support");
        uint payAmount = valueAmount[_rid][_token].mul(_num);
        uint payFee = payAmount.mul(room.valueFee).div(VALUE_FEE_BASE);

        address[] memory inviters = invite.inviterTree(_to, MAX_INVITE_HEIGHT);
        uint[] memory amounts = new uint[](inviters.length);
        uint totalInviterAmount = 0;
        for (uint i = 0; i < inviters.length; i ++) {
            uint percent = getInvitePercent(i);
            amounts[i] = payAmount.mul(percent).div(PERCENT_BASE);
            totalInviterAmount = totalInviterAmount.add(amounts[i]);
        }
        if (address(_token) == WETH) {
            require(msg.value == payAmount.add(payFee), "illegal ETH amount");
            IWETH(WETH).deposit{value: payAmount.add(payFee)}();
        } else {
            SafeERC20.safeTransferFrom(_token, msg.sender, address(this), payAmount.add(payFee));
        }
        _token.safeTransfer(address(invite), totalInviterAmount);
        uint remainAmount = invite.sendReward(_to, _token, amounts);
        payAmount = payAmount.sub(totalInviterAmount.sub(remainAmount));
        totalTokenAmount[_token] = totalTokenAmount[_token].add(payAmount);
        totalFeeAmount[_token] = totalFeeAmount[_token].add(payFee);

        bytes32 requestId = doRandom();
        randomInfo[requestId] = RandomInfo({
            to: _to,
            rid: _rid,
            num: _num
        });
        blindBoxNum[_rid][_to] = blindBoxNum[_rid][_to].add(_num);

        emit BuyBlindBox(_rid, _to, _token, _num, payAmount.add(totalInviterAmount.sub(remainAmount)), payFee, requestId);
    }

    function finishRandom(bytes32 _requestId) internal override {
        RandomInfo storage random = randomInfo[_requestId];
        require(random.to != address(0), "requestId not exists");
        uint seed = randomResult[_requestId];
        for (uint i = 0; i < random.num; i ++) {
            seed = uint256(keccak256(abi.encodePacked(seed, i)));
            uint nftRange = seed.mod(MAX_END_INDEX);
            uint rangeIndex = 0;
            for (; rangeIndex < rangeInfo[random.rid].length; rangeIndex ++) {
                if (nftRange >= rangeInfo[random.rid][rangeIndex].startIndex && nftRange < rangeInfo[random.rid][rangeIndex].endIndex) {
                    RangeInfo storage range = rangeInfo[random.rid][rangeIndex]; 
                    nftToken.mint(random.to, range.nftId, 1, "0x");
                    emit OpenBlindBox(random.rid, random.to, rangeIndex, 1, _requestId);
                    break;
                }
            }
            require(rangeIndex < rangeInfo[random.rid].length, "rangeInfo error");
        }
        blindBoxNum[random.rid][random.to] = blindBoxNum[random.rid][random.to].sub(random.num);
        delete randomInfo[_requestId];

        super.finishRandom(_requestId);
    }

    function claim(uint256 rid, address to) external {
        require(rid < roomInfo.length, "illegal rid"); 
        RoomInfo storage room = roomInfo[rid];
        uint256 nftNum = rangeInfo[rid].length;
        address[] memory accounts = new address[](nftNum);
        uint256[] memory ids = new uint256[](nftNum);
        for (uint i = 0; i < nftNum; i ++) {
            accounts[i] = to; 
            ids[i] = rangeInfo[rid][i].nftId;
        }
        uint256[] memory balances = nftToken.balanceOfBatch(accounts, ids);
        uint minNum = uint(-1);
        for (uint i = 0; i < balances.length; i ++) {
            if (balances[i] < minNum) {
                minNum = balances[i];
            }
        }
        if (minNum <= 0) {
            return; 
        }
        uint reward = room.rewardAmount.mul(minNum);
        require(room.rewardPool >= reward, "reward pool not enough");
        room.rewardPool = room.rewardPool.sub(reward);
        for (uint i = 0; i < balances.length; i ++) {
            balances[i] = minNum;
        }
        nftToken.burnBatch(to, ids, balances);
        SafeERC20.safeTransfer(room.rewardToken, to, reward);
        emit Claim(rid, to, minNum, reward);
    }

    function roomDeposit(uint rid, uint amount) external {
        require(rid < roomInfo.length, "rid not exist");  
        RoomInfo storage room = roomInfo[rid];
        uint balanceBefore = room.rewardToken.balanceOf(address(this));
        SafeERC20.safeTransferFrom(room.rewardToken, msg.sender, address(this), amount);
        uint balanceAfter = room.rewardToken.balanceOf(address(this));
        require(balanceAfter > balanceBefore, "token transfer error");
        room.rewardPool = room.rewardPool.add(balanceAfter.sub(balanceBefore));
        emit RewardPoolDeposit(rid, msg.sender, room.rewardToken, balanceAfter.sub(balanceBefore));
    }

    function roomWithdraw(uint rid, uint amount) external RoomNotBegin(rid) {
        require(msg.sender == owner(), "Caller not owner");
        RoomInfo storage room = roomInfo[rid];
        if (block.timestamp > room.endSeconds) {
            require(block.timestamp > room.endSeconds.add(60 * 60 * 24 * 7), "the reward can be withdrawed only after 1 week");
        }
        if (room.rewardPool < amount) {
            amount = room.rewardPool;
        }
        room.rewardPool = room.rewardPool.sub(amount);
        tokenTransfer(room.rewardToken, rewardReceiver, amount);
        emit RewardPoolWithdraw(rid, rewardReceiver, room.rewardToken, amount);
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IP2EERC1155 {

    function create(
        uint256 _maxSupply,
        uint256 _initialSupply,
        uint256 _type,
        bytes calldata _data
    ) external returns (uint256 tokenId);

    function createBatch(
        uint256 _maxSupply,
        uint256 _initialSupply,
        uint256[] calldata _types,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (uint256[] calldata tokenIds);

    function createBatchDefault(uint256[] calldata _types, uint256[] calldata _values) external returns (uint256[] calldata tokenIds);

    function mint(address to, uint256 _id, uint256 _quantity, bytes calldata _data) external;

    function burn(address _account, uint256 _id, uint256 _amount) external;

    function burnBatch(address account, uint256[] calldata ids, uint256[] calldata amounts) external;

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function totalBalance(address account, uint256[] calldata ids) external view returns (uint256, uint256[] calldata);

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] calldata);

    function disableTokenTransfer(uint _id) external;

    function enableTokenTransfer(uint _id) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IInvite {

    function inviterTree(address _user, uint _height) external view returns (address[] memory);

    function sendReward(address _user, IERC20 _token, uint[] memory amounts) external returns (uint);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '../interfaces/IP2EERC1155.sol';
import '../core/SafeOwnable.sol';
import 'hardhat/console.sol';
import '../core/Random.sol';
import '../interfaces/IInvite.sol';

contract GameRoomManager is SafeOwnable, Random {
    using SafeMath for uint256;
    using Strings for uint256;

    event NewGameRoom(uint rid, IERC20 token, uint value, uint valueFee, uint odds);
    event RoomRange(uint rid, uint nftType, uint startIndex, uint endIndex);
    event BuyBlindBox(uint rid, address user, uint256 loop, uint num, uint payAmount, uint payFee, bytes32 requestId);
    event OpenBlindBox(uint rid, uint loop, address to, uint rangeIndex, bytes32 requestId);
    event Claim(uint rid, uint loop, address to, uint num, uint reward);
    event RewardPoolDeposit(uint rid, address from, IERC20 token, uint256 amount);
    event RewardPoolWithdraw(uint rid, address to, IERC20 token, uint256 amount);
    event NewReceiver(address oldReceiver, address newReceiver);
    event NewRewardReceiver(address oldRewardReceiver, address newRewardReceiver);
    event NewMaxOpenNum(uint256 oldMaxOpenNum, uint256 newMaxOpenNum);

    uint256 constant MAX_END_INDEX = 1000000;
    uint256 constant VALUE_FEE_BASE = 10000;
    uint256 constant MAX_INVITE_HEIGHT = 3;
    function getInvitePercent(uint height) internal pure returns (uint) {
        if (height == 0) {
            return 2000;
        } else if (height == 1) {
            return 1000;
        } else if (height == 2) {
            return 500;
        } else {
            return 0;
        }
    }
    uint256 constant PERCENT_BASE = 10000;

    struct RoomInfo {
        IERC20 token;
        uint256 value;
        uint256 currentLoop;
        uint256 loopBeginAt;
        uint256 loopFinishAt;
        uint256 loopInterval;
        bool loopFinish;
        uint256 valueFee;
        uint256 rewardAmount;
        uint256 odds;
        uint256 maxOpenNum;
    }

    struct RangeInfo {
        uint256 nftType;
        uint256 startIndex;
        uint256 endIndex;
    }

    struct RandomInfo {
        address to;
        uint256 rid;
        uint256 num;
        uint256 loop;
    }

    RoomInfo[] public roomInfo;
    mapping(uint256 => RangeInfo[]) public rangeInfo;
    mapping(bytes32 => RandomInfo) public randomInfo;
    mapping(uint256 => uint256[]) nftTypes;
    mapping(uint256 => mapping(uint256 => uint256[])) public nftIDs;
    mapping(uint256 => mapping(uint256 => uint256)) public loopResult;
    mapping(uint256 => mapping(address => uint256)) public blindBoxNum;

    IInvite public invite;
    IP2EERC1155 public nftToken;
    address public receiver;
    address public rewardReceiver;

    function roomInfoLength() external view returns (uint256) {
        return roomInfo.length;
    }

    function loopNFT(uint _rid, uint _loop) external view returns (uint256[] memory) {
        return nftIDs[_rid][_loop];
    }
    
    function rangeInfoLength(uint256 rid) external view returns (uint256) {
        return rangeInfo[rid].length;
    }

    function setMaxOpenNum(uint rid, uint256 newOpenNum) external onlyOwner {
        require(rid < roomInfo.length, "illegal rid");
        emit NewMaxOpenNum(roomInfo[rid].maxOpenNum, newOpenNum);
        roomInfo[rid].maxOpenNum = newOpenNum;
    }

    function setReceiver(address _receiver) external onlyOwner {
        require(_receiver != address(0), "receiver is zero");
        emit NewReceiver(receiver, _receiver);
        receiver = _receiver;
    }

    function setRewardReceiver(address _rewardReceiver) external onlyOwner {
        require(_rewardReceiver != address(0), "rewardReceiver is zero");
        emit NewRewardReceiver(rewardReceiver, _rewardReceiver);
        rewardReceiver = _rewardReceiver;
    }

    function beginLoop(uint _rid, uint _startAt) public {
        if (_rid >= roomInfo.length) {
            return;
        }
        RoomInfo storage room = roomInfo[_rid];
        if (block.timestamp <= room.loopFinishAt || block.timestamp > _startAt) {
            return;
        }
        room.currentLoop = room.currentLoop + 1;
        room.loopBeginAt = _startAt;
        room.loopFinishAt = _startAt.add(room.loopInterval);
        room.loopFinish = false;
        uint[] memory nftValues = new uint[](nftTypes[_rid].length);
        nftIDs[_rid][room.currentLoop] = nftToken.createBatchDefault(nftTypes[_rid], nftValues);
    }

    function finishLoop(uint _rid, uint _loop) public {
        if (_rid >= roomInfo.length) {
            return;
        }
        RoomInfo storage room = roomInfo[_rid];
        if (_loop != room.currentLoop || room.loopFinish || block.timestamp < room.loopFinishAt) {
            return;
        }
        room.loopFinish = true;
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, block.coinbase, block.number)));
        bytes32 requestId = _requestRandom(seed);
        require(randomInfo[requestId].to == address(0), "random already exists");
        randomInfo[requestId] = RandomInfo({
            to: address(this),
            rid: _rid,
            num: 1,
            loop: _loop
        });
        emit BuyBlindBox(_rid, address(this), _loop, 1, 0, 0, requestId);
    }

    constructor(IInvite _invite, IP2EERC1155 _nftToken, address _receiver, address _rewardReceiver, address _linkAccessor) Random(_linkAccessor) SafeOwnable(msg.sender) {
        require(address(_invite) != address(0), "invite address is zero");
        invite = _invite;
        require(address(_nftToken) != address(0), "nftToken is zero");
        nftToken = _nftToken;
        require(_receiver != address(0), "receiver is zero");
        receiver = _receiver;
        emit NewReceiver(address(0), receiver);
        require(_rewardReceiver != address(0), "rewardReceiver is zero");
        rewardReceiver = _rewardReceiver;
        emit NewRewardReceiver(address(0), rewardReceiver);
    }

    function add(
        IERC20 _token, uint256 _value, uint256 _valueFee, uint256 _loopInterval, uint256 _odds, uint256[] memory _nftTypes, uint256[] memory _nftPercents
    ) external onlyOwner {
        require(address(_token) != address(0), "rewardToken is zero address");
        roomInfo.push(RoomInfo({
            token: _token,
            value: _value,
            currentLoop: 0,
            loopBeginAt: 0,
            loopFinishAt: 0,
            loopFinish: false,
            loopInterval: _loopInterval,
            valueFee: _valueFee,
            rewardAmount: 0,
            odds: _odds,
            maxOpenNum: 1
        }));
        uint rid = roomInfo.length - 1;
        emit NewGameRoom(rid, _token, _value, _valueFee, _odds);
        require(_nftTypes.length == _nftPercents.length && _nftTypes.length > 0, "illegal type percent info");
        uint lastEndIndex = 0;
        for (uint i = 0; i < rangeInfo[rid].length; i ++) {
            lastEndIndex = rangeInfo[rid][i].endIndex;
        }
        for (uint i = 0; i < _nftTypes.length; i ++) {
            rangeInfo[rid].push(RangeInfo({
                nftType : _nftTypes[i],
                startIndex: lastEndIndex,
                endIndex: lastEndIndex.add(_nftPercents[i])
            }));
            nftTypes[rid].push(_nftTypes[i]);
            emit RoomRange(rid, _nftTypes[i], lastEndIndex, lastEndIndex.add(_nftPercents[i]));
            lastEndIndex = lastEndIndex.add(_nftPercents[i]);
        }
        require(lastEndIndex == MAX_END_INDEX, "illegal percent info");
        beginLoop(rid, block.timestamp);
    }

    function buyBlindBox(uint256 _rid, uint256 _num, address _to) external {
        require(_rid < roomInfo.length, "illegal rid"); 
        RoomInfo storage room = roomInfo[_rid];
        require(_num <= roomInfo[_rid].maxOpenNum, "illegal open num");
        require(block.timestamp >= room.loopBeginAt && block.timestamp <= room.loopFinishAt, "room not begin or already finish");
        uint payAmount = room.value.mul(_num);
        uint payFee = payAmount.mul(room.valueFee).div(VALUE_FEE_BASE);

        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, block.coinbase, block.number)));
        bytes32 requestId = _requestRandom(seed);
        require(randomInfo[requestId].to == address(0), "random already exists");
        randomInfo[requestId] = RandomInfo({
            to: _to,
            rid: _rid,
            num: _num,
            loop: room.currentLoop
        });
        blindBoxNum[_rid][_to] = blindBoxNum[_rid][_to].add(_num);

        address[] memory inviters = invite.inviterTree(_to, MAX_INVITE_HEIGHT);
        uint[] memory amounts = new uint[](inviters.length);
        uint totalInviterAmount = 0;
        for (uint i = 0; i < inviters.length; i ++) {
            uint percent = getInvitePercent(i);
            amounts[i] = payAmount.mul(percent).div(PERCENT_BASE); 
            totalInviterAmount = totalInviterAmount.add(amounts[i]);
        }
        SafeERC20.safeTransferFrom(room.token, msg.sender, address(invite), totalInviterAmount);
        //uint remainAmount = invite.sendReward(_to, room.token, amounts);
        invite.sendReward(_to, room.token, amounts);
        SafeERC20.safeTransferFrom(room.token, msg.sender, address(this), payAmount.sub(totalInviterAmount));
        if (payFee > 0) {
            SafeERC20.safeTransferFrom(room.token, msg.sender, receiver, payFee);
        }
        emit BuyBlindBox(_rid, _to, room.currentLoop, _num, payAmount, payFee, requestId);
    }

    function finishRandom(bytes32 _requestId) internal override {
        RandomInfo storage random = randomInfo[_requestId];
        require(random.to != address(0), "requestId not exists");
        uint seed = randomResult[_requestId];
        for (uint i = 0; i < random.num; i ++) {
            seed = uint256(keccak256(abi.encodePacked(seed, i)));
            uint nftRange = seed.mod(MAX_END_INDEX);
            uint rangeIndex = 0;
            for (; rangeIndex < rangeInfo[random.rid].length; rangeIndex ++) {
                if (nftRange >= rangeInfo[random.rid][rangeIndex].startIndex && nftRange < rangeInfo[random.rid][rangeIndex].endIndex) {
                    uint nftId = nftIDs[random.rid][random.loop][rangeIndex];
                    nftToken.mint(random.to, nftId, 1, "0x");
                    emit OpenBlindBox(random.rid, random.loop, random.to, rangeIndex, _requestId);
                    if (random.to == address(this)) {
                        loopResult[random.rid][random.loop] = nftId;
                    }
                    break;
                }
            }
            require(rangeIndex < rangeInfo[random.rid].length, "rangeInfo error");
        }
        blindBoxNum[random.rid][random.to] = blindBoxNum[random.rid][random.to].sub(random.num);
        delete randomInfo[_requestId];

        super.finishRandom(_requestId);
    }

    function claim(uint256 _rid, uint256 _loop, address _to) external {
        require(_rid < roomInfo.length, "illegal rid"); 
        RoomInfo storage room = roomInfo[_rid];
        require(_loop < room.currentLoop || (_loop == room.currentLoop && room.loopFinish), "loop not finish");
        uint resultNftId = loopResult[_rid][_loop];
        uint balance = nftToken.balanceOf(_to, resultNftId);
        uint reward = room.value.mul(balance).mul(room.odds);
        require(reward > 0, "user not win");
        require(room.rewardAmount >= reward, "reward token not enough");
        room.rewardAmount = room.rewardAmount.sub(reward);
        nftToken.burn(_to, resultNftId, balance);
        SafeERC20.safeTransfer(room.token, _to, reward);
        emit Claim(_rid, _loop, _to, balance, reward);
    }

    function roomDeposit(uint _rid, uint _amount) external {
        require(_rid < roomInfo.length, "rid not exist");  
        RoomInfo storage room = roomInfo[_rid];
        uint balanceBefore = room.token.balanceOf(address(this));
        SafeERC20.safeTransferFrom(room.token, msg.sender, address(this), _amount);
        uint balanceAfter = room.token.balanceOf(address(this));
        require(balanceAfter > balanceBefore, "token transfer error");
        room.rewardAmount = room.rewardAmount.add(balanceAfter.sub(balanceBefore));
        emit RewardPoolDeposit(_rid, msg.sender, room.token, balanceAfter.sub(balanceBefore));
    }

    function roomWithdraw(uint _rid, uint _amount) external {
        require(msg.sender == owner(), "Caller not owner");
        require(_rid < roomInfo.length, "illegal rid");
        RoomInfo storage room = roomInfo[_rid];
        require(block.timestamp > room.loopFinishAt + 60 * 60 * 24 * 7, "the reward can be withdrawed only after 1 week");
        if (room.rewardAmount < _amount) {
            _amount = room.rewardAmount;
        }
        room.rewardAmount = room.rewardAmount.sub(_amount);
        SafeERC20.safeTransfer(room.token, rewardReceiver, _amount);
        emit RewardPoolWithdraw(_rid, rewardReceiver, room.token, _amount);
    }

    function userRecord(uint _rid, uint[] memory loops, address user) external view returns (uint[] memory){
        RoomInfo storage room = roomInfo[_rid];
        uint[] memory res = new uint[](loops.length);
        for (uint i = 0; i < loops.length; i ++) {
            if (loops[i] > room.currentLoop) {
                res[i] = 0;
            }
            uint resultNftId = loopResult[_rid][loops[i]];
            uint balance = nftToken.balanceOf(user, resultNftId);
            res[i] = balance.mul(room.odds);
        }
        return res;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '../libraries/TransferHelper.sol';
import '../interfaces/IP2EERC1155.sol';
import '../interfaces/IInvite.sol';
import '../interfaces/IWETH.sol';
import '../core/SafeOwnable.sol';
import 'hardhat/console.sol';
import '../core/Random.sol';

contract BurnRoomManager is SafeOwnable, Random {
    using SafeMath for uint256;
    using Strings for uint256;
    using SafeERC20 for IERC20;

    event NewBurnRoom(uint rid, IERC20 token, uint totalLoop, uint totalNum);
    event RoomRange(uint rid, uint nftType, uint startIndex, uint endIndex);
    event BuyBlindBox(uint rid, uint loop, address user, uint num, uint payAmount, uint payFee, bytes32 requestId);
    event OpenBlindBox(uint rid, uint loop, address to, uint rangeIndex, uint num, bytes32 requestId);
    event Claim(uint rid, uint loop, address to, uint reward);
    event NewReceiver(address oldReceiver, address newReceiver);
    event NewFeeReceiver(address oldReceiver, address newReceiver);
    event NewRewardReceiver(address oldReceiver, address newReceiver);
    event FeeWithdraw(IERC20 token, uint amount);
    event LoopBegin(uint rid, uint loop);
    event LoopFinish(uint rid, uint loop);
    event Winner(uint rid, uint loop, address to);
    event NFTCreated(IP2EERC1155 nftToken, uint rid, uint loop, uint[] ids, uint[] types, uint[] values);

    uint256 constant MAX_END_INDEX = 1000000;
    uint256 constant VALUE_FEE_BASE = 10000;
    address immutable WETH;
    uint256 constant MAX_INVITE_HEIGHT = 3;
    function getInvitePercent(uint height) internal pure returns (uint) {
        if (height == 0) {
            return 2000;
        } else if (height == 1) {
            return 1000;
        } else if (height == 2) {
            return 500;
        } else {
            return 0;
        }
    }
    uint256 constant PERCENT_BASE = 10000;

    struct RoomInfo {
        IERC20 token;
        uint256 value;
        uint256 currentLoop;
        uint256 totalLoop;
        uint256 openNum;
        uint256 totalNum;
        uint256 valueFee;
        uint256 maxOpenNum;
        uint256 maxBurnNum;
    }
    struct RangeInfo {
        uint256 nftType;
        uint256 startIndex;
        uint256 endIndex;
    }

    struct RandomInfo {
        address to;
        uint256 rid;
        uint256 loop;
        uint256 num;
    }

    function setMaxOpenNum(uint _rid, uint _num) external {
        require(_rid < roomInfo.length, "illegal rid");
        roomInfo[_rid].maxOpenNum = _num;
    }

    function setMaxBurnNum(uint _rid, uint _num) external {
        require(_rid < roomInfo.length, "illegal rid");
        roomInfo[_rid].maxBurnNum = _num;
    }

    RoomInfo[] public roomInfo;
    mapping(uint256 => uint256[]) nftTypes;
    mapping(uint256 => RangeInfo[]) public rangeInfo;
    mapping(uint256 => mapping(uint256 => uint256[])) public nftIDs;
    mapping(uint256 => mapping(uint256 => uint256)) public roomReward;
    mapping(uint256 => mapping(uint256 => uint256)) public claimedReward;
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public winers;
    mapping(uint256 => mapping(uint256 => uint256)) public winerNum;
    mapping(bytes32 => RandomInfo) public randomInfo;
    mapping(uint256 => mapping(address => uint256)) public blindBoxNum;

    IInvite immutable public invite;
    IP2EERC1155 public nftToken;

    address public feeReceiver;
    address public rewardReceiver;
    mapping(IERC20 => uint) public totalFeeAmount;

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0), "tokenReceiver is zero");
        emit NewFeeReceiver(feeReceiver, _feeReceiver);
        feeReceiver = _feeReceiver;
    }

    function setRewardReceiver(address _rewardReceiver) external onlyOwner {
        require(_rewardReceiver != address(0), "tokenReceiver is zero");
        emit NewRewardReceiver(_rewardReceiver, rewardReceiver);
        rewardReceiver = _rewardReceiver;
    }

    function tokenTransfer(IERC20 _token, address _to, uint _amount) internal returns (uint) {
        if (address(_token) == WETH) {
            IWETH(address(_token)).withdraw(_amount);
            TransferHelper.safeTransferETH(_to, _amount);
        } else {
            _token.safeTransfer(_to, _amount);
        }
        return _amount;
    }

    function feeWithdraw(IERC20 _token, uint _amount) external onlyOwner {
        if (_amount > totalFeeAmount[_token]) {
            _amount = totalFeeAmount[_token];
        }
        totalFeeAmount[_token] = totalFeeAmount[_token].sub(_amount);
        require(feeReceiver != address(0), "feeReceiver is zero");
        tokenTransfer(_token, feeReceiver, _amount);
        emit FeeWithdraw(_token, _amount);
    }

    function roomInfoLength() external view returns (uint256) {
        return roomInfo.length;
    }

    function rangeInfoLength(uint256 rid) external view returns (uint256) {
        return rangeInfo[rid].length;
    }

    function loopNFT(uint _rid, uint _loop) external view returns (uint256[] memory) {
        return nftIDs[_rid][_loop];
    }

    constructor(address _WETH, IInvite _invite, IP2EERC1155 _nftToken, address _feeReceiver, address _rewardReceiver, address _linkAccessor) Random(_linkAccessor) SafeOwnable(msg.sender) {
        require(_WETH != address(0), "WETH is zero");
        WETH = _WETH;
        require(address(_invite) != address(0), "invite address is zero");
        invite = _invite;
        require(address(_nftToken) != address(0), "nftToken is zero");
        nftToken = _nftToken;
        require(_feeReceiver != address(0), "feeReceiver is zero");
        feeReceiver = _feeReceiver;
        emit NewFeeReceiver(address(0), feeReceiver);
        require(_rewardReceiver != address(0), "rewardReceiver is zero");
        rewardReceiver = _rewardReceiver;
        emit NewRewardReceiver(address(0), rewardReceiver);
    }

    function beginLoop(uint _rid) public {
        if (_rid >= roomInfo.length) {
            return;
        }
        RoomInfo storage room = roomInfo[_rid];
        if (room.currentLoop > room.totalLoop) {
            return;
        }
        if (room.currentLoop > 0 && room.openNum != room.totalNum) {
            return;
        }
        emit LoopFinish(_rid, room.currentLoop);
        room.currentLoop = room.currentLoop + 1;
        uint256[] memory nftValues = new uint256[](nftTypes[_rid].length);
        emit LoopBegin(_rid, room.currentLoop);
        nftIDs[_rid][room.currentLoop] = nftToken.createBatchDefault(nftTypes[_rid], nftValues);
        emit NFTCreated(nftToken, _rid, room.currentLoop, nftIDs[_rid][room.currentLoop], nftTypes[_rid], nftValues);
        room.openNum = 0;
    }

    function add(
        IERC20 _token, uint256 _value, uint256 _totalLoop, uint256 _totalNum, uint256 _valueFee, uint256[] memory _nftTypes, uint256[] memory _nftPercents
    ) external onlyOwner {
        require(address(_token) != address(0), "token is zero address");
        roomInfo.push(RoomInfo({
            token: _token,
            value: _value,
            currentLoop: 0,
            totalLoop: _totalLoop,
            openNum: 0,
            totalNum: _totalNum,
            valueFee: _valueFee,
            maxOpenNum: 1,
            maxBurnNum: 1
        }));
        uint rid = roomInfo.length - 1;
        emit NewBurnRoom(rid, _token, _totalLoop, _totalNum);

        require(_nftTypes.length == _nftPercents.length && _nftTypes.length > 0, "illegal type percent info");
        uint lastEndIndex = 0;
        for (uint i = 0; i < _nftTypes.length; i ++) {
            rangeInfo[rid].push(RangeInfo({
                nftType : _nftTypes[i],
                startIndex: lastEndIndex,
                endIndex: lastEndIndex.add(_nftPercents[i])
            }));
            nftTypes[rid].push(_nftTypes[i]);
            emit RoomRange(rid, _nftTypes[i], lastEndIndex, lastEndIndex.add(_nftPercents[i]));
            lastEndIndex = lastEndIndex.add(_nftPercents[i]);
        }
        require(lastEndIndex == MAX_END_INDEX, "illegal percent info");
        beginLoop(rid);
    }

    function doRandom() internal returns (bytes32){
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, block.coinbase, block.number)));
        bytes32 requestId = _requestRandom(seed);
        require(randomInfo[requestId].to == address(0), "random already exists");
        return requestId;
    }

    function tokenNotFull(uint _rid, uint _loop, address _user) internal view returns(bool) {
        (uint256 totalBalance, ) = nftToken.totalBalance(_user, nftIDs[_rid][_loop]);
        return totalBalance.add(blindBoxNum[_rid][_user]) > rangeInfo[_rid].length;
    }

    function buyBlindBox(uint256 _rid, uint256 _loop, uint256 _num, address _to) external payable {
        require(_rid < roomInfo.length, "illegal rid"); 
        RoomInfo storage room = roomInfo[_rid];
        require(_loop > 0 && _loop == room.currentLoop, "loop illegal");
        require(room.totalNum.sub(_num) >= room.openNum, "loop already finish");
        require(_num <= room.maxOpenNum, "illegal num");
        uint payAmount = room.value.mul(_num);
        uint payFee = payAmount.mul(room.valueFee).div(VALUE_FEE_BASE);
        address[] memory inviters = invite.inviterTree(_to, MAX_INVITE_HEIGHT);
        uint[] memory amounts = new uint[](inviters.length);
        uint totalInviterAmount = 0;
        for (uint i = 0; i < inviters.length; i ++) {
            uint percent = getInvitePercent(i);
            amounts[i] = payAmount.mul(percent).div(PERCENT_BASE); 
            totalInviterAmount = totalInviterAmount.add(amounts[i]);
        }
        if (address(room.token) == WETH) {
            require(msg.value == payAmount.add(payFee), "illegal ETH amount");
            IWETH(WETH).deposit{value: payAmount.add(payFee)}();
        } else {
            SafeERC20.safeTransferFrom(room.token, msg.sender, address(this), payAmount.add(payFee));
        }
        room.token.safeTransfer(address(invite), totalInviterAmount);
        uint remainAmount = invite.sendReward(_to, room.token, amounts);
        payAmount = payAmount.sub(totalInviterAmount.sub(remainAmount));
        roomReward[_rid][_loop] = roomReward[_rid][_loop].add(payAmount);
        totalFeeAmount[room.token] = totalFeeAmount[room.token].add(payFee);
        bytes32 requestId = doRandom();
        randomInfo[requestId] = RandomInfo({
            to: _to,
            rid: _rid,
            num: _num,
            loop: _loop
        });

        blindBoxNum[_rid][_to] = blindBoxNum[_rid][_to].add(_num);
        room.openNum = room.openNum + _num;

        require(tokenNotFull(_rid, _loop, _to), "token alrady full");

        beginLoop(_rid);
        emit BuyBlindBox(_rid, _loop, _to, _num, payAmount, payFee, requestId);
    }

    function finishRandom(bytes32 _requestId) internal override {
        RandomInfo storage random = randomInfo[_requestId];
        require(random.to != address(0), "requestId not exists");
        uint seed = randomResult[_requestId];
        for (uint i = 0; i < random.num; i ++) {
            seed = uint256(keccak256(abi.encodePacked(seed, i)));
            uint nftRange = seed.mod(MAX_END_INDEX);
            uint rangeIndex = 0;
            for (; rangeIndex < rangeInfo[random.rid].length; rangeIndex ++) {
                if (nftRange >= rangeInfo[random.rid][rangeIndex].startIndex && nftRange < rangeInfo[random.rid][rangeIndex].endIndex) {
                    uint nftId = nftIDs[random.rid][random.loop][rangeIndex];
                    nftToken.mint(random.to, nftId, 1, "0x");
                    emit OpenBlindBox(random.rid, random.loop, random.to, rangeIndex, 1, _requestId);
                    break;
                }
            }
            require(rangeIndex < rangeInfo[random.rid].length, "rangeInfo error");
        }
        (uint256 totalBalance, uint256[] memory balances) = nftToken.totalBalance(random.to, nftIDs[random.rid][random.loop]);
        bool win = true;
        if (totalBalance == rangeInfo[random.rid].length) {
            for (uint i = 0; i < balances.length; i ++) {
                if (balances[i] != 1) {
                    win = false;
                    break;
                }
            }
        } else {
            win = false;
        }
        if (win) {
            winers[random.rid][random.loop][random.to] = win;    
            winerNum[random.rid][random.loop] = winerNum[random.rid][random.loop].add(1);
        }
        blindBoxNum[random.rid][random.to] = blindBoxNum[random.rid][random.to].sub(random.num);
        delete randomInfo[_requestId];

        super.finishRandom(_requestId);
    }

    function burnToken(uint _rid, uint _loop, uint _rangeIndex, uint _num) external {
        require(_rid < roomInfo.length, "illegal rid"); 
        RoomInfo storage room = roomInfo[_rid];
        require(_loop > 0 && _loop == room.currentLoop, "loop illegal");
        require(room.totalNum != room.openNum, "loop alrady finish");
        require(_num > 0 && _num <= room.maxBurnNum, "illegal num");
        require(_rangeIndex < rangeInfo[_rid].length, "illegal rangeInfo");
        (, uint[] memory balances) = nftToken.totalBalance(msg.sender, nftIDs[_rid][_loop]);
        require(balances[_rangeIndex] > _num, "illegal balance");
        uint[] memory ids = new uint[](1);
        ids[0] = nftIDs[_rid][_loop][_rangeIndex];
        uint[] memory nums = new uint[](1);
        nums[0] = _num;
        nftToken.burnBatch(msg.sender, ids, nums);
    }

    function claim(uint256 _rid, uint256 _loop, address _to) external {
        require(_rid < roomInfo.length, "illegal rid"); 
        RoomInfo storage room = roomInfo[_rid];
        require(_loop < room.currentLoop || room.openNum == room.totalNum, "loop not finish");
        require(winers[_rid][_loop][_to] == true, "not the winner");
        uint reward = roomReward[_rid][_loop].div(winerNum[_rid][_loop]);

        claimedReward[_rid][_loop] = claimedReward[_rid][_loop].add(reward);
        delete winers[_rid][_loop][_to];
        uint[] memory balances = new uint256[](rangeInfo[_rid].length);
        for (uint i = 0; i < balances.length; i ++) {
            balances[i] = 1;
        }
        nftToken.burnBatch(_to, nftIDs[_rid][_loop], balances);

        tokenTransfer(room.token, _to, reward);
        emit Claim(_rid, _loop, _to, reward);
    }

    function ownerClaim(uint _rid, uint256 _loop) external onlyOwner {
        require(_rid < roomInfo.length, "illegal rid"); 
        RoomInfo storage room = roomInfo[_rid];
        require(room.openNum == room.totalNum, "loop not finish");
        require(_loop < room.currentLoop || room.openNum == room.totalNum, "loop not finish");
        require(winerNum[_rid][_loop] == 0 && roomReward[_rid][_loop] > 0, "already have winner");
        uint amount = roomReward[_rid][_loop];
        delete winerNum[_rid][_loop];
        tokenTransfer(room.token, rewardReceiver, amount);
    }

    function userRecord(uint _rid, address user) external view returns (bool[] memory){
        RoomInfo storage room = roomInfo[_rid];
        bool[] memory res = new bool[](room.totalLoop);
        for (uint i = 1; i <= room.totalLoop; i ++) {
            res[i - 1] = winers[_rid][i][user];
        }
        return res;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/proxy/Initializable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../token/TokenLocker.sol';
import '../core/SafeOwnable.sol';

contract SmartChefInitializable is SafeOwnable, ReentrancyGuard, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The address of the smart chef factory
    address public SMART_CHEF_FACTORY;

    // Whether a limit is set for users
    bool public hasUserLimit;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The block number when CAKE mining ends.
    uint256 public bonusEndBlock;

    // The block number when CAKE mining starts.
    uint256 public startBlock;

    // The block number of the last pool update
    uint256 public lastRewardBlock;

    // The pool limit (0 if none)
    uint256 public poolLimitPerUser;

    // CAKE tokens created per block.
    uint256 public rewardPerBlock;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // The reward token
    IERC20 public rewardToken;

    // The staked token
    IERC20 public stakedToken;

    TokenLocker public tokenLocker;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt
    }

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event NewPoolLimit(uint256 poolLimitPerUser);
    event Withdraw(address indexed user, uint256 amount);

    constructor() SafeOwnable(msg.sender) {
        SMART_CHEF_FACTORY = msg.sender;
    }

    function setTokenLocker(TokenLocker _tokenLocker) external onlyOwner {
        //require(_tokenLocker != address(0), "token locker address is zero"); 
        //emit NewTokenLocker(tokenLocker, _tokenLocker);
        tokenLocker = _tokenLocker;
    }

    /*
     * @notice Initialize the contract
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _startBlock: start block
     * @param _bonusEndBlock: end block
     * @param _poolLimitPerUser: pool limit per user in stakedToken (if any, else 0)
     * @param _admin: admin address with ownership
     */
    function initialize(
        IERC20 _stakedToken,
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _poolLimitPerUser,
        address _admin
    ) external initializer {
        require(msg.sender == SMART_CHEF_FACTORY, "Not factory");

        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        if (_poolLimitPerUser > 0) {
            hasUserLimit = true;
            poolLimitPerUser = _poolLimitPerUser;
        }

        uint256 decimalsRewardToken = uint256(ERC20(address(rewardToken)).decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(10**(uint256(30).sub(decimalsRewardToken)));

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        // Transfer ownership to the admin address who becomes owner of the contract
        setPendingOwner(_admin);
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        if (hasUserLimit) {
            require(_amount.add(user.amount) <= poolLimitPerUser, "User amount above limit");
        }

        _updatePool();

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
            if (pending > 0) {
                if (address(tokenLocker) == address(0) || rewardToken != tokenLocker.token()) {
                    rewardToken.safeTransfer(address(msg.sender), pending);
                } else {
                    rewardToken.approve(address(tokenLocker), pending);
                    tokenLocker.addReceiver(msg.sender, pending);
                }
            }
        }

        if (_amount > 0) {
            uint balanceBefore = stakedToken.balanceOf(address(this));
            stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint balanceAfter = stakedToken.balanceOf(address(this));
            _amount = balanceAfter.sub(balanceBefore);
            user.amount = user.amount.add(_amount);
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);

        emit Deposit(msg.sender, _amount);
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");

        _updatePool();

        uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            stakedToken.safeTransfer(address(msg.sender), _amount);
        }

        if (pending > 0) {
            //rewardToken.safeTransfer(address(msg.sender), pending);
            if (address(tokenLocker) == address(0) || rewardToken != tokenLocker.token()) {
                rewardToken.safeTransfer(address(msg.sender), pending);
            } else {
                rewardToken.approve(address(tokenLocker), pending);
                tokenLocker.addReceiver(msg.sender, pending);
            }
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);

        emit Withdraw(msg.sender, _amount);
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        if (amountToTransfer > 0) {
            stakedToken.safeTransfer(address(msg.sender), amountToTransfer);
        }

        emit EmergencyWithdraw(msg.sender, amountToTransfer);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(stakedToken), "Cannot be staked token");
        require(_tokenAddress != address(rewardToken), "Cannot be reward token");

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner {
        require(startBlock < block.number, "Pool is not started"); 
        require(block.number <= bonusEndBlock, "Pool has ended");
        bonusEndBlock = block.number;
    }

    /*
     * @notice Update pool limit per user
     * @dev Only callable by owner.
     * @param _hasUserLimit: whether the limit remains forced
     * @param _poolLimitPerUser: new pool limit per user
     */
    function updatePoolLimitPerUser(bool _hasUserLimit, uint256 _poolLimitPerUser) external onlyOwner {
        require(hasUserLimit, "Must be set");
        if (_hasUserLimit) {
            require(_poolLimitPerUser > poolLimitPerUser, "New limit must be higher");
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            hasUserLimit = _hasUserLimit;
            poolLimitPerUser = 0;
        }
        emit NewPoolLimit(poolLimitPerUser);
    }

    /*
     * @notice Update reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @dev This function is only callable by owner.
     * @param _startBlock: the new start block
     * @param _bonusEndBlock: the new end block
     */
    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _bonusEndBlock) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        require(_startBlock < _bonusEndBlock, "New startBlock must be lower than new endBlock");
        require(block.number < _startBlock, "New startBlock must be higher than current block");

        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        emit NewStartAndEndBlocks(_startBlock, _bonusEndBlock);
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));
        if (block.number > lastRewardBlock && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 reward = multiplier.mul(rewardPerBlock);
            uint256 adjustedTokenPerShare =
                accTokenPerShare.add(reward.mul(PRECISION_FACTOR).div(stakedTokenSupply));
            return user.amount.mul(adjustedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        } else {
            return user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        }
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));

        if (stakedTokenSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        uint256 reward = multiplier.mul(rewardPerBlock);
        accTokenPerShare = accTokenPerShare.add(reward.mul(PRECISION_FACTOR).div(stakedTokenSupply));
        lastRewardBlock = block.number;
    }

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../interfaces/INftOracle.sol';
import '../token/TokenLocker.sol';
import '../core/SafeOwnable.sol';
import "../token/P2EToken.sol";

contract NftFarm is SafeOwnable, ReentrancyGuard, ERC1155, ERC1155Holder {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum NftType {ERC721, ERC1155}

    struct UserInfo {
        uint256 amount;     
        uint256 rewardDebt; 
    }

    struct PoolInfo {
        address nftContract;
        NftType nftType;
        address priceOracle;
        uint256 allocPoint;       
        uint256 lastRewardBlock;  
        uint256 accPerShare; 
        uint256 totalAmount;
    }

    P2EToken public rewardToken;
    uint256 public rewardPerBlock;
    uint256 public BONUS_MULTIPLIER;
    
    PoolInfo[] public poolInfo;
    mapping(address => uint256) public pidOfContract;
    mapping(address => bool) public existsContract;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    uint256 public totalAllocPoint = 0;
    uint256 public startBlock;
    TokenLocker public tokenLocker;
    mapping(address => mapping(uint => uint)) nftIds;
    uint currentNftId;

    function getNftId(address _nftContract, uint _nftId) internal returns (uint) {
        uint currentId = nftIds[_nftContract][_nftId];
        if (currentId == 0) {
            currentId = currentNftId + 1;
            currentNftId = currentNftId + 1;
            nftIds[_nftContract][_nftId] = currentId;
        }
        return currentId;
    }
    
    event Deposit(address indexed user, uint256 indexed pid, uint256[] ids, uint256[] amounts);
    event Withdraw(address indexed user, uint256 indexed pid, uint256[] ids, uint256[] amounts);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256[] _ids, uint256 amount);
    event NewRewardPerBlock(uint oldReward, uint newReward);
    event NewMultiplier(uint oldMultiplier, uint newMultiplier);
    event NewPool(uint pid, NftType nftType, address nftContract, address priceOracle, uint allocPoint, uint totalPoint);
    event NewTokenLocker(TokenLocker oldTokenLocker, TokenLocker newTokenLocker);

    modifier validatePoolByPid(uint256 _pid) {
        require (_pid < poolInfo.length, "Pool does not exist");
        _;
    }

    function setTokenLocker(TokenLocker _tokenLocker) external onlyOwner {
        //require(_tokenLocker != address(0), "token locker address is zero"); 
        emit NewTokenLocker(tokenLocker, _tokenLocker);
        tokenLocker = _tokenLocker;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    )
        internal
        view
        override
    {
        require(from == address(0) || to == address(0), "NFT CAN ONLY MINT OR BURN");
        require(operator == address(this), "NFT OPERATOR CAN ONLY BE THIS");
    }

    constructor(
        P2EToken _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock
    ) SafeOwnable(msg.sender) ERC1155("") {
        require(address(_rewardToken) != address(0), "illegal rewardToken");
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        BONUS_MULTIPLIER = 1;
    }

    function updateMultiplier(uint256 multiplierNumber, bool withUpdate) external onlyOwner {
        if (withUpdate) {
            massUpdatePools();
        }
        emit NewMultiplier(BONUS_MULTIPLIER, multiplierNumber);
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function updateRewardPerBlock(uint256 _rewardPerBlock, bool _withUpdate) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        emit NewRewardPerBlock(rewardPerBlock, _rewardPerBlock);
        rewardPerBlock = _rewardPerBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(uint256 _allocPoint, NftType _nftType, address _nftContract, address _priceOracle, bool _withUpdate) external onlyOwner {
        require(_nftContract != address(0), "nftContract address is zero");
        require(address(_nftContract) != address(rewardToken), "can not add reward");
        require(!existsContract[_nftContract], "nftContract already exist");
        //check it is a legal nftContract
        if (_priceOracle == address(0)) {
            INftOracle(_nftContract).values(0); 
        } else {
            INftOracle(_priceOracle).valuesOf(_nftContract, 0);
        }
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        pidOfContract[_nftContract] = poolInfo.length;
        existsContract[_nftContract] = true;
        poolInfo.push(PoolInfo({
            nftContract: _nftContract,
            nftType: _nftType,
            priceOracle: _priceOracle,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accPerShare: 0,
            totalAmount: 0
        }));

        emit NewPool(poolInfo.length - 1, _nftType, _nftContract, _priceOracle, _allocPoint, totalAllocPoint);
    }

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyOwner validatePoolByPid(_pid) {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
        }
        emit NewPool(_pid, poolInfo[_pid].nftType, poolInfo[_pid].nftContract, poolInfo[_pid].priceOracle, _allocPoint, totalAllocPoint);
    }

    function pendingReward(uint256 _pid, address _user) external validatePoolByPid(_pid) view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPerShare = pool.accPerShare;
        uint256 lpSupply = pool.totalAmount;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 rewardReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accPerShare = accPerShare.add(rewardReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accPerShare).div(1e12).sub(user.rewardDebt);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }
    
    function updatePool(uint256 _pid) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.totalAmount;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 rewardReward = multiplier.mul(rewardPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        rewardReward = rewardToken.mint(address(this), rewardReward);
        pool.accPerShare = pool.accPerShare.add(rewardReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function getNftValue(PoolInfo storage pool, uint id) internal view returns (uint) {
        if (pool.priceOracle == address(0)) {
            return INftOracle(pool.nftContract).values(id); 
        } else {
            return INftOracle(pool.priceOracle).valuesOf(pool.nftContract, id);
        }
    }
    
    function deposit(uint256 _pid, uint[] memory _ids, uint[] memory _amounts) external nonReentrant validatePoolByPid(_pid) {
        require(_ids.length == _amounts.length, "illegal id num");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                if (address(tokenLocker) == address(0)) {
                    safeRewardTransfer(msg.sender, pending);
                } else {
                    rewardToken.approve(address(tokenLocker), pending);
                    tokenLocker.addReceiver(msg.sender, pending);
                }
            }
        }
        if (_ids.length > 0) {
            uint totalValues = 0;
            uint[] memory innerNftIds = new uint[](_ids.length);
            for (uint i = 0; i < _ids.length; i ++) {
                uint value = getNftValue(pool, _ids[i]);
                totalValues = totalValues.add(value);
                if (pool.nftType == NftType.ERC721) {
                    require(_amounts[i] == 1, "NFT721 CAN ONLY TRANSFER ONE BY ONE");
                    IERC721(pool.nftContract).safeTransferFrom(msg.sender, address(this), _ids[i]);
                }
                innerNftIds[i] = getNftId(pool.nftContract, _ids[i]);
            }
            if (pool.nftType == NftType.ERC1155) {
                IERC1155(pool.nftContract).safeBatchTransferFrom(msg.sender, address(this), _ids, _amounts, new bytes(0));
            }
            _mintBatch(msg.sender, innerNftIds, _amounts, new bytes(0));

            if (totalValues > 0) {
                user.amount = user.amount.add(totalValues);
                pool.totalAmount = pool.totalAmount.add(totalValues);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _ids, _amounts);
    }

    function withdraw(uint256 _pid, uint[] memory _ids, uint[] memory _amounts) external nonReentrant validatePoolByPid(_pid) {
        require(_ids.length == _amounts.length, "illegal id num");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            if (address(tokenLocker) == address(0)) {
                safeRewardTransfer(msg.sender, pending);
            } else {
                rewardToken.approve(address(tokenLocker), pending);
                tokenLocker.addReceiver(msg.sender, pending);
            }
        }
        if (_ids.length > 0) {
            uint totalValues = 0;
            uint[] memory innerNftIds = new uint[](_ids.length);
            for (uint i = 0; i < _ids.length; i ++) {
                uint value = getNftValue(pool, _ids[i]);
                totalValues = totalValues.add(value);
                if (pool.nftType == NftType.ERC721) {
                    require(_amounts[i] == 1, "NFT721 CAN ONLY TRANSFER ONE BY ONE");
                    IERC721(pool.nftContract).safeTransferFrom(address(this), msg.sender, _ids[i]);
                }
                innerNftIds[i] = nftIds[pool.nftContract][_ids[i]];
                require(innerNftIds[i] != 0, "nftContract Id Not exists");
            }
            if (pool.nftType == NftType.ERC1155) {
                IERC1155(pool.nftContract).safeBatchTransferFrom(address(this), msg.sender, _ids, _amounts, new bytes(0));
            }
            _burnBatch(msg.sender, innerNftIds, _amounts);

            require(user.amount >= totalValues, "withdraw: not good");
            if(totalValues > 0) {
                user.amount = user.amount.sub(totalValues);
                pool.totalAmount = pool.totalAmount.sub(totalValues);
            }
        }

        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _ids, _amounts);
    }

    function emergencyWithdraw(uint256 _pid, uint[] memory _ids) external nonReentrant validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (_ids.length > 0) {
            address[] memory accounts = new address[](_ids.length);
            uint[] memory innerNftIds = new uint[](_ids.length);
            uint[] memory amounts = new uint[](_ids.length);
            for (uint i = 0; i < _ids.length; i ++) {
                if (pool.nftType == NftType.ERC721) {
                    IERC721(pool.nftContract).safeTransferFrom(address(this), msg.sender, _ids[i]);
                    amounts[i] = 1;
                }
                innerNftIds[i] = nftIds[pool.nftContract][_ids[i]];
                require(innerNftIds[i] != 0, "nftContract Id Not exists");
                accounts[i] = msg.sender;
            }
            if (pool.nftType == NftType.ERC1155) {
                amounts = IERC1155(pool.nftContract).balanceOfBatch(accounts, innerNftIds);
                IERC1155(pool.nftContract).safeBatchTransferFrom(address(this), msg.sender, _ids, amounts, new bytes(0));
            }
            _burnBatch(msg.sender, innerNftIds, amounts);
        }

        uint amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, _pid, _ids, amount);
    }

    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint currentBalance = IERC20(rewardToken).balanceOf(address(this));
        if (currentBalance < _amount) {
            _amount = currentBalance;
        }
        IERC20(rewardToken).safeTransfer(_to, _amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC1155Receiver.sol";
import "../../utils/Context.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) public {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) external view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface INftOracle {

    function values(uint256 nftId) external view returns (uint256);

    function valuesOf(address nftContract, uint256 nftId) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155Receiver.sol";
import "../../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../core/SafeOwnable.sol';

contract P2EERC1155 is ERC1155, SafeOwnable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 private _currentTokenID = 0;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public types;
    mapping(uint256 => uint256) public values;
    mapping(uint256 => bool) public disableTransfer;
    string public name;
    string public symbol;
    mapping(uint256 => string) private uris;
    string public baseMetadataURI;

    modifier onlyOwnerOrCreator(uint256 id) {
        require(msg.sender == owner() || msg.sender == creators[id], "only owner or creator can do this");
        _;
    }

    function disableTokenTransfer(uint _id) external onlyOwnerOrCreator(_id) {
        disableTransfer[_id] = true;
    }

    function enableTokenTransfer(uint _id) external onlyOwnerOrCreator(_id) {
        disableTransfer[_id] = false;
    }

    constructor(string memory _uri, string memory name_, string memory symbol_) ERC1155(_uri) SafeOwnable(msg.sender) {
        name = name_;
        symbol = symbol_;
        baseMetadataURI = _uri;
    }

    function setURI(string memory newuri) external {
        baseMetadataURI = newuri;
    }

    function uri(uint256 _id) public override view returns (string memory) {
        require(_exists(_id), "ERC1155#uri: NONEXISTENT_TOKEN");

        if(bytes(uris[_id]).length > 0){
            return uris[_id];
        }
        if (types[_id] > 0) {
            return string(abi.encodePacked(baseMetadataURI, "?type=", types[_id].toString()));
        } else {
            return string(abi.encodePacked(baseMetadataURI, "/", _id.toString()));
        }
    }

    function _exists(uint256 _id) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    function updateUri(uint256 _id, string memory _uri) external onlyOwnerOrCreator(_id) {
        if (bytes(_uri).length > 0) {
            uris[_id] = _uri;
            emit URI(_uri, _id);
        }
        else{
            delete uris[_id];
            emit URI(string(abi.encodePacked(baseMetadataURI, _id.toString(), ".json")), _id);
        }
    }

    function create(
        uint256 _maxSupply,
        uint256 _initialSupply,
        uint256 _type,
        bytes memory _data
    ) external returns (uint256 tokenId) {
        require(_initialSupply <= _maxSupply, "Initial supply cannot be more than max supply");
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();
        creators[_id] = msg.sender;
        types[_id] = _type;
        emit URI(string(abi.encodePacked(baseMetadataURI, "?type=", _id.toString())), _id);

        if (_initialSupply != 0) _mint(msg.sender, _id, _initialSupply, _data);
        tokenSupply[_id] = _initialSupply;
        tokenMaxSupply[_id] = _maxSupply;
        return _id;
    }

    function createBatch(
        uint256 _maxSupply,
        uint256 _initialSupply,
        uint256[] memory _types,
        uint256[] memory _values,
        bytes memory _data
    ) public returns (uint256[] memory tokenIds) {
        require(_types.length > 0 && _types.length == _values.length, "illegal type length");
        require(_initialSupply <= _maxSupply, "Initial supply cannot be more than max supply");
        require(_types.length > 0, "illegal type length");
        tokenIds = new uint[](_types.length);
        for (uint i = 0; i < _types.length; i ++) {
            uint id = _currentTokenID.add(i + 1);
            tokenIds[i] = id;
            creators[id] = msg.sender;
            types[id] = _types[i];
            values[id] = _values[i];
            if (_initialSupply != 0) _mint(msg.sender, id, _initialSupply, _data);
            tokenSupply[id] = _initialSupply;
            tokenMaxSupply[id] = _maxSupply;
        }
        _currentTokenID= _currentTokenID.add(_types.length);
    }

    function createBatchDefault(uint256[] memory _types, uint256[] memory _values) external returns (uint256[] memory tokenIds) {
        return createBatch(uint(-1), 0, _types, _values, new bytes(0));
    }

    function _getNextTokenID() private view returns (uint256) {
        return _currentTokenID.add(1);
    }

    function _incrementTokenTypeId() private {
        _currentTokenID++;
    }
    
    function mint(address to, uint256 _id, uint256 _quantity, bytes memory _data) public onlyOwnerOrCreator(_id) {
        uint256 tokenId = _id;
        require(tokenSupply[tokenId].add(_quantity) <= tokenMaxSupply[tokenId], "Max supply reached");
        _mint(to, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }

    function burn(address _account, uint256 _id, uint256 _amount) external onlyOwnerOrCreator(_id) {
        _burn(_account, _id, _amount);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) external {
        for (uint i = 0; i < ids.length; i ++) {
            require(msg.sender == owner() || msg.sender == creators[ids[i]], "only owner or creator can do this");
        }
        _burnBatch(account, ids, amounts);
    }

    function multiSafeTransferFrom(address from, address[] memory tos, uint256 id, uint256[] memory amounts, bytes memory data) external {
        require(tos.length == amounts.length, "illegal num");
        for (uint i = 0; i < tos.length; i ++) {
            safeTransferFrom(from, tos[i], id, amounts[i], data);
        }
    }

    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    )
        internal
        view
        override
    { 
        if (from != address(0) && to != address(0)) {
            for (uint i = 0; i < ids.length; i ++) {
                require(amounts[i] == 0 || !disableTransfer[ids[i]], "Token Transfer Disabled");
            }
        }
    }

    function totalBalance (
        address account,
        uint256[] memory ids
    )
        external
        view
        returns (uint256, uint256[] memory)
    {
        uint256[] memory batchBalances = new uint256[](ids.length);
        uint256 _totalBalance = 0;

        for (uint256 i = 0; i < ids.length; ++i) {
            batchBalances[i] = balanceOf(account, ids[i]);
            _totalBalance = _totalBalance.add(batchBalances[i]);
        }

        return (_totalBalance, batchBalances);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '../libraries/TransferHelper.sol';
import '../interfaces/IP2EERC1155.sol';
import '../interfaces/IWETH.sol';
import '../core/SafeOwnable.sol';
import 'hardhat/console.sol';
import '../core/Random.sol';

contract Invite {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event InviteUser(address user, address inviter);
    event InviterReward(address user, IERC20 _token, address invitee, uint relation, uint amount);
    event ClaimReward(address user, IERC20 token, uint amount);

    uint public constant MAX_HEIGHT = 5;

    address public immutable rootInviter;
    address public immutable WETH;
    mapping(address => address) inviter;
    mapping(address => mapping(IERC20 => uint256[])) inviterReward;
    mapping(IERC20 => uint) lastBalance;

    constructor(address _WETH, address _rootInviter) {
        require(_WETH != address(0), "WETH address is zero");
        WETH = _WETH;
        rootInviter = _rootInviter;
        inviter[_rootInviter] = address(this);
        emit InviteUser(_rootInviter, address(this));
    }

    function registeInviter(address _inviter) external {
        require(inviter[msg.sender] == address(0), "user already have inviter");
        require(inviter[_inviter] != address(0), "inviter have no inviter");
        inviter[msg.sender] = _inviter;
        emit InviteUser(msg.sender, _inviter);
    }

    function inviterTree(address _user, uint _height) external view returns (address[] memory) {
        require(_height < MAX_HEIGHT, "height too much");
        address[] memory inviters = new address[](_height);
        address lastUser = _user;
        for (uint i = 0; i < _height; i ++) {
            lastUser = inviter[lastUser];
            if(lastUser == address(0)){
                break; 
            }
            inviters[i] = lastUser;
        }
        return inviters;
    }

    function sendReward(address _user, IERC20 _token, uint[] memory amounts) external returns (uint) {
        address lastUser = _user;
        uint totalAmount = 0;
        for (uint i = 0; i < amounts.length; i ++) {
            lastUser = inviter[lastUser];
            if (lastUser == address(0)) {
                break;
            }
            uint[] storage reward = inviterReward[lastUser][_token];
            while (reward.length <= i) {
                reward.push(0); 
            }
            reward[i] = reward[i].add(amounts[i]);
            totalAmount = totalAmount.add(amounts[i]);
            emit InviterReward(lastUser, _token, _user, i, amounts[i]);
        }
        uint currentBalance = _token.balanceOf(address(this));
        uint tokenLastBalance = lastBalance[_token];
        require(currentBalance.sub(tokenLastBalance) >= totalAmount, "amount not enough");
        lastBalance[_token] = lastBalance[_token].add(totalAmount);
        if (currentBalance.sub(tokenLastBalance) > totalAmount) {
            _token.safeTransfer(msg.sender, currentBalance.sub(tokenLastBalance).sub(totalAmount));
        }
        return currentBalance.sub(tokenLastBalance).sub(totalAmount);
    }

    function pending(address _user, IERC20[] memory _tokens) public view returns (uint[] memory) {
        uint[] memory userAmounts = new uint[](_tokens.length);
        for (uint i = 0; i < _tokens.length; i ++) {
            uint[] storage amounts = inviterReward[_user][_tokens[i]];
            for (uint j = 0; j < amounts.length; j ++) {
                userAmounts[i] = userAmounts[i].add(amounts[j]);
            }
        }
        return userAmounts;
    }

    function tokenTransfer(IERC20 _token, address _to, uint _amount) internal returns (uint) {
        if (_amount == 0) {
            return 0;
        }
        if (address(_token) == WETH) {
            IWETH(address(_token)).withdraw(_amount);
            TransferHelper.safeTransferETH(_to, _amount);
        } else {
            _token.safeTransfer(_to, _amount);
        }
        return _amount;
    }

    function claim(address _user, IERC20[] memory _tokens) external {
        uint[] memory amounts = pending(_user, _tokens);
        for (uint i = 0; i < amounts.length; i ++) {
            if (amounts[i] > 0) {
                for (uint j = 0; j < inviterReward[_user][_tokens[i]].length; j ++) {
                    inviterReward[_user][_tokens[i]][j] = 0;
                }
                lastBalance[_tokens[i]] = lastBalance[_tokens[i]].sub(amounts[i]);
            }
        }
        for (uint i = 0; i < amounts.length; i ++) {
            tokenTransfer(_tokens[i], _user, amounts[i]);
            emit ClaimReward(_user, _tokens[i], amounts[i]);
        }
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../interfaces/IP2EToken.sol';
import '../token/TokenLocker.sol';
import '../core/SafeOwnable.sol';
import 'hardhat/console.sol';

contract P2EIco {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    event NewReceiver(address receiver, uint sendAmount, uint lastReleaseAt);
    event ReleaseToken(address receiver, uint releaseAmount, uint nextReleaseAmount, uint nextReleaseBlockNum);

    uint256 public constant PRICE_BASE = 1e6;
    ERC20 public immutable sendToken;
    address public immutable sendTokenReceiver;
    IP2EToken public immutable receiveToken;
    uint public immutable icoPrice;
    TokenLocker public tokenLocker;
    uint256 public immutable totalAmount;
    uint256 public remainRelease;

    uint256 public totalReceived;
    uint256 public totalRelease;

    constructor(
        ERC20 _sendToken, address _sendTokenReceiver, IP2EToken _receiveToken, uint _icoPrice, uint256 _totalAmount
    ) {
        require(address(_sendToken) != address(0), "ilelgal send token");
        sendToken = _sendToken;
        //require(_sendTokenReceiver != address(0), "send token receiver is zero");
        //zero address is ok, so no one can retrive the sendToken
        sendTokenReceiver = _sendTokenReceiver;
        require(address(_receiveToken) != address(0), "illegal token");
        receiveToken = _receiveToken;
        require(address(_sendToken) != address(_receiveToken), "sendToken and receiveToken is the same");
        require(_icoPrice > 0, "illegal icoPrice");
        icoPrice = _icoPrice;
        remainRelease = totalAmount = _totalAmount;
    }

    function initTokenLocker(TokenLocker _tokenLocker) external {
        require(address(tokenLocker) == address(0), "tokenLocker already setted");
        tokenLocker = _tokenLocker;
    }

    function deposit(address _receiver, uint256 _amount) external {
        uint balanceBefore = sendToken.balanceOf(address(this));
        sendToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint balanceAfter = sendToken.balanceOf(address(this));
        _amount = balanceAfter.sub(balanceBefore);
        require(_receiver != address(0), "receiver address is zero");
        require(_amount > 0, "release amount is zero");

        uint sendTokenMisDecimal = uint(18).sub(sendToken.decimals());
        uint receiveTokenMisDecimal = uint(18).sub(ERC20(address(receiveToken)).decimals());
        uint receiveAmount = _amount.mul(uint(10) ** (sendTokenMisDecimal)).mul(PRICE_BASE).div(icoPrice).div(uint(10) ** (receiveTokenMisDecimal));
        require(remainRelease >= receiveAmount, "release amount is bigger than reaminRelease");
        totalReceived = totalReceived.add(_amount);
        remainRelease = remainRelease.sub(receiveAmount);
        totalRelease = totalRelease.add(receiveAmount);
        receiveToken.mint(address(this), receiveAmount);
        receiveToken.approve(address(tokenLocker), receiveAmount);
        tokenLocker.addReceiver(_receiver, receiveAmount);
        emit NewReceiver(_receiver, _amount, block.timestamp);
    }

    function claim(address _receiver) external {
        tokenLocker.claim(_receiver); 
    }

    function totalLockAmount() external view returns (uint256) {
        return tokenLocker.totalLockAmount();
    }


    //response1: the timestamp for next release
    //response2: the amount for next release
    //response3: the total amount already released
    //response4: the remain amount for the receiver to release
    function getReleaseInfo(address _receiver) public view returns (uint256 nextReleaseAt, uint256 nextReleaseAmount, uint256 alreadyReleaseAmount, uint256 remainReleaseAmount) {
        if (false) {
            alreadyReleaseAmount = 0;
        }
        (nextReleaseAt, nextReleaseAmount, remainReleaseAmount) = tokenLocker.pending(_receiver);
    }

    function withdraw(uint amount) external {
        uint balance = sendToken.balanceOf(address(this));
        if (amount > balance) {
            amount = balance;
        }
        if (amount > 0) {
            sendToken.safeTransfer(sendTokenReceiver, amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../token/TokenLocker.sol';
import '../core/SafeOwnable.sol';
import 'hardhat/console.sol';

contract ILO is SafeOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;     
        uint256 lastTime;
    }
    struct PoolInfo {
        IERC20 lpToken;           
        uint256 allocPoint;       
        uint256 totalAmount;
    }

    event NewStartSeconds(uint oldSeconds, uint newSeconds);
    event NewEndSeconds(uint oldSeconds, uint newSeconds);
    event OwnerDeposit(address user, uint256 amount, uint totalAmount);
    event OwnerWithdraw(address user, uint256 amount);
    event NewPool(IERC20 lpToken, uint allocPoint, uint totalAllocPoint);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 amount);
    event NewTokenLocker(TokenLocker oldTokenLocker, TokenLocker newTokenLocker);


    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    uint256 public totalAllocPoint = 0;

    IERC20 immutable public rewardToken;
    uint256 public rewardAmount;
    uint256 public startSeconds;
    uint256 public endSeconds;
    uint256 constant public FINISH_WAIT = 7 days;
    TokenLocker public tokenLocker;

    modifier notBegin() {
        require(block.timestamp < startSeconds, "ILO already begin");
        _;
    }

    modifier alreadyFinish() {
        require(block.timestamp > endSeconds + FINISH_WAIT, "ILO not finish");
        _;
    }

    modifier notProcessing() {
        require(block.timestamp < startSeconds || block.timestamp > endSeconds + FINISH_WAIT, "ILO in processing");
        _;
    }

    function setTokenLocker(TokenLocker _tokenLocker) external onlyOwner {
        //require(_tokenLocker != address(0), "token locker address is zero"); 
        emit NewTokenLocker(tokenLocker, _tokenLocker);
        tokenLocker = _tokenLocker;
    }
    /*
    function setStartSeconds(uint256 _startSeconds) external onlyOwner notProcessing {
        emit NewStartSeconds(startSeconds, _startSeconds);
        startSeconds = _startSeconds;
    }

    function setEndSeconds(uint256 _endSeconds) external onlyOwner notProcessing {
        emit NewEndSeconds(endSeconds, _endSeconds);
        endSeconds = _endSeconds;
    }
    */
    constructor(
        IERC20 _rewardToken,
        uint256 _startSeconds,
        uint256 _endSeconds
    ) SafeOwnable(msg.sender) {
        rewardToken = _rewardToken;
        startSeconds = _startSeconds;
        emit NewStartSeconds(0, _startSeconds);
        endSeconds = _endSeconds;
        emit NewEndSeconds(0, _endSeconds);
    }

    function ownerDeposit(uint amount) external notProcessing {
        rewardAmount = rewardAmount.add(amount);     
        SafeERC20.safeTransferFrom(rewardToken, msg.sender, address(this), amount);
        emit OwnerDeposit(msg.sender, amount, rewardAmount);
    }

    function ownerWithdraw(uint amount) external notProcessing onlyOwner {
        uint balance = rewardToken.balanceOf(address(this));
        if (amount > balance) {
            amount = balance;
        }
        rewardAmount = rewardAmount.sub(amount);     
        SafeERC20.safeTransfer(rewardToken, owner(), amount);
        emit OwnerWithdraw(owner(), amount);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(uint256 _allocPoint, IERC20 _lpToken) external notBegin onlyOwner {
        _lpToken.balanceOf(address(this)); //ensure this is a token
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            totalAmount: 0
        }));
        emit NewPool(_lpToken, _allocPoint, totalAllocPoint);
    }

    function deposit(uint256 _pid, uint256 _amount) external {
        require(_pid < poolInfo.length, "illegal pid");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(block.timestamp >= startSeconds && block.timestamp <= endSeconds, "ILO not in processing");
        require(_amount > 0, "illegal amount");

        user.amount = user.amount.add(_amount);
        user.lastTime = block.timestamp;
        pool.totalAmount = pool.totalAmount.add(_amount);
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        emit Deposit(msg.sender, _pid, _amount);
    }

    function pending(uint256 _pid, address _user) public view returns (uint256) {
        require(_pid < poolInfo.length, "illegal pid");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 poolBalance = rewardAmount.mul(pool.allocPoint).div(totalAllocPoint);
        if (pool.totalAmount == 0) {
            return 0;
        }
        return poolBalance.mul(user.amount).div(pool.totalAmount);
    }

    function safeRewardTransfer(address _to, uint256 _amount) internal {
        uint256 balance = rewardToken.balanceOf(address(this));
        if (_amount > balance) {
            _amount = balance;
        }
        rewardToken.safeTransfer(_to, _amount);
    }


    function withdraw(uint256 _pid) external {
        require(block.timestamp > endSeconds, "Can not withdraw now");
        require(_pid < poolInfo.length, "illegal pid");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 pendingAmount = pending(_pid, msg.sender);
        if (pendingAmount > 0) {
            if (address(tokenLocker) == address(0)) {
                safeRewardTransfer(msg.sender, pendingAmount);
            } else {
                rewardToken.approve(address(tokenLocker), pendingAmount);
                tokenLocker.addReceiver(msg.sender, pendingAmount);
            }
            emit Claim(msg.sender, _pid, pendingAmount);
        }
        if (user.amount > 0) {
            uint _amount = user.amount;
            user.amount = 0;
            user.lastTime = block.timestamp;
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            emit Withdraw(msg.sender, _pid, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../swap/P2EFactory.sol';
import '../swap/P2EPair.sol';
import '../ilo/ILO.sol';
contract IloApy {
    using SafeMath for uint;

    uint public constant PRICE_BASE = 10 ** 18;
    uint public immutable PRICE = 500000000000000000; //0.5
    ILO public immutable ilo;
    P2EFactory public immutable factory;
    IERC20 public immutable USDT;

    constructor(ILO _ilo, P2EFactory _factory, IERC20 _USDT) {
        ilo = _ilo;
        factory = _factory;
        USDT = _USDT;
    }

    function calculateAPY(uint rewardAmount, uint allocPoint, uint totalAllocPoint, uint lpAmount, uint totalAmount) internal view returns(uint) {
        uint molecular = rewardAmount.mul(allocPoint).mul(lpAmount).mul(PRICE).div(PRICE_BASE);
        //uint denominator = totalAllocPoint.mul(totalAmount.add(lpAmount)).mul(2).mul(PRICE_BASE);
        uint denominator = totalAllocPoint.mul(totalAmount).mul(2).mul(PRICE_BASE);
        if (denominator != 0) {
            return molecular.mul(1e4).div(denominator);
        } else {
            return 0;
        }
    }

    function calculateLPAmount(P2EPair pair, uint num) internal view returns (uint amount) {
        uint totalSupply = pair.totalSupply();
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        if (pair.token0() == address(USDT)) {
            if (reserve0 != 0) {
                amount = num.mul(totalSupply).div(reserve0); 
            }
        } else {
            if (reserve1 != 0) {
                amount = num.mul(totalSupply).div(reserve1);
            }
        }
    }

    function APY() external view returns (uint256[] memory apys) {
        uint poolLength = ilo.poolLength();
        apys = new uint[](poolLength);
        uint totalAllocPoint = ilo.totalAllocPoint();
        uint rewardAmount = ilo.rewardAmount();
        for (uint i = 0; i < poolLength; i ++) {
            (IERC20 lpToken, uint allocPoint, uint totalAmount) = ilo.poolInfo(i);        
            uint lpAmount = calculateLPAmount(P2EPair(address(lpToken)), PRICE_BASE);
            apys[i] = calculateAPY(rewardAmount, allocPoint, totalAllocPoint, lpAmount, totalAmount);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../swap/P2EFactory.sol';
import '../swap/P2EPair.sol';
import '../farm/MasterChef.sol';
import '../swapmining/Oracle.sol';
contract FarmApy {
    using SafeMath for uint;

    uint public constant PRICE_BASE = 10 ** 18;
    uint public constant YEAR_BLOCK_NUM = 10512000;
    MasterChef public immutable masterChef;
    P2EFactory public immutable factory;
    IERC20 public immutable USDT;
    Oracle public immutable oracle;
    IERC20 public immutable P2E;

    constructor(MasterChef _masterChef, P2EFactory _factory, IERC20 _USDT, Oracle _oracle, IERC20 _P2E) {
        masterChef = _masterChef;
        factory = _factory;
        USDT = _USDT;
        oracle = _oracle;
        P2E = _P2E;
    }

    function calculateAPY(uint price, uint rewardAmount, uint allocPoint, uint totalAllocPoint, uint lpAmount, uint totalAmount) internal view returns(uint) {
        uint molecular = rewardAmount.mul(allocPoint).mul(lpAmount).mul(price).div(PRICE_BASE);
        //uint denominator = totalAllocPoint.mul(totalAmount.add(lpAmount)).mul(2).mul(PRICE_BASE);
        uint denominator = totalAllocPoint.mul(totalAmount).mul(2).mul(PRICE_BASE);
        if (denominator != 0) {
            return molecular.mul(1e4).div(denominator);
        } else {
            return 0;
        }
    }
    
    function calculateLPAmount(P2EPair pair, uint num) internal view returns (uint amount) {
        uint totalSupply = pair.totalSupply();
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        if (pair.token0() == address(USDT)) {
            if (reserve0 != 0) {
                amount = num.mul(totalSupply).div(reserve0); 
            }
        } else {
            if (reserve1 != 0) {
                amount = num.mul(totalSupply).div(reserve1);
            }
        }
    }
    
    function APY() external view returns (uint256[] memory apys) {
        uint poolLength = masterChef.poolLength();
        return rangeAPY(0, poolLength - 1);
    }

    function rangeAPY(uint _startPid, uint _endPid) public view returns(uint256[] memory apys) {
        apys = new uint[](_endPid - _startPid + 1);
        uint totalAllocPoint = masterChef.totalAllocPoint();
        uint rewardAmount = masterChef.rewardPerBlock();
        rewardAmount = rewardAmount.mul(YEAR_BLOCK_NUM);
        uint price = oracle.consult(address(P2E), PRICE_BASE, address(USDT));
        console.log("price: ", price);
        for (uint i = _startPid; i < _endPid; i ++) {
            (IERC20 lpToken, uint allocPoint, , ) = masterChef.poolInfo(i);        
            uint lpAmount = calculateLPAmount(P2EPair(address(lpToken)), PRICE_BASE);
            uint totalAmount = IERC20(address(lpToken)).balanceOf(address(masterChef));
            apys[i] = calculateAPY(price, rewardAmount, allocPoint, totalAllocPoint, lpAmount, totalAmount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '../core/SafeOwnable.sol';
import "hardhat/console.sol";

contract MockToken is ERC20 {
    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        if (decimals_ != 18) {
            _setupDecimals(decimals_);
        }
    }

    function mint (address to_, uint amount_) external {
        _mint(to_, amount_);
    }
}

// SPDX-License-Identifier: MIT


pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './SmartChefInitializable.sol';

contract PoolFactory is SafeOwnable {
    event NewSmartChefContract(address indexed smartChef);

    address[] public allPools;

    function poolLength() external view returns (uint) {
        return allPools.length;
    }

    constructor() SafeOwnable(msg.sender) {
    }

    function deployPool(
        IERC20 _stakedToken,
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _poolLimitPerUser,
        address _admin
    ) external onlyOwner {
        require(_stakedToken.totalSupply() >= 0);
        require(_rewardToken.totalSupply() >= 0);
        require(_stakedToken != _rewardToken, "Tokens must be be different");

        bytes memory bytecode = type(SmartChefInitializable).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_stakedToken, _rewardToken, _startBlock));
        address smartChefAddress;

        assembly {
            smartChefAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        SmartChefInitializable(smartChefAddress).initialize(
            _stakedToken,
            _rewardToken,
            _rewardPerBlock,
            _startBlock,
            _bonusEndBlock,
            _poolLimitPerUser,
            _admin
        );
        allPools.push(smartChefAddress);
        emit NewSmartChefContract(smartChefAddress);
    }
}