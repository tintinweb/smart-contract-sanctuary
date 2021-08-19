// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./Ownable.sol";

contract LinkBSCOracleTest is Ownable {
    
    address[] OraclesAddress;
    uint OracleId;
    mapping (address => string) public Oracles;
    mapping (address => uint) OracleToId;
    mapping (uint => address) IdToOracle;
    
    function create(string memory pair_name, address oracle_addr) public onlyOwner {
        Oracles[oracle_addr] = pair_name;
    }
    
    function readAll() public returns(address[] memory) {
        delete OraclesAddress;
        
        for(uint i = 1; i <= OracleId ; i++){
            address OracleAddr = IdToOracle[i];
            OraclesAddress.push(OracleAddr);
        }
        
        return OraclesAddress;
    }
    
    function update (string memory pair_name, address oracle_addr) public onlyOwner returns(bool) {
        require(OracleToId[oracle_addr] != 0 ,"Can not find oracle_addr");
        Oracles[oracle_addr] = pair_name;
        
        return true;
    }

    function deletes(address oracle_addr) public onlyOwner returns(bool) {
        delete Oracles[oracle_addr];
        return true;
    }
    
}