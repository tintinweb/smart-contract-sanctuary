//SourceUnit: Pentagram.sol

pragma solidity ^0.5.4;

contract Pentagram {
    
    modifier onlyRegisterd {
        require(users[msg.sender].registered, "not registered");
        _;
    }
    
    modifier onceADay {
        require(block.timestamp > users[msg.sender].checkpoint + DAY, "Ops!");
        _;
    }
   
    uint8[5] public REFERRAL_PERCENTS = [25, 15, 10, 10, 10];
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public DAY = 1 days;
    uint constant public MAX_DAILY_REF_WITHDRAWAL = 25000 trx;

    uint public totalUsers;
    uint public totalSystemInvested;
    uint public totalSystemPentaTrade;

    address payable public PENTA_TRADE = address(uint160(0x419cebe767d26f509b184c677b0e70268fdfad8e25));
    address payable public PENTA_BUILD = address(uint160(0x419898a2ed9511ccbb757c2bf32ec68487e1052b26));
    
    address payable public marketingAddress;
    address payable public devAddress;
    address payable public communityWallet;

    using SafeMath for uint64;
    using SafeMath for uint256;

    struct User {

        uint64 balance;
        uint64 totalInvested;
        uint64 totalWithdrawn;
        uint64 totalRefBonus;
        uint64 directReferrals;
        uint64 refBonus;
        uint64 reActivateAmount;
        uint64 leadershipBonus;
        uint64 totalPentaTrade;
        uint32 checkpoint;
        address referrer;
        uint8 vrr;
        bool registered;
        uint40[5] uplines;

    }

    mapping(address => User) public users;

    event NewUser(address indexed user, address referrer, uint amount);
    event NewDeposit(address indexed user, uint256 amount);
    event NewPentaTradeDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 dividends);
    event Reinvest(address indexed user, uint256 dividends);
    event RefWithdrawn(address indexed user, uint256 profit, uint256 currentBonus);

    constructor(address payable marketingAddr, address payable communityAddr, address payable devAddr) public {
        require(!isContract(marketingAddr) &&
        !isContract(communityAddr) &&
        !isContract(devAddr));
        
        marketingAddress = marketingAddr;
        communityWallet = communityAddr;
        devAddress = devAddr;
        
        users[devAddress].registered = true;
        users[devAddress].vrr = 10;
    }

    //////////////////////////////////////////////////////////
    //------------------private functions-------------------//

    function payLeadership(uint _amount) private {
        address upline = users[msg.sender].referrer;
        for (uint i = 0; i < REFERRAL_PERCENTS.length; i++) {
            if (upline != address(0)) {
                users[upline].leadershipBonus += uint64(_amount * REFERRAL_PERCENTS[i] / PERCENTS_DIVIDER);
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

    function distributeRegisterFund(uint _amount) private {
        marketingAddress.transfer(_amount*8/100);
        devAddress.transfer(_amount*6/100);
        communityWallet.transfer(_amount*6/100);
        PENTA_BUILD.transfer(_amount*22/100);
        PENTA_TRADE.transfer(_amount*50/100);
    }
    
    function payAdminOnDep(uint _amount) private {
        marketingAddress.transfer(_amount*4/100);
        devAddress.transfer(_amount*3/100);
        communityWallet.transfer(_amount*3/100);
    }
    
    function payAdminOnWithdrawal(uint _amount) private {
        uint fee = _amount*6/100;
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) marketingAddress.transfer(fee);
        fee = _amount*4/100;
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) devAddress.transfer(fee);
        fee = _amount*3/100;
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) communityWallet.transfer(fee);
    }
    
    //---------------end of private functions---------------//
    //////////////////////////////////////////////////////////

    function register(address referrer) external payable {
        
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(referrer != address(0) && users[referrer].registered && referrer != msg.sender, "Invalid referrer");
        require(msg.value >= 200 trx && msg.value <= 1e7 trx);//Max deposit amount 10M trx
        require(!users[msg.sender].registered, "already registered");

        users[msg.sender].referrer = referrer;
        users[msg.sender].vrr = 10;
        users[msg.sender].registered = true;
        
        users[referrer].refBonus += uint64(msg.value * 8 / 100);
        users[referrer].directReferrals += 1;
        
        totalUsers += 1;
        totalSystemInvested += msg.value;
        countLeadership();
        distributeRegisterFund(msg.value);
        
        emit NewUser(msg.sender, users[msg.sender].referrer, msg.value);

    }

    function depositPentaMax() external onlyRegisterd payable {
        
        require(msg.value >= 100 trx && msg.value <= 1e7 trx, "invalid amount");

        User storage user = users[msg.sender];
        user.balance = uint64(user.balance.add(msg.value));
        user.totalInvested = uint64(user.totalInvested.add(msg.value));

        if(user.checkpoint == 0){
            user.checkpoint = uint32(block.timestamp);
        }
        
        users[user.referrer].refBonus += uint64(msg.value * 8 / 100);
        
        totalSystemInvested += msg.value;
        
        payAdminOnDep(msg.value);
        
        emit NewDeposit(msg.sender, msg.value);

    }

    function depositPentaTrade() external onlyRegisterd payable {
        
        require(msg.value >= 200 trx && msg.value <= 1e7 trx, "invalid amount");

        users[users[msg.sender].referrer].refBonus += uint64(msg.value * 8 / 100);
        users[msg.sender].totalPentaTrade += uint64(msg.value);
        
        totalSystemPentaTrade += msg.value;
        
        payAdminOnDep(msg.value);
        PENTA_TRADE.transfer(msg.value*82/100);
        
        emit NewPentaTradeDeposit(msg.sender, msg.value);

    }
    
    function reActivatePentaMax() external onlyRegisterd payable {
        
        require(users[msg.sender].reActivateAmount > 0 && msg.value >= users[msg.sender].reActivateAmount  && msg.value <= 1e7 trx, "invalid amount");

        User storage user = users[msg.sender];
        user.balance = uint64(user.balance.add(msg.value));
        user.totalInvested = uint64(user.totalInvested.add(msg.value));
        user.reActivateAmount = 0;
        
        users[user.referrer].refBonus += uint64(msg.value * 8 / 100);
        
        totalSystemInvested += msg.value;
        
        payAdminOnDep(msg.value);
        
        emit NewDeposit(msg.sender, msg.value);

    }

    function withdrawPentaMax() external onlyRegisterd onceADay {

        require(users[msg.sender].totalWithdrawn < users[msg.sender].balance * 180 / 100, "Ops!");
        require(users[msg.sender].reActivateAmount == 0, "redeposit");

        User storage user = users[msg.sender];
        
        uint dividend = user.balance * user.vrr / 100;
        
        if (user.totalWithdrawn + dividend > user.balance * 180 / 100) {
            dividend = (user.balance * 180 / 100).sub(user.totalWithdrawn);
        }

        if (user.vrr > 3) user.vrr -= 2;
        else if(user.vrr == 3) user.vrr = 2;

        user.totalWithdrawn += uint64(dividend);
        user.checkpoint = uint32(block.timestamp);
        if(dividend >= 250 trx){
            user.reActivateAmount = uint64( dividend * 20 / 100);
        }
        
        payLeadership(dividend);

        if (address(this).balance < dividend) {
            dividend = address(this).balance;
        }

        msg.sender.transfer(dividend);
        
        payAdminOnWithdrawal(dividend);

        emit Withdrawn(msg.sender, dividend);
    }

    function reinvestPentaMax() external onlyRegisterd onceADay {

        User storage user = users[msg.sender];

        uint dividend = user.balance * user.vrr / 100;
        
        if (user.totalWithdrawn + dividend > user.balance * 180 / 100) {
            dividend = (user.balance * 180 / 100).sub(user.totalWithdrawn);
        }
        
        user.balance += uint64(dividend);
        if (user.vrr < 10) user.vrr += 1;
        user.checkpoint = uint32(block.timestamp);

        emit Reinvest(msg.sender, dividend);
    }
    
    function reinvestLeadership() external onlyRegisterd {

        require(block.timestamp > users[msg.sender].checkpoint + 2 * DAY, "Oops!");
        
        User storage user = users[msg.sender];

        user.balance += user.leadershipBonus;
        
        emit Reinvest(msg.sender, user.leadershipBonus);
        
        user.leadershipBonus = 0;
        user.checkpoint = uint32(block.timestamp);

    }

    function withdrawRefBonus() external onlyRegisterd {

        User storage user = users[msg.sender];
        require(block.timestamp > user.checkpoint + 2 * DAY, "Oops!");

        uint paid = user.refBonus > MAX_DAILY_REF_WITHDRAWAL ? MAX_DAILY_REF_WITHDRAWAL : user.refBonus;

        user.refBonus = uint64(user.refBonus.sub(paid));
        user.checkpoint = uint32(block.timestamp);
        user.totalRefBonus += uint64(paid);
        
        payLeadership(paid);
        
        if (address(this).balance < paid) {
            paid = address(this).balance;
        }

        msg.sender.transfer(paid);
        
        payAdminOnWithdrawal(paid);
        
        emit RefWithdrawn(msg.sender, paid, user.refBonus);
    }

    function getUserDividends(address _user) public view returns (uint){

        if(!users[_user].registered) return 0;
        
        return users[_user].balance * users[_user].vrr / 100;
    }

    function getData(address _addr) external view returns ( uint[] memory data ){
        
        User memory u = users[_addr];
        uint[] memory d = new uint[](16);
        d[0] = u.balance;
        d[1] = u.totalInvested;
        d[2] = u.totalWithdrawn;
        d[3] = u.totalRefBonus;
        d[4] = u.refBonus;
        d[5] = u.reActivateAmount;
        d[6] = u.leadershipBonus;
        d[7] = u.totalPentaTrade;
        d[8] = u.checkpoint;
        d[9] = u.vrr;
        d[10] = u.registered ? 1 : 0;
        d[11] = totalUsers;
        d[12] = totalSystemInvested;
        d[13] = totalSystemPentaTrade;
        d[14] = u.directReferrals;
        
        return d;
        
    }
    
    function getUplines(address _addr) external view returns(uint40[5] memory){
        return users[_addr].uplines;
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