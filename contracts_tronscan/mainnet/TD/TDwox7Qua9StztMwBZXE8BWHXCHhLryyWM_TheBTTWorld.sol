//SourceUnit: TheBTTWorld.sol

pragma solidity ^0.5.9 <0.6.10;

contract TheBTTWorld {
    using SafeMath for uint256;
    
    trcToken token;
    address payable admin;
   
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    event MultiSend(address addr, uint256 _amount);
    
    function changeToken(trcToken _token) external onlyAdmin{
        token = _token;
    } 
    
    function contractInfo() view external returns(uint256 trx_balance, uint256 token_balance) {
        return(
            trx_balance = address(this).balance,
            token_balance = address(this).tokenBalance(token)
        );
    }
    
    constructor() public {
        admin = msg.sender;
        token = 1002000;
    }
    
    function multisendToken(address payable[]  memory  _contributors, uint256[] memory _balances, trcToken _token) public payable {
        require(token==_token,"Invalid token");
        uint256 total = msg.tokenvalue;
        for(uint256 i=0; i < _contributors.length; i++) {
            total = total.sub(_balances[i]);
            _contributors[i].transferToken(_balances[i],_token);
        }
        
        emit MultiSend(msg.sender,msg.tokenvalue);
    }
    
    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable{
        uint256 total = msg.value;
        for (uint256 i = 0; i < _contributors.length; i++) {
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit MultiSend(msg.sender,msg.value);
    }
    
    function tokenInfo() public payable returns(trcToken, uint256){
        trcToken id = msg.tokenid;
        uint256 value = msg.tokenvalue;
        return (id, value);
    }
    
    function transferOwnership(address payable owner_address,uint _amount) external onlyAdmin{
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