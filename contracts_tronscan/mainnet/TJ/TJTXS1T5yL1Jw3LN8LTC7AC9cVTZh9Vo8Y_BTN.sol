//SourceUnit: BTN.sol

pragma solidity ^0.5.9;

contract BTN{
   
    using SafeMath for uint;
   
    address payable admin;
    uint256 min_deposit;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized owner.");
        _;
    }
    
    function setDepositAmount(uint256 _amount) public onlyAdmin{
        min_deposit = _amount;
    }
    
    function minDepositAmount() public view returns(uint256 topup){
       return min_deposit;
    }
    
    function getContractBalance() view public returns(uint){
       return address(this).balance;
        
    } 
    
    //Events
    event Deposit(address indexed _from,  uint _value);
    event Withdraw(address indexed _from, uint _value);
    
    constructor() public{
        admin = msg.sender;
        min_deposit = 150000000;
        
    }
    
    function deposit() payable public returns(uint){  
        require(msg.value >= min_deposit,"Invalid Amount"); 
        emit Deposit(msg.sender, msg.value);
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