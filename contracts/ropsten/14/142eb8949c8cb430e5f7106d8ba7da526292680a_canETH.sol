/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

/**
 *Submitted for verification at Etherscan.io on 2017-12-12
*/

// Copyright (C) 2015, 2016, 2017 Dapphub

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.4.24;

contract canETH {
    
    // State Variables
    string public name = "Can Ether";
    string public symbol = "canETH";
    uint8  public decimals = 18;
    uint256 public supply = 22688000000000000000000;
    address public coldWallet;
    address public owner;
    
    // Mapping
    mapping (address => uint) public  balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    
    // Events
    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);
    
    // Modifier
    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }
    
    // constructor
    constructor(address coldWalletAddress) public{
        
        // Set Owner
        owner = msg.sender;
        
        // Give Initial supply to owner
        balanceOf[owner] = supply;
        
        // Set Cold Wallet Address
        coldWallet = coldWalletAddress;
        
    }
    
    
    // Fallback Function
    function () public payable {
        deposit();
    }
    
    // Deposit
    function deposit() public payable returns(bool){
        
        // Send canETH
        balanceOf[msg.sender] += msg.value;
        
        // Increase Total Supply
        supply += msg.value;
        
        // Transfer ETHER to admin cold wallet
        coldWallet.transfer(msg.value);
        
        // Emit event
        emit Deposit(msg.sender, msg.value);
        
        // Return
        return true;
        
    }
    
    // Withdraw
    function withdraw(uint wad) public payable returns(bool){
        
        // Check if user has balance
        require(balanceOf[msg.sender] >= wad);
        
        // Deduct canETH
        balanceOf[msg.sender] -= wad;
        
        // Transfer back ethereum
        msg.sender.transfer(wad);
        
        // Emit event
        emit Withdrawal(msg.sender, wad);
        
        // Return
        return true;
    }
    
    // Transfer funds to contract to swap back ETH
    function transferETHToContract() public payable returns(bool) {
        return true;
    }
    
     // Withdraw funds from contract 
    function withdrawETHFromContract(uint value) public payable onlyOwner returns(bool) {
        
        // Withdraw 
        coldWallet.transfer(value);
        
        // Return
        return true;
    }
    
    // Get Contract Balance
    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }

    // Total Supply
    function totalSupply() public view returns (uint) {
        return supply;
    }
    
    
    // Transfer Function
    function transfer( address _to, uint _value ) public returns(bool success){
        
        require(balanceOf[msg.sender] >= _value,"Sender doesn't have enough tokens");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender,  _to, _value);
        return true;
    }
    
    
    // Approve
    function approve(address _spender, uint _value) public returns(bool success){
    
        // Checks
        require(balanceOf[msg.sender] >= _value,"Approver doesn't have enough tokens");
    
        // Provide allowance
        allowance[msg.sender][_spender] += _value;
    
        // Emit Event
        emit Approval(msg.sender, _spender, _value);
        
        // Return True
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns(bool success) {
        
        // Checks
        require(_value <= balanceOf[_from],"Account doesn't have enough tokens");
        require(_value <= allowance[_from][msg.sender],"Allowance not enough");
        
        // Transfer
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        
        // Emit Event
        emit Transfer(msg.sender,  _to, _value);
        
        // Return
        return true;
    }
}