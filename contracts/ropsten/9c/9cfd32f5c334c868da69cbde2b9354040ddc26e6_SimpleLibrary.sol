pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// Exercise to verify library, factory and deployed contracts
//
// Instructions
// 1. Deploy SimpleLibrary first & verify
// 2. Deploy SimpleFactory next & verify
// 3. Execute SimpleFactory.deploySimpleContract(...) and verify the contract
// 4. Execute SimpleFactory.deploySimpleContract(...) again and check whether you
//   need to verify it
//
// For step 3, the following `geth` script may help
//
// var simpleContractAbi = {get this from EtherScan};
// var simpleContract=eth.contract(simpleContractAbi);
// var symbol = {your symbol};
// var name = {your name};
// var initialNumber = {your initialNumber};
// var simpleContractConstructor=simpleContract.new.getData(symbol, name, initialNumber);
//
// The output from the next command will give you the argument required to verify SimpleContract
// the first time
// simpleContractConstructor.substring(9)
//
// Enjoy. BokkyPooBah / Bok Consulting Pty Ltd 2018
// ----------------------------------------------------------------------------

library SimpleLibrary {
    function add(uint a, uint b) public pure returns (uint c) {
        c = a + b;
    }
}

contract SimpleContract {
    using SimpleLibrary for uint;
    
    string public symbol;
    string public name;
    uint public initialNumber;
    
    uint public a;
    uint public b;

    constructor(string _symbol, string _name, uint _initialNumber) public {
        symbol = _symbol;
        name = _name;
        initialNumber = _initialNumber;
    }
    
    function testIt() public {
        a = 123;
        b = initialNumber.add(b);
    }
}

contract SimpleFactory {
    SimpleContract[] public deployedContracts;
    
    function deploySimpleContract(string _symbol, string _name, uint _initialNumber) public {
        SimpleContract c = new SimpleContract(_symbol, _name, _initialNumber + 1000);
        deployedContracts.push(c);
    }
}