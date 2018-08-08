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



/**
 * @title CrowdsaleConfig
 * @dev Holds all constants for SelfKeyCrowdsale contract
*/
contract CrowdsaleConfig {
    uint256 public constant TOKEN_DECIMALS = 18;
    uint256 public constant MIN_TOKEN_UNIT = 10 ** uint256(TOKEN_DECIMALS);

    // Initial distribution amounts
    uint256 public constant TOTAL_SUPPLY_CAP = 6000000000 * MIN_TOKEN_UNIT;

    // 33% of the total supply cap
    uint256 public constant SALE_CAP = 1980000000 * MIN_TOKEN_UNIT;

    // Minimum cap per purchaser on public sale = $100 in KEY (at $0.015)
    uint256 public constant PURCHASER_MIN_TOKEN_CAP = 6666 * MIN_TOKEN_UNIT;

    // Maximum cap per purchaser on first day of public sale = $3,000 in KEY (at $0.015)
    uint256 public constant PURCHASER_MAX_TOKEN_CAP_DAY1 = 200000 * MIN_TOKEN_UNIT;

    // Maximum cap per purchaser on public sale = $18,000 in KEY (at $0.015)
    uint256 public constant PURCHASER_MAX_TOKEN_CAP = 1200000 * MIN_TOKEN_UNIT;

    // 16.5%
    uint256 public constant FOUNDATION_POOL_TOKENS = 876666666 * MIN_TOKEN_UNIT;
    uint256 public constant FOUNDATION_POOL_TOKENS_VESTED = 113333334 * MIN_TOKEN_UNIT;

    // Approx 33%
    uint256 public constant COMMUNITY_POOL_TOKENS = 1980000000 * MIN_TOKEN_UNIT;

    // Founders&#39; distribution. Total = 16.5%
    uint256 public constant FOUNDERS_TOKENS = 330000000 * MIN_TOKEN_UNIT;
    uint256 public constant FOUNDERS_TOKENS_VESTED_1 = 330000000 * MIN_TOKEN_UNIT;
    uint256 public constant FOUNDERS_TOKENS_VESTED_2 = 330000000 * MIN_TOKEN_UNIT;

    // 1% for legal advisors
    uint256 public constant LEGAL_EXPENSES_1_TOKENS = 54000000 * MIN_TOKEN_UNIT;
    uint256 public constant LEGAL_EXPENSES_2_TOKENS = 6000000 * MIN_TOKEN_UNIT;

    // KEY price in USD (thousandths)
    uint256 public constant TOKEN_PRICE_THOUSANDTH = 15;  // $0.015 per KEY

    // Contract wallet addresses for initial allocation
    address public constant CROWDSALE_WALLET_ADDR = 0xE0831b1687c9faD3447a517F9371E66672505dB0;
    address public constant FOUNDATION_POOL_ADDR = 0xD68947892Ef4D94Cdef7165b109Cf6Cd3f58A8e8;
    address public constant FOUNDATION_POOL_ADDR_VEST = 0xd0C24Bb82e71A44eA770e84A3c79979F9233308D;
    address public constant COMMUNITY_POOL_ADDR = 0x0506c5485AE54aB14C598Ef16C459409E5d8Fc03;
    address public constant FOUNDERS_POOL_ADDR = 0x4452d6454e777743a5Ee233fbe873055008fF528;
    address public constant LEGAL_EXPENSES_ADDR_1 = 0xb57911380F13A0a9a6Ba6562248674B5f56D7BFE;
    address public constant LEGAL_EXPENSES_ADDR_2 = 0x9be281CdcF34B3A01468Ad1008139410Ba5BB2fB;

    // 6 months period, in seconds, for pre-commitment half-vesting
    uint64 public constant PRECOMMITMENT_VESTING_SECONDS = 15552000;
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
    totalSupply = totalSupply.add(_amount);
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

/* solhint-disable not-rely-on-time */









/**
 * @title SelfKeyToken
 * @dev SelfKey Token implementation.
 */
contract SelfKeyToken is MintableToken {
    string public constant name = &#39;SelfKey&#39;; //solhint-disable-line const-name-snakecase
    string public constant symbol = &#39;KEY&#39;; //solhint-disable-line const-name-snakecase
    uint256 public constant decimals = 18; //solhint-disable-line const-name-snakecase

    uint256 public cap;
    bool private transfersEnabled = false;

    event Burned(address indexed burner, uint256 value);

    /**
     * @dev Only the contract owner can transfer without restrictions.
     *      Regular holders need to wait until sale is finalized.
     * @param _sender — The address sending the tokens
     * @param _value — The number of tokens to send
     */
    modifier canTransfer(address _sender, uint256 _value) {
        require(transfersEnabled || _sender == owner);
        _;
    }

    /**
     * @dev Constructor that sets a maximum supply cap.
     * @param _cap — The maximum supply cap.
     */
    function SelfKeyToken(uint256 _cap) public {
        cap = _cap;
    }

    /**
     * @dev Overrides MintableToken.mint() for restricting supply under cap
     * @param _to — The address to receive minted tokens
     * @param _value — The number of tokens to mint
     */
    function mint(address _to, uint256 _value) public onlyOwner canMint returns (bool) {
        require(totalSupply.add(_value) <= cap);
        return super.mint(_to, _value);
    }

    /**
     * @dev Checks modifier and allows transfer if tokens are not locked.
     * @param _to — The address to receive tokens
     * @param _value — The number of tokens to send
     */
    function transfer(address _to, uint256 _value)
        public canTransfer(msg.sender, _value) returns (bool)
    {
        return super.transfer(_to, _value);
    }

    /**
     * @dev Checks modifier and allows transfer if tokens are not locked.
     * @param _from — The address to send tokens from
     * @param _to — The address to receive tokens
     * @param _value — The number of tokens to send
     */
    function transferFrom(address _from, address _to, uint256 _value)
        public canTransfer(_from, _value) returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Enables token transfers.
     *      Called when the token sale is successfully finalized
     */
    function enableTransfers() public onlyOwner {
        transfersEnabled = true;
    }

    /**
    * @dev Burns a specific number of tokens.
    * @param _value — The number of tokens to be burned.
    */
    function burn(uint256 _value) public onlyOwner {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burned(burner, _value);
    }
}












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



/**
 * @title SelfKeyCrowdsale
 * @dev SelfKey Token Crowdsale implementation.
 */
// solhint-disable-next-line max-states-count
contract SelfKeyCrowdsale is Ownable, CrowdsaleConfig {
    using SafeMath for uint256;
    using SafeERC20 for SelfKeyToken;

    // whitelist of addresses that can perform precommitments and KYC verifications
    mapping(address => bool) public isVerifier;

    // Token contract
    SelfKeyToken public token;

    uint64 public startTime;
    uint64 public endTime;

    // Minimum tokens expected to sell
    uint256 public goal;

    // How many tokens a buyer gets per ETH
    uint256 public rate = 51800;

    // ETH price in USD, can be later updated until start date
    uint256 public ethPrice = 777;

    // Total amount of tokens purchased, including pre-sale
    uint256 public totalPurchased = 0;

    mapping(address => bool) public kycVerified;
    mapping(address => uint256) public tokensPurchased;

    // a mapping of dynamically instantiated token timelocks for each pre-commitment beneficiary
    mapping(address => address) public vestedTokens;

    bool public isFinalized = false;

    // Token Timelocks
    TokenTimelock public foundersTimelock1;
    TokenTimelock public foundersTimelock2;
    TokenTimelock public foundationTimelock;

    // Vault to hold funds until crowdsale is finalized. Allows refunding if crowdsale is not successful.
    RefundVault public vault;

    // Crowdsale events
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    event VerifiedKYC(address indexed participant);

    event AddedPrecommitment(
        address indexed participant,
        uint256 tokensAllocated
    );

    event Finalized();

    modifier verifierOnly() {
        require(isVerifier[msg.sender]);
        _;
    }

    /**
     * @dev Crowdsale contract constructor
     * @param _startTime — Unix timestamp representing the crowdsale start time
     * @param _endTime — Unix timestamp representing the crowdsale start time
     * @param _goal — Minimum amount of tokens expected to sell.
     */
    function SelfKeyCrowdsale(
        uint64 _startTime,
        uint64 _endTime,
        uint256 _goal
    ) public
    {
        require(_endTime > _startTime);

        // sets contract owner as a verifier
        isVerifier[msg.sender] = true;

        token = new SelfKeyToken(TOTAL_SUPPLY_CAP);

        // mints all possible tokens to the crowdsale contract
        token.mint(address(this), TOTAL_SUPPLY_CAP);
        token.finishMinting();

        startTime = _startTime;
        endTime = _endTime;
        goal = _goal;

        vault = new RefundVault(CROWDSALE_WALLET_ADDR);

        // Set timelocks to 6 months and a year after startTime, respectively
        uint64 sixMonthLock = uint64(startTime + 15552000);
        uint64 yearLock = uint64(startTime + 31104000);

        // Instantiation of token timelocks
        foundersTimelock1 = new TokenTimelock(token, FOUNDERS_POOL_ADDR, sixMonthLock);
        foundersTimelock2 = new TokenTimelock(token, FOUNDERS_POOL_ADDR, yearLock);
        foundationTimelock = new TokenTimelock(token, FOUNDATION_POOL_ADDR_VEST, yearLock);

        // Genesis allocation of tokens
        token.safeTransfer(FOUNDATION_POOL_ADDR, FOUNDATION_POOL_TOKENS);
        token.safeTransfer(COMMUNITY_POOL_ADDR, COMMUNITY_POOL_TOKENS);
        token.safeTransfer(FOUNDERS_POOL_ADDR, FOUNDERS_TOKENS);
        token.safeTransfer(LEGAL_EXPENSES_ADDR_1, LEGAL_EXPENSES_1_TOKENS);
        token.safeTransfer(LEGAL_EXPENSES_ADDR_2, LEGAL_EXPENSES_2_TOKENS);

        // Allocation of vested tokens
        token.safeTransfer(foundersTimelock1, FOUNDERS_TOKENS_VESTED_1);
        token.safeTransfer(foundersTimelock2, FOUNDERS_TOKENS_VESTED_2);
        token.safeTransfer(foundationTimelock, FOUNDATION_POOL_TOKENS_VESTED);
    }

    /**
     * @dev Fallback function is used to buy tokens.
     *      It&#39;s the only entry point since `buyTokens` is internal
     */
    function () public payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev Adds an address to the whitelist of Verifiers
     * @param _address - address of the verifier
     */
    function addVerifier (address _address) public onlyOwner {
        isVerifier[_address] = true;
    }

    /**
     * @dev Removes an address from the whitelist of Verifiers
     * @param _address - address of the verifier to be removed
     */
    function removeVerifier (address _address) public onlyOwner {
        isVerifier[_address] = false;
    }

    /**
     * @dev Sets a new start date as long as token hasn&#39;t started yet
     * @param _startTime - unix timestamp of the new start time
     */
    function setStartTime (uint64 _startTime) public onlyOwner {
        require(now < startTime);
        require(_startTime > now);
        require(_startTime < endTime);

        startTime = _startTime;
    }

    /**
     * @dev Sets a new end date as long as end date hasn&#39;t been reached
     * @param _endTime - unix timestamp of the new end time
     */
    function setEndTime (uint64 _endTime) public onlyOwner {
        require(now < endTime);
        require(_endTime > now);
        require(_endTime > startTime);

        endTime = _endTime;
    }

    /**
     * @dev Updates the ETH/USD conversion rate as long as the public sale hasn&#39;t started
     * @param _ethPrice - Updated conversion rate
     */
    function setEthPrice(uint256 _ethPrice) public onlyOwner {
        require(now < startTime);
        require(_ethPrice > 0);

        ethPrice = _ethPrice;
        rate = ethPrice.mul(1000).div(TOKEN_PRICE_THOUSANDTH);
    }

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     *      work. Calls the contract&#39;s finalization function.
     */
    function finalize() public onlyOwner {
        require(now > startTime);
        require(!isFinalized);

        finalization();
        Finalized();

        isFinalized = true;
    }

    /**
     * @dev If crowdsale is unsuccessful, a refund can be claimed back
     */
    function claimRefund(address participant) public {
        // requires sale to be finalized and goal not reached,
        require(isFinalized);
        require(!goalReached());

        vault.refund(participant);
    }

    /**
     * @dev If crowdsale is unsuccessful, participants can claim refunds
     */
    function goalReached() public constant returns (bool) {
        return totalPurchased >= goal;
    }

    /**
     * @dev Release time-locked tokens
     */
    function releaseLockFounders1() public {
        foundersTimelock1.release();
    }

    function releaseLockFounders2() public {
        foundersTimelock2.release();
    }

    function releaseLockFoundation() public {
        foundationTimelock.release();
    }

    /**
     * @dev Release time-locked tokens for any vested address
     */
    function releaseLock(address participant) public {
        require(vestedTokens[participant] != 0x0);

        TokenTimelock timelock = TokenTimelock(vestedTokens[participant]);
        timelock.release();
    }

    /**
     * @dev Verifies KYC for given participant.
     *      This enables token purchases by the participant addres
     */
    function verifyKYC(address participant) public verifierOnly {
        kycVerified[participant] = true;

        VerifiedKYC(participant);
    }

    /**
     * @dev Adds an address for pre-sale commitments made off-chain.
     * @param beneficiary — Address of the already verified participant
     * @param tokensAllocated — Exact amount of KEY tokens (including decimal places) to allocate
     * @param halfVesting — determines whether the half the tokens will be time-locked or not
     */
    function addPrecommitment(
        address beneficiary,
        uint256 tokensAllocated,
        bool halfVesting
    ) public verifierOnly
    {
        // requires to be on pre-sale
        require(now < startTime); // solhint-disable-line not-rely-on-time

        kycVerified[beneficiary] = true;

        uint256 tokens = tokensAllocated;
        totalPurchased = totalPurchased.add(tokens);
        tokensPurchased[beneficiary] = tokensPurchased[beneficiary].add(tokens);

        if (halfVesting) {
            // half the tokens are put into a time-lock for a pre-defined period
            uint64 endTimeLock = uint64(startTime + PRECOMMITMENT_VESTING_SECONDS);

            // Sets a timelock for half the tokens allocated
            uint256 half = tokens.div(2);
            TokenTimelock timelock;

            if (vestedTokens[beneficiary] == 0x0) {
                timelock = new TokenTimelock(token, beneficiary, endTimeLock);
                vestedTokens[beneficiary] = address(timelock);
            } else {
                timelock = TokenTimelock(vestedTokens[beneficiary]);
            }

            token.safeTransfer(beneficiary, half);
            token.safeTransfer(timelock, tokens.sub(half));
        } else {
            // all tokens are sent to the participant&#39;s address
            token.safeTransfer(beneficiary, tokens);
        }

        AddedPrecommitment(
            beneficiary,
            tokens
        );
    }

    /**
     * @dev Additional finalization logic. Enables token transfers.
     */
    function finalization() internal {
        if (goalReached()) {
            burnUnsold();
            vault.close();
            token.enableTransfers();
        } else {
            vault.enableRefunds();
        }
    }

    /**
     *  @dev Low level token purchase. Only callable internally. Participants MUST be KYC-verified before purchase
     *  @param participant — The address of the token purchaser
     */
    function buyTokens(address participant) internal {
        require(kycVerified[participant]);
        require(now >= startTime);
        require(now < endTime);
        require(!isFinalized);
        require(msg.value != 0);

        // Calculate the token amount to be allocated
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(rate);

        // Update state
        tokensPurchased[participant] = tokensPurchased[participant].add(tokens);
        totalPurchased = totalPurchased.add(tokens);

        require(totalPurchased <= SALE_CAP);
        require(tokensPurchased[participant] >= PURCHASER_MIN_TOKEN_CAP);

        if (now < startTime + 86400) {
            // if still during the first day of token sale, apply different max cap
            require(tokensPurchased[participant] <= PURCHASER_MAX_TOKEN_CAP_DAY1);
        } else {
            require(tokensPurchased[participant] <= PURCHASER_MAX_TOKEN_CAP);
        }

        // Sends ETH contribution to the RefundVault and tokens to participant
        vault.deposit.value(msg.value)(participant);
        token.safeTransfer(participant, tokens);

        TokenPurchase(
            msg.sender,
            participant,
            weiAmount,
            tokens
        );
    }

    /**
     * @dev Burn all remaining (unsold) tokens.
     *      This should be called after sale finalization
     */
    function burnUnsold() internal {
        // All tokens held by this contract get burned
        token.burn(token.balanceOf(this));
    }
}