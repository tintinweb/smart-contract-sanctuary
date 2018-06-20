pragma solidity ^0.4.18;

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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract UserRegistryInterface {
  event AddAddress(address indexed who);
  event AddIdentity(address indexed who);

  function knownAddress(address _who) public constant returns(bool);
  function hasIdentity(address _who) public constant returns(bool);
  function systemAddresses(address _to, address _from) public constant returns(bool);
}

contract MultiOwners {

    event AccessGrant(address indexed owner);
    event AccessRevoke(address indexed owner);
    
    mapping(address => bool) owners;
    address public publisher;

    function MultiOwners() public {
        owners[msg.sender] = true;
        publisher = msg.sender;
    }

    modifier onlyOwner() { 
        require(owners[msg.sender] == true);
        _; 
    }

    function isOwner() public constant returns (bool) {
        return owners[msg.sender] ? true : false;
    }

    function checkOwner(address maybe_owner) public constant returns (bool) {
        return owners[maybe_owner] ? true : false;
    }

    function grant(address _owner) onlyOwner public {
        owners[_owner] = true;
        AccessGrant(_owner);
    }

    function revoke(address _owner) onlyOwner public {
        require(_owner != publisher);
        require(msg.sender != _owner);

        owners[_owner] = false;
        AccessRevoke(_owner);
    }
}

contract TokenRecipient {
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; 
}

contract TokenInterface is ERC20 {
  string public name;
  string public symbol;
  uint public decimals;
}

contract MintableTokenInterface is TokenInterface {
  address public owner;
  function mint(address beneficiary, uint amount) public returns(bool);
  function transferOwnership(address nextOwner) public;
}

