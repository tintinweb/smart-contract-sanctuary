/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

/**
* @title CryptolottoToken
* This smart contract is a part of Cryptolotto (cryptolotto.cc) product.
*
* Cryptolotto is a blockchain-based, Ethereum powered lottery which gives to users the most 
* transparent and honest chances of winning.
*
* The main idea of Cryptolotto is straightforward: people from all over the world during the 
* set period of time are contributing an equal amount of ETH to one wallet. When a timer ends 
* this smart-contract powered wallet automatically sends all received ETHs to a one randomly 
* chosen wallet-participant.
*
* Due to the fact that Cryptolotto is built on a blockchain technology, it eliminates any 
* potential for intervention by third parties and gives 100% guarantee of an honest game.
* There are no backdoors and no human or computer soft can interfere the process of picking a winner.
*
* If during the game only one player joins it, then the player will receive all his ETH back.
* If a player sends not the exact amount of ETH - he will receive all his ETH back.
* Creators of the product can change the entrance price for the game. If the price is changed 
* then new rules are applied when a new game starts.
*
* The original idea of Cryptolotto belongs to t.me/crypto_god and t.me/crypto_creator - Founders.
* Cryptolotto smart-contracts are the property of Founders and are protected by copyright,
* trademark, patent, trade secret, other intellectual property, proprietary rights laws and other applicable laws.
*
* All information related to the product can be found only on: 
* - cryptolotto.cc
* - github.com/cryptolotto
* - instagram.com/cryptolotto
* - facebook.com/cryptolotto
*
* Crytolotto was designed and developed by erde.group (t.me/erdegroup).
**/
contract CryptolottoToken is StandardToken {
    /**
    * @dev Token name.
    */
    string public constant name = "Cryptolotto";
    
    /**
    * @dev Token symbol.
    */
    string public constant symbol = "CRY";
    
    /**
    * @dev Amount of decimals.
    */
    uint8 public constant decimals = 18;

    /**
    * @dev Amount of tokens supply.
    */
    uint256 public constant INITIAL_SUPPLY = 100000 * (10 ** uint256(decimals));
 
    /**
    * @dev Token holder struct.
    */
    struct TokenHolder {
        uint balance;
        uint balanceUpdateTime;
        uint rewardWithdrawTime;
    }

    /**
    * @dev Store token holder balances updates time.
    */
    mapping(address => TokenHolder) holders;

    /**
    * @dev Amount of not distributed wei on this dividends period.
    */
    uint256 public weiToDistribute;

    /**
    * @dev Amount of wei that will be distributed on this dividends period.
    */
    uint256 public totalDividends;

    /**
    * @dev Didents period.
    */
    uint256 public period = 2592000;

    /**
    * @dev Store last period start date in timestamp.
    */
    uint256 public lastPeriodStarDate;

    /**
    * @dev Checks tokens balance.
    */
    modifier tokenHolder() {
        require(balanceOf(msg.sender) > 0);
        _;
    }

    /**
    * @dev Constructor that gives msg.sender all of existing tokens.
    */
    function CryptolottoToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
        lastPeriodStarDate = now - period;
    }

    /**
    * @dev Starts dividends period and allow withdraw dividends.
    */
    function startDividendsPeriod() public {
        require(lastPeriodStarDate + period < now);
        weiToDistribute += address(this).balance - weiToDistribute;
        totalDividends = weiToDistribute;
        lastPeriodStarDate += period;
    }

    /**
    * @dev Transfer coins.
    *
    * @param receiver The address to transfer to.
    * @param amount The amount to be transferred.
    */
    function transfer(address receiver, uint256 amount) public returns (bool) {
        beforeBalanceChanges(msg.sender);
        beforeBalanceChanges(receiver);

        return super.transfer(receiver, amount);
    }

    /**
    * @dev Transfer coins.
    *
    * @param from Address from which will be withdrawn tokens.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transferFrom(address from, address to, uint256 value) 
        public 
        returns (bool) 
    {
        beforeBalanceChanges(from);
        beforeBalanceChanges(to);

        return super.transferFrom(from, to, value);
    }

    /**
    * @dev Fix last balance updates.
    */
    function beforeBalanceChanges(address _who) internal {
        if (holders[_who].balanceUpdateTime <= lastPeriodStarDate) {
            holders[_who].balanceUpdateTime = now;
            holders[_who].balance = balanceOf(_who);
        }
    }

    /**
    * @dev Calculate token holder reward.
    */
    function reward() view public returns (uint) {
        if (holders[msg.sender].rewardWithdrawTime >= lastPeriodStarDate) {
            return 0;
        }
        
        uint256 balance;
        if (holders[msg.sender].balanceUpdateTime <= lastPeriodStarDate) {
            balance = balanceOf(msg.sender);
        } else {
            balance = holders[msg.sender].balance;
        }

        return totalDividends * balance / INITIAL_SUPPLY;
    }

    /**
    * @dev Allow withdraw reward.
    */
    function withdrawReward() public returns (uint) {
        uint value = reward();
        if (value == 0) {
            return 0;
        }
        
        if (!msg.sender.send(value)) {
            return 0;
        }
        
        if (balanceOf(msg.sender) == 0) {
            // garbage collector
            delete holders[msg.sender];
        } else {
            holders[msg.sender].rewardWithdrawTime = now;
        }

        weiToDistribute -= value;

        return value;
    }
    /**
    * @dev Simple payable function that allows accept ether.
    */
    function() public payable {}
}