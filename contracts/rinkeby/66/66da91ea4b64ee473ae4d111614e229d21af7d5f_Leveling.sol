// contracts/Leveling.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract Leveling is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    mapping(uint256 => uint256) private _tokenValues;
    
    uint256 public constant COLLECTION_SIZE = 9999;
    uint256 public constant MAX_RESERVED = 50;
    uint256 public constant MAX_MINT = 20;
    uint256 public constant MAX_BURN = 50;
    uint256 internal constant STARTING_LVL = 1;
    
    uint256 internal mintIndex = 0;
    uint256 internal additionMintIndex = COLLECTION_SIZE;

    string private baseURI = 'ipfs://QmYhsZgJjdFydTy1LnHb7WotcYsQYmB6encDte5Gdkq2Uj/';

    bool publicSale = false;

    constructor() ERC721("Leveling", "LVLING"){}

    function _baseURI() internal view override returns (string memory) 
    {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner 
    {
        baseURI = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) 
    {
        require(_exists(tokenId), "TokenId must exist to get tokenURI");

        uint256 tokenVal = _tokenValues[tokenId];
        return string(abi.encodePacked(_baseURI(), tokenVal.toString()));
    }

    function _setTokenValue(uint256 tokenId, uint256 tokenVal) internal 
    {
        require(_exists(tokenId), "TokenId must exist to set tokenValue");
        _tokenValues[tokenId] = tokenVal;
    }

    function tokenValue(uint256 tokenId) public view returns (uint256) 
    {
        return _tokenValues[tokenId];
    }

    function highestLevelOfOwner(address owner) public view returns (uint256)
    {
        uint256 numOwnedTokens = balanceOf(owner);

        uint256 maxLevel = 0;
        for (uint256 i = 0; i < numOwnedTokens; i++)
        {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i);
            uint256 tokenVal = tokenValue(tokenId);

            if (tokenVal > maxLevel)
            {
                maxLevel = tokenVal;
            }
        }

        return maxLevel;
    }

    function _burn(uint256 tokenId) internal virtual override 
    {
        super._burn(tokenId);

        if (_tokenValues[tokenId] != 0) {
            delete _tokenValues[tokenId];
        }
    }

    function levelUpAndBurn(uint256 tokenId1, uint256 tokenId2) external nonReentrant 
    {
        require(_exists(tokenId1), "TokenId1 must exist");
        require(_exists(tokenId2), "TokenId2 must exist");
        require(ownerOf(tokenId1) == msg.sender, "Must own the token you're trying to burn");
        require(ownerOf(tokenId2) == msg.sender, "Must own the token you're trying to burn");

        uint256 tokenId1Val = tokenValue(tokenId1);
        uint256 tokenId2Val = tokenValue(tokenId2);

        uint256 newVal = tokenId1Val + tokenId2Val;

        _burn(tokenId1);
        _burn(tokenId2);

        _safeMint(msg.sender, additionMintIndex);

        _setTokenValue(additionMintIndex, newVal);
        additionMintIndex++;
    }

    function levelUpAndBurnMultiple(uint256 burnBelowLevel, uint256 burnAboveLevel, uint256 numToBurn) external nonReentrant
    {
        require (numToBurn >= 2, "Must burn at least two tokens");

        uint256 numOwnedTokens = balanceOf(msg.sender);
        
        numToBurn = numToBurn > numOwnedTokens 
            ? numOwnedTokens 
            : numToBurn;

        require (numOwnedTokens >= 2, "Must own at least two tokens to burn");

        uint256 endTokenVal = 0;

        uint256 burnIndex = 0;
        uint256[] memory tokenIdsToBurn = new uint256[](numToBurn);

        for (uint256 i = 0; i < numToBurn; i++)
        {
            //abort early if we've reached max burn
            if (burnIndex >= MAX_BURN)
            {
                break;
            }

            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            uint256 tokenVal = tokenValue(tokenId);

            if (tokenVal < burnBelowLevel || tokenVal > burnAboveLevel)
            {   
                endTokenVal += tokenVal;
                tokenIdsToBurn[burnIndex] = tokenId;
                burnIndex++;
            }
        }

        require (burnIndex >= 2, "Not enough tokens to burn within specified parameters");
        
        for (uint256 j = 0; j < burnIndex; j++)
        {
           _burn(tokenIdsToBurn[j]);
        }

        _safeMint(msg.sender, additionMintIndex);
        _setTokenValue(additionMintIndex, endTokenVal);
        additionMintIndex++;
    } 

    function mint(uint256 num) public nonReentrant
    {
        require(publicSale, "Public sale must be active");
        require(num <= MAX_MINT, "Can only mint 20 tokens at a time");
        require(num > 0, "Must mint at least one token");
        require(mintIndex + num < COLLECTION_SIZE, "Purchase would exceed collection size");

        for (uint256 i = 0; i < num; i++) {
            uint256 index = i+mintIndex;
            _safeMint(msg.sender, index);
            _setTokenValue(index, STARTING_LVL);
        }

        mintIndex += num;
    }

    function mintReserved(uint256 numToReserve) external nonReentrant onlyOwner
    {
        require(mintIndex < MAX_RESERVED, "Can only reserve a max of 50 tokens");
        
        for (uint256 i = 0; i < numToReserve; i++) {
            uint256 index = i+mintIndex;
            _safeMint(msg.sender, index);
            _setTokenValue(index, STARTING_LVL);
        }

        mintIndex += numToReserve;
    }

    function togglePublicSale() external onlyOwner
    {
        publicSale = !publicSale;
    }

    function withdraw() external onlyOwner 
    {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }
}