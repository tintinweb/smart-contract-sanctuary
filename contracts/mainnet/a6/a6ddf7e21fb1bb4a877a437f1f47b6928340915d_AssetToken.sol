pragma solidity ^0.4.6;
 
contract admined {
  address public admin;

  function admined(){
    admin = msg.sender;
  }

  modifier onlyAdmin(){
    require(msg.sender == admin) ;
    _;
  }

  function transferAdminship(address newAdmin) onlyAdmin {
    admin = newAdmin;
  }

}

contract ERC223Interface {
       uint public totalSupply;
       function totalSupply() constant  returns (uint256 _supply);
	   function name() constant  returns (string _name);
	   function symbol() constant  returns (string _symbol);
	   function decimals() constant  returns (uint8 _decimals);
	   function balanceOf(address who) constant returns (uint);
	   function transfer(address to, uint value);
	   
	   event Transfers(address indexed from, address indexed to, uint256 value);  
        event Transfer(address indexed from, address indexed to, uint value, bytes data);
    
	   event TokenFallback(address from, uint value, bytes _data);

}
contract ERC223ReceivingContract { 

    function tokenFallback(address from, uint value, bytes _data);
    event TokenFallback(address from, uint value, bytes _data);
}

contract AssetToken is admined,ERC223Interface{

 mapping (address => uint256) public balanceOf;
     mapping(address => mapping(address => uint256)) allowed;

 uint256 public totalSupply;
 string public name;
  string public symbol;
  uint8 public decimal; 
  uint256 public soldToken;
  event Transfer(address indexed from, address indexed to, uint256 value);
   //Trigger when Tokens Burned
        event Burn(address indexed from, uint256 value);

 

  function AssetToken(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits, address centralAdmin) {
 balanceOf[msg.sender] = initialSupply;
    totalSupply = initialSupply;
    decimal = decimalUnits;
    symbol = tokenSymbol;
    name = tokenName;
    soldToken=0;
    
    if(centralAdmin != 0)
      admin = centralAdmin;
    else
      admin = msg.sender;
    balanceOf[admin] = initialSupply;
    totalSupply = initialSupply;  
  }

  function mintToken(address target, uint256 mintedAmount) onlyAdmin{
    balanceOf[target] += mintedAmount;
    totalSupply += mintedAmount;
    Transfer(0, this, mintedAmount);
    Transfer(this, target, mintedAmount);
  }


    function transfer(address _to, uint _value) {
        uint codeLength;
        bytes memory empty;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
	
            receiver.tokenFallback(msg.sender, _value, empty);

}
        soldToken+=_value;
        Transfers(msg.sender, _to, _value);
    }
  
    
    
 function balanceOf(address _owner) constant  returns (uint balance) {
    return balanceOf[_owner];
  }

    
    //Allow the owner to burn the token from their accounts
function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;                      
        Burn(msg.sender, _value);
        return true;
    }


  // Function to access name of token .
  function name() constant  returns (string _name) {
      return name;
  }
  // Function to access symbol of token .
  function symbol() constant  returns (string _symbol) {
      return symbol;
  }
  // Function to access decimals of token .
  function decimals() constant  returns (uint8 _decimals) {
      return decimal;
  }
  // Function to access total supply of tokens .
   function totalSupply() constant returns(uint256 initialSupply) {
        initialSupply = totalSupply;
    }
  


}