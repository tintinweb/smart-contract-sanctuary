// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./ERC721URIStorage.sol";

/*
                 _...Q._
               .'       '.
              /           \
             ;.-""""--.._ |
            /'-._____..-'\|
          .' ;  o   o    |`;
         /  /|   ()      ;  \
    _.-, '-' ; '.__.-'    \  \
.-"`,  |      \_         / `'`
 '._`.; ._    / `'--.,_=-;_
    \ \|  `\ .\_     /`  \ `._
     \ \    `/  ``---|    \   (~
      \ \.  | o   ,   \    (~ (~  ______________
       \ \`_\ _..-'    \  (\(~   |.------------.|
        \/  ``        / \(~/     ||            ||
         \__    __..-' -   '.    ||            ||
          \ \```             \   || WinterDoods||
          ;\ \o               ;  ||            ||
          | \ \               |  ||____________||
          ;  \ \              ;  '------..------'
           \  \ \ _.-'\      /          ||
            '. \-'     \   .'           ||
           _.-"  '      \-'           .-||-.
           \ '  ' '      \           '..---.- '
            \  ' '      _.'
             \' '   _.-'
              \ _.-'
*/

contract WinterDoods is ERC721URIStorage, Ownable {
    string public baseURI;
    bool private saleStarted;

    uint256 public totalWinterDoods;
    uint256 public price = 20000000000000000;

    uint256 public maxDoods = 3333;
    uint256 public maxFreeDoods = 333;
    uint256 public maxPerTX = 10;
    uint256 public maxPerTXFree = 3;

    constructor(string memory startURI) ERC721("WinterDoods", "WinterDoods") {
        baseURI = startURI;
    }

    // Read
    function totalSupply() public view virtual returns (uint256) {
        return totalWinterDoods;
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    // Write
    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function flipSaleState() public onlyOwner {
        saleStarted = !saleStarted;
    }

    function mint(uint256 amount) payable public {
        require(saleStarted, "Sale has not started!");
        require(amount > 0 && amount <= maxPerTX, "Max 10 Doods Per Transaction!");
        require(maxDoods < amount + totalWinterDoods, "Sold Out");
        require(msg.value >= amount * price, "Incorrect Price");

        payable(owner()).transfer(msg.value);

        for(uint256 i=0; i< amount; i++){
            _mint(_msgSender(), 1 + totalWinterDoods++);
        }
    }  

    function mintFree(uint256 amount) payable public {
        require(saleStarted, "Sale has not started!");
        require(amount > 0 && amount <= maxPerTXFree, "Max 3 Doods Per Transaction!");
        require(maxFreeDoods > amount + totalWinterDoods, "Out of Free Doods");

        for(uint256 i=0; i< amount; i++){
            _mint(_msgSender(), 1 + totalWinterDoods++);
        }
    }
}