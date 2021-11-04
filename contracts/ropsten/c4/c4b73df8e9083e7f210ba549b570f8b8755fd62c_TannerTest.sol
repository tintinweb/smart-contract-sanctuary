// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";


contract TannerTest is ERC721, ERC721Enumerable, Ownable {
   
   //notes

   //look at $RWASTE and kaiju kings
   

   
   
   //   SET BACK TO FALSE BEFORE
    bool public saleIsActive = true;
    //set this back to blank
    string private _baseURIextended;
    // string private _midURIextended;
    
    //seed for randNumGen
    
    uint256 private seed = 0;
   //should think of a way to be able to properly update all metadata if full image refresh needed, while holding full token -> hatchling mapping
    
    using Strings for uint256;

    bool public isAllowListActive = false;
    uint256 public constant MAX_SUPPLY = 12;
    uint256 public constant MAX_PUBLIC_MINT = 13;
    uint256 public constant PRICE_PER_TOKEN = 0.0 ether;

    mapping(address => uint8) private _allowList;
    //mapping(uint256 => address) public _previousOwner;
    
    //these will all likely be private
    mapping(uint256 => string) public _tokenMetadata;
    string[] public currentSnapshot;
    
    //test variables
    
 
    
    
   //test vars end
   
    
    // mapping(uint256 => string) public _phoenixMetadata;
    // mapping(uint256 => string) public _dragonMetadata;
    // mapping(uint256 => string) public _chickenMetadata;
    //use array instead?
    string[] public _hatchlingzMetadata = ["chicken1","chicken2","chicken3","chicken4","chicken5","dragon1","dragon2","dragon3","dragon4","phoenix1","phoenix2","phoenix3"];
  
    
   // uint256 public phoenixlength = _phoenixMetadata.length;

    constructor() ERC721 ("TannerTest", "TT") {
      
    }



//Testing functions
    
   


//test functions end

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }
    
     function setHatchlingzMetadata(string[] memory metadata) external onlyOwner {
        for (uint256 i = 0; i < metadata.length; i++) {
            _hatchlingzMetadata.push(metadata[i]);
        }
    }
   

    function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }
    
    function createCurrentSnapshot() external onlyOwner   {
        delete currentSnapshot;
       
        for(uint256 i = 1; i<= totalSupply(); i++){
            currentSnapshot.push(_tokenMetadata[i]);
        }
        
    }
    
    function pullCurrentSnapshot() external view onlyOwner returns (string[] memory)  {
        return currentSnapshot;
    }

    function mintAllowList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _allowList[msg.sender] -= numberOfTokens;

        //does i need to be 1?
        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) virtual external onlyOwner() {
        _baseURIextended = baseURI_;
    }
    //   function setMidURI(string memory midURI_) internal  {
    //     _midURIextended = midURI_;
    // }

    
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    
    // function _midURI() internal view virtual override returns (string memory) {
    //     return _midURIextended;
    // }

  
    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      for (i = 1; i <= n; i++) {
          uint256 currentToken = supply+i;
          _tokenMetadata[currentToken] = "egg";
          _safeMint(msg.sender, supply + i);
          
          // add code here to safe mint reserve eggs or phoenixes/dragons/chickens
         
      }
    }
    
    
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }
    
    
    
    
    //set up done


     function tokenURI(uint256 tokenId) public view virtual override (ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        // string memory midURI = _midURI();
        string memory URIString = _tokenMetadata[tokenId];
      
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, URIString,".json")) : "";
    }
    
  


    function mint(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");
//changed i to 1 instead of 0, so that it goes 1 beyond the total supply which would be next token ID.
// set less than or equal

       // setMidURI("jsonmetadata/");
       
        for (uint256 i = 1; i <= numberOfTokens; i++) {
            uint256 currentToken = ts+i;
            _tokenMetadata[currentToken] = "egg";
            _safeMint(msg.sender, currentToken);
           
        }
    }

        
        
   
        
        
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

//change to internal after testing
    function randNumGen (uint256 tokenId) public view returns (uint256){
        
       //probably need to use more official rand num gen.
     
        uint256 randNumLong = uint(keccak256(abi.encodePacked(tokenId.toString(),msg.sender,block.timestamp,block.difficulty,seed.toString())));
       
        uint256 randNum = randNumLong % 10;
        return randNum;
    }



    function rollForHatch (uint256 tokenId) external returns ( string memory){
        string memory currentMetadata = _tokenMetadata[tokenId];
        string memory egg = "egg";
        
        require(msg.sender == ownerOf(tokenId), "You aren't the owner of this egg.");
        require(!(msg.sender == _previousOwner[tokenId]), "You have already tried to hatch this egg during this ownership term. Please obtain new egg to try to hatch again");
        require(keccak256(abi.encodePacked(currentMetadata)) == keccak256(abi.encodePacked(egg)), "Your egg has already hatched!");
        // code to select random number 
        uint256 hatchNum = 0;
        uint256 randNumGenerated = randNumGen(tokenId);
        string memory result;
        seed++;
        //for testing
        //bool test = true;
        
        
        if (hatchNum == randNumGenerated){
            result = "Your egg hatched! Refresh your metadata :)";
          // setMidURI("hatchmetadata/");
           _tokenMetadata[tokenId] = _hatchlingzMetadata[_hatchlingzMetadata.length - 1];
           _hatchlingzMetadata.pop();
           tokenURI(tokenId);
        } 
      
        
        else{
            result = "Your egg didn't hatch this time, good luck next time!";
        }
        
        _previousOwner[tokenId] = msg.sender;
        return  result;
        //return strings based on conditions of hatch

    }


}