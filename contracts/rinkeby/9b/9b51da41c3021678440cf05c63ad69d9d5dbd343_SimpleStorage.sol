/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage{
    uint favorateNumber; //default value is 0
    
    struct People{
        uint256 favorateNumber;
        string name;
    }
    
    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;
    
    function store(uint256 _favorateNumber) public{
        favorateNumber = _favorateNumber;
    }
    
    function retrieve() public view returns (uint256){
        return favorateNumber;
    }
    
    function addPerson(string memory name, uint256 _favorateNumber) public{
        people.push(People(_favorateNumber, name));
        nameToFavoriteNumber[name] = _favorateNumber;
    }
    
}

contract unusedTest{
    uint favorateNumber; //default value is 0
    
    struct People{
        uint256 favorateNumber;
        string name;
    }
    
    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;
    
    function store(uint256 _favorateNumber) public{
        favorateNumber = _favorateNumber;
    }
    
    function retrieve() public view returns (uint256){
        return favorateNumber;
    }
    
    function addPerson(string memory name, uint256 _favorateNumber) public{
        people.push(People(_favorateNumber, name));
        nameToFavoriteNumber[name] = _favorateNumber;
    }
    
}