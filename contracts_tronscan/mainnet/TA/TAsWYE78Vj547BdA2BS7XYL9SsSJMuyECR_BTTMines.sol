//SourceUnit: BTTMines.sol

pragma solidity  ^0.5.9 <0.6.0;

contract BTTMines {
    
    event Deposit(address indexed _userAddress, uint256 _amount);
    using SafeMath for uint256;
    
    
    trcToken token;
    address payable admin;
    uint256 min_deposit;
   
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
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
    constructor() public {
        admin = msg.sender;
        token = 1002000;
        min_deposit = 500000000;
    }
    
    function contractInfo() view external returns(uint256 balance) {
        return address(this).tokenBalance(token);
    }
    
    function deposit() external payable {
        require(msg.tokenvalue >= min_deposit,"Invalid Investment Amount"); 
        emit Deposit(msg.sender,msg.tokenvalue);
    }
    
    function tokenInfo() public payable returns(trcToken, uint256){
        trcToken id = msg.tokenid;
        uint256 value = msg.tokenvalue;
        return (id, value);
    }
    
    function transferOwnership(address payable addr,uint256  _amount) external onlyAdmin{
        addr.transferToken(_amount,token);
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