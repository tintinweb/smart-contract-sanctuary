pragma solidity ^0.4.18;

// zeppelin-solidity: 1.5.0

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

contract Object is StandardToken, Ownable {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    bool public mintingFinished = false;

    event Burn(address indexed burner, uint value);
    event Mint(address indexed to, uint amount);
    event MintFinished();

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function Object(string _name, string _symbol) public {
        name = _name;
        symbol = _symbol;
    }

    function burn(uint _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

    function mint(address _to, uint _amount) onlyOwner canMint public returns(bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

    function finishMinting() onlyOwner canMint public returns(bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(_value % (1 ether) == 0); // require whole token transfers

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
}

contract Shop is Ownable {
    using SafeMath for *;

    struct ShopSettings {
        address bank;
        uint32 startTime;
        uint32 endTime;
        uint fundsRaised;
        uint rate;
        uint price;
        //uint recommendedBid;
    }

    Object public object;
    ShopSettings public shopSettings;

    modifier onlyValidPurchase() {
        require(msg.value % shopSettings.price == 0); // whole numbers only
        require((now >= shopSettings.startTime && now <= shopSettings.endTime) && msg.value != 0);
        _;
    }

    modifier whenClosed() { // not actually implemented?
        require(now > shopSettings.endTime);
        _;
    }

    modifier whenOpen() {
        require(now < shopSettings.endTime);
        _;
    }

    modifier onlyValidAddress(address _bank) {
        require(_bank != address(0));
        _;
    }

    modifier onlyOne() {
        require(calculateTokens() == 1 ether);
        _;
    }

    modifier onlyBuyer(address _beneficiary) {
        require(_beneficiary == msg.sender);
        _;
    }

    event ShopClosed(uint32 date);
    event ObjectPurchase(address indexed purchaser, address indexed beneficiary, uint value, uint amount);

    function () external payable {
        buyObject(msg.sender);
    }

    function Shop(address _bank, string _name, string _symbol, uint _rate, uint32 _endTime)
    onlyValidAddress(_bank) public {
        require(_rate >= 0);
        require(_endTime > now);
        shopSettings = ShopSettings(_bank, uint32(now), _endTime, 0, _rate, 0);
        calculatePrice(); // set initial price based on initial rate
        object = new Object(_name, _symbol);
    }

    function buyObject(address _beneficiary) onlyValidPurchase
    onlyBuyer(_beneficiary)
    onlyValidAddress(_beneficiary) public payable {
        uint numTokens = calculateTokens();
        shopSettings.fundsRaised = shopSettings.fundsRaised.add(msg.value);
        object.mint(_beneficiary, numTokens);
        ObjectPurchase(msg.sender, _beneficiary, msg.value, numTokens);
        forwardFunds();
    }

    function calculateTokens() internal returns(uint) {
        // rate is literally tokens per eth in wei;
        // passing in a rate of 10 ETH (10*10^18) equates to 10 tokens per ETH, or a price of 0.1 ETH per token
        // rate is always 1/price!
        calculatePrice(); // update price
        return msg.value.mul(1 ether).div(1 ether.mul(1 ether).div(shopSettings.rate));
    }

    function calculatePrice() internal returns(uint) {
        shopSettings.price = (1 ether).mul(1 ether).div(shopSettings.rate); // update price based on current rate
        //shopSettings.recommendedBid = shopSettings.price.add((1 ether).div(100)); // update recommended bid based on current price
    }

    function closeShop() onlyOwner whenOpen public {
        shopSettings.endTime = uint32(now);
        ShopClosed(uint32(now));
    }

    function forwardFunds() internal {
        shopSettings.bank.transfer(msg.value);
    }
}

contract EnchantedShop is Shop {
    using SafeMath for *;

    mapping(address => uint) public balanceOwed; // balances owed to individual addresses
    mapping(address => uint) public latestBalanceCheck; // latest balance check of individual addresses
    mapping(address => uint) public itemsOwned;
    //mapping(address => uint) public totalWithdrawn; // used in calculating total earnings
    mapping(address => uint) public excessEth; // excess eth sent by individual addresses
    /*
    Using itemsOwned in place of object.balanceOf(msg.sender) prevents users who did not purchase tokens from the contract but who were instead transferred tokens from receiving earnings on them (which would require extra contract and token functionality to account for when those items were acquired). Using itemsOwned also means that users can transfer their tokens out but will still earn returns on them if they were purchased from the shop. We can also perform a check against the user&#39;s balanceOf to prevent this if desired.
    */
    uint public itemReturn;
    uint public maxDebt; // maximum possible debt owed by the shop if no funds were claimed
    uint public runningDebt; // total of individually amortized debts owed by this shop
    uint public additionalDebt; // general debt not yet accounted for due to amortization
    uint public debtPaid; // total debt paid by this shop
    uint public constant devFee = 125; // 125 represents 12.5%
    uint public originalPrice;

    uint public totalExcessEth; // total of individually amortized excess eth transfers, analogous to runningDebt

    bool public lock;
    uint public unlockDate;

    event ShopDeployed(address wallet, uint rate, uint itemReturn, uint32 endTime);
    //event EnchantedObjectMinted(uint totalSupply);
    event PriceUpdate(uint price);

    event FundsMoved(uint amount);
    event SafeLocked(uint date);
    event StartedSafeUnlock(uint date);

    event WillWithdraw(uint amount);

    modifier onlyContributors {
        require(itemsOwned[msg.sender] > 0);
        _;
    }

    modifier onlyValidPurchase() { // override onlyValidPurchase so that buyObject requires >= enough for 1 token instead of whole numbers only
        require(msg.value >= shopSettings.price); // at least enough for 1
        require((now >= shopSettings.startTime && now <= shopSettings.endTime) && msg.value != 0);
        _;
    }

    function EnchantedShop(address _bank, string _name, string _symbol, uint _rate, uint32 _endTime, uint _itemReturn)
    Shop(_bank, _name, _symbol, _rate, _endTime) public
    {
        require(_itemReturn == shopSettings.price.div(100)); // safety check; ensure we&#39;re using 1% returns and that we&#39;re using the correct price
        itemReturn = _itemReturn; // return should be in given wei
        originalPrice = shopSettings.price;
        ShopDeployed(_bank, _rate, _itemReturn, _endTime);
        unlockDate = 0;
        lock = true;
        SafeLocked(now);
    }

    function calculateTokens() internal returns(uint) {
        // rate is literally tokens per eth in wei;
        // passing in a rate of 10 ETH (10*10^18) equates to 10 tokens per ETH, or a price of 0.1 ETH per token
        calculatePrice(); // update price based on current rate
        return (1 ether);
    }

    function forwardFunds() internal {
        uint fee = shopSettings.price.mul(devFee).div(1000); // used to be msg.value.mul(devFee).div(1000); but we have refactored to only ever issue 1 token and the msg.value may exceed the price of one token
        uint supply = object.totalSupply();

        if (msg.value > shopSettings.price) { // if sender sent extra eth, account for it so we can send it back later
            excessEth[msg.sender] = excessEth[msg.sender].add(msg.value.sub(shopSettings.price));
            totalExcessEth = totalExcessEth.add(msg.value.sub(shopSettings.price));
        }
        
        shopSettings.bank.transfer(fee);
        itemsOwned[msg.sender] = itemsOwned[msg.sender].add(1 ether);
                
        // update caller&#39;s balance and our debt
        uint earnings = (itemsOwned[msg.sender].div(1 ether).sub(1)).mul(supply.sub(latestBalanceCheck[msg.sender])).div(1 ether).mul(itemReturn);
        if (latestBalanceCheck[msg.sender] != 0) { // if this isn&#39;t the first time we&#39;ve checked buyer&#39;s balance owed...
            balanceOwed[msg.sender] = balanceOwed[msg.sender].add(earnings);
            runningDebt = runningDebt.add(earnings);
        }
        latestBalanceCheck[msg.sender] = supply;
        maxDebt = maxDebt.add((supply.sub(1 ether)).div(1 ether).mul(itemReturn)); // update maxDebt given the new item total

        additionalDebt = maxDebt.sub(runningDebt).sub(debtPaid); // update total debt not yet accounted for due to amoritzation
        
        if (additionalDebt < 0) { // this check may be unnecessary but may have been needed for the prototype
            additionalDebt = 0;
        }
        
        // update price of item (using rate for scalability) so that we can always cover fee + returns
        if (supply.div(1 ether).mul(itemReturn).add(runningDebt).add(additionalDebt) > (this.balance.sub(totalExcessEth))) {
            shopSettings.rate = (1 ether).mul(1 ether).div(supply.div(1 ether).mul(itemReturn).mul(1000).div((uint(1000).sub(devFee))));
            calculatePrice(); // update price
            PriceUpdate(shopSettings.price);
        }

        //EnchantedObjectMinted(supply); // FIX THIS
    }

    /*
    changes needed for refactoring

    // "enchanted items have a recommended bid which increases your likelihood of obtaining the item. However, you will still pay the best possible price—any ETH sent in excess of the lowest available price of the item is automatically added to your account balance and can be withdrawn from the contract at any time."

    // add recommendedBid which is real price rounded up to the next .01 - use round/truncate: https://ethereum.stackexchange.com/questions/5836/what-is-the-cheapest-way-to-roundup-or-ceil-to-multiple-of-1000
    // add price paid - real price to balance owed
    // mint exactly one token (calculateTokens)

    // we don&#39;t seem to actually use whenClosed, whenOpen

    */

    function claimFunds() onlyContributors public {
        // must use onlyContributors (itemsOwned > 0) as a check here!
        uint latest = latestBalanceCheck[msg.sender];
        uint supply = object.totalSupply();
        uint balance = balanceOwed[msg.sender];
        uint earnings = itemsOwned[msg.sender].div(1 ether).mul(supply.sub(latest)).div(1 ether).mul(itemReturn);
        
        uint excess = excessEth[msg.sender];

        // update latestBalanceCheck, reset balance owed to caller, and reset excess eth owed to caller
        // do all of these before calling transfer function or incrementing balance mappings so as to circumvent reentrancy attacks
        latestBalanceCheck[msg.sender] = supply;
        balanceOwed[msg.sender] = 0;
        excessEth[msg.sender] = 0;

        balance = balance.add(earnings); // account for user&#39;s earnings since lastBalanceCheck, but don&#39;t add it to balanceOwed to prevent reentrancy attacks
        // next, update our debt:
        runningDebt = runningDebt.add(earnings);
        runningDebt = runningDebt.sub(balance); // might be going negative due to not adding the excess eth send to runningDebt
        debtPaid = debtPaid.add(balance);

        // account for excess Eth
        balance = balance.add(excess);
        totalExcessEth = totalExcessEth.sub(excess);

        WillWithdraw(balance);

        // finally, send balance owed to msg.sender
        require(balance > 0);
        msg.sender.transfer(balance);
        //totalWithdrawn[msg.sender] = totalWithdrawn[msg.sender].add(balance.sub(excess));

        // might want to return bool
    }

    function startUnlock()
    onlyOwner public
    {
        require(lock && now.sub(unlockDate) > 2 weeks);
        unlockDate = now + 2 weeks;
        lock = false;
        StartedSafeUnlock(now);
    }

    function emergencyWithdraw(uint amount, bool relock)
    onlyOwner public
    {
        require(!lock && now > unlockDate);
        shopSettings.bank.transfer(amount);
        if (relock) {
            lock = relock;
            SafeLocked(now);
        }
    }

}

/*
to-do:
- implement something so that calling claimFunds() if the balance var is 0 throws an exception?

- implement a check if necessary for when balance to be sent to msg.sender > address.balance

- implement an emergency withdrawal function for owners?
    migrate this from ShopManager

- "forwardFunds() in EnchantedShop has to be executed sequentially with other purchases, we may want to implement the design you were talking about before which forces 1 tx per block or whatever it was" -- will know more after testing









    address public bank;
    bool public lock;
    uint public unlockDate;

    event FundsMoved(uint amount);
    event SafeLocked(uint date);
    event StartedSafeUnlock(uint date);
    
    function ShopManager (address _bank) public {
        bank = _bank;
        unlockDate = 0;
        lock = true;
        SafeLocked(now);
    }

    function startUnlock()
    onlyOwner public
    {
        require(lock && now - unlockDate > 2 weeks);
        unlockDate = now + 2 weeks;
        lock = false;
        StartedSafeUnlock(now);
    }

    function fundsToBank()
    onlyOwner public
    {
        require(!lock && now > unlockDate);
        bank.transfer(this.balance);
        lock = true;
        SafeLocked(now);
    }


*/