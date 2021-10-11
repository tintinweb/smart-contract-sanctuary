// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";
import "Counters.sol";
import "Ownable.sol";
import "ERC721URIStorage.sol";

contract ArkarusGacha is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private gachaURI = "https://gateway.pinata.cloud/ipfs/QmTJ1kwADh5cq5EB4sYViPqrGaBsGptpNzBNais3ADcDNL";
    uint256 private gachaLimit = 1000;
    // string private premiumGachaURI = "";
    // uint256 private premiumGachaLimit = 1000;
    string private openGachaURI = "https://gateway.pinata.cloud/ipfs/QmfJWZ7yJUUN129tMjaXtAsreSXq5Zy85Sr8iJQv4stMH6";
    uint256 private robotsPerGacha = 10;
    uint256 private gachaPrice = 0.01*10**18;
    
    constructor() public ERC721("Arkarus Gacha NFT", "AKSGACHA") {}

    event nftPrice(uint256);

    function setGachaURI(string memory newGachaURI) public onlyOwner
    {
        gachaURI = newGachaURI;
    }
    
    function getGachaURI() public view returns(string memory)
    {
        return gachaURI;
    }
    
    function setGachaLimit(uint newGachaLimit) public onlyOwner
    {
        gachaLimit = newGachaLimit;
    }
    
    function getGachaLimit() public view returns(uint256)
    {
        return gachaLimit;
    }

    function setOpenGachaURI(string memory newOpenGachaURI) public onlyOwner
    {
        openGachaURI = newOpenGachaURI;
    }
    
    function getOpenGachaURI() public view returns(string memory)
    {
        return openGachaURI;
    }

    function setRobotsPerGacha(uint256 newRobotsPerGacha) public onlyOwner
    {
        robotsPerGacha = newRobotsPerGacha;
    }
    
    function getRobotsPerGacha() public view returns(uint256)
    {
        return robotsPerGacha;
    }


    function mintGachaTicket() public payable returns (uint256)
    {
        require(_tokenIds.current() <= gachaLimit, 'Gacha ticket reaches limit');      
        
        // emit nftPrice(msg.value);
        // payable(address(this)).transfer(msg.value);
        
        emit nftPrice(gachaPrice);
        payable(address(this)).transfer(gachaPrice);
        
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, gachaURI);


        return newItemId;
    }
    
    function getBalance() public view returns (uint256)
    {
        return address(msg.sender).balance;
    }
    
    function mintOpenGacha(uint256 tokenId) public returns (uint256)
    {
        require(msg.sender == ERC721.ownerOf(tokenId), "Only token owner can open gacha");
        _burn(tokenId);
        
        uint j=0;
        uint256 newItemId;
        for(j; j<robotsPerGacha; j++)
        {
            _tokenIds.increment();

            newItemId = _tokenIds.current();
            _mint(msg.sender, newItemId);
            _setTokenURI(newItemId, openGachaURI);
        }
        
        // _tokenIds.increment();

        // uint256 newItemId = _tokenIds.current();
        // _mint(msg.sender, newItemId);
        // _setTokenURI(newItemId, openGachaURI);

        return newItemId;
    }
    
    function getContractBalance() public view returns (uint256)
    {
        return address(this).balance;
    }
    
    
    // function mintPremiumGachaTicket() public returns (uint256)
    // {
    //     require(_tokenIds.current() <= gachaLimit, 'Gacha ticket reaches limit');
        
    //     _tokenIds.increment();

    //     uint256 newItemId = _tokenIds.current();
    //     _mint(msg.sender, newItemId);
    //     _setTokenURI(newItemId, gachaURI);

    //     return newItemId;
    // }
}