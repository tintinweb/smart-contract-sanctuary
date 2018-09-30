pragma solidity ^0.4.24;

/*
    Sale(address ethwallet)   // this will send the received ETH funds to this address
  @author Yumerium Ltd
*/
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract YumeriumManager {
    function getYumerium(address sender) external payable returns (uint256);
}

contract Sale {
    uint public saleEnd1 = 1535846400 + 1 days; //9/3/2018 @ 12:00am (UTC)
    uint public saleEnd2 = saleEnd1 + 1 days; //9/4/2018 @ 12:00am (UTC)
    uint public saleEnd3 = saleEnd2 + 1 days; //9/5/2018 @ 12:00am (UTC)
    uint public saleEnd4 = 1539129600; //10/10/2018 @ 12:00am (UTC)
    uint256 public minEthValue = 10 ** 15; // 0.001 eth
    
    using SafeMath for uint256;
    uint256 public maxSale;
    uint256 public totalSaled;
    mapping(uint256 => mapping(address => uint256)) public ticketsEarned;   // tickets earned for each user each day
                                                                            // (day => (user address => # tickets))
    mapping(uint256 => uint256) public totalTickets; // (day => # total tickets)
    mapping(uint256 => uint256) public eachDaySold; // how many ethereum sold for each day
    uint256 public currentDay;  // shows what day current day is for event sale (0 = event sale ended)
                                // 1 = day 1, 2 = day 2, 3 = day 3
    mapping(uint256 => address[]) public eventSaleParticipants; // participants for event sale for each day
    
    YumeriumManager public manager;

    address public creator;

    event Contribution(address from, uint256 amount);

    constructor(address _manager_address) public {
        maxSale = 316906850 * 10 ** 8; 
        manager = YumeriumManager(_manager_address);
        creator = msg.sender;
        currentDay = 1;
    }

    function () external payable {
        buy();
    }

    // CONTRIBUTE FUNCTION
    // converts ETH to TOKEN and sends new TOKEN to the sender
    function contribute() external payable {
        buy();
    }
    
    function getNumParticipants(uint256 whichDay) public view returns (uint256) {
        return eventSaleParticipants[whichDay].length;
    }
    
    function buy() internal {
        require(msg.value>=minEthValue);
        require(now < saleEnd4); // main sale postponed
        
        uint256 amount = manager.getYumerium.value(msg.value)(msg.sender);
        uint256 total = totalSaled.add(amount);
        
        require(total<=maxSale);
        
        totalSaled = total;
        if (currentDay > 0) {
            eachDaySold[currentDay] = eachDaySold[currentDay].add(msg.value);
            uint256 tickets = msg.value.div(10 ** 17);
            if (ticketsEarned[currentDay][msg.sender] == 0) {
                eventSaleParticipants[currentDay].push(msg.sender);
            }
            ticketsEarned[currentDay][msg.sender] = ticketsEarned[currentDay][msg.sender].add(tickets);
            totalTickets[currentDay] = totalTickets[currentDay].add(tickets);
            if (now >= saleEnd3)
            {
                currentDay = 0;
            }
            else if (now >= saleEnd2)
            {
                currentDay = 3;
            }
            else if (now >= saleEnd1)
            {
                currentDay = 2;
            }
        }
        
        emit Contribution(msg.sender, amount);
    }

    // change yumo address
    function changeManagerAddress(address _manager_address) external {
        require(msg.sender==creator, "You are not a creator!");
        manager = YumeriumManager(_manager_address);
    }
}