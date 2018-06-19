pragma solidity ^0.4.21;

contract NanoLedger{
    
    mapping (uint => string) data;

    
    function saveCode(uint256 id, string dataMasuk) public{
        data[id] = dataMasuk;
    }
    
    function verify(uint8 id) view public returns (string){
        return (data[id]);
    }
}