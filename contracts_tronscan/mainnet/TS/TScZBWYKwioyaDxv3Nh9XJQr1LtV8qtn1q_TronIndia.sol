//SourceUnit: Tronindia.sol

pragma solidity 0.5.4;

contract TronIndia {
    struct User {
        uint256 Id;
        
        address upline;
        uint256 referrals;
        uint256 deposit_amount;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
    }

    address payable public owner;

    mapping(address => User) public users;

    uint8[] public ref_bonuses;                     // 1 => 1%
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
 //   mapping(uint8 => address) public pool_top;
    uint256[] public levels;
    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public last_id;
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
  //  event DirectPayout(address indexed addr, address indexed from, uint256 amount);
//    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
  //  event PoolPayout(address indexed addr, uint256 amount);
   // event Withdraw(address indexed addr, uint256 amount);
//    event LimitReached(address indexed addr, uint256 amount);

    constructor(address payable _owner) public {
        levels.push(550 trx);
        levels.push(600 trx);
        levels.push(1400 trx);
        levels.push(2500 trx);
        levels.push(4500 trx);
        levels.push(12500 trx);
        levels.push(15000 trx);
        levels.push(25000 trx);
        levels.push(40000 trx);
        levels.push(100000 trx);
        levels.push(200000 trx);
        levels.push(1000000 trx);
        levels.push(5000000 trx);
        
        owner = _owner;
        last_id=1;
        users[owner].Id=last_id;
    }
    modifier onlyOwner(){
        require(msg.sender==owner,"onlyOwner can call!");
        _;
    }
    function _setUpline(address _addr, address _upline) private {
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

    function _deposit(uint256 _value, address _addr, uint256 _packageId) private {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");
        require(_value == levels[_packageId], "Invalid amount");
        
        users[_addr].deposit_amount = _value;
        
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits +=  _value;
        users[_addr].Id = ++last_id;
        total_deposited += _value;
        emit NewDeposit(_addr,  _value);

    }
    
    function Upgrade(uint256 _packageid) payable external  {
       
        require(users[msg.sender].Id >= 1, "user not exists");
        require(msg.value == levels[_packageid], "Invalid amount");
        
        users[msg.sender].deposit_amount = msg.value;
        
        users[msg.sender].deposit_time = uint40(block.timestamp);
        users[msg.sender].total_deposits +=  msg.value;
        users[msg.sender].Id = ++last_id;
        total_deposited += msg.value;
        emit NewDeposit(msg.sender,  msg.value);

    }

    function deposit(address _upline,uint256 packageId) payable external {
        _setUpline(msg.sender, _upline);
        _deposit(msg.value,msg.sender,packageId);
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

    function transferROI(uint256 _amount,address payable _addr) external onlyOwner {
        require(_amount > 0, "Zero payout");
        users[msg.sender].total_payouts += _amount;
        _addr.transfer(_amount);
    }
    
    function withdrawal(uint256 amount) external onlyOwner {
        require(address(this).balance > 0, "Zero Balance");
        require(amount < address(this).balance , "not have Balance");
       
        owner.transfer(amount*10^6);
    }
    
    function chkowner() public view returns(uint256) {
        require(address(this).balance > 0, "Zero payout");
       
        return address(this).balance;
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 UserID) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount,users[_addr].Id);
    }
 
}