/**
 *Submitted for verification at Etherscan.io on 2021-04-24
*/

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2021 0xdev0 - All rights reserved
// https://twitter.com/0xdev0

pragma solidity ^0.8.0;

interface IERC20 {
  function initialize() external;
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

interface ILendingPair {
  function checkAccountHealth(address _account) external view;
  function totalDebt(address _token) external view returns(uint);
  function lpToken(address _token) external view returns(IERC20);
  function debtOf(address _account, address _token) external view returns(uint);
  function deposit(address _token, uint _amount) external;
  function withdraw(address _token, uint _amount) external;
  function borrow(address _token, uint _amount) external;
  function repay(address _token, uint _amount) external;
  function withdrawRepay(address _token, uint _amount) external;
  function withdrawBorrow(address _token, uint _amount) external;
  function controller() external view returns(IController);

  function swapTokenToToken(
    address  _fromToken,
    address  _toToken,
    address  _recipient,
    uint     _inputAmount,
    uint     _minOutput,
    uint     _deadline
  ) external returns(uint);
}

interface ILendingPairCallee {
  function flashSwapCall(address _recipient, uint _amountA, uint _amountB, bytes calldata _data) external;
}

interface IController {
  function interestRateModel() external view returns(IInterestRateModel);
  function feeRecipient() external view returns(address);
  function priceDelay() external view returns(uint);
  function slowPricePeriod() external view returns(uint);
  function slowPriceRange() external view returns(uint);
  function liqMinHealth() external view returns(uint);
  function liqFeePool() external view returns(uint);
  function liqFeeSystem() external view returns(uint);
  function liqFeeCaller() external view returns(uint);
  function liqFeesTotal() external view returns(uint);
  function depositLimit(address _lendingPair, address _token) external view returns(uint);
}

interface IInterestRateModel {
  function systemRate(ILendingPair _pair) external view returns(uint);
  function supplyRate(ILendingPair _pair, address _token) external view returns(uint);
  function borrowRate(ILendingPair _pair, address _token) external view returns(uint);
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

contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), owner);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

