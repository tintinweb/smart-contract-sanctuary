pragma solidity ^0.7.4;
// "SPDX-License-Identifier: Apache License 2.0"

import "./Bridge.sol";

contract BridgeDeployer {
    
    address public _addressVAL;
    address public _addressXOR;
    bytes32 public _networkId;
    address[] public _initialPeers;
    Bridge public _bridge;
    
    event NewBridgeDeployed(address bridgeAddress);

    /**
     * Constructor.
     * @param initialPeers - list of initial bridge validators on substrate side.
     * @param addressVAL address of VAL token Contract
     * @param addressXOR address of XOR token Contract
     * @param networkId id of current EVM network used for bridge purpose.
     */
    constructor(
        address[] memory initialPeers,
        address addressVAL,
        address addressXOR,
        bytes32 networkId)  {
        _initialPeers = initialPeers;
        _addressXOR = addressXOR;
        _addressVAL = addressVAL;
        _networkId = networkId;
    }
    
    function deployBridgeContract() public {
        _bridge = new Bridge(_initialPeers, _addressVAL, _addressXOR, _networkId);
        
        emit NewBridgeDeployed(address(_bridge));
    } 
}