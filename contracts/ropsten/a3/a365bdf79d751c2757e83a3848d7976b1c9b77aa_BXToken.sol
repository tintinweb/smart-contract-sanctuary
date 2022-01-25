/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/Strings.sol)

/*
    @contract BXToken
    @description NFT Contract of bx.com.br
*/

pragma solidity ^0.8.0;


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
    
    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
}

pragma solidity ^0.8.0;

/**
* @dev - name BX Contract
*      - description BX Token used by our projects
*      - author bx.com.br
*      - url https://bx.com.br
 */
contract BXToken {
    
    using Strings for uint256;
    
    mapping (uint256 => address) private tokenOwner;
    mapping (uint256 => uint256) public tokenToPrice;
    mapping (uint256 => uint256) public tokenToBxId;
    
    event Mint(address indexed from_, uint256 tokenId_, uint256 bxId_, string name_, string tokenURI_, uint256 price_);
    event Transfer(address indexed from_, address indexed to_, uint256 tokenId_, uint256 bxId_, uint256 price_);
    
    address payable owner;
    
    string private _name;
    string private _symbol;
    string private _baseURI;
    string private _baseURL;

    
    struct NFT {
        uint256 tokenId;
        uint256 bxId;
        string name;
        string group;
        string tokenURI;
    }
    
    NFT[] public _nfts;
    
    constructor(string memory name_, string memory symbol_, string memory baseURI_, string memory baseURL_) {
        owner = payable(msg.sender);
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
        _baseURL = baseURL_;
    }
    
    /**
     * @dev Modifier only contract owner can call method.
     */
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    /**
     * @dev Append two strings
     */
    function append(string storage a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
    
    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }
    
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    
    /**
     * @dev Returns owner of tokenId
     */
    function ownerOf(uint256 tokenId_) public view virtual returns (address) {
        return tokenOwner[tokenId_];
    }
    
    /**
     * @dev Returns token URL in market using tokenID
     */
    function getToken(uint256 tokenId_) public view virtual returns (uint256, string memory, string memory) {
        NFT storage nft = _nfts[tokenId_];
        return (nft.tokenId, nft.name, nft.tokenURI);
    }
    
    /**
     * @dev Returns tokenURI using tokenID
     */
    function tokenURI(uint256 tokenId_) public view virtual returns (string memory) {
        NFT storage nft = _nfts[tokenId_];
        return append(_baseURI, nft.tokenURI);
    }
    
    /**
     * @dev Returns token URL in market using tokenID
     */
    function tokenURL(uint256 tokenId_) public view virtual returns (string memory) {
        NFT storage nft = _nfts[tokenId_];
        return append(_baseURL, nft.tokenId.toString());
    }
    
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _nfts.length;
    }
    
    /**
     * @dev Set price to token. If price is zero, nft cannot be purchased
     */
    function setTokenPrice(uint256 tokenId_, uint256 price_) external {
        require(msg.sender == tokenOwner[tokenId_], 'Not owner of this token');
        tokenToPrice[tokenId_] = price_;
    }
    
    /**
     * @dev Returns token price
     */
    function getTokenPrice(uint256 tokenId_) public view virtual returns (uint256) {
        return tokenToPrice[tokenId_];
    }
    
    /**
     * @dev Mint nft. If price is zero, nft cannot be purchased
     */
    function mintNFT(address to_, string memory name_, string memory group_, string memory tokenURI_, uint256 bxId_, uint256 price_) external onlyOwner returns (uint256) {
        require(owner == msg.sender); // Only the Owner can create nfts
        uint256 nftId = totalSupply(); // NFT id
        _nfts.push(NFT(nftId, bxId_, name_, group_, tokenURI_));
        tokenOwner[nftId] = to_;
        tokenToPrice[nftId] = price_;
        tokenToBxId[nftId] = bxId_;
        emit Mint(msg.sender, nftId, bxId_, name_, tokenURI_, price_);
        return nftId;
    }
    
    /**
     * @dev Buy nft. Pay nft price, transfer to seller, change of owner.
     */
    function buy(uint256 tokenId_) external payable {
        uint256 price = tokenToPrice[tokenId_];
        string memory token_not_for_sale = Strings.append('This token is not for sale - ', Strings.toString(price));
        require(price != 0, token_not_for_sale);
        require(msg.value == price, 'Incorrect value');
        
        address seller = tokenOwner[tokenId_];
        require(seller != msg.sender, 'You already have this token');
        
        payable(seller).transfer(msg.value);
        
        tokenOwner[tokenId_] = msg.sender;
        
        tokenToPrice[tokenId_] = 0; // not for sale for now
        
        emit Transfer(seller, msg.sender, tokenId_, tokenToBxId[tokenId_], price);
    }
    
}