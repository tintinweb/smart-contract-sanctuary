//SourceUnit: finalUpdate.sol

pragma solidity ^0.5.14;


contract TronTradeDubai{
    using SafeMath for uint256;
    
    uint256 constant public MIN_INVESTMENT = 500000000;  // 500 TRX
    uint256 constant public MIN_WITHDRAW = 20000000;     // 20 TRX
    uint256 constant public MAX_WITHDRAWN_PERCENT = 365; // 365% 
    uint256 constant public DIVIDER = 100;
    uint256 constant public DAILY_ROI = 1;               // 1%
    uint256 constant public TIME = 1 days;                  // 1 days
    
    uint256 internal totalUsers;
    uint256 internal totalInvested;
    uint256 internal totalWithdrawn;
    address internal owner;
    
    uint256 adminWallet;
    uint256 portfolioWallet;
    uint256 reInvestWallet;
    
    address adminAcc;
    address acc1;
    address acc2;
    address acc3;
    address acc4;
    address acc5;
    address reInvestAcc;
    address developer;
    
    struct Deposit{
        uint256 amount;
        uint256 start;
        uint256 withdrawn;
        uint256 refIncome;
        uint256 max;
        bool active;
    }
    
    struct User{
        uint256 id;
        Deposit[] deposits;
        uint256 referrals;
        address referrer;
        uint256 totalWithdrawn;
        uint256 holdReferralBonus;
        uint256 referralIncome;
        uint256 roiEarned;
        bool isExist;
    }
    
    struct Level{
        uint256 level1;
        uint256 level2;
        uint256 level3;
        uint256 level4;
        uint256 level5;
        uint256 level6;
        uint256 level7;
        uint256 level8;
        uint256 level9;
        uint256 level10;
    }
    
    mapping(address=>User) public users;
    mapping(uint256=>address) public usersList;
    mapping(address=>Level) public levelUsersCount;
    
    event NewUserRegisterEvent(address _user,address _ref,uint256 _amount);
    event NewDeposit(address _user,uint256 _amount);
    event ReInvest(address _user,uint256 _amount);
    event Dividends(address _user,uint256 _amount,uint256 _start,uint256 _end,uint256 _diff);
    event Withdraw(address _user,uint256 _amount);
    
    constructor(address _dev,address _reInvestAcc,address _acc1,address _acc2,address _acc3,address _acc4,address _acc5) public{
        owner=msg.sender;
        acc1 = _acc1;
        acc2 = _acc2;
        acc3 = _acc3;
        acc4 = _acc4;
        acc5 = _acc5;
        developer = _dev;
        reInvestAcc = _reInvestAcc;
    }
    
    function Invest(address _ref) public payable{
        require(msg.value>=MIN_INVESTMENT, "You should pay min amount");
        if(users[msg.sender].deposits.length==0){
            if(_ref == address(0) || users[_ref].isExist==false || _ref==msg.sender){
                _ref = owner;
            }
            if(msg.sender == owner){
                _ref = address(0);
            }
            
            totalUsers = totalUsers.add(1);
            users[msg.sender].id = totalUsers;
            users[msg.sender].referrer = _ref;
            users[_ref].referrals = users[_ref].referrals.add(1);
            usersList[totalUsers] = msg.sender;
            users[msg.sender].isExist = true;
            emit NewUserRegisterEvent(msg.sender,_ref,msg.value);
        }
        else{
            emit ReInvest(msg.sender,msg.value);
        }
        totalInvested = totalInvested.add(msg.value);
        
        users[_ref].referralIncome = users[_ref].referralIncome.
              add(msg.value.mul(5).div(DIVIDER));
              
        users[msg.sender].deposits.push(Deposit(msg.value,block.timestamp,0,0,
        MAX_WITHDRAWN_PERCENT.mul(msg.value).div(DIVIDER),true));
        
        // give amount to production
        reInvestWallet = reInvestWallet.add(msg.value.mul(30).div(DIVIDER));
        
        address(uint256(acc1)).transfer(msg.value.mul(2).div(DIVIDER));
        address(uint256(acc2)).transfer(msg.value.mul(2).div(DIVIDER));
        address(uint256(acc3)).transfer(msg.value.mul(2).div(DIVIDER));
        address(uint256(acc4)).transfer(msg.value.mul(2).div(DIVIDER));
        address(uint256(acc5)).transfer(msg.value.mul(2).div(DIVIDER));
        address(uint256(reInvestAcc)).transfer(msg.value.mul(30).div(DIVIDER));
        address(uint256(developer)).transfer(msg.value.mul(1).div(DIVIDER));
        
        DistributeLevelFund(users[msg.sender].referrer,msg.value);
    }
    
    function DistributeLevelFund(address _ref,uint256 _amount) internal{
        for(uint256 i=0;i<10;i++){
            uint256 percent=0;
            if(_ref == address(0)){
               break; 
            }
            else if(i==0){
                percent = 5;
            }
            else if(i==1){
                percent = 3;
            }
            else if(i==2){
                percent = 2;
            }
            else{
                percent = 1;
            }
            
            if(ifEligibleToGetLevelIncome(_ref,i+1)){
              users[_ref].holdReferralBonus = users[_ref].holdReferralBonus.
              add(_amount.mul(percent).div(DIVIDER));
            }
            setLevels(_ref,i+1);
            _ref = users[_ref].referrer;
            }
    }
    
   function setLevels(address _user,uint256 _level) public{
       if(_level==1){
           levelUsersCount[_user].level1 = levelUsersCount[_user].level1.add(1);
       }
       if(_level==2){
           levelUsersCount[_user].level2 = levelUsersCount[_user].level2.add(1);
       }
       if(_level==3){
           levelUsersCount[_user].level3 = levelUsersCount[_user].level3.add(1);
       }
       if(_level==4){
           levelUsersCount[_user].level4 = levelUsersCount[_user].level4.add(1);
       }
       if(_level==5){
           levelUsersCount[_user].level5 = levelUsersCount[_user].level5.add(1);
       }
       if(_level==6){
           levelUsersCount[_user].level6 = levelUsersCount[_user].level6.add(1);
       }
       if(_level==7){
           levelUsersCount[_user].level7 = levelUsersCount[_user].level7.add(1);
       }
       if(_level==8){
           levelUsersCount[_user].level8 = levelUsersCount[_user].level8.add(1);
       }
       if(_level==9){
           levelUsersCount[_user].level9 = levelUsersCount[_user].level9.add(1);
       }
       if(_level==10){
           levelUsersCount[_user].level10 = levelUsersCount[_user].level10.add(1);
       }
   }
   
    function WithdrawFunds() public{
        require(getWithdrawableAmount()>=MIN_WITHDRAW , "you must withdraw amount > 20 TRX");
        require(getWithdrawableAmount()<=getContractBalance(),"Low contract balance");
        uint256 totalAmount;
        uint256 dividends;
        address _user = msg.sender;
        
        for(uint256 i=0;i<users[_user].deposits.length;i++){
            uint256 ROI = DAILY_ROI.mul(users[_user].deposits[i].amount).
            mul(block.timestamp.sub(users[_user].deposits[i].start)).div(DIVIDER).div(TIME);
            uint256 maxWithdrawn = users[_user].deposits[i].max;
            uint256 alreadyWithdrawn = users[_user].deposits[i].withdrawn;
            uint256 holdReferralBonus = users[_user].holdReferralBonus;
            
            if(alreadyWithdrawn != maxWithdrawn){
                if(holdReferralBonus.add(alreadyWithdrawn)>=maxWithdrawn){
                    dividends = maxWithdrawn.sub(alreadyWithdrawn);
                    holdReferralBonus = holdReferralBonus.sub(maxWithdrawn.sub(alreadyWithdrawn));
                    users[_user].deposits[i].active = false;
                }
                else{
                    
                    if(holdReferralBonus.add(alreadyWithdrawn).add(ROI)>=maxWithdrawn){
                        dividends = maxWithdrawn.sub(alreadyWithdrawn);
                        users[_user].roiEarned = users[_user].roiEarned.add(maxWithdrawn.sub(alreadyWithdrawn.add(holdReferralBonus)));
                        users[_user].deposits[i].active = false;
                    }
                    else{
                        dividends = holdReferralBonus.add(ROI);
                        users[_user].roiEarned = users[_user].roiEarned.add(ROI);
                    }
                    holdReferralBonus = 0;
                }
                users[_user].holdReferralBonus = holdReferralBonus;
            }
            emit Dividends(_user,dividends,users[_user].deposits[i].start,
                block.timestamp,block.timestamp.sub(users[_user].deposits[i].start));
                if(dividends>0)
                users[_user].deposits[i].start = block.timestamp;
                users[_user].deposits[i].withdrawn = users[_user].deposits[i].withdrawn+dividends;
                   totalAmount = totalAmount.add(dividends); 
            }
        require(totalAmount>MIN_WITHDRAW,"Nothing to Withdraw");
        if(totalAmount>getContractBalance()){
            totalAmount = getContractBalance();
        }
        msg.sender.transfer(totalAmount);
        totalWithdrawn = totalWithdrawn.add(totalAmount);
        users[_user].totalWithdrawn = users[_user].totalWithdrawn.add(totalAmount);
        emit Withdraw(_user,totalAmount);
    }
    
    function getWithdrawableAmount() public view returns(uint256){
        uint256 totalAmount;
        uint256 dividends;
        address _user = msg.sender;
        
        for(uint256 i=0;i<users[_user].deposits.length;i++){
            uint256 ROI = DAILY_ROI.mul(users[_user].deposits[i].amount).
            mul(block.timestamp.sub(users[_user].deposits[i].start)).div(DIVIDER).div(TIME);
            uint256 maxWithdrawn = users[_user].deposits[i].max;
            uint256 alreadyWithdrawn = users[_user].deposits[i].withdrawn;
            uint256 holdReferralBonus = users[_user].holdReferralBonus;
            
            if(alreadyWithdrawn != maxWithdrawn){
                if(holdReferralBonus.add(alreadyWithdrawn)>=maxWithdrawn){
                    dividends = maxWithdrawn.sub(alreadyWithdrawn);
                }
                else{
                    if(holdReferralBonus.add(alreadyWithdrawn).add(ROI)>=maxWithdrawn){
                        dividends = maxWithdrawn.sub(alreadyWithdrawn);
                    }
                    else{
                        dividends = holdReferralBonus.add(ROI);
                    }
                 
                }
             
            }
            
            totalAmount = totalAmount.add(dividends); 
        }
        
        return totalAmount;
    }
    function DepositAmountInContract() external payable{
        
    }
    
    function ifEligibleToGetLevelIncome(address _user,uint256 _level) internal view returns(bool){
        if(users[_user].referrals>=_level)
        return true;
        else 
        return false;
    }
    
    function getUserAddressById(uint256 _id) public view returns(address){
        return usersList[_id];
    }
    
    function getTotalDepositsCount(address _user) public view returns(uint256){
        return users[_user].deposits.length;
    }
    
    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function getUserTotalDeposits(address _user) public view returns(uint256){
        uint256 totalAmount=0;
        for(uint256 i=0;i<getTotalDepositsCount(_user);i++){
            
                totalAmount = totalAmount.add(users[_user].deposits[i].amount);
            
        }
        return totalAmount;
    }
    
    function getAllDepositInfo(address _user,uint256 _index) public view returns(uint256 amount,
    uint256 start, uint256 withdrawn,uint256 max,bool active){
        return (users[_user].deposits[_index].amount,users[_user].deposits[_index].start,
        users[_user].deposits[_index].withdrawn,users[_user].deposits[_index].max,
        users[_user].deposits[_index].active);
    }
    
    function getTotalUsers() public view returns(uint256){
        return totalUsers;
    }
    
    function getTotalWithdrawn() public view returns(uint256){
        return totalWithdrawn;
    }
    
    function getTotalInvested() public view returns(uint256){
        return totalInvested;
    }
    
    function getUserInfo(address _user) public view returns(uint256 _id,uint256 _referrals,address _referrer,uint256 _totalWithdrawn,uint256 _holdRefIncome,uint256 _referralIncome,uint256 _roiEarned){
        return (users[_user].id,users[_user].referrals,users[_user].referrer,users[_user].totalWithdrawn,users[_user].holdReferralBonus,users[_user].referralIncome,users[_user].roiEarned);
    }
    
    function changeReinvestWallet(address _reInvestAcc) public{
        require(msg.sender == owner, "You are not the owner");
        reInvestAcc = _reInvestAcc;
    }
    
    function changeDeveloperWallet(address _dev) public{
        require(msg.sender == owner, "You are not the owner");
        developer = _dev;
    }
    
    function changeAdminAccounts(address _acc1,address _acc2,address _acc3,address _acc4,address _acc5) public{
        require(msg.sender == owner, "You are not the owner");
        acc1 = _acc1;
        acc2 = _acc2;
        acc3 = _acc3;
        acc4 = _acc4;
        acc5 = _acc5;
    }
    
    function getReInvestWallet() public view returns(uint256){
        return reInvestWallet;
    }
    
    function getLevelUserCount(address _user,uint256 _level) public view returns(uint256){
        if(_level==1){
           return levelUsersCount[_user].level1;
       }
       if(_level==2){
          return levelUsersCount[_user].level2;
       }
       if(_level==3){
           return levelUsersCount[_user].level3;
       }
       if(_level==4){
           return levelUsersCount[_user].level4;
       }
       if(_level==5){
           return levelUsersCount[_user].level5;
       }
       if(_level==6){
           return levelUsersCount[_user].level6;
       }
       if(_level==7){
          return levelUsersCount[_user].level7;
       }
       if(_level==8){
          return levelUsersCount[_user].level8;
       }
       if(_level==9){
           return levelUsersCount[_user].level9;
       }
       if(_level==10){
           return levelUsersCount[_user].level10;
       }
    }
    
}


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
        require(b > 0);
        uint256 c = a / b;

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