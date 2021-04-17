/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
/// SPDX-License-Identifier: GPL-3.0-or-later

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

library Utilities {
	// concat two bytes objects
    function concat(bytes memory a, bytes memory b)
            internal pure returns (bytes memory) {
        return abi.encodePacked(a, b);
    }

    // convert address to bytes
    function toBytes(address x) internal pure returns (bytes memory b) {
		b = new bytes(20);

		for (uint i = 0; i < 20; i++)
			b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
	}

	// convert uint256 to bytes
	function toBytes(uint256 x) internal pure returns (bytes memory b) {
    	b = new bytes(32);
    	assembly { mstore(add(b, 32), x) }
	}
}

contract GAMMA { // Γ - mv - NFT - mkt - γ
    address payable public dao = 0x057e820D740D5AAaFfa3c6De08C5c98d990dB00d;
    uint256 public constant GAMMA_MAX = 5772156649015328606065120900824024310421;
    uint256 public totalSupply;
    string public name = "GAMMA";
    string public symbol = "GAMMA";
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => bool) public burned;
    mapping(uint256 => uint256) public tokenByIndex;
    mapping(uint256 => string) public tokenURI;
    mapping(uint256 => Sale) public sale;
    mapping(bytes4 => bool) public supportsInterface; // eip-165 
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(address => mapping(uint256 => uint256)) public tokenOfOwnerByIndex;
    event Approval(address indexed approver, address indexed spender, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event UpdateSale(uint256 indexed ethPrice, uint256 indexed tokenId, bool forSale);
    struct Sale {
        uint256 ethPrice;
        bool forSale;
    }
    constructor (string memory _name, string memory _symbol) public {
        supportsInterface[0x80ac58cd] = true; // ERC721 
        supportsInterface[0x5b5e139f] = true; // METADATA
        supportsInterface[0x780e9d63] = true; // ENUMERABLE
        name = _name;
        symbol = _symbol;
    }
    function approve(address spender, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId] || isApprovedForAll[ownerOf[tokenId]][msg.sender], "!owner/operator");
        getApproved[tokenId] = spender;
        emit Approval(msg.sender, spender, tokenId); 
    }
    function mint(uint256 ethPrice, string calldata _tokenURI, bool forSale) external { 
        totalSupply++;
        require(totalSupply <= GAMMA_MAX, "maxed");
        uint256 tokenId = totalSupply;
        balanceOf[msg.sender]++;
        ownerOf[tokenId] = msg.sender;
        tokenByIndex[tokenId - 1] = tokenId;
        tokenURI[tokenId] = _tokenURI;
        sale[tokenId].ethPrice = ethPrice;
        sale[tokenId].forSale = forSale;
        tokenOfOwnerByIndex[msg.sender][tokenId - 1] = tokenId;
        emit Transfer(address(0), msg.sender, tokenId); 
        emit UpdateSale(ethPrice, tokenId, forSale);
    }
    function purchase(uint256 tokenId) payable external {
        require(msg.value == sale[tokenId].ethPrice, "!ethPrice");
        require(sale[tokenId].forSale, "!forSale");
        address owner = ownerOf[tokenId];
        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "!transfer");
        _transfer(owner, msg.sender, tokenId);
    }
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function _transfer(address from, address to, uint256 tokenId) internal {
        balanceOf[from]--; 
        balanceOf[to]++; 
        getApproved[tokenId] = address(0);
        ownerOf[tokenId] = to;
        sale[tokenId].forSale = false;
        tokenOfOwnerByIndex[from][tokenId - 1] = 0;
        tokenOfOwnerByIndex[to][tokenId - 1] = tokenId;
        emit Transfer(from, to, tokenId); 
    }
    function transfer(address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "!owner");
        _transfer(msg.sender, to, tokenId);
    }
    function transferBatch(address[] calldata to, uint256[] calldata tokenId) external {
        require(to.length == tokenId.length, "!to/tokenId");
        for (uint256 i = 0; i < to.length; i++) {
            require(msg.sender == ownerOf[tokenId[i]], "!owner");
            _transfer(msg.sender, to[i], tokenId[i]);
        }
    }
    function transferFrom(address from, address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId] || getApproved[tokenId] == msg.sender || isApprovedForAll[ownerOf[tokenId]][msg.sender], "!owner/spender/operator");
        _transfer(from, to, tokenId);
    }
    function updateDao(address payable _dao) external {
        require(msg.sender == dao, "!dao");
        dao = _dao;
    }
    function updateSale(uint256 ethPrice, uint256 tokenId, bool forSale) payable external {
        require(msg.sender == ownerOf[tokenId], "!owner");
        sale[tokenId].ethPrice = ethPrice;
        sale[tokenId].forSale = forSale;
        (bool success, ) = dao.call{value: msg.value}("");
        require(success, "!transfer");
        emit UpdateSale(ethPrice, tokenId, forSale);
    }
    function burn(uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "!owner");
        burned[tokenId] = true;
        _transfer(ownerOf[tokenId], address(0), tokenId);
    }
}

