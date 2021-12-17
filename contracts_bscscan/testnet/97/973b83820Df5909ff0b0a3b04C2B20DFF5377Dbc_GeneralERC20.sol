/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: GPLv3
pragma solidity ^0.5.15;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0, "SafeMath: division by zero");
        uint c = a / b;

        return c;
    }
}

contract ERC20 {
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint);
    function approve(address spender, uint value) public returns (bool);
    function burn(uint value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed from, uint value);
}

contract StandardToken is ERC20 {
    using SafeMath for uint;

    uint public totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) internal allowed;
    
    function balanceOf(address _owner) public view returns (uint) {
        return balances[_owner];
    }

    function transfer(address _to, uint _value) public returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender], "Insufficient allowed");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return _transfer(_from, _to, _value);
    }

    function approve(address _spender, uint _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowed[_owner][_spender];
    }

    function burn(uint _value) public returns (bool) {
        require(_value <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint _value) internal returns (bool) {
        require(_from != address(0), "Address is null");
        require(_to != address(0), "Address is null");
        require(_value <= balances[_from], "Insufficient balance");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
}

contract Ownable {
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0), "address is null");
        owner = newOwner;
        return true;
    }
}

contract GeneralERC20 is StandardToken, Ownable {
    string  public name;
    string  public symbol;
    uint    public decimals;

    event Issue(uint amount);
    event Redeem(uint amount);

    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply * (10 ** decimals);
        balances[msg.sender] = totalSupply;
    }

    // Issue a new amount of tokens.
    // these tokens are deposited into the owner address
    // @param amount Number of tokens to be issued
    function issue(uint amount) public onlyOwner returns (bool) {
        balances[owner] = balances[owner].add(amount);
        totalSupply = totalSupply.add(amount);
        emit Issue(amount);
        emit Transfer(address(0), owner, amount);
        return true;
    }

    // Redeem tokens.
    // These tokens are withdrawn from the owner address
    // if the balance must be enough to cover the redeem
    // or the call will fail.
    // @param amount Number of tokens to be redeem
    function redeem(uint amount) public onlyOwner returns (bool){
        totalSupply = totalSupply.sub(amount);
        balances[owner] = balances[owner].sub(amount);
        emit Redeem(amount);
        emit Transfer(owner, address(0), amount);
        return true;
    }
}