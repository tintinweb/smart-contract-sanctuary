pragma solidity ^0.4.24;

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract CRTLotto is Owned {
    uint public ticketPrice;
    uint public totalTickets;

    mapping(uint => address) public tickets;

    constructor() public {
        ticketPrice = 0.01 * 10 ** 18;
        totalTickets = 0;
    }
    
    function setTicketPrice(uint _ticketPrice) external onlyOwner {
        ticketPrice = _ticketPrice;
    }
    
    function() payable external {
        uint ethSent = msg.value;
        require(ethSent >= ticketPrice);
        
        tickets[totalTickets] = msg.sender;
        totalTickets += 1;
    }
    
    function resetLotto() external onlyOwner {
        totalTickets = 0;
    }
    
    function withdrawEth() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}