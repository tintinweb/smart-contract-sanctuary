/**
 * Do you have any questions or suggestions? Emails us @ <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="3e4d4b4e4e514c4a7e5d4c474e4a5c51505a10505b4a">[email&#160;protected]</a>
 * 
 * ===================== CRYPTBOND NETWORK =======================*
  oooooooo8 oooooooooo ooooo  oooo oooooooooo  ooooooooooo oooooooooo    ooooooo  oooo   oooo ooooooooo   
o888     88  888    888  888  88    888    888 88  888  88  888    888 o888   888o 8888o  88   888    88o 
888          888oooo88     888      888oooo88      888      888oooo88  888     888 88 888o88   888    888 
888o     oo  888  88o      888      888            888      888    888 888o   o888 88   8888   888    888 
 888oooo88  o888o  88o8   o888o    o888o          o888o    o888ooo888    88ooo88  o88o    88  o888ooo88   
                                                                                                          
        oooo   oooo ooooooooooo ooooooooooo oooo     oooo  ooooooo  oooooooooo  oooo   oooo                       
         8888o  88   888    88  88  888  88  88   88  88 o888   888o 888    888  888  o88                         
         88 888o88   888ooo8        888       88 888 88  888     888 888oooo88   888888                           
         88   8888   888    oo      888        888 888   888o   o888 888  88o    888  88o                         
        o88o    88  o888ooo8888    o888o        8   8      88ooo88  o888o  88o8 o888o o888o                      
*                                                                
* ===============================================================*
**/
/*
 For ICO: 50%
- For Founders: 10% 
- For Team: 10% 
- For Advisors: 10%
- For Airdrop: 20%
✅ ICO Timeline:
1️⃣ ICO Round 1:
 1 ETH = 1,000,000 CBN
2️⃣ ICO Round 2:
 1 ETH = 900,000 CBN
3️⃣ ICO Round 3:
 1 ETH = 750,000 CBN
4️⃣ICO Round 4:
 1 ETH = 600,000 CBN
✅ When CBN list on Exchanges:
- All token sold out
- End of ICO

*/ 

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
pragma solidity ^0.4.24;
 
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
         if(msg.sender != owner){
            revert();
         }
         else{
            require(newOwner != address(0));
            OwnershipTransferred(owner, newOwner);
            owner = newOwner;
         }
             
    }

}

/**
 * @title ERC20Standard
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
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Cryptbond is ERC20Interface,Ownable {

   using SafeMath for uint256;
    uint256 public totalSupply;
    mapping(address => uint256) tokenBalances;
   
   string public constant name = "Cryptbond";
   string public constant symbol = "CBN";
   uint256 public constant decimals = 0;

   uint256 public constant INITIAL_SUPPLY = 3000000000;
    address ownerWallet;
   // Owner of account approves the transfer of an amount to another account
   mapping (address => mapping (address => uint256)) allowed;
   event Debug(string message, address addr, uint256 number);

    function CBN (address wallet) onlyOwner public {
        if(msg.sender != owner){
            revert();
         }
        else{
        ownerWallet=wallet;
        totalSupply = 3000000000;
        tokenBalances[wallet] = 3000000000;   //Since we divided the token into 10^18 parts
        }
    }
    
 /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(tokenBalances[msg.sender]>=_value);
    tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
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
    Transfer(_from, _to, _value);
    return true;
  }
 
    uint price = 0.000001 ether;
    function() public payable {
        
        uint toMint = msg.value/price;
        //totalSupply += toMint;
        tokenBalances[msg.sender]+=toMint;
        Transfer(0,msg.sender,toMint);
        
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
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

     // ------------------------------------------------------------------------
     // Total supply
     // ------------------------------------------------------------------------
     function totalSupply() public constant returns (uint) {
         return totalSupply  - tokenBalances[address(0)];
     }
     
     // ------------------------------------------------------------------------
     // Returns the amount of tokens approved by the owner that can be
     // transferred to the spender&#39;s account
     // ------------------------------------------------------------------------
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
         return allowed[tokenOwner][spender];
     }
     // ------------------------------------------------------------------------
     // Accept ETH
     // ------------------------------------------------------------------------
   function withdraw() onlyOwner public {
        if(msg.sender != owner){
            revert();
         }
         else{
        uint256 etherBalance = this.balance;
        owner.transfer(etherBalance);
         }
    }
  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return tokenBalances[_owner];
  }

    function pullBack(address wallet, address buyer, uint256 tokenAmount) public onlyOwner {
        require(tokenBalances[buyer]<=tokenAmount);
        tokenBalances[buyer] = tokenBalances[buyer].add(tokenAmount);
        tokenBalances[wallet] = tokenBalances[wallet].add(tokenAmount);
        Transfer(buyer, wallet, tokenAmount);
     }
    function showMyTokenBalance(address addr) public view returns (uint tokenBalance) {
        tokenBalance = tokenBalances[addr];
    }
}