pragma solidity ^0.4.11;

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
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
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
 * @title HoQuToken
 * @dev HoQu.io token contract.
 */
contract HoQuToken is StandardToken, Pausable {
    
    string public constant name = "HOQU Token";
    string public constant symbol = "HQX";
    uint32 public constant decimals = 18;
    
    /**
     * @dev Give all tokens to msg.sender.
     */
    function HoQuToken(uint _totalSupply) {
        require (_totalSupply > 0);
        totalSupply = balances[msg.sender] = _totalSupply;
    }

    function transfer(address _to, uint _value) whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}

/**
 * @title BaseCrowdSale
 * @title HoQu.io base crowdsale contract for managing a token crowdsale.
 */
contract BaseCrowdsale is Pausable {
    using SafeMath for uint256;

    // all accepted ethers go to this address
    address beneficiaryAddress;

    // all remain tokens after ICO should go to that address
    address public bankAddress;

    // token instance
    HoQuToken public token;

    uint256 public maxTokensAmount;
    uint256 public issuedTokensAmount = 0;
    uint256 public minBuyableAmount;
    uint256 public tokenRate; // amount of HQX per 1 ETH
    
    uint256 endDate;

    bool public isFinished = false;

    /**
    * Event for token purchase logging
    * @param buyer who paid for the tokens
    * @param tokens amount of tokens purchased
    * @param amount ethers paid for purchase
    */
    event TokenBought(address indexed buyer, uint256 tokens, uint256 amount);

    modifier inProgress() {
        require (!isFinished);
        require (issuedTokensAmount < maxTokensAmount);
        require (now <= endDate);
        _;
    }
    
    /**
    * @param _tokenAddress address of a HQX token contract
    * @param _bankAddress address for remain HQX tokens accumulation
    * @param _beneficiaryAddress accepted ETH go to this address
    * @param _tokenRate rate HQX per 1 ETH
    * @param _minBuyableAmount min ETH per each buy action (in ETH)
    * @param _maxTokensAmount ICO HQX capacity (in HQX)
    * @param _endDate the date when ICO will expire
    */
    function BaseCrowdsale(
        address _tokenAddress,
        address _bankAddress,
        address _beneficiaryAddress,
        uint256 _tokenRate,
        uint256 _minBuyableAmount,
        uint256 _maxTokensAmount,
        uint256 _endDate
    ) {
        token = HoQuToken(_tokenAddress);

        bankAddress = _bankAddress;
        beneficiaryAddress = _beneficiaryAddress;

        tokenRate = _tokenRate;
        minBuyableAmount = _minBuyableAmount.mul(1 ether);
        maxTokensAmount = _maxTokensAmount.mul(1 ether);
    
        endDate = _endDate;
    }

    /*
     * @dev Set new HoQu token exchange rate.
     */
    function setTokenRate(uint256 _tokenRate) onlyOwner inProgress {
        require (_tokenRate > 0);
        tokenRate = _tokenRate;
    }

    /*
     * @dev Set new minimum buyable amount in ethers.
     */
    function setMinBuyableAmount(uint256 _minBuyableAmount) onlyOwner inProgress {
        require (_minBuyableAmount > 0);
        minBuyableAmount = _minBuyableAmount.mul(1 ether);
    }

    /**
     * Buy HQX. Check minBuyableAmount and tokenRate.
     * @dev Performs actual token sale process. Sends all ethers to beneficiary.
     */
    function buyTokens() payable inProgress whenNotPaused {
        require (msg.value >= minBuyableAmount);
    
        uint256 payAmount = msg.value;
        uint256 returnAmount = 0;

        // calculate token amount to be transfered to investor
        uint256 tokens = tokenRate.mul(payAmount);
    
        if (issuedTokensAmount + tokens > maxTokensAmount) {
            tokens = maxTokensAmount.sub(issuedTokensAmount);
            payAmount = tokens.div(tokenRate);
            returnAmount = msg.value.sub(payAmount);
        }
    
        issuedTokensAmount = issuedTokensAmount.add(tokens);
        require (issuedTokensAmount <= maxTokensAmount);

        // send token to investor
        token.transfer(msg.sender, tokens);
        // notify listeners on token purchase
        TokenBought(msg.sender, tokens, payAmount);

        // send ethers to special address
        beneficiaryAddress.transfer(payAmount);
    
        if (returnAmount > 0) {
            msg.sender.transfer(returnAmount);
        }
    }

    /**
     * Trigger emergency token pause.
     */
    function pauseToken() onlyOwner returns (bool) {
        require(!token.paused());
        token.pause();
        return true;
    }

    /**
     * Unpause token.
     */
    function unpauseToken() onlyOwner returns (bool) {
        require(token.paused());
        token.unpause();
        return true;
    }
    
    /**
     * Finish ICO.
     */
    function finish() onlyOwner {
        require (issuedTokensAmount >= maxTokensAmount || now > endDate);
        require (!isFinished);
        isFinished = true;
        token.transfer(bankAddress, token.balanceOf(this));
    }
    
    /**
     * Buy HQX. Check minBuyableAmount and tokenRate.
     */
    function() external payable {
        buyTokens();
    }
}

/**
 * @title PrivatePlacement
 * @dev HoQu.io Private Token Placement contract
 */
contract PrivatePlacement is BaseCrowdsale {

    // internal addresses for HoQu tokens allocation
    address public foundersAddress;
    address public supportAddress;
    address public bountyAddress;

    // initial amount distribution values
    uint256 public constant totalSupply = 888888000 ether;
    uint256 public constant initialFoundersAmount = 266666400 ether;
    uint256 public constant initialSupportAmount = 8888880 ether;
    uint256 public constant initialBountyAmount = 35555520 ether;

    // whether initial token allocations was performed or not
    bool allocatedInternalWallets = false;
    
    /**
    * @param _bankAddress address for remain HQX tokens accumulation
    * @param _foundersAddress founders address
    * @param _supportAddress support address
    * @param _bountyAddress bounty address
    * @param _beneficiaryAddress accepted ETH go to this address
    */
    function PrivatePlacement(
        address _bankAddress,
        address _foundersAddress,
        address _supportAddress,
        address _bountyAddress,
        address _beneficiaryAddress
    ) BaseCrowdsale(
        createToken(totalSupply),
        _bankAddress,
        _beneficiaryAddress,
        10000, /* rate HQX per 1 ETH (includes 100% private placement bonus) */
        100, /* min amount in ETH */
        23111088, /* cap in HQX */
        1507939200 /* end 10/14/2017 @ 12:00am (UTC) */
    ) {
        foundersAddress = _foundersAddress;
        supportAddress = _supportAddress;
        bountyAddress = _bountyAddress;
    }

    /*
     * @dev Perform initial token allocation between founders&#39; addresses.
     * Is only executed once after presale contract deployment and is invoked manually.
     */
    function allocateInternalWallets() onlyOwner {
        require (!allocatedInternalWallets);

        allocatedInternalWallets = true;

        token.transfer(foundersAddress, initialFoundersAmount);
        token.transfer(supportAddress, initialSupportAmount);
        token.transfer(bountyAddress, initialBountyAmount);
    }
    
    /*
     * @dev HoQu Token factory.
     */
    function createToken(uint256 _totalSupply) internal returns (HoQuToken) {
        return new HoQuToken(_totalSupply);
    }
}