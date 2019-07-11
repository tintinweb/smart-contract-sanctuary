/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity ^0.5.1;
library SafeMath {
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function Smul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }
      uint256 z = a * b;
      assert((a == 0)||(z/a == b));
      return z;
  }
  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function Sdiv(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
          return 0;
      }
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function Ssub(uint256 a, uint256 b) internal pure returns (uint256) {
      require(a >= b, &#39;First parameter must be greater than second&#39;);
      assert(a >= b);
      uint256 z = a - b;
      return z;
  }
  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function Sadd(uint256 a, uint256 b) internal pure returns (uint256 c) {
      uint256 z = a + b;
      require((z >= a) && (z >= b),&#39;Result must be greater than parameters&#39;);
      assert((z >= a) && (z >= b));
      return z;
  }
}

contract ERC20Basic {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public payable returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  bool internal pause = false;
  modifier chk_paused(){
      require(pause == false,&#39;Sorry, contract paused by the administrator&#39;);
      _;
  }
}

contract ERC20 is ERC20Basic {
function totalSupply() public view returns (uint);
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public  payable returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) internal balances;
  struct partners{
      uint256 seq;
      address owner;
  }
  mapping(uint => partners) internal store;
  uint256 internal totalPartners_;
  uint256 internal div_bal_;
  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public payable  returns (bool) {
    require(_to != address(0),&#39;Address need to be different of zero&#39;);
    require(_value <= balances[msg.sender],&#39;Value is greater than balance&#39;);
    require(pause == false,&#39;Contract paused to pay dividends or other reason especified in polidatacompressor.com&#39;);
    if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] = balances[msg.sender].Ssub(_value);
        //looking for partner informed into _to
        bool exists_ = false;
        for (uint i = 1 ; i <= totalPartners_ ; i++) {
            if (store[i].owner == _to){
                exists_ = true;
            }
        }
        if (exists_ == false){
           totalPartners_ = totalPartners_.Sadd(1);
           store[totalPartners_].seq = totalPartners_;
           store[totalPartners_].owner = _to;
        }
        balances[_to] = balances[_to].Sadd(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
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
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;
  address internal owner;
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
    public  payable  chk_paused()
    returns (bool)
  {
    require(_to != address(0),&#39;Address need to be different of zero&#39;);
    require(_value <= balances[_from],&#39;Value is greater than balance&#39;);
    require(_value <= allowed[_from][msg.sender],&#39;Value is greater than allowed&#39;);

    balances[_from] = balances[_from].Ssub(_value);
    balances[_to] = balances[_to].Sadd(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].Ssub(_value);
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
  function approve(address _spender, uint256 _value) public chk_paused() returns (bool) {
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
   ) public view returns (uint256){
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
    public chk_paused()
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].Sadd(_addedValue));
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
  ) public chk_paused() returns (bool){
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.Ssub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

contract PoliToken is StandardToken {
  string public constant name = "PoliToken";
  string public constant symbol = "POLI";
  uint256 public constant INITIAL_SUPPLY = 10000000;
  
  constructor() public  {
    totalPartners_ = 1;
    store[totalPartners_].seq = totalPartners_;
    store[totalPartners_].owner = msg.sender;
    owner = msg.sender;
    div_bal_ = address(this).balance;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
  }
      function totalSupply() public view returns (uint) {
        return INITIAL_SUPPLY;
    }
   function paying_dividends(uint _seq_ini, uint _seq_fim) external onlyOwner() onlyPaused() {
      require(_seq_fim >= _seq_ini, &#39;first parameter must be greater than second&#39;);
      uint256 tot_;
      uint256 div_;
      uint256 max_partners_;
      uint gas_;
      tot_ = div_bal_;
      max_partners_ = totalPartners_;
      if (max_partners_ > _seq_fim){
          max_partners_ = _seq_fim;
      }
      for (uint i = _seq_ini; i <= max_partners_; i++){
          div_ = balances[store[i].owner].Smul(tot_).Sdiv(INITIAL_SUPPLY);
          gas_ = gasleft();
          store[i].owner.call.value(div_).gas(gas_)("");
      }
      if (max_partners_ == totalPartners_){
          div_bal_ = 0;
      }
  }
  function deposits_and_donations() external payable noZero() returns(bool){
      if (pause != true){
         div_bal_ = address(this).balance;
      }
      return true;
  }
  function change_pause(bool _pause) external onlyOwner returns(bool){
      pause = _pause;
      div_bal_ = address(this).balance;
      return true;
  }
  function chk_pause() external view returns(bool){
      return pause;
  }
  function chk_balance() external view returns(uint){
      return address(this).balance;
  }
  function chk_balance_dividends() external view returns(uint){
      return div_bal_;
  }
  function transfer_owner(address _owner) external onlyOwner returns(bool){
      owner = _owner;
      return true;
  }
  function chk_active_owner() external view returns(address){
      return owner;
  }
  function chk_total_partners() external view returns(uint){
      return totalPartners_;
  }
  function chk_partner_address(uint i) external view returns(address){
      return store[i].owner;
  }
  modifier onlyOwner(){
      require(msg.sender == owner, &#39;Sorry, you must be owner&#39;);
      _;
  }
  modifier onlyPaused(){
      require(pause == true,&#39;You need pause transactions to execute this&#39;);
      _;
  }
  modifier noZero(){
      require(msg.value > 0,&#39;Value must be greater than zero&#39;);
      _;
  }
}