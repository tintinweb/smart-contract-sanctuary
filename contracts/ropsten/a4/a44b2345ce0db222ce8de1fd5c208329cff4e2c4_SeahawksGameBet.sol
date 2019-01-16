pragma solidity >=0.4.22 <0.6.0;
//import "github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol";  

library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }
}

contract SeahawksGameBet {

    using SafeMath for uint256;
    
    address public owner;
    uint256 public betAmount;
    uint256 public numberOfBets;
    uint256 public totalParticipants;

    address[2] public participants; 
    
    mapping (address => bool) public participantData;
    
    event OwnerAdded(address add, uint256 amount);
    event ParticipantAdded(address add, uint256 amount);
    event OwnerBackOut(address add, uint256 amount);
    event PrizeDistributed(address winner, uint amount);
    
    // Constructor, takes in number of participants in bet
    function initBet(bool gamePrediction) public payable {
        owner = msg.sender;
        betAmount = msg.value;
        numberOfBets = 0;
        totalParticipants = 2;
        //ownerPrediction = gamePrediction;
        addParticipant(msg.sender, gamePrediction);
        
        emit OwnerAdded(msg.sender, betAmount);
    }

    function joinBet() public payable {
        // checks if owner has joined
        require(numberOfBets == 1);
        // check if player exists
        require(!participantExists(msg.sender));
        // check if meets bet amount
        require(msg.value == betAmount);
        addParticipant(msg.sender, !participantData[0]);
        
        emit ParticipantAdded(msg.sender, msg.value);
    }

    // Checks if participant exits
    function participantExists(address participantToCheck) public view returns(bool) {
        for (uint256 i = 0; i < totalParticipants; i++) {
            if (participants[i] == participantToCheck) {
                return true;
            }
        }
        return false;
    }
    
    function addParticipant(address adr, bool _winOrLose) private {
        // set participant info
        participantData[adr] = _winOrLose;
        // add participant address to array
        participants[numberOfBets] = adr;
        // increment numberOfBets
        numberOfBets++;
    }
    
    // Allow the first person to withdraw their funds if the second person has not yet deposited his bet
    function backOut() public  {
        
        require(numberOfBets == 1);
        address temp = participants[0];
        
        delete participants[0];
        numberOfBets = 0;
        temp.transfer(betAmount);
        betAmount = 0;
        
        emit OwnerBackOut(msg.sender, betAmount);
    }
    
    // Transfer prize to winner.
    function distributePrize(bool gameResult) public {
        
        require(numberOfBets == totalParticipants);
        
        address temp;
        if (participantData[participants[0]] == gameResult) {
            //transfer money to participant[0]
            temp = participants[0];
        } else {
            temp = participants[1];
        }
        
        // winner cannot distribute prize
        //require(msg.sender != temp); 
        
        delete participants[0];
        delete participants[1];
        numberOfBets = 0;
        
        // send out ether
        emit PrizeDistributed (temp, betAmount.mul(2));
        temp.transfer(betAmount.mul(2));
        
        betAmount = 0;
    }
}