// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

interface Medianizer {
    function read() external view returns (bytes32);
}
interface OracleSecurityModule {
    function peek() external view returns (bytes32,bool);
    function peep() external view returns (bytes32,bool);
    function bud(address) external view returns (uint256);
}

contract OSMedianizer {
    
    
    mapping(address => bool) public authorized;
    address public governance;
    
    OracleSecurityModule constant public OSM = OracleSecurityModule(0x81FE72B5A8d1A857d176C3E7d5Bd2679A9B85763);
    Medianizer constant public MEDIANIZER = Medianizer(0x729D19f657BD0614b4985Cf1D82531c67569197B);
    
    constructor() public {
        governance = msg.sender;
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
          if (OSM.bud(address(this))==1) {
              (bytes32 _val,) = OSM.peek(); 
              return (uint(_val),true);
          }
        }
        return (uint(MEDIANIZER.read()),false);
    }
    
    function foresight() external view returns (uint price, bool osm) {
        if (authorized[msg.sender]) {
          if (OSM.bud(address(this))==1) {
              (bytes32 _val,) = OSM.peep(); 
              return (uint(_val),true);
          }
        }
        return (uint(MEDIANIZER.read()),false);
    }
}