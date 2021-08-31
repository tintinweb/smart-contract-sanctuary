/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

pragma solidity ^0.4.19;

contract Lottery {

    enum TicketType { Full, Half, Quarter }

    struct Ticket {
        address owner;
        uint hash;
        TicketType ticketType;
        uint number; // randomly generated number
        bool submitted;
    }

    Ticket[] public tickets; // submitted tickets
    mapping (uint => Ticket) public ticketMap; // hash => Ticket

    uint public period; // how many blocks each round is
    uint public lastStartBlock; // starting block of the current round
    uint public reward; // total reward collected from tickets

    mapping(address => uint) public balances; // winner accounts
    uint[] public hashes; // used to clear balances mapping after each round
    uint[3] public winnerNumbers; // numbers of winning tickets

    modifier inSubmission() {
        require(block.number < lastStartBlock + period / 2);
        _;
    }

    modifier inReveal() {
        require(block.number >= lastStartBlock + period / 2);
        require(block.number < lastStartBlock + period);
        _;
    }

    // if round ended
    modifier afterReveal() {
        require(block.number >= lastStartBlock + period);
        _;
    }

    modifier hasMoney() { require(balances[msg.sender] > 0); _; }

    /**
     * if round ended but restart function not called, then restart, payout and continue
     */
    modifier checkPayout() {
        if(block.number >= lastStartBlock + period) {
            payout();
        }
        _;
    }

    function Lottery(uint _period) public {
        require((_period / 2) * 2 == _period); // must be divisible by 2
        period = _period;
        lastStartBlock = block.number;
    }

    /**
     * return sha3 of the number together with sender address
     * do not use in the blockchain
     */
    function keccak(uint number) public constant returns(uint) {
        return uint(keccak256(number, msg.sender));
    }

    function getTicketType() private constant returns(TicketType) {
        if(msg.value == 8 finney) return TicketType.Full;
        if(msg.value == 4 finney) return TicketType.Half;
        if(msg.value == 2 finney) return TicketType.Quarter;
        revert();
    }

    function getTicketPrice(TicketType ticketType) private pure returns(uint) {
        if(ticketType == TicketType.Full) return 8 finney;
        if(ticketType == TicketType.Half) return 4 finney;
        if(ticketType == TicketType.Quarter) return 2 finney;
        revert();
    }

    /**
     * generate new ticket from given hash
     */
    function purchaseTicket(uint hash) public payable checkPayout inSubmission {
        require(ticketMap[hash].owner == address(0)); // cannot buy same ticket
        Ticket memory ticket = Ticket({
            owner: msg.sender,
            hash: hash,
            ticketType: getTicketType(),
            number: 0,
            submitted: false
        });

        ticketMap[hash] = ticket;
        hashes.push(hash);

        reward += msg.value;
    }

    /**
     * validate {number} with hash and add relevant ticket to submitted tickets
     */
    function submitNumber(uint number) public checkPayout inReveal {
        uint hash = keccak(number);
        Ticket storage ticket = ticketMap[hash];
        require(ticket.owner != address(0)); // ticket exists
        require(ticket.submitted == false); // ticket should not be submitted before

        ticket.number = number;
        ticket.submitted = true;
        tickets.push(ticket);
    }

    /**
     * reset the state variables for a new round
     */
    function restart() private {
        lastStartBlock = lastStartBlock + period;

        for(uint i = 0; i < hashes.length; i++) {
            delete ticketMap[hashes[i]];
        }
        delete hashes;
        delete tickets;
    }

    /**
     * choose winners XORing random numbers and assign balances if there are enough participants
     */
    function payout() public afterReveal returns(uint[3]) {
        // refund tickets if there are not 3 participants at least
        if(tickets.length < 3) {
            for(uint i = 0; i < tickets.length; i++) {
                balances[tickets[i].owner] += getTicketPrice(tickets[i].ticketType);
            }
            restart();
            return;
        }

        // XOR random numbers of tickets and set moduli of the last 3 as winners
        uint XOR = 0;
        Ticket[] memory winnerTickets = new Ticket[](3);

        for(uint j = 0; j < tickets.length; j++) {
            XOR ^= tickets[j].number;
            if(j >= tickets.length - 3) {
                winnerNumbers[j - tickets.length + 3] = tickets[XOR % tickets.length].number;
                winnerTickets[j - tickets.length + 3] = tickets[XOR % tickets.length];
            }
        }

        // share the reward among the winners
        uint totalPartialReward;
        for(uint k = 0; k < winnerTickets.length; k++) {
            // calculate reward from index and ticket type
            uint partialReward = reward / ( 2 ** (k + 1)); // M/2 for 1st, M/4 for 2nd, M/8 for 3rd
            if(winnerTickets[k].ticketType == TicketType.Half) partialReward /= 2;
            if(winnerTickets[k].ticketType == TicketType.Quarter) partialReward /= 4;
            // arrange balances
            totalPartialReward += partialReward;
            balances[winnerTickets[k].owner] += partialReward;
        }
        reward -= totalPartialReward;

        restart();
        return winnerNumbers;
    }

    /**
     * get winner ticket numbers (used in test)
     */
    function getWinnerNumbers() public constant returns(uint[3]) {
        return winnerNumbers;
    }

    /**
     * send reward to winner account
     */
    function withdrawal() public hasMoney {
        uint balance = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(balance);
    }

    function() public payable {}
}