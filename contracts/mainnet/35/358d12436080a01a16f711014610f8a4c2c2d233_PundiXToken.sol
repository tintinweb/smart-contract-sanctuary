pragma solidity ^0.4.11;


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
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}


contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  MintableToken public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */ 
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

  // creates the token to be sold. 
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }


}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

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
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

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
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  
  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until 
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) 
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) 
    returns (bool success) {
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

contract BurnableToken is StandardToken {

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint _value)
        public
    {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

    event Burn(address indexed burner, uint indexed value);
}

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
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


contract PundiXToken is MintableToken, BurnableToken {

    event ShowCurrentIndex(address indexed to, uint256 value);
    event ShowBonus(address indexed to, uint256 value);

    string public constant name = "Pundi X Token";
    string public constant symbol = "PXS";
    uint8 public constant decimals = 18;

    uint256 public totalSupplyBonus;

    uint64[] public bonusTimeList = [
    1512057600,1514736000,1517414400,1519833600,1522512000,1525104000,1527782400,1530374400,1533052800,1535731200,1538323200,1541001600,
    1543593600,1546272000,1548950400,1551369600,1554048000,1556640000,1559318400,1561910400,1564588800,1567267200,1569859200,1572537600,
    1575129600,1577808000,1580486400,1582992000,1585670400,1588262400,1590940800,1593532800,1596211200,1598889600,1601481600,1604160000];


    uint8 public currentTimeIndex;

    function PundiXToken() {
        currentTimeIndex = 0;
    }

    // --------------------------------------------------------
    mapping(address=>uint256) weiBalance;
    address[] public investors;

    function addWei(address _address, uint256 _value) onlyOwner canMint public {
        uint256 value = weiBalance[_address];
        if (value == 0) {
            investors.push(_address);
        }
        weiBalance[_address] = value.add(_value);
    }

    function getInvestorsCount() constant onlyOwner public returns (uint256 investorsCount) {
        return investors.length;
    }

    function getWeiBalance(address _address) constant onlyOwner public returns (uint256 balance) {
        return weiBalance[_address];
    }

    // --------------------------------------------------------


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        bool result = super.transferFrom(_from, _to, _value);
        if (result && currentTimeIndex < bonusTimeList.length) {
            bonus(_from);
            bonus(_to);
        }
        return result;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        bool result = super.transfer(_to, _value);
        if (result && currentTimeIndex < bonusTimeList.length) {
            bonus(msg.sender);
            bonus(_to);
        }
        return result;
    }


    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        bool result = super.mint(_to, _amount);
        if (result) {
            bonus(_to);
        }
        return result;
    }

    function burn(uint256 _value) public {
        super.burn(_value);
        if (currentTimeIndex < bonusTimeList.length) {
            bonus(msg.sender);
        }

    }
    // --------------------------------------------------------

    mapping(address => User) public users;

    struct User {
        uint256 txTimestamp;
        uint256[] monthBalance;
        uint8 monthIndex;
        uint256[] receiveBonus;
        uint8 receiveIndex;
    }

    function bonus(address _address) internal {
        User storage user = users[_address];
        tryNextTimeRange();

        uint64 maxTime = bonusTimeList[currentTimeIndex];
        if (user.txTimestamp > maxTime) {
            return;
        }

        uint64 minTime = 0;
        if (currentTimeIndex > 0) {
            minTime = bonusTimeList[currentTimeIndex-1];
        }

        for (uint _i = user.monthBalance.length; _i <= currentTimeIndex; _i++) {
            user.monthBalance.push(0);
        }

        // first time
        if (user.txTimestamp == 0) {
            user.monthBalance[currentTimeIndex] = balances[_address];
            user.monthIndex = currentTimeIndex;
        } else if (user.txTimestamp >= minTime) {
            user.monthBalance[currentTimeIndex] = balances[_address];
        } else { // (user.txTimestamp < minTime) cross month
            uint256 pBalance = user.monthBalance[user.monthIndex];
            for (uint8 i = user.monthIndex; i < currentTimeIndex; i++) {
                user.monthBalance[i] = pBalance;
            }
            user.monthBalance[currentTimeIndex] = balances[_address];
            user.monthIndex = currentTimeIndex;
        }
        user.txTimestamp = now;

    }

    function tryNextTimeRange() internal {
        uint8 len = uint8(bonusTimeList.length) - 1;
        uint64 _now = uint64(now);
        for(; currentTimeIndex < len; currentTimeIndex++) {
            if (bonusTimeList[currentTimeIndex] >= _now) {
                break;
            }
        }
    }

    function receiveBonus() public {
        tryNextTimeRange();

        if (currentTimeIndex == 0) {
            return;
        }

        address addr = msg.sender;

        User storage user = users[addr];

        if (user.monthIndex < currentTimeIndex) {
            bonus(addr);
        }

        User storage xuser = users[addr];

        if (xuser.receiveIndex == xuser.monthIndex || xuser.receiveIndex >= bonusTimeList.length) {
            return;
        }


        require(user.receiveIndex < user.monthIndex);

        uint8 monthInterval = xuser.monthIndex - xuser.receiveIndex;

        uint256 bonusToken = 0;

        if (monthInterval > 6) {
            uint8 _length = monthInterval - 6;

            for (uint8 j = 0; j < _length; j++) {
                xuser.receiveBonus.push(0);
                xuser.receiveIndex++;
            }
        }

        uint256 balance = xuser.monthBalance[xuser.monthIndex];

        for (uint8 i = xuser.receiveIndex; i < xuser.monthIndex; i++) {
            uint256 preMonthBonus = calculateBonusToken(i, balance);
            balance = preMonthBonus.add(balance);
            bonusToken = bonusToken.add(preMonthBonus);
            xuser.receiveBonus.push(preMonthBonus);
            xuser.receiveIndex++;
        }

        // 事件
        ShowBonus(addr, bonusToken);

        if (bonusToken == 0) {
            return;
        }

        totalSupplyBonus = totalSupplyBonus.sub(bonusToken);

        this.transfer(addr, bonusToken);
    }

    function calculateBonusToken(uint8 _monthIndex, uint256 _balance) internal returns (uint256) {
        uint256 bonusToken = 0;
        if (_monthIndex < 12) {
            // 7.31606308769453%
            bonusToken = _balance.div(10000000000000000).mul(731606308769453);
        } else if (_monthIndex < 24) {
            // 2.11637098909784%
            bonusToken = _balance.div(10000000000000000).mul(211637098909784);
        } else if (_monthIndex < 36) {
            // 0.881870060450728%
            bonusToken = _balance.div(100000000000000000).mul(881870060450728);
        }

        return bonusToken;
    }


    function calculationTotalSupply() onlyOwner {
        uint256 u1 = totalSupply.div(10);

        uint256 year1 = u1.mul(4);
        uint256 year2 = u1.mul(2);
        uint256 year3 = u1;

        totalSupplyBonus = year1.add(year2).add(year3);
    }

    function recycleUnreceivedBonus(address _address) onlyOwner {
        tryNextTimeRange();
        require(currentTimeIndex > 34);

        uint64 _now = uint64(now);

        uint64 maxTime = bonusTimeList[currentTimeIndex];

        uint256 bonusToken = 0;

        // TODO 180 days
        uint64 finalTime = 180 days + maxTime;

        if (_now > finalTime) {
            bonusToken = totalSupplyBonus;
            totalSupplyBonus = 0;
        }

        require(bonusToken != 0);

        this.transfer(_address, bonusToken);
    }

}