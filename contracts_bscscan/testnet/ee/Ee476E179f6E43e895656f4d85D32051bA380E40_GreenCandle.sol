// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import './interfaces/IERC20.sol';
import './libs/SafeMath.sol';
import './libs/SafeMathInt.sol';
import './libs/Address.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/ILP.sol';
import './interfaces/IPinkAntiBot.sol';
import './Context.sol';
import './Ownable.sol';
import './ERC20Detailed.sol';

contract GreenCandle is ERC20Detailed, Ownable {
  using SafeMath for uint256;
  using SafeMathInt for int256;

  // Used for authentication
  address public master;

  // LP atomic sync
  address public lp;
  ILP public lpContract;

  modifier onlyMaster() {
    require(msg.sender == master);
    _;
  }

  bool public initialDistributionFinished;
  mapping(address => bool) allowTransfer;

  uint256 private constant DECIMALS = 9;
  uint256 private constant MAX_UINT256 = ~uint256(0);

  uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 10**15 * 10**DECIMALS;

  uint256 public transactionTax = 1100;
  uint256 public buybackLimit = 10**18;
  uint256 public buybackDivisor = 100;
  mapping(address => uint256) public lastBuy;

  IUniswapV2Router02 public uniswapV2Router;
  IUniswapV2Pair public uniswapV2Pair;
  address public uniswapV2PairAddress;
  address public deadAddress = 0x000000000000000000000000000000000000dEaD;
  address payable public marketingAddress;

  bool public buyBackEnabled = false;

  mapping(address => bool) private _isExcluded;

  bool private privateSaleDropCompleted = false;

  // TOTAL_GRC is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _grcPerFragment is an integer.
  // Use the highest value that fits in a uint256 for max granularity.
  uint256 private constant TOTAL_GRC =
    MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

  // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GRC + 1) - 1) / 2
  uint256 private constant MAX_SUPPLY = ~uint128(0); // (2^128) - 1

  uint256 private _totalSupply;
  uint256 private _grcPerFragment;
  mapping(address => uint256) private _grcBalances;
  mapping(address => mapping(address => uint256)) private _allowedFragments;

  IPinkAntiBot public pinkAntiBot;

  event LogRebase(uint256 indexed epoch, uint256 totalSupply);
  event SwapEnabled(bool enabled);

  modifier initialDistributionLock() {
    require(
      initialDistributionFinished || this.isOwner() || allowTransfer[msg.sender]
    );
    _;
  }

  modifier validRecipient(address to) {
    require(to != address(0x0));
    require(to != address(this));
    _;
  }

  constructor(
    address router,
    address payable _marketingAddress,
    address _masterAddress
  ) ERC20Detailed('Green Candle', 'GRC', uint8(DECIMALS)) {
    marketingAddress = _marketingAddress;
    master = _masterAddress;

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);

    uniswapV2PairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
      .createPair(address(this), _uniswapV2Router.WETH());

    uniswapV2Router = _uniswapV2Router;

    setLP(uniswapV2PairAddress);

    IUniswapV2Pair _uniswapV2Pair = IUniswapV2Pair(uniswapV2PairAddress);

    uniswapV2Pair = _uniswapV2Pair;

    _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
    _grcBalances[msg.sender] = TOTAL_GRC;
    _grcPerFragment = TOTAL_GRC.div(_totalSupply);

    initialDistributionFinished = false;

    //exclude owner and this contract from fee
    _isExcluded[owner()] = true;
    _isExcluded[address(this)] = true;

    emit Transfer(address(0x0), msg.sender, _totalSupply);
  }

  /**
   * @dev Notifies Fragments contract about a new rebase cycle.
   * @param supplyDelta The number of new fragment tokens to add into circulation via expansion.
   * @return The total number of fragments after the supply adjustment.
   */
  function rebase(uint256 epoch, int256 supplyDelta)
    external
    onlyMaster
    returns (uint256)
  {
    if (supplyDelta == 0) {
      emit LogRebase(epoch, _totalSupply);
      return _totalSupply;
    }

    if (supplyDelta < 0) {
      _totalSupply = _totalSupply.sub(uint256(-supplyDelta));
    } else {
      _totalSupply = _totalSupply.add(uint256(supplyDelta));
    }

    if (_totalSupply > MAX_SUPPLY) {
      _totalSupply = MAX_SUPPLY;
    }

    _grcPerFragment = TOTAL_GRC.div(_totalSupply);
    lpContract.sync();

    emit LogRebase(epoch, _totalSupply);
    return _totalSupply;
  }

  /**
   * @notice Sets a new master
   */
  function setMaster(address _master) external onlyOwner returns (bool) {
    master = _master;
    return true;
  }

  /**
   * @notice Sets contract LP address
   */
  function setLP(address _lp) public onlyOwner returns (bool) {
    lp = _lp;
    lpContract = ILP(_lp);
    return true;
  }

  /**
   * @return The total number of fragments.
   */
  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @param who The address to query.
   * @return The balance of the specified address.
   */
  function balanceOf(address who) public view override returns (uint256) {
    return _grcBalances[who].div(_grcPerFragment);
  }

  function transfer(address recipient, uint256 amount)
    external
    override
    validRecipient(recipient)
    initialDistributionLock
    returns (bool)
  {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  event Sender(address sender);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external override validRecipient(recipient) returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      msg.sender,
      _allowedFragments[sender][msg.sender].sub(amount)
    );
    return true;
  }

  /**
   * @dev Transfer tokens to a specified address.
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   * @return True on success, false otherwise.
   */
  function _transfer(
    address from,
    address to,
    uint256 value
  ) private validRecipient(to) initialDistributionLock returns (bool) {
    require(from != address(0), 'ERC20: transfer from the zero address');
    require(to != address(0), 'ERC20: transfer to the zero address');
    require(value > 0);

    pinkAntiBot.onPreTransferCheck(from, to, value);

    uint256 balance = address(this).balance;
    if (buyBackEnabled && balance > buybackLimit) {
      buyBackTokens(buybackLimit.div(buybackDivisor));
    }

    _tokenTransfer(from, to, value);

    return true;
  }

  function _tokenTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    if (_isExcluded[sender] || _isExcluded[recipient]) {
      _transferExcluded(sender, recipient, amount);
    } else {
      _transferStandard(sender, recipient, amount);
    }
  }

  function _transferStandard(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    (uint256 tTransferAmount, uint256 tFee) = _getTValues(amount);
    uint256 grcDeduct = amount.mul(_grcPerFragment);
    uint256 grcValue = tTransferAmount.mul(_grcPerFragment);
    _grcBalances[sender] = _grcBalances[sender].sub(grcDeduct);
    _grcBalances[recipient] = _grcBalances[recipient].add(grcValue);
    _takeFee(sender, tFee);
    emit Transfer(sender, recipient, amount);
  }

  function _transferExcluded(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    uint256 grcValue = amount.mul(_grcPerFragment);
    _grcBalances[sender] = _grcBalances[sender].sub(grcValue);
    _grcBalances[recipient] = _grcBalances[recipient].add(grcValue);
    emit Transfer(sender, recipient, amount);
  }

  function _getTValues(uint256 tAmount)
    private
    view
    returns (uint256, uint256)
  {
    uint256 tFee = calculateFee(tAmount);
    uint256 tTransferAmount = tAmount.sub(tFee);
    return (tTransferAmount, tFee);
  }

  function calculateFee(uint256 _amount) private view returns (uint256) {
    return _amount.mul(transactionTax).div(10000);
  }

  function _takeFee(address sender, uint256 tFee) private {
    uint256 rFee = tFee.mul(_grcPerFragment);
    _grcBalances[address(this)] = _grcBalances[address(this)].add(rFee);
    emit Transfer(sender, address(this), tFee);
  }

  function buyBackTokens(uint256 amount) private {
    if (amount > 0) {
      swapETHForTokens(amount);
    }
  }

  function transferToAddressETH(address payable recipient, uint256 amount)
    private
  {
    recipient.transfer(amount);
  }

  receive() external payable {}

  function swapETHForTokens(uint256 amount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = uniswapV2Router.WETH();
    path[1] = address(this);

    // make the swap
    uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
      value: amount
    }(
      0, // accept any amount of Tokens
      path,
      deadAddress, // Burn address
      block.timestamp.add(300)
    );
  }

  /**
   * @dev Increase the amount of tokens that an owner has allowed to a spender.
   * This method should be used instead of approve() to avoid the double approval vulnerability
   * described above.
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */

  function increaseAllowance(address spender, uint256 addedValue)
    public
    initialDistributionLock
    returns (bool)
  {
    _approve(
      msg.sender,
      spender,
      _allowedFragments[msg.sender][spender].add(addedValue)
    );
    return true;
  }

  function _approve(
    address owner,
    address spender,
    uint256 value
  ) private {
    require(owner != address(0));
    require(spender != address(0));

    _allowedFragments[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of
   * msg.sender. This method is included for ERC20 compatibility.
   * increaseAllowance and decreaseAllowance should be used instead.
   * Changing an allowance with this method brings the risk that someone may transfer both
   * the old and the new allowance - if they are both greater than zero - if a transfer
   * transaction is mined before the later approve() call is mined.
   *
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */

  function approve(address spender, uint256 value)
    public
    override
    initialDistributionLock
    returns (bool)
  {
    _approve(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner has allowed to a spender.
   * @param owner_ The address which owns the funds.
   * @param spender The address which will spend the funds.
   * @return The number of tokens still available for the spender.
   */
  function allowance(address owner_, address spender)
    public
    view
    override
    returns (uint256)
  {
    return _allowedFragments[owner_][spender];
  }

  /**
   * @dev Decrease the amount of tokens that an owner has allowed to a spender.
   *
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    initialDistributionLock
    returns (bool)
  {
    uint256 oldValue = _allowedFragments[msg.sender][spender];
    if (subtractedValue >= oldValue) {
      _allowedFragments[msg.sender][spender] = 0;
    } else {
      _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
    }
    emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
    return true;
  }

  function setInitialDistributionFinished() external onlyOwner {
    initialDistributionFinished = true;
  }

  function enableTransfer(address _addr) external onlyOwner {
    allowTransfer[_addr] = true;
  }

  function excludeAddress(address _addr) external onlyOwner {
    _isExcluded[_addr] = true;
  }

  function unexcludeAddress(address _addr) external onlyOwner {
    _isExcluded[_addr] = false;
  }

  function burnAutoLP() external onlyOwner {
    uint256 balance = uniswapV2Pair.balanceOf(address(this));
    uniswapV2Pair.transfer(owner(), balance);
  }

  function airDrop(address[] calldata recipients, uint256[] calldata values)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < recipients.length; i++) {
      _tokenTransfer(msg.sender, recipients[i], values[i]);
    }
  }

  function setBuyBackEnabled(bool _enabled) public onlyOwner {
    buyBackEnabled = _enabled;
  }

  function setBuyBackLimit(uint256 _buybackLimit) public onlyOwner {
    buybackLimit = _buybackLimit;
  }

  function setBuyBackDivisor(uint256 _buybackDivisor) public onlyOwner {
    buybackDivisor = _buybackDivisor;
  }

  function burnBNB(address payable burnAddress) external onlyOwner {
    burnAddress.transfer(address(this).balance);
  }

  function setMarketingAddress(address payable _marketing) public onlyOwner {
    marketingAddress = _marketing;
  }

  function setAntiBot(address pinkAntiBot_) public onlyOwner {
    pinkAntiBot = IPinkAntiBot(pinkAntiBot_);
    pinkAntiBot.setTokenOwner(msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

library SafeMathInt {
  int256 private constant MIN_INT256 = int256(1) << 255;
  int256 private constant MAX_INT256 = ~(int256(1) << 255);

  /**
   * @dev Multiplies two int256 variables and fails on overflow.
   */
  function mul(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a * b;

    // Detect overflow when multiplying MIN_INT256 with -1
    require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
    require((b == 0) || (c / b == a));
    return c;
  }

  /**
   * @dev Division of two int256 variables and fails on overflow.
   */
  function div(int256 a, int256 b) internal pure returns (int256) {
    // Prevent overflow when dividing MIN_INT256 by -1
    require(b != -1 || a != MIN_INT256);

    // Solidity already throws when dividing by 0.
    return a / b;
  }

  /**
   * @dev Subtracts two int256 variables and fails on overflow.
   */
  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require((b >= 0 && c <= a) || (b < 0 && c > a));
    return c;
  }

  /**
   * @dev Adds two int256 variables and fails on overflow.
   */
  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  /**
   * @dev Converts to absolute value, and fails on overflow.
   */
  function abs(int256 a) internal pure returns (int256) {
    require(a != MIN_INT256);
    return a < 0 ? -a : a;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

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
        bytes32 accountHash =
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IUniswapV2Router02 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IUniswapV2Factory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IPinkAntiBot {
  function setTokenOwner(address owner) external;

  function onPreTransferCheck(
    address from,
    address to,
    uint256 amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ILP {
  function sync() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import './Context.sol';

contract Ownable is Context {
  address payable private _owner;
  address payable private _previousOwner;
  uint256 private _lockTime;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address payable msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address payable) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
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
    _owner = payable(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address payable newOwner)
    public
    virtual
    onlyOwner
  {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  function geUnlockTime() public view returns (uint256) {
    return _lockTime;
  }

  //Locks the contract for owner for the amount of time provided
  function lock(uint256 time) public virtual onlyOwner {
    _previousOwner = _owner;
    _owner = payable(address(0));
    _lockTime = block.timestamp + time;
    emit OwnershipTransferred(_owner, address(0));
  }

  //Unlocks the contract for owner when _lockTime is exceeds
  function unlock() public virtual {
    require(
      _previousOwner == msg.sender,
      "You don't have permission to unlock"
    );
    require(block.timestamp > _lockTime, 'Contract is locked until 7 days');
    emit OwnershipTransferred(_owner, _previousOwner);
    _owner = payable(_previousOwner);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import './interfaces/IERC20.sol';

abstract contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  /**
   * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
   * these values are immutable: they can only be set once during
   * construction.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view returns (uint8) {
    return _decimals;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

