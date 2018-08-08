pragma solidity ^0.4.21;

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

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

contract OracleI {
    bytes32 public oracleName;
    bytes16 public oracleType;
    uint256 public rate;
    bool public waitQuery;
    uint256 public updateTime;
    uint256 public callbackTime;
    function getPrice() view public returns (uint);
    function setBank(address _bankAddress) public;
    function setGasPrice(uint256 _price) public;
    function setGasLimit(uint256 _limit) public;
    function updateRate() external returns (bool);
}

interface ExchangerI {
    /* Order creation */
    function buyTokens(address _recipient) payable public;
    function sellTokens(address _recipient, uint256 tokensCount) public;

    /* Rate calc & init  params */
    function requestRates() payable public;
    function calcRates() public;

    /* Data getters */
    function tokenBalance() public view returns(uint256);
    function getOracleData(uint number) public view returns (address, bytes32, bytes16, bool, uint256, uint256, uint256);

    /* Balance methods */
    function refillBalance() payable public;
    function withdrawReserve() public;
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


/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}


/**
 * @title LibreCash token contract.
 *
 * @dev ERC20 token contract.
 */
contract LibreCash is MintableToken, BurnableToken, Claimable  {
    string public constant name = "LibreCash";
    string public constant symbol = "Libre";
    uint32 public constant decimals = 18;
}


