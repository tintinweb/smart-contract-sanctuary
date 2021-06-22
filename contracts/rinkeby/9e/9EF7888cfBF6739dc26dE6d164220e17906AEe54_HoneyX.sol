/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

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

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

contract HoneyX is Ownable, IERC20, IERC20Metadata {
    using Address for address;

    uint256 private _swapFee;
    uint256 private _liquidityFee;
    uint256 private _maxTransferAmount;
    bool private _tokenIsInitialized;
    bool private _devIsInitialized;
    uint8 private _devIsInitialized2;

    mapping(address => uint256) private _holders;
    mapping(uint256 => address) private _holdersPosition;
    uint256 private _lastHoldersPosition = 0;

    IUniswapV2Router02 _uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private _pairAddress;

    mapping(address => uint8) private _devPosition;
    mapping(uint8 => address) private _dev;
    mapping(uint8 => uint256) private _totalAmountClaimAbleByDevPosition;
    mapping(uint8 => uint256[2][]) private _claimableAmountForDevByPosition;
    uint8 private _maxDev = 7;
    uint256 private _amountLeft7;
    uint256 private _amountLeft;

    uint256 private _airdropTotal;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    string private _name = "HoneyX";
    string private _symbol = "HONEYX";

    constructor() {
        _mint(address(this), 100000000000 * 10**decimals());
        _tokenIsInitialized = false;
        _setSwapFee(5);
        _setLiquidityFee(5);

        // Create a uniswap pair for this new token
        _pairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        _devIsInitialized = false;
        _tokenIsInitialized = false;
    }

    function _init1() public onlyOwner {
        require(!_tokenIsInitialized, "you can only initialize once");

        _airdropTotal = (_totalSupply * 400) / 10000;

        IERC20(this).transfer(
            0xD1257dd8e2b87338f1618BF04Bba37a1C477cC78, //caztcoin team
            (_totalSupply * 50) / 10000
        );

        IERC20(this).transfer(
            0x0b967f76D15aBf9Fd32f584c905E96Ac38eE69Fd, // marketing
            (_totalSupply * 400) / 10000
        );
        IERC20(this).transfer(
            0x7379F33676A47F3C1DB2aA16C0fd5c89D255826d, // product development
            (_totalSupply * 400) / 10000
        );
        IERC20(this).transfer(
            0x6520a4bEB513B96f9b2081874BC777229AeA0A5b, // liquidity
            (_totalSupply * 7500) / 10000
        );

        uint256 totalAmountClaimableByDev = (_totalSupply * 200) / 10000;
        uint256 amountSentFirst = (totalAmountClaimableByDev * 1000) / 10000;
        _amountLeft = totalAmountClaimableByDev - amountSentFirst;

        address[6] memory devAddresses =
            [
                0xD1257dd8e2b87338f1618BF04Bba37a1C477cC78,
                //0x8e2712263E10e42aB862e35fB55dBB0756078F18,
                0x2D570751c74D6367B79F97934AA4eDFAf83ebEa9,
                0x75e521Ed7A25f1432CA0a4BB6dE6Bfd6af40954A,
                0x8E78C3659758f287118A29D72049BD128e122548,
                0xd8d875805a4d0A06eFFCBcCb573c28fAA56DD53B,
                0xBe2A4C9b224DBc8730e06FEC727a1709d1641bdB
            ];

        for (uint8 i = 0; i < devAddresses.length; i++) {
            uint8 position = i + 1;
            _dev[position] = devAddresses[i];
            _devPosition[devAddresses[i]] = position;
            _totalAmountClaimAbleByDevPosition[
                position
            ] = totalAmountClaimableByDev;
            IERC20(this).transfer(devAddresses[i], amountSentFirst);
        }

        uint256 totalAmountClaimableByDev7 = (_totalSupply * 50) / 10000;
        uint256 amountSentFirst7 = (totalAmountClaimableByDev7 * 1000) / 10000;
        _amountLeft7 = totalAmountClaimableByDev7 - amountSentFirst7;
        _dev[7] = 0x3439439F4Cc4F96106688Cb98aca45C4ad3f4C0C;
        _devPosition[0x3439439F4Cc4F96106688Cb98aca45C4ad3f4C0C] = 7;
        _totalAmountClaimAbleByDevPosition[7] = totalAmountClaimableByDev7;
        IERC20(this).transfer(
            0x3439439F4Cc4F96106688Cb98aca45C4ad3f4C0C,
            amountSentFirst7
        );

        _devIsInitialized2 = 1;
        _devIsInitialized = true;

        uint256 timestamp = 300;
        uint256 amountForEachTwoWeeks = _amountLeft / 24;
        for (uint8 i = 1; i <= 24; i++) {
            _claimableAmountForDevByPosition[7].push(
                [block.timestamp + timestamp, amountForEachTwoWeeks]
            );

            timestamp = timestamp + timestamp;
        }

        _tokenIsInitialized = true;
        _init2();
        _devIsInitialized2 = 1;
    }

    function _init2() internal onlyOwner {
        require(_devIsInitialized2 == 1, "_devInit must be called first");
        uint256 timestamp7 = 300;
        uint256 amountForEachTwoWeeks7 = _amountLeft7 / 24;
        for (uint8 a = 1; a <= 6; a++) {
            for (uint8 i = 1; i <= 24; i++) {
                _claimableAmountForDevByPosition[a].push(
                    [block.timestamp + timestamp7, amountForEachTwoWeeks7]
                );

                timestamp7 = timestamp7 + timestamp7;
            }
        }
        _devIsInitialized2 = 2;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {_approve(sender, _msgSender(), currentAllowance - amount);}

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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

        if (sender != address(this)) {
            require(
                amount < _maxTransferAmount,
                "Max transfer amount is exceeded"
            );
        }

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {_balances[sender] = senderBalance - amount;}

        if (!recipient.isContract()) {
            _setHolder(recipient);
        }
        uint256 recipientAmount = amount;
        if (sender == _pairAddress) {
            uint256 amountToHolders = (amount * _swapFee) / 1000;
            uint256 amountToLiquidity = (amount * _liquidityFee) / 1000;
            _sendTaxToHolders(amountToHolders, sender);
            _sendTaxToLiquidity(amountToLiquidity);

            recipientAmount =
                recipientAmount -
                (amountToHolders + amountToLiquidity);
        }

        _balances[recipient] += recipientAmount;

        emit Transfer(sender, recipient, recipientAmount);
    }

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

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function standard_transfer(address recipient, uint256 amount)
        internal
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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

    function _sendTaxToHolders(uint256 amount, address from) private {
        for (uint256 i = 1; i <= _lastHoldersPosition; i++) {
            if (_holdersPosition[i] != from) {
                _transfer(
                    from,
                    _holdersPosition[i],
                    amount / _lastHoldersPosition
                );
            }
        }
    }

    function _sendTaxToLiquidity(uint256 amount) private {
        uint256 amountToken = amount / 2;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToken,
            0,
            path,
            address(this),
            block.timestamp + 500
        );

        _approve(address(this), address(_uniswapV2Router), amount);
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            amountToken,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp + 500
        );
    }

    function setSwapFee(uint256 fee) public onlyOwner {
        require(fee > 0, "must not be 0");
        _setSwapFee(fee);
    }

    function setLiquidityFee(uint256 fee) public onlyOwner {
        require(fee > 0, "must not be 0");
        _setLiquidityFee(fee);
    }

    function getTotalHolders() public view returns (uint256) {
        return _lastHoldersPosition;
    }

    function setMaxTransferAmount(uint256 percent) public onlyOwner {
        require(percent > 0, "must not be 0");
        _setMaxTransferAmount(percent);
    }

    function _setMaxTransferAmount(uint256 percent) private {
        _maxTransferAmount = (totalSupply() * percent**2) / 10000;
    }

    function _setSwapFee(uint256 fee) private {
        _swapFee = fee;
    }

    function _setLiquidityFee(uint256 fee) private {
        _liquidityFee = fee;
    }

    function _setHolder(address holder) private {
        if (!_isHolder(holder)) {
            _holders[holder] = _lastHoldersPosition + 1;
            _holdersPosition[_lastHoldersPosition + 1] = holder;
            _lastHoldersPosition++;
        }
    }

    function _isHolder(address holder) internal view returns (bool) {
        return _holders[holder] > 0;
    }

    function claimTokenForDev() public {
        uint8 yourPosition = _devPosition[_msgSender()];
        require(yourPosition > 0, "You cannot claim the token !");
        uint256 amountClaimable = _amountClaimable(yourPosition);
        require(amountClaimable > 0, "0 claimable amount");
        IERC20(this).transfer(_msgSender(), amountClaimable);
    }

    function getClaimableTokenAmountInDetails(address devAddress)
        public
        view
        returns (uint256[2][] memory)
    {
        return _claimableAmountForDevByPosition[_devPosition[devAddress]];
    }

    function getClaimableTokenAmount(address devAddress)
        public
        view
        returns (uint256)
    {
        uint8 devPosition = _devPosition[devAddress];
        require(devPosition > 0, "You cannot claim the token !");
        uint256 amount = 0;
        for (
            uint8 i = 0;
            i < _claimableAmountForDevByPosition[devPosition].length;
            i++
        ) {
            if (
                 block.timestamp >=
                 _claimableAmountForDevByPosition[devPosition][i][0]
            ) {
                amount += _claimableAmountForDevByPosition[devPosition][i][1];
            }
        }
        return amount;
    }

    function _amountClaimable(uint8 devPosition) private returns (uint256) {
        uint256 amount = 0;
        for (
            uint8 i = 1;
            i < _claimableAmountForDevByPosition[devPosition].length;
            i++
        ) {
            if (
                 block.timestamp >=
                _claimableAmountForDevByPosition[devPosition][i][0]
               
            ) {
                amount += _claimableAmountForDevByPosition[devPosition][i][1];
                _claimableAmountForDevByPosition[devPosition][i][0] = 0;
            }
        }
        return amount;
    }

    function replaceDev(address previousAddress, address newDevAddress)
        public
        onlyOwner
    {
        require(
            _devPosition[previousAddress] > 0,
            "Dev not exist or already removed"
        );
        require(
            _devPosition[newDevAddress] == 0,
            "Dev address is already exist"
        );
        uint8 lastDevPosition = _devPosition[previousAddress];
        _dev[lastDevPosition] = newDevAddress;
        _devPosition[newDevAddress] = lastDevPosition;
    }

    function airdrop(
        address[] memory airdropAddresses,
        uint256[] memory amounts
    ) public onlyOwner {
        for (uint256 i = 0; i <= airdropAddresses.length; i++) {
            IERC20(this).transfer(airdropAddresses[i], amounts[i]);
        }
    }

    function swapFee() public view returns (uint256) {
        return _swapFee;
    }

    function liquidityFee() public view returns (uint256) {
        return _liquidityFee;
    }

    function airdropTotal() public view returns (uint256) {
        return _airdropTotal;
    }

    function getDevPosition(address devAddress) public view returns (uint8) {
        return _devPosition[devAddress];
    }
}