contract RealVault {
    address vault = address(this);
    address escrow = 0x4744cda32bE7b3e75b9334001da9ED21789d4c0d;
    uint256 propertyCount;
    
    GAMMA public property;
    GAMMA public rights;
    
    mapping(bytes => bool) public inVault;
    mapping(bytes => uint256[]) public rightsPerProperty;
  
    constructor() public {
        property = new GAMMA("Property", "pGAMMA");
        rights = new GAMMA("Rights", "rGAMMA");
    }  
  
    // ----- Mint property NFTs
    function mintProperty(uint256 _ethPrice, string calldata _tokenURI, bool _forSale) public {
        propertyCount++;
        property.mint(_ethPrice, _tokenURI, _forSale);
        bytes memory tokenKey = getTokenKey(address(property), property.totalSupply());
        inVault[tokenKey] = true;
    }
    
    // ----- Deposit property NFTs
    function depositProperty(address _tokenAddress, uint256 _tokenId) public {
		propertyCount++;
		require(IERC721(_tokenAddress).ownerOf(_tokenId) == msg.sender, "!owner");
		bytes memory tokenKey = getTokenKey(_tokenAddress, _tokenId);
		inVault[tokenKey] = true;
		IERC721(_tokenAddress).transferFrom(msg.sender, vault, _tokenId);
	}
	
	// ----- Mint rights NFTs
    function mintRights(address _tokenAddress, uint256 _tokenId, uint256 _ethPrice, string calldata _tokenURI, bool _forSale) public {
        require(IERC721(_tokenAddress).ownerOf(_tokenId) != address(0), 'Property does not exist!');
        
        bytes memory tokenKey = getTokenKey(_tokenAddress, _tokenId);
        require(inVault[tokenKey], 'Property is not in vault!');
        
        rights.mint(_ethPrice, _tokenURI, _forSale);
        rightsPerProperty[tokenKey].push(rights.totalSupply());
    }
    
    // ----- Send to escrow
    function toEscrow(address _tokenAddress, uint256 _tokenId) public {
        bytes memory tokenKey = getTokenKey(_tokenAddress, _tokenId);
        
        if (address(property) == _tokenAddress) {
            require(inVault[tokenKey], 'Property is not in vault!');
            IERC721(_tokenAddress).transferFrom(vault, escrow, _tokenId);
            inVault[tokenKey] = false;
        } else if (address(rights) == _tokenAddress) {
            for(uint i = 0; i < rightsPerProperty[tokenKey].length; i++) {
                if (rightsPerProperty[tokenKey][i] == _tokenId) {
                    IERC721(_tokenAddress).transferFrom(vault, escrow, _tokenId);
                } else {
                    break;
                }
            }
        }
    }
    
    // ----- Approve contracts to transfer property and rights NFTs
    function approveContract(address _contract) public {
        property.setApprovalForAll(_contract, true);
        rights.setApprovalForAll(_contract, true);
    }

    // ----- Get token key for a given NFT 
	function getTokenKey(address tokenAddress, uint256 tokenId) public pure returns (bytes memory) {
		return Utilities.concat(Utilities.toBytes(tokenAddress), Utilities.toBytes(tokenId));
	}
	
    receive() external payable {  require(msg.data.length ==0); }
}