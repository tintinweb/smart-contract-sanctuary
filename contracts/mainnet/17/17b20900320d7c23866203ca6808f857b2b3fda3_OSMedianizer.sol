/**
 *Submitted for verification at Etherscan.io on 2021-03-14
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
        token = address(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
        OSM = OracleSecurityModule(0x8Df8f06DC2dE0434db40dcBb32a82A104218754c);
        MEDIANIZER = EACAggregatorProxy(0x547a514d5e3769680Ce22B2361c10Ea13619e8a9);
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