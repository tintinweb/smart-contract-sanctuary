pragma solidity ^0.8.0;

import  "./ERC20-v0.8.0.sol";

contract GoodPayGlobal is ERC20 {
    
    address owner;
    string Name = 'GoodPayGlobal';
    string Symbol = 'GPG';
  
 constructor( address _owner) ERC20(Name, Symbol){
        owner =_owner;
        uint256 initialSupply = 2000000000*10**18;
        _mint(owner, initialSupply);
    }

      modifier onlyOwner() {
            require(owner == msg.sender, 'caller is not admin'); 
            _;
      }
      
      function BeginTokenLock() external onlyOwner{
          tokenLocked = true;
      }
      
    function EndTokenLock() external onlyOwner{
          tokenLocked = false;
    }
    
    function RestrictAddress( address _addressToBeRestricted) public onlyOwner{
        RestrictedAddress[_addressToBeRestricted] = true;
     
    }
    
    function UnestrictAddress( address _addressToBeUnrestricted) public onlyOwner{
    RestrictedAddress[_addressToBeUnrestricted] = false;
   
    }


    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function mint(address recipient, uint256 amount) external onlyOwner {
         require(tokenLocked == false, 'token locked');
        _mint(recipient, amount);
    }

    function burn(address recipient, uint256 amount) external onlyOwner {
         require(tokenLocked == false, 'token locked');
        _burn(recipient, amount);
    }
}