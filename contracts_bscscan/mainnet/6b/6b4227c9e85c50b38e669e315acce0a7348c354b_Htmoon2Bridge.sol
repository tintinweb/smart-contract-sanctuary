/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract Htmoon2Bridge {
    using SafeMath for uint256;

    uint256 public minSignatures;
    address public admin;
    address private newAdmin;
    IERC20 public token;
    uint256 public nonce;
    mapping(address => mapping(string => bool)) public processedSignatory;
    mapping(uint256 => mapping(uint256 => bool)) public processedNonces;
    address[] public signatories;
    mapping(address => bool) public isSignatory;
    mapping(string => uint256) public confirmBridgeFrom;

    event SetSignatoriesEvent(address[] signatories_);

    event BridgeToEvent(
        address indexed from,
        uint256 indexed toTarget,
        uint256 indexed nonce,
        address to,
        uint256 amount,
        uint256 date,
        uint256 eventType
    );

    event ConfirmBridgeFromEvent(
        address indexed from,
        uint256 indexed fromTarget,
        uint256 indexed fromNonce,
        uint256 count,
        address to,
        uint256 amount,
        uint256 date
    );

    event BridgeFromEvent(
        address indexed from,
        uint256 indexed fromTarget,
        uint256 indexed fromNonce,
        address to,
        uint256 amount,
        uint256 date
    );

    constructor(address _token) {
        admin = msg.sender;
        token = IERC20(_token);
        minSignatures = 2;
    }

    function toString(uint256 value) internal pure returns (string memory) {
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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function setAdmin(address _newAdmin) external {
        require(msg.sender == admin, "only admin");
        newAdmin = _newAdmin;
    }

    function confirmAdmin() external {
        require(msg.sender == newAdmin, "only new admin");
        admin = newAdmin;
        newAdmin == address(0);
    }

    function setMinSignatures(uint256 _minSignatures) external {
        require(msg.sender == admin, "only admin");
        require(_minSignatures > 0, "must be more than 0");
        minSignatures = _minSignatures;
    }

    function bridgeTo(
        address to,
        uint256 toTarget,
        uint256 amount
    ) external {
        token.transferFrom(msg.sender, address(this), amount);
        nonce++;
        emit BridgeToEvent(
            msg.sender,
            toTarget,
            nonce,
            to,
            amount,
            block.timestamp,
            0
        );
    }

    function adminBridgeFrom(
        address from,
        address to,
        uint256 fromTarget,
        uint256 amount,
        uint256 fromNonce
    ) external {
        require(msg.sender == admin, "only admin");
        require(
            processedNonces[fromTarget][fromNonce] == false,
            "transfer already processed"
        );
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "not enough balance");
        processedNonces[fromTarget][fromNonce] = true;

        token.transfer(to, amount);
        emit BridgeFromEvent(
            from,
            fromTarget,
            fromNonce,
            to,
            amount,
            block.timestamp
        );
    }

    function bridgeFrom(
        address from,
        address to,
        uint256 fromTarget,
        uint256 amount,
        uint256 fromNonce
    ) external {
        require(isSignatory[msg.sender], "only signatory");
        require(
            processedNonces[fromTarget][fromNonce] == false,
            "transfer already processed"
        );
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount, "not enough balance");
        string memory signatoryKey = string(
            abi.encodePacked(fromTarget, fromNonce)
        );
        require(
            processedSignatory[msg.sender][signatoryKey] == false,
            "transfer already confirmed"
        );
        processedSignatory[msg.sender][signatoryKey] = true;

        confirmBridgeFrom[signatoryKey]++;
        if (confirmBridgeFrom[signatoryKey] >= minSignatures) {
            processedNonces[fromTarget][fromNonce] = true;
            token.transfer(to, amount);
            emit BridgeFromEvent(
                from,
                fromTarget,
                fromNonce,
                to,
                amount,
                block.timestamp
            );
        } else {
            emit ConfirmBridgeFromEvent(
                from,
                fromTarget,
                fromNonce,
                confirmBridgeFrom[signatoryKey],
                to,
                amount,
                block.timestamp
            );
        }
    }

    function setSignatories(address[] calldata _signatories) external {
        require(msg.sender == admin, "only admin");
        require(_signatories.length > 0, "must be more than 0");

        for (uint256 i = 0; i < signatories.length; i++)
            isSignatory[signatories[i]] = false;

        signatories = _signatories;

        for (uint256 i = 0; i < signatories.length; i++)
            isSignatory[signatories[i]] = true;

        emit SetSignatoriesEvent(_signatories);
    }
}