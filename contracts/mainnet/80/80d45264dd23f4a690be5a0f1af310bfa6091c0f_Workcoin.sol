pragma solidity ^0.4.21;

/// @title SafeMath contract - Math operations with safety checks.
/// @author OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
contract SafeMath
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function pow(uint256 a, uint256 b) internal pure returns (uint256) {
        uint c = a ** b;
        assert(a == 0 || c / a == b);
        return c;
    }
}

contract Ownable
{
    event NewOwner(address old, address current);
    event NewPotentialOwner(address old, address potential);

    address public owner = msg.sender;
    address public potentialOwner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPotentialOwner {
        require(msg.sender == potentialOwner);
        _;
    }

    function setOwner(address _new) public onlyOwner {
        emit NewPotentialOwner(owner, _new);
        potentialOwner = _new;
    }

    function confirmOwnership() public onlyPotentialOwner {
        emit NewOwner(owner, potentialOwner);
        owner = potentialOwner;
        potentialOwner = 0;
    }
}

/// @title Abstract Token, ERC20 token interface
contract ERC20I
{
    function name() constant public returns (string);
    function symbol() constant public returns (string);
    function decimals() constant public returns (uint8);
    function totalSupply() constant public returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/// Full complete implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
contract ERC20 is ERC20I, SafeMath
{
    //using SafeMath for uint;

    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 public totalSupply;
    string  public version;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    /// @dev Returns number of tokens owned by given address.
    function name() public view returns (string) {
        return name;
    }

    /// @dev Returns number of tokens owned by given address.
    function symbol() public view returns (string) {
        return symbol;
    }

    /// @dev Returns number of tokens owned by given address.
    function decimals() public view returns (uint8) {
        return decimals;
    }

    /// @dev Returns number of tokens owned by given address.
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
      return balances[_owner];
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
      require(_to != address(0x0));
      require(_value <= balances[msg.sender]);

      balances[msg.sender] = sub(balances[msg.sender], _value);
      balances[_to] = add(balances[_to], _value);
      emit Transfer(msg.sender, _to, _value);
      return true;
    }

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

      balances[_from] = sub(balances[_from], _value);
      balances[_to] = add(balances[_to], _value);
      allowed[_from][msg.sender] = sub( allowed[_from][msg.sender], _value);
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
      allowed[msg.sender][_spender] = add(allowed[msg.sender][_spender], _addedValue);
      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
        allowed[msg.sender][_spender] = sub(oldValue, _subtractedValue);
      }
      emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
    }
}

contract Pausable is Ownable {

    event EPause(); //address owner, string event
    event EUnpause();

    bool public paused = true;

    modifier whenNotPaused()
    {
        require(!paused);
        _;
    }

    function pause() public onlyOwner
    {
        paused = true;
        emit EPause();
    }

    function unpause() public onlyOwner
    {
        paused = false;
        emit EUnpause();
    }
}

/**
   @title ERC827 interface, an extension of ERC20 token standard

   Interface of a ERC827 token, following the ERC20 standard with extra
   methods to transfer value and data and execute calls in transfers and
   approvals.
 */


contract MintableToken is ERC20, Ownable
{
    uint256 maxSupply = 1e25; //tokens limit

    // triggered when the total supply is increased
    event Issuance(uint256 _amount);
    // triggered when the total supply is decreased
    event Destruction(uint256 _amount);

    /**
        @dev increases the token supply and sends the new tokens to an account
        can only be called by the contract owner
        @param _to         account to receive the new amount
        @param _amount     amount to increase the supply by
    */
    function issue(address _to, uint256 _amount) public onlyOwner {
        require(maxSupply >= totalSupply + _amount);
        totalSupply +=  _amount;
        balances[_to] += _amount;
        emit Issuance(_amount);
        emit Transfer(this, _to, _amount);
    }

    /**
        @dev removes tokens from an account and decreases the token supply
        can only be called by the contract owner
        (if robbers detected, if will be consensus about token amount)
        @param _from       account to remove the amount from
        @param _amount     amount to decrease the supply by
    */
    function destroy(address _from, uint256 _amount) public onlyOwner {
        balances[_from] -= _amount;
        totalSupply -= _amount;
        emit Transfer(_from, this, _amount);
        emit Destruction(_amount);
    }
}

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is MintableToken, Pausable {

    function transferFrom(address _from, address _to, uint256 _value)
        public
        whenNotPaused
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value)
        public
        whenNotPaused
        returns (bool)
    {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue)
        public
        whenNotPaused
        returns (bool)
    {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue)
        public
        whenNotPaused
        returns (bool)
    {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

}

contract Workcoin is PausableToken {

    address internal seller;

    /**
        @dev modified pausable/trustee seller contract
    */
    function transfer(address _to, uint256 _value) public
        returns (bool)
    {
        if(paused) {
            require(seller == msg.sender);
            return super.transfer(_to, _value);
        } else {
            return super.transfer(_to, _value);
        }
    }

    function sendToken(address _to, uint256 _value) public onlyOwner
        returns (bool)
    {
        require(_to != address(0x0));
        require(_value <= balances[this]);
        balances[this] = sub(balances[this], _value);
        balances[_to] = add(balances[_to], _value);
        emit Transfer(this, _to, _value);
        return true;
    }


    function setSeller(address _seller) public onlyOwner {
        seller = _seller;
    }

    /** @dev transfer ethereum from contract */
    function transferEther(address _to, uint256 _value)
        public
        onlyOwner
        returns (bool)
    {
        _to.transfer(_value); // CHECK THIS
        return true;
    }

    /**
        @dev owner can transfer out any accidentally sent ERC20 tokens
    */
    function transferERC20Token(address tokenAddress, address to, uint256 tokens)
        public
        onlyOwner
        returns (bool)
    {
        return ERC20(tokenAddress).transfer(to, tokens);
    }

    /**
        @dev mass transfer
        @param _holders addresses of the owners to be notified ["address_1", "address_2", ..]
     */
    function massTransfer(address [] _holders, uint256 [] _payments)
        public
        onlyOwner
        returns (bool)
    {
        uint256 hl = _holders.length;
        uint256 pl = _payments.length;
        require(hl <= 100 && hl == pl);
        for (uint256 i = 0; i < hl; i++) {
            transfer(_holders[i], _payments[i]);
        }
        return true;
    }

    /*
        @dev tokens constructor
    */
    function Workcoin() public
    {
        name = "Workcoin";
        symbol = "WRR";
        decimals = 18;
        version = "1.3";
        issue(this, 1e7 * 1e18);
    }

    function() public payable {}
}