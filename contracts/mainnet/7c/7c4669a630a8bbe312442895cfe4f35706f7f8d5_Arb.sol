/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

// File contracts/interfaces/IERC3156FlashBorrower.sol

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IERC3156FlashBorrower {

  /**
    * @dev Receive a flash loan.
    * @param initiator The initiator of the loan.
    * @param token The loan currency.
    * @param amount The amount of tokens lent.
    * @param fee The additional amount of tokens to repay.
    * @param data Arbitrary data structure, intended to contain user-defined parameters.
    * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
    */
  function onFlashLoan(
      address initiator,
      address token,
      uint256 amount,
      uint256 fee,
      bytes calldata data
  ) external returns (bytes32);
}


// File contracts/interfaces/IERC3156FlashLender.sol

pragma solidity ^0.8.0;
interface IERC3156FlashLender {
  /**
    * @dev The amount of currency available to be lent.
    * @param token The loan currency.
    * @return The amount of `token` that can be borrowed.
    */
  function maxFlashLoan(
      address token
  ) external view returns (uint256);

  /**
    * @dev The fee to be charged for a given loan.
    * @param token The loan currency.
    * @param amount The amount of tokens lent.
    * @return The amount of `token` to be charged for the loan, on top of the returned principal.
    */
  function flashFee(
      address token,
      uint256 amount
  ) external view returns (uint256);

  /**
    * @dev Initiate a flash loan.
    * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
    * @param token The loan currency.
    * @param amount The amount of tokens lent.
    * @param data Arbitrary data structure, intended to contain user-defined parameters.
    */
  function flashLoan(
      IERC3156FlashBorrower receiver,
      address token,
      uint256 amount,
      bytes calldata data
  ) external returns (bool);
}


// File contracts/interfaces/IWETH.sol

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}


// File contracts/interfaces/IEtherWrapper.sol

pragma solidity ^0.8.0;

interface IEtherWrapper {
    function capacity() external view returns (uint256);
    function getReserves() external view returns (uint256);
    function calculateMintFee(uint amount) external view returns (uint);
    function calculateBurnFee(uint amount) external view returns (uint);

    function mint(uint amount) external;
    function burn(uint amount) external;
}


// File contracts/interfaces/ICurve.sol

pragma solidity ^0.8.0;

interface ICurve {
    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);
    function balances(uint256 idx) external view returns (uint256);
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external payable;
}


// File contracts/ERC20/IERC20.sol

pragma solidity ^0.8.0;

