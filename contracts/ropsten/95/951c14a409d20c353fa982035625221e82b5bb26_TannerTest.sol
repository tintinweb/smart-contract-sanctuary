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
   
  
   IYolk public Yolk;

   //string[] public currentSnapshot;
   
   //   SET BACK TO FALSE BEFORE
    bool public saleIsActive = false;
    bool public isAllowListActive = false;
    bool public isGen2Active = false;
    
    string private _baseURIextended;

    using Strings for uint256;
 
    uint256 public MAX_SUPPLY = 12;
    uint256 public MAX_PUBLIC_MINT = 13;
    uint256 public constant PRICE_PER_TOKEN = 0.0 ether;
    //test if changing cost works with the ether there.
    uint256 public PAYTOHATCH_PRICE = 40 ether;
    uint256 public PAYTOLAY_PRICE = 40 ether;
    
    mapping(address => uint8) private _allowList;
    mapping(uint256 => bool) internal _hasTokenLaidEgg;
    

    modifier HatchlingzOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Cannot interact with a Hatchlingz you do not own");
        _;
    }
    //update to Hatchlingz
    constructor() ERC721 ("TannerTest", "TT") {
      
    }

    
    function setMaxSupply (uint256 newMaxSupply) external onlyOwner {
        MAX_SUPPLY = newMaxSupply;
    }
    
     function setRollToHatchCost (uint256 newRollCost) external onlyOwner {
        PAYTOHATCH_PRICE = newRollCost;
    }

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }
    
    
    
    function setHatchlingzMetadata(string[] memory metadata, uint256 animalType) external onlyOwner {
        require(animalType == 0 || animalType == 1 || animalType ==2, "not a valid animal type");
        
        //0 for commmon/chicken, 1 for rare/dragon, 2 for legendary/phoenix
        
        if(animalType == 0){
            delete _chickenMetadata;
            for (uint256 i = 0; i < metadata.length; i++) {
                _chickenMetadata.push(metadata[i]);
            }
        }
        else if (animalType == 1){
            delete _dragonMetadata;
            for (uint256 i = 0; i < metadata.length; i++) {
                _dragonMetadata.push(metadata[i]);
            }
        }
        else if (animalType == 2){
            delete _phoenixMetadata;
            for (uint256 i = 0; i < metadata.length; i++) {
                _phoenixMetadata.push(metadata[i]);
            }
        }
       
    }
   

    function numAvailableToMint(address addr) external view returns (uint8) {
        return _allowList[addr];
    }
    
  

    function mintAllowList(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(numberOfTokens <= _allowList[msg.sender] && numberOfTokens > 0, "Exceeded max available to purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");
//test this -=
        _allowList[msg.sender] -= numberOfTokens;
        Yolk.updateReward(msg.sender, address(0));
    
        for (uint256 i = 1; i <= numberOfTokens; i++) {
            uint256 currentToken = ts+i;
            _tokenMetadata[currentToken] = "egg";
            _safeMint(msg.sender, currentToken);
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
        require( totalSupply() + n <= MAX_SUPPLY, "reserving too many");
        uint supply = totalSupply();
        uint i;
        Yolk.updateReward(msg.sender, address(0));
        
       
        for (i = 1; i <= n; i++) {
            uint256 currentToken = supply+i;
            _tokenMetadata[currentToken] = "egg";
            _safeMint(msg.sender, currentToken);
        }
       
    
    }
    
    function reserveHatched(uint256 n, uint256 hatchlingType) public onlyOwner {
        require( hatchlingType == 0 || hatchlingType == 1 || hatchlingType == 2, "you aren't hatching a valid type");
        require( totalSupply() + n <= MAX_SUPPLY, "reserving too many");
        uint supply = totalSupply();
        uint i;
        Yolk.updateReward(msg.sender, address(0));
        //hatchlingType Enter 0 for chicken, 1 for dargon, 2 for phoenix
        
        if (hatchlingType == 2){
            for (i = 1; i <= n; i++) {
                uint256 currentToken = supply+i;
                _tokenMetadata[currentToken] = _phoenixMetadata[_phoenixMetadata.length - 1];
                _phoenixMetadata.pop();
                _walletBalanceOfPhoenix[msg.sender] ++;
                _safeMint(msg.sender, currentToken);
                
    
            }
        }
        
        else if (hatchlingType == 1){
            for (i = 1; i <= n; i++) {
                uint256 currentToken = supply+i;
                _tokenMetadata[currentToken] = _dragonMetadata[_dragonMetadata.length - 1];
                _dragonMetadata.pop();
                _walletBalanceOfDragon[msg.sender] ++;
                _safeMint(msg.sender, currentToken);
               
        
            } 
        }
          
        else if (hatchlingType == 0){
            for (i = 1; i <= n; i++) {
                uint256 currentToken = supply+i;
                _tokenMetadata[currentToken] = _chickenMetadata[_chickenMetadata.length - 1];
                _chickenMetadata.pop();
                _walletBalanceOfChicken[msg.sender] ++;
                _safeMint(msg.sender, currentToken);
                
            }
        }  
    }
    
    
    
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }
    
    function setGen2Active(bool newState) public onlyOwner {
        isGen2Active = newState;
    }
    

    function mint(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens > 0 && numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        Yolk.updateReward(msg.sender, address(0));

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            uint256 currentToken = ts+i;
            _tokenMetadata[currentToken] = "egg";
            _safeMint(msg.sender, currentToken);
           
        }
    }

        
    function _transfer(address from, address to, uint256 tokenId) internal virtual override (ERC721) {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
    
        Yolk.updateReward(from, to);
        
     
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
    
    //using HatchlingzOwner Modifier
    function payYolkRollToHatch(uint256 tokenId) external HatchlingzOwner(tokenId) {
        require(keccak256(abi.encodePacked(_tokenMetadata[tokenId])) == keccak256(abi.encodePacked("egg")), "Your egg has already hatched!");
        //require(msg.sender == ownerOf(tokenId), "you must be the owner of this Hatchlingz to use this");
        
        Yolk.burn(msg.sender, PAYTOHATCH_PRICE);
        
        rollForHatch(tokenId, msg.sender, msg.sender);
        
    }
    
    function payToLayEgg (uint256 tokenId) external HatchlingzOwner(tokenId){
        require(!_hasTokenLaidEgg[tokenId], "This Hatchlingz has already laid an egg");
        require(isGen2Active, "Cannot lay eggs at this time");
        require(totalSupply()+1 <= MAX_SUPPLY, "All allowed eggs for Gen 2 have already been laid");
        
        uint256 nextTokenId = totalSupply() + 1;
        
        Yolk.burn(msg.sender, PAYTOLAY_PRICE);
        _tokenMetadata[nextTokenId] = "egg2";
        _safeMint(msg.sender, nextTokenId);
        
    }
    



}