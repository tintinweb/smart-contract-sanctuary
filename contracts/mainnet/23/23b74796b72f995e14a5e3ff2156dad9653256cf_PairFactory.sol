/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function mint(address account, uint amount) external;
  function burn(address account, uint amount) external;
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

interface IInterestRateModel {
  function systemRate(ILendingPair _pair, address _token) external view returns(uint);
  function supplyRatePerBlock(ILendingPair _pair, address _token) external view returns(uint);
  function borrowRatePerBlock(ILendingPair _pair, address _token) external view returns(uint);
}

interface IRewardDistribution {
  function distributeReward(address _account, address _token) external;
}

interface IController {
  function interestRateModel() external view returns(IInterestRateModel);
  function rewardDistribution() external view returns(IRewardDistribution);
  function feeRecipient() external view returns(address);
  function LIQ_MIN_HEALTH() external view returns(uint);
  function minBorrowUSD() external view returns(uint);
  function liqFeeSystem(address _token) external view returns(uint);
  function liqFeeCaller(address _token) external view returns(uint);
  function liqFeesTotal(address _token) external view returns(uint);
  function colFactor(address _token) external view returns(uint);
  function depositLimit(address _lendingPair, address _token) external view returns(uint);
  function borrowLimit(address _lendingPair, address _token) external view returns(uint);
  function originFee(address _token) external view returns(uint);
  function depositsEnabled() external view returns(bool);
  function borrowingEnabled() external view returns(bool);
  function setFeeRecipient(address _feeRecipient) external;
  function tokenPrice(address _token) external view returns(uint);
  function tokenSupported(address _token) external view returns(bool);
}

interface ILendingPair {
  function checkAccountHealth(address _account) external view;
  function accrueAccount(address _account) external;
  function accrue() external;
  function accountHealth(address _account) external view returns(uint);
  function totalDebt(address _token) external view returns(uint);
  function tokenA() external view returns(address);
  function tokenB() external view returns(address);
  function lpToken(address _token) external view returns(IERC20);
  function debtOf(address _account, address _token) external view returns(uint);
  function pendingDebtTotal(address _token) external view returns(uint);
  function pendingSupplyTotal(address _token) external view returns(uint);
  function deposit(address _token, uint _amount) external;
  function withdraw(address _token, uint _amount) external;
  function borrow(address _token, uint _amount) external;
  function repay(address _token, uint _amount) external;
  function withdrawBorrow(address _token, uint _amount) external;
  function controller() external view returns(IController);

  function borrowBalance(
    address _account,
    address _borrowedToken,
    address _returnToken
  ) external view returns(uint);

  function convertTokenValues(
    address _fromToken,
    address _toToken,
    uint    _inputAmount
  ) external view returns(uint);
}

