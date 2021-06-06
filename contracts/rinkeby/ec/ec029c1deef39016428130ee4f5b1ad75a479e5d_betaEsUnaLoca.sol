/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 < 0.8.0;

contract betaEsUnaLoca{
    address owner;
    uint storedInt;
    string texto;
    string storeString;
    
    
    event SetInt(uint set);
    event SetString(string set);
    
    modifier onlyOwner{
        require(msg.sender == owner, "tu no eres el owner");
        _;
    }
    
    constructor(){
        owner = msg.sender;
    }
    
    function setInt(uint _storedInt) public onlyOwner{
        storedInt = _storedInt;
        emit SetInt(_storedInt);
    }
    
    function getInt() public view returns(uint){
        return storedInt;
    }
    
    
    function write(string calldata _texto) public onlyOwner{
        texto = _texto;
    }
    
    function read() public view returns(string memory){
        return texto;
    }
    
    function write2f(string memory _storeString) public onlyOwner{
        storeString = _storeString;
        emit SetString(_storeString);
    }
    
    function read2f() public view returns(string memory){
        return storeString;
    }
    
}