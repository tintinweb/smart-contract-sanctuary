pragma solidity ^0.4.25;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract LzToken is ERC20Basic {

  mapping(address => uint256) balances;
  
  string public constant name = "LocalStarToken";
  string public constant symbol = "LZ";
  uint8 public constant decimals = 18;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender]-_value;
    balances[_to] = balances[_to]+_value;
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract LocalStarRoster is LzToken{
    event AddEmployee(string _employee_real_name);
    event UpdateEmployee(string _employee_real_name);
    event Mint(address to,uint256 value);
    
    mapping (uint => Employee) private employees;
    
    address  admin;
    
    struct Employee {
        
        uint employee_number;//1 ceo 2 coo
        string employee_real_name;
        string employee_nick_name;
        string employee_join_date;
        string employee_sex;
        string employee_department;
        uint employee_status;//1:Incumbency 0:Quit
        string employee_position;//ceo cfo coo 
        address employee_wallet;
    }
    
    function LocalStarRoster()
        public
    {
        admin=msg.sender;
        
        addEmployee(1,"谢小强","小强","2017-10-10","CEO","男","玄宗",admin);
        mintLzToken(admin);
        
        addEmployee(2,"林斌","豹子头","2017-10-12","COO","男","玄宗",admin);
        mintLzToken(admin);
        
        addEmployee(3,"林涛","汤姆猫","2017-10-14","CTO","男","玄机",admin);
        mintLzToken(admin);
    }
    
    function  addEmployee  (uint _employee_number, string _employee_real_name, string _employee_nick_name,string _employee_join_date,string _employee_position,string _employee_sex,string _employee_department,address _employee_wallet)public
    {
        require(msg.sender==admin);
        require(employees[_employee_number].employee_number==0);
        
        employees[_employee_number] = Employee({
            employee_number: _employee_number,
            employee_real_name: _employee_real_name,
            employee_nick_name: _employee_nick_name,
            employee_join_date: _employee_join_date,
            employee_sex:_employee_sex,
            employee_department:_employee_department,
            employee_status: 1,
            employee_position: _employee_position,
            employee_wallet:_employee_wallet
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
    
    function getEmployeeInformation(uint _employee_number)
        public
        constant
        returns (string _employee_real_name,string _employee_nick_name,string _employee_position,string _employee_join_date,uint256 _balance)
    {
        Employee _employee=employees[_employee_number];
        
        require(_employee.employee_number>0);
        _employee_real_name=_employee.employee_real_name;
        _employee_nick_name=_employee.employee_nick_name;
        _employee_join_date=_employee.employee_join_date;
        
        _employee_position=_employee.employee_position;
        
        _balance=balances[_employee.employee_wallet];
        
    }
    
    function mintLzToken(address _address)public{
        require(msg.sender==admin);
        uint256 value=1000000000000000000;
        
        balances[_address]=balances[_address]+value;
        totalSupply=totalSupply+value;
        
        Mint(_address,value);
    }

    function getEmployeeAllInformation(uint _employee_number)
        public
        constant
        returns (string _employee_real_name,string _employee_nick_name,string _employee_position,string _employee_join_date,string _employee_sex,string _employee_department)
    {
        Employee _employee=employees[_employee_number];
        
        require(_employee.employee_number>0);
        _employee_real_name=_employee.employee_real_name;
        _employee_nick_name=_employee.employee_nick_name;
        _employee_join_date=_employee.employee_join_date;
        _employee_sex=_employee.employee_sex;

        _employee_department=_employee.employee_department;
        
        _employee_position=_employee.employee_position;
        
    }
    
    function transfer(address _to, uint256 _value) public  returns (bool) {
        bool result = super.transfer(_to, _value);
        return result;
    }
    
    function withdraw(){
        require(msg.sender==admin);
        msg.sender.transfer(this.balance);
    }
    
}