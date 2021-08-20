/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

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
    address _owner = 0xE75527f4A89Ad180826Ebf9a30b706ab5cA505b6;
    

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    constructor(){
        token = address(this);
    }
    
    
    function setNewOwner(address _newOwner) public onlyOwner{
        _owner = _newOwner;
    }
    
    function owner() public view returns(address){
        return _owner;
    }
    
    
    function setToken(address thisToken) public onlyOwner{
        token = thisToken;
    }
    
    function addBalance(uint256 newBalance) public onlyOwner{
        newBalance = newBalance * (10**9);
        balance += newBalance;
    }
    
    function sendToken( address receiver, uint256 _amounts_) private{
        balance -= sold;
        sold += _amounts_;
        BEP20(token).transfer(receiver, _amounts_);
    }
    
    function buyToken() public payable{
        uint256 value = msg.value / (10**18);
        address sender = msg.sender;
        uint256 calculate = value * PRICE;
        require(balance > calculate, 'Not enough tokens');
        sendToken( sender, calculate );
    }
    
    function withdrawEther() public onlyOwner{
        require(address(this).balance != 0, 'Not have ether balance');
        payable(_owner).transfer(address(this).balance);
    }
    
    function withdrawToken(uint256 __value) public onlyOwner{
        sendToken( _owner, __value );
    } 
    
}