//SourceUnit: CommunityGame.sol

pragma solidity 0.5.10; 

contract CommunityGame{
    using SafeMath for uint256;

    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public WINNER_SHARE = 400;
	uint256 constant public TRONKING_SHARE = 500;	
	uint256 public constant TICKET_PRICE = 50e6; // 50 TRX

    uint256 public LOTTERY_STEP = 1 days; 
    uint256 public MAX_TICKETS = 10;
    uint256 public LOTTERY_START_TIME;
    uint256 public roundId = 1;
    uint256 public totalPool = 0;
    uint256 public totalTickets = 0;

    address owner;
    address payable tronking;

    struct User {
        uint256 totalTickets;
        uint256 totalReward;
        uint256 totalWins;
    }

    mapping (address => User) public users;
    mapping(uint256 => mapping(uint256 => address)) public ticketsUsers;
    mapping(uint256 => mapping(address => uint256)) public usersTickets;
    
    event Winner(address indexed winnerAddress, uint256 winnerPrize, uint256 roundId, uint256 totalPool, uint256 totalTickets, uint256 time);
    event BuyTicket(address indexed user, uint256 roundId, uint256 totalTickets, uint256 time);


    function() payable external {
    }

    constructor(address  ownerAddr, address payable tronkingAddr, uint256 startDate) public{
        owner = ownerAddr;
        tronking = tronkingAddr;
        if(startDate > 0){
            LOTTERY_START_TIME = startDate;
        }
        else{
            LOTTERY_START_TIME = block.timestamp;
        }
    }

    function buyTicket(uint256 cnt) public payable {
        require(cnt <= MAX_TICKETS, "max ticket numbers is 10");
        require(block.timestamp > LOTTERY_START_TIME, "round does not start yet");
        require(cnt.mul(TICKET_PRICE) == msg.value, "wrong payment amount");

        for(uint256 i=0; i < cnt; i++){
            ticketsUsers[roundId][totalTickets+i] = msg.sender;
        }
        usersTickets[roundId][msg.sender] += cnt;
        totalTickets += cnt;
        totalPool += msg.value;
        users[msg.sender].totalTickets += cnt;

        emit BuyTicket(msg.sender, roundId, cnt, block.timestamp);

        if(LOTTERY_START_TIME.add(LOTTERY_STEP) < block.timestamp){
            draw();
        }       
    }
    
    function draw() public {
        require(LOTTERY_START_TIME.add(LOTTERY_STEP) < block.timestamp , "round is not finish yet" );

        if(totalTickets>0){

            uint256 winnerPrize   = totalPool.mul(WINNER_SHARE).div(PERCENTS_DIVIDER);
            uint256 tronkingShare = totalPool.mul(TRONKING_SHARE).div(PERCENTS_DIVIDER);

            uint256 random = (_getRandom()).mod(totalTickets); 
            address winnerAddress = ticketsUsers[roundId][random];
            users[winnerAddress].totalWins = users[winnerAddress].totalWins.add(1);
            users[winnerAddress].totalReward = users[winnerAddress].totalReward.add(winnerPrize);

            address(uint160(winnerAddress)).transfer(winnerPrize);
            tronking.transfer(tronkingShare);
        
            emit Winner(winnerAddress, winnerPrize, roundId, totalPool, totalTickets, block.timestamp);
        }
        else{
            emit Winner(address(0), 0, roundId, totalPool, totalTickets, block.timestamp);
        }
        
        // Reset Round
        totalPool = address(this).balance;
        roundId = roundId.add(1);
        totalTickets = 0;
        LOTTERY_START_TIME = block.timestamp;
    }
    
    function _getRandom() private view returns(uint256){
        return uint256(keccak256(abi.encode(block.timestamp,totalTickets,block.difficulty, address(this).balance)));
    }
    
    function getUserTickets(address _userAddress, uint256 round) public view returns(uint256) {
         return usersTickets[round][_userAddress];
    }
    
    function getRoundStats() public view returns(uint256, uint256, uint256, uint256) {
        return (
            roundId,
            LOTTERY_START_TIME.add(LOTTERY_STEP),
            totalPool,
            totalTickets
            );
    }
    
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}