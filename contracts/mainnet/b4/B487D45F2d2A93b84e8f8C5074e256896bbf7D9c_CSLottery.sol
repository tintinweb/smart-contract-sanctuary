pragma solidity ^0.4.18;

/*
VERSION DATE: 23/03/2018

CREATED BY: CRYPTO SPORTZ
UNJOY YOUR TEAM AND SPORTS AND EMAIL US IF YOU HAVE ANY QUESTIONS
*/

contract OraclizeI {
	address public cbAddress;
	function query(uint _timestamp, string _datasource, string _arg) external payable returns (bytes32 _id);
	function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) external payable returns (bytes32 _id);
	function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) public payable returns (bytes32 _id);
	function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) external payable returns (bytes32 _id);
	function queryN(uint _timestamp, string _datasource, bytes _argN) public payable returns (bytes32 _id);
	function queryN_withGasLimit(uint _timestamp, string _datasource, bytes _argN, uint _gaslimit) external payable returns (bytes32 _id);
	function getPrice(string _datasource) public returns (uint _dsprice);
	function getPrice(string _datasource, uint gaslimit) public returns (uint _dsprice);
	function setProofType(byte _proofType) external;
	function setCustomGasPrice(uint _gasPrice) external;
	function randomDS_getSessionPubKeyHash() external constant returns(bytes32);
}
contract OraclizeAddrResolverI {
	function getAddress() public returns (address _addr);
}
contract usingOraclize {
	
	uint8 constant networkID_auto = 0;
	uint8 constant networkID_mainnet = 1;
	uint8 constant networkID_testnet = 2;
	uint8 constant networkID_morden = 2;
	uint8 constant networkID_consensys = 161;

	OraclizeAddrResolverI OAR;

	OraclizeI oraclize;
	modifier oraclizeAPI 
	{
		if((address(OAR)==0)||(getCodeSize(address(OAR))==0))
			oraclize_setNetwork(networkID_auto);

		if(address(oraclize) != OAR.getAddress())
			oraclize = OraclizeI(OAR.getAddress());

		_;
	}
	modifier coupon(string code){
		oraclize = OraclizeI(OAR.getAddress());
		_;
	}

	function oraclize_setNetwork(uint8 networkID) internal returns(bool)
	{
		return oraclize_setNetwork();
		networkID; // silence the warning and remain backwards compatible
	}
	
	function oraclize_setNetwork() internal returns(bool)
	{
		if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed)>0){ //mainnet
			OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
			return true;
		}

		if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1)>0){ //ropsten testnet
			OAR = OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
			return true;
		}

		return false;
	}
	
	function oraclize_query(string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
		uint price = oraclize.getPrice(datasource, gaslimit);
		if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
		return oraclize.query_withGasLimit.value(price)(0, datasource, arg, gaslimit);
	}

    function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
	}
	
	function oraclize_getPrice(string datasource) oraclizeAPI internal returns (uint){
		return oraclize.getPrice(datasource);
	}

	function oraclize_getPrice(string datasource, uint gaslimit) oraclizeAPI internal returns (uint){
		return oraclize.getPrice(datasource, gaslimit);
	}

    function oraclize_setCustomGasPrice(uint gasPrice) oraclizeAPI internal {
        return oraclize.setCustomGasPrice(gasPrice);
    }
	
	function oraclize_cbAddress() oraclizeAPI internal returns (address){
		return oraclize.cbAddress();
	}

	function getCodeSize(address _addr) constant internal returns(uint _size) {
		assembly {
			_size := extcodesize(_addr)
		}
	}

}

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
	string constant public   name = "CryptoSport";
	string constant public symbol = "CS";

	uint256 public totalSupply;
	struct Token
	{
		uint256 price;			//  value of stake
		uint256	option;			//  [payout]96[idLottery]64[combination]32[dateBuy]0
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
			Transfer(_from, _to, _tokenId);
			ownershipTokenCount[_from]--;
			// clear any previously approved ownership exchange
			delete tokenIndexToApproved[_tokenId];
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

contract CSLottery is ERC721, usingOraclize, Functional, Owned
{
	uint256 public feeLottery;
	
	enum Status {
		NOTFOUND,		//0 game not created
		PLAYING,		//1 buying tickets
		PROCESSING,		//2 waiting for result
		PAYING,	 		//3 redeeming
		CANCELING		//4 canceling the game
	}
	
	struct Game {
		string  nameLottery;
		uint32  countCombinations;
		uint32  dateStopBuy;
		uint32  minStake;				// per finney = 0.001E
		uint32  winCombination;
		uint256 betsSumIn;				// amount bets
		uint256 feeValue;				// amount fee
		Status status;					// status of game
		bool isFreezing;
	}
	Game[] private game;
	
	struct Stake {
		uint256 sum;		// amount bets
		uint32 count;		// count bets 
	}
	mapping(uint32 => mapping (uint32 => Stake)) public betsAll; // ID-lottery => combination => Stake
	mapping(bytes32 => uint32) private queryRes;  // ID-query => ID-lottery
	
	uint256 public ORACLIZE_GAS_LIMIT = 200000;
	uint256 public ORACLIZE_GASPRICE_GWEY = 40; // 40Gwey

	event LogEvent(string _event, string nameLottery, uint256 value);
	event LogToken(string _event, address user, uint32 idLottery, uint32 idToken, uint32 combination, uint256 amount);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
	
	modifier onlyAdmin {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

	modifier onlyOraclize {
        require (msg.sender == oraclize_cbAddress());
        _;
    }

	function getLotteryByID(uint32 _id) public view returns (
		string  nameLottery,
		uint32 countCombinations,
		uint32 dateStopBuy,
		uint32 minStake,
		uint32 winCombination,
		uint32 betsCount,
		uint256 betsSumIn,
		uint256 feeValue,
		Status status,
		bool isFreezing
	){
		Game storage gm = game[_id];
		nameLottery = gm.nameLottery;
		countCombinations = gm.countCombinations;
		dateStopBuy = gm.dateStopBuy;
		minStake = gm.minStake;
		winCombination = gm.winCombination;
		betsCount = getCountTokensByLottery(_id);
		betsSumIn = gm.betsSumIn;  
		if (betsSumIn==0) betsSumIn = getSumInByLottery(_id);
		feeValue = gm.feeValue;
		status = gm.status;
		if ( status == Status.PLAYING && timenow() > dateStopBuy ) status = Status.PROCESSING;
		isFreezing = gm.isFreezing;
	}
	
	function getCountTokensByLottery(uint32 idLottery) internal view returns (uint32)
	{
		Game storage curGame = game[idLottery];
		uint32 count = 0;
		for(uint32 i=1;i<=curGame.countCombinations;i++) count += betsAll[idLottery][i].count;
		return count;
	}
	
	function getSumInByLottery(uint32 idLottery) internal view returns (uint256)
	{
		Game storage curGame = game[idLottery];
		uint256 sum = 0;
		for(uint32 i=1;i<=curGame.countCombinations;i++) sum += betsAll[idLottery][i].sum;
		return sum;
	}
	
	function getTokenByID(uint256 _id) public view returns ( 
			uint256 price,
			uint256 payment,
			uint32 combination,
			uint32 dateBuy,
			uint32 idLottery,
			address ownerToken,
			bool payout
	){
		Token storage tkn = tokens[_id];

		price = tkn.price;
		
		uint256 packed = tkn.option;
		payout = uint8((packed >> (12*8)) & 0xFF)==1?true:false;
		idLottery   = uint32((packed >> (8*8)) & 0xFFFFFFFF);
		combination = uint32((packed >> (4*8)) & 0xFFFFFFFF);
		dateBuy     = uint32(packed & 0xFFFFFFFF);

		payment = 0;
		Game storage curGame = game[idLottery];
		
		uint256 betsSumIn = curGame.betsSumIn;  
		if (betsSumIn==0) betsSumIn = getSumInByLottery(idLottery);

		if (curGame.winCombination==combination) payment = betsSumIn * tkn.price / betsAll[idLottery][ curGame.winCombination ].sum;
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

	function getStatLotteries() public view returns ( 
			uint32 countAll,
			uint32 countPlaying,
			uint32 countProcessing,
			string listPlaying,
			string listProcessing
	){
		countAll = uint32(game.length);
		countPlaying = 0;
		countProcessing = 0;
		listPlaying="";
		listProcessing="";
		uint32 curtime = timenow();
		for (uint32 i = 0; i < countAll; i++)
		{
			if (game[i].status!=Status.PLAYING) continue;
			if (curtime <  game[i].dateStopBuy) { countPlaying++; listPlaying = strConcat( listPlaying, ",", uint2str(i) ); }
			if (curtime >= game[i].dateStopBuy) { countProcessing++; listProcessing = strConcat( listProcessing, ",", uint2str(i) ); }
		}
		
	}

	function CSLottery() public 
	{
	}

	function setOraclizeGasPrice(uint256 priceGwey, uint256 limit) onlyAdmin public
	{
		ORACLIZE_GASPRICE_GWEY = priceGwey;
		ORACLIZE_GAS_LIMIT = limit;
		oraclize_setCustomGasPrice( uint256(ORACLIZE_GASPRICE_GWEY) * 10**9 );
	}

	function freezeLottery(uint32 idLottery, bool freeze) public onlyAdmin 
	{ 
		Game storage curGame = game[idLottery];
		require( curGame.isFreezing != freeze );
		curGame.isFreezing = freeze; 
	}

	function addLottery( string _nameLottery, uint32 _dateStopBuy, uint32 _countCombinations, uint32 _minStakeFinney ) onlyAdmin public 
	{
		require( bytes(_nameLottery).length > 2 );
		require( _countCombinations > 1 );
		require( _minStakeFinney > 0 );
		require( _dateStopBuy > timenow() );

		Game memory _game;
		_game.nameLottery = _nameLottery;
		_game.countCombinations = _countCombinations;
		_game.dateStopBuy = _dateStopBuy;
		_game.minStake 	= _minStakeFinney;
		_game.status = Status.PLAYING;

		uint256 newGameId = game.push(_game) - 1;
		
		LogEvent( "AddGame", _nameLottery, newGameId );
	}

	function () payable public { require (msg.value == 0x0); }
	
	function buyToken(uint32 idLottery, uint32 combination, address captainAddress) payable public
	{
		Game storage curGame = game[idLottery];
		require( curGame.status == Status.PLAYING );
		require( timenow() < curGame.dateStopBuy );
		require( combination > 0 && combination <= curGame.countCombinations );
		require( captainAddress != msg.sender );
		require( curGame.isFreezing == false );
		
		// check money for stake
		require( msg.value >= curGame.minStake * 1 finney );
		
		uint256 userStake = msg.value;
		uint256 feeValue = userStake * 5 / 100;		// 5% fee for contract
		userStake = userStake - feeValue;
		
		if (captainAddress!=0x0) 
		{
			uint256 captainValue = feeValue * 20 / 100;		// bonus for captain = 1%
			feeValue = feeValue - captainValue;
			require(feeValue + captainValue + userStake == msg.value);
			captainAddress.transfer(captainValue);
		}

		curGame.feeValue  = curGame.feeValue + feeValue;
		betsAll[idLottery][combination].sum += userStake;
		betsAll[idLottery][combination].count += 1;

		uint128 packed;
		packed = ( uint128(idLottery) << 8*8 ) + ( uint128(combination) << 4*8 ) + uint128(block.timestamp);

		Token memory _token = Token({
			price: userStake,
			option : packed
		});

		uint256 newTokenId = totalSupply++;
		tokens[newTokenId] = _token;
		_transfer(0, msg.sender, newTokenId);
		LogToken( "Buy", msg.sender, idLottery, uint32(newTokenId), combination, userStake);
	}
	
	// take win money or money for canceling lottery
	function redeemToken(uint256 _tokenId) public 
	{
		Token storage tkn = tokens[_tokenId];

		uint256 packed = tkn.option;
		bool payout = uint8((packed >> (12*8)) & 0xFF)==1?true:false;
		uint32 idLottery = uint32((packed >> (8*8)) & 0xFFFFFFFF);
		uint32 combination = uint32((packed >> (4*8)) & 0xFFFFFFFF);

		Game storage curGame = game[idLottery];
		
		require( curGame.status == Status.PAYING || curGame.status == Status.CANCELING);

		require( msg.sender == tokenIndexToOwner[_tokenId] );	// only onwer`s token
		require( payout == false ); // has not paid
		require( combination == curGame.winCombination || curGame.status == Status.CANCELING );

		uint256 sumPayment = 0;
		if ( curGame.status == Status.CANCELING ) sumPayment = tkn.price;
		if ( curGame.status == Status.PAYING ) sumPayment = curGame.betsSumIn * tkn.price / betsAll[idLottery][curGame.winCombination].sum;

		payout = true;
		packed += uint128(payout?1:0) << 12*8;
		tkn.option = packed;
	
		msg.sender.transfer(sumPayment);
		
		LogToken( "Redeem", msg.sender, idLottery, uint32(_tokenId), combination, sumPayment);
	}
	
	function cancelLottery(uint32 idLottery) public 
	{
		Game storage curGame = game[idLottery];
		
		require( curGame.status == Status.PLAYING );
		// only owner/admin or anybody after 7 days
		require( msg.sender == owner || admins[msg.sender] || timenow() > curGame.dateStopBuy + 7 * 24*60*60 );

		curGame.status = Status.CANCELING;

		LogEvent( "CancelLottery", curGame.nameLottery, idLottery );
		
		takeFee(idLottery);
	}

	function __callback(bytes32 queryId, string _result) onlyOraclize public
	{
		uint32 idLottery = queryRes[queryId];
		require( idLottery != 0 );

		Game storage curGame = game[idLottery];
		
		require( curGame.status == Status.PLAYING );
		require( timenow() > curGame.dateStopBuy );
		
		uint32 tmpCombination = uint32(parseInt(_result,0));
		
		string memory error = "callback";
		if ( tmpCombination==0 ) error = "callback_result_not_found";
		if ( tmpCombination > curGame.countCombinations ) { tmpCombination = 0; error = "callback_result_limit"; }

		LogEvent( error, curGame.nameLottery, tmpCombination );

		if (tmpCombination!=0) 
		{
			curGame.winCombination = tmpCombination;
			checkWinNobody(idLottery);
		}
	}

	function resolveLotteryByOraclize(uint32 idLottery, uint32 delaySec) onlyAdmin public payable
	{
		Game storage curGame = game[idLottery];
		
		uint oraclizeFee = oraclize_getPrice( "URL", ORACLIZE_GAS_LIMIT );
		require(msg.value + curGame.feeValue > oraclizeFee); // if contract has not enought money to do query
		
		curGame.feeValue = curGame.feeValue + msg.value - oraclizeFee;

		LogEvent( "ResolveLotteryByOraclize", curGame.nameLottery, delaySec );
		
		string memory tmpQuery;
		tmpQuery = strConcat( "json(https://cryptosportz.com/api/v2/game/", uint2str(idLottery), "/result).result" );
	
		uint32 delay;
		if ( timenow() < curGame.dateStopBuy ) delay = curGame.dateStopBuy - timenow() + delaySec;
										  else delay = delaySec;
	
		bytes32 queryId = oraclize_query(delay, "URL", tmpQuery, ORACLIZE_GAS_LIMIT);
		queryRes[queryId] = idLottery;
	}

	function resolveLotteryByHand(uint32 idLottery, uint32 combination) onlyAdmin public 
	{
		Game storage curGame = game[idLottery];
		
		require( curGame.status == Status.PLAYING );
		require( combination <= curGame.countCombinations );
		require( combination != 0 );

		require( timenow() > curGame.dateStopBuy + 2*60*60 );

		curGame.winCombination = combination;
		
		LogEvent( "ResolveLotteryByHand", curGame.nameLottery, curGame.winCombination );
		
		checkWinNobody(idLottery);
	}
	
	function checkWinNobody(uint32 idLottery) internal
	{
		Game storage curGame = game[idLottery];
		
		curGame.status = Status.PAYING;
		curGame.betsSumIn = getSumInByLottery(idLottery);
		
		// nobody win = send all to feeLottery
		if ( betsAll[idLottery][curGame.winCombination].count == 0 )
		{
			if (curGame.betsSumIn+curGame.feeValue!=0) feeLottery = feeLottery + curGame.betsSumIn + curGame.feeValue;
			LogEvent( "NOBODYWIN", curGame.nameLottery, curGame.betsSumIn+curGame.feeValue );
		}
		else 
			takeFee(idLottery);
	}
	
	function takeFee(uint32 idLottery) internal
	{
		Game storage curGame = game[idLottery];
		
		// take fee
		if ( curGame.feeValue > 0 )
		{
			feeLottery = feeLottery + curGame.feeValue;
			LogEvent( "TakeFee", curGame.nameLottery, curGame.feeValue );
		}
	}
	
	function withdraw() onlyOwner public
	{
		require( feeLottery > 0 );

		uint256 tmpFeeLottery = feeLottery;
		feeLottery = 0;
		
		owner.transfer(tmpFeeLottery);
		LogEvent( "WITHDRAW", "", tmpFeeLottery);
	}

}