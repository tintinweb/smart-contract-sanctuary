// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;



contract AcessControl {


    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;


   function _grantRole(bytes32 role, address account) private {
        _roles[role].members[account] = true;
    }


    function _setupRole(bytes32 role, address account) internal  {
        _grantRole(role, account);
    }


    function hasRole(bytes32 role, address account) public view  returns (bool) {
        return _roles[role].members[account];
    }


}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


import "./ERC20Token.sol";
import "./AccessControl.sol";
import "./Pausable.sol";


contract MyToken is ERC20Token, AcessControl, Pausable {
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
    bytes32 public constant ROLE_MINTER = keccak256("ROLE_MINTER");
    bytes32 public constant ROLE_BURNER = keccak256("ROLE_BURNER");

    constructor(string memory name, string memory symbol) 
        ERC20Token(name, symbol)
    {
        _setupRole(ROLE_ADMIN, msg.sender);
        _setupRole(ROLE_MINTER, msg.sender);
        _setupRole(ROLE_BURNER, msg.sender);
    }

    modifier isAdmin() {
        require(hasRole(ROLE_ADMIN, msg.sender), "You are not Admin");
        _;
    }

    modifier isMinter() {
        require(
            hasRole(ROLE_MINTER, msg.sender),
            "You do not have permision to mint"
        );
        _;
    }

    modifier isBurner() {
        require(
            hasRole(ROLE_BURNER, msg.sender),
            "You do not have permision to burn"
        );
        _;
    }

    function handleMint(address account, uint256 amount) isMinter public {
        mint(account, amount);
    }

    function handleBurn(uint256 amount) isBurner  public {
        burn(msg.sender, amount);
    }
    
    
    function pauseTransfer() public isAdmin {
        pause();
    }

    function unPauseTransfer() public isAdmin {
        unpause();
    }

    function makeTransfer(address to , uint256 value) public payable whenNotPaused returns (bool) {
        return transfer(to, value);
    }
}

// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

pragma solidity ^0.8.0;



contract ERC20Token {


    using SafeMath for uint256;
   
    string public _name;
    string public _symbol;
    uint256 public _totalSupply = 0;
    
    
    uint256 public decimals = 18;
    
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint)) _allowed;
    
    event Transfer (address indexed from, address indexed to, uint value);
    
    constructor (string memory name, string memory symbol)  {
        _name = name;
        _symbol = symbol;
        
    }
    
    function balanceOf(address owner) public view returns (uint) {
        return _balances[owner];
    }
    
    
    function transfer (address to, uint256 value ) public returns (bool) {
        
        require(_balances[msg.sender] >= value, "ERC20: not enough balance to transfer");
        
        _balances[msg.sender].sub(value);
        
        _balances[to].add(value);
        
        emit Transfer(msg.sender, to, value);
        
        return true;
        
        
    }
    
    function mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        
        _totalSupply.add(amount);
        
        _balances[account].add(amount);
        
        emit Transfer(address(0), account, amount);
        
    }
    
    
    function burn (address account, uint256 amount) internal {
        require (account != address(0), "ERC20: burn from the zero address");
        
        uint256 accountBalance = _balances[account];
        
        require(accountBalance > amount, "ERC20: not enough balance to burn");
        
        _totalSupply.sub(amount);
        
        _balances[account].sub(amount);
        
        emit Transfer(account, address(0), amount);
        
    }

    
}

// SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.0;


contract Pausable  {
    
  event Paused();
  event Unpaused();

  bool private _paused = false;

  /**
   * @return true if the contract is paused, false otherwise.
   */
  function isPaused() public view returns(bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(_paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public  whenNotPaused {
    _paused = true;
    emit Paused();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public  whenPaused {
    _paused = false;
    emit Unpaused();
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

