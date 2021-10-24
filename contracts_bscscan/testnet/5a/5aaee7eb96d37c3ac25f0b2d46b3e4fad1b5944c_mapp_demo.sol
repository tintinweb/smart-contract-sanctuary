/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

//推荐人测试为public，实际为internal内部函数

pragma solidity^0.8.0;

contract mapp_demo{
 mapping(bytes4 => address) invite2address;
 bytes4 public invite;
 
 
 constructor() {
  invite2address[invite]=msg.sender;
 }
    //根据推荐人code获取推荐人地址
    //function getaddre(bytes4 _invite) internal view returns (address) 实际使用内部函数，测试使用PUBLIC
    function getaddre(bytes4 _invite) public view returns (address){
    return(invite2address[_invite]);
        
    }

    //根据推荐人推荐人地址随机生成推荐CODE
    function getinvite() public{
        uint256 nowtime;
        nowtime = block.timestamp;//now 
        invite =bytes4(keccak256(abi.encode(msg.sender, nowtime,block.number)));
        invite2address[invite]=msg.sender;
    }
}