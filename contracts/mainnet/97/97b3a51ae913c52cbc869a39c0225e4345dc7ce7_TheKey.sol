/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;
 
interface ICaller{

    function ownerOf(uint _tokenId) external returns(address);
}


contract TheKey {
    
    string public sponsoringContent = "";

    function updateSponsoringContent(string memory newSponsoringContent) external {
        address owner = ICaller(address(0x3B3ee1931Dc30C1957379FAc9aba94D1C48a5405)).ownerOf(2724);
        require(msg.sender == owner, "Not owner of 2724");
        sponsoringContent=newSponsoringContent;
    }


    function getSponsoringContent() public view returns (string memory){
        return sponsoringContent;
    }
}