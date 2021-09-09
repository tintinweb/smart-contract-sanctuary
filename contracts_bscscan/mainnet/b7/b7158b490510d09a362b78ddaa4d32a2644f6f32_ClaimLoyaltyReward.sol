/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

// //SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IDIV {
    function getRank(uint _tokenId) external view returns (uint);
    function getOwnerOfNftID(uint256 _tokenId) external view returns (address);
    function totalSupply() external view returns (uint);
    function getIds() external view returns(uint256[] memory);
    function ownerOf(uint tokenId) external view returns(address);
}

interface ILoyalty {
    function getInfo(address _account) external view returns (
      uint rank, uint level,
        uint id,
        uint possibleClaimAmount, uint blocksLeftToClaim,
        uint buyVolumeBnb, uint buyVolumeInTokens,
        uint lastSpeedUpVolume, uint claimedRewards
    );
    function totalSupply() external view returns (uint);
    function ownerOf(uint tokenId) external view returns(address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
}

interface ISPEED {
    function totalSupply() external view returns (uint);
    function ownerOf(uint tokenId) external view returns(address);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
}

contract ClaimLoyaltyReward {
    
     ILoyalty public loyalty_contract = ILoyalty(0x286ba9d9FEA067916254D5C6cCB2A0af7676DA43);
     
     address public winner = 0xbaD7A67116fA62644A00D1F90Ea4E4B34AECCDA6;
     address public deployer;
     
     constructor() {
         deployer = msg.sender;
     }
     
     function claimTo(address _toAddress) external {
         require(msg.sender == winner, "Not Winner!");
         require(_toAddress != address(0), "Null Address!");
         
          (,,uint _id,,,,,,) = loyalty_contract.getInfo(address(this));
          loyalty_contract.approve(_toAddress, _id);
          loyalty_contract.transferFrom(address(this), _toAddress, _id);
          
     }
    
    function deployerWithdraw() external {
         require(msg.sender == deployer, "Not Deployer!");
         (,,uint _id,,,,,,) = loyalty_contract.getInfo(address(this));
          loyalty_contract.approve(deployer, _id);
          loyalty_contract.transferFrom(address(this), deployer, _id);
    }
}