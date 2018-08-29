pragma solidity 0.4.24;

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
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

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol

/**
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

// File: contracts/WhiteListManager.sol

contract WhiteListManager is Ownable {

    // The list here will be updated by multiple separate WhiteList contracts
    mapping (address => bool) public list;

    function greylist(address addr) public onlyOwner {

        list[addr] = false;
    }

    function greylistMany(address[] addrList) public onlyOwner {

        for (uint256 i = 0; i < addrList.length; i++) {
            
            greylist(addrList[i]);
        }
    }

    function whitelist(address addr) public onlyOwner {

        list[addr] = true;
    }

    function whitelistMany(address[] addrList) public onlyOwner {

        for (uint256 i = 0; i < addrList.length; i++) {
            
            whitelist(addrList[i]);
        }
    }

    function isWhitelisted(address addr) public view returns (bool) {

        return list[addr];
    }
}

// File: contracts/Token.sol

contract MedipediaToken is MintableToken, BurnableToken, DetailedERC20, WhiteListManager{

    // ------------------------------------------------------------------------
    // Every token amount must be multiplied by constant E18 to reflect decimals
    // ------------------------------------------------------------------------
    uint256 constant E18 = 10**18;

    uint256 public constant BUSINESS_DEVELOPMENT_SUPPLY_LIMIT = 520000000 * E18; // 520,000,000 tokens
    uint256 public constant MANAGEMENT_TEAM_SUPPLY_LIMIT = 520000000 * E18; // 520,000,000 tokens will be Locked for 18 Months
    uint256 public constant ADVISORS_SUPPLY_LIMIT = 130000000 * E18; // 130,000,000 tokens will be Locked for 12 Months
    uint256 public constant EARLY_INVESTORS_SUPPLY_LIMIT = 130000000 * E18; // 130,000,000 tokens will be Locked for 12 Months

    // ------------------------------------------------------------------------
    // INITIAL_SUPPLY =  BUSINESS_DEVELOPMENT_SUPPLY_LIMIT + MANAGEMENT_TEAM_SUPPLY_LIMIT +
    //                   ADVISORS_SUPPLY_LIMIT + EARLY_INVESTORS_SUPPLY_LIMIT
    // ------------------------------------------------------------------------
    uint256 public constant INITIAL_SUPPLY = 1300000000 * E18;// 1.3 Billion tokens
    uint256 public constant TOTAL_SUPPLY_LIMIT = 2600000000 * E18;// 2.6 Billion tokens

    uint256 public constant TOKEN_SUPPLY_AIRDROP_LIMIT  = 15000000 * E18; // 15,000,000 tokens
    uint256 public constant TOKEN_SUPPLY_BOUNTY_LIMIT   = 35000000 * E18; // 35,000,000 tokens

    uint256 totalTokensIssuedToAdvisor;
    uint256 totalTokensIssuedToEarlyInvestors;
    uint256 totalTokensIssuedToMgmtTeam;

    
    uint256 releaseTimeToUnlockAdvisorTokens;
    uint256 releaseTimeToUnlockEarlyInvestorTokens;
    uint256 releaseTimeToUnlockManagementTokens;

    bool public isICORunning;
    address public icoContract;

    uint256 public airDropTokenIssuedTotal;
    uint256 public bountyTokenIssuedTotal;
    uint256 public preICOTokenIssuedTotal;

    uint8 private constant AIRDROP_EVENT = 1;
    uint8 private constant BOUNTY_EVENT  = 2;
    uint8 private constant PREICO_EVENT  = 3;
    uint8 private constant ICO_EVENT     = 4;

    event Released(uint256 amount);

    constructor(string _name, string _symbol, uint8 _decimals) 
    DetailedERC20(_name, _symbol, _decimals) 
        public 
    {
        balances[msg.sender] = BUSINESS_DEVELOPMENT_SUPPLY_LIMIT;
        totalSupply_ = INITIAL_SUPPLY;

        totalTokensIssuedToAdvisor = 0;
        totalTokensIssuedToEarlyInvestors = 0;
        totalTokensIssuedToMgmtTeam = 0;

        airDropTokenIssuedTotal = 0;
        bountyTokenIssuedTotal = 0;
        preICOTokenIssuedTotal = 0;

        //Epoch timestamps
        releaseTimeToUnlockAdvisorTokens = 1566345600; // GMT: Wednesday, 21 August 2019 00:00:00
        releaseTimeToUnlockEarlyInvestorTokens = 1566345600; // GMT: Wednesday, 21 August 2019 00:00:00
        releaseTimeToUnlockManagementTokens = 1582243200; // GMT: Friday, 21 February 2020 00:00:00
        
    }

    // ------------------------------------------------------------------------
    // Contract should not accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }

    /**
   * @notice Transfers vested tokens to Advisor.
   * @param _beneficiary ERC20 token which is being vested
   * @param _releaseAmount ERC20 token which is being vested
   */
    function releaseToAdvisor(address _beneficiary, uint256 _releaseAmount) public onlyOwner{
        require(isWhitelisted(_beneficiary), "Beneficiary is not whitelisted");
        require(now >= releaseTimeToUnlockAdvisorTokens, "Release Advisor tokens on or after GMT: Wednesday, 21 August 2019 00:00:00");
        
        uint256 releaseAmount = _releaseAmount.mul(E18);
        require(totalTokensIssuedToAdvisor.add(releaseAmount) <= ADVISORS_SUPPLY_LIMIT);

        balances[_beneficiary] = balances[_beneficiary].add(releaseAmount);

        totalTokensIssuedToAdvisor = totalTokensIssuedToAdvisor.add(releaseAmount);

        emit Released(_releaseAmount);
  }

  /**
   * @notice Transfers vested tokens to Early Investors.
   * @param _beneficiary ERC20 token which is being vested
   * @param _releaseAmount ERC20 token which is being vested
   */
    function releaseToEarlyInvestors(address _beneficiary, uint256 _releaseAmount) public onlyOwner{
        require(isWhitelisted(_beneficiary), "Beneficiary is not whitelisted");
        require(now >= releaseTimeToUnlockEarlyInvestorTokens, "Release Early Investors tokens on or after GMT: Wednesday, 21 August 2019 00:00:00");
        
        uint256 releaseAmount = _releaseAmount.mul(E18);
        require(totalTokensIssuedToEarlyInvestors.add(releaseAmount) <= EARLY_INVESTORS_SUPPLY_LIMIT);

        balances[_beneficiary] = balances[_beneficiary].add(releaseAmount);

        totalTokensIssuedToEarlyInvestors = totalTokensIssuedToEarlyInvestors.add(releaseAmount);

        emit Released(_releaseAmount);
  }


  /**
   * @notice Transfers vested tokens to Management Team.
   * @param _beneficiary ERC20 token which is being vested
   * @param _releaseAmount ERC20 token which is being vested
   */
    function releaseToMgmtTeam(address _beneficiary, uint256 _releaseAmount) public onlyOwner{
        require(isWhitelisted(_beneficiary), "Beneficiary is not whitelisted");
        require(now >= releaseTimeToUnlockManagementTokens, "Release Mgmt Team tokens on or after GMT: Friday, 21 February 2020 00:00:00");
        
        uint256 releaseAmount = _releaseAmount.mul(E18);
        require(totalTokensIssuedToMgmtTeam.add(releaseAmount) <= MANAGEMENT_TEAM_SUPPLY_LIMIT);

        balances[_beneficiary] = balances[_beneficiary].add(releaseAmount);

        totalTokensIssuedToMgmtTeam = totalTokensIssuedToMgmtTeam.add(releaseAmount);

        emit Released(_releaseAmount);
  }

    /**
     * @notice Start ICO.
     * @param start bool value
    */
    function startICO(bool start) public onlyOwner{
        isICORunning = start;
    }

    /**
     * @notice Set the ICO smart contract address.
     * @param _icoContract contract address of the ICO smart contract
    */
    function setIcoContract(address _icoContract) public onlyOwner {
        
        // Allow to set the ICO contract only once
        require(icoContract == address(0));
        require(_icoContract != address(0));

        icoContract = _icoContract;
    }

    /**
     * @notice Reward Airdrop Participant.
     * @param _beneficiary wallet address of the Airdrop Participant
     * @param _amount number of tokens to be rewarded
    */
    function rewardAirdrop(address _beneficiary, uint256 _amount) public onlyOwner {
        require(isWhitelisted(_beneficiary), "Beneficiary is not whitelisted");

        uint256 amount = _amount.mul(E18);
        require (totalSupply_.add(amount) < TOTAL_SUPPLY_LIMIT);

        require(amount <= TOKEN_SUPPLY_AIRDROP_LIMIT);

        require(airDropTokenIssuedTotal < TOKEN_SUPPLY_AIRDROP_LIMIT);

        uint256 remainingTokens = TOKEN_SUPPLY_AIRDROP_LIMIT.sub(airDropTokenIssuedTotal);
        if (amount > remainingTokens) {
            amount = remainingTokens;
        }

        balances[_beneficiary] = balances[_beneficiary].add(amount);

        airDropTokenIssuedTotal = airDropTokenIssuedTotal.add(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);

        emit Transfer(address(AIRDROP_EVENT), _beneficiary, amount);
    }

    /**
     * @notice Reward Bounty Participant.
     * @param _beneficiary wallet address of the Bounty Participant
     * @param _amount number of tokens to be rewarded
    */
    function rewardBounty(address _beneficiary, uint256 _amount) public onlyOwner {
        require(isWhitelisted(_beneficiary), "Beneficiary is not whitelisted");
        uint256 amount = _amount.mul(E18);
        require (totalSupply_.add(amount) < TOTAL_SUPPLY_LIMIT);
        require(amount <= TOKEN_SUPPLY_BOUNTY_LIMIT);

        uint256 remainingTokens = TOKEN_SUPPLY_BOUNTY_LIMIT.sub(bountyTokenIssuedTotal);
        if (amount > remainingTokens) {
            amount = remainingTokens;
        }

        balances[_beneficiary] = balances[_beneficiary].add(amount);

        bountyTokenIssuedTotal = bountyTokenIssuedTotal.add(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);

        emit Transfer(address(BOUNTY_EVENT), _beneficiary, amount);
    }

    /**
     * @notice Pre ICO handler
     * @param _beneficiary wallet address of the Pre ICO Buyer
     * @param _amount number of tokens purchased
    */
    function preICO(address _beneficiary, uint256 _amount) public onlyOwner {
        require(isWhitelisted(_beneficiary), "Buyer is not whitelisted");

        uint256 amount = _amount.mul(E18);

        require (totalSupply_.add(amount) <= TOTAL_SUPPLY_LIMIT);

        uint256 remainingTokens = TOTAL_SUPPLY_LIMIT.sub(totalSupply_);

        require (amount <= remainingTokens);

        preICOTokenIssuedTotal = preICOTokenIssuedTotal.add(amount);

        super.mint(_beneficiary, amount);

        emit Transfer(address(PREICO_EVENT), _beneficiary, amount);
    }

    function preICOMany(address[] addrList, uint256[] amountList) public onlyOwner {

        require(addrList.length == amountList.length);

        for (uint256 i = 0; i < addrList.length; i++) {

            preICO(addrList[i], amountList[i]);
        }
    }

    /**
     * @notice ICO handler
     * @param buyer wallet address of the ICO Buyer
     * @param tokens number of tokens purchased
    */
    function onICO(address buyer, uint256 tokens) public onlyOwner returns (bool success) {
        require(isICORunning);
        require(isWhitelisted(buyer), "Buyer is not whitelisted");
        require (icoContract != address(0));
        require (msg.sender == icoContract);
        require (tokens > 0);
        require (buyer != address(0));

        require (totalSupply_.add(tokens) <= TOTAL_SUPPLY_LIMIT);

        super.mint(buyer, tokens);
        emit Transfer(address(ICO_EVENT), buyer, tokens);

        return true;
    }
}