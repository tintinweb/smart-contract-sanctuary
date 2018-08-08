pragma solidity ^0.4.17;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title ERC20
 * @dev ERC20 interface
 */
contract ERC20 {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}







contract Controlled {
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

/**
 * @title MiniMe interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20MiniMe is ERC20, Controlled {
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool);
    function totalSupply() public constant returns (uint);
    function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint);
    function totalSupplyAt(uint _blockNumber) public constant returns(uint);
    function createCloneToken(string _cloneTokenName, uint8 _cloneDecimalUnits, string _cloneTokenSymbol, uint _snapshotBlock, bool _transfersEnabled) public returns(address);
    function generateTokens(address _owner, uint _amount) public returns (bool);
    function destroyTokens(address _owner, uint _amount)  public returns (bool);
    function enableTransfers(bool _transfersEnabled) public;
    function isContract(address _addr) constant internal returns(bool);
    function claimTokens(address _token) public;
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
}








/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  ERC20MiniMe public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }


  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    buyTokens(beneficiary, msg.value);
  }

  // implementation of low level token purchase function
  function buyTokens(address beneficiary, uint256 weiAmount) internal {
    require(beneficiary != 0x0);
    require(validPurchase(weiAmount));

    transferToken(beneficiary, weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    forwardFunds(weiAmount);
  }

  // low level transfer token
  // override to create custom token transfer mechanism, eg. pull pattern
  function transferToken(address beneficiary, uint256 weiAmount) internal {
    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    token.generateTokens(beneficiary, tokens);

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds(uint256 weiAmount) internal {
    wallet.transfer(weiAmount);
  }

  // @return true if the transaction can buy tokens
  function validPurchase(uint256 weiAmount) internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = weiAmount != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }

  // @return true if crowdsale has started
  function hasStarted() public constant returns (bool) {
    return now >= startTime;
  }
}

/**
 * @title CappedCrowdsale
 * @dev Extension of Crowdsale with a max amount of funds raised
 */
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }

  // overriding Crowdsale#validPurchase to add extra cap logic
  // @return true if investors can buy at the moment
  function validPurchase(uint256 weiAmount) internal constant returns (bool) {
    return super.validPurchase(weiAmount) && !capReached();
  }

  // overriding Crowdsale#hasEnded to add cap logic
  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return super.hasEnded() || capReached();
  }

  // @return true if cap has been reached
  function capReached() internal constant returns (bool) {
   return weiRaised >= cap;
  }

  // overriding Crowdsale#buyTokens to add partial refund logic
  function buyTokens(address beneficiary) public payable {
     uint256 weiToCap = cap.sub(weiRaised);
     uint256 weiAmount = weiToCap < msg.value ? weiToCap : msg.value;

     buyTokens(beneficiary, weiAmount);

     uint256 refund = msg.value.sub(weiAmount);
     if (refund > 0) {
       msg.sender.transfer(refund);
     }
   }
}




/// @dev The token controller contract must implement these functions
contract TokenController {
    ERC20MiniMe public ethealToken;
    address public SALE; // address where sale tokens are located

    /// @notice needed for hodler handling
    function addHodlerStake(address _beneficiary, uint256 _stake) public;
    function setHodlerStake(address _beneficiary, uint256 _stake) public;
    function setHodlerTime(uint256 _time) public;


    /// @notice Called when `_owner` sends ether to the MiniMe Token contract
    /// @param _owner The address that sent the ether to create tokens
    /// @return True if the ether is accepted, false if it throws
    function proxyPayment(address _owner) public payable returns(bool);

    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount) public returns(bool);
}






/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal {
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
 * @title Eliptic curve signature operations
 *
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 */

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using his signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    //Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

}

/**
 * @title EthealWhitelist
 * @author thesved
 * @notice EthealWhitelist contract which handles KYC
 */
