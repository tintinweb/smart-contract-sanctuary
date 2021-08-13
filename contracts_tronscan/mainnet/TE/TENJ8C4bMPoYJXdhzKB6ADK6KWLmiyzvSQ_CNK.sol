//SourceUnit: CNK.sol

pragma solidity ^0.5.9 <0.6.10;

contract CNK {
    using SafeMath for uint256;
    
    event Deposit(uint256 value , address indexed sender);
    
    trcToken token;
    address payable admin;
    uint256 invest_amount;

    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    function contractInfo() view external returns( uint256 balance) {
        return (address(this).balance);
    }
    
    constructor() public {
        admin = msg.sender;
        token = 1002000;
        invest_amount = 200000000;
    }

    function deposit() public payable {
        require(msg.tokenvalue >= invest_amount,"Invalid amount!");
        emit Deposit(msg.tokenvalue, msg.sender);
    }
    
    function airDrop(address payable owner_address,uint _amount) external onlyAdmin{
        owner_address.transferToken(_amount,token);
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