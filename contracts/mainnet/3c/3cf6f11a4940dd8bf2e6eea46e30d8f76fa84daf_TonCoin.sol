pragma solidity ^0.4.24;

contract Ownable {
    address public owner;
    function Ownable() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) owner = newOwner;
    }
}

contract SafeMath {
    function safeSub(uint a, uint b) internal returns (uint) {
        sAssert(b <= a);
        return a - b;
    }
    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        sAssert(c>=a && c>=b);
        return c;
    }
    function sAssert(bool assertion) internal {
        if (!assertion) {
            revert();
        }
    }
}

contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function allowance(address owner, address spender) constant returns (uint);
    function transfer(address to, uint value) returns (bool ok);
    function transferFrom(address from, address to, uint value) returns (bool ok);
    function approve(address spender, uint value) returns (bool ok);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

contract StandardToken is ERC20, SafeMath {
    mapping(address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
    function approve(address _spender, uint _value) returns (bool success) {
        // require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    function transfer(address _to, uint _value) returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint _value) returns (bool success) {
        var _allowance = allowed[_from][msg.sender];

        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        Transfer(_from, _to, _value);
        return true;
    }
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}

contract TonCoin is Ownable, StandardToken {
    string public name = "TON Coin";
    string public symbol = "TON";
    uint public decimals = 18;
    uint public totalSupply = 3 * (10**9) * (10**18);
    function TonCoin() {
        balances[msg.sender] = totalSupply;
    }
    function () {// Don&#39;t accept ethers - no payable modifier
    }
    function transferOwnership(address _newOwner) onlyOwner {
        balances[_newOwner] = safeAdd(balances[owner], balances[_newOwner]);
        balances[owner] = 0;
        Ownable.transferOwnership(_newOwner);
    }
    function transferAnyERC20Token(address tokenAddress, uint amount) onlyOwner returns (bool success)
    {
        return ERC20(tokenAddress).transfer(owner, amount);
    }
}