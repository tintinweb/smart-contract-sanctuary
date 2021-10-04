/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

pragma experimental ABIEncoderV2;

contract Register {
    event NewProfile(
        string lastname,
        string firstname,
        address indexed from,
        uint256 indexed userId
    );
    struct Profile {
        string lastname;
        string firstname;
        uint256 userId;
    }
    mapping(address => Profile) public Profiles;
    mapping(address => uint256) public ProfileIds;
    uint256 public REGISTRATION_FEE = 0.01 ether;
    uint256 public profileId;
    address owner;

    constructor()  {
        owner = msg.sender;
    }
    function createProfile (string calldata lastname, string calldata firstname) external payable {
        require(ProfileIds[msg.sender] == 0, "Profile has been added");
        require(msg.value == REGISTRATION_FEE, "You must send 0.01 ETH to register");
        profileId++;
        Profile memory profile = Profile(lastname, firstname, profileId);
        Profiles[msg.sender] = profile;
        ProfileIds[msg.sender] = profileId;
        emit NewProfile(lastname, firstname, msg.sender, profileId);
    }
    function getProfile(address user) external view returns(Profile memory) {
        Profile memory profile = Profiles[user];
        return profile;
    }
    function delteMyProfile () external {
        delete Profiles[msg.sender];
        delete ProfileIds[msg.sender];
    }
    function deleteProfle (address user) onlyOwner external {
        delete Profiles[user];
        delete ProfileIds[user];
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}