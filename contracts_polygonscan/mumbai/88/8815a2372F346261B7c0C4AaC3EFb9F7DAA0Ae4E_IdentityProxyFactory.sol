// SPDX-License-Identifier: GPL-3.0-onlly
pragma solidity ^0.8.4;

import "IIdentity.sol";
import "Proxy.sol";

contract IdentityProxyFactory {
    address public immutable identityImplementation;

    mapping(bytes32 => address) internal _reserves;

    event ProxyReserved(address indexed reserver, bytes32 saltHash);
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

    function isProxyReserved(bytes32 saltHash) external view returns (bool) {
        return _reserves[saltHash] != address(0);
    }

    function reserveProxy(bytes32 saltHash) external {
        require(
            _reserves[saltHash] == address(0),
            "IdentityProxyFactory: proxy already reserved"
        );

        _reserves[saltHash] = msg.sender;

        emit ProxyReserved(msg.sender, saltHash);
    }

    function createProxy(address owner, bytes32 salt)
        external
        returns (address)
    {
        address reserver = _reserves[keccak256(abi.encodePacked(salt))];

        require(
            reserver == address(0) || reserver == msg.sender,
            "IdentityProxyFactory: caller is not reserver"
        );

        address payable proxy = payable(
            new Proxy{salt: salt}(identityImplementation)
        );

        IIdentity(proxy).init(owner);

        emit ProxyCreated(proxy);

        return proxy;
    }
}