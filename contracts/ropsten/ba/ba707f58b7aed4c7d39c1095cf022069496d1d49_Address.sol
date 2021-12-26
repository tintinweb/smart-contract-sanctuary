/**
 *Submitted for verification at Etherscan.io on 2021-12-26
*/

pragma solidity >0.4.99 <0.6.0;

contract Parameters {

    uint public constant PRICE_OF_TOKEN = 0.01 ether;
    uint public constant MAX_TOKENS_BUY = 80;
    uint public constant MIN_TICKETS_BUY_FOR_ROUND = 80;

    uint public maxNumberStepCircle = 40;

    uint public currentRound;
    uint public totalEthRaised;
    uint public totalTicketBuyed;

    uint public uniquePlayer;

    uint public numberCurrentTwist;

    bool public isTwist;

    bool public isDemo;
    uint public simulateDate;

}

library Zero {
    function requireNotZero(address addr) internal pure {
        require(addr != address(0), "require not zero address");
    }

    function requireNotZero(uint val) internal pure {
        require(val != 0, "require not zero value");
    }

    function notZero(address addr) internal pure returns(bool) {
        return !(addr == address(0));
    }

    function isZero(address addr) internal pure returns(bool) {
        return addr == address(0);
    }

    function isZero(uint a) internal pure returns(bool) {
        return a == 0;
    }

    function notZero(uint a) internal pure returns(bool) {
        return a != 0;
    }
}

library Address {
    function toAddress(bytes memory source) internal pure returns(address addr) {
        assembly { addr := mload(add(source,0x14)) }
        return addr;
    }

    function isNotContract(address addr) internal view returns(bool) {
        uint length;
        assembly { length := extcodesize(addr) }
        return length == 0;
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
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

}

library Percent {
    struct percent {
        uint num;
        uint den;
    }

    function mul(percent storage p, uint a) internal view returns (uint) {
        if (a == 0) {
            return 0;
        }
        return a*p.num/p.den;
    }

    function div(percent storage p, uint a) internal view returns (uint) {
        return a/p.num*p.den;
    }

    function sub(percent storage p, uint a) internal view returns (uint) {
        uint b = mul(p, a);
        if (b >= a) {
            return 0;
        }
        return a - b;
    }

    function add(percent storage p, uint a) internal view returns (uint) {
        return a + mul(p, a);
    }

    function toMemory(percent storage p) internal view returns (Percent.percent memory) {
        return Percent.percent(p.num, p.den);
    }

    function mmul(percent memory p, uint a) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        return a*p.num/p.den;
    }

    function mdiv(percent memory p, uint a) internal pure returns (uint) {
        return a/p.num*p.den;
    }

    function msub(percent memory p, uint a) internal pure returns (uint) {
        uint b = mmul(p, a);
        if (b >= a) {
            return 0;
        }
        return a - b;
    }

    function madd(percent memory p, uint a) internal pure returns (uint) {
        return a + mmul(p, a);
    }
}


contract Accessibility {
    address private owner;
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "access denied");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function changeOwner(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }
}


