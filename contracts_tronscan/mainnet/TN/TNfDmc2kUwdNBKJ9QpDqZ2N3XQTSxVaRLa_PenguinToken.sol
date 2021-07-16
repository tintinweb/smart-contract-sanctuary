//SourceUnit: PenguinToken.sol

pragma solidity ^0.5.4;

import "./SafeMath.sol";

contract PenguinToken {
  using SafeMath for uint256;

  address public devaddr;
  // Public variables of the token
  string public name;
  string public symbol;
  uint8 public decimals = 6;
  // 18 decimals is the strongly suggested default, avoid changing it
  uint256 public totalSupply;

  // This creates an array with all balances
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;

  // This generates a public event on the blockchain that will notify clients
  event Transfer(address indexed from, address indexed to, uint256 value);

  // This generates a public event on the blockchain that will notify clients
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  // This notifies clients about the amount burnt
  event Burn(address indexed from, uint256 value);

  /**
   * Constructor function
   *
   * Initializes contract with initial supply tokens to the creator of the contract
   */
  uint256 initialSupply = 100000; //100M tokens
  string tokenName = 'Penguin Token';
  string tokenSymbol = 'PENGU';
  constructor() public {
      totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
      balanceOf[msg.sender] = totalSupply;                // Give the creator 100M tokens at the begining
      name = tokenName;                                   // Set the name for display purposes
      symbol = tokenSymbol;                               // Set the symbol for display purposes
      devaddr = msg.sender;
  }

  /**
   * Internal transfer, only can be called by this contract
   */
  function _transfer(address _from, address _to, uint _value) internal {
      // Prevent transfer to 0x0 address. Use burn() instead
      // Check if the sender has enough
      require(balanceOf[_from] >= _value);
      // Check for overflows
      require(balanceOf[_to] + _value >= balanceOf[_to]);
      // Save this for an assertion in the future
      uint previousBalances = balanceOf[_from] + balanceOf[_to];
      // Subtract from the sender
      balanceOf[_from] -= _value;
      // Add the same to the recipient
      balanceOf[_to] += _value;
      emit Transfer(_from, _to, _value);
      // Asserts are used to use static analysis to find bugs in your code. They should never fail
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
  }

  /**
   * Transfer tokens
   *
   * Send `_value` tokens to `_to` from your account
   *
   * @param _to The address of the recipient
   * @param _value the amount to send
   */
  function transfer(address _to, uint256 _value) public returns (bool success) {
      _transfer(msg.sender, _to, _value);
      return true;
  }

  /**
   * Transfer tokens from other address
   *
   * Send `_value` tokens to `_to` on behalf of `_from`
   *
   * @param _from The address of the sender
   * @param _to The address of the recipient
   * @param _value the amount to send
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      require(_value <= allowance[_from][msg.sender]);     // Check allowance
      allowance[_from][msg.sender] -= _value;
      _transfer(_from, _to, _value);
      return true;
  }

  /**
   * Set allowance for other address
   *
   * Allows `_spender` to spend no more than `_value` tokens on your behalf
   *
   * @param _spender The address authorized to spend
   * @param _value the max amount they can spend
   */
  function approve(address _spender, uint256 _value) public
  returns (bool success) {
      allowance[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);
      return true;
  }

  /**
   * Destroy tokens
   *
   * Remove `_value` tokens from the system irreversibly
   *
   * @param _value the amount of money to burn
   */
  function burn(uint256 _value) public returns (bool success) {
      require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
      balanceOf[msg.sender] -= _value;            // Subtract from the sender
      totalSupply -= _value;                      // Updates totalSupply
      emit Burn(msg.sender, _value);
      return true;
  }

  /**
   * Destroy tokens from other account
   *
   * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
   *
   * @param _from the address of the sender
   * @param _value the amount of money to burn
   */
  function burnFrom(address _from, uint256 _value) public onlyContract returns (bool success) {
      require(balanceOf[_from] >= _value);                                // Check if the targeted balance is enough
      require(_value <= allowance[_from][msg.sender]);                    // Check allowance
      balanceOf[_from] = totalSupply.sub(_value);                         // Subtract from the targeted balance
      allowance[_from][msg.sender] = totalSupply.sub(_value);             // Subtract from the sender's allowance
      totalSupply = totalSupply.sub(_value);                              // Update totalSupply
      emit Burn(_from, _value);
      return true;
  }

  function mint(address account, uint256 amount) public onlyContract {
      require(account != address(0), "TRC20: mint to the zero address");
      totalSupply = totalSupply.add(amount);
      balanceOf[account] = balanceOf[account].add(amount);
      emit Transfer(address(0), account, amount);
  }

  modifier onlyOwner() {
    require(msg.sender == devaddr,"you need to be the owner");
    _;
  }
  address public penguStake;
  modifier onlyContract() {
    require(msg.sender == devaddr || msg.sender == penguStake);
    _;
  }

  function setPenguStakeAddr(address _penguStake) public onlyOwner {
    penguStake = _penguStake;
  }

  function transferOwnership(address _to) public onlyOwner {
    devaddr = _to;
  }

}


//SourceUnit: SafeMath.sol

pragma solidity ^0.5.4;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}