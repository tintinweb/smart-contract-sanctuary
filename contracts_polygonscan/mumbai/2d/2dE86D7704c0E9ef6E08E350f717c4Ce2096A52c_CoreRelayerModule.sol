// SPDX-License-Identifier: GPL-3.0-onlly
pragma solidity ^0.8.4;

import "ECDSA.sol";

import "CoreBaseModule.sol";
import "IIdentity.sol";

contract CoreRelayerModule is CoreBaseModule {
    using ECDSA for bytes32;

    mapping(address => uint256) internal _nonces;

    event Executed(
        address indexed identity,
        bool indexed success,
        bytes result,
        bytes32 txHash
    );

    function getNonce(address identity) external view returns (uint256) {
        return _nonces[identity];
    }

    function executeWithoutRefund(
        address identity,
        bytes calldata data,
        bytes calldata sig
    ) external returns (bool) {
        bytes32 txHash = _getTxHash(
            identity,
            data,
            0,
            0,
            address(0),
            address(0)
        );

        address signer = txHash.toEthSignedMessageHash().recover(sig);

        require(
            signer == IIdentity(identity).owner(),
            "CoreRelayerModule: invalid signer"
        );

        _nonces[identity]++;

        (bool success, bytes memory result) = address(this).call(data);

        emit Executed(identity, success, result, txHash);

        return success;
    }

    function executeThroughIdentity(
        address identity,
        address to,
        uint256 value,
        bytes memory data
    ) external onlySelf onlyWhenUnlocked(identity) returns (bytes memory) {
        return IIdentity(identity).execute(to, value, data);
    }

    function _getTxHash(
        address identity,
        bytes memory data,
        uint256 gasPrice,
        uint256 gasLimit,
        address gasToken,
        address gasRelayer
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    bytes1(0x19),
                    bytes1(0x0),
                    block.chainid,
                    address(this),
                    address(identity),
                    _nonces[identity],
                    data,
                    gasPrice,
                    gasLimit,
                    gasToken,
                    gasRelayer
                )
            );
    }
}