contract EthealWhitelist is Ownable {
    using ECRecovery for bytes32;

    // signer address for offchain whitelist signing
    address public signer;

    // storing whitelisted addresses
    mapping(address => bool) public isWhitelisted;

    event WhitelistSet(address indexed _address, bool _state);

    ////////////////
    // Constructor
    ////////////////
    function EthealWhitelist(address _signer) {
        require(_signer != address(0));

        signer = _signer;
    }

    /// @notice set signing address after deployment
    function setSigner(address _signer) public onlyOwner {
        require(_signer != address(0));

        signer = _signer;
    }

    ////////////////
    // Whitelisting: only owner
    ////////////////

    ///&#160;@notice Set whitelist state for an address.
    function setWhitelist(address _addr, bool _state) public onlyOwner {
        require(_addr != address(0));
        isWhitelisted[_addr] = _state;
        WhitelistSet(_addr, _state);
    }

    ///&#160;@notice Set whitelist state for multiple addresses
    function setManyWhitelist(address[] _addr, bool _state) public onlyOwner {
        for (uint256 i = 0; i < _addr.length; i++) {
            setWhitelist(_addr[i], _state);
        }
    }

    /// @notice offchain whitelist check
    function isOffchainWhitelisted(address _addr, bytes _sig) public view returns (bool) {
        bytes32 hash = keccak256("\x19Ethereum Signed Message:\n20",_addr);
        return hash.recover(_sig) == signer;
    }
}

/**
 * @title EthealNormalSale
 * @author thesved
 * @notice Etheal Token Sale contract, with softcap and hardcap (cap)
 * @dev This contract has to be finalized before token claims are enabled
 */
