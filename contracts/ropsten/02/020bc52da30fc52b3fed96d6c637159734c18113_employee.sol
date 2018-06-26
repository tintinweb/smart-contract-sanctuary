pragma solidity ^0.4.19;

contract employee
{
    
    struct person
    {
        string name;
        uint age;
        
    }
    
    mapping(address=>person)employeedetails;
    
    function setemployee(address employee_add, string name, uint age) public
    {
       
       if(employeedetails[employee_add].age==0)
        employeedetails[employee_add] = person(name, age);
    }
    
    function getemployee(address employee_add) public constant returns (string name, uint age)
    {
        return (employeedetails[employee_add].name, employeedetails[employee_add].age);
    }
    
    
}