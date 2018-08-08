pragma solidity ^0.4.18;

contract TBsell{
    TBCoin TBSC =TBCoin(0x6158e3F89b4398f5fb20D20DbFc5a5c955F0F6dd);
    address public wallet = 0x61C8C6d0119Cdc3fFFB4E49ebf0899887e49761D;
    address public TBowner;
    uint public TBrate = 1200;
    function TBsell() public{
        TBowner = msg.sender;
    }
    function () public payable{
        require(TBSC.balanceOf(this) >= msg.value*TBrate);
        TBSC.transfer(msg.sender,msg.value*TBrate);
        wallet.transfer(msg.value);
    }
    function getbackTB(uint amount) public{
        assert(msg.sender == TBowner);
        TBSC.transfer(TBowner,amount);
    }
    function changeTBrate(uint rate) public{
        assert(msg.sender == TBowner);
        TBrate = rate;
    }
}


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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

/**
 * @title Standard ERC20 token
    *
      * @dev Implementation of the basic standard token.
         * @dev https://github.com/ethereum/EIPs/issues/20
            * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
               */
contract StandardToken {
  using SafeMath for uint256;
  mapping (address => mapping (address => uint256)) allowed;
  mapping(address => uint256) balances;
  mapping(address => bool) preICO_address;
  uint256 public totalSupply;
  uint256 public endDate;
  /**
  * @dev transfer token for a specified address
      * @param _to The address to transfer to.
          * @param _value The amount to be transferred.
              */
  function transfer(address _to, uint256 _value) public returns (bool) {

    if( preICO_address[msg.sender] ) require( now > endDate + 120 days ); //Lock coin
    else require( now > endDate ); //Lock coin

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
  * @dev Gets the balance of the specified address.
      * @param _owner The address to query the the balance of. 
          * @return An uint256 representing the amount owned by the passed address.
              */
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return balances[_owner];
  }

  /**
   * @dev Transfer tokens from one address to another
        * @param _from address The address which you want to send tokens from
             * @param _to address The address which you want to transfer to
                  * @param _value uint256 the amout of tokens to be transfered
                       */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    if( preICO_address[_from] ) require( now > endDate + 120 days ); //Lock coin
    else require( now > endDate ); //Lock coin

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
        * @param _spender The address which will spend the funds.
             * @param _value The amount of tokens to be spent.
                  */
  function approve(address _spender, uint256 _value) public returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    if( preICO_address[msg.sender] ) require( now > endDate + 120 days ); //Lock coin
    else require( now > endDate ); //Lock coin

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  event Approval(address indexed owner, address indexed spender, uint256 value);

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
        * @param _owner address The address which owns the funds.
             * @param _spender address The address which will spend the funds.
                  * @return A uint256 specifing the amount of tokens still avaible for the spender.
                       */
  function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract TBCoin is StandardToken, Ownable {
    using SafeMath for uint256;

    // Token Info.
    string  public constant name = "TimeBox Coin";
    string  public constant symbol = "TB";
    uint8   public constant decimals = 18;

    // Sale period.
    uint256 public startDate;
    // uint256 public endDate;

    // Token Cap for each rounds
    uint256 public saleCap;

    // Address where funds are collected.
    address public wallet;

    // Amount of raised money in wei.
    uint256 public weiRaised;

    // Event
    event TokenPurchase(address indexed purchaser, uint256 value,
                        uint256 amount);
    event PreICOTokenPushed(address indexed buyer, uint256 amount);

    // Modifiers
    modifier uninitialized() {
        require(wallet == 0x0);
        _;
    }

    function TBCoin() public{
    }
// 
    function initialize(address _wallet, uint256 _start, uint256 _end,
                        uint256 _saleCap, uint256 _totalSupply)
                        public onlyOwner uninitialized {
        require(_start >= getCurrentTimestamp());
        require(_start < _end);
        require(_wallet != 0x0);
        require(_totalSupply > _saleCap);

        startDate = _start;
        endDate = _end;
        saleCap = _saleCap;
        wallet = _wallet;
        totalSupply = _totalSupply;

        balances[wallet] = _totalSupply.sub(saleCap);
        balances[0xb1] = saleCap;
    }

    function supply() internal view returns (uint256) {
        return balances[0xb1];
    }

    function getCurrentTimestamp() internal view returns (uint256) {
        return now;
    }

    function getRateAt(uint256 at) public constant returns (uint256) {
        if (at < startDate) {
            return 0;
        } else if (at < (startDate + 3 days)) {
            return 1500;
        } else if (at < (startDate + 9 days)) {
            return 1440;
        } else if (at < (startDate + 15 days)) {
            return 1380;
        } else if (at < (startDate + 21 days)) {
            return 1320;
        } else if (at < (startDate + 27 days)) {
            return 1260;
        } else if (at <= endDate) {
            return 1200;
        } else {
            return 0;
        }
    }

    // Fallback function can be used to buy tokens
    function () public payable {
        buyTokens(msg.sender, msg.value);
    }

    // For pushing pre-ICO records
    function push(address buyer, uint256 amount) public onlyOwner { //b753a98c
        require(balances[wallet] >= amount);
        require(now < startDate);
        require(buyer != wallet);

        preICO_address[ buyer ] = true;

        // Transfer
        balances[wallet] = balances[wallet].sub(amount);
        balances[buyer] = balances[buyer].add(amount);
        PreICOTokenPushed(buyer, amount);
    }

    function buyTokens(address sender, uint256 value) internal {
        require(saleActive());

        uint256 weiAmount = value;
        uint256 updatedWeiRaised = weiRaised.add(weiAmount);

        // Calculate token amount to be purchased
        uint256 actualRate = getRateAt(getCurrentTimestamp());
        uint256 amount = weiAmount.mul(actualRate);

        // We have enough token to sale
        require(supply() >= amount);

        // Transfer
        balances[0xb1] = balances[0xb1].sub(amount);
        balances[sender] = balances[sender].add(amount);
        TokenPurchase(sender, weiAmount, amount);

        // Update state.
        weiRaised = updatedWeiRaised;

        // Forward the fund to fund collection wallet.
        wallet.transfer(msg.value);
    }

    function finalize() public onlyOwner {
        require(!saleActive());

        // Transfer the rest of token to TB team
        balances[wallet] = balances[wallet].add(balances[0xb1]);
        balances[0xb1] = 0;
    }

    function saleActive() public constant returns (bool) {
        return (getCurrentTimestamp() >= startDate &&
                getCurrentTimestamp() < endDate && supply() > 0);
    }
    
}