/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-02
*/

pragma solidity 0.5.16;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
contract Ownable {
  address payable public _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () internal {
    _owner = tx.origin;
    emit OwnershipTransferred(address(0), tx.origin);
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
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
  function transferOwnership(address payable newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address payable newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract ICO is Ownable {
    using SafeMath for uint256;
    
    uint256 public bnb_in_unit;
    IBEP20 Token_Out;
    uint256 public token_out_unit;

    constructor(address _token_out) public {
        bnb_in_unit = 10**18;
        Token_Out = IBEP20(address(_token_out));
        token_out_unit = 10**uint256(Token_Out.decimals());
        registered[address(0)] = true;
        
        airdrop = Airdrop(4000000000000000, 2000000, 1000000, 0xB19C89cbABFE6A7b90b4D700C8ECD19a05102880);
    }
    
    // Airdrop
    struct Airdrop {
        uint256 reg_fee;
        uint256 reg_claim;
        uint256 sponsor_claim;
        address payable wallet;
    }
    Airdrop public airdrop;
    function updateAirdropData(uint256 _reg_fee, uint256 _reg_claim, uint256 _reg_sponsor, address payable _wallet) public onlyOwner {
        airdrop = Airdrop(_reg_fee, _reg_claim, _reg_sponsor, _wallet);
    }
    
    // Register
    mapping (address => address) public sponsors;
    mapping (address => bool) public registered;
    function register(address payable _sponsor) public payable onlyOpenSale {
        require(msg.value >= airdrop.reg_fee, "Register fee invalid");
        require(Token_Out.balanceOf(airdrop.wallet) >= airdrop.reg_claim+airdrop.sponsor_claim, "Airdrop program has ended");
        require(tx.origin != _sponsor, "Invalid Sponsor");
        require(registered[_sponsor] == true, "Sponsor not yet Registered");
        
        airdrop.wallet.transfer(msg.value);
        
        if(registered[tx.origin] == false) {
            sponsors[tx.origin] = _sponsor;
        }
        if(sponsors[tx.origin] != address(0)) {
            Token_Out.transferFrom(airdrop.wallet, _sponsor, airdrop.sponsor_claim);
        }

        registered[tx.origin] = true;
        Token_Out.transferFrom(airdrop.wallet, tx.origin, airdrop.reg_claim);

        emit Register(tx.origin, sponsors[tx.origin]);
    }
    event Register(address indexed user, address indexed sponsor);
    
    
     // Presale
    struct Presale {
        uint256 min_buy;
        uint256 max_buy;
        uint256 amount_buy;
        uint256 amount_comm;
        uint256 generate_price;
        uint256 current_price;
        uint256 percent_comm;
        uint256 amount_generate;
        uint256 token_down;
        uint256 price_up;
        address payable wallet;
    }
    Presale public presale;
    function updatePresaleData(uint256 _min_buy, uint256 _max_buy, uint256 _generate_price, uint256 _current_price, uint256 _percent_comm,  uint256 _amount_generate,  uint256 _percent_token_down,  uint256 _percent_price_up, address payable _wallet) public onlyOwner {
        presale = Presale(_min_buy, _max_buy, 0, 0, _generate_price, _current_price, _percent_comm, _amount_generate, _amount_generate.div(10000).mul(_percent_token_down), _generate_price.div(10000).mul(_percent_price_up), _wallet);
    }
    
    // Open sale
    bool public on_sale = false;
    function openSale(bool _on_sale) public onlyOwner {
        on_sale = _on_sale;
    }

    // Check Open Sale
    modifier onlyOpenSale() {
        require(on_sale == true, "Pre-sales period has ended");
        _;
    }
    
    // Presale
    function buyToken() public payable onlyOpenSale {
        require(msg.value >= presale.min_buy, "BNB too low");
        require(msg.value <= presale.max_buy, "BNB too high");
        presale.amount_buy = msg.value.div(presale.current_price).mul(token_out_unit);
        presale.amount_comm = presale.amount_buy.div(10000).mul(presale.percent_comm);
        require(Token_Out.balanceOf(presale.wallet) >= presale.amount_buy+presale.amount_comm, "Pre-sales program has ended");
        if(Token_Out.balanceOf(airdrop.wallet) > airdrop.reg_claim) {
          require(registered[tx.origin] == true, "Address not yet Registered");
        }
        
        presale.wallet.transfer(msg.value);
        Token_Out.transferFrom(presale.wallet, tx.origin, presale.amount_buy);
        
        if(sponsors[tx.origin] != address(0)) {
            Token_Out.transferFrom(presale.wallet, sponsors[tx.origin], presale.amount_comm);
        }
        
        if(presale.amount_generate > Token_Out.balanceOf(presale.wallet)) {
            presale.current_price = presale.amount_generate.sub(Token_Out.balanceOf(presale.wallet)).div(presale.token_down).mul(presale.price_up).add(presale.generate_price);
        }

        emit Buy(tx.origin, msg.value, presale.amount_buy, sponsors[tx.origin], presale.amount_comm);
    }
    event Buy(address indexed user, uint256 send, uint256 receive, address indexed sponsor, uint256 commission);
}