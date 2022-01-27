// SPDX-License-Identifier: MIT
// Author : Exotic Yohan
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721.sol";
import "./ownable.sol";
import "./ERC721enumerable.sol";


contract Exotic is Ownable, ERC721, ERC721Enumerable {
    
    string public PROVENANCE;
    bool public saleIsActive = false; // false
    bool checkWhitelist = true;
    uint16 public  MAX_EX;
    uint16 public  MAX_PRESALE;

    uint16 public MAX_PUBLIC_MINT;

    uint256 constant public exPresalePrice = 0.005 ether;
    uint256 constant public exPrice = 0.007 ether;


    uint256 public startingIndexBlock = 0;

    uint256 public startingIndex = 0;
    uint256 public SALE_START = 0;

   
    mapping(address => bool) public whitelist;
    mapping(address => bool) public senders;


    string private _baseURIextended;


    constructor(uint16 _maxEx, uint16 _maxPresale, uint16 _maxMint  ) ERC721("Exotic", "EX") {

        /* set total MAX EX
                max single amount to mint
                max presale amount
                
        */

        require(_maxEx > 0,"max EX cannot be 0");
        require(_maxMint > 0, "max mint cannot be 0");
        require(_maxPresale <= _maxEx, "max preSale cannot exceed maxEx");
        MAX_EX = _maxEx;
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
        //require(SALE_START == 0, "SaleStart already set!");
        require(_startTime > 0, "cannot set to 0!");
        SALE_START = _startTime;
    }

    // set ipfs data to token id sequence by acquiring block number once, and use with MOD MAX_EX to set initial index 

    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }

      function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_EX;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number - startingIndexBlock > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_EX;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex++;
        }
    }

        // @dev launch presale

      function launchPresale(uint16 daysLaunch ) public onlyOwner returns (bool) {
        require(SALE_START == 0, "sale start already set!" );
        require(daysLaunch > 0, "days launch must be positive");
        require(startingIndex != 0, "index must be set to launch presale!");

        SALE_START = getNow() + (daysLaunch * 86400);
        saleIsActive = true;
        return true;
    }



    function startSaleSequence(uint16 _days) public onlyOwner {

        require(saleIsActive == false, "Sale already Active!");

       
       
        setStartingIndex(); // set starting index
       
        launchPresale(_days); // launch presale
        
    }


    // Whitelist 
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);


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

    // checkWhitelist
    function flipCheckWhitelist() public onlyOwner {
        checkWhitelist = !checkWhitelist;
    }

    // Sender 
    event AddedToSenders(address indexed account);
    event RemovedFromSenders(address indexed account);

     function addSender(address _address) public onlyOwner  {
        
        require(_address != address(0));
        senders[_address] = true;
        emit AddedToSenders(_address);
    }

    function removeSender(address _address) public onlyOwner {
        require(_address != address(0));
        senders[_address] = false;
        emit RemovedFromSenders(_address);
    }

    function isSender(address _address) public view returns(bool) {
        require(_address != address(0));
        return senders[_address];
    }


    function setMaxMint(uint16 _max) public onlyOwner {
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
      require(supply + n <= MAX_EX, "Purchase would exceed max tokens");
      uint i;
      for (i = 0; i < n; i++) {
          _safeMint(_msgSender(), supply + i);
      }
    }

    
     function mintPresale(uint numberOfTokens) public payable{
        
        if(checkWhitelist == true){
            require(isWhitelisted(_msgSender()) == true);
        }

        uint256 ts = totalSupply();
        require(numberOfTokens > 0 );
        require(exPresalePrice * (numberOfTokens) <= msg.value, "Ether value sent is not correct");
        require(saleIsActive, "Sale must be active to mint tokens");
        require(getNow() < SALE_START, "Sale already started!");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_PRESALE, "Purchase would exceed max presale");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(_msgSender(), ts + i);
        }
    }


    function mintEx(uint numberOfTokens) public payable {
        
        if(checkWhitelist == true){
            require(isWhitelisted(_msgSender()) == true);
        }

        uint256 ts = totalSupply();
        require(numberOfTokens > 0, "number of tokens cannot be 0!" );
        require(exPrice * (numberOfTokens) <= msg.value, "Ether value sent is not correct");
        require(SALE_START != 0 && SALE_START <= getNow(),"EX Sale has not started!" );
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_EX, "Purchase would exceed max tokens");
        

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(_msgSender(), ts + i);
        }
    }

    // senders mint for cc buyers

    function sendCCEx(address  _target, uint numberOfTokens) public {
        
        require(senders[_msgSender()] == true, "not confirmed to send");

        uint256 ts = totalSupply();
        require(numberOfTokens > 0 );
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_EX, "Purchase would exceed max tokens");
        

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(_target, ts + i);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    


}