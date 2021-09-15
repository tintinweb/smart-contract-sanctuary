// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./import_zap.sol";


 contract mycontract is  ERC721Enumerable,
    NativeMetaTransaction, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;
    string _baseURIextended;
   uint256 saleprice=0.02 ether;
    mapping(address=>uint) balance;
    bool public saleIsActive;
    uint256 total_mintable=4444;
   constructor () ERC721('mytoken','mts') public{
       saleIsActive=false; 
   }

      function pauseSale() public onlyOwner {
        require(saleIsActive == true, "sale is already paused");
        saleIsActive = false;
    }

    function startSale() public onlyOwner {
        require(saleIsActive == false, "sale is already started");
        saleIsActive = true;
    }
     
   function CreateNft( address owner, string memory tokenuri) public payable returns(uint256 rnt){
      require(saleIsActive, "Sale must be active to mint");  
       require(saleprice <= msg.value, "Ether Not Enough");
       require(_tokenIds.current() <= total_mintable, "Ether Not Enough");
       if(msg.value==saleprice){
       _tokenIds.increment();
       uint256 newid=_tokenIds.current();
       _mint(owner, newid);
       tokenURI(newid);
       }
   }
   
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
   
   function setBaseURI(string memory baseURI_) external onlyOwner() {
            _baseURIextended = baseURI_;
            
       
   }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
            require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
                
            }
        
        function _baseURI() internal view virtual override returns (string memory) {
            return _baseURIextended;
        }

}