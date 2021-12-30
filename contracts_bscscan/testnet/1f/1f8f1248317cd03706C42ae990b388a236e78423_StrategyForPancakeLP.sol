// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import  "../interfaces/IPair.sol";
import  "../interfaces/IMasterChef.sol";
import  "../interfaces/IRouter02.sol";

import  "./BaseStrategy.sol";

// 1. stake Pancake lp earn cake.
// 2. cake to lp
contract StrategyForPancakeLP is BaseStrategy {
  using SafeERC20 for IERC20;

  address public immutable router;
  // bsc: 0x73feaa1ee314f8c655e354234017be2193c9e24e
  address public immutable masterChef;
  

  uint public immutable pid;

  address public immutable token0;
  address public immutable token1;

  address[] public outputToToken0Path;
  address[] public outputToToken1Path;

  constructor(address _controller, address _fee, address _want, address _router, address _master, uint _pid)
    BaseStrategy(_controller, _fee, _want, IMasterChef(_master).cake()) {
    router = _router;
    masterChef = _master;
    pid = _pid;

    token0 = IPair(_want).token0();
    token1 = IPair(_want).token1();
  
    outputToToken0Path = [output, token0];
    outputToToken1Path = [output, token1];

    doApprove();
  }

  function doApprove() public {
    IERC20(token0).safeApprove(router, type(uint).max);
    IERC20(token1).safeApprove(router, type(uint).max);

    IERC20(output).safeApprove(router, type(uint).max);
    IERC20(want).safeApprove(masterChef, type(uint).max);
  }

  function balanceOfPool() public virtual override view returns (uint) {
    (uint amount, ) = IMasterChef(masterChef).userInfo(pid, address(this));
    return amount;
  }

  function pendingOutput() external virtual override view returns (uint) {
    return IMasterChef(masterChef).pendingCake(pid, address(this));
  }

  function deposit() public virtual override {
    uint dAmount = IERC20(want).balanceOf(address(this));
    if (dAmount > 0) {
      IMasterChef(masterChef).deposit(pid, dAmount);  // receive pending cake.
      emit Deposit(dAmount);
    }

    doHarvest();
  }

  // yield
  function harvest() public virtual override {
    IMasterChef(masterChef).deposit(pid, 0);
    doHarvest();
  }

  // only call from dToken 
  function withdraw(uint _amount) external virtual override {
    address dToken = IController(controller).dyTokens(want);
    require(msg.sender == dToken, "invalid caller");

    uint dAmount = IERC20(want).balanceOf(address(this));
    if (dAmount < _amount) {
      IMasterChef(masterChef).withdraw(pid, _amount - dAmount);
    }

    safeTransfer(want, dToken, _amount);  // lp transfer to dToken
    emit Withdraw(_amount);
    doHarvest();
  }

  // should used for reset strategy
  function withdrawAll() external virtual override returns (uint balance) {
    address dToken = IController(controller).dyTokens(want);
    require(msg.sender == controller || msg.sender == dToken, "invalid caller");
    
    doHarvest();
    uint b = balanceOfPool();
    IMasterChef(masterChef).withdraw(pid, b);

    uint balance = IERC20(want).balanceOf(address(this));
    IERC20(want).safeTransfer(dToken, balance);
    emit Withdraw(balance);
    
    // May left a little output token, let's send to Yield Fee Receiver.
    uint256 cakeBalance = IERC20(output).balanceOf(address(this));
    (address feeReceiver, ) = feeConf.getConfig("yield_fee");
    IERC20(output).safeTransfer(feeReceiver, cakeBalance);
  }

  function emergency() external override onlyOwner {
    IMasterChef(masterChef).emergencyWithdraw(pid);
    
    uint amount = IERC20(want).balanceOf(address(this));
    address dToken = IController(controller).dyTokens(want);

    if (dToken != address(0)) {
      IERC20(want).safeTransfer(dToken, amount);
    } else {
      IERC20(want).safeTransfer(owner(), amount);
    }
    emit Withdraw(amount);
  }

  function doHarvest() internal virtual {
    uint256 cakeBalance = IERC20(output).balanceOf(address(this));
    if(cakeBalance > minHarvestAmount) {

      IRouter02(router).swapExactTokensForTokens(cakeBalance/2, 0, outputToToken0Path, address(this), block.timestamp + 10);
      IRouter02(router).swapExactTokensForTokens(cakeBalance/2, 0, outputToToken1Path, address(this), block.timestamp + 10);
      
      uint token0Amount = IERC20(token0).balanceOf(address(this));
      uint token1Amount = IERC20(token1).balanceOf(address(this));

      (, , uint liquidity) = IRouter02(router).addLiquidity(token0, token1,
        token0Amount, token1Amount,
        0, 0,
        address(this),
        block.timestamp + 10);
      
      uint fee = sendYieldFee(liquidity);
      uint hAmount = liquidity - fee;

      IMasterChef(masterChef).deposit(pid, hAmount);
      emit Harvest(hAmount);
    }
  }

  function sendYieldFee(uint liquidity) internal returns (uint fee) {
    (address feeReceiver, uint yieldFee) = feeConf.getConfig("yield_fee");

    fee = liquidity * yieldFee / PercentBase;
    if (fee > 0) {
      IERC20(want).safeTransfer(feeReceiver, fee);
    }
  }

  function setToken0Path(address[] memory _path) public onlyOwner {
    outputToToken0Path = _path;
  }

  function setToken2Path(address[] memory _path) public onlyOwner {
    outputToToken1Path = _path;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

// for PancakePair or UniswapPair
interface IPair {

  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IMasterChef {
  function cake() external view returns (address) ;
  function poolLength() external view returns (uint256);
  function poolInfo(uint pid) external view returns (address lpToken,  uint256 allocPoint, uint256 lastRewardBlock, uint256 accSushiPerShare);
  function userInfo(uint pid, address user)  external view returns (uint amount, uint rewardDebt);
  
  // View function to see pending SUSHIs on frontend.
  function pendingCake(uint256 _pid, address _user) external view returns (uint256);
  
  function deposit(uint256 _pid, uint256 _amount) external;
  function withdraw(uint256 _pid, uint256 _amount) external;
  function emergencyWithdraw(uint256 _pid) external;
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IRouter02 {

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

  function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);


  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../Constants.sol";
import  "../interfaces/IStrategy.sol";
import  "../interfaces/IFeeConf.sol";
import  "../interfaces/IController.sol";


/*
  if possible, strategies must remain as immutable as possible, instead of updating variables, update the contract by linking it in the controller
*/

abstract contract BaseStrategy is Constants, IStrategy, Ownable {
    using SafeERC20 for IERC20;
    
    address internal want; // such as: pancake lp 
    address public output; // such as: cake

    uint public minHarvestAmount;
    address public override controller;
    IFeeConf public feeConf;

    event Harvest(uint amount);
    event Deposit(uint amount);
    event Withdraw(uint amount);
    
    constructor(address _controller, address _fee, address _want, address _output) {
      controller = _controller;
      want = _want;
      output = _output;
      minHarvestAmount = 1e18;

      feeConf = IFeeConf(_fee);
    }

    function getWant() external view override returns (address){
      return want;
    }

    function balanceOf() external virtual view returns (uint256) {
      uint b = IERC20(want).balanceOf(address(this));
      return b + balanceOfPool();
    }

    function balanceOfPool() public virtual view returns (uint);

    // normally call from dToken.
    function deposit() public virtual;
    
    function harvest() external virtual;
    
    // Withdraw partial funds, normally used with a dToken withdrawal
    function withdraw(uint _amount) external virtual ;
    
    // Withdraw all funds, normally used when migrating strategies
    function withdrawAll() external virtual returns (uint balance);
    
    function emergency() external virtual;

    // pending cake
    function pendingOutput() external virtual view returns (uint);
    

    function setMinHarvestAmount(uint _minAmount) external onlyOwner {
      minHarvestAmount = _minAmount;
    }

    function setController(address _controller) external onlyOwner {
      controller = _controller;
    }

    function setFeeConf(address _feeConf) external onlyOwner {
      feeConf = IFeeConf(_feeConf);
    }

    // TODO: 紧急出口，测试使用
    function inCaseTokensGetStuck(address _token, uint _amount) public onlyOwner {
      IERC20(_token).safeTransfer(owner(), _amount);
    }

    function safeTransfer(address _token, address _to, uint _amount) internal {
      uint b = IERC20(_token).balanceOf(address(this));
      if (b > _amount) {
        IERC20(_token).safeTransfer(_to, _amount);
      } else {
        IERC20(_token).safeTransfer(_to, b);
      }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Constants {
  uint public constant PercentBase = 10000;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IStrategy {

    function controller() external view returns (address);
    function getWant() external view returns (address);
    function deposit() external;
    function harvest() external;
    function withdraw(uint) external;
    function withdrawAll() external returns (uint256);
    function balanceOf() external view returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IFeeConf {
  function getConfig(bytes32 _key) external view returns (address, uint); 
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IController {
  function dyTokens(address) external view returns (address);
  function getValueConf(address _underlying) external view returns (address oracle, uint16 dr, uint16 pr);
  function getValueConfs(address token0, address token1) external view returns (address oracle0, uint16 dr0, uint16 pr0, address oracle1, uint16 dr1, uint16 pr1);

  function strategies(address) external view returns (address);
  function dyTokenVaults(address) external view returns (address);

  function beforeDeposit(address , address _vault, uint) external view;
  function beforeBorrow(address _borrower, address _vault, uint256 _amount) external view;
  function beforeWithdraw(address _redeemer, address _vault, uint256 _amount) external view;
  function beforeRepay(address _repayer , address _vault, uint256 _amount) external view;

  function joinVault(address _user, bool isDeposit) external;
  function exitVault(address _user, bool isDeposit) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}