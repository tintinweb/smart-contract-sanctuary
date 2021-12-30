/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

pragma solidity >=0.6.0 <0.9.0;

contract Test1 {
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    struct Food {
        string name;
        uint256 price;
    }

    People[] public peoples;

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        peoples.push(People(_favoriteNumber, _name));
    }
}