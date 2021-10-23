// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract UserCrud {
    constructor() {
        totalUsers = 0;
    }

    struct user {
        string uuid;
        string accountType;
        uint devices;
    }

    user[] public users;

    uint public totalUsers;

    event UserEvent(string uuid, string accountType, uint devices);

    event AccountTypeUpdated(string uuid, string accountType);

    event UserDelete(string uuid);

    function insert(
        string memory uuid,
        string memory accountType,
        uint devices
    ) public returns (uint _totalUsers) {
        user memory newUser = user(uuid, accountType, devices);
        for(uint i = 0; i<totalUsers; i++) {
            if(compareStrings(users[i].uuid, uuid)) {
                revert('user with that uuid already exists');
            }
        }
        users.push(newUser);
        totalUsers++;
        emit UserEvent(uuid, accountType, devices);
        return totalUsers;
    }

    function updateAccountType(string memory uuid, string memory newAccountType)
        public
        returns (bool success)
    {
        for (uint i = 0; i < totalUsers; i++) {
            if (compareStrings(users[i].uuid, uuid)) {
                users[i].accountType = newAccountType;
                emit AccountTypeUpdated(uuid, newAccountType);
                return true;
            }
        }
        return false;
    }

    function deleteUser(string memory uuid) public returns (bool success) {
        require(totalUsers > 0, "No existing users to delete.");

        for (uint i = 0; i < totalUsers; i++) {
          if(compareStrings(users[i].uuid, uuid)) {
            users[i] = users[totalUsers-1];
            users.pop();
            totalUsers--;
            emit UserDelete(uuid);
            return true;
          }
        }
        return false;
    }

    function getUser(string memory _uuid) public view returns (string memory uuid, string memory accountType, uint devices) {
      for(uint i = 0; i<totalUsers; i++){
        if(compareStrings(users[i].uuid, _uuid)) {
          return(users[i].uuid, users[i].accountType, users[i].devices);
        }
      }
      revert('user not found');
    }

    function getUsers() external view returns (user[] memory) {
        return users;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encode(a)) == keccak256(abi.encode(b));
    }
}