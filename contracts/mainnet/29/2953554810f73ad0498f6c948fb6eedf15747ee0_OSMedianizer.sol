/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.6.12;

interface OracleSecurityModule {
    function peek() external view returns (uint256, bool);
    function peep() external view returns (uint256, bool);
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
        token = address(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e);
        OSM = OracleSecurityModule(0x208EfCD7aad0b5DD49438E0b6A0f38E951A50E5f);
        MEDIANIZER = EACAggregatorProxy(0xA027702dbb89fbd58938e4324ac03B58d812b0E1);
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
        if (authorized[msg.sender]) {
            return OSM.peek();
        }
        uint ans = uint(MEDIANIZER.latestAnswer());
        return (ans * 1e18 / 10**uint(MEDIANIZER.decimals()), false);
    }
    
    function foresight() external view returns (uint price, bool osm) {
        if (authorized[msg.sender]) {
            return OSM.peep();
        }
        uint ans = uint(MEDIANIZER.latestAnswer());
        return (ans * 1e18 / 10**uint(MEDIANIZER.decimals()), false);
    }
}