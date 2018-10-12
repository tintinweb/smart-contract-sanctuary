pragma solidity ^0.4.0;
contract MySuperCard {
    string public  name;
    uint8 public age;
    string public photoHash;
    address public wallet;
    
    constructor(
        string _name,
        uint8 _age,
        string _photoHash, 
        address _wallet)
    {
            name = _name;
            age = _age;
            photoHash = _photoHash;
            wallet = _wallet;
            
            
    }
    
    function changeAge(uint8 newAge)
    {
        age = newAge;
    }
}