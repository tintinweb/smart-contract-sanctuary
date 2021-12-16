// SPDX-License-Identifier: MIT

/*
   _____             _             __          __        _        _                 
  / ____|           | |            \ \        / /       | |      | |                
 | (___   __ _ _ __ | |_ __ _ ___   \ \  /\  / /__  _ __| | _____| |__   ___  _ __  
  \___ \ / _` | '_ \| __/ _` / __|   \ \/  \/ / _ \| '__| |/ / __| '_ \ / _ \| '_ \ 
  ____) | (_| | | | | || (_| \__ \    \  /\  / (_) | |  |   <\__ \ | | | (_) | |_) |
 |_____/ \__,_|_| |_|\__\__,_|___/     \/  \/ \___/|_|  |_|\_\___/_| |_|\___/| .__/ 
                                                                             | |    
                                                                             |_|    
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721URIStorage.sol";

contract SantasWorkshop is ERC721URIStorage, Ownable {
    string public baseURI;
    bool private saleStarted;

    uint256 public totalHats;
    uint256 public price = 25000000000000000;

    uint256 public maxHats = 12025;
    uint256 public maxPerTX = 12;

    address private constant santa = 0x513d334F1530cFc5bdCc3a589a952EaA0dA34547;

    constructor(string memory startURI) ERC721("Santas Workshop", "SNTAWRKSP") {
        baseURI = startURI;
    }

    function totalSupply() public view virtual returns (uint256) {
        return totalHats;
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    function flipSaleState() public onlyOwner {
        saleStarted = !saleStarted;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function mint(uint256 amount) payable public {
        require(saleStarted, "Sale not live");
        require(amount > 0 && amount <= maxPerTX, "12 Max Hats Per Transaction");
        require(maxHats > amount + totalHats, "Sold Out");
        require(msg.value >= amount * price, "Send .025 per Hat");

        payable(santa).transfer(msg.value);

        for(uint256 i=0; i< amount; i++){
            _mint(_msgSender(), 1 + totalHats++);
        }
    }  
}