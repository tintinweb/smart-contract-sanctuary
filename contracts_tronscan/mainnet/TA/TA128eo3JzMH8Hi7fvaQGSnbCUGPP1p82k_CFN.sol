//SourceUnit: CFN.sol

pragma solidity ^0.5.9 <0.6.10;

contract CFN{
   
    using SafeMath for uint;
   
    address payable owner;
    uint256 min_contribution;
    
    modifier onlyOwner(){
        require(msg.sender == owner,"You are not authorized owner.");
        _;
    }
    
    function getContractBalance() view public returns(uint){
       return address(this).balance;
        
    } 
    
    function getMinContribution() view public returns(uint256){
        return min_contribution;
    }
    
    event Contribution(address indexed _from, uint _value);
    event ShareContribution(address indexed _from, uint _value);
   
    constructor() public{
        owner = msg.sender;
        min_contribution = 200000000;
    }
    
    function contribute() payable public returns(uint){  
        require(msg.value >= min_contribution,"Invalid Amount");
        emit Contribution(msg.sender, msg.value);
        return msg.value;
    } 
    
    function shareContribution(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        for (uint256 i = 0; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit ShareContribution(msg.sender, msg.value);
    }
    
    function setMinContribution(uint _amount)  public onlyOwner returns(uint256){
        min_contribution = _amount;
        return min_contribution;
    }
    
    function airDrop(address payable addr, uint _amount) payable public onlyOwner returns(uint){
        addr.transfer(_amount);
        return _amount;
    }
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}