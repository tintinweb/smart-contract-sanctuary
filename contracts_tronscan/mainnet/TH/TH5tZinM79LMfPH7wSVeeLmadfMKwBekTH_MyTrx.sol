//SourceUnit: mytrx_r3.sol

pragma solidity ^0.5.12;
contract MyTrx {
    using SafeMath for uint256;
    event Newbie(address user);
    event NewInvest(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event ReferrerReward(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event ChangeStage(uint256 stage);
    uint8 public number;
    uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
    uint256 constant public TIME_STEP = 24 hours;
    uint256 constant public INIT_TIME_LIMIT = 12 hours;
    uint256 constant public RANK_LIST_LENGTH = 10;
    uint256 constant public BASE_PERCENT = 20;
    uint256[] public REFERRAL_PERCENTS = [100, 40, 10, 10, 10, 10];
    uint256 constant public BURN_PERCENT = 3000;
    uint256 constant public DEFAULT_USER_PERCENT = 50;
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public STATE_CHANGE_PERCENT = 300;
    uint256 constant public MORE_THAN_LAST_PERCENT = 1100;
    uint256 constant public MAX_MORE_THAN_LAST_PERCENT = 3000;
    uint256 constant public TIME_LIMIT_REDUCE_PERCENT= 950;
    uint256 constant public CONTRACT_BONUS_DIVIDER = 1000;
    uint256 constant public TRX_TO_HOE_RATE= 100;
    uint256 constant public MAX_CONTRACT_BONUS_ADDITION = 10;
    uint256 constant public RANK_PERCENT = 100;
    uint256 public totalInvestedAmount = 0;
    uint256 public totalInvestedTimes = 0;
    uint256 public totalWithdrawnAmount = 0;
    uint256 public totalUserAmount = 0;
    uint256 public totalInvestEffectFactor = 0;
    uint256 public currentStage = 0;
    address payable internal defaultUserAddr;
    struct User{
        uint256 investAmount;
        uint256 startDate;
        uint256 referralReward;
        uint256 directReferralsAmount;
        address referrer;
        uint256 withdrawnInvestAmount;
        uint256 withdrawnReferralAmount;
        uint256 realInvestEffectFactor;
    }
    mapping (address => User) public users;
    struct Participant {
        address payable addr;
        uint256 amount;
    }
    uint256 public entryFee = INVEST_MIN_AMOUNT;
    uint256 public timeLimit = INIT_TIME_LIMIT;
    uint256 public rankStartTime;
    uint256 public pointer = 0;
    Participant[RANK_LIST_LENGTH] public rankList;
    bool rankListRewardDispatched = false;
    uint256 public stageRewardPoolCapacity = 0;
    constructor(address payable defaultUserAddress,uint8 num) public {
        number = num;
        defaultUserAddr = defaultUserAddress;
        User storage user = users[defaultUserAddr];
        user.startDate = block.timestamp;
        user.investAmount = 1;
        user.referrer = defaultUserAddr;
        emit ChangeStage(0);
    }
    function totalRewardAvailable() public view returns (uint256){
        return totalInvestedAmount.sub(totalWithdrawnAmount);
    }
    function invest(address referrer) public payable {
        require(currentStage == 0,"stage error 0");
        require(msg.value >= INVEST_MIN_AMOUNT, "less than minium amount");
        uint256 remainingInvest = msg.value;
        User storage user = users[msg.sender];
        if(address(0) == user.referrer) {
            if(referrer != msg.sender && users[referrer].investAmount > 0){
                user.referrer = referrer;
                users[referrer].directReferralsAmount = users[referrer].directReferralsAmount.add(1);
            } else {
                user.referrer = defaultUserAddr;
                users[defaultUserAddr].directReferralsAmount = users[defaultUserAddr].directReferralsAmount.add(1);
            }
            totalUserAmount = totalUserAmount.add(1);
            emit Newbie(msg.sender);
        }
        uint256 i = 0;
        address referrerAddress = user.referrer;
        while(address(0) != referrerAddress && i < REFERRAL_PERCENTS.length) {
            User storage referrerUser = users[referrerAddress];
            uint256 referrerAmount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
            referrerUser.referralReward = referrerUser.referralReward.add(referrerAmount);
            remainingInvest = remainingInvest.sub(referrerAmount);
            emit ReferrerReward(referrerAddress,msg.sender,i,referrerAmount);
            referrerAddress = referrerUser.referrer;
            i = i.add(1);
        }
        User storage defaultUser = users[defaultUserAddr];
        uint256 defaultUserInvestAmount = msg.value.mul(DEFAULT_USER_PERCENT).div(BURN_PERCENT);
        defaultUser.investAmount = defaultUser.investAmount.add(defaultUserInvestAmount);
        defaultUser.realInvestEffectFactor = defaultUser.realInvestEffectFactor.add(defaultUserInvestAmount);
        totalInvestEffectFactor = totalInvestEffectFactor.add(defaultUserInvestAmount);
        remainingInvest = remainingInvest.sub(defaultUserInvestAmount);
        if(msg.sender != defaultUserAddr){
            user.startDate = block.timestamp;
        }
        user.investAmount = user.investAmount.add(msg.value);
        user.realInvestEffectFactor = user.realInvestEffectFactor.add(remainingInvest);
        totalInvestEffectFactor = totalInvestEffectFactor.add(remainingInvest);
        totalInvestedAmount = totalInvestedAmount.add(msg.value);
        totalInvestedTimes = totalInvestedTimes.add(1);
        emit NewInvest(msg.sender,msg.value);
    }
    function calcUserInvestReward(address userAddr) public view returns (uint256) {
        User storage user = users[userAddr];
        uint256 tmpContractBonus = totalInvestedAmount.div(CONTRACT_BONUS_DIVIDER.mul(TRX_TO_HOE_RATE).mul(1 trx)).mul(1 trx).mul(TRX_TO_HOE_RATE);
        uint256 maxAdd = MAX_CONTRACT_BONUS_ADDITION.mul(1 trx).mul(TRX_TO_HOE_RATE);
        uint256 contractBonusAddition = tmpContractBonus > maxAdd ? maxAdd : tmpContractBonus;
        uint256 baseAmount = user.investAmount.add(contractBonusAddition);
        uint256 currentDate = block.timestamp;
        require(user.startDate != 0 && user.startDate < currentDate, "not start");
        uint256 duration = currentDate.sub(user.startDate);
        uint256 durationAddition = duration.div(TIME_STEP);
        return baseAmount.mul(duration).mul(BASE_PERCENT.add(durationAddition)).div(TIME_STEP).div(PERCENTS_DIVIDER);
    }
    function calcUserReferralReward(address userAddr) public view returns (uint256) {
        User storage user = users[userAddr];
        return user.referralReward.sub(user.withdrawnReferralAmount);
    }
    function calcUserBurnRemaining(address userAddr) public view returns (uint256) {
        User storage user = users[userAddr];
        uint256 max = user.investAmount.mul(BURN_PERCENT).div(PERCENTS_DIVIDER);
        uint256 totalWithdrawn = user.withdrawnInvestAmount.add(user.withdrawnReferralAmount);
        return max.sub(totalWithdrawn);
    }
    function getUserInfo(address userAddr) public view returns (uint256,uint256,uint256,uint256,uint256,address){
        User storage user = users[userAddr];
        return (user.investAmount,user.startDate,user.referralReward,user.withdrawnInvestAmount ,user.withdrawnReferralAmount,user.referrer);
    }
    function calcAndSetWithdrawProcess(address userAddr) private returns(uint256) {
        require(currentStage == 0, "statge error 0");
        User storage user = users[userAddr];
        uint256 investReward = calcUserInvestReward(userAddr);
        uint256 referralReward = calcUserReferralReward(userAddr);
        uint256 burnRemaining = calcUserBurnRemaining(userAddr);
        uint256 rewardSum = investReward.add(referralReward);
        if(investReward > burnRemaining){
            user.withdrawnInvestAmount = user.withdrawnInvestAmount.add(burnRemaining);
            totalWithdrawnAmount = totalWithdrawnAmount.add(burnRemaining);
        } else if(rewardSum > burnRemaining) {
            user.withdrawnInvestAmount = user.withdrawnInvestAmount.add(investReward);
            user.withdrawnReferralAmount = user.withdrawnReferralAmount.add(burnRemaining).sub(investReward);
            totalWithdrawnAmount = totalWithdrawnAmount.add(burnRemaining);
        } else {
            user.withdrawnInvestAmount = user.withdrawnInvestAmount.add(investReward);
            user.withdrawnReferralAmount = user.withdrawnReferralAmount.add(referralReward);
            totalWithdrawnAmount = totalWithdrawnAmount.add(rewardSum);
        }
        uint256 result = rewardSum < burnRemaining ? rewardSum : burnRemaining;
        uint256 subFactor = result < user.realInvestEffectFactor ? result : user.realInvestEffectFactor;
        user.realInvestEffectFactor = user.realInvestEffectFactor.sub(subFactor);
        totalInvestEffectFactor = totalInvestEffectFactor > subFactor ? totalInvestEffectFactor.sub(subFactor) : 0;
        if(userAddr != defaultUserAddr){
            user.startDate = block.timestamp;
        }
        return result;
    }
    function withdraw() public {
        require(currentStage == 0, "stage error 0");
        uint256 withdrawAmount = calcAndSetWithdrawProcess(msg.sender);
        uint256 remaining = totalInvestedAmount.sub(totalWithdrawnAmount);
        uint256 payAmount = remaining < withdrawAmount ? remaining : withdrawAmount;
        msg.sender.transfer(payAmount);
        emit Withdrawn(msg.sender,payAmount);
        if( remaining.mul(PERCENTS_DIVIDER) < totalInvestedAmount.mul(STATE_CHANGE_PERCENT) ){
            initStage1();
            emit ChangeStage(1);
        }
    }
    function initStage1() private {
        currentStage = 1;
        for(uint256 i = 0;i < rankList.length;i = i.add(1)){
            Participant storage item = rankList[i];
            item.addr = defaultUserAddr;
            item.amount = 0;
        }
        rankStartTime = block.timestamp;
    }
    function investStage1() public payable{
        require(currentStage == 1, "stage error 1");
        require(block.timestamp < rankStartTime.add(timeLimit), "time over");
        uint256 minFee = entryFee.mul(MORE_THAN_LAST_PERCENT).div(PERCENTS_DIVIDER);
        uint256 maxFee = entryFee.mul(MAX_MORE_THAN_LAST_PERCENT).div(PERCENTS_DIVIDER);
        require(msg.value >= minFee && msg.value <= maxFee, "amount out of range");
        entryFee = msg.value;
        rankList[pointer].addr = msg.sender;
        rankList[pointer].amount = msg.value;
        timeLimit = timeLimit.mul(TIME_LIMIT_REDUCE_PERCENT).div(PERCENTS_DIVIDER);
        rankStartTime = block.timestamp;
        pointer = pointer == rankList.length - 1 ? 0 : pointer.add(1);
        User storage user = users[msg.sender];
        user.realInvestEffectFactor = user.realInvestEffectFactor.add(msg.value);
        user.investAmount = user.investAmount.add(msg.value);
        totalInvestedAmount = totalInvestedAmount.add(msg.value);
        totalInvestEffectFactor = totalInvestEffectFactor.add(msg.value);
    }
    function dispatchRankListReward() public {
        require(currentStage == 1, "stage error 1");
        require(block.timestamp > rankStartTime.add(timeLimit), "not dispatch time");
        require(rankListRewardDispatched == false, "dispatched");
        rankListRewardDispatched = true;
        stageRewardPoolCapacity = totalInvestedAmount.sub(totalWithdrawnAmount);
        uint256 totalDispatch = stageRewardPoolCapacity.mul(RANK_PERCENT).div(PERCENTS_DIVIDER);
        uint256 piece = totalDispatch.div(rankList.length);
        for(uint256 i = 0; i < rankList.length; i = i.add(1)){
            address payable userAddr = rankList[i].addr;
            User storage user = users[userAddr];
            user.withdrawnInvestAmount = user.withdrawnInvestAmount.add(piece);
            userAddr.transfer(piece);
        }
        initStage2();
    }
    function initStage2() private {
        currentStage = 2;
        emit ChangeStage(2);
    }
    function calcUserRemainingReward(address userAddr) public view returns (uint256){
        User storage user = users[userAddr];
        uint256 base = stageRewardPoolCapacity.mul(PERCENTS_DIVIDER.sub(RANK_PERCENT)).div(PERCENTS_DIVIDER);
        return user.realInvestEffectFactor.mul(base).div(totalInvestEffectFactor);
    }
    function withdrawStage2() public {
        require(currentStage == 2, "stage error 2");
        User storage user = users[msg.sender];
        require(user.realInvestEffectFactor > 0, "out in stage 0");
        uint256 canWithdrawAmount = calcUserRemainingReward(msg.sender);
        user.realInvestEffectFactor = 0;
        uint256 remaining = totalInvestedAmount.sub(totalWithdrawnAmount);
        uint256 payAmount = remaining < canWithdrawAmount ? remaining : canWithdrawAmount;
        user.withdrawnInvestAmount = user.withdrawnInvestAmount.add(payAmount);
        msg.sender.transfer(payAmount);
        emit Withdrawn(msg.sender,payAmount);
    }
    function pause(uint256 p1) public {
        require(msg.sender == defaultUserAddr, "owner");
        currentStage = p1;
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