contract Ownable {

  address public owner;
  address public pendingOwner;

  event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferConfirmed(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferConfirmed(address(0), owner);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function transferOwnership(address _newOwner) external onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferInitiated(owner, _newOwner);
    pendingOwner = _newOwner;
  }

  function acceptOwnership() external {
    require(msg.sender == pendingOwner, "Ownable: caller is not pending owner");
    emit OwnershipTransferConfirmed(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

interface ILPTokenMaster is IERC20 {
  function initialize() external;
  function transferOwnership(address newOwner) external;
  function underlying() external view returns(address);
  function owner() external view returns(address);
  function lendingPair() external view returns(address);
  function selfBurn(uint _amount) external;
}

interface IWETH {
  function deposit() external payable;
  function withdraw(uint wad) external;
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
  function approve(address spender, uint amount) external returns (bool);
}

library Math {

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow, so we distribute.
    return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
  }

  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a / b + (a % b == 0 ? 0 : 1);
  }
}

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

contract ERC20 is Ownable {

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

  mapping (address => uint) public balanceOf;
  mapping (address => mapping (address => uint)) public allowance;

  string public name;
  string public symbol;
  uint8 public immutable decimals;
  uint public totalSupply;

  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    require(_decimals > 0, "decimals");
  }

  function transfer(address _recipient, uint _amount) external returns (bool) {
    _transfer(msg.sender, _recipient, _amount);
    return true;
  }

  function approve(address _spender, uint _amount) external returns (bool) {
    _approve(msg.sender, _spender, _amount);
    return true;
  }

  function transferFrom(address _sender, address _recipient, uint _amount) external returns (bool) {
    require(allowance[_sender][msg.sender] >= _amount, "ERC20: insufficient approval");
    _transfer(_sender, _recipient, _amount);
    _approve(_sender, msg.sender, allowance[_sender][msg.sender] - _amount);
    return true;
  }

  function mint(address _account, uint _amount) external onlyOwner {
    _mint(_account, _amount);
  }

  function burn(address _account, uint _amount) external onlyOwner {
    _burn(_account, _amount);
  }

  function _transfer(address _sender, address _recipient, uint _amount) internal {
    require(_sender != address(0), "ERC20: transfer from the zero address");
    require(_recipient != address(0), "ERC20: transfer to the zero address");
    require(balanceOf[_sender] >= _amount, "ERC20: insufficient funds");

    balanceOf[_sender] -= _amount;
    balanceOf[_recipient] += _amount;
    emit Transfer(_sender, _recipient, _amount);
  }

  function _mint(address _account, uint _amount) internal {
    require(_account != address(0), "ERC20: mint to the zero address");

    totalSupply += _amount;
    balanceOf[_account] += _amount;
    emit Transfer(address(0), _account, _amount);
  }

  function _burn(address _account, uint _amount) internal {
    require(_account != address(0), "ERC20: burn from the zero address");

    balanceOf[_account] -= _amount;
    totalSupply -= _amount;
    emit Transfer(_account, address(0), _amount);
  }

  function _approve(address _owner, address _spender, uint _amount) internal {
    require(_owner != address(0), "ERC20: approve from the zero address");
    require(_spender != address(0), "ERC20: approve to the zero address");

    allowance[_owner][_spender] = _amount;
    emit Approval(_owner, _spender, _amount);
  }
}

contract ReentrancyGuard {
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor () {
    _status = _NOT_ENTERED;
  }

  modifier nonReentrant() {
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
  }
}

contract TransferHelper {

  using SafeERC20 for IERC20;

  // Mainnet
  IWETH internal constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  // Kovan
  // IWETH internal constant WETH = IWETH(0xd0A1E359811322d97991E03f863a0C30C2cF029C);

  function _safeTransferFrom(address _token, address _sender, uint _amount) internal virtual {
    require(_amount > 0, "TransferHelper: amount must be > 0");
    IERC20(_token).safeTransferFrom(_sender, address(this), _amount);
  }

  function _safeTransfer(address _token, address _recipient, uint _amount) internal virtual {
    require(_amount > 0, "TransferHelper: amount must be > 0");
    IERC20(_token).safeTransfer(_recipient, _amount);
  }

  function _wethWithdrawTo(address _to, uint _amount) internal virtual {
    require(_amount > 0, "TransferHelper: amount must be > 0");
    require(_to != address(0), "TransferHelper: invalid recipient");

    WETH.withdraw(_amount);
    (bool success, ) = _to.call { value: _amount }(new bytes(0));
    require(success, 'TransferHelper: ETH transfer failed');
  }

  function _depositWeth() internal {
    require(msg.value > 0, "TransferHelper: amount must be > 0");
    WETH.deposit { value: msg.value }();
  }
}

