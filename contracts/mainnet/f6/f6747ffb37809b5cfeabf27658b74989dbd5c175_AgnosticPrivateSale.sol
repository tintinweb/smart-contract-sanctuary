pragma solidity 0.6.0;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface ERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint value) external  returns (bool success);
}

contract AgnosticPrivateSale {
  using SafeMath for uint256;

  uint256 public totalSold;
  ERC20 public Token;
  address payable public owner;
  uint256 public constant decimals = 18;
  uint256 private constant _precision = 10 ** decimals;
  uint256 public startDate;
  
  bool ableToClaim;
  bool sellSystem;
  
  struct User {
    uint256 accountBalance;
  }
    
  mapping(address => User) public users;
  
  address[] public allUsers;
   
  constructor(address token) public {
    owner = msg.sender;
    Token = ERC20(token);
    ableToClaim = false;
    sellSystem = true;
    startDate = now;
  }

  function contribute() external payable {
    require(sellSystem);
    require(msg.value >= 0.01 ether);
    
    uint256 amount = msg.value;
    
     if (now.sub(startDate) <= 2 days) {
       amount = amount.mul(100);
    } else if(now.sub(startDate) > 2 days && now.sub(startDate) <= 3 days) {
       amount = amount.mul(95);
    } else if(now.sub(startDate) > 3 days && now.sub(startDate) <= 4 days) {
       amount = amount.mul(90);
    } else if(now.sub(startDate) > 4 days && now.sub(startDate) <= 5 days) {
       amount = amount.mul(85);
    } else if(now.sub(startDate) > 5 days && now.sub(startDate) <= 6 days) {
       amount = amount.mul(80);
    } else if(now.sub(startDate) > 6 days && now.sub(startDate) <= 7 days) {
       amount = amount.mul(75);
    }
    
    amount = amount.div(100);
    
    totalSold = totalSold.add(amount);
    
    users[msg.sender].accountBalance = users[msg.sender].accountBalance.add(amount);
     
    allUsers.push(msg.sender);
    
    owner.transfer(msg.value);
  }
  
   function returnAllTokens() public {
    require(msg.sender == owner);
    require(ableToClaim);
        
    for (uint id = 0; id < allUsers.length; id++) {
          address getAddressUser = allUsers[id];
          uint256 value = users[getAddressUser].accountBalance;
          users[getAddressUser].accountBalance = users[getAddressUser].accountBalance.sub(value);
          if(value != 0){
             Token.transfer(msg.sender, value);
          }
     }
  }
           
  function claimTokens() public {
    require(ableToClaim);
    uint256 value = users[msg.sender].accountBalance;
    users[msg.sender].accountBalance = users[msg.sender].accountBalance.sub(value);
    Token.transfer(msg.sender, value);
  }
  
  function openClaimSystem (bool _ableToClaim) public {
    require(msg.sender == owner);
    ableToClaim = _ableToClaim;
  }
  
  function closeSellSystem () public {
    require(msg.sender == owner);
    sellSystem = false;
  }

  function liqudity() public {
    require(msg.sender == owner);
    Token.transfer(msg.sender, Token.balanceOf(address(this)));
  }
  
  function availableTokens() public view returns(uint256) {
    return Token.balanceOf(address(this));
  }
  
  function yourTokens() public view returns(uint256) {
    return users[msg.sender].accountBalance;
  }
  
  function showTime() public view returns(uint256 _now, uint256 nextRound, uint256 timeToNextRound, uint256 percentPriceNow) {
      
    uint256 price = 0;
    
    if (now.sub(startDate) <= 2 days) {
       price = 100;
    } else if(now.sub(startDate) > 2 days && now.sub(startDate) <= 3 days) {
       price = 105;
    } else if(now.sub(startDate) > 3 days && now.sub(startDate) <= 4 days) {
       price = 110;
    } else if(now.sub(startDate) > 4 days && now.sub(startDate) <= 5 days) {
       price = 115;
    } else if(now.sub(startDate) > 5 days && now.sub(startDate) <= 6 days) {
       price = 120;
    } else if(now.sub(startDate) > 6 days && now.sub(startDate) <= 7 days) {
       price = 125;
    }
    
    return (now, startDate, now.sub(startDate), percentPriceNow);
  }
}