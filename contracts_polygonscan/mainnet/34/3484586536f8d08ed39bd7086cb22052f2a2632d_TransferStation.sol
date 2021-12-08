/**
 *Submitted for verification at polygonscan.com on 2021-12-08
*/

// File: contracts/libraries/TransferHelper.sol

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// File: contracts/TransferStation.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


contract TransferStation {
    address public owner;
    mapping(address => bool)public claimUsers;

    constructor(address[] memory users) public {
        owner = msg.sender;
        addClaimUsers(users);
    }

    modifier ownerOnly() {
        require(
            msg.sender == owner,
            "This function is restricted to the contract's owner"
        );
        _;
    }
    modifier claimUsersOnly() {
        require(
            claimUsers[msg.sender],
            "This function is restricted to the claimUsers"
        );
        _;
    }

    function addClaimUsers(address[] memory users) public ownerOnly {
        for (uint256 i = 0; i < users.length; i++) {
            claimUsers[users[i]] = true;
        }
    }

    function removeClaimUsers(address[] memory users) public ownerOnly {
        for (uint256 i = 0; i < users.length; i++) {
            claimUsers[users[i]] = false;
        }
    }

    function deposit(address token, uint256 amount) public {
        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            amount
        );
    }

    function withdraw(address token, uint256 amount) public claimUsersOnly {
        TransferHelper.safeTransfer(token, msg.sender, amount);
    }
}