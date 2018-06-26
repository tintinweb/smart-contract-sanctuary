pragma solidity 0.4.24;

contract Hello {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function doSomething() returns (string) {
        return &quot;Oye! Hello Hello&quot;;
    }

}

contract World {
    address public owner;

    Hello xyz_;

    constructor(Hello _xyz) public {
        xyz_ = _xyz;
        owner = msg.sender;
    }

    function interactWithXYZ() returns (string) {
      return  xyz_.doSomething();
    }
}