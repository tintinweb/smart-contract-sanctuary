/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

pragma solidity 0.5.16;

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

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
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
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
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
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
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract BEP20Contract is Ownable {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _payableInvestors;

    string private _name;
    // How many token units a buyer gets per ETH/wei during Pre sale. The ETH price is fixed at 400$ during Pre sale.
    uint256 public preSaleRate = 0.0000029 ether;
    // Min purchase size of incoming ETH during pre sale period fixed at 0.1 ETH
    uint256 public minPurchasePreSale = 0.0000029 ether;
    // Max purchase size of incoming ETH during pre sale period fixed at 4 ETH
    uint256 public maxPurchasePreSale = 4 ether;
    // Token amount distributed during the Pre sale
    uint256 public tokenDistributedPreSale;
    // Amount of ETH/wei raised during the Pre sale
    uint256 public EthRaisedPreSale;
    // Token base Pre sale
    address public BASEToken;

    constructor() public {
      _name = "Pre Sale Contract";
    }

    /**
    * @dev Returns the name of the token.
    */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
    * @dev See {BEP20-balanceOf}.
    */
    function getBalance() public view returns (uint256) {
        return IBEP20(BASEToken).balanceOf(address(this));
    }

    function withdrawBalance() external onlyOwner {
        IBEP20(BASEToken).transfer(owner(), getBalance());
    }

    function updateBaseToken(address _account) external onlyOwner {
        BASEToken = _account;
    }

    function updatePreSaleRate(uint256 _preSaleRateAmount) external onlyOwner {
        preSaleRate = (_preSaleRateAmount).mul(1 wei);
    }

    function updateMinPurchasePreSale(uint256 _minPurchasePreSaleAmount) external onlyOwner {
        minPurchasePreSale = (_minPurchasePreSaleAmount).mul(1 wei);
    }

    function updateMaxPurchasePreSale(uint256 _maxPurchasePreSaleAmount) external onlyOwner {
        maxPurchasePreSale = (_maxPurchasePreSaleAmount).mul(1 wei);
    }

    function getBalancePayable() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawBalancePayable(uint256 _amountWithdraw) external onlyOwner {
        uint256 _amount = _amountWithdraw;//getBalancePayable();

        (bool success, ) = msg.sender.call.value(_amount)("");
        require(success, "Failed to send Ether");

        _balances[address(this)] -= _amount;
    }

    function buyToken() external payable returns (bool) {
        uint256 _amount = msg.value;
        
        uint256 _amountToken = _getTokenPreSaleAmount(_amount);
        uint256 _maxPurchasePreSaleInvestor = _payableInvestors[_msgSender()] + _amount;

        require(_amount >= minPurchasePreSale, "Failed the amount is not respecting the minimum deposit of Presale.");
        require(_maxPurchasePreSaleInvestor <= maxPurchasePreSale, "Failed the amount is not respecting the maximum deposit of Presale.");
        require(_amountToken > 0, "Invalid token amount.");
        require(IBEP20(BASEToken).transfer(_msgSender(),_amountToken));

        _balances[address(this)] += _amount;

        tokenDistributedPreSale = tokenDistributedPreSale.add(_amountToken);
        EthRaisedPreSale = EthRaisedPreSale.add(_amount);
        _payableInvestors[_msgSender()] += _amount;
        return true;
    }

    // Calcul the amount of token the benifiaciary will get by buying during Presale 
    function _getTokenPreSaleAmount(uint256 _weiAmount) internal view returns (uint256) {
      uint256 _amountToSend = _weiAmount.div(preSaleRate).mul(10 ** 18);
      return _amountToSend;
    }
}