// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC721URIStorage.sol';
import './Counters.sol';

interface Istaking{
    function startStakePeriod(uint _tokenId) external;
    function getStakeDetails(uint _tokenId) external returns (uint,uint,uint);
    function revokeNFTstake(uint _tokenId) external;
}
interface IAuction{
    function startBidPeriod(uint _tokenId, uint startPrice,address owner) external;
    function revokeNFTBid(uint _tokenId) external ;
}

/**
 * @notice - This is the NFT contract
 */
contract TwentyFourNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    address public gov;
    address public stakingAddress;
    address public auctionAddress;
    mapping (uint => address) public artist;
    uint[] public burntNFTs;
    mapping (string => uint) hashExists;
    mapping (uint =>string) public publicImage;
    event CreateNFT(uint indexed _tokenId,address indexed artist,string hash,uint createTime);
    //mapping (uint256 => string) private rawHash; //for rawfileHash only for the owner

     Counters.Counter private _counter;
    
    constructor (
        address _dev   //dev address
    ) 
        ERC721('24nft.store', '24NFT') 
    {
        gov = _dev;
    }
    
    function getURI(uint _tokenId) external view returns( string memory){
        require(msg.sender == ownerOf(_tokenId),'Not Authorized');
        return _tokenURIs[_tokenId];
    }
        
    function getArtist(uint _tokenId) external view returns(address){
        return artist[_tokenId];
    }

    function setStakingAddress(address _staking) public onlyGov(){
        stakingAddress = _staking;
    }
    function setAuctionAddress(address _auction) public onlyGov(){
        auctionAddress = _auction;
    }

    /** 
     * @dev mint a NFT
     * @dev tokenURI - URL include ipfs hash
     */
    function mint(
        string memory tokenURI,
        string memory _image,
        uint startPrice 
         //string memory rawUri
         ) public returns (bool) {
        /// Mint a new NFT
        require(hashExists[tokenURI] == 0,'NFT Already Exists');
        
        hashExists[tokenURI] = 1;
        _counter.increment();
        uint256 _id = _counter.current();
        artist[_id] = msg.sender;
        _mint(auctionAddress, _id);
        _setTokenURI(_id, tokenURI);
        //rawHash[_id]  = rawUri;
        Istaking(stakingAddress).startStakePeriod(_id);
        IAuction(auctionAddress).startBidPeriod(_id, startPrice,msg.sender);
        publicImage[_id]=_image;
        emit CreateNFT(_id,msg.sender,_image,block.timestamp);
        return true;
    }
    function revokeNFT(uint _tokenId) external onlyArtist(_tokenId){
        uint totalStakes;
        uint endTime;
        (totalStakes,endTime,) = Istaking(stakingAddress).getStakeDetails(_tokenId);
        require(totalStakes>0,'Cannot revoke after someone has staked');
        require(endTime>block.timestamp,'Cannot revoke after auction has started');
        _burn(_tokenId);
        Istaking(stakingAddress).revokeNFTstake(_tokenId);
        IAuction(stakingAddress).revokeNFTBid(_tokenId);
        burntNFTs.push(_tokenId);
    }

    function eraseNFT(uint _tokenId) external onlyAuction() {
        _burn(_tokenId);
    }

    function clearStoredBurntAddresses() external onlyGov(){
        delete burntNFTs;
    }

    modifier onlyGov (){
        require(msg.sender == gov,"You don't have the permission to do that");
        _;
    }
    modifier onlyArtist (uint _id){
        require(msg.sender == artist[_id],"You don't have the permission to do that");
        _;
    }
    modifier onlyAuction (){
        require(msg.sender == auctionAddress,"You don't have the permission to do that");
        _;
    }
}