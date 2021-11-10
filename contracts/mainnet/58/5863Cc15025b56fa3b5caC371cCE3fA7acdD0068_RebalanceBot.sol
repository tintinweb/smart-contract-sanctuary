// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import '../interfaces/IxAssetCLR.sol';
import '../interfaces/IxTokenManager.sol';

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * CLR rebalance bot which performs adminSwap and adminBurn / adminMint
 * in order to bring tokens in the CLR position back to a certain ratio
 */
contract RebalanceBot is Ownable {
    IxTokenManager xTokenManager = IxTokenManager(0xfA3CaAb19E6913b6aAbdda4E27ac413e96EaB0Ca);

    /**
     * Performs a rebalance for a given CLR instance which swaps underlying for xAsset and burns it
     * Used to bring token ratio in a given position back to normal using xAsset burn method
     * Groups Unstake, Swap and Burn in one transaction
     * @param xAssetCLR CLR instance
     * @param t0UnstakeAmt amount of token 0 to unstake
     * @param t1UnstakeAmt amount of token 1 to unstake
     * @param swapAmount amount of underlying asset to swap for xAsset
     * @param burnAmount amount of xAsset to burn
     * @param t0IsxAsset true if token 0 is the xAsset, false otherwise
     */
    function swapAndBurnRebalance(IxAssetCLR xAssetCLR, uint256 t0UnstakeAmt, uint256 t1UnstakeAmt, 
                            uint256 swapAmount, uint256 burnAmount, bool t0IsxAsset) public onlyOwnerOrManager {
        xAssetCLR.adminUnstake(t0UnstakeAmt, t1UnstakeAmt);
        xAssetCLR.adminSwap(swapAmount, !t0IsxAsset);
        xAssetCLR.adminBurn(burnAmount, t0IsxAsset);
    }

    /**
     * Performs a rebalance for a given CLR instance which swaps xAsset for underlying and mints more xAsset
     * Used to bring token ratio in a given position back to normal using xAsset mint method
     * Groups Unstake, Swap and Mint in one transaction
     * @param xAssetCLR CLR instance
     * @param t0UnstakeAmt amount of token 0 to unstake
     * @param t1UnstakeAmt amount of token 1 to unstake
     * @param swapAmount amount of xAsset to swap for underlying asset
     * @param mintAmount amount of underlying asset to mint with
     * @param t0IsxAsset true if token 0 is the xAsset, false otherwise
     */
    function swapAndMintRebalance(IxAssetCLR xAssetCLR, uint256 t0UnstakeAmt, uint256 t1UnstakeAmt, 
                            uint256 swapAmount, uint256 mintAmount, bool t0IsxAsset) public onlyOwnerOrManager {
        xAssetCLR.adminUnstake(t0UnstakeAmt, t1UnstakeAmt);
        xAssetCLR.adminSwap(swapAmount, t0IsxAsset);
        xAssetCLR.adminMint(mintAmount, t0IsxAsset);
    }

    modifier onlyOwnerOrManager {
        require(
            msg.sender == owner() ||
            xTokenManager.isManager(msg.sender, address(this)),
            "Function may be called only by owner or manager"
        );
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * xAssetCLR Interface
 */
interface IxAssetCLR is IERC20 {
    function adminRebalance() external;

    function adminStake(uint256 amount0, uint256 amount1) external;

    function adminSwap(uint256 amount, bool _0for1) external;

    function adminSwapOneInch(
        uint256 minReturn,
        bool _0for1,
        bytes memory _oneInchData
    ) external;

    function adminUnstake(uint256 amount0, uint256 amount1) external;

    function burn(uint256 amount) external;

    function calculateAmountsMintedSingleToken(uint8 inputAsset, uint256 amount)
        external
        view
        returns (uint256 amount0Minted, uint256 amount1Minted);

    function calculateMintAmount(uint256 _amount, uint256 totalSupply)
        external
        view
        returns (uint256 mintAmount);

    function calculatePoolMintedAmounts(uint256 amount0, uint256 amount1)
        external
        view
        returns (uint256 amount0Minted, uint256 amount1Minted);

    function changePool(address _poolAddress, uint24 _poolFee) external;

    function collect()
        external
        returns (uint256 collected0, uint256 collected1);

    function collectAndRestake() external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function getAmountInAsset0Terms(uint256 amount)
        external
        view
        returns (uint256);

    function getAmountInAsset1Terms(uint256 amount)
        external
        view
        returns (uint256);

    function getAmountsForLiquidity(uint128 liquidity)
        external
        view
        returns (uint256 amount0, uint256 amount1);

    function getAsset0Price() external view returns (int128);

    function getAsset1Price() external view returns (int128);

    function getBufferBalance() external view returns (uint256);

    function getBufferToken0Balance() external view returns (uint256 amount0);

    function getBufferToken1Balance() external view returns (uint256 amount1);

    function getBufferTokenBalance()
        external
        view
        returns (uint256 amount0, uint256 amount1);

    function getLiquidityForAmounts(uint256 amount0, uint256 amount1)
        external
        view
        returns (uint128 liquidity);

    function getNav() external view returns (uint256);

    function getPositionLiquidity() external view returns (uint128 liquidity);

    function getStakedBalance() external view returns (uint256);

    function getStakedTokenBalance()
        external
        view
        returns (uint256 amount0, uint256 amount1);

    function getTicks() external view returns (int24 tick0, int24 tick1);

    function getTotalLiquidity() external view returns (uint256 amount);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function initialize(
        string memory _symbol,
        int24 _tickLower,
        int24 _tickUpper,
        address _token0,
        address _token1,
        UniswapContracts memory contracts,
        // Staking parameters
        address _rewardsToken,
        address _rewardEscrow,
        bool _rewardsAreEscrowed
    ) external;

    function lastLockedBlock(address) external view returns (uint256);

    function mint(uint8 inputAsset, uint256 amount) external;

    function mintInitial(uint256 amount0, uint256 amount1) external;

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function pauseContract() external returns (bool);

    function paused() external view returns (bool);

    function poolFee() external view returns (uint24);

    function renounceOwnership() external;

    function resetTwap() external;

    function setMaxTwapDeviationDivisor(uint256 newDeviationDivisor) external;

    function setTwapPeriod(uint32 newPeriod) external;

    function symbol() external view returns (string memory);

    function token0DecimalMultiplier() external view returns (uint256);

    function token0Decimals() external view returns (uint8);

    function token1DecimalMultiplier() external view returns (uint256);

    function token1Decimals() external view returns (uint8);

    function tokenDiffDecimalMultiplier() external view returns (uint256);

    function tokenId() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function adminMint(uint256 amount, bool isToken0) external;

    function adminBurn(uint256 amount, bool isToken0) external;
    
    function adminApprove(bool isToken0) external;

    struct UniswapContracts {
        address pool;
        address router;
        address quoter;
        address positionManager;
    }

    function unpauseContract() external returns (bool);

    function withdrawToken(address token, address receiver) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IxTokenManager {
    /**
     * @dev Add a manager to an xAsset fund
     */
    function addManager(address manager, address fund) external;

    /**
     * @dev Remove a manager from an xAsset fund
     */
    function removeManager(address manager, address fund) external;

    /**
     * @dev Check if an address is a manager for a fund
     */
    function isManager(address manager, address fund)
        external
        view
        returns (bool);

    /**
     * @dev Set revenue controller
     */
    function setRevenueController(address controller) external;

    /**
     * @dev Check if address is revenue controller
     */
    function isRevenueController(address caller) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}