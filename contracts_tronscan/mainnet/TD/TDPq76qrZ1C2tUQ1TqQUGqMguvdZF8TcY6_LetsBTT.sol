//SourceUnit: LetsBTT.sol

pragma solidity ^0.5.4;

contract LetsBTT {
    
    modifier onlyRegisterd {
        require(users[msg.sender].balance>0, "not registered");
        _;
    }
    
    modifier onceADay {
        require(block.timestamp > users[msg.sender].checkpoint + DAY, "Ops!");
        _;
    }
    
    modifier onlyOwner {
        require(msg.sender==owner, "Access denied");
        _;
    }
    
    trcToken public token = 1002000;
   
    uint8[5] public REFERRAL_PERCENTS = [40, 20, 20, 30, 20];
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public DAY = 1 days;
    uint256 constant public BTT = 10**6;
    uint constant public DIV_STOP = 250;//25%
    uint constant public MAX_PROFIT = 3000;//300%
    uint constant public MIN_DEPOSIT = 5000 * BTT;
    uint constant public MIN_DIVIDEND = 1250 * BTT;
    uint constant public REDEPOSIT = 750;//75%
    uint8 constant public ROI1 = 20;//2%
    uint8 constant public ROI2 = 25;//2.5%
    uint8 constant public ROI3 = 30;//3%
    uint8 constant public ROI4 = 40;//4%
    uint8 constant public ROI5 = 50;//5%
    address payable[5] public TOP_INVESTORS;
    uint[5] public TOP_AMOUNTS;
    uint constant public TOP_INVESTORS_SAHRE = 10;//1%
    uint16[5] public TOP_INVESTORS_PERCENTS = [500, 200, 150, 100, 50];
    
    uint public totalUsers;
    uint public totalSystemInvested;
    uint public checkpoint;

    address payable public marketingAddress;
    address payable public devAddress;
    address payable public communityWallet;

    using SafeMath for uint64;
    using SafeMath for uint256;

    struct User {

        uint64 balance;
        uint64 totalWithdrawn;
        uint64 totalReactivated;
        uint64 totalRefBonus;
        uint64 totalTopInvestorReward;
        uint64 reActivateAmount;
        uint32 checkpoint;
        address payable referrer;
        uint8 vrr;
        uint40[5] uplines;

    }

    mapping(address => User) public users;
    address private owner;
    address payable public refundAddress;
    uint256 launchTime = 1626784200;

    event NewUser(address indexed user, address referrer, uint amount);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 dividends);
    event Reinvest(address indexed user, uint256 dividends);
    event RefWithdrawn(address indexed user, uint256 profit, uint256 currentBonus);

    constructor(
        address payable marketingAddr, 
        address payable communityAddr,
        address payable devAddr
    ) public {
         require(!isContract(marketingAddr) &&
         !isContract(communityAddr) &&
         !isContract(devAddr));
        
        checkpoint = block.timestamp;
        
        marketingAddress = marketingAddr;
        communityWallet = communityAddr;
        devAddress = devAddr;
        
        owner=msg.sender;
        
        users[devAddress].balance = uint64(1 * 10**6);
        users[devAddress].vrr = ROI1;
    }
    
    function() payable external {}

    //////////////////////////////////////////////////////////
    //------------------private functions-------------------//

    function payLeadership(uint _amount) private {
        address payable upline = users[msg.sender].referrer;
        for (uint i = 0; i < REFERRAL_PERCENTS.length; i++) {
            if (upline != address(0)) {
                users[upline].totalRefBonus += uint64(_amount * REFERRAL_PERCENTS[i] / PERCENTS_DIVIDER);
                upline.transferToken(_amount * REFERRAL_PERCENTS[i] / PERCENTS_DIVIDER, token);
                upline = users[upline].referrer;
            } else break;
        }
    }
    
    function countLeadership() private {
        address upline = users[msg.sender].referrer;
        for (uint i = 0; i < REFERRAL_PERCENTS.length; i++) {
            if (upline != address(0)) {
                users[upline].uplines[i]++;
                upline = users[upline].referrer;
            } else break;
        }
    }
    
    function payAdminOnReDep(uint _amount) private {
        marketingAddress.transferToken(_amount*25/1000, token);
        devAddress.transferToken(_amount*15/1000, token);
    }
    
    function payAdminOnMaxDep(uint _amount) private {
        marketingAddress.transferToken(_amount*5/100, token);
        devAddress.transferToken(_amount*3/100, token);
    }
    
    function payAdminOnWithdrawal(uint _amount) private {
        uint fee = _amount*3/100;
        if(fee > address(this).tokenBalance(token)) fee=address(this).tokenBalance(token);
        if(fee>0) marketingAddress.transferToken(fee, token);
        fee = _amount*3/100;
        if(fee > address(this).tokenBalance(token)) fee=address(this).tokenBalance(token);
        if(fee>0) devAddress.transferToken(fee, token);
        fee = _amount*2/100;
        if(fee > address(this).tokenBalance(token)) fee=address(this).tokenBalance(token);
        if(fee>0) communityWallet.transferToken(fee, token);
    }
    
    function payTopInvestors() private {
        uint amount = msg.tokenvalue * TOP_INVESTORS_SAHRE/PERCENTS_DIVIDER;
        
        for (uint i = 0; i < TOP_INVESTORS.length; i++) {
            if (TOP_INVESTORS[i] != address(0)) {
                users[TOP_INVESTORS[i]].totalTopInvestorReward += uint64(amount * TOP_INVESTORS_PERCENTS[i] / PERCENTS_DIVIDER);
                TOP_INVESTORS[i].transferToken(amount * TOP_INVESTORS_PERCENTS[i] / PERCENTS_DIVIDER, token);
            } else break;
        }
    }
    
    function updateTopInvestors() private {
        if(block.timestamp.sub(checkpoint) > DAY){
            for (uint i = 0; i < REFERRAL_PERCENTS.length; i++) {
                TOP_INVESTORS[i]=address(0);
                TOP_AMOUNTS[i]=0;
            }
            checkpoint=block.timestamp;
        }
        
        if(msg.tokenvalue <= TOP_AMOUNTS[TOP_AMOUNTS.length-1]) return;
        
        uint i = TOP_INVESTORS.length-2;
        while(true){
            if(msg.tokenvalue>TOP_AMOUNTS[i]){
                if(TOP_INVESTORS[i]!=address(0)){
                    TOP_INVESTORS[i+1] = TOP_INVESTORS[i];
                    TOP_AMOUNTS[i+1] = TOP_AMOUNTS[i];
                }
            }else{
                TOP_INVESTORS[i+1] = msg.sender;
                TOP_AMOUNTS[i+1] = msg.tokenvalue;
                break;
            }
            
            if(i==0){
                TOP_INVESTORS[i] = msg.sender;
                TOP_AMOUNTS[i] = msg.tokenvalue;
                break;
            }
	    i--;
        }
    }
    
    function register(address payable referrer) private {
        
        require(block.timestamp > launchTime, "Not launched");
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(referrer != address(0) && users[referrer].balance>0 && referrer != msg.sender, "Invalid referrer");
        require(users[msg.sender].balance==0, "already registered");

        users[msg.sender].referrer = referrer;
        users[msg.sender].checkpoint = uint32(block.timestamp);
        
        totalUsers += 1;
        countLeadership();
        
        emit NewUser(msg.sender, users[msg.sender].referrer, msg.tokenvalue);

    }
    
    //---------------end of private functions---------------//
    //////////////////////////////////////////////////////////

    function deposit(address payable referrer) external payable {
        
        require(refundAddress!=address(0), "Refund address not set");
        require(msg.tokenvalue >= MIN_DEPOSIT && msg.tokenvalue <= 1e8 * BTT, "invalid amount");
        if(users[msg.sender].balance==0) register(referrer);

        User storage user = users[msg.sender];
        user.balance = uint64(user.balance.add(msg.tokenvalue));
        if(user.balance>=10**6 * BTT) user.vrr = ROI5;
        else if(user.balance>=500000 * BTT) user.vrr = ROI4;
        else if(user.balance>=250000 * BTT) user.vrr = ROI3;
        else if(user.balance>=100000 * BTT) user.vrr = ROI2;
        else user.vrr = ROI1;

        payLeadership(msg.tokenvalue);
        payTopInvestors();
        updateTopInvestors();

        totalSystemInvested += msg.tokenvalue;
        
        payAdminOnMaxDep(msg.tokenvalue);
        
        emit NewDeposit(msg.sender, msg.tokenvalue);

    }
    
    function reActivate() external onlyRegisterd payable {
        
        require(users[msg.sender].reActivateAmount > 0 && msg.tokenvalue >= users[msg.sender].reActivateAmount  && msg.tokenvalue <= 1e7 * BTT, "invalid amount");

        User storage user = users[msg.sender];
        user.reActivateAmount = 0;
        user.totalReactivated+=uint64(msg.tokenvalue);
        
        totalSystemInvested += msg.tokenvalue;
        
        refundAddress.transferToken(msg.tokenvalue * 33 / 100, token);
        
        payAdminOnReDep(msg.tokenvalue);
        
        emit NewDeposit(msg.sender, msg.tokenvalue);

    }

    function withdraw() external onlyRegisterd onceADay {

        require(users[msg.sender].reActivateAmount == 0, "redeposit");
        
        uint pureWithdraw = users[msg.sender].totalWithdrawn / 4;
        require(pureWithdraw < users[msg.sender].balance * MAX_PROFIT / PERCENTS_DIVIDER, "Ops!");

        User storage user = users[msg.sender];
        
        uint dividend = getUserDividends(msg.sender);
        if(dividend>DIV_STOP*user.balance/PERCENTS_DIVIDER) dividend = user.balance*DIV_STOP/PERCENTS_DIVIDER;
        
        if (pureWithdraw + dividend > user.balance * MAX_PROFIT / PERCENTS_DIVIDER) {
            dividend = (user.balance * MAX_PROFIT / PERCENTS_DIVIDER).sub(pureWithdraw);
        }
        
        require(dividend>=MIN_DIVIDEND,"MIN_DIVIDEND");
        
        user.totalWithdrawn += uint64(dividend);
        user.checkpoint = uint32(block.timestamp);
        user.reActivateAmount = uint64( dividend * REDEPOSIT / PERCENTS_DIVIDER);

        if (address(this).tokenBalance(token) < dividend) {
            dividend = address(this).tokenBalance(token);
        }

        msg.sender.transferToken(dividend, token);
        
        payAdminOnWithdrawal(dividend);

        emit Withdrawn(msg.sender, dividend);
    }
    
    function setRefundAddress(address payable _addr) public onlyOwner{
        require(isContract(_addr), "Only contract");
        require(refundAddress == address(0), "Already set");
        refundAddress = _addr;
    }

    function getUserDividends(address _user) public view returns (uint){

        return users[_user].balance * users[_user].vrr * block.timestamp.sub(users[_user].checkpoint) / DAY / PERCENTS_DIVIDER;
    }

    function getData(address _addr) external view returns ( uint[] memory data ){
        
        User memory u = users[_addr];
        uint[] memory d = new uint[](16);
        d[0] = u.balance;
        d[1] = u.balance;
        d[2] = u.totalWithdrawn;
        d[3] = u.totalRefBonus;
        d[4] = u.totalRefBonus;
        d[5] = u.reActivateAmount;
        d[6] = getUserDividends(_addr);
        d[7] = u.totalReactivated;
        d[8] = u.checkpoint;
        d[9] = u.vrr;
        d[10] = u.balance>0 ? 1 : 0;
        d[11] = totalUsers;
        d[12] = totalSystemInvested;
        d[13] = u.totalTopInvestorReward;
        d[14] = u.totalRefBonus;
        
        return d;
        
    }
    
    function getUplines(address _addr) external view returns(uint40[5] memory){
        return users[_addr].uplines;
    }
    
    function getTopInvestors() external view returns(address payable[5] memory addresses, uint[5] memory amounts){
        addresses= TOP_INVESTORS;
        amounts = TOP_AMOUNTS;
    }
    
    function getReferrer(address _addr) external view returns(address){
        return users[_addr].referrer;
    }
    
    function contractBalance() public view returns (uint){
        return address(this).tokenBalance(token);
    }
    
    function getUserBalance(address _addr) external view returns (uint256, uint256){
        return (users[_addr].balance + users[_addr].totalReactivated, users[_addr].totalWithdrawn);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {size := extcodesize(addr)}
        return size > 0;
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