pragma solidity ^0.4.18;

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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

contract Pausable is Ownable {

    event EPause();
    event EUnpause();

    bool public paused = true;

    modifier whenNotPaused()
    {
        require(!paused);
        _;
    }

    modifier whenPaused()
    {
        require(paused);
        _;
    }

    function pause() public onlyOwner
    {
        paused = true;
        EPause();
    }

    function pauseInternal() internal
    {
        paused = true;
        EPause();
    }

    function unpause() public onlyOwner
    {
        paused = false;
        EUnpause();
    }

    function isPaused() view public returns(bool) {
        return paused;
    }

    function unpauseInternal() internal
    {
        paused = false;
        EUnpause();
    }

}

contract StandardToken is ERC20, BasicToken {
  using SafeMath for uint256;
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
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is PausableToken {

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

contract Streamity is BurnableToken {

    string public constant name = &quot;Streamity&quot;;
    string public constant symbol = &quot;STM&quot;;
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 180000000 ether;


    address public tokenOwner = 0x99395F3CFa72E30E1073E2DB4d716efCFa1a9b82;
    address public reserveFund = 0xC5fed49Be1F6c3949831a06472aC5AB271AF89BD; //18 600 000 STM
    address public advisersPartners = 0x5B5521E9D795CA083eF928A58393B8f7FF95e098; //3 720 000 STM
    address public teamWallet = 0x556dB38b73B97954960cA72580EbdAc89327808E; // 4 650 000 STM


    uint public timeLock = now + 1 years;

    function Streamity () public {
        totalSupply_ = INITIAL_SUPPLY;

        balances[tokenOwner] = INITIAL_SUPPLY;

        balances[this] = balances[tokenOwner].sub(23250000 ether); // for freezing
        balances[tokenOwner] = balances[tokenOwner].sub(23250000 ether);
        Transfer(tokenOwner, this, 23250000 ether);

        balances[reserveFund] = balances[tokenOwner].sub(18600000 ether);
        balances[tokenOwner] = balances[tokenOwner].sub(18600000 ether);
        Transfer(tokenOwner, reserveFund, 18600000 ether);

        balances[advisersPartners] = balances[tokenOwner].sub(3720000 ether);
        balances[tokenOwner] = balances[tokenOwner].sub(3720000 ether);
        Transfer(tokenOwner, advisersPartners, 3720000 ether);

        balances[teamWallet] = balances[tokenOwner].sub(4650000 ether);
        balances[tokenOwner] = balances[tokenOwner].sub(4650000 ether);
        Transfer(tokenOwner, teamWallet, 4650000 ether);
    }

    function sendTokens(address _to, uint _value) public onlyOwner {
        require(_to != address(0));
        require(_value <= balances[tokenOwner]);
        balances[tokenOwner] = balances[tokenOwner].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(tokenOwner, _to, _value);
    }

    function unlockTeamTokens() public {
        require(now >= timeLock);

        uint amount = 23250000 ether;

        balances[this] = balances[this].sub(amount);
        balances[teamWallet] = balances[teamWallet].add(amount);
        Transfer(this, teamWallet, amount);
    }

}


contract SalesManager is Ownable {

    using SafeMath for uint;

    uint public stage = 0;
    uint256 public weisRaised;  // how many weis was raised on crowdsale
    address public tokenAddress;
    uint256 public decimals = 18;
    uint256 DEC = 10 ** uint256(decimals);
    uint256 public buyPrice = 1000000000000000000 wei;
    address public ethOwner = 0x50c8871c224AB276CF71EaB74482CBF5a36b9af5;


    function SalesManager() public {
        tokenAddress = new Streamity();
    }

    event CrowdSaleFinished(string info);

    struct Ico {
        uint256 tokens;             // Tokens in crowdsale
        uint startDate;             // Date when crowsale will be starting, after its starting that property will be the 0
        uint endDate;               // Date when crowdsale will be stop
        uint8 discount;             // Discount
        uint8 discountFirstDayICO;  // Discount. Only for first stage ico
    }

    Ico public ICO;


    function updateStat(uint256 tokens, uint startDate, uint endDate, uint8 discount, uint8 discountFirstDayICO) public onlyOwner {
        ICO = Ico(tokens, startDate, endDate, discount, discountFirstDayICO);
    }

    /*
    * Function confirm autosell
    *
    */
    function confirmSell(uint256 _amount) internal view
        returns(bool)
    {
        if (ICO.tokens < _amount) {
            return false;
        }

        return true;
    }

    /*
    *  Make discount
    */
    function countDiscount(uint256 amount) internal
        returns(uint256)
    {
        uint256 _amount = (amount.mul(DEC)).div(buyPrice);

        if (1 == stage) {
            _amount = _amount.add(withDiscount(_amount, ICO.discount));
        }
        else if (2 == stage)
        {
            if (now <= ICO.startDate + 1 days)
            {
                if (0 == ICO.discountFirstDayICO) {
                    ICO.discountFirstDayICO = 20;
                }
                _amount = _amount.add(withDiscount(_amount, ICO.discountFirstDayICO));
            }
            else
            {
                _amount = _amount.add(withDiscount(_amount, ICO.discount));
            }
        }
        else if (3 == stage) {
            _amount = _amount.add(withDiscount(_amount, ICO.discount));
        }

        return _amount;
    }

    /**
    * Function for change discount if need
    *
    */
    function changeDiscount(uint8 _discount) public onlyOwner
        returns (bool)
    {
        ICO = Ico (ICO.tokens, ICO.startDate, ICO.endDate, _discount, ICO.discountFirstDayICO);
        return true;
    }

    /**
    * Expanding of the functionality
    *
    * @param _numerator - Numerator - value (10000)
    * @param _denominator - Denominator - value (10000)
    *
    * example: price 1000 tokens by 1 ether = changeRate(1, 1000)
    */
    function changeRate(uint256 _numerator, uint256 _denominator) public onlyOwner
        returns (bool success)
    {
        if (_numerator == 0) _numerator = 1;
        if (_denominator == 0) _denominator = 1;

        buyPrice = (_numerator.mul(DEC)).div(_denominator);

        return true;
    }

    /*
    * Function show in contract what is now
    *
    */
    function crowdSaleStatus() internal constant
        returns (string)
    {
        if (1 == stage) {
            return &quot;Pre-ICO&quot;;
        } else if(2 == stage) {
            return &quot;ICO first stage&quot;;
        } else if (3 == stage) {
            return &quot;ICO second stage&quot;;
        } else if (4 >= stage) {
            return &quot;feature stage&quot;;
        }

        return &quot;there is no stage at present&quot;;
    }

    /*
    * Seles manager
    *
    */
    function paymentManager(address sender, uint256 value) internal
    {
        uint256 discountValue = countDiscount(value);
        bool conf = confirmSell(discountValue);

        if (conf) {

            sell(sender, discountValue);

            weisRaised = weisRaised.add(value);

            if (now >= ICO.endDate) {
                Streamity(tokenAddress).pause();
                CrowdSaleFinished(crowdSaleStatus()); // if time is up
            }

        } else {

            sell(sender, ICO.tokens); // sell tokens which has been accessible

            weisRaised = weisRaised.add(value);

            Streamity(tokenAddress).pause();
            CrowdSaleFinished(crowdSaleStatus());  // if tokens sold
        }
    }

    /*
    * Function for selling tokens in crowd time.
    *
    */
    function sell(address _investor, uint256 _amount) internal
    {
        ICO.tokens = ICO.tokens.sub(_amount);

        Streamity(tokenAddress).sendTokens(_investor, _amount);
        if(!ethOwner.send(msg.value)) revert();
    }

    /*
    * Function for start crowdsale (any)
    *
    * @param _tokens - How much tokens will have the crowdsale - amount humanlike value (10000)
    * @param _startDate - When crowdsale will be start - unix timestamp (1512231703 )
    * @param _endDate - When crowdsale will be end - humanlike value (7) same as 7 days
    * @param _discount - Discount for the crowd - humanlive value (7) same as 7 %
    * @param _discount - Discount for the crowds first day - humanlive value (7) same as 7 %
    */
    function startCrowd(uint256 _tokens, uint _startDate, uint _endDate, uint8 _discount, uint8 _discountFirstDayICO) public onlyOwner
    {
        ICO = Ico (_tokens * DEC, _startDate, _startDate + _endDate * 1 days , _discount, _discountFirstDayICO);
        stage = stage.add(1);
        Streamity(tokenAddress).unpause();
    }

    /**
    * Function for web3js, should be call when somebody will buy tokens from website. This function only delegator.
    *
    * @param _investor - address of investor (who payed)
    * @param _amount - ethereum
    */
    function transferWeb3js(address _investor, uint256 _amount) external onlyOwner
    {
        sell(_investor, _amount);
    }

    /**
    * Function for adding discount
    *
    */
    function withDiscount(uint256 _amount, uint _percent) internal pure
        returns (uint256)
    {
        return (_amount.mul(_percent)).div(100);
    }

    /**
    * Function payments handler
    *
    */
    function() public payable
    {
        assert(msg.value >= 1 ether / 10);
        require(now >= ICO.startDate);

        if (Streamity(tokenAddress).isPaused() == false) {
            paymentManager(msg.sender, msg.value);
        } else {
            revert();
        }
    }

    // call any function from another contract
    function callData(address contractAddress, bytes data) public onlyOwner {
        if(!contractAddress.call(data)) revert();
    }

    function transferOwnershipToken(address newTokenOwnerAddress) public onlyOwner {
        Streamity tokenContract = Streamity(tokenAddress);
        tokenContract.transferOwnership(newTokenOwnerAddress);
    }

    function pauseToken() public onlyOwner {
        Streamity tokenContract = Streamity(tokenAddress);
        tokenContract.pause();
    }

    function unPauseToken() public onlyOwner {
        Streamity tokenContract = Streamity(tokenAddress);
        tokenContract.pause();
    }

    function drop(address[] _destinations, uint256[] _amount) public onlyOwner
    returns (uint) {
        uint i = 0;
        while (i < _destinations.length) {
           Streamity(tokenAddress).sendTokens(_destinations[i], _amount[i]);
           i += 1;
        }
        return(i);
    }

}