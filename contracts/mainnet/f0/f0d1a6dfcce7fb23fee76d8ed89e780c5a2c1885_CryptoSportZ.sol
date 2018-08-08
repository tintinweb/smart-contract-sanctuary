pragma solidity ^0.4.18;

/*
VERSION DATE: 04/06/2018

CREATED BY: CRYPTO SPORTZ
ENJOY YOUR TEAM AND SPORTS AND EMAIL US IF YOU HAVE ANY QUESTIONS
*/

contract ERC721Abstract
{
	function implementsERC721() public pure returns (bool);
	function balanceOf(address _owner) public view returns (uint256 balance);
	function ownerOf(uint256 _tokenId) public view returns (address owner);
	function approve(address _to, uint256 _tokenId) public;
	function transferFrom(address _from, address _to, uint256 _tokenId) public;
	function transfer(address _to, uint256 _tokenId) public;
 
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

	// Optional
	// function totalSupply() public view returns (uint256 total);
	// function name() public view returns (string name);
	// function symbol() public view returns (string symbol);
	// function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
	// function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}

contract ERC721 is ERC721Abstract
{
	string constant public   name = "CryptoSportZ";
	string constant public symbol = "CSZ";

	uint256 public totalSupply;
	struct Token
	{
		uint256 price;			//  value of stake
		uint256	option;			//  [payout]96[idGame]64[combination]32[dateBuy]0
	}
	mapping (uint256 => Token) tokens;
	
	// A mapping from tokens IDs to the address that owns them. All tokens have some valid owner address
	mapping (uint256 => address) public tokenIndexToOwner;
	
	// A mapping from owner address to count of tokens that address owns.	
	mapping (address => uint256) ownershipTokenCount; 

	// A mapping from tokenIDs to an address that has been approved to call transferFrom().
	// Each token can only have one approved address for transfer at any time.
	// A zero value means no approval is outstanding.
	mapping (uint256 => address) public tokenIndexToApproved;
	
	function implementsERC721() public pure returns (bool)
	{
		return true;
	}

	function balanceOf(address _owner) public view returns (uint256 count) 
	{
		return ownershipTokenCount[_owner];
	}
	
	function ownerOf(uint256 _tokenId) public view returns (address owner)
	{
		owner = tokenIndexToOwner[_tokenId];
		require(owner != address(0));
	}
	
	// Marks an address as being approved for transferFrom(), overwriting any previous approval. 
	// Setting _approved to address(0) clears all transfer approval.
	function _approve(uint256 _tokenId, address _approved) internal 
	{
		tokenIndexToApproved[_tokenId] = _approved;
	}
	
	// Checks if a given address currently has transferApproval for a particular token.
	// param _claimant the address we are confirming token is approved for.
	// param _tokenId token id, only valid when > 0
	function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
		return tokenIndexToApproved[_tokenId] == _claimant;
	}
	
	function approve( address _to, uint256 _tokenId ) public
	{
		// Only an owner can grant transfer approval.
		require(_owns(msg.sender, _tokenId));

		// Register the approval (replacing any previous approval).
		_approve(_tokenId, _to);

		// Emit approval event.
		Approval(msg.sender, _to, _tokenId);
	}
	
	function transferFrom( address _from, address _to, uint256 _tokenId ) public
	{
		// Check for approval and valid ownership
		require(_approvedFor(msg.sender, _tokenId));
		require(_owns(_from, _tokenId));

		// Reassign ownership (also clears pending approvals and emits Transfer event).
		_transfer(_from, _to, _tokenId);
	}
	
	function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
		return tokenIndexToOwner[_tokenId] == _claimant;
	}
	
	function _transfer(address _from, address _to, uint256 _tokenId) internal 
	{
		ownershipTokenCount[_to]++;
		tokenIndexToOwner[_tokenId] = _to;

		if (_from != address(0)) 
		{
			ownershipTokenCount[_from]--;
			// clear any previously approved ownership exchange
			delete tokenIndexToApproved[_tokenId];
			Transfer(_from, _to, _tokenId);
		}

	}
	
	function transfer(address _to, uint256 _tokenId) public
	{
		require(_to != address(0));
		require(_owns(msg.sender, _tokenId));
		_transfer(msg.sender, _to, _tokenId);
	}

}

