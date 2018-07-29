pragma solidity ^0.4.24;

contract MyFirstContract {
    string constant myName = &quot;hardy&quot;;
    string public greeting;
    
    constructor(string initGreeting) public {
        greeting = initGreeting;
    }
    
    function interact() public pure returns(string) {
        return &quot;hello&quot;;
    }
}