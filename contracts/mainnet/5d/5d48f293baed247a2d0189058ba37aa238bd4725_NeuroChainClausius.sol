pragma solidity ^0.4.13;

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

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

contract NeuroChainClausius is Owned, ERC20Interface {

  // Adding safe calculation methods to uint256
  using SafeMath for uint;
  // Defining balances mapping (ERC20)
  mapping(address => uint256) balances;
  // Defining allowances mapping (ERC20)
  mapping(address => mapping (address => uint256)) allowed;
  // Defining addresses allowed to bypass global freeze
  mapping(address => bool) public freezeBypassing;
  // Defining addresses association between NeuroChain and ETH network
  mapping(address => string) public neuroChainAddresses;
  // Event raised when a NeuroChain address is changed
  event NeuroChainAddressSet(
    address ethAddress,
    string neurochainAddress,
    uint timestamp,
    bool isForcedChange
  );
  // Event raised when trading status is toggled
  event FreezeStatusChanged(
    bool toStatus,
    uint timestamp
  );
  // Token Symbol
  string public symbol = "NCC";
  // Token Name
  string public name = "NeuroChain Clausius";
  // Token Decimals
  uint8 public decimals = 18;
  // Total supply of token
  uint public _totalSupply = 657440000 * 10**uint(decimals);
  // Current distributed supply
  uint public _circulatingSupply = 0;
  // Global freeze toggle
  bool public tradingLive = false;
  // Address of the Crowdsale Contract
  address public icoContractAddress;
  /**
   * @notice Sending Tokens to an address
   * @param to The receiver address
   * @param tokens The amount of tokens to send (without de decimal part)
   * @return {"success": "If the operation completed successfuly"}
   */
  function distributeSupply(
    address to,
    uint tokens
  )
  public onlyOwner returns (bool success)
  {
    uint tokenAmount = tokens.mul(10**uint(decimals));
    require(_circulatingSupply.add(tokenAmount) <= _totalSupply);
    _circulatingSupply = _circulatingSupply.add(tokenAmount);
    balances[to] = tokenAmount;
    return true;
  }
  /**
   * @notice Allowing a spender to bypass global frezze
   * @param sender The allowed address
   * @return {"success": "If the operation completed successfuly"}
   */
  function allowFreezeBypass(
    address sender
  )
  public onlyOwner returns (bool success)
  {
    freezeBypassing[sender] = true;
    return true;
  }
  /**
   * @notice Sets if the trading is live
   * @param isLive Enabling/Disabling trading
   */
  function setTradingStatus(
    bool isLive
  )
  public onlyOwner
  {
    tradingLive = isLive;
    FreezeStatusChanged(tradingLive, block.timestamp);
  }
  // Modifier that requires the trading to be live or
  // allowed to bypass the freeze status
  modifier tokenTradingMustBeLive(address sender) {
    require(tradingLive || freezeBypassing[sender]);
    _;
  }
  /**
   * @notice Sets the ICO Contract Address variable to be used with the
   * `onlyIcoContract` modifier.
   * @param contractAddress The NeuroChainCrowdsale deployed address
   */
  function setIcoContractAddress(
    address contractAddress
  )
  public onlyOwner
  {
    freezeBypassing[contractAddress] = true;
    icoContractAddress = contractAddress;
  }
  // Modifier that requires msg.sender to be Crowdsale Contract
  modifier onlyIcoContract() {
    require(msg.sender == icoContractAddress);
    _;
  }
  /**
   * @notice Permit `msg.sender` to set its NeuroChain Address
   * @param neurochainAddress The NeuroChain Address
   */
  function setNeuroChainAddress(
    string neurochainAddress
  )
  public
  {
    neuroChainAddresses[msg.sender] = neurochainAddress;
    NeuroChainAddressSet(
      msg.sender,
      neurochainAddress,
      block.timestamp,
      false
    );
  }
  /**
   * @notice Force NeuroChain Address to be associated to a
   * standard ERC20 account
   * @dev Can only be called by the ICO Contract
   * @param ethAddress The ETH address to associate
   * @param neurochainAddress The NeuroChain Address
   */
  function forceNeuroChainAddress(
    address ethAddress,
    string neurochainAddress
  )
  public onlyIcoContract
  {
    neuroChainAddresses[ethAddress] = neurochainAddress;
    NeuroChainAddressSet(
      ethAddress,
      neurochainAddress,
      block.timestamp,
      true
    );
  }
  /**
   * @notice Return the total supply of the token
   * @dev This function is part of the ERC20 standard
   * @return The token supply
   */
  function totalSupply() public constant returns (uint) {
    return _totalSupply;
  }
  /**
   * @notice Get the token balance of `tokenOwner`
   * @dev This function is part of the ERC20 standard
   * @param tokenOwner The wallet to get the balance of
   * @return {"balance": "The balance of `tokenOwner`"}
   */
  function balanceOf(
    address tokenOwner
  )
  public constant returns (uint balance)
  {
    return balances[tokenOwner];
  }
  /**
   * @notice Transfers `tokens` from msg.sender to `to`
   * @dev This function is part of the ERC20 standard
   * @param to The address that receives the tokens
   * @param tokens Token amount to transfer
   * @return {"success": "If the operation completed successfuly"}
   */
  function transfer(
    address to,
    uint tokens
  )
  public tokenTradingMustBeLive(msg.sender) returns (bool success)
  {
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    Transfer(msg.sender, to, tokens);
    return true;
  }
  /**
   * @notice Transfer tokens from an address to another
   * through an allowance made beforehand
   * @dev This function is part of the ERC20 standard
   * @param from The address sending the tokens
   * @param to The address recieving the tokens
   * @param tokens Token amount to transfer
   * @return {"success": "If the operation completed successfuly"}
   */
  function transferFrom(
    address from,
    address to,
    uint tokens
  )
  public tokenTradingMustBeLive(from) returns (bool success)
  {
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    Transfer(from, to, tokens);
    return true;
  }
  /**
   * @notice Approve an address to send `tokenAmount` tokens to `msg.sender` (make an allowance)
   * @dev This function is part of the ERC20 standard
   * @param spender The allowed address
   * @param tokens The maximum amount allowed to spend
   * @return {"success": "If the operation completed successfuly"}
   */
  function approve(
    address spender,
    uint tokens
  )
  public returns (bool success)
  {
    allowed[msg.sender][spender] = tokens;
    Approval(msg.sender, spender, tokens);
    return true;
  }
  /**
   * @notice Get the remaining allowance for a spender on a given address
   * @dev This function is part of the ERC20 standard
   * @param tokenOwner The address that owns the tokens
   * @param spender The spender
   * @return {"remaining": "The amount of tokens remaining in the allowance"}
   */
  function allowance(
    address tokenOwner,
    address spender
  )
  public constant returns (uint remaining)
  {
    return allowed[tokenOwner][spender];
  }
  /**
   * @notice Permits to create an approval on a contract and then call a method
   * on the approved contract right away.
   * @param spender The allowed address
   * @param tokens The maximum amount allowed to spend
   * @param data The data sent back as parameter to the contract (bytes array)
   * @return {"success": "If the operation completed successfuly"}
   */
  function approveAndCall(
    address spender,
    uint tokens,
    bytes data
  )
  public returns (bool success)
  {
    allowed[msg.sender][spender] = tokens;
    Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
    return true;
  }
  /**
   * @notice Permits to withdraw any ERC20 tokens that have been mistakingly sent to this contract
   * @param tokenAddress The received ERC20 token address
   * @param tokens The amount of ERC20 tokens to withdraw from this contract
   * @return {"success": "If the operation completed successfuly"}
   */
  function transferAnyERC20Token(
    address tokenAddress,
    uint tokens
  )
  public onlyOwner returns (bool success)
  {
    return ERC20Interface(tokenAddress).transfer(owner, tokens);
  }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }

    /**
    * @dev Divides two numbers with 18 decimals, represented as uints (e.g. ether or token values)
    */
    uint constant ETHER_PRECISION = 10 ** 18;
    function ediv(uint x, uint y) internal pure returns (uint z) {
        // Put x to the 36th order of magnitude, so natural division will put it back to the 18th
        // Adding y/2 before putting x back to the 18th order of magnitude is necessary to force the EVM to round up instead of down
        z = add(mul(x, ETHER_PRECISION), y / 2) / y;
    }
}