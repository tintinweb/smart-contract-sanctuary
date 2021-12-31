// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./Phake.sol";

contract PhudgyPenguins is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;
    
    bool public public_sale_running = false;

    // mainnet
    Phake private immutable Phunks = Phake(0xf07468eAd8cf26c752C676E43C814FEe9c8CF402);
    Phake private immutable PudgyPenguins = Phake(0xBd3531dA5CF5857e7CfAA92426877b022e612cf8);
    Phake private immutable PHAYC = Phake(0xcb88735A1eAe17fF2A2aBAEC1ba03d877F4Bc055);

    string private base_uri = "https://ipfs.io/ipfs/QmTgCQtL9Eec4uwu3tJajWSmEJjC5AKv1QCkFr33iKm2c3/";
    
    constructor () ERC721("Phudgy Penguins", "PHUDGIES") {
        _safeMint(0xcf541b1323c83D671009535815b9e92CaA70e017, _tokenSupply.current());
        _tokenSupply.increment();
    }

    function setBaseURI(string memory new_uri) external onlyOwner {
        base_uri = new_uri;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(base_uri, tokenId.toString(), ".json"));
    }   

    function publicMint(uint _quantity) external payable {
        require(public_sale_running, "Public sale is not running");
        require(_quantity <= 20, "Invalid number of tokens queries for minting");
        require(_tokenSupply.current() + _quantity <= 8888, "Not enough tokens left to mint");

        if (Phunks.balanceOf(msg.sender) + PudgyPenguins.balanceOf(msg.sender) + PHAYC.balanceOf(msg.sender) > 0) {
            if (_tokenSupply.current() >= 2222) {
                require(msg.value == 0.02 ether * _quantity, "Incorrect ETH sent to mint");
            } else {
                require(msg.value == 0, "Bro it's free...");
            }
        } else {
            if (_tokenSupply.current() >= 6666) {
                require(msg.value == 0.04 ether * _quantity, "Incorrect ETH sent to mint");
            } else if (_tokenSupply.current() >= 4444) {
                require(msg.value == 0.03 ether * _quantity, "Incorrect ETH sent to mint");
            } else if (_tokenSupply.current() >= 2222) {
                require(msg.value == 0.02 ether * _quantity, "Incorrect ETH sent to mint");
            } else {
                require(msg.value == 0.01 ether * _quantity, "Incorrect ETH sent to mint");
            }
        }  
            
        for (uint i = 0; i < _quantity; ++i) {
            _safeMint(msg.sender, _tokenSupply.current());
            _tokenSupply.increment();
        }
    }

    function togglePublicSale() external onlyOwner {
        public_sale_running = !public_sale_running;
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}