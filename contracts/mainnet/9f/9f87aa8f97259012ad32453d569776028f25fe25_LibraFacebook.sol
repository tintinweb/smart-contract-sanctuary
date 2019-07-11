/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity ^0.4.24;
interface Interfacemc {
  
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

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


contract LibraFacebook is Interfacemc{
    using SafeMath for uint256;
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 public totalSupply;
    string public name = "Libra Facebook"; 
    uint8 public decimals = 8; 
    string public symbol = "LBA";
    address private _owner;
    
    mapping (address => bool) public _notransferible;
    mapping (address => bool) private _administradores; 
    
    constructor() public{
        _owner = msg.sender;
        totalSupply = 1000000000000000000;
        _balances[_owner] = totalSupply;
        _administradores[_owner] = true;
    }

    function isAdmin(address dir) public view returns(bool){
        return _administradores[dir];
    }
    
    modifier OnlyOwner(){
        require(msg.sender == _owner, "Not an admin");
        _;
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

    function _transfer(address from, address to, uint256 value) internal {
        require(!_notransferible[from], "No authorized ejecutor");
        require(value <= _balances[from], "Not enough balance");
        require(to != address(0), "Invalid account");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Invalid account");

        _allowed[msg.sender][spender] = value;
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
        require(value <= _allowed[from][msg.sender], "Not enough approved ammount");
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
        require(spender != address(0), "Invalid account");

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
        require(spender != address(0), "Invalid account");

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _burn(address account, uint256 value) internal {
        require(account != 0, "Invalid account");
        require(value <= _balances[account], "Not enough balance");

        totalSupply = totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _burnFrom(address account, uint256 value) internal {
        require(value <= _allowed[account][msg.sender], "No enough approved ammount");
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
    }

    function setTransferible(address admin, address sujeto, bool state) public returns (bool) {
        require(_administradores[admin], "Not an admin");
        _notransferible[sujeto] = state;
        return true;
    }

    function setNewAdmin(address admin)public OnlyOwner returns(bool){
        _administradores[admin] = true;
        return true;
    }  

}