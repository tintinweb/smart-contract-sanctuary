/**
 *Submitted for verification at polygonscan.com on 2021-07-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

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

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    function getOwner() external override view returns (address) {
        return owner();
    }

    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom (address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero'));
        return true;
    }

    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    function _transfer (address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve (address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance'));
    }
}

// FOX Token with Governance.
contract FOXToken is BEP20 {
    // Transfer tax rate in basis points. (default 10%)
    uint16 public transferTaxRate = 1000;
    // Burn rate % of transfer tax. (default 50% x 10% = 5% of total amount).
    uint16 public burnRate = 50;
    // Max transfer tax rate: 10%.
    uint16 public constant MAXIMUM_TRANSFER_TAX_RATE = 1000;
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Max transfer amount rate in basis points. (default is 0.5% of total supply)
    uint16 public maxTransferAmountRate = 50;
    // Addresses that excluded from antiWhale
    mapping(address => bool) private _excludedFromAntiWhale;
    // Automatic swap and liquify enabled
    bool public swapAndLiquifyEnabled = false;
    // Min amount to liquify. (default 500)
    uint256 public minAmountToLiquify = 500 ether;
    // The swap router, modifiable. Will be changed to other's router when our own AMM release
    IUniswapV2Router02 public swapRouter;
    // The trading pair
    address public swapPair;
    // In swap and liquify
    bool private _inSwapAndLiquify;

    // The operator can only update the transfer tax rate
    address private _operator;

    // Events
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event TransferTaxRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event BurnRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event MaxTransferAmountRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event SwapAndLiquifyEnabledUpdated(address indexed operator, bool enabled);
    event MinAmountToLiquifyUpdated(address indexed operator, uint256 previousAmount, uint256 newAmount);
    event SwapRouterUpdated(address indexed operator, address indexed router, address indexed pair);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    modifier antiWhale(address sender, address recipient, uint256 amount) {
        if (maxTransferAmount() > 0) {
            if (
                _excludedFromAntiWhale[sender] == false
                && _excludedFromAntiWhale[recipient] == false
            ) {
                require(amount <= maxTransferAmount(), "AntiWhale: Transfer amount exceeds the maxTransferAmount");
            }
        }
        _;
    }

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    modifier transferTaxFree {
        uint16 _transferTaxRate = transferTaxRate;
        transferTaxRate = 0;
        _;
        transferTaxRate = _transferTaxRate;
    }

    /**
     * @notice Constructs the of the contract.
     */
    constructor() public BEP20("Fox Token", "FOX") {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);

        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[BURN_ADDRESS] = true;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    /// @dev overrides transfer function to meet tokenomics
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiWhale(sender, recipient, amount) {
        // swap and liquify
        if (
            swapAndLiquifyEnabled == true
            && _inSwapAndLiquify == false
            && address(swapRouter) != address(0)
            && swapPair != address(0)
            && sender != swapPair
            && sender != owner()
        ) {
            swapAndLiquify();
        }

        if (recipient == BURN_ADDRESS || transferTaxRate == 0) {
            super._transfer(sender, recipient, amount);
        } else {
            // default tax is 10% of every transfer
            uint256 taxAmount = amount.mul(transferTaxRate).div(10000);
            uint256 burnAmount = taxAmount.mul(burnRate).div(100);
            uint256 liquidityAmount = taxAmount.sub(burnAmount);
            require(taxAmount == burnAmount + liquidityAmount, "ERROR::transfer: Burn value invalid");

            // default 90% of transfer sent to recipient
            uint256 sendAmount = amount.sub(taxAmount);
            require(amount == sendAmount + taxAmount, "ERROR::transfer: Tax value invalid");

            super._transfer(sender, BURN_ADDRESS, burnAmount);
            super._transfer(sender, address(this), liquidityAmount);
            super._transfer(sender, recipient, sendAmount);
            amount = sendAmount;
        }
    }

    /// @dev Burn by reduce total supply
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /// @dev BurnFrom by reduce total supply
    function burnFrom(address account, uint256 amount) public {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    /// @dev Swap and liquify
    function swapAndLiquify() private lockTheSwap transferTaxFree {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 maxTransferAmount = maxTransferAmount();
        contractTokenBalance = contractTokenBalance > maxTransferAmount ? maxTransferAmount : contractTokenBalance;

        if (contractTokenBalance >= minAmountToLiquify) {
            // only min amount to liquify
            uint256 liquifyAmount = minAmountToLiquify;

            // split the liquify amount into halves
            uint256 half = liquifyAmount.div(2);
            uint256 otherHalf = liquifyAmount.sub(half);

            // capture the contract's current ETH balance.
            // this is so that we can capture exactly the amount of ETH that the
            // swap creates, and not make the liquidity event include any ETH that
            // has been manually sent to the contract
            uint256 initialBalance = address(this).balance;

            // swap tokens for ETH
            swapTokensForEth(half);

            // how much ETH did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);

            // add liquidity
            addLiquidity(otherHalf, newBalance);

            emit SwapAndLiquify(half, newBalance, otherHalf);
        }
    }

    /// @dev Swap tokens for eth
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the swap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        _approve(address(this), address(swapRouter), tokenAmount);

        // make the swap
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    /// @dev Add liquidity
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(swapRouter), tokenAmount);

        // add the liquidity
        swapRouter.addLiquidityETH{value: ethAmount}(
    address(this),
    tokenAmount,
    0, // slippage is unavoidable
    0, // slippage is unavoidable
    operator(),
    block.timestamp
    );
    }

    /**
     * @dev Returns the max transfer amount.
     */
    function maxTransferAmount() public view returns (uint256) {
        return totalSupply().mul(maxTransferAmountRate).div(10000);
    }

    /**
     * @dev Returns the address is excluded from antiWhale or not.
     */
    function isExcludedFromAntiWhale(address _account) public view returns (bool) {
        return _excludedFromAntiWhale[_account];
    }

