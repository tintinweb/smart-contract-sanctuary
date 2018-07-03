pragma solidity ^0.4.24;

// File: browser/SafeMath.sol

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

// File: browser/jimbolia.sol

/**
 * Jimbolia
 *
 * @title A fixed supply ERC-20 token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
contract JimboliaT {
    using SafeMath for uint;
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    /**
     * Constructs the Token contract and gives all of the supply to the address
     *     that deployed it. The fixed supply is 1 billion tokens with up to 18
     *     decimal places.
     */
    function Token() public {
        symbol = &#39;JIT&#39;;
        name = &#39;Jimbolia Token&#39;;
        decimals = 18;
        totalSupply = 20000 * 10**uint(decimals);
        balances[msg.sender] = totalSupply;
        Transfer(address(0), msg.sender, totalSupply);
    }
    /**
     * @dev Fallback function
     */
    function() public payable { revert(); }
    /**
     * Gets the token balance of any wallet.
     * @param _owner Wallet address of the returned token balance.
     * @return The balance of tokens in the wallet.
     */
    function balanceOf(address _owner)
        public
        constant
        returns (uint balance)
    {
        return balances[_owner];
    }
    /**
     * Transfers tokens from the sender&#39;s wallet to the specified `_to` wallet.
     * @param _to Address of the transfer&#39;s recipient.
     * @param _value Number of tokens to transfer.
     * @return True if the transfer succeeded.
     */
    function transfer(address _to, uint _value) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    /**
     * Transfer tokens from any wallet to the `_to` wallet. This only works if
     *     the `_from` wallet has already allocated tokens for the caller wallet
     *     using `approve`. The from wallet must have sufficient balance to
     *     transfer. The caller must have sufficient allowance to transfer.
     * @param _from Wallet address that tokens are withdrawn from.
     * @param _to Wallet address that tokens are deposited to.
     * @param _value Number of tokens transacted.
     * @return True if the transfer succeeded.
     */
    function transferFrom(address _from, address _to, uint _value)
        public
        returns (bool success)
    {
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    /**
     * Sender allows another wallet to `transferFrom` tokens from their wallet.
     * @param _spender Address of `transferFrom` recipient.
     * @param _value Number of tokens to `transferFrom`.
     * @return True if the approval succeeded.
     */
    function approve(address _spender, uint _value)
        public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    /**
     * Gets the number of tokens that an `_owner` has approved for a _spender
     *     to `transferFrom`.
     * @param _owner Wallet address that tokens can be withdrawn from.
     * @param _spender Wallet address that tokens can be deposited to.
     * @return The number of tokens allowed to be transferred.
     */
    function allowance(address _owner, address _spender)
        public
        constant
        returns (uint remaining)
    {
        return allowed[_owner][_spender];
    }
}