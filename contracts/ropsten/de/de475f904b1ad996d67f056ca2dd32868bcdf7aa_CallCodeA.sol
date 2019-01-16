pragma solidity ^0.4.0;

contract LibraryA {
    function a() public {
        selfdestruct(tx.origin);
    }
}

contract LibraryB {
    function a() public {
        selfdestruct(msg.sender);
    }
}

contract CallCodeA {
    LibraryA lib;
    constructor (address a) public {
        lib = LibraryA(a);
    }
    function () payable external {
    }
    function a() public {
        address(lib).callcode(bytes4(keccak256("a()")));
    }
}

contract CallCodeB {
    LibraryB lib;
    constructor (address a) public {
        lib = LibraryB(a);
    }
    function () payable external {
    }
    function a() public {
        address(lib).callcode(bytes4(keccak256("a()")));
    }
}