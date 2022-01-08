// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol";

contract LilBrains is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;
    
    bool public public_sale_running = false;
    bool public private_sale_running = false;

    string private base_uri = "https://lilbrains.com/metadata/";

    mapping (address => uint) public presale_allocation;
    
    constructor () ERC721("Lil Brains", "BRAINZ") {
        _safeMint(0x369434192aE1D4c7B7D33A331eC092d4832763F9, 0);
        _tokenSupply.increment();
    }

    function setBaseURI(string memory new_uri) external onlyOwner {
        base_uri = new_uri;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(base_uri, (tokenId + 1).toString()));
    }   
    
    function privateMint(uint _quantity) external payable {
        require(presale_allocation[msg.sender] >= _quantity, "Not enough presale allocation");
        require(private_sale_running, "Private sale is not running");
        require(_quantity <= 14, "Invalid number of tokens queries for minting");
        require(msg.value == 0.045 ether * _quantity, "Incorrect ETH sent to mint");
        require(_tokenSupply.current() + _quantity <= 7777, "Not enough tokens left to mint");

        for (uint i = 0; i < _quantity; ++i) {
            --presale_allocation[msg.sender];
            _safeMint(msg.sender, _tokenSupply.current());
            _tokenSupply.increment();
        }
    }

    function publicMint(uint _quantity) external payable {
        require(public_sale_running, "Public sale is not running");
        require(_quantity <= 14, "Invalid number of tokens queries for minting");
        require(msg.value == 0.045 ether * _quantity, "Incorrect ETH sent to mint");
        require(_tokenSupply.current() + _quantity <= 7777, "Not enough tokens left to mint");
        
        for (uint i = 0; i < _quantity; ++i) {
            _safeMint(msg.sender, _tokenSupply.current());
            _tokenSupply.increment();
        }
    }

    function whitelist(address [] memory addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; ++i) {
            presale_allocation[addresses[i]] += 7;
        }
    }
    
    function togglePublicSale() external onlyOwner {
        public_sale_running = !public_sale_running;
    }

    function togglePrivateSale() external onlyOwner {
        private_sale_running = !private_sale_running;
    }
    
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;

        payable(0x67E0D5a40BF8db099980F159955C6fAA2164ff84).transfer(18 * balance / 100); // donations
        payable(0x5862aD03648aa877E37c9Aa1cD6A67324797fEb5).transfer(40 * balance / 100); // team 
        payable(0x49fEc51444243bAd5c8f9c88E055FDF7cCBC9999).transfer(17 * balance / 100); // treasury

        payable(0x9408c666a65F2867A3ef3060766077462f84C717).transfer(125 * balance / 1000);
        payable(0x6B003507d437caF2bF3E1C79e536136513153cD8).transfer(address(this).balance);
    }
}