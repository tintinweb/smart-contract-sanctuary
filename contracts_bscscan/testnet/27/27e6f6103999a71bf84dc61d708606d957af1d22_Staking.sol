/**
 *Submitted for verification at BscScan.com on 2021-07-23
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
  
  struct Deposits{
      uint tariff;
      uint[] amounts;
      uint[] depTime;
      uint[] withdrawn;
      uint[] withdrawnRoi;
      uint[] withdrawnRoiTime;
      bool[] withdraw;
  }

  struct Investor {
    bool registered;
    uint invested;
    uint investedAt;
    uint firstDepositAt;
  }

  address public owner;
  address tokenAddr = 0x8691BB7E4f4d299716850bE908df9F8e002dED16;
  address contractAddr = address(this);
  IERC20 token = IERC20(tokenAddr);

  Tariff[] public tariffs;

  uint public totalInvestors;
  uint public totalInvested;
  uint public totalWithdrawal;

  mapping (address => Investor) public investors;
  mapping(address => uint[]) user_deposit_time;
  mapping(address => uint[]) user_deposit_amount;
  mapping(address => Deposits) depo;
  
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
    owner = msg.sender;
    tariffs.push(Tariff(300 minutes, 20));
  }
    
    // Deposit Tokens for Staking. User has to call 
    // approve/increase allowance function from token before staking
    function deposit(uint tokenAmount) public {
        
        tokenAmount = tokenAmount * 1000000000000000000;
        require(tokenAmount > 0, "Zero Amount");
        require(token.balanceOf(msg.sender) > 0, "Not enough balance");
        // token.approve(contractAddr, tokenAmount);
        token.transferFrom(msg.sender, contractAddr, tokenAmount);
      
        register(address(msg.sender));
           
        investors[msg.sender].invested += tokenAmount;
            
        totalInvested += tokenAmount;
    
        depo[msg.sender].amounts.push(tokenAmount);
        depo[msg.sender].depTime.push(block.timestamp);
        depo[msg.sender].withdrawn.push(0);
        depo[msg.sender].withdraw.push(false);
        depo[msg.sender].withdrawnRoiTime.push(0);
        
        emit DepositAt(msg.sender, tokenAmount);
    }
    
    // ROI withdrawable 
    function withdrawRoi() public {
        
        address user = msg.sender;
        uint withdrawableAmt;
        Deposits storage dep = depo[user];
        Tariff storage tariff = tariffs[dep.tariff];
        uint len = dep.amounts.length;
        uint timediff;
        
        for(uint i = 0; i < len; i++) {
            
            if(dep.withdrawnRoiTime[i] == 0){
                timediff = block.timestamp - dep.depTime[i];
            }
            else{
                timediff = block.timestamp - dep.withdrawnRoiTime[i];
            }
            
            if(timediff >= 5 minutes){
                withdrawableAmt = dep.amounts[i] * tariff.percent / tariff.time / 100;
                dep.withdrawnRoi[i] += withdrawableAmt;
                dep.withdrawn[i] += withdrawableAmt;
                dep.withdrawnRoiTime[i] = block.timestamp;
            }
            else{
                revert("Withdraw time not reached");
            }
        }
    }
    
    // ROI withdraw
    function withdrawable(address user) public view returns (uint) {
        
        uint withdrawableAmt;
        Deposits storage dep = depo[user];
        Tariff storage tariff = tariffs[dep.tariff];
        uint len = dep.amounts.length;
        uint timediff;
        
        for(uint i = 0; i < len; i++) {
            
            if(dep.withdrawnRoiTime[i] == 0){
                timediff = block.timestamp - dep.depTime[i];
            }
            else{
                timediff = block.timestamp - dep.withdrawnRoiTime[i];
            }
            
            if(timediff >= 5 minutes){
                withdrawableAmt = dep.amounts[i] * tariff.percent / tariff.time / 100;
            }
            else{
                revert("Withdraw time not reached");
            }
        }
        return withdrawableAmt;
    }
    
    // Principal withdraw
    function pWithdraw() public {
        
        address user = msg.sender;
        uint len = depo[user].amounts.length;
        Deposits storage dep = depo[user];
        Tariff storage tariff = tariffs[dep.tariff];
        
        for(uint i = 0; i < len; i++){
            
            if(block.timestamp - dep.depTime[i] >= 5 minutes){
                
                if(dep.withdraw[i] == false){
                    uint amount = dep.amounts[i] + ( dep.amounts[i] * tariff.percent / tariff.time / 100 );
                    amount = amount - dep.withdrawnRoi[i];
                    token.transfer(msg.sender, amount);
                    dep.withdraw[i] = true;
                    dep.withdrawn[i] = amount;
                }
                else if(dep.withdraw[i] == true){
                    revert("Already Withdrawn");
                }
            }
            
            else if(block.timestamp - dep.depTime[i] < 365 days){
                revert("Time not reached");
            }
        }
    }
    
    // User Details
    function details(address user) public view returns (uint[] memory, uint[] memory, uint[] memory, bool[] memory){
        uint len = depo[user].amounts.length;
        uint[] memory staked = new uint[](len);
        uint[] memory time = new uint[](len);
        uint[] memory withdrawnTokens = new uint[](len);
        bool[] memory hasWithdrawn = new bool[](len);
        
        for(uint i = 0; i < len; i++){
            staked[i] = depo[user].amounts[i];
            time[i] = depo[user].depTime[i];
            withdrawnTokens[i] = depo[user].withdrawn[i];
            hasWithdrawn[i] = depo[user].withdraw[i];
        }
        
        return(staked, time, withdrawnTokens, hasWithdrawn);
    }
  
    // Owner withdraw token
    function withdrawToken(address tokenAddress, address to, uint amount) external {
      require(msg.sender == owner, "Only owner");
      IERC20 token_ = IERC20(tokenAddress);
      token_.transfer(to, amount);
    }  
    
    // Owner withdraw BNB
    function withdrawBNB(address payable to, uint amount) external {
        require(msg.sender == owner, "Only owner");
        to.transfer(amount);
    }
    
    // Transfer Ownership
    function transferOwnership(address to) external {
        require(msg.sender == owner, "Only owner");
        owner = to;
        emit TransferOwnership(owner);
    }
    
    // Receive BNB functionality
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }  
    
}