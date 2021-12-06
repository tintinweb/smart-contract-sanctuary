/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    uint256 _totalSupply=50000;
uint256 constant MAXSUPPLY=1000000;
address minter;
uint256 constant fee=1;

event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner,address indexed _spender, uint256 _value);

event MintershipTransfer(
    address indexed previousMinter,
    address indexed newMinter
);


    mapping (address => uint) public balances;
    mapping (address => mapping(address => uint)) public _allowed;


    constructor() {
      balances[msg.sender] +=_totalSupply;
      minter = msg.sender;
    }

    function totalSupply() public view returns (uint256) { 
        return _totalSupply;
    
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }


    function mint(address receiver, uint256 amount) public returns (bool) {
        require(msg.sender ==minter, "Minting not authorized from this address");
        require(_totalSupply + amount <= MAXSUPPLY,"Total supply higher than max supply");
        _totalSupply = _totalSupply + amount;
        balances[receiver] = balances[receiver] + (amount);
        emit Transfer(address(0), receiver, amount);
        return true;
    }

    function burn(address receiver, uint256 amount) public returns (bool) {
        require(receiver != address(0), "Receiver address error");
        require(amount <= balances[receiver],"Balance to low to enable burn");
        _totalSupply= _totalSupply - (amount);
        balances [receiver] = balances[receiver] - (amount);
        emit Transfer(receiver, address(0), amount);
        return true;
    }

    function transferMintership(address newMinter, address previousMinter) public returns (bool) {
        require(msg.sender == minter, "Only minter can transfer mintership");
        minter = newMinter;
        emit MintershipTransfer(previousMinter, newMinter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender]>=_value + fee,"Sender do not have sufficient funds");
        balances[msg.sender] -=(_value);
        balances[_to] +=fee;
        balances[minter] +=fee;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(fee + _value <= balances[_from],"Not enough funds");
        require(fee + _value <= _allowed[_from][msg.sender],"Not enough funds");
        require(_to !=address(0),"Receiver address error");
        balances[_from] = balances[_from] - (_value);
        balances[_to] = balances[_to] +(_value) - fee;
        balances[minter] +=fee;
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender] - (_value);
        emit Transfer(_from,_to,_value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0),"Spender can't be a void address");
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
       return _allowed[_owner][_spender];
    }
}