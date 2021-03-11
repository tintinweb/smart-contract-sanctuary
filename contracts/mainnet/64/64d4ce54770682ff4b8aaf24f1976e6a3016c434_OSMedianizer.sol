/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.6.12;

interface OracleSecurityModule {
    function read() external view returns (uint256, bool);
    function foresight() external view returns (uint256, bool);
}

interface EACAggregatorProxy {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (int256);
}

contract OSMedianizer {
    address public token;
    OracleSecurityModule public OSM;
    EACAggregatorProxy public MEDIANIZER;
    
    constructor() public {
        token = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
        OSM = OracleSecurityModule(0x82c93333e4E295AA17a05B15092159597e823e8a);
        MEDIANIZER = EACAggregatorProxy(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);
    }
    
    function read() external view returns (uint price, bool osm) {
        (price, osm) = OSM.read();
        if (!osm) {
            osm = false;
            uint ans = uint(MEDIANIZER.latestAnswer());
            price = ans * 1e18 / 10**uint(MEDIANIZER.decimals());
        }
    }
    
    function foresight() external view returns (uint price, bool osm) {
        (price, osm) = OSM.foresight();
        if (!osm) {
            osm = false;
            uint ans = uint(MEDIANIZER.latestAnswer());
            price = ans * 1e18 / 10**uint(MEDIANIZER.decimals());
        }
    }
}