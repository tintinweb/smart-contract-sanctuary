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
  
  struct Deposits{
      uint[] amounts;
      uint[] depTime;
      uint[] withdrawn;
      bool[] withdraw;
  }

  struct Investor {
    bool registered;
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
    tariffs.push(Tariff(30 minutes, 10));
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
    
        depo[msg.sender].amounts.push(tokenAmount);
        depo[msg.sender].depTime.push(block.timestamp);
        depo[msg.sender].withdrawn.push(0);
        depo[msg.sender].withdraw.push(false);
        
        emit DepositAt(msg.sender, tokenAmount);
    }
    
    // Principal withdraw
    function pWithdraw(uint i) public {
        IERC20 token = IERC20(tokenAddr);
        if(block.timestamp - depo[msg.sender].depTime[i] >= 30 minutes){
            
            if(depo[msg.sender].withdraw[i] == false){
                uint amount = depo[msg.sender].amounts[i] + ( depo[msg.sender].amounts[i] * 10 / 100 );
                token.transfer(msg.sender, amount);
                depo[msg.sender].withdraw[i] = true;
                depo[msg.sender].withdrawn[i] = amount;
            }
            else if(depo[msg.sender].withdraw[i] == true){
                revert("False!");
            }
        }
        
        else if(block.timestamp - depo[msg.sender].depTime[i] < 30 minutes){
            revert("Time not reached");
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