pragma solidity ^0.4.18;


contract Dragon {
    
    function transfer(address receiver, uint amount)returns(bool ok);
    function balanceOf( address _address )returns(uint256);

    
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}




contract DragonLock is Ownable {
    
    using SafeMath for uint;
   
  
    Dragon public tokenreward; 
    
    
   
   
    
    uint public TimeLock;
    address public receiver;
 
    
    
  
    
    function DragonLock (){
        
        tokenreward = Dragon (  0x814f67fa286f7572b041d041b1d99b432c9155ee ); // dragon token address
        
        TimeLock = now + 90 days;
       
        receiver = 0x2b29397aEC174A52bff15225efbb5311c7d63b38; // Receiver address change
        
      
        
    }
    
    
    //allows token holders to withdar their dragons after timelock expires
    function withdrawDragons(){
        
        require ( now > TimeLock );
        require ( receiver == msg.sender );
      
       
        tokenreward.transfer ( msg.sender , tokenreward.balanceOf (this)  );
        
    }
    
    

   
  

    
   
}