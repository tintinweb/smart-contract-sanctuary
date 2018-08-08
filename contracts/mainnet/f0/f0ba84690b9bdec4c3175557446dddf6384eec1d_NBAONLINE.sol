pragma solidity ^0.4.19;
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
	string constant public   name = "NBA ONLINE";
	string constant public symbol = "Ticket";

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
		emit Approval(msg.sender, _to, _tokenId);
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
			emit Transfer(_from, _to, _tokenId);
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
        admins[owner] = true;
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
contract NBAONLINE is Functional,Owned,ERC721{
    using SafeMath for uint256;
    
    enum STATUS {
		NOTFOUND,		//0 game not created
		PLAYING,		//1 buying tickets for players
		PROCESSING,		//2 waiting for result
		PAYING,	 		//3 redeeming
		REFUNDING		//4 canceling the game
	}
    struct Game{
        string name;                                //GameName
        uint256 id;                                 //Game ID
        uint256 totalPot;                           //Total Deposit 
        uint256 totalWinnersDeposit;                //Total Winner Deposit
        uint256 dateStopBuy;                        //Deadline of buying tickets of the game
        STATUS status;                              //Game Status 
        mapping(uint8=>uint256)potDetail;           //The amount of each player in a Game
        mapping(uint8=>uint8)result;                //The results of 30 players in a game 0:Lose 1: Win
    }
    mapping(uint256=>Game)private games;            //id find game
    uint256[] private gameIdList;
    
    uint256 private constant min_amount = 0.005 ether;
    uint256 private constant max_amount = 1000 ether;
    
    function NBAONLINE () public {
    }

    /* Modifiers */
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    modifier onlyAdmin {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    function addOneGame(string _name,uint256 _deadline)onlyAdmin() external{
        uint256 _id = gameIdList.length;
        require(games[_id].status == STATUS.NOTFOUND);
        require( _deadline > timenow() );
        games[_id] = Game(_name,_id,0,0,_deadline,STATUS.PLAYING);
        gameIdList.push(_id);
    }
    function getGamesLength()public view returns(uint256 length){
        return gameIdList.length;
    }
    function calculateDevCut (uint256 _price) public pure returns (uint256 _devCut) {
        return _price.mul(5).div(100); // 5%
    }
    function generateTicketData(uint256 idLottery, uint8 combination,uint8 status) public view returns(uint256 packed){
        packed = (uint256(status) << 12*8) + ( uint256(idLottery) << 8*8 ) + ( uint256(combination) << 4*8 ) + uint256(block.timestamp);
    }
    
    function parseTicket(uint256	packed)public pure returns(uint8 payout,uint256 idLottery,uint256 combination,uint256 dateBuy){
		payout = uint8((packed >> (12*8)) & 0xFF);
		idLottery   = uint256((packed >> (8*8)) & 0xFFFFFFFF);
		combination = uint256((packed >> (4*8)) & 0xFFFFFFFF);
		dateBuy     = uint256(packed & 0xFFFFFFFF);
    }
    
    function updateTicketStatus(uint256	packed,uint8 newStatus)public pure returns(uint256 npacked){
		uint8 payout = uint8((packed >> (12*8)) & 0xFF);
		npacked = packed + (uint256(newStatus-payout)<< 12*8);
    }
    function buyTicket(uint256 _id, uint8 _choose)payable external{
        Game storage curGame = games[_id];
        require(curGame.status == STATUS.PLAYING);
        require( timenow() < curGame.dateStopBuy );
        require(msg.value >= min_amount);
        require(msg.value <= max_amount);
        require(_choose < 30&&_choose >= 0);
        uint256 dev = calculateDevCut(msg.value);
        uint256 deposit = msg.value.sub(dev);
        curGame.totalPot = curGame.totalPot.add(deposit);
        curGame.potDetail[_choose] = curGame.potDetail[_choose].add(deposit);

		Token memory _token = Token({
			price: deposit,
			option : generateTicketData(_id,_choose,0)
		});

		uint256 newTokenId = totalSupply++;
		tokens[newTokenId] = _token;
		_transfer(0, msg.sender, newTokenId);

        if(dev > 0){
            owner.transfer(dev);
        }
    }
    function cancelTicket(uint256 _tid)payable external{
        //confirm ownership
        require(tokenIndexToOwner[_tid] == msg.sender);
        Token storage _token = tokens[_tid];
        uint256 gameId   = uint256((_token.option >> (8*8)) & 0xFFFFFFFF);
        Game storage curGame = games[gameId];
        //confirm game status
        require(curGame.status == STATUS.PLAYING);
        //confirm game time 
        require( timenow() < curGame.dateStopBuy );
        uint8 ticketStatus = uint8((_token.option >> (12*8)) & 0xFF);
        //confirm ticket status
        require(ticketStatus == 0);
        uint256 refundFee = _token.price;
        //confirm ticket price
        require(refundFee > 0);
        uint8 _choose = uint8((_token.option >> (4*8)) & 0xFFFFFFFF);
        curGame.totalPot = curGame.totalPot.sub(refundFee);
        curGame.potDetail[_choose] = curGame.potDetail[_choose].sub(refundFee);
        _token.option = updateTicketStatus(_token.option,3);
        msg.sender.transfer(refundFee);
    }
    function openResult(uint256 _id,uint8[] _result)onlyAdmin() external{
        Game storage curGame = games[_id];
        require(curGame.status == STATUS.PLAYING);
        require(timenow() > curGame.dateStopBuy + 2*60*60);
        
        uint256 _totalWinnersDeposit = 0;
        for(uint256 i=0; i< _result.length; i++){
            require(_result[i]<30&&_result[i]>=0);
            curGame.result[_result[i]] = 1;
            _totalWinnersDeposit = _totalWinnersDeposit.add(curGame.potDetail[_result[i]]);
        }
        if(_totalWinnersDeposit > 0){
            curGame.status = STATUS.PAYING;
            curGame.totalWinnersDeposit = _totalWinnersDeposit;
        }else{
            curGame.status = STATUS.REFUNDING;
        }
    }

    
    function getWinningPrize(uint256 _tid)payable external{
        require(tokenIndexToOwner[_tid] == msg.sender);
        Token storage _token = tokens[_tid];
        uint8 _choose = uint8((_token.option >> (4*8)) & 0xFFFFFFFF);
        uint256 gameId   = uint256((_token.option >> (8*8)) & 0xFFFFFFFF);
        Game storage curGame = games[gameId];
        //confirm game status
        require(curGame.status == STATUS.PAYING);
        require(curGame.result[_choose] == 1);
        require(curGame.totalWinnersDeposit > 0);
        require(curGame.totalPot > 0);
        uint8 ticketStatus = uint8((_token.option >> (12*8)) & 0xFF);
        //confirm ticket status
        require(ticketStatus == 0);
        uint256 paybase = _token.price;
        //confirm ticket price
        require(paybase > 0);
        uint256 winningPrize = 0;
        if(curGame.totalWinnersDeposit > 0){
            winningPrize = (paybase.mul(curGame.totalPot)).div(curGame.totalWinnersDeposit);
        }
        if(winningPrize > 0){
            _token.option = updateTicketStatus(_token.option,1);
            msg.sender.transfer(winningPrize);
        }
    }
    function getRefund(uint256 _tid)payable external{
        //confirm ownership
        require(tokenIndexToOwner[_tid] == msg.sender);
        Token storage _token = tokens[_tid];
        uint256 gameId   = uint256((_token.option >> (8*8)) & 0xFFFFFFFF);
        Game storage curGame = games[gameId];
        //confirm game status
        require(curGame.status == STATUS.REFUNDING);
        require(curGame.totalWinnersDeposit == 0);
        require(curGame.totalPot > 0);
        uint8 ticketStatus = uint8((_token.option >> (12*8)) & 0xFF);
        //confirm ticket status
        require(ticketStatus == 0);
        uint256 refundFee = _token.price;
        //confirm ticket price
        require(refundFee > 0);
  
        _token.option = updateTicketStatus(_token.option,2);
        msg.sender.transfer(refundFee);
    }
    function getGameInfoById(uint256 _id)public view returns(
    uint256 _totalPot,
    uint256 _totalWinnersDeposit,
    uint256 _dateStopBuy,
    uint8 _gameStatus,
    string _potDetail, 
    string _results,
    string _name
    )
    {
        Game storage curGame = games[_id];
        _potDetail = "";
        _results = "";
        for(uint8 i=0;i<30;i++){
            _potDetail = strConcat(_potDetail,",",uint2str(curGame.potDetail[i]));
            _results = strConcat(_results,",",uint2str(curGame.result[i]));
        }
        _totalPot = curGame.totalPot;
        _totalWinnersDeposit = curGame.totalWinnersDeposit;
        _dateStopBuy = curGame.dateStopBuy;
        _name = curGame.name;
        _gameStatus = uint8(curGame.status);
        if ( curGame.status == STATUS.PLAYING && timenow() > _dateStopBuy ) _gameStatus = uint8(STATUS.PROCESSING);
    }
    function getAllGames(bool onlyPlaying,uint256 from, uint256 to)public view returns(string gameInfoList){
        gameInfoList = "";
        uint256 counter = 0;
        for(uint256 i=0; i<gameIdList.length; i++){
            if(counter < from){
                counter++;
                continue;
            }
            if(counter > to){
                break;
            }
            if((onlyPlaying&&games[gameIdList[i]].status == STATUS.PLAYING && timenow() < games[gameIdList[i]].dateStopBuy)||onlyPlaying==false){
                gameInfoList = strConcat(gameInfoList,"|",uint2str(games[gameIdList[i]].id));
                gameInfoList = strConcat(gameInfoList,",",games[gameIdList[i]].name);
                gameInfoList = strConcat(gameInfoList,",",uint2str(games[gameIdList[i]].totalPot));
                gameInfoList = strConcat(gameInfoList,",",uint2str(games[gameIdList[i]].dateStopBuy));
                if(games[gameIdList[i]].status == STATUS.PLAYING && timenow() > games[gameIdList[i]].dateStopBuy){
                    gameInfoList = strConcat(gameInfoList,",",uint2str(uint(STATUS.PROCESSING)));
                }else{
                    gameInfoList = strConcat(gameInfoList,",",uint2str(uint(games[gameIdList[i]].status)));
                }
                counter++;
            }
        }
    }
        
    function getMyTicketList(bool active,uint256 from, uint256 to)public view returns(string info){
        info = "";
        uint256 counter = 0;
        if(ownershipTokenCount[msg.sender] > 0){
            for(uint256 i=0; i<totalSupply; i++){
                if(tokenIndexToOwner[i] == msg.sender){
                    if(counter < from){
                        counter++;
                        continue;
                    }
                    if(counter > to){
                        break;
                    }
                    
                    Token memory _token = tokens[i];
                    uint256 gameId = uint256((_token.option >> (8*8)) & 0xFFFFFFFF);
                    uint256 tStatus = uint256((_token.option >> (12*8)) & 0xFF);
                    uint256 dateBuy = uint256(_token.option & 0xFFFFFFFF);
                    uint256 _choose = uint256((_token.option >> (4*8)) & 0xFFFFFFFF);
                    uint256 otherpick = getNumbersOfPick(gameId,uint8(_choose));
                    Game storage curGame = games[gameId];
                    if((active&&(tStatus == 0&&(curGame.status == STATUS.PLAYING||(curGame.result[uint8(_choose)] == 1&&curGame.status == STATUS.PAYING)||curGame.status == STATUS.REFUNDING)))||active == false){
                        info = strConcat(info,"|",uint2str(i));
                        info = strConcat(info,",",uint2str(gameId));
                        info = strConcat(info,",",uint2str(_token.price));
                        info = strConcat(info,",",uint2str(dateBuy));
                        info = strConcat(info,",",uint2str(_choose));
                        info = strConcat(info,",",uint2str(otherpick));
                        info = strConcat(info,",",uint2str(tStatus));
                        if(curGame.status == STATUS.PLAYING && timenow() > curGame.dateStopBuy){
                            info = strConcat(info,",",uint2str(uint(STATUS.PROCESSING)));
                        }else{
                            info = strConcat(info,",",uint2str(uint(curGame.status)));
                        }
                        if(tStatus == 3||curGame.potDetail[uint8(_choose)]==0){
                            info = strConcat(info,",",uint2str(0));//Canceled ticket
                        }else{
                            if(curGame.totalWinnersDeposit > 0){
                                if(curGame.result[uint8(_choose)]==1){
                                    //Win ticket
                                    info = strConcat(info,",",uint2str(_token.price.mul(curGame.totalPot).div(curGame.totalWinnersDeposit)));
                                }else{
                                    //Lose ticket
                                    info = strConcat(info,",",uint2str(_token.price.mul(curGame.totalPot).div(curGame.potDetail[uint8(_choose)])));
                                }
                            }else{
                                //Pending or Processing
                                info = strConcat(info,",",uint2str(_token.price.mul(curGame.totalPot).div(curGame.potDetail[uint8(_choose)])));
                            }
                        }
                        if(curGame.status == STATUS.PAYING&&curGame.result[uint8(_choose)] == 1){
                            info = strConcat(info,",",uint2str(1));
                        }else {
                            info = strConcat(info,",",uint2str(0));
                        }
                        info = strConcat(info,",",uint2str(curGame.totalPot));
                    }
                    counter++;
                }
            }
        }
    }

    function getNumbersOfPick(uint256 _gid, uint8 _pick)public view returns(uint256 num){
        require(_pick < 30&&_pick >= 0);
        Game storage curGame = games[_gid];
        num = 0;
        for(uint256 i=0; i<totalSupply; i++){
            uint256 data = tokens[i].option;
            uint256 _gameId = uint256((data >> (8*8)) & 0xFFFFFFFF);
            if(curGame.id == _gameId){
                uint8 _choose = uint8((data >> (4*8)) & 0xFFFFFFFF);
                uint8 tStatus = uint8((data >> (12*8)) & 0xFF);
                if(_pick == _choose&&tStatus!=3){
                    num++;
                }
            }
        }
    }
}