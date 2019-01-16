pragma solidity 0.4.24;

interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface KyberNetwork {
    function trade(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId) external payable returns(uint);
}

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
    ERC20 constant public ETH_TOKEN_ADDRESS =
        ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    ERC20 constant public DAI_TOKEN = 
        ERC20(0x00ad6d458402f60fd3bd25163575031acdce07538d);
    
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
    
    function buyCourse( uint _courseId, uint _orderId, 

  
        uint maxDestAmount,
        uint minConversionRate,
        KyberNetwork kyberNetworkProxy) payable public{
            
        require (listCourse[_courseId].price != 0);
        
        
       // require(src == ETH_TOKEN_ADDRESS);
        
        uint paidAmout = kyberNetworkProxy.trade.value(msg.value)(ETH_TOKEN_ADDRESS,msg.value,DAI_TOKEN,address(this),
                                                maxDestAmount,minConversionRate,
                                                0x0);
                                                
        require (paidAmout >= listCourse[_courseId].price);                                                 
                                                
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
        
        DAI_TOKEN.transferFrom(msg.sender,this,priceUnlock);
        //teacher.transfer(priceUnlock);
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
        DAI_TOKEN.transferFrom(user,this,priceLock);
        //user.transfer(priceLock);
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