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
        token = address(0xc00e94Cb662C3520282E6f5717214004A7f26888);
        OSM = OracleSecurityModule(0xBED0879953E633135a48a157718Aa791AC0108E4);
        MEDIANIZER = EACAggregatorProxy(0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5);
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