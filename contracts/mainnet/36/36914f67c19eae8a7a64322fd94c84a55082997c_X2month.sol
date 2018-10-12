pragma solidity 0.4 .25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns(uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns(uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns(uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

contract X2month {

  using SafeMath
  for uint;
  // array containing information about beneficiaries
  mapping(address => uint) public userDeposit;
  //array containing information about the time of payment
  mapping(address => uint) public userTime;
  //array containing information on interest paid
  mapping(address=>uint) public persentWithdraw;
  //fund fo transfer percent
  address public projectFund = 0x15e3aAD84394012f450d7A6965f2f4C59Ca7071a;
  //wallet for a charitable foundation
  address public charityFund = 0x6c3607D37A000d7879F02b98c59376c7DAc91151;
  //percentage deducted to the advertising fund
  uint projectPercent = 5;
  //percent for a charitable foundation
  uint charityPercent = 1;
  //min payment 0.01 ether
  uint public minPayment = 1 finney;
  //time through which you can take dividends
  uint chargingTime = 1 hours;
  //persent 0.175 per hour
  uint public startPercent = 175;
  uint public lowPersent = 200;
  uint public middlePersent = 225;
  uint public highPersent = 250;
  //interest rate increase steps
  uint public stepLow = 1000 ether;
  uint public stepMiddle = 2500 ether;
  uint public stepHigh = 5000 ether;
  uint countOfInvestors = 0;
  
  modifier isIssetUser() {
    require(userDeposit[msg.sender] > 0, "Deposit not found");
    _;
  }

  modifier timePayment() {
    require(now >= userTime[msg.sender].add(chargingTime), "Too fast payout request");
    _;
  }
 
  function collectPercent() isIssetUser timePayment internal {
    //if the user received 200% or more of his contribution, delete the user
    if( (userDeposit[msg.sender].mul(2)) <= persentWithdraw[msg.sender]){
        userDeposit[msg.sender]=0;
        userTime[msg.sender]=0;
        persentWithdraw[msg.sender]=0;
    }else{
       uint payout = payoutAmount();
       userTime[msg.sender] = now;    
       persentWithdraw[msg.sender]+=payout;    
       msg.sender.transfer(payout); 
    }
  }
  
  function persentRate()public view returns(uint){
      //get contract balance
      uint balance = address(this).balance;
      //calculate persent rate
      if(balance < stepLow){return(startPercent);}
      if(balance>=stepLow && balance<stepMiddle){return(lowPersent);}
      if(balance>=stepMiddle && balance<stepHigh){return(middlePersent);}
      if(balance>=stepHigh){return(highPersent);}
  }
  
  function payoutAmount()public view returns(uint){
      uint persent = persentRate();
      uint rate = userDeposit[msg.sender].mul(persent).div(100000);
      uint interestRate=now.sub(userTime[msg.sender]).div(chargingTime);
      uint withdrawalAmount = rate.mul(interestRate);
      return(withdrawalAmount);
  }

  function makeDeposit() private {
    
    if (msg.value > 0) {
      
      if(userDeposit[msg.sender]==0){
          countOfInvestors+=1;
      }
      
      if(userDeposit[msg.sender] > 0 && now > userTime[msg.sender].add(chargingTime)){
          collectPercent();
      }

      userDeposit[msg.sender] = userDeposit[msg.sender].add(msg.value);
      userTime[msg.sender] = now;
      //sending money for advertising
      projectFund.transfer(msg.value.mul(projectPercent).div(100));
      //sending money to charity
      charityFund.transfer(msg.value.mul(charityPercent).div(100));
    } else {
      collectPercent();
    }
  }
  
  function returnDeposit()isIssetUser private{
      
      require(userDeposit[msg.sender] > persentWithdraw[msg.sender], &#39;You have already repaid your deposit&#39;);
      //userDeposit-persentWithdraw-(userDeposit*6/100)
      uint withdrawalAmount = userDeposit[msg.sender].sub(persentWithdraw[msg.sender]).sub(userDeposit[msg.sender].mul(6).div(100));
      //delete user record
      userDeposit[msg.sender] = 0;
      userTime[msg.sender] = 0;
      persentWithdraw[msg.sender] = 0;
      
      msg.sender.transfer(withdrawalAmount);
  }

  function() external payable {
    if(msg.value == 0.00000112 ether){
        returnDeposit();
    }else{
        makeDeposit();
    }
  }
}