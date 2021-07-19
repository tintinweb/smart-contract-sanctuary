//SourceUnit: TronExpress.sol

pragma solidity 0.5.4;

contract TronExpress {
    struct User {
        uint256 Id;
        uint256 deposit_amount;
        uint256 total_deposits;
    }
    
    uint256 [] deposite_amountarr;
    uint256 [] deposite_pakgrr;
    uint40 p = 0;

    address payable public owner;

    mapping(address => User) public users;

    mapping(address => mapping(uint256 => uint256)) public userdepositeamount;
    uint256[] public levels;
    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public last_id;
    event NewDeposit(address indexed addr, uint256 amount);
    event Multisended(address indexed addr, uint256 amount);


    constructor(address payable _owner) public {
        
         
        levels.push(50 trx);
        levels.push(75 trx);
        levels.push(150 trx);
        levels.push(400 trx);
        levels.push(900 trx);
        levels.push(2100 trx);
        levels.push(5200 trx); 
        
        levels.push(500 trx);
        levels.push(1000 trx);
        levels.push(2000 trx);
        levels.push(4000 trx);
        levels.push(8000 trx);
        levels.push(16000 trx);
         
       
        owner = _owner;
        last_id=1;
        users[owner].Id=last_id;
    }
    modifier onlyOwner(){
        require(msg.sender==owner,"onlyOwner can call!");
        _;
    }
    
    

    
        function _chakowner() public view returns(address _owneraddress){

            return owner;  
        
    }
     function Register( uint256 _packageId) payable external {
        
        require(msg.value == levels[_packageId], "Invalid _amount");
        require(msg.value == 50 trx, "Invalid _amount");
        require(users[msg.sender].Id == 0  || checkuserdeposite(msg.sender , msg.value) == 1 , "User Already Register");
        users[msg.sender].deposit_amount = msg.value;
        users[msg.sender].total_deposits +=  msg.value;
       deposite_pakgrr.push( _packageId);
        deposite_amountarr.push( msg.value);
        userdepositeamount[msg.sender][p]=msg.value;
        users[msg.sender].Id = ++last_id;
        p++;
        total_deposited += msg.value;
        emit NewDeposit(msg.sender,  msg.value);
        }

    
    function upgrade( uint256 _packageId) payable external 
    {
        require(msg.value == levels[_packageId], "Invalid _amount");
        require( checkuserdeposite(msg.sender , msg.value) == 1 , "User Already deposite");
        require(users[msg.sender].Id > 0  , "You are not register");
            users[msg.sender].deposit_amount = msg.value;
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
    function transferROI(uint256 _amount,address payable _addr) payable public  {
        require(_amount > 0, "Zero payout");
         require (msg.value == _amount ,"not have Balance!") ;
    
        _addr.transfer(_amount);
    }
   
     function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i],"Invalid Amount");
            total = total - _balances[i];
            _contributors[i].transfer(_balances[i]);
        }
        emit Multisended( msg.sender , msg.value);
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
    function userInfo(address _addr) view external returns(  uint256 deposit_amount, uint256 UserID) {
        return ( users[_addr].deposit_amount,users[_addr].Id);
    }
 
}