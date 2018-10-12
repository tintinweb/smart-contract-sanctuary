pragma solidity ^0.4.25;

contract Raffle {
    address public charity = msg.sender;
    uint public ticketPrice;
    bool public raffleClosed = false;
    uint public ticketsPurchased = 0;
    mapping (uint => address) public ticketBuyers;
    uint public amountRaised;
    uint public winningTicketNumber;

    bool public winnerApproved = false;

    // event FundTransfer(address indexed backer, uint amount, bool isContribution);

    modifier onlyBy(address _account) { require(msg.sender == _account); _; }


    function Raffle(
        uint szaboCostOfEachTicket
    ) public {
        ticketPrice = szaboCostOfEachTicket * 1 szabo;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public{
        require(!raffleClosed);
        uint amount = msg.value;
        uint tokenAmount = amount / ticketPrice;
        uint quantity = amount / ticketPrice;
        require(quantity >= 1 && quantity < 100);

        for(uint i = ticketsPurchased; i < quantity;i++){
            ticketBuyers[i] = msg.sender;
            ticketsPurchased += 1;
        }
        
        amountRaised += msg.value;
    }

    function buyTicket() payable public{ 
        require(!raffleClosed);
        uint amount = msg.value;
        uint tokenAmount = amount / ticketPrice;
        uint quantity = amount / ticketPrice;
        require(quantity >= 1 && quantity < 100);

        for(uint i = ticketsPurchased; i < quantity;i++){
            ticketBuyers[i] = msg.sender;
            ticketsPurchased += 1;
        }
        
        amountRaised += msg.value;

    }

    function selectWinningNumber() onlyBy(charity){        
        uint winner = uint(keccak256(block.blockhash(block.number-1))) % ticketsPurchased;
        winningTicketNumber = winner;
        raffleClosed = true;
    }


    function claimPrize() public{
        require(winnerApproved);
        require(raffleClosed);
        require(msg.sender == ticketBuyers[winningTicketNumber]);
        msg.sender.transfer(amountRaised / 2);
    }

    function approveWinner() onlyBy(charity){
        winnerApproved = true;
    }


    function withdrawEther() onlyBy(charity) public {
        charity.transfer(this.balance);
    }
}