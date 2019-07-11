/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity ^0.5.0;

/**
 * (E)t)h)e)x) Loto Contract 
 *  This smart-contract is the part of Ethex Lottery fair game.
 *  See latest version at https://github.com/ethex-bet/ethex-contacts 
 *  http://ethex.bet
 */


/**
 * (E)t)h)e)x) Jackpot Contract 
 *  This smart-contract is the part of Ethex Lottery fair game.
 *  See latest version at https://github.com/ethex-bet/ethex-contracts 
 *  http://ethex.bet
 */

contract EthexJackpot {
    mapping(uint256 => address payable) public tickets;
    uint256 public numberEnd;
    uint256 public firstNumber;
    uint256 public dailyAmount;
    uint256 public weeklyAmount;
    uint256 public monthlyAmount;
    uint256 public seasonalAmount;
    bool public dailyProcessed;
    bool public weeklyProcessed;
    bool public monthlyProcessed;
    bool public seasonalProcessed;
    address payable private owner;
    address public lotoAddress;
    address payable public newVersionAddress;
    EthexJackpot previousContract;
    uint256 public dailyNumberStartPrev;
    uint256 public weeklyNumberStartPrev;
    uint256 public monthlyNumberStartPrev;
    uint256 public seasonalNumberStartPrev;
    uint256 public dailyStart;
    uint256 public weeklyStart;
    uint256 public monthlyStart;
    uint256 public seasonalStart;
    uint256 public dailyEnd;
    uint256 public weeklyEnd;
    uint256 public monthlyEnd;
    uint256 public seasonalEnd;
    uint256 public dailyNumberStart;
    uint256 public weeklyNumberStart;
    uint256 public monthlyNumberStart;
    uint256 public seasonalNumberStart;
    uint256 public dailyNumberEndPrev;
    uint256 public weeklyNumberEndPrev;
    uint256 public monthlyNumberEndPrev;
    uint256 public seasonalNumberEndPrev;
    
    event Jackpot (
        uint256 number,
        uint256 count,
        uint256 amount,
        byte jackpotType
    );
    
    event Ticket (
        bytes16 indexed id,
        uint256 number
    );
    
    event Superprize (
        uint256 amount,
        address winner
    );
    
    uint256 constant DAILY = 5000;
    uint256 constant WEEKLY = 35000;
    uint256 constant MONTHLY = 150000;
    uint256 constant SEASONAL = 450000;
    uint256 constant PRECISION = 1 ether;
    uint256 constant DAILY_PART = 84;
    uint256 constant WEEKLY_PART = 12;
    uint256 constant MONTHLY_PART = 3;
    
    constructor() public payable {
        owner = msg.sender;
    }
    
    function() external payable { }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyOwnerOrNewVersion {
        require(msg.sender == owner || msg.sender == newVersionAddress);
        _;
    }
    
    modifier onlyLoto {
        require(msg.sender == lotoAddress, "Loto only");
        _;
    }
    
    function migrate() external onlyOwnerOrNewVersion {
        newVersionAddress.transfer(address(this).balance);
    }

    function registerTicket(bytes16 id, address payable gamer) external onlyLoto {
        uint256 number = numberEnd + 1;
        if (block.number >= dailyEnd) {
            setDaily();
            dailyNumberStart = number;
        }
        else
            if (dailyNumberStart == dailyNumberStartPrev)
                dailyNumberStart = number;
        if (block.number >= weeklyEnd) {
            setWeekly();
            weeklyNumberStart = number;
        }
        else
            if (weeklyNumberStart == weeklyNumberStartPrev)
                weeklyNumberStart = number;
        if (block.number >= monthlyEnd) {
            setMonthly();
            monthlyNumberStart = number;
        }
        else
            if (monthlyNumberStart == monthlyNumberStartPrev)
                monthlyNumberStart = number;
        if (block.number >= seasonalEnd) {
            setSeasonal();
            seasonalNumberStart = number;
        }
        else
            if (seasonalNumberStart == seasonalNumberStartPrev)
                seasonalNumberStart = number;
        numberEnd = number;
        tickets[number] = gamer;
        emit Ticket(id, number);
    }
    
    function setLoto(address loto) external onlyOwner {
        lotoAddress = loto;
    }
    
    function setNewVersion(address payable newVersion) external onlyOwner {
        newVersionAddress = newVersion;
    }
    
    function payIn() external payable {
        uint256 distributedAmount = dailyAmount + weeklyAmount + monthlyAmount + seasonalAmount;
        if (distributedAmount < address(this).balance) {
            uint256 amount = (address(this).balance - distributedAmount) / 4;
            dailyAmount += amount;
            weeklyAmount += amount;
            monthlyAmount += amount;
            seasonalAmount += amount;
        }
    }

    function processJackpots(bytes32 hash) private {
        uint48 modulo = uint48(bytes6(hash << 29));
        
        uint256 dailyPayAmount;
        uint256 weeklyPayAmount;
        uint256 monthlyPayAmount;
        uint256 seasonalPayAmount;
        uint256 dailyWin;
        uint256 weeklyWin;
        uint256 monthlyWin;
        uint256 seasonalWin;
        if (dailyProcessed == false) {
            dailyPayAmount = dailyAmount * PRECISION / DAILY_PART / PRECISION;
            dailyAmount -= dailyPayAmount;
            dailyProcessed = true;
            dailyWin = getNumber(dailyNumberStartPrev, dailyNumberEndPrev, modulo);
            emit Jackpot(dailyWin, dailyNumberEndPrev - dailyNumberStartPrev + 1, dailyPayAmount, 0x01);
        }
        if (weeklyProcessed == false) {
            weeklyPayAmount = weeklyAmount * PRECISION / WEEKLY_PART / PRECISION;
            weeklyAmount -= weeklyPayAmount;
            weeklyProcessed = true;
            weeklyWin = getNumber(weeklyNumberStartPrev, weeklyNumberEndPrev, modulo);
            emit Jackpot(weeklyWin, weeklyNumberEndPrev - weeklyNumberStartPrev + 1, weeklyPayAmount, 0x02);
        }
        if (monthlyProcessed == false) {
            monthlyPayAmount = monthlyAmount * PRECISION / MONTHLY_PART / PRECISION;
            monthlyAmount -= monthlyPayAmount;
            monthlyProcessed = true;
            monthlyWin = getNumber(monthlyNumberStartPrev, monthlyNumberEndPrev, modulo);
            emit Jackpot(monthlyWin, monthlyNumberEndPrev - monthlyNumberStartPrev + 1, monthlyPayAmount, 0x04);
        }
        if (seasonalProcessed == false) {
            seasonalPayAmount = seasonalAmount;
            seasonalAmount -= seasonalPayAmount;
            seasonalProcessed = true;
            seasonalWin = getNumber(seasonalNumberStartPrev, seasonalNumberEndPrev, modulo);
            emit Jackpot(seasonalWin, seasonalNumberEndPrev - seasonalNumberStartPrev + 1, seasonalPayAmount, 0x08);
        }
        if (dailyPayAmount > 0)
            getAddress(dailyWin).transfer(dailyPayAmount);
        if (weeklyPayAmount > 0)
            getAddress(weeklyWin).transfer(weeklyPayAmount);
        if (monthlyPayAmount > 0)
            getAddress(monthlyWin).transfer(monthlyPayAmount);
        if (seasonalPayAmount > 0)
            getAddress(seasonalWin).transfer(seasonalPayAmount);
    }
    
    function settleJackpot() external {
        if (block.number >= dailyEnd)
            setDaily();
        if (block.number >= weeklyEnd)
            setWeekly();
        if (block.number >= monthlyEnd)
            setMonthly();
        if (block.number >= seasonalEnd)
            setSeasonal();
        
        if (block.number == dailyStart || (dailyStart < block.number - 256))
            return;
        
        processJackpots(blockhash(dailyStart));
    }

    function settleMissedJackpot(bytes32 hash) external onlyOwner {
        if (block.number >= dailyEnd)
            setDaily();
        if (block.number >= weeklyEnd)
            setWeekly();
        if (block.number >= monthlyEnd)
            setMonthly();
        if (block.number >= seasonalEnd)
            setSeasonal();
        
        if (dailyStart < block.number - 256)
            processJackpots(hash);
    }
    
    function paySuperprize(address payable winner) external onlyLoto {
        uint256 superprizeAmount = dailyAmount + weeklyAmount + monthlyAmount + seasonalAmount;
        dailyAmount = 0;
        weeklyAmount = 0;
        monthlyAmount = 0;
        seasonalAmount = 0;
        emit Superprize(superprizeAmount, winner);
        winner.transfer(superprizeAmount);
    }
    
    function setOldVersion(address payable oldAddress) external onlyOwner {
        previousContract = EthexJackpot(oldAddress);
        dailyStart = previousContract.dailyStart();
        dailyEnd = previousContract.dailyEnd();
        dailyProcessed = previousContract.dailyProcessed();
        weeklyStart = previousContract.weeklyStart();
        weeklyEnd = previousContract.weeklyEnd();
        weeklyProcessed = previousContract.weeklyProcessed();
        monthlyStart = previousContract.monthlyStart();
        monthlyEnd = previousContract.monthlyEnd();
        monthlyProcessed = previousContract.monthlyProcessed();
        seasonalStart = previousContract.seasonalStart();
        seasonalEnd = previousContract.seasonalEnd();
        seasonalProcessed = previousContract.seasonalProcessed();
        dailyNumberStartPrev = previousContract.dailyNumberStartPrev();
        weeklyNumberStartPrev = previousContract.weeklyNumberStartPrev();
        monthlyNumberStartPrev = previousContract.monthlyNumberStartPrev();
        seasonalNumberStartPrev = previousContract.seasonalNumberStartPrev();
        dailyNumberStart = previousContract.dailyNumberStart();
        weeklyNumberStart = previousContract.weeklyNumberStart();
        monthlyNumberStart = previousContract.monthlyNumberStart();
        seasonalNumberStart = previousContract.seasonalNumberStart();
        dailyNumberEndPrev = previousContract.dailyNumberEndPrev();
        weeklyNumberEndPrev = previousContract.weeklyNumberEndPrev();
        monthlyNumberEndPrev = previousContract.monthlyNumberEndPrev();
        seasonalNumberEndPrev = previousContract.seasonalNumberEndPrev();
        numberEnd = previousContract.numberEnd();
        dailyAmount = previousContract.dailyAmount();
        weeklyAmount = previousContract.weeklyAmount();
        monthlyAmount = previousContract.monthlyAmount();
        seasonalAmount = previousContract.seasonalAmount();
        firstNumber = numberEnd;
        previousContract.migrate();
    }
    
    function getAddress(uint256 number) public returns (address payable) {
        if (number <= firstNumber)
            return previousContract.getAddress(number);
        return tickets[number];
    }
    
    function setDaily() private {
        dailyProcessed = dailyNumberEndPrev == numberEnd;
        dailyStart = dailyEnd;
        dailyEnd = dailyStart + DAILY;
        dailyNumberStartPrev = dailyNumberStart;
        dailyNumberEndPrev = numberEnd;
    }
    
    function setWeekly() private {
        weeklyProcessed = weeklyNumberEndPrev == numberEnd;
        weeklyStart = weeklyEnd;
        weeklyEnd = weeklyStart + WEEKLY;
        weeklyNumberStartPrev = weeklyNumberStart;
        weeklyNumberEndPrev = numberEnd;
    }
    
    function setMonthly() private {
        monthlyProcessed = monthlyNumberEndPrev == numberEnd;
        monthlyStart = monthlyEnd;
        monthlyEnd = monthlyStart + MONTHLY;
        monthlyNumberStartPrev = monthlyNumberStart;
        monthlyNumberEndPrev = numberEnd;
    }
    
    function setSeasonal() private {
        seasonalProcessed = seasonalNumberEndPrev == numberEnd;
        seasonalStart = seasonalEnd;
        seasonalEnd = seasonalStart + SEASONAL;
        seasonalNumberStartPrev = seasonalNumberStart;
        seasonalNumberEndPrev = numberEnd;
    }
    
    function getNumber(uint256 startNumber, uint256 endNumber, uint48 modulo) pure private returns (uint256) {
        return startNumber + modulo % (endNumber - startNumber + 1);
    }
}

