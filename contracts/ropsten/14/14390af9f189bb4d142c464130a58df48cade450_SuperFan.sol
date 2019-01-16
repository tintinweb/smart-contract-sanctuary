pragma solidity ^0.4.25;

/*
VERSION DATE: 31/10/2018
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
	
	modifier onlyOwner {
        require(msg.sender == owner);
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

contract VirtualTokens is Owned
{
	
	uint256 public totalMint;
	address public artist;
	mapping(address => uint) unused;

	// добавить тип получения??
	struct Params
	{
		uint price;
		uint count;
	}
	mapping(address => Params) sellout;
	
	event SendTokens(address indexed from, address indexed to, uint count);
	
	function mintTokens(uint count, address _artist) public onlyOwner
	{
		require(totalMint==0);
		require(_artist!=0x0);
		
		totalMint = count;
		
		unused[_artist] = count/10;
		unused[this] = count - unused[_artist];
		
		artist = _artist;
	}
	
	function unusedOf(address tokenOwner) public view returns (uint balance)
	{
		address addr = this;
		if (tokenOwner!=0x0) addr = tokenOwner;
        return unused[addr];
    }
	
	function sendTokens(address to, uint count) public 
	{
		require(unused[msg.sender]>=count);
        unused[msg.sender] = unused[msg.sender] - count;
		unused[to] = unused[to] + count;
        emit SendTokens(msg.sender, to, count);
    }
	
	
	function markTokensToSell(uint count, uint price) public
	{
		require(count>0);
		require(price>0);
		require(unused[msg.sender]>=count);
		require(sellout[msg.sender].count==0);
		
		sellout[msg.sender].count = count;
		sellout[msg.sender].price = price;
	}
	
	function deleteMark() public
	{
		require(sellout[msg.sender].count>0);
		sellout[msg.sender].count = 0;
		sellout[msg.sender].price = 0;
	}
	
	function getInfoByAddr(address addr) public view returns(uint count, uint price)
	{
		count = sellout[addr].count;
		price = sellout[addr].price ;
	}

	function buyTokens(address whom) public payable
	{
		uint count = sellout[whom].count;
		uint price = sellout[whom].price ;
		require(count>0);
		require(unused[whom]>=count);
		require(msg.value == count * price);
		
        unused[msg.sender] = unused[msg.sender] + count;
		unused[whom] = unused[whom] - count;
		sellout[whom].count = 0;
		sellout[whom].price = 0;

		whom.transfer(msg.value);

        emit SendTokens(whom, msg.sender, count);
	}
	
	
	
}

contract ExpandedToken is ERC721, VirtualTokens, Functional
{
	string public   name = "SuperFan";
	string public symbol = "SFT";
	function setName(string _name, string _symbol) external onlyOwner 
	{
		name = _name;
		symbol = _symbol;
	}
	
	uint256 public totalSupply;
	
	string public defaultMetadataURI = "https://www.superfan.com/tokens/";
	function setDefaultMetadataURI(string _defaultUri) external onlyOwner 
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
	function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool)
	{
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
			// clear any previously approved ownership exchange
			delete tokenIndexToApproved[_tokenId];
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
		require(tokens[_tokenId].time!=0);
		infoUrl = strConcat( defaultMetadataURI, "", uint2str(_tokenId) );
	}
	
}



contract SuperFan is ExpandedToken
{

	uint256 public buyPrice  = 1 * 10**15;	// 1 TOKEN = 0.001 ETHER = 1000000000000000
	uint256 private constant FEECONTRACT = 10;
	uint256 public feeValue;

	constructor() public 
	{
		//mintTokens(10000, 0x90b964BB555E4A1890E2B13F4840579150E68913);
	}
	
	//event LogToken(address user, uint256 idToken, uint256 count);
	
	function getTokenInfo(uint256 _tokenId) public view returns (
		uint32 time,
		uint params,
		address owner
	){
		require(tokens[_tokenId].time!=0);
		time = tokens[_tokenId].time;
		params = tokens[_tokenId].params;
		owner = ownerOf(_tokenId);
	}
	
	// per finney = 0.001E
    function setBuyPrice(uint256 newBuyPriceFinney) onlyOwner public
	{
		require(newBuyPriceFinney != 0);
		require(buyPrice != newBuyPriceFinney * 1 finney);
        buyPrice = newBuyPriceFinney * 1 finney;
    }
	
	function createToken() private
	{
		Token memory _token = Token({
			time : timenow(),
			params : 0
		});
	
		uint256 newTokenId = totalSupply++;
		tokens[newTokenId] = _token;
		
		_transfer(0x0, msg.sender, newTokenId);
	}
	
	function takeTokens(uint count) public
	{
		require(unused[msg.sender]>count);
		unused[msg.sender] = unused[msg.sender] - count;
		
		for(uint i=0;i<count;i++)
		{
			createToken();
		}

	//	emit LogToken( msg.sender, newTokenId, count);
	}
	
	/*
	only if contract has enough and user has no one
	*/
	function getFreeToken(bytes32 r, bytes32 s, uint8 v) public
	{
		bytes memory prefix = "\x19Ethereum Signed Message:\n32";
		address signer = ecrecover(keccak256( abi.encodePacked(prefix, this, msg.sender) ), v, r, s);
        //require(admins[signer]);
		
		require(unused[this]>0);
		unused[this]--;
		
		require(balanceOf(msg.sender)==0);
		
		createToken();
	}
	
	function buyToken() public payable
	{
		require(unused[this]>0);
		unused[this]--;
		
		require(msg.value == buyPrice);
		
		createToken();
		
		// fee
		uint sendValue = msg.value;
		uint256 curFee = sendValue * FEECONTRACT / 100;
		sendValue = sendValue - curFee;
		feeValue = feeValue + curFee;
		
		artist.transfer(sendValue);
		
	//	emit LogToken( msg.sender, newTokenId, 1);
	}

	// как обновлять информацию?
	// пока только сам владелей может менять информацию
	function updateToken(uint idToken, uint params) public
	{
		//require(params!=0);
		require(tokens[idToken].time!=0);
		require(ownerOf(idToken) == msg.sender);
		
		tokens[idToken].params = params;
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