// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Base64Utils.sol";

pragma solidity ^0.8.0;

interface TokenInterface {
    function claim(address recipient, uint256 tokenId, uint256 _dayPasses, uint256 _packChoice, uint256 _petChoice) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Cryptogotchi_Genesis_Eggs is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for string;
    
    bool public hatchingEnabled;
    bool public mintEnabled;
    
    address public cryptogotchiContract;
    address public WethAddress = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    uint256 public price = 30000000000000000; // .03 wETH
    
    string[3] public svgData;
    string[4] public metadata;
    // rainbow1, gold2, silver3
    
    struct Egg {
        uint256 dayPasses;
        uint256 pet;
    }
    
    constructor() ERC721("Cryptogotchi Genesis Egg", "EGG"){}
    
    event Claim(address claimFrom, uint256 tokenId, uint256 dayPasses, uint256 packChoice, uint256 petChoice);
    event Mint(address mintedTo, uint256 tokenId);
    
    mapping(uint256 => Egg) public unit;
    
    Counters.Counter private _tokenIds;
    
    function setCryptogotchiContract(address nftContract) public onlyOwner {
        cryptogotchiContract = nftContract;
    }
    
    function enableMint() public onlyOwner {
        mintEnabled = true;
    }
    
    function enableClaiming() public onlyOwner {
        hatchingEnabled = true;
    }
    
    function withdrawMatic() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function setMetadata(string memory _data, uint256 position) public onlyOwner {
        metadata[position] = _data;
    }
    
    function setSvgData(string memory _data, uint256 position) public onlyOwner {
        svgData[position] = _data;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        Egg memory egg = unit[tokenId];
        
        string memory output = string(abi.encodePacked(
            svgData[0], 
            Utils.toString(tokenId), 
            svgData[1], 
            Utils.toString(egg.dayPasses),
            svgData[2], 
            Utils.toAsciiString(ownerOf(tokenId)),
            metadata[egg.pet]
        ));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Crypogotchi Genesis Egg #', Utils.toString(tokenId), '", "description": "A Cryptogotchi is a living interactive NFT that yeilds Quantifiable Spacetime Meed (QSM) tokens as a reward when properly cared for.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    
    function mintNFT(uint256 amount) public {
        require(mintEnabled, 'mint not enabled');
        require(amount > 0, 'no amount');
        require(amount <= 5, 'max 5 per purchase');
        require(_tokenIds.current() < 1050, 'mint limit reached');
        require(_tokenIds.current() + amount <= 1050, 'amount exceeds max mintable');
        require(TokenInterface(WethAddress).allowance(msg.sender, address(this)) >= price * amount, 'not approved'); //.035 wETH
        require(TokenInterface(WethAddress).balanceOf(msg.sender) >= price * amount, 'insufficient wETH balance');
        
        TokenInterface(WethAddress).transferFrom(msg.sender, owner(), price * amount);
        
        for (uint256 i = 0; i < amount; i++) {
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            
            uint256 _pet;
            uint256 _dayPasses;
            
            // 500 rainbow
            if (tokenId <= 550) {
                _pet = 1;
                _dayPasses = 700;
            } 
            // 300 first in flight
            if (tokenId > 550 && tokenId <= 850) {
                _pet = 2;
                _dayPasses = 600;
            }
            // 200 death star
            if (tokenId > 850 && tokenId <= 1050) {
                _pet = 3;
                _dayPasses = 500;
            }
            
            unit[tokenId] = Egg({ dayPasses: _dayPasses, pet: _pet });
            
            _safeMint(msg.sender, tokenId);
            
            emit Mint(msg.sender, tokenId);
        }
    }
    
    // 20 rainbow 15 gold 15 silver then to existing wallets.
    function mintGenesis(address _recipient, uint256 _amount, uint256 _dayPasses, uint256 _pet) public onlyOwner {
        for (uint256 i = 0; i < _amount; i++) {
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            
            unit[tokenId] = Egg({ dayPasses: _dayPasses, pet: _pet });
            
            _safeMint(_recipient, tokenId);
            
            emit Mint(_recipient, tokenId);
        }
    }
    
    function claimCryptogotchi(uint256 tokenId) public {
        require(hatchingEnabled, "hatching not enabled yet");
        require(_isApprovedOrOwner(msg.sender, tokenId), "not the owner of this NFT");
        
        Egg memory egg = unit[tokenId];
        
        _burn(tokenId);
        
        TokenInterface(cryptogotchiContract).claim(msg.sender, tokenId, egg.dayPasses, 0, egg.pet);
        
        emit Claim(msg.sender, tokenId, egg.dayPasses, 0, egg.pet);
    }
    
     function getOwnersTokenIds(address account) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(account);
        uint256[] memory tokenIds = new uint256[](balance);
        
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(account, i);
        }
        
        return tokenIds;
    }
}