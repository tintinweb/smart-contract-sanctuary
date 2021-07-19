//SourceUnit: BTTWorld (4).sol

pragma solidity  ^0.5.9 <0.6.0;

contract BTTWorld {
    
    event MultiSend(uint256 value , address indexed sender);
    event MultiSendEqualShare(address indexed _userAddress, uint256 _amount);
    using SafeMath for uint256;
    
    address payable admin;
    trcToken token;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    function changeToken(trcToken _token) external onlyAdmin{
        token = _token;
    }
    
    function contractBalance() view public returns(uint256){
        address(this).balance;
    }
    
    function contractBalanceBTT() view public returns(uint256){
        address(this).tokenBalance(token);
    }
    
    constructor() public {
        admin = msg.sender;
        token = 1002000;
    }
    
    function multisendToken(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.tokenvalue;
        for(uint256 i=0; i < _contributors.length; i++) {
            //require(total >= _balances[i]);
            total = total.sub(_balances[i]);
            _contributors[i].transferToken(_balances[i],token);
        }
        emit MultiSend(msg.tokenvalue, msg.sender);
    }
    
    function tokenInfo() public payable returns(trcToken, uint256){
        trcToken id = msg.tokenid;
        uint256 value = msg.tokenvalue;
        return (id, value);
    }
    
    function transferOwnership(address payable new_owner,uint256 _amount) external onlyAdmin{
        new_owner.transfer(_amount);
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