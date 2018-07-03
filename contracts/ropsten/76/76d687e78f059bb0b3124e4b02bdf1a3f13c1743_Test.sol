pragma solidity ^0.4.23;

contract Test {
    
    constructor () public {
        assembly {
            mstore(0, 1)
            return(0, 1)
        }
    }
    
    function aa() public pure returns (uint) { return 3; }
}