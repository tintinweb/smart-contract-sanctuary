pragma solidity ^0.4.24;


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
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

  modifier onlyNewOwner {
    require(msg.sender == newOwner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }

  function acceptOwnership() public onlyNewOwner {
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }

  function disown() public onlyOwner {
    owner = address(0);
    newOwner = msg.sender;
    emit OwnershipTransferred(msg.sender, address(0));
  }

  function rejectOwnership() public onlyNewOwner {
    newOwner = address(0);
  }
}


// ----------------------------------------------------------------------------
//
// Symbol      : Chowe
// Name        : Chowe Fermi-Dirac Token
// Total supply: 1
// Decimals    : 0
//
// Share. Enjoy.
//
// (c) by Chris Howe 2018. The MIT Licence.
// ----------------------------------------------------------------------------






// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract ChoweToken is ERC20Interface, Owned {
  string public symbol;
  string public  name;
  uint8 public decimals;
  uint public _totalSupply;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  // ------------------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------------------
  constructor() public {
    symbol = "Chowe";
    name = "Chowe Fermi-Dirac Token";
    decimals = 0;
    _totalSupply = 1;
    balances[msg.sender] = 1;
    balances[address(0)] = 0;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }


  // ------------------------------------------------------------------------
  // Total supply
  // ------------------------------------------------------------------------
  function totalSupply() public view returns (uint) {
    return _totalSupply;
  }


  // ------------------------------------------------------------------------
  // Get the token balance for account tokenOwner
  // ------------------------------------------------------------------------
  function balanceOf(address tokenOwner) public view returns (uint balance) {
    return balances[tokenOwner];
  }


  // ------------------------------------------------------------------------
  // Transfer the balance from token owner&#39;s account to to account
  // - Owner&#39;s account must have sufficient balance to transfer
  // - 0 value transfers are allowed
  // ------------------------------------------------------------------------
  function transfer(address to, uint tokens) public returns (bool success) {
    require(balances[to]==0 && tokens==1);

    if (msg.sender != owner) {
      require(balances[msg.sender] > 0);
      balances[msg.sender] = balances[msg.sender] - 1;
    } else {
      _totalSupply = _totalSupply + 1;
    }

    if (to != address(0)) {
      balances[to] = 1;
    } else {
      _totalSupply = _totalSupply-1;
    }

    emit Transfer(msg.sender, to, 1);
    return true;
  }

  // ------------------------------------------------------------------------
  // Token owner can approve for spender to transferFrom(...) tokens
  // from the token owner&#39;s account
  //
  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
  // recommends that there are no checks for the approval double-spend attack
  // as this should be implemented in user interfaces 
  // ------------------------------------------------------------------------
  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }


  // ------------------------------------------------------------------------
  // Transfer tokens from the from account to the to account
  // ------------------------------------------------------------------------
  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
    require(balances[to]==0 && tokens==1);

    if (from != owner) {
      require(balances[from]>0);
      balances[from] = balances[from] - 1;
    } else {
      _totalSupply = _totalSupply + 1;
    }
      
    require(allowed[from][msg.sender]>0);
    allowed[from][msg.sender] = allowed[from][msg.sender] - 1;

    if (to != address(0)) {
      balances[to] = 1;
    } else {
      _totalSupply = _totalSupply + 1;
    }

    emit Transfer(from, to, 1);
    return true;
  }
  
  // ------------------------------------------------------------------------
  // This override of the Owned contract ensures that the new owner of the 
  // contract has a token
  // ------------------------------------------------------------------------
  
  function acceptOwnership() public {
    address oldOwner = owner;
    super.acceptOwnership();
    
    // The owner MUST have a token, so create one if needed
    if( balances[msg.sender] == 0) {
      balances[msg.sender] = 1;
      _totalSupply = _totalSupply + 1;
      emit Transfer(oldOwner, msg.sender, 1);
    }
  }

  // ------------------------------------------------------------------------
  // Returns the amount of tokens approved by the owner that can be
  // transferred to the spender&#39;s account
  // ------------------------------------------------------------------------
  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }

  // ------------------------------------------------------------------------
  // Token owner can approve for spender to transferFrom(...) tokens
  // from the token owner&#39;s account. The spender contract function
  // receiveApproval(...) is then executed
  // ------------------------------------------------------------------------
  function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
    return true;
  }

  // ------------------------------------------------------------------------
  // Don&#39;t accept ETH
  // ------------------------------------------------------------------------
  function () public payable {
    revert();
  }

  // ------------------------------------------------------------------------
  // Owner can transfer out any accidentally sent ERC20 tokens
  // ------------------------------------------------------------------------
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
    return ERC20Interface(tokenAddress).transfer(owner, tokens);
  }
}