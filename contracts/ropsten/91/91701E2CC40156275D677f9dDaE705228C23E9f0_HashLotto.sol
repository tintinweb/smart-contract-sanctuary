pragma solidity 0.4.24;

contract HashLotto {

    struct Ticket {
        bytes32 myGuess;
        uint atBlockNumber;
    }
    mapping (address => Ticket) public tickets;

    event LogToldYouSo(address indexed who, bytes32 braggingRights);

    constructor() public payable {
    }

    function markMyWord(bytes32 myGuess, uint32 ahead) public payable {
        require(0.1 ether <= msg.value);
        require(0 < ahead);
        tickets[msg.sender] = Ticket({
            myGuess: myGuess,
            atBlockNumber: block.number + ahead
        });
    }

    function toldYouSo(bytes32 braggingRights) public {
        Ticket storage myTicket = tickets[msg.sender];
        uint atBlockNumber = myTicket.atBlockNumber;
        require(0 < atBlockNumber);
        require(atBlockNumber < block.number);
        require(myTicket.myGuess == blockhash(atBlockNumber));
        emit LogToldYouSo(msg.sender, braggingRights);
        delete tickets[msg.sender];
        msg.sender.transfer(address(this).balance);
    }

    function() public {
    }
}