/**
 * Complex crowdsale with huge posibilities
 * Core features:
 * - Whitelisting
 *  - Min\max invest amounts
 * - Only known users
 * - Buy with allowed tokens
 *  - Oraclize based pairs (ETH to TOKEN)
 * - Revert\refund
 * - Personal bonuses
 * - Amount bonuses
 * - Total supply bonuses
 * - Early birds bonuses
 * - Extra distribution (team, foundation and also)
 * - Soft and hard caps
 * - Finalization logics
**/
contract Crowdsale is MultiOwners, TokenRecipient {
  using SafeMath for uint;

  //  ██████╗ ██████╗ ███╗   ██╗███████╗████████╗███████╗
  // ██╔════╝██╔═══██╗████╗  ██║██╔════╝╚══██╔══╝██╔════╝
  // ██║     ██║   ██║██╔██╗ ██║███████╗   ██║   ███████╗
  // ██║     ██║   ██║██║╚██╗██║╚════██║   ██║   ╚════██║
  // ╚██████╗╚██████╔╝██║ ╚████║███████║   ██║   ███████║
  //  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚══════╝
  uint public constant VERSION = 0x1;
  enum State {
    Setup,          // Non active yet (require to be setuped)
    Active,         // Crowdsale in a live
    Claim,          // Claim funds by owner
    Refund,         // Unsucceseful crowdsale (refund ether)
    History         // Close and store only historical fact of existence
  }


  struct PersonalBonusRecord {
    uint bonus;
    address refererAddress;
    uint refererBonus;
  }

  struct WhitelistRecord {
    bool allow;
    uint min;
    uint max;
  }


  //  ██████╗ ██████╗ ███╗   ██╗███████╗██╗███╗   ██╗ ██████╗ 
  // ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║████╗  ██║██╔════╝ 
  // ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██╔██╗ ██║██║  ███╗
  // ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║╚██╗██║██║   ██║
  // ╚██████╗╚██████╔╝██║ ╚████║██║     ██║██║ ╚████║╚██████╔╝
  //  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝╚═╝  ╚═══╝ ╚═════╝ 
                                                           
  bool public isWhitelisted;            // Should be whitelisted to buy tokens
  bool public isKnownOnly;              // Should be known user to buy tokens
  bool public isAmountBonus;            // Enable amount bonuses in crowdsale?
  bool public isEarlyBonus;             // Enable early bird bonus in crowdsale?
  bool public isTokenExchange;          // Allow to buy tokens for another tokens?
  bool public isAllowToIssue;           // Allow to issue tokens with tx hash (ex bitcoin)
  bool public isDisableEther;           // Disable purchase with the Ether
  bool public isExtraDistribution;      // Should distribute extra tokens to special contract?
  bool public isTransferShipment;       // Will ship token via minting?
  bool public isCappedInEther;          // Should be capped in Ether 
  bool public isPersonalBonuses;        // Should check personal beneficiary bonus?
  bool public isAllowClaimBeforeFinalization;
                                        // Should allow to claim funds before finalization?
  bool public isMinimumValue;           // Validate minimum amount to purchase
  bool public isMinimumInEther;         // Is minimum amount setuped in Ether or Tokens?

  uint public minimumPurchaseValue;     // How less buyer could to purchase

  // List of allowed beneficiaries
  mapping (address => WhitelistRecord) public whitelist;

  // Known users registry (required to known rules)
  UserRegistryInterface public userRegistry;

  mapping (uint => uint) public amountBonuses; // Amount bonuses
  uint[] public amountSlices;                  // Key is min amount of buy
  uint public amountSlicesCount;               // 10000 - 100.00% bonus over base pricetotaly free
                                               //  5000 - 50.00% bonus
                                               //     0 - no bonus at all
  mapping (uint => uint) public timeBonuses;   // Time bonuses
  uint[] public timeSlices;                    // Same as amount but key is seconds after start
  uint public timeSlicesCount;

  mapping (address => PersonalBonusRecord) public personalBonuses; 
                                        // personal bonuses
  MintableTokenInterface public token;  // The token being sold
  uint public tokenDecimals;            // Token decimals

  mapping (address => TokenInterface) public allowedTokens;
                                        // allowed tokens list
  mapping (address => uint) public tokensValues;
                                        // TOKEN to ETH conversion rate (oraclized)
  uint public startTime;                // start and end timestamps where 
  uint public endTime;                  // investments are allowed (both inclusive)
  address public wallet;                // address where funds are collected
  uint public price;                    // how many token (1 * 10 ** decimals) a buyer gets per wei
  uint public hardCap;
  uint public softCap;

  address public extraTokensHolder;     // address to mint/transfer extra tokens (0 – 0%, 1000 - 100.0%)
  uint public extraDistributionPart;    // % of extra distribution

  // ███████╗████████╗ █████╗ ████████╗███████╗
  // ██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██╔════╝
  // ███████╗   ██║   ███████║   ██║   █████╗  
  // ╚════██║   ██║   ██╔══██║   ██║   ██╔══╝  
  // ███████║   ██║   ██║  ██║   ██║   ███████╗
  // ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝   ╚══════╝
  // amount of raised money in wei
  uint public weiRaised;
  // Current crowdsale state
  State public state;
  // Temporal balances to pull tokens after token sale
  // requires to ship required balance to smart contract
  mapping (address => uint) public beneficiaryInvest;
  uint public soldTokens;

  mapping (address => uint) public weiDeposit;
  mapping (address => mapping(address => uint)) public altDeposit;

  modifier inState(State _target) {
    require(state == _target);
    _;
  }

  // ███████╗██╗   ██╗███████╗███╗   ██╗████████╗███████╗
  // ██╔════╝██║   ██║██╔════╝████╗  ██║╚══██╔══╝██╔════╝
  // █████╗  ██║   ██║█████╗  ██╔██╗ ██║   ██║   ███████╗
  // ██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║╚██╗██║   ██║   ╚════██║
  // ███████╗ ╚████╔╝ ███████╗██║ ╚████║   ██║   ███████║
  // ╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝
  
  event EthBuy(
    address indexed purchaser, 
    address indexed beneficiary, 
    uint value, 
    uint amount);
  event HashBuy(
    address indexed beneficiary, 
    uint value, 
    uint amount, 
    uint timestamp, 
    bytes32 indexed bitcoinHash);
  event AltBuy(
    address indexed beneficiary, 
    address indexed allowedToken, 
    uint allowedTokenValue, 
    uint ethValue, 
    uint shipAmount);
    
  event ShipTokens(address indexed owner, uint amount);

  event Sanetize();
  event Finalize();

  event Whitelisted(address indexed beneficiary, uint min, uint max);
  event PersonalBonus(address indexed beneficiary, address indexed referer, uint bonus, uint refererBonus);
  event FundsClaimed(address indexed owner, uint amount);


  // ███████╗███████╗████████╗██╗   ██╗██████╗     ███╗   ███╗███████╗████████╗██╗  ██╗ ██████╗ ██████╗ ███████╗
  // ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗    ████╗ ████║██╔════╝╚══██╔══╝██║  ██║██╔═══██╗██╔══██╗██╔════╝
  // ███████╗█████╗     ██║   ██║   ██║██████╔╝    ██╔████╔██║█████╗     ██║   ███████║██║   ██║██║  ██║███████╗
  // ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝     ██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║   ██║██║  ██║╚════██║
  // ███████║███████╗   ██║   ╚██████╔╝██║         ██║ ╚═╝ ██║███████╗   ██║   ██║  ██║╚██████╔╝██████╔╝███████║
  // ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝         ╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝

  function setFlags(
    // Should be whitelisted to buy tokens
    bool _isWhitelisted,
    // Should be known user to buy tokens
    bool _isKnownOnly,
    // Enable amount bonuses in crowdsale?
    bool _isAmountBonus,
    // Enable early bird bonus in crowdsale?
    bool _isEarlyBonus,
    // Allow to buy tokens for another tokens?
    bool _isTokenExchange,
    // Allow to issue tokens with tx hash (ex bitcoin)
    bool _isAllowToIssue,
    // Should reject purchases with Ether?
    bool _isDisableEther,
    // Should mint extra tokens for future distribution?
    bool _isExtraDistribution,
    // Will ship token via minting? 
    bool _isTransferShipment,
    // Should be capped in ether
    bool _isCappedInEther,
    // Should beneficiaries pull their tokens? 
    bool _isPersonalBonuses,
    // Should allow to claim funds before finalization?
    bool _isAllowClaimBeforeFinalization)
    inState(State.Setup) onlyOwner public 
  {
    isWhitelisted = _isWhitelisted;
    isKnownOnly = _isKnownOnly;
    isAmountBonus = _isAmountBonus;
    isEarlyBonus = _isEarlyBonus;
    isTokenExchange = _isTokenExchange;
    isAllowToIssue = _isAllowToIssue;
    isDisableEther = _isDisableEther;
    isExtraDistribution = _isExtraDistribution;
    isTransferShipment = _isTransferShipment;
    isCappedInEther = _isCappedInEther;
    isPersonalBonuses = _isPersonalBonuses;
    isAllowClaimBeforeFinalization = _isAllowClaimBeforeFinalization;
  }

  // ! Could be changed in process of sale (since 02.2018)
  function setMinimum(uint _amount, bool _inToken) 
    onlyOwner public
  {
    if (_amount == 0) {
      isMinimumValue = false;
      minimumPurchaseValue = 0;
    } else {
      isMinimumValue = true;
      isMinimumInEther = !_inToken;
      minimumPurchaseValue = _amount;
    }
  }

  function setPrice(uint _price)
    inState(State.Setup) onlyOwner public
  {
    require(_price > 0);
    price = _price;
  }

  function setSoftHardCaps(uint _softCap, uint _hardCap)
    inState(State.Setup) onlyOwner public
  {
    hardCap = _hardCap;
    softCap = _softCap;
  }

  function setTime(uint _start, uint _end)
    inState(State.Setup) onlyOwner public 
  {
    require(_start < _end);
    require(_end > block.timestamp);
    startTime = _start;
    endTime = _end;
  }

  function setToken(address _tokenAddress) 
    inState(State.Setup) onlyOwner public
  {
    token = MintableTokenInterface(_tokenAddress);
    tokenDecimals = token.decimals();
  }

  function setWallet(address _wallet) 
    inState(State.Setup) onlyOwner public 
  {
    require(_wallet != address(0));
    wallet = _wallet;
  }
  
  function setRegistry(address _registry) 
    inState(State.Setup) onlyOwner public 
  {
    require(_registry != address(0));
    userRegistry = UserRegistryInterface(_registry);
  }

  function setExtraDistribution(address _holder, uint _extraPart) 
    inState(State.Setup) onlyOwner public
  {
    require(_holder != address(0));
    extraTokensHolder = _holder;
    extraDistributionPart = _extraPart;
  }

  function setAmountBonuses(uint[] _amountSlices, uint[] _bonuses) 
    inState(State.Setup) onlyOwner public 
  {
    require(_amountSlices.length > 1);
    require(_bonuses.length == _amountSlices.length);
    uint lastSlice = 0;
    for (uint index = 0; index < _amountSlices.length; index++) {
      require(_amountSlices[index] > lastSlice);
      lastSlice = _amountSlices[index];
      amountSlices.push(lastSlice);
      amountBonuses[lastSlice] = _bonuses[index];
    }

    amountSlicesCount = amountSlices.length;
  }

  function setTimeBonuses(uint[] _timeSlices, uint[] _bonuses) 
    // ! Not need to check state since changes at 02.2018
    // inState(State.Setup)
    onlyOwner 
    public 
  {
    // Only once in life time
    // ! Time bonuses is changable after 02.2018
    // require(timeSlicesCount == 0);
    require(_timeSlices.length > 0);
    require(_bonuses.length == _timeSlices.length);
    uint lastSlice = 0;
    uint lastBonus = 10000;
    if (timeSlicesCount > 0) {
      // ! Since time bonuses is changable we should take latest first
      lastSlice = timeSlices[timeSlicesCount - 1];
      lastBonus = timeBonuses[lastSlice];
    }

    for (uint index = 0; index < _timeSlices.length; index++) {
      require(_timeSlices[index] > lastSlice);

      // ! Add check for next bonus is equal or less than previous
      require(_bonuses[index] <= lastBonus);

      // ? Should we check bonus in a future
      lastSlice = _timeSlices[index];
      timeSlices.push(lastSlice);
      timeBonuses[lastSlice] = _bonuses[index];
    }
    timeSlicesCount = timeSlices.length;
  }
  
  function setTokenExcange(address _token, uint _value)
    inState(State.Setup) onlyOwner public
  {
    allowedTokens[_token] = TokenInterface(_token);
    updateTokenValue(_token, _value); 
  }

  function saneIt() 
    inState(State.Setup) onlyOwner public 
  {
    require(startTime < endTime);
    require(endTime > now);

    require(price > 0);

    require(wallet != address(0));
    require(token != address(0));

    if (isKnownOnly) {
      require(userRegistry != address(0));
    }

    if (isAmountBonus) {
      require(amountSlicesCount > 0);
    }

    if (isExtraDistribution) {
      require(extraTokensHolder != address(0));
    }

    if (isTransferShipment) {
      require(token.balanceOf(address(this)) >= hardCap);
    } else {
      require(token.owner() == address(this));
    }

    state = State.Active;
  }

  function finalizeIt(address _futureOwner) inState(State.Active) onlyOwner public {
    require(ended());

    token.transferOwnership(_futureOwner);

    if (success()) {
      state = State.Claim;
    } else {
      state = State.Refund;
    }
  }

  function historyIt() inState(State.Claim) onlyOwner public {
    require(address(this).balance == 0);
    state = State.History;
  }

  // ███████╗██╗  ██╗███████╗ ██████╗██╗   ██╗████████╗███████╗
  // ██╔════╝╚██╗██╔╝██╔════╝██╔════╝██║   ██║╚══██╔══╝██╔════╝
  // █████╗   ╚███╔╝ █████╗  ██║     ██║   ██║   ██║   █████╗  
  // ██╔══╝   ██╔██╗ ██╔══╝  ██║     ██║   ██║   ██║   ██╔══╝  
  // ███████╗██╔╝ ██╗███████╗╚██████╗╚██████╔╝   ██║   ███████╗
  // ╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝    ╚═╝   ╚══════╝

  function calculateEthAmount(
    address _beneficiary,
    uint _weiAmount,
    uint _time,
    uint _totalSupply
  ) public constant returns(
    uint calculatedTotal, 
    uint calculatedBeneficiary, 
    uint calculatedExtra, 
    uint calculatedreferer, 
    address refererAddress) 
  {
    _totalSupply;
    uint bonus = 0;
    
    if (isAmountBonus) {
      bonus = bonus.add(calculateAmountBonus(_weiAmount));
    }

    if (isEarlyBonus) {
      bonus = bonus.add(calculateTimeBonus(_time.sub(startTime)));
    }

    if (isPersonalBonuses && personalBonuses[_beneficiary].bonus > 0) {
      bonus = bonus.add(personalBonuses[_beneficiary].bonus);
    }

    calculatedBeneficiary = _weiAmount.mul(10 ** tokenDecimals).div(price);
    if (bonus > 0) {
      calculatedBeneficiary = calculatedBeneficiary.add(calculatedBeneficiary.mul(bonus).div(10000));
    }

    if (isExtraDistribution) {
      calculatedExtra = calculatedBeneficiary.mul(extraDistributionPart).div(10000);
    }

    if (isPersonalBonuses && 
        personalBonuses[_beneficiary].refererAddress != address(0) && 
        personalBonuses[_beneficiary].refererBonus > 0) 
    {
      calculatedreferer = calculatedBeneficiary.mul(personalBonuses[_beneficiary].refererBonus).div(10000);
      refererAddress = personalBonuses[_beneficiary].refererAddress;
    }

    calculatedTotal = calculatedBeneficiary.add(calculatedExtra).add(calculatedreferer);
  }

  function calculateAmountBonus(uint _changeAmount) public constant returns(uint) {
    uint bonus = 0;
    for (uint index = 0; index < amountSlices.length; index++) {
      if(amountSlices[index] > _changeAmount) {
        break;
      }

      bonus = amountBonuses[amountSlices[index]];
    }
    return bonus;
  }

  function calculateTimeBonus(uint _at) public constant returns(uint) {
    uint bonus = 0;
    for (uint index = timeSlices.length; index > 0; index--) {
      if(timeSlices[index - 1] < _at) {
        break;
      }
      bonus = timeBonuses[timeSlices[index - 1]];
    }

    return bonus;
  }

  function validPurchase(
    address _beneficiary, 
    uint _weiAmount, 
    uint _tokenAmount,
    uint _extraAmount,
    uint _totalAmount,
    uint _time) 
  public constant returns(bool) 
  {
    _tokenAmount;
    _extraAmount;

    // ! Check min purchase value (since 02.2018)
    if (isMinimumValue) {
      // ! Check min purchase value in ether (since 02.2018)
      if (isMinimumInEther && _weiAmount < minimumPurchaseValue) {
        return false;
      }

      // ! Check min purchase value in tokens (since 02.2018)
      if (!isMinimumInEther && _tokenAmount < minimumPurchaseValue) {
        return false;
      }
    }

    if (_time < startTime || _time > endTime) {
      return false;
    }

    if (isKnownOnly && !userRegistry.knownAddress(_beneficiary)) {
      return false;
    }

    uint finalBeneficiaryInvest = beneficiaryInvest[_beneficiary].add(_weiAmount);
    uint finalTotalSupply = soldTokens.add(_totalAmount);

    if (isWhitelisted) {
      WhitelistRecord storage record = whitelist[_beneficiary];
      if (!record.allow || 
          record.min > finalBeneficiaryInvest ||
          record.max < finalBeneficiaryInvest) {
        return false;
      }
    }

    if (isCappedInEther) {
      if (weiRaised.add(_weiAmount) > hardCap) {
        return false;
      }
    } else {
      if (finalTotalSupply > hardCap) {
        return false;
      }
    }

    return true;
  }

                                                                                        
  function updateTokenValue(address _token, uint _value) onlyOwner public {
    require(address(allowedTokens[_token]) != address(0x0));
    tokensValues[_token] = _value;
  }

  // ██████╗ ███████╗ █████╗ ██████╗ 
  // ██╔══██╗██╔════╝██╔══██╗██╔══██╗
  // ██████╔╝█████╗  ███████║██║  ██║
  // ██╔══██╗██╔══╝  ██╔══██║██║  ██║
  // ██║  ██║███████╗██║  ██║██████╔╝
  // ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ 
  function success() public constant returns(bool) {
    if (isCappedInEther) {
      return weiRaised >= softCap;
    } else {
      return token.totalSupply() >= softCap;
    }
  }

  function capped() public constant returns(bool) {
    if (isCappedInEther) {
      return weiRaised >= hardCap;
    } else {
      return token.totalSupply() >= hardCap;
    }
  }

  function ended() public constant returns(bool) {
    return capped() || block.timestamp >= endTime;
  }


  //  ██████╗ ██╗   ██╗████████╗███████╗██╗██████╗ ███████╗
  // ██╔═══██╗██║   ██║╚══██╔══╝██╔════╝██║██╔══██╗██╔════╝
  // ██║   ██║██║   ██║   ██║   ███████╗██║██║  ██║█████╗  
  // ██║   ██║██║   ██║   ██║   ╚════██║██║██║  ██║██╔══╝  
  // ╚██████╔╝╚██████╔╝   ██║   ███████║██║██████╔╝███████╗
  //  ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝╚═╝╚═════╝ ╚══════╝
  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) inState(State.Active) public payable {
    require(!isDisableEther);
    uint shipAmount = sellTokens(_beneficiary, msg.value, block.timestamp);
    require(shipAmount > 0);
    forwardEther();
  }

  function buyWithHash(address _beneficiary, uint _value, uint _timestamp, bytes32 _hash) 
    inState(State.Active) onlyOwner public 
  {
    require(isAllowToIssue);
    uint shipAmount = sellTokens(_beneficiary, _value, _timestamp);
    require(shipAmount > 0);
    HashBuy(_beneficiary, _value, shipAmount, _timestamp, _hash);
  }
  
  function receiveApproval(address _from, 
                           uint256 _value, 
                           address _token, 
                           bytes _extraData) public 
  {
    if (_token == address(token)) {
      TokenInterface(_token).transferFrom(_from, address(this), _value);
      return;
    }

    require(isTokenExchange);
    
    require(toUint(_extraData) == tokensValues[_token]);
    require(tokensValues[_token] > 0);
    require(forwardTokens(_from, _token, _value));

    uint weiValue = _value.mul(tokensValues[_token]).div(10 ** allowedTokens[_token].decimals());
    require(weiValue > 0);

    uint shipAmount = sellTokens(_from, weiValue, block.timestamp);
    require(shipAmount > 0);

    AltBuy(_from, _token, _value, weiValue, shipAmount);
  }

  function claimFunds() onlyOwner public returns(bool) {
    require(state == State.Claim || (isAllowClaimBeforeFinalization && success()));
    wallet.transfer(address(this).balance);
    return true;
  }

  function claimTokenFunds(address _token) onlyOwner public returns(bool) {
    require(state == State.Claim || (isAllowClaimBeforeFinalization && success()));
    uint balance = allowedTokens[_token].balanceOf(address(this));
    require(balance > 0);
    require(allowedTokens[_token].transfer(wallet, balance));
    return true;
  }

  function claimRefundEther(address _beneficiary) inState(State.Refund) public returns(bool) {
    require(weiDeposit[_beneficiary] > 0);
    _beneficiary.transfer(weiDeposit[_beneficiary]);
    return true;
  }

  function claimRefundTokens(address _beneficiary, address _token) inState(State.Refund) public returns(bool) {
    require(altDeposit[_token][_beneficiary] > 0);
    require(allowedTokens[_token].transfer(_beneficiary, altDeposit[_token][_beneficiary]));
    return true;
  }

  function addToWhitelist(address _beneficiary, uint _min, uint _max) onlyOwner public
  {
    require(_beneficiary != address(0));
    require(_min <= _max);

    if (_max == 0) {
      _max = 10 ** 40; // should be huge enough? :0
    }

    whitelist[_beneficiary] = WhitelistRecord(true, _min, _max);
    Whitelisted(_beneficiary, _min, _max);
  }
  
  function setPersonalBonus(
    address _beneficiary, 
    uint _bonus, 
    address _refererAddress, 
    uint _refererBonus) onlyOwner public {
    personalBonuses[_beneficiary] = PersonalBonusRecord(
      _bonus,
      _refererAddress,
      _refererBonus
    );

    PersonalBonus(_beneficiary, _refererAddress, _bonus, _refererBonus);
  }

  // ██╗███╗   ██╗████████╗███████╗██████╗ ███╗   ██╗ █████╗ ██╗     ███████╗
  // ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗████╗  ██║██╔══██╗██║     ██╔════╝
  // ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝██╔██╗ ██║███████║██║     ███████╗
  // ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██║╚██╗██║██╔══██║██║     ╚════██║
  // ██║██║ ╚████║   ██║   ███████╗██║  ██║██║ ╚████║██║  ██║███████╗███████║
  // ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚══════╝
  // low level token purchase function
  function sellTokens(address _beneficiary, uint _weiAmount, uint timestamp) 
    inState(State.Active) internal returns(uint)
  {
    uint beneficiaryTokens;
    uint extraTokens;
    uint totalTokens;
    uint refererTokens;
    address refererAddress;
    (totalTokens, beneficiaryTokens, extraTokens, refererTokens, refererAddress) = calculateEthAmount(
      _beneficiary, 
      _weiAmount, 
      timestamp, 
      token.totalSupply());

    require(validPurchase(_beneficiary,   // Check if current purchase is valid
                          _weiAmount, 
                          beneficiaryTokens,
                          extraTokens,
                          totalTokens,
                          timestamp));

    weiRaised = weiRaised.add(_weiAmount); // update state (wei amount)
    beneficiaryInvest[_beneficiary] = beneficiaryInvest[_beneficiary].add(_weiAmount);
    shipTokens(_beneficiary, beneficiaryTokens);     // ship tokens to beneficiary
    EthBuy(msg.sender,             // Fire purchase event
                  _beneficiary, 
                  _weiAmount, 
                  beneficiaryTokens);
    ShipTokens(_beneficiary, beneficiaryTokens);

    if (isExtraDistribution) {            // calculate and
      shipTokens(extraTokensHolder, extraTokens);
      ShipTokens(extraTokensHolder, extraTokens);
    }

    if (isPersonalBonuses) {
      PersonalBonusRecord storage record = personalBonuses[_beneficiary];
      if (record.refererAddress != address(0) && record.refererBonus > 0) {
        shipTokens(record.refererAddress, refererTokens);
        ShipTokens(record.refererAddress, refererTokens);
      }
    }

    soldTokens = soldTokens.add(totalTokens);
    return beneficiaryTokens;
  }

  function shipTokens(address _beneficiary, uint _amount) 
    inState(State.Active) internal 
  {
    if (isTransferShipment) {
      token.transfer(_beneficiary, _amount);
    } else {
      token.mint(address(this), _amount);
      token.transfer(_beneficiary, _amount);
    }
  }

  function forwardEther() internal returns (bool) {
    weiDeposit[msg.sender] = msg.value;
    return true;
  }

  function forwardTokens(address _beneficiary, address _tokenAddress, uint _amount) internal returns (bool) {
    TokenInterface allowedToken = allowedTokens[_tokenAddress];
    allowedToken.transferFrom(_beneficiary, address(this), _amount);
    altDeposit[_tokenAddress][_beneficiary] = _amount;
    return true;
  }

  // ██╗   ██╗████████╗██╗██╗     ███████╗
  // ██║   ██║╚══██╔══╝██║██║     ██╔════╝
  // ██║   ██║   ██║   ██║██║     ███████╗
  // ██║   ██║   ██║   ██║██║     ╚════██║
  // ╚██████╔╝   ██║   ██║███████╗███████║
  //  ╚═════╝    ╚═╝   ╚═╝╚══════╝╚══════╝
  function toUint(bytes left) public pure returns (uint) {
      uint out;
      for (uint i = 0; i < 32; i++) {
          out |= uint(left[i]) << (31 * 8 - i * 8);
      }
      
      return out;
  }
}

