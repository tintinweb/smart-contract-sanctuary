pragma solidity ^0.4.24;

pragma solidity ^0.4.11;


/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint value);
  event MintFinished();

  bool public mintingFinished = false;
  uint public totalSupply = 0;


  modifier canMint() {
    if(mintingFinished) throw;
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint _amount) public onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
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
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    if (paused) throw;
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    if (!paused) throw;
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}


/**
 * Pausable token
 *
 * Simple ERC20 Token example, with pausable token creation
 **/

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint _value) whenNotPaused {
    super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) whenNotPaused {
    super.transferFrom(_from, _to, _value);
  }
}


/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a time has passed
 */
contract TokenTimelock {

  // ERC20 basic token contract being held
  ERC20Basic token;

  // beneficiary of tokens after they are released
  address beneficiary;

  // timestamp where token release is enabled
  uint releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint _releaseTime) {
    require(_releaseTime > now);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

  /**
   * @dev beneficiary claims tokens held by time lock
   */
  function claim() {
    require(msg.sender == beneficiary);
    require(now >= releaseTime);

    uint amount = token.balanceOf(this);
    require(amount > 0);

    token.transfer(beneficiary, amount);
  }
}


/**
 * @title OMGToken
 * @dev Omise Go Token contract
 */
contract ERC20Token is PausableToken, MintableToken {
  using SafeMath for uint256;

  string public name;
  string public symbol;
  uint public decimals;


  function ERC20Token(string _name, string _symbol, uint _decimals) public  {
      name = _name;
      symbol = _symbol;
      decimals = _decimals;
  }

}

contract Teamable is ERC20Token {
    using SafeMath for uint256;
    
    struct Team {
        uint256     memberCount;
        uint256     voteCount;
    }
    
    Team[] public teams;
    string[] public teamNames;
    address[] public users;
    
    mapping(string => uint256) private teamNameToIndex;
    mapping(address => uint256) public userAddressToTeamIndex;
    mapping(address => string) public userAddressToName;
    mapping(address => bool) public tokenDistributed;
    
    event NewTeam(string name, uint256 indexed index, address indexed creator);
    event NewMember(string name, uint256 indexed teamIndex, address indexed userAddress);
    
    
    /**
      * @dev Token Initial
      * @param _name Token name.
      * @param _symbol Token symbol, less than 4 charactors.
      */
    constructor(
        string _name, 
        string _symbol
    ) 
        ERC20Token(
            _name, 
            _symbol, 
            0
        ) public {
        
        // put empty team to index 0
        teamNameToIndex[&quot;empty&quot;] = 0;
        teams.push(Team(0, 0));
        teamNames.push(&quot;empty&quot;);
    }
    
    modifier isTeamNameNotExist(string _name) {
        require(teamNameToIndex[_name] == 0);
        _;
    }
    
    modifier validTeamIndex(uint256 _index) {
        require(_index < teams.length + 1);
        _;
    }
    
    function newTeam(string _teamName, string _memberName) public 
        isTeamNameNotExist(_teamName) {

        uint256 teamIndex = teams.push(Team(0, 0)) - 1;
        teamNameToIndex[_teamName] = teamIndex;
        teamNames.push(_teamName);
        
        emit NewTeam(_teamName, teamIndex, msg.sender);
        newMember(_memberName, teamIndex);
    }
    
    function newMember(string _name, uint256 _teamIndex) public {
        require(userAddressToTeamIndex[msg.sender] == 0);
        
        // prevent duplicated user
        if (keccak256(userAddressToName[msg.sender]) == keccak256(&quot;&quot;)) {
            users.push(msg.sender);
        }

        userAddressToTeamIndex[msg.sender] = _teamIndex;
        userAddressToName[msg.sender] = _name;
        teams[_teamIndex].memberCount = teams[_teamIndex].memberCount.add(1);
        
        emit NewMember(_name, _teamIndex, msg.sender);
    }
    
    function kickMember(address _memberAddress) public onlyOwner {
        require(userAddressToTeamIndex[_memberAddress] != 0);
        
        uint256 teamIndex = userAddressToTeamIndex[_memberAddress];
        userAddressToTeamIndex[_memberAddress] = 0;
        teams[teamIndex].memberCount = teams[teamIndex].memberCount.sub(1);
    }
    
    function freezeTeam() public onlyOwner{
        
    }
    
    function teamCount() public view returns (uint256) {
        // Skip index 0
        return teams.length - 1;
    }
    
    function teamProfile(uint256 _teamId) public view 
        validTeamIndex(_teamId)
        returns (string _name, address[] _members, uint256 _voteCount) {
        
        
        Team storage team = teams[_teamId];
        _members = new address[](team.memberCount);
        uint256 memberIndex = 0;
        for(uint256 i = 0; i < users.length; i++) {
            address userAddress = users[i];
            if( _teamId == userAddressToTeamIndex[userAddress] ) {
                _members[memberIndex] = userAddress;
                memberIndex = memberIndex.add(1);
            }
        }
        
        _name = teamNames[_teamId];
        _voteCount = team.voteCount;
    }
    
    function teamNameIndex(string name) public view returns (uint256) {
        return teamNameToIndex[name];
    }
    
    function userCount() public view returns (uint256) {
        return users.length;
    }
}

contract Voteable is Teamable {
    using SafeMath for uint256;
    
    /**
      * @dev Token Initial
      * @param _name Token name.
      * @param _symbol Token symbol, less than 4 charactors.
      */
    constructor(
        string _name, 
        string _symbol
    ) 
        Teamable(
            _name, 
            _symbol
        ) public {
    }
    
    function distributeTokensToMembers(uint256 beginIndex, uint256 endIndex) public onlyOwner {
        for(uint256 i = beginIndex; i < endIndex; i++) {
            address userAddress = users[i];
            if( false == tokenDistributed[userAddress] ) {
                mint(userAddress, 3);
                tokenDistributed[userAddress] = true;
                
                // Approve this contract for transferFrom
                allowed[userAddress][this] = 3;
            }
        }
    }
    
    function distributeTokensToMembers() public onlyOwner {
        distributeTokensToMembers(0, users.length);
    }
    
    function votes() public returns (uint256[]) {
        
    }
    
    function vote(uint256 _teamIndex) public
        validTeamIndex(_teamIndex) {
        
        PizzaCoin pizza = PizzaCoin(this);
        pizza.transferFrom(msg.sender, this, 1);
            
        teams[_teamIndex].voteCount = teams[_teamIndex].voteCount.add(1);
    }
}

contract PizzaCoin is Voteable {
    using SafeMath for uint256;
    
    
    
    /**
      * @dev Token Initial
      */
    constructor(
        // string _name, 
        // string _symbol
    ) 
        Voteable(
            &quot;Pizza Coin&quot;, 
            &quot;PZC&quot;
        ) public {
    }
    
}