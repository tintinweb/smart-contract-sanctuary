//SourceUnit: OyesTronProTopup.sol

pragma solidity ^0.5.9;


contract OyesTronProTopup{
   
    using SafeMath for uint;
   
    address payable admin;
    uint256 min_topup;
    uint256 admin_charge;
    
    struct User{
        uint balance;
        uint timestamp;
        
    }
    
    mapping (address => User) public users;
   
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized owner.");
        _;
    }
    
    function setMinTopup(uint256 topup) public onlyAdmin{
        min_topup = topup;
    }
    
    function minTopup() public view returns(uint256 topup){
       return min_topup;
    }
    
    function setAdminCharge(uint256 _admin_charge) public onlyAdmin{
        admin_charge = _admin_charge;
    }
    
    function adminCharge() public view returns(uint256 topup){
       return admin_charge;
    }
    
    
    function checkWallet(address addr) public view returns(uint){
        User storage user = users[addr];
        return user.balance;
    }
    
    function getContractBalance() view public returns(uint){
       return address(this).balance;
        
    } 
    
    function adminAddress() view public returns(address){
        return admin;
    }
    
    //Events
    event Deposit(address indexed _from, uint _admin, uint _value);
    event Withdraw(address indexed _from, uint _value);
    
    constructor() public{
        
        admin = msg.sender;
        min_topup = 100000000;
        admin_charge = 10;
    }
    
   
    
    //Setters
    function deposit() payable public returns(uint){  
        
        uint adminShare;
        uint depAmt;
        User storage user = users[msg.sender];
        require(msg.value >= min_topup,"Invalid Topup Amount"); 
        
        adminShare = msg.value.mul(admin_charge).div(100);
        admin.transfer(adminShare);
        depAmt = msg.value.sub(adminShare);
        user.balance = user.balance.add(depAmt);
        
        user.timestamp = now;
        emit Deposit(msg.sender, adminShare, msg.value);
        return msg.value;
        
    }  
    
    function addIncome(address winner, uint income) internal returns(uint){  
        User storage user = users[winner];
        user.balance = user.balance.add(income);
        user.timestamp = now;
        return income;
    }  
     
      
    function withdraw(address payable addr, uint _amount) payable public onlyAdmin returns(uint){
        User storage user = users[addr];
        addIncome(addr,_amount);
        user.balance = user.balance.sub(_amount);
        user.timestamp = now;
        addr.transfer(_amount);
        emit Withdraw(addr, _amount);
        return _amount;
    }
    
    
    
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}