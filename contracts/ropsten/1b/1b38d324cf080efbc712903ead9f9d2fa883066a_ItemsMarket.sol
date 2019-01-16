pragma solidity 0.4.21;

/*
VERSION DATE: 11/12/2018
*/

contract SuperFan
{
	function ownerOf(uint256) public view returns (address);
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

contract ItemProperty is Owned
{
	enum Permission
	{
		NONE,
		WHITE,
		BLACK
	}
	
	struct Item
	{
		bool freeze;
		uint count;
		uint bought;
		uint deleted;
		uint price;
		address artist;
		uint32 shareArtist;
		uint32 stopBuy;
		string metadataURI;
		Permission permission;
		mapping (address => bool) list;
	}
	mapping (uint => Item) items;
	uint public countItems;
	mapping(string => uint) existsItems;
	
	function checkExistsItems(string name) view public returns (uint idItem)
	{
		idItem = existsItems[name];
	}
	
	event CreateItem(string name, uint idItem, uint count, uint price, uint stopBuy);
	event UpdatePrice(uint idItem, uint price);
	
	function createItem(string _name, uint _count, uint _price, address _artist, uint32 _shareArtist, string _metadataURI, uint32 _stopBuy) public onlyAdmin
	{
		require( bytes(_name).length > 3 );
		require(_count>0);
		require(_price>0);
		require(_artist!=address(0));
		require(_shareArtist>0&&_shareArtist<100);
		require(existsItems[_name]==0);

		Item memory _item = Item({
			freeze : false,
			count : _count,
			bought : 0,
			deleted : 0,
			price : _price,
			artist : _artist,
			shareArtist : _shareArtist,
			metadataURI : _metadataURI,
			stopBuy : _stopBuy,
			permission : Permission.NONE
		});

		uint curNumItem = ++countItems;
		items[curNumItem] = _item;
		existsItems[_name] = curNumItem;

		emit CreateItem(_name, curNumItem, _count, _price, _stopBuy);
	}

	function getItem(uint idItem) view public returns (
		bool freeze,
		uint count,
		uint bought,
		uint deleted,
		uint price,
		address artist,
		uint32 shareArtist,
		string metadataURI,
		uint32 stopBuy,
		Permission permission
	){
		require(items[idItem].count!=0);
		Item memory item = items[idItem];
		
		freeze = item.freeze;
		count = item.count;
		bought = item.bought;
		deleted = item.deleted;
		price = item.price;
		artist = item.artist;
		shareArtist = item.shareArtist;
		metadataURI = item.metadataURI;
		stopBuy = item.stopBuy;
		permission = item.permission;
	}
	
	function updatePrice(uint idItem, uint _price) public onlyAdmin
	{
		require(items[idItem].count!=0);
		require(items[idItem].price != _price);
		emit UpdatePrice(idItem, _price);
		items[idItem].price = _price;
	}
	
	function updateMetadata(uint idItem, string _metadataURI) public onlyAdmin
	{
		require(items[idItem].count!=0);
		items[idItem].metadataURI = _metadataURI;
	}
	
	function setFreeze(uint idItem, bool freeze) public onlyAdmin
	{
		require(items[idItem].count!=0);
		require(items[idItem].freeze != freeze);
		items[idItem].freeze = freeze;
	}
	
	function setPermission(uint idItem, Permission permission) public onlyAdmin
	{
		Item storage item = items[idItem];
		require(item.count!=0);
		items[idItem].permission = permission;
	}

	function checkList(uint idItem, address addr) public view returns (bool inList, Permission permission)
	{
		Item storage item = items[idItem];
		require(item.count!=0);
		inList = item.list[addr];
		permission = item.permission;
	}
	
	function addToList(uint idItem, address[] addrs) public onlyAdmin
	{
		Item storage item = items[idItem];
		require(item.count!=0);
		for(uint i = 0; i < addrs.length; i++) 
		{
			if (!item.list[addrs[i]]) item.list[addrs[i]] = true;
		}
	}
	
	function delFromList(uint idItem, address[] addrs) public onlyAdmin
	{
		Item storage item = items[idItem];
		require(item.count!=0);
		for(uint i = 0; i < addrs.length; i++) 
		{
			if (item.list[addrs[i]]) item.list[addrs[i]] = false;
		}
	}
	
}

contract ExpandedItem is ItemProperty, Functional
{
	string public constant   name = "ItemToken";
	string public constant symbol = "IT";
	
	uint256 public totalSupply;

	struct Token
	{
		uint32 time;
		uint itemId;
		address contractAddr;
		uint tokenId;
		bool deleted;
	}

	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	
	mapping (uint256 => Token) tokens;
	mapping (uint256 => address) tokenIndexToOwner;
	mapping (address => uint256) ownershipTokenCount; 
	mapping (address => mapping (uint => uint[])) tokensByAddr;
	
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
		}
		
		emit Transfer(_from, _to, _tokenId);
	}
	
	function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl)
	{
		require(tokens[_tokenId].time!=0);
		infoUrl = strConcat( items[tokens[_tokenId].itemId].metadataURI, "", uint2str(_tokenId) );
	}
	
	function getCountTokens(address addr, uint id) public view returns (uint count)
	{
		count = 0;
		uint[] storage mas = tokensByAddr[addr][id];
		count = mas.length;
	}
	
	function getListTokens(address addr, uint id, uint min, uint max) public view returns (string res)
	{
		res = "";
		uint[] storage mas = tokensByAddr[addr][id];
		if (max>mas.length || max==0) max = mas.length;
		for(uint i=min;i<max;i++)
		{
			uint tokenId = mas[i];
			if (tokens[tokenId].deleted) continue;
			res = strConcat( res, ",", uint2str(tokenId) );
		}
	}
	
}

