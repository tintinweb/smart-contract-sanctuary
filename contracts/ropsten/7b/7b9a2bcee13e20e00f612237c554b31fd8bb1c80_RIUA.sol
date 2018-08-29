pragma solidity ^0.4.24;
/****************************************************************************** 
 *
 * Some interesting features for Regulating Securities Tokens Accounts in IBBT
 * Securities Tokens Vault offer by IBBT
 * 
 * XYZ Corporatiop Securities Token
 * 
 * 
*/

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
}



contract Nonpayable {

  // ------------------------------------------------------------------------
  // Don&#39;t accept ETH
  // ------------------------------------------------------------------------
  function () public payable {
    revert();
  }
}

contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function DissolveBusiness() public onlyOwner { 
    // This function is called when the organization is no longer actively operating
    // The Management can decide to Terminate access to the Securities Token. 
    // The Blockchain records remain, but the contract no longer can perform functions pertaining 
    // to the operations of the Securities.
    // https://www.irs.gov/businesses/small-businesses-self-employed/closing-a-business-checklist
    selfdestruct(owner);
  }
}



// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSharesIssued() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Regulated is Ownable {
    
  event ShareholderRegistered(address indexed shareholder);
  event CorpBlackBook(address indexed shareholder);           // Consider this option as the Nevada Commission little black book, bad actors are blacklisted 
  
  mapping(address => bool) regulationStatus;

  function RegisterShareholder(address shareholder) public onlyOwner {
    regulationStatus[shareholder] = true;
    emit ShareholderRegistered(shareholder);
  }

  function NevadaBlackBook(address shareholder) public onlyOwner {
    regulationStatus[shareholder] = false;
    emit CorpBlackBook(shareholder);
  }
  
  function ensureRegulated(address shareholder) public constant {
    require(regulationStatus[shareholder] == true);
  }

  function isRegulated(address shareholder) public constant returns (bool approved) { 
    return regulationStatus[shareholder];
  }
}

contract  AcceptEth is Regulated {
    address public owner;
    uint public price;
    mapping (address => uint) balance;

    constructor() public {
        // set owner as the address of the one who created the contract
        owner = msg.sender;
        // set the price to 2 ether
        price = 1 ether; // Exclude Gas/Wei to transfer
        
    }

    function accept() public payable onlyOwner {

        // Error out if anything other than 2 ether is sent
        require(msg.value == price);
        
        RegisterShareholder(owner);
        
        regulationStatus[owner] = true;
        emit ShareholderRegistered(owner);        
 

        // Track that calling account deposited ether
        balance[msg.sender] += msg.value;
    }
    
    function refund(uint amountRequested) public onlyOwner {

        RegisterShareholder(owner);
        
        regulationStatus[owner] = true;
        
        emit ShareholderRegistered(owner);
        
        require(amountRequested > 0 && amountRequested <= balance[msg.sender]);
        

        balance[msg.sender] -= amountRequested;

        msg.sender.transfer(amountRequested); // contract transfers ether to msg.sender&#39;s address
        
        
    }
    
    event Accept(address from, address indexed to, uint amountRequested);
    event Refund(address to, address indexed from, uint amountRequested);
}

contract ERC20 {
  function totalSupply() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);
  
  
// "Increases total supply of the token by value and credits it to address owner."
//  function increaseShares(uint256 value, address to) returns (bool);

// "Decreases total supply by value and withdraws it from address owner if it has a sufficient balance."
//  function decreaseShares(uint256 value, address from) returns (bool);


  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract RIUA is ERC20, Regulated, AcceptEth {
  using SafeMath for uint;

  string public symbol;
  string public  name;
  uint8 public decimals;
  uint public _totalShares;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() public {
    symbol = "RIU";                                     // Create the Sucurities Token Symbol Here
    name = "Residual Income Unit DAO A";                      // Description of the Securetized Tokens
    // In our sample we have created securites tokens and fractional securities for the tokens upto 18 digits
    decimals = 0;                                       // Number of Digits [0-18] If an organization wants to fractionalize the securities
    // The 0 can be any digit up to 18. Eighteen is the standard for cryptocurrencies
    _totalShares = 100000 * 10**uint(decimals);       // Total Number of Securities Issued (example 5,000,000 Shares of XYZ)
    balances[owner] = _totalShares;
    emit Transfer(address(0), owner, _totalShares);     // Owner or Company Representative (CFO/COO/CEO/CHAIRMAN)

    regulationStatus[owner] = true;
    emit ShareholderRegistered(owner);
  }

  function issue(address recipient, uint tokens) public onlyOwner returns (bool success) {
    require(recipient != address(0));
    require(recipient != owner);
    
    RegisterShareholder(recipient);
    transfer(recipient, tokens);
    return true;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    // Organization is Merged or Sold and Securities Management needs to transfer to new owners
    require(newOwner != address(0));
    require(newOwner != owner);
   
    RegisterShareholder(newOwner);
    transfer(newOwner, balances[owner]);
    owner = newOwner;
  }

  function totalSupply() public constant returns (uint supply) {
    return _totalShares - balances[address(0)];
  }

  function balanceOf(address tokenOwner) public constant returns (uint balance) {
    return balances[tokenOwner];
  }

  function transfer(address to, uint tokens) public returns (bool success) {
    ensureRegulated(msg.sender);
    ensureRegulated(to);
    
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }

  function approve(address spender, uint tokens) public returns (bool success) {
    // Put a check for race condition issue with approval workflow of ERC20
    require((tokens == 0) || (allowed[msg.sender][spender] == 0));
    
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }

  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
    ensureRegulated(from);
    ensureRegulated(to);

    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }

  function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }

  // ---------------------------------------------------------------------------
  // Corporation can issue more shares or revoce/cancel shares
  // https://github.com/ethereum/EIPs/pull/621
  // ---------------------------------------------------------------------------
  
  // ------------------------------------------------------------------------
  // Owner can transfer out any accidentally sent ERC20 tokens
  // ------------------------------------------------------------------------
  function transferOtherERC20Assets(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
  }
}