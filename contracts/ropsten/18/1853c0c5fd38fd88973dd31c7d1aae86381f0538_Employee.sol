pragma solidity >=0.4.0 <0.6.0;

contract Employee {
    struct EmployeeData {
    string fName;
    bool laptopUsage;
    }
    mapping(address => EmployeeData) public EmployeeID;
    address [] EmployeeArray;
    
     function setInfo  (string memory _fName, bool _laptopUage, address _address) public returns (bool)
    { 
        EmployeeID[_address].fName = _fName;
        EmployeeID[_address].laptopUsage = _laptopUage;
        EmployeeArray.push(_address);
        return true;
    }
    
    function getName (address _address) public returns (string memory)
    {
        return EmployeeID[_address].fName;
    }
    
    function findLaptopUsage (address _address) public returns (bool)
    {
        return EmployeeID[_address].laptopUsage;
    }
}