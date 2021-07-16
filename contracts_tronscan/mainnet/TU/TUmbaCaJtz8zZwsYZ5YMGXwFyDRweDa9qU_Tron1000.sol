//SourceUnit: Tron1000.sol

pragma solidity 0.5.10;

contract Tron1000 {
    struct User {
        uint256 Id;
        address upline;
        uint256 referrals;
        uint256 deposit_amount;
        uint40 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
    }
    
    
    uint256 [] deposite_amountarr;
    uint256 [] deposite_pakgrr;
    uint40 p = 0;


    address payable public owner;

    mapping(address => User) public users;

                      // 1 => 1%
    mapping(address => mapping(uint256 => uint256)) public userdepositeamount;
 
    uint256[] public levels;
    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public last_id;
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);


    constructor(address payable _owner) public {
        
        levels.push(1000 trx);
        levels.push(1400 trx);
        levels.push(3500 trx);
        levels.push(8000 trx);
        levels.push(20000 trx);
        levels.push(40000 trx);
        levels.push(80000 trx);
        levels.push(150000 trx);
        levels.push(5000 trx);
        levels.push(20000 trx);
        levels.push(50000 trx);
        levels.push(120000 trx);
        levels.push(250000 trx);
        levels.push(600000 trx);
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

    function Register(address payable _upline, uint256 _packageId) payable external {
        

        _setUpline(msg.sender, _upline);
        require(users[msg.sender].upline != address(0) || msg.sender == owner, "No upline");
        require(msg.value == levels[_packageId], "Invalid amount");
        require(msg.value == 1000 trx, "Invalid amount");
        require(users[msg.sender].Id == 0  || checkuserdeposite(msg.sender , msg.value) == 1 , "User Already Register");
        
        
        users[msg.sender].deposit_amount = msg.value;
        
        users[msg.sender].deposit_time = uint40(block.timestamp);
        users[msg.sender].total_deposits +=  msg.value;
      
       
       deposite_pakgrr.push( _packageId);
        deposite_amountarr.push( msg.value);
        
        userdepositeamount[msg.sender][p]=msg.value;
        
        users[msg.sender].Id = ++last_id;
        
        uint256 referralreward = msg.value * 98 / 100;
        _upline.transfer(referralreward);
        p++;
        
        total_deposited += msg.value;
        emit NewDeposit(msg.sender,  msg.value);
        }
    
    
    
        function upgrade(uint256 _packageId) payable external{
        
        require(users[msg.sender].Id > 0  , "You are not register");
        require(checkuserdeposite(msg.sender , msg.value) == 1 , "User Already deposite");
            users[msg.sender].deposit_amount = msg.value;
        
        users[msg.sender].deposit_time = uint40(block.timestamp);
        users[msg.sender].total_deposits +=  msg.value;
        
        deposite_pakgrr.push( _packageId);
        deposite_amountarr.push( msg.value);
        
        userdepositeamount[msg.sender][p]=msg.value;
        p++;
        
        
        total_deposited += msg.value;
        emit NewDeposit(msg.sender,  msg.value);
        
        }

    
    function checkuserdeposite(address add , uint256 valu) internal view returns(uint256){
        
        uint256 g;
        for(uint256 z ; z <= deposite_amountarr.length; z++){
            
            if(userdepositeamount[add][z] == valu){
                
                 g = 0;
                 break;
            }
            else
            {
                g = 1;
            }
        
        }

            return g;
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
        _addr.transfer(_amount*(10**6));
    }
   
     function multiple_transfer_ROI(address payable [] calldata userAddress,uint256[] calldata _amount) external onlyOwner {
        
        uint8 i = 0;
        for (i; i < userAddress.length; i++) {
            userAddress[i].transfer(_amount[i]*(10**6));
        
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
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 UserID) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount,users[_addr].Id);
    }
 
}