// To receive BNB from swapRouter when swapping
receive() external payable {}

/**
 * @dev Update the transfer tax rate.
 * Can only be called by the current operator.
 */
function updateTransferTaxRate(uint16 _transferTaxRate) public onlyOperator {
require(_transferTaxRate <= MAXIMUM_TRANSFER_TAX_RATE, "ERROR::updateTransferTaxRate: Transfer tax rate must not exceed the maximum rate.");
emit TransferTaxRateUpdated(msg.sender, transferTaxRate, _transferTaxRate);
transferTaxRate = _transferTaxRate;
}

/**
 * @dev Update the burn rate.
 * Can only be called by the current operator.
 */
function updateBurnRate(uint16 _burnRate) public onlyOperator {
require(_burnRate <= 100, "ERROR::updateBurnRate: Burn rate must not exceed the maximum rate.");
emit BurnRateUpdated(msg.sender, burnRate, _burnRate);
burnRate = _burnRate;
}

/**
 * @dev Update the max transfer amount rate.
 * Can only be called by the current operator.
 */
function updateMaxTransferAmountRate(uint16 _maxTransferAmountRate) public onlyOperator {
require(_maxTransferAmountRate <= 10000, "ERROR::updateMaxTransferAmountRate: Max transfer amount rate must not exceed the maximum rate.");
emit MaxTransferAmountRateUpdated(msg.sender, maxTransferAmountRate, _maxTransferAmountRate);
maxTransferAmountRate = _maxTransferAmountRate;
}

/**
 * @dev Update the min amount to liquify.
 * Can only be called by the current operator.
 */
function updateMinAmountToLiquify(uint256 _minAmount) public onlyOperator {
emit MinAmountToLiquifyUpdated(msg.sender, minAmountToLiquify, _minAmount);
minAmountToLiquify = _minAmount;
}

/**
 * @dev Exclude or include an address from antiWhale.
 * Can only be called by the current operator.
 */
function setExcludedFromAntiWhale(address _account, bool _excluded) public onlyOperator {
_excludedFromAntiWhale[_account] = _excluded;
}

/**
 * @dev Update the swapAndLiquifyEnabled.
 * Can only be called by the current operator.
 */
function updateSwapAndLiquifyEnabled(bool _enabled) public onlyOperator {
emit SwapAndLiquifyEnabledUpdated(msg.sender, _enabled);
swapAndLiquifyEnabled = _enabled;
}

