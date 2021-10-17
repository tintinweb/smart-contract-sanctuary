// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Nekoverse is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;
    uint256 private maxMint = 20;
    
    uint256 public constant COST_ONE = 0.03 ether;
    uint256 public constant DISCOUNT1 = 0.02 ether;
    
    bool public active = false;
    uint public constant MAX_ENTRIES = 9999;
    uint public reserve = 30;

    constructor(string memory baseURI) ERC721("Nekoverse", "NEKO")  {
        setBaseURI(baseURI);
    }
    
    function getCost(uint256 num) public pure returns (uint256) {
        if (num < 10) {
            return COST_ONE * num;
        } else {
            return DISCOUNT1 * num;
        }
    }

    function mint(uint256 qty) public payable {
        uint256 mintIndex = totalSupply();

        if(msg.sender != owner()) {
          require(active, "Sale is not active");
          require( qty < (maxMint+1),"You can mint a maximum of maxMint Nekos" );
          require(msg.value >= getCost(qty), "ETH sent is not correct");
        }
        
        require( mintIndex + qty < MAX_ENTRIES, "Exceeds maximum supply" );

        for(uint256 i; i < qty; i++){
          _safeMint(msg.sender, mintIndex + i );
        }
    }
    
    function reserveMint(uint256 reserveQty) public onlyOwner {        
        uint mintIndex = totalSupply();
        require(reserveQty > 0 && reserveQty <= reserve, "Not enough reserve left for team");
        for (uint i = 0; i < reserveQty; i++) {
            _safeMint(msg.sender, mintIndex + i);
        }
        reserve = reserve - reserveQty;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function isActive() public view returns(bool) {
        return active;
    }

    function saleActive(bool val) public onlyOwner {
        active = val;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}