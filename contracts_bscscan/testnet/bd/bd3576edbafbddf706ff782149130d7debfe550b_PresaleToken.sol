/**
 *Submitted for verification at BscScan.com on 2021-08-21
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

interface BEP20 {

  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PresaleToken{
    uint256 public PRICE =  250_000 * (10**9);
    uint256 public balance;
    address public token;
    uint256 public sold;
    bool public enableClaimed;
    address _owner = 0xE75527f4A89Ad180826Ebf9a30b706ab5cA505b6;
    

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyEnabledToClaim() {
        require( enableClaimed , "claim not available for this time");
        _;
    }
    
    mapping (address => uint256) private balanceOf;
    
    constructor(){
        token = address(this);
    }
    
    function setNewOwner(address _newOwner) public onlyOwner{
        _owner = _newOwner;
    }
    
    function owner() public view returns(address){
        return _owner;
    }
    
    function enableToClaim(bool _enableThis) public onlyOwner{
        enableClaimed = _enableThis;
    }
    
    function testBalanceOf(address otherTokenAddress) public view returns(uint256){
        return BEP20(otherTokenAddress).balanceOf(address(this));
    }
    
    function claimToken() public onlyEnabledToClaim{
        require( balanceOf[msg.sender] != 0, 'cant send zero balance');
        sendToken( msg.sender, balanceOf[msg.sender]);
    }
    
    function setToken(address thisToken) public onlyOwner{
        token = thisToken;
    }
    
    function setBalance(uint256 newBalance) public onlyOwner{
        newBalance = newBalance * (10**9);
        balance = newBalance;
    }
    
    function setPrice(uint256 thisPrice) public onlyOwner{
        PRICE = thisPrice * (10**9);
    }
    
    function sendToken( address receiver, uint256 _amounts_) private{
        balanceOf[msg.sender] = 0;
        BEP20(token).transfer(receiver, _amounts_);
    }
    
    function balanceToClaim(address _users) public view returns(uint256){
        return balanceOf[_users];
    }
    
    function sendToClaim( address receiver, uint256 _amounts_) private{
        balance -= _amounts_;
        sold += _amounts_;
        balanceOf[receiver] += _amounts_;
    }
    
    
    function buyToken() public payable{
        
        uint256 value = msg.value ;
        address sender = msg.sender;
        uint256 calculate = value * PRICE;
                calculate = calculate/ (10**18);
        require( calculate < balance, 'Not enough tokens');
            
        sendToClaim( sender, calculate );
    }
    
    function withdrawEther() public onlyOwner{
        //require(address(this).balance != 0, 'Not have ether balance');
        payable(_owner).transfer(address(this).balance);
    }
    
    function withdrawToken(uint256 __value) public onlyOwner{
        uint256 _amountss_ = __value * (10**9);
        balance -= _amountss_;
        sold += _amountss_;
        sendToken( _owner, _amountss_ );
    } 
    
    function withdraw_another_token_if_any(address otherToken, uint256 otherAmount, uint8 otherDecimal) public onlyOwner{
        BEP20(otherToken).transfer(_owner, (otherAmount * (10**otherDecimal)));
    }
    
}