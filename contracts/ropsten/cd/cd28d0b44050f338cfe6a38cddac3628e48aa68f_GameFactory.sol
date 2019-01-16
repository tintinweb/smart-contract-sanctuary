/***
 *       ___     ___      _    
 *      /   \   |_  )    / |   
 *      | - |    / /     | |   
 *      |_|_|   /___|   _|_|_  
 *    _|"""""|_|"""""|_|"""""| 
 *    "`-0-0-&#39;"`-0-0-&#39;"`-0-0-&#39; 
 */

pragma solidity ^ 0.4.24; 
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


library List {
  /** Finds the index of a given value in an array. */
  function indexOf(uint[] storage values, uint value) internal view returns(int) {
    uint i = 0;
    while (i<values.length) {
        if(values[i] == value){
            return int(i);
        }
        i++;
    }

    return -1;
  }

  /** Removes the given value in an array. */
  function removeValue(uint[] storage values, uint value) internal returns(int) {
    int i = indexOf(values,value);
    if(i>0 && uint(i)<values.length){ 
        removeIndex(values, uint(i));
    }

    return i;
  }

  /** Removes the value at the given index in an array. */
  function removeIndex(uint[] storage values, uint i) internal {      
    if(i<values.length){ 
        while (i<values.length-1) {
            values[i] = values[i+1];
            i++;
        }
        values.length--;
    }
  }
}

/**
 * @title NameFilter
 * @dev filter string
 */
library NameFilter {
    /**
     * @dev filters name strings
     * -converts uppercase to lower case.  
     * -makes sure it does not start/end with a space
     * -makes sure it does not contain multiple spaces in a row
     * -cannot be only numbers
     * -cannot start with 0x 
     * -restricts characters to A-Z, a-z, 0-9, and space.
     * @return reprocessed string in bytes32 format
     */
    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
        //sorry limited to 32 characters
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }
        
        // create a bool to track if we have a non number character
        bool _hasNonNumber;
        
        // convert & check
        for (uint256 i = 0; i < _length; i++)
        {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // convert to lower case a-z
                _temp[i] = byte(uint(_temp[i]) + 32);
                
                // we have a non number
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                    // require character is a space
                    _temp[i] == 0x20 || 
                    // OR lowercase a-z
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                    // or 0-9
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");
                
                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;    
            }
        }
        
        require(_hasNonNumber == true, "string cannot be only numbers");
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}


contract Owned {
    modifier isActivated {
        require(activated == true, "its not ready yet."); 
        _;
    }
    
    modifier isHuman {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
 
    modifier limits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;    
    }
 
    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

    address public owner;
	bool public activated = true;

    constructor() public{
        owner = msg.sender;
    }

	function terminate() public onlyOwner {
		selfdestruct(owner);
	}

	function setIsActivated(bool _activated) public onlyOwner {
		activated = _activated;
	}
}

 
contract IGame {
     
    address public owner; 
    address public creator;
    address public manager;
	uint256 public poolValue = 0;
	uint256 public round = 0;
	uint256 public totalBets = 0;
	uint256 public startTime = now;
    bytes32 public name;
    string public title;
	uint256 public price;
	uint256 public timespan;
	uint32 public gameType;

    /* profit divisions */
	uint256 public profitOfSociety = 5;  
	uint256 public profitOfManager = 1; 
	uint256 public profitOfFirstPlayer = 15;
	uint256 public profitOfWinner = 40;
	 
}


/***
 *       ___     ___      _    
 *      /   \   |_  )    / |   
 *      | - |    / /     | |   
 *      |_|_|   /___|   _|_|_  
 *    _|"""""|_|"""""|_|"""""| 
 *    "`-0-0-&#39;"`-0-0-&#39;"`-0-0-&#39; 
 */

