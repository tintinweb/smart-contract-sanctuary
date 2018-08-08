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
    using SafeMath for uint;
    struct Status{
        string studentId; // 学籍号
        string schoolId;// 学校 
        string majorId;// 专业
        uint8 length;// 学制
        uint8 eduType;// 学历类别
        uint8 eduForm;// 学习形式
        uint8 level;// 层次(专/本/硕/博)
        uint8 state;// 学籍状态
        uint16 class;// 班级
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

    CET4[] CET4List; // 四级成绩列表
    CET6[] CET6List; // 六级成绩列表

    mapping (uint=>uint32) internal CET4IndexToId; // 四级成绩序号到地址的映射
    mapping (uint=>uint32) internal CET6IndexToId; // 六级成绩序号到地址的映射
    mapping (uint32=>uint) public idCET4Count; //地址到四级成绩数量映射
    mapping (uint32=>uint) public idCET6Count; //地址到六级成绩数量映射
    
    mapping (uint32=>Status) public idToUndergaduate;// 地址到本科学籍的映射
    mapping (uint32=>Status) public idToMaster;// 地址到硕士学籍的映射
    mapping (uint32=>Status) public idToDoctor;// 地址到博士学籍的映射
   
    
    function addUndergraduate(uint32 _id,string _studentId,string _schoolId,string _majorId,uint8 _length,uint8 _eduType,uint8 _eduForm,uint8 _level,uint8 _state,uint16 _class,uint32 _admissionDate,uint32 _departureDate)
    public onlyOwner{
        idToUndergaduate[_id] = Status(_studentId,_schoolId,_majorId,_length,_eduType,_eduForm,_level,_state,_class,_admissionDate,_departureDate);
    }
    
    function addMaster(uint32 _id,string _studentId,string _schoolId,string _majorId,uint8 _length,uint8 _eduType,uint8 _eduForm,uint8 _level,uint8 _state,uint16 _class,uint32 _admissionDate,uint32 _departureDate)
    public onlyOwner{
        idToMaster[_id] = Status(_studentId,_schoolId,_majorId,_length,_eduType,_eduForm,_level,_state,_class,_admissionDate,_departureDate);
    }
    
    function addDoctor(uint32 _id,string _studentId,string _schoolId,string _majorId,uint8 _length,uint8 _eduType,uint8 _eduForm,uint8 _level,uint8 _state,uint16 _class,uint32 _admissionDate,uint32 _departureDate)
    public onlyOwner{
        idToDoctor[_id] = Status(_studentId,_schoolId,_majorId,_length,_eduType,_eduForm,_level,_state,_class,_admissionDate,_departureDate);
    }


    // 给某个地址添加四级成绩记录
    function addCET4(uint32 _id,uint32 _time,uint32 _grade) public onlyOwner{
        uint index = CET4List.push(CET4(_time,_grade))-1;
        CET4IndexToId[index] = _id;
        idCET4Count[_id]++;
    }

    // 给某个地址添加六级成绩记录
    function addCET6(uint32 _id,uint32 _time,uint32 _grade) public onlyOwner{
        uint index = CET6List.push(CET6(_time,_grade))-1;
        CET6IndexToId[index] = _id;
        idCET6Count[_id]++;
    }

    // 获得某个地址的四级成绩
    function getCET4ById(uint32 _id) view public returns (uint32[],uint32[]) {
        uint32[] memory timeList = new uint32[](idCET4Count[_id]); 
        uint32[] memory gradeList = new uint32[](idCET4Count[_id]);
        uint counter = 0;    
        for (uint i = 0; i < CET4List.length; i++) {
            if(CET4IndexToId[i]==_id){
                timeList[counter] = CET4List[i].time;
                gradeList[counter] = CET4List[i].grade;
                counter++;
            }
        }
        return(timeList,gradeList);
    }

    // 获得某个地址的六级成绩
    function getCET6ById(uint32 _id) view public returns (uint32[],uint32[]) {
        uint32[] memory timeList = new uint32[](idCET6Count[_id]); 
        uint32[] memory gradeList = new uint32[](idCET6Count[_id]);
        uint counter = 0;    
        for (uint i = 0; i < CET6List.length; i++) {
            if(CET6IndexToId[i]==_id){
                timeList[counter] = CET6List[i].time;
                gradeList[counter] = CET6List[i].grade;
                counter++;
            }
        }
        return(timeList,gradeList);
    }
}