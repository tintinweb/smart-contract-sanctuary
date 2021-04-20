/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

pragma solidity >=0.6.6<=0.7.1;


contract simplesc {
    string name = "test sce";
    string symbol = "testsc";
    string version = "0.0.1";
    uint decimal = 18;

    
    function getContractInfo() public returns(string memory, string memory, string memory, uint) {
        return(name, symbol, version, decimal);
    }

    function getName() public returns(string memory) {
        return(name);
    }

    function getSymbol() public returns(string memory) {
        return(symbol);
    }

    function getDecimal() public returns(uint) {
        return(decimal);
    }

    function getVersion() public returns(string memory) {
        return(version);
    }
    

}