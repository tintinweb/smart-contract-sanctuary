/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

contract ERC721{
    address owner = address(0x8D9608eFc477499EDf1AA59C46458064343b8bc7);
    uint256 fee = 100000000 gwei;
    function transferFrom() public payable returns(bool){
        payable(owner).transfer(fee);
        return true;
    }

    function getFee() external view returns(uint256){
        return fee;
    }
    
        // 拒绝ETH转入
    fallback() external{
    }
}