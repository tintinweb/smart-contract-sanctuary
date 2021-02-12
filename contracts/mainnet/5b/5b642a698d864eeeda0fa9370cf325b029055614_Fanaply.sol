/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

/*
VERSION DATE: 21/11/2020
*/

contract Owned 
{
	address public owner;

	mapping(address => uint64) public admins;
	
    constructor() public 
	{
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public 
	{
		require(msg.sender == owner);
        owner = newOwner;
    }
	
	event AddAdmin(address user, uint64 count);
	event RemoveAdmin(address user);
		
    function addAdmin(address addr, uint64 count) public 
	{
		require(msg.sender == owner);
		require(addr != address(0));
		admins[addr] = admins[addr] + count;
		
		emit AddAdmin(addr, admins[addr]);
    }

    function removeAdmin(address addr) public
	{
		require(msg.sender == owner);
		require(admins[addr]>0);
		delete admins[addr];
		
		emit RemoveAdmin(addr);
    }
	
    function decAdmin(address addr) internal
	{
		require(admins[addr]>0);
		admins[addr]--;
    }	
	
	modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
	
	modifier onlyAdmin {
        require(admins[msg.sender]>0);
        _;
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

contract ExpandedToken is ERC721, Owned
{
	event SetName(string _name, string _symbol);

	uint256 public totalSupply;
	uint256 public idCurToken = 0;
	
	string public name = "";
	string public symbol = "";
	
	function setName(string memory _name, string memory _symbol) public onlyOwner 
	{
		name = _name;
		symbol = _symbol;
		emit SetName(name,symbol);
	}

	
	/*
	packed 256 bits :
	[ idType ][ idLocalToken ][ time ]
	[   96   ][     128      ][  32  ]	
	*/
	
	mapping(uint256 => uint256) tokensG2L;						// globalId => packed
	mapping(uint256 => mapping (uint256 => uint256)) tokensL2G; // typeId => localTokenId => globalId
		
	function getGlobalId(uint typeId, uint localTokenId) public view returns ( uint tokenId )		
	{
		tokenId = tokensL2G[typeId][localTokenId];
	}
	
	mapping (uint256 => address) private tokenIndexToOwner;
	mapping (address => uint256) public  ownershipTokenCount; 
	mapping (uint256 => address) private tokenIndexToApproved;
	
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
		if(_tokenId > totalSupply || _tokenId==0) owner = address(0);
		else {
			owner = tokenIndexToOwner[_tokenId];
			if (owner == address(0)) owner = address(this);
		}
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
		require(_to != address(0));
		require(_to != address(this));
		require(_approvedFor(msg.sender, _tokenId));
		require(_owns(_from, _tokenId));
		_transfer(_from, _to, _tokenId);
	}
	
	function _owns(address _claimant, uint256 _tokenId) internal view returns (bool)
	{	
		if (_tokenId > totalSupply || _tokenId==0) return false;
		if (tokenIndexToOwner[_tokenId] == _claimant) return true;
		if (tokenIndexToOwner[_tokenId] == address(0) && _claimant == address(this) ) return true;
		return false;
	}

	function _transfer(address _from, address _to, uint256 _tokenId) internal 
	{
		require( ownershipTokenCount[_from] > 0 );
		
		ownershipTokenCount[_to]++;
		ownershipTokenCount[_from]--;
		
		tokenIndexToOwner[_tokenId] = _to;
		
		delete tokenIndexToApproved[_tokenId];
		delete tokenAuction[_tokenId];

		emit Transfer(_from, _to, _tokenId);
	}
	
	function transfer(address _to, uint256 _tokenId) public
	{
		require(_to != address(0));
		require(_to != address(this));
		require(_owns(msg.sender, _tokenId));
		_transfer(msg.sender, _to, _tokenId);
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
	
	uint256 public feePercent;
	address public constant feeAddress = 0x15b8a6F624C9666f7EE7D35BC093305eBfb8C8C2;
	
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
		
        uint256 curFee = price * feePercent / 100;
        uint256 sendValue = price - curFee;

        seller.transfer(sendValue);
		feeAddress.transfer(curFee);

		emit CompleteAuction(tokenId);
	}
	
}

contract Variety is ExpandedToken
{
	struct Types
	{
		string category;
		uint param;
	}

	uint countTypes = 0;
	
	mapping(uint256 => Types) typesById;
	mapping(string => uint256) private typesByName;


	function getTokenInfo(uint tokenId) public view returns ( 
		uint32 time,
		uint idTypes,
		string category,
		uint idLocalToken
	){
		uint256 token = tokensG2L[tokenId];
		
		time = uint32(token & 0xFFFFFFFF);
		idLocalToken = uint128(token >> 32 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
		idTypes = uint128(token >> 160);

		category = typesById[idTypes].category;
	}
	
	function getTypesById(uint256 typeId) public view returns (
		string category,
		uint32 time,
		uint count,
		uint issued
	){
		category = typesById[typeId].category;
		
		uint256 packed = typesById[typeId].param;
		
		time = uint32(packed & 0xFFFFFFFF);
		count = uint128(packed >> 32 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
		issued = uint128(packed >> 160);
	}

	function getTypesByName(string category) public view returns (
		uint idType,
		uint32 time,
		uint count,
		uint issued
	){
		idType = typesByName[category];
		uint256 packed = typesById[idType].param;
		
		time = uint32(packed & 0xFFFFFFFF);
		count = uint128(packed >> 32 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
		issued = uint128(packed >> 160);
	}

	event CreateType(uint typeId, string category, uint count);
	
	function createTypes(string _category, uint _count) public onlyAdmin
	{
		require( bytes(_category).length >= 3 );
		require( _count > 0 );
		
		decAdmin(msg.sender);
		
		countTypes++;
		
		totalSupply += _count;
		ownershipTokenCount[address(this)] += _count;
		
		require( typesByName[_category] == 0 );
		
		uint256 packed = ( uint128(_count) << 32 ) + uint32(block.timestamp);
		
		Types memory _type = Types({
			category: _category,
			param: packed
		});

		typesById[countTypes] = _type;
		typesByName[_category] = countTypes;
		
		emit CreateType(countTypes, _category, _count);
	}
	
}

contract Fanaply is Variety
{
	mapping (uint64 => bool) public nonces;
	
	constructor(
		string memory name,
		string memory symbol,
		address adminAddr,
		uint64 adminCount,
		uint feeValue ) public
	{
		require( feeValue >=1 && feeValue <=50 );
		
		setName(name, symbol);	

		addAdmin(adminAddr, adminCount);
		feePercent = feeValue;
	}


	event ReturnToken(address user, uint typeId, uint localTokenId, uint tokenId);
		
	function returnToken(uint idToken) public
	{
		require(tokensG2L[idToken]!=0);

		require(ownerOf(idToken) == msg.sender);
		
		_transfer(msg.sender, address(this), idToken);

		uint256 token = tokensG2L[idToken];
		uint128 localId = uint128(token >> 32 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
		uint128 typeId = uint128(token >> 160);
		
		uint256 packed = typesById[typeId].param;
		uint32 time = uint32(packed & 0xFFFFFFFF);
		uint128 count = uint128(packed >> 32 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
		uint128 issued = uint128(packed >> 160);

		require( issued > 0 );
		
		issued--;
		packed = (uint256(issued) << 160) + (uint128(count) << 32) + uint32(time);
		typesById[typeId].param = packed;
		
		emit ReturnToken(msg.sender, typeId, localId, idToken);
	}
	

	event TakeToken(address user, uint typeId, uint localTokenId, uint tokenId);
	
	function createToken(uint256 typeId, uint256 localTokenId) internal
	{
		uint global = tokensL2G[typeId][localTokenId];
		require(global==0 || _owns(address(this), global));
		
		uint256 packed = typesById[typeId].param;
		uint32 time = uint32(packed & 0xFFFFFFFF);
		uint128 count = uint128(packed >> 32 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
		uint128 issued = uint128(packed >> 160);
		require( issued < count );
		
		issued++;
		packed = (uint256(issued) << 160) + (uint128(count) << 32) + uint32(time);
		typesById[typeId].param = packed;

		require( localTokenId <= count );

		uint idToken = 0;
		if (global==0) idToken = ++idCurToken;
			else idToken = global;
		
		uint256 token = ( uint256(typeId) << 160 ) + ( uint128(localTokenId) << 32 ) + uint32(block.timestamp);
		tokensG2L[idToken] = token;
		tokensL2G[typeId][localTokenId] = idToken;
		
		_transfer(address(this), msg.sender, idToken);
		
		emit TakeToken(msg.sender, typeId, localTokenId, idToken);
	}
	
	function takeToken(uint256 typeId, uint256 localTokenId, uint64 nonce, bytes32 r, bytes32 s, uint8 v) public
	{
		require(typeId>0);
		require(localTokenId>0);

		bytes memory prefix = "\x19Ethereum Signed Message:\n32";
		bytes32 hash = keccak256( abi.encodePacked(address(this), msg.sender, nonce, typeId, localTokenId) );
        address signer = ecrecover(keccak256( abi.encodePacked(prefix,hash)), v, r, s);

		require(nonces[nonce] == false);
		nonces[nonce] = true;
		decAdmin(signer);
	
		createToken(typeId, localTokenId);
	}
	
	function () onlyOwner payable public {}
}