/**
 * @dev Update the swap router.
 * Can only be called by the current operator.
 */
function updateSwapRouter(address _router) public onlyOperator {
swapRouter = IUniswapV2Router02(_router);
swapPair = IUniswapV2Factory(swapRouter.factory()).getPair(address(this), swapRouter.WETH());
require(swapPair != address(0), "ERROR::updateSwapRouter: Invalid pair address.");
emit SwapRouterUpdated(msg.sender, address(swapRouter), swapPair);
}

/**
 * @dev Returns the address of the current operator.
 */
function operator() public view returns (address) {
return _operator;
}

/**
 * @dev Transfers operator of the contract to a new account (`newOperator`).
 * Can only be called by the current operator.
 */
function transferOperator(address newOperator) public onlyOperator {
require(newOperator != address(0), "ERROR::transferOperator: new operator is the zero address");
emit OperatorTransferred(_operator, newOperator);
_operator = newOperator;
}
// Copied and modified from YAM code:
// https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
// https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
// Which is copied and modified from COMPOUND:
// https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

/// @dev A record of each accounts delegate
mapping (address => address) internal _delegates;

/// @notice A checkpoint for marking number of votes from a given block
struct Checkpoint {
uint32 fromBlock;
uint256 votes;
}

/// @notice A record of votes checkpoints for each account, by index
mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

/// @notice The number of checkpoints for each account
mapping (address => uint32) public numCheckpoints;

/// @notice The EIP-712 typehash for the contract's domain
bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

/// @notice The EIP-712 typehash for the delegation struct used by the contract
bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

/// @notice A record of states for signing / validating signatures
mapping (address => uint) public nonces;

/// @notice An event thats emitted when an account changes its delegate
event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

/// @notice An event thats emitted when a delegate account's vote balance changes
event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

/**
 * @notice Delegate votes from `msg.sender` to `delegatee`
 * @param delegator The address to get delegatee for
 */
function delegates(address delegator)
external
view
returns (address)
{
return _delegates[delegator];
}

/**
 * @notice Delegate votes from `msg.sender` to `delegatee`
 * @param delegatee The address to delegate votes to
 */
function delegate(address delegatee) external {
return _delegate(msg.sender, delegatee);
}

/**
 * @notice Delegates votes from signatory to `delegatee`
 * @param delegatee The address to delegate votes to
 * @param nonce The contract state required to match the signature
 * @param expiry The time at which to expire the signature
 * @param v The recovery byte of the signature
 * @param r Half of the ECDSA signature pair
 * @param s Half of the ECDSA signature pair
 */
function delegateBySig(
address delegatee,
uint nonce,
uint expiry,
uint8 v,
bytes32 r,
bytes32 s
)
external
{
bytes32 domainSeparator = keccak256(
abi.encode(
DOMAIN_TYPEHASH,
keccak256(bytes(name())),
getChainId(),
address(this)
)
);

bytes32 structHash = keccak256(
abi.encode(
DELEGATION_TYPEHASH,
delegatee,
nonce,
expiry
)
);

bytes32 digest = keccak256(
abi.encodePacked(
"\x19\x01",
domainSeparator,
structHash
)
);

address signatory = ecrecover(digest, v, r, s);
require(signatory != address(0), "Error::delegateBySig: invalid signature");
require(nonce == nonces[signatory]++, "Error::delegateBySig: invalid nonce");
require(now <= expiry, "Error::delegateBySig: signature expired");
return _delegate(signatory, delegatee);
}

/**
 * @notice Gets the current votes balance for `account`
 * @param account The address to get votes balance
 * @return The number of current votes for `account`
 */
function getCurrentVotes(address account)
external
view
returns (uint256)
{
uint32 nCheckpoints = numCheckpoints[account];
return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
}

/**
 * @notice Determine the prior number of votes for an account as of a block number
 * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
 * @param account The address of the account to check
 * @param blockNumber The block number to get the vote balance at
 * @return The number of votes the account had as of the given block
 */
function getPriorVotes(address account, uint blockNumber)
external
view
returns (uint256)
{
require(blockNumber < block.number, "Error::getPriorVotes: not yet determined");

uint32 nCheckpoints = numCheckpoints[account];
if (nCheckpoints == 0) {
return 0;
}

// First check most recent balance
if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
return checkpoints[account][nCheckpoints - 1].votes;
}