contract TicketsStorage is Accessibility, Parameters  {
    using SafeMath for uint;
    using Percent for Percent.percent;

    struct Ticket {
        address payable wallet;
        uint winnerRound;
    }

    struct CountWinner {
        uint countWinnerRound_1;
        uint countWinnerRound_2;
        uint countWinnerRound_3;
        uint countWinnerRound_4;
        uint countWinnerRound_5;
    }

    struct PayEachWinner {
        uint payEachWinner_1;
        uint payEachWinner_2;
        uint payEachWinner_3;
        uint payEachWinner_4;
        uint payEachWinner_5;
    }

    uint private stepEntropy = 1;
    uint private precisionPay = 4;

    uint private remainStepTS;
    uint private countStepTS;

    mapping (uint => CountWinner) countWinner;
    // currentRound -> CountWinner

    mapping (uint => PayEachWinner) payEachWinner;
    // currentRound -> PayEachWinner

    mapping (uint => uint) private countTickets;
    // currentRound -> number ticket

    mapping (uint => mapping (uint => Ticket)) private tickets;
    // currentRound -> number ticket -> Ticket

    mapping (uint => mapping (address => uint)) private balancePlayer;
    // currentRound -> wallet -> balance player

    mapping (uint => mapping (address => uint)) private balanceWinner;
    // currentRound -> wallet -> balance winner

    mapping (uint => uint[]) private happyTickets;
    // currentRound -> array happy tickets

    Percent.percent private percentTicketPrize_2 = Percent.percent(1,100);            // 1.0 %
    Percent.percent private percentTicketPrize_3 = Percent.percent(4,100);            // 4.0 %
    Percent.percent private percentTicketPrize_4 = Percent.percent(10,100);            // 10.0 %
    Percent.percent private percentTicketPrize_5 = Percent.percent(35,100);            // 35.0 %

    Percent.percent private percentAmountPrize_1 = Percent.percent(1797,10000);            // 17.97%
    Percent.percent private percentAmountPrize_2 = Percent.percent(1000,10000);            // 10.00%
    Percent.percent private percentAmountPrize_3 = Percent.percent(1201,10000);            // 12.01%
    Percent.percent private percentAmountPrize_4 = Percent.percent(2000,10000);            // 20.00%
    Percent.percent private percentAmountPrize_5 = Percent.percent(3502,10000);            // 35.02%


    event LogMakeDistribution(uint roundLottery, uint roundDistibution, uint countWinnerRound, uint payEachWinner);
    event LogHappyTicket(uint roundLottery, uint roundDistibution, uint happyTicket);

    function isWinner(uint round, uint numberTicket) public view returns (bool) {
        return tickets[round][numberTicket].winnerRound > 0;
    }

    function getBalancePlayer(uint round, address wallet) public view returns (uint) {
        return balancePlayer[round][wallet];
    }

    function getBalanceWinner(uint round, address wallet) public view returns (uint) {
        return balanceWinner[round][wallet];
    }

    function ticketInfo(uint round, uint numberTicket) public view returns(address payable wallet, uint winnerRound) {
        Ticket memory ticket = tickets[round][numberTicket];
        wallet = ticket.wallet;
        winnerRound = ticket.winnerRound;
    }

    function newTicket(uint round, address payable wallet, uint priceOfToken) public onlyOwner {
        countTickets[round]++;
        Ticket storage ticket = tickets[round][countTickets[round]];
        ticket.wallet = wallet;
        balancePlayer[round][wallet] = balancePlayer[round][wallet].add(priceOfToken);
    }

    function clearRound(uint round) public {
        countTickets[round] = 0;
        countWinner[round] = CountWinner(0,0,0,0,0);
        payEachWinner[round] = PayEachWinner(0,0,0,0,0);
        stepEntropy = 1;
        remainStepTS = 0;
        countStepTS = 0;
    }

    function makeDistribution(uint round, uint priceOfToken) public onlyOwner {
        uint count = countTickets[round];
        uint amountEthCurrentRound = count.mul(priceOfToken);

        makeCountWinnerRound(round, count);
        makePayEachWinner(round, amountEthCurrentRound);

        CountWinner memory cw = countWinner[round];
        PayEachWinner memory pw = payEachWinner[round];

        emit LogMakeDistribution(round, 1, cw.countWinnerRound_1, pw.payEachWinner_1);
        emit LogMakeDistribution(round, 2, cw.countWinnerRound_2, pw.payEachWinner_2);
        emit LogMakeDistribution(round, 3, cw.countWinnerRound_3, pw.payEachWinner_3);
        emit LogMakeDistribution(round, 4, cw.countWinnerRound_4, pw.payEachWinner_4);
        emit LogMakeDistribution(round, 5, cw.countWinnerRound_5, pw.payEachWinner_5);

        if (happyTickets[round].length > 0) {
            delete happyTickets[round];
        }
    }

    function makeCountWinnerRound(uint round, uint cntTickets) internal {
        uint cw_1 = 1;
        uint cw_2 = percentTicketPrize_2.mmul(cntTickets);
        uint cw_3 = percentTicketPrize_3.mmul(cntTickets);
        uint cw_4 = percentTicketPrize_4.mmul(cntTickets);
        uint cw_5 = percentTicketPrize_5.mmul(cntTickets);

        countWinner[round] = CountWinner(cw_1, cw_2, cw_3, cw_4, cw_5);
    }

    function makePayEachWinner(uint round, uint amountEth) internal {
        CountWinner memory cw = countWinner[round];

        uint pw_1 = roundEth(percentAmountPrize_1.mmul(amountEth).div(cw.countWinnerRound_1), precisionPay);
        uint pw_2 = roundEth(percentAmountPrize_2.mmul(amountEth).div(cw.countWinnerRound_2), precisionPay);
        uint pw_3 = roundEth(percentAmountPrize_3.mmul(amountEth).div(cw.countWinnerRound_3), precisionPay);
        uint pw_4 = roundEth(percentAmountPrize_4.mmul(amountEth).div(cw.countWinnerRound_4), precisionPay);
        uint pw_5 = roundEth(percentAmountPrize_5.mmul(amountEth).div(cw.countWinnerRound_5), precisionPay);

        payEachWinner[round] = PayEachWinner(pw_1, pw_2, pw_3, pw_4, pw_5);

    }

    function getCountTickets(uint round) public view returns (uint) {
        return countTickets[round];
    }

    function getCountTwist(uint countsTickets, uint maxCountTicketByStep) public returns(uint countTwist) {
        countTwist = countsTickets.div(2).div(maxCountTicketByStep);
        if (countsTickets > countTwist.mul(2).mul(maxCountTicketByStep)) {
            remainStepTS = countsTickets.sub(countTwist.mul(2).mul(maxCountTicketByStep));
            countTwist++;
        }
        countStepTS = countTwist;

    }

    function getMemberArrayHappyTickets(uint round, uint index) public view returns (uint value) {
        value =  happyTickets[round][index];
    }

    function getLengthArrayHappyTickets(uint round) public view returns (uint length) {
        length = happyTickets[round].length;
    }

    function getStepTransfer() public view returns (uint stepTransfer, uint remainTicket) {
        stepTransfer = countStepTS;
        remainTicket = remainStepTS;
    }

    function getCountWinnersDistrib(uint round) public view returns (uint countWinnerRound_1, uint countWinnerRound_2, uint countWinnerRound_3, uint countWinnerRound_4, uint countWinnerRound_5) {
        CountWinner memory cw = countWinner[round];

        countWinnerRound_1 = cw.countWinnerRound_1;
        countWinnerRound_2 = cw.countWinnerRound_2;
        countWinnerRound_3 = cw.countWinnerRound_3;
        countWinnerRound_4 = cw.countWinnerRound_4;
        countWinnerRound_5 = cw.countWinnerRound_5;
    }

    function getPayEachWinnersDistrib(uint round) public view returns (uint payEachWinner_1, uint payEachWinner_2, uint payEachWinner_3, uint payEachWinner_4, uint payEachWinner_5) {
        PayEachWinner memory pw = payEachWinner[round];

        payEachWinner_1 = pw.payEachWinner_1;
        payEachWinner_2 = pw.payEachWinner_2;
        payEachWinner_3 = pw.payEachWinner_3;
        payEachWinner_4 = pw.payEachWinner_4;
        payEachWinner_5 = pw.payEachWinner_5;
    }

    function addBalanceWinner(uint round, uint amountPrize, uint happyNumber) public onlyOwner {
        balanceWinner[round][tickets[round][happyNumber].wallet] = balanceWinner[round][tickets[round][happyNumber].wallet].add(amountPrize);
    }

    function setWinnerRountForTicket(uint round, uint winnerRound, uint happyNumber) public onlyOwner {
        tickets[round][happyNumber].winnerRound = winnerRound;
    }

    //            tickets[round][happyNumber].winnerRound = winnerRound;

    function addHappyNumber(uint round, uint numCurTwist, uint happyNumber) public onlyOwner {
        happyTickets[round].push(happyNumber);
        emit LogHappyTicket(round, numCurTwist, happyNumber);
    }

    function findHappyNumber(uint round) public onlyOwner returns(uint) {
        stepEntropy++;
        uint happyNumber = getRandomNumberTicket(stepEntropy, round);
        while (tickets[round][happyNumber].winnerRound > 0) {
            stepEntropy++;
            happyNumber++;
            if (happyNumber > countTickets[round]) {
                happyNumber = 1;
            }
        }
        return happyNumber;
    }

    function getRandomNumberTicket(uint entropy, uint round) public view returns(uint) {
        require(countTickets[round] > 0, "number of tickets must be greater than 0");
        uint randomFirst = maxRandom(block.number, msg.sender).div(now);
        uint randomNumber = randomFirst.mul(entropy) % (countTickets[round]);
        if (randomNumber == 0) { randomNumber = 1;}
        return randomNumber;
    }

    function random(uint upper, uint blockn, address entropy) internal view returns (uint randomNumber) {
        return maxRandom(blockn, entropy) % upper;
    }

    function maxRandom(uint blockn, address entropy) internal view returns (uint randomNumber) {
        return uint(keccak256(
                abi.encodePacked(
                    blockhash(blockn),
                    entropy)
            ));
    }

    function roundEth(uint numerator, uint precision) internal pure returns(uint round) {
        if (precision > 0 && precision < 18) {
            uint256 _numerator = numerator / 10 ** (18 - precision - 1);
            //            _numerator = (_numerator + 5) / 10;
            _numerator = (_numerator) / 10;
            round = (_numerator) * 10 ** (18 - precision);
        }
    }


}

