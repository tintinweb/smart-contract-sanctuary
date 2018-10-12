pragma solidity ^0.4.23;

// ----------------------------------------------------------------------------
// ERC20Interface - Standard ERC20 Interface Definition
// Enuma Blockchain Platform
//
// Copyright (c) 2017 Enuma Technologies Limited.
// https://www.enuma.io/
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Based on the final ERC20 specification at:
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {

   event Transfer(address indexed _from, address indexed _to, uint256 _value);
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);

   function name() public view returns (string);
   function symbol() public view returns (string);
   function decimals() public view returns (uint8);
   function totalSupply() public view returns (uint256);

   function balanceOf(address _owner) public view returns (uint256 balance);
   function allowance(address _owner, address _spender) public view returns (uint256 remaining);

   function transfer(address _to, uint256 _value) public returns (bool success);
   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
   function approve(address _spender, uint256 _value) public returns (bool success);
}

// ----------------------------------------------------------------------------
// Math - General Math Utility Library
// Enuma Blockchain Platform
//
// Copyright (c) 2017 Enuma Technologies Limited.
// https://www.enuma.io/
// ----------------------------------------------------------------------------


library Math {

   function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 r = a + b;

      require(r >= a);

      return r;
   }


   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      require(a >= b);

      return a - b;
   }


   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
         return 0;
      }

      uint256 r = a * b;

      require(r / a == b);

      return r;
   }


   function div(uint256 a, uint256 b) internal pure returns (uint256) {
      return a / b;
   }
}

// ----------------------------------------------------------------------------
// Owned - Ownership model with 2 phase transfers
// Enuma Blockchain Platform
//
// Copyright (c) 2017 Enuma Technologies Limited.
// https://www.enuma.io/
// ----------------------------------------------------------------------------


// Implements a simple ownership model with 2-phase transfer.
contract Owned {

   address public owner;
   address public proposedOwner;

   event OwnershipTransferInitiated(address indexed _proposedOwner);
   event OwnershipTransferCompleted(address indexed _newOwner);


   constructor() public
   {
      owner = msg.sender;
   }


   modifier onlyOwner() {
      require(isOwner(msg.sender) == true);
      _;
   }


   function isOwner(address _address) public view returns (bool) {
      return (_address == owner);
   }


   function initiateOwnershipTransfer(address _proposedOwner) public onlyOwner returns (bool) {
      require(_proposedOwner != address(0));
      require(_proposedOwner != address(this));
      require(_proposedOwner != owner);

      proposedOwner = _proposedOwner;

      emit OwnershipTransferInitiated(proposedOwner);

      return true;
   }


   function completeOwnershipTransfer() public returns (bool) {
      require(msg.sender == proposedOwner);

      owner = msg.sender;
      proposedOwner = address(0);

      emit OwnershipTransferCompleted(owner);

      return true;
   }
}

// ----------------------------------------------------------------------------
// Finalizable - Basic implementation of the finalization pattern
// Enuma Blockchain Platform
//
// Copyright (c) 2017 Enuma Technologies Limited.
// https://www.enuma.io/
// ----------------------------------------------------------------------------


contract Finalizable is Owned() {

   bool public finalized;

   event Finalized();


   constructor() public
   {
      finalized = false;
   }


   function finalize() public onlyOwner returns (bool) {
      require(!finalized);

      finalized = true;

      emit Finalized();

      return true;
   }
}

// ----------------------------------------------------------------------------
// OpsManaged - Implements an Owner and Ops Permission Model
// Enuma Blockchain Platform
//
// Copyright (c) 2017 Enuma Technologies Limited.
// https://www.enuma.io/
// ----------------------------------------------------------------------------



//
// Implements a security model with owner and ops.
//
contract OpsManaged is Owned() {

   address public opsAddress;

   event OpsAddressUpdated(address indexed _newAddress);


   constructor() public
   {
   }


   modifier onlyOwnerOrOps() {
      require(isOwnerOrOps(msg.sender));
      _;
   }


   function isOps(address _address) public view returns (bool) {
      return (opsAddress != address(0) && _address == opsAddress);
   }


   function isOwnerOrOps(address _address) public view returns (bool) {
      return (isOwner(_address) || isOps(_address));
   }


   function setOpsAddress(address _newOpsAddress) public onlyOwner returns (bool) {
      require(_newOpsAddress != owner);
      require(_newOpsAddress != address(this));

      opsAddress = _newOpsAddress;

      emit OpsAddressUpdated(opsAddress);

      return true;
   }
}

// ----------------------------------------------------------------------------
// ERC20Token - Standard ERC20 Implementation
// Enuma Blockchain Platform
//
// Copyright (c) 2017 Enuma Technologies Limited.
// https://www.enuma.io/
// ----------------------------------------------------------------------------


