//SPDX-License-Identifier: Unlicense
pragma solidity =0.6.6;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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


contract LamboPresale is Ownable {
  using SafeMath for uint256;

  IERC20 public Token;
  uint256 public TokenDecimals;

  mapping(address => uint256) public investments; // total WEI invested per address (1ETH = 1e18WEI)
  mapping (uint256=> address) public investors;   // list of participating investor addresses
  uint256 private _investorCount = 0;             // number of unique addresses that have invested

  mapping(address => bool) public whitelistAddresses; // all addresses eligible for presale
  mapping(address => bool) public devAddresses;       // all addresses that are devs

  uint256 public constant INVESTMENT_LIMIT_PRESALE = 1.5  ether; // 1.5 ETH is maximum investment limit for pre-sale
  uint256 public constant INVESTMENT_LIMIT_DEVELOPER = 2.88 ether; // 2.88 ETH is maximum investment limit for developer pre-sale
  uint256 public constant INVESTMENT_LIMIT_PUBLIC = 0.5 ether;    //0.5 ETH is maximum investment limit for public pre-sale

  uint256 public constant INVESTMENT_RATIO_PRESALE   = 28;// divided by 100 // whitelist pre-sale rate is 0.28 ETH/$LAMBO
  uint256 public constant INVESTMENT_RATIO_DEVELOPER = 18;// divided by 100 // developer pre-sale rate is 0.18 ETH/$LAMBO
  uint256 public constant INVESTMENT_RATIO_PUBLIC = 42;   // divided by 100 // public pre-sale rate is 0.42 ETH/$LAMBO (Uniswap listing price)

  bool public isPresaleActive = false; // investing is only allowed if presale is active
  bool public allowPublicInvestment = false; // public investing is only allowed once the devlist/whitelist presale is over

  constructor() public {
    TokenDecimals = 1e18;
  }

  function passTokenAddress(address tokenAddress) public onlyOwner {
    Token = IERC20(tokenAddress);
  }

  function startPresale() public onlyOwner {
    isPresaleActive = true;
  }

  function startPublicPresale() public onlyOwner {
    allowPublicInvestment = true;
  }

  function endPresale() public onlyOwner {
    isPresaleActive = false;
    payable(owner()).transfer(address(this).balance);
    Token.transfer(address(Token), Token.balanceOf(address(this)));
  }

  function addWhitelistAddresses(address[] calldata _whitelistAddresses) external onlyOwner {
    for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
      whitelistAddresses[_whitelistAddresses[i]] = true;
    }
  }

  function addDevAddresses(address[] calldata _devlistAddresses) external onlyOwner {
    for (uint256 i = 0; i < _devlistAddresses.length; i++) {
      devAddresses[_devlistAddresses[i]] = true;
    }
  }

  function refundInvestors() external onlyOwner {
    for (uint256 i = 0; i < _investorCount; i++) {
      address addressToRefund = investors[i];
      uint256 refundAmount = investments[investors[i]];

//      console.log("addressToRefund: '%s'", addressToRefund);
//      console.log("refundAmount: '%s'", refundAmount);

      payable(addressToRefund).transfer(refundAmount);
      investments[investors[i]].sub(refundAmount);
    }
  }

  modifier presaleActive() {
    require(isPresaleActive, "Presale is currently not active.");
    _;
  }

  modifier eligibleForPresale() {
    require(whitelistAddresses[_msgSender()] || devAddresses[_msgSender()] || allowPublicInvestment, "Your address is not whitelisted for either presale, or the public presale hasn't started yet.");
    _;
  }

  receive()
    external
    payable
    presaleActive
    eligibleForPresale
  {
    uint256 addressTotalInvestment = investments[_msgSender()].add(msg.value);

    uint256 amountOfTokens;

    if (isDevAddress(_msgSender()) && !allowPublicInvestment){

      require(addressTotalInvestment <= INVESTMENT_LIMIT_DEVELOPER, "Max investment per dev pre-sale address is 2.88 ETH.");

      amountOfTokens = msg.value.mul(100).div(INVESTMENT_RATIO_DEVELOPER);

    } else if (isWhitelisted(_msgSender()) && !allowPublicInvestment) {

      require(addressTotalInvestment <= INVESTMENT_LIMIT_PRESALE, "Max investment per whitelist pre-sale address is 1.5 ETH.");

      amountOfTokens = msg.value.mul(100).div(INVESTMENT_RATIO_PRESALE);

    } else if (allowPublicInvestment) {

      require(addressTotalInvestment <= INVESTMENT_LIMIT_PUBLIC, "Max investment for every address (once public presale has started) is 0.5 ETH.");

      amountOfTokens = msg.value.mul(100).div(INVESTMENT_RATIO_PUBLIC);
    }

    Token.transfer(_msgSender(), amountOfTokens);

    investors[_investorCount] = msg.sender;
    _investorCount++;

    investments[_msgSender()] = addressTotalInvestment;

  }

  function isWhitelisted(address adr) public view returns (bool){
    return whitelistAddresses[adr];
  }

  function isDevAddress(address adr) public view returns (bool){
    return devAddresses[adr];
  }

  function getInvestedAmount(address adr) public view returns (uint256){
      return investments[adr];
  }

  function getInvestorCount() public view returns (uint256){
    return _investorCount;
  }

  function getPresaleInvestmentLimit() view public returns (uint256) {
    return INVESTMENT_LIMIT_PRESALE;
  }

  function getDeveloperPresaleInvestmentLimit() view public returns (uint256) {
    return INVESTMENT_LIMIT_DEVELOPER;
  }

  function getPublicPresaleInvestmentLimit() view public returns (uint256) {
    return INVESTMENT_RATIO_PUBLIC;
  }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {
    "": {}
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}