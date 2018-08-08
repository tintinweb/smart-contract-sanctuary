pragma solidity 0.4.21;

// File: contracts/ERC20Basic.sol

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

// File: contracts/SafeMath.sol

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

// File: contracts/BasicToken.sol

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

// File: contracts/BurnableToken.sol

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
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}

// File: contracts/ERC20.sol

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

// File: contracts/Ownable.sol

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

// File: contracts/StandardToken.sol

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

// File: contracts/MintableToken.sol

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

// File: contracts/HVT.sol

contract HVT is MintableToken, BurnableToken {
  using SafeMath for uint256;

  string public name = "HiVe Token";
  string public symbol = "HVT";
  uint8 public decimals = 18;

  bool public enableTransfers = false;

  // functions overrides in order to maintain the token locked during the ICO
  function transfer(address _to, uint256 _value) public returns(bool) {
    require(enableTransfers);
    return super.transfer(_to,_value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
      require(enableTransfers);
      return super.transferFrom(_from,_to,_value);
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    require(enableTransfers);
    return super.approve(_spender,_value);
  }

  function burn(uint256 _value) public {
    require(enableTransfers);
    super.burn(_value);
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    require(enableTransfers);
    super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    require(enableTransfers);
    super.decreaseApproval(_spender, _subtractedValue);
  }

  // enable token transfers
  function enableTokenTransfers() public onlyOwner {
    enableTransfers = true;
  }

  // batch transfer with different amounts for each address
  function batchTransferDiff(address[] _to, uint256[] _amount) public {
    require(enableTransfers);
    require(_to.length == _amount.length);
    uint256 totalAmount = arraySum(_amount);
    require(totalAmount <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(totalAmount);
    for(uint i;i < _to.length;i++){
      balances[_to[i]] = balances[_to[i]].add(_amount[i]);
      Transfer(msg.sender,_to[i],_amount[i]);
    }
  }

  // batch transfer with same amount for each address
  function batchTransferSame(address[] _to, uint256 _amount) public {
    require(enableTransfers);
    uint256 totalAmount = _amount.mul(_to.length);
    require(totalAmount <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(totalAmount);
    for(uint i;i < _to.length;i++){
      balances[_to[i]] = balances[_to[i]].add(_amount);
      Transfer(msg.sender,_to[i],_amount);
    }
  }

  // get sum of array values
  function arraySum(uint256[] _amount) internal pure returns(uint256){
    uint256 totalAmount;
    for(uint i;i < _amount.length;i++){
      totalAmount = totalAmount.add(_amount[i]);
    }
    return totalAmount;
  }
}

// File: contracts/ICOEngineInterface.sol

contract ICOEngineInterface {

    // false if the ico is not started, true if the ico is started and running, true if the ico is completed
    function started() public view returns(bool);

    // false if the ico is not started, false if the ico is started and running, true if the ico is completed
    function ended() public view returns(bool);

    // time stamp of the starting time of the ico, must return 0 if it depends on the block number
    function startTime() public view returns(uint);

    // time stamp of the ending time of the ico, must retrun 0 if it depends on the block number
    function endTime() public view returns(uint);

    // Optional function, can be implemented in place of startTime
    // Returns the starting block number of the ico, must return 0 if it depends on the time stamp
    // function startBlock() public view returns(uint);

    // Optional function, can be implemented in place of endTime
    // Returns theending block number of the ico, must retrun 0 if it depends on the time stamp
    // function endBlock() public view returns(uint);

    // returns the total number of the tokens available for the sale, must not change when the ico is started
    function totalTokens() public view returns(uint);

    // returns the number of the tokens available for the ico. At the moment that the ico starts it must be equal to totalTokens(),
    // then it will decrease. It is used to calculate the percentage of sold tokens as remainingTokens() / totalTokens()
    function remainingTokens() public view returns(uint);

    // return the price as number of tokens released for each ether
    function price() public view returns(uint);
}

// File: contracts/KYCBase.sol

//import "./SafeMath.sol";


// Abstract base contract
contract KYCBase {
    using SafeMath for uint256;

    mapping (address => bool) public isKycSigner;
    mapping (uint64 => uint256) public alreadyPayed;

    event KycVerified(address indexed signer, address buyerAddress, uint64 buyerId, uint maxAmount);

    function KYCBase(address [] kycSigners) internal {
        for (uint i = 0; i < kycSigners.length; i++) {
            isKycSigner[kycSigners[i]] = true;
        }
    }

    // Must be implemented in descending contract to assign tokens to the buyers. Called after the KYC verification is passed
    function releaseTokensTo(address buyer) internal returns(bool);

    // This method can be overridden to enable some sender to buy token for a different address
    function senderAllowedFor(address buyer)
        internal view returns(bool)
    {
        return buyer == msg.sender;
    }

    function buyTokensFor(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        public payable returns (bool)
    {
        require(senderAllowedFor(buyerAddress));
        return buyImplementation(buyerAddress, buyerId, maxAmount, v, r, s);
    }

    function buyTokens(uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        public payable returns (bool)
    {
        return buyImplementation(msg.sender, buyerId, maxAmount, v, r, s);
    }

    function buyImplementation(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        private returns (bool)
    {
        // check the signature
        bytes32 hash = sha256("Eidoo icoengine authorization", this, buyerAddress, buyerId, maxAmount);
        address signer = ecrecover(hash, v, r, s);
        if (!isKycSigner[signer]) {
            revert();
        } else {
            uint256 totalPayed = alreadyPayed[buyerId].add(msg.value);
            require(totalPayed <= maxAmount);
            alreadyPayed[buyerId] = totalPayed;
            KycVerified(signer, buyerAddress, buyerId, maxAmount);
            return releaseTokensTo(buyerAddress);
        }
    }

    // No payable fallback function, the tokens must be buyed using the functions buyTokens and buyTokensFor
    function () public {
        revert();
    }
}

// File: contracts/RefundVault.sol

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

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

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

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}

// File: contracts/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

// File: contracts/TokenTimelock.sol

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

  // ERC20 basic token contract being held
  ERC20Basic public token;

  // beneficiary of tokens after they are released
  address public beneficiary;

  // timestamp when token release is enabled
  uint256 public releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
    require(_releaseTime > now);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiary.
   */
  function release() public {
    require(now >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}

// File: contracts/HivePowerCrowdsale.sol

// The Hive Power crowdsale contract
contract HivePowerCrowdsale is Ownable, ICOEngineInterface, KYCBase {
    using SafeMath for uint;
    enum State {Running,Success,Failure}

    State public state;

    HVT public token;

    address public wallet;

    // from ICOEngineInterface
    uint [] public prices;

    // from ICOEngineInterface
    uint public startTime;

    // from ICOEngineInterface
    uint public endTime;

    // from ICOEngineInterface
    uint [] public caps;

    // from ICOEngineInterface
    uint public remainingTokens;

    // from ICOEngineInterface
    uint public totalTokens;

    // amount of wei raised
    uint public weiRaised;

    // soft goal in wei
    uint public goal;

    // boolean to make sure preallocate is called only once
    bool public isPreallocated;

    // preallocated company token
    uint public companyTokens;

    // preallocated token for founders
    uint public foundersTokens;

    // vault for refunding
    RefundVault public vault;

    // addresses of time-locked founder vaults
    address [4] public timeLockAddresses;

    // step in seconds for token release
    uint public stepLockedToken;

    // allowed overshoot when crossing the bonus barrier (in wei)
    uint public overshoot;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
    * event for when weis are sent back to buyer
    * @param purchaser who paid for the tokens and is getting back some ether
    * @param amount of weis sent back
    */
    event SentBack(address indexed purchaser, uint256 amount);

    /* event for ICO successfully finalized */
    event FinalizedOK();

    /* event for ICO not successfully finalized */
    event FinalizedNOK();

    /**
     * event for additional token minting
     * @param timelock address of the time-lock contract
     * @param amount amount of tokens minted
     * @param releaseTime release time of tokens
     * @param wallet address of the wallet that can get the token released
     */
    event TimeLocked(address indexed timelock, uint256 amount, uint256 releaseTime, address indexed wallet);

    /**
     * event for additional token minting
     * @param to who got the tokens
     * @param amount amount of tokens purchased
     */
    event Preallocated(address indexed to, uint256 amount);

    /**
     *  Constructor
     */
    function HivePowerCrowdsale(address [] kycSigner, address _token, address _wallet, uint _startTime, uint _endTime, uint [] _prices, uint [] _caps, uint _goal, uint _companyTokens, uint _foundersTokens, uint _stepLockedToken, uint _overshoot)
        public
        KYCBase(kycSigner)
    {
        require(_token != address(0));
        require(_wallet != address(0));
        require(_startTime > now);
        require(_endTime > _startTime);
        require(_prices.length == _caps.length);

        for (uint256 i=0; i < _caps.length -1; i++)
        {
          require(_caps[i+1].sub(_caps[i]) > _overshoot.mul(_prices[i]));
        }

        token = HVT(_token);
        wallet = _wallet;
        startTime = _startTime;
        endTime = _endTime;
        prices = _prices;
        caps = _caps;
        totalTokens = _caps[_caps.length-1];
        remainingTokens = _caps[_caps.length-1];
        vault = new RefundVault(_wallet);
        goal = _goal;
        companyTokens = _companyTokens;
        foundersTokens = _foundersTokens;
        stepLockedToken = _stepLockedToken;
        overshoot = _overshoot;
        state = State.Running;
        isPreallocated = false;
    }

    function preallocate() onlyOwner public {
      // can be called only once
      require(!isPreallocated);

      // mint tokens for team founders in timelocked vaults
      uint numTimelocks = 4;
      uint amount = foundersTokens / numTimelocks; //amount of token per vault
      uint256 releaseTime = endTime;
      for(uint256 i=0; i < numTimelocks; i++)
      {
        // update releaseTime according to the step
        releaseTime = releaseTime.add(stepLockedToken);
        // create tokentimelock
        TokenTimelock timeLock = new TokenTimelock(token, wallet, releaseTime);
        // keep address in memory
        timeLockAddresses[i] = address(timeLock);
        // mint tokens in tokentimelock
        token.mint(address(timeLock), amount);
        // generate event
        TimeLocked(address(timeLock), amount, releaseTime, wallet);
      }

      //teamTimeLocks.mintTokens(teamTokens);
      // Mint additional tokens (referral, airdrops, etc.)
      token.mint(wallet, companyTokens);
      Preallocated(wallet, companyTokens);
      // cannot be called anymore
      isPreallocated = true;
    }

    // function that is called from KYCBase
    function releaseTokensTo(address buyer) internal returns(bool) {
        // needs to be started
        require(started());
        // and not ended
        require(!ended());

        uint256 weiAmount = msg.value;
        uint256 weiBack = 0;
        uint currentPrice = price();
        uint currentCap = getCap();
        uint tokens = weiAmount.mul(currentPrice);
        uint tokenRaised = totalTokens - remainingTokens;

        //check if tokens exceed the amount of tokens that can be minted
        if (tokenRaised.add(tokens) > currentCap)
        {
          tokens = currentCap.sub(tokenRaised);
          weiAmount = tokens.div(currentPrice);
          weiBack = msg.value - weiAmount;
        }
        //require(tokenRaised.add(tokens) <= currentCap);

        weiRaised = weiRaised + weiAmount;
        remainingTokens = remainingTokens.sub(tokens);

        // mint tokens and transfer funds
        token.mint(buyer, tokens);
        forwardFunds(weiAmount);

        if (weiBack>0)
        {
          msg.sender.transfer(weiBack);
          SentBack(msg.sender, weiBack);
        }

        TokenPurchase(msg.sender, buyer, weiAmount, tokens);
        return true;
    }

    function forwardFunds(uint256 weiAmount) internal {
      vault.deposit.value(weiAmount)(msg.sender);
    }

    /**
     * @dev finalize an ICO in dependency on the goal reaching:
     * 1) reached goal (successful ICO):
     * -> release sold token for the transfers
     * -> close the vault
     * -> close the ICO successfully
     * 2) not reached goal (not successful ICO):
     * -> call finalizeNOK()
     */
    function finalize() onlyOwner public {
      require(state == State.Running);
      require(ended());

      // Check the soft goal reaching
      if(weiRaised >= goal) {
        // if goal reached

        // stop the minting
        token.finishMinting();
        // enable token transfers
        token.enableTokenTransfers();
        // close the vault and transfer funds to wallet
        vault.close();

        // ICO successfully finalized
        // set state to Success
        state = State.Success;
        FinalizedOK();
      }
      else {
        // if goal NOT reached
        // ICO not successfully finalized
        finalizeNOK();
      }
    }

    /**
     * @dev finalize an unsuccessful ICO:
     * -> enable the refund
     * -> close the ICO not successfully
     */
     function finalizeNOK() onlyOwner public {
       // run checks again because this is a public function
       require(state == State.Running);
       require(ended());
       // enable the refunds
       vault.enableRefunds();
       // ICO not successfully finalised
       // set state to Failure
       state = State.Failure;
       FinalizedNOK();
     }

     // if crowdsale is unsuccessful, investors can claim refunds here
     function claimRefund() public {
       require(state == State.Failure);
       vault.refund(msg.sender);
    }

    // get the next cap as a function of the amount of sold token
    function getCap() public view returns(uint){
      uint tokenRaised=totalTokens-remainingTokens;
      for (uint i=0;i<caps.length-1;i++){
        if (tokenRaised < caps[i])
        {
          // allow for a an overshoot (only when bonus is applied)
          uint tokenPerOvershoot = overshoot * prices[i];
          return(caps[i].add(tokenPerOvershoot));
        }
      }
      // but not on the total amount of tokens
      return(totalTokens);
    }

    // from ICOEngineInterface
    function started() public view returns(bool) {
        return now >= startTime;
    }

    // from ICOEngineInterface
    function ended() public view returns(bool) {
        return now >= endTime || remainingTokens == 0;
    }

    function startTime() public view returns(uint) {
      return(startTime);
    }

    function endTime() public view returns(uint){
      return(endTime);
    }

    function totalTokens() public view returns(uint){
      return(totalTokens);
    }

    function remainingTokens() public view returns(uint){
      return(remainingTokens);
    }

    // return the price as number of tokens released for each ether
    function price() public view returns(uint){
      uint tokenRaised=totalTokens-remainingTokens;
      for (uint i=0;i<caps.length-1;i++){
        if (tokenRaised < caps[i])
        {
          return(prices[i]);
        }
      }
      return(prices[prices.length-1]);
    }

    // No payable fallback function, the tokens must be buyed using the functions buyTokens and buyTokensFor
    function () public {
        revert();
    }

}

// File: contracts/ERC20Interface.sol

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}