contract A21 is IGame, Owned {
    
    event newRandomNumber_bytes(bytes);
    event newRandomNumber_uint(uint);
    
    
  	using SafeMath for uint256;
	using List for uint[];
  
	struct Bet {
		address addr;
		uint8 value;
		uint8 c1;
		uint8 c2;
		uint256 round;
		uint256 date;
		uint256 eth;
		uint256 award;
		uint8 awardType; 
	}

	struct Player { 
		mapping(uint256 => Bet) bets;
		uint256 numberOfBets;
	}	

	struct Result {
		uint256 round;
		address addr;
		uint256 award;
		uint8 awardType; 
		Bet bet;
	}

	uint256 private constant MINIMUM_PRICE = 0.01 ether;
	uint256 private constant MAXIMUM_PRICE = 100 ether;
	uint8 private constant NUMBER_OF_CARDS_VALUE = 13;
	uint8 private constant NUMBER_OF_CARDS = NUMBER_OF_CARDS_VALUE * 4;
	uint8 private constant MAXIMUM_NUMBER_OF_BETS = 26;
	uint8 private constant BLACKJACK = 21;
	uint256 private constant MINIMUM_TIMESPAN = 1 minutes;  
	uint256 private constant MAXIMUM_TIMESPAN = 24 hours;  

	uint256[] private _cards;
    mapping(uint8 => Bet) private _bets;
	mapping(address => Player) private _players;  
	Result[] private _results;
	Result private lastResult; 

	mapping(address => uint256) public balances;
    address public creator;
    address public manager;
	uint256 public poolValue = 0;
	uint256 public round = 0;
	uint256 public totalBets = 0;
	uint8 public numberOfBets = 0;
	uint256 public startTime = now;
    bytes32 public name;
    string public title;
	uint256 public price;
	uint256 public timespan;
	uint32 public gameType = BLACKJACK;

    /* profit divisions */
	uint256 public profitOfSociety = 5;  
	uint256 public profitOfManager = 1; 
	uint256 public profitOfFirstPlayer = 15;
	uint256 public profitOfWinner = 40;
	
	/* events */
	event OnBuy(uint256 indexed round, address indexed playerAddress, uint256 price, uint8 cardValue, uint8 c1, uint8 c2, uint256 timestamp); 
	event OnWin(uint256 indexed round, address indexed playerAddress, uint256 award, uint8 cardValue, uint8 c1, uint8 c2, uint256 timestamp); 
	event OnReward(uint256 indexed round, address indexed playerAddress, uint256 award, uint8 cardValue, uint8 c1, uint8 c2, uint256 timestamp); 
	event OnWithdraw(address indexed sender, uint256 value, uint256 timestamp); 
	event OnNewRound(uint256 indexed round, uint256 timestamp); 

	constructor(address _manager, bytes32 _name, string _title, uint256 _price, uint256 _timespan,
		uint256 _profitOfManager, uint256 _profitOfFirstPlayer, uint256 _profitOfWinner
		) public {
		require(address(_manager)!=0x0, "invaild address");
		require(_price >= MINIMUM_PRICE && _price <= MAXIMUM_PRICE, "price not in range (MINIMUM_PRICE, MAXIMUM_PRICE)");
		require(_timespan >= MINIMUM_TIMESPAN && _timespan <= MAXIMUM_TIMESPAN, "timespan not in range(MINIMUM_TIMESPAN, MAXIMUM_TIMESPAN)");
		require(_name[0] != 0, "invaild name"); 
        require(_profitOfManager <=20, "[profitOfManager] don&#39;t take too much commission :)");
        require(_profitOfFirstPlayer <=50, "[profitOfFirstPlayer] don&#39;t take too much commission :)");
        require(_profitOfWinner <=100 && (_profitOfManager + _profitOfWinner + _profitOfFirstPlayer) <=100, "[profitOfWinner] don&#39;t take too much commission :)");
        
        creator = msg.sender;
		owner = 0x56C4ECf7fBB1B828319d8ba6033f8F3836772FA9; 
		manager = _manager;
		name = _name;
		title = _title;
		price = _price;
		timespan = _timespan;
		profitOfManager = _profitOfManager;
		profitOfFirstPlayer = _profitOfFirstPlayer;
		profitOfWinner = _profitOfWinner;

		newRound();  
	}

	function() public payable isActivated isHuman limits(msg.value){
		// airdrop
		goodluck();
	}

	function goodluck() public payable isActivated isHuman limits(msg.value) {
		require(msg.value >= price, "value < price");
		require(msg.value >= MINIMUM_PRICE && msg.value <= MAXIMUM_PRICE, "value not in range (MINIMUM_PRICE, MAXIMUM_PRICE)");
		
		if(getTimeLeft()<=0){
			// timeout, end.
			endRound();
		}

		// contribution
		uint256 awardOfSociety = msg.value.mul(profitOfSociety).div(100);
		poolValue = poolValue.add(msg.value).sub(awardOfSociety);
		balances[owner] = balances[owner].add(awardOfSociety);

		uint256 v = buyCore(); 

		if(v == BLACKJACK || _cards.length<=1){
			// someone wins or cards have been run out.
			endRound();
		}		
	}

	function withdraw(uint256 amount) public isActivated isHuman returns(bool) {
		uint256 bal = balances[msg.sender];
		require(bal> 0);
		require(bal>= amount);
		require(address(this).balance>= amount);
		balances[msg.sender] = balances[msg.sender].sub(amount); 
		msg.sender.transfer(amount);

		emit OnWithdraw(msg.sender, amount, now);
		return true;
	}
    
	/* for the reason of promotion, manager can increase the award pool   */
	function addAward() public payable isActivated isHuman limits(msg.value) {
		require(msg.sender == manager, "only manager can add award into pool");  
		// thanks this smart manager 
		poolValue =  poolValue.add(msg.value);
	}
	
	function isPlayer(address addr) public view returns(bool){
	    return _players[addr].numberOfBets > 0 ;
	}

    function getTimeLeft() public view returns(uint256) { 
        // grab time
        uint256 _now = now;
		uint256 _endTime = startTime.add(timespan);
        
        if (_now >= _endTime){
			return 0;
		}
         
		return (_endTime - _now);
    }
    

	function getBets() public view returns (address[], uint8[], uint8[], uint8[]){
		uint len = numberOfBets;
		address[] memory ps = new address[](len);
		uint8[] memory vs = new uint8[](len);
		uint8[] memory c1s = new uint8[](len);
		uint8[] memory c2s = new uint8[](len);
		uint8 i = 0; 
		while (i< len) {
			ps[i] = _bets[i].addr;
			vs[i] = _bets[i].value;
			c1s[i] = _bets[i].c1;
			c2s[i] = _bets[i].c2;
			i++;
		}

		return (ps, vs, c1s, c2s);
	} 

	function getBetHistory(address player, uint32 v) public view returns (uint256[], uint256[], uint8[], uint8[]){
		Player storage p = _players[player];
		uint256 len = v;
		if(len == 0 || len > p.numberOfBets){
		    len = p.numberOfBets;
		}
		if(len == 0 ){
			return ;
		}
		
		uint256[] memory rounds = new uint256[](len);
		uint256[] memory awards = new uint256[](len);  
		uint8[] memory c1s = new uint8[](len);
		uint8[] memory c2s = new uint8[](len);
		uint256 i = p.numberOfBets - 1; 
		while (i>= p.numberOfBets - len) { 
			Bet storage r = p.bets[i];
			rounds[i] = r.round;
			awards[i] = r.award; 
			c1s[i] = r.c1;
			c2s[i] = r.c2;
			i--;
		}

		return (rounds, awards, c1s, c2s);
	}

	function getResults(uint32 v) public view returns (uint256[], address[], uint256[], uint8[], uint8[], uint8[]){
		uint256 len = v;
		if(len == 0 || len >_results.length){
		    len = _results.length;
		}
		
		if(len == 0 ){
			return ;
		}
		
		uint256[] memory rounds = new uint256[](len);
		address[] memory addrs = new address[](len);
		uint256[] memory awards = new uint256[](len); 
		uint8[] memory awardTypes = new uint8[](len);
		uint8[] memory c1s = new uint8[](len);
		uint8[] memory c2s = new uint8[](len);
		uint256 i = _results.length -1; 
		while (i>= _results.length-len) { 
			Result storage r = _results[i];
			rounds[i] = r.round;
			addrs[i] = r.addr;
			awards[i] = r.award;
			awardTypes[i] = r.awardType;
			c1s[i] = r.bet.c1;
			c2s[i] = r.bet.c2;
			i--;
		}

		return (rounds, addrs, awards, awardTypes, c1s, c2s);
	}
	
	function getLastResult() public view returns (uint, address, uint, uint8,  uint, uint, uint){ 
		return (lastResult.round, lastResult.bet.addr, lastResult.award, lastResult.awardType, 
			 lastResult.bet.value, lastResult.bet.c1, lastResult.bet.c2);
	}

/***
 *    .------..------..------.
 *    |A.--. ||2.--. ||1.--. |
 *    | (\/) || (\/) || :/\: |
 *    | :\/: || :\/: || (__) |
 *    | &#39;--&#39;A|| &#39;--&#39;2|| &#39;--&#39;1|
 *    `------&#39;`------&#39;`------&#39;
 *    === private functions ===
 */

	function buyCore() private returns (uint256){
		totalBets++;
		// draw 2 cards 
		(uint c1, uint c2) =  draw(0); 

		uint256 v = eval(c1, c2);

		Bet storage bet =  _bets[numberOfBets++];
		bet.addr = msg.sender;
		bet.value =  uint8(v);
		bet.c1 = uint8(c1);
		bet.c2 = uint8(c2);		
		bet.round = round;
		bet.date = now;
		bet.eth = msg.value; 
		
		// push to hist
		Player storage player = _players[msg.sender];
		player.bets[player.numberOfBets++] = bet;

		emit OnBuy(round, msg.sender, msg.value, bet.value, bet.c1, bet.c2, now);

		return v;
	}

	function newRound() private {
		numberOfBets = 0;
		for(uint8 i =0; i < MAXIMUM_NUMBER_OF_BETS; i++){
			Bet storage bet = _bets[i];
			bet.addr = address(0);
		}

		_cards = new uint[](NUMBER_OF_CARDS);
		for(i=0; i< NUMBER_OF_CARDS; i++){
			_cards[i] = i;
		}
		_cards.length = NUMBER_OF_CARDS;
		round++; 
		startTime = now;

		emit OnNewRound(round, now);
	}

	function endRound() private {
		uint256 awardOfManager = poolValue.mul(profitOfManager).div(100);
		uint256 awardOfFirstPlayer = poolValue.mul(profitOfFirstPlayer).div(100);
		uint256 awardOfWinner = poolValue.mul(profitOfWinner).div(100);

		if(numberOfBets>0 ){
			// check winner
			uint8 i = 0;
			int winner = -1;
			while (i< numberOfBets) {
				if(_bets[i].value == BLACKJACK){				
					winner = int(i);
					break;
				}
				i++;
			}

			address firstPlayerAddr = _bets[0].addr;
			balances[firstPlayerAddr] = balances[firstPlayerAddr].add(awardOfFirstPlayer); 
            _results.push(Result(round, firstPlayerAddr, awardOfFirstPlayer, 1, _bets[0])); //Bet(_bets[0].addr, _bets[0].value, _bets[0].c1, _bets[0].c2, _bets[0].round, _bets[0].date, _bets[0].eth)

            Player storage player = _players[firstPlayerAddr];
	        Bet storage _bet = player.bets[player.numberOfBets-1];
	        _bet.award = _bet.award.add(awardOfFirstPlayer);
	        _bet.awardType = 1;
		        
			emit OnReward(round, firstPlayerAddr, awardOfFirstPlayer, _bets[0].value, _bets[0].c1, _bets[0].c2, now);
			
			if(winner>=0){	
				Bet memory bet = _bets[uint8(winner)];			
				address winAddr = bet.addr; 
				balances[winAddr] = balances[winAddr].add(awardOfWinner);
				lastResult = Result(round, winAddr, awardOfWinner, BLACKJACK, bet) ;//Bet(bet.addr,  bet.value, bet.c1, bet.c2, bet.round, bet.date, bet.eth)
                _results.push(Result(round,winAddr, awardOfWinner, BLACKJACK, bet));
                
                player = _players[winAddr];
		        _bet = player.bets[player.numberOfBets-1];
		        _bet.award = _bet.award.add(awardOfWinner);
		        _bet.awardType = BLACKJACK;
		        
				emit OnWin(round, winAddr, awardOfWinner, bet.value, bet.c1, bet.c2, now);
			}

		}else{
		    // no bets (!o!)
			awardOfWinner = 0;
			awardOfFirstPlayer = 0;
			awardOfManager = 0;
		} 

		balances[manager] = balances[manager].add(awardOfManager); 
		
		poolValue =  poolValue.sub(awardOfManager).sub(awardOfFirstPlayer).sub(awardOfWinner);
		
		releaseCommission();

		newRound();
	}

	function releaseCommission() private {
		// &#128580; in case too busy in developing dapps and have no time to collect team commission 
		// thanks everyone!
		uint256 commission = balances[owner];
		if(commission > 0){
			owner.transfer(commission);
			balances[owner] = 0;
		}

		// For the main reason of gas fee, we don&#39;t release all players&#39; awards, so please withdraw it by yourself. 
	}

	function eval(uint256 c1, uint256 c2)  private pure returns (uint256){
		c1 = cut((c1 % 13) + 1);
		c2 = cut((c2 % 13) + 1);
		if ((c1 == 1 && c2 == 10) || ((c2 == 1 && c1 == 10))) {
			return BLACKJACK;
		}

		if (c1 + c2 > BLACKJACK) {
			return 0;
		}
 
		return c1 + c2;
	}

	function cut(uint256 v) private pure returns (uint256){
		if(v > 10)  {
			return 10;
		}
		
		return v;
	}

	function draw(uint256 randomNumber) private returns (uint, uint) {
	    uint256 max = _cards.length * (_cards.length - 1) /2;
		uint256 ind = randomNumber>0? (randomNumber%max) : rand(max);
		(uint256 i1, uint256 i2) = index2pair(ind);
		uint256 c1 = _cards[i1];
		_cards.removeIndex(i1); 
		uint256 c2 = _cards[i2];
		_cards.removeIndex(i2);
		return (c1, c2);
	}

    //unsafe randoom number, just for local test
	function rand(uint256 max) private view returns (uint256){
		uint256 _seed = uint256(keccak256(abi.encodePacked(
                (block.timestamp) +
                (block.difficulty) +
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
                (block.gaslimit) +
                ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)) +
                (block.number)
        ))); 
		
		return _seed % max; 
	}

	function index2pair(uint x) private pure returns (uint, uint) { 
		uint c1 = ((sqrt(8*x+1) - 1)/2 +1);
		uint c2 = (x - c1*(c1-1)/2);
		return (c1, c2);
	}

	function sqrt(uint x) private pure returns (uint) {
		uint z = (x + 1) / 2;
		uint y = x;
		while (z < y) {
			y = z;
			z = (x / z + z) / 2;
		}

		return y;
	}
 
}


