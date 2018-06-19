pragma solidity ^0.4.15;

contract EthereumLottery {
    function admin() constant returns (address);
    function needsInitialization() constant returns (bool);
    function initLottery(uint _jackpot, uint _numTickets, uint _ticketPrice);
}

contract LotteryAdmin {
    address public owner;
    address public admin;
    address public proposedOwner;

    address public ethereumLottery;

    uint public dailyAdminAllowance;

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
    }

    function () payable {
        Deposit(msg.sender, msg.value);
    }

    function allowsAllowance() constant returns (bool) {
        return now - lastAllowancePaymentTimestamp >= 24 hours;
    }

    function requestAllowance() onlyAdminOrOwner {
        require(allowsAllowance());

        lastAllowancePaymentTimestamp = now;
        admin.transfer(dailyAdminAllowance);
    }

    function needsInitialization() constant returns (bool) {
        if (EthereumLottery(ethereumLottery).admin() != address(this)) {
            return false;
        }

        return EthereumLottery(ethereumLottery).needsInitialization();
    }

    function initLottery(uint _nextProfile, uint _jackpot,
                         uint _numTickets, uint _ticketPrice)
             onlyAdminOrOwner {
        nextProfile = _nextProfile;
        EthereumLottery(ethereumLottery).initLottery(
            _jackpot, _numTickets, _ticketPrice);
    }

    function withdraw(uint _value) onlyOwner {
        owner.transfer(_value);
    }

    function setConfiguration(uint _dailyAdminAllowance) onlyOwner {
        dailyAdminAllowance = _dailyAdminAllowance;
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