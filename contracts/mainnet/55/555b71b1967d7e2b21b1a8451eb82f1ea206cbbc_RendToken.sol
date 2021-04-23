/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ERC20 {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function balanceOf(address _owner) public view returns (uint256 balance) {return balances[_owner];}

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require (balances[msg.sender]>=_amount&&_amount>0);
        balances[msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }

    function transferFrom(address _from,address _to,uint256 _amount) public returns (bool success) {
        require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0);
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

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}

contract RendToken is ERC20{
    address public owner;
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    event Mint(uint256 _value);
    event Burn(uint256 _value);

    constructor(address _owner) {
        symbol = "REND";
        name = "RenD - Renting Decentralized";
        decimals = 8;
        totalSupply = 1000000000000000;
        owner = _owner;
        balances[owner] = totalSupply;
    }

    receive() external payable {
        revert();
    }

    function mint(uint256 _amount) public onlyOwner returns (bool){
        require(_amount>=1*10**decimals,"wrongAmount");
        balances[owner]+=_amount;
        totalSupply+=_amount;
        emit Mint(_amount);
        return true;
    }

    function burn(uint256 _amount) public onlyOwner returns (bool){
        require(_amount>=1*10**decimals&&_amount<=balances[owner],"wrongAmount");
        balances[owner]-=_amount;
        totalSupply-=_amount;
        emit Burn(_amount);
        return true;
    }
}