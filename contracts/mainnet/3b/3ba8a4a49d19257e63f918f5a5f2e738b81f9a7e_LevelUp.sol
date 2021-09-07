// contracts/LevelUp.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract LevelUp is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    mapping(uint256 => uint256) private _tokenValues;
    
    uint256 public constant COLLECTION_SIZE = 9999;
    uint256 public constant MAX_MINT = 20;
    uint256 public constant MAX_BURN = 20;
    uint256 public constant MINT_COST = 0.05 * 10**18; //0.05 ETH
    uint256 internal constant STARTING_LVL = 1;

    uint256 internal mintIndex = 0;
    uint256 internal additionMintIndex = COLLECTION_SIZE;

    string private baseURI = 'ipfs://QmQMUrKUhsqhwyGjZZeydWWio9n3MJQGCWAA6bDHj9RDAP/';

    constructor() ERC721("LevelUp", "LVLUP"){}

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

    function levelUpAndBurnMultiple(uint256 belowLevel, uint256 aboveLevel) external nonReentrant
    {
        uint256 numOwnedTokens = balanceOf(msg.sender);

        require (numOwnedTokens >= 2, "Must own at least two tokens to combine");

        uint256 endTokenVal = 0;

        uint256 burnIndex = 0;
        uint256[] memory tokenIdsToBurn = new uint256[](20);

        for (uint256 i = 0; i < numOwnedTokens; i++)
        {
            //abort early if we've reached max burn
            if (burnIndex >= MAX_BURN)
            {
                break;
            }

            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            uint256 tokenVal = tokenValue(tokenId);

            if (tokenVal < belowLevel || tokenVal > aboveLevel)
            {   
                endTokenVal += tokenVal;
                tokenIdsToBurn[burnIndex] = tokenId;
                burnIndex++;
            }
        }

        require (burnIndex >= 2, "Not enough tokens to burn within parameters specified");
        
        for (uint256 j = 0; j < burnIndex; j++)
        {
           _burn(tokenIdsToBurn[j]);
        }

        _safeMint(msg.sender, additionMintIndex);
        _setTokenValue(additionMintIndex, endTokenVal);
        additionMintIndex++;
    } 

    function mint(uint num) external payable nonReentrant
    {
        require(num <= MAX_MINT, "Can only mint 20 tokens at a time");
        require(num > 0, "Must mint at least one token");
        require(mintIndex + num < COLLECTION_SIZE, "Purchase would exceed collection size");
        require(MINT_COST <= msg.value, "Cost is higher than provided value");

        for (uint256 i = 0; i < num; i++) {
            uint256 index = i+mintIndex;
            _safeMint(msg.sender, index);
            _setTokenValue(index, STARTING_LVL);
        }

        mintIndex += num;
    }

    function withdraw() external onlyOwner 
    {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }
}