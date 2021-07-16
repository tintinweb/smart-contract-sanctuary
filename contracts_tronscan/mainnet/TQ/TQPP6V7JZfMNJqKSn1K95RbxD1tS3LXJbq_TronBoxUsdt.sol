//SourceUnit: TronBoxUsdt.sol

pragma solidity ^0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }
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
}

interface ITetherToken {
    function transfer(address _to, uint _value) external returns (bool);
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
}

contract TronBoxUsdt {
    ITetherToken public c_tetherToken = ITetherToken(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C);

    uint256 public consumerRate  = 8;
    uint256 public targetRate  = 5;
    uint256 public allowanceRate  = 21;
    uint256 public directRate = 10;

    uint256 public rate1 = 20;
    uint256 public rate2 = 10;
    uint256 public rate3 = 7;
    uint256 public rate6 = 5;
    uint256 public rate11 = 3;

    address consumerAddress;
    address targetAddress;
    address owner;

    uint256 public delta = 0;
    uint256 public totalInput = 0;

    struct User {
        uint256 id;
        uint256 level;
        address referrer;

        uint256 depositAmount;
        uint256 totalDeposits;
        uint256 depositTime;
        uint256 allowance;
 
        uint256 withdrawAmount;
        uint256 directRealTime;
        uint256 directCount;

        uint256 teamAmount;      
        uint256 teamProfit;
        uint256 totalwithdrawAmount;
    }

    uint256 public lastUserId = 2;
    mapping(address => User) public users; 
    mapping(uint256 => address) public id2Address;
    
    using SafeMath for uint256;

    constructor(address ownerAddress, address consumer, address target) public {
        users[ownerAddress].id = 1;
        id2Address[1] = ownerAddress;
        owner = ownerAddress;
        consumerAddress = consumer;
        targetAddress = target;
    }

    function Deposit(address referrerAddress, uint256 value) external {
        totalInput += value;
        require(value%100000000 == 0 && value > 0, "not valid value");
        if (!isUserExists(msg.sender)) {
            require(isUserExists(referrerAddress), "referrer not exists");
            _register(referrerAddress);
        }else{
            require(users[msg.sender].referrer == referrerAddress);
            require(value >= users[msg.sender].depositAmount + delta, "not valid value");
            require(users[msg.sender].allowance == 0);
        }
        _deposit(msg.sender, value);
        _transferToken(msg.sender, value);
    }

    function _register(address referrerAddress) private {
        users[msg.sender].id = lastUserId;
        users[msg.sender].referrer = referrerAddress;
        id2Address[lastUserId] = msg.sender;      
        lastUserId++;
        users[referrerAddress].directCount += 1;
    }
    
    function _deposit(address user, uint256 value) private {
        users[user].depositAmount = value;
        users[user].depositTime = block.timestamp;
        users[user].totalDeposits += value;
        users[user].allowance += value*allowanceRate/10;

        address referrer = users[msg.sender].referrer;
        users[referrer].directRealTime += value*directRate/100;
        users[referrer].level += value/100000000;

        for (uint8 i = 1; i < 26 && referrer != address(0); i++) {
            users[referrer].teamAmount += value;
            referrer = users[referrer].referrer;
        }
    }
    function _transferToken(address user, uint256 value) private {
        uint256 consumer = value.mul(consumerRate).div(100);
        uint256 target = value.mul(targetRate).div(100);
        uint256 contractValue = value.sub(consumer).sub(target);

        require(c_tetherToken.transferFrom(user, consumerAddress, consumer), "transfer error");
        require(c_tetherToken.transferFrom(user, targetAddress, target), "transfer error");
        require(c_tetherToken.transferFrom(user, address(this), contractValue), "transfer error");
    }
    function Withdraw() external {
        require(isUserExists(msg.sender), "user not exists");
        require(users[msg.sender].allowance != 0, "not depositAmount");
        uint256 maxWithdrawAmount = users[msg.sender].allowance.sub(users[msg.sender].withdrawAmount);
        require(maxWithdrawAmount > 0, "out");

        uint256 curProfit = _calDayProfit();
        _updateUpline(curProfit);

        curProfit += users[msg.sender].teamProfit + users[msg.sender].directRealTime;
        users[msg.sender].teamProfit = 0;
        users[msg.sender].directRealTime = 0;

        if (maxWithdrawAmount > curProfit) {
            users[msg.sender].withdrawAmount += curProfit;
            c_tetherToken.transfer(msg.sender, curProfit);
            users[msg.sender].totalwithdrawAmount += curProfit;
        }else{
            _clear();
            users[msg.sender].totalwithdrawAmount += maxWithdrawAmount;
            c_tetherToken.transfer(msg.sender, maxWithdrawAmount);
        }
    }

    function _calDayProfit() private returns(uint256) {
        uint256 daysInterval = (block.timestamp - users[msg.sender].depositTime) / 1 days;
        uint256 curProfit = users[msg.sender].depositAmount * daysInterval / 100;
        users[msg.sender].depositTime += daysInterval * 1 days;
        return curProfit;
    }

    function _updateUpline(uint256 curProfit) private {
        address referrer = users[msg.sender].referrer;
        for (uint8 i = 1; i < 26 && referrer != address(0); i++) {
            if (users[referrer].level >= i) {
                uint256 rate = rate11;
                if (i == 1) {
                    rate = rate1;
                }else if (i == 2){
                    rate = rate2;
                }else if (3 <= i && i <=5){
                    rate = rate3;
                }else if (6 <= i && i <=10){
                    rate = rate6;
                }
                users[referrer].teamProfit += rate*curProfit/100;
            }
            referrer = users[referrer].referrer;
        }
    }

    function _clear() private {
        users[msg.sender].allowance = 0;
        users[users[msg.sender].referrer].level -= users[msg.sender].depositAmount/100000000;
        users[msg.sender].withdrawAmount = 0;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function setDelta(uint256 _delta) public onlyOwner {
        delta = _delta;
    }
    function setConsumerRate(uint256 rate) public onlyOwner {
        consumerRate = rate;
    }
    function setTargetRate(uint256 rate) public onlyOwner {
        targetRate = rate;
    }
    function setAllowanceRate(uint256 rate) public onlyOwner {
        allowanceRate = rate;
    }
    function setDirectRate(uint256 rate) public onlyOwner {
        directRate = rate;
    }

    function setRate1(uint256 rate) public onlyOwner {
        rate1 = rate;
    }
    function setRate2(uint256 rate) public onlyOwner {
        rate2 = rate;
    }
    function setRate3(uint256 rate) public onlyOwner {
        rate3 = rate;
    }
    function setRate6(uint256 rate) public onlyOwner {
        rate6 = rate;
    }
    function setRate11(uint256 rate) public onlyOwner {
        rate11 = rate;
    }

    function setConsumerAddress(address _consumer) public onlyOwner {
        consumerAddress = _consumer;
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function CurAllowance(address user) public view returns (uint256) {
        return users[user].allowance;
    }

    function MaxWithdrawAmount(address user) public view returns (uint256) {
        return users[user].allowance - users[user].withdrawAmount;
    }

    function DirectRealTime(address user) public view returns (uint) {
        return users[user].directRealTime;
    }

    function Day1Team(address user) public view returns (uint) {
        return users[user].teamProfit;
    }

    function sumDay(address user) public view returns (uint) {
        uint256 daysInterval = (block.timestamp - users[user].depositTime) / 1 days;
        uint256 curProfit = users[user].depositAmount * daysInterval / 100;
        if (users[user].allowance == 0){
            return 0;
        }
        return curProfit;
    }

    function RemainWithdraw(address user) public view returns (uint) {
        uint256 daysInterval = (block.timestamp - users[user].depositTime) / 1 days;
        uint256 curProfit = users[user].depositAmount * daysInterval / 100;
        curProfit += users[user].teamProfit + users[user].directRealTime;
        uint256 maxWithdrawAmount = users[user].allowance - users[user].withdrawAmount;
        if (curProfit < maxWithdrawAmount){
            return curProfit;
        }else {
            return maxWithdrawAmount;
        }
    }

    function WithdrawAmount(address user) public view returns (uint) {
        return users[user].withdrawAmount;
    }

    function TotalwithdrawAmount(address user) public view returns (uint) {
        return users[user].totalwithdrawAmount;
    }

    function Day1Dividends(address user) public view returns (uint) {
        uint256 daysInterval = (block.timestamp - users[user].depositTime) / 1 days;
        uint256 curProfit = users[user].depositAmount * daysInterval / 100;
        curProfit += users[user].teamProfit + users[user].directRealTime;
        uint256 maxWithdrawAmount = users[user].allowance - users[user].withdrawAmount;
        if (curProfit < maxWithdrawAmount){
            return users[user].depositAmount/100;
        }else {
            return 0;
        }
    }

    function TotalDeposits(address user) public view returns (uint) {
        return users[user].totalDeposits;
    }

    function DepositTime(address user) public view returns (uint) {
        if (users[user].id == 0 || users[user].allowance == 0){
            return 0;
        }
        return users[user].depositTime;
    }

    function Level(address user) public view returns (uint) {
        return users[user].level*100000000;
    }

    function DirectCount(address user) public view returns (uint) {
        return users[user].directCount;
    }

    function TeamAmount(address user) public view returns (uint) {
        return users[user].teamAmount;
    }

    function SumWithdrawAmount() public view returns (uint) {
        uint sumWithdrawAmount = 0;
        for (uint i = 1; i < lastUserId; i++) {
            sumWithdrawAmount += users[id2Address[i]].totalwithdrawAmount;
        }
        return sumWithdrawAmount;
    }
}