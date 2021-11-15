// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';

contract LiquidityAndStaking is Ownable {
    address public liquidityAddress;
    address public GainTokenAddress;
    address public GLWallet;
    address public PAXGAddress;
    address public USDCAddress;
    address public factory;
    uint256 public amountA;
    uint256 public amountB;
    uint256 public liquidityAB;
    uint[] public amountsPaxg;
    uint[] public amountsUsdc;
    address[] public PAXG_GAIN;
    address[] public USDC_GAIN;
    
    event details(uint256 amountA, uint256 amountB, uint256 liquidityAB);

    constructor() {
        liquidityAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        GainTokenAddress = 0x9FC4bbd299F03D341BF275ed33402f793DC41C99;
        GLWallet = 0x819704F4dd43c1c2D8890be1a44dEdb2caBE8647;
        PAXGAddress = 0x6dE86BC1DE4BeC6213C127540B46E264B310C8CC;
        USDCAddress = 0xa1633D089d0c613D9992C445832819e0b35c51a3;
        PAXG_GAIN = [GainTokenAddress, PAXGAddress];
        USDC_GAIN = [GainTokenAddress, USDCAddress];
    }

    function updateGainTokenAddress(address _GainAddress)
        external onlyOwner
        returns (address)
    {
        GainTokenAddress = _GainAddress;
        return _GainAddress;
    }


    function withdraw(address _tokenAddress)
        external onlyOwner
        returns (bool)
    {
        IERC20(_tokenAddress).transfer(owner(), IERC20(_tokenAddress).balanceOf(address(this)));
        return true;
    }

    function addLiquidityFromContract(
        address tokenAddress,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) internal returns (bool) {

        // IERC20 tokenAddressA = IERC20(GainTokenAddress);
        IERC20 tokenAddressB = IERC20(tokenAddress);

        // tokenAddressA.transferFrom(msg.sender, address(this), amountADesired);
        // tokenAddressB.transferFrom(msg.sender, address(this), amountBDesired); 

        // tokenAddressA.approve(liquidityAddress, IERC20(GainTokenAddress).balanceOf(address(this)));
        tokenAddressB.approve(liquidityAddress, IERC20(tokenAddress).balanceOf(address(this)));

        IUniswapV2Router01 addLiq = IUniswapV2Router01(liquidityAddress);
        (amountA, amountB, liquidityAB) = addLiq.addLiquidity(
            GainTokenAddress,
            tokenAddress,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            deadline
        );

        emit details(amountA, amountB, liquidityAB);

        return true;
    }

    function swapFromContract(
        address tokenAddress,
        uint256 amountIn,
        address[] memory path,
        address to,
        uint256 deadline
    ) internal returns (uint256[] memory) {

        IERC20 tokenAddress_ = IERC20(tokenAddress);

        //tokenAddress_.transferFrom(GLWallet, address(this), amountIn);

        tokenAddress_.approve(liquidityAddress, IERC20(tokenAddress).balanceOf(address(this)));

        IUniswapV2Router01 swapLiq = IUniswapV2Router01(liquidityAddress);

        uint[] memory amounts = swapLiq.swapExactTokensForTokens(
                amountIn,
                1,
                path,
                to,
                deadline
        );

        return amounts;
    }

    function tokenSwap() external onlyOwner returns(bool){
        uint256 deadline = block.timestamp + 30 days;

            IERC20 tokenAddress = IERC20(GainTokenAddress);
            uint256 balance = tokenAddress.balanceOf(GLWallet);
            require(balance >= 10000 * (10 ** 18), "$LIQ&STAK: GL-wallet has less balance");

            tokenAddress.transferFrom(GLWallet, address(this), 10000000000000000000000);

            tokenAddress.approve(liquidityAddress, IERC20(tokenAddress).balanceOf(address(this)));
            
            (amountsPaxg) = swapFromContract(PAXGAddress, 2500000000000000000000, PAXG_GAIN, address(this), deadline);
            addLiquidityFromContract(PAXGAddress, 2500000000000000000000, amountsPaxg[1], 1, 1, address(this), deadline);
            (amountsUsdc) = swapFromContract(USDCAddress, 2500000000000000000000, USDC_GAIN, address(this), deadline);
            addLiquidityFromContract(USDCAddress, 2500000000000000000000, amountsUsdc[1], 1, 1, address(this), deadline);
        return true;
    }
}

interface IUniswapV2Router01 {
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

    // function removeLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     uint256 liquidity,
    //     uint256 amountAMin,
    //     uint256 amountBMin,
    //     address to,
    //     uint256 deadline
    // ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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

