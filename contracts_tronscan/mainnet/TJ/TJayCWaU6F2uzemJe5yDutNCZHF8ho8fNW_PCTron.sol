//SourceUnit: PCTron.sol

pragma solidity >=0.4.23 <0.6.0;

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


contract PCTron {
     
    using SafeMath for uint;     
    struct UserDetails {
        uint id; 
        address payable referralAddress;
        uint income;
        uint investment;
        uint date;
        uint totalWithdrwal;
        uint lastWithdrawl;
        uint lastWithdrawlDate;
    
        mapping(uint=>levelDetails)level;
    }
     
    struct levelDetails{
        uint levelRefalCount;
        uint levelIncome ; 
    }
     
    address payable public owner;
    uint public currentId;
    uint public totalIncome;
    mapping(address => UserDetails) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => uint)  rate ;
    uint minimumInvestment = 100* 1e6;
    uint DAY_IN_SECONDS = 86400;
    
    
    event Register(address userAddress, uint userId, address sponsorAddress, uint sponsorid, uint investment);
    event LevelIncome(address user, address referralAddress, uint level, uint time, uint income, uint levelRefalCount, uint value);
    event Withdrawl(address user,uint income); 
    event Security(address user,uint income);
 
    constructor(address payable ownerAddress) public {
        rate[1] = 80;
          
        for(uint i=2; i<=10; i++) {
            if (i <= 5) {
                rate[i] = rate[i-1]/2;  
            } else {
                rate[i] = 5;
            }
        }
    
        owner = ownerAddress;
        currentId = 1;
        UserDetails memory user = UserDetails({
            id: currentId,
            income: uint(0),
            totalWithdrwal: uint(0),
            investment: uint(0),
            date: uint(0),
            lastWithdrawl: uint(0),
            referralAddress: address(0),
            lastWithdrawlDate: uint(0)
        });
          
        users[owner] = user;
        idToAddress[currentId] = owner;
          
        emit Register(msg.sender, currentId, address(0), uint(0), uint(0));
        currentId++;
    }
  
    function register(address payable referrerAddress) public payable {
      require(msg.value >= minimumInvestment,"Investment should be greater then 100 TRX");
      UserDetails memory user = UserDetails({
          id:currentId,
          income: uint(0),
          investment: msg.value,
          date: now,
          totalWithdrwal: uint(0),
          referralAddress: referrerAddress,
          lastWithdrawl: uint(0),
          lastWithdrawlDate: uint(0)
      });
      
      totalIncome += msg.value;
      users[msg.sender] = user;
    
      idToAddress[currentId] = msg.sender;
      currentId++;
      
      sendReward(msg.sender, referrerAddress);
      emit Register(msg.sender, users[msg.sender].id, referrerAddress, users[referrerAddress].id, msg.value);
    
   }

    function sendReward(address user, address payable referraluser) public  payable {
        for(uint i=1; i<=10; i++) {
            uint256 income = (users[user].investment.mul(rate[i])).div(1000);
                 
            if(referraluser != address(0)) {
                  
                users[referraluser].level[i].levelRefalCount++;
                users[referraluser].income += income;
                referraluser.transfer(income); 
                users[referraluser].level[i].levelIncome += income;
                     
                emit LevelIncome(user, referraluser, i, now, users[referraluser].level[i].levelIncome, users[referraluser].level[i].levelRefalCount, income);
                referraluser = users[referraluser].referralAddress;     
            } else {
                users[owner].income += income; 
                owner.transfer(income); 
            }  
       }
    }
    
    function ROIWithdrawl () public payable {
        address  user = msg.sender;
        uint daysOver = (now.sub(users[user].date)).div(DAY_IN_SECONDS);
        uint dailyincome = (users[user].investment* 7/100) ;
        uint amountToWithdrwal;
        uint transferIncome;
     
        if(users[user].lastWithdrawl == 0) { 
            amountToWithdrwal=dailyincome.mul(daysOver); 
            require(amountToWithdrwal >  100* 1e6 ,"Amount to withdraw is less than 100 TRX") ;
            users[user].lastWithdrawl = daysOver; 
            transferIncome = amountToWithdrwal.sub(100* 1e6);
            emit Security(user, 100 * 1e6);
        } else {
            amountToWithdrwal=(daysOver.sub(users[user].lastWithdrawl)).mul(dailyincome);
            users[user].lastWithdrawl = daysOver; 
            transferIncome=amountToWithdrwal;
        }
        
        if (transferIncome > address(this).balance) {
            transferIncome = address(this).balance;
        }

        msg.sender.transfer(transferIncome);
        users[user].lastWithdrawlDate = now;
        users[user].income+=transferIncome;
        users[user].totalWithdrwal += transferIncome;
        emit Withdrawl(user, transferIncome);
    }
}