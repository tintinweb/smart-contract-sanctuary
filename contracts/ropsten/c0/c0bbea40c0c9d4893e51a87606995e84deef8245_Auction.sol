/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }
}
interface nftToken {
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    function _exists(uint256 tokenId) external view returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}
contract Auction {
    using SafeMath for uint256;
    struct Art {
        string artName;
        string artistName;
        uint256 artPrice;
    }
    address public admin2;
    nftToken public nft;
    constructor(nftToken _nft) public{
        nft=_nft;
        admin2=msg.sender;
    }
    mapping(string=>Art) public artDetails;
    mapping(uint256 => string) public tokenIdToName;
    modifier onlyAdmin {
        require(msg.sender==admin2,"Only admin is allowed to access");
        _;
    }
    function addArt(string memory _artName, string memory _artistName, uint256 _artPrice) public onlyAdmin  {
        artDetails[_artName].artName=_artName;
        artDetails[_artName].artistName=_artistName;
        artDetails[_artName].artPrice=_artPrice;
    }
    function setIDName(uint256 _tokenId, string memory _artName ) public onlyAdmin {
       require(nft._exists(_tokenId),"TokenId doesn't not exists");
       require(keccak256(abi.encodePacked(artDetails[_artName].artName)) == keccak256(abi.encodePacked(_artName)),"Art does not exists");
       tokenIdToName[_tokenId]=_artName;
    }
    mapping(address=> mapping(uint256=>uint256)) auctionPrice;
    mapping(uint256=>address payable) biderAddress;
    bool auctionStarted;
    uint256 startTime;
    uint256 public endTime;
    uint256 totalAddress;
    address public highestBidder;
    uint256 public highestValue;
    function startAuction() public onlyAdmin {
        auctionStarted=true;
        startTime=now;
        endTime=startTime + 15 minutes;
    }
    function stopAuction() public onlyAdmin {
        auctionStarted=false;
    }
    function bidAmount(uint256 _tokenId) public payable{
        require(auctionStarted==true,"Auction has not started yet");
        require(endTime>=now,"Auction has been stopped");
        require(nft._exists(_tokenId),"Token Id does not exist");
        require(msg.value>=artDetails[tokenIdToName[_tokenId]].artPrice);
        if(auctionPrice[msg.sender][_tokenId]==0) {
            totalAddress++;
            biderAddress[totalAddress++]=msg.sender;
        }
        auctionPrice[msg.sender][_tokenId]=auctionPrice[msg.sender][_tokenId].add(msg.value);
    }
    function result(uint256 _tokenId) public payable onlyAdmin returns(address,uint256) {
        require(now>=endTime || auctionStarted==false,"Auction is still going");
        require(nft._exists(_tokenId),"Token Id does not exist");
        for(uint256 i=0;i<totalAddress;i++) {
            if(highestValue<auctionPrice[biderAddress[i]][_tokenId]) {
                highestValue=auctionPrice[biderAddress[i]][_tokenId];
                highestBidder=biderAddress[i];
            }
        }
        nft.transferFrom(admin2,highestBidder,_tokenId);
        auctionPrice[highestBidder][_tokenId]=0;
        for(uint256 i=0;i<totalAddress;i++) {
        biderAddress[i].transfer(auctionPrice[biderAddress[i]][_tokenId]);
        }
        return (highestBidder,highestValue);
    }
}