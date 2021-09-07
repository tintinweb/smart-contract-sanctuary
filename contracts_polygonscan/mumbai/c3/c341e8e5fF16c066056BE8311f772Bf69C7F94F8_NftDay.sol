/**
 *Submitted for verification at polygonscan.com on 2021-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract NftDay {
//hash stocké dans la blockchain
    string memeHash;
//Write function
    function set(string memory _memehash) public {
        memeHash = _memehash;

    }
//Read function
//obtenir la valeur du hash
    function get() public view returns (string memory) {
        return memeHash;
}

}