contract Owned 
{
    address private candidate;
	address public owner;

	mapping(address => bool) public admins;
	
    function Owned() public 
	{
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public 
	{
		require(msg.sender == owner);
        candidate = newOwner;
    }
	
	function confirmOwner() public 
	{
        require(candidate == msg.sender); // run by name=candidate
		owner = candidate;
    }
	
    function addAdmin(address addr) external 
	{
		require(msg.sender == owner);
        admins[addr] = true;
    }

    function removeAdmin(address addr) external
	{
		require(msg.sender == owner);
        admins[addr] = false;
    }
}

contract Functional
{
	// parseInt(parseFloat*10^_b)
	function parseInt(string _a, uint _b) internal pure returns (uint) 
	{
		bytes memory bresult = bytes(_a);
		uint mint = 0;
		bool decimals = false;
		for (uint i=0; i<bresult.length; i++){
			if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
				if (decimals){
				   if (_b == 0) break;
					else _b--;
				}
				mint *= 10;
				mint += uint(bresult[i]) - 48;
			} else if (bresult[i] == 46) decimals = true;
		}
		if (_b > 0) mint *= 10**_b;
		return mint;
	}
	
	function uint2str(uint i) internal pure returns (string)
	{
		if (i == 0) return "0";
		uint j = i;
		uint len;
		while (j != 0){
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint k = len - 1;
		while (i != 0){
			bstr[k--] = byte(48 + i % 10);
			i /= 10;
		}
		return string(bstr);
	}
	
	function strConcat(string _a, string _b, string _c) internal pure returns (string)
	{
		bytes memory _ba = bytes(_a);
		bytes memory _bb = bytes(_b);
		bytes memory _bc = bytes(_c);
		string memory abc;
		uint k = 0;
		uint i;
		bytes memory babc;
		if (_ba.length==0)
		{
			abc = new string(_bc.length);
			babc = bytes(abc);
		}
		else
		{
			abc = new string(_ba.length + _bb.length+ _bc.length);
			babc = bytes(abc);
			for (i = 0; i < _ba.length; i++) babc[k++] = _ba[i];
			for (i = 0; i < _bb.length; i++) babc[k++] = _bb[i];
		}
        for (i = 0; i < _bc.length; i++) babc[k++] = _bc[i];
		return string(babc);
	}
	
	function timenow() public view returns(uint32) { return uint32(block.timestamp); }
}

contract CryptoSportZ is ERC721, Functional, Owned
{
	uint256 public feeGame;
	
	enum Status {
		NOTFOUND,		//0 game not created
		PLAYING,		//1 buying tickets
		PROCESSING,		//2 waiting for result
		PAYING,	 		//3 redeeming
		CANCELING		//4 canceling the game
	}
	
	struct Game {
		string  nameGame;
		uint32  countCombinations;
		uint32  dateStopBuy;
		uint32  winCombination;
		uint256 betsSumIn;				// amount bets
		uint256 feeValue;				// amount fee
		Status status;					// status of game
		bool isFreezing;
	}

	mapping (uint256 => Game) private game;
	uint32 public countGames;
	
	uint32 private constant shiftGame = 0;
	uint32 private constant FEECONTRACT = 5;
	
	struct Stake {
		uint256 sum;		// amount bets
		uint32 count;		// count bets 
	}
	mapping(uint32 => mapping (uint32 => Stake)) public betsAll; // ID-game => combination => Stake
	mapping(bytes32 => uint32) private queryRes;  // ID-query => ID-game
	
	event LogEvent(string _event, string nameGame, uint256 value);
	event LogToken(string _event, address user, uint32 idGame, uint256 idToken, uint32 combination, uint256 amount);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
	
	modifier onlyAdmin {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

	function getPriceTicket() public view returns ( uint32 )
	{
		if ( timenow() >= 1531339200 ) return 8000;	// after 11.07 20:00
		if ( timenow() >= 1530993600 ) return 4000;	// after 07.07 20:00
		if ( timenow() >= 1530648000 ) return 2000;	// after 03.06 20:00
		if ( timenow() >= 1530302400 ) return 1000;	// after 29.06 20:00
		if ( timenow() >= 1529870400 ) return 500;	// after 24.06 20:00
		if ( timenow() >= 1529438400 ) return 400;	// after 19.06 20:00
		if ( timenow() >= 1529006400 ) return 300;	// after 14.06 20:00
		if ( timenow() >= 1528747200 ) return 200;	// after 11.06 20:00
		if ( timenow() >= 1528401600 ) return 100;	// after 07.06 20:00
		return 50;
	}
	
	function getGameByID(uint32 _id) public view returns (
		string  nameGame,
		uint32 countCombinations,
		uint32 dateStopBuy,
		uint32 priceTicket,
		uint32 winCombination,
		uint32 betsCount,
		uint256 betsSumIn,
		uint256 feeValue,
		Status status,
		bool isFreezing
	){
		Game storage gm = game[_id];
		nameGame = gm.nameGame;
		countCombinations = gm.countCombinations;
		dateStopBuy = gm.dateStopBuy;
		priceTicket = getPriceTicket();
		winCombination = gm.winCombination;
		betsCount = getCountTokensByGame(_id);
		betsSumIn = gm.betsSumIn;  
		if (betsSumIn==0) betsSumIn = getSumInByGame(_id);
		feeValue = gm.feeValue;
		status = gm.status;
		if ( status == Status.PLAYING && timenow() > dateStopBuy ) status = Status.PROCESSING;
		isFreezing = gm.isFreezing;
	}
	
	function getBetsMas(uint32 idGame) public view returns (uint32[33])
	{
		Game storage curGame = game[idGame];
		uint32[33] memory res;
		for(uint32 i=1;i<=curGame.countCombinations;i++) res[i] = betsAll[idGame][i].count;
		return res;
	}
	
	function getCountTokensByGame(uint32 idGame) internal view returns (uint32)
	{
		Game storage curGame = game[idGame];
		uint32 count = 0;
		for(uint32 i=1;i<=curGame.countCombinations;i++) count += betsAll[idGame][i].count;
		return count;
	}
	
	function getSumInByGame(uint32 idGame) internal view returns (uint256)
	{
		Game storage curGame = game[idGame];
		uint256 sum = 0;
		for(uint32 i=1;i<=curGame.countCombinations;i++) sum += betsAll[idGame][i].sum;
		return sum;
	}
	
	function getTokenByID(uint256 _id) public view returns ( 
			uint256 price,
			uint256 payment,
			uint32 combination,
			uint32 dateBuy,
			uint32 idGame,
			address ownerToken,
			bool payout
	){
		Token storage tkn = tokens[_id];

		price = tkn.price;
		
		uint256 packed = tkn.option;
		payout 		= uint8((packed >> (12*8)) & 0xFF)==1?true:false;
		idGame  	= uint32((packed >> (8*8)) & 0xFFFFFFFF);
		combination = uint32((packed >> (4*8)) & 0xFFFFFFFF);
		dateBuy     = uint32(packed & 0xFFFFFFFF);

		payment = 0;
		Game storage curGame = game[idGame];
		
		uint256 betsSumIn = curGame.betsSumIn;  
		if (betsSumIn==0) betsSumIn = getSumInByGame(idGame);

		if (curGame.winCombination==combination) payment = betsSumIn / betsAll[idGame][ curGame.winCombination ].count;
		if (curGame.status == Status.CANCELING) payment = tkn.price;
		
		ownerToken = tokenIndexToOwner[_id];
	}

	function getUserTokens(address user, uint32 count) public view returns ( string res )
	{
		res="";
		require(user!=0x0);
		uint32 findCount=0;
		for (uint256 i = totalSupply-1; i >= 0; i--)
		{
			if(i>totalSupply) break;
			if (user == tokenIndexToOwner[i]) 
			{
				res = strConcat( res, ",", uint2str(i) );
				findCount++;
				if (count!=0 && findCount>=count) break;
			}
		}
	}
	
	function getUserTokensByGame(address user, uint32 idGame) public view returns ( string res )
	{
		res="";
		require(user!=0x0);
		for(uint256 i=0;i<totalSupply;i++) 
		{
			if (user == tokenIndexToOwner[i]) 
			{
				uint256 packed = tokens[i].option;
				uint32 idGameToken = uint32((packed >> (8*8)) & 0xFFFFFFFF);
				if (idGameToken == idGame) res = strConcat( res, ",", uint2str(i) );
			}
		}
	}
	
	function getTokensByGame(uint32 idGame) public view returns (string res)
	{
		res="";
		for(uint256 i=0;i<totalSupply;i++) 
		{
			uint256 packed = tokens[i].option;
			uint32 idGameToken = uint32((packed >> (8*8)) & 0xFFFFFFFF);
			if (idGameToken == idGame) res = strConcat( res, ",", uint2str(i) );
		}
	}	
	
	function getStatGames() public view returns ( 
			uint32 countAll,
			uint32 countPlaying,
			uint32 countProcessing,
			string listPlaying,
			string listProcessing
	){
		countAll = countGames;
		countPlaying = 0;
		countProcessing = 0;
		listPlaying="";
		listProcessing="";
		uint32 curtime = timenow();
		for(uint32 i=shiftGame; i<countAll+shiftGame; i++)
		{
			if (game[i].status!=Status.PLAYING) continue;
			if (curtime <  game[i].dateStopBuy) { countPlaying++; listPlaying = strConcat( listPlaying, ",", uint2str(i) ); }
			if (curtime >= game[i].dateStopBuy) { countProcessing++; listProcessing = strConcat( listProcessing, ",", uint2str(i) ); }
		}
	}
	function CryptoSportZ() public 
	{
	}

	function freezeGame(uint32 idGame, bool freeze) public onlyAdmin 
	{
		Game storage curGame = game[idGame];
		require( curGame.isFreezing != freeze );
		curGame.isFreezing = freeze; 
	}
	
	function addGame( string _nameGame ) onlyAdmin public 
	{
		require( bytes(_nameGame).length > 2 );

		Game memory _game;
		_game.nameGame = _nameGame;
		_game.countCombinations = 32;
		_game.dateStopBuy = 1531666800;
		_game.status = Status.PLAYING;

		uint256 newGameId = countGames + shiftGame;
		game[newGameId] = _game;
		countGames++;
		
		LogEvent( "AddGame", _nameGame, newGameId );
	}

	function () payable public { require (msg.value == 0x0); }
	
	function buyToken(uint32 idGame, uint32 combination, address captainAddress) payable public
	{
		Game storage curGame = game[idGame];
		require( curGame.status == Status.PLAYING );
		require( timenow() < curGame.dateStopBuy );
		require( combination > 0 && combination <= curGame.countCombinations );
		require( curGame.isFreezing == false );
		
		uint256 userStake = msg.value;
		uint256 ticketPrice = uint256(getPriceTicket()) * 1 finney;
		
		// check money for stake
		require( userStake >= ticketPrice );
		
		if ( userStake > ticketPrice )
		{
			uint256 change = userStake - ticketPrice;
			userStake = userStake - change;
			require( userStake == ticketPrice );
			msg.sender.transfer(change);
		}
		
		uint256 feeValue = userStake * FEECONTRACT / 100;		// fee for contract

		if (captainAddress!=0x0 && captainAddress != msg.sender) 
		{
			uint256 captainValue = feeValue * 20 / 100;		// bonus for captain = 1%
			feeValue = feeValue - captainValue;
			captainAddress.transfer(captainValue);
		}

		userStake = userStake - feeValue;	
		curGame.feeValue  = curGame.feeValue + feeValue;
		
		betsAll[idGame][combination].sum += userStake;
		betsAll[idGame][combination].count += 1;

		uint256 packed;
		packed = ( uint128(idGame) << 8*8 ) + ( uint128(combination) << 4*8 ) + uint128(block.timestamp);

		Token memory _token = Token({
			price: userStake,
			option : packed
		});

		uint256 newTokenId = totalSupply++;
		tokens[newTokenId] = _token;
		_transfer(0x0, msg.sender, newTokenId);
		LogToken( "Buy", msg.sender, idGame, newTokenId, combination, userStake);
	}
	
	// take win money or money for canceling game
	function redeemToken(uint256 _tokenId) public 
	{
		Token storage tkn = tokens[_tokenId];

		uint256 packed = tkn.option;
		bool payout = uint8((packed >> (12*8)) & 0xFF)==1?true:false;
		uint32 idGame = uint32((packed >> (8*8)) & 0xFFFFFFFF);
		uint32 combination = uint32((packed >> (4*8)) & 0xFFFFFFFF);

		Game storage curGame = game[idGame];
		
		require( curGame.status == Status.PAYING || curGame.status == Status.CANCELING);

		require( msg.sender == tokenIndexToOwner[_tokenId] );	// only onwer`s token
		require( payout == false ); // has not paid
		require( combination == curGame.winCombination || curGame.status == Status.CANCELING );

		uint256 sumPayment = 0;
		if ( curGame.status == Status.CANCELING ) sumPayment = tkn.price;
		if ( curGame.status == Status.PAYING ) sumPayment = curGame.betsSumIn / betsAll[idGame][curGame.winCombination].count;

		payout = true;
		packed += uint128(payout?1:0) << 12*8;
		tkn.option = packed;
	
		msg.sender.transfer(sumPayment);
		
		LogToken( "Redeem", msg.sender, idGame, uint32(_tokenId), combination, sumPayment);
	}
	
	function cancelGame(uint32 idGame) public 
	{
		Game storage curGame = game[idGame];
		
		require( curGame.status == Status.PLAYING );
		// only owner/admin or anybody after 60 days
		require( msg.sender == owner || admins[msg.sender] || timenow() > curGame.dateStopBuy + 60 days );

		curGame.status = Status.CANCELING;

//		LogEvent( "CancelGame", curGame.nameGame, idGame );
		
		takeFee(idGame);
	}

	function resolveGameByHand(uint32 idGame, uint32 combination) onlyAdmin public 
	{
		Game storage curGame = game[idGame];
		
		require( curGame.status == Status.PLAYING );
		require( combination <= curGame.countCombinations );
		require( combination != 0 );

		require( timenow() > curGame.dateStopBuy + 2*60*60 );

		curGame.winCombination = combination;
		
//		LogEvent( "ResolveGameByHand", curGame.nameGame, curGame.winCombination );
		
		checkWinNobody(idGame);
	}
	
	function checkWinNobody(uint32 idGame) internal
	{
		Game storage curGame = game[idGame];
		
		curGame.status = Status.PAYING;
		curGame.betsSumIn = getSumInByGame(idGame);
		
		// nobody win = send all to feeGame
		if ( betsAll[idGame][curGame.winCombination].count == 0 )
		{
			if (curGame.betsSumIn+curGame.feeValue!=0) feeGame = feeGame + curGame.betsSumIn + curGame.feeValue;
			LogEvent( "NobodyWin", curGame.nameGame, curGame.betsSumIn+curGame.feeValue );
		}
		else 
			takeFee(idGame);
	}
	
	function takeFee(uint32 idGame) internal
	{
		Game storage curGame = game[idGame];
		
		// take fee
		if ( curGame.feeValue > 0 )
		{
			feeGame = feeGame + curGame.feeValue;
			LogEvent( "TakeFee", curGame.nameGame, curGame.feeValue );
		}
	}
	
	function withdraw() onlyOwner public
	{
		require( feeGame > 0 );

		uint256 tmpFeeGame = feeGame;
		feeGame = 0;
		
		owner.transfer(tmpFeeGame);
//		LogEvent( "Withdraw", "", tmpFeeGame);
	}

}