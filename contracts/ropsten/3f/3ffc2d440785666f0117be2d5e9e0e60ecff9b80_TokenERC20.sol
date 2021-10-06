/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

pragma solidity ^0.4.24;


interface tokenRecipient { function receiveApprovol (address _from, uint256 _value, address _token, bytes _extradata) external;}

contract TokenERC20{ 
    
string public name; 
string public symbol; 
uint8 public decimals = 19;
uint256 public totalSupply;

mapping (address => uint256) public balanceOf; 
mapping (address => mapping(address => uint256)) public allowance; 

constructor( 
    uint256 initialSupply, 
    string tokenName, 
    string tokenSymbol 
    ) public{ 
        totalSupply = initialSupply*10**uint256(decimals); 
        balanceOf[msg.sender] = totalSupply; 
        name = tokenName; 
        symbol = tokenSymbol; 
    }
    
    //for validation
    
    function _transfer(address _from, address _to, uint _value) internal { 
        
        require(_to != 0x0); 
        require(balanceOf[_from] >=_value); 
        require(balanceOf[_to] + _value >= balanceOf[_to]); 
        
        uint previousBalances = balanceOf[_from] + balanceOf[_to]; 
        
        balanceOf[_from] -= _value; 
        balanceOf[_to] += _value; 
        
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances); 
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success){ 
        
        _transfer(msg.sender, _to, _value); 
        return true; 
    }
    
    
    // allowance
    
    function transferFrom (address _from, address _to, uint256 _value) public returns (bool success){ 
        require(_value <=allowance[_from][msg.sender]); 
        allowance[_from][msg.sender] -=_value; _transfer(_from,_to, _value); 
    } 
    
    function approve (address _spender, uint256 _value) public returns (bool success){ 
        allowance[msg.sender][_spender] = _value; 
        return true; 
    } 
    
    
    function approveAndCall(address _spender, uint256 _value, bytes _extradata) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender); 
        
        if(approve(_spender,_value)){ 
            spender.receiveApprovol(msg.sender, _value, this, _extradata); 
            return true; 
        } 
    }
    
    
    // Burn functionality
    
    function burn (uint256 _value) public returns (bool success){ 
        require(balanceOf[msg.sender] >= _value); 
        balanceOf[msg.sender] -= _value; 
        totalSupply -= _value; 
        return true; 
    } 
    
    function burnFrom(address _from, uint256 _value) public returns (bool success){ 
        require(balanceOf[_from] >= _value); 
        require(_value <= allowance[_from][msg.sender]); 
        
        balanceOf[_from] -= _value; 
        totalSupply -= _value; 
        
        return true;
    }

}