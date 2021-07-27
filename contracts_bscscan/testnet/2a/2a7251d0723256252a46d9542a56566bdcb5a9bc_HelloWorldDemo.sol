/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract HelloWorld {
    
    string public name = "";
    
    constructor (string memory _name) {
        name = _name;
    }

    function setName(string memory _name)  public {
        name = _name;
    }
}

contract HelloWorldDemo {
    constructor () {}
    
    function createContract(string memory name)  public returns (address addr)  {
        HelloWorld a = new HelloWorld(name);
        return address(a);

        // bytes32 _salt = keccak256(abi.encodePacked(address0));
        // HelloWorld a = new HelloWorld{salt: _salt}();
        // return address(a);
        
        // bytes memory bytecode = type(HelloWorld).creationCode;
        // assembly {
        //     addr := create2(0x0, add(bytecode,0x20), mload(bytecode), _salt)
        // }
        // return addr;
    }
    
}