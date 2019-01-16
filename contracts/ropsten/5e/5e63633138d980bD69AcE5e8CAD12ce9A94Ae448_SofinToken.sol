pragma solidity 0.4.18;

// File: src/zeppelin/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: src/zeppelin/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: src/zeppelin/token/Freezable.sol

/*
 * Created by Input Strategic Partners (ISP) and Intimate.io
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
 * TITLE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE
 * SOFTWARE BE LIABLE FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

pragma solidity 0.4.18;

/**
 * @title Freezable
 * @dev allows authorized accounts to add/remove other accounts to the list of fozen accounts.
 * Accounts in the list cannot transfer and approve and their balances and allowances cannot be retrieved.
 */
contract Freezable {

  event Frozen(address indexed _account);
  event Unfrozen(address indexed _account);

  mapping (address => bool) public frozenAccounts;

  /// Make sure access control is initialized
  function Freezable() public { }

  /**
  * @dev Throws if called by any account that&#39;s frozen.
  */
  modifier notFrozen {
    require(!frozenAccounts[msg.sender]);
    _;
  }

/**
* @dev check if an account is frozen
* @param account address to check
* @return true iff the address is in the list of frozen accounts and hasn&#39;t been unfrozen
*/
  function isFrozen(address account) public view returns (bool) {
    return frozenAccounts[account];
  }
}

// File: src/zeppelin/token/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic, Freezable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(!isFrozen(msg.sender) && !isFrozen(_to));

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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    require(!isFrozen(_owner));
    return balances[_owner];
  }

}

// File: src/zeppelin/token/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: src/zeppelin/token/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public notFrozen returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    require(!isFrozen(_from) && !isFrozen(_to));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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
  function approve(address _spender, uint256 _value) public notFrozen returns (bool) {
    require(!isFrozen(_spender));
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
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    require(!isFrozen(_owner) && !isFrozen(_spender));
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue) public
    returns (bool success)
  {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public
    returns (bool success)
  {
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

// File: src/zeppelin/token/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {
  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value > 0);

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
  }
}

// File: src/SofinToken.sol

contract SofinToken is BurnableToken {
  string public constant name = &#39;SOFIN&#39;;
  string public constant symbol = &#39;SOFIN&#39;;
  uint256 public constant decimals = 18;

  uint256 public constant tokenCreationCap =  45000000 * 10 ** decimals;

  address public multiSigWallet;
  address public owner;

  bool public active = true;

  uint256 public oneTokenInWei = 153846153846200;

  modifier onlyOwner {
    if (owner != msg.sender) {
      revert();
    }
    _;
  }

  modifier onlyActive {
    if (!active) {
      revert();
    }
    _;
  }

  /**
  * @dev add an address to the list of frozen accounts
  * @param account address to freeze
  * @return true if the address was added to the list of frozen accounts, false if the address was already in the list 
  */
  function freezeAccount(address account) public onlyOwner returns (bool success) {
    if (!frozenAccounts[account]) {
      frozenAccounts[account] = true;
      Frozen(account);
      success = true; 
    }
  }

  /**
  * @dev remove an address from the list of frozen accounts
  * @param account address to unfreeze
  * @return true if the address was removed from the list of frozen accounts, 
  * false if the address wasn&#39;t in the list in the first place 
  */
  function unfreezeAccount(address account) public onlyOwner returns (bool success) {
    if (frozenAccounts[account]) {
      frozenAccounts[account] = false;
      Unfrozen(account);
      success = true;
    }
  }

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  function SofinToken(address _multiSigWallet) public {
    multiSigWallet = _multiSigWallet;
    owner = msg.sender;
  }

  function() payable public {
    createTokens();
  }

  /**
   * @param  _to Target address.
   * @param  _amount Amount of SOFIN tokens, _NOT_ multiplied to decimals.
   */
  function mintTokens(address _to, uint256 _amount) external onlyOwner {
    uint256 decimalsMultipliedAmount = _amount.mul(10 ** decimals);
    uint256 checkedSupply = totalSupply.add(decimalsMultipliedAmount);
    if (tokenCreationCap < checkedSupply) {
      revert();
    }

    balances[_to] += decimalsMultipliedAmount;
    totalSupply = checkedSupply;

    Mint(_to, decimalsMultipliedAmount);
    Transfer(address(0), _to, decimalsMultipliedAmount);
  }

  function withdraw() external onlyOwner {
    multiSigWallet.transfer(this.balance);
  }

  function finalize() external onlyOwner {
    active = false;

    MintFinished();
  }

  /**
   * Sets price in wei per 1 SOFIN token.
   */
  function setTokenPriceInWei(uint256 _oneTokenInWei) external onlyOwner {
    oneTokenInWei = _oneTokenInWei;
  }

  function createTokens() internal onlyActive {
    if (msg.value <= 0) {
      revert();
    }

    uint256 multiplier = 10 ** decimals;
    uint256 tokens = msg.value.mul(multiplier) / oneTokenInWei;

    uint256 checkedSupply = totalSupply.add(tokens);
    if (tokenCreationCap < checkedSupply) {
      revert();
    }

    balances[msg.sender] += tokens;
    totalSupply = checkedSupply;

    Mint(msg.sender, tokens);
    Transfer(address(0), msg.sender, tokens);
    TokenPurchase(
      msg.sender,
      msg.sender,
      msg.value,
      tokens
    );
  }
}