/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.0;
abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    
    // mo meed to specfy internal in constructor as contract is abstract 
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract UserStorage is Context {
    
    struct User {
        address userAddress;
        string userType;
    }
    User[] private users;

    mapping(address => uint) private indexOf;
    
    function createUser(string calldata userType) external {
        require(indexOf[_msgSender()] == 0, "Error: User is already registered");
        User memory user = User(_msgSender(), userType);
        users.push(user);
        indexOf[_msgSender()] = users.length;
    }
    
    function isRegistered(address userAddress) public view returns(bool){
        if(indexOf[userAddress] != 0) {
            return true;
        } else {
            return false;
        }
    }
    
    function getUserType(address userAddress) public view returns(string memory){
        require(indexOf[userAddress] != 0, "ERROR: User is not registered");
        return users[indexOf[userAddress] - 1].userType;
    }
}