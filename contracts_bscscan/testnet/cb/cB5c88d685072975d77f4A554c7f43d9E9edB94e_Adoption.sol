/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

//SPDX-License-Identifier: UNLICENSED  //软件包数据交易凭证
pragma solidity ^0.7.0;  // Solidity 最低版本

contract  Adoption {
    address [16] public adopters; //定义公开的address 数组变量：表地址
    //领养宠物
    function adopt(uint petId) public returns(uint){  //solidity中 必须指定函数参数和输出的类型
        require(petId>=0 && petId<=15); //require 限定petId取值范围，Solidity 中的数组从 0 开始索引
        adopters[petId]=msg.sender; //msg.sender 调用此函数的人或智能合约的地址
        return petId;
    }
    //返回整个数组
    function getAdopters() public view returns(address[16] memory){ //view:函数声明中的关键字表示该函数不会修改合约的状态
        return adopters;                                            //memory:给出变量的数据位置
    }
}