pragma solidity ^0.8.4;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Metadata is IERC20 {
    /// @return The name of the token
    function name() external view returns (string memory);

    /// @return The symbol of the token
    function symbol() external view returns (string memory);

    /// @return The number of decimal places the token has
    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.4;

interface ISnailPool {
    function getPoolInfo() external view returns (uint256 liq, bool isCitadel);
    function lock(uint256 collateral, address whose, uint256 posId) external;
    function unlock(uint256 collateral) external;
}

pragma solidity ^0.8.4;

interface ISnailPoolFactory {
    function newVixPool(string memory _fullName, address _dai) external returns (address);
    function newCitadelPool(string memory _fullName, address _dai) external returns (address);
}

pragma solidity ^0.8.4;

   struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

interface ISwapRouter {


    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    /// @dev Returns the pool for the given token pair and fee. The pool contract may or may not exist.
    /// @dev actually returns IUniswapV3Pool type
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address);

}

pragma solidity ^0.8.4;

interface IUniswapV3CrossPoolOracle {
    function assetToEth(
        address _tokenIn,
        uint256 _amountIn,
        uint32 _twapPeriod
    ) external view returns (uint256 ethAmountOut);

    function assetToAsset(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint32 _twapPeriod
    ) external view returns (uint256 amountOut);

    function ethToAsset(
        uint256 _ethAmountIn,
        address _tokenOut,
        uint32 _twapPeriod
    ) external view returns (uint256 amountOut);
}

pragma solidity ^0.8.4;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IUniswapV3CrossPoolOracle.sol";
import "./ISwapRouter.sol";
import "./ISnailPool.sol";
import "./ISnailPoolFactory.sol";
import "./IERC20Metadata.sol";


interface IUniswapV3Pool {
  function swap(
    address recipient,
    bool zeroForOne,
    int256 amountSpecified,
    uint160 sqrtPriceLimitX96,
    bytes memory data
  ) external returns (int256 amount0, int256 amount1);
}

