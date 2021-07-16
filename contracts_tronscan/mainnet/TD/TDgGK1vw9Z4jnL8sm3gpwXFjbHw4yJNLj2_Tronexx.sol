//SourceUnit: tronexx.sol

pragma solidity 0.5.14;

contract Tronexx {
    
    using SafeMath for uint256;
    

    struct User {
        uint256 Id;
        address payable upline;
        uint256 referrals;
        uint256 deposit_amount;
        uint40 deposit_time;
    }
    
    address payable public owner;

    mapping(address => User) public users;

    mapping(address => mapping(uint256 => uint256)) public userdepositeamount;
    uint256[] public levels;
    uint256 public total_users = 1;
    uint256 public last_id;
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);


    constructor(address payable _owner) public {
        
        
        levels.push(50 trx);
        levels.push(250 trx);
        levels.push(500 trx);
        levels.push(1000 trx);
        levels.push(2500 trx);
        levels.push(5000 trx);
        levels.push(10000 trx);
        levels.push(25000 trx);
        
        
        owner = _owner;
        last_id=1;
        users[owner].Id=last_id;
    }
    modifier onlyOwner(){
        require(msg.sender==owner,"onlyOwner can call!");
        _;
    }
    
    function _setUpline(address _addr, address payable _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;

        }
    }

      function _chakUpline( address _upline) public view returns(bool){
        if(users[msg.sender].upline == address(0) && _upline != msg.sender && msg.sender != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {

            return true;  

        }
    }
        function _chakowner() public view returns(address _owneraddress){

            return owner;  
        
    }

    
    function Register(address payable _upline, uint256 _packageId) payable external {
        
 
        _setUpline(msg.sender, _upline);
        require(users[msg.sender].upline != address(0) || msg.sender == owner, "No upline");
        require(msg.value == levels[_packageId], "Invalid _amount");
        require(msg.value == 50 trx, "Invalid _amount");
        require(users[msg.sender].Id == 0  , "User Already Register");
        users[msg.sender].Id =last_id + 1;
        users[msg.sender].deposit_amount = msg.value;
        users[msg.sender].deposit_time = uint40(block.timestamp);
        emit NewDeposit(msg.sender,  msg.value);
         last_id++;
        
        }
    
        function upgrade(uint256 _packageId) payable external{
        
        require(users[msg.sender].Id > 0  , "You are not register");
        require(msg.value == levels[_packageId], "Invalid _amount");
            users[msg.sender].deposit_amount = msg.value;
        users[msg.sender].deposit_time = uint40(block.timestamp);
        emit NewDeposit(msg.sender,  msg.value);
        }

    
    function getuserId(address _Address) public view returns(uint256 userid){
        
        return users[_Address].Id; 
    
    }
    
    
    function userexists(address _addres) public view returns(bool){
        
        if( users[_addres].Id >= 1){
            
        return true; 
        }
        else{
            
            return false;
        }
    
    }
    function transferROI(uint256 _amount,address payable _addr) payable public  {
        require(_amount > 0, "Zero payout");
         require (msg.value == _amount ,"not have Balance!") ;
         
        _addr.transfer(_amount);
    }
   
    

    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
    }
    
    function withdrawal(uint256 amount) public onlyOwner {
        
        require(amount <= address(this).balance , "not have Balance");
        require(amount >= 0 , "not have Balance");
        
       
        owner.transfer(amount*(10**6));
    }
    
    function checkcontractbalance() public view returns(uint256) {
        require(address(this).balance > 0, "Zero payout");
       
        return address(this).balance;
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline,  uint256 deposit_amount) {
        return (users[_addr].upline, users[_addr].deposit_amount);
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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