// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./Ownable.sol";
import "./AggregatorInterface.sol";

contract LinkBSCOracleTest is Ownable {
    
    uint OraclePairId;
    string[] allOracle;
    mapping (string => address) public Oracles;
    mapping (uint => string) IdToOraclePair;
    mapping (string => uint) OraclePairToId;
    
    constructor(string memory pair_name, address oracle_addr) {
        OraclePairId++;
        IdToOraclePair[OraclePairId] = pair_name;
        OraclePairToId[pair_name] = OraclePairId;
        Oracles[pair_name] = oracle_addr;
    }
    
    function addOracle(string memory pair_name, address oracle_addr) public onlyOwner returns(bool) {
        OraclePairId++;
        IdToOraclePair[OraclePairId] = pair_name;
        OraclePairToId[pair_name] = OraclePairId;
        Oracles[pair_name] = oracle_addr;
        return true;
    }
    
    function getOracles() public returns(string[] memory){
        delete allOracle;
        for(uint i = 1; i <= OraclePairId ; i++) {
            string memory OraclePair = IdToOraclePair[i];
            allOracle.push(OraclePair);
        }
        
        return allOracle;
    }
    
    function updateOracle (string memory pair_name, address oracle_addr) public onlyOwner returns(bool) {
        Oracles[pair_name] = oracle_addr;
        return true;
    }

    function removeOracle(string memory pair_name) public onlyOwner returns(bool) {
        delete Oracles[pair_name];
        delete IdToOraclePair[OraclePairToId[pair_name]];
        delete OraclePairToId[pair_name];
        return true;
    }
    
    function getPrice(string memory pair_name) public view returns(int256) {
        address OracleAddr = Oracles[pair_name];
        return AggregatorInterface(OracleAddr).latestAnswer();
    }
    
}