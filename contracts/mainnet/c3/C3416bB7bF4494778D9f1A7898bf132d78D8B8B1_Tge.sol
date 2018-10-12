pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Whitelist is Ownable {
    mapping(address => bool) whitelist;
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function add(address _address) public onlyOwner {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function remove(address _address) public onlyOwner {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
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
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}






/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
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

  mapping (address => mapping (address => uint256)) internal allowed;


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
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
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
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


contract CrowdfundableToken is MintableToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public cap;

    function CrowdfundableToken(uint256 _cap, string _name, string _symbol, uint8 _decimals) public {
        require(_cap > 0);
        require(bytes(_name).length > 0);
        require(bytes(_symbol).length > 0);
        cap = _cap;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    // override
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require(totalSupply_.add(_amount) <= cap);
        return super.mint(_to, _amount);
    }

    // override
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(mintingFinished == true);
        return super.transfer(_to, _value);
    }

    // override
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(mintingFinished == true);
        return super.transferFrom(_from, _to, _value);
    }

    function burn(uint amount) public {
        totalSupply_ = totalSupply_.sub(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
    }
}

contract Minter is Ownable {
    using SafeMath for uint;

    /* --- EVENTS --- */

    event Minted(address indexed account, uint etherAmount, uint tokenAmount);
    event Reserved(uint etherAmount);
    event MintedReserved(address indexed account, uint etherAmount, uint tokenAmount);
    event Unreserved(uint etherAmount);

    /* --- FIELDS --- */

    CrowdfundableToken public token;
    uint public saleEtherCap;
    uint public confirmedSaleEther;
    uint public reservedSaleEther;

    /* --- MODIFIERS --- */

    modifier onlyInUpdatedState() {
        updateState();
        _;
    }

    modifier upToSaleEtherCap(uint additionalEtherAmount) {
        uint totalEtherAmount = confirmedSaleEther.add(reservedSaleEther).add(additionalEtherAmount);
        require(totalEtherAmount <= saleEtherCap);
        _;
    }

    modifier onlyApprovedMinter() {
        require(canMint(msg.sender));
        _;
    }

    modifier atLeastMinimumAmount(uint etherAmount) {
        require(etherAmount >= getMinimumContribution());
        _;
    }

    modifier onlyValidAddress(address account) {
        require(account != 0x0);
        _;
    }

    /* --- CONSTRUCTOR --- */

    constructor(CrowdfundableToken _token, uint _saleEtherCap) public onlyValidAddress(address(_token)) {
        require(_saleEtherCap > 0);

        token = _token;
        saleEtherCap = _saleEtherCap;
    }

    /* --- PUBLIC / EXTERNAL METHODS --- */

    function transferTokenOwnership() external onlyOwner {
        token.transferOwnership(owner);
    }

    function reserve(uint etherAmount) external
        onlyInUpdatedState
        onlyApprovedMinter
        upToSaleEtherCap(etherAmount)
        atLeastMinimumAmount(etherAmount)
    {
        reservedSaleEther = reservedSaleEther.add(etherAmount);
        updateState();
        emit Reserved(etherAmount);
    }

    function mintReserved(address account, uint etherAmount, uint tokenAmount) external
        onlyInUpdatedState
        onlyApprovedMinter
    {
        reservedSaleEther = reservedSaleEther.sub(etherAmount);
        confirmedSaleEther = confirmedSaleEther.add(etherAmount);
        require(token.mint(account, tokenAmount));
        updateState();
        emit MintedReserved(account, etherAmount, tokenAmount);
    }

    function unreserve(uint etherAmount) public
        onlyInUpdatedState
        onlyApprovedMinter
    {
        reservedSaleEther = reservedSaleEther.sub(etherAmount);
        updateState();
        emit Unreserved(etherAmount);
    }

    function mint(address account, uint etherAmount, uint tokenAmount) public
        onlyInUpdatedState
        onlyApprovedMinter
        upToSaleEtherCap(etherAmount)
    {
        confirmedSaleEther = confirmedSaleEther.add(etherAmount);
        require(token.mint(account, tokenAmount));
        updateState();
        emit Minted(account, etherAmount, tokenAmount);
    }

    // abstract
    function getMinimumContribution() public view returns(uint);

    // abstract
    function updateState() public;

    // abstract
    function canMint(address sender) public view returns(bool);

    // abstract
    function getTokensForEther(uint etherAmount) public view returns(uint);
}

contract ExternalMinter {
    Minter public minter;
}

