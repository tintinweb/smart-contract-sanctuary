/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

pragma solidity ^0.8.0;



contract owned{
    address public owner;
    
    constructor() public{
    
    owner = msg.sender;  
    
    }
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    function transferOwnership (address newOwner) onlyOwner public{
        owner=newOwner;
    }
}
    
contract TokenERC20 is owned {
    
    string public _name;
    string public _symbol;
    uint8 public _decimals=18;
    uint256 public _totalSupply;
    
    mapping (address => uint256) public _balanceOf;
    mapping(address => mapping(address => uint256)) public _allowance;
    mapping (address => bool) public _frozenAccount;
    
    event Transfer (address indexed from, address indexed to, uint256 value);
    event Approval (address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool frozen);
    
    
    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol) public {
        
        _totalSupply = initialSupply * (10 ** uint256(_decimals));   
        _balanceOf[msg.sender] = _totalSupply;
        _name=tokenName;
        _symbol=tokenSymbol;
    
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
      function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    
     function decimals() public view returns (uint8) {
        return 18;
    }
    
    
    function balanceOf(address account) public view returns (uint256) {
        return _balanceOf[account];
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowance[owner][spender];
    }

    
    function _transfer(address _from, address _to, uint _value) internal {
     
     require(_to != address(0));
     require(_balanceOf[_from]>=_value);
     require(_balanceOf[_to] + _value >= _balanceOf[_to]);
     require(!_frozenAccount[msg.sender]);
     
     uint previousBalances = _balanceOf[_from]+ _balanceOf[_to];
     
     _balanceOf[_from] -= _value;
     _balanceOf[_to] += _value;
     
     emit Transfer(_from, _to, _value);
     assert(_balanceOf[_from] + _balanceOf[_to] == previousBalances);
     
        
    }
    
    
    function transfer(address _to, uint256 _value) public returns (bool success){
        
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    
    function transferFrom (address _from, address _to, uint256 _value) public returns (bool success){
        
        require(_value <= _allowance[_from][msg.sender]);
        _allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
        
    
    
    function approve(address _spender, uint256 _value) public
    returns (bool success){
        _allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
 
    function burn (uint256 _value) onlyOwner public returns (bool success) {
        require(_balanceOf[msg.sender] >= _value);
        
        _balanceOf[msg.sender]-=_value;
        _totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
        
    }
    
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success){
        
        require(_balanceOf[_from]>= _value);
        require(_value <=_allowance[_from][msg.sender]);
        
        _balanceOf[_from] -= _value;
        _totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
        
    }
    
    function mint(address target, uint256 amount) onlyOwner public{
         require(target != address(0));
        _balanceOf[target] += amount;
        _totalSupply+=amount;
    }
    
    function freeze(address target, bool freeze) onlyOwner public{
        _frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
}