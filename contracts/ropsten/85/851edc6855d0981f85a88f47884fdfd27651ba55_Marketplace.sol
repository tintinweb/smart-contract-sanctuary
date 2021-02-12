/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

pragma solidity ^0.6.0;
// SPDX-License-Identifier: UNLICENSED

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 *
*/

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

contract Marketplace is Owned{
    
    using SafeMath for uint256;
    
    struct User{
        uint256 id;
        address wallet;
        Category category; 
    }
    
    struct Order{
        uint256 payment;
        address buyer;
        address seller;
        uint256 lastUpdated;
        string description;
        Status status;
    }
    
    mapping(address => User) public users;
    mapping(uint256 => Order) public orders;
    mapping (address => bool) internal admins;
    
    uint256 usersCount;
    uint256 orderNo;
    
    enum Category{None, Buyer, Seller, Both}
    enum Status{DoesNotExist, Initiated, Delivered, Completed, Cancelled, Disputed}
    
    event Registered(address _wallet, Category _category, uint256 _identifier);
    event NewOrder(uint256 _orderNo, address _buyer, address _seller, uint256 _amount);
    event Delivered(uint256 _orderNo);
    event Completed(uint256 _orderNo);
    event Cancelled(uint256 _orderNo, address _by);
    event FundsReleased(uint256 _orderNo, address _to);
    event DisputeOpened(uint256 _orderNo, address _by, string _message);
    event AdminAdded(address _newAdmin);
    event AdminRemoved(address _removedAdmin);
    
    function Register_as_Buyer(address _wallet) external{
        register(_wallet, Category.Buyer);
    }
    
    function Register_as_Seller(address _wallet) external{
        register(_wallet, Category.Seller);
    }
    
    function Buy(address _seller, uint256 _payment, string memory _orderDescription) 
    external payable 
    isBuyer isSeller(_seller) sufficientPayment(_payment){
        orderNo += 1;
        orders[orderNo].buyer = msg.sender;
        orders[orderNo].seller = _seller;
        orders[orderNo].lastUpdated = block.timestamp;
        orders[orderNo].payment = _payment;
        orders[orderNo].description = _orderDescription;
        orders[orderNo].status = Status.Initiated;
        
        // payment will be added to escrow at this time
        emit NewOrder(orderNo, msg.sender, _seller, _payment);
    }

    function DeliverOrder(uint256 _orderNo) external validSeller(_orderNo) validOrder(_orderNo){
        orders[_orderNo].status = Status.Delivered;
        orders[_orderNo].lastUpdated = block.timestamp;
        emit Delivered(_orderNo);
    }
    
    function CompleteOrder(uint256 _orderNo) external validBuyer(_orderNo) validOrder(_orderNo){
        require(orders[_orderNo].status != Status.Completed, "Order is already completed");
        
        orders[_orderNo].status = Status.Completed;
        orders[_orderNo].lastUpdated = block.timestamp;
        
        // release payment
        payable(orders[_orderNo].seller).transfer(orders[_orderNo].payment);
        
        emit Completed(_orderNo);
        emit FundsReleased(_orderNo, orders[_orderNo].seller);
    }
    
    function RequestFunds(uint256 _orderNo) external validOrder(_orderNo) validSeller(_orderNo){
        require(orders[_orderNo].status != Status.Completed, "Order is already completed");
        require(orders[_orderNo].status == Status.Delivered, "Order is not delivered");
        require(orders[_orderNo].status != Status.Disputed, "Order is in dispute");
        require(orders[_orderNo].lastUpdated.add(3 days) <= block.timestamp, "Payment can be claimed after 3 days of delivery");
        
        // release payment
        payable(orders[_orderNo].seller).transfer(orders[_orderNo].payment);
        
        emit FundsReleased(_orderNo, orders[_orderNo].seller);
    }
    
    function OpenDispute(uint256 _orderNo, string memory _description) external {
        require(orders[_orderNo].seller == msg.sender || orders[_orderNo].buyer == msg.sender, "UnAuthorized");
        orders[_orderNo].description = _description;
        orders[_orderNo].status = Status.Disputed;
        
        emit DisputeOpened(orderNo, msg.sender, _description);
    }
    
    function CancelOrder(address _releasePaymentTo, uint256 _orderNo) external onlyAdmin {
        require(orders[_orderNo].status != Status.Completed, "Order is already completed");
        orders[_orderNo].status = Status.Cancelled;
        // recheck the receiver is either buyer or seller
        require(orders[_orderNo].buyer == _releasePaymentTo || 
        orders[_orderNo].seller == _releasePaymentTo , "The receiver is neither buyer nor seller");
        // release payment to buyer/seller
        payable(_releasePaymentTo).transfer(orders[_orderNo].payment);
        
        emit Cancelled(orderNo, msg.sender);
    }
    
    function AddAdmin(address _admin) external onlyOwner{
        admins[_admin] = true;   
        emit AdminAdded(_admin);
    }
    
    function RemoveAdmin(address _admin) external onlyOwner{
        admins[_admin] = false;   
        emit AdminRemoved(_admin);
    }
    
    function register(address _wallet, Category _category) internal {
        require(_wallet == msg.sender, "please register with your desired wallet");
        
        // check if already registered in same category
        require(users[msg.sender].category != _category, "Already registered");
        
        // increment the users count
        usersCount += 1;
        
        // check if already registered but in different category
        if(users[msg.sender].category != Category.None && users[msg.sender].category != _category){
            _category = Category.Both;
            usersCount -= 1;
        }
        
        users[msg.sender].category = _category;
        users[msg.sender].wallet = _wallet;
        users[msg.sender].id = usersCount;
        
        emit Registered(_wallet, _category, usersCount);
    }
    
    modifier onlyAdmin{
        require(admins[msg.sender], "Only Admin is allowed");
        _;
    }
    
    modifier validSeller(uint256 _orderNo){
        require(orders[_orderNo].seller == msg.sender, "UnAuthorized");
        _;
    }
    
    modifier validBuyer(uint256 _orderNo){
        require(orders[_orderNo].buyer == msg.sender, "UnAuthorized");
        _;
    }
    
    modifier validOrder(uint256 _orderNo){
        require(orders[orderNo].status != Status.DoesNotExist, "Invalid Order No");
        _;
    }
    
        
    modifier isBuyer{
        require(users[msg.sender].category == Category.Buyer || users[msg.sender].category == Category.Both, "un-registered buyer");
        _;
    }
    
    modifier isSeller(address _seller){
        require(users[_seller].category == Category.Seller || users[msg.sender].category == Category.Both, "un-registered seller");
        _;
    }
    
    modifier sufficientPayment(uint256 _payment){
        require(_payment <= msg.value, "Insufficient payment");
        _;
    }
}