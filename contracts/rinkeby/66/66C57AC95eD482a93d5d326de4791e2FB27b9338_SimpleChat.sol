/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <=0.9.9;

contract SimpleChat {
    
    struct User {
        string nickname;
    }
    
    mapping(address => User) public premiumUsers;

    event Message(uint timestamp, string message, address userAddress, string nickname);
    event PremiumUser(uint timestamp, string nickname, address userAddress);

    function buyPremium(string memory nickname_) public payable {
        if (msg.value != 5000000000000000)
            revert("Premium costs 0.05 ETH");
        
        premiumUsers[msg.sender] = User({
            nickname: nickname_
        });
        
        emit PremiumUser(block.timestamp, nickname_, msg.sender);
    }

    function isPremium(address user_) public view returns(bool) {
        if (compareStrings(premiumUsers[user_].nickname, "")) {
            return true;
        } else {
            return false;
        }
    }

    function sendMessage(string memory message_) public returns (bool) {
        if (compareStrings(message_, ""))
            revert("Message is empty");

        string memory nickname = premiumUsers[msg.sender].nickname;

        if (compareStrings(nickname, "")) {
            emit Message(block.timestamp, message_, msg.sender, "");
        } else {
            emit Message(block.timestamp, message_, msg.sender, nickname);
        }

        return true;
    }
    
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}