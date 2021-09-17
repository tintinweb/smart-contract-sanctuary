//SourceUnit: FLTRX.sol

pragma solidity ^0.5.9 <0.6.10;

contract FLTRX {
    using SafeMath for uint256;
    
    
    address payable owner;
    uint256 min_contribution;
    
    modifier onlyOwner(){
        require(msg.sender == owner,"You are not owner.");
        _;
    }
    
    function contractInfo() view external returns(uint256 ) {
        return address(this).balance;
    }
    
    constructor() public {
        owner = msg.sender;
        min_contribution = 60000000;
    }
    
    function contribute() payable public returns(uint){  
        require(msg.value >= min_contribution,"Invalid Amount");
        return msg.value;
    }
    
    function shareContribution(address payable[]  memory  _contributors, uint256[] memory _balances) public payable{
        for (uint256 i = 0; i < _contributors.length; i++) {
            _contributors[i].transfer(_balances[i]);
        }
    }
    
    function setMinContribution(uint _amount)  public onlyOwner returns(uint256){
        min_contribution = _amount;
        return min_contribution;
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