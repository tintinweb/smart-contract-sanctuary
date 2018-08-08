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

contract Token {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

contract Pausable is Ownable {

  uint public endDate;

  /**
   * @dev modifier to allow actions only when the contract IS not paused
   */
  modifier whenNotPaused() {
    require(now >= endDate);
    _;
  }

}

contract StandardToken is Token, Pausable {
    using SafeMath for uint256;
    mapping (address => mapping (address => uint256)) internal allowed;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0));
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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0));
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
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

contract ABsCoins is StandardToken {

    string public constant name = "ABsCoinss";
    string public constant symbol = "ABSDS";
    uint8 public constant decimals = 18;
    address public tokenWallet;
    address public teamWallet = 0x6DF8FFA78987EbfC7078ab3223732Ddda074f7D2;

    uint256 public constant INITIAL_SUPPLY = 29000000 ether;

    function ABsCoins (address tokenOwner, uint _endDate) public{
        totalSupply = INITIAL_SUPPLY;
        balances[teamWallet] = 7424000 ether;
        balances[tokenOwner] = INITIAL_SUPPLY - balances[teamWallet];
        endDate = _endDate;
        tokenWallet = tokenOwner;
        emit Transfer(0x0, teamWallet, balances[teamWallet]);
        emit Transfer(0x0, tokenOwner, balances[tokenOwner]);
    }

    function sendTokens(address _to, uint _amount) external onlyOwner {
        require(_amount <= balances[tokenWallet]);
        balances[tokenWallet] -= _amount;
        balances[_to] += _amount;
        emit Transfer(tokenWallet, msg.sender, _amount);
    }

}

contract SalesManager is Ownable {
    using SafeMath for uint256;

    /**
     *
        Pre-ICO
        Start date: January 21, 2018 (09:00 AM EST Time)
        End date: February 21, 2018 (09:00 AM EST Time)
        The number of tokens available: 1 305 000
        Currency accepted: ETH, BTC
        Token exchange rate: 1 ETH = 2400 ABsCoins
        Minimum transaction amount in Ethereum: 0.1 ETH
        Minimum transaction amount in Bitcoin: 0.01 BTC
        Bonuses:
        Day 1-2: +40% bonus
        Day 3-10: +30% bonus
        Day 11-30: +25% bonus //check

        ICO
        Start date: March 21, 2018 (09:00 AM EST Time)
        End date: April 21, 2018 (09:00 AM EST Time)
        The number of tokens available: 20 271 000
        Currency accepted: ETH, BTC
        Token exchange rate: 1 ETH = 2400 ABsCoins
        Minimum transaction amount in Ethereum: 0.1 ETH
        Minimum transaction amount in Bitcoin: 0.01 BTC
        Bonuses:
        Day 1: +15% bonus
        Day 2-10: +10% bonus
        Day 11-20: +5% bonus
        Day 21-31: 0% bonus
    **/

    uint public constant startDate = 1532689569;
    uint public constant endPreICO = 1532692158;

    uint public constant startICO = 1532692158;
    uint public constant endDate = 1532695758;

    uint constant bonus40 = startDate + 2 days;
    uint constant bonus30 = startDate + 10 days;
    uint constant bonus25 = startDate + 31 days;

    uint constant bonus15 = startICO + 1 days;
    uint constant bonus10 = startICO + 10 days;
    uint constant bonus5 = startICO + 31 days;


    struct Stat {
        uint currentFundraiser;
        uint btcAmount;
        uint ethAmount;
        uint txCounter;
    }

    Stat public stat;

    uint public constant preIcoCap = 1305000 ether;
    uint public constant IcoCap = 20271000 ether;


    uint256 tokenRate = 50;
    address public tokenAddress = 0xF4ae690f7f641295e7EE66093e19DA6fbFC620Ab;

    address public tokenOwner = 0xF4ae690f7f641295e7EE66093e19DA6fbFC620Ab;

    /**
     * @dev modifier to allow actions only when Pre-ICO end date is now
     */
    modifier isFinished() {
        require(now >= endDate);
        _;
    }

    function isPreICO() internal view returns (bool) {
        if (now >= startDate && now < endPreICO) {
            return true;
        } else {
            return false;
        }
    }

    function isICO() internal view returns (bool) {
        if (now >= startICO && now < endDate) {
            return true;
        } else {
            return false;
        }
    }

    function SalesManager () public{
        tokenAddress = new ABsCoins(tokenOwner, endDate);
    }

    function () payable public {
        if (msg.value < 0.1 ether || (!isPreICO() && !isICO())) revert();
        buyTokens();
    }

    function buyTokens() internal {
        uint256 tokens = msg.value.mul(tokenRate);
        if(isPreICO()){
            if (now <= bonus40) {
                tokens += tokens * 40 / 100;
            } else if (bonus40 > now &&  now <= bonus30) {
                tokens += tokens * 30 / 100;
            } else if (bonus30 > now &&  now <= bonus25) {
                tokens += tokens * 25 / 100;
            }

            uint256 balance = preIcoCap.sub(stat.currentFundraiser);
            if (balance < tokens) {
                uint toReturn = tokenRate.mul(tokens.sub(balance));
                msg.sender.transfer(toReturn);
                sendTokens(balance, msg.value - toReturn);
            } else {
                sendTokens(tokens, msg.value);
            }
        } else if (isICO()) {
            if (now <= bonus15) {
                tokens += tokens * 15 / 100;
            } else if (bonus15 > now &&  now <= bonus10) {
                tokens += tokens * 10 / 100;
            } else if (bonus10 > now &&  now <= bonus5) {
                tokens += tokens * 5 / 100;
            }

            uint256 balanceIco = IcoCap.sub(stat.currentFundraiser);
            if (balanceIco < tokens) {
                toReturn = tokenRate.mul(tokens.sub(balanceIco));
                msg.sender.transfer(toReturn);
                sendTokens(balanceIco, msg.value - toReturn);
            } else {
                sendTokens(tokens, msg.value);
            }
        }  else {
            revert();
        }

    }

    function sendTokens(uint _amount, uint _ethers) internal {
        ABsCoins tokenHolder = ABsCoins(tokenAddress);
        tokenHolder.sendTokens(msg.sender, _amount);
        stat.currentFundraiser += _amount;
        tokenOwner.transfer(_ethers);
        stat.ethAmount += _ethers;
        stat.txCounter += 1;
    }

    function sendTokensManually(address _to, uint _amount, uint _btcAmount) public onlyOwner {
        require(_to != address(0));
        ABsCoins tokenHolder = ABsCoins(tokenAddress);
        tokenHolder.sendTokens(_to, _amount);
        stat.currentFundraiser += _amount;
        stat.btcAmount += _btcAmount;
        stat.txCounter += 1;
    }

    function setTokenRate(uint newTokenRate) public onlyOwner {
        tokenRate = newTokenRate;
    }

}