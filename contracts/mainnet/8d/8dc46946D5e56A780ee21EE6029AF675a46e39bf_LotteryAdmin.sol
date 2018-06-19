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
    }

    function () payable {
        Deposit(msg.sender, msg.value);
    }

    function needsAdministration() constant returns (bool) {
        if (EthereumLottery(ethereumLottery).admin() != address(this)) {
            return false;
        }

        return EthereumLottery(ethereumLottery).needsFinalization();
    }

    function administrate(uint _steps) {
        EthereumLottery(ethereumLottery).finalizeLottery(_steps);
    }

    function initLottery(uint _jackpot, uint _numTickets,
                         uint _ticketPrice, int _durationInBlocks)
             onlyAdminOrOwner {
        EthereumLottery(ethereumLottery).initLottery.value(_jackpot)(
            _jackpot, _numTickets, _ticketPrice, _durationInBlocks);
    }

    function withdraw(uint _value) onlyOwner {
        owner.transfer(_value);
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