contract LendingPair is TransferHelper, ReentrancyGuard {

  // Prevents division by zero and other undesirable behaviour
  uint private constant MIN_RESERVE = 1000;

  using Address for address;
  using Clones for address;

  mapping (address => mapping (address => uint)) public debtOf;
  mapping (address => mapping (address => uint)) public accountInterestSnapshot;
  mapping (address => uint) public cumulativeInterestRate; // 100e18 = 100%
  mapping (address => uint) public totalDebt;
  mapping (address => IERC20) public lpToken;

  IController public controller;
  address public tokenA;
  address public tokenB;
  uint public lastBlockAccrued;

  event Liquidation(
    address indexed account,
    address indexed repayToken,
    address indexed supplyToken,
    uint repayAmount,
    uint supplyAmount
  );

  event Deposit(address indexed account, address indexed token, uint amount);
  event Withdraw(address indexed token, uint amount);
  event Borrow(address indexed token, uint amount);
  event Repay(address indexed account, address indexed token, uint amount);

  receive() external payable {}

  function initialize(
    address _lpTokenMaster,
    address _controller,
    IERC20 _tokenA,
    IERC20 _tokenB
  ) external {
    require(address(tokenA) == address(0), "LendingPair: already initialized");
    require(address(_tokenA) != address(0) && address(_tokenB) != address(0), "LendingPair: cannot be ZERO address");

    controller = IController(_controller);
    tokenA = address(_tokenA);
    tokenB = address(_tokenB);
    lastBlockAccrued = block.number;

    lpToken[tokenA] = _createLpToken(_lpTokenMaster);
    lpToken[tokenB] = _createLpToken(_lpTokenMaster);
  }

  function depositRepay(address _account, address _token, uint _amount) external nonReentrant {
    _validateToken(_token);
    accrueAccount(_account);

    _depositRepay(_account, _token, _amount);
    _safeTransferFrom(_token, msg.sender, _amount);
  }

  function depositRepayETH(address _account) external payable nonReentrant {
    _validateToken(address(WETH));
    accrueAccount(_account);

    _depositRepay(_account, address(WETH), msg.value);
    _depositWeth();
  }

  function deposit(address _account, address _token, uint _amount) external nonReentrant {
    _validateToken(_token);
    accrueAccount(_account);

    _deposit(_account, _token, _amount);
    _safeTransferFrom(_token, msg.sender, _amount);
  }

  function withdrawBorrow(address _token, uint _amount) external nonReentrant {
    _validateToken(_token);
    accrueAccount(msg.sender);

    _withdrawBorrow(_token, _amount);
    _safeTransfer(_token, msg.sender, _amount);
  }

  function withdrawBorrowETH(uint _amount) external nonReentrant {
    _validateToken(address(WETH));
    accrueAccount(msg.sender);

    _withdrawBorrow(address(WETH), _amount);
    _wethWithdrawTo(msg.sender, _amount);
  }

  function withdraw(address _token, uint _amount) external nonReentrant {
    _validateToken(_token);
    accrueAccount(msg.sender);

    _withdraw(_token, _amount);
    _safeTransfer(_token, msg.sender, _amount);
  }

  function withdrawAll(address _token) external nonReentrant {
    _validateToken(_token);
    accrueAccount(msg.sender);

    uint amount = lpToken[_token].balanceOf(msg.sender);
    _withdraw(_token, amount);
    _safeTransfer(_token, msg.sender, amount);
  }

  function withdrawAllETH() external nonReentrant {
    _validateToken(address(WETH));
    accrueAccount(msg.sender);

    uint amount = lpToken[address(WETH)].balanceOf(msg.sender);
    _withdraw(address(WETH), amount);
    _wethWithdrawTo(msg.sender, amount);
  }

  function borrow(address _token, uint _amount) external nonReentrant {
    _validateToken(_token);
    accrueAccount(msg.sender);

    _borrow(_token, _amount);
    _safeTransfer(_token, msg.sender, _amount);
  }

  function repayAll(address _account, address _token) external nonReentrant {
    _validateToken(_token);
    _requireAccountNotAccrued(_token, _account);
    accrueAccount(_account);

    uint amount = debtOf[_token][_account];
    _repay(_account, _token, amount);
    _safeTransferFrom(_token, msg.sender, amount);
  }

  function repayAllETH(address _account) external payable nonReentrant {
    _validateToken(address(WETH));
    _requireAccountNotAccrued(address(WETH), _account);
    accrueAccount(_account);

    uint amount = debtOf[address(WETH)][_account];
    require(msg.value >= amount, "LendingPair: insufficient ETH deposit");

    _depositWeth();
    _repay(_account, address(WETH), amount);
    uint refundAmount = msg.value > amount ? (msg.value - amount) : 0;

    if (refundAmount > 0) {
      _wethWithdrawTo(msg.sender, refundAmount);
    }
  }

  function repay(address _account, address _token, uint _amount) external nonReentrant {
    _validateToken(_token);
    accrueAccount(_account);

    _repay(_account, _token, _amount);
    _safeTransferFrom(_token, msg.sender, _amount);
  }

  function accrue() public {
    if (lastBlockAccrued < block.number) {
      _accrueInterest(tokenA);
      _accrueInterest(tokenB);
      lastBlockAccrued = block.number;
    }
  }

  function accrueAccount(address _account) public {
    _distributeReward(_account);
    accrue();
    _accrueAccountInterest(_account);

    if (_account != feeRecipient()) {
      _accrueAccountInterest(feeRecipient());
    }
  }

  // Sell collateral to reduce debt and increase accountHealth
  // Set _repayAmount to uint(-1) to repay all debt, inc. pending interest
  function liquidateAccount(
    address _account,
    address _repayToken,
    uint    _repayAmount,
    uint    _minSupplyOutput
  ) external nonReentrant {

    // Input validation and adjustments

    _validateToken(_repayToken);
    address supplyToken = _repayToken == tokenA ? tokenB : tokenA;

    // Check account is underwater after interest

    accrueAccount(_account);
    uint health = accountHealth(_account);
    require(health < controller.LIQ_MIN_HEALTH(), "LendingPair: account health < LIQ_MIN_HEALTH");

    // Calculate balance adjustments

    _repayAmount = Math.min(_repayAmount, debtOf[_repayToken][_account]);

    uint supplyDebt   = _convertTokenValues(_repayToken, supplyToken, _repayAmount);
    uint callerFee    = supplyDebt * controller.liqFeeCaller(_repayToken) / 100e18;
    uint systemFee    = supplyDebt * controller.liqFeeSystem(_repayToken) / 100e18;
    uint supplyBurn   = supplyDebt + callerFee + systemFee;
    uint supplyOutput = supplyDebt + callerFee;

    require(supplyOutput >= _minSupplyOutput, "LendingPair: supplyOutput >= _minSupplyOutput");

    // Adjust balances

    _burnSupply(supplyToken, _account, supplyBurn);
    _mintSupply(supplyToken, feeRecipient(), systemFee);
    _burnDebt(_repayToken, _account, _repayAmount);

    // Settle token transfers

    _safeTransferFrom(_repayToken, msg.sender, _repayAmount);
    _mintSupply(supplyToken, msg.sender, supplyOutput);

    emit Liquidation(_account, _repayToken, supplyToken, _repayAmount, supplyOutput);
  }

  function accountHealth(address _account) public view returns(uint) {

    if (debtOf[tokenA][_account] == 0 && debtOf[tokenB][_account] == 0) {
      return controller.LIQ_MIN_HEALTH();
    }

    uint totalAccountSupply  = _supplyCredit(_account, tokenA, tokenA)  + _supplyCredit(_account, tokenB, tokenA);
    uint totalAccountBorrow = _borrowBalance(_account, tokenA, tokenA) + _borrowBalance(_account, tokenB, tokenA);

    return totalAccountSupply * 1e18 / totalAccountBorrow;
  }

  // Get borow balance converted to the units of _returnToken
  function borrowBalance(
    address _account,
    address _borrowedToken,
    address _returnToken
  ) external view returns(uint) {

    _validateToken(_borrowedToken);
    _validateToken(_returnToken);

    return _borrowBalance(_account, _borrowedToken, _returnToken);
  }

  function supplyBalance(
    address _account,
    address _suppliedToken,
    address _returnToken
  ) external view returns(uint) {

    _validateToken(_suppliedToken);
    _validateToken(_returnToken);

    return _supplyBalance(_account, _suppliedToken, _returnToken);
  }

  function supplyRatePerBlock(address _token) external view returns(uint) {
    _validateToken(_token);
    return controller.interestRateModel().supplyRatePerBlock(ILendingPair(address(this)), _token);
  }

  function borrowRatePerBlock(address _token) external view returns(uint) {
    _validateToken(_token);
    return _borrowRatePerBlock(_token);
  }

  function pendingSupplyInterest(address _token, address _account) external view returns(uint) {
    _validateToken(_token);
    uint newInterest = _newInterest(lpToken[_token].balanceOf(_account), _token, _account);
    return newInterest * _lpRate(_token) / 100e18;
  }

  function pendingBorrowInterest(address _token, address _account) external view returns(uint) {
    _validateToken(_token);
    return _pendingBorrowInterest(_token, _account);
  }

  function feeRecipient() public view returns(address) {
    return controller.feeRecipient();
  }

  function checkAccountHealth(address _account) public view  {
    uint health = accountHealth(_account);
    require(health >= controller.LIQ_MIN_HEALTH(), "LendingPair: insufficient accountHealth");
  }

  function convertTokenValues(
    address _fromToken,
    address _toToken,
    uint    _inputAmount
  ) external view returns(uint) {

    _validateToken(_fromToken);
    _validateToken(_toToken);

    return _convertTokenValues(_fromToken, _toToken, _inputAmount);
  }

  function _depositRepay(address _account, address _token, uint _amount) internal {

    uint debt = debtOf[_token][_account];
    uint repayAmount = debt > _amount ? _amount : debt;

    if (repayAmount > 0) {
      _repay(_account, _token, repayAmount);
    }

    uint depositAmount = _amount - repayAmount;

    if (depositAmount > 0) {
      _deposit(_account, _token, depositAmount);
    }
  }

  function _withdrawBorrow(address _token, uint _amount) internal {

    uint supplyAmount = lpToken[_token].balanceOf(msg.sender);
    uint withdrawAmount = supplyAmount > _amount ? _amount : supplyAmount;

    if (withdrawAmount > 0) {
      _withdraw(_token, withdrawAmount);
    }

    uint borrowAmount = _amount - withdrawAmount;

    if (borrowAmount > 0) {
      _borrow(_token, borrowAmount);
    }
  }

  function _distributeReward(address _account) internal {
    IRewardDistribution rewardDistribution = controller.rewardDistribution();

    if (
      address(rewardDistribution) != address(0) &&
      _account != feeRecipient()
    ) {
      rewardDistribution.distributeReward(_account, tokenA);
      rewardDistribution.distributeReward(_account, tokenB);
    }
  }

  function _mintSupply(address _token, address _account, uint _amount) internal {
    if (_amount > 0) {
      lpToken[_token].mint(_account, _amount);
    }
  }

  function _burnSupply(address _token, address _account, uint _amount) internal {
    if (_amount > 0) {
      lpToken[_token].burn(_account, _amount);
    }
  }

  function _mintDebt(address _token, address _account, uint _amount) internal {
    debtOf[_token][_account] += _amount;
    totalDebt[_token] += _amount;
  }

  // Origination fee is earned entirely by the protocol and is not split with the LPs
  // The goal is to prevent free flash loans
  function _mintDebtWithOriginFee(address _token, address _account, uint _amount) internal {
    uint originFee = _originationFee(_token, _amount);
    _mintSupply(_token, feeRecipient(), originFee);
    _mintDebt(_token, _account, _amount + originFee);
  }

  function _burnDebt(address _token, address _account, uint _amount) internal {
    debtOf[_token][_account] -= _amount;
    totalDebt[_token] -= _amount;
  }

  function _accrueAccountInterest(address _account) internal {
    uint lpBalanceA = lpToken[tokenA].balanceOf(_account);
    uint lpBalanceB = lpToken[tokenB].balanceOf(_account);

    _accrueAccountSupply(tokenA, lpBalanceA, _account);
    _accrueAccountSupply(tokenB, lpBalanceB, _account);
    _accrueAccountDebt(tokenA, _account);
    _accrueAccountDebt(tokenB, _account);

    accountInterestSnapshot[tokenA][_account] = cumulativeInterestRate[tokenA];
    accountInterestSnapshot[tokenB][_account] = cumulativeInterestRate[tokenB];
  }

  function _accrueAccountSupply(address _token, uint _amount, address _account) internal {
    if (_amount > 0) {
      uint supplyInterest   = _newInterest(_amount, _token, _account);
      uint newSupplyAccount = supplyInterest * _lpRate(_token) / 100e18;
      uint newSupplySystem  = supplyInterest * _systemRate(_token) / 100e18;

      _mintSupply(_token, _account, newSupplyAccount);
      _mintSupply(_token, feeRecipient(), newSupplySystem);
    }
  }

  function _accrueAccountDebt(address _token, address _account) internal {
    if (debtOf[_token][_account] > 0) {
      uint newDebt = _pendingBorrowInterest(_token, _account);
      _mintDebt(_token, _account, newDebt);
    }
  }

  function _withdraw(address _token, uint _amount) internal {

    lpToken[_token].burn(msg.sender, _amount);

    checkAccountHealth(msg.sender);

    emit Withdraw(_token, _amount);
  }

  function _borrow(address _token, uint _amount) internal {

    require(lpToken[_token].balanceOf(msg.sender) == 0, "LendingPair: cannot borrow supplied token");

    _mintDebtWithOriginFee(_token, msg.sender, _amount);

    _checkBorrowLimits(_token, msg.sender);
    checkAccountHealth(msg.sender);

    emit Borrow(_token, _amount);
  }

  function _repay(address _account, address _token, uint _amount) internal {
    _burnDebt(_token, _account, _amount);
    emit Repay(_account, _token, _amount);
  }

  function _deposit(address _account, address _token, uint _amount) internal {

    _checkOracleSupport(tokenA);
    _checkOracleSupport(tokenB);

    require(debtOf[_token][_account] == 0, "LendingPair: cannot deposit borrowed token");

    _mintSupply(_token, _account, _amount);
    _checkDepositLimit(_token);

    emit Deposit(_account, _token, _amount);
  }

  function _accrueInterest(address _token) internal {
    cumulativeInterestRate[_token] += _pendingInterestRate(_token);
  }

  function _pendingInterestRate(address _token) internal view returns(uint) {
    uint blocksElapsed = block.number - lastBlockAccrued;
    return _borrowRatePerBlock(_token) * blocksElapsed;
  }

  function _createLpToken(address _lpTokenMaster) internal returns(IERC20) {
    ILPTokenMaster newLPToken = ILPTokenMaster(_lpTokenMaster.clone());
    newLPToken.initialize();
    return IERC20(newLPToken);
  }

  function _safeTransfer(address _token, address _recipient, uint _amount) internal override {
    TransferHelper._safeTransfer(_token, _recipient, _amount);
    _checkMinReserve(address(_token));
  }

  function _wethWithdrawTo(address _to, uint _amount) internal override {
    TransferHelper._wethWithdrawTo(_to, _amount);
    _checkMinReserve(address(WETH));
  }

  function _borrowRatePerBlock(address _token) internal view returns(uint) {
    return controller.interestRateModel().borrowRatePerBlock(ILendingPair(address(this)), _token);
  }

  function _pendingBorrowInterest(address _token, address _account) internal view returns(uint) {
    return _newInterest(debtOf[_token][_account], _token, _account);
  }

  function _borrowBalance(
    address _account,
    address _borrowedToken,
    address _returnToken
  ) internal view returns(uint) {

    return _convertTokenValues(_borrowedToken, _returnToken, debtOf[_borrowedToken][_account]);
  }

  // Get supply balance converted to the units of _returnToken
  function _supplyBalance(
    address _account,
    address _suppliedToken,
    address _returnToken
  ) internal view returns(uint) {

    return _convertTokenValues(_suppliedToken, _returnToken, lpToken[_suppliedToken].balanceOf(_account));
  }

  function _supplyCredit(
    address _account,
    address _suppliedToken,
    address _returnToken
  ) internal view returns(uint) {

    return _supplyBalance(_account, _suppliedToken, _returnToken) * controller.colFactor(_suppliedToken) / 100e18;
  }

  function _convertTokenValues(
    address _fromToken,
    address _toToken,
    uint    _inputAmount
  ) internal view returns(uint) {

    uint priceFrom = controller.tokenPrice(_fromToken) * 1e18 / 10 ** IERC20(_fromToken).decimals();
    uint priceTo   = controller.tokenPrice(_toToken)   * 1e18 / 10 ** IERC20(_toToken).decimals();

    return _inputAmount * priceFrom / priceTo;
  }

  function _validateToken(address _token) internal view {
    require(_token == tokenA || _token == tokenB, "LendingPair: invalid token");
  }

  function _checkOracleSupport(address _token) internal view {
    require(controller.tokenSupported(_token), "LendingPair: token not supported");
  }

  function _checkMinReserve(address _token) internal view {
    require(IERC20(_token).balanceOf(address(this)) >= MIN_RESERVE, "LendingPair: below MIN_RESERVE");
  }

  function _checkDepositLimit(address _token) internal view {
    require(controller.depositsEnabled(), "LendingPair: deposits disabled");

    uint depositLimit = controller.depositLimit(address(this), _token);

    if (depositLimit > 0) {
      require((lpToken[_token].totalSupply()) <= depositLimit, "LendingPair: deposit limit reached");
    }
  }

  function _checkBorrowLimits(address _token, address _account) internal view {
    require(controller.borrowingEnabled(), "LendingPair: borrowing disabled");

    uint accountBorrowUSD = debtOf[_token][_account] * controller.tokenPrice(_token) / 1e18;
    require(accountBorrowUSD >= controller.minBorrowUSD(), "LendingPair: borrow amount below minimum");

    uint borrowLimit = controller.borrowLimit(address(this), _token);

    if (borrowLimit > 0) {
      require(totalDebt[_token] <= borrowLimit, "LendingPair: borrow limit reached");
    }
  }

  function _originationFee(address _token, uint _amount) internal view returns(uint) {
    return _amount * controller.originFee(_token) / 100e18;
  }

  function _systemRate(address _token) internal view returns(uint) {
    return controller.interestRateModel().systemRate(ILendingPair(address(this)), _token);
  }

  function _lpRate(address _token) internal view returns(uint) {
    return 100e18 - _systemRate(_token);
  }

  function _newInterest(uint _balance, address _token, address _account) internal view returns(uint) {
    uint currentCumulativeRate = cumulativeInterestRate[_token] + _pendingInterestRate(_token);
    return _balance * (currentCumulativeRate - accountInterestSnapshot[_token][_account]) / 100e18;
  }

  // Used in repayAll and repayAllETH to prevent front-running
  // Potential attack:
  // Recipient account watches the mempool and takes out a large loan just before someone calls repayAll.
  // As a result, paying account would end up paying much more than anticipated
  function _requireAccountNotAccrued(address _token, address _account) internal view {
    if (lastBlockAccrued == block.number && cumulativeInterestRate[_token] > 0) {
      require(
        cumulativeInterestRate[_token] > accountInterestSnapshot[_token][_account],
        "LendingPair: account already accrued"
      );
    }
  }
}

