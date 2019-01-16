pragma solidity 0.4.24;


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
    constructor(address _owner) public {
        owner = _owner;
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}



/**
 * @title Validator
 * @dev The Validator contract has a validator address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Validator {
    address public validator;

    event NewValidatorSet(address indexed previousOwner, address indexed newValidator);

    /**
    * @dev The Validator constructor sets the original `validator` of the contract to the sender
    * account.
    */
    constructor() public {
        validator = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the validator.
    */
    modifier onlyValidator() {
        require(msg.sender == validator);
        _;
    }

    /**
    * @dev Allows the current validator to transfer control of the contract to a newValidator.
    * @param newValidator The address to become next validator.
    */
    function setNewValidator(address newValidator) public onlyValidator {
        require(newValidator != address(0));
        emit NewValidatorSet(validator, newValidator);
        validator = newValidator;
    }
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



contract TokenInterface {
    function mint(address _to, uint256 _amount) public returns (bool);
    function finishMinting() public returns (bool);
    function transferOwnership(address newOwner) public;
}


/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive. The contract requires a MintableToken that will be
 * minted as contributions arrive, note that the crowdsale contract
 * must be owner of the token in order to be able to mint it.
 */
contract Crowdsale {
    using SafeMath for uint256;

    // The token being sold
    address public token;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // address where funds are collected
    address public wallet;

    // how many token units a buyer gets per ether
    uint256 public rate;

    // amount of raised money in wei
    uint256 public weiRaised;

    // maximum amount of wei that can be raised
    uint256 public hardCap;

    /**
    * event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor(uint256 _startTime, uint256 _endTime, uint256 _hardCap, uint256 _rate, address _wallet, address _token) public {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        startTime = _startTime;
        endTime = _endTime;
        hardCap = _hardCap;
        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = getTokenAmount(weiAmount);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        TokenInterface(token).mint(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

    // Override this method to have a way to add business logic to your crowdsale when buying
    function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
        return weiAmount.mul(rate);
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        require(weiRaised.add(msg.value) <= hardCap);
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

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
 
    constructor(address _owner) public Ownable(_owner) {}

    /**
    * @dev Must be called after crowdsale ends, to do some extra finalization
    * work. Calls the contract&#39;s finalization function.
    */
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        emit Finalized();

        isFinalized = true;
    }

    /**
    * @dev Can be overridden to add finalization logic. The overriding function
    * should call super.finalization() to ensure the chain of finalization is
    * executed entirely.
    */
    function finalization() internal {}
}







contract Whitelist is Ownable {
    mapping(address => bool) internal investorMap;

    /**
    * event for investor approval logging
    * @param investor approved investor
    */
    event Approved(address indexed investor);

    /**
    * event for investor disapproval logging
    * @param investor disapproved investor
    */
    event Disapproved(address indexed investor);

    constructor(address _owner) 
        public 
        Ownable(_owner) 
    {
        
    }

    /** @param _investor the address of investor to be checked
      * @return true if investor is approved
      */
    function isInvestorApproved(address _investor) external view returns (bool) {
        require(_investor != address(0));
        return investorMap[_investor];
    }

    /** @dev approve an investor
      * @param toApprove investor to be approved
      */
    function approveInvestor(address toApprove) external onlyOwner {
        investorMap[toApprove] = true;
        emit Approved(toApprove);
    }

    /** @dev approve investors in bulk
      * @param toApprove array of investors to be approved
      */
    function approveInvestorsInBulk(address[] toApprove) external onlyOwner {
        for (uint i = 0; i < toApprove.length; i++) {
            investorMap[toApprove[i]] = true;
            emit Approved(toApprove[i]);
        }
    }

    /** @dev disapprove an investor
      * @param toDisapprove investor to be disapproved
      */
    function disapproveInvestor(address toDisapprove) external onlyOwner {
        delete investorMap[toDisapprove];
        emit Disapproved(toDisapprove);
    }

    /** @dev disapprove investors in bulk
      * @param toDisapprove array of investors to be disapproved
      */
    function disapproveInvestorsInBulk(address[] toDisapprove) external onlyOwner {
        for (uint i = 0; i < toDisapprove.length; i++) {
            delete investorMap[toDisapprove[i]];
            emit Disapproved(toDisapprove[i]);
        }
    }
}



