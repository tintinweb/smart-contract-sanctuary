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

/**
 * @title Boosto Pool
 */
contract BoostoPool{
    using SafeMath for uint256;

    // total number of investors
    uint256 public totalInvestors;

    address[] investorsList;

    mapping(address => bool) public investors;
    mapping(address => bool) public winners;

    address private BSTContract = 0xDf0041891BdA1f911C4243f328F7Cf61b37F965b;
    address private fundsWallet;
    address private operatorWallet;

    uint256 public unit;
    uint256 public size;

    uint256 public BSTAmount;

    uint256 public winnerCount;
    uint256 public paidWinners = 0;

    uint256 public bonus;
    bool public bonusInETH;

    uint256 public startDate;
    uint256 public duration; // in seconds

    /**
     * @dev Creates a new pool
     */
    constructor(
        uint256 _startDate,
        uint256 _duration,
        uint256 _winnerCount,
        uint256 _bonus,
        bool _bonusInETH,
        uint256 _unit,
        uint256 _BSTAmount,
        uint256 _size,
        address _fundsWallet,
        address _operatorWallet
        ) public{
        
        startDate = _startDate;
        duration = _duration;
        
        winnerCount = _winnerCount;
        bonus = _bonus;
        bonusInETH = _bonusInETH;
        unit = _unit;
        BSTAmount = _BSTAmount;
        size = _size;

        fundsWallet = _fundsWallet;
        operatorWallet = _operatorWallet;
    }

    /**
     * @dev Checks if the pool is still open or not
     */
    modifier isPoolOpen() {
        require(totalInvestors < size && now < (startDate + duration) && now >= startDate);
        _;
    }

    /**
     * @dev Checks if the pool is closed
     */
    modifier isPoolClosed() {
        require(totalInvestors >= size || now >= (startDate + duration));
        _;
    }

    /**
     * @dev Checks if the pool is finished successfully
     */
    modifier isPoolFinished() {
        require(totalInvestors >= size);
        _;
    }

    /**
     * @dev modifier for check msg.value
     */
    modifier checkInvestAmount(){
        require(msg.value == unit);
        _;
    }

    /**
     * @dev check if the sender is already invested
     */
    modifier notInvestedYet(){
        require(!investors[msg.sender]);
        _;
    }

    /**
     * @dev check if the sender is admin
     */
    modifier isAdmin(){
        require(msg.sender == operatorWallet);
        _;
    }

    /**
     * @dev fallback function
     */
    function() checkInvestAmount notInvestedYet isPoolOpen payable public{
        fundsWallet.transfer(msg.value);

        StandardToken bst = StandardToken(BSTContract);
        bst.transfer(msg.sender, BSTAmount);

        investorsList[investorsList.length++] = msg.sender;
        investors[msg.sender] = true;

        totalInvestors += 1;
    }

    /**
     * @dev Allows the admin to tranfer ETH to SC 
     * when bounus is in ETH
     */
    function adminDropETH() isAdmin payable public{
        assert(bonusInETH);
        assert(msg.value == winnerCount.mul(bonus));
    }

    /**
     * @dev Allows the admin to withdraw remaining token and ETH when
     * the pool is closed and not reached the goal(no rewards)
     */
    function adminWithdraw() isAdmin isPoolClosed public{
        assert(totalInvestors <= size);

        StandardToken bst = StandardToken(BSTContract);
        uint256 bstBalance = bst.balanceOf(this);

        if(bstBalance > 0){
            bst.transfer(msg.sender, bstBalance);
        }

        uint256 ethBalance = address(this).balance;
        if(ethBalance > 0){
            msg.sender.transfer(ethBalance);
        }
    }

    /**
     * @dev Selects a random winner and transfer the funds.
     * This function could fail when the selected wallet is a duplicate winner
     * and need to try again to select an another random investor.
     * When we have N winners, the admin need to call this function N times. This is 
     * not an efficient method but since we have just a few winners it will work fine.
     */
    function adminAddWinner() isPoolFinished isAdmin public{
        assert(paidWinners < winnerCount);
        uint256 winnerIndex = random();
        assert(!winners[investorsList[winnerIndex]]);

        winners[investorsList[winnerIndex]] = true;
        paidWinners += 1;

        if(bonusInETH){
            investorsList[winnerIndex].transfer(bonus);
        }else{
            StandardToken(BSTContract).transfer(investorsList[winnerIndex], bonus);
        }
    }

    /**
     * @dev Selects a random winner among all investors
     */
    function random() public view returns (uint256) {
        return uint256(keccak256(block.timestamp, block.difficulty))%size;
    }

    /**
     * @dev Returns the details of an investor by its index.
     * UI can use this function to show the info.
     * @param index Index of the investor in investorsList
     */
    function getWalletInfoByIndex(uint256 index) 
            public constant returns (address _addr, bool _isWinner){
        _addr = investorsList[index];
        _isWinner = winners[_addr];
    }

    /**
     * @dev Returns the details of an investor
     * UI can use this function to show the info.
     * @param addr Address of the investor
     */
    function getWalletInfo(address addr) 
            public constant returns (bool _isWinner){
        _isWinner = winners[addr];
    }

    /**
     * @dev checks if there is enough funds in the contract or not
     * @param status Boolean to show if there is enough funds or not
     */
    function isHealthy() 
            public constant returns (bool status){

        // ETH balance is not enough
        if(bonusInETH && address(this).balance < winnerCount.mul(bonus)){
            return false;
        }
        
        uint256 bstBalance = StandardToken(BSTContract).balanceOf(this);

        uint256 enoughBalance = BSTAmount.mul(size - totalInvestors); 
        if(!bonusInETH){
            enoughBalance = bstBalance.add(winnerCount.mul(bonus));
        }
        if(bstBalance < enoughBalance){
            return false;
        }
        return true;
    }
}

contract BoostoPoolFactory {

    event NewPool(address creator, address pool);

    function createNew(
        uint256 _startDate,
        uint256 _duration,
        uint256 _winnerCount,
        uint256 _bonus,
        bool _bonusInETH,
        uint256 _unit,
        uint256 _BSTAmount,
        uint256 _size,
        address _fundsWallet,
        address _operatorWallet
    ) public returns(address created){
        address ret = new BoostoPool(
            _startDate,
            _duration,
            _winnerCount,
            _bonus,
            _bonusInETH,
            _unit,
            _BSTAmount,
            _size,
            _fundsWallet,
            _operatorWallet
        );
        emit NewPool(msg.sender, ret);
    }
}