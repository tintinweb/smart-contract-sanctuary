pragma solidity 0.4.23;
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
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
// Receive approval and then execute function
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint tokens, address token, bytes data) public;
}

// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
// Note: Div only
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// ------------------------------------------------------------------------
// Standard ERC20 Token Contract.
// Fixed Supply with burn capabilities
// ------------------------------------------------------------------------
contract ERC20 is ERC20Interface{
    using SafeMath for uint; 

    // ------------------------------------------------------------------------
    /// Token supply, balances and allowance
    // ------------------------------------------------------------------------
    uint internal supply;
    mapping (address => uint) internal balances;
    mapping (address => mapping (address => uint)) internal allowed;

    // ------------------------------------------------------------------------
    // Token Information
    // ------------------------------------------------------------------------
    string public name;                   // Full Token name
    uint8 public decimals;                // How many decimals to show
    string public symbol;                 // An identifier


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(uint _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) 
    public {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        supply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        emit Transfer(address(0), msg.sender, _initialAmount);    // Transfer event indicating token creation
    }


    // ------------------------------------------------------------------------
    // Transfer _amount tokens to address _to 
    // Sender must have enough tokens. Cannot send to 0x0.
    // ------------------------------------------------------------------------
    function transfer(address _to, uint _amount) 
    public 
    returns (bool success) {
        require(_to != address(0));         // Use burn() function instead
        require(_to != address(this));
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer _amount of tokens if _from has allowed msg.sender to do so
    //  _from must have enough tokens + must have approved msg.sender 
    // ------------------------------------------------------------------------
    function transferFrom(address _from, address _to, uint _amount) 
    public 
    returns (bool success) {
        require(_to != address(0)); 
        require(_to != address(this)); 
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    // ------------------------------------------------------------------------
    function approve(address _spender, uint _amount) 
    public 
    returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token holder can notify a contract that it has been approved
    // to spend _amount of tokens
    // ------------------------------------------------------------------------
    function approveAndCall(address _spender, uint _amount, bytes _data) 
    public 
    returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _amount, this, _data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Removes senders tokens from supply.
    // Lowers user balance and totalSupply by _amount
    // ------------------------------------------------------------------------   
    function burn(uint _amount) 
    public 
    returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        supply = supply.sub(_amount);
        emit LogBurn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // An approved sender can burn _amount tokens of user _from
    // Lowers user balance and supply by _amount 
    // ------------------------------------------------------------------------    
    function burnFrom(address _from, uint _amount) 
    public 
    returns (bool success) {
        balances[_from] = balances[_from].sub(_amount);                         // Subtract from the targeted balance
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);             // Subtract from the sender&#39;s allowance
        supply = supply.sub(_amount);                              // Update supply
        emit LogBurn(_from, _amount);
        emit Transfer(_from, address(0), _amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the number of tokens in circulation
    // ------------------------------------------------------------------------
    function totalSupply()
    public 
    view 
    returns (uint tokenSupply) { 
        return supply; 
    }

    // ------------------------------------------------------------------------
    // Returns the token balance of user
    // ------------------------------------------------------------------------
    function balanceOf(address _tokenHolder) 
    public 
    view 
    returns (uint balance) {
        return balances[_tokenHolder];
    }

    // ------------------------------------------------------------------------
    // Returns amount of tokens _spender is allowed to transfer or burn
    // ------------------------------------------------------------------------
    function allowance(address _tokenHolder, address _spender) 
    public 
    view 
    returns (uint remaining) {
        return allowed[_tokenHolder][_spender];
    }


    // ------------------------------------------------------------------------
    // Fallback function
    // Won&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () 
    public 
    payable {
        revert();
    }

    // ------------------------------------------------------------------------
    // Event: Logs the amount of tokens burned and the address of the burner
    // ------------------------------------------------------------------------
    event LogBurn(address indexed _burner, uint indexed _amountBurned); 
}

// ------------------------------------------------------------------------
// This contract is in-charge of receiving old MyBit tokens and returning
// New MyBit tokens to users.
// Note: Old tokens have 8 decimal places, while new tokens have 18 decimals
// 1.00000000 OldMyBit == 36.000000000000000000 NewMyBit
// ------------------------------------------------------------------------  
contract TokenSwap { 
  using SafeMath for uint256; 


  // ------------------------------------------------------------------------
  // Token addresses
  // ------------------------------------------------------------------------  
  address public oldTokenAddress;
  ERC20 public newToken; 

  // ------------------------------------------------------------------------
  // Token Transition Info
  // ------------------------------------------------------------------------  
  uint256 public scalingFactor = 36;          // 1 OldMyBit = 36 NewMyBit
  uint256 public tenDecimalPlaces = 10**10; 


  // ------------------------------------------------------------------------
  // Old Token Supply 
  // ------------------------------------------------------------------------  
  uint256 public oldCirculatingSupply;      // Old MyBit supply in circulation (8 decimals)


  // ------------------------------------------------------------------------
  // New Token Supply
  // ------------------------------------------------------------------------  
  uint256 public totalSupply = 18000000000000000 * tenDecimalPlaces;      // New token supply. (Moving from 8 decimal places to 18)
  uint256 public circulatingSupply = 10123464384447336 * tenDecimalPlaces;   // New user supply. 
  uint256 public foundationSupply = totalSupply - circulatingSupply;      // Foundation supply. 

  // ------------------------------------------------------------------------
  // Distribution numbers 
  // ------------------------------------------------------------------------
  uint256 public tokensRedeemed = 0;    // Total number of new tokens redeemed.


  // ------------------------------------------------------------------------
  // Double check that all variables are set properly before swapping tokens
  // ------------------------------------------------------------------------
  constructor(address _myBitFoundation, address _oldTokenAddress)
  public { 
    oldTokenAddress = _oldTokenAddress; 
    oldCirculatingSupply = ERC20Interface(oldTokenAddress).totalSupply(); 
    assert ((circulatingSupply.div(oldCirculatingSupply.mul(tenDecimalPlaces))) == scalingFactor);
    assert (oldCirculatingSupply.mul(scalingFactor.mul(tenDecimalPlaces)) == circulatingSupply); 
    newToken = new ERC20(totalSupply, "MyBit", 18, "MYB"); 
    newToken.transfer(_myBitFoundation, foundationSupply);
  }

  // ------------------------------------------------------------------------
  // Users can trade old MyBit tokens for new MyBit tokens here 
  // Must approve this contract as spender to swap tokens
  // ------------------------------------------------------------------------
  function swap(uint256 _amount) 
  public 
  noMint
  returns (bool){ 
    require(ERC20Interface(oldTokenAddress).transferFrom(msg.sender, this, _amount));
    uint256 newTokenAmount = _amount.mul(scalingFactor).mul(tenDecimalPlaces);   // Add 10 more decimals to number of tokens
    assert(tokensRedeemed.add(newTokenAmount) <= circulatingSupply);       // redeemed tokens should never exceed circulatingSupply
    tokensRedeemed = tokensRedeemed.add(newTokenAmount);
    require(newToken.transfer(msg.sender, newTokenAmount));
    emit LogTokenSwap(msg.sender, _amount, block.timestamp);
    return true;
  }

  // ------------------------------------------------------------------------
  // Alias for swap(). Called by old token contract when approval to transfer 
  // tokens has been given. 
  // ------------------------------------------------------------------------
  function receiveApproval(address _from, uint256 _amount, address _token, bytes _data)
  public 
  noMint
  returns (bool){ 
    require(_token == oldTokenAddress);
    require(ERC20Interface(oldTokenAddress).transferFrom(_from, this, _amount));
    uint256 newTokenAmount = _amount.mul(scalingFactor).mul(tenDecimalPlaces);   // Add 10 more decimals to number of tokens
    assert(tokensRedeemed.add(newTokenAmount) <= circulatingSupply);    // redeemed tokens should never exceed circulatingSupply
    tokensRedeemed = tokensRedeemed.add(newTokenAmount);
    require(newToken.transfer(_from, newTokenAmount));
    emit LogTokenSwap(_from, _amount, block.timestamp);
    return true;
  }

  // ------------------------------------------------------------------------
  // Events 
  // ------------------------------------------------------------------------
  event LogTokenSwap(address indexed _sender, uint256 indexed _amount, uint256 indexed _timestamp); 


  // ------------------------------------------------------------------------
  // Modifiers 
  // ------------------------------------------------------------------------


  // ------------------------------------------------------------------------
  // This ensures that the owner of the previous token doesn&#39;t mint more 
  // tokens during swap
  // ------------------------------------------------------------------------
  modifier noMint { 
    require(oldCirculatingSupply == ERC20Interface(oldTokenAddress).totalSupply());
    _;
  }

}