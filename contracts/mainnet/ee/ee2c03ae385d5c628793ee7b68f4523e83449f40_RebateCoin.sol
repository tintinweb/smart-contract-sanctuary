pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
  uint256 constant private MAX_UINT256 =
  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  function safeAdd (uint256 x, uint256 y) constant internal returns (uint256 z) {
    assert (x <= MAX_UINT256 - y);
    return x + y;
  }

  function safeSub (uint256 x, uint256 y) constant internal returns (uint256 z) {
    assert (x >= y);
    return x - y;
  }

  function safeMul (uint256 x, uint256 y)  constant internal  returns (uint256 z) {
    if (y == 0) return 0; // Prevent division by zero at the next line
    assert (x <= MAX_UINT256 / y);
    return x * y;
  }
  
  
   function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract RebateCoin is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals = 18;
    uint256 private _supply;
    uint256 private _totalSupply;

    uint public tokenPrice = 100 * (10**13); // wei , 0.001 eth , 6 usd
 
	uint private SaleStage1_start = 1527811200;
	uint256 private SaleStage1_supply = 24 * (10**24);
	uint private SaleStage1_tokenPrice = 84 * (10**13); // 0.5 usd

	uint private SaleStage2_start = 1530403200;
	uint256 private SaleStage2_supply = 10 * (10**24);
	uint private SaleStage2_tokenPrice = 108; // 0.65 usd

	uint private SaleStage3_start = 1533081600;
	uint256 private SaleStage3_supply = 50 * (10**24);
	uint private SaleStage3_tokenPrice = 134 * (10**24); // 0.8 usd
	
    uint public startDate = 1527811200;
    uint public endDate = 1535760000;

	uint256 public hardcap = 22800 ether;
	uint256 public softcap = 62250 ether;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function RebateCoin() public {
        symbol = "RBC";
        name = "Rebate Coin";
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are not allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
		if (tokens > 0 && from != to) {
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
		}
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ------------------------------------------------------------------------
    // RBC Tokens per 1 ETH
    // ------------------------------------------------------------------------
    function () public payable {
        require(now >= startDate && now <= endDate);
        uint tokens;
        if (now >= SaleStage3_start) {
            tokens = safeDiv(msg.value * (10**18),SaleStage3_tokenPrice);
			_supply = safeAdd(SaleStage3_supply,safeAdd(SaleStage2_supply,SaleStage1_supply));
        } else if(now >= SaleStage2_start) {
            tokens = safeDiv(msg.value * (10**18),SaleStage2_tokenPrice);
			_supply = safeAdd(SaleStage2_supply,SaleStage1_supply);
        } else if(now >= SaleStage1_start) {
            tokens = safeDiv(msg.value * (10**18),SaleStage1_tokenPrice);
			_supply = SaleStage1_supply;
		} else {}
		require( _totalSupply < _supply);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        _totalSupply = safeAdd(_totalSupply, tokens);
        Transfer(address(0), msg.sender, tokens);
        owner.transfer(msg.value);
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}