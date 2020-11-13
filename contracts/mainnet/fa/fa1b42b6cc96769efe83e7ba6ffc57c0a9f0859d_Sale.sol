pragma solidity ^0.6.0;
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


 interface ERC20 {
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external  view returns (uint);
 function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool ok);
  function approve(address spender, uint value)external returns (bool ok);
}


contract Sale {
    using SafeMath for uint256;

  
    uint256 public totalSold;
    ERC20 public Token;
    address payable public owner;
  
    uint256 public collectedETH;
    uint256 public startDate;

  
  

    constructor(address _wallet) public {
        owner=msg.sender;
        Token=ERC20(_wallet);

    }

   
    // receive FUNCTION
    // converts ETH to TOKEN and sends new TOKEN to the sender
    receive () payable external {
        require(startDate>0 && now.sub(startDate) <= 7 days);
        require(availableOBR()>0);
        require(msg.value>= 1 ether && msg.value <= 50 ether);
         
          uint256 amount;
          
      if(now.sub(startDate)  <= 1 days)
      {
          uint256 rate= (uint256(2000000000000000000));
          amount = (msg.value.mul(rate))/10**18;
      
      }
      else if(now.sub(startDate) > 1 days && now.sub(startDate) <= 2 days)
      {
          uint256 rate= (uint256(1940000000000000000));
          amount = (msg.value.mul(rate))/10**18;
      }
      else if(now.sub(startDate) > 2 days && now.sub(startDate) <= 3 days)
      {
           uint256 rate= (uint256(1880000000000000000));
          amount = (msg.value.mul(rate))/10**18;
      }
      else if(now.sub(startDate) > 3 days && now.sub(startDate) <= 4 days)
      {
           uint256 rate= (uint256(1830000000000000000));
          amount = (msg.value.mul(rate))/10**18;
      }
      else if(now.sub(startDate) > 4 days && now.sub(startDate) <= 5 days)
      {
           uint256 rate= (uint256(1780000000000000000));
          amount = (msg.value.mul(rate))/10**18;
      }
       else if(now.sub(startDate) > 5 days && now.sub(startDate) <= 6 days)
      {
           uint256 rate= (uint256(1730000000000000000));
          amount = (msg.value.mul(rate))/10**18;
      }
       else if(now.sub(startDate) > 6 days && now.sub(startDate) <= 7 days)
      {
           uint256 rate= (uint256(1690000000000000000));
          amount = (msg.value.mul(rate))/10**18;
      } else{
          amount=0;
      }
        require(amount<=availableOBR());
        totalSold =totalSold.add(amount);
        collectedETH=collectedETH.add(msg.value);
        Token.transfer(msg.sender, amount);
    }
    
   
    // CONTRIBUTE FUNCTION
    // converts ETH to TOKEN and sends new TOKEN to the 
    
    function contribute() external payable {
       require(startDate>0 && now.sub(startDate) <= 7 days);
        require(availableOBR()>0);
        require(msg.value>= 1 ether && msg.value <= 50 ether);
        
        uint256 amount;
        
       if(now.sub(startDate)  <= 1 days)
      {
          uint256 rate= (uint256(2000000000000000000));
          amount = (msg.value.mul(rate))/10**18;
      
      }
      else if(now.sub(startDate) > 1 days && now.sub(startDate) <= 2 days)
      {
          uint256 rate= (uint256(1940000000000000000));
          amount = (msg.value.mul(rate))/10**18;
      }
      else if(now.sub(startDate) > 2 days && now.sub(startDate) <= 3 days)
      {
           uint256 rate= (uint256(1880000000000000000));
          amount = (msg.value.mul(rate))/10**18;
      }
      else if(now.sub(startDate) > 3 days && now.sub(startDate) <= 4 days)
      {
           uint256 rate= (uint256(1830000000000000000));
          amount = (msg.value.mul(rate))/10**18;
      }
      else if(now.sub(startDate) > 4 days && now.sub(startDate) <= 5 days)
      {
           uint256 rate= (uint256(1780000000000000000));
          amount = (msg.value.mul(rate))/10**18;
      }
       else if(now.sub(startDate) > 5 days && now.sub(startDate) <= 6 days)
      {
           uint256 rate= (uint256(1730000000000000000));
          amount = (msg.value.mul(rate))/10**18;
      }
       else if(now.sub(startDate) > 6 days && now.sub(startDate) <= 7 days)
      {
           uint256 rate= (uint256(1690000000000000000));
          amount = (msg.value.mul(rate))/10**18;
      } else{
          amount=0;
      }
   
        require(amount<=availableOBR());
        totalSold =totalSold.add(amount);
        collectedETH=collectedETH.add(msg.value);
        Token.transfer(msg.sender, amount);
    }
    
    //function to get the current price of token per ETH
    
    function getPrice()public view returns(uint256){
        if(startDate==0)
        {
            return 0;
        }
         else if(now.sub(startDate)  <= 1 days)
      {
         return 2000000000000000000;
        
      
      }
      else if(now.sub(startDate) > 1 days && now.sub(startDate) <= 2 days)
      {
        
          return 1940000000000000000;
      }
      else if(now.sub(startDate) > 2 days && now.sub(startDate) <= 3 days)
      {
          
           return 1880000000000000000;
      }
      else if(now.sub(startDate) > 3 days && now.sub(startDate) <= 4 days)
      {
         
          return 1830000000000000000;
      }
      else if(now.sub(startDate) > 4 days && now.sub(startDate) <= 5 days)
      {
         
          return 1780000000000000000;
      }
       else if(now.sub(startDate) > 5 days && now.sub(startDate) <= 6 days)
      {
         
          return 1730000000000000000;
      }
       else if(now.sub(startDate) > 6 days && now.sub(startDate) <= 7 days)
      {
          return 1690000000000000000;
      } else{
          return 0;
      }
    }
    
    
    //function to change the owner
    //only owner can call this function
    
    function changeOwner(address payable _owner) public {
        require(msg.sender==owner);
        owner=_owner;
    }
    
    //function to withdraw collected ETH
     //only owner can call this function
     
    function withdrawETH()public {
        require(msg.sender==owner && collectedETH>0 && address(this).balance >= collectedETH);
        uint256 amount=collectedETH;
        collectedETH=0;
        owner.transfer(amount);
    }
    
    //function to withdraw available OBR in this contract
     //only owner can call this function
     
    function withdrawOBR()public{
         require(msg.sender==owner && availableOBR()>0);
         Token.transfer(owner,availableOBR());
    }
    
    //function to start the Sale
    //only owner can call this function
     
    function startSale()public{
        require(msg.sender==owner && startDate==0);
        startDate=now;
    }
    
    //function to return the available OBR balance in the contract
    function availableOBR()public view returns(uint256){
        return Token.balanceOf(address(this));
    }

}