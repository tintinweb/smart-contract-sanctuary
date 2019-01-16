pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

contract LocalStarRoster{
    event AddEmployee(string _employee_real_name);
    event UpdateEmployee(string _employee_real_name);

    
    mapping (uint => Employee) private employees;
    
    address public admin;
    
    struct Employee {
        
        uint employee_number;//1 ceo 2 coo
        string employee_real_name;
        string employee_nick_name;
        string employee_join_date;
        uint employee_status;//1:Incumbency 0:Quit
        string employee_position;//ceo cfo coo 
    }
    
    function LocalStarRoster()
        public
    {
        admin=msg.sender;
        
        addEmployee(1,"小强","谢小强","2017-10-10","CEO");
        addEmployee(2,"豹子头","林斌","2017-10-10","COO");
        addEmployee(3,"汤姆猫","林涛","2017-10-10","CTO");
    }
    
    function  addEmployee  (uint _employee_number, string _employee_real_name, string _employee_nick_name,string _employee_join_date,string _employee_position)public
    {
        require(msg.sender==admin);
        require(employees[_employee_number].employee_number==0);
        
        employees[_employee_number] = Employee({
            employee_number: _employee_number,
            employee_real_name: _employee_real_name,
            employee_nick_name: _employee_nick_name,
            employee_join_date: _employee_join_date,
            employee_status: 1,
            employee_position: _employee_position
        });
        AddEmployee(_employee_real_name);
    }
    
    function  updateEmployee  (uint _employee_number, uint _employee_status,string _employee_position)public
    {
        require(msg.sender==admin);
        
        Employee emp=employees[_employee_number];
        require(emp.employee_number>0);
        
        emp.employee_status=_employee_status;
        emp.employee_position=_employee_position;
        
        UpdateEmployee(emp.employee_real_name);
    }
    
    function getAllEmployeeById(uint _employee_number)
        public
        constant
        returns (Employee _employee)
    {
        _employee=employees[_employee_number];
        require(_employee.employee_number>0);
    }
    
}