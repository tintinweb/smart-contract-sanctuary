// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./OpCommon.sol";

contract OpDefalut is OpCommon {

    event EnableUser(address indexed user);
    event DisableUser(address indexed user);
    event SetAccountCenter(address indexed index);

    function setAccountCenter(address _accountCenter) public {
        require(accountCenter == address(0) || msg.sender == accountCenter, "CHFRY/OpDefalut: Not Auth to set accountCenter");
        accountCenter = _accountCenter;
        emit SetAccountCenter(accountCenter);
    }

    function isAuth(address user) public view returns (bool) {
        return _auth[user];
    }

    function enable(address user) public {
        require(
            msg.sender == address(this) || msg.sender == accountCenter,
            "CHFRY/OpDefalut: eble() not SmartAccount itself or accountCenter"
        );
        require(user != address(0), "CHFRY/OpDefalut: EOA address can not be 0");
        require(!_auth[user], "CHFRY/OpDefalut: Already Enabled");
        _auth[user] = true;
        emit EnableUser(user);
    }

    function disable(address user) public {
        require(msg.sender == address(this), "CHFRY/OpDefalut: disable() not SmartAccount itself ");
        require(user != address(0), "CHFRY/OpDefalut: EOA address can not be 0");
        require(_auth[user], "CHFRY/OpDefalut: Already Disabled");
        delete _auth[user];
        emit DisableUser(user);
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
    address internal accountCenter;
    
    receive() external payable {}
}