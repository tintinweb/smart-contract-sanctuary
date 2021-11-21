// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./KeyManager.sol";
import "./ERC725.sol";

contract Registry is KeyManager, ERC725 {

    event Registration(address userAddress);
    event Deregistration(address userAddress);
    event KeyChanged(address userAddress);
    
    mapping (address => UserRegistry) public usersAll;
    address[] public userAccounts;
    uint public indexUser;

    bytes32 domainBytes;
    bytes32 userNotesBytes;

    // attributes
    struct UserRegistry { 
        //string domain;
        bytes32 domain;
        //string userNotes;
        bytes32 userNotes;
        uint userSince;
        uint userIndex;
        bytes32 key;
    }
    
    // this function is copied from https://ethereum.stackexchange.com/questions/9142/how-to-convert-a-string-to-bytes32
    // to make it possible to use ERC725 functions
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    // Registration 
    function addUser(address _userAddress, string memory _domain, string memory _userNotes, bytes32 _key) public {
        require(usersAll[_userAddress].userSince == 0, "User already exists");
        // adding the key for KeyManager
        KeyManager.addKey(_key, 1, 1);
        // using ERC725 for the domain value
        ERC725.setData(_key, stringToBytes32(_domain));
        domainBytes = ERC725.getData(_key);
        ERC725.setData(stringToBytes32(_domain), stringToBytes32(_userNotes));
        userNotesBytes = ERC725.getData(stringToBytes32(_domain));
        
        usersAll[_userAddress] = UserRegistry(
            {
                domain: keccak256(abi.encode(domainBytes)),                                                    
                userNotes: keccak256(abi.encode(userNotesBytes)),                                                                           
                userSince: block.timestamp,
                userIndex: indexUser,
                key: KeyManager.getKey(_key)
            });

        userAccounts.push(_userAddress);
        indexUser++;
        // addUser function triggers the event "Registration"
        emit Registration(_userAddress);
    }

    // KeyChanged
    function KeyRotation(address _userAddress, bytes32 _newKey) public {
        // deleting the old key for KeyManager
        KeyManager.removeKey(usersAll[_userAddress].key); 
        // deleting the old Key from UserRegistry struct
        delete usersAll[_userAddress].key;
        // adding the new key
        KeyManager.addKey(_newKey, 1, 1);
        
        usersAll[_userAddress] = UserRegistry(
            {
                domain: usersAll[_userAddress].domain,                //tum.de
                userNotes: usersAll[_userAddress].userNotes,          //university
                userSince: usersAll[_userAddress].userSince,
                userIndex: usersAll[_userAddress].userIndex,
                key: KeyManager.getKey(_newKey)
            });

        // KeyRotation triggers the event "KeyChanged"    
        emit KeyChanged(_userAddress);
    }

    // Getting user data
    function getUser(address _userAddress) public view returns (bytes32 _domain, bytes32 _userNotes, uint _userSince, bytes32 _key) {
        return (usersAll[_userAddress].domain, usersAll[_userAddress].userNotes, usersAll[_userAddress].userSince, usersAll[_userAddress].key);
    }

    // Deregistration
    function removeUser(address _userAddress) public {
        require(usersAll[_userAddress].userSince != 0, "User does not exist");
        // deleting address from userAccounts
        delete userAccounts[usersAll[_userAddress].userIndex];
        // copy last item to the just deleted address
        userAccounts[usersAll[_userAddress].userIndex] = userAccounts[userAccounts.length - 1]; 

        UserRegistry storage user = usersAll[userAccounts[usersAll[_userAddress].userIndex]]; 
        // update the userIndex of the corresponding user struct of moved item
        user.userIndex = usersAll[_userAddress].userIndex; 
        // remove the last item (same as the moved one)
        userAccounts.pop(); 
        // delete user from mapping
        delete usersAll[_userAddress]; 
        indexUser--;
        // removeUser function triggers the event "Deregistration"
        emit Deregistration(_userAddress);
    }

    // get a list of users' addresses
    function getUsers() public view returns (address[] memory){
        return userAccounts;
    }

}