/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes memory) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract MintableToken {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function royalities(uint _tokenId) public view returns (uint);
    function creators(uint _tokenId) public view returns (address payable);
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
    
    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}
 
contract Broker is ERC721Holder{
    
    address owner;
    uint16 public brokerage;
    mapping(address => mapping (uint => bool)) tokenOpenForSale;
    // mapping (uint => uint) public prices;
    mapping (address => tokenDet[]) public tokensForSalePerUser;
    
    //auction type :
    // 1 : only direct buy
    // 2 : only bid
    // 3 : both buy and bid
    
    struct auction {
        address payable lastOwner;
        uint currentBid;
        address payable highestBidder;
        uint auctionType;
        uint startingPrice;
        uint buyPrice;
        bool buyer;
        uint startingTime;
        uint closingTime;
    }
    
    struct tokenDet {
        address NFTAddress;
        uint tokenID;
    }
    
    mapping (address => mapping (uint => auction)) public auctions;
    // mapping (uint => auction) public auctions;
    
    tokenDet[] public tokensForSale;
    
    constructor(uint16 _brokerage) public{
        owner = msg.sender;
        brokerage = _brokerage;
    } 
    
    function getTokensForSale() public view returns (tokenDet[] memory) {
        return tokensForSale;
    }
    
    function getTokensForSalePerUser(address _user) public view returns (tokenDet[] memory) {
        return tokensForSalePerUser[_user];
    }
    
    function setBrokerage(uint16 _brokerage) public onlyOwner {
        brokerage = _brokerage;
    }

    function bid(uint tokenID, address _mintableToken) payable public{
        MintableToken Token = MintableToken(_mintableToken);
        require(tokenOpenForSale[_mintableToken][tokenID]==true,'Token Not For Sale');
        require(msg.value>auctions[_mintableToken][tokenID].currentBid,'Insufficient Payment');
        require(block.timestamp < auctions[_mintableToken][tokenID].closingTime, 'Auction Time Over!');
        require(auctions[_mintableToken][tokenID].auctionType!=1, 'Auction Not For Bid');
        
        if(auctions[_mintableToken][tokenID].buyer == true){
            auctions[_mintableToken][tokenID].highestBidder.transfer(auctions[_mintableToken][tokenID].currentBid);
        }
        
        Token.safeTransferFrom(Token.ownerOf(tokenID), address(this), tokenID);
        auctions[_mintableToken][tokenID].currentBid = msg.value;
        auctions[_mintableToken][tokenID].buyer = true;
        auctions[_mintableToken][tokenID].highestBidder = msg.sender;
    }
    
    function collect(uint tokenID, address _mintableToken) public{
        
        MintableToken Token = MintableToken(_mintableToken);
        require(block.timestamp > auctions[_mintableToken][tokenID].closingTime, 'Auction Not Over!');
        
        address payable lastOwner2 = auctions[_mintableToken][tokenID].lastOwner;
        uint royalities = Token.royalities(tokenID);
        address payable creator = Token.creators(tokenID);
        
        auctions[_mintableToken][tokenID].buyPrice = uint(0);
        tokenOpenForSale[_mintableToken][tokenID] = false;
        
        Token.safeTransferFrom(Token.ownerOf(tokenID), auctions[_mintableToken][tokenID].highestBidder , tokenID);
        creator.transfer(royalities*auctions[_mintableToken][tokenID].currentBid/10000);
        lastOwner2.transfer((10000-royalities-brokerage)*auctions[_mintableToken][tokenID].currentBid/10000);
        
         uint index;
        for(uint i=0; i<tokensForSale.length; i++){
            if(tokensForSale[i].tokenID==tokenID){
                index = i;
                break;
            }
        }
        
        tokensForSale[index] = tokensForSale[tokensForSale.length - 1];
        delete tokensForSale[tokensForSale.length - 1];
        tokensForSale.pop();
        
        uint index2;
        for(uint i=0; i<tokensForSalePerUser[lastOwner2].length; i++){
            if(tokensForSalePerUser[lastOwner2][i].tokenID==tokenID){
                index2 = i;
                break;
            }
        }
        
        tokensForSalePerUser[lastOwner2][index2] = tokensForSalePerUser[lastOwner2][tokensForSalePerUser[lastOwner2].length - 1];
        delete tokensForSalePerUser[lastOwner2][tokensForSalePerUser[lastOwner2].length - 1];
        tokensForSalePerUser[lastOwner2].pop();
        
    }
    
    function buy(uint tokenID, address _mintableToken) payable public{
        
        MintableToken Token = MintableToken(_mintableToken);
        require(tokenOpenForSale[_mintableToken][tokenID]==true,'Token Not For Sale');
        require(msg.value>=auctions[_mintableToken][tokenID].buyPrice,'Insufficient Payment');
        require(auctions[_mintableToken][tokenID].auctionType!=2,'Auction for Bid only!');
        address payable lastOwner2 = auctions[_mintableToken][tokenID].lastOwner;
        uint royalities = Token.royalities(tokenID);
        address payable creator = Token.creators(tokenID);
        
        // auctions[_mintableToken][tokenID].buyPrice = uint(0);
        tokenOpenForSale[_mintableToken][tokenID] = false;
        auctions[_mintableToken][tokenID].buyer = true;
        auctions[_mintableToken][tokenID].highestBidder = msg.sender;
        auctions[_mintableToken][tokenID].currentBid = auctions[_mintableToken][tokenID].buyPrice;
        
        Token.safeTransferFrom(Token.ownerOf(tokenID),  auctions[_mintableToken][tokenID].highestBidder, tokenID);
        creator.transfer(royalities*auctions[_mintableToken][tokenID].currentBid/10000);
        lastOwner2.transfer((10000-royalities-brokerage)*auctions[_mintableToken][tokenID].currentBid/10000);
        
        uint index;
        for(uint i=0; i<tokensForSale.length; i++){
            if(tokensForSale[i].tokenID==tokenID){
                index = i;
                break;
            }
        }
        
        tokensForSale[index] = tokensForSale[tokensForSale.length - 1];
        delete tokensForSale[tokensForSale.length - 1];
        tokensForSale.pop();
        
        uint index2;
        for(uint i=0; i<tokensForSalePerUser[lastOwner2].length; i++){
            if(tokensForSalePerUser[lastOwner2][i].tokenID==tokenID){
                index2 = i;
                break;
            }
        }
        
        tokensForSalePerUser[lastOwner2][index2] = tokensForSalePerUser[lastOwner2][tokensForSalePerUser[lastOwner2].length - 1];
        delete tokensForSalePerUser[lastOwner2][tokensForSalePerUser[lastOwner2].length - 1];
        tokensForSalePerUser[lastOwner2].pop();
    } 
    
    function withdraw() onlyOwner public {
        msg.sender.transfer(address(this).balance);
    }
    
    function putOnSale(uint _tokenID, uint _startingPrice, uint _auctionType, uint _buyPrice, uint _duration, address _mintableToken) public{
        MintableToken Token = MintableToken(_mintableToken);
        require(Token.ownerOf(_tokenID)==msg.sender,'Permission Denied');
        require(Token.getApproved(_tokenID)==address(this),'Broker Not approved');
        auction memory newAuction = auction(msg.sender, _startingPrice, address(0), _auctionType, _startingPrice, _buyPrice, false, block.timestamp,  block.timestamp + _duration ); 
        auctions[_mintableToken][_tokenID] = newAuction;
        tokenOpenForSale[_mintableToken][_tokenID] = true;
        tokenDet memory object = tokenDet(_mintableToken,_tokenID);
        tokensForSale.push(object);
        tokensForSalePerUser[msg.sender].push(object);
    }
    
    function putSaleOff(uint tokenID, address _mintableToken) public{
        MintableToken Token = MintableToken(_mintableToken);
        require(Token.ownerOf(tokenID)==msg.sender,'Permission Denied');
        auctions[_mintableToken][tokenID].buyPrice = uint(0);
        tokenOpenForSale[_mintableToken][tokenID] = false;
        uint index;
        for(uint i=0; i<tokensForSale.length; i++){
            if(tokensForSale[i].tokenID==tokenID){
                index = i;
                break;
            }
        }
        
        tokensForSale[index] = tokensForSale[tokensForSale.length - 1];
        delete tokensForSale[tokensForSale.length - 1];
        tokensForSale.pop();
        
        uint index2;
        for(uint i=0; i<tokensForSalePerUser[msg.sender].length; i++){
            if(tokensForSalePerUser[msg.sender][i].tokenID==tokenID){
                index2 = i;
                break;
            }
        }
        
        tokensForSalePerUser[msg.sender][index2] = tokensForSalePerUser[msg.sender][tokensForSalePerUser[msg.sender].length - 1];
        delete tokensForSalePerUser[msg.sender][tokensForSalePerUser[msg.sender].length - 1];
        tokensForSalePerUser[msg.sender].pop();
    }
         
    function getOnSaleStatus(address _mintableToken, uint tokenID) public view returns (bool){
        return tokenOpenForSale[_mintableToken][tokenID];
    }
    
    modifier onlyOwner() {
        require(owner==msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function () payable external{
    //call your function here / implement your actions
    }

}