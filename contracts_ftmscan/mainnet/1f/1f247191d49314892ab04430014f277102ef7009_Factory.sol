/**
 *Submitted for verification at FtmScan.com on 2021-12-16
*/

pragma solidity ^0.7.0;

contract Factory {
    address public whatdidIjustcreated;

    function createContract (string memory name) public {
        address newContract = address(new Contract(name));
        whatdidIjustcreated = newContract;
    } 
}

contract Contract {
    string public name;

    constructor(string memory _n) {
        name = _n;
    }
}