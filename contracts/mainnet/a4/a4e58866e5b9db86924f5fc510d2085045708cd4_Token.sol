// 0.4.20+commit.3155dd80.Emscripten.clang
pragma solidity ^0.4.20;

/**
 * Ethereum Token callback
 */
interface tokenRecipient {
  function receiveApproval( address from, uint256 value, bytes data ) external;
}

/**
 * ERC223 callback
 */
interface ContractReceiver {
  function tokenFallback( address from, uint value, bytes data ) external;
}

/**
 * Ownable Contract
 */
contract Owned {
  address public owner;

  function owned() public {
    owner = msg.sender;
  }

  function changeOwner(address _newOwner) public onlyOwner {
    owner = _newOwner;
  }

  modifier onlyOwner {
    require (msg.sender == owner);
    _;
  }
}

/**
 * ERC20 token with added ERC223 and Ethereum-Token support
 *
 * Blend of multiple interfaces:
 * - https://theethereum.wiki/w/index.php/ERC20_Token_Standard
 * - https://www.ethereum.org/token (uncontrolled, non-standard)
 * - https://github.com/Dexaran/ERC23-tokens/blob/Recommended/ERC223_Token.sol
 */
contract Token is Owned {
  string  public name;
  string  public symbol;
  uint8   public decimals = 18;
  uint256 public totalSupply;

  mapping( address => uint256 ) balances;
  mapping( address => mapping(address => uint256) ) allowances;

  /**
   * ERC20 Approval Event
   */
  event Approval(
    address indexed owner,
    address indexed spender,
    uint value
  );

  /**
   * ERC20-compatible version only, breaks ERC223 compliance but block
   * explorers and exchanges expect ERC20. Also, cannot overload events
   */
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  function Token(
    uint256 _initialSupply,
    string _tokenName,
    string _tokenSymbol
  )
    public
  {
    totalSupply = _initialSupply * 10**18;
    balances[msg.sender] = _initialSupply * 10**18;

    name = _tokenName;
    symbol = _tokenSymbol;
  }

  /**
   * ERC20 Balance Of Function
   */
  function balanceOf( address owner ) public constant returns (uint) {
    return balances[owner];
  }

  /**
   * ERC20 Approve Function
   */
  function approve( address spender, uint256 value ) public returns (bool success) {
    // WARNING! When changing the approval amount, first set it back to zero
    // AND wait until the transaction is mined. Only afterwards set the new
    // amount. Otherwise you may be prone to a race condition attack.
    // See: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    allowances[msg.sender][spender] = value;
    Approval( msg.sender, spender, value );
    return true;
  }

  /**
   * Recommended fix for known attack on any ERC20
   */
  function safeApprove(
    address _spender,
    uint256 _currentValue,
    uint256 _value
  )
    public
    returns (bool success)
  {
    // If current allowance for _spender is equal to _currentValue, then
    // overwrite it with _value and return true, otherwise return false.

    if (allowances[msg.sender][_spender] == _currentValue)
      return approve(_spender, _value);

    return false;
  }

  /**
   * ERC20 Allowance Function
   */
  function allowance(
    address owner,
    address spender
  )
    public constant
    returns (uint256 remaining)
  {
    return allowances[owner][spender];
  }

  /**
   * ERC20 Transfer Function
   */
  function transfer(
    address to,
    uint256 value
  )
    public
    returns (bool success)
  {
    bytes memory empty; // null
    _transfer( msg.sender, to, value, empty );
    return true;
  }

  /**
   * ERC20 Transfer From Function
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool success)
  {
    require( value <= allowances[from][msg.sender] );

    allowances[from][msg.sender] -= value;
    bytes memory empty;
    _transfer( from, to, value, empty );

    return true;
  }

  /**
   * Ethereum Token Approve and Call Function
   */
  function approveAndCall(
    address spender,
    uint256 value,
    bytes context
  )
    public
    returns (bool success)
  {
    if (approve(spender, value))
    {
      tokenRecipient recip = tokenRecipient(spender);

      if (isContract(recip))
        recip.receiveApproval(msg.sender, value, context);

      return true;
    }

    return false;
  }


  /**
   * ERC223 Transfer and invoke specified callback
   */
  function transfer(
    address to,
    uint value,
    bytes data,
    string custom_fallback
  )
    public
    returns (bool success)
  {
    _transfer( msg.sender, to, value, data );

    // throws if custom_fallback is not a valid contract call
    require(
      address(to).call.value(0)(
        bytes4(keccak256(custom_fallback)),
        msg.sender,
        value,
        data
      )
    );

    return true;
  }

  /**
   * ERC223 Transfer to a contract or externally-owned account
   */
  function transfer(
    address to,
    uint value,
    bytes data
  )
    public
    returns (bool success)
  {
    if (isContract(to)) {
      return transferToContract( to, value, data );
    }

    _transfer( msg.sender, to, value, data );
    return true;
  }

  /**
   * ERC223 Transfer to contract and invoke tokenFallback() method
   */
  function transferToContract(
    address to,
    uint value,
    bytes data
  )
    private
    returns (bool success)
  {
    _transfer( msg.sender, to, value, data );

    ContractReceiver rx = ContractReceiver(to);

    if (isContract(rx)) {
      rx.tokenFallback( msg.sender, value, data );
      return true;
    }

    return false;
  }

  /**
   * ERC223 fetch contract size (must be nonzero to be a contract)
   */
  function isContract(address _addr)
    private
    constant
    returns (bool)
  {
    uint length;
    assembly { length := extcodesize(_addr) }
    return (length > 0);
  }

  /**
   * Transfer Functionality
   */
  function _transfer(
    address from,
    address to,
    uint value,
    bytes data
  )
    internal
  {
    require( to != 0x0 );
    require( balances[from] >= value );
    require( balances[to] + value > balances[to] ); // catch overflow

    balances[from] -= value;
    balances[to] += value;

    bytes memory ignore;
    ignore = data; // ignore compiler warning
    Transfer( from, to, value ); // ERC20-version, ignore data
  }
}