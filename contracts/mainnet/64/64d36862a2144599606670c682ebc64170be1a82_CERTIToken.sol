pragma solidity ^0.4.15;

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

contract SafeMath {
    function safeSub(uint a, uint b) pure internal returns (uint) {
        sAssert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) pure internal returns (uint) {
        uint c = a + b;
        sAssert(c>=a && c>=b);
        return c;
    }

    function sAssert(bool assertion) pure internal {
        if (!assertion) {
            revert();
        }
    }
}

contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);
    function allowance(address owner, address spender) public constant returns (uint);

    function transfer(address to, uint value) public returns (bool ok);
    function transferFrom(address from, address to, uint value) public returns (bool ok);
    function approve(address spender, uint value) public returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract StandardToken is ERC20, SafeMath {
    mapping(address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

    function transfer(address _to, uint _value) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        var _allowance = allowed[_from][msg.sender];

        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}

contract CERTIToken is Ownable, StandardToken {
    string public name = "SingleSource";
    string public symbol = "CERTI";
    uint public decimals = 18;

    uint public totalSupply = 2000000000 ether;

    function CERTIToken() {
        balances[msg.sender] = totalSupply;
    }

    function () public {
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        balances[_newOwner] = safeAdd(balances[owner], balances[_newOwner]);
        balances[owner] = 0;
        Ownable.transferOwnership(_newOwner);
    }

    function transferAnyERC20Token(address tokenAddress, uint amount) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, amount);
    }
}