pragma solidity ^0.4.15;

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
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
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
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
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
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
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
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}


/**
 * @title BitImageToken
 * @dev ERC20 burnable token based on OpenZeppelin&#39;s implementation.
 */
contract BitImageToken is StandardToken, BurnableToken, Ownable {

    /**
     * @dev Event for tokens timelock logging.
     * @param _holder {address} the holder of tokens after they are released.
     * @param _releaseTime {uint256} the UNIX timestamp when token release is enabled.
     */
    event Timelock(address indexed _holder, uint256 _releaseTime);

    string public name;
    string public symbol;
    uint8 public decimals;
    bool public released;
    address public saleAgent;

    mapping (address => uint256) public timelock;

    modifier onlySaleAgent() {
        require(msg.sender == saleAgent);
        _;
    }

    modifier whenReleased() {
        if (timelock[msg.sender] != 0) {
            require(released && now > timelock[msg.sender]);
        } else {
            require(released || msg.sender == saleAgent);
        }
        _;
    }


    /**
     * @dev Constructor instantiates token supply and allocates balanace to the owner.
     */
    function BitImageToken() public {
        name = "Bitimage Token";
        symbol = "BIM";
        decimals = 18;
        released = false;
        totalSupply = 10000000000 ether;
        balances[msg.sender] = totalSupply;
        Transfer(address(0), msg.sender, totalSupply);
    }

    /**
     * @dev Associates this token with a specified sale agent. The sale agent will be able
     * to call transferFrom() function to transfer tokens during crowdsale.
     * @param _saleAgent {address} the address of a sale agent that will sell this token.
     */
    function setSaleAgent(address _saleAgent) public onlyOwner {
        require(_saleAgent != address(0));
        require(saleAgent == address(0));
        saleAgent = _saleAgent;
        super.approve(saleAgent, totalSupply);
    }

    /**
     * @dev Sets the released flag to true which enables to transfer tokens after crowdsale is end.
     * Once released, it is not possible to disable transfers.
     */
    function release() public onlySaleAgent {
        released = true;
    }

    /**
     * @dev Sets time when token release is enabled for specified holder.
     * @param _holder {address} the holder of tokens after they are released.
     * @param _releaseTime {uint256} the UNIX timestamp when token release is enabled.
     */
    function lock(address _holder, uint256 _releaseTime) public onlySaleAgent {
        require(_holder != address(0));
        require(_releaseTime > now);
        timelock[_holder] = _releaseTime;
        Timelock(_holder, _releaseTime);
    }

    /**
     * @dev Transfers tokens to specified address.
     * Overrides the transfer() function with modifier that prevents the ability to transfer
     * tokens by holders unitl release time. Only sale agent can transfer tokens unitl release time.
     * @param _to {address} the address to transfer to.
     * @param _value {uint256} the amount of tokens to be transferred.
     */
    function transfer(address _to, uint256 _value) public whenReleased returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
     * @dev Transfers tokens from one address to another.
     * Overrides the transferFrom() function with modifier that prevents the ability to transfer
     * tokens by holders unitl release time. Only sale agent can transfer tokens unitl release time.
     * @param _from {address} the address to send from.
     * @param _to {address} the address to transfer to.
     * @param _value {uint256} the amount of tokens to be transferred.
     */
    function transferFrom(address _from, address _to, uint256 _value) public whenReleased returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Overrides the approve() function with  modifier that prevents the ability to approve the passed
     * address to spend the specified amount of tokens until release time.
     * @param _spender {address} the address which will spend the funds.
     * @param _value {uint256} the amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public whenReleased returns (bool) {
        return super.approve(_spender, _value);
    }

    /**
     * @dev Increment allowed value.
     * Overrides the increaseApproval() function with modifier that prevents the ability to increment
     * allowed value until release time.
     * @param _spender {address} the address which will spend the funds.
     * @param _addedValue {uint} the amount of tokens to be added.
     */
    function increaseApproval(address _spender, uint _addedValue) public whenReleased returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    /**
     * @dev Dicrement allowed value.
     * Overrides the decreaseApproval() function with modifier that prevents the ability to dicrement
     * allowed value until release time.
     * @param _spender {address} the address which will spend the funds.
     * @param _subtractedValue {uint} the amount of tokens to be subtracted.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public whenReleased returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    /**
     * @dev Burns a specified amount of tokens.
     * Overrides the burn() function with modifier that prevents the ability to burn tokens
     * by holders excluding the sale agent.
     * @param _value {uint256} the amount of token to be burned.
     */
    function burn(uint256 _value) public onlySaleAgent {
        super.burn(_value);
    }

    /**
     * @dev Burns a specified amount of tokens from specified address.
     * @param _from {address} the address to burn from.
     * @param _value {uint256} the amount of token to be burned.
     */
    function burnFrom(address _from, uint256 _value) public onlySaleAgent {
        require(_value > 0);
        require(_value <= balances[_from]);
        balances[_from] = balances[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(_from, _value);
    }
}


/**
 * @title BitImageCrowdsale
 * @dev The BitImageCrowdsale contract is used for selling BitImageToken tokens (BIM).
 */
contract BitImageTokenSale is Pausable {
    using SafeMath for uint256;

    /**
     * @dev Event for token purchase logging.
     * @param _investor {address} the address of investor.
     * @param _weiAmount {uint256} the amount of contributed Ether.
     * @param _tokenAmount {uint256} the amount of tokens purchased.
     */
    event TokenPurchase(address indexed _investor, uint256 _weiAmount, uint256 _tokenAmount);

    /**
     * @dev Event for Ether Refunding logging.
     * @param _investor {address} the address of investor.
     * @param _weiAmount {uint256} the amount of Ether to be refunded.
     */
    event Refunded(address indexed _investor, uint256 _weiAmount);

    BitImageToken public token;

    address public walletEtherPresale;
    address public walletEhterCrowdsale;

    address public walletTokenTeam;
    address[] public walletTokenAdvisors;
    address public walletTokenBounty;
    address public walletTokenReservation;

    uint256 public startTime;
    uint256 public period;
    uint256 public periodPresale;
    uint256 public periodCrowdsale;
    uint256 public periodWeek;

    uint256 public weiMinInvestment;
    uint256 public weiMaxInvestment;

    uint256 public rate;

    uint256 public softCap;
    uint256 public goal;
    uint256 public goalIncrement;
    uint256 public hardCap;

    uint256 public tokenIcoAllocated;
    uint256 public tokenTeamAllocated;
    uint256 public tokenAdvisorsAllocated;
    uint256 public tokenBountyAllocated;
    uint256 public tokenReservationAllocated;

    uint256 public weiTotalReceived;

    uint256 public tokenTotalSold;

    uint256 public weiTotalRefunded;

    uint256 public bonus;
    uint256 public bonusDicrement;
    uint256 public bonusAfterPresale;

    struct Investor {
        uint256 weiContributed;
        uint256 tokenBuyed;
        bool refunded;
    }

    mapping (address => Investor) private investors;
    address[] private investorsIndex;

    enum State { NEW, PRESALE, CROWDSALE, CLOSED }
    State public state;


    /**
     * @dev Constructor for a crowdsale of BitImageToken tokens.
     */
    function BitImageTokenSale() public {
        walletEtherPresale = 0xE19f0ccc003a36396FE9dA4F344157B2c60A4B8E;
        walletEhterCrowdsale = 0x10e5f0e94A43FA7C9f7F88F42a6a861312aD1d31;
        walletTokenTeam = 0x35425E32fE41f167990DBEa1010132E9669Fa500;
        walletTokenBounty = 0x91325c4a25893d80e26b4dC14b964Cf5a27fECD8;
        walletTokenReservation = 0x4795eC1E7C24B80001eb1F43206F6e075fCAb4fc;
        walletTokenAdvisors = [
            0x2E308F904C831e41329215a4807d9f1a82B67eE2,
            0x331274f61b3C976899D6FeB6f18A966A50E98C8d,
            0x6098b02d10A1f27E39bCA219CeB56355126EC74f,
            0xC14C105430C13e6cBdC8DdB41E88fD88b9325927
        ];
        periodPresale = 4 weeks;
        periodCrowdsale = 6 weeks;
        periodWeek = 1 weeks;
        weiMinInvestment = 0.1 ether;
        weiMaxInvestment = 500 ether;
        rate = 130000;
        softCap = 2000 ether;
        goal = 6000 ether;
        goalIncrement = goal;
        hardCap = 42000 ether;
        bonus = 30;
        bonusDicrement = 5;
        state = State.NEW;
        pause();
    }

    /**
     * @dev Fallback function is called whenever Ether is sent to the contract.
     */
    function() external payable {
        purchase(msg.sender);
    }

    /**
     * @dev Initilizes the token with given address and allocates tokens.
     * @param _token {address} the address of token contract.
     */
    function setToken(address _token) external onlyOwner whenPaused {
        require(state == State.NEW);
        require(_token != address(0));
        require(token == address(0));
        token = BitImageToken(_token);
        tokenIcoAllocated = token.totalSupply().mul(62).div(100);
        tokenTeamAllocated = token.totalSupply().mul(18).div(100);
        tokenAdvisorsAllocated = token.totalSupply().mul(4).div(100);
        tokenBountyAllocated = token.totalSupply().mul(6).div(100);
        tokenReservationAllocated = token.totalSupply().mul(10).div(100);
        require(token.totalSupply() == tokenIcoAllocated.add(tokenTeamAllocated).add(tokenAdvisorsAllocated).add(tokenBountyAllocated).add(tokenReservationAllocated));
    }

    /**
     * @dev Sets the start time.
     * @param _startTime {uint256} the UNIX timestamp when to start the sale.
     */
    function start(uint256 _startTime) external onlyOwner whenPaused {
        require(_startTime >= now);
        require(token != address(0));
        if (state == State.NEW) {
            state = State.PRESALE;
            period = periodPresale;
        } else if (state == State.PRESALE && weiTotalReceived >= softCap) {
            state = State.CROWDSALE;
            period = periodCrowdsale;
            bonusAfterPresale = bonus.sub(bonusDicrement);
            bonus = bonusAfterPresale;
        } else {
            revert();
        }
        startTime = _startTime;
        unpause();
    }

    /**
     * @dev Finalizes the sale.
     */
    function finalize() external onlyOwner {
        require(weiTotalReceived >= softCap);
        require(now > startTime.add(period) || weiTotalReceived >= hardCap);

        if (state == State.PRESALE) {
            require(this.balance > 0);
            walletEtherPresale.transfer(this.balance);
            pause();
        } else if (state == State.CROWDSALE) {
            uint256 tokenTotalUnsold = tokenIcoAllocated.sub(tokenTotalSold);
            tokenReservationAllocated = tokenReservationAllocated.add(tokenTotalUnsold);

            require(token.transferFrom(token.owner(), walletTokenBounty, tokenBountyAllocated));
            require(token.transferFrom(token.owner(), walletTokenReservation, tokenReservationAllocated));
            require(token.transferFrom(token.owner(), walletTokenTeam, tokenTeamAllocated));
            token.lock(walletTokenReservation, now + 0.5 years);
            token.lock(walletTokenTeam, now + 1 years);
            uint256 tokenAdvisor = tokenAdvisorsAllocated.div(walletTokenAdvisors.length);
            for (uint256 i = 0; i < walletTokenAdvisors.length; i++) {
                require(token.transferFrom(token.owner(), walletTokenAdvisors[i], tokenAdvisor));
                token.lock(walletTokenAdvisors[i], now + 0.5 years);
            }

            token.release();
            state = State.CLOSED;
        } else {
            revert();
        }
    }

    /**
     * @dev Allows investors to get refund in case when ico is failed.
     */
    function refund() external whenNotPaused {
        require(state == State.PRESALE);
        require(now > startTime.add(period));
        require(weiTotalReceived < softCap);

        require(this.balance > 0);

        Investor storage investor = investors[msg.sender];

        require(investor.weiContributed > 0);
        require(!investor.refunded);

        msg.sender.transfer(investor.weiContributed);
        token.burnFrom(msg.sender, investor.tokenBuyed);
        investor.refunded = true;
        weiTotalRefunded = weiTotalRefunded.add(investor.weiContributed);

        Refunded(msg.sender, investor.weiContributed);
    }

    function purchase(address _investor) private whenNotPaused {
        require(state == State.PRESALE || state == State.CROWDSALE);
        require(now >= startTime && now <= startTime.add(period));

        if (state == State.CROWDSALE) {
            uint256 timeFromStart = now.sub(startTime);
            if (timeFromStart > periodWeek) {
                uint256 currentWeek = timeFromStart.div(1 weeks);
                uint256 bonusWeek = bonusAfterPresale.sub(bonusDicrement.mul(currentWeek));
                if (bonus > bonusWeek) {
                    bonus = bonusWeek;
                }
                currentWeek++;
                periodWeek = currentWeek.mul(1 weeks);
            }
        }

        uint256 weiAmount = msg.value;
        require(weiAmount >= weiMinInvestment && weiAmount <= weiMaxInvestment);

        uint256 tokenAmount = weiAmount.mul(rate);
        uint256 tokenBonusAmount = tokenAmount.mul(bonus).div(100);
        tokenAmount = tokenAmount.add(tokenBonusAmount);

        weiTotalReceived = weiTotalReceived.add(weiAmount);
        tokenTotalSold = tokenTotalSold.add(tokenAmount);
        require(tokenTotalSold <= tokenIcoAllocated);

        require(token.transferFrom(token.owner(), _investor, tokenAmount));

        Investor storage investor = investors[_investor];
        if (investor.weiContributed == 0) {
            investorsIndex.push(_investor);
        }
        investor.tokenBuyed = investor.tokenBuyed.add(tokenAmount);
        investor.weiContributed = investor.weiContributed.add(weiAmount);

        if (state == State.CROWDSALE) {
            walletEhterCrowdsale.transfer(weiAmount);
        }
        TokenPurchase(_investor, weiAmount, tokenAmount);

        if (weiTotalReceived >= goal) {
            if (state == State.PRESALE) {
                startTime = now;
                period = 1 weeks;
            }
            uint256 delta = weiTotalReceived.sub(goal);
            goal = goal.add(goalIncrement).add(delta);
            bonus = bonus.sub(bonusDicrement);
        }
    }
}