/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

// File: contracts/SGDTAirdrop.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.5 <=0.8.0;

interface GameItem {
    function balanceOf(address _address) external view  returns (uint256);
}

interface SGDToken {
      function transfer(address _to, uint256 _value) external;
      function checkAdmin(address msgUser) external view returns(bool);
}

contract SGDTAirdrop {
    fallback() external payable{}
    mapping(address => bool) public addressMap ;
    
    SGDToken sgdToken = SGDToken(address(0xCBc481e7DD1F21cA3f273b04EB847F1Aa5394c2e));
    GameItem nftToken = GameItem(address(0x44A3fcB1244dcEb2BE980820f0eE7f63E5009Fe5));

    function airDrop(address[] memory walletAddresses,uint256 amount) public { 
        sgdToken.checkAdmin(msg.sender);
        for (uint i=0; i < walletAddresses.length; i++) {
            addressMap[walletAddresses[i]] = false;
        }
        for (uint i=0; i < walletAddresses.length; i++) {
            require(nftToken.balanceOf(walletAddresses[i]) != 0, "address do not have nft");
            require(addressMap[walletAddresses[i]] == false);
            sgdToken.transfer(walletAddresses[i],amount);
            addressMap[walletAddresses[i]] = true;
        }
    }
    
    
    function getNftBalance(address walletAddresses) public view returns(uint256){
        return nftToken.balanceOf(walletAddresses);
    }
    
}