pragma solidity ^0.4.10;

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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
  function transfer(address _to, uint256 _value) returns (bool) {
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
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

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
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
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
    require(msg.sender == owner);
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

contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}

/**
    BlockChain Board Of Derivatives Token. 
 */
contract BBDToken is StandardToken, Ownable {

    // Metadata
    string public constant name = "BlockChain Board Of Derivatives Token";
    string public constant symbol = "BBD";
    uint256 public constant decimals = 18;
    string public constant version = &#39;1.0.0&#39;;

    // Presale parameters
    uint256 public presaleStartTime;
    uint256 public presaleEndTime;

    bool public presaleFinalized = false;

    uint256 public constant presaleTokenCreationCap = 40000 * 10 ** decimals;// amount on presale
    uint256 public constant presaleTokenCreationRate = 20000; // 2 BDD per 1 ETH

    // Sale parameters
    uint256 public saleStartTime;
    uint256 public saleEndTime;

    bool public saleFinalized = false;

    uint256 public constant totalTokenCreationCap = 240000 * 10 ** decimals; //total amount on ale and presale
    uint256 public constant saleStartTokenCreationRate = 16600; // 1.66 BDD per 1 ETH
    uint256 public constant saleEndTokenCreationRate = 10000; // 1 BDD per 1 ETH

    // Migration information
    address public migrationAgent;
    uint256 public totalMigrated;

    // Team accounts
    address public constant qtAccount = 0x87a9131485cf8ed8E9bD834b46A12D7f3092c263;
    address public constant coreTeamMemberOne = 0xe43088E823eA7422D77E32a195267aE9779A8B07;
    address public constant coreTeamMemberTwo = 0xad00884d1E7D0354d16fa8Ab083208c2cC3Ed515;

    uint256 public constant divisor = 10000;

    // ETH amount rised
    uint256 raised = 0;

    // Events
    event Migrate(address indexed _from, address indexed _to, uint256 _value);
    event TokenPurchase(address indexed _purchaser, address indexed _beneficiary, uint256 _value, uint256 _amount);

    function() payable {
        require(!presaleFinalized || !saleFinalized); //todo

        if (!presaleFinalized) {
            buyPresaleTokens(msg.sender);
        }
        else{
            buySaleTokens(msg.sender);
        }
    }

    function BBDToken(uint256 _presaleStartTime, uint256 _presaleEndTime, uint256 _saleStartTime, uint256 _saleEndTime) {
        require(_presaleStartTime >= now);
        require(_presaleEndTime >= _presaleStartTime);
        require(_saleStartTime >= _presaleEndTime);
        require(_saleEndTime >= _saleStartTime);

        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleEndTime;
        saleStartTime = _saleStartTime;
        saleEndTime = _saleEndTime;
    }

    // Get token creation rate
    function getTokenCreationRate() constant returns (uint256) {
        require(!presaleFinalized || !saleFinalized);

        uint256 creationRate;

        if (!presaleFinalized) {
            //The rate on presales is constant
            creationRate = presaleTokenCreationRate;
        } else {
            //The rate on sale is changing lineral while time is passing. On sales start it is 1.66 and on end 1.0 
            uint256 rateRange = saleStartTokenCreationRate - saleEndTokenCreationRate;
            uint256 timeRange = saleEndTime - saleStartTime;
            creationRate = saleStartTokenCreationRate.sub(rateRange.mul(now.sub(saleStartTime)).div(timeRange));
        }

        return creationRate;
    }
    
    // Buy presale tokens
    function buyPresaleTokens(address _beneficiary) payable {
        require(!presaleFinalized);
        require(msg.value != 0);
        require(now <= presaleEndTime);
        require(now >= presaleStartTime);

        uint256 bbdTokens = msg.value.mul(getTokenCreationRate()).div(divisor);
        uint256 checkedSupply = totalSupply.add(bbdTokens);
        require(presaleTokenCreationCap >= checkedSupply);

        totalSupply = totalSupply.add(bbdTokens);
        balances[_beneficiary] = balances[_beneficiary].add(bbdTokens);

        raised += msg.value;
        TokenPurchase(msg.sender, _beneficiary, msg.value, bbdTokens);
    }

    // Finalize presale
    function finalizePresale() onlyOwner external {
        require(!presaleFinalized);
        require(now >= presaleEndTime || totalSupply == presaleTokenCreationCap);

        presaleFinalized = true;

        uint256 ethForCoreMember = this.balance.mul(500).div(divisor);

        coreTeamMemberOne.transfer(ethForCoreMember); // 5%
        coreTeamMemberTwo.transfer(ethForCoreMember); // 5%
        qtAccount.transfer(this.balance); // Quant Technology 90%
    }

    // Buy sale tokens
    function buySaleTokens(address _beneficiary) payable {
        require(!saleFinalized);
        require(msg.value != 0);
        require(now <= saleEndTime);
        require(now >= saleStartTime);

        uint256 bbdTokens = msg.value.mul(getTokenCreationRate()).div(divisor);
        uint256 checkedSupply = totalSupply.add(bbdTokens);
        require(totalTokenCreationCap >= checkedSupply);

        totalSupply = totalSupply.add(bbdTokens);
        balances[_beneficiary] = balances[_beneficiary].add(bbdTokens);

        raised += msg.value;
        TokenPurchase(msg.sender, _beneficiary, msg.value, bbdTokens);
    }

    // Finalize sale
    function finalizeSale() onlyOwner external {
        require(!saleFinalized);
        require(now >= saleEndTime || totalSupply == totalTokenCreationCap);

        saleFinalized = true;

        //Add aditional 25% tokens to the Quant Technology and development team
        uint256 additionalBBDTokensForQTAccount = totalSupply.mul(2250).div(divisor); // 22.5%
        totalSupply = totalSupply.add(additionalBBDTokensForQTAccount);
        balances[qtAccount] = balances[qtAccount].add(additionalBBDTokensForQTAccount);

        uint256 additionalBBDTokensForCoreTeamMember = totalSupply.mul(125).div(divisor); // 1.25%
        totalSupply = totalSupply.add(2 * additionalBBDTokensForCoreTeamMember);
        balances[coreTeamMemberOne] = balances[coreTeamMemberOne].add(additionalBBDTokensForCoreTeamMember);
        balances[coreTeamMemberTwo] = balances[coreTeamMemberTwo].add(additionalBBDTokensForCoreTeamMember);

        uint256 ethForCoreMember = this.balance.mul(500).div(divisor);

        coreTeamMemberOne.transfer(ethForCoreMember); // 5%
        coreTeamMemberTwo.transfer(ethForCoreMember); // 5%
        qtAccount.transfer(this.balance); // Quant Technology 90%
    }

    // Allow migrate contract
    function migrate(uint256 _value) external {
        require(saleFinalized);
        require(migrationAgent != 0x0);
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalMigrated = totalMigrated.add(_value);
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
        Migrate(msg.sender, migrationAgent, _value);
    }

    function setMigrationAgent(address _agent) onlyOwner external {
        require(saleFinalized);
        require(migrationAgent == 0x0);

        migrationAgent = _agent;
    }

    // ICO Status overview. Used for BBOD landing page
    function icoOverview() constant returns (uint256 currentlyRaised, uint256 currentlyTotalSupply, uint256 currentlyTokenCreationRate){
        currentlyRaised = raised;
        currentlyTotalSupply = totalSupply;
        currentlyTokenCreationRate = getTokenCreationRate();
    }
}