pragma solidity ^0.4.25;

/*
VERSION DATE: 23/10/2018
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
}

contract ERC721 is ERC721Abstract
{
	string constant public   name = "SuperFan";
	string constant public symbol = "SFT";

	uint256 public totalSupply;
	
	struct Token
	{
		uint256 price;
		uint256	pack;
		string uri;
	}
	
	mapping (uint256 => Token) public tokens;
	
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
			ownershipTokenCount[_from]--;
			// clear any previously approved ownership exchange
			delete tokenIndexToApproved[_tokenId];
			emit Transfer(_from, _to, _tokenId);
		}

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
		Token storage tkn = tokens[_tokenId];
		return tkn.uri;
	}
	
	function tokenURI(uint256 _tokenId) public view returns (string infoUrl)
	{
		Token storage tkn = tokens[_tokenId];
		return tkn.uri;
	}

}

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

contract SuperFan is ERC721, Owned
{
	constructor() public {}
	
	event LogToken(address user, uint256 idToken, uint256 amount);
	
	function addToken(uint256 option, string struri) public onlyOwner payable
	{
	
		Token memory _token = Token({
			price: msg.value,
			pack : option,
			uri : struri
		});

		uint256 newTokenId = totalSupply++;
		tokens[newTokenId] = _token;
		
		_transfer(0x0, msg.sender, newTokenId);
		
		emit LogToken( msg.sender, newTokenId, msg.value);
	}
	
}