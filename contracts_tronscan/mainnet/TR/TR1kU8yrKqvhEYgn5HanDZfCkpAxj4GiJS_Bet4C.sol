//SourceUnit: bet4c.sol

pragma solidity ^0.5.9;

contract Bet4C{
   
    using SafeMath for uint;
    uint amount;
    uint adminCharge = 5;
    uint investmentAmt = 1000000;
    uint adminShare;
    uint depAmt;
    uint rewardAmt;
    address payable public owner;
    address payable admin;
    
    struct User{
        address userid;
        uint balances;
        uint tranxAmt;
        uint timestamp;
        string remark;
    }
    
    mapping (address => User) internal users;
    
    modifier strict(){
        require(msg.sender == owner,"You are not authorized owner.");
        _;
    }
    
    //Getters
    function changeOwner(address payable newOwner) public strict{
        owner = newOwner;
    }
    
    function checkWallet(address addr) public view returns(uint){
        User storage user = users[addr];
        return user.balances;
    }
    
    function getContractBalance() view public returns(uint){
       return address(this).balance;
        
    } 
    
    //Events
    event Deposit(address indexed _from, uint _admin, uint _value);
    event Withdraw(address indexed _from, uint _value);
    event Income(address indexed _from, uint _value);
   
    constructor(address payable _admin) payable public{
        owner = address(this);
        admin = _admin;
    }
    
    //Fallback
    function() payable external{
        msg.sender.call.value(msg.value);
       
    }
    
    //Setters
    function deposit() payable public returns(uint){  
        User storage user = users[msg.sender];
        require(msg.value == investmentAmt,"Invalid Investment Amount"); 
        user.userid = msg.sender;
        adminShare = msg.value.mul(adminCharge).div(100);
        admin.transfer(adminShare);
        depAmt = msg.value.sub(adminShare);
        user.balances = user.balances.add(depAmt);
        user.tranxAmt = msg.value;
        user.remark = "User Deposited";
        user.timestamp = now;
        emit Deposit(msg.sender, adminShare, msg.value);
        amount = msg.value;
        
    }  
    
    function addIncome(address winner, uint income) public returns(uint){  
        User storage user = users[winner];
        user.balances = user.balances.add(income);
        user.tranxAmt = income;
        user.remark = "Income Added";
        user.timestamp = now;
        emit Income(winner,income);
        return income;
    }  
      
    function withdraw(uint _amount) payable public returns(uint){
        User storage user = users[msg.sender];
        amount = _amount;
        require(address(this).balance > 0 && address(this).balance >= amount,"Withdraw amount exhausted.");
        
        address payable receiver = address(uint160(msg.sender));
        user.balances = user.balances.sub(amount);
        user.timestamp = now;
        user.remark = "User Withdraw";
        emit Withdraw(msg.sender, amount);
        receiver.transfer(amount);
        return amount;
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