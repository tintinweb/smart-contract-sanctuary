//SourceUnit: TronAO_ROI.sol

pragma solidity =0.4.25;
/*
** TronAO Simple ROI
** Min Invest: 10 TRX
** http://tronao.x10.bz/
*/
contract TronAO_SimpleROI_v1 {

    uint constant PAYMENT_PERIOD = 60 minutes; // get profit every hour
    uint constant MIN_DEPOSIT = 10000000; //minimum deposit is 10 TRX
    uint constant HOURLY_PROFIT_DIVIDER = 2400; // 1/2400 is 0.04166% per hour, 1% per day.

    uint public startTime;
    uint public totalUsers;
    uint public totalDeposited;
    uint public totalPayout;

    address _owner;

    struct User {
        uint deposit; //total deposited by the user
        uint checkedProfit; //unwithdrawn user profit at the time of the last check
        uint totalProfit; //total amount withdrawn by the user
        uint checkTime; //timestamp of the last user profit check
    }

    mapping (address => User) public users; //user info is public, it's possible to check stats of any user

    modifier startTimeCheck() {
        require(startTime < now, "The contract is not started yet.");
        _;
    }

    constructor() public {
        startTime = now + 24 * PAYMENT_PERIOD; // we start in 24 hours after the contract deployment;
        _owner = msg.sender;
    }

    function deposit() external payable startTimeCheck() {
        require(msg.value >= MIN_DEPOSIT, "Minimum Deposit of 10 TRX");
        User storage user = users[msg.sender];
        if (user.checkTime == 0) { //new user
            user.deposit = msg.value;
            user.checkTime = now;
            totalUsers++;
        } else { //new deposit of existing user
            _userCheck(user);
            user.deposit += msg.value; //We can't overflow uint256 here.         
        }
        totalDeposited += msg.value;
        users[_owner].checkedProfit += msg.value / 100; // 1% admin fee.
    }

    function withdrawAll() external {
        User storage user = users[msg.sender];
        _userCheck(user);
        require(user.checkedProfit > 0);
        uint contractBalance = address(this).balance;
        uint profit = user.checkedProfit;
        if (contractBalance > profit) { //the contract have enough money
            user.checkedProfit = 0;
            user.totalProfit += profit;
            totalPayout += profit;
            msg.sender.transfer(profit);
        } else { //if the contract have not enough money, it sends all that left
            require(user.checkedProfit >= contractBalance, "Sanity check");
            user.checkedProfit -= contractBalance;
            user.totalProfit += contractBalance;
            totalPayout += contractBalance;
            msg.sender.transfer(contractBalance);
        }
    }

    function reinvestAll() external {
        User storage user = users[msg.sender];
        _userCheck(user);
        require(user.checkedProfit >= MIN_DEPOSIT, "Minimum 10 TRX To Deposit");
        user.deposit += user.checkedProfit; //We can't overflow uint256 here.
        totalDeposited += user.checkedProfit;
        user.checkedProfit = 0;
        //no admin fees on reinvest
    }

    function _userCheck(User storage user) internal {
        require(user.checkTime > 0, "Please Deposit First");
        require(user.checkTime < now, "Sanity check");
        uint periods = (now - user.checkTime) / PAYMENT_PERIOD;
        if (periods > 0) {
            user.checkedProfit += (user.deposit / HOURLY_PROFIT_DIVIDER) * periods; //0.04166% per an hour, 1% per a day.
            user.checkTime += periods * PAYMENT_PERIOD;
        }
    }

    function getMyInfo() external view returns (uint, uint, uint, uint, uint) {
        User storage user = users[msg.sender];
        return (user.deposit, user.checkedProfit, user.totalProfit, user.checkTime, now);
    }
}