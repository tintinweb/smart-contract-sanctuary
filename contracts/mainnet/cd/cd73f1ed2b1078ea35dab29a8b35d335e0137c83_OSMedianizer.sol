/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.6.12;

interface OracleSecurityModule {
    function peek() external view returns (uint256, bool);
    function peep() external view returns (uint256, bool);
    function bud(address) external view returns (uint256);
}

interface EACAggregatorProxy {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (int256);
}

contract OSMedianizer {
    mapping(address => bool) public authorized;
    address public governance;
    address public token;

    OracleSecurityModule public OSM;
    EACAggregatorProxy public MEDIANIZER;
    
    constructor() public {
        governance = msg.sender;
        token = address(0x514910771AF9Ca656af840dff83E8264EcF986CA);
        OSM = OracleSecurityModule(0x9B0C694C6939b5EA9584e9b61C7815E8d97D9cC7);
        MEDIANIZER = EACAggregatorProxy(0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c);
    }
    
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
    
    function setAuthorized(address _authorized) external {
        require(msg.sender == governance, "!governance");
        authorized[_authorized] = true;
    }
    
    function revokeAuthorized(address _authorized) external {
        require(msg.sender == governance, "!governance");
        authorized[_authorized] = false;
    }
    
    function read() external view returns (uint price, bool osm) {
        if (authorized[msg.sender] && OSM.bud(address(this)) == 1) {
            (price, osm) = OSM.peek();
            if (osm) return (price, true);
        }
        return (uint(MEDIANIZER.latestAnswer()) * 1e10, false);
    }
    
    function foresight() external view returns (uint price, bool osm) {
        if (authorized[msg.sender] && OSM.bud(address(this)) == 1) {
            (price, osm) = OSM.peep();
            if (osm) return (price, true);
        }
        return (uint(MEDIANIZER.latestAnswer()) * 1e10, false);
    }
}