/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0;

//ERC20
interface ERC20 {
   
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external  returns (uint remaining);
   
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

//ERC223
interface ERC223 {
    function transfer(address _to, uint _value, bytes memory _data) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

//ERC223ReceivingContract
abstract contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes memory _data) virtual public;
}

//Token
abstract contract Token {
   string  _symbol;
   string  _name;
   uint8  _decimals;
   uint  _totalSupply;
    
    mapping (address => uint) internal _balanceOf;
    mapping (address => mapping (address => uint)) internal _allowances;
    
    constructor(string memory symbol1, string memory name1, uint8  decimals1, uint  totalSupply1)  {
        _symbol = symbol1;
        _name = name1;
        _decimals = decimals1;
        _totalSupply = totalSupply1;
    }
    
    function name() public  virtual returns (string memory) {
        return _name;
    }
    
    function symbol() public  virtual returns (string memory) {
        return _symbol;
    }
    
    function decimals() public  virtual returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public   virtual returns (uint) {
        return _totalSupply;
    }
    
    function balanceOf(address  _addr) virtual public  returns (uint256);
    function transfer(address _to, uint256  _value) virtual public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256  _value);
}

//AIORYX Coin 


 contract AIORYX is Token("ARX", "AIORYX", 18, 100000000000000000000000000), ERC20, ERC223  {

    //mapping (address => uint) private _balanceOf;
    //mapping (address => mapping(address => uint)) private _allowances;
    
    constructor()  {
        _balanceOf[msg.sender] = _totalSupply;
    }
    
    function isContract(address _addr) public view returns (bool) {
        uint codeSize;
        assembly {
            codeSize := extcodesize(_addr)
        }
        return  codeSize > 0;
    }
    
    function totalSupply() public view  override returns (uint) {
        return _totalSupply;
        
    }
    
    function balanceOf(address _owner) public view override returns (uint balance) {
        return _balanceOf[_owner];
    }
    
    function transfer(address _to, uint _value) public override returns (bool success) {
        if (_value > 0 && 
        _value <= _balanceOf[msg.sender] &&
        !isContract(_to)){
            _balanceOf[msg.sender] -= _value;
            _balanceOf[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }
    
        function transfer(address _to, uint _value, bytes memory _data) public override returns (bool) {
        if (_value > 0 &&
            _value <= _balanceOf[msg.sender] &&
            isContract(_to)) {
            _balanceOf[msg.sender] -= _value;
            _balanceOf[_to] += _value;
            ERC223ReceivingContract _contract = ERC223ReceivingContract(_to);
            _contract.tokenFallback(msg.sender, _value, _data);
            Transfer(msg.sender, _to, _value, _data);
            return true;
        }
        return false;
    }

    
    function transferFrom(address _from, address _to, uint _value) public override returns (bool success){
        if(_allowances[_from][msg.sender] > 0 &&
           _value > 0 &&
           _allowances[_from][msg.sender] >= _value &&
           _balanceOf[_from] >= _value) {
               _balanceOf[_from] -= _value;
               _balanceOf[_to] += _value;
               _allowances[_from][msg.sender] -= _value;
              emit Transfer(_from,_to,_value);
               return true;
           }
           return false;
    }
    
    function approve(address _spender, uint _value) public override returns (bool success){
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
        
    }
    
    function allowance(address _owner, address _spender) public  view override returns (uint remaining){
        //if(_allowances[_owner]) {
         return  _allowances[_owner][_spender];
        //}
        //return 0;
    }
}