pragma solidity ^0.4.11;


/*
  Author: Victor Mezrin  <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="790f101a0d160b39141c030b1017571a1614">[email&#160;protected]</a>
*/


/* Interface of the ERC223 token */
contract ERC223TokenInterface {
    function name() constant returns (string _name);
    function symbol() constant returns (string _symbol);
    function decimals() constant returns (uint8 _decimals);
    function totalSupply() constant returns (uint256 _supply);

    function balanceOf(address _owner) constant returns (uint256 _balance);

    function approve(address _spender, uint256 _value) returns (bool _success);
    function allowance(address _owner, address spender) constant returns (uint256 _remaining);

    function transfer(address _to, uint256 _value) returns (bool _success);
    function transfer(address _to, uint256 _value, bytes _metadata) returns (bool _success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool _success);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value, bytes metadata);
}


/* Interface of the contract that is going to receive ERC223 tokens */
contract ERC223ContractInterface {
    function erc223Fallback(address _from, uint256 _value, bytes _data){
        // to avoid warnings during compilation
        _from = _from;
        _value = _value;
        _data = _data;
        // Incoming transaction code here
        throw;
    }
}


/* https://github.com/LykkeCity/EthereumApiDotNetCore/blob/master/src/ContractBuilder/contracts/token/SafeMath.sol */
contract SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) throw;
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x < y) throw;
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (y == 0) return 0;
        if (x > MAX_UINT256 / y) throw;
        return x * y;
    }
}


contract ERC223Token is ERC223TokenInterface, SafeMath {

    /*
      Storage of the contract
    */

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;


    /*
      Getters
    */

    function name() constant returns (string _name) {
        return name;
    }

    function symbol() constant returns (string _symbol) {
        return symbol;
    }

    function decimals() constant returns (uint8 _decimals) {
        return decimals;
    }

    function totalSupply() constant returns (uint256 _supply) {
        return totalSupply;
    }

    function balanceOf(address _owner) constant returns (uint256 _balance) {
        return balances[_owner];
    }


    /*
      Allow to spend
    */

    function approve(address _spender, uint256 _value) returns (bool _success) {
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 _remaining) {
        return allowances[_owner][_spender];
    }


    /*
      Transfer
    */

    function transfer(address _to, uint256 _value) returns (bool _success) {
        bytes memory emptyMetadata;
        __transfer(msg.sender, _to, _value, emptyMetadata);
        return true;
    }

    function transfer(address _to, uint256 _value, bytes _metadata) returns (bool _success)
    {
        __transfer(msg.sender, _to, _value, _metadata);
        Transfer(msg.sender, _to, _value, _metadata);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool _success) {
        if (allowances[_from][msg.sender] < _value) throw;

        allowances[_from][msg.sender] = safeSub(allowances[_from][msg.sender], _value);
        bytes memory emptyMetadata;
        __transfer(_from, _to, _value, emptyMetadata);
        return true;
    }

    function __transfer(address _from, address _to, uint256 _value, bytes _metadata) internal
    {
        if (_from == _to) throw;
        if (_value == 0) throw;
        if (balanceOf(_from) < _value) throw;

        balances[_from] = safeSub(balanceOf(_from), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);

        if (isContract(_to)) {
            ERC223ContractInterface receiverContract = ERC223ContractInterface(_to);
            receiverContract.erc223Fallback(_from, _value, _metadata);
        }

        Transfer(_from, _to, _value);
    }


    /*
      Helpers
    */

    // Assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) internal returns (bool _isContract) {
        _addr = _addr; // to avoid warnings during compilation

        uint256 length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }
}



// ERC223 token with the ability for the owner to block any account
contract DASToken is ERC223Token {
    mapping (address => bool) blockedAccounts;
    address public secretaryGeneral;


    // Constructor
    function DASToken() {
        secretaryGeneral = msg.sender;
        name = &quot;DA$&quot;;
        symbol = &quot;DA$&quot;;
        decimals = 18;
        totalSupply = 1000000000000000000000000000;
        balances[msg.sender] = totalSupply;
    }


    modifier onlySecretaryGeneral {
        if (msg.sender != secretaryGeneral) throw;
        _;
    }


    // block account
    function blockAccount(address _account) onlySecretaryGeneral {
        blockedAccounts[_account] = true;
    }

    // unblock account
    function unblockAccount(address _account) onlySecretaryGeneral {
        blockedAccounts[_account] = false;
    }

    // check is account blocked
    function isAccountBlocked(address _account) returns (bool){
        return blockedAccounts[_account];
    }

    // override transfer methods to throw on blocked accounts
    function transfer(address _to, uint256 _value) returns (bool _success) {
        if (blockedAccounts[msg.sender]) {
            throw;
        }
        return super.transfer(_to, _value);
    }

    function transfer(address _to, uint256 _value, bytes _metadata) returns (bool _success) {
        if (blockedAccounts[msg.sender]) {
            throw;
        }
        return super.transfer(_to, _value, _metadata);
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool _success) {
        if (blockedAccounts[_from]) {
            throw;
        }
        return super.transferFrom(_from, _to, _value);
    }
}