contract PairFactory is Ownable {

  uint private constant MAX_INT = 2**256 - 1;

  using Address for address;
  using Clones for address;

  address public lendingPairMaster;
  address public lpTokenMaster;
  IController public controller;

  mapping(address => mapping(address => address)) public pairByTokens;

  event PairCreated(address indexed pair, address indexed tokenA, address indexed tokenB);

  constructor(
    address _lendingPairMaster,
    address _lpTokenMaster,
    IController _controller
  ) {
    lendingPairMaster = _lendingPairMaster;
    lpTokenMaster = _lpTokenMaster;
    controller = _controller;
  }

  function createPair(
    address _tokenA,
    address _tokenB
  ) external returns(address) {

    require(_tokenA != _tokenB, 'PairFactory: duplicate tokens');
    require(_tokenA != address(0) && _tokenB != address(0), 'PairFactory: zero address');
    require(pairByTokens[_tokenA][_tokenB] == address(0), 'PairFactory: already exists');

    require(
      controller.tokenSupported(_tokenA) && controller.tokenSupported(_tokenB),
      "PairFactory: token not supported"
    );

    LendingPair lendingPair = LendingPair(payable(lendingPairMaster.clone()));
    lendingPair.initialize(lpTokenMaster, address(controller), IERC20(_tokenA), IERC20(_tokenB));
    pairByTokens[_tokenA][_tokenB] = address(lendingPair);
    pairByTokens[_tokenB][_tokenA] = address(lendingPair);

    emit PairCreated(address(lendingPair), _tokenA, _tokenB);

    return address(lendingPair);
  }
}