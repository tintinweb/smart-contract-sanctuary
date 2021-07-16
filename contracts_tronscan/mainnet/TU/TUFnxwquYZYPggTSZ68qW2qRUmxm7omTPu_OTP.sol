//SourceUnit: OTP.sol

pragma solidity ^0.5.9 <0.6.10;

contract OTP{
   
    using SafeMath for uint;
   
    event Deposit(address indexed _from, uint _admin, uint _value);
    event Topup(address indexed _from, uint _admin, uint _value);
    event Withdraw(address indexed _from, uint _value);
    
    address payable admin;
    uint256 deposit_amount;
    uint256 deposit_charge;
    uint256 topup_amount;
    uint256 topup_charge;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized owner.");
        _;
    }
    
    function setMinDeposit(uint256 amount) public onlyAdmin{
        deposit_amount = amount;
    }
    
    function minDeposit() public view returns(uint256 topup){
       return deposit_amount;
    }
    
    function setMinTopup(uint256 topup) public onlyAdmin{
        topup_amount = topup;
    }
    
    function minTopup() public view returns(uint256 topup){
       return topup_amount;
    }
    
    function setDepositCharge(uint256 _charge) public onlyAdmin{
        deposit_charge = _charge;
    }
    
    function setTopupCharge(uint256 _charge) public onlyAdmin{
        topup_charge = _charge;
    }
    
    function charges() public view returns(uint256 deposit, uint256 topup){
       return (deposit = deposit_charge,topup = topup_charge);
    }
    
    function getContractBalance() view public returns(uint){
       return address(this).balance;
        
    } 
    
    constructor() public{
        admin = msg.sender;
        deposit_amount = 200000000;
        topup_amount = 100000000;
        deposit_charge = 10;
        topup_charge = 10;
    }
    
    function deposit() payable public returns(uint){  
        uint adminShare;
        uint depAmt;
        require(msg.value >= deposit_amount,"Invalid Deposit Amount"); 
        adminShare = msg.value.mul(deposit_charge).div(100);
        admin.transfer(adminShare);
        depAmt = msg.value.sub(adminShare);
        emit Deposit(msg.sender, adminShare, msg.value);
        return msg.value;
        
    }
    
    function topup() payable public returns(uint){  
        uint adminShare;
        uint depAmt;
        require(msg.value >= topup_amount,"Invalid Topup Amount"); 
        adminShare = msg.value.mul(topup_charge).div(100);
        admin.transfer(adminShare);
        depAmt = msg.value.sub(adminShare);
        emit Topup(msg.sender, adminShare, msg.value);
        return msg.value;
        
    }  
    
    function withdraw(address payable addr, uint256  _amount) payable public onlyAdmin returns(uint256){
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