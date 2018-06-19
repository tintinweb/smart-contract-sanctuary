pragma solidity ^0.4.13;

contract EthereumLottery {
    function admin() constant returns (address);
    function needsInitialization() constant returns (bool);
    function initLottery(uint _jackpot, uint _numTickets,
                         uint _ticketPrice, int _durationInBlocks) payable;
    function needsFinalization() constant returns (bool);
    function finalizeLottery(uint _steps);
}

contract LotteryAdmin {
    address public owner;
    address public admin;
    address public proposedOwner;

    address public ethereumLottery;

    uint public dailyAdminAllowance;
    uint public maximumAdminBalance;
    uint public maximumJackpot;
    int public minimumDurationInBlocks;

    uint public lastAllowancePaymentTimestamp;
    uint public nextProfile;

    event Deposit(address indexed _from, uint _value);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdminOrOwner {
        require(msg.sender == owner || msg.sender == admin);
        _;
    }

    function LotteryAdmin(address _ethereumLottery) {
        owner = msg.sender;
        admin = msg.sender;
        ethereumLottery = _ethereumLottery;

        dailyAdminAllowance = 50 finney;
        maximumAdminBalance = 1 ether;
        maximumJackpot = 100 ether;
        minimumDurationInBlocks = 60;
    }

    function () payable {
        Deposit(msg.sender, msg.value);
    }

    function needsAllowancePayment() constant returns (bool) {
        return now - lastAllowancePaymentTimestamp >= 24 hours &&
               admin.balance < maximumAdminBalance;
    }

    function needsAdministration() constant returns (bool) {
        if (EthereumLottery(ethereumLottery).admin() != address(this)) {
            return false;
        }

        return needsAllowancePayment() ||
               EthereumLottery(ethereumLottery).needsFinalization();
    }

    function administrate(uint _steps) onlyAdminOrOwner {
        if (needsAllowancePayment()) {
            lastAllowancePaymentTimestamp = now;
            admin.transfer(dailyAdminAllowance);
        } else {
            EthereumLottery(ethereumLottery).finalizeLottery(_steps);
        }
    }

    function needsInitialization() constant returns (bool) {
        if (EthereumLottery(ethereumLottery).admin() != address(this)) {
            return false;
        }

        return EthereumLottery(ethereumLottery).needsInitialization();
    }

    function initLottery(uint _nextProfile,
                         uint _jackpot, uint _numTickets,
                         uint _ticketPrice, int _durationInBlocks)
             onlyAdminOrOwner {
        require(_jackpot <= maximumJackpot);
        require(_durationInBlocks >= minimumDurationInBlocks);

        nextProfile = _nextProfile;
        EthereumLottery(ethereumLottery).initLottery.value(_jackpot)(
            _jackpot, _numTickets, _ticketPrice, _durationInBlocks);
    }

    function withdraw(uint _value) onlyOwner {
        owner.transfer(_value);
    }

    function setConfiguration(uint _dailyAdminAllowance,
                              uint _maximumAdminBalance,
                              uint _maximumJackpot,
                              int _minimumDurationInBlocks)
             onlyOwner {
        dailyAdminAllowance = _dailyAdminAllowance;
        maximumAdminBalance = _maximumAdminBalance;
        maximumJackpot = _maximumJackpot;
        minimumDurationInBlocks = _minimumDurationInBlocks;
    }

    function setLottery(address _ethereumLottery) onlyOwner {
        ethereumLottery = _ethereumLottery;
    }

    function setAdmin(address _admin) onlyOwner {
        admin = _admin;
    }

    function proposeOwner(address _owner) onlyOwner {
        proposedOwner = _owner;
    }

    function acceptOwnership() {
        require(proposedOwner != 0);
        require(msg.sender == proposedOwner);
        owner = proposedOwner;
    }

    function destruct() onlyOwner {
        selfdestruct(owner);
    }
}