contract SnailFront is Ownable {

    function concatenate(string memory s1, string memory s2) public pure returns (string memory) {
        return string(abi.encodePacked(s1, s2));
    }

    //fee is 3000; default fee for all pools, also look at smaller fee (less liq?) pools of 0.05%

   IUniswapV3CrossPoolOracle public priceProvider;
   ISwapRouter public router;

    // position
    struct Pos {
        address tok0;
        address tok1;
        uint256 amountInDai;
        uint256 amountOut;
        uint256 leverage;
        uint256 daiColSize;
        uint256 vixLocked;
        uint256 expiry;
        bool open;
        bool liquidated;
    }

    //indexing individual trades
    mapping(address => Pos[]) public positions;

    //indexing all univ3Pool=>snailPool, citadel
    mapping(address => address) public snailPoolsTypeC;

    //indexing all univ3Pool=>snailPool, vix
    mapping(address => address) public snailPoolsTypeV;

    //gov-controlled param. main risk score indicator for a coin
    //1000 => citadel-only (eg dai pool positions)
    //990 ratio => citadel:vix = 99:1, ideal (theoretical-only) score
    //0 ratio (luigi finance tier) => citadel:vix = 1:1, fully-backed citadel
    mapping(address => uint256) public vixScore;

    mapping(address => uint256) public maxLeverage;

    uint24 public defaultFee;
    uint256 public defaultDeadline;
    address public dai;
    address public factory;
    uint32 public candle;
    uint256 public absoluteLeverageCap;


    event NewVixPool(address indexed uni, address indexed pool);
    event NewCitadelPool(address indexed uni, address indexed pool);
    event Liquidated(address indexed who, uint indexed posId);
    event Closed(address indexed who, uint indexed posId);
    event Opened(address indexed who, uint indexed posId);


    constructor(IUniswapV3CrossPoolOracle _pp, ISwapRouter _r,
                uint24 _fee, uint256 _dl,
                address _dai, uint32 _candle, uint256 _lev,
                address _factory) public {
        priceProvider = _pp;
        router = _r;
        defaultFee = _fee;
        defaultDeadline = _dl;
        dai = _dai;
        // def 30 min candle
        // 1800
        candle = _candle;
        absoluteLeverageCap = _lev;
        factory = _factory;
    }

    function getSnailPool(address _uniPool) public view
        returns (address sPoolC, address sPoolV, uint256 sPoolCLiq, uint256 sPoolVLiq)
    {
        sPoolC = snailPoolsTypeC[_uniPool];
        sPoolV = snailPoolsTypeV[_uniPool];
        (sPoolCLiq, ) = ISnailPool(sPoolC).getPoolInfo();
        (sPoolVLiq, ) = ISnailPool(sPoolV).getPoolInfo();
    }

    function getMaxLeverage(address _tok1) public view
        returns (uint256) {
        if (maxLeverage[_tok1] == 0) {
            return absoluteLeverageCap;
        } else {
            return maxLeverage[_tok1];
        }
    }

    function daiMarginFromCollateral(address _tok1, uint256 sPoolCLiq,
                                    uint256 cPoolVLiq)
        public view returns (uint256 margin, uint256 vixCollateralToLock)
    {
        uint256 score = vixScore[_tok1];
        //truncating digits
        vixCollateralToLock = ((cPoolVLiq * (1000 - score)) / 1000);
        //calculate max liq provided by Citadel capped @ Vix airbag liq
        if (vixCollateralToLock >= sPoolCLiq) {
            margin = sPoolCLiq;
        } else {
            margin = vixCollateralToLock;
        }
    }

    // limit to DAI or (W)ETH trading pairs at start?
    // function setAllowedTok0(address _col, bool _isOk) public onlyOwner {
    //     allowedCollateral[_col] = _isOk;
    // }

	function open(address _tok1,
				   uint256 _daiColSize, uint256 _leverage) public {
        // DAI-COIN/WETH-COIN at start, zapper for everything else
        require(_leverage < getMaxLeverage(_tok1), "l");
        IERC20(dai).transferFrom(msg.sender, address(this), _daiColSize);
        // NOTE prevent non-EOA from calling (except ZAPPER), flash loan
        (address sPoolC, address sPoolV, uint256 sPoolCLiq, uint256 sPoolVLiq) =
            getSnailPool(router.getPool(dai, _tok1, defaultFee));

        (uint256 maxMargin, uint256 vixCollateralToLock) =
            daiMarginFromCollateral(_tok1, sPoolCLiq, sPoolVLiq);
        uint256 requestedMargin = _leverage * _daiColSize;
        require(requestedMargin < maxMargin, "m");
        uint256 amountOutMinimum = priceProvider.assetToAsset(dai, requestedMargin,
                                                              _tok1, candle);
        // 0 transfer required margin from citadel pool for the buy-in
        IERC20(dai).transferFrom(sPoolC, address(this), requestedMargin);
        // 2 perform the buy-in
        // NOTE no custom slippage, slippage is included in oracle request amountOut
        ExactInputSingleParams memory swapParams =
            ExactInputSingleParams(dai, _tok1, defaultFee,
                                   address(this), defaultDeadline,
                                   requestedMargin, amountOutMinimum, 0);
        uint256 amountOut = router.exactInputSingle(swapParams);
        Pos memory pos = Pos({
            tok0: dai,
            tok1: _tok1,
            // aka citadelLocked
            amountInDai: requestedMargin,
            amountOut: amountOut,
            leverage: _leverage,
            daiColSize: _daiColSize,
            vixLocked: vixCollateralToLock,
            expiry: block.timestamp + 30 days,
            open: true,
            liquidated: false
        });
        positions[msg.sender].push(pos);
        // 1 lock vixScore-weighted margin insurance in vix pool
        ISnailPool(sPoolV).lock(vixCollateralToLock, msg.sender, positions[msg.sender].length);
        emit Opened(msg.sender, positions[msg.sender].length);
	}

	function close(address _whose, uint256 _posId) public {
        Pos memory pos = positions[_whose][_posId];
        require(pos.open, "o");
        require(_whose == msg.sender, "a");
        uint256 currentPrice = priceProvider.assetToAsset(dai, pos.amountInDai,
                                                          pos.tok1, candle);
        uint256 liquidationPrice = pos.amountOut - pos.amountOut/pos.leverage;
        require(currentPrice > liquidationPrice, "p");
        positions[_whose][_posId].open = false;
        positions[_whose][_posId].liquidated = false;
        (address sPoolC , address sPoolV, , ) =
            getSnailPool(router.getPool(dai, pos.tok1, defaultFee));

        // swap back
            uint256 amountOutMinimum = priceProvider.assetToAsset(pos.tok1, pos.amountOut,
                                                                  dai, candle);
            ExactInputSingleParams memory swapParams =
                ExactInputSingleParams(pos.tok1, dai, defaultFee,
                                       address(this), defaultDeadline,
                                       pos.amountOut, amountOutMinimum, 0);
            // DAI amountOut received from swapback
            uint256 amountOut = router.exactInputSingle(swapParams);

        if (amountOut > pos.amountInDai) {
            // this is the place to implement fee-on-win
            IERC20(dai).transfer(_whose, amountOut-pos.amountInDai);
            IERC20(dai).transfer(_whose, pos.daiColSize);
            IERC20(dai).transfer(sPoolC, pos.amountInDai);
            ISnailPool(sPoolV).unlock(pos.vixLocked);
        } else {
            // this is the place to implement fee-on-lose; not fee-on-liquidation

            //make citadel LPs whole in any case
            IERC20(dai).transfer(sPoolC, pos.amountInDai);
            // return what's left in collateral
            IERC20(dai).transfer(_whose, pos.daiColSize - (pos.amountInDai - amountOut));
            ISnailPool(sPoolV).unlock(pos.vixLocked);
        }
        emit Closed(_whose, _posId);
	}

    // liquidity in this Front hotwallet is shared, this is the additional mechanism
    // to repair hotwallet dai reserves
    // function donateLiquidity() public {
    // }

    // reverse pool - bid for a new pool for your favourite Uniswap token
    // function bidForNewVix() public {
    // }

    function newVixPool(address _tok0, address _tok1) public {
        address uniPool = router.getPool(_tok0, _tok1, defaultFee);
        require(snailPoolsTypeV[uniPool] == address(0), "p");
        string memory name = concatenate(IERC20Metadata(_tok0).symbol(),
                                         IERC20Metadata(_tok1).symbol());
        string memory fullName = concatenate("SnailVix", name);
        address snailPool = ISnailPoolFactory(factory).newVixPool(fullName, dai);
        snailPoolsTypeV[uniPool] == snailPool;
        emit NewVixPool(uniPool, snailPool);
    }

    function newCitadelPool(address _tok0, address _tok1) public {
        address uniPool = router.getPool(_tok0, _tok1, defaultFee);
        require(snailPoolsTypeC[uniPool] == address(0), "p");
        string memory name = concatenate(IERC20Metadata(_tok0).symbol(),
                                         IERC20Metadata(_tok1).symbol());
        string memory fullName = concatenate("SnailCitadel", name);
        address snailPool = ISnailPoolFactory(factory).newCitadelPool(fullName, dai);
        snailPoolsTypeC[uniPool] == snailPool;
        emit NewCitadelPool(uniPool, snailPool);
    }

	function liquidate(address _whose, uint256 _posId) public {
        Pos memory pos = positions[_whose][_posId];
        require(pos.open, "o");
        uint256 currentPrice = priceProvider.assetToAsset(dai, pos.amountInDai,
                                                          pos.tok1, candle);
        uint256 liquidationPrice = pos.amountOut - pos.amountOut/pos.leverage;
        require((currentPrice <= liquidationPrice) || (block.timestamp > pos.expiry) , "p");
        positions[_whose][_posId].open = false;
        positions[_whose][_posId].liquidated = true;
        (address sPoolC , address sPoolV, , ) =
            getSnailPool(router.getPool(dai, pos.tok1, defaultFee));
        // make vix LPs happy - transfer collateral and luigi coins to Vix pool
        IERC20(dai).transfer(sPoolV, pos.daiColSize);
        IERC20(pos.tok1).transfer(sPoolV, pos.daiColSize);
        // make citadel LPs happy - unlock full dai Vix collateral and comp citadel
        ISnailPool(sPoolV).unlock(pos.vixLocked);
        IERC20(dai).transferFrom(sPoolV, sPoolC, pos.daiColSize);
        emit Liquidated(_whose, _posId);
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
    constructor () {
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

