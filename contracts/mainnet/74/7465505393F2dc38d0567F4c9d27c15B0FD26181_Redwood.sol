// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

// Inspired/Copied fromm cyberpunks BGANPUNKS,
// cryptovoxels, etherpoems, rug.wtf.
// coolcats, punkcats, discord.art, zenft, 
// and all creators in the nft struggle

// special shoutout: @evacyrif -- thank you!
// YWhales -- hey!

// Yeah, this album is dedicated
// To all the teachers that told me I'd never amount to nothin'
// To all the people that lived above the buildings that I was hustlin' in front of
// Called the police on me when I was just tryin' to make some money to feed my daughter (it's all good)
// And all the ****** in the struggle
// You know what I'm sayin'? It's all good, baby baby
// ...Juicy by The Notorious B.I.G.

//                      .  .---.                .  
//              o      _|_ |                   _|_ 
//    .--.--.   .  .--. |  |--- .-. .--..-. .--.|  
//    |  |  |   |  |  | |  |   (   )|  (.-' `--.|  
//____'  '  `--' `-'  `-`-''    `-' '   `--'`--'`-'
// _mintForest Redwoods August 2021     
                                                 


contract Redwood is ERC721, Ownable {
    using SafeMath for uint256;
    uint public constant MAX_REDWOODS = 10000;
    bool public hasSaleStarted = false;
    uint public sell_max = 250;
    uint public price = 50000000000000000; // 0.05eth to start
    
    // The IPFS hash for all Chubbies concatenated *might* 
    // stored here once all Chubbies are issued and if I figure it out
    string public METADATA_PROVENANCE_HASH = "";

    // Truth.　
    string public constant R = "NFTs for the planet. 1Billion trees planted IRL.";

    // Mapping from token ID to name
    mapping (uint256 => string) private _tokenName;

    // Mapping if certain name string has already been reserved
    mapping (string => bool) private _nameReserved;

    constructor(string memory baseURI) ERC721("_mintForest Redwoods", "_mF_REDWOODS")  {
        setBaseURI(baseURI);
    }

    // Events
    event NameChange (uint256 indexed tokenIndex, string newName);
    event Unveil(uint256 indexed tokenIndex);

    //@dev Returns if the name has been reserved.
    function isNameReserved(string memory nameString) public view returns (bool) {
        return _nameReserved[toLower(nameString)];
    }

    // gets current name of tokenId, if any
    function getTokenName(uint256 tokenId) public view returns (string memory){
        return _tokenName[tokenId];
    }

    function getPrice() public view returns (uint){
        return price;
    }


    //Changes the name for tokenId
    function changeName(uint256 tokenId, string memory newName) public {
        address owner = ownerOf(tokenId);

        require(_msgSender() == owner, "ERC721: caller is not the owner");
        require(validateName(newName) == true, "Not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])), "New name is same as the current one");
        require(isNameReserved(newName) == false, "Name already reserved");
        // If already named, dereserve old name
        if (bytes(_tokenName[tokenId]).length > 0) {
            toggleReserveName(_tokenName[tokenId], false);
        }
        toggleReserveName(newName, true);
        _tokenName[tokenId] = newName;
        emit NameChange(tokenId, newName);
    }


    // @dev Reserves the name if isReserve is set to true, de-reserves if set to false
    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    // Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
    function validateName(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 25) return false; // Cannot be longer than 25 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            )
                return false;

            lastChar = char;
        }

        return true;
    }

    // @dev Converts the string to lowercase
    function toLower(string memory str) public pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    

    
   function mintTree(uint256 numRedwoods) public payable {
        require(hasSaleStarted == true, "Sale hasn't started");
        require(totalSupply() < MAX_REDWOODS, "Sale has already ended");
        require(totalSupply() < sell_max, "Current phase is sold out.");
        require(numRedwoods > 0 && numRedwoods <= 200, "You can adopt minimum 1, maximum 200 Redwoods");
        require(totalSupply().add(numRedwoods) <= MAX_REDWOODS, "Exceeds MAX_REDWOODS");
        require(totalSupply().add(numRedwoods) <= sell_max, "Exceeds sell max.");
        require(msg.value >= price.mul(numRedwoods), "Ether value sent is below the price");

        for (uint i = 0; i < numRedwoods; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            emit Unveil(mintIndex);
        }
    }
    
    // God Mode
    function setProvenanceHash(string memory _hash) public onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setPrice(uint newPriceGwei) public onlyOwner {
        //  receives new price in gwei
        price = newPriceGwei;
    }

    function setSellMax(uint newSellMax) public onlyOwner {
        require(newSellMax > totalSupply(), "New sell max lower than qty sold.");
        require(newSellMax <= MAX_REDWOODS, "New sell max higher than total.");
        sell_max = newSellMax;
    }
    
    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }
    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }
    
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function ownerMint(uint256 numRedwoods, address addressTo) public onlyOwner {
        require(totalSupply().add(numRedwoods) <= MAX_REDWOODS, "Exceeded supply");
        require(totalSupply().add(numRedwoods) <= sell_max, "Exceeds sell max.");
        //require(hasSaleStarted == false, "Sale has already started");
        uint256 index;
        // Reserved for people who helped this project and giveaways
        for (index = 0; index < numRedwoods; index++) {
            uint mintIndex = totalSupply();
            _safeMint(addressTo, mintIndex);
            emit Unveil(mintIndex);
        }
    }
}