contract Tge is Minter {
    using SafeMath for uint;

    /* --- CONSTANTS --- */

    uint constant public MIMIMUM_CONTRIBUTION_AMOUNT_PREICO = 3 ether;
    uint constant public MIMIMUM_CONTRIBUTION_AMOUNT_ICO = 1 ether / 5;
    
    uint constant public PRICE_MULTIPLIER_PREICO1 = 1443000;
    uint constant public PRICE_MULTIPLIER_PREICO2 = 1415000;

    uint constant public PRICE_MULTIPLIER_ICO1 = 1332000;
    uint constant public PRICE_MULTIPLIER_ICO2 = 1304000;
    uint constant public PRICE_MULTIPLIER_ICO3 = 1248000;
    uint constant public PRICE_MULTIPLIER_ICO4 = 1221000;
    uint constant public PRICE_MULTIPLIER_ICO5 = 1165000;
    uint constant public PRICE_MULTIPLIER_ICO6 = 1110000;
    uint constant public PRICE_DIVIDER = 1000;

    /* --- EVENTS --- */

    event StateChanged(uint from, uint to);
    event PrivateIcoInitialized(uint _cap, uint _tokensForEther, uint _startTime, uint _endTime, uint _minimumContribution);
    event PrivateIcoFinalized();

    /* --- FIELDS --- */

    // minters
    address public crowdsale;
    address public deferredKyc;
    address public referralManager;
    address public allocator;
    address public airdropper;

    // state
    enum State {Presale, Preico1, Preico2, Break, Ico1, Ico2, Ico3, Ico4, Ico5, Ico6, FinishingIco, Allocating, Airdropping, Finished}
    State public currentState = State.Presale;
    mapping(uint => uint) public startTimes;
    mapping(uint => uint) public etherCaps;

    // private ico
    bool public privateIcoFinalized = true;
    uint public privateIcoCap = 0;
    uint public privateIcoTokensForEther = 0;
    uint public privateIcoStartTime = 0;
    uint public privateIcoEndTime = 0;
    uint public privateIcoMinimumContribution = 0;

    /* --- MODIFIERS --- */

    modifier onlyInState(State _state) {
        require(_state == currentState);
        _;
    }

    modifier onlyProperExternalMinters(address minter1, address minter2, address minter3, address minter4, address minter5) {
        require(ExternalMinter(minter1).minter() == address(this));
        require(ExternalMinter(minter2).minter() == address(this));
        require(ExternalMinter(minter3).minter() == address(this));
        require(ExternalMinter(minter4).minter() == address(this));
        require(ExternalMinter(minter5).minter() == address(this));
        _;
    }

    /* --- CONSTRUCTOR / INITIALIZATION --- */

    constructor(
        CrowdfundableToken _token,
        uint _saleEtherCap
    ) public Minter(_token, _saleEtherCap) {
        require(keccak256(_token.symbol()) == keccak256("ALL"));
    }

    // initialize states start times and caps
    function setupStates(uint saleStart, uint singleStateEtherCap, uint[] stateLengths) internal {
        require(!isPrivateIcoActive());

        startTimes[uint(State.Preico1)] = saleStart;
        setStateLength(State.Preico1, stateLengths[0]);
        setStateLength(State.Preico2, stateLengths[1]);
        setStateLength(State.Break, stateLengths[2]);
        setStateLength(State.Ico1, stateLengths[3]);
        setStateLength(State.Ico2, stateLengths[4]);
        setStateLength(State.Ico3, stateLengths[5]);
        setStateLength(State.Ico4, stateLengths[6]);
        setStateLength(State.Ico5, stateLengths[7]);
        setStateLength(State.Ico6, stateLengths[8]);

        // the total sale ether cap is distributed evenly over all selling states
        // the cap from previous states is accumulated in consequent states
        // adding confirmed sale ether from private ico
        etherCaps[uint(State.Preico1)] = singleStateEtherCap;
        etherCaps[uint(State.Preico2)] = singleStateEtherCap.mul(2);
        etherCaps[uint(State.Ico1)] = singleStateEtherCap.mul(3);
        etherCaps[uint(State.Ico2)] = singleStateEtherCap.mul(4);
        etherCaps[uint(State.Ico3)] = singleStateEtherCap.mul(5);
        etherCaps[uint(State.Ico4)] = singleStateEtherCap.mul(6);
        etherCaps[uint(State.Ico5)] = singleStateEtherCap.mul(7);
        etherCaps[uint(State.Ico6)] = singleStateEtherCap.mul(8);
    }

    function setup(
        address _crowdsale,
        address _deferredKyc,
        address _referralManager,
        address _allocator,
        address _airdropper,
        uint saleStartTime,
        uint singleStateEtherCap,
        uint[] stateLengths
    )
    public
    onlyOwner
    onlyInState(State.Presale)
    onlyProperExternalMinters(_crowdsale, _deferredKyc, _referralManager, _allocator, _airdropper)
    {
        require(stateLengths.length == 9); // preico 1-2, break, ico 1-6
        require(saleStartTime >= now);
        require(singleStateEtherCap > 0);
        require(singleStateEtherCap.mul(8) <= saleEtherCap);
        crowdsale = _crowdsale;
        deferredKyc = _deferredKyc;
        referralManager = _referralManager;
        allocator = _allocator;
        airdropper = _airdropper;
        setupStates(saleStartTime, singleStateEtherCap, stateLengths);
    }

    /* --- PUBLIC / EXTERNAL METHODS --- */

    function moveState(uint from, uint to) external onlyInUpdatedState onlyOwner {
        require(uint(currentState) == from);
        advanceStateIfNewer(State(to));
    }

    // override
    function transferTokenOwnership() external onlyInUpdatedState onlyOwner {
        require(currentState == State.Finished);
        token.transferOwnership(owner);
    }

    // override
    function getTokensForEther(uint etherAmount) public view returns(uint) {
        uint tokenAmount = 0;
        if (isPrivateIcoActive()) tokenAmount = etherAmount.mul(privateIcoTokensForEther).div(PRICE_DIVIDER);
        else if (currentState == State.Preico1) tokenAmount = etherAmount.mul(PRICE_MULTIPLIER_PREICO1).div(PRICE_DIVIDER);
        else if (currentState == State.Preico2) tokenAmount = etherAmount.mul(PRICE_MULTIPLIER_PREICO2).div(PRICE_DIVIDER);
        else if (currentState == State.Ico1) tokenAmount = etherAmount.mul(PRICE_MULTIPLIER_ICO1).div(PRICE_DIVIDER);
        else if (currentState == State.Ico2) tokenAmount = etherAmount.mul(PRICE_MULTIPLIER_ICO2).div(PRICE_DIVIDER);
        else if (currentState == State.Ico3) tokenAmount = etherAmount.mul(PRICE_MULTIPLIER_ICO3).div(PRICE_DIVIDER);
        else if (currentState == State.Ico4) tokenAmount = etherAmount.mul(PRICE_MULTIPLIER_ICO4).div(PRICE_DIVIDER);
        else if (currentState == State.Ico5) tokenAmount = etherAmount.mul(PRICE_MULTIPLIER_ICO5).div(PRICE_DIVIDER);
        else if (currentState == State.Ico6) tokenAmount = etherAmount.mul(PRICE_MULTIPLIER_ICO6).div(PRICE_DIVIDER);

        return tokenAmount;
    }

    function isSellingState() public view returns(bool) {
        if (currentState == State.Presale) return isPrivateIcoActive();
        return (
            uint(currentState) >= uint(State.Preico1) &&
            uint(currentState) <= uint(State.Ico6) &&
            uint(currentState) != uint(State.Break)
        );
    }

    function isPrivateIcoActive() public view returns(bool) {
        return now >= privateIcoStartTime && now < privateIcoEndTime;
    }

    function initPrivateIco(uint _cap, uint _tokensForEther, uint _startTime, uint _endTime, uint _minimumContribution) external onlyOwner {
        require(_startTime > privateIcoEndTime); // should start after previous private ico
        require(now >= privateIcoEndTime); // previous private ico should be finished
        require(privateIcoFinalized); // previous private ico should be finalized
        require(_tokensForEther > 0);
        require(_endTime > _startTime);
        require(_endTime < startTimes[uint(State.Preico1)]);

        privateIcoCap = _cap;
        privateIcoTokensForEther = _tokensForEther;
        privateIcoStartTime = _startTime;
        privateIcoEndTime = _endTime;
        privateIcoMinimumContribution = _minimumContribution;
        privateIcoFinalized = false;
        emit PrivateIcoInitialized(_cap, _tokensForEther, _startTime, _endTime, _minimumContribution);
    }

    function finalizePrivateIco() external onlyOwner {
        require(!isPrivateIcoActive());
        require(now >= privateIcoEndTime); // previous private ico should be finished
        require(!privateIcoFinalized);
        require(reservedSaleEther == 0); // kyc needs to be finished

        privateIcoFinalized = true;
        confirmedSaleEther = 0;
        emit PrivateIcoFinalized();
    }

    /* --- INTERNAL METHODS --- */

    // override
    function getMinimumContribution() public view returns(uint) {
        if (currentState == State.Preico1 || currentState == State.Preico2) {
            return MIMIMUM_CONTRIBUTION_AMOUNT_PREICO;
        }
        if (uint(currentState) >= uint(State.Ico1) && uint(currentState) <= uint(State.Ico6)) {
            return MIMIMUM_CONTRIBUTION_AMOUNT_ICO;
        }
        if (isPrivateIcoActive()) {
            return privateIcoMinimumContribution;
        }
        return 0;
    }

    // override
    function canMint(address account) public view returns(bool) {
        if (currentState == State.Presale) {
            // external sales and private ico
            return account == crowdsale || account == deferredKyc;
        }
        else if (isSellingState()) {
            // crowdsale: external sales
            // deferredKyc: adding and approving kyc
            // referralManager: referral fees
            return account == crowdsale || account == deferredKyc || account == referralManager;
        }
        else if (currentState == State.Break || currentState == State.FinishingIco) {
            // crowdsale: external sales
            // deferredKyc: approving kyc
            // referralManager: referral fees
            return account == crowdsale || account == deferredKyc || account == referralManager;
        }
        else if (currentState == State.Allocating) {
            // Community and Bounty allocations
            // Advisors, Developers, Ambassadors and Partners allocations
            // Customer Rewards allocations
            // Team allocations
            return account == allocator;
        }
        else if (currentState == State.Airdropping) {
            // airdropping for all token holders
            return account == airdropper;
        }
        return false;
    }

    // override
    function updateState() public {
        updateStateBasedOnTime();
        updateStateBasedOnContributions();
    }

    function updateStateBasedOnTime() internal {
        // move to the next state, if the current one has finished
        if (now >= startTimes[uint(State.FinishingIco)]) advanceStateIfNewer(State.FinishingIco);
        else if (now >= startTimes[uint(State.Ico6)]) advanceStateIfNewer(State.Ico6);
        else if (now >= startTimes[uint(State.Ico5)]) advanceStateIfNewer(State.Ico5);
        else if (now >= startTimes[uint(State.Ico4)]) advanceStateIfNewer(State.Ico4);
        else if (now >= startTimes[uint(State.Ico3)]) advanceStateIfNewer(State.Ico3);
        else if (now >= startTimes[uint(State.Ico2)]) advanceStateIfNewer(State.Ico2);
        else if (now >= startTimes[uint(State.Ico1)]) advanceStateIfNewer(State.Ico1);
        else if (now >= startTimes[uint(State.Break)]) advanceStateIfNewer(State.Break);
        else if (now >= startTimes[uint(State.Preico2)]) advanceStateIfNewer(State.Preico2);
        else if (now >= startTimes[uint(State.Preico1)]) advanceStateIfNewer(State.Preico1);
    }

    function updateStateBasedOnContributions() internal {
        // move to the next state, if the current one&#39;s cap has been reached
        uint totalEtherContributions = confirmedSaleEther.add(reservedSaleEther);
        if(isPrivateIcoActive()) {
            // if private ico cap exceeded, revert transaction
            require(totalEtherContributions <= privateIcoCap);
            return;
        }
        
        if (!isSellingState()) {
            return;
        }
        
        else if (int(currentState) < int(State.Break)) {
            // preico
            if (totalEtherContributions >= etherCaps[uint(State.Preico2)]) advanceStateIfNewer(State.Break);
            else if (totalEtherContributions >= etherCaps[uint(State.Preico1)]) advanceStateIfNewer(State.Preico2);
        }
        else {
            // ico
            if (totalEtherContributions >= etherCaps[uint(State.Ico6)]) advanceStateIfNewer(State.FinishingIco);
            else if (totalEtherContributions >= etherCaps[uint(State.Ico5)]) advanceStateIfNewer(State.Ico6);
            else if (totalEtherContributions >= etherCaps[uint(State.Ico4)]) advanceStateIfNewer(State.Ico5);
            else if (totalEtherContributions >= etherCaps[uint(State.Ico3)]) advanceStateIfNewer(State.Ico4);
            else if (totalEtherContributions >= etherCaps[uint(State.Ico2)]) advanceStateIfNewer(State.Ico3);
            else if (totalEtherContributions >= etherCaps[uint(State.Ico1)]) advanceStateIfNewer(State.Ico2);
        }
    }

    function advanceStateIfNewer(State newState) internal {
        if (uint(newState) > uint(currentState)) {
            emit StateChanged(uint(currentState), uint(newState));
            currentState = newState;
        }
    }

    function setStateLength(State state, uint length) internal {
        // state length is determined by next state&#39;s start time
        startTimes[uint(state)+1] = startTimes[uint(state)].add(length);
    }

    function isInitialized() public view returns(bool) {
        return crowdsale != 0x0 && referralManager != 0x0 && allocator != 0x0 && airdropper != 0x0 && deferredKyc != 0x0;
    }
}