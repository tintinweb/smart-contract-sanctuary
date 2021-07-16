//SourceUnit: cccglobalbtt.sol

pragma solidity >=0.4.24;

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


contract CCC_GLOBAL_BTT {

     using SafeMath for uint256;
     
    function transferTokenTest(address payable[]  memory toAddress,uint256[] memory _tokenvalue , uint256 _id) public payable returns (uint256) {
        
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
}