/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface NFTContract{
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface TokenContract {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract SBFCreward {
    address private admin;

    NFTContract private nftContract;
    TokenContract private tokenContract;

    uint256 private StartTime; 
    uint256 private RewardOneHour = 1*10**14; //0.0001 * multiplier = 0.001 lox

    mapping(address=>bool) private isNotAllowed;
    mapping(uint256=>uint256) private lastTime; 

    constructor(address _nftAddress, address _tokenAddress, address _admin){
        nftContract = NFTContract(_nftAddress);
        tokenContract = TokenContract(_tokenAddress);
        admin = _admin;
        StartTime = block.timestamp;
    }

    modifier onlyAdmin {
        require(msg.sender==admin,"only admin can call this function");
        _;
    }

    function Claim(uint256 _id) external {
        require(!isNotAllowed[msg.sender], "Sorry, you are not allowed to claim Reward");
        require(nftContract.ownerOf(_id) == msg.sender,"You are not owner of this nft");

        uint256 _tokenReward = getMultiplier(msg.sender)*AvailableReward(_id);
        lastTime[_id] = block.timestamp;
        require(tokenContract.transfer(msg.sender,_tokenReward),"token not Transfered succefully");
    }

    function ClaimArray(uint256[] memory _ids) external {
        require(!isNotAllowed[msg.sender], "Sorry, you are not allowed to claim Reward");
        for(uint256 i = 0; i < _ids.length;i++) {
            require(nftContract.ownerOf(_ids[i]) == msg.sender,"You are not owner of this nft");
        }
        uint256 _tokenReward = 0;
        for(uint256 i = 0; i < _ids.length;i++){
            _tokenReward += AvailableReward(_ids[i]);
            lastTime[_ids[i]] = block.timestamp;
        }
        require(tokenContract.transfer(msg.sender,getMultiplier(msg.sender)*_tokenReward),"token not Transfered succefully");
    }

    function AvailableReward(uint256 _id) public view returns(uint256) {
        require(!isNotAllowed[msg.sender], "Sorry, you are not allowed to claim Reward");
        return ((block.timestamp - (lastTime[_id] > 0 ? lastTime[_id] : StartTime))/(60))*
        RewardOneHour; 
    }

    function getLastTime(uint256 _id) public view returns(uint256) {
        return lastTime[_id]; 
    }

    function getMultiplier(address _user) public view returns(uint256){
        if(nftContract.balanceOf(_user) >= 4 && nftContract.balanceOf(_user) < 10){
            return 11;
        } else if(nftContract.balanceOf(_user) >= 10 && nftContract.balanceOf(_user) < 20){
            return 13;
        }  else if(nftContract.balanceOf(_user) >= 20 ){
            return 15;
        } else {
        return 10;
        }
    }


    function addAllowStatus(address _user,bool status) public onlyAdmin{
        isNotAllowed[_user] = status;
    }

    function withdrawBalance(address _to) public onlyAdmin {
        (bool os, ) = payable(_to).call{value: address(this).balance}("");
        require(os);
    }

    function withdrawBalanceERC20(TokenContract _token, address _to, uint256 _amount) public onlyAdmin {
        _token.transfer(_to,_amount);
    }

    function changeAdmin(address _new) public onlyAdmin{
        admin = _new;
    }

}