// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import {Variables} from "../variables.sol";

interface IndexInterface {
    function list() external view returns (address);
}

interface ListInterface {
    function addAuth(address user) external;

    function removeAuth(address user) external;
}

contract Constants is Variables {
    uint256 public constant implementationVersion = 1;
    // StakeAllIndex Address.
    address public immutable stakeAllIndex;
    // The Account Module Version.
    uint256 public constant version = 2;

    constructor(address _stakeAllIndex) {
        stakeAllIndex = _stakeAllIndex;
    }
}

contract Record is Constants {
    constructor(address _stakeAllIndex) Constants(_stakeAllIndex) {}

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
        require(
            msg.sender == address(this) || msg.sender == stakeAllIndex,
            "not-self-index"
        );
        require(user != address(0), "not-valid");
        require(!_auth[user], "already-enabled");
        _auth[user] = true;
        ListInterface(IndexInterface(stakeAllIndex).list()).addAuth(user);
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
        ListInterface(IndexInterface(stakeAllIndex).list()).removeAuth(user);
        emit LogDisableUser(user);
    }
}

contract StakeAllDefaultImplementation is Record {
    constructor(address _stakeAllIndex) public Record(_stakeAllIndex) {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

contract Variables {
    // Auth Module(Address of Auth => bool).
    mapping(address => bool) internal _auth;

    // nonces chainId => nonces
    mapping(uint256 => uint256) internal _nonces;
}