/**
 *Submitted for verification at Etherscan.io on 2021-10-30
*/

pragma solidity ^0.6.0;

//difine the contract (contract name)
contract SimpleStorage {
    
    // Put in your varibles
    uint256 favoriteNumber;
    
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    
    People [] public people;
    mapping(string => uint256) public nameToFavoriteNumber;
    
    //Create a function 
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }
    
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }
    
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People( _favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
    
    
  
}