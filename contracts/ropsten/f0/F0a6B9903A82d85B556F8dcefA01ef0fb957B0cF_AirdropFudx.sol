/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

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

contract AirdropFudx  {
    
    /* User registers with telegram handle and mobile no (optional)
    Telegram group will brodcast airdrop date and a 4 digit code applicable for a day.
    users will run claimAirdrop fn to claim tokens.
    Tokens will remain with admin who will approve contract to transferFrom 
     
     */
     // The token being sold
    IERC20 private token;

    // User registration
     address admin;
     
     constructor (IERC20 _token) {
         admin = msg.sender;
         token = IERC20(_token);
     }
     struct Users {
         address user;
         string telegram;
         uint256 mobile;
     }
     Users[] users;
     address[] public registered;
     
     mapping (uint256 => Users) registration;
     uint256 public count;
     event Register(address indexed User, uint256 Time);
     
     function register(string calldata _telegram, uint256 _mobile) external {
        require(!_check(msg.sender), "User already registered");
        require(isOpen,"Registration not open");
      
        count++;
        registration[count] = Users(msg.sender, _telegram, _mobile);
        registered.push(msg.sender);
        emit Register(msg.sender, block.timestamp);
        
     }
     
     function _check(address _user) internal returns(bool success) {
        for (uint i = 0; i<users.length; i++) {
            if(users[i].user == _user) {
                return true;
            }
            return false;
        }
        
     }
     function _checkClaimed(address _user) internal returns(bool success) {
        for (uint i = 0; i<claimed.length; i++) {
            if(claimed[i] == _user) {
                return true;
            }
            return false;
        }
        
     }
     
     bool public isOpen;
     
     
     modifier onlyOwner{
      require (msg.sender == admin, "Only Admin");
      _;
     }
     
     function openClose() external onlyOwner {
         if( isOpen) {
             isOpen = false;
         } else {
             isOpen = true;
         }
     }
     
     uint40 code;
     function setCode(uint40 _code) external onlyOwner {
         code = _code;
     }
     
     uint256 tokenAmount;
     function setTokenAmount(uint256 _tokenamount) external onlyOwner {
         tokenAmount = _tokenamount;
     }
     
     function setApprove() public onlyOwner returns(bool success) {
         uint256 xamount = count * tokenAmount;
         require(token.balanceOf(address(this))>= xamount, "Not enough balance in contract");
         return true;
     }
     
     address[] claimed;
     function claimAirdrop(uint40 _code) external returns(bool success) {
         require(!_checkClaimed(msg.sender),"Already claimed tokens");
         require(isOpen, "Airdrop claims not yet open");
         require(code == _code, "Code Incorrect" );
         
         token.transfer( msg.sender, tokenAmount);    
         claimed.push(msg.sender);
         return true;
         
     }
     
     
}