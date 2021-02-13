/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

pragma solidity ^0.4.24;

contract Token {
    
    string public name;
    string public symbol;
    uint8 public decimals = 4;
    
    uint public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor(string initName, string initSymbol, uint initSupply) public {
        totalSupply = initSupply*10**uint256(decimals);
        name = initName;
        symbol = initSymbol;
        balanceOf[msg.sender] = totalSupply;
    }
    
   function name() external view returns (string){
       return name;
   }
   
   function symbol() external view returns (string){
       return symbol;
   }
   
   function decimals() external view returns (uint8){
       return decimals;
   }
   
   function totalSupply() external view returns (uint256){
       return totalSupply;
   }
   
   function balanceOf(address _owner) public view returns (uint256 balance){
       return balanceOf[_owner];
   }
   
   function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowance[_owner][_spender];
    }
    
    function _transfer(address _from,address _to, uint256 _value) internal {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
    
    function transfer(address _to, uint256 _value) public returns(bool success){
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success){
        require(allowance[_from][msg.sender] >= _value);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from,_to,_value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success){
        // require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
}