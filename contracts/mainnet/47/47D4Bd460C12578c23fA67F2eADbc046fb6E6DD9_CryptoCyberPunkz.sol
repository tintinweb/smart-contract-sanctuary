// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import './Ownable.sol';
import "./Strings.sol";
import "./ERC721Enumerable.sol";

contract CryptoCyberPunkz is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public MAX_TOKENS = 11111;
    bool public minting_allowed = false;
    
    mapping(address => uint) public whitelist;
    
    constructor() ERC721 ("CryptoCyberPunkz", "CYBERPUNKZ") {
        whitelist[0x65a7C3Cb6d1C3cEf361063C57936d9d4c9D7bCAB] = 20;
        whitelist[0xB3a00c3CA08A1BD29341519A4f1eaEdBBa82ca39] = 8;
        whitelist[0x3bA005CD1B720fE3Ff421b25d1419b8510dA9221] = 10;
        whitelist[0x4F69d6405Aa065642b42EEa7b2a30a00dc6F2e76] = 46; 
        whitelist[0x975e735f908830D5307D8747cd421A48057DD7aD] = 20;
        whitelist[0xBAa660319b7A0D743310E5F06DC2391E326BE5F4] = 40; 
        whitelist[0x007E363726DFe9491Bb48a2c0b91aa1f1D9B43a9] = 6;
        whitelist[0x8e456Ffe70FAE287DB164b23C0B22900005eEF73] = 2;
        whitelist[0x296866dd32AF3d8c8fC05505673282230Bb81c55] = 2;
        whitelist[0xC6B2a936A6beA35499C446b0dC69db6443f25580] = 2; 
        whitelist[0x50f3F2DEab6e446277e9ab863A763B0C0922E105] = 4;
        whitelist[0x74678c56d7902F7d044F2D24D867c404E5b2e4aB] = 6; 
        whitelist[0x50f3F2DEab6e446277e9ab863A763B0C0922E105] = 4; 
        whitelist[0x1E7e19Ef2035364853D09648B2951bDeDaE9c1b3] = 4;
        whitelist[0x77D74a7611DB43241E25c65888e6a26fa69019a1] = 20; 
        whitelist[0x736011B7d04d8a014EFdAe6a653E3405f3CDC720] = 40;
        whitelist[0x1C53889fea48E2CD289DCE95c9932CE049750C95] = 18;
        whitelist[0x3336eD787919678c3d49124dca8a3F581891C19D] = 8;
        whitelist[0x7DBdD4Df5D41945CF1940bA3cae70F3eD9B7a243] = 20;
        whitelist[0x5663DF5d63cDFC9724E057A29DB8D26777D5fc42] = 1;
        whitelist[0xD3A44893DBb21424CB699081a2727043A95a954D] = 80;
        whitelist[0x2031213cD107911515bBBDD98CE3b5C6dB3e4012] = 20;
        whitelist[0xe52776d36ef023e1f38B22D35Aee64b4FaCfA6ec] = 8;
        whitelist[0xCf02c795751f6D62f187de335d986AAD7Cc26FE5] = 350;
        whitelist[0xC511883A81e2813a4FF09f457F08033b07d226Ff] = 350;
        whitelist[0xa6bf5618D2E860C679E703141dBdFCA12bC7E957] = 350;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("https://cryptocyberpunks.com/metadata/", (tokenId + 1).toString()));
    }
    
    function claimPresale(uint256 _num_to_mint) external {
        require(totalSupply() + _num_to_mint <= MAX_TOKENS, "Not enough tokens left for minting");
        require(whitelist[msg.sender] >= _num_to_mint, "Cannot premint that many tokens");
        
        for (uint256 i = 0; i < _num_to_mint; ++i) {
            _safeMint(msg.sender, totalSupply());
            --whitelist[msg.sender];
        }
    }
    
    function mintToken(uint256 _num_to_mint) external payable {
        require(minting_allowed, "Minting has not begun yet");
        require(msg.value == _num_to_mint * 0.05 ether, "Invalid query for minting amount or incorrect amount of ETH sent");
        require(_num_to_mint <= 20, "Too many tokens queried for minting");
        require(totalSupply() + _num_to_mint <= MAX_TOKENS, "Not enough NFTs left to mint");
        
        for (uint8 quantity = 0; quantity < _num_to_mint; ++quantity) {
            _safeMint(msg.sender, totalSupply());
        } 
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function toggleMinting() external onlyOwner {
        minting_allowed = !minting_allowed;
    }
}