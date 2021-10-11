/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;
// pragma experimental ABIEncoderV2;

contract Contractnw {
    
    struct UserInfo{
    bytes32 name;
    uint256 phone;
    bytes32 email;
    }
        
    
    
    
    
    mapping(address => UserInfo ) public userInfo;
   

    function setUserInfo(bytes32 _name,
        uint256 _phone,
        bytes32 _email) public
        {
        userInfo[address(msg.sender)] = UserInfo({
            name: _name,
            email: _email,
            phone: _phone
        });
        }
    

    function getUserInfo(address _owner) public view returns (bytes32,uint256,bytes32) {

        return (userInfo[_owner].name,userInfo[_owner].phone,userInfo[_owner].email);
    }

}