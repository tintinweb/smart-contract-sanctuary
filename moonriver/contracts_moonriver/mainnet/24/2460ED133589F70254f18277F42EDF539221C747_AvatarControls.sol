pragma solidity >=0.5.0 <0.6.0;

import "./AvatarLibrary.sol";

contract AvatarControls {

    using AvatarLibrary for AvatarLibrary.AvatarStorage;
    AvatarLibrary.AvatarStorage avatars;

    event New(string _name);
    function createAvatar(string memory name) public {
        avatars.createAvatar(name);
        emit New(name);
    }

    function getAvatarCount() external view returns(uint) {
        return avatars.getAvatarCount();
    }

    function getAvatarIdByAddress(address owner) public view returns(uint) {
        return avatars.getAvatarIdByAddress(owner);
    }

    function getAvatarNameById(uint id) public view returns(string memory) {
        return avatars.getAvatarNameById(id);
    }

    function getAvatarNameByAddress(address owner) public view returns(string memory) {
        return avatars.getAvatarNameByAddress(owner);
    }

    function getMyAvatarId() public view returns(uint) {
        return avatars.getAvatarIdByAddress(msg.sender);
    }

    function getMyAvatarName() public view returns(string memory) {
        return avatars.getAvatarNameByAddress(msg.sender);
    }

    function getMyAvatarSector() public pure returns(uint) {
        // todo: has to look at other contract
        uint test = 1;
        return test;
    }

    function getMyAvatarShipId() public pure returns(uint) {
        // todo: has to look at other contract
        uint shipid = 1;
        return shipid;
    }

    function hasAvatar(address owner) public view returns(bool) {
        return avatars.hasAvatar(owner);
    }

    function haveAvatar() public view returns(bool) {
        return avatars.hasAvatar(msg.sender);
    }

}

pragma solidity >=0.5.0 <0.6.0;

library AvatarLibrary {

    struct Avatar {
        string name;
    }

    struct AvatarStorage {
        Avatar[] avatars;
        mapping (address => uint) addressToAvatar;
        mapping (address => bool) wasCreated;
    }

    function createAvatar(AvatarStorage storage self, string memory name) internal {
        require(self.wasCreated[msg.sender] == false, 'You already have an avatar.');
        uint id = self.avatars.push(
            Avatar(
                name
            )
        ) - 1;
        self.addressToAvatar[msg.sender] = id;
        self.wasCreated[msg.sender] = true;
    }

    function getAvatarCount(AvatarStorage storage self) public view returns (uint) {
        return self.avatars.length;
    }

    function getAvatarIdByAddress(AvatarStorage storage self, address owner) public view returns(uint) {
        //require (self.wasCreated[owner], 'Not an avatar.');
        return self.addressToAvatar[owner];
    }

    function getAvatarNameById(AvatarStorage storage self, uint id) public view returns (string memory) {
        return self.avatars[id].name;
    }

    function getAvatarNameByAddress(AvatarStorage storage self, address owner) public view returns (string memory) {
        //require (self.wasCreated[owner], 'Not an avatar.');
        uint avatarId = self.addressToAvatar[owner];
        return self.avatars[avatarId].name;
    }

    function hasAvatar(AvatarStorage storage self, address owner) public view returns (bool) {
        return self.wasCreated[owner];
    }
}