/**
 * (E)t)h)e)x) House Contract 
 *  This smart-contract is the part of Ethex Lottery fair game.
 *  See latest version at https://github.com/ethex-bet/ethex-contracts 
 *  http://ethex.bet
 */
 
 contract EthexHouse {
     address payable private owner;
     
     constructor() public {
         owner = msg.sender;
     }
     
     modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function payIn() external payable {
    }
    
    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }
 }

/**
 * (E)t)h)e)x) Superprize Contract 
 *  This smart-contract is the part of Ethex Lottery fair game.
 *  See latest version at https://github.com/ethex-bet/ethex-lottery 
 *  http://ethex.bet
 */
 
 contract EthexSuperprize {
    struct Payout {
        uint256 index;
        uint256 amount;
        uint256 block;
        address payable winnerAddress;
        bytes16 betId;
    }
     
    Payout[] public payouts;
     
    address payable private owner;
    address public lotoAddress;
    address payable public newVersionAddress;
    EthexSuperprize previousContract;
    uint256 public hold;
    
    event Superprize (
        uint256 index,
        uint256 amount,
        address winner,
        bytes16 betId,
        byte state
    );
    
    uint8 constant PARTS = 6;
    uint256 constant PRECISION = 1 ether;
    uint256 constant MONTHLY = 150000;
     
    constructor() public {
        owner = msg.sender;
    }
     
     modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function() external payable { }
    
    function initSuperprize(address payable winner, bytes16 betId) external {
        require(msg.sender == lotoAddress);
        uint256 amount = address(this).balance - hold;
        hold = address(this).balance;
        uint256 sum;
        uint256 temp;
        for (uint256 i = 1; i < PARTS; i++) {
            temp = amount * PRECISION * (i - 1 + 10) / 75 / PRECISION;
            sum += temp;
            payouts.push(Payout(i, temp, block.number + i * MONTHLY, winner, betId));
        }
        payouts.push(Payout(PARTS, amount - sum, block.number + PARTS * MONTHLY, winner, betId));
        emit Superprize(0, amount, winner, betId, 0);
    }
    
    function paySuperprize() external onlyOwner {
        if (payouts.length == 0)
            return;
        Payout[] memory payoutArray = new Payout[](payouts.length);
        uint i = payouts.length;
        while (i > 0) {
            i--;
            if (payouts[i].block <= block.number) {
                emit Superprize(payouts[i].index, payouts[i].amount, payouts[i].winnerAddress, payouts[i].betId, 0x01);
                hold -= payouts[i].amount;
            }
            payoutArray[i] = payouts[i];
            payouts.pop();
        }
        for (i = 0; i < payoutArray.length; i++)
            if (payoutArray[i].block > block.number)
                payouts.push(payoutArray[i]);
        for (i = 0; i < payoutArray.length; i++)
            if (payoutArray[i].block <= block.number)
                payoutArray[i].winnerAddress.transfer(payoutArray[i].amount);
    }
     
    function setOldVersion(address payable oldAddress) external onlyOwner {
        previousContract = EthexSuperprize(oldAddress);
        lotoAddress = previousContract.lotoAddress();
        hold = previousContract.hold();
        uint256 index;
        uint256 amount;
        uint256 betBlock;
        address payable winner;
        bytes16 betId;
        for (uint i = 0; i < previousContract.getPayoutsCount(); i++) {
            (index, amount, betBlock, winner, betId) = previousContract.payouts(i);
            payouts.push(Payout(index, amount, betBlock, winner, betId));
        }
        previousContract.migrate();
    }
    
    function setNewVersion(address payable newVersion) external onlyOwner {
        newVersionAddress = newVersion;
    }
    
    function setLoto(address loto) external onlyOwner {
        lotoAddress = loto;
    }
    
    function migrate() external {
        require(msg.sender == owner || msg.sender == newVersionAddress);
        require(newVersionAddress != address(0));
        newVersionAddress.transfer(address(this).balance);
    }   

    function getPayoutsCount() view public returns (uint256) {
        return payouts.length;
    }
}

