pragma solidity ^0.4.25;

/*
VERSION DATE: 12/12/2018
*/

contract Owned 
{
    address private candidate;
	address public owner;

	mapping(address => bool) public admins;
	
    constructor() public 
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
        require(candidate == msg.sender);
		owner = candidate;
    }
	
    function addAdmin(address addr) public 
	{
		require(msg.sender == owner);
		if(addr!=address(0)) admins[addr] = true;
    }

    function removeAdmin(address addr) public
	{
		require(msg.sender == owner);
        if (admins[addr]) admins[addr] = false;
    }
	
	modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
	
	modifier onlyAdmin {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }
}

contract Functional
{
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

contract ERC721
{
	function implementsERC721() public pure returns (bool);
	function balanceOf(address _owner) public view returns (uint256 balance);
	function ownerOf(uint256 _tokenId) public view returns (address owner);
	function approve(address _to, uint256 _tokenId) public;
	function transferFrom(address _from, address _to, uint256 _tokenId) public;
	function transfer(address _to, uint256 _tokenId) public;
 
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
}

contract VirtualToken is Owned
{
	uint256 public totalMint;
	address public artist;
	mapping(address => uint) unused;

	struct MarkSellOut
	{
		uint price;
		uint count;
	}
	mapping(address => MarkSellOut) sellout;
	
	event SendVirtTokens(address indexed from, address indexed to, uint count);
	event MarkTokensToSell(address indexed owner, uint count, uint price);
	event DeleteMark(address indexed owner);
	event BuyVirtTokens(address indexed form, address indexed who, uint count);
	
	function mintTokens(uint count, address _artist, uint shareArtist) public onlyOwner
	{
		require(totalMint==0);
		
		totalMint = count;
		
		if (_artist!=address(0))
		{
			unused[_artist] = count * shareArtist / 100;
			unused[this] = count - unused[_artist];
			artist = _artist;
		}
		else
		{
			unused[this] = count;
		}
	}
	
	function unusedOf(address tokenOwner) public view returns (uint balance)
	{
		address addr = this;
		if (tokenOwner!=address(0)) addr = tokenOwner;
        return unused[addr];
    }
	
	function sendVirtTokens(address to, uint count) public 
	{
		require(unused[msg.sender]>=count);
        unused[msg.sender] = unused[msg.sender] - count;
		unused[to] = unused[to] + count;
        emit SendVirtTokens(msg.sender, to, count);
    }
	
	function markTokensToSell(uint count, uint price) public
	{
		require(count>0);
		require(price>0);
		require(unused[msg.sender]>=count);
		require(sellout[msg.sender].count==0);
		
		sellout[msg.sender].count = count;
		sellout[msg.sender].price = price;
		
		emit MarkTokensToSell(msg.sender, count, price);
	}
	
	function deleteMark() public
	{
		require(sellout[msg.sender].count>0);
		sellout[msg.sender].count = 0;
		sellout[msg.sender].price = 0;
		
		emit DeleteMark(msg.sender);
	}
	
	function getInfoMarkTokens(address addr) public view returns(uint countMark, uint countAll, uint price)
	{
		countMark = sellout[addr].count;
		countAll = unused[addr];
		price = sellout[addr].price ;
	}

	function buyVirtTokens(address whom, uint countToBuy) public payable
	{
		uint count = sellout[whom].count;
		uint price = sellout[whom].price ;

		require(whom!=msg.sender);
		require(count>0);
		require(countToBuy>0);
		
		require(count>=countToBuy);
		require(unused[whom]>=countToBuy);

		require(msg.value == countToBuy * price);
		
        unused[msg.sender] = unused[msg.sender] + countToBuy;
		unused[whom] = unused[whom] - countToBuy;

		sellout[whom].count = sellout[whom].count - countToBuy;

		whom.transfer(msg.value);

        emit BuyVirtTokens(whom, msg.sender, countToBuy);
	}
}

contract ExpandedToken is ERC721, VirtualToken, Functional
{
	event SetName(string _name, string _symbol);
	
	string public name = "SuperFan";
	string public symbol = "SFT";
	function setName(string _name, string _symbol) public onlyOwner 
	{
		name = _name;
		symbol = _symbol;
		emit SetName(name,symbol);
	}
	
	uint256 public totalSupply;
	
	string public defaultMetadataURI = "https://www.superfan.com/tokens/";
	function setDefaultMetadataURI(string _defaultUri) public onlyOwner 
	{
		defaultMetadataURI = _defaultUri;
	}
	
	struct Token
	{
		uint32 time;
		uint256	params;
	}
	
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	
	mapping (uint256 => Token) tokens;
	mapping (uint256 => address) public tokenIndexToOwner;
	mapping (address => uint256) ownershipTokenCount; 
	mapping (uint256 => address) public tokenIndexToApproved;
	
	function getListTokens(address addr, uint min, uint max) public view returns (string res)
	{
		res = "";
		if (max>totalSupply || max==0) max = totalSupply;
		for(uint id=min;id<max;id++)
		{
			if (tokenIndexToOwner[id] == addr) res = strConcat( res, ",", uint2str(id) );
		}
	}
	
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
	
	function _approve(uint256 _tokenId, address _approved) internal 
	{
		tokenIndexToApproved[_tokenId] = _approved;
	}
	
	function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool)
	{
		return tokenIndexToApproved[_tokenId] == _claimant;
	}
	
	function approve( address _to, uint256 _tokenId ) public
	{
		require(_owns(msg.sender, _tokenId));
		_approve(_tokenId, _to);
		emit Approval(msg.sender, _to, _tokenId);
	}
	
	function transferFrom( address _from, address _to, uint256 _tokenId ) public
	{
		require(_approvedFor(msg.sender, _tokenId));
		require(_owns(_from, _tokenId));
		_transfer(_from, _to, _tokenId);
	}
	
	function _owns(address _claimant, uint256 _tokenId) internal view returns (bool)
	{
		return tokenIndexToOwner[_tokenId] == _claimant;
	}
	
	function _transfer(address _from, address _to, uint256 _tokenId) internal 
	{
		ownershipTokenCount[_to]++;
		tokenIndexToOwner[_tokenId] = _to;

		if (_from != address(0)) 
		{
			ownershipTokenCount[_from]--;
			delete tokenIndexToApproved[_tokenId];
			delete tokenAuction[_tokenId];
		}
		
		emit Transfer(_from, _to, _tokenId);
	}
	
	function transfer(address _to, uint256 _tokenId) public
	{
		require(_to != address(0));
		require(_owns(msg.sender, _tokenId));
		_transfer(msg.sender, _to, _tokenId);
	}
	
	function transfers(address _to, uint256[] _tokens) public
    {
		require(_to != address(0));
        for(uint i = 0; i < _tokens.length; i++)
        {
			require(_owns(msg.sender, _tokens[i]));
			_transfer(msg.sender, _to, _tokens[i]);
        }
    }
	
	function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl)
	{
		if(tokens[_tokenId].time!=0) infoUrl = strConcat( defaultMetadataURI, "", uint2str(_tokenId) );
	}

	struct Auction
	{
        address seller;
        uint startingPrice;
        uint endingPrice;
        uint32 startedAt;
		uint32 period;
		uint32 blocks;
    }
	mapping (uint256 => Auction) tokenAuction;
	
	event CreateAuction(uint256 tokenId, uint32 startedAt, uint256 startingPrice, uint256 endingPrice, uint32 period, uint32 blocks);
	event CancelAuction(uint tokenId);
	event CompleteAuction(uint tokenId);
	
	uint256 public FEECONTRACT = 10;
	uint256 public feeValue;
	
	function createAuction( uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint32 period, uint32 blocks ) public
    {
        require(_owns(msg.sender, tokenId));
		require(tokenAuction[tokenId].startedAt==0);
		require(period >= 1 minutes && period <= 30 days);
		require(blocks>=1 && blocks <=10);
		require(startingPrice > 0);
		require(endingPrice > 0);
		
        Auction memory auction = Auction(
            msg.sender,
            startingPrice,
            endingPrice,
            timenow(),
			period,
			blocks
        );
		
		tokenAuction[tokenId] = auction;
		
        emit CreateAuction(tokenId, timenow(), startingPrice, endingPrice, period, blocks);
    }

	function cancelAuction(uint256 tokenId) public
	{
        require(_owns(msg.sender, tokenId));
		require(tokenAuction[tokenId].startedAt!=0);

		delete tokenAuction[tokenId];

        emit CancelAuction(tokenId);
    }

	function getAuction(uint256 tokenId) public view returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint32 startedAt,
		uint32 period,
		uint32 blocks,
		uint curPrice
		
    ){
        Auction storage auction = tokenAuction[tokenId];
        if(tokenAuction[tokenId].startedAt!=0)
		{
			seller = auction.seller;
			startingPrice = auction.startingPrice;
			endingPrice = auction.endingPrice;
			startedAt = auction.startedAt;
			period = auction.period;
			blocks = auction.blocks;
			curPrice = getCurrentPrice(tokenId);
		}
    }

	function getCurrentPrice(uint256 tokenId) public view returns (uint)
    {
		Auction storage auction = tokenAuction[tokenId];

		if(tokenAuction[tokenId].startedAt==0) return 0;
		if(timenow()>=auction.startedAt + auction.period) return auction.endingPrice;
		
		int changePriceOfStage = (int(auction.endingPrice) - int(auction.startingPrice)) / auction.blocks;
		uint32 periodOfStage = auction.period / auction.blocks;
		uint32 curStage = ( timenow() - auction.startedAt ) / periodOfStage;
		uint price = uint(int(auction.startingPrice) + changePriceOfStage * curStage);
				
		return price;
	}
	
	function bid(uint256 tokenId) public payable
	{
		Auction storage auction = tokenAuction[tokenId];
		
		require(auction.startedAt!=0);
		
		uint256 price = getCurrentPrice(tokenId);
        require(msg.value == price);
		
		address seller = auction.seller;
		require(msg.sender != seller);

		_transfer(seller, msg.sender, tokenId);
		
        uint256 curFee = price * FEECONTRACT / 100;
        uint256 sendValue = price - curFee;
		feeValue = feeValue + curFee;

        seller.transfer(sendValue);

		emit CompleteAuction(tokenId);
	}
	
}

