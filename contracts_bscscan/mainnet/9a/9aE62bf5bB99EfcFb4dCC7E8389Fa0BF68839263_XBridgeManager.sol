//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./XBridge.sol";


/// @title XBridgeManager for XBridges
/// @author Markymark (SafemoonMark) & Gabriel Willen (Useless Surgeon)
/// @notice XBridgeManager is responsible for the creation and verification of XBridges
contract XBridgeManager {

    using Address for address;

    /// @notice maps personal address to XBridge address
    mapping (address => address) XBridges;
    /// @notice mapping for storing verified XBridges
    mapping (address => bool) isVerified;
    /// @notice notifies blockchain that a XBridge was created
    event CreateXBridge(address newContract, address contractOwner);
    /// @notice this is the private address of the single deployed XBridge that proxies are created from
    address private proxyableXBridge = address(0);

    /// @notice this prevents calls to createProxy in the event the main XBridge hasn't been deployed
    modifier isProxyableXBridgeDeployed () {
        require(proxyableXBridge != address(0), "Missing address to deployed PesrsonalContract");
        _;
    }

    /// @notice Points the XBridgeManager to the deployed XBridge only can be called once.
    function lockProxyableXBridgeAddress(address deployedXBridge) external {
        require(proxyableXBridge == address(0), "Deployed XBridge address is locked");
        proxyableXBridge = deployedXBridge;
    }

    /// @notice Creates a XBridge for this public address
    function createXBridge(address publicKey) external isProxyableXBridgeDeployed returns (address) {
        // If this is called without an address than it creates a bridge for the sender
        if (publicKey == address(0)) publicKey = payable(msg.sender);
        require(XBridges[publicKey] == address(0), 'Private Bridge already created for this address');
        // Create new Private Contract
        address pContract = XBridge(payable(proxyableXBridge)).createProxy();
        // set this before init to protect against any recursion
        isVerified[pContract] = true;
        // initialize proxy
        XBridge(payable(pContract)).bind(publicKey);
        // Verify New Personal Bridge
        XBridges[publicKey] = pContract;
        emit CreateXBridge(pContract, publicKey);
        return pContract;
    }

    /// @notice Gets the XBridge for this personal address
    /// @return The address of the XBridge if one exists
    function getXBridgeAddress(address personalAddress) public view returns(address) {
        return XBridges[personalAddress];
    }

    /// @notice Verifies the address is a XBridge
    /// @return true if the address is a XBridge
    function isXBridge(address potentialBridge) public view returns(bool) {
        return isVerified[potentialBridge];
    }

}