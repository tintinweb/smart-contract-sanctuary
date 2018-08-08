pragma solidity 0.4.24;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Interface {
     function totalSupply() public constant returns (uint);
     function balanceOf(address tokenOwner) public constant returns (uint balance);
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
     function transfer(address to, uint tokens) public returns (bool success);
     function approve(address spender, uint tokens) public returns (bool success);
     function transferFrom(address from, address to, uint tokens) public returns (bool success);
     function mint(address from, address to, uint tokens) public;
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract RADION is ERC20Interface,Ownable {

   using SafeMath for uint256;
   
   string public name;
   string public symbol;
   uint256 public decimals;

   uint256 public _totalSupply;
   mapping(address => uint256) tokenBalances;
   address musicContract;
   address advertisementContract;
   address sale;
   address wallet;

   // Owner of account approves the transfer of an amount to another account
   mapping (address => mapping (address => uint256)) allowed;
   
    // whitelisted addresses are those that have registered on the website
    mapping(address=>bool) whiteListedAddresses;
   
   /**
   * @dev Contructor that gives msg.sender all of existing tokens.
   */
    constructor(address _wallet) public {
        owner = msg.sender;
        wallet = _wallet;
        name  = "RADION";
        symbol = "RADIO";
        decimals = 18;
        _totalSupply = 55000000 * 10 ** uint(decimals);
        tokenBalances[wallet] = _totalSupply;   //Since we divided the token into 10^18 parts
    }
    
     // Get the token balance for account `tokenOwner`
     function balanceOf(address tokenOwner) public constant returns (uint balance) {
         return tokenBalances[tokenOwner];
     }
  
     // Transfer the balance from owner&#39;s account to another account
     function transfer(address to, uint tokens) public returns (bool success) {
         require(to != address(0));
         require(tokens <= tokenBalances[msg.sender]);
         tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(tokens);
         tokenBalances[to] = tokenBalances[to].add(tokens);
         emit Transfer(msg.sender, to, tokens);
         return true;
     }
  
     /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= tokenBalances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    tokenBalances[_from] = tokenBalances[_from].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
  
     /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

     // ------------------------------------------------------------------------
     // Total supply
     // ------------------------------------------------------------------------
     function totalSupply() public constant returns (uint) {
         return _totalSupply  - tokenBalances[address(0)];
     }
     
    
     
     // ------------------------------------------------------------------------
     // Returns the amount of tokens approved by the owner that can be
     // transferred to the spender&#39;s account
     // ------------------------------------------------------------------------
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
         return allowed[tokenOwner][spender];
     }
     
     /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

     //only to be used by the ICO
     
    function mint(address sender, address receiver, uint256 tokenAmount) public {
      require(msg.sender == musicContract || msg.sender == advertisementContract);
      require(tokenBalances[sender] >= tokenAmount);               // checks if it has enough to sell
      tokenBalances[receiver] = tokenBalances[receiver].add(tokenAmount);                  // adds the amount to buyer&#39;s balance
      tokenBalances[sender] = tokenBalances[sender].sub(tokenAmount);                        // subtracts amount from seller&#39;s balance
      emit Transfer(sender, receiver, tokenAmount); 
    }
    
    function setAddresses(address music, address advertisement,address _sale) public onlyOwner
    {
       musicContract = music;
       advertisementContract = advertisement;
       sale = _sale;
    }

     function () public payable {
        revert();
     }
 
    function buy(address beneficiary, uint ethAmountSent, uint rate) public onlyOwner
    {
        require(beneficiary != 0x0 && whiteListedAddresses[beneficiary] == true);
        require(ethAmountSent>0);
        uint weiAmount = ethAmountSent;
        uint tokens = weiAmount.mul(rate);
        
        require(tokenBalances[wallet] >= tokens);               // checks if it has enough to sell
        tokenBalances[beneficiary] = tokenBalances[beneficiary].add(tokens);                  // adds the amount to buyer&#39;s balance
        tokenBalances[wallet] = tokenBalances[wallet].sub(tokens);                        // subtracts amount from seller&#39;s balance
        emit Transfer(wallet, beneficiary, tokens); 
    }
 
     // ------------------------------------------------------------------------
     // Owner can transfer out any accidentally sent ERC20 tokens
     // ------------------------------------------------------------------------
     function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
         return ERC20Interface(tokenAddress).transfer(owner, tokens);
     }

    function addAddressToWhiteList(address whitelistaddress) public onlyOwner
    {
        whiteListedAddresses[whitelistaddress] = true;
    }
    
    function checkIfAddressIsWhitelisted(address whitelistaddress) public onlyOwner constant returns (bool)
    {
        if (whiteListedAddresses[whitelistaddress] == true)
            return true;
        return false; 
    }
}