// SPDX-License-Identifier: GPL-3.0-onlly
pragma solidity ^0.8.4;

import "IIdentity.sol";
import "Proxy.sol";

contract IdentityProxyFactory {
    address public immutable identityImplementation;

    event ProxyCreated(address indexed proxy);

    constructor(address identityImpl) {
        require(
            identityImpl != address(0),
            "IdentityProxyFactory: identity implementation is zero address"
        );

        identityImplementation = identityImpl;
    }

    function getProxyAddress(bytes32 salt) external view returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                salt,
                                keccak256(
                                    abi.encodePacked(
                                        type(Proxy).creationCode,
                                        uint256(uint160(identityImplementation))
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }

    function createProxy(address owner, bytes32 salt)
        external
        returns (address)
    {
        address payable proxy = payable(
            new Proxy{salt: salt}(identityImplementation)
        );

        IIdentity(proxy).init(owner);

        emit ProxyCreated(proxy);

        return proxy;
    }
}