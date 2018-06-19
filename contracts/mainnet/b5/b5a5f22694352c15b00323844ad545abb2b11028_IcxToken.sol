pragma solidity ^0.4.11;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function Migrations() {
    owner = msg.sender;
  }

  function setCompleted(uint completed) restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}

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

contract Lockable {
    uint public creationTime;
    bool public lock;
    bool public tokenTransfer;
    address public owner;
    mapping( address => bool ) public unlockaddress;
    mapping( address => bool ) public lockaddress;

    event Locked(address lockaddress,bool status);
    event Unlocked(address unlockedaddress, bool status);


    // if Token transfer
    modifier isTokenTransfer {
        // if token transfer is not allow
        if(!tokenTransfer) {
            require(unlockaddress[msg.sender]);
        }
        _;
    }

    // This modifier check whether the contract should be in a locked
    // or unlocked state, then acts and updates accordingly if
    // necessary
    modifier checkLock {
        if (lockaddress[msg.sender]) {
            throw;
        }
        _;
    }

    modifier isOwner {
        require(owner == msg.sender);
        _;
    }

    function Lockable() {
        creationTime = now;
        tokenTransfer = false;
        owner = msg.sender;
    }

    // Lock Address
    function lockAddress(address target, bool status)
    external
    isOwner
    {
        require(owner != target);
        lockaddress[target] = status;
        Locked(target, status);
    }

    // UnLock Address
    function unlockAddress(address target, bool status)
    external
    isOwner
    {
        unlockaddress[target] = status;
        Unlocked(target, status);
    }
}

library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
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

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

// ICON ICX Token
/// @author DongOk Ryu - <<span class="__cf_email__" data-cfemail="9bebf4ebdbeff3fef7f4f4ebb5f8f4b5f0e9">[email&#160;protected]</span>>
contract IcxToken is ERC20, Lockable {
    using SafeMath for uint;

    mapping( address => uint ) _balances;
    mapping( address => mapping( address => uint ) ) _approvals;
    uint _supply;
    address public walletAddress;

    //event TokenMint(address newTokenHolder, uint amountOfTokens);
    event TokenBurned(address burnAddress, uint amountOfTokens);
    event TokenTransfer();

    modifier onlyFromWallet {
        require(msg.sender != walletAddress);
        _;
    }

    function IcxToken( uint initial_balance, address wallet) {
        require(wallet != 0);
        require(initial_balance != 0);
        _balances[msg.sender] = initial_balance;
        _supply = initial_balance;
        walletAddress = wallet;
    }

    function totalSupply() constant returns (uint supply) {
        return _supply;
    }

    function balanceOf( address who ) constant returns (uint value) {
        return _balances[who];
    }

    function allowance(address owner, address spender) constant returns (uint _allowance) {
        return _approvals[owner][spender];
    }

    function transfer( address to, uint value)
    isTokenTransfer
    checkLock
    returns (bool success) {

        require( _balances[msg.sender] >= value );

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        Transfer( msg.sender, to, value );
        return true;
    }

    function transferFrom( address from, address to, uint value)
    isTokenTransfer
    checkLock
    returns (bool success) {
        // if you don&#39;t have enough balance, throw
        require( _balances[from] >= value );
        // if you don&#39;t have approval, throw
        require( _approvals[from][msg.sender] >= value );
        // transfer and return true
        _approvals[from][msg.sender] = _approvals[from][msg.sender].sub(value);
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        Transfer( from, to, value );
        return true;
    }

    function approve(address spender, uint value)
    isTokenTransfer
    checkLock
    returns (bool success) {
        _approvals[msg.sender][spender] = value;
        Approval( msg.sender, spender, value );
        return true;
    }

    // burnToken burn tokensAmount for sender balance
    function burnTokens(uint tokensAmount)
    isTokenTransfer
    external
    {
        require( _balances[msg.sender] >= tokensAmount );

        _balances[msg.sender] = _balances[msg.sender].sub(tokensAmount);
        _supply = _supply.sub(tokensAmount);
        TokenBurned(msg.sender, tokensAmount);

    }


    function enableTokenTransfer()
    external
    onlyFromWallet {
        tokenTransfer = true;
        TokenTransfer();
    }

    function disableTokenTransfer()
    external
    onlyFromWallet {
        tokenTransfer = false;
        TokenTransfer();
    }

}