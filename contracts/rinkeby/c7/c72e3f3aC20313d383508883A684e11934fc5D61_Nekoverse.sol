// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Nekoverse is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private maxMint = 20;
    uint256 private price = 30000000000000000; //0.03 ETH;
    bool public active = false;
    uint public constant MAX_ENTRIES = 10000;
    uint public reserve = 20;

    constructor(string memory baseURI) ERC721("Nekoverse", "NEKO")  {
        setBaseURI(baseURI);
    }

    function mint(address _to, uint256 qty) public payable {
        uint256 supply = totalSupply();

        if(msg.sender != owner()) {
          require(active, "Sale is not active");
          require( qty < (maxMint+1),"You can adopt a maximum of maxMint Frogs" );
          require( msg.value >= price * qty,"Ether sent is not correct" );
        }
        
        require( supply + qty < MAX_ENTRIES, "Exceeds maximum supply" );

        for(uint256 i; i < qty; i++){
          _safeMint( _to, supply + i );
        }
    }
    
    function reserveMint(address _to, uint256 reserveQty) public onlyOwner {        
        uint supply = totalSupply();
        require(reserveQty > 0 && reserveQty <= reserve, "Not enough reserve left for team");
        for (uint i = 0; i < reserveQty; i++) {
            _safeMint(_to, supply + i);
        }
        reserve = reserve - reserveQty;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function isPaused() public view returns(bool) {
        return active;
    }

    function pause(bool val) public onlyOwner {
        active = val;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}