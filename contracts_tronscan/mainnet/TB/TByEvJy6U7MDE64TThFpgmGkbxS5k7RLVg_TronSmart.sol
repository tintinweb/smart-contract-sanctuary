//SourceUnit: TronSmart.sol

pragma solidity  ^0.5.9 <0.6.0;

contract TronSmart {
    
    event Deposit(address indexed _userAddress, uint256 _amount);
    using SafeMath for uint256;
    
    struct Player{
        uint256 balance;
    }
    
    address payable admin;
    mapping(address => Player) public players;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    constructor() public {
        admin = msg.sender;
    }
    
    function deposit() external payable {
        Player storage player = players[msg.sender];
        player.balance.add(msg.value);
        emit Deposit(msg.sender,msg.value);
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