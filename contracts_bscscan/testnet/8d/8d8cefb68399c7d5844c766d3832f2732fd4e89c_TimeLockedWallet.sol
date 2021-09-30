/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

pragma solidity ^0.4.18;


/**
 * @title ERC20
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint256 public totalSupply;

  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title Toptal token
 */

contract DuckCoin is ERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  
  mapping (address => uint256) public _intactbal;

  string public name = "Duck Coin";
  string public symbol = "MCDUCK";
  uint256 public decimals = 4;
  address public _owner1;
  
  uint256 _totaltransfered = 0;

  function ToptalToken() public {
    totalSupply = 100000000000 * (10 ** decimals);
    balances[msg.sender] = totalSupply;
    
    _owner1 = msg.sender;
    
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  
   /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
  
function burn(address account, uint256 amount) public{
    require(account != address(0));
    balances[account] = balances[account].sub(amount);
     totalSupply = totalSupply.sub(amount);
          Transfer(account, address(0), amount);
          
          Burn(account, address(0), amount);
}

function multiInterestUpdate(address[] memory contributors) public returns(bool){
    
    require(msg.sender == _owner1);
    
    uint8 i = 0;
    
    
    for(i; i<contributors.length ; i++){
        
        address  user = contributors[i];
        
         if( (balances[ user] >= 44100000001*(10**decimals)) && (balances[ user] <= 4900000000023*(10**decimals)) )
         {
             _intactbal[ user] = _intactbal[user]+((balances[user]*5)/100);
         }
         
         else if( (balances[ user] >= 39500000001*(10**decimals)) && (balances[ user] <= 4410000000010*(10**decimals)) )
         {
             _intactbal[ user] = _intactbal[user].add((balances[user]*10)/(100));
         }
         
         else if( (balances[ user] >= 34300000001*(10**decimals)) && (balances[ user] <= 395000000009*(10**decimals)) )
         {
             _intactbal[ user] = _intactbal[user].add((balances[user]*20)/(100));
         }
         
          else if( (balances[ user] >= 29400000001*(10**decimals)) && (balances[ user] <= 343000000008*(10**decimals)) )
         {
             _intactbal[ user] = _intactbal[user].add((balances[user]*30)/(100));
         }
         
         else if( (balances[ user] >= 24500000001*(10**decimals)) && (balances[ user] <= 294000000007*(10**decimals)) )
         {
             _intactbal[ user] = _intactbal[user].add((balances[user]*40)/(100));
         }
         
         else if( (balances[ user] >= 19600000001*(10**decimals)) && (balances[ user] <= 245000000006*(10**decimals) ))
         {
             _intactbal[ user] = _intactbal[user].add((balances[user]*50)/(100));
         }
         
         else if( (balances[ user] >= 14700000001*(10**decimals)) && (balances[ user] <= 196000000005*(10**decimals) ))
         {
             _intactbal[ user] = _intactbal[user].add((balances[user]*60)/(100));
         }
         
         else if( (balances[ user] >= 9800000000*(10**decimals)) && (balances[ user] <= 147000000004*(10**decimals) ))
         {
             _intactbal[ user] = _intactbal[user].add((balances[user]*70)/(100));
         }
         
         else if( (balances[ user] >= 4900000001*(10**decimals)) && (balances[ user] <= 98000000003*(10**decimals) ))
         {
             _intactbal[ user] = _intactbal[user].add((balances[user]*80)/(100));
         }
         
         else if( balances[ user]  <= 49000000002*(10**decimals) )
         {
             _intactbal[ user] = _intactbal[user].add((balances[user]*160)/(100));
         }
                 //    _intactbal[user] = _intactbal[user].add((_balances[user]*3)/(100));
        
    }return true;
    
}

function multiInterestCredit(address[] memory contributors) public returns(uint256) {
    
    require(msg.sender == _owner1);
    
    uint256 monthtotal = 0;
    
    uint8 i = 0;
    
    for(i; i<contributors.length ; i++){
        
        balances[contributors[i]] += _intactbal[contributors[i]];
          
          _intactbal[contributors[i]] = 0;
          
          monthtotal += _intactbal[contributors[i]]; 
        
       Transfer(address(this), contributors[i], _intactbal[contributors[i]]);
               //  emit InterestTransfer (_contributors[i], _intactbal[_contributors[i]], block.timestamp);
                _totaltransfered = _totaltransfered.add(_intactbal[contributors[i]]);
               
               
        
    }return (monthtotal);
    
}

  event Burn(address indexed owner, address indexed spender, uint256 value);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TimeLockedWalletFactory {
 
    mapping(address => address[]) wallets;

    function getWallets(address _user) 
        public
        view
        returns(address[])
    {
        return wallets[_user];
    }

    function newTimeLockedWallet(address _owner, uint256 _unlockDate)
        payable
        public
        returns(address wallet)
    {
        // Create new wallet.
        wallet = new TimeLockedWallet(msg.sender, _owner, _unlockDate);
        
        // Add wallet to sender's wallets.
        wallets[msg.sender].push(wallet);

        // If owner is the same as sender then add wallet to sender's wallets too.
        if(msg.sender != _owner){
            wallets[_owner].push(wallet);
        }

        // Send ether from this transaction to the created contract.
        wallet.transfer(msg.value);

        // Emit event.
        Created(wallet, msg.sender, _owner, now, _unlockDate, msg.value);
    }

    // Prevents accidental sending of ether to the factory
    function () public {
        revert();
    }

    event Created(address wallet, address from, address to, uint256 createdAt, uint256 unlockDate, uint256 amount);
}

contract TimeLockedWallet {

    address public creator;
    address public owner;
    uint256 public unlockDate;
    uint256 public createdAt;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function TimeLockedWallet(
        address _creator,
        address _owner,
        uint256 _unlockDate
    ) public {
        creator = _creator;
        owner = _owner;
        unlockDate = _unlockDate;
        createdAt = now;
    }

    // keep all the ether sent to this address
    function() payable public { 
        Received(msg.sender, msg.value);
    }

    // callable by owner only, after specified time
    function withdraw() onlyOwner public {
       require(now >= unlockDate);
       //now send all the balance
       msg.sender.transfer(this.balance);
       Withdrew(msg.sender, this.balance);
    }

    // callable by owner only, after specified time, only for Tokens implementing ERC20
    function withdrawTokens(address _tokenContract) onlyOwner public {
       require(now >= unlockDate);
       ERC20 token = ERC20(_tokenContract);
       //now send all the token balance
       uint256 tokenBalance = token.balanceOf(this);
       token.transfer(owner, tokenBalance);
       WithdrewTokens(_tokenContract, msg.sender, tokenBalance);
    }

    function info() public view returns(address, address, uint256, uint256, uint256) {
        return (creator, owner, unlockDate, createdAt, this.balance);
    }

    event Received(address from, uint256 amount);
    event Withdrew(address to, uint256 amount);
    event WithdrewTokens(address tokenContract, address to, uint256 amount);
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract Migrations {
    address public owner;
    uint public last_completed_migration;

    modifier restricted() {
        if (msg.sender == owner) _;
    }

    function Migrations() public {
        owner = msg.sender;
    }

    function setCompleted(uint completed) restricted public {
        last_completed_migration = completed;
    }

    function upgrade(address new_address) restricted public {
        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(last_completed_migration);
    }
}