contract EthealNormalSale is Pausable, FinalizableCrowdsale, CappedCrowdsale {
    // the token is here
    TokenController public ethealController;

    // after reaching {weiRaised} >= {softCap}, there is {softCapTime} seconds until the sale closes
    // {softCapClose} contains the closing time
    uint256 public rate = 700;
    uint256 public softCap = 6800 ether;
    uint256 public softCapTime = 120 hours;
    uint256 public softCapClose;
    uint256 public cap = 14300 ether;

    // how many token is sold and not claimed, used for refunding to token controller
    uint256 public tokenBalance;

    // total token sold
    uint256 public tokenSold;

    // minimum contribution, 0.1ETH
    uint256 public minContribution = 0.1 ether;

    // whitelist: above threshold the contract has to approve each transaction
    EthealWhitelist public whitelist;
    uint256 public whitelistThreshold = 1 ether;

    // deposit address from which it can get funds before sale
    address public deposit;
    
    // stakes contains token bought and contirbutions contains the value in wei
    mapping (address => uint256) public stakes;
    mapping (address => uint256) public contributions;

    // promo token bonus
    address public promoTokenController;
    mapping (address => uint256) public bonusExtra;

    // addresses of contributors to handle finalization after token sale end (refunds or token claims)
    address[] public contributorsKeys; 

    // events for token purchase during sale and claiming tokens after sale
    event LogTokenClaimed(address indexed _claimer, address indexed _beneficiary, uint256 _amount);
    event LogTokenPurchase(address indexed _purchaser, address indexed _beneficiary, uint256 _value, uint256 _amount, uint256 _participants, uint256 _weiRaised);
    event LogTokenSoftCapReached(uint256 _closeTime);
    event LogTokenHardCapReached();

    ////////////////
    // Constructor and inherited function overrides
    ////////////////

    /// @notice Constructor to create PreSale contract
    /// @param _ethealController Address of ethealController
    /// @param _startTime The start time of token sale in seconds.
    /// @param _endTime The end time of token sale in seconds.
    /// @param _minContribution The minimum contribution per transaction in wei (0.1 ETH)
    /// @param _rate Number of HEAL tokens per 1 ETH
    /// @param _softCap Softcap in wei, reaching it ends the sale in _softCapTime seconds
    /// @param _softCapTime Seconds until the sale remains open after reaching _softCap
    /// @param _cap Maximum cap in wei, we can&#39;t raise more funds
    /// @param _wallet Address of multisig wallet, which will get all the funds after successful sale
    function EthealNormalSale(
        address _ethealController,
        uint256 _startTime, 
        uint256 _endTime, 
        uint256 _minContribution, 
        uint256 _rate, 
        uint256 _softCap, 
        uint256 _softCapTime, 
        uint256 _cap, 
        address _wallet
    )
        CappedCrowdsale(_cap)
        FinalizableCrowdsale()
        Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
        // ethealController must be valid
        require(_ethealController != address(0));
        ethealController = TokenController(_ethealController);

        // caps have to be consistent with each other
        require(_softCap <= _cap);
        softCap = _softCap;
        softCapTime = _softCapTime;

        // this is needed since super constructor wont overwite overriden variables
        cap = _cap;
        rate = _rate;

        minContribution = _minContribution;
    }

    ////////////////
    // Administer contract details
    ////////////////

    /// @notice Sets min contribution
    function setMinContribution(uint256 _minContribution) public onlyOwner {
        minContribution = _minContribution;
    }

    /// @notice Sets soft cap and max cap
    function setCaps(uint256 _softCap, uint256 _softCapTime, uint256 _cap) public onlyOwner {
        require(_softCap <= _cap);
        softCap = _softCap;
        softCapTime = _softCapTime;
        cap = _cap;
    }

    /// @notice Sets crowdsale start and end time
    function setTimes(uint256 _startTime, uint256 _endTime) public onlyOwner {
        require(_startTime <= _endTime);
        require(!hasEnded());
        startTime = _startTime;
        endTime = _endTime;
    }

    /// @notice Set rate
    function setRate(uint256 _rate) public onlyOwner {
        require(_rate > 0);
        rate = _rate;
    }

    /// @notice Set address of promo token
    function setPromoTokenController(address _addr) public onlyOwner {
        require(_addr != address(0));
        promoTokenController = _addr;
    }

    /// @notice Set whitelist contract address and minimum threshold
    function setWhitelist(address _whitelist, uint256 _threshold) public onlyOwner {
        // if whitelist contract address is provided we set it
        if (_whitelist != address(0)) {
            whitelist = EthealWhitelist(_whitelist);
        }
        whitelistThreshold = _threshold;
    }

    /// @notice Set deposit contract address from which it can receive money before sale
    function setDeposit(address _deposit) public onlyOwner {
        deposit = _deposit;
    }

    /// @notice move excess tokens, eg to hodler/sale contract
    function moveTokens(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0));
        require(_amount <= getHealBalance().sub(tokenBalance));
        require(ethealController.ethealToken().transfer(_to, _amount));
    }

    ////////////////
    // Purchase functions
    ////////////////

    /// @dev Overriding Crowdsale#buyTokens to add partial refund
    /// @param _beneficiary Beneficiary of the token purchase
    function buyTokens(address _beneficiary) public payable whenNotPaused {
        handlePayment(_beneficiary, msg.value, now, "");
    }

    /// @dev buying tokens for someone with offchain whitelist signature
    function buyTokensSigned(address _beneficiary, bytes _whitelistSign) public payable whenNotPaused {
        handlePayment(_beneficiary, msg.value, now, _whitelistSign);
    }

    /// @dev Internal function for handling transactions with ether.
    function handlePayment(address _beneficiary, uint256 _amount, uint256 _time, bytes memory _whitelistSign) internal {
        require(_beneficiary != address(0));

        uint256 weiAmount = handleContribution(_beneficiary, _amount, _time, _whitelistSign);      
        forwardFunds(weiAmount);  

        // handle refund excess tokens
        uint256 refund = _amount.sub(weiAmount);
        if (refund > 0) {
            _beneficiary.transfer(refund);
        }
    }

    /// @dev Handling the amount of contribution and cap logic. Internal function.
    /// @return Wei successfully contributed.
    function handleContribution(address _beneficiary, uint256 _amount, uint256 _time, bytes memory _whitelistSign) internal returns (uint256) {
        require(_beneficiary != address(0));

        uint256 weiToCap = howMuchCanXContributeNow(_beneficiary);
        uint256 weiAmount = uint256Min(weiToCap, _amount);

        // account the new contribution
        transferToken(_beneficiary, weiAmount, _time, _whitelistSign);

        // close sale in softCapTime seconds after reaching softCap
        if (weiRaised >= softCap && softCapClose == 0) {
            softCapClose = now.add(softCapTime);
            LogTokenSoftCapReached(uint256Min(softCapClose, endTime));
        }

        // event for hard cap reached
        if (weiRaised >= cap) {
            LogTokenHardCapReached();
        }

        return weiAmount;
    }

    /// @dev Handling token distribution and accounting. Overriding Crowdsale#transferToken.
    /// @param _beneficiary Address of the recepient of the tokens
    /// @param _weiAmount Contribution in wei
    /// @param _time When the contribution was made
    function transferToken(address _beneficiary, uint256 _weiAmount, uint256 _time, bytes memory _whitelistSign) internal {
        require(_beneficiary != address(0));
        require(validPurchase(_weiAmount));

        // increase wei Raised
        weiRaised = weiRaised.add(_weiAmount);

        // require whitelist above threshold
        contributions[_beneficiary] = contributions[_beneficiary].add(_weiAmount);
        require(contributions[_beneficiary] <= whitelistThreshold 
                || whitelist.isWhitelisted(_beneficiary)
                || whitelist.isOffchainWhitelisted(_beneficiary, _whitelistSign)
        );

        // calculate tokens, so we can refund excess tokens to EthealController after token sale
        uint256 _bonus = getBonus(_beneficiary, _weiAmount, _time);
        uint256 tokens = _weiAmount.mul(rate).mul(_bonus).div(100);
        tokenBalance = tokenBalance.add(tokens);

        if (stakes[_beneficiary] == 0) {
            contributorsKeys.push(_beneficiary);
        }
        stakes[_beneficiary] = stakes[_beneficiary].add(tokens);

        LogTokenPurchase(msg.sender, _beneficiary, _weiAmount, tokens, contributorsKeys.length, weiRaised);
    }

    /// @dev Get eth deposit from Deposit contract
    function depositEth(address _beneficiary, uint256 _time, bytes _whitelistSign) public payable whenNotPaused {
        require(msg.sender == deposit);

        handlePayment(_beneficiary, msg.value, _time, _whitelistSign);
    }

    /// @dev Deposit from other currencies
    function depositOffchain(address _beneficiary, uint256 _amount, uint256 _time, bytes _whitelistSign) public onlyOwner whenNotPaused {
        handleContribution(_beneficiary, _amount, _time, _whitelistSign);
    }

    /// @dev Overriding Crowdsale#validPurchase to add min contribution logic
    /// @param _weiAmount Contribution amount in wei
    /// @return true if contribution is okay
    function validPurchase(uint256 _weiAmount) internal constant returns (bool) {
        bool nonEnded = !hasEnded();
        bool nonZero = _weiAmount != 0;
        bool enoughContribution = _weiAmount >= minContribution;
        return nonEnded && nonZero && enoughContribution;
    }

    /// @dev Overriding Crowdsale#hasEnded to add soft cap logic
    /// @return true if crowdsale event has ended or a softCapClose time is set and passed
    function hasEnded() public constant returns (bool) {
        return super.hasEnded() || softCapClose > 0 && now > softCapClose;
    }

    /// @dev Extending RefundableCrowdsale#finalization sending back excess tokens to ethealController
    function finalization() internal {
        uint256 _balance = getHealBalance();

        // saving token balance for future reference
        tokenSold = tokenBalance; 

        // send back the excess token to ethealController
        if (_balance > tokenBalance) {
            ethealController.ethealToken().transfer(ethealController.SALE(), _balance.sub(tokenBalance));
        }

        // hodler stake counting starts 14 days after closing normal sale
        ethealController.setHodlerTime(now + 14 days);

        super.finalization();
    }


    ////////////////
    // AFTER token sale
    ////////////////

    /// @notice Modifier for after sale finalization
    modifier afterSale() {
        require(isFinalized);
        _;
    }

    /// @notice Claim token for msg.sender after token sale based on stake.
    function claimToken() public afterSale {
        claimTokenFor(msg.sender);
    }

    /// @notice Claim token after token sale based on stake.
    /// @dev Anyone can call this function and distribute tokens after successful token sale
    /// @param _beneficiary Address of the beneficiary who gets the token
    function claimTokenFor(address _beneficiary) public afterSale whenNotPaused {
        uint256 tokens = stakes[_beneficiary];
        require(tokens > 0);

        // set the stake 0 for beneficiary
        stakes[_beneficiary] = 0;

        // decrease tokenBalance, to make it possible to withdraw excess HEAL funds
        tokenBalance = tokenBalance.sub(tokens);

        // distribute hodlr stake
        ethealController.addHodlerStake(_beneficiary, tokens);

        // distribute token
        require(ethealController.ethealToken().transfer(_beneficiary, tokens));
        LogTokenClaimed(msg.sender, _beneficiary, tokens);
    }

    /// @notice claimToken() for multiple addresses
    /// @dev Anyone can call this function and distribute tokens after successful token sale
    /// @param _beneficiaries Array of addresses for which we want to claim tokens
    function claimManyTokenFor(address[] _beneficiaries) external afterSale {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            claimTokenFor(_beneficiaries[i]);
        }
    }


    ////////////////
    // Bonus functions
    ////////////////

    /// @notice Sets extra 5% bonus for those addresses who send back a promo token
    /// @notice It contains an easter egg.
    ///&#160;@param _addr this address gets the bonus
    ///&#160;@param _value how many tokens are transferred
    function setPromoBonus(address _addr, uint256 _value) public {
        require(msg.sender == promoTokenController || msg.sender == owner);
        require(_value>0);

        uint256 _bonus = keccak256(_value) == 0xbeced09521047d05b8960b7e7bcc1d1292cf3e4b2a6b63f48335cbde5f7545d2 ? 6 : 5;

        if (bonusExtra[ _addr ] < _bonus) {
            bonusExtra[ _addr ] = _bonus;
        }
    }

    /// @notice Manual set extra bonus for addresses
    function setBonusExtra(address _addr, uint256 _bonus) public onlyOwner {
        require(_addr != address(0));
        bonusExtra[_addr] = _bonus;
    }

    /// @notice Mass set extra bonus for addresses
    function setManyBonusExtra(address[] _addr, uint256 _bonus) external onlyOwner {
        for (uint256 i = 0; i < _addr.length; i++) {
            setBonusExtra(_addr[i],_bonus);
        }
    }

    /// @notice Returns bonus for now
    function getBonusNow(address _addr, uint256 _size) public view returns (uint256) {
        return getBonus(_addr, _size, now);
    }

    /// @notice Returns the bonus in percentage, eg 130 means 30% bonus
    function getBonus(address _addr, uint256 _size, uint256 _time) public view returns (uint256 _bonus) {
        // detailed bonus structure: https://etheal.com/#heal-token
        _bonus = 100;
        
        // time based bonuses
        uint256 _day = getSaleDay(_time);
        uint256 _hour = getSaleHour(_time);
        if (_day <= 1) {
            if (_hour <= 1) _bonus = 130;
            else if (_hour <= 5) _bonus = 125;
            else if (_hour <= 8) _bonus = 120;
            else _bonus = 118;
        } 
        else if (_day <= 2) { _bonus = 116; }
        else if (_day <= 3) { _bonus = 115; }
        else if (_day <= 5) { _bonus = 114; }
        else if (_day <= 7) { _bonus = 113; }
        else if (_day <= 9) { _bonus = 112; }
        else if (_day <= 11) { _bonus = 111; }
        else if (_day <= 13) { _bonus = 110; }
        else if (_day <= 15) { _bonus = 108; }
        else if (_day <= 17) { _bonus = 107; }
        else if (_day <= 19) { _bonus = 106; }
        else if (_day <= 21) { _bonus = 105; }
        else if (_day <= 23) { _bonus = 104; }
        else if (_day <= 25) { _bonus = 103; }
        else if (_day <= 27) { _bonus = 102; }

        // size based bonuses
        if (_size >= 100 ether) { _bonus = _bonus + 4; }
        else if (_size >= 10 ether) { _bonus = _bonus + 2; }

        // manual bonus
        _bonus += bonusExtra[ _addr ];

        return _bonus;
    }


    ////////////////
    // Constant, helper functions
    ////////////////

    /// @notice How many wei can the msg.sender contribute now.
    function howMuchCanIContributeNow() view public returns (uint256) {
        return howMuchCanXContributeNow(msg.sender);
    }

    /// @notice How many wei can an ethereum address contribute now.
    /// @param _beneficiary Ethereum address
    /// @return Number of wei the _beneficiary can contribute now.
    function howMuchCanXContributeNow(address _beneficiary) view public returns (uint256) {
        require(_beneficiary != address(0));

        if (hasEnded() || paused) 
            return 0;

        // wei to hard cap
        uint256 weiToCap = cap.sub(weiRaised);

        return weiToCap;
    }

    /// @notice For a give date how many 24 hour blocks have ellapsed since token sale start
    ///  Before sale return 0, first day 1, second day 2, ...
    /// @param _time Date in seconds for which we want to know which sale day it is
    /// @return Number of 24 hour blocks ellapsing since token sale start starting from 1
    function getSaleDay(uint256 _time) view public returns (uint256) {
        uint256 _day = 0;
        if (_time > startTime) {
            _day = _time.sub(startTime).div(60*60*24).add(1);
        }
        return _day;
    }

    /// @notice How many 24 hour blocks have ellapsed since token sale start
    /// @return Number of 24 hour blocks ellapsing since token sale start starting from 1
    function getSaleDayNow() view public returns (uint256) {
        return getSaleDay(now);
    }

    /// @notice Returns sale hour: 0 before sale, 1 for the first hour, ...
    /// @param _time Date in seconds for which we want to know which sale hour it is
    /// @return Number of 1 hour blocks ellapsing since token sale start starting from 1
    function getSaleHour(uint256 _time) view public returns (uint256) {
        uint256 _hour = 0;
        if (_time > startTime) {
            _hour = _time.sub(startTime).div(60*60).add(1);
        }
        return _hour;
    }

    /// @notice How many 1 hour blocks have ellapsed since token sale start
    /// @return Number of 1 hour blocks ellapsing since token sale start starting from 1
    function getSaleHourNow() view public returns (uint256) {
        return getSaleHour(now);
    }

    /// @notice Minimum between two uint256 numbers
    function uint256Min(uint256 a, uint256 b) pure internal returns (uint256) {
        return a > b ? b : a;
    }


    ////////////////
    // Test and contribution web app, NO audit is needed
    ////////////////

    /// @notice How many contributors we have.
    /// @return Number of different contributor ethereum addresses
    function getContributorsCount() view public returns (uint256) {
        return contributorsKeys.length;
    }

    /// @notice Get contributor addresses to manage refunds or token claims.
    /// @dev If the sale is not yet successful, then it searches in the RefundVault.
    ///  If the sale is successful, it searches in contributors.
    /// @param _pending If true, then returns addresses which didn&#39;t get their tokens distributed to them
    /// @param _claimed If true, then returns already distributed addresses
    /// @return Array of addresses of contributors
    function getContributors(bool _pending, bool _claimed) view public returns (address[] contributors) {
        uint256 i = 0;
        uint256 results = 0;
        address[] memory _contributors = new address[](contributorsKeys.length);

        // search in contributors
        for (i = 0; i < contributorsKeys.length; i++) {
            if (_pending && stakes[contributorsKeys[i]] > 0 || _claimed && stakes[contributorsKeys[i]] == 0) {
                _contributors[results] = contributorsKeys[i];
                results++;
            }
        }

        contributors = new address[](results);
        for (i = 0; i < results; i++) {
            contributors[i] = _contributors[i];
        }

        return contributors;
    }

    /// @notice How many HEAL tokens do this contract have
    function getHealBalance() view public returns (uint256) {
        return ethealController.ethealToken().balanceOf(address(this));
    }

    /// @notice Get current date for web3
    function getNow() view public returns (uint256) {
        return now;
    }
}