/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.17;

interface Interface_stars {
    
    function transfer(address , uint256) payable external returns(bool);
    function transferFrom(address ,address , uint256) payable external returns(bool) ;
    function balanceOf(address)  external view  returns(uint256);
    function approve(address , uint256) external payable  returns(bool);
    
}  


interface NFT{
    function createToken(address , uint256 , uint256)payable external;
    function ownerOf( uint256) external returns(address);
    function tokenDetails(uint256) external returns(uint256,uint256);
    function returnTokenCount(address , uint256 , bool) external returns(uint256);
    function burn(address , uint256) external payable ;
    function safeTransferFrom(address , address , uint256) external payable ;
    function transfer(address , uint256) external payable;
}


contract Game{
    
    constructor () public{
        
    owner  = msg.sender;
       
    }
    Interface_stars public  stars ;
    NFT public nft;
    
    function set_token_address(address token_add) public {
        require(msg.sender == owner);
        stars = Interface_stars(token_add);
    }
    function set_nft_address(address nft_add) public{
        require(msg.sender == owner);
        nft = NFT(nft_add);
        
    }
    
    
    mapping(address => uint256) allowed;
    mapping(address => bool) isSignup;
    address public owner;
    mapping(uint256 => address) blockedTokens;
    
    
    uint256 public value;
    uint256 public NoOfTokens;
    uint256 public starCount; 
    
    function setValue(uint256 _value) public payable {
        require(msg.sender==owner);
        value = _value;
        
    }
    function setToken(uint256 _amount) public payable{
         require(msg.sender==owner);
        NoOfTokens = _amount;
    }
    function setStars(uint256 _stars) public payable{
         require(msg.sender==owner);
        starCount = _stars;
    }
    
    
    //assuming 0: rock , 1: paper , 2:scissor
    function signUp(address player) public payable returns(bool){
        require(isSignup[player]==false , "already signUp");
        isSignup[player] = true;
        
        for(uint256 stones=0; stones< NoOfTokens; stones++){
          nft.createToken(player, 1 ,value);  
        }
        
        for(uint256 paper =0;  paper < NoOfTokens; paper++){
          nft.createToken(player, 2 ,value);            
        }
        for(uint256 scissor = 0; scissor< NoOfTokens ; scissor++){
          nft.createToken(player, 3 ,value);  
        }
        
      return  stars.transferFrom(owner,player ,starCount);
    
    }
    
    
   
    function blockStars(address _of , uint256 _count) public{
        require(stars.balanceOf(_of)>=1);
        stars.transferFrom(_of , owner , _count);
        
    
        
    }

    
    function transferBack(address player , uint256 _amount) public payable{
        stars.transferFrom(owner , player , _amount);
    }
 
   
    function cardDetails(address user , uint256 tokenId) public payable returns(uint256 , uint256){
        require(user == nft.ownerOf(tokenId));
         uint256 cardType ;
         uint256 valueOfCard;
         (cardType,valueOfCard) = nft.tokenDetails(tokenId);
         blockedTokens[tokenId]=user;
         return (cardType,valueOfCard);

    }
    //block the cards
    
    
    function clearTokens(uint256 tokenID1 , uint256 tokenID2 , bool status) public payable {
        if(!status){
           uint256 tokenToReturn;
           tokenID1== 0 ? tokenToReturn=tokenID2 : tokenToReturn = tokenID1;
           nft.transfer( blockedTokens[tokenToReturn] , tokenToReturn);
           
        }
        delete(blockedTokens[tokenID1]);
        delete(blockedTokens[tokenID2]);
    }
    
  
    
    function TotalCards(address _of) public   returns(uint256){


        return nft.returnTokenCount(_of, 0 , true);
    }
    
    function remainingRock(address _of) public   returns(uint256){
       return nft.returnTokenCount(_of, 1 , false);
    }
    
    function remainingPaper(address _of) public   returns(uint256){
       return nft.returnTokenCount(_of, 2 , false);
    }
    
    function remainingScissor(address _of) public   returns(uint256){
        return nft.returnTokenCount(_of, 3 , false);
    }
    
    
    function showStars(address _of) public view returns(uint256){
        return stars.balanceOf(_of); // call hritik function
    }
    

    
    
}