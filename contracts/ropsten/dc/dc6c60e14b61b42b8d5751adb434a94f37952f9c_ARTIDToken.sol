//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\IERC20.sol
pragma solidity ^0.4.24;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
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

//File: node_modules\openzeppelin-solidity\contracts\math\SafeMath.sol
pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
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

//File: node_modules\openzeppelin-solidity\contracts\token\ERC20\ERC20.sol
pragma solidity ^0.4.24;




/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

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
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
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
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
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
    require(account != 0);
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
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

//File: node_modules\openzeppelin-solidity\contracts\ownership\Ownable.sol
pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
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

//File: contracts\ARTIDToken.sol
/**
 * @title RKR token
 *
 * @version 1.0
 * @author ARTID
 */
pragma solidity ^0.4.24;






contract ARTIDToken is ERC20 {
    using SafeMath for uint256;
    
    string public constant name = "ARTIDToken";
    string public constant symbol = "ARTID";
    uint8 public constant decimals = 18;
    //uint256 public constant TOTAL_SUPPLY = 120e6 * 1e18;

     /**
     * @dev Constructor of ARTIDToken 
     */
    constructor() public {
        _initialMint();
        //_mint(msg.sender, TOTAL_SUPPLY);
    }

    function _initialMint() private{
        //1
        _mint(address(0x7003d8df7b38f4c758975fd4800574fecc0da7cd), 12e6 * 1e18);
        //2
        _mint(address(0xdfdaa3b74fcc65b9e90d5922a74f8140a2b67d0f), 12e6 * 1e18);
        //3
        _mint(address(0x0141f8d84f25739e426fd19783a1ec3a1f5a35e0), 12e6 * 1e18);
        //4
        _mint(address(0x8863f676474c65e9b85dc2b7fee16188503ae790), 12e6 * 1e18);
        //5
        _mint(address(0xabf2e86c69648e9ed6cd284f4f82df3f9df7a3dd), 12e6 * 1e18);
        //6
        _mint(address(0x66348c99019d6c21fe7c4f954fd5a5cb0b41aa2c), 12e6 * 1e18);
        //7
         _mint(address(0x3257b7ebb5e52c67cdd0c1112b28db362b7463cd), 12e6 * 1e18);
        //8
         _mint(address(0x0c26122396a4bd59d855f19b69dadba3b19ba4d7), 12e6 * 1e18);
        //9
         _mint(address(0x5b38e7b2c9ac03fa53e96220dcd299e3b47e1624), 12e6 * 1e18);
        //10
         _mint(address(0x5593105770cd53802c067734d7e321e22e08c9a4), 3949480 * 1e18);
        //11
         _mint(address(0xa8cdeef81970f44444eeb2c87c7eb2eb9a097a34), 3022807 * 1e18);
        //12
         _mint(address(0x0b9e4d7d67552a3a044cbdc024188eaa057b72bc), 2400100 * 1e18);
        //13
         _mint(address(0x7631029bd3f117b1a746506a04af966a5ede1b46), 2400000 * 1e18);
        //14
         _mint(address(0x1ba5d47dcb2dc5d0afa86be3b7f5e2c421525b75), 109391 * 1e18);
        //15
         _mint(address(0xb847988c1ea802842ff89466c8a35d5d052840bb), 100000 * 1e18);
        //16
         _mint(address(0xcd807ad1b19f9a5a9fc1af1b1da448696d041504), 8363 * 1e18);
        //17
         _mint(address(0x3ed4ac1eced4bd01c51a2317609120a16b85e19e), 8248 * 1e18);
        //18
         _mint(address(0xfc886ff0fb687826e5a2572f366e38a6e81ea249), 364 * 1e18);
        //19
         _mint(address(0xc6a1c5c60ecf4d6bf8b340f207505272fa281ede), 201 * 1e18);
        //20
         _mint(address(0xa8cb97cbd42acca81eb3680d9b94ace459b502a2), 182 * 1e18);
        //21
         _mint(address(0xf22e45982ed32849ee8fe2a342534f2a53b93695), 120 * 1e18);
        //22
         _mint(address(0xe9d520f036d16a48636bf16371dcce0819cf6229), 100 * 1e18);
        //23
         _mint(address(0x84d6339aa4900310aa9780ec66db57c88d2cd734), 100 * 1e18);
        //24
         _mint(address(0x2c049093f263669a432dac59dac31d3c2b9c1996), 100 * 1e18);
        //25
         _mint(address(0x23345fd753519795b9d7238690ababbb0469eb3e), 100 * 1e18);
        //26
         _mint(address(0x421926ee0cb7941058387fc1a85532e7a94aa3c1), 100 * 1e18);
        //27
         _mint(address(0x82389b139658378cdec2c1ed600aa4717ca59fad), 100 * 1e18);
        //28
         _mint(address(0x93bb098498d538749a1d00f564555430a06bffbe), 44 * 1e18);
        //29
         _mint(address(0xe619413a56bfcafbb84916f86d646248cc1abe76), 30 * 1e18);
        //30
         _mint(address(0xce2dae844a2f473cb10e72ea5b5cd82ce1c86c76), 30 * 1e18);
        //31
         _mint(address(0xbd189a18b2cc01bcf00574ee4f7ddad1e15183ee), 20 * 1e18);
        //32
         _mint(address(0x0c4206f1e138cc8f584b89b6f62a4330120237ee), 20 * 1e18);
    }
}