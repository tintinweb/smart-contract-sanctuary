pragma solidity 0.4.24;

contract MainCon {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function doSomething() public pure returns (string) {
        return "Oye! Hello Hello";
    }

}

contract SubCon {
    address public owner;

    MainCon xyz_;

    constructor(MainCon _xyz) public {
        xyz_ = _xyz;
        owner = msg.sender;
    }

    function interactWithXYZ() returns (string) {
      return  xyz_.doSomething();
    }
}