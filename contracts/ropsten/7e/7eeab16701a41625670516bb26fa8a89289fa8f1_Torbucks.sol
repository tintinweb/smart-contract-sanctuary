pragma solidity ^0.4.24;

/**

 * @title ERC20 interface

 * @dev see https://github.com/ethereum/EIPs/issues/20

 */

contract ERC20 {

  function totalSupply() public view returns (uint256);



  function balanceOf(address who) public view returns (uint256);



  function transfer(address to, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);



  function allowance(address owner, address spender)

    public view returns (uint256);



  function transferFrom(address from, address to, uint256 value)

    public returns (bool);



  function approve(address spender, uint256 value) public returns (bool);

  event Approval(

    address indexed owner,

    address indexed spender,

    uint256 value

  );

}

/**

 * @title SafeMath

 * @dev Math operations with safety checks that throw on error

 */

library SafeMath {



  /**

  * @dev Multiplies two numbers, throws on overflow.

  */

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {

    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the

    // benefit is lost if &#39;b&#39; is also tested.

    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522

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
 * @title Torbucks
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */

 /**
  * Version 0.2 - 30/08/2018 FLOW DAY
  *
  * TO DO:
  * --
  * -- resetBalance()
  * --
  * --
  * -- removeWallet()
  */

contract Torbucks is ERC20 {
  using SafeMath for uint256;

  /**
   * DECLARATIONS
   */
  // Token information
  string public constant name = "Torbuck"; // solium-disable-line uppercase
  string public constant symbol = "TOR"; // solium-disable-line uppercase
  uint8 public constant decimals = 2; // solium-disable-line uppercase
  uint256 public constant INITIAL_SUPPLY = 1000000 * (10 ** uint256(decimals));


  // mappings
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  struct account{
      string alias;
      bool isManager;
      bool isSet;
      address next;
  }
  mapping (address => account) wallets;

  // variables
  uint256 totalSupply_;
  address owner;
  address walletListHead;


  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor() public {
    owner = msg.sender;
    totalSupply_ = INITIAL_SUPPLY;
    balances[address(this)] = INITIAL_SUPPLY;
    wallets[address(this)].isSet = true;
    wallets[address(this)].alias = "Torbuck Piggybank";
    wallets[address(this)].next = address(0);
    walletListHead = address(this);
    emit Transfer(address(0), address(this), INITIAL_SUPPLY);
  }

  // modifiers
  modifier onlyOwner(){
      require(msg.sender == owner);
      _;
  }
  modifier onlyManager(){
      require(wallets[msg.sender].isManager);
      _;
  }
  modifier onlyManagerOrOwner(){
      require(wallets[msg.sender].isManager || msg.sender == owner);
      _;
  }

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
    require(_to != address(0));
    require(_to == address(this));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _address The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _address) public view returns (uint256) {
    return balances[_address];
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(wallets[msg.sender].isManager);
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
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    require(wallets[_spender].isManager);
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

  function getHeadWalletList() public view returns (address){
      return walletListHead;
  }

  function getWallet(address index) public view returns (string _alias, address _next, bool _isManager, bool _isSet, uint256 _balance){
      _alias = wallets[index].alias;
      _next = wallets[index].next;
      _isManager = wallets[index].isManager;
      _isSet = wallets[index].isSet;
      _balance = balances[index];
  }

  /**
   * --- MANAGER Functions ---
   */

  function vaultToWallet(address _to, uint256 _value) public onlyManager returns (bool){
      require(wallets[_to].isSet);
      if(balances[address(this)] >= _value){
          balances[address(this)] = balances[address(this)].sub(_value);
          balances[_to] = balances[_to].add(_value);
          emit Transfer(address(this), _to, _value);
          return true;
      }
      return false;
  }

  function walletToVault(address _from, uint256 _value) public onlyManager returns (bool){
      require(wallets[_from].isSet);
      if(balances[_from] >= _value){
          balances[_from] = balances[_from].sub(_value);
          balances[address(this)] = balances[address(this)].add(_value);
          emit Transfer(_from, address(this), _value);
          return true;
      }
      return false;
  }

  function emptyWallet(address _wallet) public onlyManager returns (bool) {
      require(wallets[_wallet].isSet);
      require(balances[_wallet] > 0);
      uint256 _value = balances[_wallet];
      balances[_wallet] = balances[_wallet].sub(_value);
      balances[address(this)] = balances[address(this)].add(_value);
      emit Transfer(_wallet, address(this), _value);
  }

  function managerSelfRemove() public onlyManager returns (bool) {
      wallets[msg.sender].isManager = false;
      return true;
  }

  function removeWallet(address _wallet) public onlyManager returns (bool) {
      require(wallets[_wallet].isSet);
      require(balances[_wallet] == 0);
      wallets[_wallet].isSet = false;
      return true;
  }

  /**
   * --- OWNER and MANAGER Functions ---
   */
   function addWallet(address _newWallet, string _alias) public onlyManagerOrOwner returns (bool){
       require(wallets[_newWallet].isSet != true);
       wallets[_newWallet].alias = _alias;
       wallets[_newWallet].isManager = false;
       wallets[_newWallet].isSet = true;

       // if wallet is already in list return with success
       if (wallets[_newWallet].next != address(0)){return true;}

       // add wallet to list and update head
       wallets[_newWallet].next = walletListHead;
       walletListHead = _newWallet;
       return true;
   }

  /**
   * --- OWNER Functions ---
   */

  /**
   * @dev Function to add a manager to the managers array
   */
  function addManager(address _manager) public onlyOwner returns (bool) {
        require(wallets[_manager].isSet);
        require(wallets[_manager].isManager == false);
        wallets[_manager].isManager = true;
        return true;
  }

  /**
   * @dev Function to remove a manager
   */
  function removeManager(address _manager) public onlyOwner returns (bool){
      require(wallets[_manager].isSet);
      require(wallets[_manager].isManager);
      wallets[_manager].isManager = false;
      return true;
  }

  /**
   * @dev function for the owner to selfdestruct the contract
   */
  function kill() public onlyOwner {
      selfdestruct(owner);
   }

  /**
   * @dev Fallback function in case someone sends ether to the contract so it doesn&#39;t get lost
   */
  //function() public payable {}

}