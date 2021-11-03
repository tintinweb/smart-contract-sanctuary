/**
 *Submitted for verification at polygonscan.com on 2021-11-03
*/

pragma solidity ^0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract presale {
    
 IERC20 token;
 bool public open = true;
 address payable private _wallet = payable(0x1E00Ef7C8D33e0fC65e7D313C4ccCcFD286b3953); //Replace your wallet address here
 
 address private admin;
 
 mapping(address => uint256) public balance;
 uint256 public constant mincap = 10 * 250 * 100000; // 100 Matic Min contribution
 uint256 public constant maxcap = 1000 * 250 * 100000; // 1000 Matic max contribution
 uint256 private constant hardcap = 500000 * 10**18;
 uint256 private count = 0;
 
                    
 uint256 public rate = 250;
 uint256 div = 10000000000000;
 
 
 constructor ( address _token) {
     token = IERC20(_token);
     admin = msg.sender;
 }
 
 modifier onlyOwner() {
    require(msg.sender == admin,"only for admin");
    _;
  }
 
 function opensale() external onlyOwner {
     open = true;
 }
 
 function closesale() external onlyOwner {
     open = false;
 }
 
 function buytokens() public payable {
     require(open == true,"presale is closed");
     uint256 cnt = (msg.value * rate)/div;
     require(token.balanceOf(address(this)) >= cnt, "not enough tokens");
     require(cnt >= mincap && cnt <= maxcap, "amount is less than minimum or more than maximum");
     require(balance[msg.sender]+cnt <= maxcap,"more than maximum capacity per user");
     count += msg.value;
     balance[msg.sender] += cnt;
     token.transfer(msg.sender,cnt);
     _wallet.transfer(msg.value);
     if(count >= hardcap){
         open = false;
     }
 }
 
 function returnUnusedTokens() external onlyOwner returns(bool success){
     require(open == false,"presale is open");
     token.transfer(admin,token.balanceOf(address(this)));
     return true;
 }
 
 receive() payable external {
     buytokens();
 } 
}