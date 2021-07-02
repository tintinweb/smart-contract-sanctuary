/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

pragma solidity ^0.4.24;

contract TokenERC20{
    
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalsupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approve(address owner, address spender, uint256 value);
    
    constructor(
        uint256 initialsupply,
        string tokenName,
        string tokensymbol
        ) public {
            totalsupply = initialsupply*10**uint256(decimals);
            balanceOf[msg.sender] = totalsupply;
            name = tokenName;
            symbol = tokensymbol;
        }
        
        function _transfer(address _from, address _to, uint _value) internal{
            
            require(_to != 0x0);
            require(balanceOf[_from] >= _value);
            require(balanceOf[_to] + _value >= balanceOf[_to]);
            
            uint previousBalances = balanceOf[_from] + balanceOf[_to];
            
            balanceOf[_from] -= _value;
            balanceOf[_to] += _value;
            
            emit Transfer(_from, _to, _value);
            assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
            
        }
        
        function transfer(address _to, uint256 _value) public returns(bool success){
            
            _transfer(msg.sender, _to, _value);
            return true;
        }
        
         function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
             
             require(_value <= allowance[_from][msg.sender]);
             allowance[_from][msg.sender] -= _value;
             _transfer(_from, _to, _value);
             return true;
         }
        
        function approve(address _spender, uint256 _value) public returns(bool success){
            
            allowance[msg.sender][_spender] = _value;
            emit Approve(msg.sender, _spender, _value);
            return true;
        }
}