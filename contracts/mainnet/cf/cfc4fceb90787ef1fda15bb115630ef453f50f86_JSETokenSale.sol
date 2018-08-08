pragma solidity ^0.4.23;

// File: contracts/JSECoinCrowdsaleConfig.sol

contract JSECoinCrowdsaleConfig {
    
    uint8 public constant   TOKEN_DECIMALS = 18;
    uint256 public constant DECIMALSFACTOR = 10**uint256(TOKEN_DECIMALS);

    uint256 public constant DURATION                                = 12 weeks; 
    uint256 public constant CONTRIBUTION_MIN                        = 0.1 ether; // Around $64
    uint256 public constant CONTRIBUTION_MAX_NO_WHITELIST           = 20 ether; // $9,000
    uint256 public constant CONTRIBUTION_MAX                        = 10000.0 ether; //After Whitelisting
    
    uint256 public constant TOKENS_MAX                              = 10000000000 * (10 ** uint256(TOKEN_DECIMALS)); //10,000,000,000 aka 10 billion
    uint256 public constant TOKENS_SALE                             = 5000000000 * DECIMALSFACTOR; //50%
    uint256 public constant TOKENS_DISTRIBUTED                      = 5000000000 * DECIMALSFACTOR; //50%


    // For the public sale, tokens are priced at 0.006 USD/token.
    // So if we have 450 USD/ETH -> 450,000 USD/KETH / 0.006 USD/token = ~75000000
                                                                    //    3600000
    uint256 public constant TOKENS_PER_KETHER                       = 75000000;

    // Constant used by buyTokens as part of the cost <-> tokens conversion.
    // 18 for ETH -> WEI, TOKEN_DECIMALS (18 for JSE Coin Token), 3 for the K in tokensPerKEther.
    uint256 public constant PURCHASE_DIVIDER                        = 10**(uint256(18) - TOKEN_DECIMALS + 3);

}

// File: contracts/ERC223.sol

