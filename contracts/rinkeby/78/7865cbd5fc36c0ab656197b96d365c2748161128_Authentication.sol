/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma experimental ABIEncoderV2;
contract Authentication {
    struct UserInformation {
        address addres;
        string name;
        string password;
        string CNIC;
        bool isUserLoggedIn;
    }

    mapping(address => UserInformation) user;
    address []  addresses;
    function StoreInformation(address _address,string memory _name,
                              string memory _password,string memory _cnic) public returns (bool) 
    {
        if(keccak256(abi.encodePacked(user[_address].addres)) ==
            keccak256(abi.encodePacked(_address))) 
        {
            return false;
        }
        else
        {
            require(user[_address].addres != msg.sender);
            addresses.push(address(_address));
            user[_address].addres = _address;
            user[_address].name = _name;
            user[_address].password = _password;
            user[_address].CNIC = _cnic;
            user[_address].isUserLoggedIn = false;
            return true;
        }
    }
    function arr() public view returns(address[] memory)
    {
        return addresses;
    }
    function login(address _address, string memory _password) public returns (bool)
    {
        if (keccak256(abi.encodePacked(user[_address].password)) ==
            keccak256(abi.encodePacked(_password)) && keccak256(abi.encodePacked(user[_address].addres)) ==
            keccak256(abi.encodePacked(_address)) ) 
        {
            user[_address].isUserLoggedIn = true;
            return user[_address].isUserLoggedIn;
        } 
        else 
        {
            return false;
        }
    }

    function IsUserLoggedIn(address _address) public view returns (bool) 
    {
        return (user[_address].isUserLoggedIn);
    }

    function RetrieveInformation(address _address) public view returns (UserInformation memory) 
    {
        return user[_address];
    }

    function logout(address _address) public 
    {
        user[_address].isUserLoggedIn = false;
    }
}