// Next check implicit zero balance
if (checkpoints[account][0].fromBlock > blockNumber) {
return 0;
}

uint32 lower = 0;
uint32 upper = nCheckpoints - 1;
while (upper > lower) {
uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
Checkpoint memory cp = checkpoints[account][center];
if (cp.fromBlock == blockNumber) {
return cp.votes;
} else if (cp.fromBlock < blockNumber) {
lower = center;
} else {
upper = center - 1;
}
}
return checkpoints[account][lower].votes;
}

function _delegate(address delegator, address delegatee)
internal
{
address currentDelegate = _delegates[delegator];
uint256 delegatorBalance = balanceOf(delegator); // balance of underlying token (not scaled);
_delegates[delegator] = delegatee;

emit DelegateChanged(delegator, currentDelegate, delegatee);

_moveDelegates(currentDelegate, delegatee, delegatorBalance);
}

function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
if (srcRep != dstRep && amount > 0) {
if (srcRep != address(0)) {
// decrease old representative
uint32 srcRepNum = numCheckpoints[srcRep];
uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
uint256 srcRepNew = srcRepOld.sub(amount);
_writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
}

if (dstRep != address(0)) {
// increase new representative
uint32 dstRepNum = numCheckpoints[dstRep];
uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
uint256 dstRepNew = dstRepOld.add(amount);
_writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
}
}
}

function _writeCheckpoint(
address delegatee,
uint32 nCheckpoints,
uint256 oldVotes,
uint256 newVotes
)
internal
{
uint32 blockNumber = safe32(block.number, "Error::_writeCheckpoint: block number exceeds 32 bits");

if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
} else {
checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
numCheckpoints[delegatee] = nCheckpoints + 1;
}

emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
}

function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
require(n < 2**32, errorMessage);
return uint32(n);
}

function getChainId() internal pure returns (uint) {
uint256 chainId;
assembly { chainId := chainid() }
return chainId;
}
}

abstract contract ReentrancyGuard {
uint256 private constant _NOT_ENTERED = 1;
uint256 private constant _ENTERED = 2;

uint256 private _status;

constructor () internal {
_status = _NOT_ENTERED;
}

modifier nonReentrant() {
// On the first call to nonReentrant, _notEntered will be true
require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

// Any calls to nonReentrant after this point will fail
_status = _ENTERED;

_;

// By storing the original value once again, a refund is triggered (see
// https://eips.ethereum.org/EIPS/eip-2200)
_status = _NOT_ENTERED;
}
}

interface IFoxReferral {
/**
 * @dev Record referral.
 */
function recordReferral(address user, address referrer) external;

/**
 * @dev Record referral commission.
 */
function recordReferralCommission(address referrer, uint256 commission) external;

/**
 * @dev Get the referrer address that referred the user.
 */
function getReferrer(address user) external view returns (address);
}



// MasterChef is the master of FOX. He can make FOX and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once FOX is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable, ReentrancyGuard {
using SafeMath for uint256;
using SafeBEP20 for IBEP20;

// Info of each user.
struct UserInfo {
uint256 amount;         // How many LP tokens the user has provided.
uint256 rewardDebt;     // Reward debt. See explanation below.
uint256 rewardLockedUp;  // Reward locked up.
uint256 nextHarvestUntil; // When can the user harvest again.
//
// We do some fancy math here. Basically, any point in time, the amount of FOX
// entitled to a user but is pending to be distributed is:
//
//   pending reward = (user.amount * pool.accFoxPerShare) - user.rewardDebt
//
// Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
//   1. The pool's `accFoxPerShare` (and `lastRewardBlock`) gets updated.
//   2. User receives the pending reward sent to his/her address.
//   3. User's `amount` gets updated.
//   4. User's `rewardDebt` gets updated.
}

// Info of each pool.
struct PoolInfo {
IBEP20 lpToken;           // Address of LP token contract.
uint256 allocPoint;       // How many allocation points assigned to this pool. FOX to distribute per block.
uint256 lastRewardBlock;  // Last block number that token distribution occurs.
uint256 accFoxPerShare;   // Accumulated fox per share, times 1e12. See below.
uint16 depositFeeBP;      // Deposit fee in basis points
uint256 harvestInterval;  // Harvest interval in seconds
uint256 totalToken;       // Total tokens in this pool
uint256 minDeposit;       // Minimum native token required to use this pool
}

