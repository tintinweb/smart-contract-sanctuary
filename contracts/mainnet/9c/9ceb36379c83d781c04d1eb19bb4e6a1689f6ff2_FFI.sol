/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

pragma solidity ^0.5.2;

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


pragma solidity ^0.5.2;

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
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}



pragma solidity ^0.5.2;

contract FFI is IERC20 {

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    string public name = "FFI";
    string public symbol = "FFI";
    uint8 public decimals = 18;
    uint256 private _totalSupply = 1000000000 * 10 ** uint256(decimals);

    constructor() public {
      _balances[msg.sender] = _totalSupply;
    }

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

    function approve(address spender, uint256 value) public returns (bool) {
      _approve(msg.sender, spender, value);
      return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
      _transfer(from, to, value);
      _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
      return true;
    }

    function burn(uint256 value) public {
      _burn(msg.sender, value);
    }

    function burnFrom(address from, uint256 value) public {
      _burnFrom(from, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
      _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
      return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
      _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
      return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
      require(to != address(0));

      _balances[from] = _balances[from].sub(value);
      _balances[to] = _balances[to].add(value);
      emit Transfer(from, to, value);
    }

    function _burn(address account, uint256 value) internal {
      require(account != address(0));

      _totalSupply = _totalSupply.sub(value);
      _balances[account] = _balances[account].sub(value);
      emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
      require(spender != address(0));
      require(owner != address(0));

      _allowed[owner][spender] = value;
      emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 value) internal {
      _burn(account, value);
      _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}