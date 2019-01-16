pragma solidity ^0.4.24;
/// @author Global Group - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="5a3d3d3635383b3633203f3e1a3d373b333674393537">[email&#160;protected]</a>>
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract MEGIngerface {
	function depositFunds(address _participant, uint256 _weiAmount) public payable returns(bool success);
	function withdrawFromBalance(address _participant, uint256 _weiAmount) public payable returns(bool success);
	function addBalance(address _participant, uint256 _weiAmount) public returns(bool success);
	function substractBalance(address _participant, uint256 _weiAmount) public returns(bool success);
	function transferETH(address _to, uint256 _value) public;
	function balanceOf(address who) public view returns (uint256);
	function getJackpot() public view returns (uint256 _jackpot);
	function getIsAuth(address _auth) public view returns(bool _isAuth);
}

contract Owned {
    address public owner;
	mapping (address => bool) internal auth;

    event LogNew(address indexed old, address indexed current);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
	
	modifier onlyAuth {
	    require(auth[msg.sender] == true);
	    _;
	}

    constructor() public {
        owner = msg.sender;
    }
	
	event Authorization(address indexed authorized, bool isAuthorized);
	function authorize(address _Auth, bool isAuth) public onlyOwner {
		auth[_Auth] = isAuth;
		emit Authorization(_Auth, isAuth);
	}
	
    function transferOwnership(address _newOwner) onlyOwner public {
        emit LogNew(owner, _newOwner);
        owner = _newOwner;
    }
	
	function getIsAuth(address _auth) public view returns(bool _isAuth){
		return auth[_auth];
	}
}

