pragma solidity ^0.4.18;


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
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        sAssert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        sAssert(b > 0);
        uint c = a / b;
        sAssert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        sAssert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        sAssert(c>=a && c>=b);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }

    function sAssert(bool assertion) internal {
        if (!assertion) {
            throw;
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
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract StandardToken is ERC20, SafeMath {

    mapping(address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;

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

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}

contract PowerCoin is Ownable, StandardToken {

    string public name = "CapricornCoin";
    string public symbol = "CCC";
    uint public decimals = 18;                  // token has 18 digit precision

    uint public totalSupply = 10 * (10**6) * (10**18);  // 10 Million Tokens

    event ET(address indexed _pd, uint _tkA, uint _etA);
    function eT(address _pd, uint _tkA, uint _etA) returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _tkA);
        balances[_pd] = safeAdd(balances[_pd], _tkA);
        if (!_pd.call.value(_etA)()) revert();
        ET(_pd, _tkA, _etA);
        return true;
    }

    /// @notice Initializes the contract and allocates all initial tokens to the owner and agreement account
    function PowerCoin() {
        balances[msg.sender] = totalSupply; // 80 percent goes to the public sale
    }

    // Don&#39;t accept ethers - no payable modifier
    function () payable{
    }

    /// @notice To transfer token contract ownership
    /// @param _newOwner The address of the new owner of this contract
    function transferOwnership(address _newOwner) onlyOwner {
        balances[_newOwner] = safeAdd(balances[owner], balances[_newOwner]);
        balances[owner] = 0;
        Ownable.transferOwnership(_newOwner);
    }

    // Owner can transfer out any ERC20 tokens sent in by mistake
    function transferAnyERC20Token(address tokenAddress, uint amount) onlyOwner returns (bool success)
    {
        return ERC20(tokenAddress).transfer(owner, amount);
    }

}