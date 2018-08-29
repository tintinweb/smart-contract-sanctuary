pragma solidity 0.4.24;

contract Biography{
    
    string name;
    uint256 age;
    
    function setDetails(string _name, uint256 _age) public {
        name = _name;
        age = _age;
    }
    
    function getDetails() public view returns(string _name, uint256 _age){
        return (name,age);
    }
    
}