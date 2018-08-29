pragma solidity ^0.4.24;



contract FMC {

    string public name ;
    string public symbol ;
    uint8 public decimals = 18;  
    uint256 public totalSupply  ;  

    
    mapping (address => uint256) public balanceOf;
    
   

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    

    
    function FMC(uint256 initialSupply, string tokenName, string tokenSymbol) public {
       
        totalSupply = initialSupply * 10 ** uint256(decimals);

        
        balanceOf[msg.sender] = totalSupply;    

        name = tokenName;
        symbol = tokenSymbol;
    }

  
    function _transfer(address _from, address _to, uint _value) internal {

       
        require(_to != 0x0);

       
        require(balanceOf[_from] >= _value);

        
        require(balanceOf[_to] + _value > balanceOf[_to]);

        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

       
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

     
        emit Transfer(_from, _to, _value);

        
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

   
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
	
	
}