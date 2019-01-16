// c1.sol
pragma solidity ^0.4.25;
contract Ct {
    uint256 a;
    constructor() public {
        a = 1;
    }
    
    function increaseCt() public {
        a += 1;
    }
}