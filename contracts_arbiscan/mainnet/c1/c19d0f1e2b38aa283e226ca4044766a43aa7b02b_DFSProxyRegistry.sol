/**
 *Submitted for verification at arbiscan.io on 2021-10-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


abstract contract IProxyRegistry {
    function proxies(address _owner) public virtual view returns (address);
    function build(address) public virtual returns (address);
}

/// @title Checks Mcd registry and replaces the proxy addr if owner changed
contract DFSProxyRegistry {
    IProxyRegistry public mcdRegistry = IProxyRegistry(0x283Cc5C26e53D66ed2Ea252D986F094B37E6e895);

    mapping(address => address) public changedOwners;
    mapping(address => address[]) public additionalProxies;


    /// @notice Returns the proxy address associated with the user account
    /// @dev If user changed ownership of Dsproxy admin can hardcode replacement
    function getMcdProxy(address _user) public view returns (address) {
        address proxyAddr = mcdRegistry.proxies(_user);

        return proxyAddr;
    }


    function getAllProxies(address _user) public view returns (address, address[] memory) {
        return (getMcdProxy(_user), additionalProxies[_user]);
    }
}