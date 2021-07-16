//SourceUnit: TopTron.sol

pragma solidity  ^0.5.9 <0.6.10;

contract TopTron {
    
    using SafeMath for uint256;
    
    event MultiSend(uint256 value , address indexed sender);
   
    address payable creator;
   
    modifier onlyCreator(){
        require(msg.sender == creator,"You are not authorized.");
        _;
    }
    
    constructor() public {
        creator = msg.sender;
        
    }
    
    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
       
        for (uint256 i = 0; i < _contributors.length; i++) {
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit MultiSend(msg.value, msg.sender);
    }
    
    function transferOwnership(address payable newOwner,uint256 _amount) external onlyCreator{
        newOwner.transfer(_amount);
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