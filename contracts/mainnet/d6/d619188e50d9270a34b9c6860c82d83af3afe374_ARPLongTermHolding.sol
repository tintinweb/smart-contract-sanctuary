pragma solidity ^0.4.23;


/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
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
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
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
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

contract ARPLongTermHolding {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using Math for uint256;

    // During the first 31 days of deployment, this contract opens for deposit of ARP.
    uint256 public constant DEPOSIT_PERIOD      = 31 days; // = 1 months

    // 16 months after deposit, user can withdrawal all his/her ARP.
    uint256 public constant WITHDRAWAL_DELAY    = 480 days; // = 16 months

    // Ower can drain all remaining ARP after 3 years.
    uint256 public constant DRAIN_DELAY         = 1080 days; // = 3 years.

    // 50% bonus ARP return
    uint256 public constant BONUS_SCALE         = 2;

    // ERC20 basic token contract being held
    ERC20 public arpToken;
    address public owner;
    uint256 public arpDeposited;
    uint256 public depositStartTime;
    uint256 public depositStopTime;

    struct Record {
        uint256 amount;
        uint256 timestamp;
    }

    mapping (address => Record) records;

    /* 
     * EVENTS
     */

    /// Emitted when all ARP are drained.
    event Drained(uint256 _amount);

    /// Emitted for each sucuessful deposit.
    uint256 public depositId = 0;
    event Deposit(uint256 _depositId, address indexed _addr, uint256 _amount, uint256 _bonus);

    /// Emitted for each sucuessful withdrawal.
    uint256 public withdrawId = 0;
    event Withdrawal(uint256 _withdrawId, address indexed _addr, uint256 _amount);

    /// Initialize the contract
    constructor(ERC20 _arpToken, uint256 _depositStartTime) public {
        arpToken = _arpToken;
        owner = msg.sender;
        depositStartTime = _depositStartTime;
        depositStopTime = _depositStartTime.add(DEPOSIT_PERIOD);
    }

    /*
     * PUBLIC FUNCTIONS
     */

    /// Drains ARP.
    function drain() public {
        require(msg.sender == owner);
        // solium-disable-next-line security/no-block-members
        require(now >= depositStartTime.add(DRAIN_DELAY));

        uint256 balance = arpToken.balanceOf(address(this));
        require(balance > 0);

        arpToken.safeTransfer(owner, balance);

        emit Drained(balance);
    }

    function() public {
        // solium-disable-next-line security/no-block-members
        if (now >= depositStartTime && now < depositStopTime) {
            deposit();
        // solium-disable-next-line security/no-block-members
        } else if (now > depositStopTime){
            withdraw();
        } else {
            revert();
        }
    }

    /// Gets the balance of the specified address.
    function balanceOf(address _owner) view public returns (uint256) {
        return records[_owner].amount;
    }

    /// Gets the withdrawal timestamp of the specified address.
    function withdrawalTimeOf(address _owner) view public returns (uint256) {
        return records[_owner].timestamp.add(WITHDRAWAL_DELAY);
    }

    /// Deposits ARP.
    function deposit() private {
        uint256 amount = arpToken
            .balanceOf(msg.sender)
            .min256(arpToken.allowance(msg.sender, address(this)));
        require(amount > 0);

        uint256 bonus = amount.div(BONUS_SCALE);

        Record storage record = records[msg.sender];
        record.amount = record.amount.add(amount).add(bonus);
        // solium-disable-next-line security/no-block-members
        record.timestamp = now;
        records[msg.sender] = record;

        arpDeposited = arpDeposited.add(amount).add(bonus);

        if (bonus > 0) {
            arpToken.safeTransferFrom(owner, address(this), bonus);
        }
        arpToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(depositId++, msg.sender, amount, bonus);
    }

    /// Withdraws ARP.
    function withdraw() private {
        require(arpDeposited > 0);

        Record storage record = records[msg.sender];
        require(record.amount > 0);
        // solium-disable-next-line security/no-block-members
        require(now >= record.timestamp.add(WITHDRAWAL_DELAY));
        uint256 amount = record.amount;
        delete records[msg.sender];

        arpDeposited = arpDeposited.sub(amount);

        arpToken.safeTransfer(msg.sender, amount);

        emit Withdrawal(withdrawId++, msg.sender, amount);
    }
}