contract ERC20 is Ownable {

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

  mapping (address => uint) public balanceOf;
  mapping (address => mapping (address => uint)) public allowance;

  string public name;
  string public symbol;
  uint8 public decimals;
  uint public totalSupply;

  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    require(decimals > 0, "decimals");
  }

  function transfer(address _recipient, uint _amount) public returns (bool) {
    _transfer(msg.sender, _recipient, _amount);
    return true;
  }

  function approve(address _spender, uint _amount) public returns (bool) {
    _approve(msg.sender, _spender, _amount);
    return true;
  }

  function transferFrom(address _sender, address _recipient, uint _amount) public returns (bool) {
    require(allowance[_sender][msg.sender] >= _amount, "ERC20: insufficient approval");
    _transfer(_sender, _recipient, _amount);
    _approve(_sender, msg.sender, allowance[_sender][msg.sender] - _amount);
    return true;
  }

  function _transfer(address _sender, address _recipient, uint _amount) internal {
    require(_sender != address(0), "ERC20: transfer from the zero address");
    require(_recipient != address(0), "ERC20: transfer to the zero address");
    require(balanceOf[_sender] >= _amount, "ERC20: insufficient funds");

    balanceOf[_sender] -= _amount;
    balanceOf[_recipient] += _amount;
    emit Transfer(_sender, _recipient, _amount);
  }

  function mint(address _account, uint _amount) public onlyOwner {
    _mint(_account, _amount);
  }

  function burn(address _account, uint _amount) public onlyOwner {
    _burn(_account, _amount);
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

interface IWETH {
  function deposit() external payable;
  function withdraw(uint wad) external;
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
  function approve(address spender, uint amount) external returns (bool);
}

contract TransferHelper {

  // Mainnet
  IWETH internal constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  // Ropsten
  // IWETH internal constant WETH = IWETH(0xc778417E063141139Fce010982780140Aa0cD5Ab);

  function _safeTransferFrom(address _token, address _sender, uint _amount) internal returns(uint) {
    IERC20(_token).transferFrom(_sender, address(this), _amount);
    require(_amount > 0, "TransferHelper: amount must be > 0");
  }

  function _wethWithdrawTo(address _to, uint _amount) internal {
    require(_amount > 0, "TransferHelper: amount must be > 0");
    WETH.withdraw(_amount);
    (bool success, ) = _to.call { value: _amount }(new bytes(0));
    require(success, 'TransferHelper: ETH transfer failed');
  }
}

contract LendingPair is ReentrancyGuard, TransferHelper {

  // Prevents division by zero and other nasty stuff
  uint public constant MIN_RESERVE = 1000;

  using Address for address;
  using Clones for address;

  mapping (address => mapping (address => uint)) public debtOf;
  mapping (address => mapping (address => uint)) public accountInterestSnapshot;
  mapping (address => uint) public cumulativeInterestRate; // 1e18 = 1%
  mapping (address => uint) public totalDebt;
  mapping (address => uint) public storedSwapReserve;
  mapping (address => uint) public swapTime;
  mapping (address => uint) public storedLendingReserve;
  mapping (address => uint) public lendingTime;
  mapping (address => IERC20) public lpToken;

  IController public controller;
  address public tokenA;
  address public tokenB;
  uint public lastTimeAccrued;

  event Swap(
    address indexed fromToken,
    address indexed toToken,
    address indexed recipient,
    uint inputAmount,
    uint outputAmount
  );

  event FlashSwap(
    address indexed recipient,
    uint amountA,
    uint amountB
  );

  event Liquidation(
    address indexed account,
    uint supplyBurnA,
    uint supplyBurnB,
    uint borrowBurnA,
    uint borrowBurnB
  );

  event Deposit(address indexed token, uint amount);
  event Withdraw(address indexed token, uint amount);
  event Borrow(address indexed token, uint amount);
  event Repay(address indexed token, uint amount);

  receive() external payable {}

  function initialize(
    address _lpTokenMaster,
    address _controller,
    IERC20 _tokenA,
    IERC20 _tokenB
  ) public {
    require(address(tokenA) == address(0), "LendingPair: already initialized");
    require(address(_tokenA) != address(0) && address(_tokenB) != address(0), "LendingPair: cannot be ZERO address");

    controller = IController(_controller);
    tokenA = address(_tokenA);
    tokenB = address(_tokenB);
    lastTimeAccrued = block.timestamp;
    cumulativeInterestRate[tokenA] = 1e18;
    cumulativeInterestRate[tokenB] = 1e18;

    lpToken[tokenA] = _createLpToken(_lpTokenMaster);
    lpToken[tokenB] = _createLpToken(_lpTokenMaster);
  }

  function depositRepay(address _token, uint _amount) public {
    _depositRepay(_token, _amount);
    IERC20(_token).transferFrom(msg.sender, address(this), _amount);
  }

  function depositRepayETH() public payable {
    _depositRepay(address(WETH), msg.value);
    WETH.deposit { value: msg.value }();
  }

  function withdrawBorrow(address _token, uint _amount) public {
    _withdrawBorrow(_token, _amount);
    _safeTransfer(IERC20(_token), msg.sender, _amount);
  }

  function withdrawBorrowETH(uint _amount) public {
    _withdrawBorrow(address(WETH), _amount);
    _wethWithdrawTo(msg.sender, _amount);
    _checkMinReserve(IERC20(address(WETH)));
  }

  function deposit(address _token, uint _amount) public {
    accrueAccount(msg.sender);
    _deposit(_token, _amount);
    _safeTransferFrom(_token, msg.sender, _amount);
  }

  function withdrawAll(address _token) public {
    accrueAccount(msg.sender);
    uint amount = lpToken[address(_token)].balanceOf(msg.sender);
    _withdraw(_token, amount);
    _safeTransfer(IERC20(_token), msg.sender, amount);
  }

  function withdraw(address _token, uint _amount) public {
    accrueAccount(msg.sender);
    _withdraw(_token, _amount);
    _safeTransfer(IERC20(_token), msg.sender, _amount);
  }

  function borrow(address _token, uint _amount) public {
    accrueAccount(msg.sender);
    _borrow(_token, _amount);
    _safeTransfer(IERC20(_token), msg.sender, _amount);
  }

  function repayAll(address _token) public {
    accrueAccount(msg.sender);
    uint amount = debtOf[_token][msg.sender];
    _repay(_token, amount);
    _safeTransferFrom(_token, msg.sender, amount);
  }

  function repay(address _token, uint _amount) public {
    accrueAccount(msg.sender);
    _repay(_token, _amount);
    _safeTransferFrom(_token, msg.sender, _amount);
  }

  function flashSwap(
    address _recipient,
    uint _amountA,
    uint _amountB,
    bytes calldata _data
  ) public nonReentrant {

    _delayLendingPrice(tokenA);
    _delayLendingPrice(tokenB);

    require(_amountA > 0 || _amountB > 0, 'LendingPair: insufficient input amounts');

    uint balanceA = IERC20(tokenA).balanceOf(address(this));
    uint balanceB = IERC20(tokenB).balanceOf(address(this));

    if (_amountA > 0) _safeTransfer(IERC20(tokenA), _recipient, _amountA);
    if (_amountB > 0) _safeTransfer(IERC20(tokenB), _recipient, _amountB);
    ILendingPairCallee(_recipient).flashSwapCall(msg.sender, _amountA, _amountB, _data);

    uint adjustedBalanceA = balanceA + _amountA * 3 / 1000;
    uint adjustedBalanceB = balanceB + _amountB * 3 / 1000;
    uint expectedK = adjustedBalanceA * adjustedBalanceB;

    _earnSwapInterest(tokenA, _amountA);
    _earnSwapInterest(tokenB, _amountB);

    require(_k() >= expectedK, "LendingPair: insufficient return amount");

    emit FlashSwap(_recipient, _amountA, _amountB);
  }

  function swapETHToToken(
    address  _toToken,
    address  _recipient,
    uint     _minOutput,
    uint     _deadline
  ) public payable nonReentrant returns(uint) {

    uint outputAmount = _swap(address(WETH), _toToken, _recipient, msg.value, _minOutput, _deadline);
    WETH.deposit { value: msg.value }();
    _safeTransfer(IERC20(_toToken), _recipient, outputAmount);

    return outputAmount;
  }

  function swapTokenToETH(
    address  _fromToken,
    address  _recipient,
    uint     _inputAmount,
    uint     _minOutput,
    uint     _deadline
  ) public nonReentrant returns(uint) {

    uint outputAmount = _swap(_fromToken, address(WETH), _recipient, _inputAmount, _minOutput, _deadline);
    _safeTransferFrom(_fromToken, msg.sender, _inputAmount);
    _wethWithdrawTo(_recipient, outputAmount);
    _checkMinReserve(IERC20(address(WETH)));

    return outputAmount;
  }

  function swapTokenToToken(
    address  _fromToken,
    address  _toToken,
    address  _recipient,
    uint     _inputAmount,
    uint     _minOutput,
    uint     _deadline
  ) public nonReentrant returns(uint) {

    uint outputAmount = _swap(_fromToken, _toToken, _recipient, _inputAmount, _minOutput, _deadline);
    _safeTransferFrom(_fromToken, msg.sender, _inputAmount);
    _safeTransfer(IERC20(_toToken), _recipient, outputAmount);

    return outputAmount;
  }

  function accrue() public {
    _accrueInterest(tokenA);
    _accrueInterest(tokenB);
    lastTimeAccrued = block.timestamp;
  }

  function accrueAccount(address _account) public {
    accrue();
    _accrueAccount(_account);
  }

  function accountHealth(address _account) public view returns(uint) {
    uint totalAccountSupply  = supplyBalance(_account, tokenA, tokenA) + supplyBalance(_account, tokenB, tokenA);
    uint totalAccountBorrrow = borrowBalance(_account, tokenA, tokenA) + borrowBalance(_account, tokenB, tokenA);

    if (totalAccountBorrrow == 0) {
      return controller.liqMinHealth();
    } else {
      return totalAccountSupply * 1e18 / totalAccountBorrrow;
    }
  }

  // Get borow balance converted to the units of _returnToken
  function borrowBalance(
    address _account,
    address _borrowedToken,
    address _returnToken
  ) public view returns(uint) {
    return convertTokenValues(_borrowedToken, _returnToken, debtOf[_borrowedToken][_account]);
  }

  // Get supply balance converted to the units of _returnToken
  function supplyBalance(
    address _account,
    address _suppliedToken,
    address _returnToken
  ) public view returns(uint) {
    return convertTokenValues(_suppliedToken, _returnToken, lpToken[_suppliedToken].balanceOf(_account));
  }

  // Get the value of _fromToken in the units of _toToken without slippage or fees
  function convertTokenValues(
    address _fromToken,
    address _toToken,
    uint    _inputAmount
  ) public view returns(uint) {

    uint inputReserve  = lendingReserve(_fromToken);
    uint outputReserve = lendingReserve(_toToken);
    require(inputReserve > 0 && outputReserve > 0, "LendingPair: invalid reserve balances");

    return _inputAmount * 1e18 * outputReserve / inputReserve / 1e18;
  }

  function getExpectedOutput(
    address  _fromToken,
    address  _toToken,
    uint     _inputAmount
  ) public view returns(uint) {

    uint inputReserve  = swapReserve(_fromToken);
    uint outputReserve = swapReserve(_toToken);

    require(inputReserve > 0 && outputReserve > 0, "LendingPair: invalid reserve balances");

    uint inputAmountWithFee = _inputAmount * 997;
    uint numerator = inputAmountWithFee * outputReserve;
    uint denominator = inputReserve * 1000 + inputAmountWithFee;
    uint output = numerator / denominator;
    uint maxOutput = IERC20(_toToken).balanceOf(address(this)) - MIN_RESERVE;

    return output > maxOutput ? maxOutput : output;
  }

  function supplyRate(address _token) public view returns(uint) {
    return controller.interestRateModel().supplyRate(ILendingPair(address(this)), _token);
  }

  function borrowRate(address _token) public view returns(uint) {
    return controller.interestRateModel().borrowRate(ILendingPair(address(this)), _token);
  }

  // Sell collateral to reduce debt and increase accountHealth
  function liquidateAccount(address _account) public {
    uint health = accountHealth(_account);
    require(health < controller.liqMinHealth(), "LendingPair: account health > liqMinHealth");

    (uint supplyBurnA, uint borrowBurnA) = _liquidateToken(_account, tokenA, tokenB);
    (uint supplyBurnB, uint borrowBurnB) = _liquidateToken(_account, tokenB, tokenA);

    emit Liquidation(_account, supplyBurnA, supplyBurnB, borrowBurnA, borrowBurnB);
  }

  function pendingSupplyInterest(address _token, address _account) public view returns(uint) {
    return _newInterest(lpToken[_token].balanceOf(_account), _token, _account);
  }

  function pendingBorrowInterest(address _token, address _account) public view returns(uint) {
    return _newInterest(debtOf[_token][_account], _token, _account);
  }

  // Used to calculate swap price
  function swapReserve(address _token) public view returns(uint) {
    return _reserve(_token, storedSwapReserve[_token], swapTime[_token]);
  }

  // Used to calculate liquidation price
  function lendingReserve(address _token) public view returns(uint) {
    return _reserve(_token, storedLendingReserve[_token], lendingTime[_token]);
  }

  function feeRecipient() public view returns(address) {
    return controller.feeRecipient();
  }

  function checkAccountHealth(address _account) public view  {
    uint health = accountHealth(_account);
    require(health >= controller.liqMinHealth(), "LendingPair: insufficient accountHealth");
  }

  function _reserve(address _token, uint _storedReserve, uint _vTime) internal view returns(uint) {
    uint realReserve = IERC20(_token).balanceOf(address(this));
    if (block.timestamp > (_vTime + controller.priceDelay())) { return realReserve; }

    uint timeElapsed = block.timestamp - _vTime;
    int diffAmount = (int(realReserve) - int(_storedReserve)) * int(_timeShare(timeElapsed)) / int(1e18);

    return uint(int(_storedReserve) + diffAmount);
  }

  function _swap(
    address  _fromToken,
    address  _toToken,
    address  _recipient,
    uint     _inputAmount,
    uint     _minOutput,
    uint     _deadline
  ) internal returns(uint) {

    _validateToken(_fromToken);
    _validateToken(_toToken);

    _delayLendingPrice(_fromToken);
    _delayLendingPrice(_toToken);

    uint outputReserve = IERC20(_toToken).balanceOf(address(this));
    uint outputAmount = getExpectedOutput(_fromToken, _toToken, _inputAmount);

    require(_deadline >= block.timestamp,  "LendingPair: _deadline <= block.timestamp");
    require(outputAmount >= _minOutput,    "LendingPair: outputAmount >= _minOutput");
    require(outputAmount <= outputReserve, "LendingPair: insufficient reserves");

    _earnSwapInterest(_toToken, outputAmount);

    emit Swap(_fromToken, _toToken, _recipient, _inputAmount, outputAmount);

    return outputAmount;
  }

  function _depositRepay(address _token, uint _amount) internal {

    accrueAccount(msg.sender);

    uint debt = debtOf[_token][msg.sender];
    uint repayAmount = debt > _amount ? _amount : debt;

    if (repayAmount > 0) {
      _repay(_token, repayAmount);
    }

    uint depositAmount = _amount - repayAmount;

    if (depositAmount > 0) {
      _deposit(_token, depositAmount);
    }
  }

  function _withdrawBorrow(address _token, uint _amount) internal {

    accrueAccount(msg.sender);
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

  function _earnSwapInterest(address _token, uint _amount) internal {
    uint earnedAmount = _amount * 3 / 1000;
    uint newInterest = earnedAmount * 1e18 / lpToken[_token].totalSupply();
    cumulativeInterestRate[_token] += newInterest;
  }

  function _mintDebt(address _token, address _account, uint _amount) internal {
    debtOf[_token][_account] += _amount;
    totalDebt[_token] += _amount;
  }

  function _burnDebt(address _token, address _account, uint _amount) internal {
    debtOf[_token][_account] -= _amount;
    totalDebt[_token] -= _amount;
  }

  function _delaySwapPrice(address _token) internal {
    storedSwapReserve[_token] = swapReserve(_token);
    swapTime[_token] = block.timestamp;
  }

  function _delayLendingPrice(address _token) internal {
    storedLendingReserve[_token] = lendingReserve(_token);
    lendingTime[_token] = block.timestamp;
  }

  function _liquidateToken(
    address _account,
    address _supplyToken,
    address _borrowToken
  ) internal returns(uint, uint) {

    uint accountSupply  = lpToken[_supplyToken].balanceOf(_account);
    uint accountDebt    = debtOf[_borrowToken][_account];
    uint supplyDebt     = convertTokenValues(_borrowToken, _supplyToken, accountDebt);
    uint supplyRequired = supplyDebt + supplyDebt * controller.liqFeesTotal() / 100e18;

    uint supplyBurn = supplyRequired > accountSupply ? accountSupply : supplyRequired;

    uint supplyBurnMinusFees = (supplyBurn * 100e18 / (100e18 + controller.liqFeesTotal()));
    uint systemFee = supplyBurnMinusFees * controller.liqFeeSystem() / 100e18;
    uint callerFee = supplyBurnMinusFees * controller.liqFeeCaller() / 100e18;

    lpToken[_supplyToken].burn(_account, supplyBurn);
    lpToken[_supplyToken].mint(feeRecipient(), systemFee);
    lpToken[_supplyToken].mint(msg.sender, callerFee);

    uint debtBurn = convertTokenValues(_supplyToken, _borrowToken, supplyBurnMinusFees);

    // Remove dust debt to allow full debt wipe
    if (debtBurn < accountDebt) {
      debtBurn = (accountDebt - debtBurn) < accountDebt / 10000 ? accountDebt : debtBurn;
    }

    _burnDebt(_borrowToken, _account, debtBurn);

    return (supplyBurn, debtBurn);
  }

  function _accrueAccount(address _account) internal {
    _accrueAccountSupply(tokenA, _account);
    _accrueAccountSupply(tokenB, _account);
    _accrueAccountDebt(tokenA, _account);
    _accrueAccountDebt(tokenB, _account);

    accountInterestSnapshot[tokenA][_account] = cumulativeInterestRate[tokenA];
    accountInterestSnapshot[tokenB][_account] = cumulativeInterestRate[tokenB];

    _accrueSystem(tokenA);
    _accrueSystem(tokenB);
  }

  // Accrue system interest from the total debt
  // Cannot use total supply since nobody may be supplying to that side (borrowing sold assets from another side)
  function _accrueSystem(address _token) internal {
    _ensureAccountInterestSnapshot(feeRecipient());
    uint systemInterest = _newInterest(totalDebt[_token], _token, feeRecipient());
    uint newSupply = systemInterest * _systemRate() / 100e18;
    lpToken[_token].mint(feeRecipient(), newSupply);
  }

  function _ensureAccountInterestSnapshot(address _account) internal {
    if (accountInterestSnapshot[tokenA][_account] == 0) {
      accountInterestSnapshot[tokenA][_account] = cumulativeInterestRate[tokenA];
    }

    if (accountInterestSnapshot[tokenB][_account] == 0) {
      accountInterestSnapshot[tokenB][_account] = cumulativeInterestRate[tokenB];
    }
  }

  function _accrueAccountSupply(address _token, address _account) internal {
    uint supplyInterest = pendingSupplyInterest(_token, _account);
    uint newSupply = supplyInterest * _systemRate() / 100e18;

    lpToken[_token].mint(_account, newSupply);
  }

  function _accrueAccountDebt(address _token, address _account) internal {
    uint newDebt = pendingBorrowInterest(_token, _account);
    _mintDebt(_token, _account, newDebt);
  }

  function _withdraw(address _token, uint _amount) internal {
    _validateToken(_token);

    _delaySwapPrice(_token);
    _delayLendingPrice(_token);

    lpToken[address(_token)].burn(msg.sender, _amount);

    checkAccountHealth(msg.sender);

    emit Withdraw(_token, _amount);
  }

  function _borrow(address _token, uint _amount) internal {
    _validateToken(_token);

    _delaySwapPrice(_token);
    _delayLendingPrice(_token);

    require(lpToken[address(_token)].balanceOf(msg.sender) == 0, "LendingPair: cannot borrow supplied token");

    _mintDebt(_token, msg.sender, _amount);

    checkAccountHealth(msg.sender);

    emit Borrow(_token, _amount);
  }

  function _repay(address _token, uint _amount) internal {
    _validateToken(_token);

    _delaySwapPrice(_token);
    _delayLendingPrice(_token);
    _burnDebt(_token, msg.sender, _amount);

    emit Repay(_token, _amount);
  }

  function _deposit(address _token, uint _amount) internal {
    _checkDepositLimit(_token, _amount);

    // Initialize on first deposit (pair creation).
    _initOrDelaySwapPrice(_token, _amount);
    _initOrDelayLendingPrice(_token, _amount);

    // Deposit is required to withdraw, borrow & repay so we only need to check this here.
    _ensureAccountInterestSnapshot(msg.sender);

    _validateToken(_token);
    require(debtOf[_token][msg.sender] == 0, "LendingPair: cannot deposit borrowed token");

    lpToken[address(_token)].mint(msg.sender, _amount);

    emit Deposit(_token, _amount);
  }

  function _accrueInterest(address _token) internal {
    uint timeElapsed = block.timestamp - lastTimeAccrued;
    uint newInterest = borrowRate(_token) / 365 days * timeElapsed;
    cumulativeInterestRate[_token] += newInterest;
  }

  function _initOrDelaySwapPrice(address _token, uint _amount) internal {
    if (storedSwapReserve[_token] == 0) {
      storedSwapReserve[_token] = _amount;
      swapTime[_token] = block.timestamp - controller.priceDelay();
    } else {
      _delaySwapPrice(_token);
    }
  }

  function _initOrDelayLendingPrice(address _token, uint _amount) internal {
    if (storedLendingReserve[_token] == 0) {
      storedLendingReserve[_token] = _amount;
      lendingTime[_token] = block.timestamp - controller.priceDelay();
    } else {
      _delayLendingPrice(_token);
    }
  }

  function _createLpToken(address _lpTokenMaster) internal returns(IERC20) {
    IERC20 newLPToken = IERC20(_lpTokenMaster.clone());
    newLPToken.initialize();
    return newLPToken;
  }

  function _timeShare(uint _timeElapsed) internal view returns(uint) {
    if (_timeElapsed > controller.slowPricePeriod()) {
      return _timeElapsed * 1e18 / controller.priceDelay();
    } else {
      return _timeElapsed * 1e18 / controller.slowPricePeriod() * controller.slowPriceRange() / 100e18;
    }
  }

  function _validateToken(address _token) internal view {
    require(_token == tokenA || _token == tokenB, "LendingPair: invalid token");
  }

  function _safeTransfer(IERC20 _token, address _recipient, uint _amount) internal {
    _token.transfer(_recipient, _amount);
    _checkMinReserve(_token);
  }

  function _checkMinReserve(IERC20 _token) internal view {
    require(_token.balanceOf(address(this)) >= MIN_RESERVE, "LendingPair: below MIN_RESERVE");
  }

  function _k() internal view returns(uint) {
    uint balanceA = IERC20(tokenA).balanceOf(address(this));
    uint balanceB = IERC20(tokenB).balanceOf(address(this));

    return balanceA * balanceB;
  }

  function _checkDepositLimit(address _token, uint _amount) internal view {
    uint depositLimit = controller.depositLimit(address(this), _token);

    if (depositLimit > 0) {
      require((lpToken[_token].totalSupply() + _amount) <= depositLimit, "LendingPair: deposit limit reached");
    }
  }

  function _systemRate() internal view returns(uint) {
    return controller.interestRateModel().systemRate(ILendingPair(address(this)));
  }

  function _newInterest(uint _balance, address _token, address _account) internal view returns(uint) {
    return _balance * (cumulativeInterestRate[_token] - accountInterestSnapshot[_token][_account]) / 1e18;
  }
}

contract InterestRateModel {

  uint private constant MIN_RATE  = 1e17;   // 0.1%
  uint private constant LOW_RATE  = 20e18;  // 20%
  uint private constant HIGH_RATE = 1000e18; // 1,000%

  uint private constant TARGET_UTILIZATION = 80e18; // 80%
  uint public constant  SYSTEM_RATE        = 50e18; // 50% - share of borrowRate earned by the system

  function supplyRate(ILendingPair _pair, address _token) public view returns(uint) {
    return borrowRate(_pair, _token) * SYSTEM_RATE / 100e18;
  }

  function borrowRate(ILendingPair _pair, address _token) public view returns(uint) {
    uint debt = _pair.totalDebt(_token);
    uint supply = IERC20(_pair.lpToken(_token)).totalSupply();

    if (supply == 0 || debt == 0) { return MIN_RATE; }

    uint utilization = _max(debt * 100e18 / supply, 100e18);

    if (utilization < TARGET_UTILIZATION) {
      uint rate = LOW_RATE * utilization / 100e18;
      return (rate < MIN_RATE) ? MIN_RATE : rate;
    } else {
      // (999 - (1000 * 0.8)) / (1000 * 0.2)
      utilization = 100e18 * ( debt - (supply * TARGET_UTILIZATION / 100e18) ) / (supply * (100e18 - TARGET_UTILIZATION) / 100e18);
      utilization = _max(utilization, 100e18);
      return LOW_RATE + (HIGH_RATE - LOW_RATE) * utilization / 100e18;
    }
  }

  function utilizationRate(ILendingPair _pair, address _token) public view returns(uint) {
    uint debt = _pair.totalDebt(_token);
    uint supply = IERC20(_pair.lpToken(_token)).totalSupply();

    if (supply == 0 || debt == 0) { return 0; }

    return _max(debt * 100e18 / supply, 100e18);
  }

  // InterestRateModel can later be replaced for more granular fees per _lendingPair
  function systemRate(ILendingPair _pair) public pure returns(uint) {
    return SYSTEM_RATE;
  }

  function _max(uint _valueA, uint _valueB) internal pure returns(uint) {
    return _valueA > _valueB ? _valueB : _valueA;
  }
}