// The new FOX token!
FOXToken public fox;
// Dev address.
address public devAddress;
// FOXs created per block.
uint256 public foxPerBlock;
// Bonus multiplier for early token makers.
uint256 public constant BONUS_MULTIPLIER = 1;
// Deposit Fee address
address public feeAddress;
// Max harvest interval: 14 days.
uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;
// Max deposit fee: 10%
uint256 public constant MAXIMUM_DEPOSIT_FEE = 1000;
// Max minDeposit FOX in wallet to use each pool: 1000 FOX
uint256 public constant MAXIMUM_MIN_DEPOSIT_FEE = 1000 ether;

// Info of each pool.
PoolInfo[] public poolInfo;
// Info of each user that stakes LP tokens.
mapping (uint256 => mapping (address => UserInfo)) public userInfo;
// Total allocation points. Must be the sum of all allocation points in all pools.
uint256 public totalAllocPoint = 0;
// The block number when FOX mining starts.
uint256 public startBlock;
// Total locked up rewards
uint256 public totalLockedUpRewards;

// FOX referral contract address.
IFoxReferral public foxReferral;
// Referral commission rate in basis points, default 3%.
uint16 public referralCommissionRate = 300;
// Max referral commission rate: 10%.
uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 1000;
// Max emission rate: 1000 FOX/block
uint256 public constant MAX_TOKEN_PER_BLOCK = 1000 * 10 ** 18;

// Pool Exists Mapper
mapping(IBEP20 => bool) public poolExistence;

event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);
event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);

constructor(
FOXToken _fox,
address _devAddress,
address _feeAddress,
uint256 _foxPerBlock,
uint256 _startBlock
) public {
fox = _fox;
devAddress = _devAddress;
feeAddress = _feeAddress;
foxPerBlock = _foxPerBlock;
startBlock = _startBlock;
}

function poolLength() external view returns (uint256) {
return poolInfo.length;
}

// Add a new lp to the pool. Can only be called by the owner.
// XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, uint256 _harvestInterval, uint256 _minDeposit, bool _withUpdate)
public onlyOwner {
require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE, "add: invalid deposit fee basis points");
require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "add: invalid harvest interval");
require(_minDeposit <= MAXIMUM_MIN_DEPOSIT_FEE, "add: invalid Min Deposit amount");
if (_withUpdate) {
massUpdatePools();
}
uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
totalAllocPoint = totalAllocPoint.add(_allocPoint);
poolExistence[_lpToken] = true;

poolInfo.push(PoolInfo({
lpToken: _lpToken,
allocPoint: _allocPoint,
lastRewardBlock: lastRewardBlock,
accFoxPerShare: 0,
depositFeeBP: _depositFeeBP,
harvestInterval: _harvestInterval,
minDeposit: _minDeposit,
totalToken : 0
}));
}

// Update the given pool's token allocation point and deposit fee. Can only be called by the owner.
function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, uint256 _harvestInterval, uint256 _minDeposit, bool _withUpdate)
public onlyOwner {
require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE, "set: invalid deposit fee basis points");
require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "set: invalid harvest interval");
require(_minDeposit <= MAXIMUM_MIN_DEPOSIT_FEE, "add: invalid Min Deposit amount");
if (_withUpdate) {
massUpdatePools();
}
totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
poolInfo[_pid].allocPoint = _allocPoint;
poolInfo[_pid].depositFeeBP = _depositFeeBP;
poolInfo[_pid].harvestInterval = _harvestInterval;
poolInfo[_pid].minDeposit = _minDeposit;
}

// Return reward multiplier over the given _from to _to block.
function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
return _to.sub(_from).mul(BONUS_MULTIPLIER);
}

