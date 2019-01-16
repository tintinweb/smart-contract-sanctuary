pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    // modify by chris to make sure the proxy contract can set the first owner
    require(msg.sender == owner);
    _;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwnerProxyCall() {
    // modify by chris to make sure the proxy contract can set the first owner
    if(owner!=address(0)){
      require(msg.sender == owner);
    }
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwnerProxyCall {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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


/// @title BibBom Token Holding Incentive Program
/// @author TranTho - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="0d7965626b6b4d6f646a6f6260236e6260">[email&#160;protected]</a>>.
/// For more information, please visit https://bigbom.com.
contract BBOHoldingContract {
    using SafeMath for uint;
    using Math for uint;
   
    // During the first 60 days of deployment, this contract opens for deposit of BBO.
    uint public constant DEPOSIT_PERIOD             = 60 days; // = 2 months

    // 18 months after deposit, user can withdrawal all or part of his/her BBO with bonus.
    // The bonus is this contract&#39;s initial BBO balance.
    uint public constant WITHDRAWAL_DELAY           = 540 days; // = 1 year and 6 months

    // Send 0.001ETH per 10000 BBO partial withdrawal, or 0 for a once-for-all withdrawal.
    // All ETH will be returned.
    uint public constant WITHDRAWAL_SCALE           = 1E7; // 1ETH for withdrawal of 10,000,000 BBO.

    // Ower can drain all remaining BBO after 3 years.
    uint public constant DRAIN_DELAY                = 1080 days; // = 3 years.
    
    address public bboTokenAddress  = 0x0;
    address public owner            = 0x0;

    uint public bboDeposited        = 0;
    uint public depositStartTime    = 0;
    uint public depositStopTime     = 0;

    struct Record {
        uint bboAmount;
        uint timestamp;
    }

    mapping (address => Record) records;
    
    /* 
     * EVENTS
     */

    /// Emitted when program starts.
    event Started(uint _time);

    /// Emitted when all BBO are drained.
    event Drained(uint _bboAmount);

    /// Emitted for each sucuessful deposit.
    uint public depositId = 0;
    event Deposit(uint _depositId, address indexed _addr, uint _bboAmount);

    /// Emitted for each sucuessful deposit.
    uint public withdrawId = 0;
    event Withdrawal(uint _withdrawId, address indexed _addr, uint _bboAmount);

    /// @dev Initialize the contract
    /// @param _bboTokenAddress BBO ERC20 token address
    constructor (address _bboTokenAddress, address _owner) public {
        require(_bboTokenAddress != address(0));
        require(_owner != address(0));

        bboTokenAddress = _bboTokenAddress;
        owner = _owner;
    }

    /*
     * PUBLIC FUNCTIONS
     */

    /// @dev start the program.
    function start() public {
        require(msg.sender == owner);
        require(depositStartTime == 0);

        depositStartTime = now;
        depositStopTime  = depositStartTime + DEPOSIT_PERIOD;

        emit Started(depositStartTime);
    }


    /// @dev drain BBO.
    function drain() public {
        require(msg.sender == owner);
        require(depositStartTime > 0 && now >= depositStartTime + DRAIN_DELAY);

        uint balance = bboBalance();
        require(balance > 0);

        require(ERC20(bboTokenAddress).transfer(owner, balance));

        emit Drained(balance);
    }

    function () payable {
        require(depositStartTime > 0);

        if (now >= depositStartTime && now <= depositStopTime) {
            depositBBO();
        } else if (now > depositStopTime){
            withdrawBBO();
        } else {
            revert();
        }
    }

    /// @return Current BBO balance.
    function bboBalance() public constant returns (uint) {
        return ERC20(bboTokenAddress).balanceOf(address(this));
    }

    /// @dev Deposit BBO.
    function depositBBO() payable {
        require(depositStartTime > 0);
        require(msg.value == 0);
        require(now >= depositStartTime && now <= depositStopTime);
        
        ERC20 bboToken = ERC20(bboTokenAddress);
        uint bboAmount = bboToken
            .balanceOf(msg.sender)
            .min256(bboToken.allowance(msg.sender, address(this)));

        require(bboAmount > 0);

        Record storage record = records[msg.sender];
        record.bboAmount = record.bboAmount.add(bboAmount);
        record.timestamp = now;
        records[msg.sender] = record;

        bboDeposited = bboDeposited.add(bboAmount);

        emit Deposit(depositId++, msg.sender, bboAmount);
        
        require(bboToken.transferFrom(msg.sender, address(this), bboAmount));
    }

    /// @dev Withdrawal BBO.
    function withdrawBBO() payable {
        require(depositStartTime > 0);
        require(bboDeposited > 0);

        Record storage record = records[msg.sender];
        require(now >= record.timestamp + WITHDRAWAL_DELAY);
        require(record.bboAmount > 0);

        uint bboWithdrawalBase = record.bboAmount;
        if (msg.value > 0) {
            bboWithdrawalBase = bboWithdrawalBase
                .min256(msg.value.mul(WITHDRAWAL_SCALE));
        }

        uint bboBonus = getBonus(bboWithdrawalBase);
        uint balance = bboBalance();
        uint bboAmount = balance.min256(bboWithdrawalBase + bboBonus);
        
        bboDeposited = bboDeposited.sub(bboWithdrawalBase);
        record.bboAmount = record.bboAmount.sub(bboWithdrawalBase);

        if (record.bboAmount == 0) {
            delete records[msg.sender];
        } else {
            records[msg.sender] = record;
        }

        emit Withdrawal(withdrawId++, msg.sender, bboAmount);

        require(ERC20(bboTokenAddress).transfer(msg.sender, bboAmount));
        if (msg.value > 0) {
            msg.sender.transfer(msg.value);
        }
    }

    function getBonus(uint _bboWithdrawalBase) constant returns (uint) {
        return internalCalculateBonus(bboBalance() - bboDeposited,bboDeposited, _bboWithdrawalBase);
    }

    function internalCalculateBonus(uint _totalBonusRemaining, uint _bboDeposited, uint _bboWithdrawalBase) constant returns (uint) {
        require(_bboDeposited > 0);
        require(_totalBonusRemaining >= 0);

        // The bonus is non-linear function to incentivize later withdrawal.
        // bonus = _totalBonusRemaining * power(_bboWithdrawalBase/_bboDeposited, 1.0625)
        return _totalBonusRemaining
            .mul(_bboWithdrawalBase.mul(sqrt(sqrt(sqrt(sqrt(_bboWithdrawalBase))))))
            .div(_bboDeposited.mul(sqrt(sqrt(sqrt(sqrt(_bboDeposited))))));
    }

    function sqrt(uint x) internal constant returns (uint) {
        uint y = x;
        while (true) {
            uint z = (y + (x / y)) / 2;
            uint w = (z + (x / z)) / 2;
            if (w == y) {
                if (w < y) return w;
                else return y;
            }
            y = w;
        }
    }
}