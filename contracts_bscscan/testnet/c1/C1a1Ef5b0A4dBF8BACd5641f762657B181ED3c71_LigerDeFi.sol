/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

/*********************************************************************************
 *   #-----------------------LIGER-DEFI-TOKENOMICS---------------------------#   *
 *   #                                                                       #   *
 *   #   5% fee auto add to the liquidity pool when selling                  #   *
 *   #   4% fee auto distribute to all holders as staking reward             #   *
 *   #   1% fee auto transfer to treasury vault for maintainance             #   *
 *   #   total 10% fee to be collect after holder transfer or swap           #   *
 *   #   LIGER token will deflate itself in supply with every transaction    #   *
 *   #   50% Supply is burned at start after Liquidity Lock.                 #   *
 *   #                                                                       #   *
 *   #-----------------------------------------------------------------------#   *
 *   #             #-----------TOKEN-DISTRIBUTION-----------#                #   *
 *   #             #   TOTAL SUPPLY - 100,000,000,000,000   #                #   *
 *   #             # 50%    - Burn Address (Burn Forever)   #                #   *
 *   #             # 35%    - Liquidity Pool (Locked)       #                #   *
 *   #             # 5%     - Features Project (Locked)     #                #   *
 *   #             # 5%     - Development Team (locked)     #                #   *
 *   #             # 5%     - Marketing/Airdrop             #                #   *
 *   #             #----------------------------------------#                #   *
 *   #-----------------------------------------------------------------------#   *
 ********************************************************************************/

// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

