pragma solidity ^0.4.0;

contract Library {
    function a() public {
        selfdestruct(msg.sender);
    }
}

contract DelegateCall {
    Library lib;
    constructor (address a) public {
        lib = Library(a);
    }
    function () payable external {
    }
    function a() public {
        address(lib).delegatecall(bytes4(keccak256("a()")));
    }
}

contract StaticCall {
    Library lib;
    constructor (address a) public {
        lib = Library(a);
    }
    function () payable external {
    }
    function a() public view {
        address(lib).call(bytes4(keccak256("a()")));
    }
}