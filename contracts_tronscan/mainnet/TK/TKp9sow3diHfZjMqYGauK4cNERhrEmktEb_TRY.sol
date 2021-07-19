//SourceUnit: ITRC20.sol

pragma solidity ^0.4.23;
/**
 * @title TRC20 interface (compatible with ERC20 interface)
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface ITRC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//SourceUnit: MinterRole.sol

pragma solidity ^0.4.23;

import "./Roles.sol";

contract MinterRole {

    using Roles for Roles.Role;
	
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;
	
    constructor () internal {

        _addMinter(msg.sender);
    }
	
    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

//SourceUnit: Roles.sol

pragma solidity ^0.4.23;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */

library Roles {

    struct Role {
        mapping (address => bool) bearer;
 	}


    function add(Role storage role, address account) internal {

        require(account != address(0));

        require(!has(role, account));

        role.bearer[account] = true;
    }


    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));
        role.bearer[account] = false;
    }


    function has(Role storage role, address account) internal view returns (bool) {

        require(account != address(0));
        return role.bearer[account];
    }
}

//SourceUnit: SafeMath.sol

pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */

library SafeMath {

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

//SourceUnit: TRC20.sol

pragma solidity ^0.4.23;

import "./ITRC20.sol";
import "./SafeMath.sol";

/**
 * @title Standard TRC20 token (compatible with ERC20 token)
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */

contract TRC20 is ITRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

 
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

 
    function allowance(
        address owner,
        address spender
    )
    public
    view
    returns (uint256)
    {
        return _allowed[owner][spender];
    }


    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }


    function approve(address spender, uint256 value) public returns (bool) {
        //判断地址不为0
        require(spender != address(0));
        //授权转账额度
        _allowed[msg.sender][spender] = value;
        //发布广播
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
    public
    returns (bool)
    {

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

        _transfer(from, to, value);
        return true;
    }


    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
    public
    returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
    public
    returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }


    function _transfer(address from, address to, uint256 value) internal {

        require(to != address(0));

        _balances[from] = _balances[from].sub(value);

        _balances[to] = _balances[to].add(value);

        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }


    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }


    function _burnFrom(address account, uint256 value) internal {

        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
            value);
        _burn(account, value);
    }
}

//SourceUnit: TRY.sol

pragma solidity ^0.4.23;

import "./TRC20.sol";
import "./MinterRole.sol";


contract TRY is TRC20, MinterRole {

    string private _name;

    string private _symbol;

    uint8 private _decimals;

    constructor (string name, string symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }


    function name() public view returns (string) {
        return _name;
    }


    function symbol() public view returns (string) {
        return _symbol;
    }


    function decimals() public view returns (uint8) {
        return _decimals;
    }


    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }


    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }


    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}