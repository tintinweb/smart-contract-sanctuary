pragma solidity 0.4.25;

/**
 * Anonplayer : Who will win the League of Legends World Championship 2018 ?(Liquid|100 Thieves)
 * betting time ends 1535979600 UNIX
 * The fallback function allows you to bet agree / 1st-choice on the above competetion
 * minimum bet 0.02 ETH
 *
 */

 contract Justice {

   using SafeMath for uint;

   // variables
   address public admin;
   uint256 public fee; // per 1000
   uint256 public endTime; // Unix time bets will be allowed till
   uint256 public limitTime; // failsafe time, past which in case of inactivity by the admin users can withdraw funds

   mapping (address => uint256) public agreeMap; // bets on agree mapped by sent address
   mapping (address => uint256) public disagreeMap; // bets on disagree mapped by sent address
   address[] agreeList; // lists to iterate payments
   address[] disagreeList;
   uint256 public totalAgree;
   uint256 public totalDisagree;
   string public statement;
   uint256 private iterA;
   uint256 private iterB;

   // events
   event Deposit(bool agree);
   event Withdraw(bool agree, uint value);
   event Result(string msg);

   modifier isAdmin() {
       require(msg.sender == admin);
       _;
   }

   constructor (string statement_, uint256 endTime_,  uint256 limitTime_) public {
     admin = msg.sender;
     statement = statement_;
     endTime = endTime_;
     limitTime = limitTime_;
     fee = 8;
     iterA = 0;
     iterB = 0;
   }

   // Entering and withdrawing from bets

   // this is agree() but is using fallback mechanism

   function() public payable {
     require(block.timestamp < endTime && agreeMap[msg.sender].add(msg.value) > 0.02 ether);
     if (agreeMap[msg.sender] == 0) { agreeList.push(msg.sender); }
     agreeMap[msg.sender] = agreeMap[msg.sender].add(msg.value);
     totalAgree =totalAgree.add(msg.value);
     emit Deposit(true);
   }

   function agreeWithdraw(uint amount) public {
     require(agreeMap[msg.sender] >= amount && block.timestamp < endTime);
     agreeMap[msg.sender] = agreeMap[msg.sender].sub(amount);
     totalAgree = totalAgree.sub(amount);
     msg.sender.transfer(amount);
     emit Withdraw(true, amount);
   }

   function disagree() public payable {
     require(block.timestamp < endTime && disagreeMap[tx.origin].add(msg.value) > 0.02 ether);
     if (disagreeMap[tx.origin] == 0) { disagreeList.push(tx.origin); }
     disagreeMap[tx.origin] = disagreeMap[tx.origin].add(msg.value);
     totalDisagree =totalDisagree.add(msg.value);
     emit Deposit(false);
   }

   function disagreeWithdraw(uint amount) public {
     require(disagreeMap[msg.sender] >= amount && block.timestamp < endTime);
     disagreeMap[msg.sender] = disagreeMap[msg.sender].sub(amount);
     totalDisagree = totalDisagree.sub(amount);
     msg.sender.transfer(amount);
     emit Withdraw(false, amount);
   }

   // Fallback in case admin is absent long after event.
   // Allows players to Withdraw funds indefinately
   function lockBreak() public {
     require( limitTime < block.timestamp );
     endTime = 3000000000;
   }

   // In case fair conditions are disrupted
   function endBetting() public isAdmin {
     endTime = block.timestamp.sub(900);
     emit Result("early");
   }

   // admin tools to return winnings

   function resultDraw() public isAdmin {
     require( endTime < block.timestamp);

     if(iterA != agreeList.length)
     multiSendA(1000 - fee, 1000);
     else {
         if(iterB != disagreeList.length)
         multiSendB(1000 - fee, 1000);
         if(iterB == disagreeList.length) {
             admin.transfer(address(this).balance);
             emit Result("draw");
         }
     }
   }

   function resultAccept() public isAdmin {
     require( endTime < block.timestamp);
     multiSendA((totalDisagree+totalAgree).mul(1000 - fee), totalAgree.mul(1000));
     if(iterA == agreeList.length) {
         admin.transfer(address(this).balance);
         emit Result("agree");
     }
   }

   function resultReject() public isAdmin {
     require( endTime < block.timestamp);
     multiSendB((totalDisagree+totalAgree).mul(1000 - fee), totalDisagree.mul(1000));
     if(iterB == disagreeList.length) {
         admin.transfer(address(this).balance);
         emit Result("disagree");
     }
   }

   function multiSendA( uint256 numer, uint256 denom ) internal isAdmin {
     for (uint initi = iterA; iterA < initi + 10 && iterA < agreeList.length; iterA++) {
         agreeList[iterA].send(agreeMap[agreeList[iterA]].mul(numer).div(denom));
     }
   }

   function multiSendB( uint256 numer, uint256 denom ) internal isAdmin {
     for (uint initi = iterB; iterB < initi + 10 && iterB < disagreeList.length; iterB++) {
         disagreeList[iterB].send(disagreeMap[agreeList[iterB]].mul(numer).div(denom));
     }
   }

  }

  // github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
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
     require(b > 0); // Solidity only automatically asserts when dividing by 0
     uint256 c = a / b;
     // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

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

 }