contract SundayLottery is Accessibility, Parameters {
    using SafeMath for uint;

    using Address for *;
    using Zero for *;

    TicketsStorage private m_tickets;
    mapping (address => bool) private notUnigue;


    address payable public administrationWallet;

    uint private countWinnerRound_1;
    uint private countWinnerRound_2;
    uint private countWinnerRound_3;
    uint private countWinnerRound_4;
    uint private countWinnerRound_5;

    uint private payEachWinner_1;
    uint private payEachWinner_2;
    uint private payEachWinner_3;
    uint private payEachWinner_4;
    uint private payEachWinner_5;

    uint private remainStep;
    uint private countStep;

    // more events for easy read from blockchain
    event LogNewTicket(address indexed addr, uint when, uint round);
    event LogBalanceChanged(uint when, uint balance);
    event LogChangeTime(uint newDate, uint oldDate);
    event LogRefundEth(address indexed player, uint value);
    event LogWinnerDefine(uint roundLottery, uint typeWinner, uint step);
    event ChangeAddressWallet(address indexed owner, address indexed newAddress, address indexed oldAddress);
    event SendToAdministrationWallet(uint balanceContract);
    event Play(uint currentRound, uint numberCurrentTwist);

    modifier balanceChanged {
        _;
        emit LogBalanceChanged(getCurrentDate(), address(this).balance);
    }

    modifier notFromContract() {
        require(msg.sender.isNotContract(), "only externally accounts");
        _;
    }

    constructor(address payable _administrationWallet) public {
        require(_administrationWallet != address(0));
        administrationWallet = _administrationWallet;
        m_tickets = new TicketsStorage();
        currentRound = 1;
        m_tickets.clearRound(currentRound);
    }

    function() external payable {
        if (msg.value >= PRICE_OF_TOKEN) {
            buyTicket(msg.sender);
        } else if (msg.value.isZero()) {
            makeTwists();
        } else {
            refundEth(msg.sender, msg.value);
        }
    }

    function getMemberArrayHappyTickets(uint round, uint index) public view returns (uint value) {
        value =  m_tickets.getMemberArrayHappyTickets(round, index);
    }

    function getLengthArrayHappyTickets(uint round) public view returns (uint length) {
        length =  m_tickets.getLengthArrayHappyTickets(round);
    }

    function getTicketInfo(uint round, uint index) public view returns (address payable wallet, uint winnerRound) {
        (wallet, winnerRound) =  m_tickets.ticketInfo(round, index);
    }

    function getCountWinnersDistrib() public view returns (uint countWinRound_1, uint countWinRound_2,
        uint countWinRound_3, uint countWinRound_4, uint countWinRound_5) {
        (countWinRound_1, countWinRound_2, countWinRound_3,
        countWinRound_4, countWinRound_5) = m_tickets.getCountWinnersDistrib(currentRound);
    }

    function getPayEachWinnersDistrib() public view returns (uint payEachWin_1, uint payEachWin_2,
        uint payEachWin_3, uint payEachWin_4, uint payEachWin_5) {
        (payEachWin_1, payEachWin_2, payEachWin_3,
        payEachWin_4, payEachWin_5) = m_tickets.getPayEachWinnersDistrib(currentRound);
    }

    function getStepTransfer() public view returns (uint stepTransferVal, uint remainTicketVal) {
        (stepTransferVal, remainTicketVal) = m_tickets.getStepTransfer();
    }

    function loadWinnersPerRound() internal {
        (countWinnerRound_1, countWinnerRound_2, countWinnerRound_3,
        countWinnerRound_4, countWinnerRound_5) = getCountWinnersDistrib();
    }

    function loadPayEachWinners() internal {
        (payEachWinner_1, payEachWinner_2, payEachWinner_3,
        payEachWinner_4, payEachWinner_5) = getPayEachWinnersDistrib();
    }

    function loadCountStep() internal {
        (countStep, remainStep) = m_tickets.getStepTransfer();
    }

    function balanceETH() external view returns(uint) {
        return address(this).balance;
    }

    function refundEth(address payable _player, uint _value) internal returns (bool) {
        require(_player.notZero());
        _player.transfer(_value);
        emit LogRefundEth(_player, _value);
    }

    function buyTicket(address payable _addressPlayer) public payable notFromContract balanceChanged {
        uint investment = msg.value;
        require(investment >= PRICE_OF_TOKEN, "investment must be >= PRICE_OF_TOKEN");
        require(!isTwist, "ticket purchase is prohibited during the twist");

        uint tickets = investment.div(PRICE_OF_TOKEN);
        if (tickets > MAX_TOKENS_BUY) {
            tickets = MAX_TOKENS_BUY;
        }
        uint requireEth = tickets.mul(PRICE_OF_TOKEN);
        if (investment > requireEth) {
            refundEth(msg.sender, investment.sub(requireEth));
        }

        if (tickets > 0) {
            uint currentDate = now;
            while (tickets != 0) {
                m_tickets.newTicket(currentRound, _addressPlayer, PRICE_OF_TOKEN);
                emit LogNewTicket(_addressPlayer, currentDate, currentRound);
                currentDate++;
                totalTicketBuyed++;
                tickets--;
            }
        }

        if (!notUnigue[_addressPlayer]) {
            notUnigue[_addressPlayer] = true;
            uniquePlayer++;
        }
        totalEthRaised = totalEthRaised.add(requireEth);
    }

    function makeTwists() public notFromContract {
        uint countTickets = m_tickets.getCountTickets(currentRound);
        require(countTickets > MIN_TICKETS_BUY_FOR_ROUND, "the number of tickets purchased must be >= MIN_TICKETS_BUY_FOR_ROUND");
        require(isSunday(getCurrentDate()), "you can only play on Sunday");
        if (!isTwist) {
            numberCurrentTwist = m_tickets.getCountTwist(countTickets, maxNumberStepCircle);
            m_tickets.makeDistribution(currentRound, PRICE_OF_TOKEN);
            isTwist = true;
            loadWinnersPerRound();
            loadPayEachWinners();
            loadCountStep();
        } else {
            if (numberCurrentTwist > 0) {
                play(currentRound, maxNumberStepCircle);
                emit Play(currentRound, numberCurrentTwist);
                numberCurrentTwist--;
                if (numberCurrentTwist == 0) {
                    isTwist = false;
                    currentRound++;
                    m_tickets.clearRound(currentRound);
                    sendToAdministration();
                }
            }
        }
    }

    function play(uint round, uint maxCountTicketByStep) internal {
        uint countTransfer = 0;
        uint numberTransfer = 0;
        if (remainStep > 0) {
            if (countStep > 1) {
                countTransfer = maxCountTicketByStep;
            } else {
                countTransfer = remainStep;
            }
        } else {
            countTransfer = maxCountTicketByStep;
        }

        if (countStep > 0) {
            if (countWinnerRound_1 > 0 && numberTransfer < countTransfer) {
                if (transferPrize(payEachWinner_1, round, 1)) {
                    countWinnerRound_1--;
                    emit LogWinnerDefine(round, 1, numberTransfer);
                }
                numberTransfer++;
            }
            if (countWinnerRound_2 > 0 && numberTransfer < countTransfer) {
                while (numberTransfer < countTransfer && countWinnerRound_2 > 0) {
                    if (transferPrize(payEachWinner_2, round, 2)) {
                        countWinnerRound_2--;
                        emit LogWinnerDefine(round, 2, numberTransfer);
                    }
                    numberTransfer++;
                }
            }
            if (countWinnerRound_3 > 0 && numberTransfer < countTransfer) {
                while (numberTransfer < countTransfer && countWinnerRound_3 > 0) {
                    if (transferPrize(payEachWinner_3, round, 3)) {
                        countWinnerRound_3--;
                        emit LogWinnerDefine(round, 3, numberTransfer);
                    }
                    numberTransfer++;
                }
            }
            if (countWinnerRound_4 > 0 && numberTransfer < countTransfer) {
                while (numberTransfer < countTransfer && countWinnerRound_4 > 0) {
                    if (transferPrize(payEachWinner_4, round, 4)) {
                        countWinnerRound_4--;
                        emit LogWinnerDefine(round, 4, numberTransfer);
                    }
                    numberTransfer++;
                }
            }
            if (countWinnerRound_5 > 0 && numberTransfer < countTransfer) {
                while (numberTransfer < countTransfer && countWinnerRound_5 > 0) {
                    if (transferPrize(payEachWinner_5, round, 5)) {
                        countWinnerRound_5--;
                        emit LogWinnerDefine(round, 5, numberTransfer);
                    }
                    numberTransfer++;
                }
            }

            countStep--;
        }
    }

    function transferPrize(uint amountPrize, uint round, uint winnerRound) internal returns(bool) {
        if (address(this).balance > amountPrize) {
            uint happyNumber = m_tickets.findHappyNumber(round);
            m_tickets.addHappyNumber(currentRound, numberCurrentTwist, happyNumber);
            m_tickets.addBalanceWinner(currentRound, amountPrize, happyNumber);
            m_tickets.setWinnerRountForTicket(currentRound, winnerRound, happyNumber);
            (address payable wallet, ) =  m_tickets.ticketInfo(round, happyNumber);
            wallet.transfer(amountPrize);
            return true;
        } else {
            return false;
        }
    }

    function setMaxNumberStepCircle(uint256 _number) external onlyOwner {
        require(_number > 0);
        maxNumberStepCircle = _number;
    }

    function getBalancePlayer(uint round, address wallet) external view returns (uint) {
        return m_tickets.getBalancePlayer(round, wallet);
    }

    function getBalanceWinner(uint round, address wallet) external view returns (uint) {
        return m_tickets.getBalanceWinner(round, wallet);
    }

    function getCurrentDate() public view returns (uint) {
        if (isDemo) {
            return simulateDate;
        }
        return now;
    }

    function setSimulateDate(uint _newDate) external onlyOwner {
        if (isDemo) {
            require(_newDate > simulateDate);
            emit LogChangeTime(_newDate, simulateDate);
            simulateDate = _newDate;
        }
    }

    function setDemo() external onlyOwner {
        if (uniquePlayer == 0) {
            isDemo = true;
        }
    }

    function isSunday(uint timestamp) public pure returns (bool) {
        uint numberDay = (timestamp / (1 days) + 4) % 7;
        if (numberDay == 0) {
            return true;
        } else {
            return false;
        }
    }

    function getCountTickets(uint round) public view returns (uint countTickets) {
        countTickets = m_tickets.getCountTickets(round);
    }

    function setAdministrationWallet(address payable _newWallet) external onlyOwner {
        require(_newWallet != address(0));
        address payable _oldWallet = administrationWallet;
        administrationWallet = _newWallet;
        emit ChangeAddressWallet(msg.sender, _newWallet, _oldWallet);
    }

    function sendToAdministration() internal {
        require(administrationWallet != address(0), "wallet address is not 0");
        uint amount = address(this).balance;

        if (amount > 0) {
            if (administrationWallet.send(amount)) {
                emit SendToAdministrationWallet(amount);
            }
        }
    }

}