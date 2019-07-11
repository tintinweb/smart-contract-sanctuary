/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

pragma solidity ^0.4.24;
 
contract GoodsInfo{
    struct Goods{
      string info;
      bool isVaild;
    }
    mapping (uint => Goods) goodsInfoMap;
    address owner;
    constructor(address a) public{
        owner = a;
    }
    function record(uint i,string info) public{
        require(msg.sender == owner);
        require(goodsInfoMap[i].isVaild == false);
        goodsInfoMap[i].info = info;
        goodsInfoMap[i].isVaild = true;
    }
    function getRecordById(uint i) constant public returns (string){
        return goodsInfoMap[i].info;
    }
}