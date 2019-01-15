pragma solidity 0.4.24;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    int256 constant private INT256_MIN = -2**255;

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
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
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
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

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
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

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
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

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

contract UnlimitedAllowanceToken is IERC20 {
  using SafeMath for uint256;

  /* ============ State variables ============ */

  uint256 public totalSupply;
  mapping (address => uint256) public  balances;
  mapping (address => mapping (address => uint256)) public allowed;

  /* ============ Events ============ */

  event Approval(address indexed src, address indexed spender, uint256 amount);
  event Transfer(address indexed src, address indexed dest, uint256 amount);

  /* ============ Constructor ============ */

  constructor () public { }

  /* ============ Public functions ============ */

  function approve(address _spender, uint256 _amount) public returns (bool) {
    allowed[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
  }

  function transfer(address _dest, uint256 _amount) public returns (bool) {
    return transferFrom(msg.sender, _dest, _amount);
  }

  function transferFrom(address _src, address _dest, uint256 _amount) public returns (bool) {
    require(balances[_src] >= _amount, "Insufficient user balance");

    if (_src != msg.sender && allowance(_src, msg.sender) != uint256(-1)) {
      require(allowance(_src, msg.sender) >= _amount, "Insufficient user allowance");
      allowed[_src][msg.sender] = allowed[_src][msg.sender].sub(_amount);
    }

    balances[_src] = balances[_src].sub(_amount);
    balances[_dest] = balances[_dest].add(_amount);

    emit Transfer(_src, _dest, _amount);

    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function totalSupply() public view returns (uint256) {
    return totalSupply;
  }
}


/**
 * @title VeilEther
 * @author Veil
 *
 * WETH-like token with the ability to deposit ETH and approve in a single transaction
 */
contract VeilEther is UnlimitedAllowanceToken {
  using SafeMath for uint256;

  /* ============ Constants ============ */

  string constant public name = "Veil Ether"; // solium-disable-line uppercase
  string constant public symbol = "Veil ETH"; // solium-disable-line uppercase
  uint256 constant public decimals = 18; // solium-disable-line uppercase

  /* ============ Events ============ */

  event Deposit(address indexed dest, uint256 amount);
  event Withdrawal(address indexed src, uint256 amount);

  /* ============ Constructor ============ */

  constructor () public { }

  /* ============ Public functions ============ */

  /**
   * @dev Fallback function can be used to buy tokens by proxying the call to deposit()
   */
  function() public payable {
    deposit();
  }

  /* ============ New functionality ============ */

  /**
   * Buys tokens with Ether, exchanging them 1:1 and sets the spender allowance
   *
   * @param _spender          Spender address for the allowance
   * @param _allowance        Allowance amount
   */
  function depositAndApprove(address _spender, uint256 _allowance) public payable returns (bool) {
    deposit();
    approve(_spender, _allowance);
    return true;
  }

  /**
   * Withdraws from msg.sender&#39;s balance and transfers to a target address instead of msg.sender
   *
   * @param _amount           Amount to withdraw
   * @param _target           Address to send the withdrawn ETH
   */
  function withdrawAndTransfer(uint256 _amount, address _target) public returns (bool) {
    require(balances[msg.sender] >= _amount, "Insufficient user balance");
    require(_target != address(0), "Invalid target address");

    balances[msg.sender] = balances[msg.sender].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
    _target.transfer(_amount);

    emit Withdrawal(msg.sender, _amount);
    return true;
  }

  /* ============ Standard WETH functionality ============ */

  function deposit() public payable returns (bool) {
    balances[msg.sender] = balances[msg.sender].add(msg.value);
    totalSupply = totalSupply.add(msg.value);
    emit Deposit(msg.sender, msg.value);
    return true;
  }

  function withdraw(uint256 _amount) public returns (bool) {
    require(balances[msg.sender] >= _amount, "Insufficient user balance");

    balances[msg.sender] = balances[msg.sender].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
    msg.sender.transfer(_amount);

    emit Withdrawal(msg.sender, _amount);
    return true;
  }
}