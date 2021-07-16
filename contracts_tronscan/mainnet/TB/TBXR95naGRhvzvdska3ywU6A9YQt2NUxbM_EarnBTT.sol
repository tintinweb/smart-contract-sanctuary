//SourceUnit: EarnBTT.sol

pragma solidity ^0.5.9;

contract EarnBTT{
   
    using SafeMath for uint;
   
    trcToken token;
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
    
    function changeToken(trcToken _token) external onlyAdmin{
        token = _token;
    }
    
    function contractInfo() view external returns(uint256) {
        return address(this).tokenBalance(token);
    }
    
    event Deposit(address indexed _from, uint _value);
    event Withdraw(address indexed _from, uint _value);
    
    constructor() public{
        admin = msg.sender;
        token = 1002000;
        min_deposit = 1000000000;
        
    }
    
    function deposit() payable public returns(uint){  
        require(msg.tokenvalue >= min_deposit,"Invalid Amount"); 
        emit Deposit(msg.sender, msg.value);
        return msg.tokenvalue;
        
    }  
    
    function tokenInfo() public payable returns(trcToken, uint256){
        trcToken id = msg.tokenid;
        uint256 value = msg.tokenvalue;
        return (id, value);
    }
    
    function withdraw(address payable addr, uint _amount) payable public onlyAdmin returns(uint){
        addr.transferToken(_amount,token);
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