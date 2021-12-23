/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

/**
 *Submitted for verification at Etherscan.io on 2019-04-10
*/

pragma solidity >0.4.99 <0.6.0;

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


contract TicketsStorage is Accessibility  {
    using SafeMath for uint;

    struct Ticket {
        address payable wallet;
        bool isWinner;
        uint numberTicket;
    }

    uint private entropyNumber = 121;

    mapping (uint => uint) private countTickets;
    // currentRound -> number ticket

    mapping (uint => mapping (uint => Ticket)) private tickets;
    // currentRound -> number ticket -> Ticket

    mapping (uint => mapping (address => uint)) private balancePlayer;
    // currentRound -> wallet -> balance player

    mapping (address => mapping (uint => uint)) private balanceWinner;
    // wallet -> balance winner

    event LogHappyTicket(uint roundLottery, uint happyTicket);

    function checkWinner(uint round, uint numberTicket) public view returns (bool) {
        return tickets[round][numberTicket].isWinner;
    }

    function getBalancePlayer(uint round, address wallet) public view returns (uint) {
        return balancePlayer[round][wallet];
    }

    function ticketInfo(uint round, uint index) public view returns(address payable wallet, bool isWinner, uint numberTicket) {
        Ticket memory ticket = tickets[round][index];
        wallet = ticket.wallet;
        isWinner = ticket.isWinner;
        numberTicket = ticket.numberTicket;
    }

    function newTicket(uint round, address payable wallet, uint priceOfToken) public onlyOwner {
        countTickets[round]++;
        Ticket storage ticket = tickets[round][countTickets[round]];
        ticket.wallet = wallet;
        ticket.numberTicket = countTickets[round];
        balancePlayer[round][wallet] = balancePlayer[round][wallet].add(priceOfToken);
    }

    function clearRound(uint round) public {
        countTickets[round] = 0;
        if (entropyNumber == 330) {
            entropyNumber = 121;
        }
    }

    function getCountTickets(uint round) public view returns (uint) {
        return countTickets[round];
    }

    function addBalanceWinner(uint round, uint amountPrize, uint happyNumber) public onlyOwner {
        address walletTicket = tickets[round][happyNumber].wallet;
        balanceWinner[walletTicket][round] = balanceWinner[walletTicket][round].add(amountPrize);
        tickets[round][happyNumber].isWinner = true;
    }

    function getBalanceWinner(address wallet, uint round) public view returns (uint) {
        return balanceWinner[wallet][round];
    }

    function findHappyNumber(uint round, uint typeStep) public onlyOwner returns(uint) {
        require(countTickets[round] > 0, "number of tickets must be greater than 0");
        uint happyNumber = 0;
        if (typeStep == 3) {
            happyNumber = getRandomNumber(11);
        } else if (typeStep == 1) {
            happyNumber = getRandomNumber(3);
        } else if (typeStep == 2) {
            happyNumber = getRandomNumber(6);
        } else {
            happyNumber = getRandomNumber(2);
        }
        emit LogHappyTicket(round, happyNumber);
        return happyNumber;
    }

    function getRandomNumber(uint step) internal returns(uint) {
        entropyNumber = entropyNumber.add(1);
        uint randomFirst = maxRandom(block.number, msg.sender).div(now);
        uint randomNumber = randomFirst.mul(entropyNumber) % (66);
        randomNumber = randomNumber % step;
        return randomNumber + 1;
    }

    function maxRandom(uint blockn, address entropyAddress) internal view returns (uint randomNumber) {
        return uint(keccak256(
                abi.encodePacked(
                    blockhash(blockn),
                    entropyAddress)
            ));
    }

}

