/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

pragma solidity ^0.8.1;

contract Storage {
    
    string private _hash;
    
    constructor(string memory hash) {
        _hash = hash;
    }
    
    function updateHash(string memory hash) external {
        _hash = hash;
    }
    
    function getHash() external view returns (string memory) {
        return _hash;
    }

}