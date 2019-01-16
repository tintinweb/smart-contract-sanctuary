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
    event UpdateEmployeeWallet(string _employee_real_name,address _employee_wallet);
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
    
    function constructor() public{
        admin=msg.sender;
        
        initEmployee();
    }
    
    function initEmployee(){
        require(msg.sender==admin);
        
        address tempWallet=0x00000000000;
        
        addEmployee(1,"谢坚","连叔小强","2016/5/10","CEO","男","玄宗",tempWallet);
        
        addEmployee(2,"林斌","豹子头","2016/5/10","COO","男","玄宗",tempWallet);

        addEmployee(3,"王李","睡衣熊","2016/5/10","主编","男","玄典",tempWallet);
        
        addEmployee(4,"林涛","汤姆猫","2017/7/11","CTO","男","玄机",tempWallet);
        
        addEmployee(5,"马能周","鼹鼠","2017/7/14","主编","男","玄知",tempWallet);
        
        addEmployee(6,"黄颖","蓝灯","2017/11/27","市场总监","男","玄策",tempWallet);

        addEmployee(11,"李菁","迷鹿","2017/7/3","市场运营","女","玄策",tempWallet);

        addEmployee(12,"谢敏","考拉","2017/7/10","总助","女","玄宗",tempWallet);

        addEmployee(13,"苏振兴","神犬哮天","2017/7/19","产品经理","男","玄机",tempWallet);

        addEmployee(14,"卿启程","翻羽","2017/7/19","Android开发工程师","男","玄机",tempWallet);

        addEmployee(15,"杨珈","小跳蛙","2017/7/20","UI设计","男","玄机",tempWallet);

        addEmployee(16,"柏子瑄","三文鱼","2017/7/24","行政主管","女","玄宗",tempWallet);

        addEmployee(17,"刘思汗","大黄蜂","2017/8/3","前端开发","男","玄机",tempWallet);

        addEmployee(18,"范新","大蟒蛇","2017/8/10","iOS开发工程师","男","玄机",tempWallet);

        addEmployee(19,"朱凯雄","渡鸦","2017/8/11","服务器运维工程师","男","玄机",tempWallet);

        addEmployee(20,"汪文鹏","斑鸠","2017/8/14","市场主管","男","玄策",tempWallet);

        addEmployee(21,"蒋芳","红鲤鱼","2017/8/14","品牌公关","女","玄策",tempWallet);

        addEmployee(22,"何腾","雪雕","2017/8/21","PHP开发工程师","男","玄机",tempWallet);

        addEmployee(23,"李莺","夜莺","2017/8/25","测试工程师","女","玄机",tempWallet);

        addEmployee(24,"张保思","天蝎","2018/3/19","文案兼流量运营","男","玄策",tempWallet);

        addEmployee(25,"张杏荣","海星","2018/3/20","人事主管","女","玄宗",tempWallet);

        addEmployee(26,"熊敏","维尼熊","2018/4/2","市场运营","女","玄策",tempWallet);

        addEmployee(27,"刘荣泽","狒狒","2018/4/17","Android开发工程师","男","玄机",tempWallet);

        addEmployee(28,"刘赞虎","老虎","2018/5/14","PHP开发工程师","男","玄机",tempWallet);

        addEmployee(29,"廖鑫炜","廖鑫炜","2018/5/28","Java开发工程师","男","玄机",tempWallet);

        addEmployee(30,"蔡悦","袋鼠","2018/6/4","实习编辑","女","玄知",tempWallet);

        addEmployee(31,"吴霞","小绵羊","2018/6/8","平台运营专员","女","玄知",tempWallet);

        addEmployee(32,"陈皓","企鹅","2018/6/19","设计","男","玄策",tempWallet);

        addEmployee(33,"张俊瑜","圣龙","2018/6/21","Java开发工程师","男","玄机",tempWallet);

        addEmployee(34,"张波","边牧犬","2018/6/25","Java开发工程师","男","玄机",tempWallet);

        addEmployee(35,"朱荣","北极狐","2018/7/23","爬虫工程师","男","玄机",tempWallet);

        addEmployee(35,"宋俊","蓝精灵","2018/8/1","运营专员","男","玄策",tempWallet);

        addEmployee(36,"龙渝蕙","兔子","2018/9/3","产品经理","男","玄机",tempWallet);
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
        
        if(_employee_wallet!=0x0){
            mintLzToken(_employee_wallet);   
        }
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
    
    function  updateEmployeeWallet  (uint _employee_number, address _employee_wallet)public
    {
        require(msg.sender==admin);
        
        Employee emp=employees[_employee_number];
        require(emp.employee_number>0);
        
        emp.employee_wallet=_employee_wallet;
        
        UpdateEmployeeWallet(emp.employee_real_name,_employee_wallet);
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
        returns (string _employee_real_name,string _employee_nick_name,string _employee_position,string _employee_join_date,string _employee_sex,string _employee_department,uint256 _balance)
    {
        Employee _employee=employees[_employee_number];
        
        require(_employee.employee_number>0);
        _employee_real_name=_employee.employee_real_name;
        _employee_nick_name=_employee.employee_nick_name;
        _employee_join_date=_employee.employee_join_date;
        _employee_sex=_employee.employee_sex;

        _employee_department=_employee.employee_department;
        
        _employee_position=_employee.employee_position;
        
        _balance=balances[_employee.employee_wallet];
        
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