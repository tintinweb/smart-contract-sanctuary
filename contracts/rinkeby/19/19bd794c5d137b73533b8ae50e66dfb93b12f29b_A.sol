/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract E {
    address public sender;
    
    function callA(address a) public returns(bool, bytes memory) {
        return address(a).delegatecall(
            abi.encodeWithSignature("setSender()")
        );
    }
}

contract D {
    address public sender;
    
    function callE(address e, address a) public returns(bool, bytes memory) {
        return address(e).delegatecall(
            abi.encodeWithSignature("callA(address)", a)
        );
    }
}

contract C {
    address public sender;
    
    function callD(address d, address e, address a) public returns(bool, bytes memory) {
        return address(d).call(
            abi.encodeWithSignature("callE(address,address)", e, a)
        );
    }
}

contract B {
    address public sender;
    
    function callC(address c, address d, address e, address a) public returns(bool, bytes memory) {
        return address(c).delegatecall(
            abi.encodeWithSignature("callD(address,address,address)", d, e, a)
        ); 
    }
}

contract A {
    address public sender;
    
    address public a;
    B public b;
    C public c;
    D public d;
    E public e;
    
    constructor() {
        e = new E();
        d = new D();
        c = new C();
        b = new B();
        a = address(this);
    }
    
    function setSender() public {
        sender = msg.sender;
    }
    
    function callB() public returns(bool, bytes memory){
        return address(b).delegatecall(
            abi.encodeWithSignature(
                "callC(address,address,address,address)", 
                address(c),
                address(d),
                address(e),
                address(a)
            )
        );
    }
}