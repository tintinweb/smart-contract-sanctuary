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

contract BoostoToken is StandardToken {
    using SafeMath for uint256;

    struct HourlyReward{
        uint passedHours;
        uint percent;
    }

    string public name = "Boosto";
    string public symbol = "BST";
    uint8 public decimals = 18;

    // 1B total supply
    uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);
    
    uint256 public totalRaised; // total ether raised (in wei)

    uint256 public startTimestamp; // timestamp after which ICO will start
    
    // 1 month = 1 * 30 * 24 * 60 * 60
    uint256 public durationSeconds;

    // the ICO ether max cap (in wei)
    uint256 public maxCap;

    
     // Minimum Transaction Amount(0.1 ETH)
    uint256 public minAmount = 0.1 ether;

    // 1 ETH = X BST
    uint256 public coinsPerETH = 1000;

    /**
     * hourlyRewards[hours from start timestamp] = percent
     * for example hourlyRewards[10] = 20 -- 20% more coins for first 10 hoours after ICO start
     */
    HourlyReward[] public hourlyRewards;

    /**
     * if true, everyone can participate in ICOs.
     * otherwise just whitelisted wallets can participate
     */
    bool isPublic = false;

    /**
     * mapping to save whitelisted users
     */
    mapping(address => bool) public whiteList;
    
    /**
     * Address which will receive raised funds 
     * and owns the total supply of tokens
     */
    address public fundsWallet = 0x776EFa46B4b39Aa6bd2D65ce01480B31042aeAA5;

    /**
     * Address which will manage whitelist
     * and ICOs
     */
    address private adminWallet = 0xc6BD816331B1BddC7C03aB51215bbb9e2BE62dD2;    
    /**
     * @dev Constructor
     */
    constructor() public{
        //fundsWallet = msg.sender;

        startTimestamp = now;

        // ICO is not active by default. Admin can set it later
        durationSeconds = 0;

        //initially assign all tokens to the fundsWallet
        balances[fundsWallet] = totalSupply;
        Transfer(0x0, fundsWallet, totalSupply);
    }

    /**
     * @dev Checks if an ICO is open
     */
    modifier isIcoOpen() {
        require(isIcoInProgress());
        _;
    }

    /**
     * @dev Checks if the investment amount is greater than min amount
     */
    modifier checkMin(){
        require(msg.value >= minAmount);
        _;
    }

    /**
     * @dev Checks if msg.sender can participate in the ICO
     */
    modifier isWhiteListed(){
        require(isPublic || whiteList[msg.sender]);
        _;
    }

    /**
     * @dev Checks if msg.sender is admin
     * both fundsWallet and adminWallet are considered as admin
     */

    modifier isAdmin(){
        require(msg.sender == fundsWallet || msg.sender == adminWallet);
        _;
    }

    /**
     * @dev Payable fallback. This function will be called
     * when investors send ETH to buy BST
     */
    function() public isIcoOpen checkMin isWhiteListed payable{
        totalRaised = totalRaised.add(msg.value);

        uint256 tokenAmount = calculateTokenAmount(msg.value);
        balances[fundsWallet] = balances[fundsWallet].sub(tokenAmount);
        balances[msg.sender] = balances[msg.sender].add(tokenAmount);

        Transfer(fundsWallet, msg.sender, tokenAmount);

        // immediately transfer ether to fundsWallet
        fundsWallet.transfer(msg.value);
    }

    /**
     * @dev Calculates token amount for investors based on weekly rewards
     * and msg.value
     * @param weiAmount ETH amount in wei amount
     * @return Total BST amount
     */
    function calculateTokenAmount(uint256 weiAmount) public constant returns(uint256) {
        uint256 tokenAmount = weiAmount.mul(coinsPerETH);
        // setting rewards is possible only for 4 weeks
        for (uint i = 0; i < hourlyRewards.length; i++) {
            if (now <= startTimestamp + (hourlyRewards[i].passedHours * 1 hours)) {
                return tokenAmount.mul(100+hourlyRewards[i].percent).div(100);    
            }
        }
        return tokenAmount;
    }

    /**
     * @dev Update WhiteList for an address
     * @param _address The address
     * @param _value Boolean to represent the status
     */
    function adminUpdateWhiteList(address _address, bool _value) public isAdmin{
        whiteList[_address] = _value;
    }


    /**
     * @dev Allows admin to launch a new ICO
     * @param _startTimestamp Start timestamp in epochs
     * @param _durationSeconds ICO time in seconds(1 day=24*60*60)
     * @param _coinsPerETH BST price in ETH(1 ETH = ? BST)
     * @param _maxCap Max ETH capture in wei amount
     * @param _minAmount Min ETH amount per user in wei amount
     * @param _isPublic Boolean to represent that the ICO is public or not
     */
    function adminAddICO(
        uint256 _startTimestamp,
        uint256 _durationSeconds, 
        uint256 _coinsPerETH,
        uint256 _maxCap,
        uint256 _minAmount, 
        uint[] _rewardHours,
        uint256[] _rewardPercents,
        bool _isPublic
        ) public isAdmin{

        // we can&#39;t add a new ICO when an ICO is already in progress
        assert(!isIcoInProgress());
        assert(_rewardPercents.length == _rewardHours.length);

        startTimestamp = _startTimestamp;
        durationSeconds = _durationSeconds;
        coinsPerETH = _coinsPerETH;
        maxCap = _maxCap;
        minAmount = _minAmount;

        hourlyRewards.length = 0;
        for(uint i=0; i < _rewardHours.length; i++){
            hourlyRewards[hourlyRewards.length++] = HourlyReward({
                    passedHours: _rewardHours[i],
                    percent: _rewardPercents[i]
                });
        }

        isPublic = _isPublic;
        // reset totalRaised
        totalRaised = 0;
    }

    /**
     * @dev Return true if an ICO is already in progress;
     * otherwise returns false
     */
    function isIcoInProgress() public constant returns(bool){
        if(now < startTimestamp){
            return false;
        }
        if(now > (startTimestamp + durationSeconds)){
            return false;
        }
        if(totalRaised >= maxCap){
            return false;
        }
        return true;
    }
}