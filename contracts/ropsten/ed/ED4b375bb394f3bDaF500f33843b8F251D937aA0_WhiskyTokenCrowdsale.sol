pragma solidity ^0.4.24;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title Operated
 * @dev The Operated contract has a list of ops addresses, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Operated {
    mapping(address => bool) private _ops;

    event OperatorChanged(
        address indexed operator,
        bool active
    );

    /**
     * @dev The Operated constructor sets the original ops account of the contract to the sender
     * account.
     */
    constructor() internal {
        _ops[msg.sender] = true;
        emit OperatorChanged(msg.sender, true);
    }

    /**
     * @dev Throws if called by any account other than the operations accounts.
     */
    modifier onlyOps() {
        require(isOps(), "only operations accounts are allowed to call this function");
        _;
    }

    /**
     * @return true if `msg.sender` is an operator.
     */
    function isOps() public view returns(bool) {
        return _ops[msg.sender];
    }

    /**
     * @dev Allows the current operations accounts to give control of the contract to new accounts.
     * @param _account The address of the new account
     * @param _active Set active (true) or inactive (false)
     */
    function setOps(address _account, bool _active) public onlyOps {
        _ops[_account] = _active;
        emit OperatorChanged(msg.sender, true);
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns(address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @author https://github.com/hunterlong/fiatcontractd
 */
contract FiatContract {
    function ETH(uint _id) public view returns (uint256);
    function USD(uint _id) public view returns (uint256);
    function EUR(uint _id) public view returns (uint256);
    function GBP(uint _id) public view returns (uint256);
    function updatedAt(uint _id) public view returns (uint);
}

contract FiatContractMock is FiatContract {

    uint256 private price;
    uint256 private createdAt;

    constructor() public {
        // price = 1 szabo;
        //price = 21150592216582; // 475€ as 0.01€ in WEI
        price = 10000000000; // 1 ETH = 1.000.000 EUR
        createdAt = now;
    }

    function setPrice(uint256 _price) public {
        require(_price > 0);
        price = _price;
    }

    function ETH(uint _id) public view returns (uint256) {
        require(_id == 0); // to support only ETH
        return 1 ether;
    }

    function EUR(uint _id) public view returns (uint256) {
        require(_id == 0); // to support only ETH
        return price; 
    }

    function USD(uint _id) public view returns (uint256) {
        require(_id == 0); // to support only ETH
        return price; 
    }

    function GBP(uint _id) public view returns (uint256) {
        require(_id == 0); // to support only ETH
        return price; 
    }

    function updatedAt(uint _id) public view returns (uint) {
        require(_id == 0); // to support only ETH
        return createdAt;
    }

}

/**
 * @title WHISKY TOKEN
 * @author WHYTOKEN GmbH
 * @notice WHISKY TOKEN (WHY) stands for a disruptive new possibility in the crypto currency market
 * due to the combination of High-End Whisky and Blockchain technology.
 * WHY is a german based token, which lets everyone participate in the lucrative crypto market
 * with minimal risk and effort through a high-end whisky portfolio as security.
 */
contract WhiskyToken is IERC20, Ownable, Operated {
    using SafeMath for uint256;
    using SafeMath for uint64;

    // ERC20 standard variables
    string public name = "Whisky Token";
    string public symbol = "WHY";
    uint8 public decimals = 18;
    uint256 public initialSupply = 28100000 * (10 ** uint256(decimals));
    uint256 public totalSupply;

    // Address of the ICO contract
    address public crowdSaleContract;

    // The asset value of the whisky in EUR cents
    uint64 public assetValue;

    // Fee to charge on every transfer (e.g. 15 is 1,5%)
    uint64 public feeCharge;

    // Global freeze of all transfers
    bool public freezeTransfer;

    // Flag to make all token available
    bool private tokenAvailable;

    // Maximum value for feeCharge
    uint64 private constant feeChargeMax = 20;

    // Address of the account/wallet which should receive the fees
    address private feeReceiver;

    // Mappings of addresses for balances, allowances and frozen accounts
    mapping(address => uint256) internal balances;
    mapping(address => mapping (address => uint256)) internal allowed;
    mapping(address => bool) public frozenAccount;

    // Event definitions
    event Fee(address indexed payer, uint256 fee);
    event FeeCharge(uint64 oldValue, uint64 newValue);
    event AssetValue(uint64 oldValue, uint64 newValue);
    event Burn(address indexed burner, uint256 value);
    event FrozenFunds(address indexed target, bool frozen);
    event FreezeTransfer(bool frozen);

    // Constructor which gets called once on contract deployment
    constructor(address _tokenOwner) public {
        transferOwnership(_tokenOwner);
        setOps(_tokenOwner, true);
        crowdSaleContract = msg.sender;
        feeReceiver = msg.sender;
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
        assetValue = 0;
        feeCharge = 15;
        freezeTransfer = true;
        tokenAvailable = false;
    }

    /**
     * @notice Returns the total supply of tokens.
     * @dev The total supply is the amount of tokens which are currently in circulation.
     * @return Amount of tokens in Sip.
     */
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    /**
     * @notice Gets the balance of the specified address.
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount of tokens owned by the passed address.
     */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        if (!tokenAvailable) {
            return 0;
        }
        return balances[_owner];
    }

    /**
     * @dev Internal transfer, can only be called by this contract.
     * Will throw an exception to rollback the transaction if anything is wrong.
     * @param _from The address from which the tokens should be transfered from.
     * @param _to The address to which the tokens should be transfered to.
     * @param _value The amount of tokens which should be transfered in Sip.
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "zero address is not allowed");
        require(_value >= 1000, "must transfer more than 1000 sip");
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(!frozenAccount[_from], "sender address is frozen");
        require(!frozenAccount[_to], "receiver address is frozen");

        uint256 transferValue = _value;
        if (msg.sender != owner() && msg.sender != crowdSaleContract) {
            uint256 fee = _value.div(1000).mul(feeCharge);
            transferValue = _value.sub(fee);
            balances[feeReceiver] = balances[feeReceiver].add(fee);
            emit Fee(msg.sender, fee);
        }

        // SafeMath.sub will throw if there is not enough balance.
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(transferValue);
        if (tokenAvailable) {
            emit Transfer(_from, _to, transferValue);
        }
    }

    /**
     * @notice Transfer tokens to a specified address. The message sender has to pay the fee.
     * @dev Calls _transfer with message sender address as _from parameter.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred in Sip.
     * @return Indicates if the transfer was successful.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @notice Transfer tokens from one address to another. The message sender has to pay the fee.
     * @dev Calls _transfer with the addresses provided by the transactor.
     * @param _from The address which you want to send tokens from.
     * @param _to The address which you want to transfer to.
     * @param _value The amount of tokens to be transferred in Sip.
     * @return Indicates if the transfer was successful.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender], "requesting more token than allowed");

        _transfer(_from, _to, _value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return true;
    }

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of the transactor.
     * @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which is allowed to retrieve the tokens.
     * @param _value The amount of tokens to be spent in Sip.
     * @return Indicates if the approval was successful.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(_spender != address(0), "zero address is not allowed");
        require(_value >= 1000, "must approve more than 1000 sip");

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @notice Returns the amount of tokens that the owner allowed to the spender.
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner The address which owns the tokens.
     * @param _spender The address which is allowed to retrieve the tokens.
     * @return The amount of tokens still available for the spender in Sip.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @notice Increase the amount of tokens that an owner allowed to a spender.
     * @dev Approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which is allowed to retrieve the tokens.
     * @param _addedValue The amount of tokens to increase the allowance by in Sip.
     * @return Indicates if the approval was successful.
     */
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(_spender != address(0), "zero address is not allowed");
        require(_addedValue >= 1000, "must approve more than 1000 sip");
        
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @notice Decrease the amount of tokens that an owner allowed to a spender. 
     * @dev Approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which is allowed to retrieve the tokens.
     * @param _subtractedValue The amount of tokens to decrease the allowance by in Sip.
     * @return Indicates if the approval was successful.
     */
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(_spender != address(0), "zero address is not allowed");
        require(_subtractedValue >= 1000, "must approve more than 1000 sip");

        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    } 

    /**
     * @notice Burns a specific amount of tokens.
     * @dev Tokens get technically destroyed by this function and are therefore no longer in circulation afterwards.
     * @param _value The amount of token to be burned in Sip.
     */
    function burn(uint256 _value) public {
        require(!freezeTransfer || isOps(), "all transfers are currently frozen");
        require(_value <= balances[msg.sender], "address has not enough token to burn");
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }

    /**
     * @notice Not for public use!
     * @dev Modifies the assetValue which represents the monetized value (in EUR) of the whisky baking the token.
     * @param _value The new value of the asset in EUR cents.
     */
    function setAssetValue(uint64 _value) public onlyOwner {
        uint64 oldValue = assetValue;
        assetValue = _value;
        emit AssetValue(oldValue, _value);
    }

    /**
     * @notice Not for public use!
     * @dev Modifies the feeCharge which calculates the fee for each transaction.
     * @param _value The new value of the feeCharge as fraction of 1000 (e.g. 15 is 1,5%).
     */
    function setFeeCharge(uint64 _value) public onlyOwner {
        require(_value <= feeChargeMax, "can not increase fee charge over it&#39;s limit");
        uint64 oldValue = feeCharge;
        feeCharge = _value;
        emit FeeCharge(oldValue, _value);
    }


    /**
     * @notice Not for public use!
     * @dev Prevents/Allows target from sending & receiving tokens.
     * @param _target Address to be frozen.
     * @param _freeze Either to freeze or unfreeze it.
     */
    function freezeAccount(address _target, bool _freeze) public onlyOwner {
        require(_target != address(0), "zero address is not allowed");

        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }

    /**
     * @notice Not for public use!
     * @dev Globally freeze all transfers for the token.
     * @param _freeze Freeze or unfreeze every transfer.
     */
    function setFreezeTransfer(bool _freeze) public onlyOwner {
        freezeTransfer = _freeze;
        emit FreezeTransfer(_freeze);
    }

    /**
     * @notice Not for public use!
     * @dev Allows the owner to set the address which receives the fees.
     * @param _feeReceiver the address which should receive fees.
     */
    function setFeeReceiver(address _feeReceiver) public onlyOwner {
        require(_feeReceiver != address(0), "zero address is not allowed");
        feeReceiver = _feeReceiver;
    }

    /**
     * @notice Not for public use!
     * @dev Make all tokens available for ERC20 wallets.
     * @param _available Activate or deactivate all tokens
     */
    function setTokenAvailable(bool _available) public onlyOwner {
        tokenAvailable = _available;
    }
}

/**
 * @title WHISKY TOKEN ICO
 * @author WHYTOKEN GmbH
 * @notice WHISKY TOKEN (WHY) stands for a disruptive new possibility in the crypto currency market
 * due to the combination of High-End Whisky and Blockchain technology.
 * WHY is a german based token, which lets everyone participate in the lucrative crypto market
 * with minimal risk and effort through a high-end whisky portfolio as security.
 */
contract WhiskyTokenCrowdsale is Ownable, Operated {
    using SafeMath for uint256;
    using SafeMath for uint64;

    // Address of the beneficiary which will receive the raised ETH 
    // Initialized during deployment
    address public beneficiary;

    // Deadline of the ICO as epoch time
    // Initialized when entering the first phase
    uint256 public deadline;

    // Amount raised by the ICO in Ether
    // Initialized during deployment
    uint256 public amountRaisedETH;

    // Amount raised by the ICO in Euro
    // Initialized during deployment
    uint256 public amountRaisedEUR;

    // Amount of tokens sold in Sip
    // Initialized during deployment
    uint256 public tokenSold;

    // Indicator if the funding goal has been reached
    // Initialized during deployment
    bool public fundingGoalReached;

    // Indicator if the ICO already closed
    // Initialized during deployment
    bool public crowdsaleClosed;

    // Internal indicator if we have checked our goals at the end of the ICO
    // Initialized during deployment
    bool private goalChecked;

    // Instance of our deployed Whisky Token
    // Initialized during deployment
    WhiskyToken public tokenReward;

    // Instance of the FIAT contract we use for ETH/EUR conversion
    // Initialized during deployment
    FiatContract public fiat;

    // Amount of Euro cents we need to reach for the softcap
    // 2.000.000 EUR
    uint256 private minTokenSellInEuroCents = 200000000;

    // Minimum amount of Euro cents you need to pay per transaction
    // 30 EUR    
    uint256 private minTokenBuyEuroCents = 3000;

    // Minimum amount of tokens (in Sip) which are sold at the softcap
    // 2.583.333 token
    uint256 private minTokenSell = 2583333 * 1 ether;

    // Maximum amount of tokens (in Sip) which are sold at the hardcap
    // 25.250.000 tokens
    uint256 private maxTokenSell = 25250000 * 1 ether;

    // Minimum amount of tokens (in Sip) which the beneficiary will receive
    // for the founders at the softcap
    // 308.627 tokens
    uint256 private minFounderToken = 308627 * 1 ether;

    // Maximum amount of tokens (in Sip) which the beneficiary will receive
    // for the founders at the hardcap
    // 1.405.000 tokens
    uint256 private maxFounderToken = 1405000 * 1 ether;

    // Minimum amount of tokens (in Sip) which the beneficiary will receive
    // for Research & Development and the Advisors after the ICO
    // 154.313 tokens
    uint256 private minRDAToken = 154313 * 1 ether;

    // Maximum amount of tokens (in Sip) which the beneficiary will receive
    // for Research & Development and the Advisors after the ICO
    // 1.405.000 tokens
    uint256 private maxRDAToken = 1405000 * 1 ether;

    // Amount of tokens (in Sip) which a customer will receive as bounty
    // 5 tokens
    uint256 private bountyTokenPerPerson = 5 * 1 ether;

    // Maximum amount of tokens (in Sip) which are available for bounty
    // 40.000 tokens
    uint256 private maxBountyToken = 40000 * 1 ether;

    // Amount of tokens which are left for bounty
    // Initialized during deployment
    uint256 public tokenLeftForBounty;

    // The pre-sale phase of the ICO
    // 333.333 tokens for 60 cent/token
    Phase private preSalePhase = Phase({
        id: PhaseID.PreSale,
        tokenPrice: 60,
        tokenForSale: 333333 * 1 ether,
        tokenLeft: 333333 * 1 ether
    });

    // The first public sale phase of the ICO
    // 2.250.000 tokens for 80 cent/token
    Phase private firstPhase = Phase({
        id: PhaseID.First,
        tokenPrice: 80,
        tokenForSale: 2250000 * 1 ether,
        tokenLeft: 2250000 * 1 ether
    });

    // The second public sale phase of the ICO
    // 21.000.000 tokens for 100 cent/token
    Phase private secondPhase = Phase({
        id: PhaseID.Second,
        tokenPrice: 100,
        tokenForSale: 21000000 * 1 ether,
        tokenLeft: 21000000 * 1 ether
    });

    // The third public sale phase of the ICO
    // 1.666.667 tokens for 120 cent/token
    Phase private thirdPhase = Phase({
        id: PhaseID.Third,
        tokenPrice: 120,
        tokenForSale: 1666667 * 1 ether,
        tokenLeft: 1666667 * 1 ether
    });

    // The closed phase of the ICO
    // No token for sell
    Phase private closedPhase = Phase({
        id: PhaseID.Closed,
        tokenPrice: ~uint64(0),
        tokenForSale: 0,
        tokenLeft: 0
    });

    // Points to the current phase
    Phase public currentPhase;

    // Structure for the phases
    // Consists of an id, the tokenPrice and the amount
    // of tokens available and left for sale
    struct Phase {
        PhaseID id;
        uint64 tokenPrice;
        uint256 tokenForSale;
        uint256 tokenLeft;
    }

    // Enumeration for identification of the phases
    enum PhaseID {
        PreSale,        // 0 
        First,          // 1
        Second,         // 2
        Third,          // 3
        Closed          // 4
    }    

    // Mapping of an address to a customer
    mapping(address => Customer) public customer;

    // Structure representing a customer
    // Consists of a rating, the amount of Ether and Euro the customer raised,
    // and a boolean indicating if he/she has already received a bounty
    struct Customer {
        Rating rating;
        uint256 amountRaisedEther;
        uint256 amountRaisedEuro;
        uint256 amountReceivedWhiskyToken;
        bool hasReceivedBounty;
    }

    // Enumeration for identification of a rating for a customer
    enum Rating {
        Unlisted,       // 0: No known customer, can&#39;t buy any token
        Whitelisted     // 1: Known customer by personal data, allowed to buy token
    }

    // Event definitions
    event SaleClosed();
    event GoalReached(address recipient, uint256 tokensSold, uint256 totalAmountRaised);
    event WhitelistUpdated(address indexed _account, uint8 _phase);
    event PhaseEntered(PhaseID phaseID);
    event TokenSold(address indexed customer, uint256 amount);
    event BountyTransfer(address indexed customer, uint256 amount);
    event FounderTokenTransfer(address recipient, uint256 amount);
    event RDATokenTransfer(address recipient, uint256 amount);
    event FundsWithdrawal(address indexed recipient, uint256 amount);

    // Constructor which gets called once on contract deployment
    constructor() public {
        setOps(msg.sender, true);
        beneficiary = msg.sender;
        tokenReward = new WhiskyToken(msg.sender);
        // fiat = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591); // Main
        // fiat = FiatContract(0x2CDe56E5c8235D6360CCbb0c57Ce248Ca9C80909); // Ropsten
        fiat = new FiatContractMock();  // Rinkeby and in-memory
        currentPhase = preSalePhase;
        fundingGoalReached = false;
        crowdsaleClosed = false;
        goalChecked = false;
        tokenLeftForBounty = maxBountyToken;
        tokenReward.transfer(msg.sender, currentPhase.tokenForSale);
        currentPhase.tokenLeft = 0;
        tokenSold += currentPhase.tokenForSale;
        amountRaisedEUR = amountRaisedEUR.add((currentPhase.tokenForSale.div(1 ether)).mul(currentPhase.tokenPrice));
    }

    /**
     * @notice Not for public use!
     * @dev Advances the crowdsale to the next phase.
     */
    function nextPhase() public onlyOwner {
        require(currentPhase.id != PhaseID.Closed, "already reached the closed phase");

        uint8 nextPhaseNum = uint8(currentPhase.id) + 1;

        if (PhaseID(nextPhaseNum) == PhaseID.First) {
            currentPhase = firstPhase;
            deadline = now + 365 * 1 days;
        }
        if (PhaseID(nextPhaseNum) == PhaseID.Second) {
            currentPhase = secondPhase;
        }
        if (PhaseID(nextPhaseNum) == PhaseID.Third) {
            currentPhase = thirdPhase;
        }
        if (PhaseID(nextPhaseNum) == PhaseID.Closed) {
            currentPhase = closedPhase;
        }

        emit PhaseEntered(currentPhase.id);
    }

    /**
     * @notice Not for public use!
     * @dev Set the rating of a customer by address.
     * @param _account The address of the customer you want to change the rating of.
     * @param _phase The rating as an uint:
     * 0 => Unlisted
     * 1 => Whitelisted
     */
    function updateWhitelist(address _account, uint8 _phase) external onlyOps returns (bool) {
        require(_account != address(0), "zero address is not allowed");
        require(_phase == uint8(Rating.Unlisted) || _phase == uint8(Rating.Whitelisted), "invalid rating");

        Rating rating = Rating(_phase);
        customer[_account].rating = rating;
        emit WhitelistUpdated(_account, _phase);

        if (rating > Rating.Unlisted && !customer[_account].hasReceivedBounty && tokenLeftForBounty > 0) {
            customer[_account].hasReceivedBounty = true;
            customer[_account].amountReceivedWhiskyToken = customer[_account].amountReceivedWhiskyToken.add(bountyTokenPerPerson);
            tokenLeftForBounty = tokenLeftForBounty.sub(bountyTokenPerPerson);
            tokenReward.transfer(_account, bountyTokenPerPerson);
            emit BountyTransfer(_account, bountyTokenPerPerson);
        }

        return true;
    }

    /**
     * @dev Checks if the deadline is reached or the crowdsale has been closed.
     */
    modifier afterDeadline() {
        if ((now >= deadline && currentPhase.id >= PhaseID.First) || currentPhase.id == PhaseID.Closed) {
            _;
        }
    }

    /**
     * @notice Check if the funding goal was reached.
     * Can only be called after the deadline or if the crowdsale has been closed.
     * @dev Checks if the goal or time limit has been reached and ends the campaign.
     * Should be directly called after the ICO.
     */
    function checkGoalReached() public afterDeadline {
        if (!goalChecked) {
            if (_checkFundingGoalReached()) {
                emit GoalReached(beneficiary, tokenSold, amountRaisedETH);
            }
            if (!crowdsaleClosed) {
                crowdsaleClosed = true;
                emit SaleClosed();
            }
            goalChecked = true;
        }
    }

    /**
     * @dev Internal function for checking if we reached our funding goal.
     * @return Indicates if the funding goal has been reached.
     */
    function _checkFundingGoalReached() internal returns (bool) {
        if (!fundingGoalReached) {
            if (amountRaisedEUR >= minTokenSellInEuroCents) {
                fundingGoalReached = true;
            }
        }
        return fundingGoalReached;
    }

    /**
     * @dev Fallback function
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () external payable {
        _buyToken(msg.sender);
    }

    /**
     * @notice Buy tokens for ether. You can also just send ether to the contract to buy tokens.
     * Your address needs to be whitelisted first.
     * @dev Allows the caller to buy token for his address.
     * Implemented for the case that other contracts want to buy tokens.
     */
    function buyToken() external payable {
        _buyToken(msg.sender);
    }

    /**
     * @notice Buy tokens for another address. The address still needs to be whitelisted.
     * @dev Allows the caller to buy token for a different address.
     * @param _receiver Address of the person who should receive the tokens.
     */
    function buyTokenForAddress(address _receiver) external payable {
        require(_receiver != address(0), "zero address is not allowed");
        _buyToken(_receiver);
    }

    /**
     * @notice Not for public use!
     * @dev Send tokens to receiver who has payed with FIAT or other currencies.
     * @param _receiver Address of the person who should receive the tokens.
     * @param _cent The amount of euro cents which the person has payed.
     */
    function buyTokenForAddressWithEuroCent(address _receiver, uint64 _cent) external onlyOps {
        require(!crowdsaleClosed, "crowdsale is closed");
        require(_receiver != address(0), "zero address is not allowed");
        require(currentPhase.id != PhaseID.PreSale, "not allowed to buy token in presale phase");
        require(currentPhase.id != PhaseID.Closed, "not allowed to buy token in closed phase");
        require(customer[_receiver].rating == Rating.Whitelisted, "address is not whitelisted");
        _sendTokenReward(_receiver, _cent);        
        _checkFundingGoalReached();
    }

    /**
     * @dev Internal function for buying token.
     * @param _receiver Address of the person who should receive the tokens.
     */
    function _buyToken(address _receiver) internal {
        require(!crowdsaleClosed, "crowdsale is closed");
        require(currentPhase.id != PhaseID.PreSale, "not allowed to buy token in presale phase");
        require(currentPhase.id != PhaseID.Closed, "not allowed to buy token in closed phase");
        require(customer[_receiver].rating == Rating.Whitelisted, "address is not whitelisted");
        _sendTokenReward(_receiver, 0);
        _checkFundingGoalReached();
    }

    /**
     * @dev Internal function for sending token as reward for ether.
     * @param _receiver Address of the person who should receive the tokens.
     */
    function _sendTokenReward(address _receiver, uint64 _cent) internal {
        // Remember the ETH amount of the message sender, not the token receiver!
        // We need this because if the softcap was not reached
        // the message sender should be able to retrive his ETH
        uint256 amountEuroCents;
        uint256 tokenAmount;
        if (msg.value > 0) {
            uint256 amount = msg.value;
            customer[msg.sender].amountRaisedEther = customer[msg.sender].amountRaisedEther.add(amount);
            amountRaisedETH = amountRaisedETH.add(amount);
            amountEuroCents = amount.div(fiat.EUR(0));
            tokenAmount = (amount.div(getTokenPrice())) * 1 ether;
        } else if (_cent > 0) {
            amountEuroCents = _cent;
            tokenAmount = (amountEuroCents.div(currentPhase.tokenPrice)) * 1 ether;
        } else {
            revert("this should never happen");
        }
        
        uint256 sumAmountEuroCents = customer[_receiver].amountRaisedEuro.add(amountEuroCents);
        customer[_receiver].amountRaisedEuro = sumAmountEuroCents;
        amountRaisedEUR = amountRaisedEUR.add(amountEuroCents);

        require(((tokenAmount / 1 ether) * currentPhase.tokenPrice) >= minTokenBuyEuroCents, "must buy token for at least 30 EUR");
        require(tokenAmount <= currentPhase.tokenLeft, "not enough token left in current phase");
        currentPhase.tokenLeft = currentPhase.tokenLeft.sub(tokenAmount);

        customer[_receiver].amountReceivedWhiskyToken = customer[_receiver].amountReceivedWhiskyToken.add(tokenAmount);
        tokenSold = tokenSold.add(tokenAmount);
        tokenReward.transfer(_receiver, tokenAmount);
        emit TokenSold(_receiver, tokenAmount);
    }

    /**
     * @notice Withdraw your funds if the ICO softcap has not been reached.
     * @dev Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
     * sends the entire ether amount to the beneficiary.
     * Also caluclates and sends the tokens for the founders, research & development and advisors.
     * All tokens which were not sold or send will be burned at the end.
     * If goal was not reached, each contributor can withdraw the amount they contributed.
     */
    function safeWithdrawal() public afterDeadline {
        require(crowdsaleClosed, "crowdsale must be closed");
        
        if (!fundingGoalReached) {
            // Let customers retrieve their ether
            require(customer[msg.sender].amountRaisedEther > 0, "message sender has not raised any ether to this contract");
            uint256 amount = customer[msg.sender].amountRaisedEther;
            customer[msg.sender].amountRaisedEther = 0;
            msg.sender.transfer(amount);
            emit FundsWithdrawal(msg.sender, amount);
        } else {
            // Let owner retrive current ether amount and founder token
            require(beneficiary == msg.sender, "message sender is not the beneficiary");
            uint256 ethAmount = address(this).balance;
            beneficiary.transfer(ethAmount);
            emit FundsWithdrawal(beneficiary, ethAmount);

            // Calculate and transfer founder token
            uint256 founderToken = (tokenSold - minTokenSell) * (maxFounderToken - minFounderToken) / (maxTokenSell - minTokenSell) + minFounderToken - (maxBountyToken - tokenLeftForBounty);
            require(tokenReward.transfer(beneficiary, founderToken), "founder token transfer failed");
            emit FounderTokenTransfer(beneficiary, founderToken);

            // Calculate and transfer research and advisor token
            uint256 rdaToken = (tokenSold - minTokenSell) * (maxRDAToken - minRDAToken) / (maxTokenSell - minTokenSell) + minRDAToken;
            require(tokenReward.transfer(beneficiary, rdaToken), "RDA token transfer failed");
            emit RDATokenTransfer(beneficiary, rdaToken);

            // Burn all leftovers
            tokenReward.burn(tokenReward.balanceOf(this));
        }
    }

    /**
     * @notice Not for public use!
     * @dev Allows early withdrawal of ether from the contract if the funding goal is reached.
     * Only the owner and beneficiary of the contract can call this function.
     * @param _amount The amount of ETH (in wei) which should be retreived.
     */
    function earlySafeWithdrawal(uint256 _amount) public onlyOwner {
        require(fundingGoalReached, "funding goal has not been reached");
        require(beneficiary == msg.sender, "message sender is not the beneficiary");
        require(address(this).balance >= _amount, "contract has less ether in balance than requested");

        beneficiary.transfer(_amount);
        emit FundsWithdrawal(beneficiary, _amount);
    }

    /**
     * @dev Internal function to calculate token price based on the ether price and current phase.
     */
    function getTokenPrice() internal view returns (uint256) {
        return getEtherInEuroCents() * currentPhase.tokenPrice / 100;
    }

    /**
     * @dev Internal function to calculate 1 EUR in WEI.
     */
    function getEtherInEuroCents() internal view returns (uint256) {
        return fiat.EUR(0) * 100;
    }

    /**
     * @notice Not for public use!
     * @dev Change the address of the fiat contract
     * @param _fiat The new address of the fiat contract
     */
    function setFiatContractAddress(address _fiat) public onlyOwner {
        require(_fiat != address(0), "zero address is not allowed");
        fiat = FiatContract(_fiat);
    }

    /**
     * @notice Not for public use!
     * @dev Change the address of the beneficiary
     * @param _beneficiary The new address of the beneficiary
     */
    function setBeneficiary(address _beneficiary) public onlyOwner {
        require(_beneficiary != address(0), "zero address is not allowed");
        beneficiary = _beneficiary;
    }
}