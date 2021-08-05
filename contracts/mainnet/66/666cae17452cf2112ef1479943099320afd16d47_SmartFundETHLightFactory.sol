/**
 *Submitted for verification at Etherscan.io on 2020-09-24
*/

pragma solidity ^0.6.12;

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
interface PermittedAddressesInterface {
  function permittedAddresses(address _address) external view returns(bool);
  function addressesTypes(address _address) external view returns(string memory);
  function isMatchTypes(address _address, uint256 addressType) external view returns(bool);
}


interface ExchangePortalInterface {
  function trade(
    IERC20 _source,
    uint256 _sourceAmount,
    IERC20 _destination,
    uint256 _type,
    bytes32[] calldata _proof,
    uint256[] calldata _positions,
    bytes calldata _additionalData,
    bool _verifyDestanation
  )
    external
    payable
    returns (uint256);


  function getValue(address _from, address _to, uint256 _amount) external view returns (uint256);

  function getTotalValue(
    address[] calldata _fromAddresses,
    uint256[] calldata _amounts,
    address _to
    )
    external
    view
   returns (uint256);
}






/*
  The SmartFund contract is what holds all the tokens and ether, and contains all the logic
  for calculating its value (and ergo profit), allows users to deposit/withdraw their funds,
  and calculates the fund managers cut of the funds profit among other things.
  The SmartFund gets the value of its token holdings (in Ether) and trades through the ExchangePortal
  contract. This means that as new exchange capabalities are added to new exchange portals, the
  SmartFund will be able to upgrade to a new exchange portal, and trade a wider variety of assets
  with a wider variety of exchanges. The SmartFund is also connected to a permittedAddresses contract,
  which determines which exchange, pool, defi portals the SmartFund is allowed to connect to, restricting
  the fund owners ability to connect to a potentially malicious contract.
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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

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
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


abstract contract SmartFundLightCore is Ownable, IERC20 {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // Fund type
  bool public isLightFund = true;

  // Total amount of ether or stable deposited by all users
  uint256 public totalWeiDeposited = 0;

  // Total amount of ether or stable withdrawn by all users
  uint256 public totalWeiWithdrawn = 0;

  // The Interface of the Exchange Portal
  ExchangePortalInterface public exchangePortal;

  // The Smart Contract which stores the addresses of all the authorized Exchange Portals
  PermittedAddressesInterface public permittedAddresses;

  // portals recognizes ETH by this address
  IERC20 constant internal ETH_TOKEN_ADDRESS = IERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

  // For ERC20 compliance
  string public name;

  // The maximum amount of tokens that can be traded via the smart fund
  uint256 public MAX_TOKENS = 20;

  // Percentages are rounded to 3 decimal places
  uint256 public TOTAL_PERCENTAGE = 10000;

  // Address of the platform that takes a cut from the fund manager success cut
  address public platformAddress;

  // The percentage of earnings paid to the fund manager. 10000 = 100%
  // e.g. 10% is 1000
  uint256 public successFee;

  // The percentage of fund manager earnings paid to the platform. 10000 = 100%
  // e.g. 10% is 1000
  uint256 public platformFee;

  // An array of all the erc20 token addresses the smart fund holds
  address[] public tokenAddresses;

  // Boolean value that determines whether the fund accepts deposits from anyone or
  // only specific addresses approved by the manager
  bool public onlyWhitelist = false;

  // Mapping of addresses that are approved to deposit if the manager only want's specific
  // addresses to be able to invest in their fund
  mapping (address => bool) public whitelist;

  uint public version = 7;

  // the total number of shares in the fund
  uint256 public totalShares = 0;

  // Denomination of initial shares
  uint256 constant internal INITIAL_SHARES = 10 ** 18;

  // The earnings the fund manager has already cashed out
  uint256 public fundManagerCashedOut = 0;

  // for ETH and ERC20 fund this asset different
  address public coreFundAsset;

  // If true the contract will require each new asset to buy to be on a special Merkle tree list
  bool public isRequireTradeVerification;

  // how many shares belong to each address
  mapping (address => uint256) public addressToShares;

  // so that we can easily check that we don't add duplicates to our array
  mapping (address => bool) public tokensTraded;

  // this is really only being used to more easily show profits, but may not be necessary
  // if we do a lot of this offchain using events to track everything
  // total `depositToken` deposited - total `depositToken` withdrawn
  mapping (address => int256) public addressesNetDeposit;

  event Deposit(address indexed user, uint256 amount, uint256 sharesReceived, uint256 totalShares);
  event Withdraw(address indexed user, uint256 sharesRemoved, uint256 totalShares);
  event Trade(address src, uint256 srcAmount, address dest, uint256 destReceived);
  event SmartFundCreated(address indexed owner);


  constructor(
    address _owner,
    string memory _name,
    uint256 _successFee,
    address _platformAddress,
    address _exchangePortalAddress,
    address _permittedAddresses,
    address _coreFundAsset,
    bool    _isRequireTradeVerification
  )public{
    // never allow a 100% fee
    require(_successFee < TOTAL_PERCENTAGE);

    name = _name;
    successFee = _successFee;
    platformFee = _successFee; // platform fee the same as manager fee

    // Init manager
    if(_owner == address(0)){
      transferOwnership(msg.sender);
    }
    else{
      transferOwnership(_owner);
    }

    // Init platform address
    if(_platformAddress == address(0)){
      platformAddress = msg.sender;
    }
    else{
      platformAddress = _platformAddress;
    }

    // Initial Token is Ether
    tokenAddresses.push(address(ETH_TOKEN_ADDRESS));

    // Initial interfaces
    exchangePortal = ExchangePortalInterface(_exchangePortalAddress);
    permittedAddresses = PermittedAddressesInterface(_permittedAddresses);

    // Initial core assets
    coreFundAsset = _coreFundAsset;

    // Initial check if fund require trade verification or not
    isRequireTradeVerification = _isRequireTradeVerification;

    emit SmartFundCreated(owner());
  }

  // virtual methods
  // USD and ETH based funds have different implements of this methods
  function calculateFundValue() public virtual view returns (uint256);
  function getTokenValue(IERC20 _token) public virtual view returns (uint256);


  /**
  * @dev Sends (_mul/_div) of every token (and ether) the funds holds to _withdrawAddress
  *
  * @param _mul                The numerator
  * @param _div                The denominator
  * @param _withdrawAddress    Address to send the tokens/ether to
  *
  * NOTE: _withdrawAddress changed from address to address[] arrays because balance calculation should be performed
  * once for all usesr who wants to withdraw from the current balance.
  *
  */
  function _withdraw(
    uint256[] memory _mul,
    uint256[] memory _div,
    address[] memory _withdrawAddress
    )
    internal
    returns (uint256)
  {
    for (uint8 i = 1; i < tokenAddresses.length; i++) {
      // Transfer that _mul/_div of each token we hold to the user
      IERC20 token = IERC20(tokenAddresses[i]);
      uint256 fundAmount = token.balanceOf(address(this));

      // Transfer ERC20 to _withdrawAddress
      for(uint8 j = 0; j < _withdrawAddress.length; j++){
        // calculate withdraw ERC20 share
        uint256 payoutAmount = fundAmount.mul(_mul[j]).div(_div[j]);
        if(payoutAmount > 0)
          token.transfer(_withdrawAddress[j], payoutAmount);
      }
    }
    // Transfer ETH to _withdrawAddress
    uint256 etherBalance = address(this).balance;
    for(uint8 k = 0; k < _withdrawAddress.length; k++){
      // calculate withdraw ETH share
      uint256 etherPayoutAmount = (etherBalance).mul(_mul[k]).div(_div[k]);
      if(etherPayoutAmount > 0)
        payable(_withdrawAddress[k]).transfer(etherPayoutAmount);
    }
  }

  /**
  * @dev Withdraws users fund holdings, sends (userShares/totalShares) of every held token
  * to msg.sender, defaults to 100% of users shares.
  *
  * @param _percentageWithdraw    The percentage of the users shares to withdraw.
  */
  function withdraw(uint256 _percentageWithdraw) external {
    require(totalShares != 0, "EMPTY_SHARES");
    require(_percentageWithdraw <= TOTAL_PERCENTAGE, "INCORRECT_PERCENT");

    uint256 percentageWithdraw = (_percentageWithdraw == 0) ? TOTAL_PERCENTAGE : _percentageWithdraw;

    uint256 addressShares = addressToShares[msg.sender];

    uint256 numberOfWithdrawShares = addressShares.mul(percentageWithdraw).div(TOTAL_PERCENTAGE);

    uint256 fundManagerCut;
    uint256 fundValue;

    // Withdraw the users share minus the fund manager's success fee
    (fundManagerCut, fundValue, ) = calculateFundManagerCut();

    uint256 withdrawShares = numberOfWithdrawShares.mul(fundValue.sub(fundManagerCut)).div(fundValue);

    // prepare call data for _withdarw
    address[] memory spenders = new address[](1);
    spenders[0] = msg.sender;

    uint256[] memory value = new uint256[](1);
    value[0] = totalShares;

    uint256[] memory cut = new uint256[](1);
    cut[0] = withdrawShares;

    // do withdraw
    _withdraw(cut, value, spenders);

    // Store the value we are withdrawing in ether
    uint256 valueWithdrawn = fundValue.mul(withdrawShares).div(totalShares);

    totalWeiWithdrawn = totalWeiWithdrawn.add(valueWithdrawn);
    addressesNetDeposit[msg.sender] -= int256(valueWithdrawn);

    // Subtract from total shares the number of withdrawn shares
    totalShares = totalShares.sub(numberOfWithdrawShares);
    addressToShares[msg.sender] = addressToShares[msg.sender].sub(numberOfWithdrawShares);

    emit Withdraw(msg.sender, numberOfWithdrawShares, totalShares);
  }

  /**
  * @dev Facilitates a trade of the funds holdings via the exchange portal
  *
  * @param _source            ERC20 token to convert from
  * @param _sourceAmount      Amount to convert (in _source token)
  * @param _destination       ERC20 token to convert to
  * @param _type              The type of exchange to trade with
  * @param _proof             Merkle tree proof (if not used just set [])
  * @param _positions         Merkle tree positions (if not used just set [])
  * @param _additionalData    For additional data (if not used just set "0x0")
  * @param _minReturn         Min expected amount of destination
  */
  function trade(
    IERC20 _source,
    uint256 _sourceAmount,
    IERC20 _destination,
    uint256 _type,
    bytes32[] calldata _proof,
    uint256[] calldata _positions,
    bytes calldata _additionalData,
    uint256 _minReturn
  ) external onlyOwner {
    require(_minReturn > 0, "MIN_RETURN_0");

    uint256 receivedAmount;

    if (_source == ETH_TOKEN_ADDRESS) {
      // Make sure fund contains enough ether
      require(address(this).balance >= _sourceAmount, "NOT_ENOUGH_ETH");
      // Call trade on ExchangePortal along with ether
      receivedAmount = exchangePortal.trade.value(_sourceAmount)(
        _source,
        _sourceAmount,
        _destination,
        _type,
        _proof,
        _positions,
        _additionalData,
        isRequireTradeVerification
      );
    } else {
      _source.approve(address(exchangePortal), _sourceAmount);
      receivedAmount = exchangePortal.trade(
        _source,
        _sourceAmount,
        _destination,
        _type,
        _proof,
        _positions,
        _additionalData,
        isRequireTradeVerification
      );
    }

    // make sure fund recive destanation
    require(receivedAmount >= _minReturn, "RECEIVED_LESS_THAN_MIN_RETURN");

    // add token to trader list
    _addToken(address(_destination));

    // emit event
    emit Trade(
      address(_source),
      _sourceAmount,
      address(_destination),
      receivedAmount);
  }


  // return all tokens addresses from fund
  function getAllTokenAddresses() external view returns (address[] memory) {
    return tokenAddresses;
  }

  /**
  * @dev Adds a token to tokensTraded if it's not already there
  * @param _token    The token to add
  */
  function _addToken(address _token) internal {
    // don't add token to if we already have it in our list
    if (tokensTraded[_token] || (_token == address(ETH_TOKEN_ADDRESS)))
      return;

    tokensTraded[_token] = true;
    tokenAddresses.push(_token);
    uint256 tokenCount = tokenAddresses.length;

    // we can't hold more than MAX_TOKENS tokens
    require(tokenCount <= MAX_TOKENS, "MAX_TOKENS");
  }

  /**
  * @dev Removes a token from tokensTraded
  *
  * @param _token         The address of the token to be removed
  * @param _tokenIndex    The index of the token to be removed
  *
  */
  function removeToken(address _token, uint256 _tokenIndex) public onlyOwner {
    require(_token != address(ETH_TOKEN_ADDRESS));
    require(tokensTraded[_token]);
    require(IERC20(_token).balanceOf(address(this)) == 0);
    require(tokenAddresses[_tokenIndex] == _token);

    tokensTraded[_token] = false;

    // remove token from array
    uint256 arrayLength = tokenAddresses.length - 1;
    tokenAddresses[_tokenIndex] = tokenAddresses[arrayLength];
    delete tokenAddresses[arrayLength];
    tokenAddresses.pop();
  }

  /**
  * @dev Calculates the funds profit
  *
  * @return The funds profit in deposit token (Ether)
  */
  function calculateFundProfit() public view returns (int256) {
    uint256 fundValue = calculateFundValue();

    return int256(fundValue) + int256(totalWeiWithdrawn) - int256(totalWeiDeposited);
  }

  /**
  * @dev Calculates the amount of shares received according to ether deposited
  *
  * @param _amount    Amount of ether to convert to shares
  *
  * @return Amount of shares to be received
  */
  function calculateDepositToShares(uint256 _amount) public view returns (uint256) {
    uint256 fundManagerCut;
    uint256 fundValue;

    // If there are no shares in the contract, whoever deposits owns 100% of the fund
    // we will set this to 10^18 shares, but this could be any amount
    if (totalShares == 0)
      return INITIAL_SHARES;

    (fundManagerCut, fundValue, ) = calculateFundManagerCut();

    uint256 fundValueBeforeDeposit = fundValue.sub(_amount).sub(fundManagerCut);

    if (fundValueBeforeDeposit == 0)
      return 0;

    return _amount.mul(totalShares).div(fundValueBeforeDeposit);

  }


  /**
  * @dev Calculates the fund managers cut, depending on the funds profit and success fee
  *
  * @return fundManagerRemainingCut    The fund managers cut that they have left to withdraw
  * @return fundValue                  The funds current value
  * @return fundManagerTotalCut        The fund managers total cut of the profits until now
  */
  function calculateFundManagerCut() public view returns (
    uint256 fundManagerRemainingCut, // fm's cut of the profits that has yet to be cashed out (in `depositToken`)
    uint256 fundValue, // total value of fund (in `depositToken`)
    uint256 fundManagerTotalCut // fm's total cut of the profits (in `depositToken`)
  ) {
    fundValue = calculateFundValue();
    // The total amount of ether currently deposited into the fund, takes into account the total ether
    // withdrawn by investors as well as ether withdrawn by the fund manager
    // NOTE: value can be negative if the manager performs well and investors withdraw more
    // ether than they deposited
    int256 curtotalWeiDeposited = int256(totalWeiDeposited) - int256(totalWeiWithdrawn.add(fundManagerCashedOut));

    // If profit < 0, the fund managers totalCut and remainingCut are 0
    if (int256(fundValue) <= curtotalWeiDeposited) {
      fundManagerTotalCut = 0;
      fundManagerRemainingCut = 0;
    } else {
      // calculate profit. profit = current fund value - total deposited + total withdrawn + total withdrawn by fm
      uint256 profit = uint256(int256(fundValue) - curtotalWeiDeposited);
      // remove the money already taken by the fund manager and take percentage
      fundManagerTotalCut = profit.mul(successFee).div(TOTAL_PERCENTAGE);
      fundManagerRemainingCut = fundManagerTotalCut.sub(fundManagerCashedOut);
    }
  }

  /**
  * @dev Allows the fund manager to withdraw their cut of the funds profit
  */
  function fundManagerWithdraw() public onlyOwner {
    uint256 fundManagerCut;
    uint256 fundValue;

    (fundManagerCut, fundValue, ) = calculateFundManagerCut();

    uint256 platformCut = (platformFee == 0) ? 0 : fundManagerCut.mul(platformFee).div(TOTAL_PERCENTAGE);

    // prepare call data for _withdarw
    address[] memory spenders = new address[](2);
    spenders[0] = platformAddress;
    spenders[1] = owner();

    uint256[] memory value = new uint256[](2);
    value[0] = fundValue;
    value[1] = fundValue;

    uint256[] memory cut = new uint256[](2);
    cut[0] = platformCut;
    cut[1] = fundManagerCut - platformCut;

    // do withdraw
    _withdraw(cut, value, spenders);

    // add report
    fundManagerCashedOut = fundManagerCashedOut.add(fundManagerCut);
  }

  // calculate the current value of an address's shares in the fund
  function calculateAddressValue(address _address) public view returns (uint256) {
    if (totalShares == 0)
      return 0;

    return calculateFundValue().mul(addressToShares[_address]).div(totalShares);
  }

  // calculate the net profit/loss for an address in this fund
  function calculateAddressProfit(address _address) public view returns (int256) {
    uint256 currentAddressValue = calculateAddressValue(_address);

    return int256(currentAddressValue) - addressesNetDeposit[_address];
  }

  // This method was added to easily record the funds token balances, may (should?) be removed in the future
  function getFundTokenHolding(IERC20 _token) external view returns (uint256) {
    if (_token == ETH_TOKEN_ADDRESS)
      return address(this).balance;
    return _token.balanceOf(address(this));
  }

  /**
  * @dev Allows the manager to set whether or not only whitelisted addresses can deposit into
  * their fund
  *
  * @param _onlyWhitelist    boolean representing whether only whitelisted addresses can deposit
  */
  function setWhitelistOnly(bool _onlyWhitelist) external onlyOwner {
    onlyWhitelist = _onlyWhitelist;
  }

  /**
  * @dev Allows the fund manager to whitelist specific addresses to control
  * whos allowed to deposit into the fund
  *
  * @param _user       The user address to whitelist
  * @param _allowed    The status of _user, true means allowed to deposit, false means not allowed
  */
  function setWhitelistAddress(address _user, bool _allowed) external onlyOwner {
    whitelist[_user] = _allowed;
  }

  /**
  * @dev Allows the fund manager to connect to a new permitted exchange portal
  *
  * @param _newExchangePortalAddress    The address of the new permitted exchange portal to use
  */
  function setNewExchangePortal(address _newExchangePortalAddress) public onlyOwner {
    // Require correct permitted address type
    require(permittedAddresses.isMatchTypes(_newExchangePortalAddress, 1), "WRONG_ADDRESS");
    // Set new
    exchangePortal = ExchangePortalInterface(_newExchangePortalAddress);
  }


  /**
  * @dev This method is present in the alpha testing phase in case for some reason there are funds
  * left in the SmartFund after all shares were withdrawn
  *
  * @param _token    The address of the token to withdraw
  */
  function emergencyWithdraw(address _token) external onlyOwner {
    require(totalShares == 0);
    if (_token == address(ETH_TOKEN_ADDRESS)) {
      msg.sender.transfer(address(this).balance);
    } else {
      IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }
  }

  /**
  * @dev Approve 0 for a certain address
  *
  * NOTE: Some ERC20 has no standard approve logic, and not allow do new approve
  * if alredy approved.
  *
  * @param _token                   address of ERC20
  * @param _spender                 address of spender
  */
  function resetApprove(address _token, address _spender) external onlyOwner {
    IERC20(_token).approve(_spender, 0);
  }

  // Fallback payable function in order to be able to receive ether from other contracts
  fallback() external payable {}

  /**
    **************************** ERC20 Compliance ****************************
  **/

  // Note that addressesNetDeposit does not get updated when transferring shares, since
  // this is used for updating off-chain data it doesn't affect the smart contract logic,
  // but is an issue that currently exists

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

  uint8 public decimals = 18;

  string public symbol = "FND";

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
  * @dev Total number of shares in existence
  */
  function totalSupply() external override view returns (uint256) {
    return totalShares;
  }

  /**
  * @dev Gets the balance of the specified address.
  *
  * @param _who    The address to query the the balance of.
  *
  * @return A uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _who) external override view returns (uint256) {
    return addressToShares[_who];
  }

  /**
  * @dev Transfer shares for a specified address
  *
  * @param _to       The address to transfer to.
  * @param _value    The amount to be transferred.
  *
  * @return true upon success
  */
  function transfer(address _to, uint256 _value) external override returns (bool) {
    require(_to != address(0));
    require(_value <= addressToShares[msg.sender]);

    addressToShares[msg.sender] = addressToShares[msg.sender].sub(_value);
    addressToShares[_to] = addressToShares[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer shares from one address to another
   *
   * @param _from     The address which you want to send tokens from
   * @param _to       The address which you want to transfer to
   * @param _value    The amount of shares to be transferred
   *
   * @return true upon success
   */
  function transferFrom(address _from, address _to, uint256 _value) external override returns (bool) {
    require(_to != address(0));
    require(_value <= addressToShares[_from]);
    require(_value <= allowed[_from][msg.sender]);

    addressToShares[_from] = addressToShares[_from].sub(_value);
    addressToShares[_to] = addressToShares[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of shares on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * @param _spender    The address which will spend the funds.
   * @param _value      The amount of shares to be spent.
   *
   * @return true upon success
   */
  function approve(address _spender, uint256 _value) external override returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of shares that an owner allowed to a spender.
   *
   * @param _owner      The address which owns the funds.
   * @param _spender    The address which will spend the funds.
   *
   * @return A uint256 specifying the amount of shares still available for the spender.
   */
  function allowance(address _owner, address _spender) external override view returns (uint256) {
    return allowed[_owner][_spender];
  }
}


/*
  Note: this smart fund inherits SmartFundLightCore and make core operations like deposit,
  calculate fund value etc in ETH
*/
contract SmartFundETHLight is SmartFundLightCore {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /**
  * @dev constructor
  *
  * @param _owner                        Address of the fund manager
  * @param _name                         Name of the fund, required for DetailedERC20 compliance
  * @param _successFee                   Percentage of profit that the fund manager receives
  * @param _platformAddress              Address of platform to send fees to
  * @param _exchangePortalAddress        Address of initial exchange portal
  * @param _permittedAddresses           Address of permittedAddresses contract
  * @param _isRequireTradeVerification   If true fund will require verification from Merkle White list for each new asset
  */
  constructor(
    address _owner,
    string memory _name,
    uint256 _successFee,
    address _platformAddress,
    address _exchangePortalAddress,
    address _permittedAddresses,
    bool    _isRequireTradeVerification
  )
  SmartFundLightCore(
    _owner,
    _name,
    _successFee,
    _platformAddress,
    _exchangePortalAddress,
    _permittedAddresses,
    address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee),
    _isRequireTradeVerification
  )
  public{}

  /**
  * @dev Deposits ether into the fund and allocates a number of shares to the sender
  * depending on the current number of shares, the funds value, and amount deposited
  *
  * @return The amount of shares allocated to the depositor
  */
  function deposit() external payable returns (uint256) {
    // Check if the sender is allowed to deposit into the fund
    if (onlyWhitelist)
      require(whitelist[msg.sender]);

    // Require that the amount sent is not 0
    require(msg.value != 0, "ZERO_DEPOSIT");

    totalWeiDeposited += msg.value;

    // Calculate number of shares
    uint256 shares = calculateDepositToShares(msg.value);

    // If user would receive 0 shares, don't continue with deposit
    require(shares != 0, "ZERO_SHARES");

    // Add shares to total
    totalShares = totalShares.add(shares);

    // Add shares to address
    addressToShares[msg.sender] = addressToShares[msg.sender].add(shares);

    addressesNetDeposit[msg.sender] += int256(msg.value);

    emit Deposit(msg.sender, msg.value, shares, totalShares);

    return shares;
  }

  /**
  * @dev Calculates the funds value in deposit token (Ether)
  *
  * @return The current total fund value
  */
  function calculateFundValue() public override view returns (uint256) {
    uint256 ethBalance = address(this).balance;

    // If the fund only contains ether, return the funds ether balance
    if (tokenAddresses.length == 1)
      return ethBalance;

    // Otherwise, we get the value of all the other tokens in ether via exchangePortal

    // Calculate value for ERC20
    address[] memory fromAddresses = new address[](tokenAddresses.length - 1); // Sub ETH
    uint256[] memory amounts = new uint256[](tokenAddresses.length - 1);
    uint index = 0;

    for (uint256 i = 1; i < tokenAddresses.length; i++) {
      fromAddresses[index] = tokenAddresses[i];
      amounts[index] = IERC20(tokenAddresses[i]).balanceOf(address(this));
      index++;
    }
    // Ask the Exchange Portal for the value of all the funds tokens in eth
    uint256 tokensValue = exchangePortal.getTotalValue(
      fromAddresses,
      amounts,
      address(ETH_TOKEN_ADDRESS)
    );

    // Sum ETH + ERC20
    return ethBalance + tokensValue;
  }

  /**
  * @dev get balance of input asset address in ETH ratio
  *
  * @param _token     token address
  *
  * @return balance in ETH
  */
  function getTokenValue(IERC20 _token) public override view returns (uint256) {
    // return ETH
    if (_token == ETH_TOKEN_ADDRESS){
      return address(this).balance;
    }
    // return ERC20 in ETH
    else{
      uint256 tokenBalance = _token.balanceOf(address(this));
      return exchangePortal.getValue(
        address(_token),
        address(ETH_TOKEN_ADDRESS),
        tokenBalance
      );
    }
  }
}


contract SmartFundETHLightFactory {
  address public platfromAddress;

  constructor(address _platfromAddress) public {
    platfromAddress = _platfromAddress;
  }

  function createSmartFundLight(
    address _owner,
    string  memory _name,
    uint256 _successFee,
    address _exchangePortalAddress,
    address _permittedAddresses,
    bool    _isRequireTradeVerification
  )
  public
  returns(address)
  {
    SmartFundETHLight smartFundETHLight = new SmartFundETHLight(
      _owner,
      _name,
      _successFee,
      platfromAddress,
      _exchangePortalAddress,
      _permittedAddresses,
      _isRequireTradeVerification
    );

    return address(smartFundETHLight);
  }
}