/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RocketCoin{
    address _admin;
    string public NAME;
    string public SYMBOL;
    uint8 public  DECIMALS;
    uint256 public _totalSupply;
    mapping(address => uint) balances;
    event Transfer(address indexed from, address indexed to, uint256 amount);
    mapping(address => mapping(address => uint)) public allowance;
    event Approval(address indexed owner, address indexed spender, uint value);
    constructor (){
        _admin = msg.sender;
        NAME = "RocketCoin";
        SYMBOL = "ROC";
        DECIMALS = 18;
        _totalSupply = 100000000000000000000000000;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
        //create permission
    modifier onlyAdmin{
        require(msg.sender == _admin, "unauthorized");
        _;
    }
    //check balance of Supply
    function totalSupply() public onlyAdmin view returns(uint SupplyBalance)  {
        return balances[_admin];
    }
    //check balance
    function balanceOf(address tokenOwner) public view returns(uint balance){
      return balances[tokenOwner]; 
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}