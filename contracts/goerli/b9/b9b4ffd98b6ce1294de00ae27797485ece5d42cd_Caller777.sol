/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

pragma solidity ^0.8.0;

contract Caller777{
    address public nft777;
    
    constructor(address nft777_){
        nft777 = nft777_;
    }
    
    function mintMul(uint256 amount,uint256 value_,uint256 mintAmount) public payable{
        for (uint256 i;i<amount;i++){
            (bool success,) = nft777.call{value: value_}(abi.encodeWithSignature("mintTokens(uint256)", mintAmount));
            require(success,"ERROR: call 777 error");
        }
    }
}