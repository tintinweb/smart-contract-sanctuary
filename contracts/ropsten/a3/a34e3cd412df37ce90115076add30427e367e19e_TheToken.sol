// SPDX-License-Identifier: MIT

// Create an ERC721 Token with the following requirements

// 1. user can only buy tokens when the sale is started
// 2. the sale should be ended within 30 days
// 3. the owner can set base URI
// 4. the owner can set the price of NFT
// 5. NFT minting hard limit is 100

 
    // ************************************************** // 

pragma solidity ^0.8.4;

import "./ERC721.sol";


contract TheToken is ERC721 { 
    
    uint256 public saleStartTime;
    uint256 private salePeriod;
    uint256 private saleEndTime;
    uint256 private NFTPrice;
    uint256 private NFTMaxSupply;
    uint256 internal tokenID;
    uint256 public currentSupply;
    uint256 public fundRaised;
    uint256 public lastTokenID;
    
     // ************************************************** // 
    
    constructor() {
        
        saleStartTime = block.timestamp + 10;
        salePeriod = 30 days;       /*  30 days --- consider 180 second for sake of practice */
        saleEndTime = saleStartTime + salePeriod ;
        NFTMaxSupply = 5;       /*  100 NFT --- consider 5NFT for practice only*/
        tokenID = 0;
        currentSupply = 0;
        lastTokenID = tokenID;
        // baseURI_ =  "https://my-json-server.typicode.com/asimro/NFTdata/tokens/";  
    }

    fallback() external payable {}
    receive() external payable {}
    
    modifier isSaleStart(){
        require(saleStartTime < block.timestamp, "TheToken: sale yet to start");
        require(NFTPrice > 0,"TheToken: NFT price is not yet set");
        require(bytes(baseURI_).length > 0,"TheToken: baseURI need to be decleared");
        _;
    }
    
     modifier isSaleEnd(){
        require(block.timestamp < saleEndTime, "TheToken: sale ended");
        _;
    }
    
    modifier maxSupply(){
        require(currentSupply < NFTMaxSupply ,"Max Supply achived");
        _;
    }   
   
   
   
   // ************************************************** // 
   
   function setNFTPrice(uint256 _NFTPrice) public onlyOwner() {
       NFTPrice = _NFTPrice * 10**18;       /*     1 ether   */
    }
   
   function getNFTPrice() public view returns(uint256) {
       return NFTPrice;
    }
   
   
   
    // ************************************************** // 
   
   function setBaseURI(string memory BaseURI) public onlyOwner() {
       baseURI_ = BaseURI;          /*     https://my-json-server.typicode.com/asimro/NFTdata/tokens/    */
    }
   
   
   
    // ************************************************** // 
        
    function buyToken(address to) public payable
        isSaleStart
        isSaleEnd
        maxSupply
        returns(uint256 totalFunds){
        
        require(msg.value == NFTPrice && msg.sender != address(0),"TheToken: unrequired value");
        
        payable(address(this)).transfer(msg.value);
        fundRaised = fundRaised + msg.value;
        
        tokenID += 1;
        lastTokenID = tokenID;
        currentSupply +=1;
        _mint(to, tokenID);
        
        return fundRaised;
    }


     // ************************************************** // 
     
    function killingContract()external payable onlyOwner() returns(bool){
        require(block.timestamp > saleEndTime,"TheToken: sale in progress");
        
        emit Transfer(address(this), owner(), fundRaised);    
        selfdestruct(payable(owner()));
        return true;
    }
}