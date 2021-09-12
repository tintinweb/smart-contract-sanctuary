/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.7;
/*

Create an ERC721 Token with the following requirements

user can only buy tokens when the sale is started
the sale should be ended within 30 days
the owner can set base URI
the owner can set the price of NFT
NFT minting hard limit is 100

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
}

contract NFTAXY{
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    string private baseURI = "https://floydnft.com/token/";
    uint private salePrice;
    uint private hardLimit = 100;
    uint public currentPublicTokenID = 0;
    string _tokenName;
    string _tokenSymbol;
    uint private saleTill;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    address private _owner;
    
    
    using Strings for uint256;
    
    // mapping for storing token against uri
    mapping(uint=>string) public _tokenURImap;
    
    // constructor(string memory _tokenName, string memory _tokenSymbol,uint _salePrice) ERC721(_tokenName, _tokenSymbol){
    //     saleStart = false;
    //     salePrice = _salePrice;
    // }
    constructor(){
        _tokenName = "AXY Token";
        _tokenSymbol = "AXY";
        salePrice = 10;
        saleTill = 0 days;
        
        _owner = msg.sender;
    }
    
modifier _isSaleON() {
    require(block.timestamp < saleTill,"Sale is currently Off.");
    _;
}

modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
//_________________________________ FUNCTIONS ________________________________

function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
//_________________________________ FUNCTIONS ________________________________

function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view  returns (bool) {}
    function setApprovalForAll(address operator, bool approved) public virtual  {}
    function safeTransferFrom(address from,address to,uint256 tokenId) public virtual  { }
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes memory _data) public virtual  {}
    function transferFrom(address from,address to,uint256 tokenId) public virtual  {}
    function ownerOf(uint256 tokenId) public view virtual  returns (address) {}
    function approve(address to, uint256 tokenId) public virtual  {}
    function balanceOf(address aowner) public view virtual  returns (uint256) {}
    function getApproved(uint256 tokenId) public view virtual  returns (address) { }
    function isApprovedForAll(address bowner, address operator) public view virtual  returns (bool) {}
    
    // ___________________ Starting the sale ________________________
  function startSale(uint _forDays) public onlyOwner{
      uint _Days = _forDays * 1 days;
      require(_Days <= 30 days,"The sale has to be less or equal to 30 days");
      saleTill = block.timestamp + _Days;
  }  
  // ___________________ Stoping the sale ________________________
  function stopSale() public onlyOwner{
      require(block.timestamp < saleTill,"Sale is already Off.");
      saleTill = 0 days;
  }  
  
  //_____________________ Buying NFT ________________________
  function mintNdIncrementSupply(address to, uint tokenID) internal{
         _mint(to,tokenID);
    }
    
    
  function mintAXY(address _to,uint _quantity) payable external _isSaleON {
        require(_to != address(0), "Can't mint to 0 address");
        require(msg.value >= salePrice * _quantity && currentPublicTokenID + _quantity <= 100, "Not Enough Ether to buy NFTs or The buying NFTs are more then 100");
        
        for(uint i = 1; i<= _quantity; i++){
            currentPublicTokenID++;
            mintNdIncrementSupply(_to, currentPublicTokenID);
            // ________ Binding an url to a token ____________
            _tokenURImap[currentPublicTokenID] = tokenURI(currentPublicTokenID);
        }
  }
  
  function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI,tokenId.toString())) : "";
    }
  
  // ______________________ Setting URL _______________________
  function setURI(string memory _uri) public onlyOwner{
      baseURI = _uri;
    }
    
    // ______________________ Setting Price _______________________
  function setPrice(uint _price) public onlyOwner{
      salePrice = _price;
    }
}