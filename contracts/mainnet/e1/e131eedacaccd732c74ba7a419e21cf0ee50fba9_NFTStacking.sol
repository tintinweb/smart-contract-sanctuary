/**
 *Submitted for verification at Etherscan.io on 2021-12-31
*/

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
    uint256 private tokenRewardInOneHour = 1*10**15; //0.001 lox

    uint256 private mimumTimeForUnstake = 14*24*60*60; //14 days.
    
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
        require(msg.sender==admin,"No permission");
        _;
    }

    function stakeNFT(uint256 _nftCount) public {
        require(nftContract.ownerOf(_nftCount) == msg.sender,"You don't own this NFT"); //check if user is the owner of nft
        require(!isNftStakedByUser[_nftCount],"This NFT Is already staked");//

        isNftStakedByUser[_nftCount] = true;
        nftStakedData[_nftCount] = NftStakeObj(_nftCount,block.timestamp,block.timestamp,true);
        totalStakedNFTs += 1; 

        emit nftStakedEvent(msg.sender,_nftCount,block.timestamp);
    }

    function stakeNFTarray(uint256[] memory _allNftsIds) public {
        for(uint256 i=0;i<_allNftsIds.length;i++){
        require(nftContract.ownerOf(_allNftsIds[i]) == msg.sender,"You don't own this NFT"); //check if user is the owner of nft
        require(!isNftStakedByUser[_allNftsIds[i]],"This NFT Is already staked");//

        isNftStakedByUser[_allNftsIds[i]] = true;
        nftStakedData[_allNftsIds[i]] = NftStakeObj(_allNftsIds[i],block.timestamp,block.timestamp,true);
        totalStakedNFTs += 1;
        emit nftStakedEvent(msg.sender,_allNftsIds[i],block.timestamp);
        }
        
    }

    function unStakeNFT(uint256 _nftCount) public {
        require(nftContract.ownerOf(_nftCount) == msg.sender,"You don't own this NFT"); //check if user is the owner of nft
        require(isNftStakedByUser[_nftCount],"Please stake NFT first");//
        
        isNftStakedByUser[_nftCount] = false;
        nftStakedData[_nftCount].isStaked = false;
        totalStakedNFTs -= 1;

        emit nftUnStakedEvent(msg.sender,_nftCount,block.timestamp);


        _giveUserReward(_nftCount);

    }

    function unStakeNFTarray(uint256[] memory _allNftsIds) public {
        for(uint256 i=0;i<_allNftsIds.length;i++){

        require(nftContract.ownerOf(_allNftsIds[i]) == msg.sender,"You don't own this NFT"); //check if user is the owner of nft
        require(isNftStakedByUser[_allNftsIds[i]],"Please stake NFT first");//
        
        isNftStakedByUser[_allNftsIds[i]] = false;
        nftStakedData[_allNftsIds[i]].isStaked = false;
        totalStakedNFTs -= 1;

        emit nftUnStakedEvent(msg.sender,_allNftsIds[i],block.timestamp);

        _giveUserReward(_allNftsIds[i]);

        }
    }

    function claimReward(uint256 _nftCount) public {
        
        require(nftContract.ownerOf(_nftCount) == msg.sender,"You don't own this NFT"); //check if user is the owner of nft
        require(isNftStakedByUser[_nftCount],"Please stake NFT first");//

        _giveUserReward(_nftCount);
    }

    function claimRewardarray(uint256[] memory _allNftsIds) public {
        for(uint256 i=0;i<_allNftsIds.length;i++){
        require(nftContract.ownerOf(_allNftsIds[i]) == msg.sender,"You don't own this NFT"); //check if user is the owner of nft
        require(isNftStakedByUser[_allNftsIds[i]],"Please stake NFT first");//

        _giveUserReward(_allNftsIds[i]);
        }
    }

    function _giveUserReward(uint256 _nftCount) private  {
        require(nftStakedData[_nftCount].lastRewardClaimTime + mimumTimeForUnstake < block.timestamp ,"You can claim after minimum staking time");

        uint256 _stakingstartTime = nftStakedData[_nftCount].lastRewardClaimTime;
        uint256 _stakingIntervalTime = block.timestamp - _stakingstartTime;
        nftStakedData[_nftCount].lastRewardClaimTime = block.timestamp;

        uint256 _tokenReward = (_stakingIntervalTime/(60*60))*tokenRewardInOneHour;
        totalRewardWithdrawnByNFT[_nftCount] += _tokenReward;

        require(tokenContract.transfer(msg.sender,_tokenReward),"Token transfer failed");
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

    function changeTokenRewardInOneHour(uint256 _tokenRewardInOneHour) public onlyAdmin {
    tokenRewardInOneHour = _tokenRewardInOneHour;
    }

    function changeMimumTimeForUnstake(uint256 _mimumTimeForUnstake) public onlyAdmin {
    mimumTimeForUnstake = _mimumTimeForUnstake;
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

    function getTokenRewardInOneHour() public view  returns(uint256){
        return tokenRewardInOneHour;
    }

    function getMimumTimeForUnstake() public view  returns(uint256){
        return mimumTimeForUnstake;
    }
    
     
}