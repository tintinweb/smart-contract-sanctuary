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
    
    string public name;
    string public symbol;
    uint8 public decimals=18;
    uint256 public totalSupply;
    
    mapping (address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    
    event Transfer (address indexed from, address indexed to, uint256 value);
    event Approval (address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool frozen);
    
    
    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol) public {
        
        totalSupply=initialSupply*10**uint256(decimals);     
        balanceOf[msg.sender] = totalSupply;
        name=tokenName;
        symbol=tokenSymbol;
    
    }
    
    function _name() public view returns (string memory) {
        return name;
    }
    
      function _symbol() public view returns (string memory) {
        return symbol;
    }
    
    function _totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    
    
     function _decimals() public view returns (uint8) {
        return 18;
    }
    
    
    function _balanceOf(address account) public view returns (uint256) {
        return balanceOf[account];
    }
    
    function _allowance(address owner, address spender) public view returns (uint256) {
        return allowance[owner][spender];
    }

    
    function _transfer(address _from, address _to, uint _value) internal {
     
     require(_to != address(0));
     require(balanceOf[_from]>=_value);
     require(balanceOf[_to] + _value >= balanceOf[_to]);
     require(!frozenAccount[msg.sender]);
     
     uint previousBalances = balanceOf[_from]+ balanceOf[_to];
     
     balanceOf[_from] -= _value;
     balanceOf[_to] += _value;
     
     emit Transfer(_from, _to, _value);
     assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
     
        
    }
    
    
    function transfer(address _to, uint256 _value) public returns (bool success){
        
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    
    function transferFrom (address _from, address _to, uint256 _value) public returns (bool success){
        
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
        
    
    
    function approve(address _spender, uint256 _value) public
    returns (bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
 
    function burn (uint256 _value) onlyOwner public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        
        balanceOf[msg.sender]-=_value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
        
    }
    
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success){
        
        require(balanceOf[_from]>= _value);
        require(_value <=allowance[_from][msg.sender]);
        
        balanceOf[_from] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
        
    }
    
    function mintToken (address target, uint256 mintedAmount) onlyOwner public{
        balanceOf[target] +=mintedAmount;
        totalSupply+=mintedAmount;
    }
    
    function freezeAccount (address target, bool freeze) onlyOwner public{
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
}