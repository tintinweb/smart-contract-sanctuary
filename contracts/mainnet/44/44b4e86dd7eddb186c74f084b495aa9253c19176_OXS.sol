/**
 *Submitted for verification at Etherscan.io on 2020-11-19
*/

//**OX's Staking platfrom 
//**SPDX-License-Identifier: none

pragma solidity 0.7.1;


contract Owned {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    address owner;
    address newOwner;
    function changeOwner(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

//
//** ERC20 contract
//** Information

contract ERC20 {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    function balanceOf(address _owner) view public returns (uint256 balance) {return balances[_owner];}
    
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require (balances[msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        balances[msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
  
    function transferFrom(address _from,address _to,uint256 _amount) public returns (bool success) {
        require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        balances[_from]-=_amount;
        allowed[_from][msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}


//** Token information
//** Supply, Decimal, Name, Symbol
contract OXS  is Owned,ERC20{
    uint256 public maxSupply;

    constructor(address _owner) {
        symbol = "OXS";
        name = "OXsign";
        decimals = 10;                                    
        totalSupply = 210000000000000;           
        maxSupply   = 210000000000000;           
        owner = _owner;
        balances[owner] = totalSupply;
    }
    
    receive() external payable {
        revert();
    }
    
   
}