contract GameFactory is Owned {
	uint256 private constant MINIMUM_PRICE = 0.01 ether;
	uint256 private constant MAXIMUM_PRICE = 100 ether;
	uint256 private constant MINIMUM_TIMESPAN = 1 minutes;  
	uint256 private constant MAXIMUM_TIMESPAN = 24 hours;  

    using NameFilter for string;
	mapping(bytes32 => address) public games; 
    bytes32[] public names;
    address[] public addresses;
    address[] public approved;
    address[] public offlines;
    uint256 public fee = 0.2 ether;
    uint8 public numberOfEarlybirds = 10;
    uint256 public numberOfGames = 0;

    event onNewGame (address sender, bytes32 gameName, address gameAddress, uint256 fee, uint256 timestamp);

    function newGame (address _manager, string _name, string _title, uint256 _price, uint256 _timespan,
        uint8 _profitOfManager, uint8 _profitOfFirstPlayer, uint8 _profitOfWinner) 
        limits(msg.value) isActivated payable public 
    {
		require(address(_manager)!=0x0, "invaild address");
		require(_price >= MINIMUM_PRICE && _price <= MAXIMUM_PRICE, "price not in range (MINIMUM_PRICE, MAXIMUM_PRICE)");
		require(_timespan >= MINIMUM_TIMESPAN && _timespan <= MAXIMUM_TIMESPAN, "timespan not in range(MINIMUM_TIMESPAN, MAXIMUM_TIMESPAN)");
		bytes32 name = _name.nameFilter();
        require(name[0] != 0, "invaild name");
        require(checkName(name), "duplicate name");
        require(_profitOfManager <=20, "[profitOfManager] don&#39;t take too much commission :)");
        require(_profitOfFirstPlayer <=50, "[profitOfFirstPlayer] don&#39;t take too much commission :)");
        require(_profitOfWinner <=100 && (_profitOfManager + _profitOfWinner + _profitOfFirstPlayer) <=100, "[profitOfWinner] don&#39;t take too much commission :)");
        require(msg.value >= getTicketPrice(_profitOfManager), "fee is not enough");

        address game = new A21(_manager, name, _title, _price, _timespan, _profitOfManager, _profitOfFirstPlayer, _profitOfWinner);
        games[name] = game; 
        names.push(name);
        addresses.push(game);
        numberOfGames ++;
        owner.transfer(msg.value); 

        if(numberOfGames > numberOfEarlybirds){
            // plus 10% fee everytime    
            // might overflow? I wish as well, however, at that time no one can afford the fee.
            fee +=  (fee/10);        
        }

        emit onNewGame(msg.sender, name, game, fee, now);
    } 

    function checkName(bytes32 _name) view public returns(bool){
        return address(games[_name]) == 0x0;
    }

	function addGame(address _addr) public payable onlyOwner {
	    IGame game = IGame(_addr);  
	    games[game.name()] = _addr;
        names.push(game.name());
	    addresses.push(_addr);
        approved.push(_addr);
        numberOfGames ++;
	}
	
	function approveGame(address _addr) public payable onlyOwner {
        approved.push(_addr);
	}
	
	function offlineGame(address _addr) public payable onlyOwner {
        offlines.push(_addr);
	}
	
	function setFee(uint256 _fee) public payable onlyOwner {
        fee = _fee;
	}

    function getTicketPrice(uint8 _profitOfManager) view public returns(uint256){
        // might overflow? I wish as well, however, at that time no one can afford the fee.
        return fee * _profitOfManager; 
    }

    function getNames() view public returns(bytes32[]){
        return names;
    }

    function getAddresses() view public returns(address[]){
        return addresses;
    }

    function getGame(bytes32 _name) view public returns(
        address, uint256, address, uint256, 
        uint256, uint256, uint256, 
        uint256, uint256, uint256, uint256) {
        require(!checkName(_name), "name not found!");
        address gameAddress = games[_name];
        IGame game = IGame(gameAddress);  
        return (gameAddress, game.price(), game.manager(), game.timespan(), 
            game.profitOfManager(), game.profitOfFirstPlayer(), game.profitOfWinner(), 
            game.round(), gameAddress.balance, game.poolValue(), game.totalBets());
    }

	function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
	}
}