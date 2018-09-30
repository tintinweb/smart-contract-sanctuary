pragma solidity ^0.4.24;

contract Lottery {
    using SafeMath for uint;
    using SafeMath for uint8;

    uint private lotteryBalance;
    uint private ticketsCount;

    address[] internal ticketsAddresses;
    mapping(address => uint) internal tickets;

    uint constant private DEPOSIT_MULTIPLY = 100 finney; // 0.1 eth
    uint8 constant internal ITERATION_LIMIT = 150;
    uint8 private generatorOffset = 0;
    uint private randomNumber = 0;

    Utils.winner private lastWinner;

    function addLotteryParticipant(address addr, uint depositAmount) internal {
        if (depositAmount >= DEPOSIT_MULTIPLY) {
            uint investorTicketCount = depositAmount.div(DEPOSIT_MULTIPLY);
            ticketsCount = ticketsCount.add(investorTicketCount);
            ticketsAddresses.push(addr);
            tickets[addr] = tickets[addr].add(investorTicketCount);
        }
    }

    function getLotteryBalance() public view returns(uint) {

        return lotteryBalance;
    }

    function increaseLotteryBalance(uint value) internal {

        lotteryBalance = lotteryBalance.add(value);
    }

    function resetLotteryBalance() internal {

        ticketsCount = 0;
        lotteryBalance = 0;
    }

    function setLastWinner(address addr, uint balance, uint prize, uint date) internal {
        lastWinner.addr = addr;
        lastWinner.balance = balance;
        lastWinner.prize = prize;
        lastWinner.date = date;
    }

    function getLastWinner() public view returns(address, uint, uint, uint) {
        return (lastWinner.addr, lastWinner.balance, lastWinner.prize, lastWinner.date);
    }

    function getRandomLotteryTicket() internal returns(address) {
        address addr;
        if (randomNumber != 0)
            randomNumber = random(ticketsCount);
        uint edge = 0;
        for (uint8 key = generatorOffset; key < ticketsAddresses.length && key < ITERATION_LIMIT; key++) {
            addr = ticketsAddresses[key];
            edge = edge.add(tickets[addr]);
            if (randomNumber <= edge) {
                randomNumber = 0;
                generatorOffset = 0;
                return addr;
            }
        }
        generatorOffset = key;
        return 0;
    }

    function random(uint max) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % max + 1;
    }
}

contract Stellar {
    using SafeMath for uint;

    uint private stellarInvestorBalance;

    struct stellar {
        address addr;
        uint balance;
    }

    stellar private stellarInvestor;

    Utils.winner private lastStellar;

    event NewStellar(address addr, uint balance);

    function checkForNewStellar(address addr, uint balance) internal {
        if (balance > stellarInvestor.balance) {
            stellarInvestor = stellar(addr, balance);
            emit NewStellar(addr, balance);
        }
    }

    function getStellarInvestor() public view returns(address, uint) {

        return (stellarInvestor.addr, stellarInvestor.balance);
    }

    function getStellarBalance() public view returns(uint) {

        return stellarInvestorBalance;
    }

    function increaseStellarBalance(uint value) internal {

        stellarInvestorBalance = stellarInvestorBalance.add(value);
    }

    function resetStellarBalance() internal {
        stellarInvestorBalance = 0;
    }

    function resetStellarInvestor() internal {
        stellarInvestor.addr = 0;
        stellarInvestor.balance = 0;
    }

    function setLastStellar(address addr, uint balance, uint prize, uint date) internal {
        lastStellar.addr = addr;
        lastStellar.balance = balance;
        lastStellar.prize = prize;
        lastStellar.date = date;
    }

    function getLastStellar() public view returns(address, uint, uint, uint) {
        return (lastStellar.addr, lastStellar.balance, lastStellar.prize, lastStellar.date);
    }
}

