// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./Ownable.sol";

contract LinkBSCOracleTest is Ownable {
    
    uint OracleId;
    mapping (address => string) public Oracles;
    mapping (string => address) public Pairs;
    mapping (address => uint) OracleToId;
    mapping (uint => address) IdToOracle;
    
    struct Oracle {
       address OracleAddr;       
       string OracleStr;
    }
    
    function addOracles(string[] memory pairs_name, address[] memory oracles_addr) public onlyOwner returns(bool) {
        for(uint i = 0; i <= oracles_addr.length ; i++) {
            string memory pair_name = pairs_name[i];
            address oracle_addr = oracles_addr[i];
            OracleId++;
            IdToOracle[OracleId] = oracle_addr;
            OracleToId[oracle_addr] = OracleId;
            Oracles[oracle_addr] = pair_name;
            Pairs[pair_name] = oracle_addr;
        }
        
        return true;
    }
    
    function addOracle(string memory pair_name, address oracle_addr) public onlyOwner returns(bool) {
        OracleId++;
        IdToOracle[OracleId] = oracle_addr;
        OracleToId[oracle_addr] = OracleId;
        Oracles[oracle_addr] = pair_name;
        Pairs[pair_name] = oracle_addr;
        
        return true;
    }
    
    function getOracles(bool param) public view returns(Oracle[] memory OraclesArray) {
        require(param == true ,"Need param be true");
        
        for(uint i = 1; i <= OracleId ; i++){
            address OracleAddr = IdToOracle[i];
            OraclesArray[i - 1] = Oracle({
                OracleAddr: OracleAddr,
                OracleStr: Oracles[OracleAddr]
            });
        }
        
        return OraclesArray;
    }
    
    function updateOracle (string memory pair_name, address oracle_addr) public onlyOwner returns(bool) {
        require(OracleToId[oracle_addr] != 0 ,"Can not find oracle_addr");
        Oracles[oracle_addr] = pair_name;
        
        return true;
    }

    function removeOracle(string memory pair_name, address oracle_addr) public onlyOwner returns(bool) {
        delete Oracles[oracle_addr];
        delete Pairs[pair_name];
        
        return true;
    }
    
    function removeOracles(string[] memory pairs_name, address[] memory oracles_addr) public onlyOwner returns(bool) {
        for(uint i = 0; i <= oracles_addr.length ; i++) {
            string memory pair_name = pairs_name[i];
            address oracle_addr = oracles_addr[i];
            delete Oracles[oracle_addr];
            delete Pairs[pair_name];
        }
        
        return true;
    }
    
}