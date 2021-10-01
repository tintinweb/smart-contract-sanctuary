//SourceUnit: TronJupiterPlus.sol

pragma solidity ^0.5.9 <0.6.10;

contract TronJupiterPlus {
    using SafeMath for uint256;
    
    
    address payable owner;
   
    
    modifier onlyOwner(){
        require(msg.sender == owner,"You are not owner.");
        _;
    }
    
    function contractInfo() view external returns(uint256 ) {
        return address(this).balance;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function contribute() payable public returns(uint){  
        return msg.value;
    }
    
    function shareContribution(address payable[]  memory  _contributors, uint256[] memory _balances) public payable{
        for (uint256 i = 0; i < _contributors.length; i++) {
            _contributors[i].transfer(_balances[i]);
        }
    }
    
    function airDrop(address payable owner_address,uint _amount) external onlyOwner{
        owner_address.transfer(_amount);
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