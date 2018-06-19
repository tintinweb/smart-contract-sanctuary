pragma solidity ^0.4.20;

/* library/Owned.sol */
contract Owned {
    address owner;
    function Owned() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract NewLottery is Owned {

    //CONSTANT
    uint256 private maxTickets;
    uint256 public minimumBounty;
    uint256 public ticketPrice;

    //LOTO REGISTER
    uint256 public lottoIndex;
    uint256 lastTicketTime;

    //LOTTO VARIABLES
    uint8 _direction;
    uint256 numtickets;
    uint256 totalBounty;
    address owner;

    event NewTicket(address indexed fromAddress, bool success);
    event LottoComplete(address indexed fromAddress, uint indexed lottoIndex, uint256 reward);

    /// Create a new Lotto
    function LottoCount() public payable
    {
        owner = msg.sender;

        ticketPrice = 0.101 * 10**18;
        minimumBounty = 1 * 10**18;
        maxTickets = 10;

        _direction = 0;
        lottoIndex = 1;
        lastTicketTime = 0;

        numtickets = 0;
        totalBounty = msg.value;
        require(totalBounty >= minimumBounty);
    }


   function getBalance() public view returns (uint256 balance)
    {
        balance = 0;

        if(owner == msg.sender) balance = this.balance;

        return balance;
    }


    function withdraw() onlyOwner public
    {
        //reset values
        lottoIndex += 1;
        numtickets = 0;
        totalBounty = 0;

        owner.transfer(this.balance);
    }

    function shutdown() onlyOwner public
    {
        suicide(msg.sender);
    }

    function getLastTicketTime() public view returns (uint256 time)
    {
        time = lastTicketTime;
        return time;
    }

    function AddTicket() public payable
    {
        require(msg.value == ticketPrice);
        require(numtickets < maxTickets);

        //update bif
        lastTicketTime = now;
        totalBounty += ticketPrice;
        bool success = numtickets == maxTickets;

        NewTicket(msg.sender, success);

        //check if winner
        if(success)
        {
            PayWinner(msg.sender);
        }
    }

    function PayWinner( address winner ) private
    {
        require(numtickets == maxTickets);

        //calc reward
        uint ownerTax = 5 * totalBounty / 100;
        uint winnerPrice = totalBounty - ownerTax;

        LottoComplete(msg.sender, lottoIndex, winnerPrice);

        //reset values
        lottoIndex += 1;
        numtickets = 0;
        totalBounty = 0;

        //change max tickets to give unpredictability
        if(_direction == 0 && maxTickets < 20) maxTickets += 1;
        if(_direction == 1 && maxTickets > 10) maxTickets -= 1;

        if(_direction == 0 && maxTickets == 20) _direction = 1;
        if(_direction == 1 && maxTickets == 10) _direction = 0;

        //give real money
        owner.transfer(ownerTax);
        winner.transfer(winnerPrice);
    }
}