pragma solidity ^0.4.25;

contract myToken {
    
    string public name;
    string public symbol;
    int public decimals = 0;
   address public tokenOwneraddress;
    int public totalSupply;
    int public ownerPresentTokens;
    mapping (address => int) public balanceOf;
    int public remainingblanace;
    int public ownerSupply;
    int public amount;
    event Transfer(address from1, address to1, int value);
   

   
   constructor(
        int initialSupply,
        string tokenName,
        string tokenSymbol,
        address tokenOwner,
        int ownerDiscount
        
    ) public {
        totalSupply = initialSupply;  
        ownerSupply = (totalSupply*ownerDiscount)/100;
        balanceOf[msg.sender] = totalSupply;                
        name = tokenName;                                   
        symbol = tokenSymbol;     
        tokenOwneraddress=tokenOwner;
        upDate();
    }

  function balancesof(address owner1) public constant returns (int balance)
  {
      return balanceOf[owner1];
      
  }
   
  function upDate() public {
        ownerPresentTokens = balancesof(tokenOwneraddress);
        remainingblanace= ownerPresentTokens-ownerSupply;
    }

    function transfer(address _to, int _value) public returns (bool success) {
        amount = remainingblanace-_value;
        if(amount >= 0)
        {
            balanceOf[tokenOwneraddress] -= _value;
            balanceOf[_to] += _value;
            upDate();
            emit Transfer(tokenOwneraddress, _to, _value);
            return true;
        }else{
            revert();
        }
    
    }
   
}