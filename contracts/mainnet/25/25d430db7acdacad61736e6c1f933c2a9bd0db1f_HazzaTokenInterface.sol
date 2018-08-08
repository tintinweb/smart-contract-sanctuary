pragma solidity 0.4.17;
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address internal owner;
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
/**
 * @title HazzaTokenInterface
*/
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) allowed;
  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    uint256 _allowance = allowed[_from][msg.sender];
    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}
/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  bool public mintingFinished = false;
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    //totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(msg.sender, _to, _amount);
    return true;
  }
  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  function burnTokens(uint256 _unsoldTokens) onlyOwner public returns (bool) {
    totalSupply = SafeMath.sub(totalSupply, _unsoldTokens);
  }
}
/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = false;
  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }
  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }
  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }
  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}
/**
 * @title HazzaToken TokenFunctions
 */
contract TokenFunctions is Ownable, Pausable {
  using SafeMath for uint256;
  /**
   *  @MintableToken token - Token Object
  */
  MintableToken internal token;
  struct PrivatePurchaserStruct {
    uint privatePurchaserTimeLock;
    uint256 privatePurchaserTokens;
    uint256 privatePurchaserBonus;
  }
  struct AdvisorStruct {
    uint advisorTimeLock;
    uint256 advisorTokens;
  }
  struct BackerStruct {
    uint backerTimeLock;
    uint256 backerTokens;
  }
  struct FounderStruct {
    uint founderTimeLock;
    uint256 founderTokens;
  }
  struct FoundationStruct {
    uint foundationTimeLock;
    uint256 foundationBonus;
    uint256 foundationTokens;
  }
  mapping (address => AdvisorStruct) advisor;
  mapping (address => BackerStruct) backer;
  mapping (address => FounderStruct) founder;
  mapping (address => FoundationStruct) foundation;
  mapping (address => PrivatePurchaserStruct) privatePurchaser;
  /**
   *  @uint256 totalSupply - Total supply of tokens 
   *  @uint256 publicSupply - Total public Supply 
   *  @uint256 bountySupply - Total Bounty Supply 
   *  @uint256 privateSupply - Total Private Supply 
   *  @uint256 advisorSupply - Total Advisor Supply 
   *  @uint256 backerSupply - Total Backer Supply
   *  @uint256 founderSupply - Total Founder Supply 
   *  @uint256 foundationSupply - Total Foundation Supply 
  */
      
  uint256 public totalTokens = 105926908800000000000000000; 
  uint256 internal publicSupply = 775353800000000000000000; 
  uint256 internal bountySupply = 657896000000000000000000;
  uint256 internal privateSupply = 52589473690000000000000000;  
  uint256 internal advisorSupply = 2834024170000000000000000;
  uint256 internal backerSupply = 317780730000000000000000;
  uint256 internal founderSupply = 10592690880000000000000000;
  uint256 internal foundationSupply = 38159689530000000000000000; 
  event AdvisorTokenTransfer (address indexed beneficiary, uint256 amount);
  event BackerTokenTransfer (address indexed beneficiary, uint256 amount);
  event FoundationTokenTransfer (address indexed beneficiary, uint256 amount);
  event FounderTokenTransfer (address indexed beneficiary, uint256 amount);
  event PrivatePurchaserTokenTransfer (address indexed beneficiary, uint256 amount);
  event AddAdvisor (address indexed advisorAddress, uint timeLock, uint256 advisorToken);
  event AddBacker (address indexed backerAddress, uint timeLock, uint256 backerToken);
  event AddFoundation (address indexed foundationAddress, uint timeLock, uint256 foundationToken, uint256 foundationBonus);
  event AddFounder (address indexed founderAddress, uint timeLock, uint256 founderToken);
  event BountyTokenTransfer (address indexed beneficiary, uint256 amount);
  event PublicTokenTransfer (address indexed beneficiary, uint256 amount);
  event AddPrivatePurchaser (address indexed privatePurchaserAddress, uint timeLock, uint256 privatePurchaserTokens, uint256 privatePurchaserBonus);
  function addAdvisors (address advisorAddress, uint timeLock, uint256 advisorToken) onlyOwner public returns(bool acknowledgement) {
      
      require(now < timeLock || timeLock == 0);
      require(advisorToken > 0);
      require(advisorAddress != 0x0);
      require(advisorSupply >= advisorToken);
      advisorSupply = SafeMath.sub(advisorSupply,advisorToken);
      
      advisor[advisorAddress].advisorTimeLock = timeLock;
      advisor[advisorAddress].advisorTokens = advisorToken;
      
      AddAdvisor(advisorAddress, timeLock, advisorToken);
      return true;
        
  }
  function getAdvisorStatus (address addr) public view returns(address, uint, uint256) {
        return (addr, advisor[addr].advisorTimeLock, advisor[addr].advisorTokens);
  } 
  function addBackers (address backerAddress, uint timeLock, uint256 backerToken) onlyOwner public returns(bool acknowledgement) {
      
      require(now < timeLock || timeLock == 0);
      require(backerToken > 0);
      require(backerAddress != 0x0);
      require(backerSupply >= backerToken);
      backerSupply = SafeMath.sub(backerSupply,backerToken);
           
      backer[backerAddress].backerTimeLock = timeLock;
      backer[backerAddress].backerTokens = backerToken;
      
      AddBacker(backerAddress, timeLock, backerToken);
      return true;
        
  }
  function getBackerStatus(address addr) public view returns(address, uint, uint256) {
        return (addr, backer[addr].backerTimeLock, backer[addr].backerTokens);
  } 
  function addFounder(address founderAddress, uint timeLock, uint256 founderToken) onlyOwner public returns(bool acknowledgement) {
      
      require(now < timeLock || timeLock == 0);
      require(founderToken > 0);
      require(founderAddress != 0x0);
      require(founderSupply >= founderToken);
      founderSupply = SafeMath.sub(founderSupply,founderToken);  
      founder[founderAddress].founderTimeLock = timeLock;
      founder[founderAddress].founderTokens = founderToken;
      
      AddFounder(founderAddress, timeLock, founderToken);
      return true;
        
  }
  function getFounderStatus(address addr) public view returns(address, uint, uint256) {
        return (addr, founder[addr].founderTimeLock, founder[addr].founderTokens);
  }
  function addFoundation(address foundationAddress, uint timeLock, uint256 foundationToken, uint256 foundationBonus) onlyOwner public returns(bool acknowledgement) {
      
      require(now < timeLock || timeLock == 0);
      require(foundationToken > 0);
      require(foundationBonus > 0);
      require(foundationAddress != 0x0);
      uint256 totalTokens = SafeMath.add(foundationToken, foundationBonus);
      require(foundationSupply >= totalTokens);
      foundationSupply = SafeMath.sub(foundationSupply, totalTokens);  
      foundation[foundationAddress].foundationBonus = foundationBonus;
      foundation[foundationAddress].foundationTimeLock = timeLock;
      foundation[foundationAddress].foundationTokens = foundationToken;
      
      AddFoundation(foundationAddress, timeLock, foundationToken, foundationBonus);
      return true;
        
  }
  function getFoundationStatus(address addr) public view returns(address, uint, uint256, uint256) {
        return (addr, foundation[addr].foundationTimeLock, foundation[addr].foundationBonus, foundation[addr].foundationTokens);
  }
  function addPrivatePurchaser(address privatePurchaserAddress, uint timeLock, uint256 privatePurchaserToken, uint256 privatePurchaserBonus) onlyOwner public returns(bool acknowledgement) {
      
      require(now < timeLock || timeLock == 0);
      require(privatePurchaserToken > 0);
      require(privatePurchaserBonus > 0);
      require(privatePurchaserAddress != 0x0);
      uint256 totalTokens = SafeMath.add(privatePurchaserToken, privatePurchaserBonus);
      require(privateSupply >= totalTokens);
      privateSupply = SafeMath.sub(privateSupply, totalTokens);        
      privatePurchaser[privatePurchaserAddress].privatePurchaserTimeLock = timeLock;
      privatePurchaser[privatePurchaserAddress].privatePurchaserTokens = privatePurchaserToken;
      privatePurchaser[privatePurchaserAddress].privatePurchaserBonus = privatePurchaserBonus;
      
      AddPrivatePurchaser(privatePurchaserAddress, timeLock, privatePurchaserToken, privatePurchaserBonus);
      return true;
        
  }
  function getPrivatePurchaserStatus(address addr) public view returns(address, uint256, uint, uint) {
        return (addr, privatePurchaser[addr].privatePurchaserTimeLock, privatePurchaser[addr].privatePurchaserTokens, privatePurchaser[addr].privatePurchaserBonus);
  }
  function TokenFunctions() internal {
    token = createTokenContract();
  }
  /**
   * function createTokenContract - Mintable Token Created
   */
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }
  
  /** 
   * function getTokenAddress - Get Token Address 
   */
  function getTokenAddress() onlyOwner public returns (address) {
    return token;
  }
}
/**
 * @title HazzaToken 
 */
 
