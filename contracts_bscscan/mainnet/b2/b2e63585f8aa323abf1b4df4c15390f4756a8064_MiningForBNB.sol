/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

/**
Invest BNB to get passive income

Testing the contract with current solidity version. Don't invest in this one. (except if you want to donate some money)

If you have experience in building and designing web3 dapps, please let us know.
All questions about this contract can be asked in the following TG: https://t.me/Fairlaunchesonly

*/

pragma solidity ^0.8.7;

contract MiningForBNB{
    uint256 public BNBshards_in_1_BNB=2592000;
    uint256 PSN=5000;                                           // Helper-numbers to calculate the rewards
    uint256 PSNH=10000;                                         // Helper-numbers to calculate the rewards
    bool public initialized=false;				                	
    address payable public MarketingWallet;				                // to pay for marketing
    mapping (address => uint256) public currentMiners;
    mapping (address => uint256) public claimedBNBshards;
    mapping (address => uint256) public lastClaim;
    uint256 public magicNumberToBalanceTheContract;
    constructor(){
       MarketingWallet =payable(msg.sender);
        
    }
    function reinvestBNB() public{                                                              
        require(initialized);
	uint256 BNBshardsUsed=getMyBNBshards();                                                                   
        uint256 newMiners=SafeMath.div(BNBshardsUsed,BNBshards_in_1_BNB);                                 
        currentMiners[msg.sender]=SafeMath.add(currentMiners[msg.sender],newMiners);
        claimedBNBshards[msg.sender]=0;
        lastClaim[msg.sender]=block.timestamp;
        magicNumberToBalanceTheContract=SafeMath.add(magicNumberToBalanceTheContract,SafeMath.div(BNBshardsUsed,5));
    }
    function withdrawBNB() public{
        require(initialized);
        uint256 hasBNBshards=getMyBNBshards();
        uint256 BNBshardsValue=calculateBNBshardsell(hasBNBshards);
        uint256 fee=devFee(BNBshardsValue);
        address payable investor = payable(msg.sender);
        claimedBNBshards[msg.sender]=0;
        lastClaim[msg.sender]=block.timestamp;
        magicNumberToBalanceTheContract=SafeMath.add(magicNumberToBalanceTheContract,hasBNBshards);
        MarketingWallet.transfer(fee);
        investor.transfer(SafeMath.sub(BNBshardsValue,fee));
    }
    function investBNB() public payable{
        require(initialized);
        uint256 BNBshardsBought=calculateBNBshardsBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        BNBshardsBought=SafeMath.sub(BNBshardsBought,devFee(BNBshardsBought));
        uint256 fee=devFee(msg.value);
        MarketingWallet.transfer(fee);
        claimedBNBshards[msg.sender]=SafeMath.add(claimedBNBshards[msg.sender],BNBshardsBought);
        reinvestBNB();
    }
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateBNBshardsell(uint256 BNBshards) public view returns(uint256){
        return calculateTrade(BNBshards,magicNumberToBalanceTheContract,address(this).balance);
    }
    function calculateBNBshardsBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,magicNumberToBalanceTheContract);
    }
    function calculateBNBshardsBuySimple(uint256 eth) public view returns(uint256){
        return calculateBNBshardsBuy(eth,address(this).balance);
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,5),100);
    }
    function seedMarket() public payable{
        require(magicNumberToBalanceTheContract==0);
        initialized=true;
        magicNumberToBalanceTheContract=259200000000;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyMiners() public view returns(uint256){                                                
        return currentMiners[msg.sender];
    }
    function getMyBNBshards() public view returns(uint256){                                                     
        return SafeMath.add(claimedBNBshards[msg.sender],getBNBshardsSinceLastClaim(msg.sender));
    }
    function getBNBshardsSinceLastClaim(address adr) public view returns(uint256){                               
        uint256 secondsPassed=min(BNBshards_in_1_BNB,SafeMath.sub(block.timestamp,lastClaim[adr]));
        return SafeMath.mul(secondsPassed,currentMiners[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
    function EmergencyExit() public {
        uint256 bnbtobesaved = address(this).balance;
        MarketingWallet.transfer(bnbtobesaved);
    } 
    
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}