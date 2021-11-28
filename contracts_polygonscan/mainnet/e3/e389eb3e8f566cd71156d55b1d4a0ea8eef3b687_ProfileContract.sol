/**
 *Submitted for verification at polygonscan.com on 2021-11-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract ProfileContract {

    struct Profile {
        string firstName;
        string lastName;
        uint32 dob;
        string message;
        address[] addresses;
    }

    Profile[] profiles;
    mapping(address => uint256) public address_mapping;

    function createProfile(string memory _firstName, string memory _lastName, uint32 _dob, string memory _message, address _initializer) public {
        address[] memory _addresses = new address[](1);
        _addresses[0] = _initializer;

        Profile memory profile = Profile(_firstName,_lastName,_dob,_message,_addresses);
        profiles.push(profile);
        
        address_mapping[_initializer] = profiles.length - 1;
    }

    function getProfile(uint256 profile_id) public view returns (Profile memory) {
        return profiles[profile_id];
    }
}