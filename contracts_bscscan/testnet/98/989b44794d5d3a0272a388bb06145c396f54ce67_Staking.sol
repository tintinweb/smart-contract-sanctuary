/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Staking {

  struct Tariff {
    uint time;
    uint percent;
  }

  struct Deposit {
    uint tariff;
    uint amount;
    uint at;
    bool isWithdrawal;
  }

  struct Investor {
    bool registered;
    Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint investedAt;
    uint firstDepositAt;
    uint withdrawn;
    uint totalWithdrawn;
  }

  address public owner = msg.sender;
  address tokenAddr = 0x2C14479B25eCAF9c553164A95F1E1221Ca18f929;
  address contractAddr = address(this);

  Tariff[] public tariffs;

  uint public totalInvestors;
  uint public totalInvested;
  uint public totalWithdrawal;

  mapping (address => Investor) public investors;
  mapping (address => Tariff) public tariff;
  mapping(address => uint[]) user_deposit_time;
  mapping(address => uint[]) user_deposit_amount;
  
  event DepositAt(address user, uint amount);
  event Withdraw(address user, uint amount);
  event TransferOwnership(address user);
  event Received(address, uint);

  function register(address user) internal {

    if (!investors[user].registered) {

      investors[user].registered = true;
      investors[user].investedAt = block.timestamp;
      investors[user].firstDepositAt = block.timestamp;
     
      totalInvestors++;
    }
  }
  
  constructor()  {
    tariffs.push(Tariff(5 minutes, 10));
  }
    
    // Deposit Tokens for Staking. User has to call 
    // approve/increase allowance function from token before staking
    function deposit(uint tokenAmount) external {
        
        IERC20 token = IERC20(tokenAddr);
        tokenAmount = tokenAmount * 1000000000000000000;
        require(tokenAmount > 0);
        require(token.balanceOf(msg.sender) > 0);
        token.approve(contractAddr, tokenAmount);
        token.transferFrom(msg.sender, contractAddr, tokenAmount);
      
        register(address(msg.sender));
           
        investors[msg.sender].invested += tokenAmount;
            
        totalInvested += tokenAmount;
    
        investors[msg.sender].deposits.push(Deposit(0, tokenAmount, block.timestamp,false));
        
        emit DepositAt(msg.sender, tokenAmount);
    }
    
    // User ROI withdrawable view
    function withdrawable(address user) public view returns (uint amount) {
    
        Investor storage investor = investors[user];

        for (uint i = 0; i < investor.deposits.length; i++) {
    
          Deposit storage dep = investor.deposits[i];
    
          Tariff storage tariffNew = tariffs[dep.tariff];
    
          
          uint finish = dep.at + tariffNew.time;
          uint since = dep.at ;
          uint till = block.timestamp > finish ? finish : block.timestamp;
          
          amount += dep.amount * (till - since) * tariffNew.percent / tariffNew.time / 100;
          
        }
        return amount;
    }
    
    // Principal Withdrawable 
    function principalWithdrawable(address user) internal returns (uint amount) {

        Investor storage investor = investors[user];

        for (uint i = 0; i < investor.deposits.length; i++) {
    
          Deposit storage dep = investor.deposits[i];
    
          Tariff storage tariffNew = tariffs[dep.tariff];
    
          
          uint finish = dep.at + tariffNew.time;
          uint since = dep.at ;
          uint till = block.timestamp > finish ? finish : block.timestamp;
          uint timeDiff = till - since;
          
          require(timeDiff >= 5 minutes, "Principal withdrawal time limit not reached!");
            amount += dep.amount * (till - since) * tariffNew.percent / tariffNew.time / 100;
            amount += dep.amount;
            investor.deposits[i].isWithdrawal = true;
          }
          amount = amount - investor.withdrawn;
        return amount;

    }
    
    // View Principal Withdrawable
    function principalWithdrawableView(address user) external view returns (uint amount) {

        Investor storage investor = investors[user];

        for (uint i = 0; i < investor.deposits.length; i++) {
    
          Deposit storage dep = investor.deposits[i];
    
          Tariff storage tariffNew = tariffs[dep.tariff];
    
          
          uint finish = dep.at + tariffNew.time;
          uint since = dep.at ;
          uint till = block.timestamp > finish ? finish : block.timestamp;
          uint timeDiff = till - since;
          
          if(timeDiff >= 5 minutes){
            amount+= dep.amount * (till - since) * tariffNew.percent / tariffNew.time / 100;
            amount += dep.amount;
          }
        }
        amount = amount - investor.withdrawn;
        return amount;

    }
  
    // Principal Withdraw
    function principalWithdraw(address payable to) external {
      uint amount = principalWithdrawable(msg.sender);
      IERC20 token = IERC20(tokenAddr);
      
      token.transfer(to, amount);
      investors[msg.sender].totalWithdrawn += amount;
      investors[msg.sender].withdrawn += amount;
      totalWithdrawal += amount;
       
      emit Withdraw(to, amount);
    }
    
    // View user details
    function myData(address userAddr) public view returns (uint,uint,uint,uint,uint) {

    Investor storage investor = investors[userAddr];
     
        uint invested = investor.invested;
        uint totalIncome = withdrawable(userAddr);
        uint withdrawn = investor.withdrawn;
        return (invested,totalIncome,withdrawn,totalInvestors,totalInvested);
    }
    
    // Owner withdraw token
    function withdrawToken(address tokenAddress, address to, uint amount) external {
      require(msg.sender == owner);
      IERC20 token = IERC20(tokenAddress);
      token.transfer(to, amount);
    }  
    
    // Owner withdraw BNB
    function withdrawBNB(address payable to, uint amount) external {
        require(msg.sender == owner);
        to.transfer(amount);
    }
    
    // Transfer Ownership
    function transferOwnership(address to) external {
        require(msg.sender == owner);
        owner = to;
        emit TransferOwnership(owner);
    }
    
    // Receive BNB functionality
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }  
    
}