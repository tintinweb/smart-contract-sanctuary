/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

pragma solidity 0.5.10;

interface Oracle {
    enum QueryStatus { INVALID, OK, NOT_AVAILABLE, DISAGREEMENT}
    
    function query(bytes calldata input) external payable returns (bytes32 output, uint256 updatedAt, QueryStatus status);
        
    function queryPrice() external view returns (uint256);
}

contract TicketSeller {
    uint256 public remainingTickets;
    mapping (address => uint256) private tickets;
    mapping (address => string) private ticketNumber;
    mapping (address => bytes) private userID;
    
    constructor(uint256 totalTicket) public {
        remainingTickets = totalTicket;
    }
    
    function ticketCount(address owner) public view returns (uint256){
        return tickets[owner];
    }
    
    function yourNumber(address owner) public view returns (string memory){
        return ticketNumber[owner];
    }
    
    function checkID(address owner) public view returns (bytes memory){
        return userID[owner];
    }
    
    function yourID(string memory id) public returns(string memory){
        require(bytes(id).length == 13,'Need id with 13 digits');
        userID[msg.sender] = abi.encodePacked(id);
    }
    
    function transfer(address to) public {
        require(tickets[msg.sender]>0, "MUST_HAVE_TICKET");
        tickets[msg.sender] -= 1;
        tickets[to] += 1;
    }
    
    function buyTicket(string memory number) public payable { 
        require(bytes(number).length == 6,"Need number with 6 digits");
        ticketNumber[msg.sender] = number;
        
        uint256 price = getTicketPrice();
        require(msg.value >= price, "NOT_ENOUGH_PAYMENT");
        require(remainingTickets > 0, "NO_MORE_TICKET");
        remainingTickets -= 1;
        tickets[msg.sender] += 1;
    }
    
    function getTicketPrice() public payable returns (uint256){
            //Find how many ETH worth 100 Bath
            //1.Get BATH/USD
            Oracle oracle = Oracle(0x61Ab2054381206d7660000821176F2A798F031de);
            (bytes32 thbUsd,,) = oracle.query.value(oracle.queryPrice())("THB/USD");
            //2.ETH/USD
            Oracle oracle2 = Oracle(0x07416E24085889082d767AF4CA09c37180A3853c);
            (bytes32 ethUsd,,) = oracle2.query.value(oracle2.queryPrice())("ETH/USD");
            //3.Return result
            return 100 * uint256(thbUsd) * 1e18 / uint256(ethUsd);
        }
}