contract ComplexExchanger is ExchangerI {
    using SafeMath for uint256;

    address public tokenAddress;
    LibreCash token;
    address[] public oracles;
    uint256 public deadline;
    address public withdrawWallet;

    uint256 public requestTime;
    uint256 public calcTime;

    uint256 public buyRate;
    uint256 public sellRate;
    uint256 public buyFee;
    uint256 public sellFee;

    uint256 constant ORACLE_ACTUAL = 15 minutes;
    uint256 constant ORACLE_TIMEOUT = 10 minutes;
    // RATE_PERIOD should be greater than or equal to ORACLE_ACTUAL
    uint256 constant RATE_PERIOD = 15 minutes;
    uint256 constant MIN_READY_ORACLES = 2;
    uint256 constant FEE_MULTIPLIER = 100;
    uint256 constant RATE_MULTIPLIER = 1000;
    uint256 constant MAX_RATE = 5000 * RATE_MULTIPLIER;
    uint256 constant MIN_RATE = 100 * RATE_MULTIPLIER;

    event InvalidRate(uint256 rate, address oracle);
    event OracleRequest(address oracle);
    event Buy(address sender, address recipient, uint256 tokenAmount, uint256 price);
    event Sell(address sender, address recipient, uint256 cryptoAmount, uint256 price);
    event ReserveRefill(uint256 amount);
    event ReserveWithdraw(uint256 amount);

    enum State {
        LOCKED,
        PROCESSING_ORDERS,
        WAIT_ORACLES,
        CALC_RATES,
        REQUEST_RATES
    }

    function() payable public {
        buyTokens(msg.sender);
    }

    function ComplexExchanger(
        address _token,
        uint256 _buyFee,
        uint256 _sellFee,
        address[] _oracles,
        uint256 _deadline,
        address _withdrawWallet
    ) public
    {
        require(
            _withdrawWallet != address(0x0) &&
            _token != address(0x0) &&
            _deadline > now &&
            _oracles.length >= MIN_READY_ORACLES
        );

        tokenAddress = _token;
        token = LibreCash(tokenAddress);
        oracles = _oracles;
        buyFee = _buyFee;
        sellFee = _sellFee;
        deadline = _deadline;
        withdrawWallet = _withdrawWallet;
    }

    /**
     * @dev Returns the contract state.
     */
    function getState() public view returns (State) {
        if (now >= deadline)
            return State.LOCKED;

        if (now - calcTime < RATE_PERIOD)
            return State.PROCESSING_ORDERS;

        if (waitingOracles() != 0)
            return State.WAIT_ORACLES;

        if (readyOracles() >= MIN_READY_ORACLES)
            return State.CALC_RATES;

        return State.REQUEST_RATES;
    }

    /**
     * @dev Allows user to buy tokens by ether.
     * @param _recipient The recipient of tokens.
     */
    function buyTokens(address _recipient) public payable {
        require(getState() == State.PROCESSING_ORDERS);

        uint256 availableTokens = tokenBalance();
        require(availableTokens > 0);

        uint256 tokensAmount = msg.value.mul(buyRate) / RATE_MULTIPLIER;
        require(tokensAmount != 0);

        uint256 refundAmount = 0;
        // if recipient set as 0x0 - recipient is sender
        address recipient = _recipient == 0x0 ? msg.sender : _recipient;

        if (tokensAmount > availableTokens) {
            refundAmount = tokensAmount.sub(availableTokens).mul(RATE_MULTIPLIER) / buyRate;
            tokensAmount = availableTokens;
        }

        token.transfer(recipient, tokensAmount);
        Buy(msg.sender, recipient, tokensAmount, buyRate);
        if (refundAmount > 0)
            recipient.transfer(refundAmount);
    }

    /**
     * @dev Allows user to sell tokens and get ether.
     * @param _recipient The recipient of ether.
     * @param tokensCount The count of tokens to sell.
     */
    function sellTokens(address _recipient, uint256 tokensCount) public {
        require(getState() == State.PROCESSING_ORDERS);
        require(tokensCount <= token.allowance(msg.sender, this));

        uint256 cryptoAmount = tokensCount.mul(RATE_MULTIPLIER) / sellRate;
        require(cryptoAmount != 0);

        if (cryptoAmount > this.balance) {
            uint256 extraTokens = (cryptoAmount - this.balance).mul(sellRate) / RATE_MULTIPLIER;
            cryptoAmount = this.balance;
            tokensCount = tokensCount.sub(extraTokens);
        }

        token.transferFrom(msg.sender, this, tokensCount);
        address recipient = _recipient == 0x0 ? msg.sender : _recipient;

        Sell(msg.sender, recipient, cryptoAmount, sellRate);
        recipient.transfer(cryptoAmount);
    }

    /**
     * @dev Requests oracles rates updating; funds oracles if needed.
     */
    function requestRates() public payable {
        require(getState() == State.REQUEST_RATES);
        // Or just sub msg.value
        // If it will be below zero - it will throw revert()
        // require(msg.value >= requestPrice());
        uint256 value = msg.value;

        for (uint256 i = 0; i < oracles.length; i++) {
            OracleI oracle = OracleI(oracles[i]);
            uint callPrice = oracle.getPrice();

            // If oracle needs funds - refill it
            if (oracles[i].balance < callPrice) {
                value = value.sub(callPrice);
                oracles[i].transfer(callPrice);
            }

            if (oracle.updateRate())
                OracleRequest(oracles[i]);
        }
        requestTime = now;

        if (value > 0)
            msg.sender.transfer(value);
    }

    /**
     * @dev Returns cost of requestRates function.
     */
    function requestPrice() public view returns(uint256) {
        uint256 requestCost = 0;
        for (uint256 i = 0; i < oracles.length; i++) {
            requestCost = requestCost.add(OracleI(oracles[i]).getPrice());
        }
        return requestCost;
    }

    /**
     * @dev Calculates buy and sell rates after oracles have received it.
     */
    function calcRates() public {
        require(getState() == State.CALC_RATES);

        uint256 minRate = 2**256 - 1; // Max for UINT256
        uint256 maxRate = 0;
        uint256 validOracles = 0;

        for (uint256 i = 0; i < oracles.length; i++) {
            OracleI oracle = OracleI(oracles[i]);
            uint256 rate = oracle.rate();
            if (oracle.waitQuery()) {
                continue;
            }
            if (isRateValid(rate)) {
                minRate = Math.min256(rate, minRate);
                maxRate = Math.max256(rate, maxRate);
                validOracles++;
            } else {
                InvalidRate(rate, oracles[i]);
            }
        }
        // If valid rates data is insufficient - throw
        if (validOracles < MIN_READY_ORACLES)
            revert();

        buyRate = minRate.mul(FEE_MULTIPLIER * RATE_MULTIPLIER - buyFee * RATE_MULTIPLIER / 100) / FEE_MULTIPLIER / RATE_MULTIPLIER;
        sellRate = maxRate.mul(FEE_MULTIPLIER * RATE_MULTIPLIER + sellFee * RATE_MULTIPLIER / 100) / FEE_MULTIPLIER / RATE_MULTIPLIER;

        calcTime = now;
    }

    /**
     * @dev Returns contract oracles&#39; count.
     */
    function oracleCount() public view returns(uint256) {
        return oracles.length;
    }

    /**
     * @dev Returns token balance of the sender.
     */
    function tokenBalance() public view returns(uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Returns data for an oracle by its id in the array.
     */
    function getOracleData(uint number)
        public
        view
        returns (address, bytes32, bytes16, bool, uint256, uint256, uint256)
                /* address, name, type, waitQuery, updTime, clbTime, rate */
    {
        OracleI curOracle = OracleI(oracles[number]);

        return(
            oracles[number],
            curOracle.oracleName(),
            curOracle.oracleType(),
            curOracle.waitQuery(),
            curOracle.updateTime(),
            curOracle.callbackTime(),
            curOracle.rate()
        );
    }

    /**
     * @dev Returns ready (which have data to be used) oracles count.
     */
    function readyOracles() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < oracles.length; i++) {
            OracleI oracle = OracleI(oracles[i]);
            if ((oracle.rate() != 0) &&
                !oracle.waitQuery() &&
                (now - oracle.updateTime()) < ORACLE_ACTUAL)
                count++;
        }

        return count;
    }

    /**
     * @dev Returns wait query oracle count.
     */
    function waitingOracles() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < oracles.length; i++) {
            if (OracleI(oracles[i]).waitQuery() && (now - requestTime) < ORACLE_TIMEOUT) {
                count++;
            }
        }

        return count;
    }

    /**
     * @dev Withdraws balance only to special hardcoded wallet ONLY WHEN contract is locked.
     */
    function withdrawReserve() public {
        require(getState() == State.LOCKED && msg.sender == withdrawWallet);
        ReserveWithdraw(this.balance);
        withdrawWallet.transfer(this.balance);
        token.burn(tokenBalance());
    }

    /**
     * @dev Allows to deposit eth to the contract without creating orders.
     */
    function refillBalance() public payable {
        ReserveRefill(msg.value);
    }

    /**
     * @dev Returns if given rate is within limits; internal.
     * @param rate Rate.
     */
    function isRateValid(uint256 rate) internal pure returns(bool) {
        return rate >= MIN_RATE && rate <= MAX_RATE;
    }
    
    function setDeadline(uint256 _deadline) public {
        deadline = _deadline;
    }

}


