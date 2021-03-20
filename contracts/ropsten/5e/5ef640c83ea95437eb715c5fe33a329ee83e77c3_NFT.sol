/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

contract NFT {

    address public owner;
	string public name;
	string public symbol;
	
	mapping (uint256 => string) internal idToUri;
	mapping (uint256 => address) internal idToOwner;
	mapping (address => uint256) private ownerToNFTokenCount;
	mapping (uint256 => address) internal idToApproval;
	
	event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
	event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	
	modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
	
	modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || idToApproval[_tokenId] == msg.sender);
        _;
    }
	
	modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0));
        _;
    }
    
    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender);
        _;
    }
	
	constructor(string memory _name, string memory _symbol) {
	    owner = msg.sender;
		name = _name;
		symbol = _symbol;
	}
	
	function tokenURI(uint256 _tokenId) public view returns (string memory) {
		require(idToOwner[_tokenId] != address(0));
		return idToUri[_tokenId];
	}
	
	function approve(address _approved, uint256 _tokenId) public canOperate(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner);
        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return getOwnerNFTCount(_owner);
    }
    
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        _owner = idToOwner[_tokenId];
        require(_owner != address(0));
    }
    
    function transfer(address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        address from = idToOwner[_tokenId];
        removeNFToken(from, _tokenId);
        addNFToken(_to, _tokenId);
        clearApproval(_tokenId);
        emit Transfer(from, _to, _tokenId);
    }
    
    function addNFToken(address _to, uint256 _tokenId) internal virtual {
        require(idToOwner[_tokenId] == address(0));
        idToOwner[_tokenId] = _to;
        ownerToNFTokenCount[_to] = ownerToNFTokenCount[_to] + 1;
    }
    
    function getOwnerNFTCount(address _owner) internal virtual view returns (uint256) {
        return ownerToNFTokenCount[_owner];
    }
	
	function burn(uint256 _tokenId) public virtual {
	    require(msg.sender == idToOwner[_tokenId]);
		address tokenOwner = idToOwner[_tokenId];
		clearApproval(_tokenId);
		removeNFToken(tokenOwner, _tokenId);
		emit Transfer(tokenOwner, address(0), _tokenId);
	}
	
	function clearApproval(uint256 _tokenId) internal virtual {
		if (idToApproval[_tokenId] != address(0)) {
			delete idToApproval[_tokenId];
		}
	}

	function removeNFToken(address _from, uint256 _tokenId) internal virtual {
		require(idToOwner[_tokenId] == _from);
		ownerToNFTokenCount[_from] = ownerToNFTokenCount[_from] - 1;
		delete idToOwner[_tokenId];
	}
	
	function setTokenUri(uint256 _tokenId, string memory _uri) internal onlyOwner {
		require(idToOwner[_tokenId] != address(0));
		idToUri[_tokenId] = _uri;
	}
	
	function mint(address _to, uint256 _tokenId, string calldata _uri) public onlyOwner {
		require(_to != address(0));
		require(idToOwner[_tokenId] == address(0));
		idToOwner[_tokenId] = _to;
		ownerToNFTokenCount[_to] = ownerToNFTokenCount[_to] + 1;
		setTokenUri(_tokenId, _uri);
		emit Transfer(address(0), _to, _tokenId);
	}
	
	function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

}