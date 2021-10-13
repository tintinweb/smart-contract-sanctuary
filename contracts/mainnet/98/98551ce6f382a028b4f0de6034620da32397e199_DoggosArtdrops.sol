// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Strings.sol";
import "./ERC1155.sol";
import "./Ownable.sol";

abstract contract Doggos {
  function tokenOfOwnerByIndex(address owner, uint256 index) external virtual view returns (uint256);
  function balanceOf(address owner) external virtual view returns (uint256);
}

contract DoggosArtdrops is Ownable, ERC1155 {
    
    Doggos private doggo;
    using Strings for uint256;
    
    bool public hasClaimStarted = false;
    bool public hasSaleStarted = false;
    bool[100][5556]private doggoTokenCheck;
    
    uint256[100] public seriesSupply;
    uint256 private totalTokenSupply = 0;
    uint256 public dropSeries = 1;
    uint256 public MINT_PRICE = 0.7 ether;
    uint256 private constant MAX_DROP = 777;
    
    string public name = "The Doggos Artdrops";
    string public symbol = "TDA";
    address doggosAddress = 0x88ED28549Eb66cB5a4580fb3C54148Ce2d5c7F0f;

    constructor() ERC1155("") {
        doggo = Doggos(doggosAddress);
    }
    
    function doggoTokenStatus(uint256 tokenId) public view returns (bool) { 
        return doggoTokenCheck[tokenId][dropSeries];
    }
    
    function mintDrops(uint256 numofDoggos) public payable { 
        require(seriesSupply[dropSeries] + numofDoggos <= MAX_DROP, "Exceeds max Drop mintable");
        require(hasSaleStarted == true, "Sales have not start");
        require(numofDoggos <= 20, "Max mint of 20 Drop");
        require(msg.value >= MINT_PRICE * numofDoggos, "Value sent insufficient");
        
        _mint(msg.sender, dropSeries, numofDoggos, "");
        seriesSupply[dropSeries] += numofDoggos;
        totalTokenSupply += numofDoggos;
    } 
    
    function claimDrop(uint256 numofDoggos) public {  
        require(hasClaimStarted == true, "Claiming has not start");
        require(seriesSupply[dropSeries] + numofDoggos <= MAX_DROP, "Exceeds max Drop mintable"); 
        require(numofDoggos <= 20, "Exceeds max Drop claimable");
        
        uint256 balance = doggo.balanceOf(msg.sender);
        uint256 index = 0;
        
        for (uint256 i = 0; i < numofDoggos; i++) {
            for (uint256 j = index; j < balance; j++){  
                if (doggoTokenCheck[doggo.tokenOfOwnerByIndex(msg.sender, j)][dropSeries] == false) {
                    doggoTokenCheck[doggo.tokenOfOwnerByIndex(msg.sender, j)][dropSeries] = true;
                     _mint(msg.sender, dropSeries, 1, ""); 
                     seriesSupply[dropSeries] += 1;
                     totalTokenSupply += 1;
                     index = j + 1;
                     j = balance;
                }
            }
        }
    }
    
    function checkClaimableQty() public view returns (uint256){  
        uint256 balance = doggo.balanceOf(msg.sender);
        uint256 mintcount = 0;
        
        for (uint256 i = 0; i < balance; i++){
            if (doggoTokenCheck[doggo.tokenOfOwnerByIndex(msg.sender, i)][dropSeries] ==  false) {
                mintcount = mintcount + 1;
            }
        }
        return mintcount;
    }
    
    function giveaways(address to, uint256 numofDoggos) public onlyOwner {
        require(seriesSupply[dropSeries] + numofDoggos <= MAX_DROP, "Exceeds max drop mintable");
        
        _mint(to, dropSeries, numofDoggos, "");
        seriesSupply[dropSeries] += numofDoggos;
        totalTokenSupply += numofDoggos;
    }
    
    function giveawaysToMany(address[] memory recipients) external onlyOwner {
        require(seriesSupply[dropSeries] + recipients.length <= MAX_DROP, 'Exceeds max drop mintable');
        
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], dropSeries, 1, ""); 
            seriesSupply[dropSeries] += 1;
            totalTokenSupply += 1;
        }
    }
    
    function uri(uint256 tokenId) public view override returns (string memory) {
      string memory baseURI = ERC1155.uri(tokenId);
      return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function setURI(string memory newURI) public onlyOwner {
      _setURI(newURI);
    }
    
    function setDropSeries (uint256 id) public onlyOwner {
        require(id < 100, "Exceeds DropSeries ID");
        dropSeries = id;
    }
    
    function totalSupply() public view returns (uint256) {
        return totalTokenSupply; 
    }
    
    function getPrice() public view returns (uint256){
        return MINT_PRICE;
    }
    
    function setPrice(uint256 newPrice) public onlyOwner() {  
        MINT_PRICE = newPrice;
    }
    
    function flipSale() public onlyOwner {
        hasSaleStarted = !hasSaleStarted;
    }
    
    function flipClaim() public onlyOwner {
        hasClaimStarted = !hasClaimStarted;
    }
    
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
   
}