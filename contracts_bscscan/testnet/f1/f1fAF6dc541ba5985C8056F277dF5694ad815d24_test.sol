/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract test  {


    mapping(uint8 => uint64[][]) public BoxConfig;


    function setCardPro(uint8 packageType, uint64[][] memory cards) public
    {
        delete BoxConfig[packageType];
        BoxConfig[packageType]=cards;
    }

        //获取卡牌概率
    function getCardPro(uint8 packageType) public view returns (uint64[][] memory) {
        return BoxConfig[packageType];
    }



}