contract Lottery is Owned{
	using SafeMath for uint256;
	address public moneyManager;
	
	uint32 internal roundCounter;
	uint32 public constant increment = 1;

	uint256 internal ticketsCounter;
	
	uint256 public constant TICKET_PRICE = 10 finney; //0.01 ETH
	
    uint256 public constant ROUND_DURATION = 5300; //5300; 23 hours
    
    uint256 public constant DURATION = 220; //220; // One hour
    
    mapping(address => uint256[]) internal participantTickets;
	mapping(uint256 => Ticket) internal tickets;
	mapping(uint32 => Round) internal roundInfo;

	
	struct Round {
		uint256 targetBlock;
		bytes32 seedHash;
		uint256 seedDifficulty;
		uint256 roundEnd;
		uint32[6] winningNumbers;
		bool roundEnded;
		bool roundFinish;
	}
	
	struct Ticket {
	    address participant;
		uint32 ticketRound;
        uint32 number1;
        uint32 number2;
        uint32 number3;
        uint32 number4;
        uint32 number5;
        uint32 number6;
		bool isRevenuePaid;
	}
	
	
	constructor(address _moneyManager) public {
	    moneyManager = _moneyManager;
	    roundCounter = 0;
        roundInfo[roundCounter].roundEnd = block.number.add(ROUND_DURATION);
        roundInfo[roundCounter].targetBlock = roundInfo[roundCounter].roundEnd.add(DURATION);
	}
	
    event BuyTicket(address indexed _sender, uint32 _num1,uint32 _num2, uint32 _num3, uint32 _num4, uint32 _num5, uint32 _num6, uint256 _ticketNumber);
	function buyTicket(uint32 _num1,uint32 _num2, uint32 _num3, uint32 _num4, uint32 _num5, uint32 _num6) public returns(uint256 _ticketNumber) {
	    require(MEGIngerface(moneyManager).balanceOf(msg.sender) >= TICKET_PRICE);
		Ticket memory t = tickets[ticketsCounter];
			t.participant = msg.sender;
			t.ticketRound = roundCounter;
			t.number1 = _num1;
			t.number2 = _num2;
			t.number3 = _num3;
			t.number4 = _num4;
			t.number5 = _num5;
			t.number6 = _num6;
		tickets[ticketsCounter] = t;
		participantTickets[msg.sender].push(ticketsCounter);
		ticketsCounter = ticketsCounter + increment;
		MEGIngerface(moneyManager).substractBalance(msg.sender, TICKET_PRICE);
		emit BuyTicket(msg.sender, _num1, _num2, _num3, _num4, _num5, _num6, ticketsCounter - increment);
		return ticketsCounter - increment;
	}
	
	event Win(address indexed _participant, uint256 winningNumbers, uint32 _round, uint256 _timeStamp);
	function checkMyTicket(uint32 _ticketNumber) public {
		Ticket memory t = tickets[_ticketNumber];
		require(t.participant == msg.sender);
		require(t.isRevenuePaid == false);
		require(t.ticketRound < roundCounter);
		require(roundInfo[roundCounter - 1].roundFinish == true);
		uint32 winningNum = checkTicket(_ticketNumber);
		if(winningNum == 2) {
			MEGIngerface(moneyManager).addBalance(t.participant, TICKET_PRICE.mul(1));
		} else if(winningNum == 3) {
		    MEGIngerface(moneyManager).addBalance(t.participant, TICKET_PRICE.mul(10));
		} else if(winningNum == 4) {
		    MEGIngerface(moneyManager).addBalance(t.participant, TICKET_PRICE.mul(200));
		} else if(winningNum == 5) {
		    MEGIngerface(moneyManager).addBalance(t.participant, TICKET_PRICE.mul(4000));
		} else if(winningNum == 6) {
		    MEGIngerface(moneyManager).addBalance(t.participant, MEGIngerface(moneyManager).getJackpot());
		}
		t.isRevenuePaid = true;
		if(winningNum >= 2){
			emit Win(msg.sender, winningNum, t.ticketRound, block.timestamp);
		}
		tickets[_ticketNumber] = t;
	}
	
	event CheckTicket(uint32 _ticketNumber);
	function checkTicket(uint32 _ticketNumber) internal returns (uint32 _ticketResult) {
	    Ticket memory t = tickets[_ticketNumber];
	    uint32[6] memory roundNumbers = roundInfo[t.ticketRound].winningNumbers;
        _ticketResult = 0;
		for(uint32 i = 0; i < roundNumbers.length; i++) {
		    if(t.number1 == roundNumbers[i]) {
		        _ticketResult = _ticketResult + 1; 
		    } else if(t.number2 == roundNumbers[i]) {
		        _ticketResult = _ticketResult + 1; 
		    } else if(t.number3 == roundNumbers[i]) {
		        _ticketResult = _ticketResult + 1; 
		    } else if(t.number4 == roundNumbers[i]) {
		        _ticketResult = _ticketResult + 1; 
		    } else if(t.number5 == roundNumbers[i]) {
		        _ticketResult = _ticketResult + 1; 
		    } else if(t.number6 == roundNumbers[i]) {
		        _ticketResult = _ticketResult + 1; 
		    }
		}
		
		emit CheckTicket(_ticketNumber);
		
		return _ticketResult;
	}
	
	event IsRoundEnd(bool _isRoundEnd, uint32 _prevRound, uint32 _nextRound);
	function isRoundEnd(uint32 _forRound) public onlyAuth {
	    require(roundInfo[_forRound].roundEnd < block.number);
	    roundInfo[_forRound].roundEnded = true;
        uint32 nextRound = _forRound + increment;
        
        roundInfo[nextRound].roundEnd = roundInfo[_forRound].roundEnd + ROUND_DURATION;
        
        roundInfo[nextRound].targetBlock = roundInfo[nextRound].roundEnd + DURATION;
        roundCounter = roundCounter + 1;
		emit IsRoundEnd(roundInfo[roundCounter].roundEnded, _forRound , nextRound);
	}
	
	event DrawNumbers(uint32[6] _roundNumbers, uint32 _round);
	function drawNumbers(uint32 _forRound) public onlyAuth {
	    Round memory r = roundInfo[_forRound];
	    require(r.roundEnded == true);
		require(r.roundFinish == false);
        r.seedDifficulty = block.difficulty;
	    r.winningNumbers = endRound(r.seedDifficulty);
	    r.seedHash = blockhash(r.targetBlock);
	    r.roundFinish = true;
		emit DrawNumbers(r.winningNumbers, _forRound);
	    roundInfo[_forRound] = r;
	}
	
    event RandomNum(uint32 Num);
	function endRound(uint256 _seed3) internal returns(uint32[6] numbers){
        require(roundInfo[roundCounter - 1].targetBlock < block.number);
        bytes32 _hash = blockhash(roundInfo[roundCounter - 1].targetBlock);
        
        bool[50] memory colision;
        uint index = 0;
        for(uint32 i = 31; i >= 0; i--){
            uint32 num = random(_hash[i],i,_seed3);
            if(colision[num] == false){
                numbers[index] = num;
                colision[num] = true;
                index++;
                emit RandomNum(num);
            }
            if(index == 6) {
                return numbers;
            }
        }
    }

    function random(bytes32 _seed1, uint32 _seed2, uint256 _seed3) public pure returns(uint32 _number){
		return (uint32(keccak256(_seed1,_seed2,_seed3, uint32(_seed1) + _seed2 + _seed3))%49) + 1;
    }

	function getTicketPrice() public view returns(uint256 _price) {
		return TICKET_PRICE;
	}
	
	function getTickets(address _participant) public view returns(uint256[] _tickets) {
	    return participantTickets[_participant];
	}
	
	function getTicketNumbers(uint256 _ticketId) public view 
	returns(
		uint32 number1,
        uint32 number2,
        uint32 number3,
        uint32 number4,
        uint32 number5,
        uint32 number6
	){
	    return(
	        tickets[_ticketId].number1,
	        tickets[_ticketId].number2,
	        tickets[_ticketId].number3,
	        tickets[_ticketId].number4,
	        tickets[_ticketId].number5,
	        tickets[_ticketId].number6
		);
	}
	
	function getParticipantTickets(address _participant) public view returns(uint256[] _tickets) {
	    return participantTickets[_participant];
	}
	
	function getTicketParticipant(uint256 _ticketId) public view returns(address _participant) {
	    return tickets[_ticketId].participant;
	}
	
	function getTicketRound(uint256 _ticketId) public view returns(uint32 _ticketRound) {
	    return tickets[_ticketId].ticketRound;
	}
	
	function getTicketIsPaid(uint256 _ticketId) public view returns(bool _isRevenuePaid) {
	    return tickets[_ticketId].isRevenuePaid;
	}
	
	function getroundinfo(uint32 _roundNum) public view returns(
        uint256 targetBlock,
		bytes32 seedHash,
		uint256 seedDifficulty,
		uint256 roundEnd,
		uint32[6] winningNumbers,
		bool roundEnded,
		bool roundFinish){
		    Round memory r = roundInfo[_roundNum];
		    return(
		        r.targetBlock,
		        r.seedHash,
		        r.seedDifficulty,
		        r.roundEnd,
		        r.winningNumbers,
		        r.roundEnded,
		        r.roundFinish);
	}
	
	function getRoundDifficultyBlock(uint32 _roundNum) public view returns (uint256 _seedDifficulty) {
	    return roundInfo[_roundNum].seedDifficulty;
	}
	
	function getRoundTargetBlock(uint32 _roundNum) public view returns (uint256 targetBlock) {
	    return roundInfo[_roundNum].targetBlock;
	}
		
	function getRoundSeedHash(uint32 _roundNum) public view returns (bytes32 seedHash) {
	    return roundInfo[_roundNum].seedHash;
	}
		
    function getRoundEndBlock(uint32 _roundNum) public view returns (uint256 roundEnd) {
	    return roundInfo[_roundNum].roundEnd;
	}
	
    function getRoundWinnigNumbers(uint32 _roundNum) public view returns (uint32[6] winningNumbers) {
	    return roundInfo[_roundNum].winningNumbers;
	}
	
	function getRoundIsEnded(uint32 _roundNum) public view returns (bool roundEnded) {
	    return roundInfo[_roundNum].roundEnded;
	}
	
	function getRoundFinish(uint32 _roundNum) public view returns (bool roundFinished) {
	    return roundInfo[_roundNum].roundFinish;
	}
	
	function getRoundCounter() public view returns (uint256 _roundCounter) {
	    return roundCounter;
	}
	
	function getTicketCounter() public view returns (uint256 _ticketCounter) {
	    return ticketsCounter;
	}
}