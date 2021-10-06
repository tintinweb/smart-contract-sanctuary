/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract E {
    function callA(address a) public returns(bool, bytes memory) {
        (bool success, bytes memory data) = a.delegatecall(
            abi.encodeWithSignature("setSender()")
        );
        return (success, data);
    }
}

contract D {
    function callE(address e, address a) public returns(bool, bytes memory) {
        (bool success, bytes memory data) = e.delegatecall(
            abi.encodeWithSignature("callA(address)", a)
        );
        return (success, data);
    }
}

contract C {
    function callD(address d, address e, address a) public returns(bool, bytes memory) {
        (bool success, bytes memory data) = d.delegatecall(
            abi.encodeWithSignature("callE(address,address)", e, a)
        );
        return (success, data);
    }
}

contract B {
    function callC(address c, address d, address e, address a) public returns(bool, bytes memory) {
        (bool success, bytes memory data) = c.delegatecall(
            abi.encodeWithSignature("callD(address,address,address)", d, e, a)
        ); 
        return (success, data);
    }
}

contract A {
    address public sender;
    
    B public b;
    C public c;
    D public d;
    E public e;
    
    constructor() {
        e = new E();
        d = new D();
        c = new C();
        b = new B();
    }
    
    function setSender() public {
        sender = msg.sender;
    }
    
    function callB() public returns(bool, bytes memory){
        (bool success, bytes memory data) = address(b).delegatecall(
            abi.encodeWithSignature(
                "callC(address,address,address,address)", 
                address(c),
                address(d),
                address(e),
                address(this)
            )
        );
        return (success, data);
    }
}