pragma solidity ^0.4.24;

contract ERC20 {
    function totalSupply() constant returns (uint supply);
    function balanceOf( address who ) constant returns (uint value);
    function allowance( address owner, address spender ) constant returns (uint _allowance);

    function transfer( address to, uint value) returns (bool ok);
    function transferFrom( address from, address to, uint value) returns (bool ok);
    function approve( address spender, uint value ) returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

contract DSTokenBase is ERC20
{
    mapping( address => uint ) _balances;
    mapping( address => mapping( address => uint ) ) _approvals;
    uint _supply;
    function DSTokenBase( uint initial_balance ) {
        _balances[msg.sender] = initial_balance;
        _supply = initial_balance;
    }
    function totalSupply() constant returns (uint supply) {
        return _supply;
    }
    function balanceOf( address who ) constant returns (uint value) {
        return _balances[who];
    }
    function transfer( address to, uint value) returns (bool ok) {
        if( _balances[msg.sender] < value ) {
            throw;
        }
        if( !safeToAdd(_balances[to], value) ) {
            throw;
        }
        _balances[msg.sender] -= value;
        _balances[to] += value;
        Transfer( msg.sender, to, value );
        return true;
    }
    function transferFrom( address from, address to, uint value) returns (bool ok) {
        // if you don&#39;t have enough balance, throw
        if( _balances[from] < value ) {
            throw;
        }
        // if you don&#39;t have approval, throw
        if( _approvals[from][msg.sender] < value ) {
            throw;
        }
        if( !safeToAdd(_balances[to], value) ) {
            throw;
        }
        // transfer and return true
        _approvals[from][msg.sender] -= value;
        _balances[from] -= value;
        _balances[to] += value;
        Transfer( from, to, value );
        return true;
    }
    function approve(address spender, uint value) returns (bool ok) {
        _approvals[msg.sender][spender] = value;
        Approval( msg.sender, spender, value );
        return true;
    }
    function allowance(address owner, address spender) constant returns (uint _allowance) {
        return _approvals[owner][spender];
    }
    function safeToAdd(uint a, uint b) internal returns (bool) {
        return (a + b >= a);
    }
}

contract DSActor {
    function tryExec( address target, bytes calldata, uint value)
             internal
             returns (bool call_ret)
    {
        return target.call.value(value)(calldata);
    }
    function exec( address target, bytes calldata, uint value)
             internal
    {
        if(!tryExec(target, calldata, value)) {
            throw;
        }
    }
}

contract DSEthTokenEvents {
    event Deposit( address indexed who, uint amount );
    event Withdrawal( address indexed who, uint amount );
}

contract DSEthToken is DSTokenBase(0)
                     , DSActor
                     , DSEthTokenEvents
{   
    string public constant name = "Wrapper ETH";
    string public constant symbol = "W-ETH";
    uint   public constant decimals = 18;

    function totalSupply() constant returns (uint supply) {
        return this.balance;
    }
    function withdraw( uint amount ) {
        if (!tryWithdraw(amount)) {
            throw;
        }
    }
    function tryWithdraw( uint amount ) returns (bool ok) {
        _balances[msg.sender] = safeSub(_balances[msg.sender], amount);
        bytes memory calldata; // define a blank `bytes`
        if (tryExec(msg.sender, calldata, amount)) { 
            Withdrawal( msg.sender, amount );
            return true;
        } else {
            _balances[msg.sender] = safeAdd(_balances[msg.sender], amount);
            return false;
        }
    }
    function deposit() payable returns (bool ok) {
        _balances[msg.sender] += msg.value;
        Deposit( msg.sender, msg.value );
        return true;
    }
    function() payable {
        deposit();
    }

    // Hoisted to remove dependency on entire util package
    function safeToAdd(uint a, uint b) internal returns (bool) {
        return (a + b >= a);
    }
    function safeAdd(uint a, uint b) internal returns (uint) {
        if (!safeToAdd(a, b)) throw;
        return a + b;
    }
    function safeToSubtract(uint a, uint b) internal returns (bool) {
        return (b <= a);
    }
    function safeSub(uint a, uint b) internal returns (uint) {
        if (!safeToSubtract(a, b)) throw;
        return a - b;
    } 

}