contract SuperFan is ExpandedToken
{
	uint256 public buyPrice  = 1 * 10**15;	// 1 TOKEN = 0.001 ETHER = 1000000000000000

	bool public paused = false;
	
	constructor(string name, string symbol, uint count, uint price, string defaultUri, address artist, address admin, uint feeContract, uint shareArtist) public 
	{
		require(feeContract>=1 && feeContract<=50);
		require(shareArtist>=1 && shareArtist<=50);
		
		setName(name, symbol);		
		mintTokens(count, artist, shareArtist);
		setBuyPrice(price);
		setDefaultMetadataURI(defaultUri);
		addAdmin(admin);
		FEECONTRACT = feeContract;
	}
	
	event LogUpdateToken(address user, uint256 tokenId, uint256 params);
	event SetBuyPrice(uint256 newBuyPrice);
	event SetPaused(bool _paused);
	
	function getTokenInfo(uint256 tokenId) public view returns (
		uint32 time,
		uint params,
		address owner
	){
		if(tokens[tokenId].time!=0)
		{
			time = tokens[tokenId].time;
			params = tokens[tokenId].params;
			owner = ownerOf(tokenId);
		}
	}
	
    function setBuyPrice(uint256 newBuyPrice) onlyOwner public
	{
		require(newBuyPrice != 0);
        buyPrice = newBuyPrice;
		
		emit SetBuyPrice(newBuyPrice);
    }
	
	function setPaused(bool _paused) public onlyOwner
	{
		require(paused != _paused);
		paused = _paused;
		
		emit SetPaused(_paused);
	}
	
	function createToken(address whom) private
	{
		require(paused == false);
		
		Token memory _token = Token({
			time : timenow(),
			params : 0
		});
	
		uint idToken = totalSupply++;
		tokens[idToken] = _token;
		
		_transfer(address(0), whom, idToken);
	}
	
	function getTokensTo(uint count, address addr) public
	{
		require(unused[msg.sender]>=count);
		unused[msg.sender] = unused[msg.sender] - count;
		
		for(uint i=0;i<count;i++)
		{
			createToken(addr);
		}
	}
	
	function getFreeToken(bytes32 r, bytes32 s, uint8 v) public
	{
		bytes memory prefix = "\x19Ethereum Signed Message:\n32";
		
		bytes32 hash = keccak256( abi.encodePacked(this, msg.sender) );
		address signer = ecrecover(keccak256( abi.encodePacked(prefix, hash) ), v, r, s);
        require(admins[signer]);
		
		require(unused[this]>0);
		unused[this]--;
		
		require(balanceOf(msg.sender)==0);
		
		createToken(msg.sender);
	}
	
	function buyToken() public payable
	{
		require(unused[this]>0);
		unused[this]--;

		require(msg.value == buyPrice);
		
		createToken(msg.sender);
		
		uint sendValue = msg.value;
		uint256 curFee = sendValue * FEECONTRACT / 100;
		sendValue = sendValue - curFee;
		feeValue = feeValue + curFee;
		
		artist.transfer(sendValue);
	}
	
	function giveOut(address[] addrs) public onlyAdmin
	{
		require(addrs.length>0);
		uint count = addrs.length;
		require(unused[this]>=count);

		unused[this] = unused[this] - count;
		
		for(uint i = 0; i < count; i++) 
		{
			createToken(addrs[i]);
		}
	}

	function updateToken(uint tokenId, uint params) public
	{
		require(tokens[tokenId].time!=0);
		require(ownerOf(tokenId) == msg.sender);
		require(tokens[tokenId].params != params);
		
		tokens[tokenId].params = params;
		
		emit LogUpdateToken(msg.sender, tokenId, params);
	}
	
	function () onlyOwner payable public {}
	
	function withdrawFee() onlyOwner public
	{
		require( feeValue > 0 );

		uint256 tmpFeeValue = feeValue;
		feeValue = 0;
		
		owner.transfer(tmpFeeValue);
	}
		
}