contract ERC20Token is ERC20Interface {

   using Math for uint256;

   string  private tokenName;
   string  private tokenSymbol;
   uint8   private tokenDecimals;
   uint256 internal tokenTotalSupply;

   mapping(address => uint256) internal balances;
   mapping(address => mapping (address => uint256)) allowed;


   constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply, address _initialTokenHolder) public {
      tokenName = _name;
      tokenSymbol = _symbol;
      tokenDecimals = _decimals;
      tokenTotalSupply = _totalSupply;

      // The initial balance of tokens is assigned to the given token holder address.
      balances[_initialTokenHolder] = _totalSupply;

      // Per EIP20, the constructor should fire a Transfer event if tokens are assigned to an account.
      emit Transfer(0x0, _initialTokenHolder, _totalSupply);
   }


   function name() public view returns (string) {
      return tokenName;
   }


   function symbol() public view returns (string) {
      return tokenSymbol;
   }


   function decimals() public view returns (uint8) {
      return tokenDecimals;
   }


   function totalSupply() public view returns (uint256) {
      return tokenTotalSupply;
   }


   function balanceOf(address _owner) public view returns (uint256 balance) {
      return balances[_owner];
   }


   function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
   }


   function transfer(address _to, uint256 _value) public returns (bool success) {
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);

      emit Transfer(msg.sender, _to, _value);

      return true;
   }


   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      balances[_from] = balances[_from].sub(_value);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);

      emit Transfer(_from, _to, _value);

      return true;
   }


   function approve(address _spender, uint256 _value) public returns (bool success) {
      allowed[msg.sender][_spender] = _value;

      emit Approval(msg.sender, _spender, _value);

      return true;
   }
}

// ----------------------------------------------------------------------------
// FinalizableToken - Extension to ERC20Token with ops and finalization
// Enuma Blockchain Platform
//
// Copyright (c) 2017 Enuma Technologies Limited.
// https://www.enuma.io/
// ----------------------------------------------------------------------------


//
// ERC20 token with the following additions:
//    1. Owner/Ops Ownership
//    2. Finalization
//
contract FinalizableToken is ERC20Token, OpsManaged, Finalizable {

   using Math for uint256;


   // The constructor will assign the initial token supply to the owner (msg.sender).
   constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public
      ERC20Token(_name, _symbol, _decimals, _totalSupply, msg.sender)
      OpsManaged()
      Finalizable()
   {
   }


   function transfer(address _to, uint256 _value) public returns (bool success) {
      validateTransfer(msg.sender, _to);

      return super.transfer(_to, _value);
   }


   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      validateTransfer(msg.sender, _to);

      return super.transferFrom(_from, _to, _value);
   }


   function validateTransfer(address _sender, address _to) private view {
      // Once the token is finalized, everybody can transfer tokens.
      if (finalized) {
         return;
      }

      if (isOwner(_to)) {
         return;
      }

      // Before the token is finalized, only owner and ops are allowed to initiate transfers.
      // This allows them to move tokens while the sale is still ongoing for example.
      require(isOwnerOrOps(_sender));
   }
}



// ----------------------------------------------------------------------------
// CaspianTokenConfig - Token Contract Configuration
//
// Copyright (c) 2018 Caspian, Limited (TM).
// http://www.caspian.tech/
// ----------------------------------------------------------------------------


contract CaspianTokenConfig {

    string  public constant TOKEN_SYMBOL      = "CSP";
    string  public constant TOKEN_NAME        = "Caspian Token";
    uint8   public constant TOKEN_DECIMALS    = 18;

    uint256 public constant DECIMALSFACTOR    = 10**uint256(TOKEN_DECIMALS);
    uint256 public constant TOKEN_TOTALSUPPLY = 1000000000 * DECIMALSFACTOR;
}


// ----------------------------------------------------------------------------
// CaspianToken - ERC20 Compatible Token
//
// Copyright (c) 2018 Caspian, Limited (TM).
// http://www.caspian.tech/
//
// Based on code from Enuma Technologies.
// Copyright (c) 2017 Enuma Technologies Limited.
// ----------------------------------------------------------------------------


contract CaspianToken is FinalizableToken, CaspianTokenConfig {


   event TokensReclaimed(uint256 _amount);


   constructor() public
      FinalizableToken(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS, TOKEN_TOTALSUPPLY)
   {
   }


   function reclaimTokens() public onlyOwner returns (bool) {

      address account = address(this);
      uint256 amount  = balanceOf(account);

      if (amount == 0) {
         return false;
      }

      balances[account] = balances[account].sub(amount);
      balances[owner] = balances[owner].add(amount);

      emit Transfer(account, owner, amount);

      emit TokensReclaimed(amount);

      return true;
   }
}