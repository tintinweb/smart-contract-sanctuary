/**
 *Submitted for verification at arbiscan.io on 2021-12-09
*/

pragma solidity ^0.6.0;

contract SimpleStorage {

    //initialises to 0
    uint256 public favoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;

    }

}