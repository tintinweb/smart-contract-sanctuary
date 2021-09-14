/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

contract ModuleProxyFactory {
    event ModuleProxyCreation(
        address indexed proxy,
        address indexed masterCopy
    );

    function createProxy(address target, bytes32 salt)
        internal
        returns (address result)
    {
        require(
            address(target) != address(0),
            "createProxy: address can not be zero"
        );
        bytes memory deployment = abi.encodePacked(
            hex"602d8060093d393df3363d3d373d3d3d363d73",
            target,
            hex"5af43d82803e903d91602b57fd5bf3"
        );
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := create2(0, add(deployment, 0x20), mload(deployment), salt)
        }
        require(result != address(0), "createProxy: address already taken");
    }

    function deployModule(
        address masterCopy,
        bytes memory initializer,
        uint256 saltNonce
    ) public returns (address proxy) {
        proxy = createProxy(
            masterCopy,
            keccak256(abi.encodePacked(keccak256(initializer), saltNonce))
        );
        (bool success, ) = proxy.call(initializer);
        require(success, "deployModule: initialization failed");

        emit ModuleProxyCreation(proxy, masterCopy);
    }
}