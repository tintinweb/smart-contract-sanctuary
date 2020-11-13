// File: contracts/libraries/SafeMath256.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library SafeMath256 {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/interfaces/ILockSend.sol

pragma solidity 0.6.12;

interface ILockSend {
    event Locksend(address indexed from,address indexed to,address token,uint amount,uint32 unlockTime);
    event Unlock(address indexed from,address indexed to,address token,uint amount,uint32 unlockTime);

    function lockSend(address to, uint amount, address token, uint32 unlockTime) external ;
    function unlock(address from, address to, address token, uint32 unlockTime) external ;
}

// File: contracts/LockSend.sol

pragma solidity 0.6.12;




contract LockSend is ILockSend {
    using SafeMath256 for uint;

    bytes4 private constant _SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 private constant _SELECTOR2 = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    mapping(bytes32 => uint) public lockSendInfos;

    modifier afterUnlockTime(uint32 unlockTime) {
        // solhint-disable-next-line not-rely-on-time
        require(uint(unlockTime) * 3600 < block.timestamp, "LockSend: NOT_ARRIVING_UNLOCKTIME_YET");
        _;
    }

    modifier beforeUnlockTime(uint32 unlockTime) {
        // solhint-disable-next-line not-rely-on-time
        require(uint(unlockTime) * 3600 > block.timestamp, "LockSend: ALREADY_UNLOCKED");
        _;
    }

    function lockSend(address to, uint amount, address token, uint32 unlockTime) public override beforeUnlockTime(unlockTime) {
        require(amount != 0, "LockSend: LOCKED_AMOUNT_SHOULD_BE_NONZERO");
        bytes32 key = _getLockedSendKey(msg.sender, to, token, unlockTime);
        _safeTransferToMe(token, msg.sender, amount);
        lockSendInfos[key] = lockSendInfos[key].add(amount);
        emit Locksend(msg.sender, to, token, amount, unlockTime);
    }

    // anyone can call this function
    function unlock(address from, address to, address token, uint32 unlockTime) public override afterUnlockTime(unlockTime) {
        bytes32 key = _getLockedSendKey(from, to, token, unlockTime);
        uint amount = lockSendInfos[key];
        require(amount != 0, "LockSend: UNLOCK_AMOUNT_SHOULD_BE_NONZERO");
        delete lockSendInfos[key];
        _safeTransfer(token, to, amount);
        emit Unlock(from, to, token, amount, unlockTime);
    }

    function _getLockedSendKey(address from, address to, address token, uint32 unlockTime) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(from, to, token, unlockTime));
    }

    function _safeTransferToMe(address token, address from, uint value) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(_SELECTOR2, from, address(this), value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "LockSend: TRANSFER_TO_ME_FAILED");
    }

    function _safeTransfer(address token, address to, uint value) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(_SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "LockSend: TRANSFER_FAILED");
    }
}