contract LibertyToken is StandardToken, BurnableToken {
  string public name = "LibreBank";
  string public symbol = "LBRS";
  uint256 public decimals = 18;

function LibertyToken() public {
  totalSupply_ = 100 * (10**6) * (10**decimals);
  balances[msg.sender] = totalSupply_;
}
} 

contract LBRSMultitransfer is Ownable {
    address public lbrsToken;
    address public sender;
    LibertyToken token;

    /**
     * @dev Implements transfer method for multiple recipient. Needed in LBRS token distribution process after ICO
     * @param recipient - recipient addresses array
     * @param balance - refill amounts array
     */
    function multiTransfer(address[] recipient,uint256[] balance) public {
        require(recipient.length == balance.length && msg.sender == sender);

        for (uint256 i = 0; i < recipient.length; i++) {
            token.transfer(recipient[i],balance[i]);
        }
    }

    /**
     * @dev Constructor
     * @param LBRS - LBRS token address
     */
    function LBRSMultitransfer(address LBRS, address _sender) public {
        lbrsToken = LBRS;
        sender = _sender;
        token = LibertyToken(lbrsToken);
    }

    /**
     * @dev Withdraw unsold tokens
     */
    function withdrawTokens() public onlyOwner {
        token.transfer(owner,tokenBalance());
    }

    /**
     * @dev Returns LBRS token balance of contract.
     */
    function tokenBalance() public view returns(uint256) {
        return token.balanceOf(this);
    }

     /**
     * @dev Sets new token sender address
     * @param _sender - token sender addresses
     */
    function setSender(address _sender) public onlyOwner {
        sender = _sender;
    }

    /**
     * @dev Kill contracts after ICO.
     */
    function kill() public onlyOwner {
        withdrawTokens();
        selfdestruct(owner);
    }
}