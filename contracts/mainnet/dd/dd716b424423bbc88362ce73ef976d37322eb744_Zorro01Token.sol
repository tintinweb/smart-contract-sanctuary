pragma solidity ^0.4.11;

// ----------------------------------------------------------------------------
//
// Owned contract
//
// ----------------------------------------------------------------------------

contract Owned {

    address public owner;
    address public newOwner;

    event OwnershipTransferProposed(
      address indexed _from,
      address indexed _to
    );

    event OwnershipTransferred(
      address indexed _from,
      address indexed _to
    );

    function Owned()
    {
      owner = msg.sender;
    }

    modifier onlyOwner
    {
      require(msg.sender == owner);
      _;
    }

    function transferOwnership(address _newOwner) onlyOwner
    {
      require(_newOwner != address(0x0));
      OwnershipTransferProposed(owner, _newOwner);
      newOwner = _newOwner;
    }

    function acceptOwnership()
    {
      require(msg.sender == newOwner);
      OwnershipTransferred(owner, newOwner);
      owner = newOwner;
    }

}


// ----------------------------------------------------------------------------
//
// SafeMath contract
//
// ----------------------------------------------------------------------------

contract SafeMath {

  function safeAdd(uint a, uint b) internal
    returns (uint)
  {
    uint c = a + b;
    assert(c >= a && c >= b);
    return c;
  }

  function safeSub(uint a, uint b) internal
    returns (uint)
  {
    assert(b <= a);
    uint c = a - b;
    assert(c <= a);
    return c;
  }

}


// ----------------------------------------------------------------------------
//
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
//
// ----------------------------------------------------------------------------

contract ERC20Interface {

    event Transfer(
      address indexed _from,
      address indexed _to,
      uint256 _value
    );
    
    event Approval(
      address indexed _owner,
      address indexed _spender,
      uint256 _value
    );

    function totalSupply() constant
      returns (uint256 newTotalSupply);
    
    function balanceOf(address _owner) constant 
      returns (uint256 balance);
    
    function transfer(address _to, uint256 _value)
      returns (bool success);
    
    function transferFrom(address _from, address _to, uint256 _value) 
      returns (bool success);
    
    function approve(address _spender, uint256 _value) 
      returns (bool success);
    
    function allowance(address _owner, address _spender) constant 
      returns (uint256 remaining);

}

// ----------------------------------------------------------------------------
//
// ERC Token Standard #20
//
// note that totalSupply() is not defined here
//
// ----------------------------------------------------------------------------