contract SundayLottery is Accessibility {
    using SafeMath for uint;

    using Address for *;
    using Zero for *;

    TicketsStorage private m_tickets;
    mapping (address => bool) private notUnigue;

    enum StepLottery {TWO, THREE, SIX, ELEVEN}
    StepLottery stepLottery;
    uint[] private step = [2, 3, 6, 11];
    uint[] private priceTicket = [0.05 ether, 0.02 ether, 0.01 ether, 0.01 ether];
    uint[] private prizePool = [0.09 ether, 0.05 ether, 0.05 ether, 0.1 ether];

    address payable public administrationWallet;

    uint private canBuyTickets = 0;

    uint public priceOfToken = 0.01 ether;

    uint private amountPrize;

    uint public currentRound;
    uint public totalEthRaised;
    uint public totalTicketBuyed;

    uint public uniquePlayer;

    // more events for easy read from blockchain
    event LogNewTicket(address indexed addr, uint when, uint round, uint price);
    event LogBalanceChanged(uint when, uint balance);
    event LogChangeTime(uint newDate, uint oldDate);
    event LogRefundEth(address indexed player, uint value);
    event LogWinnerDefine(uint roundLottery, address indexed wallet, uint happyNumber);
    event ChangeAddressWallet(address indexed owner, address indexed newAddress, address indexed oldAddress);
    event SendToAdministrationWallet(uint balanceContract);

    modifier balanceChanged {
        _;
        emit LogBalanceChanged(getCurrentDate(), address(this).balance);
    }

    modifier notFromContract() {
        require(msg.sender.isNotContract(), "only externally accounts");
        _;
    }

    constructor(address payable _administrationWallet, uint _step) public {
        require(_administrationWallet != address(0));
        administrationWallet = _administrationWallet;
        //administrationWallet = msg.sender; // for test's
        m_tickets = new TicketsStorage();
        currentRound = 1;
        m_tickets.clearRound(currentRound);
        setStepLottery(_step);
    }

    function() external payable {
        if (msg.value >= priceOfToken) {
            buyTicket(msg.sender);
        } else {
            refundEth(msg.sender, msg.value);
        }
    }

    function buyTicket(address payable _addressPlayer) public payable notFromContract balanceChanged returns (uint buyTickets) {
        uint investment = msg.value;
        require(investment >= priceOfToken, "investment must be >= PRICE OF TOKEN");

        uint tickets = investment.div(priceOfToken);
        if (tickets > canBuyTickets) {
            tickets = canBuyTickets;
            canBuyTickets = 0;
        } else {
            canBuyTickets = canBuyTickets.sub(tickets);
        }

        uint requireEth = tickets.mul(priceOfToken);
        if (investment > requireEth) {
            refundEth(msg.sender, investment.sub(requireEth));
        }

        buyTickets = tickets;
        if (tickets > 0) {
            uint currentDate = now;
            while (tickets != 0) {
                m_tickets.newTicket(currentRound, _addressPlayer, priceOfToken);
                emit LogNewTicket(_addressPlayer, currentDate, currentRound, priceOfToken);
                totalTicketBuyed++;
                tickets--;
            }
        }

        if (!notUnigue[_addressPlayer]) {
            notUnigue[_addressPlayer] = true;
            uniquePlayer++;
        }
        totalEthRaised = totalEthRaised.add(requireEth);

        if (canBuyTickets.isZero()) {
            makeTwists();
        }
    }

    function makeTwists() internal notFromContract {
        play(currentRound);
        sendToAdministration();
        canBuyTickets = step[getStepLottery()];
        currentRound++;
        m_tickets.clearRound(currentRound);
    }

    function play(uint round) internal {
        if (address(this).balance >= amountPrize) {
            uint happyNumber = m_tickets.findHappyNumber(round, getStepLottery());
            m_tickets.addBalanceWinner(currentRound, amountPrize, happyNumber);
            (address payable wallet,,) =  m_tickets.ticketInfo(round, happyNumber);
            wallet.transfer(amountPrize);
            emit LogWinnerDefine(round, wallet, happyNumber);
        }
    }

    function setStepLottery(uint newStep) public onlyOwner {
        require(uint(StepLottery.ELEVEN) >= newStep);
        require(getCountTickets(currentRound) == 0);
        stepLottery = StepLottery(newStep);
        initCanBuyTicket();
    }

    function getStepLottery() public view returns (uint currentStep) {
        currentStep = uint(stepLottery);
    }

    function initCanBuyTicket() internal {
        uint currentStepLottery = getStepLottery();
        canBuyTickets = step[currentStepLottery];
        priceOfToken = priceTicket[currentStepLottery];
        amountPrize = prizePool[currentStepLottery];
    }

    function getTicketInfo(uint round, uint index) public view returns (address payable wallet, bool isWinner, uint numberTicket) {
        (wallet, isWinner, numberTicket) =  m_tickets.ticketInfo(round, index);
    }

    function balanceETH() external view returns(uint) {
        return address(this).balance;
    }

    function refundEth(address payable _player, uint _value) internal returns (bool) {
        require(_player.notZero());
        _player.transfer(_value);
        emit LogRefundEth(_player, _value);
    }

    function getBalancePlayer(uint round, address wallet) external view returns (uint) {
        return m_tickets.getBalancePlayer(round, wallet);
    }

    function getBalanceWinner(address wallet, uint round) external view returns (uint) {
        return m_tickets.getBalanceWinner(wallet, round);
    }

    function checkWinner(uint round, uint numberTicket) public view returns (bool) {
        return m_tickets.checkWinner(round, numberTicket);
    }

    function getCurrentDate() public view returns (uint) {
        return now;
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
        require(administrationWallet != address(0), "address of wallet is 0x0");
        uint amount = address(this).balance;

        if (amount > 0) {
            if (administrationWallet.send(amount)) {
                emit SendToAdministrationWallet(amount);
            }
        }
    }

}