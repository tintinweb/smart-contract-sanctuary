// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./Strings.sol";


interface IYolk {
    function burn (address from, uint256 amount) external;
    function updateReward (address from, address to) external;
}


contract TannerTest is ERC721, ERC721Enumerable, Ownable {
   
   //notes

   //look at $RWASTE and kaiju kings
   IYolk public Yolk;

   //string[] public currentSnapshot;
   
   //   SET BACK TO FALSE BEFORE
    bool public saleIsActive = true;
    //set this back to blank
    string private _baseURIextended;
    // string private _midURIextended;
    
    //seed for randNumGen
    
   // uint256 private seed = 0;
   //should think of a way to be able to properly update all metadata if full image refresh needed, while holding full token -> hatchling mapping
    
    using Strings for uint256;

    bool public isAllowListActive = false;
    uint256 public constant MAX_SUPPLY = 12;
    uint256 public constant MAX_PUBLIC_MINT = 13;
    uint256 public constant PRICE_PER_TOKEN = 0.0 ether;

    mapping(address => uint8) private _allowList;
    
    uint256 public constant PAYTOHATCH_PRICE = 40 ether;



modifier HatchlingzOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Cannot interact with a Hatchlingz you do not own");
        _;
    }




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
    
    //  function setHatchlingzMetadata(string[] memory metadata) external onlyOwner {
    //     for (uint256 i = 0; i < metadata.length; i++) {
    //         _hatchlingzMetadata.push(metadata[i]);
    //     }
    // }
   

    function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }
    
  

    function mintAllowList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(numberOfTokens <= _allowList[msg.sender] && numberOfTokens > 0, "Exceeded max available to purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _allowList[msg.sender] -= numberOfTokens;
         Yolk.updateReward(msg.sender, address(0));
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
  
    
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    
    function setYolk(address yolkAddress) external onlyOwner {
        Yolk = IYolk(yolkAddress);
    }

  
    function reserveEggs(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      for (i = 1; i <= n; i++) {
          uint256 currentToken = supply+i;
          _tokenMetadata[currentToken] = "egg";
          _safeMint(msg.sender, supply + i);
          
          // add code here to safe mint reserve eggs or phoenixes/dragons/chickens
         
      }
    }
    
    function reserveHatched(uint256 n, uint256 hatchlingType) public onlyOwner {
      uint supply = totalSupply();
      uint i;
      //hatchlingType Enter 0 for chicken, 1 for dargon, 2 for phoenix
      if (hatchlingType == 2){
           for (i = 1; i <= n; i++) {
          uint256 currentToken = supply+i;
          _tokenMetadata[currentToken] = _phoenixMetadata[_phoenixMetadata.length - 1];
          _phoenixMetadata.pop();
          _walletBalanceOfPhoenix[msg.sender] ++;
          _safeMint(msg.sender, currentToken);
          phoenixTokens.push(currentToken);
          
          // add code here to safe mint reserve eggs or phoenixes/dragons/chickens
         
            }
      }
     else if (hatchlingType == 1){
           for (i = 1; i <= n; i++) {
          uint256 currentToken = supply+i;
          _tokenMetadata[currentToken] = _dragonMetadata[_dragonMetadata.length - 1];
          _dragonMetadata.pop();
           _walletBalanceOfDragon[msg.sender] ++;
          _safeMint(msg.sender, currentToken);
          dragonTokens.push(currentToken);
          // add code here to safe mint reserve eggs or phoenixes/dragons/chickens
         
              }
          
      }
      
      if (hatchlingType == 0){
           for (i = 1; i <= n; i++) {
          uint256 currentToken = supply+i;
          _tokenMetadata[currentToken] = _chickenMetadata[_chickenMetadata.length - 1];
          _chickenMetadata.pop();
           _walletBalanceOfChicken[msg.sender] ++;
          _safeMint(msg.sender, currentToken);
          chickenTokens.push(currentToken); 
          
          // add code here to safe mint reserve eggs or phoenixes/dragons/chickens
         
             }
      
  
      }
      Yolk.updateReward(msg.sender, address(0));
    }
    
    
    
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }
    
    
    
   
  


    function mint(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens > 0 && numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");
//changed i to 1 instead of 0, so that it goes 1 beyond the total supply which would be next token ID.
// set less than or equal
        Yolk.updateReward(msg.sender, address(0));
       // setMidURI("jsonmetadata/");
       
        for (uint256 i = 1; i <= numberOfTokens; i++) {
            uint256 currentToken = ts+i;
            _tokenMetadata[currentToken] = "egg";
            _safeMint(msg.sender, currentToken);
           
        }
    }

        
  function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override (ERC721) {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        // //_previousOwner[tokenId] = from;
        Yolk.updateReward(from, to);
        
          //WHY ISN'T THIS WORKING??
         if (!(keccak256(abi.encodePacked(_tokenMetadata[tokenId])) == keccak256(abi.encodePacked("egg")))){
            logTypeUpdates(tokenId, from, to);
        }
        
        
         if (keccak256(abi.encodePacked(_tokenMetadata[tokenId])) == keccak256(abi.encodePacked("egg"))){
        rollForHatch(tokenId, from, to);
        }
        
        
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        
        
      
        
        
         
        emit Transfer(from, to, tokenId);
    }
   
        
        
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    function payYolkRollToHatch (uint256 tokenId) external HatchlingzOwner(tokenId) {
        require(keccak256(abi.encodePacked(_tokenMetadata[tokenId])) == keccak256(abi.encodePacked("egg")), "Your egg has already hatched!");
        
        Yolk.burn(msg.sender, PAYTOHATCH_PRICE);
        
        rollForHatch(tokenId, msg.sender, msg.sender);
        
    }
    



}