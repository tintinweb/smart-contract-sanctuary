//SourceUnit: LionKing.sol

pragma solidity ^0.5.4;

contract LionKing {
    
    modifier onlyRegisterd {
        require(users[msg.sender].deposits.length>0, "not registered");
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
    
    ITRC20 public token;
    address public tokenBank;
   
    uint8[4] public REFERRAL_PERCENTS = [80, 40, 20, 10];
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public DAY = 1 days;
    uint constant public DIV_STOP = 250;//25%
    uint constant public MAX_PROFIT = 2500;//250%
    uint constant public MIN_DIVIDEND = 50 trx;
    uint constant public MIN_TRADE = 1000 trx;
    uint constant public REDEPOSIT = 700;//70%
    address payable[5] public TOP_INVESTORS;
    uint[5] public TOP_AMOUNTS;
    uint constant public TOP_INVESTORS_SAHRE = 10;//1%
    uint16[5] public TOP_INVESTORS_PERCENTS = [500, 200, 150, 100, 50];
    
    uint public totalUsers;
    uint public totalSystemInvested;
    uint public totalSystemLionTrade;
    uint public dailyCheckpoint;
    uint public checkBalance;

    address payable public LION_TRADE;
    
    address payable public marketingAddress;
    address payable public devAddress;
    address payable public communityWallet;
    address payable public adminWallet;
    address payable public refundAddress;
    uint256 launchTime = 1627907400;

    using SafeMath for uint64;
    using SafeMath for uint256;
    
    struct Deposit{
        uint64 amount;
        uint64 withdrawn;
    }

    struct User {

        uint64 totalRefBonus;
        uint64 totalLionTrade;
        uint64 totalTopInvestorReward;
        uint64 reActivateAmount;
        uint64 totalReActivateAmount;
        uint32 checkpoint;
        address payable referrer;
        uint40[4] uplines;
        Deposit[] deposits;

    }

    mapping(address => User) public users;
    uint[] public balances;
    uint[] public intervals;
    address private owner;

    event NewUser(address indexed user, address referrer, uint amount);
    event NewDeposit(address indexed user, uint256 amount);
    event NewLionTradeDeposit(address indexed user, uint256 amount, uint256 total);
    event Withdrawn(address indexed user, uint256 dividends);
    event Reinvest(address indexed user, uint256 dividends);
    event RefWithdrawn(address indexed user, uint256 profit, uint256 currentBonus);

    constructor(address payable marketingAddr, address payable communityAddr
            ,  address payable adminAddr, address payable devAddr, address payable _trade,
            ITRC20 _token, address _tokenBank) public {
        require(!isContract(marketingAddr) &&
        !isContract(communityAddr) &&
        !isContract(devAddr) &&
        !isContract(adminAddr));
        
        LION_TRADE = _trade;
        
        owner=msg.sender;
        token=_token;
        tokenBank = _tokenBank;
        dailyCheckpoint = block.timestamp;
        
        marketingAddress = marketingAddr;
        communityWallet = communityAddr;
        devAddress = devAddr;
        adminWallet=adminAddr;
        users[devAddress].deposits.push(Deposit(1 trx, 0));
    }

    //////////////////////////////////////////////////////////
    //------------------private functions-------------------//

    function computeUserDividends(address _user) private returns (uint){
        if(block.timestamp < launchTime+5 days) return 0;
        uint dividend=0;
        uint totalDividend=0;
        User storage user=users[_user];
        (uint totalDeposit, ) = getTotalDeposit(_user);
        for(uint i=0; i<user.deposits.length;i++){
            Deposit storage dep = user.deposits[i];
            uint pureWithdrawn = dep.withdrawn*30/100;
            if(pureWithdrawn>=dep.amount*MAX_PROFIT/PERCENTS_DIVIDER) continue;
            
            dividend = getDepositDividend(dep.amount, user.checkpoint);
                
            if(dividend+pureWithdrawn>dep.amount*MAX_PROFIT/PERCENTS_DIVIDER)
                dividend=(dep.amount*MAX_PROFIT/PERCENTS_DIVIDER).sub(pureWithdrawn);
            
            if(totalDividend+dividend>=totalDeposit*DIV_STOP/PERCENTS_DIVIDER){
                dep.withdrawn += uint64((totalDeposit*DIV_STOP/PERCENTS_DIVIDER).sub(totalDividend));
                totalDividend = totalDeposit*DIV_STOP/PERCENTS_DIVIDER;
                return totalDividend;
            }else{
                user.deposits[i].withdrawn+=uint64(dividend);
                totalDividend+=dividend;
            }
        }
        return totalDividend;
    }
    
    function payLeadership(uint _amount) private {
        address payable upline = users[msg.sender].referrer;
        for (uint i = 0; i < REFERRAL_PERCENTS.length; i++) {
            if (upline != address(0)) {
                users[upline].totalRefBonus += uint64(_amount * REFERRAL_PERCENTS[i] / PERCENTS_DIVIDER);
                upline.transfer(_amount * REFERRAL_PERCENTS[i] / PERCENTS_DIVIDER);
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
        marketingAddress.transfer(_amount*2/100);
        devAddress.transfer(_amount*2/100);
        communityWallet.transfer(_amount*2/100);
        adminWallet.transfer(_amount*2/100);
    }
    
    function payAdminOnMaxDep(uint _amount) private {
        marketingAddress.transfer(_amount*4/100);
        devAddress.transfer(_amount*4/100);
        communityWallet.transfer(_amount*3/100);
    }
    
    function payAdminOnTradeDep(uint _amount) private {
        marketingAddress.transfer(_amount*4/100);
        devAddress.transfer(_amount*3/100);
        communityWallet.transfer(_amount*3/100);
        adminWallet.transfer(_amount*2/100);
    }
    
    function payAdminOnWithdrawal(uint _amount) private {
        uint fee = _amount*5/100;
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) marketingAddress.transfer(fee);
        fee = _amount*3/100;
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) devAddress.transfer(fee);
        fee = _amount*2/100;
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) communityWallet.transfer(fee);
    }
    
    function payTopInvestors() private {
        uint amount = msg.value*TOP_INVESTORS_SAHRE/PERCENTS_DIVIDER;
        
        for (uint i = 0; i < TOP_INVESTORS.length; i++) {
            if (TOP_INVESTORS[i] != address(0)) {
                users[TOP_INVESTORS[i]].totalTopInvestorReward += uint64(amount * TOP_INVESTORS_PERCENTS[i] / PERCENTS_DIVIDER);
                TOP_INVESTORS[i].transfer(amount * TOP_INVESTORS_PERCENTS[i] / PERCENTS_DIVIDER);
            } else break;
        }
    }
    
    function updateTopInvestors() private {
        
        if(msg.value <= TOP_AMOUNTS[TOP_AMOUNTS.length-1]) return;
        
        uint i = TOP_INVESTORS.length-2;
        while(true){
            if(msg.value>TOP_AMOUNTS[i]){
                if(TOP_INVESTORS[i]!=address(0)){
                    TOP_INVESTORS[i+1] = TOP_INVESTORS[i];
                    TOP_AMOUNTS[i+1] = TOP_AMOUNTS[i];
                }
            }else{
                TOP_INVESTORS[i+1] = msg.sender;
                TOP_AMOUNTS[i+1] = msg.value;
                break;
            }
            if(i==0){
                TOP_INVESTORS[i] = msg.sender;
                TOP_AMOUNTS[i] = msg.value;
                break;
            }
            i--;
        }
    }
    
    //---------------end of private functions---------------//
    //////////////////////////////////////////////////////////

    function register(address payable referrer) private {
        
        require(block.timestamp > launchTime, "Not launched");
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(referrer != address(0) && users[referrer].deposits.length>0 && referrer != msg.sender, "Invalid referrer");

        users[msg.sender].referrer = referrer;
        users[msg.sender].checkpoint = uint32(block.timestamp);
        
        totalUsers += 1;
        countLeadership();
        
        emit NewUser(msg.sender, users[msg.sender].referrer, msg.value);

    }

    function deposit(address payable referrer) external payable {
        
        require(refundAddress!=address(0), "Refund address not set");
        require(msg.value >= 200 trx && msg.value <= 1e7 trx, "invalid amount");
        if(users[msg.sender].deposits.length==0) register(referrer);

        User storage user = users[msg.sender];
        user.deposits.push(Deposit(uint64(msg.value),0));
        
        refundAddress.transfer(msg.value / 10);
        payLeadership(msg.value);
        payTopInvestors();
        
        resetDailyStats();
        
        checkBalance += msg.value;
        updateTopInvestors();
        
        totalSystemInvested += msg.value;
        
        payAdminOnMaxDep(msg.value);
        
        token.transferFrom(tokenBank, msg.sender, msg.value*5);
        
        emit NewDeposit(msg.sender, msg.value);

    }

    function depositLionTrade() external payable {
        
        require(msg.value >= MIN_TRADE && msg.value <= 1e7 trx, "invalid amount");

        users[msg.sender].totalLionTrade += uint64(msg.value);
        
        totalSystemLionTrade += msg.value;
        
        payAdminOnTradeDep(msg.value);
        
        if(users[msg.sender].referrer!=address(0)){
            users[users[msg.sender].referrer].totalRefBonus += uint64(msg.value * 5 / 100);
            LION_TRADE.transfer(msg.value*83/100);
            users[msg.sender].referrer.transfer(msg.value * 5 / 100);
        }else{
            LION_TRADE.transfer(msg.value*88/100);
        }
        
        resetDailyStats();
        emit NewLionTradeDeposit(msg.sender, msg.value, users[msg.sender].totalLionTrade);

    }
    
    function reActivate() external onlyRegisterd payable {
        
        require(users[msg.sender].reActivateAmount > 0 && msg.value >= users[msg.sender].reActivateAmount  && msg.value <= 1e7 trx, "invalid amount");

        User storage user = users[msg.sender];
        user.totalReActivateAmount += uint64(msg.value);
        user.reActivateAmount = 0;
        
        totalSystemInvested += msg.value;
        
        refundAddress.transfer(msg.value / 5);
        
        payAdminOnReDep(msg.value);
        
        resetDailyStats();
        
        emit NewDeposit(msg.sender, msg.value);

    }

    function withdraw() external onlyRegisterd onceADay {

        require(users[msg.sender].reActivateAmount == 0, "redeposit");

        User storage user = users[msg.sender];
        
        resetDailyStats();
        
        uint dividend = computeUserDividends(msg.sender);
        
        require(dividend>=MIN_DIVIDEND,"MIN_DIVIDEND");
        
        user.checkpoint = uint32(block.timestamp);
        user.reActivateAmount = uint64( dividend * REDEPOSIT / PERCENTS_DIVIDER);

        if (address(this).balance < dividend) {
            dividend = address(this).balance;
        }

        msg.sender.transfer(dividend);
        
        payAdminOnWithdrawal(dividend);

        emit Withdrawn(msg.sender, dividend);
    }
    
    function resetDailyStats() public {
        
        if(block.timestamp.sub(dailyCheckpoint) > DAY){
            
            balances.push(checkBalance);
            intervals.push(block.timestamp);
            checkBalance = 0;
            dailyCheckpoint=block.timestamp;
        }
        
    }
    
    function setRefundAddress(address payable _addr) public onlyOwner{
        require(isContract(_addr), "Only contract");
        refundAddress = _addr;
    }
    
    function setDevAddress(address payable _addr) public onlyOwner{
        devAddress = _addr;
    }
    
    function setMarketingAddress(address payable _addr) public onlyOwner{
        marketingAddress = _addr;
    }
    
    function setCommunityAddress(address payable _addr) public onlyOwner{
        communityWallet = _addr;
    }
    
    function setAdminAddress(address payable _addr) public onlyOwner{
        adminWallet = _addr;
    }
    
    function setTokenBank(address _addr) public onlyOwner{
        tokenBank = _addr;
    }
    
    function getTotalDeposit(address _addr) public view returns(uint,uint){
        uint deposits=0;
        uint withdrawn=0;
        for(uint i=0; i<users[_addr].deposits.length;i++){
            deposits+=users[_addr].deposits[i].amount;
            withdrawn+=users[_addr].deposits[i].withdrawn;
        }
        return (deposits,withdrawn);
    }
    
    function getDepositDividend(uint _amount, uint _checkpoint) public view returns (uint){
        
        uint mined = 0;
        uint checkpoint = _checkpoint;
        for(uint j= 0; j<intervals.length; j++){
            if(checkpoint < intervals[j]){
                mined += 
                    _amount * 
                    getRate(balances[j]) * 
                    intervals[j].sub(checkpoint);
                checkpoint = intervals[j];
            }else{
                continue;
            }
        }
        
        mined += 
                _amount * 
                getRate(checkBalance) * 
                block.timestamp.sub(checkpoint);
        
        return mined / DAY / PERCENTS_DIVIDER;
    }
    
    function getRate(uint _amount) public pure returns(uint){
        
        if(_amount<=50000 trx) return 20;//1+1%
        if(_amount<=200000 trx) return 30;
        if(_amount<=300000 trx) return 40;
        if(_amount<=400000 trx) return 50;
        if(_amount<=500000 trx) return 60;
        if(_amount<=600000 trx) return 70;
        if(_amount<=700000 trx) return 80;
        if(_amount<=800000 trx) return 90;
        if(_amount<=1000000 trx) return 100;
        return 110;
    }
    
    function getUserDividend(address _addr) public view returns(uint){
        if(block.timestamp < launchTime+5 days) return 0;
        uint dividend=0;
        uint totalDividend=0;
        User storage user=users[_addr];
        (uint totalDeposit, ) = getTotalDeposit(_addr);
        for(uint i=0; i<user.deposits.length;i++){
            Deposit storage dep = user.deposits[i];
            uint pureWithdrawn = dep.withdrawn*30/100;
            if(pureWithdrawn>=dep.amount*MAX_PROFIT/PERCENTS_DIVIDER) continue;
            
            dividend = getDepositDividend(dep.amount, user.checkpoint);
                
            if(dividend+pureWithdrawn>dep.amount*MAX_PROFIT/PERCENTS_DIVIDER)
                dividend=(dep.amount*MAX_PROFIT/PERCENTS_DIVIDER).sub(pureWithdrawn);
            
            if(totalDividend+dividend>=totalDeposit*DIV_STOP/PERCENTS_DIVIDER){
                totalDividend = totalDeposit*DIV_STOP/PERCENTS_DIVIDER;
                return totalDividend;
            }else{
                totalDividend+=dividend;
            }
        }
        return totalDividend;
    }

    function getData(address _addr) external view returns ( uint[] memory data ){
        
        User memory u = users[_addr];
        uint[] memory d = new uint[](17);
        (uint deposits, uint withdrawn) = getTotalDeposit(_addr);
        d[0] = deposits;
        d[1] = deposits;
        d[2] = withdrawn;
        d[3] = u.totalRefBonus;
        d[4] = u.totalRefBonus;
        d[5] = u.reActivateAmount;
        d[6] = getUserDividend(_addr);
        d[7] = u.totalLionTrade;
        d[8] = u.checkpoint;
        d[9] = getRate(checkBalance);
        d[10] = u.deposits.length>0 ? 1 : 0;
        d[11] = totalUsers;
        d[12] = totalSystemInvested;
        d[13] = totalSystemLionTrade;
        d[14] = u.totalRefBonus;
        d[15] = dailyCheckpoint;
        d[16] = checkBalance;
        
        return d;
        
    }
    
    function getUplines(address _addr) external view returns(uint40[4] memory){
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
        return address(this).balance;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {size := extcodesize(addr)}
        return size > 0;
    }

}

interface ITRC20 {

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }
}