contract ERC20Token is ERC20Interface, Owned, SafeMath {

    // Account balances
    //
    mapping(address => uint256) balances;

    // Account holder approves the transfer of an amount to another account
    //
    mapping(address => mapping (address => uint256)) allowed;

    // Get the account balance for an address
    function balanceOf(address _owner) constant 
      returns (uint256 balance)
    {
      return balances[_owner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from owner&#39;s account to another account
    // ------------------------------------------------------------------------
    function transfer(address _to, uint256 _amount) 
      returns (bool success)
    {
      require( _amount > 0 );                              // Non-zero transfer
      require( balances[msg.sender] >= _amount );          // User has balance
      require( balances[_to] + _amount > balances[_to] );  // Overflow check

      balances[msg.sender] -= _amount;
      balances[_to] += _amount;
      Transfer(msg.sender, _to, _amount);
      return true;
    }

    // ------------------------------------------------------------------------
    // Allow _spender to withdraw from your account, multiple times, up to
    // _amount. If this function is called again it overwrites the
    // current allowance with _amount.
    // ------------------------------------------------------------------------
    function approve(address _spender, uint256 _amount) 
      returns (bool success)
    {
      // before changing the approve amount for an address, its allowance
      // must be reset to 0 to mitigate the race condition described here:
      // cf https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
      require( _amount == 0 || allowed[msg.sender][_spender] == 0 );
        
      // the approval amount cannot exceed the balance
      require (balances[msg.sender] >= _amount);
        
      allowed[msg.sender][_spender] = _amount;
      Approval(msg.sender, _spender, _amount);
      return true;
    }

    // ------------------------------------------------------------------------
    // Spender of tokens transfer an amount of tokens from the token owner&#39;s
    // balance to another account. The owner of the tokens must already
    // have approve(...)-d this transfer
    // ------------------------------------------------------------------------
    function transferFrom(address _from, address _to, uint256 _amount) 
    returns (bool success) 
    {
      require( _amount > 0 );                              // Non-zero transfer
      require( balances[_from] >= _amount );               // Sufficient balance
      require( allowed[_from][msg.sender] >= _amount );    // Transfer approved
      require( balances[_to] + _amount > balances[_to] );  // Overflow check

      balances[_from] -= _amount;
      allowed[_from][msg.sender] -= _amount;
      balances[_to] += _amount;
      Transfer(_from, _to, _amount);
      return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred by _spender
    // ------------------------------------------------------------------------

    function allowance(address _owner, address _spender) constant 
    returns (uint256 remaining)
    {
      return allowed[_owner][_spender];
    }

}

// ----------------------------------------------------------------------------
//
// GZR public token sale
//
// ----------------------------------------------------------------------------

contract Zorro01Token is ERC20Token {


    // VARIABLES ================================


    // basic token data

    string public constant name = "Zorro01";
    string public constant symbol = "ZORRO01";
    uint8 public constant decimals = 18;
    string public constant GITHUB_LINK = &#39;htp://github.com/..&#39;;  // TODO

    // wallet address (can be reset at any time during ICO)
    
    address public wallet;

    // ICO variables that can be reset before ICO starts

    uint public tokensPerEth = 100000;
    uint public icoTokenSupply = 500;

    // ICO constants #1

    uint public constant TOTAL_TOKEN_SUPPLY = 1000;
    uint public constant ICO_TRIGGER = 10;
    uint public constant MIN_CONTRIBUTION = 10**15;
    
    // ICO constants #2 : ICO dates

    // Start - Friday, 15-Sep-17 00:00:00 UTC
    // End - Sunday, 15-Oct-17 00:00:00 UTC
    // as per http://www.unixtimestamp.com
    uint public constant START_DATE = 1502748000;
    uint public constant END_DATE = 1502751600;

    // ICO variables

    uint public icoTokensIssued = 0;
    bool public icoFinished = false;
    bool public tradeable = false;

    // Minting
    
    uint public ownerTokensMinted = 0;
    
    // other variables
    
    uint256 constant MULT_FACTOR = 10**18;
    

    // EVENTS ===================================

    
    event LogWalletUpdated(
      address newWallet
    );
    
    event LogTokensPerEthUpdated(
      uint newTokensPerEth
    );
    
    event LogIcoTokenSupplyUpdated(
      uint newIcoTokenSupply
    );
    
    event LogTokensBought(
      address indexed buyer,
      uint ethers,
      uint tokens, 
      uint participantTokenBalance, 
      uint newIcoTokensIssued
    );
    
    event LogMinting(
      address indexed participant,
      uint tokens,
      uint newOwnerTokensMinted
    );


    // FUNCTIONS ================================
    
    // --------------------------------
    // initialize
    // --------------------------------

    function Zorro01Token() {
      owner = msg.sender;
      wallet = msg.sender;
    }


    // --------------------------------
    // implement totalSupply() ERC20 function
    // --------------------------------
    
    function totalSupply() constant
      returns (uint256)
    {
      return TOTAL_TOKEN_SUPPLY;
    }


    // --------------------------------
    // changing ICO parameters
    // --------------------------------
    
    // Owner can change the crowdsale wallet address at any time
    //
    function setWallet(address _wallet) onlyOwner
    {
      wallet = _wallet;
      LogWalletUpdated(wallet);
    }
    
    // Owner can change the number of tokens per ETH before the ICO start date
    //
    function setTokensPerEth(uint _tokensPerEth) onlyOwner
    {
      require(now < START_DATE);
      require(_tokensPerEth > 0);
      tokensPerEth = _tokensPerEth;
      LogTokensPerEthUpdated(tokensPerEth);
    }
        

    // Owner can change the number available tokens for the ICO
    // (must be below 70 million) 
    //
    function setIcoTokenSupply(uint _icoTokenSupply) onlyOwner
    {
        require(now < START_DATE);
        require(_icoTokenSupply < 70000000);
        icoTokenSupply = _icoTokenSupply;
        LogIcoTokenSupplyUpdated(icoTokenSupply);
    }


    // --------------------------------
    // Default function
    // --------------------------------
    
    function () payable
    {
        proxyPayment(msg.sender);
    }

    // --------------------------------
    // Accept ETH during crowdsale
    // --------------------------------

    function proxyPayment(address participant) payable
    {
        require(!icoFinished);
        require(now >= START_DATE);
        require(now <= END_DATE);
        require(msg.value > MIN_CONTRIBUTION);
        
        // get number of tokens
        uint tokens = msg.value * tokensPerEth / MULT_FACTOR;
        
        // first check if there is enough capacity
        uint available = icoTokenSupply - icoTokensIssued;
        require (tokens <= available); 

        // ok it&#39;s possible to issue tokens so let&#39;s do it
        
        // Add tokens purchased to account&#39;s balance and total supply
        // TODO - verify SafeAdd is not necessary
        balances[participant] += tokens;
        icoTokensIssued += tokens;

        // Transfer the tokens to the participant  
        Transfer(0x0, participant, tokens);
        
        // Log the token purchase
        LogTokensBought(participant, msg.value, tokens, balances[participant], icoTokensIssued);

        // Transfer the contributed ethers to the crowdsale wallet
        // throw is deprecated starting from Ethereum v0.9.0
        wallet.transfer(msg.value);
    }

    
    // --------------------------------
    // Minting of tokens by owner
    // --------------------------------

    // Tokens remaining available to mint by owner
    //
    function availableToMint()
      returns (uint)
    {
      if (icoFinished) {
        return TOTAL_TOKEN_SUPPLY - icoTokensIssued - ownerTokensMinted;
      } else {
        return TOTAL_TOKEN_SUPPLY - icoTokenSupply - ownerTokensMinted;        
      }
    }

    // Minting of tokens by owner
    //    
    function mint(address participant, uint256 tokens) onlyOwner 
    {
        require( tokens <= availableToMint() );
        balances[participant] += tokens;
        ownerTokensMinted += tokens;
        Transfer(0x0, participant, tokens);
        LogMinting(participant, tokens, ownerTokensMinted);
    }

    // --------------------------------
    // Declare ICO finished
    // --------------------------------
    
    function declareIcoFinished() onlyOwner
    {
      // the token can only be made tradeable after ICO finishes
      require( now > START_DATE || icoTokenSupply - icoTokensIssued < ICO_TRIGGER );
      icoFinished = true;
    }

    // --------------------------------
    // Make tokens tradeable
    // --------------------------------
    
    function tradeable() onlyOwner
    {
      // the token can only be made tradeable after ICO finishes
      require(icoFinished);
      tradeable = true;
    }

    // --------------------------------
    // Transfers
    // --------------------------------

    function transfer(address _to, uint _amount) 
      returns (bool success)
    {
      // Cannot transfer out until tradeable, except for owner
      require(tradeable || msg.sender == owner);
      return super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint _amount) 
      returns (bool success)
    {
        // not possible until tradeable
        require(tradeable);
        return super.transferFrom(_from, _to, _amount);
    }

    // --------------------------------
    // Varia
    // --------------------------------

    // Transfer out any accidentally sent ERC20 tokens
    function transferAnyERC20Token(address tokenAddress, uint amount) onlyOwner 
      returns (bool success) 
    {
        return ERC20Interface(tokenAddress).transfer(owner, amount);
    }

}