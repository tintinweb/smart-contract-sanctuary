/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.0 <0.9.0;
pragma experimental ABIEncoderV2;

library dataStructure{
    struct dataStruct{
        address userAddress;
        uint256 id;
        uint256 user1;
        uint256 user2;
        uint256 user3;
        address userAdd1;
        bool status1;
        bool status2;
    }
}

contract paramStruct{
    struct data{
        address userAddress;
        uint256 id;
        uint256 user1;
        uint256 user2;
        uint256 user3;
        address userAdd1;
        bool status1;
        bool status2;
    }
    
    mapping(address => data) public userData;
    
    function StructTest(dataStructure.dataStruct memory structData) public {
       userData[msg.sender].userAddress = structData.userAddress;
       userData[msg.sender].id = structData.id;
       userData[msg.sender].user1 = structData.user1;
       userData[msg.sender].user2 = structData.user2;
       userData[msg.sender].user3 = structData.user3;
       userData[msg.sender].userAdd1 = structData.userAdd1;
       userData[msg.sender].status1 = structData.status1;
       userData[msg.sender].status2 = structData.status2;
    }
    
    function StructTestLib(data memory structData) public {
       userData[msg.sender].userAddress = structData.userAddress;
       userData[msg.sender].id = structData.id;
       userData[msg.sender].user1 = structData.user1;
       userData[msg.sender].user2 = structData.user2;
       userData[msg.sender].user3 = structData.user3;
       userData[msg.sender].userAdd1 = structData.userAdd1;
       userData[msg.sender].status1 = structData.status1;
       userData[msg.sender].status2 = structData.status2;
    }
    
    function ParamTest(address userAddress,uint256 id,uint256 user1,uint256 user2,uint256 user3,address userAdd1,bool status1,bool status2) public {
       userData[msg.sender].userAddress = userAddress;
       userData[msg.sender].id = id;
       userData[msg.sender].user1 = user1;
       userData[msg.sender].user2 = user2;
       userData[msg.sender].user3 = user3;
       userData[msg.sender].userAdd1 = userAdd1;
       userData[msg.sender].status1 = status1;
       userData[msg.sender].status2 = status2;
    }
    
}