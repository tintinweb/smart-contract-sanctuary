/**
 *Submitted for verification at Etherscan.io on 2019-07-04
*/

// File: contracts/Ownable.sol

pragma solidity 0.5.9;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
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
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
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

// File: contracts/SafeMath.sol

pragma solidity 0.5.9;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
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
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: contracts/IERC20.sol

pragma solidity 0.5.9;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/ERC20.sol

pragma solidity 0.5.9;



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn&#39;t required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

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
     * @return A uint256 representing the amount owned by the passed address.
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
     * @dev Transfer token to a specified address
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
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses&#39; tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender&#39;s allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

// File: contracts/ERC20Burnable.sol

pragma solidity 0.5.9;


/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract ERC20Burnable is ERC20 {
    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance
     * @param from address The account whose tokens will be burned.
     * @param value uint256 The amount of token to be burned.
     */
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

// File: contracts/ERC20Mintable.sol

pragma solidity 0.5.9;



/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract ERC20Mintable is ERC20, Ownable {
    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        _mint(to, value);
        return true;
    }
}

// File: contracts/FTIToken.sol

pragma solidity 0.5.9;



contract FTIToken is ERC20Burnable, ERC20Mintable {
  string public constant name = "FTI NEWS Token";
  string public constant symbol = "TECH";
  uint8 public constant decimals = 10;

  uint256 public constant initialSupply = 299540000 * (10 ** uint256(decimals)); 

  constructor () public {
    _totalSupply = initialSupply;
    _balances[0x8D44D27D2AF7BE632baA340eA52E443756ea1aD3] = initialSupply;
  }
}

// File: contracts/FTICrowdsale.sol

pragma solidity 0.5.9;




contract FTICrowdsale is Ownable {
  using SafeMath for uint256;

  uint256 public rate;
  uint256 public minPurchase;
  uint256 public maxSupply;

  // Tokens, reserved for owners
  uint256 public stage1ReleaseTime;
  uint256 public stage2ReleaseTime;
  uint256 public stage3ReleaseTime;

  // Amount of reserved tokens
  uint256 public stage1Amount;
  uint256 public stage2Amount;
  uint256 public stage3Amount;

  bool public stage1Released;
  bool public stage2Released;
  bool public stage3Released;

  /**
   * @dev Money is sent to this wallet upon tokens purchase
   */
  address payable public wallet;

  bool public isPaused;

  FTIToken public token;

  constructor () public {
    token = new FTIToken();

    minPurchase = 0.00000000000005 ether; // price of the minimum part of the token
    rate = 0.000194 ether;

    maxSupply = 2395600000 * (10 ** 10); // 2395600000 * (10^(decimals))
    wallet = 0x8D44D27D2AF7BE632baA340eA52E443756ea1aD3;

    stage1ReleaseTime = now + 180 days; // 6 months
    stage2ReleaseTime = now + 270 days; // 9 months
    stage3ReleaseTime = now + 365 days; // 12 months

    stage1Amount = 299540000 * (10 ** uint256(token.decimals()));
    stage2Amount = 299540000 * (10 ** uint256(token.decimals()));
    stage3Amount = 299540000 * (10 ** uint256(token.decimals()));
  }

  /**
   * @dev This function suspends the tokens purchase
   */
  function pause() public onlyOwner {
    require(!isPaused, &#39;Sales must be not paused&#39;);
    isPaused = true;
  }

  /**
   * @dev This function resumes the purchase of tokens
   */
  function unpause() public onlyOwner {
    require(isPaused, &#39;Sales must be paused&#39;);
    isPaused = false;
  }

  /**
   * @dev Function set new wallet address.
   * @param newWallet Address of new wallet.
   */
  function changeWallet(address payable newWallet) public onlyOwner {
    require(newWallet != address(0));
    wallet = newWallet;
  }

  /**
   * @dev This function set new token owner.
   */
  function transferTokenOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    token.transferOwnership(newOwner);
  }

  /**
   * @dev This function burn all unsold tokens.
   */
  function burnUnsold() public onlyOwner {
    token.burn(token.balanceOf(address(this)));
  }

  /**
   * @dev This function releases tokens reserved for owners.
   */
  function releaseStage1() public onlyOwner {
    require(now > stage1ReleaseTime, &#39;Release time has not come yet&#39;);
    require(stage1Released != true, &#39;Tokens already released&#39;);

    stage1Released = true;
    token.mint(wallet, stage1Amount);
  }

  /**
   * @dev This function releases tokens reserved for owners.
   */
  function releaseStage2() public onlyOwner {
    require(now > stage2ReleaseTime, &#39;Release time has not come yet&#39;);
    require(stage2Released != true, &#39;Tokens already released&#39;);

    stage2Released = true;
    token.mint(wallet, stage2Amount);
  }

  /**
   * @dev This function releases tokens reserved for owners.
   */
  function releaseStage3() public onlyOwner {
    require(now > stage3ReleaseTime, &#39;Release time has not come yet&#39;);
    require(stage3Released != true, &#39;Tokens already released&#39;);

    stage3Released = true;
    token.mint(wallet, stage3Amount);
  }

  /**
   * @dev Fallback function
   */
  function() external payable {
    buyTokens();
  }

  function buyTokens() public payable {
    require(!isPaused, &#39;Sales are temporarily paused&#39;);

    address payable inv = msg.sender;
    require(inv != address(0));

    uint256 weiAmount = msg.value;
    require(weiAmount >= minPurchase, &#39;Amount of ether is not enough to buy even the smallest token part&#39;);

    uint256 cleanWei; // amount of wei to use for purchase excluding change and max supply overflows
    uint256 change;
    uint256 tokens;
    uint256 tokensNoBonuses;
    uint256 totalSupply;
    uint256 supply;

    tokensNoBonuses = weiAmount.mul(1E10).div(rate);

    if (weiAmount >= 10 ether) {
      tokens = tokensNoBonuses.mul(112).div(100);
    } else if (weiAmount >= 5 ether) {
      tokens = tokensNoBonuses.mul(105).div(100);
    } else {
      tokens = tokensNoBonuses;
    }

    totalSupply = token.totalSupply();
    supply = totalSupply.sub(token.balanceOf(address(this)));

    if (supply.add(tokens) > maxSupply) {
      tokens = maxSupply.sub(supply);
      require(tokens > 0, &#39;There are currently no tokens for sale&#39;);
      if (tokens >= tokensNoBonuses) {
        cleanWei = weiAmount;
      } else {
        cleanWei = tokens.mul(rate).div(1E10);
        change = weiAmount.sub(cleanWei);
      }
    } else {
      cleanWei = weiAmount;
    }

    if (token.balanceOf(address(this)) >= tokens) {
      token.transfer(inv, tokens);
    } else if (token.balanceOf(address(this)) == 0) {
      token.mint(inv, tokens);
    } else {
      uint256 mintAmount = tokens.sub(token.balanceOf(address(this)));

      token.mint(address(this), mintAmount);
      token.transfer(inv, tokens);
    }

    wallet.transfer(cleanWei);

    if (change > 0) {
      inv.transfer(change); 
    }
  }
}