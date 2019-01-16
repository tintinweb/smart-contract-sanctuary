pragma solidity >=0.4.0 <0.6.0;

contract Lottery {
    bytes32 public name;
    address payable public owner;
    uint public totalTickets;
    uint public leftTickets;
    uint public pricePerTicket;

    uint public finishBlock;
    uint public delayBlock;

    address[] public players;
    uint public playersTotal;

    uint[] public plainTickets;
    uint public plainTicketsTotal;

    struct playerStat {
        uint playerTotalTickets;
        uint playerIndex;
        bool isValid;
    }
    mapping(address => playerStat) public playerStats;

    address public winnerPlayer;
    uint public winnerRand;
    bool public isAllowed;

    constructor (bytes32 _name, uint _tickets, uint _price, address payable _owner) public {
        require(_tickets > 0, &#39;plz set tickets count&#39;);
        require(_price > 0, &#39;plz set tickets price&#39;);
        name = _name;
        owner = _owner;

        totalTickets = _tickets;
        leftTickets = _tickets;
        plainTicketsTotal = 0;

        pricePerTicket = _price;
        delayBlock = 3;
        isAllowed = false;
    }

    function gotWinner() public {
        require(leftTickets <=0, &#39;should be no more tickets&#39;);
        require(finishBlock + delayBlock <= block.number, &#39;please wait a little bit&#39;);
        winnerRand = uint(blockhash(finishBlock + delayBlock)) % totalTickets;
        uint winnerIndex = plainTickets[winnerRand];
        winnerPlayer = players[winnerIndex];
    }

    function allowEscrow() public {
        require(msg.sender == winnerPlayer, &#39;should be winner&#39;);
        isAllowed = true;
    }

    function escrow() public {
        require(isAllowed == true, &#39;should be allowed&#39;);
        selfdestruct(owner);
    }

    function buyTicket() payable public {
        require(leftTickets > 0, &#39;no more tickets&#39;);
        require(msg.value >= pricePerTicket, &#39;need pay for one ticket at least&#39;);

        uint todo = msg.value / pricePerTicket;
        if (todo > leftTickets) {
            todo = leftTickets;
        }
        if (_buyTicket(todo, msg.sender)) {
            address(msg.sender).transfer(msg.value - todo * pricePerTicket);
        }
    }

    function _buyTicket(uint _todo, address _addr) internal returns (bool) {
        uint playerIndex = playersTotal;
        if (!playerStats[_addr].isValid) {
            players.push(_addr);
            playerStats[_addr] = playerStat(_todo, playersTotal, true);
            playersTotal++;
        } else {
            playerStats[_addr].playerTotalTickets+= _todo;
            playerIndex = playerStats[_addr].playerIndex;
        }

        for (uint index = 0; index<_todo; index++) {
            plainTickets.push(playerIndex);
            plainTicketsTotal++;
            leftTickets--;
        }
        if (leftTickets == 0) {
            finishBlock = block.number;
        }
        return true;
    }
}


contract Lotteries {
    address[] public lotteries;
    mapping (address => bytes32) public lotteryNames;
    uint public lotteriesTotal;

    constructor () public {
        lotteriesTotal = 0;
    }

    function createLottery (bytes32 _name, uint _tickets, uint _price) public {
        address newContract = address(new Lottery(_name, _tickets, _price, msg.sender));
        lotteryNames[newContract] = _name;
        lotteries.push(newContract);
        lotteriesTotal++;
    }
}