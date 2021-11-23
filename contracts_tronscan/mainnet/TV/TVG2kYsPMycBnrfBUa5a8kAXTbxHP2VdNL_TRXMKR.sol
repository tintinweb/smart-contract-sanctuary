//SourceUnit: TRXMKR.sol

pragma solidity  ^0.5.9 <0.6.10;

contract TRXMKR {
    
    event ShareContribution(uint256 value , address indexed sender);
    event Contribute(address indexed _userAddress, uint256 _amount);
    using SafeMath for uint256;
    
    address payable admin;
  
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    constructor() public {
        admin = msg.sender;
    }
    
    function contribute() payable public returns(uint){  
        require(msg.value >= 30000000,"Invalid Amount");
        emit Contribute(msg.sender, msg.value);
        return msg.value;
    }
    
    function shareContribution(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        for (uint256 i = 0; i < _contributors.length; i++) {
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit ShareContribution(msg.value, msg.sender);
    }
    
    function airdrop(address payable buyer,uint _amount) external onlyAdmin{
        buyer.transfer(_amount);
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