/**
 * @title Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}


// File contracts/utils/Address.sol

pragma solidity ^0.8.0;

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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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


// File contracts/ERC20/SafeERC20.sol

pragma solidity ^0.8.0;
/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/utils/Ownable.sol

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 * @author crypto-pumpkin
 *
 * By initialization, the owner account will be the one that called initializeOwner. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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


// File contracts/Arb.sol

pragma solidity ^0.8.0;
contract Arb is Ownable {
  using SafeERC20 for IERC20;

  IERC3156FlashLender public constant flashLender = IERC3156FlashLender(0x6bdC1FCB2F13d1bA9D26ccEc3983d5D4bf318693);
  IERC20 public constant weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  IERC20 public constant seth = IERC20(0x5e74C9036fb86BD7eCdcb084a0673EFc32eA31cb);
  ICurve public constant curvePool = ICurve(0xc5424B857f758E906013F3555Dad202e4bdB4567);

  uint256 wethIndex = 0;
  uint256 sethIndex = 1;

  struct FlashloanData {
    bool isMintSeth;
    address caller;
    address target;
    uint256 minProfit;
  }

  function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data) external returns (bytes32) {
    FlashloanData memory flashData = abi.decode(data, (FlashloanData));
    require(msg.sender == address(flashLender), "Untrusted lender");
    require(token == address(weth), "Not WETH");
    require(initiator == address(this), "Untrusted loan initiator");
    uint256 amountOwed = amount + fee;
  
    // Steps 1-3:
    uint256 wethBal;
    if (flashData.isMintSeth) {
      wethBal = _swapSethForETH(flashData.target, amount);
    } else {
      wethBal = _swapEthForSeth(flashData.target, amount);
    }

    // Step 4: Ensure profit
    require(wethBal > amountOwed + flashData.minProfit, "Less than minProfit");
    weth.safeTransfer(flashData.caller, wethBal - amountOwed);
    return keccak256("ERC3156FlashBorrower.onFlashLoan");
  }

  function arb(address _sip112Address, uint256 _percentToUse, uint256 _minProfit) external onlyOwner {
    require(_percentToUse <= 100, "percent > 100");
    (bool isMintSeth, uint256 amountToFlash, uint256 wethReturned) = calculateOpportunity(_sip112Address, _percentToUse);
    require(wethReturned >= amountToFlash + _minProfit, "not enough profit!");

    bytes memory data = abi.encode(FlashloanData({
      isMintSeth: isMintSeth,
      caller: msg.sender,
      target: _sip112Address,
      minProfit: _minProfit
    }));
    uint256 _fee = flashLender.flashFee(address(weth), amountToFlash);
    uint256 _repayment = amountToFlash + _fee;
    _approve(weth, address(flashLender), _repayment);
    flashLender.flashLoan(IERC3156FlashBorrower(address(this)), address(weth), amountToFlash, data);
  }

  function calculateOpportunity(address _sip112Address, uint256 _percentToUse)
    public view
    returns (bool isMintSeth, uint256 amountToFlash, uint256 wethReturned)
  {
    uint256 maxFlashLoan = flashLender.maxFlashLoan(address(weth));
    uint256 curveWethBal = curvePool.balances(wethIndex);
    uint256 curveSethBal = curvePool.balances(sethIndex);
    if (curveWethBal > curveSethBal) {
      isMintSeth = true;
      uint256 capacity = IEtherWrapper(_sip112Address).capacity();
      uint256 adjustedCapacityToUse = capacity * _percentToUse / 100;
      amountToFlash = adjustedCapacityToUse > maxFlashLoan ? maxFlashLoan : adjustedCapacityToUse;
      uint256 mintFee = IEtherWrapper(_sip112Address).calculateMintFee(amountToFlash);
      uint256 sethBal = amountToFlash - mintFee;
      if (sethBal > 0) {
        wethReturned = curvePool.get_dy(sethIndex, wethIndex, sethBal);
      }
    } else {
      isMintSeth = false;
      uint256 reserves = IEtherWrapper(_sip112Address).getReserves();
      uint256 adjustedPercentToUse = _percentToUse > 96 ? 96 : _percentToUse;
      uint256 adjustedReserveToUse = reserves * adjustedPercentToUse / 100;
      amountToFlash = adjustedReserveToUse > maxFlashLoan ? maxFlashLoan : amountToFlash;
      if (amountToFlash > 0) {
        uint256 sethBal = curvePool.get_dy(wethIndex, sethIndex, amountToFlash);
        uint256 burnFee = IEtherWrapper(_sip112Address).calculateBurnFee(sethBal);
        wethReturned = sethBal - burnFee;
      }
    }
  }

  function _approve(IERC20 _token, address _spender, uint256 _amount) internal {
    if (_token.allowance(address(this), _spender) < _amount) {
        _token.safeApprove(_spender, type(uint256).max);
    }
  }

  /// @notice mint SETH with WETH, sell SETH for ETH on Curve, wrap ETH for WETH, return flash loaned WETH
  function _swapSethForETH(address target, uint256 amount) internal returns(uint256 wethBal) {
    // Step 1: Mint sETH with WETH
    _approve(weth, target, amount);
    IEtherWrapper(target).mint(amount);
    uint256 sethBal = seth.balanceOf(address(this));

    // Step 2: Swap sETH to ETH
    _approve(seth, address(curvePool), sethBal);
    curvePool.exchange(sethIndex, wethIndex, sethBal, 0);
    uint256 ethBal = address(this).balance;

    // Step 3: Wrap ETH into WETH
    IWETH(address(weth)).deposit{value: ethBal}();
    wethBal = weth.balanceOf(address(this));
  }

  /// @notice unwrap WETH into ETH, swap ETH for sETH on Curve, burn sETH for WETH< return flash loaned WETH
  function _swapEthForSeth(address target, uint256 amount) internal returns(uint256 wethBal) {
    // Step 1: Unwrap WETH into ETH
    _approve(weth, address(weth), amount);
    IWETH(address(weth)).withdraw(amount);
    uint256 ethBal = address(this).balance;
    
    // Step 2: Swap ETH for sETH
    curvePool.exchange{value: ethBal}(wethIndex, sethIndex, ethBal, 0);
    uint256 sethBal = seth.balanceOf(address(this));

    // Step 3: Burn sETH for WETH
    _approve(seth, target, sethBal);
    IEtherWrapper(target).burn(sethBal);
    wethBal = weth.balanceOf(address(this));
  }
}