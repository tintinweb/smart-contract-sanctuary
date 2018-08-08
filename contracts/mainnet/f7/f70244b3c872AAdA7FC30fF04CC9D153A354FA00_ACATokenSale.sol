pragma solidity ^0.4.19;

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

/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  /**
   * @param _wallet Vault address
   */
  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  /**
   * @param investor Investor address
   */
  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  /**
   * @param investor Investor address
   */
  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ACAToken is ERC20 {
    using SafeMath for uint256;

    address public owner;
    address public admin;
    address public saleAddress;

    string public name = "ACA Network Token";
    string public symbol = "ACA";
    uint8 public decimals = 18;

    uint256 totalSupply_;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => uint256) balances;

    bool transferable = false;
    mapping (address => bool) internal transferLocked;

    event Genesis(address owner, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event Burn(address indexed burner, uint256 value);
    event LogAddress(address indexed addr);
    event LogUint256(uint256 value);
    event TransferLock(address indexed target, bool value);

    // modifiers
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || msg.sender == admin);
        _;
    }

    modifier canTransfer(address _from, address _to) {
        require(_to != address(0x0));
        require(_to != address(this));

        if ( _from != owner && _from != admin ) {
            require(transferable);
            require (!transferLocked[_from]);
        }
        _;
    }

    // constructor
    function ACAToken(uint256 _totalSupply, address _saleAddress, address _admin) public {
        require(_totalSupply > 0);
        owner = msg.sender;
        require(_saleAddress != address(0x0));
        require(_saleAddress != address(this));
        require(_saleAddress != owner);

        require(_admin != address(0x0));
        require(_admin != address(this));
        require(_admin != owner);

        require(_admin != _saleAddress);

        admin = _admin;
        saleAddress = _saleAddress;

        totalSupply_ = _totalSupply;

        balances[owner] = totalSupply_;
        approve(saleAddress, totalSupply_);

        emit Genesis(owner, totalSupply_);
    }

    // permission related
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        require(newOwner != address(this));
        require(newOwner != admin);

        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }

    function transferAdmin(address _newAdmin) public onlyOwner {
        require(_newAdmin != address(0));
        require(_newAdmin != address(this));
        require(_newAdmin != owner);

        admin = _newAdmin;
        emit AdminTransferred(admin, _newAdmin);
    }

    function setTransferable(bool _transferable) public onlyAdmin {
        transferable = _transferable;
    }

    function isTransferable() public view returns (bool) {
        return transferable;
    }

    function transferLock() public returns (bool) {
        transferLocked[msg.sender] = true;
        emit TransferLock(msg.sender, true);
        return true;
    }

    function manageTransferLock(address _target, bool _value) public onlyAdmin returns (bool) {
        transferLocked[_target] = _value;
        emit TransferLock(_target, _value);
        return true;
    }

    function transferAllowed(address _target) public view returns (bool) {
        return (transferable && transferLocked[_target] == false);
    }

    // token related
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) canTransfer(msg.sender, _to) public returns (bool) {
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function balanceOfOwner() public view returns (uint256 balance) {
        return balances[owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public canTransfer(_from, _to) returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public canTransfer(msg.sender, _spender) returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public canTransfer(msg.sender, _spender) returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public canTransfer(msg.sender, _spender) returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
    }

    function emergencyERC20Drain(ERC20 _token, uint256 _amount) public onlyOwner {
        _token.transfer(owner, _amount);
    }
}

contract ACATokenSale {
    using SafeMath for uint256;

    address public owner;
    address public admin;

    address public wallet;
    ACAToken public token;

    uint256 totalSupply;

    struct StageInfo {
        uint256 opening;
        uint256 closing;
        uint256 capacity;
        uint256 minimumWei;
        uint256 maximumWei;
        uint256 rate;
        uint256 sold;
    }
    bool public tokenSaleEnabled = false;

    mapping(address => bool) public whitelist;
    mapping(address => bool) public kyclist;
    mapping(address => bool) public whitelistBonus;

    uint256 public whitelistBonusClosingTime;
    uint256 public whitelistBonusSent = 0;
    uint256 public whitelistBonusRate;
    uint256 public whitelistBonusAmount;

    mapping (address => uint256) public sales;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public weiRaised = 0;

    RefundVault public vault;

    mapping (address => address) public referrals;
    uint256 public referralAmount;
    uint256 public referralRateInviter;
    uint256 public referralRateInvitee;
    uint256 public referralSent = 0;
    bool public referralDone = false;

    mapping (address => uint256) public bounties;
    uint256 public bountyAmount;
    uint256 public bountySent = 0;

    StageInfo[] public stages;
    uint256 public currentStage = 0;

    bool public isFinalized = false;
    bool public isClaimable = false;

    // events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event TokenSaleCreated(address indexed wallet, uint256 totalSupply);
    event StageAdded(uint256 openingTime, uint256 closingTime, uint256 capacity, uint256 minimumWei, uint256 maximumWei, uint256 rate);
    event TokenSaleEnabled();

    event WhitelistUpdated(address indexed beneficiary, bool flag);
    event VerificationUpdated(address indexed beneficiary, bool flag);
    event BulkWhitelistUpdated(address[] beneficiary, bool flag);
    event BulkVerificationUpdated(address[] beneficiary, bool flag);

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event TokenClaimed(address indexed beneficiary, uint256 amount);
    event Finalized();
    event BountySetupDone();
    event BountyUpdated(address indexed target, bool flag, uint256 amount);
    event PurchaseReferral(address indexed beneficiary, uint256 amount);
    event StageUpdated(uint256 stage);
    event StageCapReached(uint256 stage);
    event ReferralCapReached();

    // do not use this on mainnet!
    event LogAddress(address indexed addr);
    event LogUint256(uint256 value);

    // modifiers
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || msg.sender == admin);
        _;
    }

    modifier onlyWhileOpen {
        require(tokenSaleEnabled == true);
        require(now >= stages[currentStage].opening && now <= stages[currentStage].closing);
        _;
    }

    modifier isVerified(address _beneficiary) {
        require(whitelist[_beneficiary] == true);
        require(kyclist[_beneficiary] == true);
        _;
    }

    modifier claimable {
        require(isFinalized == true || isClaimable == true);
        require(isGoalReached());
        _;
    }

    // getters
    function isEnabled() public view returns (bool) {
        return tokenSaleEnabled;
    }

    function isClosed() public view returns (bool) {
        return now > stages[stages.length - 1].closing;
    }

    function isGoalReached() public view returns (bool) {
        return getTotalTokenSold() >= softCap;
    }

    function getTotalTokenSold() public view returns (uint256) {
        uint256 sold = 0;
        for ( uint i = 0; i < stages.length; ++i ) {
            sold = sold.add(stages[i].sold);
        }

        return sold;
    }

    function getOpeningTime() public view returns (uint256) {
        return stages[currentStage].opening;
    }

    function getOpeningTimeByStage(uint _index) public view returns (uint256) {
        require(_index < stages.length);
        return stages[_index].opening;
    }

    function getClosingTime() public view returns (uint256) {
        return stages[currentStage].closing;
    }

    function getClosingTimeByStage(uint _index) public view returns (uint256) {
        require(_index < stages.length);
        return stages[_index].closing;
    }

    function getCurrentCapacity() public view returns (uint256) {
        return stages[currentStage].capacity;
    }

    function getCapacity(uint _index) public view returns (uint256) {
        require(_index < stages.length);
        return stages[_index].capacity;
    }

    function getCurrentSold() public view returns (uint256) {
        return stages[currentStage].sold;
    }

    function getSold(uint _index) public view returns (uint256) {
        require(_index < stages.length);
        return stages[_index].sold;
    }

    function getCurrentRate() public view returns (uint256) {
        return stages[currentStage].rate;
    }

    function getRate(uint _index) public view returns (uint256) {
        require(_index < stages.length);
        return stages[_index].rate;
    }

    function getRateWithoutBonus() public view returns (uint256) {
        return stages[stages.length - 1].rate;
    }

    function getSales(address _beneficiary) public view returns (uint256) {
        return sales[_beneficiary];
    }
    
    // setter
    function setSalePeriod(uint _index, uint256 _openingTime, uint256 _closingTime) onlyOwner public {
        require(_openingTime > now);
        require(_closingTime > _openingTime);

        require(_index > currentStage);
        require(_index < stages.length);

        stages[_index].opening = _openingTime;        
        stages[_index].closing = _closingTime;        
    }

    function setRate(uint _index, uint256 _rate) onlyOwner public {
        require(_index > currentStage);
        require(_index < stages.length);

        require(_rate > 0);

        stages[_index].rate = _rate;
    }

    function setCapacity(uint _index, uint256 _capacity) onlyOwner public {
        require(_index > currentStage);
        require(_index < stages.length);

        require(_capacity > 0);

        stages[_index].capacity = _capacity;
    }

    function setClaimable(bool _claimable) onlyOwner public {
        if ( _claimable == true ) {
            require(isGoalReached());
        }

        isClaimable = _claimable;
    }

    function addPrivateSale(uint256 _amount) onlyOwner public {
        require(currentStage == 0);
        require(_amount > 0);
        require(_amount < stages[0].capacity.sub(stages[0].sold));

        stages[0].sold = stages[0].sold.add(_amount);
    }

    function subPrivateSale(uint256 _amount) onlyOwner public {
        require(currentStage == 0);
        require(_amount > 0);
        require(stages[0].sold > _amount);

        stages[0].sold = stages[0].sold.sub(_amount);
    }

    // permission
    function setAdmin(address _newAdmin) public onlyOwner {
        require(_newAdmin != address(0x0));
        require(_newAdmin != address(this));
        require(_newAdmin != owner);

        emit AdminTransferred(admin, _newAdmin);
        admin = _newAdmin;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        require(newOwner != address(this));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // constructor
    function ACATokenSale(
        address _wallet, 
        address _admin,
        uint256 _totalSupply,
        uint256 _softCap,
        uint256 _hardCap) public {
        owner = msg.sender;

        require(_admin != address(0));
        require(_wallet != address(0));

        require(_totalSupply > 0);
        require(_softCap > 0);
        require(_hardCap > _softCap);

        admin = _admin;
        wallet = _wallet;

        totalSupply = _totalSupply;
        softCap = _softCap;
        hardCap = _hardCap;

        emit TokenSaleCreated(wallet, _totalSupply);
    }

    // state related
    function setupBounty(
        uint256 _referralAmount,
        uint256 _referralRateInviter,
        uint256 _referralRateInvitee,
        uint256 _bountyAmount,
        uint256 _whitelistBonusClosingTime,
        uint256 _whitelistBonusRate,
        uint256 _whitelistBonusAmount
    ) onlyOwner public {
        
        require(_referralAmount > 0);

        require(_referralRateInviter > 0 && _referralRateInviter < 100);
        require(_referralRateInvitee > 0 && _referralRateInvitee < 100);

        require(_whitelistBonusClosingTime > now);
        require(_whitelistBonusRate > 0);
        require(_whitelistBonusAmount > _whitelistBonusRate);
        require(_bountyAmount > 0);

        referralAmount = _referralAmount;
        referralRateInviter = _referralRateInviter;
        referralRateInvitee = _referralRateInvitee;
        bountyAmount = _bountyAmount;
        whitelistBonusClosingTime = _whitelistBonusClosingTime;
        whitelistBonusRate = _whitelistBonusRate;
        whitelistBonusAmount = _whitelistBonusAmount;

        emit BountySetupDone();
    }
    function addStage(
        uint256 _openingTime, 
        uint256 _closingTime, 
        uint256 _capacity, 
        uint256 _minimumWei, 
        uint256 _maximumWei, 
        uint256 _rate) onlyOwner public {
        require(tokenSaleEnabled == false);

        // require(_openingTime > now);
        require(_closingTime > _openingTime);

        require(_capacity > 0);
        require(_capacity < hardCap);

        require(_minimumWei > 0);
        require(_maximumWei >= _minimumWei);

        require(_rate > 0);

        require(_minimumWei.mul(_rate) < _capacity);
        require(_maximumWei.mul(_rate) < _capacity);
        if ( stages.length > 0 ) {
            StageInfo memory prevStage = stages[stages.length - 1];
            require(_openingTime > prevStage.closing);
        }

        stages.push(StageInfo(_openingTime, _closingTime, _capacity, _minimumWei, _maximumWei, _rate, 0));

        emit StageAdded(_openingTime, _closingTime, _capacity, _minimumWei, _maximumWei, _rate);
    }

    function setToken(ACAToken _token) onlyOwner public {
        token = _token;
    }

    function enableTokenSale() onlyOwner public returns (bool) {
        require(stages.length > 0);

        vault = new RefundVault(wallet);

        tokenSaleEnabled = true;
        emit TokenSaleEnabled();
        return true;
    }

    function updateStage() public returns (uint256) {
        require(tokenSaleEnabled == true);
        require(currentStage < stages.length);
        require(now >= stages[currentStage].opening);

        uint256 remains = stages[currentStage].capacity.sub(stages[currentStage].sold);
        if ( now > stages[currentStage].closing ) {
            uint256 nextStage = currentStage.add(1);
            if ( remains > 0 && nextStage < stages.length ) {
                stages[nextStage].capacity = stages[nextStage].capacity.add(remains);
                remains = stages[nextStage].capacity;
            }

            currentStage = nextStage;
            emit StageUpdated(nextStage);
        }

        return remains;
    }

    function finalize() onlyOwner public {
        require(isFinalized == false);
        require(isClosed());

        finalization();
        emit Finalized();

        isFinalized = true;
    }

    function finalization() internal {
        if (isGoalReached()) {
            vault.close();
        } else {
            vault.enableRefunds();
        }

    }

    // transaction
    function () public payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;

        _preValidatePurchase(_beneficiary, weiAmount);
        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(getCurrentRate());
    }

    function _getTokenAmountWithoutBonus(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(getRateWithoutBonus());
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isVerified(_beneficiary) {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);

        require(tokenSaleEnabled == true);

        require(now >= stages[currentStage].opening);

        // lazy execution
        uint256 remains = updateStage();

        require(currentStage < stages.length);
        require(now >= stages[currentStage].opening && now <= stages[currentStage].closing);

        require(_weiAmount >= stages[currentStage].minimumWei);
        require(_weiAmount <= stages[currentStage].maximumWei);

        uint256 amount = _getTokenAmount(_weiAmount);

        require(remains > amount);
    }

    function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        if ( getCurrentSold() == getCurrentCapacity() ) {
            currentStage = currentStage.add(1);
            emit StageUpdated(currentStage);
        }
    }

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        if ( isClaimable ) {
            token.transferFrom(owner, _beneficiary, _tokenAmount);
        }
        else {
            sales[_beneficiary] = sales[_beneficiary].add(_tokenAmount);
        }
    }

    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {

        stages[currentStage].sold = stages[currentStage].sold.add(_tokenAmount);
        _deliverTokens(_beneficiary, _tokenAmount);

        uint256 weiAmount = msg.value;
        address inviter = referrals[_beneficiary];
        if ( inviter != address(0x0) && referralDone == false ) {
            uint256 baseRate = _getTokenAmountWithoutBonus(weiAmount);
            uint256 referralAmountInviter = baseRate.div(100).mul(referralRateInviter);
            uint256 referralAmountInvitee = baseRate.div(100).mul(referralRateInvitee);
            uint256 referralRemains = referralAmount.sub(referralSent);
            if ( referralRemains == 0 ) {
                referralDone = true;
            }
            else {
                if ( referralAmountInviter >= referralRemains ) {
                    referralAmountInviter = referralRemains;
                    referralAmountInvitee = 0; // priority to inviter
                    emit ReferralCapReached();
                    referralDone = true;
                }
                if ( referralDone == false && referralAmountInviter >= referralRemains ) {
                    referralAmountInvitee = referralRemains.sub(referralAmountInviter);
                    emit ReferralCapReached();
                    referralDone = true;
                }

                uint256 referralAmountTotal = referralAmountInviter.add(referralAmountInvitee);
                referralSent = referralSent.add(referralAmountTotal);

                if ( referralAmountInviter > 0 ) {
                    _deliverTokens(inviter, referralAmountInviter);
                    emit PurchaseReferral(inviter, referralAmountInviter);
                }
                if ( referralAmountInvitee > 0 ) {
                    _deliverTokens(_beneficiary, referralAmountInvitee);
                    emit PurchaseReferral(_beneficiary, referralAmountInvitee);
                }
            }
        }
    }

    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
        // optional override
    }

    function _forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }

    // claim
    function claimToken() public claimable isVerified(msg.sender) returns (bool) {
        address beneficiary = msg.sender;
        uint256 amount = sales[beneficiary];

        emit TokenClaimed(beneficiary, amount);

        sales[beneficiary] = 0;
        return token.transferFrom(owner, beneficiary, amount);
    }

    function claimRefund() isVerified(msg.sender) public {
        require(isFinalized == true);
        require(!isGoalReached());

        vault.refund(msg.sender);
    }

    function claimBountyToken() public claimable isVerified(msg.sender) returns (bool) {
        address beneficiary = msg.sender;
        uint256 amount = bounties[beneficiary];

        emit TokenClaimed(beneficiary, amount);

        bounties[beneficiary] = 0;
        return token.transferFrom(owner, beneficiary, amount);
    }

    // bounty
    function addBounty(address _address, uint256 _amount) public onlyAdmin isVerified(_address) returns (bool) {
        require(bountyAmount.sub(bountySent) >= _amount);

        bountySent = bountySent.add(_amount);
        bounties[_address] = bounties[_address].add(_amount);
        emit BountyUpdated(_address, true, _amount);
    }
    function delBounty(address _address, uint256 _amount) public onlyAdmin isVerified(_address) returns (bool) {
        require(bounties[_address] >= _amount);
        require(_amount >= bountySent);

        bountySent = bountySent.sub(_amount);
        bounties[_address] = bounties[_address].sub(_amount);
        emit BountyUpdated(_address, false, _amount);
    }
    function getBountyAmount(address _address) public view returns (uint256) {
        return bounties[_address];
    }

    // referral
    function addReferral(address _inviter, address _invitee) public onlyAdmin isVerified(_inviter) isVerified(_invitee) returns (bool) {
        referrals[_invitee] = _inviter;
    }
    function delReferral(address _inviter, address _invitee) public onlyAdmin isVerified(_inviter) isVerified(_invitee) returns (bool) {
        delete referrals[_invitee];
    }
    function getReferral(address _address) public view returns (address) {
        return referrals[_address];
    }

    // whitelist
    function _deliverWhitelistBonus(address _beneficiary) internal {
        if ( _beneficiary == address(0x0) ) {
            return;
        }

        if ( whitelistBonus[_beneficiary] == true ) {
            return;
        }
        
        if (whitelistBonusAmount.sub(whitelistBonusSent) > whitelistBonusRate ) {
            whitelistBonus[_beneficiary] = true;

            whitelistBonusSent = whitelistBonusSent.add(whitelistBonusRate);
            bounties[_beneficiary] = bounties[_beneficiary].add(whitelistBonusRate);
            emit BountyUpdated(_beneficiary, true, whitelistBonusRate);
        }
    }
    function isAccountWhitelisted(address _beneficiary) public view returns (bool) {
        return whitelist[_beneficiary];
    }

    function addToWhitelist(address _beneficiary) external onlyAdmin {
        whitelist[_beneficiary] = true;

        if ( whitelistBonus[_beneficiary] == false && now < whitelistBonusClosingTime ) {
            _deliverWhitelistBonus(_beneficiary);
        }

        emit WhitelistUpdated(_beneficiary, true);
    }

    function addManyToWhitelist(address[] _beneficiaries) external onlyAdmin {
        uint256 i = 0;
        if ( now < whitelistBonusClosingTime ) {
            for (i = 0; i < _beneficiaries.length; i++) {
                whitelist[_beneficiaries[i]] = true;
                _deliverWhitelistBonus(_beneficiaries[i]);
            }
            return;
        }

        for (i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }

        emit BulkWhitelistUpdated(_beneficiaries, true);
    }

    function removeFromWhitelist(address _beneficiary) external onlyAdmin {
        whitelist[_beneficiary] = false;

        emit WhitelistUpdated(_beneficiary, false);
    }

    // kyc
    function isAccountVerified(address _beneficiary) public view returns (bool) {
        return kyclist[_beneficiary];
    }

    function setAccountVerified(address _beneficiary) external onlyAdmin {
        kyclist[_beneficiary] = true;

        emit VerificationUpdated(_beneficiary, true);
    }

    function setManyAccountsVerified(address[] _beneficiaries) external onlyAdmin {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            kyclist[_beneficiaries[i]] = true;
        }

        emit BulkVerificationUpdated(_beneficiaries, true);
    }

    function unverifyAccount(address _beneficiary) external onlyAdmin {
        kyclist[_beneficiary] = false;

        emit VerificationUpdated(_beneficiary, false);
    }
}