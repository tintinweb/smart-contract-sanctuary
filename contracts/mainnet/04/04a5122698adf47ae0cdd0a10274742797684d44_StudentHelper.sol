pragma solidity ^0.4.23;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor() public {
        owner = msg.sender;
    }

  /**
   * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
/**
 * @title SafeMath32
 * @dev SafeMath library implemented for uint32
 */
library SafeMath32 {

    function mul(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) {
            return 0;
       }
        uint32 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint32 a, uint32 b) internal pure returns (uint32) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint32 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        assert(b <= a);
        return a - b;
    }

    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title SafeMath16
 * @dev SafeMath library implemented for uint16
 */
library SafeMath16 {

    function mul(uint16 a, uint16 b) internal pure returns (uint16) {
        if (a == 0) {
            return 0;
        }
        uint16 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint16 a, uint16 b) internal pure returns (uint16) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint16 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        assert(b <= a);
        return a - b;
    }

    function add(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
        assert(c >= a);
        return c;
    }
}
contract StudentFactory is Ownable{

    struct Student{
        string name;// 姓名
        string nation;// 民族
        string id;// 证件号
        uint32 birth;// 生日
        bytes1 gender;// 性别
    } 
    
    struct Undergraduate{
        string studentId; // 学籍号
        string school;// 学校 
        string major;// 专业
        uint8 length;// 学制
        uint8 eduType;// 学历类别
        uint8 eduForm;// 学习形式
        uint8 class;// 班级
        uint8 level;// 层次(专/本/硕/博)
        uint8 state;// 学籍状态
        uint32 admissionDate;// 入学日期
        uint32 departureDate;// 离校日期
    }

    struct Master{
        string studentId; // 学籍号
        string school;// 学校 
        string major;// 专业
        uint8 length;// 学制
        uint8 eduType;// 学历类别
        uint8 eduForm;// 学习形式
        uint8 class;// 班级
        uint8 level;// 层次(专/本/硕/博)
        uint8 state;// 学籍状态
        uint32 admissionDate;// 入学日期
        uint32 departureDate;// 离校日期
    }

    struct Doctor{
        string studentId; // 学籍号
        string school;// 学校 
        string major;// 专业
        uint8 length;// 学制
        uint8 eduType;// 学历类别
        uint8 eduForm;// 学习形式
        uint8 class;// 班级
        uint8 level;// 层次(专/本/硕/博)
        uint8 state;// 学籍状态
        uint32 admissionDate;// 入学日期
        uint32 departureDate;// 离校日期
    }

    struct CET4{
        uint32 time; //时间，如2017年12月
        uint32 grade;// 分数
    }

    struct CET6{
        uint32 time; //时间，如2017年12月
        uint32 grade;// 分数
    }

    Student[] students;// 学生列表
    CET4[] CET4List; // 四级成绩列表
    CET6[] CET6List; // 六级成绩列表
    mapping (address=>Student) public addrToStudent;// 地址到学生的映射
    mapping (uint=>address) internal CET4IndexToAddr; // 四级成绩序号到地址的映射
    mapping (uint=>address) internal CET6IndexToAddr; // 六级成绩序号到地址的映射
    mapping (address=>uint) public addrCET4Count; //地址到四级成绩数量映射
    mapping (address=>uint) public addrCET6Count; //地址到六级成绩数量映射
    mapping (address=>Undergraduate) public addrToUndergaduate;// 地址到本科学籍的映射
    mapping (address=>Master) public addrToMaster;// 地址到硕士学籍的映射
    mapping (address=>Doctor) public addrToDoctor;// 地址到博士学籍的映射
   
    // 定义判断身份证是否被使用的modifier
    modifier availableIdOf(string _id) {
        require(_isIdExisted(_id));
        _;
    }

    // 判断证件号码是否已注册
    function _isIdExisted(string _id) private view returns(bool){
        for(uint i = 0;i<students.length;i++){
            if(keccak256(students[i].id)==keccak256(_id)){
                return false;
            }
        }
        return true;
    }

    // 创建学生
    function createStudent(string _name,string _nation,string _id,uint32 _birth,bytes1 _gender) public availableIdOf(_id){
        Student memory student = Student(_name,_nation,_id,_birth,_gender);
        addrToStudent[msg.sender] = student;
        students.push(student);
    }
}
contract StudentHelper is StudentFactory{
    using SafeMath for uint;
    // 给某个地址的人添加本科学籍信息
    function addUndergraduateTo(address _addr,string _studentId,string _school,string _major,uint8 _length,uint8 _eduType,uint8 _eduForm,uint8 _class,uint8 _level,uint8 _state,uint32 _admissionDate,uint32 _departureDate) 
    public onlyOwner{
        addrToUndergaduate[_addr] = Undergraduate(_studentId,_school,_major,_length,_eduType,_eduForm,_class,_level,_state,_admissionDate,_departureDate);
    }

    // 给某个地址的人添加硕士学籍信息
    function addMasterTo(address _addr,string _studentId,string _school,string _major,uint8 _length,uint8 _eduType,uint8 _eduForm,uint8 _class,uint8 _level,uint8 _state,uint32 _admissionDate,uint32 _departureDate) 
    public onlyOwner{
        addrToMaster[_addr] = Master(_studentId,_school,_major,_length,_eduType,_eduForm,_class,_level,_state,_admissionDate,_departureDate);
    }

    // 给某个地址的人添加博士学籍信息
    function addDoctorTo(address _addr,string _studentId,string _school,string _major,uint8 _length,uint8 _eduType,uint8 _eduForm,uint8 _class,uint8 _level,uint8 _state,uint32 _admissionDate,uint32 _departureDate) 
    public onlyOwner{
        addrToDoctor[_addr] = Doctor(_studentId,_school,_major,_length,_eduType,_eduForm,_class,_level,_state,_admissionDate,_departureDate);
    }

    // 给某个地址添加四级成绩记录
    function addCET4To(address _addr,uint32 _time,uint32 _grade) public onlyOwner{
        uint index = CET4List.push(CET4(_time,_grade))-1;
        CET4IndexToAddr[index] = _addr;
        addrCET4Count[_addr]++;
    }

    // 给某个地址添加六级成绩记录
    function addCET6To(address _addr,uint32 _time,uint32 _grade) public onlyOwner{
        uint index = CET6List.push(CET6(_time,_grade))-1;
        CET6IndexToAddr[index] = _addr;
        addrCET6Count[_addr]++;
    }

    // 获得某个地址的四级成绩
    function getCET4ByAddr(address _addr) view public returns (uint32[],uint32[]) {
        uint32[] memory timeList = new uint32[](addrCET4Count[_addr]); 
        uint32[] memory gradeList = new uint32[](addrCET4Count[_addr]);
        uint counter = 0;    
        for (uint i = 0; i < CET4List.length; i++) {
            if(CET4IndexToAddr[i]==_addr){
                timeList[counter] = CET4List[i].time;
                gradeList[counter] = CET4List[i].grade;
                counter++;
            }
        }
        return(timeList,gradeList);
    }

    // 获得某个地址的六级成绩
    function getCET6ByAddr(address _addr) view public returns (uint32[],uint32[]) {
        uint32[] memory timeList = new uint32[](addrCET6Count[_addr]); 
        uint32[] memory gradeList = new uint32[](addrCET6Count[_addr]);
        uint counter = 0;    
        for (uint i = 0; i < CET6List.length; i++) {
            if(CET6IndexToAddr[i]==_addr){
                timeList[counter] = CET6List[i].time;
                gradeList[counter] = CET6List[i].grade;
                counter++;
            }
        }
        return(timeList,gradeList);
    }
}