contract BaseAltCrowdsale is Crowdsale {
  function BaseAltCrowdsale(
    address _registry,
    address _token,
    address _extraTokensHolder,
    address _wallet,
    bool _isWhitelisted,
    uint _price,
    uint _start,
    uint _end,
    uint _softCap,
    uint _hardCap
  ) public {
    setFlags(
      // Should be whitelisted to buy tokens
      // _isWhitelisted,
      _isWhitelisted,
      // Should be known user to buy tokens
      // _isKnownOnly,
      true,
      // Enable amount bonuses in crowdsale? 
      // _isAmountBonus,
      true,
      // Enable early bird bonus in crowdsale?
      // _isEarlyBonus,
      true,
      // Allow to buy tokens for another tokens?
      // _isTokenExcange,
      false,
      // Allow to issue tokens with tx hash (ex bitcoin)
      // _isAllowToIssue,
      true,
      // Should reject purchases with Ether?
      // _isDisableEther,
      false,
      // Should mint extra tokens for future distribution?
      // _isExtraDistribution,
      true,
      // Will ship token via minting? 
      // _isTransferShipment,
      false,
      // Should be capped in ether
      // bool _isCappedInEther,
      true,
      // Should check personal bonuses?
      // _isPersonalBonuses
      true,
      // Should allow to claimFunds before finalizations?
      false
    );

    setToken(_token); 
    setTime(_start, _end);
    setRegistry(_registry);
    setWallet(_wallet);
    setExtraDistribution(
      _extraTokensHolder,
      6667 // 66.67%
    );

    setSoftHardCaps(
      _softCap, // soft
      _hardCap  // hard
    );

    // 200 ALT per 1 ETH
    setPrice(_price);
  }
}

contract AltCrowdsalePhaseOne is BaseAltCrowdsale {
  function AltCrowdsalePhaseOne (
    address _registry,
    address _token,
    address _extraTokensHolder,
    address _wallet
  )
  BaseAltCrowdsale(
    _registry,
    _token,
    _extraTokensHolder,
    _wallet,

    // Whitelisted
    false,

    // price 1 ETH -> 100000 ALT
    uint(1 ether).div(100000),

    // start - 13 Apr 2018 12:18:33 GMT
    1523621913,
    // end - 30 Jun 2018 23:59:59 GMT
    1530403199,

    // _softCap,
    2500 ether,
    // _hardCap
    7500 ether
  )
  public {
  }
}