/** @title Compliant Crowdsale */
contract CompliantCrowdsaleHardcap is Validator, FinalizableCrowdsale {
    Whitelist public whiteListingContract;

    struct MintStruct {
        address to;
        uint256 tokens;
        uint256 weiAmount;
    }

    mapping (uint => MintStruct) public pendingMints;
    uint256 public currentMintNonce;
    mapping (address => uint) public rejectedMintBalance;

    modifier checkIsInvestorApproved(address _account) {
        require(whiteListingContract.isInvestorApproved(_account));
        _;
    }

    modifier checkIsAddressValid(address _account) {
        require(_account != address(0));
        _;
    }

    /**
    * event for rejected mint logging
    * @param to address for which buy tokens got rejected
    * @param value number of tokens
    * @param amount number of ethers invested
    * @param nonce request recorded at this particular nonce
    * @param reason reason for rejection
    */
    event MintRejected(
        address indexed to,
        uint256 value,
        uint256 amount,
        uint256 indexed nonce,
        uint256 reason
    );

    /**
    * event for buy tokens request logging
    * @param beneficiary address for which buy tokens is requested
    * @param tokens number of tokens
    * @param weiAmount number of ethers invested
    * @param nonce request recorded at this particular nonce
    */
    event ContributionRegistered(
        address beneficiary,
        uint256 tokens,
        uint256 weiAmount,
        uint256 nonce
    );

    /**
    * event for rate update logging
    * @param rate new rate
    */
    event RateUpdated(uint256 rate);

    /**
    * event for whitelist contract update logging
    * @param _whiteListingContract address of the new whitelist contract
    */
    event WhiteListingContractSet(address indexed _whiteListingContract);

    /**
    * event for claimed ether logging
    * @param account user claiming the ether
    * @param amount ether claimed
    */
    event Claimed(address indexed account, uint256 amount);

    /** @dev Constructor
      * @param whitelistAddress Ethereum address of the whitelist contract
      * @param _startTime crowdsale start time
      * @param _endTime crowdsale end time
      * @param _hardcap maximum ether(in weis) this crowdsale can raise
      * @param _rate number of tokens to be sold per ether
      * @param _wallet Ethereum address of the wallet
      * @param _token Ethereum address of the token contract
      * @param _owner Ethereum address of the owner
      */
    constructor(
        address whitelistAddress,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _hardcap,
        uint256 _rate,
        address _wallet,
        address _token,
        address _owner
    )
        public
        FinalizableCrowdsale(_owner)
        Crowdsale(_startTime, _endTime, _hardcap, _rate, _wallet, _token)
    {
        setWhitelistContract(whitelistAddress);
    }

    /** @dev Updates whitelist contract address
      * @param whitelistAddress address of the new whitelist contract 
      */
    function setWhitelistContract(address whitelistAddress)
        public 
        onlyValidator 
        checkIsAddressValid(whitelistAddress)
    {
        whiteListingContract = Whitelist(whitelistAddress);
        emit WhiteListingContractSet(whiteListingContract);
    }

    /** @dev buy tokens request
      * @param beneficiary the address to which the tokens have to be minted
      */
    function buyTokens(address beneficiary)
        public 
        payable
        checkIsInvestorApproved(beneficiary)
    {
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);

        pendingMints[currentMintNonce] = MintStruct(beneficiary, tokens, weiAmount);
        emit ContributionRegistered(beneficiary, tokens, weiAmount, currentMintNonce);

        currentMintNonce++;
    }

    /** @dev Updates token rate 
    * @param _rate New token rate 
    */ 
    function updateRate(uint256 _rate) public onlyOwner { 
        require(_rate > 0);
        rate = _rate;
        emit RateUpdated(rate);
    }

    /** @dev approve buy tokens request
      * @param nonce request recorded at this particular nonce
      */
    function approveMint(uint256 nonce)
        external 
        onlyValidator
    {
        require(_approveMint(nonce));
    }

    /** @dev reject buy tokens request
      * @param nonce request recorded at this particular nonce
      * @param reason reason for rejection
      */
    function rejectMint(uint256 nonce, uint256 reason)
        external 
        onlyValidator
    {
        _rejectMint(nonce, reason);
    }

    /** @dev approve buy tokens requests in bulk
      * @param nonces request recorded at these nonces
      */
    function bulkApproveMints(uint256[] nonces)
        external 
        onlyValidator
    {
        for (uint i = 0; i < nonces.length; i++) {
            require(_approveMint(nonces[i]));
        }        
    }
    
    /** @dev reject buy tokens requests
      * @param nonces request recorded at these nonces
      * @param reasons reasons for rejection
      */
    function bulkRejectMints(uint256[] nonces, uint256[] reasons)
        external 
        onlyValidator
    {
        require(nonces.length == reasons.length);
        for (uint i = 0; i < nonces.length; i++) {
            _rejectMint(nonces[i], reasons[i]);
        }
    }

    /** @dev approve buy tokens request called internally in the approveMint and bulkApproveMints functions
      * @param nonce request recorded at this particular nonce
      */
    function _approveMint(uint256 nonce)
        private
        checkIsInvestorApproved(pendingMints[nonce].to)
        returns (bool)
    {
        // update state
        weiRaised = weiRaised.add(pendingMints[nonce].weiAmount);

        //No need to use mint-approval on token side, since the minting is already approved in the crowdsale side
        TokenInterface(token).mint(pendingMints[nonce].to, pendingMints[nonce].tokens);
        
        emit TokenPurchase(
            msg.sender,
            pendingMints[nonce].to,
            pendingMints[nonce].weiAmount,
            pendingMints[nonce].tokens
        );

        forwardFunds(pendingMints[nonce].weiAmount);
        delete pendingMints[nonce];

        return true;
    }

    /** @dev reject buy tokens request called internally in the rejectMint and bulkRejectMints functions
      * @param nonce request recorded at this particular nonce
      * @param reason reason for rejection
      */
    function _rejectMint(uint256 nonce, uint256 reason)
        private
        checkIsAddressValid(pendingMints[nonce].to)
    {
        rejectedMintBalance[pendingMints[nonce].to] = rejectedMintBalance[pendingMints[nonce].to].add(pendingMints[nonce].weiAmount);
        
        emit MintRejected(
            pendingMints[nonce].to,
            pendingMints[nonce].tokens,
            pendingMints[nonce].weiAmount,
            nonce,
            reason
        );
        
        delete pendingMints[nonce];
    }

    /** @dev claim back ether if buy tokens request is rejected */
    function claim() external {
        require(rejectedMintBalance[msg.sender] > 0);
        uint256 value = rejectedMintBalance[msg.sender];
        rejectedMintBalance[msg.sender] = 0;

        msg.sender.transfer(value);

        emit Claimed(msg.sender, value);
    }

    function finalization() internal {
        TokenInterface(token).finishMinting();
        transferTokenOwnership(owner);
        super.finalization();
    }

    /** @dev Updates token contract address
      * @param newToken New token contract address
      */
    function setTokenContract(address newToken)
        external 
        onlyOwner
        checkIsAddressValid(newToken)
    {
        token = newToken;
    }

    /** @dev transfers ownership of the token contract
      * @param newOwner New owner of the token contract
      */
    function transferTokenOwnership(address newOwner)
        public 
        onlyOwner
        checkIsAddressValid(newOwner)
    {
        TokenInterface(token).transferOwnership(newOwner);
    }

    function forwardFunds(uint256 amount) internal {
        wallet.transfer(amount);
    }
}