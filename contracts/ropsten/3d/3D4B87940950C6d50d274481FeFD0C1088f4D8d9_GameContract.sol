pragma solidity ^0.6.0;

import "./access/ManagerRole.sol";

import "./math/SafeMath.sol";

import "./interface/ITRC20.sol";

contract GameContract is ManagerRole {
  using SafeMath for uint256;

  event DepositETH(address player, uint256 amount);
  event DepositUSDT(address player, uint256 amount);
  event TransferETH(address to, uint256 amount);
  event TransferUSDT(address to, uint256 amount);

  // Title contract
  string private _title;
  // USDT token contract
  address private _usdt;

  // Players deposites to contract (buyIn)
  mapping (address => uint256) private _depositesETH;
  // Count wager ETH
  mapping (address => uint256) private _wagerOfETH;
  // Players deposites to contract (buyIn)
  mapping (address => uint256) private _depositesUSDT;
  // Count wager USDT
  mapping (address => uint256) private _wagerOfUSDT;

  constructor () public {
    _title = "GameContract";
  }

  /**
   * @dev Receive ETH
   */
  receive() external payable {}

  /**
   * @dev BuyIn - deposit ETH to the platform
   * @return A boolean that indicates if the operation was successful.
   */
  function depositETH() public payable returns (bool) {
    _depositesETH[msg.sender] = _depositesETH[msg.sender].add(msg.value);
    
    emit DepositETH(msg.sender, msg.value);
    return true;
  }

  /**
   * @dev Function to payout ETH
   * @param to The address that will receive the ETH.
   * @param value The amount of tokens to wager.
   * @return A boolean that indicates if the operation was successful.
   */
  function transferToETH(address payable to, uint256 value) public onlyManager returns (bool) {
    _wagerOfETH[msg.sender] = _wagerOfETH[msg.sender].add(value);
    to.transfer(value);

    emit TransferETH(to, value);
    return true;
  }

  /**
   * @dev BuyIn - deposit USDT to the platform.
   * @param value Amount deposit USDT.
   * @return A boolean that indicates if the operation was successful.
   */
  function depositUSDT(uint256 value) public returns (bool) {
    ITRC20 _token = ITRC20(_usdt);
    _token.transferFrom(msg.sender, address(this), value);

    _depositesUSDT[msg.sender] = _depositesUSDT[msg.sender].add(value);

    emit DepositUSDT(msg.sender, value);
    return true;
  }

  /**
   * @dev BuyIn - deposit USDT to the platform
   * @return A boolean that indicates if the operation was successful.
   */
  function transferToUSDT(address to, uint256 value) public onlyManager returns (bool) {
    ITRC20 _token = ITRC20(_usdt);
    _token.transfer(to, value);

    _wagerOfUSDT[msg.sender] = _wagerOfUSDT[msg.sender].add(value);

    emit TransferUSDT(to, value);
    return true;
  }

  /**
   * @dev Set usdt token contract
   * @param usdt address contract.
   * @return A boolean that indicates if the operation was successful.
   */
  function setUSDTContract(address usdt) public onlyManager returns (bool) {
    _usdt = usdt;
    return true;
  }

  /**
   * @dev Get BuyIn USDT sender
   * @param player Sender deposit.
   * @return A boolean that indicates if the operation was successful.
   */
  function depositOfETH(address player) public view returns (uint256) {
    return _depositesETH[player];
  }

  /**
   * @dev Get count payout ETH
   * @param owner The address that will receive the ETH.
   */
  function wagerOfETH(address owner) public view returns (uint256) {
    return _wagerOfETH[owner];
  }

  /**
   * @dev Get BuyIn USDT sender
   * @param player Sender deposit.
   */
  function depositOfUSDT(address player) public view returns (uint256) {
    return _depositesUSDT[player];
  }

  /**
   * @dev Get count payout USDT
   * @param owner The address that will receive the USDT.
   */
  function wagerOfUSDT(address owner) public view returns (uint256) {
    return _wagerOfUSDT[owner];
  }

  /**
   * @dev Get usdt token contract
   */
  function getUSDTContract() public view returns (address) {
    return _usdt;
  }
}

pragma solidity ^0.6.0;

import "./lib/Roles.sol";

contract ManagerRole {
    using Roles for Roles.Role;

    event ManagerAdded(address indexed account);
    event ManagerRemoved(address indexed account);

    Roles.Role private _managers;

    constructor () internal {
        _addManager(msg.sender);
    }

    modifier onlyManager() {
        require(isManager(msg.sender), "ManagerRole: caller does not have the Manager role");
        _;
    }

    function isManager(address account) public view returns (bool) {
        return _managers.has(account);
    }

    function getManagerAddresses() public view returns (address[] memory) {
        return _managers.accounts;
    }

    function addManager(address account) public onlyManager {
        _addManager(account);
    }

    function renounceManager() public {
        _removeManager(msg.sender);
    }

    function _addManager(address account) internal {
        _managers.add(account);
        emit ManagerAdded(account);
    }

    function _removeManager(address account) internal {
        _managers.remove(account);
        emit ManagerRemoved(account);
    }
}

pragma solidity ^0.6.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        address[] accounts;
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
        role.accounts.push(account);
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        
        for (uint256 i; i < role.accounts.length; i++) {
            if (role.accounts[i] == account) {
                _removeIndexArray(i, role.accounts);
                break;
            }
        }
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }

    function _removeIndexArray(uint256 index, address[] storage array) internal virtual {
        for(uint256 i = index; i < array.length-1; i++) {
            array[i] = array[i+1];
        }
        
        array.pop();
    }
}

pragma solidity ^0.6.0;

/**
 * @title TRC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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