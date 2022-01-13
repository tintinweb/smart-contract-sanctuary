// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721.sol";
import "./ownable.sol";
import "./ERC721enumerable.sol";



contract Yohan is Ownable, ERC721, ERC721Enumerable {
    
    string public PROVENANCE;
    bool public saleIsActive = false; // false
   
    uint256 public  MAX_BABIES;
    uint256 public  MAX_PRESALE;

    uint256 public MAX_PUBLIC_MINT;

    mapping(address => bool) public whitelist;

    uint256 public startingIndexBlock = 0;

    uint256 public startingIndex = 0;
    uint256 public SALE_START = 0;


    string private _baseURIextended;


    constructor(uint256 _maxBabies, uint256 _maxPresale, uint256 _maxMint  ) ERC721("Demo", "DIM") {

        /* @dev set total MAX babies
                max single amount to mint
                max presale amount
                
        */

        require(_maxBabies > 0,"max babies cannot be 0");
        require(_maxMint > 0, "max mint cannot be 0");
        require(_maxPresale <= _maxBabies, "max preSale cannot exceed maxBabies");
        MAX_BABIES = _maxBabies;
        MAX_PRESALE = _maxPresale;
        MAX_PUBLIC_MINT = _maxMint;
        
    }



     function getNow() private view returns (uint256) {
        uint256 timeNow = block.timestamp;
        return timeNow;
    }


    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

      function emergencySetSaleStart(uint256 _startTime) public onlyOwner {
       // require(SALE_START == 0, "SaleStart already set!");
        require(_startTime > 0, "cannot set to 0!");
        SALE_START = _startTime;
    }

    // set ipfs data to token id sequence by acquiring block number once, and use with MOD MAX_BABIES to set initial index 

    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }

      function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_BABIES;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_BABIES;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex++;
        }
    }

        // @dev launch presale

      function launchPresale(uint256 daysLaunch ) public onlyOwner returns (bool) {
        require(SALE_START == 0, "sale start already set!" );
        require(daysLaunch > 0, "days launch must be positive");
        require(startingIndex != 0, "index must be set to launch presale!");

        SALE_START = getNow() + (daysLaunch * 86400);
        saleIsActive = true;
        return true;
    }



    function startSaleSequence(uint256 _days) public onlyOwner {

        require(saleIsActive == false, "Sale already Active!");
        
       
       
        setStartingIndex(); // set starting index
       
        launchPresale(_days); // launch presale
        
    }


    // Whitelist modifier
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "Not Whitelisted!");
        _;
    }

    function addWhitelist(address _address) public onlyOwner  {
        
        require(_address != address(0));
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function removeWhitelist(address _address) public onlyOwner {
        require(_address != address(0));
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns(bool) {
        require(_address != address(0));
        return whitelist[_address];
    }




    function setMaxMint(uint256 _max) public onlyOwner {
        MAX_PUBLIC_MINT = _max;
    }



    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function getSaleState() public view returns (bool) {
        return saleIsActive;
    }




    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      require(supply + n <= MAX_BABIES, "Purchase would exceed max tokens");
      uint i;
      for (i = 0; i < n; i++) {
          _safeMint(_msgSender(), supply + i);
      }
    }

 
    
     function mintPresale(uint numberOfTokens) public payable onlyWhitelisted {
        
        uint256 ts = totalSupply();
        require(numberOfTokens > 0 );
        require(saleIsActive, "Sale must be active to mint tokens");
        require(getNow() < SALE_START, "Sale already started!");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_PRESALE, "Purchase would exceed max presale");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(_msgSender(), ts + i);
        }
    }


 
    


    function mintBaby(uint numberOfTokens) public payable onlyWhitelisted {
        uint256 ts = totalSupply();
        require(numberOfTokens > 0 );
        require(SALE_START != 0 && SALE_START <= getNow() );
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_BABIES, "Purchase would exceed max tokens");
        

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(_msgSender(), ts + i);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
     function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return ERC721.balanceOf(owner);
    }
}