// View function to see pending fox on frontend.
function pendingFox(uint256 _pid, address _user) external view returns (uint256) {
PoolInfo storage pool = poolInfo[_pid];
UserInfo storage user = userInfo[_pid][_user];
uint256 accFoxPerShare = pool.accFoxPerShare;
uint256 lpSupply = pool.totalToken;

if (block.number > pool.lastRewardBlock && lpSupply != 0) {
uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
uint256 foxReward = multiplier.mul(foxPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
accFoxPerShare = accFoxPerShare.add(foxReward.mul(1e12).div(lpSupply));
}

uint256 pending = user.amount.mul(accFoxPerShare).div(1e12).sub(user.rewardDebt);
return pending.add(user.rewardLockedUp);
}

// View function to see if user can harvest tokens.
function canHarvest(uint256 _pid, address _user) public view returns (bool) {
UserInfo storage user = userInfo[_pid][_user];
return block.timestamp >= user.nextHarvestUntil;
}

// Update reward variables for all pools.
function massUpdatePools() public {
uint256 length = poolInfo.length;
uint256 totalReward = 0;

for (uint256 pid = 0; pid < length; ++pid) {
PoolInfo storage pool = poolInfo[pid];
if (block.number <= pool.lastRewardBlock) {
continue;
}

if (pool.totalToken == 0 || pool.allocPoint == 0) {
pool.lastRewardBlock = block.number;
continue;
}

uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
uint256 foxReward = multiplier.mul(foxPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

pool.accFoxPerShare = pool.accFoxPerShare.add(foxReward.mul(1e12).div(pool.totalToken));
pool.lastRewardBlock = block.number;
totalReward.add(foxReward);
}

if(totalReward > 0){
fox.mint(devAddress, totalReward.div(10));
fox.mint(address(this), totalReward);
}
}

// Update reward variables of the given pool to be up-to-date.
function updatePool(uint256 _pid) public {
PoolInfo storage pool = poolInfo[_pid];
if (block.number <= pool.lastRewardBlock) {
return;
}

if (pool.totalToken == 0 || pool.allocPoint == 0) {
pool.lastRewardBlock = block.number;
return;
}
uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
uint256 foxReward = multiplier.mul(foxPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

pool.accFoxPerShare = pool.accFoxPerShare.add(foxReward.mul(1e12).div(pool.totalToken));
pool.lastRewardBlock = block.number;

fox.mint(devAddress, foxReward.div(10));
fox.mint(address(this), foxReward);
}

// Deposit LP tokens to MasterChef for token allocation.
function deposit(uint256 _pid, uint256 _amount, address _referrer) public nonReentrant {
PoolInfo storage pool = poolInfo[_pid];
UserInfo storage user = userInfo[_pid][msg.sender];

require(fox.balanceOf(msg.sender) >= pool.minDeposit, "Not enough native tokens to use this pool!");

updatePool(_pid);
if (_amount > 0 && address(foxReferral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
foxReferral.recordReferral(msg.sender, _referrer);
}
payOrLockupPendingFox(_pid);

if(_amount > 0) {
uint256 beforeDeposit = pool.lpToken.balanceOf(address(this));
pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
uint256 afterDeposit = pool.lpToken.balanceOf(address(this));

// Calculate the correct amount when user deposit
_amount = afterDeposit.sub(beforeDeposit);

if(pool.depositFeeBP > 0){
uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
pool.lpToken.safeTransfer(feeAddress, depositFee);
user.amount = user.amount.add(_amount).sub(depositFee);
pool.totalToken = pool.totalToken.add(_amount).sub(depositFee);
}else{
user.amount = user.amount.add(_amount);
pool.totalToken = pool.totalToken.add(_amount);
}
}
user.rewardDebt = user.amount.mul(pool.accFoxPerShare).div(1e12);
emit Deposit(msg.sender, _pid, _amount);
}

// Withdraw LP tokens from MasterChef.
function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
PoolInfo storage pool = poolInfo[_pid];
UserInfo storage user = userInfo[_pid][msg.sender];

require(pool.totalToken >= _amount, "Withdraw: Pool total tokens not enough");
require(user.amount >= _amount, "withdraw: not good");

updatePool(_pid);

payOrLockupPendingFox(_pid);
if(_amount > 0) {
user.amount = user.amount.sub(_amount);
pool.totalToken = pool.totalToken.sub(_amount);
pool.lpToken.safeTransfer(address(msg.sender), _amount);
}
user.rewardDebt = user.amount.mul(pool.accFoxPerShare).div(1e12);
emit Withdraw(msg.sender, _pid, _amount);
}

// Withdraw without caring about rewards. EMERGENCY ONLY.
function emergencyWithdraw(uint256 _pid) public nonReentrant {
PoolInfo storage pool = poolInfo[_pid];
UserInfo storage user = userInfo[_pid][msg.sender];
uint256 amount = user.amount;

require(pool.totalToken >= amount, "EmergencyWithdraw: Pool total tokens not enough");

user.amount = 0;
user.rewardDebt = 0;
user.rewardLockedUp = 0;
user.nextHarvestUntil = 0;
pool.totalToken = pool.totalToken.sub(amount);
pool.lpToken.safeTransfer(address(msg.sender), amount);
emit EmergencyWithdraw(msg.sender, _pid, amount);
}

// Pay or lockup pending FOX.
function payOrLockupPendingFox(uint256 _pid) internal {
PoolInfo storage pool = poolInfo[_pid];
UserInfo storage user = userInfo[_pid][msg.sender];

if (user.nextHarvestUntil == 0) {
user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
}

uint256 pending = user.amount.mul(pool.accFoxPerShare).div(1e12).sub(user.rewardDebt);
if (canHarvest(_pid, msg.sender)) {
if (pending > 0 || user.rewardLockedUp > 0) {
uint256 totalRewards = pending.add(user.rewardLockedUp);

// reset lockup
totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp);
user.rewardLockedUp = 0;
user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);

// send rewards
safeFoxTransfer(msg.sender, totalRewards);
payReferralCommission(msg.sender, totalRewards);
}
} else if (pending > 0) {
user.rewardLockedUp = user.rewardLockedUp.add(pending);
totalLockedUpRewards = totalLockedUpRewards.add(pending);
emit RewardLockedUp(msg.sender, _pid, pending);
}
}

// Safe FOX transfer function, just in case if rounding error causes pool to not have enough FOX.
function safeFoxTransfer(address _to, uint256 _amount) internal {
uint256 foxBal = fox.balanceOf(address(this));
if (_amount > foxBal) {
fox.transfer(_to, foxBal);
} else {
fox.transfer(_to, _amount);
}
}

// Update dev address by the previous dev.
function setDevAddress(address _devAddress) public {
require(msg.sender == devAddress, "setDevAddress: FORBIDDEN");
require(_devAddress != address(0), "setDevAddress: ZERO");
devAddress = _devAddress;
}

function setFeeAddress(address _feeAddress) public{
require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
require(_feeAddress != address(0), "setFeeAddress: ZERO");
feeAddress = _feeAddress;
}

//Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
function updateEmissionRate(uint256 _foxPerBlock) public onlyOwner {
require(_foxPerBlock <= MAX_TOKEN_PER_BLOCK, "FOX per block too high");
massUpdatePools();
emit EmissionRateUpdated(msg.sender, foxPerBlock, _foxPerBlock);
foxPerBlock = _foxPerBlock;
}

function updateAllocPoint(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
if (_withUpdate) {
massUpdatePools();
}

totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
poolInfo[_pid].allocPoint = _allocPoint;
}

// Update the fox referral contract address by the owner
function setFoxReferral(IFoxReferral _foxReferral) public onlyOwner {
foxReferral = _foxReferral;
}

// Update referral commission rate by the owner
function setReferralCommissionRate(uint16 _referralCommissionRate) public onlyOwner {
require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "setReferralCommissionRate: invalid referral commission rate basis points");
referralCommissionRate = _referralCommissionRate;
}

// Pay referral commission to the referrer who referred this user.
function payReferralCommission(address _user, uint256 _pending) internal {
if (address(foxReferral) != address(0) && referralCommissionRate > 0) {
address referrer = foxReferral.getReferrer(_user);
uint256 commissionAmount = _pending.mul(referralCommissionRate).div(10000);

if (referrer != address(0) && commissionAmount > 0) {
fox.mint(referrer, commissionAmount);
foxReferral.recordReferralCommission(referrer, commissionAmount);
emit ReferralCommissionPaid(_user, referrer, commissionAmount);
}
}
}
}