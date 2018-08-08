pragma solidity ^0.4.16;


contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner()  {
        require(msg.sender == owner);
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

    function sAssert(bool assertion) internal pure {
        if (!assertion) {
            revert();
        }
    }
}


contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) public constant returns (uint);
    function allowance(address owner, address spender) public constant returns (uint);

    function transfer(address toAcct, uint value) public returns (bool ok);
    function transferFrom(address fromAcct, address toAcct, uint value) public returns (bool ok);
    function approve(address spender, uint value) public returns (bool ok);
    event Transfer(address indexed fromAcct, address indexed toAcct, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract StandardToken is ERC20, SafeMath {

    mapping(address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
    event Burn(address indexed fromAcct, uint256 value);

    function transfer(address _toAcct, uint _value) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_toAcct] = safeAdd(balances[_toAcct], _value);
        Transfer(msg.sender, _toAcct, _value);
        return true;
    }

    function transferFrom(address _fromAcct, address _toAcct, uint _value) public returns (bool success) {
        var _allowance = allowed[_fromAcct][msg.sender];
        balances[_toAcct] = safeAdd(balances[_toAcct], _value);
        balances[_fromAcct] = safeSub(balances[_fromAcct], _value);
        allowed[_fromAcct][msg.sender] = safeSub(_allowance, _value);
        Transfer(_fromAcct, _toAcct, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public  returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
    
    function burn(uint256 _value) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value); // Subtract from the sender
        totalSupply = safeSub(totalSupply,_value); // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }
    
    

}

contract TCNYCoin is Ownable, StandardToken {

    string public name;
    string public symbol;
    uint public decimals;                  
    uint public totalSupply;  


    /// @notice Initializes the contract and allocates all initial tokens to the owner and agreement account
    function TCNYCoin() public {
    totalSupply = 100 * (10**6) * (10**6);
        balances[msg.sender] = totalSupply;
        name = "TCNY";
        symbol = "TCNY";
        decimals = 6;
    }

    function () payable public{
    }

    /// @notice To transfer token contract ownership
    /// @param _newOwner The address of the new owner of this contract
    function transferOwnership(address _newOwner) public onlyOwner {
        balances[_newOwner] = safeAdd(balances[owner], balances[_newOwner]);
        balances[owner] = 0;
        Ownable.transferOwnership(_newOwner);
    }

    // Owner can transfer out any ERC20 tokens sent in by mistake
    function transferAnyERC20Token(address tokenAddress, uint amount) public onlyOwner returns (bool success)
    {
        return ERC20(tokenAddress).transfer(owner, amount);
    }
    
    function freezeAccount(address target, bool freeze) public onlyOwner  {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    
    function mintToken(address _toAcct, uint256 _value) public onlyOwner  {
        balances[_toAcct] = safeAdd(balances[_toAcct], _value);
        totalSupply = safeAdd(totalSupply, _value);
        Transfer(0, this, _value);
        Transfer(this, _toAcct, _value);
    }

}