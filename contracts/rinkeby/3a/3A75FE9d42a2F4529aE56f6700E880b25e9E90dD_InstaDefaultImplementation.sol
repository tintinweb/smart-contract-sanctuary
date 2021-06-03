pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { Variables } from "./variables.sol";

interface IndexInterface {
    function list() external view returns (address);
}

interface ListInterface {
    function addAuth(address user) external;
    function removeAuth(address user) external;
}

contract Constants is Variables {
    uint public constant implementationVersion = 1;
    // InstaIndex Address.
    address public immutable instaIndex;
    // The Account Module Version.
    uint public constant version = 2;

    constructor(address _instaIndex) {
        instaIndex = _instaIndex;
    }
}

contract Record is Constants {
    constructor(address _instaIndex) Constants(_instaIndex) {}

    event LogEnableUser(address indexed user);
    event LogDisableUser(address indexed user);

    /**
     * @dev Check for Auth if enabled.
     * @param user address/user/owner.
     */
    function isAuth(address user) public view returns (bool) {
        return _auth[user];
    }

    /**
     * @dev Enable New User.
     * @param user Owner address
    */
    function enable(address user) public {
        require(msg.sender == address(this) || msg.sender == instaIndex, "not-self-index");
        require(user != address(0), "not-valid");
        require(!_auth[user], "already-enabled");
        _auth[user] = true;
        ListInterface(IndexInterface(instaIndex).list()).addAuth(user);
        emit LogEnableUser(user);
    }

    /**
     * @dev Disable User.
     * @param user Owner address
    */
    function disable(address user) public {
        require(msg.sender == address(this), "not-self");
        require(user != address(0), "not-valid");
        require(_auth[user], "already-disabled");
        delete _auth[user];
        ListInterface(IndexInterface(instaIndex).list()).removeAuth(user);
        emit LogDisableUser(user);
    }

}

contract InstaDefaultImplementation is Record {

    constructor(address _instaIndex) public Record(_instaIndex) {}

    receive() external payable {}
}

pragma solidity ^0.7.0;

contract Variables {
    // Auth Module(Address of Auth => bool).
    mapping (address => bool) internal _auth;
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}