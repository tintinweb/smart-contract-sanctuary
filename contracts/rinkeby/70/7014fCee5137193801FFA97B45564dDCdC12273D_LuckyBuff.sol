// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual { }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @notice ERC20 token with cost basis tracking and restricted loss-taking
 */
contract LuckyBuff is ERC20, Ownable {
    using SafeMath for uint256;

    string public override name = "NewBuff (NewBuff V1)";
    string public override symbol = "NB V1";

    address private constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address private constant OLD_BUFF = 0x0d64196b24986f04a2586082ea3a7A1C864bd9Fe;

    uint256 private constant SUPPLY = 1e9 ether;
    uint256 private _initialBasis;
    uint256 private _feeStore;
    uint256 private mintedSupply;
    uint256 private _affiliateUsualFee = 3;
    uint256 private _holderUsualFee = 3;
    uint256 private _holderPenaltyFee = 7;
    uint256 private _affiliatePenaltyFee = 7;
    uint256 private _rewardWalletPenaltyFee = 7;
    uint256 private _maxTeamMintAmount = 1e8 ether;
    uint256 private _currentLiquidity;
    uint256 private _openAt;
    uint256 private _closeAt;
    uint256 private _ath;
    uint256 private _athTimestamp;

    address private _shoppingCart;
    address private _rewardWallet;
    address private _pair;

    bool private _paused;

    struct LockedAddress {
        uint64 lockedPeriod;
        uint64 endTime;
    }
    
    struct Minting {
        address recipient;
        uint amount;
    }

    mapping(address => uint256) private _basisOf;
    mapping(address => uint256) public cooldownOf;
    mapping(address => uint256) private _buyTime;
    mapping(address => bool) private _oldBuffRwardAddress;
    mapping(address => LockedAddress) private _lockedList;


    event RequestNewCoinWithOldBuffDoge(
        address indexed requestAddress,
        uint256 requestAmount
    );
    event RequestHolderReward(
        address indexed requestAddress,
        uint256 requestAmount,
        uint256 share
    );

    /**
     * @notice deploy
     */
    constructor() {
        // setup uniswap pair and store address

        _pair = IUniswapV2Factory(IUniswapV2Router02(UNISWAP_ROUTER).factory())
            .createPair(WETH, address(this));
        _mint(address(this), SUPPLY);

        // prepare to add liquidity
        _approve(address(this), UNISWAP_ROUTER, SUPPLY);
        _approve(_pair, UNISWAP_ROUTER, SUPPLY);
        _approve(address(this), owner(), SUPPLY);

        // prepare to remove liquidity
        IERC20(_pair).approve(UNISWAP_ROUTER, type(uint256).max);

        _paused = true;
    }

    /**
     * @dev modifier for mint or burn limit
     */
    modifier isNotPaused() {
        require(_paused == false, "ERR: paused already");
        _;
    }

    receive() external payable {}

    /**
     * @notice get cost basis for given address
     * @param account address to query
     * @return cost basis
     */
    function basisOf(address account) public view returns (uint256) {
        uint256 basis = _basisOf[account];

        if (basis == 0 && balanceOf(account) > 0) {
            basis = _initialBasis;
        }

        return basis;
    }

    /**
     * @notice mint token by owner
     * @param mintAddress minting address
     * @param mintAmount minting amount
     */
    function mint(address mintAddress, uint256 mintAmount) external onlyOwner isNotPaused {
        require(mintAddress != address(0), "ERR: zero address");
        require(mintAmount > 0, "ERR: zero amount");
        _mint(mintAddress, mintAmount);
    }

    /**
     * @notice burn token by owner
     * @param burnAddress burn address
     * @param burnAmount burn amount
     */
    function burn(address burnAddress, uint256 burnAmount) external onlyOwner isNotPaused {
        require(burnAddress != address(0), "ERR: zero address");
        require(burnAmount > 0, "ERR: zero amount");
        _burn(burnAddress, burnAmount);
    }

    /**
     * @dev mint according to the amount of old coin holder has when he/she requires only one time
     * @param _oldBuffWallet wallet address with old buff
     */
    function requestNewCoinWithOldBuff(address _oldBuffWallet, address referralWallet) external {
        require(_oldBuffWallet != address(0));
        require(
            msg.sender == _oldBuffWallet,
            "ERR: msg sender must be old buff address"
        );
        require(
            _oldBuffRwardAddress[_oldBuffWallet] != true,
            "ERR: Address rewarded already"
        );
        uint256 oldBuffBalance = IERC20(OLD_BUFF).balanceOf(_oldBuffWallet);
        require(oldBuffBalance > 0, "EFF: zero old BUFF balance");
        require(
            oldBuffBalance < _totalSupply,
            "EFF: old BUFF balance exceed total supply"
        );
        if(referralWallet != address(0)) {
            uint affiliateAmount = oldBuffBalance.mul(5).div(100);
            _mint(_oldBuffWallet, oldBuffBalance.sub(affiliateAmount));
            _mint(referralWallet, affiliateAmount);
        }
        else {
            _mint(_oldBuffWallet, oldBuffBalance);
        }

        _burn(address(this), oldBuffBalance);
        _lockAddress(_oldBuffWallet, uint64(5 minutes));

        _oldBuffRwardAddress[_oldBuffWallet] = true;
        emit RequestNewCoinWithOldBuffDoge(_oldBuffWallet, oldBuffBalance);
    }

    function requestHolderReward(address holderAddress) external returns (bool) {
        require(holderAddress != address(0), "ERR: zero holder address");
        require(balanceOf(holderAddress) > 0, "ERR: zero balance");
        uint256 balance = balanceOf(holderAddress);
        uint256 share = balance.div(_totalSupply);
        uint256 rewardAmount = _feeStore.mul(share);
        if(holderAddress != owner() && holderAddress != _shoppingCart && holderAddress != _rewardWallet) {
            require(_lockedList[holderAddress].endTime < uint64(block.timestamp), "ERR: locked address");
        }
        _burn(address(this), rewardAmount);
        _mint(holderAddress, rewardAmount);
        emit RequestHolderReward(holderAddress, rewardAmount, share);
        return true;
    }

    /**
    * @notice open trading
    * @dev sender must be owner
    * @dev trading must not yet have been opened
    */
    function addLiquidity (uint liquidityAmount) external onlyOwner isNotPaused {
        require(_openAt == 0, 'ERR: already opened');
        uint ethBalance = address(this).balance;
        require(ethBalance > 0, 'ERR: zero ETH balance');

        // add liquidity, set initial cost basis
        uint limitAmount = 5e8 ether;
        require(limitAmount >= _currentLiquidity.add(liquidityAmount), "ERR: liquidity amount must be less than 500,000,000");

        _initialBasis = ((1 ether) * ethBalance / liquidityAmount);

        (uint amountToken, , ) = IUniswapV2Router02(
            UNISWAP_ROUTER
        ).addLiquidityETH{
            value: address(this).balance
        }(
            address(this),
            liquidityAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
        _currentLiquidity = _currentLiquidity.add(amountToken);
        _openAt = block.timestamp;
        _closeAt = 0;
    }

      /**
   * @notice close trading
   * @dev trading must not yet have been closed
   * @dev minimum time since open must have elapsed
   */
    function removeLiquidity () external onlyOwner isNotPaused {
        require(_openAt > 0, 'ERR: not yet opened');
        require(_closeAt == 0, 'ERR: already closed');
        require(block.timestamp > _openAt + (1 days), 'ERR: too soon');

        require(
            block.timestamp > _athTimestamp + (1 weeks),
            'ERR: recent ATH'
        );

        IUniswapV2Router02(
        UNISWAP_ROUTER
        ).removeLiquidityETH(
        address(this),
        IERC20(_pair).balanceOf(address(this)),
        0,
        0,
        address(this),
        block.timestamp
        );

        _closeAt = block.timestamp;
    }


    /**
     *@notice set Shopping cart address to transfer
     *with wallet for the servcie in project
     *@param cartAddress address for shopping service
     */
    function setShoppingCart(address cartAddress) external onlyOwner returns (bool) {
        require(cartAddress != address(0), "ERR: zero address");
        _shoppingCart = cartAddress;
        _mint(cartAddress, (5e7 ether));
        _burn(address(this), (5e7 ether));
        return true;
    }

    /**
     *@notice set reward wallet address
     *@param rewardAddress address for shopping service
     */
    function setRewardAddress(address rewardAddress) external onlyOwner returns (bool) {
        require(rewardAddress != address(0), "ERR: zero address");
        _rewardWallet = rewardAddress;
        uint256 burnAmount = 35 * 1e5 ether;
        _mint(rewardAddress, burnAmount);
        _burn(address(this), burnAmount);
        _approve(rewardAddress, owner(), burnAmount);
        return true;
    }
    
    /**
     *@notice set team wallet address
     *@param mintings team wallet address and amount
     */
    function mintDev(Minting[] calldata mintings) external onlyOwner returns (bool) {
        require(mintings.length > 0, "ERR: zero address array");
        
        for(uint i = 0; i < mintings.length; i++) {
            Minting memory m = mintings[i];
            uint amount = m.amount;
            address recipient = m.recipient;

            mintedSupply += amount;
            require(mintedSupply <= _maxTeamMintAmount, "ERR: exceed max team mint amount");
            _balances[recipient] += amount;
            _balances[address(this)] -= amount;
            _lockAddress(recipient, uint64(180 seconds));
        }
        
        return true;
    }    
    
    function setHolderUsualFee(uint256 _fee) external onlyOwner returns (bool) {
        _holderUsualFee = _fee;
        return true;
    }

    function setHolderPenaltyFee(uint256 _fee) external onlyOwner returns (bool) {
        _holderPenaltyFee = _fee;
        return true;
    }

    function setAffiliateUsualFee(uint256 _fee) external onlyOwner returns (bool) {
        _affiliateUsualFee = _fee;
        return true;
    }

    function setAffiliatePenaltyFee(uint256 _fee) external onlyOwner returns (bool) {
        _affiliatePenaltyFee = _fee;
        return true;
    }
    
    function setRewardPenaltyFee(uint256 _fee) external onlyOwner returns (bool) {
        _rewardWalletPenaltyFee = _fee;
        return true;
    }


    function pausedEnable() external onlyOwner returns (bool) {
        require(_paused == false, "ERR: already pause enabled");
        _paused = true;
        return true;
    }

    function pausedNotEnable() external onlyOwner returns (bool) {
        require(_paused == true, "ERR: already pause disabled");
        _paused = false;
        return true;
    }

    function checkPairAddress()
        external
        view
        returns (address, address)
    {
        address tokenPair = IUniswapV2Factory(IUniswapV2Router02(UNISWAP_ROUTER).factory()).getPair(WETH, address(this));
        return (_pair, tokenPair);
    }

    function checkETHBalance(address payable checkAddress) external view returns (uint) {
        require(checkAddress != address(0), "ERR: check address must not be zero");
        uint balance = checkAddress.balance;
        return balance;
    }

    function checkLockTime(address lockedAddress) external view returns (uint64, uint64) {
        return (_lockedList[lockedAddress].lockedPeriod, _lockedList[lockedAddress].endTime);
    }

    function checkHolderRewardAmount(address holderAddress) external view returns (uint256, uint256, uint256) {
        require(holderAddress != address(0), "ERR: zero holder address");
        require(balanceOf(holderAddress) > 0, "ERR: zero balance");
        uint balance = balanceOf(holderAddress);
        uint256 share = balance.div(_totalSupply);
        uint rewardAmount = _feeStore.mul(share);
        return (rewardAmount, share, _feeStore);
    }

    function checkTotalLiquidity() external onlyOwner view returns (uint256) {
        return _currentLiquidity;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        // ignore minting and burning
        if (from == address(0) || to == address(0)) return;

        // ignore add/remove liquidity
        if (from == address(this) || to == address(this)) return;
        if (from == UNISWAP_ROUTER || to == UNISWAP_ROUTER) return;

        require(
            msg.sender == UNISWAP_ROUTER ||
            msg.sender == _pair || msg.sender == owner() ||
            from == _shoppingCart ||
            to == _shoppingCart ||
            from == _rewardWallet ||
            to == _rewardWallet,
            "ERR: sender must be uniswap or shoppingCart"
        );

        address[] memory path = new address[](2);

        if (from == _pair && to != _shoppingCart) {
            require(_lockedList[to].endTime < uint64(block.timestamp), "ERR: address is locked(buy)");

            require(
                cooldownOf[to] < block.timestamp /* revert message not returned by Uniswap */
            );
            cooldownOf[to] = block.timestamp + (5 minutes);

            path[0] = WETH;
            path[1] = address(this);

            uint256[] memory amounts =
                IUniswapV2Router02(UNISWAP_ROUTER).getAmountsIn(amount, path);

            uint256 balance = balanceOf(to);
            uint256 fromBasis = ((1 ether) * amounts[0]) / amount;
            _basisOf[to] =
                (fromBasis * amount + basisOf(to) * balance) /
                (amount + balance);

            if (fromBasis > _ath) {
                _ath = fromBasis;
                _athTimestamp = block.timestamp;
            }
        } else if (to == _pair && from != _shoppingCart) {
            require(_lockedList[from].endTime < uint64(block.timestamp), "ERR: address is locked(sales)");
            
            // blacklist Vitalik Buterin
            require(
                from != 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B /* revert message not returned by Uniswap */
            );
            require(
                cooldownOf[from] < block.timestamp /* revert message not returned by Uniswap */
            );
            cooldownOf[from] = block.timestamp + (5 minutes);            
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        super._transfer(sender, recipient, amount);
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _transferWithFee(sender, recipient, amount);

        emit Transfer(sender, recipient, amount);
    }

    function _transferWithFee(
        address sender, address recipient, uint256 amount
    ) private returns (bool) {
        if (
            sender != _shoppingCart &&
            recipient != _shoppingCart && 
            sender != address(this) && recipient != address(this)
        ) {
            uint liquidityBalance = balanceOf(_pair);
            require(amount <= liquidityBalance.div(100), "ERR: Exceed the 1% of current liquidity balance");
        }
        if(sender != _shoppingCart && recipient != _shoppingCart &&
            sender != owner() && recipient != owner() &&
            sender != _rewardWallet && recipient != _rewardWallet &&
            sender != address(this) && recipient != address(this)) {
            if(sender == _pair) {
                uint holderFee = amount.mul(_holderUsualFee).div(100);
                uint affiliateFee = amount.mul(_affiliateUsualFee).div(100);
                uint256 senderBalance = _balances[sender];
                require(senderBalance >= amount, "ERC20: transfer amount exceeds balance(buy)");
                _balances[sender] = senderBalance - amount;
                uint amountWithFee = amount.sub(holderFee).sub(affiliateFee);
                _balances[address(this)] += holderFee;
                _feeStore += holderFee;
                _balances[_shoppingCart] += affiliateFee;
                _balances[recipient] += amountWithFee;
            }
            if(recipient == _pair) {
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = WETH;
                uint[] memory amounts = IUniswapV2Router02(UNISWAP_ROUTER).getAmountsOut(
                    amount,
                    path
                );

                if (basisOf(sender) <= (1 ether) * amounts[1] / amount) {
                    uint holderFee = amount.mul(_holderUsualFee).div(100);
                    uint affiliateFee = amount.mul(_affiliateUsualFee).div(100);
                    uint amountWithFee = amount.add(holderFee).add(affiliateFee);
                    uint256 senderBalance = _balances[sender];
                    require(senderBalance >= amountWithFee, "ERC20: transfer amount exceeds balance(sales-1)");
                    _balances[sender] = senderBalance - amountWithFee;
                    _balances[address(this)] += holderFee;
                    _feeStore += holderFee;
                    _balances[_shoppingCart] += affiliateFee;
                    _balances[recipient] += amount;
                }
                else {
                    uint holderPenaltyFee = amount.mul(_holderPenaltyFee).div(100);
                    uint affiliatePenaltyFee = amount.mul(_affiliatePenaltyFee).div(100);
                    uint marketPenaltyFee = amount.mul(_rewardWalletPenaltyFee).div(100);                
                    uint256 senderBalance = _balances[sender];
                    uint amountWithFee = amount.add(holderPenaltyFee).add(affiliatePenaltyFee).add(marketPenaltyFee);
                    require(senderBalance >= amountWithFee, "ERC20: transfer amount exceeds balance(sales-2)");
                    _balances[sender] = senderBalance - amountWithFee;
                    _balances[address(this)] += holderPenaltyFee;
                    _feeStore += holderPenaltyFee;
                    _balances[_shoppingCart] += marketPenaltyFee;
                    _balances[_rewardWallet] += affiliatePenaltyFee;
                    _balances[recipient] += amount;
                }
            }
        }
        else {
            uint256 senderBalance = _balances[sender];
            require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
            _balances[sender] = senderBalance - amount;
            _balances[recipient] += amount;
        }
        return true;
    }

    /**
     * @dev lock special address for some times
     * @param lockAddress address to lock
     * @param lockTime lock period
     */
    function _lockAddress(address lockAddress, uint64 lockTime) internal {
        require(lockAddress != address(0), "ERR: zero lock address");
        require(lockTime > 0, "ERR: zero lock period");
        require(_lockedList[lockAddress].endTime == 0, "ERR: already locked");
        if (lockAddress != _pair && lockAddress != UNISWAP_ROUTER &&
            lockAddress != _shoppingCart && lockAddress != address(this) &&
            lockAddress != owner()) {
            _lockedList[lockAddress].lockedPeriod = lockTime;
            _lockedList[lockAddress].endTime = uint64(block.timestamp) + lockTime;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

