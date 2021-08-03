// SPDX-License-Identifier: GPL-3.0-onlly
pragma solidity ^0.8.4;

import "IERC1271.sol";
import "IERC721Receiver.sol";
import "IERC1155Receiver.sol";
import "ECDSA.sol";
import "IERC165.sol";

import "IStaticCallExecutor.sol";
import "IIdentity.sol";

contract StaticCallExecutor is IStaticCallExecutor {
    using ECDSA for bytes32;

    function supportsStaticCall(bytes4 methodID)
        external
        pure
        override
        returns (bool)
    {
        return
            methodID == IERC165.supportsInterface.selector ||
            methodID == IERC721Receiver.onERC721Received.selector ||
            methodID == IERC1155Receiver.onERC1155Received.selector ||
            methodID == IERC1155Receiver.onERC1155BatchReceived.selector ||
            methodID == IERC1271.isValidSignature.selector;
    }

    function supportsInterface(bytes4 interfaceID)
        external
        pure
        returns (bool)
    {
        return
            interfaceID == type(IERC165).interfaceId ||
            interfaceID == type(IERC721Receiver).interfaceId ||
            interfaceID == type(IERC1155Receiver).interfaceId ||
            interfaceID == type(IERC1271).interfaceId;
    }

    function onERC721Received(
        address, /* operator */
        address, /* from */
        uint256, /* tokenID */
        bytes calldata /* data */
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address, /* operator */
        address, /* from */
        uint256, /* id */
        uint256, /* value */
        bytes calldata /* data */
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, /* operator */
        address, /* from */
        uint256[] calldata, /* ids */
        uint256[] calldata, /* values */
        bytes calldata /* data */
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4)
    {
        require(
            signature.length == 65,
            "StaticCallExecutor: invalid signature length"
        );

        address signer = hash.recover(signature);

        require(
            signer == IIdentity(msg.sender).owner(),
            "StaticCallExecutor: invalid signer"
        );

        return IERC1271.isValidSignature.selector;
    }
}