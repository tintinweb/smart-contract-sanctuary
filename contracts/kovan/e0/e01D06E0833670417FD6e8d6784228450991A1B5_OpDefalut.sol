// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./OpCommon.sol";

contract OpDefalut is OpCommon {
    
    address public immutable accountIndex;

    event LogEnableUser(address indexed user);
    event LogDisableUser(address indexed user);
    event LogIndex(address indexed index);

    constructor(address _accountIndex) {
        accountIndex = _accountIndex;
    }

    receive() external payable {}

    function isAuth(address user) public view returns (bool) {
        return _auth[user];
    }

    function enable(address user) public {
        require(
            msg.sender == address(this) || msg.sender == accountIndex,
            "not-self-index"
        );
        require(user != address(0), "not-valid");
        require(!_auth[user], "already-enabled");
        _auth[user] = true;
        emit LogEnableUser(user);
    }

    function disable(address user) public {
        require(msg.sender == address(this), "not-self");
        require(user != address(0), "not-valid");
        require(_auth[user], "already-disabled");
        delete _auth[user];
        emit LogDisableUser(user);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0x150b7a02; // bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OpCommon {
    // auth is shared storage with AccountProxy and any OpCode.
    mapping(address => bool) internal _auth; 
}