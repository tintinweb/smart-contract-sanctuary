// SPDX-License-Identifier: MIT

/*
                             =====ISLAND PUNKS=====
                                 islandpunks.io
                                                  
             ***          ***       ***   ***       ***         ****            
    ***      ***          ***   *******   ******    ***         ****      ***   
    ***      ***          ***   *******   ******    ***         ****      ***   
    ******   *******   ******   *******   ******    ******   *******   ******   
       ***      ,,,,   ,,,   ,,,,,,,*********(((((((   (((   (((       ***      
****   ,,,,,,   ,,,,,,,,,,   ,,,       ***(((   ((((   (((((((((    ((((((   ***
*******   ,,,,,,,,,,,,,,,,,,,,,,    ,,,,,,(((   (((((((((((((((((((((((   ******
*******   ,,,,,,,,,,,,,,,,,,,,,,    ,,,,,,(((   (((((((((((((((((((((((   ******
    ***,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,   ((((((((((((((((((((((((((((((((***   
       ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,         (((((((((((((((((((((((((((((      
       ,,,,,,,,,,,,,...,,,,,,,,,[email protected]@@   @@@...,,,,,,,,,,...(((((((((((((      
       ,,,,,,,,,,,,,...,,,,,,,,,[email protected]@@   @@@...,,,,,,,,,,...(((((((((((((      
       ,,,,,,,,,,,,,[email protected]@@   @@@................(((((((((((((      
       @@@.............,,,,,,[email protected]@@   @@@...,,,,...,,,..........,,,@@@      
       @@@......///////...,,,///////@@@   @@@///////,,,...//////....,,,@@@      
    @@@@@@[email protected]@@@,,,[email protected]@@,,,,@@@   @@@,,,@@@@......,,,@@@[email protected]@@@@@   
    @@@@@@[email protected]@@@,,,[email protected]@@,,,,@@@   @@@,,,@@@@......,,,@@@[email protected]@@@@@   
    @@@@@@,,,...................,,,,@@@   @@@,,,[email protected]@@@@@   
    ,,,@@@...,,,[email protected]@@......,,,,@@@   @@@,,,[email protected]@@......,,,,[email protected]@@,,,   
       @@@@@@,,,[email protected]@@,,,[email protected]@@   @@@.......,,,@@@......,,,,@@@@@@      
       @@@@@@,,,[email protected]@@,,,[email protected]@@   @@@.......,,,@@@......,,,,@@@@@@      
          @@@[email protected]@@@         @@@................,,,,@@@         
          @@@[email protected]@@@[email protected]@@[email protected]@@@@@@         @@@@@@@[email protected]@@[email protected]@@[email protected]@@         
          @@@.......%%%...%%%[email protected]@@@         @@@....%%%...%%%[email protected]@@         
             @@@..........,,,@@@                @@@@,,,[email protected]@@@            
             @@@..........,,,@@@                @@@@,,,[email protected]@@@            
             @@@[email protected]@@@@@@@@                       @@@@@@@@@[email protected]@@@            
             ,,,,,,,@@@                                   @@@,,,,,,,            
             @@@....,,,                                   ,,,[email protected]@@@            

*/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract IslandPunks is ERC721, Ownable {

    bool public paused = false;
    string private _baseURIextended;
    address payable public immutable ownerAddress;

    uint256 public tokenPrice = 0.005 ether;
	uint public maxPerTx = 10;
	uint public maxSupply = 10000;
	
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    constructor(
        address payable ownerAddress_,
        string memory _initBaseURI
    ) ERC721("COLORS - FINAL", "IPUNKS") {
        require(ownerAddress_ != address(0));
        ownerAddress = ownerAddress_;
        setBaseURI(_initBaseURI);
    }

    function totalSupply() public view returns (uint256 supply) {
        return _tokenSupply.current();
    }

    function setBaseURI(string memory baseURI_) public onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setSaleState(bool mintStatus) public onlyOwner {
        paused = mintStatus;
    }

    function isMintPaused() external view returns (bool) {
        return paused;
    }

    function updateMintPrice(uint256 newPrice) public onlyOwner {
        tokenPrice = newPrice;
    }

    function mint(address _to, uint _mintAmount) external payable {
        require(!paused, "Sale is inactive.");
        require(_mintAmount <= maxPerTx, "You can only mint 10 at a time.");
        require(_tokenSupply.current() + _mintAmount <= maxSupply, "Purchase would exceed max supply of tokens");

        if (msg.sender != ownerAddress) {
            require((tokenPrice * _mintAmount) == msg.value, "Invalid ETH amount sent.");
        }

        for(uint i = 0; i < _mintAmount; i++) {
		    uint256 _tokenId = _tokenSupply.current() + 1;
            _safeMint(_to, _tokenId);
            _tokenSupply.increment();
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(ownerAddress, balance);
    }
}