pragma solidity 0.4.20;

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
 
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

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

contract Blockdrop is ERC20Interface,Ownable {

   using SafeMath for uint256;
   
   string public name;
   string public symbol;
   uint256 public decimals;

   uint256 public _totalSupply;
   mapping(address => uint256) tokenBalances;
   address ownerWallet;
   // Owner of account approves the transfer of an amount to another account
   mapping (address => mapping (address => uint256)) allowed;
   event Debug(string message, address addr, uint256 number);

    modifier checkSize(uint numwords) {
        assert(msg.data.length >= numwords * 32 + 4);
        _;
    }     
    
   /**
   * @dev Contructor that gives wallet all of existing tokens.
   */
    function Blockdrop(address wallet) public {
        owner = wallet;
        name  = "Blockdrop";
        symbol = "BDP";
        decimals = 18;
        _totalSupply = 2350000000;
        _totalSupply = _totalSupply.mul(10 ** uint(decimals));
        tokenBalances[owner] = _totalSupply;   //Since we divided the token into 10^18 parts
    }
    
     // Get the token balance for account `tokenOwner`
     function balanceOf(address tokenOwner) public constant returns (uint balance) {
         return tokenBalances[tokenOwner];
     }
  
     // Transfer the balance from owner&#39;s account to another account
     function transfer(address to, uint tokens) public checkSize(2) returns (bool success) {
         require(to != address(0));
         require(tokens <= tokenBalances[msg.sender]);
         tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(tokens);
         tokenBalances[to] = tokenBalances[to].add(tokens);
         Transfer(msg.sender, to, tokens);
         return true;
     }
  
     /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public checkSize(3) returns (bool) {
    require(_to != address(0));
    require(_value <= tokenBalances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    tokenBalances[_from] = tokenBalances[_from].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  
     /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public checkSize(2) returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

     // ------------------------------------------------------------------------
     // Total supply
     // ------------------------------------------------------------------------
     function totalSupply() public constant returns (uint) {
         return _totalSupply.sub(tokenBalances[address(0)]);
     }
     
    
     
     // ------------------------------------------------------------------------
     // Returns the amount of tokens approved by the owner that can be
     // transferred to the spender&#39;s account
     // ------------------------------------------------------------------------
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
         return allowed[tokenOwner][spender];
     }
     
     // ------------------------------------------------------------------------
     // Don&#39;t accept ETH
     // ------------------------------------------------------------------------
     function () public payable {
         revert();
     }
}