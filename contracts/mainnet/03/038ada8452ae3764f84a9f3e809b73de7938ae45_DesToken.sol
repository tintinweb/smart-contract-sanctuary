pragma solidity ^0.4.18;

library SafeMathLib {
    function times(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function minus(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function plus(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a && c >= b);
        return c;
    }
}

library ERC20Lib {
    using SafeMathLib for uint;

    struct TokenStorage {
        mapping (address => uint) balances;
        mapping (address => mapping (address => uint)) allowed;
        uint totalSupply;
    }

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function init(TokenStorage storage self, uint _initial_supply, address _owner) internal {
        self.totalSupply = _initial_supply;
        self.balances[_owner] = _initial_supply;
    }


    function transfer(TokenStorage storage self, address _to, uint _value) internal returns (bool success) {
        self.balances[msg.sender] = self.balances[msg.sender].minus(_value);
        self.balances[_to] = self.balances[_to].plus(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(TokenStorage storage self, address _from, address _to, uint _value) internal returns (bool success) {
        var _allowance = self.allowed[_from][msg.sender];

        self.balances[_to] = self.balances[_to].plus(_value);
        self.balances[_from] = self.balances[_from].minus(_value);
        self.allowed[_from][msg.sender] = _allowance.minus(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(TokenStorage storage self, address _owner) internal view returns (uint balance) {
        return self.balances[_owner];
    }

    function approve(TokenStorage storage self, address _spender, uint _value) internal returns (bool success) {
        self.allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(TokenStorage storage self, address _owner, address _spender) internal view returns (uint remaining) {
        return self.allowed[_owner][_spender];
    }
}

contract DesToken {
    using ERC20Lib for ERC20Lib.TokenStorage;

    ERC20Lib.TokenStorage token;

    string public name = "Digital Equivalent Stabilized Coin";
    string public symbol = "DES";
    uint8 public decimals = 8;
    uint public INITIAL_SUPPLY = 100000000000;

    function DesToken() public {
        // adding decimals to initial supply
        var totalSupply = INITIAL_SUPPLY * 10 ** uint256(decimals);
        // adding total supply to owner which could be msg.sender or specific address
        token.init(totalSupply, 0x0c5E1F35336a4a62600212E3Dde252E35eEc99d5);
    }

    function totalSupply() public view returns (uint) {
        return token.totalSupply;
    }

    function balanceOf(address who) public view returns (uint) {
        return token.balanceOf(who);
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return token.allowance(owner, spender);
    }

    function transfer(address to, uint value) public returns (bool ok) {
        return token.transfer(to, value);
    }

    function transferFrom(address from, address to, uint value) public returns (bool ok) {
        return token.transferFrom(from, to, value);
    }

    function approve(address spender, uint value) public returns (bool ok) {
        return token.approve(spender, value);
    }

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}