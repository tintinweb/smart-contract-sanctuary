/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Create {
    event createNft(
        address from,address to,uint256 nftId,uint256 nftType,string nftName,
    uint256 cardType,uint256 camp,uint256 starLevel);

       int private result;

    function add(int a,int b)public returns(int c){
        result=a+b;
        c=result;
        emit createNft(address(0),msg.sender,123,1,"nvwa",1,1,1);
    }

    function getResult()public view returns (int){
        return result;
    }

}