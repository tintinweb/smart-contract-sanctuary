// SPDX-License-Identifier: MIT
import "./AuthenticatedProxy.sol";
import "./ProxyRegistry.sol";

pragma solidity ^0.8.0;

contract WyvernProxyRegistry is ProxyRegistry {

    string public constant name = "Project Wyvern Proxy Registry";

    /* Whether the initial auth address has been set. */
    bool public initialAddressSet = false;

    constructor ()
    {
        delegateProxyImplementation = address(new AuthenticatedProxy());
    }

    /**
     * Grant authentication to the initial Exchange protocol contract
     *
     * @dev No delay, can only be called once - after that the standard registry process with a delay must be used
     * @param authAddress Address of the contract to grant authentication
     */
    function grantInitialAuthentication (address authAddress)
    onlyOwner
    public
    {
        require(!initialAddressSet);
        initialAddressSet = true;
        contracts[authAddress] = true;
    }
}