/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

pragma solidity ^0.5.6;

contract ERCPayProfile {

    struct Profile{
        string name;
        string info;
    }
    
    mapping(address => Profile[]) public ProfileDB;
    
    function SetProfile(string memory _name, string memory _info) public {
        Profile memory NewProfile = Profile({
            name: _name,
            info: _info
        });
        ProfileDB[msg.sender].push(NewProfile);
    }
    
    function getProfileLength(address user) public view returns (uint){
        return (ProfileDB[user].length);
    }
}