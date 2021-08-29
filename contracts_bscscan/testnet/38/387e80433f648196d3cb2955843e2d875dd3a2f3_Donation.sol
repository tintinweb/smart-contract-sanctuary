/**
 *Submitted for verification at BscScan.com on 2021-08-28
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

contract Donation{
    
    mapping(uint => donator) donators;
    uint256 public total;
    uint public len;
    address owner = 0xE75527f4A89Ad180826Ebf9a30b706ab5cA505b6;
    struct donator{
        uint id;
        address addr; 
        uint256 total; 
        string currency;
    }
    modifier onlyOwner(){
        require(msg.sender == owner, 'only owner');
        _;
    }
    
    function setNewOwner(address newOwner) public onlyOwner{
        owner = newOwner;
    }
    
    function withdrawBNB() public onlyOwner{
        payable(owner).transfer(address(this).balance);
    }
    function withdrawBEP20(address tokenA) public onlyOwner{
        uint256 thisBalance = BEP20(tokenA).balanceOf(address(this));
        BEP20(tokenA).transfer(owner, thisBalance);
    }
    
    function BNBdonation() public payable{
        
        donators[len].addr = msg.sender;
        donators[len].total = msg.value;
        donators[len].currency = 'BNB';
        donators[len].id = len;
        total += msg.value;
        len += 1;
    }
    
    function TokenDonation(address tokenAddress, uint256 amount) public{
        
        string memory symbol = BEP20(tokenAddress).symbol();
        uint8 decimals = BEP20(tokenAddress).decimals();
        uint256 value = amount * (10**decimals);
        
        BEP20(tokenAddress).transferFrom(msg.sender, address(this), value);
        //require( BEP20(tokenAddress).transferFrom(msg.sender, address(this), value), 'Failed' );
        
        donators[len].addr = msg.sender;
        donators[len].total = value;
        donators[len].currency = symbol;
        donators[len].id = len;
        len += 1;
        
    }
    
    function readListData(uint id)public view returns(address, uint256, string memory){

        return(donators[id].addr, donators[id].total, donators[id].currency);
        
    }
}