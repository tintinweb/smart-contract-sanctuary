//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IUsdcSwap.sol";
import "./interfaces/IMaiStakingRewards.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Pair.sol";

contract MaiReinvestor is Ownable {

    uint256 public pid;

    IUniswapV2Router02 public QuickSwapV2Router02;
    IUsdcSwap public UsdcSwap;
    IMaiStakingRewards public MaiStakingRewards;

    IERC20 public Usdc;
    IERC20 public QiDao;
    IERC20 public Mai;
    IUniswapV2Pair public LPToken;

    constructor(
        uint256 _pid,
        address _QuickSwapV2Router02Addr,
        address _UsdcSwapAddr,
        address _MaiStakingRewardsAddr,
        address _UsdcAddr,
        address _QiDaoAddr,
        address _MaiAddr,
        address _LPToken
    ) {
        //Set vars
        pid = _pid; //Pool Id

        QuickSwapV2Router02 = IUniswapV2Router02(_QuickSwapV2Router02Addr);
        UsdcSwap = IUsdcSwap(_UsdcSwapAddr);
        MaiStakingRewards = IMaiStakingRewards(_MaiStakingRewardsAddr);

        Usdc = IERC20(_UsdcAddr);
        QiDao = IERC20(_QiDaoAddr); //Governance token
        Mai = IERC20(_MaiAddr); //Stable
        LPToken = IUniswapV2Pair(_LPToken);

        //Submit approvals
        Usdc.approve(_QuickSwapV2Router02Addr, type(uint256).max);
        Usdc.approve(_UsdcSwapAddr, type(uint256).max);
        QiDao.approve(_QuickSwapV2Router02Addr, type(uint256).max);
        Mai.approve(_QuickSwapV2Router02Addr, type(uint256).max);
        Mai.approve(_UsdcSwapAddr, type(uint256).max);
        LPToken.approve(_MaiStakingRewardsAddr, type(uint256).max);
        LPToken.approve(_QuickSwapV2Router02Addr, type(uint256).max);
    }

    function getDeadline() public view returns (uint256) {
        return block.timestamp + 5 minutes;
    }

    function getDeposited() public view returns (uint256) {
        return MaiStakingRewards.deposited(pid, address(this));
    }

    function getPending() public view returns (uint256) {
        return MaiStakingRewards.pending(pid, address(this));
    }

    function _calculateExactLiquidity(uint256 UsdcBalanceToAdd, uint256 MaiBalanceToAdd) internal view returns (uint256, uint256, uint256, uint256){
        //This fn returns the exact amount of liquidity to add, and avoid getting sandwiched

        (uint112 reserve0, uint112 reserve1, ) = LPToken.getReserves();
        
        //get the percentage of the pool based on the amount to provide
        uint256 percOfTotalLiqUsdc = (UsdcBalanceToAdd * 100 / reserve0);
        uint256 percOfTotalLiqMai = (MaiBalanceToAdd * 100 / reserve1);

        //Select the smaller percentage
        uint256 smallerTokenPerc;
        if (percOfTotalLiqUsdc >= percOfTotalLiqMai) {
            smallerTokenPerc = percOfTotalLiqMai;
        }
        if (percOfTotalLiqUsdc <= percOfTotalLiqMai) {
            smallerTokenPerc = percOfTotalLiqUsdc;
        }
        //Returns values (To avoid "Stack to deep", return "UsdcBalanceToAdd" and "MaiBalanceToAdd")
        return (UsdcBalanceToAdd * smallerTokenPerc / 100, MaiBalanceToAdd * smallerTokenPerc / 100, UsdcBalanceToAdd, MaiBalanceToAdd);
    }

    function _getLiquidityAmounts() internal view returns (uint256, uint256) {
        //This function determines the quantity of each token corresponds to this contract, at the moment of extract liq, based on LP
        (uint112 reserve0, uint112 reserve1, ) = LPToken.getReserves();
        uint256 totalSupply = LPToken.totalSupply();
        uint256 poolPerc = (LPToken.balanceOf(address(this)) * 100 / totalSupply);
        return (reserve0 * poolPerc / 100, reserve1 * poolPerc / 100);
    }

    function _addLiquidity(uint256 deadline) internal returns (uint256) {

        (uint256 amountUsdcMin, uint256 amountMaiMin, uint256 UsdcBalanceToAdd, uint256 MaiBalanceToAdd) = _calculateExactLiquidity(Usdc.balanceOf(address(this)), Mai.balanceOf(address(this)));

        //Provide liquidity
        (, , uint256 liquidity) = QuickSwapV2Router02.addLiquidity(
            address(Usdc),
            address(Mai),
            UsdcBalanceToAdd,
            MaiBalanceToAdd,
            amountUsdcMin,
            amountMaiMin,
            address(this),
            deadline
        );

        return liquidity;
    }

    function _removeLiquidity(uint256 deadline) internal {
        //Remove liq
        uint256 liquidity = LPToken.balanceOf(address(this));
        address tokenA = address(Usdc);
        address tokenB = address(Mai);

        (uint256 amountAMin, uint256 amountBMin) = _getLiquidityAmounts();

        QuickSwapV2Router02.removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, address(this), deadline);
    }

    function _swapQiForUsdc(uint256 deadline) internal {
        uint256 QiDaoBalance = QiDao.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(QiDao);
        path[1] = address(Usdc);

        uint256[] memory amountsOut = QuickSwapV2Router02.getAmountsOut(
            QiDaoBalance,
            path
        );

        uint256 minAmount = amountsOut[1] - ((amountsOut[1] * 1) / 100); // 1% slippage
        address receiver = address(this);

        QuickSwapV2Router02.swapExactTokensForTokens(
            QiDaoBalance,
            minAmount,
            path,
            receiver,
            deadline
        );
    } 

    function deposit(uint256 amount) public onlyOwner {
        //Deposits Usdc
        Usdc.transferFrom(msg.sender, address(this), amount);
    }

    function reinvest(uint256 deadline) public onlyOwner {
        //Reinvest all tokens in contract

        //Harvest
        MaiStakingRewards.deposit(pid, 0);

        //Check if QiDao balance > 0
        uint256 QiDaoBalance = QiDao.balanceOf(address(this));
        if (QiDaoBalance > 0) {

            //Swap all QiDao for Usdc
            _swapQiForUsdc(deadline);
        }

        //Check if Usdc balance > 0
        uint256 UsdcBalance = Usdc.balanceOf(address(this));
        if (UsdcBalance > 0) {

            //Swap half of Usdc to Mai
            UsdcSwap.swapFrom(UsdcBalance / 2);
            
            //Add liquidity
            uint256 liquidity = _addLiquidity(deadline);
            
            //Deposit on Stake
            MaiStakingRewards.deposit(pid, liquidity);
        }
    }

    function closePosition(uint256 deadline) public onlyOwner {
        //Redeem all positions, send all tokens to owner

        //Remove liquidity from Stake and harvest
        uint256 depositedAmount = getDeposited();
        MaiStakingRewards.withdraw(pid, depositedAmount);

        //Swap all QiDao to USDC
        _swapQiForUsdc(deadline);

        //Remove liquidity from Quickswap
        _removeLiquidity(deadline);

        //Swap all Mai to USDC
        uint256 MaiBalance = Mai.balanceOf(address(this));
        UsdcSwap.swapTo(MaiBalance);

        //Send all USDC to owner
        Usdc.transfer(msg.sender, Usdc.balanceOf(address(this)));
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IUsdcSwap {
    function getReserves() external view returns(uint256, uint256);
    function swapFrom(uint256 amount) external; //USDC -> miMatic
    function swapTo(uint256 amount) external; //miMatic -> USDC
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMaiStakingRewards {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function deposited(uint256 _pid, address _user) external view returns (uint256);
    function pending(uint256 _pid, address _user) external view returns (uint256);
    function emergencyWithdraw(uint256 _pid) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

interface IUniswapV2Pair {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
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
        return msg.data;
    }
}