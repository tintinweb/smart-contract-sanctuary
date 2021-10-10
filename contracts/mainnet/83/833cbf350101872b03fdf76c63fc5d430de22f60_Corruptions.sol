//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Counters.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Strings.sol";


// Contract and art written and created by Verse Studios DAO @verse_devlog https://verse.art

contract Corruptions is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    
    using Strings for string;
    
    uint256 constant MAX_CORRUPTIONS = 888;

    Counters.Counter private _tokenIds;

    mapping(uint256 => uint256) tokenIdToGenealogy;

    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;
    
    bool hasSaleStarted = false;
    
    uint256 mintPrice = 100000000000000000;

    constructor()
    ERC721("Tech Mods", "TECH")
    {

    }

    function getEntityGenealogy(uint256 _tokenId) public view returns(string memory) {
        uint256 genealogy = tokenIdToGenealogy[_tokenId];
        return Strings.toString(genealogy);
    }

    function createToken() public payable returns(uint) 
    {
        require(hasSaleStarted == true);
        
        require(msg.value >= mintPrice);
        
        require(MAX_CORRUPTIONS >= _tokenIds.current() +1);
        
        
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        uint256 dna = uint256(keccak256(abi.encode(newTokenId, block.coinbase)));
        dna = dna % dnaModulus;
        dna = dna - dna % 100;

        

        _mint(msg.sender, newTokenId);
        
        //_setTokenURI(newTokenId, _tokenURI);
        tokenIdToGenealogy[newTokenId] = dna;


        return newTokenId;
       
    }
    
    function ownerMint(string memory _tokenURI) public onlyOwner returns(uint)
    {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        uint256 dna = uint256(keccak256(abi.encode(newTokenId, block.coinbase)));
        dna = dna % dnaModulus;
        dna = dna - dna % 100;

        

        _mint(msg.sender, newTokenId);
        
        _setTokenURI(newTokenId, _tokenURI);
        tokenIdToGenealogy[newTokenId] = dna;


        return newTokenId;
    }

    function megaMint(string[] memory _tokenURIs) public onlyOwner
    {
        uint256 batch = _tokenURIs.length;

        for(uint256 mintIndex = 0; mintIndex < batch; mintIndex++)
        {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();

            uint256 dna = uint256(keccak256(abi.encode(newTokenId, block.coinbase)));
            dna = dna % dnaModulus;
            dna = dna - dna % 100;
            
            _mint(msg.sender, newTokenId);

        
            _setTokenURI(newTokenId, _tokenURIs[mintIndex]);
            tokenIdToGenealogy[newTokenId] = dna;
        }
        
        
    }

    function setTokenURIs(uint256[] memory tokenIds, string[] memory tokenURIs) public onlyOwner
    {
        uint256 batch = tokenIds.length;

        for(uint256 i = 0; i < batch; i++)
        {

            _setTokenURI(tokenIds[i], tokenURIs[i]);
        }
        
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner
    {
        _setTokenURI(_tokenId, _tokenURI);
    }
    
    function setMintPrice(uint256 _newPrice) public onlyOwner
    {
        mintPrice = _newPrice;
    }
    
    function startSale() public onlyOwner
    {
        hasSaleStarted = true;
    }
    
    function pauseSale() public onlyOwner
    {
        hasSaleStarted = false;
    }
    
    function withdrawAll() public payable onlyOwner 
    {
        require(payable(msg.sender).send(address(this).balance));
    }

}