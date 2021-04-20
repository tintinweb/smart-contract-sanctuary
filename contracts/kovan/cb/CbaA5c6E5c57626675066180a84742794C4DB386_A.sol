/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/A.sol
pragma solidity >=0.6.7 <0.7.0;

////// src/B.sol
/* pragma solidity ^0.6.7; */

contract B {
    bytes32 txt = "hello";
}

////// src/A.sol
/* pragma solidity ^0.6.7; */

/* import "./B.sol"; */

contract A is B {
    function write(bytes32 str) public {
        txt = str;
    }

    function read() public view returns (bytes32) {
        return txt;
    }
}