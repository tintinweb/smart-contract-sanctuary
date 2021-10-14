/*
* SPDX-License-Identifier: UNLICENSED
* Copyright © 2021 Blocksquare d.o.o.
*/

pragma solidity ^0.6.12;

import "./Properties.sol";
import "./Ownable.sol";

interface PropertyFactoryHelpers {
    function hasSystemAdminRights(address sender) external view returns (bool);

    function addPropertyToCP(address prop, address cp) external;

    function isCertifiedPartner(address addr) external view returns (bool);
}

// @title Property Factory
contract PropertyFactory is Ownable {
    address private _dataProxy;
    address private _propertyRegistry;

    event NewPropToken(address indexed certifiedPartner, address indexed proptoken, uint256 createdAt);

    constructor(address dataProxy, address propertyRegistry) public {
        _dataProxy = dataProxy;
        _propertyRegistry = propertyRegistry;
    }

    function setDataProxy(address dataProxy) public onlyOwner {
        _dataProxy = dataProxy;
    }

    function setPropertyRegistry(address propertyRegistry) public onlyOwner {
        _propertyRegistry = propertyRegistry;
    }

    /// @notice create new property for Certified Partner
    /// @param certifiedPartner Wallet address of Certified Partner
    /// @return contract address of newly created property
    function createNewPropTokenFor(address certifiedPartner) public returns (address) {
        require(PropertyFactoryHelpers(_dataProxy).hasSystemAdminRights(msg.sender), "PropertiesFactory: You need to have system admin rights to issue new PropToken");
        require(PropertyFactoryHelpers(_dataProxy).isCertifiedPartner(certifiedPartner), "PropertiesFactory: You can only create property for certified partner!");
        Properties propToken = new Properties(certifiedPartner, _propertyRegistry);
        PropertyFactoryHelpers(_dataProxy).addPropertyToCP(address(propToken), certifiedPartner);

        emit NewPropToken(certifiedPartner, address(propToken), now);

        return address(propToken);
    }

    /// @notice create new property for Certified Partner and Licenced Issuer
    /// @param certifiedPartner Wallet address of Certified Partner
    /// @param LI Wallet address of Licenced Issuer
    /// @return contract address of newly created property
    function createNewPropTokenForCPAndLI(address certifiedPartner, address LI) public returns (address){
        require(PropertyFactoryHelpers(_dataProxy).hasSystemAdminRights(msg.sender), "PropertiesFactory: You need to have system admin rights to issue new PropToken");
        require(PropertyFactoryHelpers(_dataProxy).isCertifiedPartner(certifiedPartner), "PropertiesFactory: You can only create property for certified partner!");
        Properties propToken = new Properties(LI, _propertyRegistry);
        PropertyFactoryHelpers(_dataProxy).addPropertyToCP(address(propToken), certifiedPartner);

        emit NewPropToken(certifiedPartner, address(propToken), now);

        return address(propToken);
    }

    /// @notice get address of data proxy contract
    /// @return address of data proxy contract
    function getDataProxy() public view returns (address) {
        return _dataProxy;
    }

    /// @notice get address of property registry contract
    /// @return address of property registry contract
    function getPropertyRegistry() public view returns (address) {
        return _propertyRegistry;
    }


    /// @dev fallback function to prevent any ether to be sent to this contract
    receive() external payable {
        revert();
    }
}