contract EthexLoto {
    struct Bet {
        uint256 blockNumber;
        uint256 amount;
        bytes16 id;
        bytes6 bet;
        address payable gamer;
    }
    
    struct Transaction {
        uint256 amount;
        address payable gamer;
    }
    
    struct Superprize {
        uint256 amount;
        bytes16 id;
    }
    
    mapping(uint256 => uint256) public blockNumberQueue;
    mapping(uint256 => uint256) public amountQueue;
    mapping(uint256 => bytes16) public idQueue;
    mapping(uint256 => bytes6) public betQueue;
    mapping(uint256 => address payable) public gamerQueue;
    uint256 public first = 2;
    uint256 public last = 1;
    uint256 public holdBalance;
    
    address payable public jackpotAddress;
    address payable public houseAddress;
    address payable public superprizeAddress;
    address payable private owner;

    event PayoutBet (
        uint256 amount,
        bytes16 id,
        address gamer
    );
    
    event RefundBet (
        uint256 amount,
        bytes16 id,
        address gamer
    );
    
    uint8 constant N = 16;
    uint256 constant MIN_BET = 0.01 ether;
    uint256 constant PRECISION = 1 ether;
    uint256 constant JACKPOT_PERCENT = 10;
    uint256 constant HOUSE_EDGE = 10;
    
    constructor(address payable jackpot, address payable house, address payable superprize) public payable {
        owner = msg.sender;
        jackpotAddress = jackpot;
        houseAddress = house;
        superprizeAddress = superprize;
    }
    
    function() external payable { }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function placeBet(bytes22 params) external payable {
        require(msg.value >= MIN_BET, "Bet amount should be greater or equal than minimal amount");
        require(bytes16(params) != 0, "Id should not be 0");
        
        bytes16 id = bytes16(params);
        bytes6 bet = bytes6(params << 128);
        
        uint256 coefficient = 0;
        uint8 markedCount = 0;
        uint256 holdAmount = 0;
        uint256 jackpotFee = msg.value * JACKPOT_PERCENT * PRECISION / 100 / PRECISION;
        uint256 houseEdgeFee = msg.value * HOUSE_EDGE * PRECISION / 100 / PRECISION;
        uint256 betAmount = msg.value - jackpotFee - houseEdgeFee;
        
        (coefficient, markedCount, holdAmount) = getHold(betAmount, bet);
        
        require(msg.value * (100 - JACKPOT_PERCENT - HOUSE_EDGE) * (coefficient * 8 - 15 * markedCount) <= 9000 ether * markedCount);
        
        require(
            msg.value * (800 * coefficient - (JACKPOT_PERCENT + HOUSE_EDGE) * (coefficient * 8 + 15 * markedCount)) <= 1500 * markedCount * (address(this).balance - holdBalance));
        
        holdBalance += holdAmount;
        
        enqueue(block.number, betAmount, id, bet, msg.sender);
        
        if (markedCount > 1)
            EthexJackpot(jackpotAddress).registerTicket(id, msg.sender);
        
        EthexHouse(houseAddress).payIn.value(houseEdgeFee)();
        EthexJackpot(jackpotAddress).payIn.value(jackpotFee)();
    }
    
    function settleBets() external {
        if (first > last)
            return;
        uint256 i = 0;
        uint256 length = last - first + 1;
        length = length > 10 ? 10 : length;
        Transaction[] memory transactions = new Transaction[](length);
        Superprize[] memory superprizes = new Superprize[](length);
        uint256 balance = address(this).balance - holdBalance;
        
        for(; i < length; i++) {
            Bet memory bet = dequeue();
            if (bet.blockNumber >= block.number) {
                length = i;
                break;
            }
            else {
                uint256 coefficient = 0;
                uint8 markedCount = 0;
                uint256 holdAmount = 0;
                (coefficient, markedCount, holdAmount) = getHold(bet.amount, bet.bet);
                holdBalance -= holdAmount;
                balance += holdAmount;
                if (bet.blockNumber < block.number - 256) {
                    transactions[i] = Transaction(bet.amount, bet.gamer);
                    emit RefundBet(bet.amount, bet.id, bet.gamer);
                    balance -= bet.amount;
                }
                else {
                    bytes32 blockHash = blockhash(bet.blockNumber);
                    coefficient = 0;
                    uint8 matchesCount;
                    bool isSuperPrize = true;
                    for (uint8 j = 0; j < bet.bet.length; j++) {
                        if (bet.bet[j] > 0x13) {
                            isSuperPrize = false;
                            continue;
                        }
                        byte field;
                        if (j % 2 == 0)
                            field = blockHash[29 + j / 2] >> 4;
                        else
                            field = blockHash[29 + j / 2] & 0x0F;
                        if (bet.bet[j] < 0x10) {
                            if (field == bet.bet[j]) {
                                matchesCount++;
                                coefficient += 30;
                            }
                            else
                                isSuperPrize = false;
                            continue;
                        }
                        else
                            isSuperPrize = false;
                        if (bet.bet[j] == 0x10) {
                            if (field > 0x09 && field < 0x10) {
                                matchesCount++;
                                coefficient += 5;
                            }
                            continue;
                        }
                        if (bet.bet[j] == 0x11) {
                            if (field < 0x0A) {
                                matchesCount++;
                                coefficient += 3;
                            }
                            continue;
                        }
                        if (bet.bet[j] == 0x12) {
                            if (field < 0x0A && field & 0x01 == 0x01) {
                                matchesCount++;
                                coefficient += 6;
                            }
                            continue;
                        }
                        if (bet.bet[j] == 0x13) {
                            if (field < 0x0A && field & 0x01 == 0x0) {
                                matchesCount++;
                                coefficient += 6;
                            }
                            continue;
                        }
                    }
                
                    if (matchesCount == 0) 
                        coefficient = 0;
                    else                    
                        coefficient *= PRECISION * 8;
                        
                    uint256 payoutAmount = bet.amount * coefficient / (PRECISION * 15 * markedCount);
                    if (payoutAmount == 0 && matchesCount > 0)
                        payoutAmount = matchesCount;
                    transactions[i] = Transaction(payoutAmount, bet.gamer);
                    emit PayoutBet(payoutAmount, bet.id, bet.gamer);
                    balance -= payoutAmount;
                    
                    if (isSuperPrize == true) {
                        superprizes[i].amount = balance;
                        superprizes[i].id = bet.id;
                        balance = 0;
                    }
                }
            }
        }
        
        for (i = 0; i < length; i++) {
            transactions[i].gamer.transfer(transactions[i].amount);
            if (superprizes[i].id != 0) {
                EthexSuperprize(superprizeAddress).initSuperprize(transactions[i].gamer, superprizes[i].id);
                EthexJackpot(jackpotAddress).paySuperprize(transactions[i].gamer);
                transactions[i].gamer.transfer(superprizes[i].amount);
            }
        }
    }
    
    function migrate(address payable newContract) external onlyOwner {
        newContract.transfer(address(this).balance);
    }

    function setJackpot(address payable jackpot) external onlyOwner {
        jackpotAddress = jackpot;
    }
    
    function setSuperprize(address payable superprize) external onlyOwner {
        superprizeAddress = superprize;
    }
    
    function length() public view returns (uint256) {
        return 1 + last - first;
    }
    
    function enqueue(uint256 blockNumber, uint256 amount, bytes16 id, bytes6 bet, address payable gamer) internal {
        last += 1;
        blockNumberQueue[last] = blockNumber;
        amountQueue[last] = amount;
        idQueue[last] = id;
        betQueue[last] = bet;
        gamerQueue[last] = gamer;
    }

    function dequeue() internal returns (Bet memory bet) {
        require(last >= first);

        bet = Bet(blockNumberQueue[first], amountQueue[first], idQueue[first], betQueue[first], gamerQueue[first]);

        delete blockNumberQueue[first];
        delete amountQueue[first];
        delete idQueue[first];
        delete betQueue[first];
        delete gamerQueue[first];
        
        if (first == last) {
            first = 2;
            last = 1;
        }
        else
            first += 1;
    }
    
    function getHold(uint256 amount, bytes6 bet) internal pure returns (uint256 coefficient, uint8 markedCount, uint256 holdAmount) {
        for (uint8 i = 0; i < bet.length; i++) {
            if (bet[i] > 0x13)
                continue;
            markedCount++;
            if (bet[i] < 0x10) {
                coefficient += 30;
                continue;
            }
            if (bet[i] == 0x10) {
                coefficient += 5;
                continue;
            }
            if (bet[i] == 0x11) {
                coefficient += 3;
                continue;
            }
            if (bet[i] == 0x12) {
                coefficient += 6;
                continue;
            }
            if (bet[i] == 0x13) {
                coefficient += 6;
                continue;
            }
        }
        holdAmount = amount * (100 - JACKPOT_PERCENT - HOUSE_EDGE) * coefficient * 2 / 375 / markedCount;
    }
}