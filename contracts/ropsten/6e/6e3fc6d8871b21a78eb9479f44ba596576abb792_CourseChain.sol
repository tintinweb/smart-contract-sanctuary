pragma solidity 0.4.24;

contract CourseChain {
    
    address public admin;

    struct OnlineCourse {
        uint price;
        address teacher;
        //uint milestone = 5;
    }
    
    //courseId => onlinecourse
    mapping (uint => OnlineCourse) public listCourse;
    
    struct Order {
        uint courseId;
        uint orderTime;
        address user;
    }
    
    mapping (uint => Order) public listOrder;
    
    uint constant courseTime = 86400;
    
    event AddCourse(uint indexed courseId, uint price, address indexed teacher);
    event BuyCourse(uint indexed courseId, uint indexed orderId, address indexed user);
    event TeacherWithdraw(address indexed teacher, uint priceUnlock, uint indexed orderId);
    event StudentCancel(address indexed teacher, uint indexed orderId, uint priceUnlock);

    // Constructor
    constructor () public {
        admin = msg.sender;
    }

    function addCourse(uint _courseId, uint _price) public {
        listCourse[_courseId] = OnlineCourse(_price, msg.sender);
        emit AddCourse(_courseId, _price, msg.sender);
    }
    
    function buyCourse(uint _courseId, uint _orderId) public{
        require (listCourse[_courseId].price > 0);
        require (msg.value >= listCourse[_courseId].price);
        
        listOrder[_orderId] = Order(_courseId, now, msg.sender);
        emit BuyCourse(_courseId, _orderId, msg.sender);
    }
    
    function withrawFundTeacher(uint _orderId) public payable{
        uint orderTime = listOrder[_orderId].orderTime;
        uint timeFromOrder = now - orderTime;
        uint courseId = listOrder[_orderId].courseId;
        address teacher = listCourse[courseId].teacher;
        uint priceCource = listCourse[courseId].price;
        
        require (listOrder[_orderId].courseId > 0);
        require (msg.sender == teacher);
        require (timeFromOrder < courseTime*5);
        
        
        
        for (uint i = 0; i<5; i++){
            if (timeFromOrder < i*courseTime){
                break;
            }
        }
        uint priceUnlock = i * priceCource / 5;
        teacher.transfer(priceUnlock);
        emit TeacherWithdraw(teacher, priceUnlock, _orderId);
    }
    
    function cancelOrder(uint _orderId) public payable{
        
        
        uint orderTime = listOrder[_orderId].orderTime;
        uint timeFromOrder = now - orderTime;
        uint courseId = listOrder[_orderId].courseId;
        address user = msg.sender;
        uint priceCource = listCourse[courseId].price;
        
        require (listOrder[_orderId].user == user);
        require (timeFromOrder < courseTime*5);
         for (uint i = 0; i<5; i++){
            if (timeFromOrder < i*courseTime){
                break;
            }
        }
        uint priceLock = (5-i) * priceCource / 5;
        user.transfer(priceLock);
        emit StudentCancel(user, _orderId, priceLock);
    }

    function  transferAdmin(address _adminAddr) public {
        require(
            msg.sender == address(admin),
            "Only admin can call this."
        );
        admin = _adminAddr;
    }

}