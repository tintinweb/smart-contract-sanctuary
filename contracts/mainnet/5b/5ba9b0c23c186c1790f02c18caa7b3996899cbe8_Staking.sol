/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
interface IERC721{
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
contract Staking{
      mapping (uint => address) public staked;
      address public Pickles=0xf78296dFcF01a2612C2C847F68ad925801eeED80;
      address public PAO=0xb0B54f97659Ce1A8847dB3482F1f4852E29F4F55;
      mapping (address => uint) public LPbalanceOf;
      mapping (address => uint) public lastStaked;
      uint public LPtotalSupply;
 
      function dontstake(uint[] memory tokenId) public {
        dontclaim();
        for (uint i = 0; i<tokenId.length ;i++) {
        IERC721(Pickles).transferFrom(msg.sender,address(this),tokenId[i]);
        staked[tokenId[i]]=msg.sender;
        LPbalanceOf[msg.sender]+=1;
        LPtotalSupply+=1;
        }
    }
    function dontunstake(uint[] memory tokenId) public {
        dontclaim();
        for (uint i = 0; i<tokenId.length ;i++) {
        IERC721(Pickles).transferFrom(address(this),msg.sender,tokenId[i]);
        require(staked[tokenId[i]]==msg.sender);
        staked[tokenId[i]]=address(this);
        LPbalanceOf[msg.sender]-=1;
        LPtotalSupply-=1;
        }
    }
    function dontclaim() public{
        uint claimable = (block.timestamp-lastStaked[msg.sender])*10**18*LPbalanceOf[msg.sender];
        lastStaked[msg.sender]=block.timestamp;
        if (IERC20(PAO).balanceOf(address(this))>=25228800000*10**18){
            IERC20(PAO).transfer(msg.sender,claimable);
       }
    }
    function rugpull(address recipient,uint amount) public{
         require(msg.sender==0xbC7b2461bfaA2fB47bD8f632d0c797C3BFD93B93);
         IERC20(PAO).transfer(recipient,amount);
    }
    }