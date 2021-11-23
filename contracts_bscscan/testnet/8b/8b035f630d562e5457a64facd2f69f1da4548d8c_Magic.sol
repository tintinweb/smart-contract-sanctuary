/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

pragma solidity ^0.5.2;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b,"Invalid values");
        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0,"Invalid values");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a,"Invalid values");
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a,"Invalid values");
        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0,"Invalid values");
        return a % b;
    }
}

contract Magic is IERC20 {
    using SafeMath for uint256;
    address private _owner;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint256 public airdropcount = 0;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    constructor (string memory name, string memory symbol, uint8 decimals, uint256 totalSupply, address owner) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalSupply = totalSupply*(10**uint256(decimals));
        _balances[owner] = _totalSupply;
        _owner = owner;
    }

    /*----------------------------------------------------------------------------
     * Functions for owner
     *----------------------------------------------------------------------------
     */

    /**
    * @dev get address of smart contract owner
    * @return address of owner
    */
    function getowner() public view returns (address) {
        return _owner;
    }

    /**
    * @dev modifier to check if the message sender is owner
    */
    modifier onlyOwner() {
        require(isOwner(),"You are not authenticate to make this transfer");
        _;
    }

    /**
     * @dev Internal function for modifier
     */
    function isOwner() internal view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfer ownership of the smart contract. For owner only
     * @return request status
      */
    function transferOwnership(address newOwner) public onlyOwner returns (bool){
        _owner = newOwner;
        return true;
    }


    /* ----------------------------------------------------------------------------
     * View only functions
     * ----------------------------------------------------------------------------
     */

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Total number of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
            _transfer(msg.sender, to, value);
            return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
             _transfer(from, to, value);
             _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
             return true;
    }

    function airdropByOwner(address[] memory _addresses, uint256[] memory _amount) public onlyOwner returns (bool){
          require(_addresses.length == _amount.length,"Invalid Array");
          uint256 count = _addresses.length;
          for (uint256 i = 0; i < count; i++){
               _transfer(msg.sender, _addresses[i], _amount[i]);
               airdropcount = airdropcount + 1;
          }
          return true;
      }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0),"Invalid to address");
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0),"Invalid address");
        require(owner != address(0),"Invalid address");
        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0),"Invalid account");
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function burn(uint256 value) public onlyOwner{
        _burn(msg.sender, value);
    }
}