contract HazzaToken is MintableToken {
    /**
    *  @string name - Token Name
    *  @string symbol - Token Symbol
    *  @uint8 decimals - Token Decimals
    *  @uint256 _totalSupply - Token Total Supply
    */
    string public constant name = "HAZZA";
    string public constant symbol = "HAZ";
    uint8 public constant decimals = 18;
    uint256 public constant _totalSupply = 105926908800000000000000000;
  
    /** Constructor HazzaToken */
    function HazzaToken() {
        totalSupply = _totalSupply;
    }
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract TokenDistribution is TokenFunctions {
  /** 
  * function grantAdvisorToken - Transfer advisor tokens 
  */
    function grantAdvisorToken() public returns(bool response) {
        require(advisor[msg.sender].advisorTokens > 0);
        require(now > advisor[msg.sender].advisorTimeLock);
        uint256 transferToken = advisor[msg.sender].advisorTokens;
        advisor[msg.sender].advisorTokens = 0;
        token.mint(msg.sender, transferToken);
        AdvisorTokenTransfer(msg.sender, transferToken);
        
        return true;
      
    }
  /** 
  * function grantBackerToken - Transfer backer tokens
  */
    function grantBackerToken() public returns(bool response) {
        require(backer[msg.sender].backerTokens > 0);
        require(now > backer[msg.sender].backerTimeLock);
        uint256 transferToken = backer[msg.sender].backerTokens;
        backer[msg.sender].backerTokens = 0;
        token.mint(msg.sender, transferToken);
        BackerTokenTransfer(msg.sender, transferToken);
        
        return true;
      
    }
  /** 
  * function grantFoundationToken - Transfer foundation tokens  
  */
    function grantFoundationToken() public returns(bool response) {
  
        if (now > foundation[msg.sender].foundationTimeLock) {
                require(foundation[msg.sender].foundationTokens > 0);
                uint256 transferToken = foundation[msg.sender].foundationTokens;
                foundation[msg.sender].foundationTokens = 0;
                token.mint(msg.sender, transferToken);
                FoundationTokenTransfer(msg.sender, transferToken);
        }
        
        if (foundation[msg.sender].foundationBonus > 0) {
                uint256 transferTokenBonus = foundation[msg.sender].foundationBonus;
                foundation[msg.sender].foundationBonus = 0;
                token.mint(msg.sender, transferTokenBonus);
                FoundationTokenTransfer(msg.sender, transferTokenBonus);
        }
        return true;
      
    }
  /** 
  * function grantFounderToken - Transfer founder tokens  
  */
    function grantFounderToken() public returns(bool response) {
        require(founder[msg.sender].founderTokens > 0);
        require(now > founder[msg.sender].founderTimeLock);
        uint256 transferToken = founder[msg.sender].founderTokens;
        founder[msg.sender].founderTokens = 0;
        token.mint(msg.sender, transferToken);
        FounderTokenTransfer(msg.sender, transferToken);
        
        return true;
      
    }
  /** 
  * function grantPrivatePurchaserToken - Transfer Private Purchasers tokens
  */
    function grantPrivatePurchaserToken() public returns(bool response) {
        if (now > privatePurchaser[msg.sender].privatePurchaserTimeLock) {
                require(privatePurchaser[msg.sender].privatePurchaserTokens > 0);
                uint256 transferToken = privatePurchaser[msg.sender].privatePurchaserTokens;
                privatePurchaser[msg.sender].privatePurchaserTokens = 0;
                token.mint(msg.sender, transferToken);
                PrivatePurchaserTokenTransfer(msg.sender, transferToken);
        }
        
        if (privatePurchaser[msg.sender].privatePurchaserBonus > 0) {
                uint256 transferBonusToken = privatePurchaser[msg.sender].privatePurchaserBonus;
                privatePurchaser[msg.sender].privatePurchaserBonus = 0;
                token.mint(msg.sender, transferBonusToken);
                PrivatePurchaserTokenTransfer(msg.sender, transferBonusToken);
        }
        return true;
      
    }
    /** 
    * function bountyFunds - Transfer bounty tokens via AirDrop
    * @param beneficiary address where owner wants to transfer tokens
    * @param tokens value of token
    */
    function bountyTransferToken(address[] beneficiary, uint256[] tokens) onlyOwner public {
        for (uint i = 0; i < beneficiary.length; i++) {
        require(bountySupply >= tokens[i]);
        bountySupply = SafeMath.sub(bountySupply, tokens[i]);
        token.mint(beneficiary[i], tokens[i]);
        BountyTokenTransfer(beneficiary[i], tokens[i]);
        
        }
    }
        /** 
    * function publicTransferToken - Transfer public tokens via AirDrop
    * @param beneficiary address where owner wants to transfer tokens
    * @param tokens value of token
    */
    function publicTransferToken(address[] beneficiary, uint256[] tokens) onlyOwner public {
        for (uint i = 0; i < beneficiary.length; i++) {
        
        require(publicSupply >= tokens[i]);
        publicSupply = SafeMath.sub(publicSupply,tokens[i]);
        token.mint(beneficiary[i], tokens[i]);
        PublicTokenTransfer(beneficiary[i], tokens[i]);
        }
    }
}
contract HazzaTokenInterface is TokenFunctions, TokenDistribution {
  
    /** Constructor HazzaTokenInterface */
    function HazzaTokenInterface() public TokenFunctions() {
    }
    
    /** HazzaToken Contract */
    function createTokenContract() internal returns (MintableToken) {
        return new HazzaToken();
    }
}