pragma solidity ^0.4.24;

// ****************************************************************************
//
// Symbol          : BECC
// Name            : Beechain Exchange Cross-chain Coin
// Decimals        : 18
// Total supply    : 500,000,000.000000000000000000
// Initial release : 70 percent (350,000,000.000000000000000000)
// Initial Locked  : 30 percent (150,000,000.000000000000000000)
// Contract start  : 2018-08-15 00:00:00 (UTC timestamp: 1534233600)
// Lock duration   : 180 days
// Release rate    : 10 percent / 30 days (15,000,000.000000000000000000)
// Release duration: 300 days.
//
// ****************************************************************************


// ****************************************************************************
// Safe math
// ****************************************************************************

library SafeMath {
    
  function mul(uint _a, uint _b) internal pure returns (uint c) {
    if (_a == 0) {
      return 0;
    }
    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  function div(uint _a, uint _b) internal pure returns (uint) {
    return _a / _b;
  }

  function sub(uint _a, uint _b) internal pure returns (uint) {
    assert(_b <= _a);
    return _a - _b;
  }

  function add(uint _a, uint _b) internal pure returns (uint c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// ****************************************************************************
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ****************************************************************************
contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ****************************************************************************
// Contract function to receive approval and execute function
// ****************************************************************************
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint tokens, address token, bytes data) public;
}

// ****************************************************************************
// Owned contract
// ****************************************************************************
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

// ****************************************************************************
// BECC Token, with the addition of symbol, name and decimals and a fixed supply
// ****************************************************************************
contract BECCToken is ERC20, Owned {
    using SafeMath for uint;
    
    event Pause();
    event Unpause();
    event ReleasedTokens(uint tokens);
    event AllocateTokens(address to, uint tokens);
    
    bool public paused = false;

    string public symbol;
    string public name;
    uint8 public decimals;
    
    uint private _totalSupply;              //total supply
    uint private _initialRelease;           //initial release
    uint private _locked;                   //locked tokens
    uint private _released = 0;             //alloced tokens
    uint private _allocated = 0;
    uint private _startTime = 1534233600 + 180 days;    //release start time:2018-08-15 00:00:00(UTC) + 180 days

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    // ************************************************************************
    // Modifier to make a function callable only when the contract is not paused.
    // ************************************************************************
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    // ************************************************************************
    // Modifier to make a function callable only when the contract is paused.
    // ************************************************************************
    modifier whenPaused() {
        require(paused);
        _;
    }
  
    // ************************************************************************
    // Constructor
    // ************************************************************************
    constructor() public {
        symbol = "BECC";
        name = "Beechain Exchange Cross-chain Coin";
        decimals = 18;
        _totalSupply = 500000000 * 10**uint(decimals);
        _initialRelease = _totalSupply * 7 / 10;
        _locked = _totalSupply * 3 / 10;
        balances[owner] = _initialRelease;
        emit Transfer(address(0), owner, _initialRelease);
    }

    // ************************************************************************
    // Total supply
    // ************************************************************************
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

    // ************************************************************************
    // Get the token balance for account `tokenOwner`
    // ************************************************************************
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    // ************************************************************************
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ************************************************************************
    function transfer(address to, uint tokens) public whenNotPaused returns (bool success) {
        require(address(0) != to && tokens <= balances[msg.sender] && 0 <= tokens);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ************************************************************************
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    // ************************************************************************
    function approve(address spender, uint tokens) public whenNotPaused returns (bool success) {
        require(address(0) != spender && 0 <= tokens);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ************************************************************************
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ************************************************************************
    function transferFrom(address from, address to, uint tokens) public whenNotPaused returns (bool success) {
        require(address(0) != to && tokens <= balances[msg.sender] && tokens <= allowed[from][msg.sender] && 0 <= tokens);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ************************************************************************
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ************************************************************************
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ************************************************************************
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ************************************************************************
    function approveAndCall(address spender, uint tokens, bytes data) public whenNotPaused returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ************************************************************************
    // Don&#39;t accept ETH
    // ************************************************************************
    function () public payable {
        revert();
    }

    // ************************************************************************
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ************************************************************************
    function transferERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }
    
    // ************************************************************************
    // called by the owner to pause, triggers stopped state
    // ************************************************************************
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    // ************************************************************************
    // called by the owner to unpause, returns to normal state
    // ************************************************************************
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
    
    // ************************************************************************
    // return free Tokens
    // ************************************************************************
    function freeBalance() public view returns (uint tokens) {
        return _released.sub(_allocated);
    }

    // ************************************************************************
    // return released Tokens
    // ************************************************************************
    function releasedBalance() public view returns (uint tokens) {
        return _released;
    }

    // ************************************************************************
    // return allocated Tokens
    // ************************************************************************
    function allocatedBalance() public view returns (uint tokens) {
        return _allocated;
    }
    
    // ************************************************************************
    // calculate released Tokens by the owner
    // ************************************************************************
    function calculateReleased() public onlyOwner returns (uint tokens) {
        require(now > _startTime);
        uint _monthDiff = (now.sub(_startTime)).div(30 days);

        if (_monthDiff >= 10 ) {
            _released = _locked;
        } else {
            _released = _monthDiff.mul(_locked.div(10));
        }
        emit ReleasedTokens(_released);
        return _released;
    }

    // ************************************************************************
    // called by the owner to alloc the released tokens
    // ************************************************************************     
    function allocateTokens(address to, uint tokens) public onlyOwner returns (bool success){
        require(address(0) != to && 0 <= tokens && tokens <= _released.sub(_allocated));
        balances[to] = balances[to].add(tokens);
        _allocated = _allocated.add(tokens);
        emit AllocateTokens(to, tokens);
        return true;
    }
}