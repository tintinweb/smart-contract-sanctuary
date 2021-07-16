//SourceUnit: PentagramRevolution.sol

pragma solidity ^0.5.4;

contract PentagramRevolution {
    
    modifier onlyRegisterd {
        require(users[msg.sender].deposits.length>0, "not registered");
        _;
    }
    
    modifier onceADay {
        require(block.timestamp > users[msg.sender].checkpoint + DAY, "Ops!");
        _;
    }
   
    uint8[5] public REFERRAL_PERCENTS = [70, 40, 20, 10, 10];
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public DAY = 1 days;
    uint constant public DIV_STOP = 250;//25%
    uint constant public MAX_PROFIT = 20000;//2000%
    uint constant public MIN_DIVIDEND = 50 trx;
    uint constant public REDEPOSIT = 500;//50%
    uint8 constant public ROI1 = 30;//3%
    uint8 constant public ROI2 = 50;//4%
    uint8 constant public ROI3 = 50;//5%
    address payable[5] public TOP_INVESTORS;
    uint[5] public TOP_AMOUNTS;
    uint constant public TOP_INVESTORS_SAHRE = 10;//1%
    uint16[5] public TOP_INVESTORS_PERCENTS = [500, 200, 150, 100, 50];
    
    uint public totalUsers;
    uint public totalSystemInvested;
    uint public totalSystemPentaTrade;
    uint public checkpoint;

    address payable public PENTA_TRADE = address(uint160(0x4100004d8420bd32d6570defb2d58f17b8538a9918));
    
    address payable public marketingAddress;
    address payable public devAddress;
    address payable public communityWallet;
    address payable public adminWallet;

    using SafeMath for uint64;
    using SafeMath for uint256;
    
    struct Deposit{
        uint64 amount;
        uint64 withdrawn;
    }

    struct User {

        uint64 totalRefBonus;
        uint64 totalPentaTrade;
        uint64 totalTopInvestorReward;
        uint64 reActivateAmount;
        uint64 totalReActivateAmount;
        uint32 checkpoint;
        address payable referrer;
        uint8 vrr;
        uint40[5] uplines;
        Deposit[] deposits;

    }

    mapping(address => User) public users;

    event NewUser(address indexed user, address referrer, uint amount);
    event NewDeposit(address indexed user, uint256 amount);
    event NewPentaTradeDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 dividends);
    event Reinvest(address indexed user, uint256 dividends);
    event RefWithdrawn(address indexed user, uint256 profit, uint256 currentBonus);

    constructor(address payable marketingAddr, address payable communityAddr,  address payable adminAddr, address payable devAddr) public {
        require(!isContract(marketingAddr) &&
        !isContract(communityAddr) &&
        !isContract(devAddr) &&
        !isContract(adminAddr));
        
        checkpoint = block.timestamp;
        
        marketingAddress = marketingAddr;
        communityWallet = communityAddr;
        devAddress = devAddr;
        adminWallet=adminAddr;
        users[devAddress].deposits.push(Deposit(1 trx, 0));
        users[devAddress].vrr = ROI3;
    }

    //////////////////////////////////////////////////////////
    //------------------private functions-------------------//

    function computeUserDividends(address _user) private returns (uint){
        
        uint dividend=0;
        uint totalDividend=0;
        User storage user=users[_user];
        (uint totalDeposit, ) = getTotalDeposit(_user);
        for(uint i=0; i<user.deposits.length;i++){
            if(user.deposits[i].withdrawn>=user.deposits[i].amount*MAX_PROFIT/PERCENTS_DIVIDER) continue;
            dividend = user.deposits[i].amount*user.vrr*block.timestamp.sub(user.checkpoint)/DAY/PERCENTS_DIVIDER;
            if(dividend+user.deposits[i].withdrawn>user.deposits[i].amount*MAX_PROFIT/PERCENTS_DIVIDER)
                dividend=(user.deposits[i].amount*MAX_PROFIT/PERCENTS_DIVIDER).sub(user.deposits[i].withdrawn);
            
            if(totalDividend+dividend>=totalDeposit*DIV_STOP/PERCENTS_DIVIDER){
                user.deposits[i].withdrawn += uint64((totalDeposit*DIV_STOP/PERCENTS_DIVIDER).sub(totalDividend));
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
        marketingAddress.transfer(_amount*10/100);
        devAddress.transfer(_amount*8/100);
        communityWallet.transfer(_amount*7/100);
        adminWallet.transfer(_amount*1/100);
    }
    
    function payAdminOnMaxDep(uint _amount) private {
        marketingAddress.transfer(_amount*5/100);
        devAddress.transfer(_amount*4/100);
        communityWallet.transfer(_amount*4/100);
    }
    
    function payAdminOnTradeDep(uint _amount) private {
        marketingAddress.transfer(_amount*4/100);
        devAddress.transfer(_amount*3/100);
        communityWallet.transfer(_amount*3/100);
    }
    
    function payAdminOnWithdrawal(uint _amount) private {
        uint fee = _amount*4/100;
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) marketingAddress.transfer(fee);
        fee = _amount*4/100;
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) devAddress.transfer(fee);
        fee = _amount*4/100;
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) communityWallet.transfer(fee);
        fee = _amount*1/100;
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) adminWallet.transfer(fee);
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
        if(block.timestamp.sub(checkpoint)> DAY){
            for (uint i = 0; i < REFERRAL_PERCENTS.length; i++) {
                if(TOP_INVESTORS[i]!=address(0) || TOP_AMOUNTS[i]>0){
                    TOP_INVESTORS[i]=address(0);
                    TOP_AMOUNTS[i]=0;
                }
            }
            checkpoint=block.timestamp;
        }
        
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

    function register(address payable referrer) internal {
        
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(referrer != address(0) && users[referrer].deposits.length>0 && referrer != msg.sender, "Invalid referrer");

        users[msg.sender].referrer = referrer;
        users[msg.sender].checkpoint = uint32(block.timestamp);
        
        totalUsers += 1;
        countLeadership();
        
        emit NewUser(msg.sender, users[msg.sender].referrer, msg.value);

    }

    function depositPentaMax(address payable referrer) external payable {
        
        require(msg.value >= 200 trx && msg.value <= 1e7 trx, "invalid amount");
        if(users[msg.sender].deposits.length==0) register(referrer);

        User storage user = users[msg.sender];
        user.deposits.push(Deposit(uint64(msg.value),0));
        (uint deposits,)=getTotalDeposit(msg.sender);
        if(deposits>=50000 trx) user.vrr = ROI3;
        else if(deposits>=10000 trx) user.vrr = ROI2;
        else user.vrr = ROI1;

        payLeadership(msg.value);
        payTopInvestors();
        updateTopInvestors();
        
        totalSystemInvested += msg.value;
        
        payAdminOnMaxDep(msg.value);
        
        emit NewDeposit(msg.sender, msg.value);

    }

    function depositPentaTrade() external onlyRegisterd payable {
        
        require(msg.value >= 200 trx && msg.value <= 1e7 trx, "invalid amount");

        users[msg.sender].totalPentaTrade += uint64(msg.value);
        
        totalSystemPentaTrade += msg.value;
        
        payAdminOnTradeDep(msg.value);
        users[users[msg.sender].referrer].totalRefBonus += uint64(msg.value * 8 / 100);
        PENTA_TRADE.transfer(msg.value*82/100);
        users[msg.sender].referrer.transfer(msg.value * 8 / 100);
        
        emit NewPentaTradeDeposit(msg.sender, msg.value);

    }
    
    function reActivatePentaMax() external onlyRegisterd payable {
        
        require(users[msg.sender].reActivateAmount > 0 && msg.value >= users[msg.sender].reActivateAmount  && msg.value <= 1e7 trx, "invalid amount");

        User storage user = users[msg.sender];
        user.totalReActivateAmount += uint64(msg.value);
        user.reActivateAmount = 0;
        
        totalSystemInvested += msg.value;
        
        payAdminOnReDep(msg.value);
        
        emit NewDeposit(msg.sender, msg.value);

    }

    function withdrawPentaMax() external onlyRegisterd onceADay {

        require(users[msg.sender].reActivateAmount == 0, "redeposit");

        User storage user = users[msg.sender];
        
        uint dividend = computeUserDividends(msg.sender);
        
        require(dividend>=MIN_DIVIDEND,"MIN_DIVIDEND");
        
        user.checkpoint = uint32(block.timestamp);
        if(dividend >= 50 trx){
            user.reActivateAmount = uint64( dividend * REDEPOSIT / PERCENTS_DIVIDER);
        }

        if (address(this).balance < dividend) {
            dividend = address(this).balance;
        }

        msg.sender.transfer(dividend);
        
        payAdminOnWithdrawal(dividend);

        emit Withdrawn(msg.sender, dividend);
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
    
    function getUserDividend(address _addr) public view returns(uint){
        uint dividend=0;
        uint totalDividend=0;
        User storage user=users[_addr];
        (uint totalDeposit, ) = getTotalDeposit(_addr);
        for(uint i=0; i<user.deposits.length;i++){
            if(user.deposits[i].withdrawn>=user.deposits[i].amount*MAX_PROFIT/PERCENTS_DIVIDER) continue;
            dividend = user.deposits[i].amount*user.vrr*block.timestamp.sub(user.checkpoint)/DAY/PERCENTS_DIVIDER;
            if(dividend+user.deposits[i].withdrawn>user.deposits[i].amount*MAX_PROFIT/PERCENTS_DIVIDER)
                dividend=(user.deposits[i].amount*MAX_PROFIT/PERCENTS_DIVIDER).sub(user.deposits[i].withdrawn);
            
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
        uint[] memory d = new uint[](16);
        (uint deposits, uint withdrawn) = getTotalDeposit(_addr);
        d[0] = deposits;
        d[1] = deposits;
        d[2] = withdrawn;
        d[3] = u.totalRefBonus;
        d[4] = u.totalRefBonus;
        d[5] = u.reActivateAmount;
        d[6] = getUserDividend(_addr);
        d[7] = u.totalPentaTrade;
        d[8] = u.checkpoint;
        d[9] = u.vrr;
        d[10] = u.deposits.length>0 ? 1 : 0;
        d[11] = totalUsers;
        d[12] = totalSystemInvested;
        d[13] = totalSystemPentaTrade;
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
        return address(this).balance;
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