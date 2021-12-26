/**
 *Submitted for verification at Etherscan.io on 2021-12-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IERC721{
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);   
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

}


contract NFTStacking {
    uint256 private timeForOneTokenReward = 60; //1 sec.

    uint256 private mimumTimeForUnstake = 60*60; //1 sec.
    
    struct NftStakeObj{
        uint256 nftId;
        uint256 stakingStartTime;
        uint256 lastRewardClaimTime;
        bool isStaked;
    }

    mapping(uint256=>bool) private isNftStakedByUser; //(nftCount=>isStaked)
    mapping(uint256=>NftStakeObj) private nftStakedData;

    mapping(uint256=>uint256) private totalRewardWithdrawnByNFT;

    uint256 private totalStakedNFTs;

    IERC721 private nftContract;
    IERC20 private tokenContract;

    address private admin;

    event nftStakedEvent(address indexed owner, uint256 indexed nftId, uint256 time);
    event nftUnStakedEvent(address indexed owner, uint256 indexed nftId, uint256 time);


    constructor(address _nftAddress, address _tokenAddress, address _admin){
        nftContract = IERC721(_nftAddress);
        tokenContract = IERC20(_tokenAddress);
        admin = _admin;
    }


    // constructor(){
    //     nftContract = IERC721(0x9d83e140330758a8fFD07F8Bd73e86ebcA8a5692);
    //     tokenContract = IERC20(0xd9145CCE52D386f254917e481eB44e9943F39138);
    //     admin = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    // }

    modifier onlyAdmin {
        require(msg.sender==admin,"only admin can call this function");
        _;
    }

    function stakeNFT(uint256 _nftCount) public {
        require(nftContract.ownerOf(_nftCount) == msg.sender,"your are not the owner of this NFT"); //check if user is the owner of nft
        require(!isNftStakedByUser[_nftCount],"User already staked this NFT");//

        isNftStakedByUser[_nftCount] = true;
        nftStakedData[_nftCount] = NftStakeObj(_nftCount,block.timestamp,block.timestamp,true);
        totalStakedNFTs += 1; 

        emit nftStakedEvent(msg.sender,_nftCount,block.timestamp);
    }

    function stakeNFTarray(uint256[] memory _allNftsIds) public {
        for(uint256 i=0;i<_allNftsIds.length;i++){
        require(nftContract.ownerOf(_allNftsIds[i]) == msg.sender,"your are not the owner of this NFT"); //check if user is the owner of nft
        require(!isNftStakedByUser[_allNftsIds[i]],"User already staked this NFT");//

        isNftStakedByUser[_allNftsIds[i]] = true;
        nftStakedData[_allNftsIds[i]] = NftStakeObj(_allNftsIds[i],block.timestamp,block.timestamp,true);
        totalStakedNFTs += 1;
        emit nftStakedEvent(msg.sender,_allNftsIds[i],block.timestamp);
        }
        
    }

    function unStakeNFT(uint256 _nftCount) public {
        require(nftContract.ownerOf(_nftCount) == msg.sender,"your are not the owner of this NFT"); //check if user is the owner of nft
        require(isNftStakedByUser[_nftCount],"Please First, Stake this Nft");//
        
        isNftStakedByUser[_nftCount] = false;
        nftStakedData[_nftCount].isStaked = false;
        totalStakedNFTs -= 1;

        emit nftUnStakedEvent(msg.sender,_nftCount,block.timestamp);


        _giveUserReward(_nftCount);

    }

    function unStakeNFTarray(uint256[] memory _allNftsIds) public {
        for(uint256 i=0;i<_allNftsIds.length;i++){

        require(nftContract.ownerOf(_allNftsIds[i]) == msg.sender,"your are not the owner of this NFT"); //check if user is the owner of nft
        require(isNftStakedByUser[_allNftsIds[i]],"Please First, Stake this Nft");//
        
        isNftStakedByUser[_allNftsIds[i]] = false;
        nftStakedData[_allNftsIds[i]].isStaked = false;
        totalStakedNFTs -= 1;

        emit nftUnStakedEvent(msg.sender,_allNftsIds[i],block.timestamp);

        _giveUserReward(_allNftsIds[i]);

        }
    }

    function claimReward(uint256 _nftCount) public {
        
        require(nftContract.ownerOf(_nftCount) == msg.sender,"your are not the owner of this NFT"); //check if user is the owner of nft
        require(isNftStakedByUser[_nftCount],"Please First, Stake this Nft");//

        _giveUserReward(_nftCount);
    }

    function claimRewardarray(uint256[] memory _allNftsIds) public {
        for(uint256 i=0;i<_allNftsIds.length;i++){
        require(nftContract.ownerOf(_allNftsIds[i]) == msg.sender,"your are not the owner of this NFT"); //check if user is the owner of nft
        require(isNftStakedByUser[_allNftsIds[i]],"Please First, Stake this Nft");//

        _giveUserReward(_allNftsIds[i]);
        }
    }

    function _giveUserReward(uint256 _nftCount) private  {
        require(nftStakedData[_nftCount].stakingStartTime + mimumTimeForUnstake < block.timestamp ,"you should claim after minimum time");

        uint256 _stakingstartTime = nftStakedData[_nftCount].lastRewardClaimTime;
        uint256 _stakingIntervalTime = block.timestamp - _stakingstartTime;
        nftStakedData[_nftCount].lastRewardClaimTime = block.timestamp;

        uint256 _tokenReward = _stakingIntervalTime *10**3 / timeForOneTokenReward;
        require(_tokenReward > 0,"reward must be greater than 1 token");
        totalRewardWithdrawnByNFT[_nftCount] += _tokenReward*10**15;

        require(tokenContract.transfer(msg.sender,_tokenReward*10**15),"token not Trasfaredd succefully");
    }



    function withdrawBalance(address _to) public payable onlyAdmin {
        (bool os, ) = payable(_to).call{value: address(this).balance}("");
        require(os);
    }

    function withdrawBalanceERC20(IERC20 _token, address _to, uint256 _amount) public payable onlyAdmin {
        _token.transfer(_to,_amount);
    }

    function adminBalance() public view onlyAdmin returns(uint256) {
        return  address(this).balance;
    }

    function adminBalanceERC20(IERC20 _token) public view onlyAdmin returns(uint256) {
        return  _token.balanceOf(address(this));
    }

    function changeAdmin(address _newAdmin) public onlyAdmin {
    admin = _newAdmin;
    }

    // getFunctions
    function getIsNftStakedByUser(uint256 _nftId) public view returns(bool){
        return isNftStakedByUser[_nftId];
    }

    function getNftStakedByUser(uint256 _nftId) public view  returns(NftStakeObj memory){
        return nftStakedData[_nftId];
    }

    function gettotalRewardWithdrawnByNFT(uint256 _nftCount) public view  returns(uint256){
        return totalRewardWithdrawnByNFT[_nftCount];
    }

    function getTotalStakedNFTs() public view  returns(uint256){
        return totalStakedNFTs;
    }

    function getTimeForOneTokenReward() public view  returns(uint256){
        return timeForOneTokenReward;
    }
     
}