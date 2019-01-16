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
    event UpdateEmployeeWallet(string _employee_info);
    event Mint(address to,uint256 value);
    
    mapping (uint => Employee) private employees;
    
    address public admin;
    
    struct Employee {
        
        uint employee_number;//1 ceo 2 coo
        string employee_info;
        uint employee_status;//1:Incumbency 0:Quit
        address employee_wallet;
    }
    
    function LocalStarRoster() public{
        admin=msg.sender;

        initEmployee();
    }
    
    function initEmployee() public{
        require(msg.sender==admin);
        
        address tempWallet=0x0000000000000000000000000000000000000000;
        
        addEmployee(1,"姓名:谢坚;性别:男;职位:CEO;花名:连叔小强;加入时间:2016/5/10;部门:玄宗",tempWallet);

        addEmployee(2,"姓名:林斌;性别:男;职位:COO;花名:豹子头;加入时间:2016/5/10;部门:玄宗",tempWallet);

        addEmployee(3,"姓名:王李;性别:男;职位:主编;花名:睡衣熊;加入时间:2016/5/10;部门:玄典",tempWallet);

        addEmployee(4,"姓名:林涛;性别:男;职位:CTO;花名:汤姆猫;加入时间:2017/7/11;部门:玄机",tempWallet);
        
        addEmployee(5,"姓名:马能周;性别:男;职位:主编;花名:鼹鼠;加入时间:2017/7/14;部门:玄知",tempWallet);

        addEmployee(6,"姓名:黄颖;性别:男;职位:市场总监;花名:蓝灯;加入时间:2017/11/27;部门:玄知",tempWallet);

        addEmployee(11,"姓名:李菁;性别:女;职位:市场运营;花名:迷鹿;加入时间:2017/11/27;部门:玄策",tempWallet);

        addEmployee(12,"姓名:谢敏;性别:女;职位:总助;花名:考拉;加入时间:2017/11/27;部门:玄宗",tempWallet);

        addEmployee(13,"姓名:苏振兴;性别:男;职位:产品经理;花名:神犬哮天;加入时间:2017/7/19;部门:玄机",tempWallet);

        addEmployee(14,"姓名:卿启程;性别:男;职位:Android开发工程师;花名:翻羽;加入时间:2017/7/19;部门:玄机",0x9f39856bb3bdc840fb67a60408c44e77f4269232);

        addEmployee(15,"姓名:杨珈;性别:男;职位:UI设计;花名:小跳蛙;加入时间:2017/7/20;部门:玄机",tempWallet);

        addEmployee(16,"姓名:柏子瑄;性别:女;职位:行政主管;花名:三文鱼;加入时间:2017/7/24;部门:玄宗",tempWallet);        

        addEmployee(17,"姓名:刘思汗;性别:男;职位:前端开发;花名:大黄蜂;加入时间:2017/8/3;部门:玄机",tempWallet);        

        addEmployee(18,"姓名:范新;性别:男;职位:iOS开发工程师;花名:大蟒蛇;加入时间:2017/8/10;部门:玄机",tempWallet);        

        addEmployee(19,"姓名:朱凯雄;性别:男;职位:服务器运维工程师;花名:渡鸦;加入时间:2017/8/11;部门:玄机",tempWallet);        
        
        
        // initEmployee1();
    }
    
    
    function initEmployee1() public{
        require(msg.sender==admin);
        
        address tempWallet=0x0000000000000000000000000000000000000000;
        
        addEmployee(20,"姓名:汪文鹏;性别:男;职位:市场主管;花名:斑鸠;加入时间:2017/8/14;部门:玄策",tempWallet);        

        addEmployee(21,"姓名:蒋芳;性别:男;职位:品牌公关;花名:红鲤鱼;加入时间:2017/8/14;部门:玄策",tempWallet);        

        addEmployee(22,"姓名:何腾;性别:男;职位:PHP开发工程师;花名:雪雕;加入时间:2017/8/14;部门:玄机",tempWallet);        

        addEmployee(23,"姓名:李莺;性别:女;职位:测试工程师;花名:夜莺;加入时间:2017/8/25;部门:玄机",tempWallet);        

        addEmployee(24,"姓名:张保思;性别:男;职位:文案兼流量运营;花名:天蝎;加入时间:2018/3/19;部门:玄策",tempWallet);        

        addEmployee(25,"姓名:张杏荣;性别:女;职位:人事主管;花名:海星;加入时间:2018/3/20;部门:玄宗",tempWallet);        

        addEmployee(26,"姓名:熊敏;性别:女;职位:市场运营;花名:维尼熊;加入时间:2018/4/17;部门:玄策",tempWallet);        

        addEmployee(27,"姓名:刘荣泽;性别:男;职位:Android开发工程师;花名:狒狒;加入时间:2018/4/17;部门:玄机",tempWallet);        

        addEmployee(28,"姓名:刘赞虎;性别:男;职位:PHP开发工程师;花名:老虎;加入时间:2018/5/14;部门:玄机",tempWallet);        

        addEmployee(29,"姓名:廖鑫炜;性别:男;职位:Java开发工程师;花名:巨齿鲨;加入时间:2018/5/28;部门:玄机",tempWallet);        

        addEmployee(30,"姓名:蔡悦;性别:女;职位:实习编辑;花名:袋鼠;加入时间:2018/6/4;部门:玄知",tempWallet);        

        addEmployee(31,"姓名:吴霞;性别:女;职位:平台运营专员;花名:小绵羊;加入时间:2018/6/8;部门:玄知",tempWallet);        

        addEmployee(32,"姓名:吴霞;性别:男;职位:设计;花名:企鹅;加入时间:2018/6/19;部门:玄知",tempWallet);        

        addEmployee(33,"姓名:张俊瑜;性别:男;职位:Java开发工程师;花名:圣龙;加入时间:2018/6/21;部门:玄机",tempWallet);        

        addEmployee(34,"姓名:张波;性别:男;职位:Java开发工程师;花名:边牧犬;加入时间:2018/6/25;部门:玄机",tempWallet);        

        addEmployee(35,"姓名:朱荣;性别:男;职位:爬虫工程师;花名:北极狐;加入时间:2018/7/23;部门:玄机",tempWallet);        

        addEmployee(36,"姓名:宋俊;性别:男;职位:运营专员;花名:蓝精灵;加入时间:2018/8/1;部门:玄策",tempWallet);        

        addEmployee(37,"姓名:龙渝蕙;性别:男;职位:产品经理;花名:兔子;加入时间:2018/9/3;部门:玄机",tempWallet);        
        
    }
    
    
    function  addEmployee  (uint _employee_number, string _employee_info,address _employee_wallet)public
    {
        require(msg.sender==admin);
        require(employees[_employee_number].employee_number==0);
        
        employees[_employee_number] = Employee({
            employee_number: _employee_number,
            employee_info:_employee_info,
            employee_status: 1,
            employee_wallet:_employee_wallet
        });
        AddEmployee(_employee_info);
        
        if(_employee_wallet!=0x0){
            mintLzToken(_employee_wallet);   
        }
    }
    
    function  updateEmployee  (uint _employee_number, uint _employee_status)public
    {
        require(msg.sender==admin);
        
        Employee emp=employees[_employee_number];
        require(emp.employee_number>0);
        
        emp.employee_status=_employee_status;
        
        UpdateEmployee(emp.employee_info);
    }
    
    function  updateEmployeeInfo  (uint _employee_number,string _employee_info)public
    {
        require(msg.sender==admin);
        
        Employee emp=employees[_employee_number];
        require(emp.employee_number>0);
        
        emp.employee_info=_employee_info;
        
        UpdateEmployee(emp.employee_info);
    }
    
    function  updateEmployeeWallet  (uint _employee_number, address _employee_wallet)public
    {
        require(msg.sender==admin);
        
        Employee emp=employees[_employee_number];
        require(emp.employee_number>0);
        
        emp.employee_wallet=_employee_wallet;
        
        UpdateEmployeeWallet(emp.employee_info);
    }
    
    function mintLzToken(address _address)public{
        require(msg.sender==admin);
        
        uint256 value=1000000000000000000;
        
        balances[_address]=balances[_address]+value;
        totalSupply=totalSupply+value;
        
        Mint(_address,value);
    }

    function getEmployeeInfo(uint _employee_number)
        public
        constant
        returns (string _employee_info,uint256 _balance,string _employee_status)
    {
        Employee _employee=employees[_employee_number];
        
        require(_employee.employee_number>0);
        _employee_info=_employee.employee_info;
        
        _employee_status=_employee.employee_status==1?"在职":"离职";
        _balance=balances[_employee.employee_wallet];
        
    }
    
    function transfer(address _to, uint256 _value) public  returns (bool) {
        bool result = super.transfer(_to, _value);
        return result;
    }
}