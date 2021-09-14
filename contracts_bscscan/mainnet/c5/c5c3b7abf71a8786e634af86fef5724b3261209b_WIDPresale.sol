/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

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
abstract contract Ownable is Context {
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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
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

interface WIDToken {
  function mintAll(address account) external;
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}
contract WIDPresale is Ownable {
    using SafeMath for uint256;

    event AddTeamBalance(address indexed team, uint256 amount, bool status);
    event TokensPurchased(address indexed buyer, uint256 indexed amount);
    event TokensClaimed(address indexed buyer, uint256 indexed amount);
    event TokensReleased(address indexed buyer, uint256 indexed amount);
    event LiquidityMigrated(uint256 amountToken, uint256 amountETH, uint256 liquidity);
    event PresaleInitialized(uint256 startDate, uint256 endDate);
    event SaleClosed();
    event WithdrawAllWID(address indexed owner);

    uint256 public pricePresale;

    WIDToken public widToken;
    uint256 public tokensForPresale;
    uint256 public tokensForAdmin;
    uint256 public tokensForTeam;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public unlockDate;
    uint256 public minCommitment;
    uint256 public maxCommitment;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public tokensSold;
    bool    public isInitialized = false;
    bool    public isClosed;
    bool    public canClaimTokens = false;

    mapping(address => uint256) public tokensPurchased;
    mapping(address => uint256) public teamBalances;
    mapping(address => bool) public teamMembers;
    
    constructor(WIDToken _widToken) public {
      widToken = _widToken;
    }
    
    modifier isActive() {
      require(block.timestamp > startDate, "WIDPresale: You are too early!");
      require(block.timestamp < endDate, "WIDPresale: You are too late!");
      _;
    }

    modifier afterClosedSale() {
      require(isClosed, "WIDPresale: Sale is not closed.");
      _;
    }
    
    function initializePresale(
      uint256 _tokensForPresale,
      uint256 _startDate,
      uint256 _endDate,
      uint256 _minCommitment,
      uint256 _maxCommitment,
      uint256 _softCap,
      uint256 _hardCap,
      uint256 _pricePresale
    ) external onlyOwner {
      require(_softCap < _hardCap, "WIDPresale: softCap cannot be higher then hardCap");
      require(_startDate < _endDate, "WIDPresale: startDate cannot be after endDate");
      require(_endDate > block.timestamp, "WIDPresale: endDate must be in the future");
      require(_minCommitment < _maxCommitment, "WIDPresale: minCommitment cannot be higher then maxCommitment");
    
      tokensForPresale =_tokensForPresale;
      startDate     = _startDate;
      endDate       = _endDate;
      minCommitment = _minCommitment;
      maxCommitment = _maxCommitment;
      softCap       = _softCap;
      hardCap       = _hardCap;
      pricePresale  = _pricePresale;

      isInitialized = true;

      emit PresaleInitialized(startDate, endDate);
    }
    
    function addTeamBalance(address _team, uint256 _balance) public onlyOwner {
      require(isInitialized, "WIDPresale: Presale has not already been initialized.");
      bool _status = false;
      if (!teamMembers[_team]) {
        teamBalances[_team] = _balance;
        teamMembers[_team] = true;
        tokensForTeam = tokensForTeam.add(_balance);
        _status = true;
      }
      emit AddTeamBalance(_team, _balance, _status);
    }

    function setCanClaim(bool canClaim) external onlyOwner afterClosedSale {
      canClaimTokens = canClaim;
    }

    function purchaseTokens() external payable isActive {
      require(!isClosed, "WIDPresale: sale closed");
      require(msg.value >= minCommitment, "WIDPresale: amount to low");
      require(tokensPurchased[_msgSender()].add(msg.value) <= maxCommitment, "WIDPresale: maxCommitment reached");
      require(teamMembers[_msgSender()] == false, "WIDPreslae: team member doesn't allow presale.");
      require(tokensSold.add(msg.value) <= hardCap, "WIDPresale: hardcap reached");

      tokensSold = tokensSold.add(msg.value);
      tokensPurchased[_msgSender()] = tokensPurchased[_msgSender()].add(msg.value);
      emit TokensPurchased(_msgSender(), msg.value);
    }
    
    function purchaseTokensManual(address investor, uint256 amount) external onlyOwner {
      require(!isClosed, "WIDPresale: sale closed");
      require(amount >= minCommitment, "WIDPresale: amount to low");
      require(tokensPurchased[investor].add(amount) <= maxCommitment, "WIDPresale: maxCommitment reached");
      require(teamMembers[investor] == false, "WIDPreslae: team member doesn't allow presale.");
      require(tokensSold.add(amount) <= hardCap, "WIDPresale: hardcap reached");

      tokensSold = tokensSold.add(amount);
      tokensPurchased[investor] = tokensPurchased[investor].add(amount);
      emit TokensPurchased(investor, amount);
    }

    function closeSale() external onlyOwner {
      require(!isClosed, "WIDPresale: already closed");
      require(block.timestamp > endDate || tokensSold == hardCap, "WIDPresale: endDate not passed or hardcap not reached");
      require(tokensSold >= softCap, "WIDPresale: softCap not reached");
      isClosed = true;
    
      uint256 preSoldWids = pricePresale.mul(tokensSold).div(10**18);
      widToken.mintAll(address(this));
      tokensForAdmin = widToken.balanceOf(address(this)).sub(preSoldWids);
      tokensForAdmin = tokensForAdmin.sub(tokensForTeam);
      
      emit SaleClosed();
    }

    function claimTokens() external afterClosedSale {
      require(canClaimTokens, "WIDPresale: Claiming is not allowed yet!");
      require(tokensPurchased[_msgSender()] > 0, "WIDPresale: no tokens to claim");
      uint256 purchasedTokens = tokensPurchased[_msgSender()].mul(pricePresale).div(10**18);
      tokensPurchased[_msgSender()] = 0;
      widToken.transfer(_msgSender(), purchasedTokens);
      emit TokensClaimed(_msgSender(), purchasedTokens);
    }

    function releaseTokens() external {
      require(!isClosed, "WIDPresale: cannot release tokens for closed sale");
      require(softCap > 0, "WIDPresale: no softCap");
      require(block.timestamp > endDate, "WIDPresale: endDate not passed");
      require(tokensPurchased[_msgSender()] > 0, "WIDPresale: no tokens to release");
      require(tokensSold < softCap, "WIDPresale: softCap reached");

      uint256 purchasedTokens = tokensPurchased[_msgSender()];
      tokensPurchased[_msgSender()] = 0;
      _msgSender().transfer(purchasedTokens);
      emit TokensReleased(_msgSender(), purchasedTokens);
    }
    
    function withdrawAllWid() public onlyOwner afterClosedSale {
      require(canClaimTokens, "WIDPresale: Claiming is not allowed yet!");
      require(tokensForAdmin > 0, "WIDPresale: no tokens to claim");
      
      widToken.transfer(_msgSender(), tokensForAdmin);
      tokensForAdmin = 0;
      emit WithdrawAllWID(_msgSender());
    }
    
    function clearWID() public onlyOwner afterClosedSale {
      widToken.transfer(_msgSender(), widToken.balanceOf(address(this)));
    }
    
    function claimWidTeamMember() external afterClosedSale {
      require(canClaimTokens, "WIDPresale: Claiming is not allowed yet!");
      require(teamMembers[_msgSender()], "WIDPresale: You are not WIDpresale Team member!");
      require(teamBalances[_msgSender()]>0, "WIDPresale: No tokens to claim!");
      
      widToken.transfer(_msgSender(), teamBalances[_msgSender()]);
      teamBalances[_msgSender()] = 0;
    }

    function tokensRemaining() external view returns (uint256) {
      return (hardCap.sub(tokensSold).mul(pricePresale).div(10**18));
    }

    function getTimeLeftEndDate() external view returns (uint256) {
      if (block.timestamp > endDate) {
        return 0;
      } else {
        return endDate.sub(block.timestamp);
      }
    }

    function getReservedTokens() external view returns (uint256) {
      return tokensPurchased[_msgSender()] > 0 ? tokensPurchased[_msgSender()].mul(pricePresale).div(10**18) : 0;
    }

    function withdrawETH() external onlyOwner afterClosedSale {
      _msgSender().transfer(address(this).balance);
    }

    receive() external payable {}
}