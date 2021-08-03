//SourceUnit: TRONLottery3.sol

pragma solidity >=0.4.22 <0.6.0;

contract TRONlottery3 {
    using SafeMath for uint256;

    uint256 constant public INVEST_MIN_AMOUNT = 1 trx;
    uint256 constant public BASE_PERCENT = 20;
    uint256[] public REFERRAL_PERCENTS = [150, 50, 20, 10];
    uint256 constant public MARKETING_FEE = 80;
    uint256 constant public PROJECT_FEE = 70;
    uint256 constant public ADMIN_FEE = 30;
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public CONTRACT_BALANCE_STEP = 100000000 trx;
    uint256 constant public TIME_STEP = 1 days;

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;

    address payable public marketingAddress;
    address payable public projectAddress;
    address payable public adminAddress;


    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
        uint256 bonus;
        uint256 earn;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        uint256 bonus;
        uint256 totalbonus;
        uint256 totalwithdrawn;
        uint256 withdrawlen;
        uint256 reflen;
        uint256 commulen;
    }

    mapping (address => User) internal users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor(address payable marketingAddr, address payable projectAddr, address payable adminAddr) public {
        require(!isContract(marketingAddr) && !isContract(projectAddr));
        marketingAddress = marketingAddr;
        projectAddress = projectAddr;
        adminAddress = adminAddr;
    }

    function invest(address referrer) public payable {
        require(msg.value >= INVEST_MIN_AMOUNT);

        marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
        projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
        emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

        User storage user = users[msg.sender];

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }

        if (user.referrer != address(0)) {

            address upline = user.referrer;
            users[upline].reflen = users[upline].reflen.add(1);
            for (uint256 i = 0; i < 4; i++) {
                if (upline != address(0)) {
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    users[upline].bonus = users[upline].bonus.add(amount);
                    users[upline].commulen = users[upline].commulen.add(1);
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }

        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            totalUsers = totalUsers.add(1);
            emit Newbie(msg.sender);
        }
        
        uint256 totalDeposit = getUserTotalDeposits(msg.sender);
        uint256 totalWithdrawn1 = user.totalwithdrawn;
         // uint256 curravaliable = getUserAvailable(msg.sender);
        uint256 curravaliable = (user.bonus).add(getUserDividends(msg.sender));
        uint256 totalEarn = totalWithdrawn1.add(curravaliable);
        if((user.deposits.length > 0) && (totalEarn  >  totalDeposit.mul(3)) ){
         
        /*   uint256 bonus = user.bonus;
           uint256 depositl = totalDeposit.mul(3);
            uint256  extrareferral  = bonus.sub(depositl);
            uint256  bonusreferral = bonus.sub(extrareferral; */
            uint256 useravaliable1 = totalDeposit.mul(3);
            uint256 extraavaliable = totalEarn.sub(useravaliable1);
            uint256 useravaliable11 = totalEarn.sub(extraavaliable);
            uint256 useravaliable111 = useravaliable11.sub(user.totalwithdrawn);
           uint256 bonusreferral = useravaliable111.sub(getUserDividends(msg.sender));
            user.bonus = bonusreferral; 
         }
        
   if (user.deposits.length == 1) {
           uint256 curbonus = user.deposits[user.deposits.length-1].bonus;
           uint256 avabonus = curbonus.add(user.bonus);
           uint256 curwithd = user.deposits[user.deposits.length-1].earn;
           uint256 avawithd = curwithd.add(user.bonus);
            user.deposits[user.deposits.length-1].bonus = avabonus;
            user.deposits[user.deposits.length-1].earn = avawithd;
        }
        
        
        if (user.deposits.length > 1) {
           uint256 prebonus = getUserTotalBonus(msg.sender);    
           uint256 curbonus = user.deposits[user.deposits.length-1].bonus;
           uint256 currbonus = (user.totalbonus).add(user.bonus);
           uint256 avacurbonus = curbonus.add(currbonus);
           uint256 avabonus;
           if(avacurbonus > prebonus){
               avabonus = avacurbonus.sub(prebonus);
           } else {
               avabonus = prebonus.sub(avacurbonus);
           }
           
           uint256 curwithd = user.deposits[user.deposits.length-1].earn;
           uint256 avawithd = curwithd.add(avabonus);
           
            user.deposits[user.deposits.length-1].bonus = avabonus;
            user.deposits[user.deposits.length-1].earn = avawithd;
        }
        
        
              
        user.deposits.push(Deposit(msg.value, 0, block.timestamp,0 , 0));
        
        
        totalInvested = totalInvested.add(msg.value);
        totalDeposits = totalDeposits.add(1);

        emit NewDeposit(msg.sender, msg.value);

    }


      function reinvest(address referrer) public payable {
        require(msg.value >= INVEST_MIN_AMOUNT);

        marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
        projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
        emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

        User storage user = users[msg.sender];

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }

        if (user.referrer != address(0)) {

            address upline = user.referrer; 
            for (uint256 i = 0; i < 4; i++) {
                if (upline != address(0)) {
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    users[upline].bonus = users[upline].bonus.add(amount);
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }

        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            totalUsers = totalUsers.add(1);
            emit Newbie(msg.sender);
        }
        
        uint256 totalDeposit = getUserTotalDeposits(msg.sender);
        uint256 totalWithdrawn1 = user.totalwithdrawn;
         // uint256 curravaliable = getUserAvailable(msg.sender);
        uint256 curravaliable = (user.bonus).add(getUserDividends(msg.sender));
        uint256 totalEarn = totalWithdrawn1.add(curravaliable);
        if((user.deposits.length > 0) && (totalEarn  >  totalDeposit.mul(3)) ){
         
        /*   uint256 bonus = user.bonus;
           uint256 depositl = totalDeposit.mul(3);
            uint256  extrareferral  = bonus.sub(depositl);
            uint256  bonusreferral = bonus.sub(extrareferral; */
            uint256 useravaliable1 = totalDeposit.mul(3);
            uint256 extraavaliable = totalEarn.sub(useravaliable1);
            uint256 useravaliable11 = totalEarn.sub(extraavaliable);
            uint256 useravaliable111 = useravaliable11.sub(user.totalwithdrawn);
           uint256 bonusreferral = useravaliable111.sub(getUserDividends(msg.sender));
            user.bonus = bonusreferral; 
         }
        
   if (user.deposits.length == 1) {
           uint256 curbonus = user.deposits[user.deposits.length-1].bonus;
           uint256 avabonus = curbonus.add(user.bonus);
           uint256 curwithd = user.deposits[user.deposits.length-1].earn;
           uint256 avawithd = curwithd.add(user.bonus);
            user.deposits[user.deposits.length-1].bonus = avabonus;
            user.deposits[user.deposits.length-1].earn = avawithd;
        }
        
        
        if (user.deposits.length > 1) {
           uint256 prebonus = getUserTotalBonus(msg.sender);    
           uint256 curbonus = user.deposits[user.deposits.length-1].bonus;
           uint256 currbonus = (user.totalbonus).add(user.bonus);
           uint256 avacurbonus = curbonus.add(currbonus);
           uint256 avabonus;
           if(avacurbonus > prebonus){
               avabonus = avacurbonus.sub(prebonus);
           } else {
               avabonus = prebonus.sub(avacurbonus);
           }
           
           uint256 curwithd = user.deposits[user.deposits.length-1].earn;
           uint256 avawithd = curwithd.add(avabonus);
           
            user.deposits[user.deposits.length-1].bonus = avabonus;
            user.deposits[user.deposits.length-1].earn = avawithd;
        }
        
        
              
        user.deposits.push(Deposit(msg.value, 0, block.timestamp,0 , 0));
        
        
        totalInvested = totalInvested.add(msg.value);
        totalDeposits = totalDeposits.add(1);

        emit NewDeposit(msg.sender, msg.value);

    }

    function withdraw() public {
        User storage user = users[msg.sender];

        uint256 userPercentRate = getUserPercentRate(msg.sender);

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        
        if(user.deposits.length == 1 ){
        user.deposits[user.deposits.length-1].bonus = referralBonus;
        user.deposits[user.deposits.length-1].earn = referralBonus;
        }
        
        if(user.deposits.length > 1){
            uint256 prebonus = getUserTotalBonus(msg.sender);    
           uint256 curbonus = user.deposits[user.deposits.length-1].bonus;
           uint256 currbonus = (user.totalbonus).add(user.bonus);
           uint256 avacurbonus = curbonus.add(currbonus);
           uint256 avabonus;
           if(avacurbonus > prebonus){
               avabonus = avacurbonus.sub(prebonus);
           } else {
               avabonus = prebonus.sub(avacurbonus);
           }
           
           uint256 curwithd = user.deposits[user.deposits.length-1].earn;
           uint256 avawithd = curwithd.add(avabonus);
           
            user.deposits[user.deposits.length-1].bonus = avabonus;
            user.deposits[user.deposits.length-1].earn = avawithd;
        }

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (user.deposits[i].earn < user.deposits[i].amount.mul(3)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);

                }
               if(user.deposits[i].earn > 0){
                 if(user.deposits[i].earn.add(dividends) > user.deposits[i].amount.mul(3)) {
                   dividends = (user.deposits[i].amount.mul(3)).sub(user.deposits[i].earn);
                  }
               } else {
               uint256 dividends1 = dividends.add(user.deposits[i].bonus);
                if(user.deposits[i].earn.add(dividends1) > user.deposits[i].amount.mul(3)) {
                   dividends = (user.deposits[i].amount.mul(3)).sub(user.deposits[i].earn);
                }
               }
               if(user.deposits[i].earn > 0){
                   user.deposits[i].earn = ((user.deposits[i].earn).add(dividends));
               } else {
                uint256 dividends2 = dividends.add(user.deposits[i].bonus);
                user.deposits[i].earn = ((user.deposits[i].earn).add(dividends2));
                } 
                
                user.deposits[i].withdrawn = ((user.deposits[i].withdrawn).add(user.deposits[i].earn));
                
                /// changing of storage data
                totalAmount = totalAmount.add(dividends);

            }
        }

        
        
        if (referralBonus > 0) {
            totalAmount = totalAmount.add(referralBonus);
            user.totalbonus = ((user.totalbonus).add(referralBonus));
            user.bonus = 0;
        }
        
        uint256 totalDeposit = getUserTotalDeposits(msg.sender);
        
        uint256 totalwithdrawnlen = user.withdrawlen;
        
        if ( (totalwithdrawnlen == 0)  &&  (totalAmount >  totalDeposit.mul(3)) ) {
            totalAmount = totalDeposit.mul(3);
        }

        if ( (totalwithdrawnlen > 0)  &&  (totalAmount >  totalDeposit.mul(3)) ) {
          uint256  totalAmount1 = totalDeposit.mul(3);
           totalAmount = totalAmount1.sub(user.totalwithdrawn);
        }
        
        

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        
        
   
        user.checkpoint = block.timestamp;
        
        user.totalwithdrawn = ((user.totalwithdrawn).add(totalAmount));
        
        user.withdrawlen = ((user.withdrawlen).add(1));

	adminAddress.transfer(totalAmount.mul(ADMIN_FEE).div(PERCENTS_DIVIDER));
	
        uint256 totalAmount11 = totalAmount.mul(ADMIN_FEE).div(PERCENTS_DIVIDER);
	
        uint256 totalAmount1 = totalAmount.sub(totalAmount11);
        
        msg.sender.transfer(totalAmount1);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
      
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getContractBalanceRate() public view returns (uint256) {
        uint256 contractBalance = address(this).balance;
        if(contractBalance < CONTRACT_BALANCE_STEP) return BASE_PERCENT;
        uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP);
        uint256 contractBalancerate = contractBalancePercent.sub(contractBalancePercent);
        return BASE_PERCENT.add(contractBalancerate);
    }

    function getUserPercentRate(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 contractBalanceRate = getContractBalanceRate();
      
        if (isActive(userAddress)) {
            uint256 timeMultiplier = (now.sub(user.checkpoint)).div(TIME_STEP);
            return contractBalanceRate.add(timeMultiplier);
        } else {
            return contractBalanceRate;
        }
    }

    function getUserDividends(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 userPercentRate = getUserPercentRate(userAddress);
        
       

        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (user.deposits[i].earn < user.deposits[i].amount.mul(3)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);

                }

                /*uint256 dividends1 = dividends.add(user.deposits[i].bonus);
                
                if(user.deposits[i].withdrawn.add(dividends1) > user.deposits[i].amount.mul(3)) {
                   dividends = (user.deposits[i].amount.mul(3)).sub(user.deposits[i].withdrawn);
                   
                } 
                if((user.deposits[i].withdrawn.add(dividends)).add(user.deposits[i].bonus) > user.deposits[i].amount.mul(3)) {
                   dividends = (user.deposits[i].amount.mul(3)).sub(user.deposits[i].withdrawn);
                   
                } */
                
                if(user.deposits[i].earn.add(dividends) > user.deposits[i].amount.mul(3)) {
                   dividends = (user.deposits[i].amount.mul(3)).sub(user.deposits[i].earn);
                   
                }

                totalDividends = totalDividends.add(dividends);
                

                /// no update of withdrawn because that is view function

            }

        }

        return totalDividends;
    }

    function getUserCheckpoint(address userAddress) public view returns(uint256) {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress) public view returns(address) {
        return users[userAddress].referrer;
    }
    
    function getUserTotalReferralBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].totalbonus;
    }
    
    function getUserTotalWithdrawl(address userAddress) public view returns(uint256) {
        return users[userAddress].totalwithdrawn;
    }
    
    function getUserAmountOfWithdraw(address userAddress) public view returns(uint256) {
        return users[userAddress].withdrawlen;
    }
    
    function getUserCurrentReferralBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].bonus;
    }  

    function getUserAmountOfRefferal(address userAddress) public view returns(uint256) {
        return users[userAddress].reflen;
    } 

    function getUserAmountOfCommunity(address userAddress) public view returns(uint256) {
        return users[userAddress].commulen;
    } 

    function getUserReferralBonus(address userAddress) public view returns(uint256) {
        //return users[userAddress].bonus
        uint256 bonus;
        uint256 totalavaliable1 = (users[userAddress].bonus).add(getUserDividends(userAddress));
        uint256 totalavaliable = totalavaliable1.add(users[userAddress].totalwithdrawn);
        uint256 totalDeposit = getUserTotalDeposits(msg.sender);
        if (users[userAddress].bonus >  totalDeposit.mul(3)) {
            //bonus = totalDeposit.mul(3);
            uint256 bonusr = users[userAddress].bonus;
            uint256 depositl = totalDeposit.mul(3);
            uint256  extrareferral  = bonusr.sub(depositl);
            uint256  bonusreferral = bonusr.sub(extrareferral);
            bonus = bonusreferral;
        } else if(totalavaliable >  totalDeposit.mul(3)) {
            //bonus = totalDeposit.mul(3);
            uint256 useravaliable1 = totalDeposit.mul(3);
            uint256 extraavaliable = totalavaliable.sub(useravaliable1);
            uint256 useravaliable11 = totalavaliable.sub(extraavaliable);
            uint256 useravaliable111 = useravaliable11.sub(users[userAddress].totalwithdrawn);
           uint256 bonusreferral = useravaliable111.sub(getUserDividends(userAddress));
           bonus = bonusreferral;
        } else {
            bonus = users[userAddress].bonus;
        }
       return bonus;
    }

    function getUserAvailable(address userAddress) public view returns(uint256) {
       // return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
       uint256 totalavaliable1 = (users[userAddress].bonus).add(getUserDividends(userAddress));
       uint256 totalavaliable = totalavaliable1.add(users[userAddress].totalwithdrawn);
       uint256 useravaliable;
       uint256 totalDeposit = getUserTotalDeposits(msg.sender);
        if (totalavaliable >  totalDeposit.mul(3)) {
            //uint256 useravaliable1 = totalDeposit.mul(3);
            //useravaliable = useravaliable1.sub(users[userAddress].totalwithdrawn);
            uint256 useravaliable1 = totalDeposit.mul(3);
            uint256 extraavaliable = totalavaliable.sub(useravaliable1);
            uint256 useravaliable11 = totalavaliable.sub(extraavaliable);
            useravaliable = useravaliable11.sub(users[userAddress].totalwithdrawn);
        } else {
            useravaliable = (users[userAddress].bonus).add(getUserDividends(userAddress));
        }
        return useravaliable;
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        if (user.deposits.length > 0) {
            if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(3)) {
                return true;
            }
        }
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256, uint256, uint256) {
        User storage user = users[userAddress];

        return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start, user.deposits[index].bonus, user.deposits[index].earn);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
        return users[userAddress].deposits.length;
    }
    

    function getUserTotalDeposits(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].withdrawn);
        }

        return amount;
    }

    function getUserTotalBonus(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].bonus);
        }

        return amount;
    }
    
     function getUserTotalEarn(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].earn);
        }

        return amount;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
    function contractInfo() view external returns(uint256 _totalUsers, uint256 _totalInvested,   uint256 _totalWithdrawn, uint256 _totalDeposites ) {
        return (totalUsers, totalInvested, totalWithdrawn, totalDeposits);
    }

}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}