pragma solidity ^0.4.18;

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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract OwnableChild {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function setOwner(address _owner) internal {
        owner = _owner;
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
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

}

/**
 * Projects / Tribes / Crowdfunds
 */
contract Tribe is StandardToken, OwnableChild
{
    // ======================================================================================
    // ======================================================================================
    // ======================================================================================
    // TOKEN

    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 1000 * (10 ** uint256(decimals));
    string public name;
    string public symbol;
    address public tribePlatform;

    /**
     * token constructor
     */
    function Tribe(address _owner, string _name, string _symbol, address _tribePlatform) public {
        setOwner(_owner);
        name = _name;
        symbol = _symbol;
        tribePlatform = _tribePlatform;

        // init token
        totalSupply_ = INITIAL_SUPPLY;
        balances[owner] = INITIAL_SUPPLY;
    }

    /*
    function createProduct(string _name, bool _mintable, uint256 _price) public {
        TribePlatform tribePlatformContract = TribePlatform(tribePlatform);
        return tribePlatformContract.createProduct(_name, _mintable, _price, address(this));
    }
    */

    // ======================================================================================
    // ======================================================================================
    // ======================================================================================
    // CROWDFUND

    struct Crowdfund {
        uint amount;
        uint fundingGoal;
        uint raisedFunds;
        uint payoutFunds;
        address[] funderAddresses;
        address[] payoutAddresses;
        mapping(address => uint) funds; // WEI
        mapping(address => uint) payouts; // WEI
    }
    //Crowdfund[] public crowdfunds;
    mapping(uint => Crowdfund) internal crowdfunds;
    bool public crowdfundActive;
    uint public crowdfundIndex = 0;

    /**
     * start a new crowdfund in this tribe
     * owner gives away &quot;amount&quot; of tokens for a sum of ether (&quot;goal&quot;)
     */
    function startCrowdfund(uint _amount, uint _goal) public onlyOwner returns(bool){
        require(crowdfundActive == false); // cant be active
        require(balances[owner] >= _amount); // owner balance must include goal

        // lock owners balance
        balances[owner] -= _amount;

        // start crowdfund
        /*crowdfunds.push(Crowdfund({
            amount: _amount,
            fundingGoal: _goal,
            raisedFunds: 0,
            payoutFunds: _goal,
            funderAddresses: new address[](0),
            payoutAddresses: new address[](0)
        }));*/
        crowdfundActive = true;
        crowdfundIndex += 1;
        crowdfunds[crowdfundIndex] = Crowdfund({
            amount: _amount,
            fundingGoal: _goal,
            raisedFunds: 0,
            payoutFunds: _goal,
            funderAddresses: new address[](0),
            payoutAddresses: new address[](0)
        });
        return true;
    }

    /**
     * Set amount and addresses of crowdfund beneficiaries
     */
    function setCrowdfundPayout(address _recipient, uint _payout) public onlyOwner returns(bool){
    //function setCrowdfundPayout(address _recipient, uint _payout) public returns(bool){
        Crowdfund storage c = crowdfunds[crowdfundIndex];
        require(crowdfundActive == true); // must be active
        require(c.payoutFunds >= _payout); // payout must be possible

        // add address if it doesnt exist
        if(c.payouts[_recipient] <= 0){
            c.payoutAddresses.push(_recipient);
        }

        // add to payouts, remove from total payouts
        c.payouts[_recipient] += _payout;
        c.payoutFunds -= _payout;
    }

    /**
     * get payout amount of user
     */
    function payoutOf(address _user) public view returns (uint256) {
        Crowdfund storage c = crowdfunds[crowdfundIndex];
        return c.payouts[_user];
    }

    /**
     * Pay into crowdfund / invest
     */
    function fundCrowdfund() public payable returns(bool){
        require(msg.value > 0); // no empty payment
        require(crowdfundActive == true); // must be active
        Crowdfund storage c = crowdfunds[crowdfundIndex];
        require(c.raisedFunds < c.fundingGoal);  // goal was not reached (DOUBLE CHECK?)
        // require(msg.value <= (s.fundingGoal - s.raisedFunds)); // limit funds (to fundingGoal)
        
        // add address if it doesnt exist
        if(c.funds[msg.sender] <= 0){
            c.funderAddresses.push(msg.sender);
        }

        // add funds, limit funds (to fundingGoal) = no overflow!
        uint leftFunds = (c.fundingGoal - c.raisedFunds);
        uint addingFunds = (msg.value <= leftFunds) ? msg.value : leftFunds;
        c.funds[msg.sender] += addingFunds;
        c.raisedFunds += addingFunds;

        // reached goal, payout artist
        if(c.raisedFunds >= c.fundingGoal){
            return finishSuccessfulCrowdfund(c);
        }

        return true;
    }

    /**
     * get funding amount of user
     */
    function fundOf(address _user) public view returns (uint256) {
        //require(crowdfundActive == true); // must be active
        Crowdfund storage c = crowdfunds[crowdfundIndex];
        return c.funds[_user];
    }

    /**
     * crowdfund payout and token distribution
     * TODO: check if there can be multiple fundings, and multiple &quot;funderAddresses&quot; entries ? (like with balanceAddresses ?) probably not...
     */
    function finishSuccessfulCrowdfund(Crowdfund storage c) private returns(bool){
        // distribute ETH (payout plan)
        for(uint p=0; p<c.payoutAddresses.length; p++){
            address pa = c.payoutAddresses[p];
            if(c.payouts[pa] > 0){
                // try sending payout, else add payout to owner address
                if(!pa.send(c.payouts[pa])){
                    c.payoutFunds += c.payouts[pa];
                }
            }
        }
        owner.transfer(c.payoutFunds);

        // give coins to funders
        uint256 amountLeft = c.amount;
        for(uint f=0; f<c.funderAddresses.length; f++){
            address fa = c.funderAddresses[f];
            // correct rounding errors (on last funder)
            if(f == (c.funderAddresses.length - 1)){
                balances[fa] += amountLeft;
                Transfer(owner, fa, amountLeft);
                amountLeft -= amountLeft;
            }else{
                uint256 addingAmount = (c.amount * c.funds[fa]) / c.raisedFunds;
                balances[fa] += addingAmount;
                Transfer(owner, fa, addingAmount);
                amountLeft -= addingAmount;
            }
        }

        // close crowdfund
        crowdfundActive = false;

        return true;
    }

    /**
     * abort current crowdfund, revert all locked tokens and ETH
     */
    function abortCrowdfund() public onlyOwner returns(bool){
        require(crowdfundActive == true);
        Crowdfund storage c = crowdfunds[crowdfundIndex];

        // lock owners balance
        balances[owner] += c.amount;

        // return ETH to funders
        for(uint f=0; f<c.funderAddresses.length; f++){
            address fa = c.funderAddresses[f];
            fa.transfer(c.funds[fa]);
        }

        return true;
    }

    // ======================================================================================
    // ======================================================================================
    // ======================================================================================
    // REVENUES

    uint256 public dividendPerToken;
    mapping(address => uint256) dividendBalanceOf;
    mapping(address => uint256) dividendCreditedTo;

    /**
     *
     */
    function update(address _user) internal {
        uint256 owed = dividendPerToken - dividendCreditedTo[_user];
        dividendBalanceOf[_user] += balanceOf(_user) * owed;
        dividendCreditedTo[_user] = dividendPerToken;
    }

    /**
     * TODO: remove rounding errors
     * TODO: check if simple payments can be made, and if the gas price is set automatically higher (default transaction don&#39;t work)
     * This default payment cannot be called by &quot;transfer&quot; or &quot;send&quot; from another contract (because of gas limitation, we need more gas for state change)
     * WORKAROUND: call &quot;TRIBEADDRESS.call.value(WEIVALUE)()&quot;
     */
    function() public payable{
        dividendPerToken += msg.value / totalSupply();  // ignoring remainder
    }

    /**
     *
     */
    function withdraw() public {
        update(msg.sender);
        uint256 amount = dividendBalanceOf[msg.sender];
        dividendBalanceOf[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    // ======================================================================================
    // REVENUES - OVERRIDE PARENT FUNCTIONS (simple ERC20 contract)

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

        update(_from);  // <-- added to simple ERC20 contract
        update(_to);    // <-- added to simple ERC20 contract

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        update(msg.sender);  // <-- added to simple ERC20 contract
        update(_to);          // <-- added to simple ERC20 contract

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    // ======================================================================================

    /**
     * TODO: probably better to call the contract directly for now
     */
    /*function createProduct() public onlyOwner returns(bool){
        {{tribePlatform->tribeProducts}}
    }*/
}