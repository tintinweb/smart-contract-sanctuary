pragma solidity ^0.4.19;

contract storeData {
    
  struct User {
    uint256 id;
    bytes32 name;
    // other stuff

    bool set; // This boolean is used to differentiate between unset and zero struct values
}
mapping(address => User) public users;
function createUser(address _userAddress, uint256 _userId, bytes32 _userName) public {
    User storage user = users[_userAddress];
    // Check that the user did not already exist:
    require(!user.set);
    //Store the user
    users[_userAddress] = User({
        id: _userId,
        name: _userName,
        set: true
    });
    
}
mapping(uint256 => bytes32) public userDataHashes;
function storeUserDataHash(uint256 _userId, bytes32 _dataHash) public {
    userDataHashes[_userId] = _dataHash;
}
}