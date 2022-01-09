// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./RandomlyAssigned.sol";

contract BabyTK is ERC721, Ownable, RandomlyAssigned{
    using Strings for uint256;
    
    bool public paused = false;
    string public baseURI;
    string public baseExtension = ".json";
    uint8 public maxMintAmount = 50;
    uint16 maxSupply = 5000;
    uint16 currentSupply = 0;
    uint256 public cost = 0.0425 ether;
    uint256 startTime;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    mapping(uint256 => uint256) private _allTokensIndex;

    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;


    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI) 
        ERC721(_name, _symbol) 
        RandomlyAssigned(maxSupply,1)
        {
            setBaseURI(_initBaseURI);
            paused = false;
        }
        
    //internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //public
    function mint (uint8 _amount) public payable
    {
      require( tokenCount() + 1 <= totalSupply());
      require( availableTokenCount() - 1 >= 0);

      if (msg.sender != owner()) {  
        require( msg.value >= cost * _amount);
      }
      
      for(uint256 i = 1; i <= _amount; i++){
        uint256 id = nextToken();
        _safeMint(msg.sender, id);
        currentSupply++;
      }
   
    }
    
    function walletOfOwner(address _owner) public view
        returns (uint256[] memory) {
            uint256 ownerTokenCount = balanceOf(_owner);
            uint256[] memory tokenIds = new uint256[](ownerTokenCount);
            
            for(uint256 i; i < ownerTokenCount; i++){
                tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
            }
        return tokenIds;
        }
    
    function tokenURI(uint256 tokenId) public view virtual override 
        returns (string memory){
            require(_exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
            );
            
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length >0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
    }

    
    
    
    //only owner
    function setCost(uint256 _newCost) public onlyOwner() {
        cost = _newCost * 1e18;
    }
    
    function setmaxMintAmount(uint8 _newmaxMintAmount) public onlyOwner() {
        maxMintAmount = _newmaxMintAmount;
    }
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
    
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    
    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    
    //ENUMERABLE
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }
    
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
    
     function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
          uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }  
    
}