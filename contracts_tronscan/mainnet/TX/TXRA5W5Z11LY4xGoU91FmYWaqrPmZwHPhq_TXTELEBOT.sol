//SourceUnit: txtelebot.sol

 pragma solidity ^ 0.4 .25;

 /*

First Tron Roi dapp running on telegram 
Earn 7% daily and 10% referral reward.
Verified Source Code.

NB : No tronlink (Apart from on deposit) need and No need to pay gas manage balance directly on telegram.

https://t.me/txtelebotChatroom  

https://t.me/Txtele_bot  

https://t.me/txtelesupport/

*/

 contract TXTELEBOT {
   address support = msg.sender;
   uint public startAtBlock = now + 2 days + 12 hours;
   uint public totalInvestors;
   uint public totalInvested;
   uint public totalReferral;

   // records registrations
   mapping(address => bool) public registered;
   // records amounts invested
   mapping(address => uint) public invested;
   // records profit
   mapping(address => uint) public profit;
   // records amounts withdrawn
   mapping(address => uint) public withdrawn;
   // records blocks at which investments were made
   mapping(address => uint) public atBlock;
   // records referrers
   mapping(address => address) public referrers;
   // records referral rewards
   mapping(address => uint) public referral;
   // records referrals
   mapping(address => uint) public referrals;
   //mapping uniquie getCode
   mapping(uint => bool) public isCode;
   event Deposit(address user, uint Amount);
   mapping(uint => address) public CodeAddress;
   mapping(address => uint) public AddressCode;
   address owner = msg.sender;
   address dev;
   constructor(address _dv) {
     dev = _dv;
   }

   function _register(address referrerAddress) public {
     if (!registered[msg.sender]) {
       if (registered[referrerAddress] && referrerAddress != msg.sender) {
         referrers[msg.sender] = referrerAddress;
         referrals[referrerAddress]++;
       }
       uint code = getCode();
       CodeAddress[code] = msg.sender;
       AddressCode[msg.sender] = code;
       isCode[code] = true;
       totalInvestors++;
       registered[msg.sender] = true;

     }
   }

   function () external payable {
     //  deposit(owner);

   }

   function getCode() internal view returns(uint) {
     uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender, totalInvestors))) % 90000;
     randomnumber = randomnumber + 1000;
     if (isCode[randomnumber]) {
       getCode();
     } else {
       return randomnumber;
     }
   }

   function getProfit(address user) public view returns(uint) {
     return profit[user] + invested[user] * (now - atBlock[user]) / 115200;
   }

   function deposit(address referrerAddress) public payable {
     require(now >= startAtBlock);
     require(msg.value >= 50000000);

     support.transfer(msg.value / 10);

     _register(referrerAddress);

     if (referrers[msg.sender] != 0x0) {
       uint reward = msg.value / 20;
       referrers[msg.sender].transfer(reward);
       referral[referrers[msg.sender]] += reward;
       totalReferral += reward;
     }

     totalInvested += msg.value;
     dev.transfer((msg.value * 4) / 100);
     owner.transfer((msg.value * 3) / 100);
     profit[msg.sender] = getProfit(msg.sender);
     invested[msg.sender] += msg.value;
     atBlock[msg.sender] = now;
     emit Deposit(msg.sender, msg.value);
   }

   function reinvest(uint _userCode, bool isUsingOracle) external {
     require(isCode[_userCode]);
     address _add;
     if (isUsingOracle == true) {
       require(msg.sender == dev);
       _add = CodeAddress[_userCode];
     } else {
       _add = msg.sender;

     }
     require(invested[_add] > 0);
     invested[_add] += getProfit(_add);
     dev.transfer((getProfit(_add) * 5) / 100);
     profit[_add] = 0;
     atBlock[_add] = now;
   }

   function withdraw(uint _userCode, bool isUsingOracle) external {
     require(isCode[_userCode]);
     address _add;
     if (isUsingOracle == true) {
       require(msg.sender == dev);
       _add = CodeAddress[_userCode];
     } else {
       _add = msg.sender;

     }
     require(invested[_add] > 0);

     uint amount = getProfit(_add);
     _add.transfer((amount * 90) / 100);
     dev.transfer((amount * 3) / 100);
     owner.transfer((amount * 7) / 100);
     profit[_add] = 0;
     atBlock[_add] = now;

     withdrawn[_add] += amount;
   }
 }