pragma solidity ^0.4.18;
contract hello {
    string greeting = &quot;fuck you&quot;;

    function say() constant public returns (string) {
        return greeting;
    }
}