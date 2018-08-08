pragma solidity ^0.4.9;

contract Petrocoin {
     /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    
    */
    /// total amount of tokens
    string public standard = &#39;Token 0.1&#39;;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public initialSupply;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

 

 
 
 
 function Petrocoin() {

        initialSupply = 100000000;
        name ="Petrocoin";
        decimals = 0;
        symbol = "PETRO";
        
        balanceOf[msg.sender] = initialSupply;              
        totalSupply = initialSupply;                        
                                   
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;           
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; 
        balanceOf[msg.sender] -= _value;                     
        balanceOf[_to] += _value;                           
      
    }


 
  function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    function depositToken(address token, uint256 amount){
    
}
    
    function () {
        throw;    
    }
}