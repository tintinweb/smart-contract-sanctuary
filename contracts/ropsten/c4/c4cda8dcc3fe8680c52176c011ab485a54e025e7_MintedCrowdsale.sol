pragma solidity ^0.4.24;

library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

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

library SafeERC20 {
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    require(token.approve(spender, value));
  }
}


interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  string private _name;
  
  string private _symbol;
  
  uint8 private _decimals;

  uint256 private _totalSupply;
  
  
  
  function setName(string name) internal {
        _name = name;
  }
  function setSymbol(string symbol) internal {
      _symbol = symbol;
  }
  
  function setDecimals(uint8 decimals) internal {
      _decimals = decimals;
  }

  function setTotalSupply(uint256 totalSupply) internal {
        _totalSupply = totalSupply;
  }
  
  
  function name() public view returns(string){
      return _name;
  }
  
  function symbol()public view returns(string){
      return _symbol;
  }
  
  function decimals() public view returns(uint8){
      return _decimals;
  }
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
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
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
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
  
   

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param amount The amount that will be created.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != 0);
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

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      amount);
    _burn(account, amount);
  }
  
  
}
contract Ownable {
  address private _owner;


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
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract WhiteList is Ownable{

    event AddedWhiteList(address _user);
    event RemovedWhiteList(address _user);

    mapping (address => bool) public isWhiteListed;

    constructor() public{
        addWhiteList(msg.sender);
    }
    modifier _inWhiteList(){
        require(isWhiteListed[msg.sender] == true );
        _;
    }

    function addWhiteList (address whiteUser) public onlyOwner {
        isWhiteListed[whiteUser] = true;
        emit AddedWhiteList(whiteUser);
    }

    function removeBlackList (address clearedUser) public onlyOwner {
        isWhiteListed[clearedUser] = false;
        emit RemovedWhiteList(clearedUser);
    }

}  
contract ERC20Mintable is ERC20, WhiteList{

  using SafeMath for uint256;

  uint256 public _initialSupply;
  
  event MintingFinished();
  event MintingAgentChanged(address addr, bool state  );

  bool private _mintingFinished = false;
  
  mapping (address => bool) public mintAgent;
   
  modifier onlyBeforeMintingFinished() {
    require(!_mintingFinished);
    _;
  }
  modifier onlyMintAgent() {
    require(mintAgent[msg.sender]);
    _;
  }
  

  /**
   * @return true if the minting is finished.
   */
  function mintingFinished() public view returns(bool) {
    return _mintingFinished;
  }
  
  

  /**
   * @dev Function to mint tokens
   * @param to The address that will receive the minted tokens.
   * @param amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address to, uint256 amount)public onlyMintAgent onlyBeforeMintingFinished  returns (bool)
  {
    _mint(to, amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting()public  onlyBeforeMintingFinished returns (bool)
  {
    _mintingFinished = true;
    emit MintingFinished();
    return true;
  }
  
  function multSender(address[] to, uint256[] amount) _inWhiteList public{

        require(to.length == amount.length);
        for (uint i = 0; i < to.length; i++) {
            transfer( to[i], amount[i]);
        }

    }

    function multMint(address[] to, uint256[] amount) _inWhiteList  public payable{

        require(to.length == amount.length);
        for (uint i = 0; i < to.length; i++) {
            _mint(to[i], amount[i]);

        }
    }
    function burn(address addr, uint256 amount) public onlyOwner{
        _burn(addr, amount);
    }
    
    function burnFrom(address addr, uint256 amount) public onlyOwner{
        _burnFrom(addr, amount);
    }
    
    function setMintAgent(address addr, bool state) onlyOwner  public {
    mintAgent[addr] = state;
    emit MintingAgentChanged(addr, state);
  }
   
}
contract EthTranchePricing is Ownable {
    using SafeMath for uint256;
    bool public _trancheTimeStatus = false;
    bool public _trancheWeiStatus = false;
    uint256 public _stageRaised = 0;
    uint256 _decimals = 18;
    uint256 public _nextTrancheStage=0;
    uint256 public _nextTranchePrice=0;
    uint256 public _sum = 0;
    uint256 public _rest = 0;
    uint256 public _restValue = 0;
    
    uint256 public constant MAX_TRANCHES = 8;
   
    
    
    struct Tranches {
        uint256 _stage;
        uint256 _price;
    }

    Tranches[MAX_TRANCHES] public _tranches;
    uint256 trancheCount;
    
    modifier onlyTrancheStatus(){
       require(_trancheTimeStatus == false);
       require(_trancheWeiStatus == false);
        _;
    }
    
    
    function setTranchTime(uint256[] tranches)public  onlyTrancheStatus onlyOwner {
        require(!(tranches.length % 2 == 1 || tranches.length >= MAX_TRANCHES*2));

        trancheCount = _tranches.length / 2;
        uint8 j;
        for(uint8 i=0; i<_tranches.length/2; i++) {
         j = i;
         
         if(tranches[j*2] < 6){
             require(block.timestamp >= tranches[j*2] && tranches[j*2] < tranches[j*2+2] );
         }else if(tranches[j*2] == 6){
             require(tranches[j*2] > tranches[j*2-2]  );
         }
          _tranches[i]._stage = tranches[i*2];
          
          _tranches[i]._price = tranches[i*2+1];
          
            
        }
        _trancheTimeStatus = true;
    }
    function setTranchWei(uint256[] tranches)public  onlyTrancheStatus onlyOwner{
        require(!(tranches.length % 2 == 1 || tranches.length >= MAX_TRANCHES*2));
        trancheCount = _tranches.length / 2 ; 
        uint256 highestAmount = 0;
        require(_tranches[0]._stage == 0);
        for(uint i=0; i<_tranches.length/2; i++){
            _tranches[i]._stage = tranches[i*2] * 10 ** _decimals;
            _tranches[i]._price = tranches[i*2+1] * 10 ** _decimals;
            
            require(!((highestAmount != 0) && (_tranches[i]._stage <= highestAmount)));
            highestAmount = _tranches[i]._stage;
        }
        require(_tranches[0]._stage == 0);
        require(_tranches[trancheCount-1]._price == 0);
        _trancheWeiStatus = true;
    }
    
    function getTranche(uint256 n) public constant returns (uint256, uint256) {
    return (_tranches[n]._stage, _tranches[n]._price);
  }
  
  function getFirstTranche() private constant returns (Tranches) {
    return _tranches[0];
  }
  
  function getLastTranche() private constant returns (Tranches) {
    return _tranches[trancheCount-1];
  }

  function getPricingStartsAt() public constant returns (uint256) {
    return getFirstTranche()._stage;
  }

  function getPricingEndsAt() public constant returns (uint256) {
    return getLastTranche()._stage;
  }

    function getCurrentTranche(uint256 stageRaised) private constant returns (Tranches) {
    uint256 i;
    for(i=0; i < _tranches.length; i++) {
      if(stageRaised < _tranches[i]._stage) {
        return _tranches[i-1];
      }
    }
  }
  function getNextTranche(uint256 stageRaised) private  returns (Tranches) {
    uint256 i;
    for(i=0; i < _tranches.length; i++) {
      if(stageRaised <= _tranches[i]._stage) {
        if(i == 3){
            _tranches[3]._stage = _tranches[i]._stage;
            _tranches[3]._price = _tranches[i-1]._price;
            return _tranches[3];
        }else{
            return _tranches[i];
        }
        
      }
    }
  }

    function getCurrentPrice(uint stageRaised) public constant returns (uint256 result) {
    return getCurrentTranche(stageRaised)._price;
  }

function calculatePrice(uint256 value) external  returns (uint256) {
    
    uint256 multiplier = 10 ** _decimals;
    uint256 _result;
    uint256 price;
   
    if(_trancheTimeStatus == true && _trancheWeiStatus == false ){
        _stageRaised = block.timestamp;
        price = getCurrentPrice(_stageRaised);
        _result = value.mul(multiplier).div(price);
        
    }else if(_trancheTimeStatus == false && _trancheWeiStatus == true){
        
        _nextTrancheStage = getNextTranche(_stageRaised)._stage;
        
        _nextTranchePrice = getNextTranche(_stageRaised)._price;
        
        _sum = _stageRaised.add(value);
          
        if(  _sum >= _nextTrancheStage ){
            
            _rest =  _sum.sub(_nextTrancheStage);
            _restValue = value;
            _restValue = _restValue.sub(_rest);
            
            uint256 _price = getCurrentPrice(_stageRaised);
             _result = ((_restValue.mul(multiplier).div(_price)).add(_rest.mul(multiplier).div(_nextTranchePrice)));
        }else{
             price = getCurrentPrice(_stageRaised);
            _result = value.mul(multiplier).div(price);
        }
     
         _stageRaised = _stageRaised.add(value);
    }    
    return _result;
  }

  function()public payable {
    require(false); // No money on this contract
  }
}

contract Crowdsale is WhiteList {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // The token being sold
  IERC20 private _token;

  // Address where funds are collected
  address private _wallet;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
  uint256 private _rate;

  // Amount of wei raised
  uint256 private _weiRaised;
  bool private _timeRate;
  bool private _quantityRate;
  uint256 public _tokensSold;
  

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokensPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param rate Number of token units a buyer gets per wei
   * @dev The rate is the conversion between wei and the smallest and indivisible
   * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
   * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
   * @param wallet Address where collected funds will be forwarded to
   * @param token Address of the token being sold
   */
  
  

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------
    
    
  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
//   function () external payable {
//     buyTokens(msg.sender);
//   }
  function setToken(IERC20 token)_inWhiteList internal {
        _token = token;
    }
    /*
    function setRate(uint256 rate) _inWhiteList public {
        _rate = rate;
    }
    */
    function setWallet(address wallet)_inWhiteList internal {
        _wallet = wallet;
    }
   

  /**
   * @return the token being sold.
   */
  function token() public view returns(IERC20) {
    return _token;
  }

  /**
   * @return the address where funds are collected.
   */
  function wallet() public view returns(address) {
    return _wallet;
  }

  /**
   * @return the number of token units a buyer gets per wei.
   */
  function rate() public view returns(uint256) {
    return _rate;
  }

  /**
   * @return the mount of wei raised.
   */
  function weiRaised() public view returns (uint256) {
    return _weiRaised;
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param beneficiary Address performing the token purchase
   */
  function buyTokens(address beneficiary, uint256 tokens) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(beneficiary, weiAmount);

    // uint256 _value = msg.value;
    // calculate token amount to be created
    uint256 _tokens = tokens;
    // update state
    //_weiRaised = _weiRaised.add(weiAmount);
   
    _processPurchase(beneficiary, _tokens);
    _tokensSold.add( _tokens);
    emit TokensPurchased(
      msg.sender,
      beneficiary,
      weiAmount,
      tokens
    );

    // _updatePurchasingState(beneficiary, weiAmount);

    _forwardFunds();
    // _postValidatePurchase(beneficiary, weiAmount);
  }
  function getTokensSold()public view returns (uint256){
        return _tokensSold;
   }

   
   
  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

    
  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use `super` in contracts that inherit from Crowdsale to extend their validations.
   * Example from CappedCrowdsale.sol&#39;s _preValidatePurchase method:
   *   super._preValidatePurchase(beneficiary, weiAmount);
   *   require(weiRaised().add(weiAmount) <= cap);
   * @param beneficiary Address performing the token purchase
   * @param weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
  {
    require(beneficiary != address(0));
    require(weiAmount != 0);
  }

//   /**
//   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
//   * @param beneficiary Address performing the token purchase
//   * @param weiAmount Value in wei involved in the purchase
//   */
//   function _postValidatePurchase(
//     address beneficiary,
//     uint256 weiAmount
//   )
//     internal
//   {
//     // optional override
//   }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param beneficiary Address performing the token purchase
   * @param tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _token.safeTransfer(beneficiary, tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param beneficiary Address receiving the tokens
   * @param tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _deliverTokens(beneficiary, tokenAmount);
  }

//   /**
//   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
//   * @param beneficiary Address receiving the tokens
//   * @param weiAmount Value in wei involved in the purchase
//   */
//   function _updatePurchasingState(
//     address beneficiary,
//     uint256 weiAmount
//   )
//     internal
//   {
//     // optional override
//   }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 weiAmount)
    internal view returns (uint256)
  {
    return weiAmount.mul(_rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    _wallet.transfer(msg.value);
  }
}

contract MintedCrowdsale is  Crowdsale {
    
    EthTranchePricing public _ethTranchePricing;
    //BonusFinalizeAgent public _bonusFinalizeAgent;
    
    bool public _finalized;
    uint256 public _tokensSold;
    
    
    constructor( address wallet, IERC20 token,EthTranchePricing ethPricing) public {
    
    require(wallet != address(0));
    require(token != address(0));
    
    
    setEthTranchePricing(ethPricing);
    Crowdsale.setWallet(wallet);
    Crowdsale.setToken(token);
    _tokensSold = token.totalSupply();
  }
   
  modifier isFinalized{
        require(_finalized == false);  
        _;
  }
 
  
  function setEthTranchePricing(EthTranchePricing ethTranchePricing) private onlyOwner {
      _ethTranchePricing = ethTranchePricing;
  }
 /* function setBonusFinalizeAgent(BonusFinalizeAgent bonusFinalizeAgent) public onlyOwner{
      _bonusFinalizeAgent = bonusFinalizeAgent;
  }
 */
  /**
   * @dev Overrides delivery by minting tokens upon purchase.
   * @param beneficiary Token purchaser
   * @param tokenAmount Number of tokens to be minted
   */
  function _deliverTokens(address beneficiary,uint256 tokenAmount)internal{
    // Potentially dangerous assumption about the type of the token.
    require(
      ERC20Mintable(address(token())).mint(beneficiary, tokenAmount));
  }
  function _finalize() public isFinalized _inWhiteList{
     // _bonusFinalizeAgent.finalizeCrowdsale();
      _finalized= true;
  }
  function getTokensSold()public view returns (uint256){
        return _tokensSold;
   }
  
  function()public isFinalized payable{
      
    uint256 _tokens = _ethTranchePricing.calculatePrice(msg.value);
     
    buyTokens(msg.sender,_tokens);
    _tokensSold += _tokens;
    
    
  }
  
}