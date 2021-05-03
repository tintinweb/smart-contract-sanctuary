/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.22;

contract ForeignToken {
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract EIP20Interface {
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract FerrasCoin is EIP20Interface, Owned{
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalContribution = 0; // Total que han gastado en ETH
    string public symbol; // Symbolo del Token
    string public name; // Nombre del token
    uint8 public decimals; // # de decimales
    uint256 public _totalSupply = 1300000000; // Suministro máximo
    uint256 public tokensIssued; // Tokens expedidos

    modifier onlyExecuteBy(address _account)
    {
        require(msg.sender == _account);
        _;
    }


    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (_value == 0) { return false; }
        uint256 fromBalance = balances[msg.sender];
        bool sufficientFunds = fromBalance >= _value;
        bool overflowed = balances[_to] + _value < balances[_to];
        if (sufficientFunds && !overflowed) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (_value == 0) { return false; }
        uint256 fromBalance = balances[_from];
        uint256 allowance = allowed[_from][msg.sender];
        bool sufficientFunds = fromBalance <= _value;
        bool sufficientAllowance = allowance <= _value;
        bool overflowed = balances[_to] + _value > balances[_to];
        if (sufficientFunds && sufficientAllowance && !overflowed) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    function withdrawForeignTokens(address _tokenContract) public onlyExecuteBy(owner) returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }

    function withdraw() public onlyExecuteBy(owner) {
        owner.transfer(address(this).balance);
    }

    function getStats() public constant returns (uint256, uint256, uint256) {
        return (totalContribution, _totalSupply, tokensIssued);
    }


    constructor() public {
        owner = msg.sender;
        symbol = "ZAZAZA";
        name = "Ferras Coin";
        decimals = 0;
        uint256 paMi = 9999999;
        tokensIssued += paMi;
        balances[msg.sender] += paMi;
        emit Transfer(address(this), msg.sender, paMi);
    }

    function() payable public {
        uint rate = uint(msg.value / 100000000000000);
        if((tokensIssued + rate) <= _totalSupply){
            owner.transfer(msg.value);
            totalContribution += msg.value;
            tokensIssued += rate;
            balances[msg.sender] += rate;
            emit Transfer(address(this), msg.sender, rate);
        }else{
            revert();
        }
        
    }


    
    event LaDerrama(address indexed _burner, uint256 _value);

    function FerrasYaEstuvo(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] -= _value;
        _totalSupply -= _value;
        emit LaDerrama(burner, _value);
    }





    function getTime() internal constant returns (uint) {
        return now;
    }
}