contract ItemsMarket is ExpandedItem
{
	
	function ItemsMarket() public 
	{
	}
	
	function getTokenInfo(uint256 _tokenId) public view returns (
		uint itemId,
		uint32 time,
		address contractAddr,
		uint tokenId,
		address buyer,
		bool deleted
	){
		require(tokens[_tokenId].time!=0);
		itemId = tokens[_tokenId].itemId;
		time = tokens[_tokenId].time;
		contractAddr = tokens[_tokenId].contractAddr;		
		tokenId = tokens[_tokenId].tokenId;
		buyer = ownerOf(_tokenId);
		deleted = tokens[_tokenId].deleted;
		
	}

	function getOwner(address _contractAddr, uint _tokenId) view public returns 
	(address owner)
	{
		SuperFan sf = SuperFan(_contractAddr);
		owner = sf.ownerOf(_tokenId);
	}
	
	event moveToken(string move, uint itemId, address contractAddr, uint tokenArtistId, uint tokenId);
	
	function createToken(uint _itemId, address _contractAddr, uint _tokenId) internal
	{
		bool mayBuy = false;
		bool inList;
		Permission permission;
		(inList,permission) = checkList(_itemId, _contractAddr);
		if (permission == Permission.NONE) mayBuy = true;
		if (permission == Permission.WHITE && inList==true) mayBuy = true;
		if (permission == Permission.BLACK && inList==false) mayBuy = true;
		require(mayBuy);

		SuperFan sf = SuperFan(_contractAddr);
		require( sf.ownerOf(_tokenId) == msg.sender );
		
		Token memory _token = Token({
			time : timenow(),
			itemId : _itemId,
			contractAddr : _contractAddr,
			tokenId : _tokenId,
			deleted : false
		});

		uint256 newTokenId = totalSupply++;
		tokens[newTokenId] = _token;
		
		tokensByAddr[_contractAddr][_tokenId].push(newTokenId);
		
		_transfer(address(0), msg.sender, newTokenId);
		
		emit moveToken( "add", _itemId, _contractAddr, _tokenId, newTokenId );
	}
	
	function buyToken(uint _itemId, address _contractAddr, uint _tokenId) public payable
	{
		Item storage item = items[_itemId];
		
		require(msg.value == item.price);
		require(item.count!=0);
		require(item.bought < item.count);
		require(item.freeze == false);
		if(item.stopBuy!=0) require(timenow()<item.stopBuy);

		createToken(_itemId, _contractAddr, _tokenId);
		
		item.bought++;
		
		uint sendValue = msg.value;
		uint256 curFee = sendValue * (100-item.shareArtist) / 100;
		sendValue = sendValue - curFee;
		item.artist.transfer(sendValue);
	}

	function getSigner(address uaddr, uint idItem, address aaddr, uint tokenId, bytes32 r, bytes32 s, uint8 v) internal view returns(address signer)
	{
		bytes memory prefix = "\x19Ethereum Signed Message:\n32";
		bytes32 hash = keccak256( address(this), uaddr, idItem, aaddr, tokenId );
		signer = ecrecover( keccak256(prefix,hash), v, r, s );
	}
	
	function getFreeToken(uint _itemId, address _contractAddr, uint _tokenId, bytes32 r, bytes32 s, uint8 v) public
	{
		address signer = getSigner( msg.sender, _itemId, _contractAddr, _tokenId, r, s, v );
        require(admins[signer]);
		
		Item storage item = items[_itemId];
		require(item.count!=0);
		require(item.bought < item.count);
		require(item.freeze == false);
		if(item.stopBuy!=0) require(timenow()<item.stopBuy);

		uint[] storage mas = tokensByAddr[_contractAddr][_tokenId];
		bool tokenFind = false;
		for(uint i=0;i<mas.length;i++)
		{
			uint iToken = mas[i];
			if ( tokens[iToken].itemId ==_itemId ) { tokenFind = true; break; }
		}
		require(tokenFind==false);		
		
		createToken(_itemId, _contractAddr, _tokenId);
		
		item.bought++;
	}
	
	function removeToken(uint256 _tokenId) public
	{
		Token storage token = tokens[_tokenId];
		
		require(token.time!=0);
		
		SuperFan sf = SuperFan(token.contractAddr);
		require( sf.ownerOf(token.tokenId) == msg.sender );
		
		token.deleted = true;
		items[token.itemId].deleted++;
		
		emit moveToken( "del", token.itemId, token.contractAddr, token.tokenId, _tokenId );
	}
	
	function () onlyOwner payable public {}
	
	function withdrawFee() onlyOwner public
	{
		require( address(this).balance > 0 );
		owner.transfer( address(this).balance );
	}
		
}