contract Star is Lottery, Stellar {

    using Math for Math.percent;
    using SafeMath for uint;

    uint constant private MIN_DEPOSIT = 10 finney; // 0.01 eth
    uint constant private PAYOUT_INTERVAL = 23 hours;
    uint constant private WITHDRAW_INTERVAL = 12 hours;
    uint constant private PAYOUT_TRANSACTION_LIMIT = 100;

    Math.percent private DAILY_PERCENT =  Math.percent(35, 10); // Math.percent(35, 10) = 35 / 10 = 3.5%
    Math.percent private FEE_PERCENT = Math.percent(18, 1);
    Math.percent private LOTTERY_PERCENT = Math.percent(1, 1);
    Math.percent private STELLAR_INVESTOR_PERCENT = Math.percent(1, 1);

    address internal owner;

    uint8 cycle;

    address[] internal addresses;

    uint internal investorCount;
    uint internal lastPayoutDate;
    uint internal lastDepositDate;

    bool public isCycleFinish = false;

    struct investor {
        uint id;
        uint balance;
        uint depositCount;
        uint lastDepositDate;
    }

    mapping(address => investor) internal investors;

    event Invest(address addr, uint amount);
    event InvestorPayout(address addr, uint amount, uint date);
    event Payout(uint amount, uint transactionCount, uint date);
    event Withdraw(address addr, uint amount);
    event NextCycle(uint8 cycle, uint now, uint);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
        addresses.length = 1;
    }

    function() payable public {
        require(isCycleFinish == false, "Cycle completed. The new cycle will start within 24 hours.");

        if (msg.value == 0) {
            withdraw(msg.sender);
            return;
        }

        deposit(msg.sender, msg.value);
    }

    function restartCycle() public onlyOwner returns(bool) {
        if (isCycleFinish == true) {
            newCycle();
            return false;
        }
        return true;
    }

    function payout(uint startPosition) public onlyOwner {

        require(isCycleFinish == false, "Cycle completed. The new cycle will start within 24 hours.");

        uint transactionCount;
        uint investorsPayout;
        uint dividendsAmount;

        if (startPosition == 0)
            startPosition = 1;

        for (uint key = startPosition; key <= investorCount && transactionCount < PAYOUT_TRANSACTION_LIMIT; key++) {
            address addr = addresses[key];
            if (investors[addr].lastDepositDate + PAYOUT_INTERVAL > now) {
                continue;
            }

            dividendsAmount = getInvestorDividends(addr);

            if (address(this).balance < dividendsAmount) {
                isCycleFinish = true;
                return;
            }

            addr.transfer(dividendsAmount);
            emit InvestorPayout(addr, dividendsAmount, now);
            investors[addr].lastDepositDate = now;

            investorsPayout = investorsPayout.add(dividendsAmount);

            transactionCount++;
        }

        lastPayoutDate = now;
        emit Payout(investorsPayout, transactionCount, lastPayoutDate);
    }

    function deposit(address addr, uint amount) internal {
        require(amount >= MIN_DEPOSIT, "Too small amount, minimum 0.01 eth");

        investor storage user = investors[addr];

        if (user.id == 0) {
            user.id = addresses.length;
            addresses.push(addr);
            investorCount ++;
        }

        uint depositFee = FEE_PERCENT.getPercentFrom(amount);

        increaseLotteryBalance(LOTTERY_PERCENT.getPercentFrom(amount));
        increaseStellarBalance(STELLAR_INVESTOR_PERCENT.getPercentFrom(amount));

        addLotteryParticipant(addr, amount);

        user.balance = user.balance.add(amount);
        user.depositCount ++;
        user.lastDepositDate = now;
        lastDepositDate = now;

        checkForNewStellar(addr, user.balance);

        emit Invest(msg.sender, msg.value);

        owner.transfer(depositFee);
    }

    function withdraw(address addr) internal {
        require(isCycleFinish == false, "Cycle completed. The new cycle will start within 24 hours.");

        investor storage user = investors[addr];
        require(user.id > 0, "Account not found");

        require(now.sub(user.lastDepositDate).div(WITHDRAW_INTERVAL) > 0, "The latest payment was earlier than 12 hours");

        uint dividendsAmount = getInvestorDividends(addr);

        if (address(this).balance < dividendsAmount) {
            isCycleFinish = true;
            return;
        }

        addr.transfer(dividendsAmount);
        user.lastDepositDate = now;

        emit Withdraw(addr, dividendsAmount);
    }

    function runLottery() public onlyOwner returns(bool) {
        return processLotteryReward();
    }

    function processLotteryReward() private returns(bool) {
        if (getLotteryBalance() > 0) {
            address winnerAddress = getRandomLotteryTicket();
            if (winnerAddress == 0)
                return false;
            winnerAddress.transfer(getLotteryBalance());
            setLastWinner(winnerAddress, investors[winnerAddress].balance, getLotteryBalance(), now);
            resetLotteryBalance();
            return true;
        }

        return false;
    }

    function giveStellarReward() public onlyOwner {
        processStellarReward();
    }

    function processStellarReward() private {
        uint balance = getStellarBalance();
        if (balance > 0) {
            (address addr, uint investorBalance) = getStellarInvestor();
            addr.transfer(balance);
            setLastStellar(addr, investors[addr].balance, getStellarBalance(), now);
            resetStellarBalance();
        }
    }

    function getInvestorCount() public view returns (uint) {

        return investorCount;
    }

    function getBalance() public view returns (uint) {

        return address(this).balance;
    }

    function getLastPayoutDate() public view returns (uint) {

        return lastPayoutDate;
    }

    function getLastDepositDate() public view returns (uint) {

        return lastDepositDate;
    }

    function getInvestorDividends(address addr) public view returns(uint) {
        uint amountPerDay = DAILY_PERCENT.getPercentFrom(investors[addr].balance);
        uint timeLapse = now.sub(investors[addr].lastDepositDate);

        return amountPerDay.mul(timeLapse).div(1 days);
    }

    function getInvestorBalance(address addr) public view returns(uint) {

        return investors[addr].balance;
    }

    function getInvestorInfo(address addr) public onlyOwner view returns(uint, uint, uint, uint) {

        return (
            investors[addr].id,
            investors[addr].balance,
            investors[addr].depositCount,
            investors[addr].lastDepositDate
        );
    }

    function newCycle() private {
        address addr;
        uint8 iteration;
        uint i;

        for (i = addresses.length - 1; i > 0; i--) {
            addr = addresses[i];
            addresses.length -= 1;
            delete investors[addr];
            iteration++;
            if (iteration >= ITERATION_LIMIT) {
                return;
            }
        }

        for (i = ticketsAddresses.length - 1; i > 0; i--) {
            addr = ticketsAddresses[i];
            ticketsAddresses.length -= 1;
            delete tickets[addr];
            iteration++;
            if (iteration >= ITERATION_LIMIT) {
                return;
            }
        }

        emit NextCycle(cycle, now, getBalance());

        cycle++;
        investorCount = 0;
        lastPayoutDate = now;
        lastDepositDate = now;
        isCycleFinish = false;

        resetLotteryBalance();
        resetStellarBalance();
        resetStellarInvestor();
    }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

library Math {

    struct percent {
        uint percent;
        uint base;
    }

    function getPercentFrom(percent storage p, uint value) internal view returns (uint) {
        return value * p.percent / p.base / 100;
    }

}

library Utils {

    struct winner {
        address addr;
        uint balance;
        uint prize;
        uint date;
    }

}