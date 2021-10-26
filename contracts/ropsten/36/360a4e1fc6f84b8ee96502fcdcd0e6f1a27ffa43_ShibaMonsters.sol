// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract ShibaMonsters is ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    // Mint Information
    uint256 public constant MINT_PRICE = 0.05 ether;
    uint256 public constant TOKEN_AMOUNT = 9999;
    
    bool public paused_mint = true;
    
    // Splitter contract address
    address public splitter;
    
    string private _baseTokenURI = "";
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _splitter
    ) ERC721(_name, _symbol) {
        splitter = _splitter;
    }
    
    event MintPaused();
    event MintUnpaused();
    
    modifier mintIsActive() {
        require(!paused_mint, "ShibaMonsters: mint is paused");
        _;
    }
    
    function pauseMint() public onlyOwner {
        paused_mint = true;
        
        emit MintPaused();
    }

    function unpauseMint() public onlyOwner {
        paused_mint = false;
        
        emit MintUnpaused();
    }
    
    function mint(uint256 amount) public payable mintIsActive {
        uint256 supply = totalSupply();
        
        require( amount <= 10,                                                          "ShibaMonsters: You can mint a maximum of 10 Shibas per TX");
        require( supply + amount <= TOKEN_AMOUNT,                                       "ShibaMonsters: Exceeds maximum ShibaMonsters supply");
        require( msg.value >= MINT_PRICE * amount,                                      "ShibaMonsters: Ether sent is less than MINT_PRICE * amount");
        
        (bool success, ) = splitter.call{value: msg.value}("");
        require(success, "Splitter transfer failed.");
    
        for(uint256 i; i < amount; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ShibaMonsters: URI query for nonexistent token");

        string memory baseURI = getBaseURI();
        string memory json = ".json";
        
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(_baseTokenURI, tokenId.toString(), json))
            : '';
    }
}