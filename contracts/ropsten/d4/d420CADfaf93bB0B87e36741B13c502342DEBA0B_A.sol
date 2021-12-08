// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
contract B {
    uint public num;
    address public sender;
    uint public value;

    function setVars(uint _num) public payable {
        num = _num *2;
        sender = msg.sender;
        value = msg.value;
    }
}

contract A {
    uint public num;
    address public sender;
    uint public value;
    address public  contarct;
    uint numb;
     

    function setVars(address _contract, uint _num) public payable {
           (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("setVars(uint256)", _num)
        );

        contarct=_contract;
        numb=_num;
         assembly {
           // return _dest.delegatecall(msg.data)
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(sub(gas(), 100000000), _contract, 0x40, calldatasize(), 0,_num)
            //return(0, len) //we throw away any return data
        }
     
        
}
 
}
contract C{
    // NOTE: storage layout must be the same as contract A
    uint public num;
    address public sender;
    uint public value;

    function setVars(uint _num) public payable {
        num = _num *5;
        sender = msg.sender;
        value = msg.value;
    }
}
contract D{
    // NOTE: storage layout must be the same as contract A
    uint public num;
    address public sender;
    uint public value;

    function setVars(uint _num) public payable {
        num = _num *10;
        sender = msg.sender;
        value = msg.value;
    }
    
}
contract E{
    // NOTE: storage layout must be the same as contract A
    uint public num;
    address public sender;
    uint public value;

    function setVars(uint _num) public payable {
        num = _num *100;
        sender = msg.sender;
        value = msg.value;
    }
    
}
contract F{
    // NOTE: storage layout must be the same as contract A
    uint public num;
    address public sender;
    uint public value;

    function setVars(uint _num) public payable {
        num = _num *100;
        sender = msg.sender;
        value = msg.value;
    }
    
}