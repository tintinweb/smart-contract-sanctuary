pragma solidity ^0.4.21;

// ============================================================================
// ERC Token Standard #20 Interface (For communication with DiipCoin Contract)
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ============================================================================
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ============================================================================
// Owned contract
// ============================================================================
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
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

// ============================================================================
// Tourpool contract
// ============================================================================
contract TourPool is Owned{
	// state variables
	bool public startlistUploaded;
	address diipCoinContract;
	address public currentLeader;
	uint public highScore;
	uint public prizeMoney;
	uint public registrationDeadline;
	uint public maxTeamSize;
	uint public playerBudget;
	uint public playerCount;

	// Rider and Player structs
	struct Rider {
		uint price;
		uint score;
	}

	struct Player {
		uint status;
		uint[] team;
		uint teamPrice;
	}

	// mappings of riders and players
	mapping(address => Player) public players;
	address[] public registrations;
	mapping(uint => Rider) public riders;

	// Events
	event NewPlayer(address indexed player);
	event TeamCommitted(address indexed player, uint indexed teamPrice, uint[] team);
	event scoresUpdated(uint[] riderIDs, uint[] dayScores);
	event scoresEdited(uint[] riderIDs, uint[] newScores);
	event PrizeMoneyStored(uint Prize);	

	// Function Modifiers
	modifier beforeDeadline {
		require(now <= registrationDeadline);
		_;
	}

	modifier diipCoinOnly {
		require(msg.sender == diipCoinContract);
		_;
	}

	// -----------
	// Constructor
	// -----------	
	function TourPool() public {		
		diipCoinContract = 0xc9E86029bd081af490ce39a3BcB1bccF99d33CfF;		
		registrationDeadline = 1530954000;
		maxTeamSize = 8;
		playerBudget = 100;
		startlistUploaded = false;		
	}

	// ---------------------------
	//  Public (player) functions
	// ---------------------------
	function register() public beforeDeadline returns (bool success){		
		// players may register only once
		require(players[msg.sender].status == 0);		
		// update player status
		players[msg.sender].status = 1;
		players[msg.sender].teamPrice = 0;
		registrations.push(msg.sender);
		// Broadcast event of player registration
		emit NewPlayer(msg.sender);
		// sent 100 DIIP to contract caller
		return transferPlayerBudget(msg.sender);		
	}

	// This function is called from the diipcoin contract
	function tokenFallback(
		address _sender,
	    uint _value,	    
	    uint[] _team
	) 
		public beforeDeadline diipCoinOnly returns (bool) 
	{
		require(startlistUploaded);	    
	    return commitTeam(_sender, _value, _team);
	}

	// ---------------------------
	//  Only Owner functions
	// ---------------------------
	function uploadStartlist(uint[] prices) public onlyOwner beforeDeadline returns (bool success){
		require(prices.length == 176);	
		for (uint i; i < prices.length; i++){
			riders[i + 1].price = prices[i];
		}
		startlistUploaded = true;
		return true;
	}

	function editStartlist(uint[] riderIDs, uint[] prices) public onlyOwner beforeDeadline returns (bool success){
		require(riderIDs.length == prices.length);
		for (uint i = 0; i < riderIDs.length; i++){
			riders[riderIDs[i]].price = prices[i];
		}
		return true;
	}

	function commitScores(
		uint[] _riderIDs, 
		uint[] _scores		
		) 
		public onlyOwner 
		{
		require(_riderIDs.length == _scores.length);
		// Update scores
		for (uint i; i < _riderIDs.length; i++){			
			riders[_riderIDs[i]].score += _scores[i];
		}		
		emit scoresUpdated(_riderIDs, _scores);
		// Set new highscore
		(highScore, currentLeader) = getHighscore();
	}

	function editScores(uint[] _riderIDs, uint[] _newScores) public onlyOwner returns (bool success){
		require(_riderIDs.length == _newScores.length);
		for (uint i; i < _riderIDs.length; i++){			
			riders[_riderIDs[i]].score = _newScores[i];
		}
		(highScore, currentLeader) = getHighscore();
		emit scoresEdited(_riderIDs, _newScores);
		return true;
	}


	function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    function storePrizeMoney() public payable onlyOwner returns (bool success){
    	emit PrizeMoneyStored(msg.value);
    	prizeMoney = msg.value;
    	return true;
    }

    function payTheWinner() public payable onlyOwner returns (bool success){
    	uint toSend = prizeMoney;
    	prizeMoney -=  toSend;
    	currentLeader.transfer(toSend);
    	return true;
    }

    // ---------------------------
	//  Getters
	// ---------------------------
	function getTeamPrice(uint[] team) public view returns (uint totalPrice){
		totalPrice = 0;
		for (uint i; i < team.length; i++){
			totalPrice += riders[team[i]].price;
		}
	}

	function getPlayerScore(address _player) public view returns(uint score){
		uint[] storage team = players[_player].team;			
		score = 0;
		for (uint i = 0; i < team.length; i++){
			uint dupCount = 0;
			for (uint j = 0;j < team.length; j++){
				if (team[i] == team[j]){
					dupCount++;
				}				
			}
			if (dupCount == 1){
				score += riders[team[i]].score;	
			}
		}
		return score;
	}

	function getHighscore() public view returns (uint newHighscore, address leader){
		newHighscore = 0;		
		for (uint i; i < registrations.length; i++){
			uint score = getPlayerScore(registrations[i]);
			if (score > newHighscore){
				newHighscore = score;
				leader = registrations[i];
			}			
		}
		return (newHighscore, leader);
	}

	function getPlayerTeam(address _player) public view returns(uint[] team){
		return players[_player].team;
	}


    // ---------------------------
	//  Private functions
	// ---------------------------
    function transferPlayerBudget(address playerAddress) private returns (bool success){
    	return ERC20Interface(diipCoinContract).transfer(playerAddress, playerBudget);
    }

    function commitTeam(
    	address _player, 
    	uint _value, 
    	uint[] _team
    ) 
    	private returns (bool success)
    {
	    // check team size, price and player registration
	    require(players[_player].status >= 1);
	    require(_team.length <= maxTeamSize);
	    uint oldPrice = players[_player].teamPrice;
	    uint newPrice = getTeamPrice(_team);
	    require(oldPrice + _value >= newPrice);
	    require(oldPrice + _value <= playerBudget);
	    // commit team and emit event
	    if (newPrice < oldPrice){
	    	ERC20Interface(diipCoinContract).transfer(_player,  (oldPrice - newPrice));
	    }
    	players[_player].teamPrice = newPrice;
    	players[_player].team = _team;
    	players[_player].status = 2;
    	emit TeamCommitted(_player, newPrice, _team);	  
    	return true;
    }

}