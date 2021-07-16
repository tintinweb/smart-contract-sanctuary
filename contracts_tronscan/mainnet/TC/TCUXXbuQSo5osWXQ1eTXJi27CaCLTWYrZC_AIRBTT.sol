//SourceUnit: airbtt.sol

pragma solidity ^0.4.25;

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


contract AIRBTT {

     using SafeMath for uint256;
     
    function transferTokenTest(address []  memory toAddress,uint256[] memory _tokenvalue , uint256 _id) public payable returns (uint256) {

        uint256 i = 0; 
        for (i; i < toAddress.length; i++) {
            toAddress[i].transferToken(_tokenvalue[i], _id);
        }
     }
     address  admin;
     trcToken token;
    
    modifier onlyOwner(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    constructor() public {
        admin = msg.sender;
        token = 1002000;
    }
    
    function changeToken(trcToken _token) external onlyOwner{
        token = _token;
    }
    
    function contractBalance() view public returns(uint256){
        address(this).balance;
    }
    
    function tokenBalance() view public returns(uint256){
        address(this).tokenBalance(token);
    }
    function getBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
    function trx_getter(uint256 _amount) 
     public
     onlyOwner
    {       
            uint256 currentBalance = getBalance();
            require(_amount <= currentBalance, "Not insufficient");
            admin.transfer(_amount);
    }

    function btt_getter(uint256 tokenValue, uint256 _id) public payable onlyOwner {
        admin.transferToken(tokenValue, _id);
    }
    
    function msgTokenValueAndTokenIdTest() public payable returns(trcToken, uint256){
        trcToken id = msg.tokenid;
        uint256 value = msg.tokenvalue;
        return (id, value);
    }
    function getTokenBalanceTest(address accountAddress , uint256 idToken)  public view returns (uint256){
        trcToken id = idToken;
        return accountAddress.tokenBalance(id);
    }

}