/**
 * @title Interface for an ERC223 Contract
 * @author Amr Gawish <amr@gawi.sh>
 * @dev Only one method is unique to contracts `transfer(address _to, uint _value, bytes _data)`
 * @notice The interface has been stripped to its unique methods to prevent duplicating methods with ERC20 interface
*/
interface ERC223 {
    function transfer(address _to, uint _value, bytes _data) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

// File: contracts/ERC223ReceivingContract.sol

/**
 * @title Contract that will work with ERC223 tokens.
 */
 
contract ERC223ReceivingContract { 

    /**
    * @dev Standard ERC223 function that will handle incoming token transfers.
    *
    * @param _from  Token sender address.
    * @param _value Amount of tokens.
    * @param _data  Transaction metadata.
    */
    function tokenFallback(address _from, uint _value, bytes _data) public;
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

// File: contracts/OperatorManaged.sol

// Simple JSE Operator management contract
contract OperatorManaged is Ownable {

    address public operatorAddress;
    address public adminAddress;

    event AdminAddressChanged(address indexed _newAddress);
    event OperatorAddressChanged(address indexed _newAddress);


    constructor() public
        Ownable()
    {
        adminAddress = msg.sender;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }


    modifier onlyAdminOrOperator() {
        require(isAdmin(msg.sender) || isOperator(msg.sender));
        _;
    }


    modifier onlyOwnerOrAdmin() {
        require(isOwner(msg.sender) || isAdmin(msg.sender));
        _;
    }


    modifier onlyOperator() {
        require(isOperator(msg.sender));
        _;
    }


    function isAdmin(address _address) internal view returns (bool) {
        return (adminAddress != address(0) && _address == adminAddress);
    }


    function isOperator(address _address) internal view returns (bool) {
        return (operatorAddress != address(0) && _address == operatorAddress);
    }

    function isOwner(address _address) internal view returns (bool) {
        return (owner != address(0) && _address == owner);
    }


    function isOwnerOrOperator(address _address) internal view returns (bool) {
        return (isOwner(_address) || isOperator(_address));
    }


    // Owner and Admin can change the admin address. Address can also be set to 0 to &#39;disable&#39; it.
    function setAdminAddress(address _adminAddress) external onlyOwnerOrAdmin returns (bool) {
        require(_adminAddress != owner);
        require(_adminAddress != address(this));
        require(!isOperator(_adminAddress));

        adminAddress = _adminAddress;

        emit AdminAddressChanged(_adminAddress);

        return true;
    }


    // Owner and Admin can change the operations address. Address can also be set to 0 to &#39;disable&#39; it.
    function setOperatorAddress(address _operatorAddress) external onlyOwnerOrAdmin returns (bool) {
        require(_operatorAddress != owner);
        require(_operatorAddress != address(this));
        require(!isAdmin(_operatorAddress));

        operatorAddress = _operatorAddress;

        emit OperatorAddressChanged(_operatorAddress);

        return true;
    }
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
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
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
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
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
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
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
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: openzeppelin-solidity/contracts/token/ERC20//MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
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
    hasMintPermission
    canMint
    public
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
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
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

// File: contracts/JSEToken.sol

/**
 * @title Main Token Contract for JSE Coin
 * @author Amr Gawish <amr@gawi.sh>
 * @dev This Token is the Mintable and Burnable to allow variety of actions to be done by users.
 * @dev It also complies with both ERC20 and ERC223.
 * @notice Trying to use JSE Token to Contracts that doesn&#39;t accept tokens and doesn&#39;t have tokenFallback function will fail, and all contracts
 * must comply to ERC223 compliance. 
*/
contract JSEToken is ERC223, BurnableToken, Ownable, MintableToken, OperatorManaged {
    
    event Finalized();

    string public name = "JSE Token";
    string public symbol = "JSE";
    uint public decimals = 18;
    uint public initialSupply = 10000000000 * (10 ** decimals); //10,000,000,000 aka 10 billion

    bool public finalized;

    constructor() OperatorManaged() public {
        totalSupply_ = initialSupply;
        balances[msg.sender] = initialSupply; 

        emit Transfer(0x0, msg.sender, initialSupply);
    }


    // Implementation of the standard transferFrom method that takes into account the finalize flag.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        checkTransferAllowed(msg.sender, _to);

        return super.transferFrom(_from, _to, _value);
    }

    function checkTransferAllowed(address _sender, address _to) private view {
        if (finalized) {
            // Everybody should be ok to transfer once the token is finalized.
            return;
        }

        // Owner and Ops are allowed to transfer tokens before the sale is finalized.
        // This allows the tokens to move from the TokenSale contract to a beneficiary.
        // We also allow someone to send tokens back to the owner. This is useful among other
        // cases, for the Trustee to transfer unlocked tokens back to the owner (reclaimTokens).
        require(isOwnerOrOperator(_sender) || _to == owner);
    }

    // Implementation of the standard transfer method that takes into account the finalize flag.
    function transfer(address _to, uint256 _value) public returns (bool success) {
        checkTransferAllowed(msg.sender, _to);

        return super.transfer(_to, _value);
    }

    /**
    * @dev transfer token for a specified contract address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @param _data Additional Data sent to the contract.
    */
    function transfer(address _to, uint _value, bytes _data) external returns (bool) {
        checkTransferAllowed(msg.sender, _to);

        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(isContract(_to));


        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        ERC223ReceivingContract erc223Contract = ERC223ReceivingContract(_to);
        erc223Contract.tokenFallback(msg.sender, _value, _data);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /** 
    * @dev Owner can transfer out any accidentally sent ERC20 tokens
    */
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }

    function isContract(address _addr) private view returns (bool) {
        uint codeSize;
        /* solium-disable-next-line */
        assembly {
            codeSize := extcodesize(_addr)
        }
        return codeSize > 0;
    }

    // Finalize method marks the point where token transfers are finally allowed for everybody.
    function finalize() external onlyAdmin returns (bool success) {
        require(!finalized);

        finalized = true;

        emit Finalized();

        return true;
    }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/JSETokenSale.sol

//
// Implementation of the token sale of JSE Token
//
// * Lifecycle *
// Initialization sequence should be as follow:
//    1. Deploy JSEToken contract
//    2. Deploy JSETokenSale contract
//    3. Set operationsAddress of JSEToken contract to JSETokenSale contract
//    4. Transfer tokens from owner to JSETokenSale contract
//    5. Transfer tokens from owner to Distributer Account
//    6. Initialize JSETokenSale contract
//
// Pre-sale sequence:
//    - Set tokensPerKEther
//    - Update whitelist
//    - Start public sale
//
// After-sale sequence:
//    1. Finalize the JSETokenSale contract
//    2. Finalize the JSEToken contract
//    3. Set operationsAddress of JSETokenSale contract to 0
//    4. Set operationsAddress of JSEToken contract to 0


contract JSETokenSale is OperatorManaged, Pausable, JSECoinCrowdsaleConfig { // Pausable is also Owned

    using SafeMath for uint256;


    // We keep track of whether the sale has been finalized, at which point
    // no additional contributions will be permitted.
    bool public finalized;

    // Public Sales start trigger
    bool public publicSaleStarted;

    // Number of tokens per 1000 ETH. See JSETokenSaleConfig for details.
    uint256 public tokensPerKEther;

    // Increase Percentage Bonus of buying tokens
    uint256 public bonusIncreasePercentage = 10; //percentage

    // Address where the funds collected during the sale will be forwarded.
    address public wallet;

    // Token contract that the sale contract will interact with.
    JSEToken public tokenContract;

    // // JSETrustee contract to hold on token balances. The following token pools will be held by trustee:
    // //    - Founders
    // //    - Advisors
    // //    - Early investors
    // //    - Presales
    // address private distributerAccount;

    // Total amount of tokens sold during presale + public sale. Excludes pre-sale bonuses.
    uint256 public totalTokensSold;

    // Total amount of tokens given as bonus during presale. Will influence accelerator token balance.
    uint256 public totalPresaleBase;
    uint256 public totalPresaleBonus;

    // Map of addresses that have been whitelisted in advance (and passed KYC).
    mapping(address => bool) public whitelist;

    // Amount of wei raised
    uint256 public weiRaised;

    //
    // EVENTS
    //
    event Initialized();
    event PresaleAdded(address indexed _account, uint256 _baseTokens, uint256 _bonusTokens);
    event WhitelistUpdated(address indexed _account);
    event TokensPurchased(address indexed _beneficiary, uint256 _cost, uint256 _tokens, uint256 _totalSold);
    event TokensPerKEtherUpdated(uint256 _amount);
    event WalletChanged(address _newWallet);
    event TokensReclaimed(uint256 _amount);
    event UnsoldTokensBurnt(uint256 _amount);
    event BonusIncreasePercentageChanged(uint256 _oldPercentage, uint256 _newPercentage);
    event Finalized();


    constructor(JSEToken _tokenContract, address _wallet) public
        OperatorManaged()
    {
        require(address(_tokenContract) != address(0));
        //  require(address(_distributerAccount) != address(0));
        require(_wallet != address(0));

        require(TOKENS_PER_KETHER > 0);


        wallet                  = _wallet;
        finalized               = false;
        publicSaleStarted       = false;
        tokensPerKEther         = TOKENS_PER_KETHER;
        tokenContract           = _tokenContract;
        //distributerAccount      = _distributerAccount;
    }


    // Initialize is called to check some configuration parameters.
    // It expects that a certain amount of tokens have already been assigned to the sale contract address.
    function initialize() external onlyOwner returns (bool) {
        require(totalTokensSold == 0);
        require(totalPresaleBase == 0);
        require(totalPresaleBonus == 0);

        uint256 ownBalance = tokenContract.balanceOf(address(this));
        require(ownBalance == TOKENS_SALE);

        emit Initialized();

        return true;
    }


    // Allows the admin to change the wallet where ETH contributions are sent.
    function changeWallet(address _wallet) external onlyAdmin returns (bool) {
        require(_wallet != address(0));
        require(_wallet != address(this));
        // require(_wallet != address(distributerAccount));
        require(_wallet != address(tokenContract));

        wallet = _wallet;

        emit WalletChanged(wallet);

        return true;
    }



    //
    // TIME
    //

    function currentTime() public view returns (uint256 _currentTime) {
        return now;
    }


    modifier onlyBeforeSale() {
        require(hasSaleEnded() == false && publicSaleStarted == false);
        _;
    }


    modifier onlyDuringSale() {
        require(hasSaleEnded() == false && publicSaleStarted == true);
        _;
    }

    modifier onlyAfterSale() {
        // require finalized is stronger than hasSaleEnded
        require(finalized);
        _;
    }


    function hasSaleEnded() private view returns (bool) {
        // if sold out or finalized, sale has ended
        if (finalized) {
            return true;
        } else {
            return false;
        }
    }



    //
    // WHITELIST
    //

    // Allows operator to add accounts to the whitelist.
    // Only those accounts will be allowed to contribute above the threshold
    function updateWhitelist(address _account) external onlyAdminOrOperator returns (bool) {
        require(_account != address(0));
        require(!hasSaleEnded());

        whitelist[_account] = true;

        emit WhitelistUpdated(_account);

        return true;
    }

    //
    // PURCHASES / CONTRIBUTIONS
    //

    // Allows the admin to set the price for tokens sold during phases 1 and 2 of the sale.
    function setTokensPerKEther(uint256 _tokensPerKEther) external onlyAdmin onlyBeforeSale returns (bool) {
        require(_tokensPerKEther > 0);

        tokensPerKEther = _tokensPerKEther;

        emit TokensPerKEtherUpdated(_tokensPerKEther);

        return true;
    }


    function () external payable whenNotPaused onlyDuringSale {
        buyTokens();
    }


    // This is the main function to process incoming ETH contributions.
    function buyTokens() public payable whenNotPaused onlyDuringSale returns (bool) {
        require(msg.value >= CONTRIBUTION_MIN);
        require(msg.value <= CONTRIBUTION_MAX);
        require(totalTokensSold < TOKENS_SALE);

        // All accounts need to be whitelisted to purchase if the value above the CONTRIBUTION_MAX_NO_WHITELIST
        bool whitelisted = whitelist[msg.sender];
        if(msg.value >= CONTRIBUTION_MAX_NO_WHITELIST){
            require(whitelisted);
        }

        uint256 tokensMax = TOKENS_SALE.sub(totalTokensSold);

        require(tokensMax > 0);
        
        uint256 actualAmount = msg.value.mul(tokensPerKEther).div(PURCHASE_DIVIDER);

        uint256 bonusAmount = actualAmount.mul(bonusIncreasePercentage).div(100);

        uint256 tokensBought = actualAmount.add(bonusAmount);

        require(tokensBought > 0);

        uint256 cost = msg.value;
        uint256 refund = 0;

        if (tokensBought > tokensMax) {
            // Not enough tokens available for full contribution, we will do partial.
            tokensBought = tokensMax;

            // Calculate actual cost for partial amount of tokens.
            cost = tokensBought.mul(PURCHASE_DIVIDER).div(tokensPerKEther);

            // Calculate refund for contributor.
            refund = msg.value.sub(cost);
        }

        totalTokensSold = totalTokensSold.add(tokensBought);

        // Transfer tokens to the account
        require(tokenContract.transfer(msg.sender, tokensBought));

        // Issue a ETH refund for any unused portion of the funds.
        if (refund > 0) {
            msg.sender.transfer(refund);
        }

        // update state
        weiRaised = weiRaised.add(msg.value.sub(refund));

        // Transfer the contribution to the wallet
        wallet.transfer(msg.value.sub(refund));

        emit TokensPurchased(msg.sender, cost, tokensBought, totalTokensSold);

        // If all tokens available for sale have been sold out, finalize the sale automatically.
        if (totalTokensSold == TOKENS_SALE) {
            finalizeInternal();
        }

        return true;
    }



    // Allows the admin to move bonus tokens still available in the sale contract
    // out before burning all remaining unsold tokens in burnUnsoldTokens().
    // Used to distribute bonuses to token sale participants when the sale has ended
    // and all bonuses are known.
    function reclaimTokens(uint256 _amount) external onlyAfterSale onlyAdmin returns (bool) {
        uint256 ownBalance = tokenContract.balanceOf(address(this));
        require(_amount <= ownBalance);
        
        address tokenOwner = tokenContract.owner();
        require(tokenOwner != address(0));

        require(tokenContract.transfer(tokenOwner, _amount));

        emit TokensReclaimed(_amount);

        return true;
    }

    function changeBonusIncreasePercentage(uint256 _newPercentage) external onlyDuringSale onlyAdmin returns (bool) {
        uint oldPercentage = bonusIncreasePercentage;
        bonusIncreasePercentage = _newPercentage;
        emit BonusIncreasePercentageChanged(oldPercentage, _newPercentage);
        return true;
    }

    // Allows the admin to finalize the sale and complete allocations.
    // The JSEToken.admin also needs to finalize the token contract
    // so that token transfers are enabled.
    function finalize() external onlyAdmin returns (bool) {
        return finalizeInternal();
    }

    function startPublicSale() external onlyAdmin onlyBeforeSale returns (bool) {
        publicSaleStarted = true;
        return true;
    }


    // The internal one will be called if tokens are sold out or
    // the end time for the sale is reached, in addition to being called
    // from the public version of finalize().
    function finalizeInternal() private returns (bool) {
        require(!finalized);

        finalized = true;

        emit Finalized();

        return true;
    }
}