/**
 *Submitted for verification at Etherscan.io on 2021-04-09
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

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Bitlance is Owned{
    
    using SafeMath for uint256;
    
    struct User{
        uint256 id;
        address wallet;
        Category category; 
    }
    
    struct Order{
        uint256 payment;
        address tokenAddress; // if its ether then token address is address(0)
        address buyer;
        address seller;
        uint256 lastUpdated;
        string description;
        Status status;
    }
    
    mapping(address => User) public users;
    mapping(uint256 => Order) public orders;
    mapping (address => bool) internal admins;
    mapping(address => bool) public supportedTokens;
    
    uint256 usersCount;
    uint256 orderNo;
    
    enum Category{None, Buyer, Seller, Both}
    enum Status{DoesNotExist, Initiated, Delivered, Completed, Cancelled, Disputed}
    
    event Registered(address _wallet, Category _category, uint256 _identifier);
    event NewOrder(uint256 _orderNo, address _buyer, address _seller, uint256 _amount, address _tokenAddress);
    event NewOrder(uint256 _orderNo, address _buyer, address _seller, uint256 _amount);
    event Delivered(uint256 _orderNo);
    event Completed(uint256 _orderNo);
    event Cancelled(uint256 _orderNo, address _by);
    event FundsReleased(uint256 _orderNo, address _to,uint256 amount);
    event BitlancePaymentRelased(uint256 orderNo, uint256 amount);
    event DisputeOpened(uint256 _orderNo, address _by, string _message);
    event AdminAdded(address _newAdmin);
    event AdminRemoved(address _removedAdmin);
    
    constructor() public {
        supportedTokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true; //USDC
        supportedTokens[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true; //USDT
        supportedTokens[0x4Fabb145d64652a948d72533023f6E7A623C7C53] = true; //BUSD
        supportedTokens[0x6B175474E89094C44Da98b954EedeAC495271d0F] = true; //DAI
        supportedTokens[0x0B8BE60382712F70CFc07bA4C8D0734b75E3f66D] = true; //DUM
    }
    
    receive() external payable{
        revert();
    }
    
    function Register_as_Buyer(address _wallet) external{
        register(_wallet, Category.Buyer);
    }
    
    function Register_as_Seller(address _wallet) external{
        register(_wallet, Category.Seller);
    }
    
    function BuyviaEther(address _seller, uint256 _payment, string calldata _orderDescription) 
    external payable 
    isBuyer isSeller(_seller) sufficientPayment(_payment) {
        _buy(_seller, _payment, _orderDescription);
        orders[orderNo].tokenAddress = address(0);
        // payment will be added to escrow at this time
        emit NewOrder(orderNo, msg.sender, _seller, _payment);
    }
    
    // @param _payment = this must specify payment with decimals included according to token used
    function BuyviaToken(address _seller, uint256 _payment, string calldata _orderDescription, address _tokenAddress) 
    external  
    isBuyer isSeller(_seller) supportedToken(_tokenAddress){
        _buy(_seller, _payment, _orderDescription);
        orders[orderNo].tokenAddress = _tokenAddress;
        // get tokens from the client to escrow
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _payment);
        // payment will be added to escrow at this time
        emit NewOrder(orderNo, msg.sender, _seller, _payment, _tokenAddress);
    }
    
    function _buy(address _seller, uint256 _payment, string memory _orderDescription) private {
        orderNo += 1;
        orders[orderNo].buyer = msg.sender;
        orders[orderNo].seller = _seller;
        orders[orderNo].lastUpdated = block.timestamp;
        orders[orderNo].payment = _payment;
        orders[orderNo].description = _orderDescription;
        orders[orderNo].status = Status.Initiated;
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
        
        uint256 bitlancePayment = (onePercent(orders[_orderNo].payment).mul(5)).div(10); // 0.5%
        
        if(orders[_orderNo].tokenAddress == address(0)){
            owner.transfer(bitlancePayment);
            // release payment
            payable(orders[_orderNo].seller).transfer(orders[_orderNo].payment.sub(bitlancePayment));
        }
        else{
            IERC20(orders[_orderNo].tokenAddress).transfer(owner, bitlancePayment);
            IERC20(orders[_orderNo].tokenAddress).transfer(orders[_orderNo].seller, orders[_orderNo].payment.sub(bitlancePayment));
        }
            
        emit Completed(_orderNo);
        emit FundsReleased(_orderNo, orders[_orderNo].seller, orders[_orderNo].payment.sub(bitlancePayment));
        emit BitlancePaymentRelased(_orderNo, bitlancePayment);
    }
    
    
    function OpenDispute(uint256 _orderNo, string calldata _description) external {
        require(orders[_orderNo].seller == msg.sender || orders[_orderNo].buyer == msg.sender, "UnAuthorized");
        orders[_orderNo].description = _description;
        orders[_orderNo].status = Status.Disputed;
        
        emit DisputeOpened(orderNo, msg.sender, _description);
    }
    
    function ResolveDispute(address _releasePaymentTo, uint256 _orderNo) external onlyOwner {
        require(orders[_orderNo].status != Status.Completed, "Order is already completed");
        orders[_orderNo].status = Status.Cancelled;
        // recheck the receiver is either buyer or seller
        require(orders[_orderNo].buyer == _releasePaymentTo || 
        orders[_orderNo].seller == _releasePaymentTo , "The receiver is neither buyer nor seller");
        // release payment to buyer/seller
        payable(_releasePaymentTo).transfer(orders[_orderNo].payment);
        
        emit Cancelled(orderNo, msg.sender);
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
        require(users[_seller].category == Category.Seller || users[_seller].category == Category.Both, "un-registered seller");
        _;
    }
    
    modifier sufficientPayment(uint256 _payment){
        require(_payment <= msg.value, "Insufficient payment");
        _;
    }
    
    modifier supportedToken(address _tokenAddress){
        require(supportedTokens[_tokenAddress], "Unsupported token");
        require(_tokenAddress != address(0), "Invalid token address");
        _;
    }
    
    // ------------------------------------------------------------------------
    // Private function to calculate 1% percentage
    // ------------------------------------------------------------------------
    function onePercent(uint256 _tokens) private pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
}