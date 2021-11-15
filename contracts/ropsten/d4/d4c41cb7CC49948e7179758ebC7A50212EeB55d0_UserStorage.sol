// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./Owned.sol";

contract BaseStorage is Owned {
    address public controllerAddr;

    modifier onlyController() {
        require(msg.sender == controllerAddr);
        _;
    }

    function setControllerAddr(address _controllerAddr) public onlyOwner {
        controllerAddr = _controllerAddr;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

contract Owned {
    address payable public ownerAddr;
    address payable public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        ownerAddr = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddr);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        // The new address cannot be null:
        require(_newOwner != address(0));

        ownerAddr = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(ownerAddr, newOwner);
        ownerAddr = newOwner;
        newOwner = payable(address(0));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "../helpers/BaseStorage.sol";

contract UserStorage is BaseStorage {
    struct Profile {
        uint256 id;
        bytes32 username;
        bytes32 firstName;
        bytes32 lastName;
        string bio;
        string gravatarEmail;
    }

    mapping(uint256 => Profile) public profiles;
    mapping(address => uint256) public addresses;
    mapping(bytes32 => uint256) public usernames;

    uint256 latestUserId = 0;

    function createUser(
        address _address,
        bytes32 _username,
        bytes32 _firstName,
        bytes32 _lastName,
        string memory _bio,
        string memory _gravatarEmail
    ) public onlyController returns (uint256) {
        latestUserId++;

        profiles[latestUserId] = Profile(
            latestUserId,
            _username,
            _firstName,
            _lastName,
            _bio,
            _gravatarEmail
        );

        addresses[_address] = latestUserId;
        usernames[_username] = latestUserId;

        return latestUserId;
    }

    // This is redundant becuase we have defined public on the profiles variable. So an automatic getter is specified on the profiles by solidity by default
    // function getUserFromId(uint256 _userId)
    //     public
    //     view
    //     returns (uint256, bytes32)
    // {
    //     return (profiles[_userId].id, profiles[_userId].username);
    // }
}

