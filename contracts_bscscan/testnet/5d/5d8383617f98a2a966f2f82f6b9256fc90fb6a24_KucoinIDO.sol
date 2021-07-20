/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.0;


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

contract KucoinIDO{

  struct Deposit {
    uint unlocktime;
    uint amount;
    bool isWithdrawal;
 }

  struct Investor {
   bool registered;
   uint usertotaltoken;
   Deposit[] deposits;
 } 

 address public owner = msg.sender;
 IERC20 public token;
 
  mapping (address => Investor) public investors;

  event DepositAt(address user, uint amount, uint timeat);
  event Withdraw(address user, uint amount, uint depositnumber, uint withdrawat);
  event DepositUpdate(address user, uint amount, uint depositnumber,uint cltime, bool wdstatus, uint at);
  event TransferOwnership(address user);


   constructor(address _token)  {
        token = IERC20(_token);
   }
   
   receive() external payable {}
   
  function Deposits(address deposit_address, uint[] memory deposit_amount,uint[] memory deposit_ctime) external {
      
    require(msg.sender==owner,"Only Owner");
    require(deposit_amount.length>0,"Amount is required");
    require(deposit_ctime.length>0,"Time is required");
    require(deposit_amount.length==deposit_ctime.length,"Amount and time count should be same");
    if (!investors[deposit_address].registered) {

      investors[deposit_address].registered = true;
    }
    uint totalAmount;
    for(uint i=0;i<deposit_amount.length;i++) {
        totalAmount+=deposit_amount[i];
        investors[deposit_address].deposits.push(Deposit(deposit_ctime[i], deposit_amount[i],false));      
    }
    investors[deposit_address].usertotaltoken+=totalAmount;
    emit DepositAt(deposit_address, totalAmount, block.timestamp);
  }


  function claimReward(uint depositIndex) external {
      Deposit storage findDeposit = investors[msg.sender].deposits[depositIndex];
      require(block.timestamp >= findDeposit.unlocktime,"Can't Claim Before Unlock Time");
      require(findDeposit.isWithdrawal==false,"Already Withdrawn");
      uint WithdrawAmt = findDeposit.amount;
      investors[msg.sender].deposits[depositIndex].isWithdrawal = true;
      token.transfer(msg.sender,WithdrawAmt);
      emit Withdraw(msg.sender, WithdrawAmt,depositIndex, block.timestamp);
  }
  
   function updateUserDeposit(address userAddr,uint depositIndex, uint amount, uint utime, bool withdrawalstatus) external {
      require(msg.sender==owner,"Only Owner");
      investors[userAddr].usertotaltoken-=investors[userAddr].deposits[depositIndex].amount;
      investors[userAddr].usertotaltoken+=amount;
      investors[userAddr].deposits[depositIndex].amount = amount;
      investors[userAddr].deposits[depositIndex].unlocktime = utime;
      investors[userAddr].deposits[depositIndex].isWithdrawal = withdrawalstatus;
      emit DepositUpdate(userAddr, amount,depositIndex,utime,withdrawalstatus, block.timestamp);
  }
  
   function transferOwnership(address to) external {
        require(msg.sender == owner);
        owner = to;
        emit TransferOwnership(owner);
  }
  
    function withdrawETH(address payable to, uint amount) public returns (bool) {
        require(msg.sender==owner);
        to.transfer(amount);
        return true;
    }
    
    function transferAnyERC20Token(address tokenAddress,address toAddress, uint tokens) public returns (bool success) {
        require(msg.sender==owner);
        return IERC20(tokenAddress).transfer(toAddress, tokens);
    } 
  
   function userDeposits(address userAddr) public view returns  (uint,uint [] memory ,uint []  memory,bool []  memory,bool []  memory) {
       uint usreTotalToken = investors[userAddr].usertotaltoken;
        uint depositLength = investors[userAddr].deposits.length;
         uint[] memory depositamounts = new uint[](depositLength);
         uint[] memory deposittimes = new uint[](depositLength);
         bool[] memory depositwithdrawals = new bool[](depositLength);
         bool[] memory claimavailable = new bool[](depositLength);
         for(uint i = 0; i < depositLength; i++){
            depositamounts[i] = investors[userAddr].deposits[i].amount;
            deposittimes[i] = investors[userAddr].deposits[i].unlocktime;
            depositwithdrawals[i] = investors[userAddr].deposits[i].isWithdrawal;
            claimavailable[i] = (investors[userAddr].deposits[i].isWithdrawal==false && investors[userAddr].deposits[i].unlocktime < block.timestamp) ? true : false;
         }
         return (usreTotalToken,depositamounts,deposittimes,depositwithdrawals,claimavailable);
    }
    
   function checkTime() public view returns  (uint getTimestamp) {
       getTimestamp = block.timestamp; 
       
    }
    

}