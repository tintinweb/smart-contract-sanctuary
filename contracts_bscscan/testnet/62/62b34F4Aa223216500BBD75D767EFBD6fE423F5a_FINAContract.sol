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

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FINAContract {
    string public constant _name = "Defina Finance";
    string public constant _symbol = "FINA";
    uint8 public constant _decimals = 18;


    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event MinterChanged(address indexed from, address to);
    event Mint(address minter, uint256 amount);
    event MintTo(address minter, uint256 amount);
    event NewOwnerAdded(address newOwner);
    event Burn(address burnAddress, uint256 amount);


    mapping(address => uint256) _balances;

    mapping(address => mapping(address => uint256)) _allowance;

    address public _minter;

    address[] public _owners;

    uint256 private _totalSupply;


    using SafeMath for uint256;


    constructor() public {
        _minter = msg.sender;
        _owners.push(_minter);
    }
    function symbol() public  view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public  view returns (uint256) {
        return _totalSupply;
    }

    function owners()public view returns (address[] memory)
    {
        return _owners;
    }

    function passMinterRole(address newMinter) public returns (bool) {
        require(msg.sender == _minter, 'Error: only minter can pass minter role');
        _minter = newMinter;
        emit MinterChanged(msg.sender, _minter);
        return true;
    }

    function isOwner(address user) public returns (bool) {
        for (uint i = 0; i < _owners.length; i++) {
            if (_owners[i] == user)
            {
                return true;
            }
        }
        return false;
    }

    function mint(uint256 amount) public {
        require(isOwner(msg.sender), 'Error: only owner can mint token');
        address receiver = msg.sender;
        _totalSupply = _totalSupply.add(amount);
        _balances[receiver] = _balances[receiver].add(amount);
        emit Mint(receiver, amount);
    }

    function mintTo(address receiver,uint256 amount) public {
        require(isOwner(msg.sender), 'Error: only owner can mint token');
        _totalSupply = _totalSupply.add(amount);
        _balances[receiver] = _balances[receiver].add(amount);
        emit MintTo(receiver, amount);
    }

    function addOwner(address newOwner) public {
        require(msg.sender == _minter, 'Error: only minter can add new owner');
        _owners.push(newOwner);
        emit NewOwnerAdded(newOwner);
    }

    function burn(address account, uint256 amount) public {
        require(account != address(0), 'Error: burn from the zero address');
        require(isOwner(msg.sender), 'Error: only owner can burn token');
        require(amount<= _balances[account], 'Error: this account doesnt have enough balance to burn');
    _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Burn(account, amount);
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return _balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public payable returns (bool)  {
        require(_allowance[msg.sender][receiver] >= numTokens, "Error: Not Enough allowance");
        require(numTokens <= _balances[msg.sender], "Error: Not Enough Balance");
        _balances[msg.sender] = _balances[msg.sender].sub(numTokens);
        _balances[receiver] = _balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        _allowance[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return _allowance[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public payable returns (bool) {
        require(numTokens <= _balances[owner], "Error: Owner balance is not enough");
        require(numTokens <= _allowance[owner][buyer], "Error: Owner allowance is not enough");
        _balances[owner] = _balances[owner].sub(numTokens);
        _allowance[owner][buyer] = _allowance[owner][buyer].sub(numTokens);
        _balances[buyer] = _balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

