/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ERC20{
    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function totalSupply() external view returns (uint );

    function decimals() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function approve(address sender , uint value)external returns(bool);

    function allowance(address sender, address spender) external view returns (uint256);

    function transfer(address recepient , uint value) external returns(bool);

    function transferFrom(address sender,address recepient, uint value) external returns(bool);

    event Transfer(address indexed from , address indexed to , uint value);

    event Approval(address indexed sender , address indexed  spender , uint value);
}

contract context{
    constructor () {}
   function _msgsender() internal view returns (address) {
    return msg.sender;
  }
}


library safeMath{
    function add(uint a , uint b) internal pure returns(uint){
        uint c = a+ b;
        require(c >= a, "amount exists");
        return c;
    }
    function sub(uint a , uint b , string memory errorMessage) internal pure returns(uint){
        uint c = a - b;
        require( c <= a , errorMessage );
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract Token is ERC20,context{
    using safeMath for uint;
    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) _allowances;
    address public Owner;

    string private _name;
    string private _symbol;
    uint private _decimal;
    uint private _totalSupply;

    constructor(){
        Owner = msg.sender;
       _name = "OGGY";
       _symbol = "OGG";
       _decimal = 18;
       _totalSupply = 100000000*10**18;
       _balances[_msgsender()] = _totalSupply;
    }

      modifier OnlyOwner{
        require(Owner == msg.sender,"only owner can update");
        _;
    }

    function name() external override view returns(string memory){
        return _name;
    }
    function symbol() external view override returns(string memory){
        return _symbol;
    }
    function decimals() external view override  returns(uint){
        return _decimal;
    }
    function balanceOf(address owner) external view override  returns(uint){
        return _balances[owner];
    }
    function totalSupply() external view override  returns(uint){
        return _totalSupply;
    }
    function approve(address spender , uint value) external override returns(bool){
        _approve(_msgsender(), spender , value);
        return true;
    }
    function allowance(address sender , address spender) external view override returns(uint){
          return _allowances[sender][spender];
    }
    function transfer(address recepient , uint value) external override returns(bool){
        _transfer(msg.sender, recepient,value);
         return true;
    }

     function transferFrom(address sender ,address recepient, uint amount) external override returns(bool){
        _approve(sender, _msgsender(), _allowances[sender][_msgsender()].sub(amount,"exceeds allownace"));
        _transfer(sender,recepient,amount);
        return true;
    }
    // 98999999999989945328
    // 98999999999989899379

    function mint(uint256 amount) public OnlyOwner returns (bool) {
        _mint(Owner, amount);
        return true;
    }

    function burn(uint256 amount) public OnlyOwner returns (bool) {
        _burn(Owner, amount);
        return true;
    }

    function _transfer(address sender,address recepient, uint value) internal  returns(bool success){
        require(_balances[sender] >= value,"Balance not enough");
        _balances[sender] = _balances[sender].sub(value,"Exceeds balance");
        _balances[recepient] = _balances[recepient].add(value);
        emit Transfer(_msgsender(), recepient , value);
        return true;
    }

    function _approve(address sender,address spender, uint amount) internal returns(bool success){
        require(_balances[_msgsender()] >= amount,"balance not enough");
        _allowances[sender][spender] = amount;
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal {
       require(account != address(0), "BEP20: burn from the zero address");
       _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
       _totalSupply = _totalSupply.sub(amount,"cant burn");
       emit Transfer(account, address(0), amount);
    }
}