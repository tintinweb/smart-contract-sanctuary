pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { Variables } from "../variables.sol";

interface IndexInterface {
    function list() external view returns (address);
}

interface ListInterface {
    function addAuth(address user) external;

    function removeAuth(address user) external;
}

contract Constants is Variables {
    uint256 public constant implementationVersion = 1;
    // InstaIndex Address.
    address public immutable instaIndex;
    // The Account Module Version.
    uint256 public constant version = 2;

    constructor(address _instaIndex) {
        instaIndex = _instaIndex;
    }
}

contract Record is Constants {
    constructor(address _instaIndex) Constants(_instaIndex) {}

    event LogEnableUser(address indexed user);
    event LogDisableUser(address indexed user);
    event LogBetaMode(bool indexed beta);

    /**
     * @dev Check for Auth if enabled.
     * @param user address/user/owner.
     */
    function isAuth(address user) public view returns (bool) {
        return _auth[user];
    }

    /**
     * @dev Check if Beta mode is enabled or not.
     */
    function isBeta() public view returns (bool) {
        return _beta;
    }

    /**
     * @dev Enable New User.
     * @param user Owner address
     */
    function enable(address user) public {
        require(
            msg.sender == address(this) || msg.sender == instaIndex,
            "not-self-index"
        );
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

    function toggleBeta() public {
        require(msg.sender == address(this), "not-self");
        _beta = !_beta;
        emit LogBetaMode(_beta);
    }

    /**
     * @dev ERC721 token receiver
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        return 0x150b7a02; // bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
    }

    /**
     * @dev ERC1155 token receiver
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external returns (bytes4) {
        return 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    }

    /**
     * @dev ERC1155 token receiver
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external returns (bytes4) {
        return 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
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
    // enable beta mode to access all the beta features.
    bool internal _beta;
}