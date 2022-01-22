// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

contract NidhiProfile {

    struct Profile {
        string name;
        string imageURL;
        string deeplink;
        string description;
        string url;
        string twitter;
        string instagram;
        string medium;
    }

    mapping (address => Profile) public userProfiles;
    mapping (string => address) public deeplinkToAddress;

    function update(Profile memory profile)
        external validDeeplink(profile.deeplink)
    {
        address owner = msg.sender;
        string storage currentDeeplink = userProfiles[owner].deeplink;
        if (bytes(currentDeeplink).length != 0) {
            delete deeplinkToAddress[currentDeeplink];
            deeplinkToAddress[profile.deeplink] = owner;
        } else if (bytes(profile.deeplink).length != 0) {
            deeplinkToAddress[profile.deeplink] = owner;
        }
        userProfiles[owner] = profile;
    }

    function remove() external {
        delete deeplinkToAddress[userProfiles[msg.sender].deeplink];
        delete userProfiles[msg.sender];
    }

    function nameOf(address owner) external view returns (string memory) {
        return userProfiles[owner].name;
    }

    function deeplinkOf(address owner) external view returns (string memory) {
        return userProfiles[owner].deeplink;
    }

    modifier validDeeplink(string memory deeplink) {
        if (bytes(deeplink).length != 0) {
            address currentAddress = deeplinkToAddress[deeplink];
            require(
                currentAddress == address(0) || currentAddress == msg.sender,
                "deeplink already in use"
            );
        }
        _;
    }
}