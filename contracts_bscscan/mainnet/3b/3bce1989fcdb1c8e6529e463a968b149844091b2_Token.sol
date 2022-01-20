/**
 *Submitted for verification at BscScan.com on 2022-01-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;


contract Token {
    
    //Tax Addresses
    address target_1 = 0xeB46756a26F58837Df192F378859AAbf4cE20639;
    address target_2= 0x5932e31bc7231d61d939e63d02E17627ce77112c;
    
    //Events 
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    
    //Variables
    string public name = "CHEFORAMA";
    string public symbol = "CHEF";
    uint public decimals = 18;
    uint public totalSupply = 5000000000*10**18;
    address owner;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping (address => uint) public balances;
    mapping (address => bool) public isBlacklisted; //Tracks blacklisted addresses
    mapping (address => bool) public taxExcluded; //Tracks adresses excluded from paying tax (applicable for the address sending tokens)
    
    constructor () {
	owner = msg.sender;
    balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view returns(uint256){
        return balances[_owner];
    }
    
    function ChangeOwner (address _newOwner) OnlyOwner public {
	owner = _newOwner;
    }
    
    function ShowOwner () public view returns(address) {
        return owner;
    }

    modifier OnlyOwner () {
	require(msg.sender == owner, "You can not call this function");
	_;
    }
    
   function ChangeTarget (uint256 _target, address _newTarget) OnlyOwner public {
	if (_target == 1){target_1  = _newTarget;}
	if (_target == 2){target_2 = _newTarget;}
   }

    //Add address to blacklist
    function addToBlackList(address _account) external OnlyOwner {
        isBlacklisted[_account] = true;
    }
    //Remove an address from blacklist
    function removeFromBlackList(address _account) external OnlyOwner {
        isBlacklisted[_account] = false;
    }

    //Disable tax payment for an address
    function excludeFromTax(address _account) external OnlyOwner {
        taxExcluded[_account] = true;
    }
    //Enable tax for certain address
    function addToTax(address _account) external OnlyOwner {
        taxExcluded[_account] = false;
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(balances[msg.sender] >= _amount, 'balance too low');
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(_spender != address(0));
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        require(_amount <= balances[_from], 'balance too low');
        require(_amount <= allowed[_from][msg.sender], 'insufficient allowance');
        allowed[_from][msg.sender] -=_amount;
        _transfer(_from, _to, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function _transfer(address _from, address _to, uint256 _amount) internal {
        require(_to != address(0), 'invalid receiving address'); 
        require(!isBlacklisted[_from] && !isBlacklisted[_to], "This address is blacklisted");

        if (taxExcluded[_from] == true) {
            balances[_from] -=_amount;
            balances[_to] +=_amount;
        }
        else{
        
            uint ShareX = _amount/25;
            uint ShareY = _amount/50;

            balances[_from] -=_amount ;
            balances[_to] += _amount - ShareX -ShareY ; 
            balances[target_1] += ShareX ;
            balances[target_2] += ShareY ;

        }

        emit Transfer(_from,_to,_amount);   
    }
}