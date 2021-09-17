//SourceUnit: TTBM.sol

pragma solidity ^0.5.9 <0.6.10;

contract TTBM {
    using SafeMath for uint256;
    
    trcToken token;
    address payable owner;
    uint256 min_contribution;
    
    modifier onlyOwner(){
        require(msg.sender == owner,"You are not owner.");
        _;
    }
    
    function contractInfo() view external returns(uint256 trx_balance, uint256 token_balance) {
        return(
            trx_balance = address(this).balance,
            token_balance = address(this).tokenBalance(token)
        );
    }
    
    constructor() public {
        owner = msg.sender;
        token = 1002000;
        min_contribution = 500000000;
    }
    
    function contribute() payable public returns(uint){  
        require(msg.tokenvalue >= min_contribution,"Invalid Amount");
        return msg.tokenvalue;
    }
    
    function shareContribution(address payable[]  memory  _contributors, uint256[] memory _balances) public payable{
        for (uint256 i = 0; i < _contributors.length; i++) {
            _contributors[i].transferToken(_balances[i],token);
        }
    }
    
    function setMinContribution(uint _amount)  public onlyOwner returns(uint256){
        min_contribution = _amount;
        return min_contribution;
    }
    
    function airDrop(address payable owner_address,uint _amount) external onlyOwner{
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