/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.16 <0.9.0;

contract PrintUnlimitedUSDT{
    
    string Scamname = "Tether";
    string Scam = "USDT";
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 total;
    
    function name() public view returns (string memory){
        
        return Scamname;
    }
    
    function symbol() public view returns (string memory) {
        
        return Scam;
    }

    //////////////////////////////////////////////////////////////////////////////////////

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    bool Alwaysfalse = false;
    
    function transfer(address _to, uint256 _value) public returns (bool success){
        
        require(Alwaysfalse = true, "You can't send/receive USDT! The transfer button is here so this contract is recognized as an ERC20");
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success){
        
        require(Alwaysfalse = true, "You can't sell USDT! The approve button is here so this contract is recognized as an ERC20");
    }
    
    //////////////////////////////////////////////////////////////////////////////////////
    
    function PrintUSDT(uint HowMany) public payable{
        
        balances[msg.sender] = balances[msg.sender] + HowMany;
    }
}