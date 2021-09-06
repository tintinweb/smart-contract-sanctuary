/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

pragma solidity ^0.8.0;

interface NFT777{
    function mintTokens(uint256 count) external payable;
}

contract Caller777{
    address public nft777;
    
    constructor(address nft777_){
        nft777 = nft777_;
    }
    
    function mintMul(uint256 amount) public payable{
        for (uint256 i;i<amount;i++){
            NFT777(nft777).mintTokens(1);
        }
    }
}