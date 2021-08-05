/**
 *Submitted for verification at Etherscan.io on 2020-12-22
*/

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

contract PreSale {
  using SafeMath for uint256;

  address public token;
  uint256 public totalSold;
  address payable public owner;
  uint256 public startDate;
  uint256 private diver;
  uint256 private multi;
  
  bool ableToClaim;
  bool sellSystem;
  
  struct User {
    uint256 accountBalance;
  }
    
  mapping(address => User) public users;
  
  address[] public allUsers;
   
  constructor() public {
    owner = msg.sender;
    token = address(0);
    ableToClaim = false;
    sellSystem = true;
    startDate = now;
    multi = 1;
    diver = 1;
  }

  function contribute() external payable {
    require(sellSystem);
    require(msg.value >= 0.01 ether);
    
    uint256 amount = msg.value;
    
    if (now.sub(startDate) <= 1 days) {
       amount = amount.mul(200);
    } else if(now.sub(startDate) > 1 days && now.sub(startDate) <= 2 days) {
       amount = amount.mul(190);
    } else if(now.sub(startDate) > 2 days && now.sub(startDate) <= 3 days) {
       amount = amount.mul(180);
    } else if(now.sub(startDate) > 3 days && now.sub(startDate) <= 4 days) {
       amount = amount.mul(170);
    } else if(now.sub(startDate) > 4 days && now.sub(startDate) <= 5 days) {
       amount = amount.mul(160);
    } else if(now.sub(startDate) > 5 days && now.sub(startDate) <= 6 days) {
       amount = amount.mul(150);
    } else if(now.sub(startDate) > 6 days && now.sub(startDate) <= 7 days) {
       amount = amount.mul(140);
    } else if(now.sub(startDate) > 7 days && now.sub(startDate) <= 8 days) {
       amount = amount.mul(130);
    } else if(now.sub(startDate) > 8 days && now.sub(startDate) <= 9 days) {
       amount = amount.mul(120);
    } else if(now.sub(startDate) > 9 days && now.sub(startDate) <= 10 days) {
       amount = amount.mul(110);
    } else {
       amount = amount.mul(100);
    }
    
    amount = amount.div(100);
    
    totalSold = totalSold.add(amount);
    
    users[msg.sender].accountBalance = users[msg.sender].accountBalance.add(amount);
     
    allUsers.push(msg.sender);
    
    owner.transfer(msg.value);
  }
  
   function returnAllTokens() public {
    require(token != address(0));
    require(msg.sender == owner);
    require(ableToClaim);
        
    for (uint id = 0; id < allUsers.length; id++) {
          address getAddressUser = allUsers[id];
          uint256 value = users[getAddressUser].accountBalance;
          users[getAddressUser].accountBalance = users[getAddressUser].accountBalance.sub(value);
          if(value != 0){
             ERC20(token).transfer(getAddressUser, (value * multi ) / diver);
          }
     }
  }
           
  function claimTokens() public {
    require(token != address(0));
    require(ableToClaim);
    uint256 value = users[msg.sender].accountBalance;
    users[msg.sender].accountBalance = users[msg.sender].accountBalance.sub(value);
    ERC20(token).transfer(msg.sender, (value * multi ) / diver);
  }
  
  function yourTokens() public view returns(uint256) {
    return users[msg.sender].accountBalance;
  }
  
  function setToken(address _token) public {
    require(msg.sender == owner);
    token = _token;
  }
  
  function setValue(uint256 _diver, uint256 _multi) public {
    require(msg.sender == owner);
    diver = _diver;
    multi = _multi;
  }
  
  function setClaimSystem (bool _ableToClaim) public {
    require(msg.sender == owner);
    ableToClaim = _ableToClaim;
  }
  
  function setSellSystem (bool _sellSystem) public {
    require(msg.sender == owner);
    sellSystem = _sellSystem;
  }
  
  function returnVariousTokenFromContract(address tokenAddress) public returns (bool success) {
      require(msg.sender == owner);
      ERC20 tempToken = ERC20(tokenAddress);
      tempToken.transfer(msg.sender, tempToken.balanceOf(address(this)));
      return true;
  }
  
  function returnETHFromContract(uint256 value) public returns (bool success) {
      require(msg.sender == owner);
      msg.sender.transfer(value);
      return true;
  }
}