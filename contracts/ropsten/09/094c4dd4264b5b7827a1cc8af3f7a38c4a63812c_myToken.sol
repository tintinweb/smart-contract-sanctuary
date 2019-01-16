pragma solidity ^0.4.25;

contract myToken {
    
    string public name;
    string public symbol;
    int8 public decimals = 0;
    address public tokenOwneraddress;
    int256 public totalSupply;
    int256 public ownerSupply;
    int public ownerPresentTokens;
    mapping (address => int256) public balanceOf;
    int256 public remainingblanace;
    event Transfer(address from1, address to1, int256 value);
   

   
   constructor(
        int256 initialSupply,
        string tokenName,
        string tokenSymbol,
        address tokenOwner,
        int256 ownerDiscount
        
    ) public {
        totalSupply = initialSupply; 
        ownerSupply = (totalSupply*ownerDiscount)/100;
        balanceOf[msg.sender] = totalSupply;                
        name = tokenName;                                   
        symbol = tokenSymbol;     
        tokenOwneraddress=tokenOwner;
        ownerPresentTokens = balancesof(tokenOwneraddress);
        remainingblanace= ownerPresentTokens-ownerSupply;
        
    }

    function upDate() public {
        ownerPresentTokens = balancesof(tokenOwneraddress);
        remainingblanace= ownerPresentTokens-ownerSupply;
    }

  function balancesof(address owner1) public constant returns (int256 balance)
  {
      return balanceOf[owner1];
      
  }
    function transfer(address _to, int256 _value) public returns (bool success) {
        int256 amount = remainingblanace-_value;
        if( amount >= 0  )
            {
        balanceOf[tokenOwneraddress] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(tokenOwneraddress, _to, _value);
        upDate();
        return true;
        }
        else {
            return false;
        }
    }
   
}