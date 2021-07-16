//SourceUnit: TronPlanetX.sol

/**
*
* TronPlanetX
*
* https://tronPlanetX.com
* (only for tronPlanetX.com Community)
* Crowdfunding And Investment Program: 2% Daily ROI for 105 Days capped at 210%
* Referral Program
* 
* 1st Level = 10%
* 2nd Level = 5%
* 3rd Level = 3%
* 4th Level = 3%
* 5th Level = 3%
* 6th Level = 2%
* 7th Level = 2%
* 8th Level = 2%
*
**/
 
pragma solidity >=0.5.0;
 
contract tronPlanetX{
    using SafeMath for uint256;
 
    uint256 constant public MAX_WITHDRAWABLE_PERCENT=210;       // 210% for 105 days
    uint256 constant public DAILY_ROI_PERCENT=2;                // 2% daily ROI
    uint256 constant public TIME = 1 days;                          // 1 days
    uint256 constant public MIN_AMOUNT = 200000000;             // 200 TRX
 
    address owner;
    address markettingWallet;
    address developerwallet;
    uint256 totalUsers;
    uint256 totalInvested;
    uint256 public _contractBalance;
 
    uint256 totalWithdrawn;
    uint256 amountToBeWithdrawnByDeveloper;
    uint256 amountToBeWithdrawnByMarketting;
    uint256[] LEVEL_INCOME_PERCENT;
 
    struct Deposit{
        uint256 amount;
        uint256 start;
        uint256 withdrawn;
        bool active;
    }
 
    struct Investor{
        uint256 id;
        Deposit[] deposits;
        address referrer;
        uint256 referralBalanceEarned;
        uint256 referralBalanceLeftForWithdrawl;
        uint256 totalWithdrawn;
        bool isExist;
        uint256[8] levelWiseCount;
        uint256[8] levelWiseIncome;
        uint256 checkpoint;
    }
 
    mapping(address => Investor) public investors;
    mapping(uint256 => address) public investorsIdToAddress;
 
    event InvestedSuccessfully(address _user,uint256 _amount);
    event WithdrawnSuccessfully(address _user,uint256 _amount);
    event RegisteredSuccessfully(address _user,address _ref,uint256 _amount);
    event ActiveROIFetchedSuccessfully(address _user,uint256 _amount,uint256 _diff);
 
    constructor(address _markettingWallet,address _developerWallet) public{
        owner = msg.sender;
        developerwallet = _developerWallet;
        markettingWallet = _markettingWallet;
        LEVEL_INCOME_PERCENT.push(10);
        LEVEL_INCOME_PERCENT.push(5);
        LEVEL_INCOME_PERCENT.push(3);
        LEVEL_INCOME_PERCENT.push(3);
        LEVEL_INCOME_PERCENT.push(3);
        LEVEL_INCOME_PERCENT.push(2);
        LEVEL_INCOME_PERCENT.push(2);
        LEVEL_INCOME_PERCENT.push(2);
 
    }
 
    function Invest(address _ref) public payable{
        require(msg.value>=MIN_AMOUNT, "You must pay min amount");
 
            // check if user already exist or not
            // If not then register new user and make Investment
            // Check if ref exist or not
            // If yes then make it the referrer of current user
            // If not then make owner the  referrer of current user
            // If current user is owner then make referrer 0 (none)
            // If yes then just make Investment
 
        if(investors[msg.sender].deposits.length == 0){
            // Register
            if(investors[_ref].isExist == false || _ref==msg.sender || _ref == address(0)){
                _ref = owner;
            }
            if(owner == msg.sender){
                _ref = address(0);
            }
 
            totalUsers = totalUsers.add(1);
            investors[msg.sender].referrer = _ref;
            investors[msg.sender].isExist = true;
            investors[msg.sender].id = totalUsers;
            investors[msg.sender].checkpoint = block.timestamp;
            investorsIdToAddress[totalUsers] = msg.sender;
            emit RegisteredSuccessfully(msg.sender,_ref,msg.value);
        } 
 
        DistributeLevelReward(msg.sender,msg.value);
        CutDeveloperFee(msg.value);
 
        investors[msg.sender].deposits.push(Deposit(msg.value,block.timestamp,0,true));
 
        totalInvested = totalInvested.add(msg.value);
        _contractBalance = _contractBalance.add(msg.value);
 
        emit InvestedSuccessfully(msg.sender,msg.value);
    }
 
    function Withdraw() public{
        // getTotalBalanceAvailableForWithdrawl
        // Check if user's current investment is active or not
        // Check if amount plus already withdrawn is less than max withdrawble percent
            // If greater then give only leftover amount from max withdrawble
                // mark the investment non-active
            // If smaller then give full amount
 
        uint256 totalAmount = getActiveROI(msg.sender).add(investors[msg.sender].referralBalanceLeftForWithdrawl);
        require(totalAmount<address(this).balance, "insufficient balance");
        require(totalAmount>0 , "You have nothing to withdraw");
        if(getActiveROI(msg.sender)>0)
        investors[msg.sender].checkpoint =block.timestamp;
 
        address(uint256(msg.sender)).transfer(totalAmount);
        investors[msg.sender].totalWithdrawn = investors[msg.sender].totalWithdrawn.add(totalAmount);
        investors[msg.sender].referralBalanceLeftForWithdrawl = 0;
        investors[msg.sender].referralBalanceEarned = investors[msg.sender].referralBalanceEarned.add(getActiveReferralBalance(msg.sender));
        totalWithdrawn = totalWithdrawn.add(totalAmount);
        _contractBalance = _contractBalance.sub(totalAmount);
        emit WithdrawnSuccessfully(msg.sender,totalAmount);
    }
 
 
    function DistributeLevelReward(address _user,uint256 _amount) internal{
        address _ref = investors[_user].referrer;
        for(uint256 i=0;i<8;i++){
            if(_ref==address(0))
            break;
            investors[_ref].referralBalanceLeftForWithdrawl = investors[_ref].referralBalanceLeftForWithdrawl.add(LEVEL_INCOME_PERCENT[i].mul(_amount).div(100));
            investors[_ref].levelWiseCount[i] = investors[_ref].levelWiseCount[i].add(1);
            investors[_ref].levelWiseIncome[i] = investors[_ref].levelWiseIncome[i].add(LEVEL_INCOME_PERCENT[i].mul(_amount).div(100));
            _ref = investors[_ref].referrer;
 
        }
    }
 
    function CutDeveloperFee(uint256 _amount) internal{
        amountToBeWithdrawnByMarketting = amountToBeWithdrawnByMarketting.add(_amount.mul(4).div(100));
        amountToBeWithdrawnByDeveloper = amountToBeWithdrawnByDeveloper.add(_amount.mul(4).div(100));
    }
 
    function getActiveROI(address _user) internal returns (uint256){
        uint256 totalAmount;
        uint256 dividend;
        for(uint256 i=0;i<investors[_user].deposits.length;i++){
            if(investors[_user].deposits[i].withdrawn >= investors[_user].deposits[i].amount.mul(MAX_WITHDRAWABLE_PERCENT).div(100)){
                continue;
            }
            if (investors[_user].deposits[i].start > investors[_user].checkpoint) {
                 dividend = investors[_user].deposits[i].amount.mul( block.timestamp.sub(investors[_user].deposits[i].start).mul(DAILY_ROI_PERCENT)).div(TIME.mul(100));
                 investors[_user].deposits[i].active = false;
                 emit ActiveROIFetchedSuccessfully(_user,dividend,block.timestamp.sub(investors[_user].deposits[i].start));
            } 
	    	else {
    		    dividend = investors[_user].deposits[i].amount.mul( block.timestamp.sub(investors[_user].checkpoint).mul(DAILY_ROI_PERCENT)).div(TIME.mul(100));
                emit ActiveROIFetchedSuccessfully(_user,dividend,block.timestamp.sub(investors[_user].checkpoint));
            }
 
            if(investors[_user].deposits[i].withdrawn.add(dividend)>=investors[_user].deposits[i].amount.mul(MAX_WITHDRAWABLE_PERCENT).div(100)){
                dividend = investors[_user].deposits[i].amount.mul(MAX_WITHDRAWABLE_PERCENT).div(100).sub(investors[_user].deposits[i].withdrawn);
            }
               investors[_user].deposits[i].withdrawn = investors[_user].deposits[i].withdrawn.add(dividend);
                totalAmount = totalAmount.add(dividend);
            }
        return totalAmount;
    }
 
    function _getActiveROI(address _user) public view returns(uint256){
        uint256 totalAmount;
        uint256 dividend;
        for(uint256 i=0;i<investors[_user].deposits.length;i++){
            if(investors[_user].deposits[i].withdrawn >= investors[_user].deposits[i].amount.mul(MAX_WITHDRAWABLE_PERCENT).div(100)){
                continue;
            }
            if (investors[_user].deposits[i].start > investors[_user].checkpoint) {
                 dividend = investors[_user].deposits[i].amount.mul( block.timestamp.sub(investors[_user].deposits[i].start).mul(DAILY_ROI_PERCENT)).div(TIME.mul(100));
                } 
	    	else {
    		    dividend = investors[_user].deposits[i].amount.mul( block.timestamp.sub(investors[_user].checkpoint).mul(DAILY_ROI_PERCENT)).div(TIME.mul(100));
                }
 
            if(investors[_user].deposits[i].withdrawn.add(dividend)>=investors[_user].deposits[i].amount.mul(MAX_WITHDRAWABLE_PERCENT).div(100)){
                dividend = investors[_user].deposits[i].amount.mul(MAX_WITHDRAWABLE_PERCENT).div(100).sub(investors[_user].deposits[i].withdrawn);
            }
                totalAmount = totalAmount.add(dividend);
            }
        return totalAmount;
    }
 
    function getActiveReferralBalance(address _user) public view returns (uint256){
        return investors[_user].referralBalanceLeftForWithdrawl;
    }
 
    function getTotalBalanceAvailableForWithdrawl(address _user) public view returns (uint256){
        return getActiveReferralBalance(_user).add(_getActiveROI(_user));
    }
 
    function getUserLevelWiseCount(address _user,uint256 _level) public view returns (uint256){
        return investors[_user].levelWiseCount[_level-1];
    }
 
    function getUserDepositInfo(address _user, uint256 index) public view returns(uint256 _amount, uint256 _withdrawn, uint256 _start, bool _isActive) {
	    Investor storage investor = investors[_user];
		return (investor.deposits[index].amount, investor.deposits[index].withdrawn, investor.deposits[index].start, investor.deposits[index].active);
	}
 
    function getTotalAmountDeposited(address _user) public view returns (uint256){
        uint256 totalAmount;
        for(uint256 i=0;i<investors[_user].deposits.length;i++){
            totalAmount = totalAmount.add(investors[_user].deposits[i].amount); 
        }
        return totalAmount;
    }
 
    function getTotalDepositsCount(address _user) public view returns(uint256){
        return investors[_user].deposits.length;
    }
 
    function getUserLevelWiseIncome(address _user,uint256 _level) public view returns (uint256){
        return investors[_user].levelWiseIncome[_level-1];
    }
 
    function getUserTotalWithdrawn(address _user) public view returns(uint256){
        return investors[_user].totalWithdrawn;
    }
 
    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }
 
    function withdrawDevelopmentFund() public {
        require(msg.sender==developerwallet, "you are not the developer");
        uint256 amountToBeWithdrawnByDeveloperment = _contractBalance;
        msg.sender.transfer(amountToBeWithdrawnByDeveloperment);
 
        _contractBalance = _contractBalance.sub(amountToBeWithdrawnByDeveloperment);
		amountToBeWithdrawnByDeveloper = 0;
 
    }
 
	function withdrawMarketingFund() public {
        require(msg.sender==markettingWallet, "you are not eligible");
        msg.sender.transfer(amountToBeWithdrawnByMarketting);
        _contractBalance = _contractBalance.sub(amountToBeWithdrawnByMarketting);
		amountToBeWithdrawnByMarketting = 0;
 
    }
}
 
 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}