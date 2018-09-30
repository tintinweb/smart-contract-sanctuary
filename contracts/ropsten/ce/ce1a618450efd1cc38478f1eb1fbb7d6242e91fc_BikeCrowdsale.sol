pragma solidity 0.4.24;

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
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
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
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
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
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
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
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts/BikeCrowdsale.sol

//import "./BlockchainBikeToken.sol";
contract BikeCrowdsale is Ownable, StandardToken {
    string public constant name = "Blockchain based Bike Token"; // name of token
    string public constant symbol = "BBT"; // symbol of token
    uint8 public constant decimals = 18;

    using SafeMath for uint256;

    struct Investor {
        uint256 weiDonated;
        uint256 tokensGiven;
        uint256 freeTokens;
    }

    mapping(address => Investor) participants;

    uint256 public totalSupply= 5*10**9 * 10**18; // total supply 
    uint256 public hardCap = 1000000 * 10**18; // 1 million ether = 1 m * 10^18 Wei
    uint256 public minimalGoal = 1000 * 10**18; // 1k ether = 1k * 10^18 Wei
    uint256 public weiToToken = 5000; // 1 ether = 5000 tokens
    uint256 public totalSoldTokens = 0;
    uint256 public openingTime = 1537372800; // date -j -f "%Y-%m-%d %H:%M:%S" "2018-09-20 00:00:00" "+%s"
    uint256 public closingTime = 1568044800; // date -j -f "%Y-%m-%d %H:%M:%S" "2019-09-10 00:00:00" "+%s";

    uint256 public totalCollected; // unit: Wei

    bool public ICOstatus = true; // true - active, false - inactive
    bool public hardcapReached = false; // true - the cap is reached, false - the cap is not reached
    bool public minimalgoalReached = false; // true - the goal is reached, false - the goal is not reached
    bool public isRefundable = true; // can refund or not

    address public forSale; // fund address for sale 
    address public ecoSystemFund; // fund address for eco-system
    address public founders; // fund address for founders
    address public team; // fund address for team
    address public advisers; // fund address for advisors
    address public bounty; // fund address for bountry
    address public affiliate; // fund address for affiliate

    address private crowdsale;
 
    //BlockchainBikeToken public token;


  constructor(
    //address _token
    ) public {

    require(hardCap > minimalGoal);
    require(openingTime < closingTime);
    //token = BlockchainBikeToken(_token);
    crowdsale = address(this);

    forSale = 0xf6ACFDba39D8F786D0D2781A1D20C82E47adF8b7;
    ecoSystemFund = 0x5A77aAE15258a2a4445C701d63dbE74016F7e629;
    founders = 0xA80A449514541aeEcd3e17BECcC74a86e3de6bfA;
    team = 0x309d62B8eaDF717b76296326CA35bB8f2D996B1a;
    advisers = 0xc4319217ca328F7518c463D6D3e78f68acc5B076;
    bounty = 0x3605e4E99efFaB70D0C84aA2beA530683824246f;
    affiliate = 0x1709365100eD9B7c417E0dF0fdc32027af1DAff1;

    /*forSale = _forSale;
    ecoSystemFund = _ecoSystemFund;
    founders = _founders;
    team = _team;
    advisers = _advisers;
    bounty = _bountry;
    affiliate = _affiliate;*/

    balances[team] = totalSupply * 28 / 100;
    balances[founders] = totalSupply * 12 / 100;
    balances[bounty] = totalSupply * 1 / 100;
    balances[affiliate] = totalSupply * 1 / 100;
    balances[advisers] = totalSupply * 1 / 100;
    balances[ecoSystemFund] = totalSupply * 5 / 100;
    balances[forSale] = totalSupply * 52 / 100;

    emit Transfer(0x0, team, balances[team]);
    emit Transfer(0x0, founders, balances[founders]);
    emit Transfer(0x0, bounty, balances[bounty]);
    emit Transfer(0x0, affiliate, balances[affiliate]);
    emit Transfer(0x0, advisers, balances[advisers]);
    emit Transfer(0x0, ecoSystemFund, balances[ecoSystemFund]);
    emit Transfer(0x0, forSale, balances[forSale]);
  }


  // returns address of crowdsale token, The token must be ERC20-compliant
  /*function getToken() view public onlyOwner() returns(address) {
    return address(token);
  }*/


  function () external payable {

    require(msg.value >= 0.1 ether); // minimal ether to buy
    require(now >= openingTime);
    require(now <= closingTime);
    require(hardCap > totalCollected);
    require(isICOActive());
    require(!hardcapReached);

    sellTokens(msg.sender, msg.value); // the msg.value is in wei
  }


  function sellTokens(address _recepient, uint256 _value) private
  {
    require(_recepient != 0x0); // 0x0 is meaning to destory(burn)
    require(now >= openingTime && now <= closingTime);

    // the unit of the msg.value is in wei 

    // if reaching the hard cap, we allow the user to pay partial ethers and get partial tokensSold
    // then, we will refund reset ethers to the buyer&#39;s address
    uint256 newTotalCollected = totalCollected + _value; // unit: wei

    if (hardCap <= newTotalCollected) {
        hardcapReached = true; // reach the hard cap
        ICOstatus = false;  // close the ICO
        isRefundable = false; // can&#39;t refund
        minimalgoalReached = true;
    }

    totalCollected = totalCollected + _value; // unit: wei

    if (minimalGoal <= newTotalCollected) {
        minimalgoalReached = true; // reach the minimal goal (soft cap)
        isRefundable = false; // can&#39;t refund
    }

    uint256 tokensSold = _value * weiToToken; // token = eth * rate
    uint256 bonusTokens = 0;
    bonusTokens = getBonusTokens(tokensSold);
    if (bonusTokens > 0) {
        tokensSold += bonusTokens;
    }

        require(balances[forSale] > tokensSold);
        balances[forSale] -= tokensSold;
        balances[_recepient] += tokensSold;
        emit Transfer(forSale, _recepient, tokensSold);

    participants[_recepient].weiDonated += _value;
    participants[_recepient].tokensGiven += tokensSold;

    totalSoldTokens += tokensSold;    // total sold tokens
  }


  function isICOActive() private returns (bool) {
    if (now >= openingTime  && now <= closingTime && !hardcapReached) {
        ICOstatus = true;
    } else {
        ICOstatus = false;
    }
    return ICOstatus;
  }


  function refund() public {
    require(now >= openingTime);
    require(now <= closingTime);
    require(isRefundable);

    uint256 weiDonated = participants[msg.sender].weiDonated;
    uint256 tokensGiven = participants[msg.sender].tokensGiven;

    require(weiDonated > 0);
    require(tokensGiven > 0);

    require(forSale != msg.sender);
    require(balances[msg.sender] >= tokensGiven); 

    balances[forSale] += tokensGiven;
    balances[msg.sender] -= tokensGiven;
    emit Transfer(msg.sender, forSale, tokensGiven);

    // if refundSaleTokens fail, it will throw
    msg.sender.transfer(weiDonated);    // unit: wei, refund ether to buyer

    participants[msg.sender].weiDonated = 0;    // set balance of wei to 0
    participants[msg.sender].tokensGiven = 0;   // set balance of token to 0
    participants[msg.sender].freeTokens = 0; // set free token to 0
 
    // re-calcuate total tokens & total wei of funding
    totalSoldTokens -= tokensGiven;
    totalCollected -= weiDonated;
  }


  function transferICOFundingToWallet(uint256 _value) public onlyOwner() {
        forSale.transfer(_value); // unit wei
  }

  function getBonusTokens(uint256 _tokensSold) view public returns (uint256) {

    uint256 bonusTokens = 0;
    uint256 bonusBeginTime = openingTime; // Sep-08
    // date -j -f "%Y-%m-%d %H:%M:%S" "2018-09-10 00:00:00" "+%s"
    if (now >= bonusBeginTime && now <= bonusBeginTime+86400*7) {
        bonusTokens = _tokensSold * 20 / 100;
    } else if (now > bonusBeginTime+86400*7 && now <= bonusBeginTime+86400*14) {
        bonusTokens = _tokensSold * 15 / 100;
    } else if (now > bonusBeginTime+86400*14 && now <= bonusBeginTime+86400*21) {
        bonusTokens = _tokensSold * 10 / 100;
    } else if (now > bonusBeginTime+86400*21 && now <= bonusBeginTime+86400*30) {
        bonusTokens = _tokensSold * 5 / 100;
    }

    uint256 newTotalSoldTokens = _tokensSold + bonusTokens;
    uint256 hardCapTokens = hardCap * weiToToken;
    if (hardCapTokens < newTotalSoldTokens) {
        bonusTokens = 0;
    }

    return bonusTokens;
  }

    function getCrowdsaleStatus() view public onlyOwner() returns (bool,bool,bool,bool) {
        return (ICOstatus,isRefundable,minimalgoalReached,hardcapReached);
    }

  function getCurrentTime() view public onlyOwner() returns (uint256) {
    return now;
  }

  function sendFreeTokens(address _to, uint256 _value) public onlyOwner() {
    require(_to != 0x0); // 0x0 is meaning to destory(burn)
    require(participants[_to].freeTokens <= 1000); // maximum total free tokens per user
    require(_value <= 100); // maximum free tokens per time
    require(_value > 0);
    require(forSale != _to);
    require(balances[forSale] > _value);

    participants[_to].freeTokens += _value;
    participants[_to].tokensGiven += _value;
    totalSoldTokens += _value;    // total sold tokens

    balances[forSale] -= _value;
    balances[_to] += _value;

    emit Transfer(forSale, _to, _value);
  }

  // get free tokens in user&#39;s account
  function getFreeTokensAmountOfUser(address _to) view public onlyOwner() returns (uint256) {
    require(_to != 0x0); // 0x0 is meaning to destory(burn)
    uint256 _tokens = 0;
    _tokens = participants[_to].freeTokens;
    return _tokens;
  }

  function getBalanceOfAccount(address _to) view public onlyOwner() returns (uint256, uint256) {
    return (participants[_to].weiDonated, participants[_to].tokensGiven);
  }

    function transferFundsTokens(address _from, address _to, uint256 _value) public onlyOwner() {
        require(_from == team || _from == founders || _from == bounty || _from == affiliate || _from == advisers || _from == ecoSystemFund || _from == forSale);
        require(_to == team || _to == founders || _to == bounty || _to == affiliate || _to == advisers || _to == ecoSystemFund || _to == forSale);
        require(_value > 0);
        require(balances[_from] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;

        emit Transfer(_from, _to, _value);
    }
}