interface ILigerBEP20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function totalBurn() external view returns (uint256);

    function estimateHolders() external view returns (uint256);

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
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
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


            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

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

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

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
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(now > _lockTime, "Contract is locked until end of locktime");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface ILigerFactory {
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

interface ILigerPair {
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

interface ILigerRouter {
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

contract LigerDeFi is Context, ILigerBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rBalance;
    mapping(address => uint256) private _tBalance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => bool) private _isExcludedFromMaxHold;
    mapping(address => bool) private _isExcludedEventFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    mapping(address => bool) private accHolders;
    address[] private allHolders;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000 * 10**9 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    string private _name = "Liger DeFi";
    string private _symbol = "LIGER";
    uint8 private _decimals = 18;

    uint8 public HolderReward = 4;
    uint8 private _previousHolderReward = HolderReward;
    uint8 public LiquidityFee = 5;
    uint8 private _previousLiquidityFee = LiquidityFee;
    uint8 public TreasuryFee = 1;
    uint8 private _previousTreasuryFee = TreasuryFee;
    address public TreasuryManager;
    address public LiquidityManager;

    address public BusdAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public BurnAddress = 0x000000000000000000000000000000000000dEaD;

    ILigerRouter public LigerRouter;
    address public LigerPairWBNB;
    address public LigerPairBUSD;
    address private checkLigerPairWBNB;
    address private checkLigerPairBUSD;

    bool inSwapAndLiquify;
    //enable / disable locking `liquidityFee` to DEX
    bool public SwapAndLiquifyEnabled = true;
    bool private _enableAllFee = true;
    bool TreasuryFeeEnable = true;
    bool private FeeOnEvent;

    uint8 private LiquidityFeeEvent;
    uint8 private RewardFeeEvent;
    uint8 private TreasuryFeeEvent;
    uint32 private DeadlineEvent;
    event DiscountFeeEvent(
        bool FeeOnEvent,
        uint8 LiquidityFeeEvent,
        uint8 RewardFeeEvent,
        uint8 TreasuryFeeEvent,
        uint32 DeadlineEvent
    );

    // max amount of tokens that can be transferred per transaction
    uint256 public MaxTxAmount = 50 * 10**9 * 10**18;
    // max amount of token holder can hold per account
    uint256 public MaxHoldAmount = 50 * 10**9 * 10**18;
    // minimum number of tokens in this contract to sent to DEX pool
    uint256 private numTokensSellToAddToLiquidity = 20 * 10**9 * 10**18;

    event Holders(uint256 CurrentHolders);
    event TreasuryFeeTransfer(
        address indexed sender,
        address indexed TreasuryManager,
        uint256 TreasuryFeeAmount
    );
    event UpdateDEXAddress(
        address indexed LigerRouter,
        address indexed LigerPairWBNB,
        address indexed LigerPairBUSD
    );
    event SwapAndLiquifyEnabledUpdated(bool Enabled);
    event SwapAndLiquify(
        uint256 TokensSwapped,
        uint256 BNBReceived,
        uint256 TokensIntoLiquidity
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(
        address DEXaddress,
        address TreasuryVault,
        address LiquidityVault
    ) public {
        _rBalance[_msgSender()] = _rTotal;

        ILigerRouter _LigerRouter = ILigerRouter(DEXaddress);
        // Create a liger pair WBNB for this new token
        LigerPairWBNB = ILigerFactory(_LigerRouter.factory()).createPair(
            address(this),
            _LigerRouter.WETH()
        );
        // Create a liger pair BUSD for this new token
        LigerPairBUSD = ILigerFactory(_LigerRouter.factory()).createPair(
            address(this),
            BusdAddress
        );

        // set the TreasuryVault & LiquidityVault Address variable
        TreasuryManager = TreasuryVault;
        LiquidityManager = LiquidityVault;

        // set the Router Address variable
        LigerRouter = _LigerRouter;

        // exclude from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[BurnAddress] = true;

        // exclude from max hold
        _isExcludedFromMaxHold[owner()] = true;
        _isExcludedFromMaxHold[address(this)] = true;
        _isExcludedFromMaxHold[BurnAddress] = true;

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[BurnAddress] = true;
        _isExcludedFromMaxTx[address(0)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function updateDEX(address newDEXaddress) external onlyOwner() {
        ILigerRouter _LigerRouter = ILigerRouter(newDEXaddress);
        // Check if liger/wbnb pair already exists
        checkLigerPairWBNB = ILigerFactory(_LigerRouter.factory()).getPair(
            address(this),
            _LigerRouter.WETH()
        );
        // Check if liger/busd pair already exists
        checkLigerPairBUSD = ILigerFactory(_LigerRouter.factory()).getPair(
            address(this),
            BusdAddress
        );
        // Create a liger pair WBNB for this new token if not exixts yet
        if (checkLigerPairWBNB == address(0)) {
            LigerPairWBNB = ILigerFactory(_LigerRouter.factory()).createPair(
                address(this),
                _LigerRouter.WETH()
            );
        } else {
            LigerPairWBNB = checkLigerPairWBNB;
        }
        // Create a liger pair BUSD for this new token if not exixts yet
        if (checkLigerPairBUSD == address(0)) {
            LigerPairBUSD = ILigerFactory(_LigerRouter.factory()).createPair(
                address(this),
                BusdAddress
            );
        } else {
            LigerPairBUSD = checkLigerPairBUSD;
        }
        // set the rest of the contract variables
        LigerRouter = _LigerRouter;
        emit UpdateDEXAddress(
            address(LigerRouter),
            LigerPairWBNB,
            LigerPairBUSD
        );
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tBalance[account];
        return tokenFromReflection(_rBalance[account]);
    }

    function totalBurn() public view override returns (uint256) {
        if (_isExcluded[BurnAddress]) return _tBalance[BurnAddress];
        return tokenFromReflection(_rBalance[BurnAddress]);
    }

    function estimateHolders() public view override returns (uint256) {
        return allHolders.length + 1;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rBalance[sender] = _rBalance[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(
            account != address(LigerRouter),
            "We can not exclude this router."
        );
        require(!_isExcluded[account], "Account is already excluded");
        if (_rBalance[account] > 0) {
            _tBalance[account] = tokenFromReflection(_rBalance[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tBalance[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function excludeFromFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedEventFee(address account, bool value)
        external
        onlyOwner()
    {
        _isExcludedEventFee[account] = value;
    }

    function setMaxTxAmount(uint256 newMaxTxAmount) external onlyOwner() {
        MaxTxAmount = newMaxTxAmount;
    }

    function setMaxHoldAmount(uint256 newMaxHoldAmount) external onlyOwner() {
        MaxHoldAmount = newMaxHoldAmount;
    }

    function setExcludeFromMaxTx(address account, bool value)
        external
        onlyOwner()
    {
        _isExcludedFromMaxTx[account] = value;
    }

    function setExcludeFromMaxHold(address account, bool value)
        external
        onlyOwner()
    {
        _isExcludedFromMaxHold[account] = value;
    }

    function setHolderRewardPercent(uint8 newHolderReward)
        external
        onlyOwner()
    {
        HolderReward = newHolderReward;
    }

    function setLiquidityFeePercent(uint8 newLiquidityFee)
        external
        onlyOwner()
    {
        LiquidityFee = newLiquidityFee;
    }

    function setTreasuryFeePercent(uint8 newTreasuryFee) external onlyOwner() {
        TreasuryFee = newTreasuryFee;
    }

    function setTreasuryManagerAddress(address newTreasuryAddress)
        external
        onlyOwner()
    {
        TreasuryManager = newTreasuryAddress;
    }

    function setLiquidityManagerAddress(address newLiquidityAddress)
        external
        onlyOwner()
    {
        LiquidityManager = newLiquidityAddress;
    }

    function setMaxTokenToLiquid(uint256 newMaxTokenToLiduid)
        external
        onlyOwner()
    {
        numTokensSellToAddToLiquidity = newMaxTokenToLiduid;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        SwapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setDiscountFeeEvent(
        bool FeeOn_Event,
        uint8 Liquidity_Fee,
        uint8 Reward_Fee,
        uint8 Treasury_Fee,
        uint32 Event_Deadline
    ) external onlyOwner {
        FeeOnEvent = FeeOn_Event;
        LiquidityFeeEvent = Liquidity_Fee;
        RewardFeeEvent = Reward_Fee;
        TreasuryFeeEvent = Treasury_Fee;
        DeadlineEvent = Event_Deadline;
        emit DiscountFeeEvent(
            FeeOnEvent,
            LiquidityFeeEvent,
            RewardFeeEvent,
            TreasuryFeeEvent,
            DeadlineEvent
        );
    }

    function FeeDiscountEvent()
        public
        view
        returns (
            bool FeeOn_Event,
            uint8 Liquidity_FeeEvent,
            uint8 Reward_FeeEvent,
            uint8 Treasury_FeeEvent,
            uint32 Deadline_Event
        )
    {
        FeeOn_Event = FeeOnEvent;
        Liquidity_FeeEvent = LiquidityFeeEvent;
        Reward_FeeEvent = RewardFeeEvent;
        Treasury_FeeEvent = TreasuryFeeEvent;
        Deadline_Event = DeadlineEvent;
    }

    //to receive BNB from Router when swaping
    receive() external payable {}

    function _reflectReward(uint256 rReward, uint256 tReward) private {
        _rTotal = _rTotal.sub(rReward);
        _tFeeTotal = _tFeeTotal.add(tReward);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tReward,
            uint256 tLiquidity
        ) = _getTValues(tAmount);
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rReward
        ) = _getRValues(tAmount, tReward, tLiquidity, _getRate());
        return (
            rAmount,
            rTransferAmount,
            rReward,
            tTransferAmount,
            tReward,
            tLiquidity
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tReward = calculateHolderReward(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tReward).sub(tLiquidity);
        return (tTransferAmount, tReward, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tReward,
        uint256 tLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rReward = tReward.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rReward).sub(rLiquidity);
        return (rAmount, rTransferAmount, rReward);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rBalance[_excluded[i]] > rSupply ||
                _tBalance[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rBalance[_excluded[i]]);
            tSupply = tSupply.sub(_tBalance[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rBalance[address(this)] = _rBalance[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tBalance[address(this)] = _tBalance[address(this)].add(tLiquidity);
    }

    function calculateHolderReward(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(HolderReward).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(LiquidityFee).div(10**2);
    }

    function calculateTreasuryFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(TreasuryFee).div(10**2);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != owner() && to != owner()) {
            if (!_isExcludedFromMaxTx[from] || !_isExcludedFromMaxTx[to]) {
                require(
                    amount <= MaxTxAmount,
                    "Transfer amount exceeds the MaxTxAmount."
                );
            }
            if (!_isExcludedFromMaxHold[to]) {
                uint256 overallAmount = balanceOf(to).add(amount);
                require(
                    overallAmount <= MaxHoldAmount,
                    "Amount to Receive exceeds the MaxHoldAmount."
                );
            }
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= MaxTxAmount) {
            contractTokenBalance = MaxTxAmount;
        }
        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != LigerPairWBNB &&
            SwapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        //transfer amount, it will take HolderReward, LiquidityFee & TreasuryFee
        _tokenTransfer(from, to, amount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBNB(half);
        // <- this breaks the BNB -> swap when swap+liquify is triggered

        // BNB balance just did we already swap
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to LigerPairWBNB
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the liger pair path of token -> wbnb
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = LigerRouter.WETH();

        _approve(address(this), address(LigerRouter), tokenAmount);

        // make the swap
        LigerRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    } // 0 is accept any amount of BNB

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(LigerRouter), tokenAmount);

        // add the liquidity
        LigerRouter.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            LiquidityManager,
            block.timestamp
        );
    } //0 is for slippage is unavoidable

    //Call this function to enable all fee
    function enableAllFee() external onlyOwner() {
        HolderReward = _previousHolderReward;
        LiquidityFee = _previousLiquidityFee;
        TreasuryFee = _previousTreasuryFee;
        inSwapAndLiquify = true;
        _enableAllFee = true;
        emit SwapAndLiquifyEnabledUpdated(true);
    }

    //Call this function to disable all fee
    function disableAllFee() external onlyOwner() {
        if (HolderReward == 0 && LiquidityFee == 0 && TreasuryFee == 0) return;
        _previousHolderReward = HolderReward;
        _previousLiquidityFee = LiquidityFee;
        _previousTreasuryFee = TreasuryFee;
        HolderReward = 0;
        LiquidityFee = 0;
        TreasuryFee = 0;
        inSwapAndLiquify = false;
        _enableAllFee = false;
        emit SwapAndLiquifyEnabledUpdated(false);
    }

    //Standard Fee setting
    function standardFee(bool setting) private {
        if (_enableAllFee) {
            if (setting) {
                HolderReward = _previousHolderReward;
                LiquidityFee = _previousLiquidityFee;
                TreasuryFee = _previousTreasuryFee;
                TreasuryFeeEnable = true;
            } else {
                _previousHolderReward = HolderReward;
                _previousLiquidityFee = LiquidityFee;
                _previousTreasuryFee = TreasuryFee;
                HolderReward = 0;
                LiquidityFee = 0;
                TreasuryFee = 0;
                TreasuryFeeEnable = false;
            }
        }
    }

    function EventFee(bool eventFeeOn) private {
        if (_enableAllFee) {
            if (eventFeeOn) {
                HolderReward = RewardFeeEvent;
                LiquidityFee = LiquidityFeeEvent;
                TreasuryFee = TreasuryFeeEvent;
            } else {
                HolderReward = _previousHolderReward;
                LiquidityFee = _previousLiquidityFee;
                TreasuryFee = _previousTreasuryFee;
            }
        }
    }

    function countHolders(address sender, address recipient) private {
        if (!accHolders[recipient]) {
            accHolders[recipient] = true;
            allHolders.push(recipient);
            emit Holders(allHolders.length);
        }

        if (accHolders[sender]) {
            uint256 senderBalance;

            if (_isExcluded[sender]) {
                senderBalance = _tBalance[sender];
            } else {
                senderBalance = tokenFromReflection(_rBalance[sender]);
            }

            if (senderBalance <= 0) {
                for (uint256 x = 0; x < allHolders.length; x++) {
                    if (allHolders[x] == sender) {
                        allHolders[x] = allHolders[allHolders.length - 1];
                        _tBalance[sender] = 0;
                        _rBalance[sender] = 0;
                        accHolders[sender] = false;
                        allHolders.pop();
                        break;
                    }
                }
                emit Holders(allHolders.length);
            }
        }
    }

    //this method is responsible for taking all fee, if collectFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (FeeOnEvent && _isExcludedEventFee[sender]) {
            if (block.timestamp <= DeadlineEvent) {
                EventFee(true);
            } else {
                FeeOnEvent = false;
                EventFee(false);
            }
        } else {
            //indicates if fee should be deducted from transfer
            standardFee(true);
        }

        uint256 _treasuryFee = calculateTreasuryFee(amount);
        uint256 afterAmount = amount.sub(_treasuryFee);

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            standardFee(false);
            afterAmount = amount;
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, afterAmount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, afterAmount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, afterAmount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, afterAmount);
        } else {
            TreasuryFeeEnable = false;
            _transferStandard(sender, recipient, afterAmount);
        }

        if (TreasuryFee != 0) {
            standardFee(false);
            TreasuryFeeEnable = true;
            //Send treasury fee to Treasury Vault
            _transferStandard(sender, TreasuryManager, _treasuryFee);
            emit TreasuryFeeTransfer(sender, TreasuryManager, _treasuryFee);
            standardFee(true);
        }

        if (!TreasuryFeeEnable) {
            standardFee(true);
            TreasuryFeeEnable = true;
        }

        // estimate current holders
        countHolders(sender, recipient);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rReward,
            uint256 tTransferAmount,
            uint256 tReward,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rBalance[sender] = _rBalance[sender].sub(rAmount);
        _rBalance[recipient] = _rBalance[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectReward(rReward, tReward);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rReward,
            uint256 tTransferAmount,
            uint256 tReward,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rBalance[sender] = _rBalance[sender].sub(rAmount);
        _tBalance[recipient] = _tBalance[recipient].add(tTransferAmount);
        _rBalance[recipient] = _rBalance[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectReward(rReward, tReward);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rReward,
            uint256 tTransferAmount,
            uint256 tReward,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tBalance[sender] = _tBalance[sender].sub(tAmount);
        _rBalance[sender] = _rBalance[sender].sub(rAmount);
        _rBalance[recipient] = _rBalance[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectReward(rReward, tReward);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rReward,
            uint256 tTransferAmount,
            uint256 tReward,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tBalance[sender] = _tBalance[sender].sub(tAmount);
        _rBalance[sender] = _rBalance[sender].sub(rAmount);
        _tBalance[recipient] = _tBalance[recipient].add(tTransferAmount);
        _rBalance[recipient] = _rBalance[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectReward(rReward, tReward);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}