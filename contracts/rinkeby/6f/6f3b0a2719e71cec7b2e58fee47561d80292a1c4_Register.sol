/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

pragma solidity ^0.5.16;

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
}