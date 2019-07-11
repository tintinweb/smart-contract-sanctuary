/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

/**
 *Submitted for verification at Etherscan.io on 2019-06-20
*/

/**
 *Submitted for verification at Etherscan.io on 2019-05-27
*/

pragma solidity >=0.4.25 <0.6.0;

/** ----------------------------------------------------------------------------
* @title ERC Token Standard #20 Interface
* https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
* ----------------------------------------------------------------------------
*/
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract ERC20 is ERC20Interface, Ownable {
  
  using SafeMath for uint256;

  mapping (address => uint256) internal _balances;

  mapping (address => mapping (address => uint256)) internal _allowed;

  uint256 internal _totalSupply;
  

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }


  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }


  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _allowed[from][msg.sender]); 
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance( address spender, uint256 addedValue) public returns (bool) { 
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance( address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0));
    require(amount <= _balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 amount) internal {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
 
  /**
  * @dev Internal transfer, only can be called by this contract
  */
  function _transfer(address _from, address _to, uint256 value) internal {
    require(value <= _balances[_from]);
    require(_to != address(0));
    require(_balances[_to] < _balances[_to] + value);
    _balances[_from] = _balances[_from].sub(value);
    _balances[_to] = _balances[_to].add(value);
    emit Transfer(_from, _to, value);
  }

}


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 */
contract MintableToken is ERC20 {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint( address _to, uint256 _amount) hasMintPermission canMint public returns (bool) {
    _totalSupply = _totalSupply.add(_amount);
    _balances[_to] = _balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


/**
 * @title Freezable token 
 * @dev Add ability froze accounts 
 */
contract FreezableToken is ERC20{

    mapping (address => bool) public frozenAccounts;

    event FrozenFunds(address target, bool frozen);

    /**
     * @dev Freze account 
     */
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccounts[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /**
     * @dev Ovveride base method _transfer from  base ERC20 contract
     */
    function _transfer(address _from, address _to, uint256 value) internal {
        require(_to != address(0x0));
        require(_balances[_from] >= value);
        require(_balances[_to] + value >= _balances[_to]);
        require(!frozenAccounts[_from]);
        require(!frozenAccounts[_to]);
        _balances[_from] = _balances[_from].sub(value);
        _balances[_to] = _balances[_to].add(value);
        emit Transfer(_from, _to, value);
    }
}



/**
 * @title Contract with user raunds 
 */
contract RoundsContract is Ownable{

  struct Round { 
      string name; 
      uint256 tokens;
      uint256 expiresAt;  
      bool isActive;
      bool isExist;
  }

  mapping ( address => Round) internal deletedRounds;
  mapping ( string => Round) internal rounds;
  string internal currentRoundKey; 

  event AddRound(string key, string name, uint256 tokens, uint256 expiresAt, bool isActive);
  event DeleteRound(string key, string name);

  modifier isRoundActive(){
    require(!isStrEmpty(currentRoundKey)); 
    require(rounds[currentRoundKey].isActive);
    require(rounds[currentRoundKey].expiresAt > block.timestamp);
    require(rounds[currentRoundKey].expiresAt > now);
    _;
  }
  
  /**
   * @dev Add new raund 
   */ 
  function addRound(string memory key, string memory name, uint256 tokens, uint256 expiresAt, bool isActive) public onlyOwner returns (bool){
      require(block.timestamp <  expiresAt);
      require(tokens > 0);
      require(!rounds[key].isExist);
      rounds[key] = Round(name, tokens, expiresAt, isActive, true);
      if (isStrEmpty(currentRoundKey) || isActive){
        currentRoundKey = key;
      }
      emit AddRound(key, name, tokens,  expiresAt, isActive);
      return true;
  }

  function setCurrentRound(string memory key) public onlyOwner returns(bool){
      currentRoundKey = key;
      return true;
  }


  function getRoundTokens(string memory key) public view returns(uint256){
      return rounds[key].tokens;
  }  

  function getRoundEndDate(string memory key) public view returns(uint256){
    return rounds[key].expiresAt;
  }

  function getRoundName(string memory key) public view returns(string memory) {
    return rounds[key].name; 
  }

  function getCurrentRoundKey() public view returns(string memory){
      return currentRoundKey;
  }


  function setRoundName(string memory key, string memory name) public onlyOwner returns(bool){
      require(rounds[key].isExist);
      require(!isStrEmpty(name));
      rounds[key].name = name;
      return true;
  }

  function setRoundTokens(string memory key, uint256 numberTokens) public onlyOwner returns(bool){
    require(rounds[key].isExist);
    require(numberTokens > 0);
    rounds[key].tokens = numberTokens;
    return true;
  }

  function setRoundEndDate(string memory key, uint256 endDate) public onlyOwner returns(bool){
    require(rounds[key].isExist);
    require(block.timestamp < endDate);
    rounds[key].expiresAt = endDate;
    return true;
  }

  function deactivateCurrentRound() public onlyOwner returns(bool){
    require(!isStrEmpty(currentRoundKey));
    rounds[currentRoundKey].isActive = false;
    return true;
  }

  function deactivateRound(string memory key) public onlyOwner returns(bool){
    require(rounds[key].isExist);
    rounds[key].isActive = false;
    return false;
  }

  function activateCurrentRound() public onlyOwner returns(bool){
    require(!isStrEmpty(currentRoundKey));
    rounds[currentRoundKey].isActive = true;
    return true;
  }

  function activateRound(string memory key) public onlyOwner returns(bool){
    require(rounds[key].isExist);
    rounds[key].isActive = true;
    return false;
  }
  

  function isStrEmpty(string memory item) private pure returns(bool){
      bytes memory tempEmptyString = bytes(item); // Uses memory
      if (tempEmptyString.length == 0) {
          return true;
      } else {
          return false;
      }   
  }

  function deleteRound(string memory key) public onlyOwner returns(bool){
    require(rounds[key].isExist);
    emit DeleteRound(key, rounds[key].name);
    delete rounds[key];
    return true;
  }  

  function currentRoundIsActive() public view returns(bool){
    return rounds[currentRoundKey].isActive;
  }

  function checkRound() internal returns(bool) {
    if (rounds[currentRoundKey].expiresAt <= block.timestamp){
        rounds[currentRoundKey].isActive = false;
        currentRoundKey = &#39;&#39;;
    }
    return true;
  }

} 

/**
 * @title Base contract 
 * @dev Contract for adding ability byu and sell tokens
 */
contract BaseContract is MintableToken, FreezableToken, RoundsContract {

    uint256 internal purchasedTokens;

    uint256 internal sellPrice;
    
    uint256 internal sellPriceDecimals;

    uint256 internal buyPrice;
    
    uint256 internal buyPriceDecimals;

    uint256 internal membersCount;

    event Buy(address target, uint256 eth, uint256 tokens);

    event Sell(address target, uint256 eth, uint256 tokens);


    
    /**
     * @return return sell price decimals
     */
    function getSellPriceDecimals() public view returns (uint256) {
        return sellPriceDecimals;
    }

    /**
     * @return return buy price decimals
     */
    function getBuyPriceDecimals() public view returns (uint256) {
        return buyPriceDecimals;
    }

    /**
     * @return return sell price
     */
    function getSellPrice() public view returns (uint256) {
        return sellPrice;
    }

    /**
     * @return return buy price
     */
    function getBuyPrice() public view returns (uint256) {
        return buyPrice;
    }

    /**
     * @return return count mebers
     */
    function getMembersCount() public view returns (uint256) {
        return membersCount;
    }

    /**
     * @dev return count bought tokens 
     * @return uint256
     */
    function getPurchasedTokens() public view returns(uint256) {
        return purchasedTokens;
    }


    /**
     * @dev set prices for sell tokens and buy tokens
     */
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner{
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }


     /**
     * @dev set prices for sell tokens and buy tokens
     */
    function setPricesDecimals(uint256 newSellDecimal, uint256 newBuyDecimal) public onlyOwner{
        sellPriceDecimals = newSellDecimal;
        buyPriceDecimals = newBuyDecimal;
    }

    /**
     * @dev buy tokens 
     */
    function buy(address _sender, uint256 _value) internal isRoundActive{
        require (_value > 0 );
        require (buyPrice > 0);
        uint256 dec = 10 ** buyPriceDecimals; 
        uint256 amount = (_value / buyPrice) * dec; 
        require((purchasedTokens + amount) < rounds[currentRoundKey].tokens);
        require( (purchasedTokens + amount) <= _totalSupply);
        purchasedTokens = purchasedTokens.add(amount);
        membersCount  = membersCount.add(1);
        _transfer( owner,  _sender, amount);
        emit Buy(_sender, _value, amount);
    }

    /**
     * @dev Sell tokens 
     */
    function sell(uint256 amount) public {
        uint256 dec = 10 ** sellPriceDecimals; 
        uint256 sellAmount = (amount * sellPrice) /  dec;
        require(owner.balance >= sellAmount);
        _transfer(msg.sender, owner, amount);
        msg.sender.transfer(sellAmount);
        emit Sell(msg.sender, sellAmount, amount);
    }
}

/** 
 * @title Contract constants 
 * @dev  Contract whose consisit base constants for contract 
 */
contract ContractConstants{

  uint internal constant TOKEN_DECIMALS = 18;

  uint internal constant TOKEN_DECIMALS_MULTIPLIER = 10 ** TOKEN_DECIMALS;

  uint256 internal constant TOKEN_TOTAL_SUPPLY = uint256(1000000000);

  string internal constant TOKEN_NAME = "WINDBELLOWSTEST";

  string internal constant TOKEN_SYMBOL = "WDNTS";

  bool internal constant PAUSED = false;

  address internal constant TOKEN_OWNER = 0x371eB59Bad8b4B7C7eB7C0599B84f7460C0875D9;

  uint256 internal TOKEN_SELL_PRICE = 4;

  uint256 internal TOKEN_SELL_PRICE_DECIMALS = 4;

  uint256 internal TOKEN_BUY_PRICE = 4;
  
  uint256 internal TOKEN_BUY_PRICE_DECIMAL = 4;
  
}

/**
 * @title MainContract
 * @dev Base contract which using for initializing new contaract
 */
contract MainContract is BaseContract, ContractConstants, Pausable{

    bool private isRealized;

    /**
     * @dev Constructor 
     */
    constructor () public {
      init();
    }

    /**
     * @return get token name
     */
    function name() public pure returns (string memory _name){
      return TOKEN_NAME;
    }

    /**
     * @return get token symbol
     */
    function symbol() public pure returns (string memory _symbol){
      return TOKEN_SYMBOL;
    }

    /**
     * @return get token decimals 
     */
    function decimals() public pure returns (uint _decimals){
      return TOKEN_DECIMALS; 
    }

    /**
     * @dev Ovveride base method transferFrom
     */
    function transferFrom(address _from, address _to, uint256 value) public whenNotPaused returns (bool _success){
       membersCount  = membersCount.add(1);
       return super.transferFrom(_from, _to, value);
    }  

    /**
     * @dev Override base method transfer
     */
    function transfer(address _to, uint256 value) public whenNotPaused returns (bool _success){
      membersCount  = membersCount.add(1);
      return super.transfer(_to, value);
    }

    /**
     * @dev Function whose calling on initialize contract
     */
    function init() private {
        if(PAUSED){
          pause();
        }
        setPrices(TOKEN_SELL_PRICE, TOKEN_BUY_PRICE);
        setPricesDecimals(TOKEN_SELL_PRICE_DECIMALS, TOKEN_BUY_PRICE_DECIMAL);
        addRound(&#39;ROUND_1&#39;, &#39;ROUND_1&#39;, 30000000 * uint256(TOKEN_DECIMALS_MULTIPLIER), 1577743200000, true);
        if (msg.sender == TOKEN_OWNER){
          mint(TOKEN_OWNER, TOKEN_TOTAL_SUPPLY * uint256(TOKEN_DECIMALS_MULTIPLIER)); 
          isRealized = true;         
        }
        transferOwnership(TOKEN_OWNER);
    }

    /**
     * @dev Release tokens by ovner
     */
    function releaseTokens() public onlyOwner returns(bool){
        require(!isRealized);
        mint(TOKEN_OWNER, TOKEN_TOTAL_SUPPLY * uint256(TOKEN_DECIMALS_MULTIPLIER));
    }

    function () external payable {
        checkRound();
        buy(msg.sender, msg.value);
    }

}