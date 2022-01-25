// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';

contract LiquidityAndStaking is Ownable{
    address public liquidityAddress;
    address public GainTokenAddress;
    address public GLWallet;
    // address public PAXGAddress;
    // address public DAIAddress;
    address public factory;
    uint256 public amountA;
    uint256 public amountB;
    uint256 public liquidityAB;
    uint[] public amountsPair1;
    uint[] public amountsPair2;
    address[] public PAIR1_GAIN;
    address[] public PAIR2_GAIN;
    uint256 public pairCount;
    uint256 public GainAmount;
    //IStaking OhmAddress;
    
    // mapping(address => mapping(address => bool)) public pairExists;

    // struct pairs {
    //     uint256 id;
    //     address pairedAddress;
    // }

    // mapping(uint256 => pairs) public pairAddresses;
    
    event details(uint256 amountA, uint256 amountB, uint256 liquidityAB);

    constructor() {
        liquidityAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        GainTokenAddress = 0xA3B37984cdac357c08269f4e2ad7E31d1Eb92C57;
        GLWallet = 0x819704F4dd43c1c2D8890be1a44dEdb2caBE8647;
        GainAmount = 10000 * (10 ** 18);
    }

    function updateGainTokenAddress(address _GainAddress)
        external onlyOwner
        returns (address) {

        GainTokenAddress = _GainAddress;
        return _GainAddress;
    }


    function withdraw(address _tokenAddress)
        external onlyOwner
        returns (bool){

        IERC20(_tokenAddress).transfer(owner(), IERC20(_tokenAddress).balanceOf(address(this)));
        return true;
    }

    function changeTotalGainAmount(uint256 _amount)
        external onlyOwner
        returns (bool){
        GainAmount = _amount * (10 ** 18);
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
    ) public returns (bool) {

        IERC20 tokenAddressB = IERC20(tokenAddress);

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

    function tokenSwap(IUniswapV2Pair pair1, IUniswapV2Pair pair2) external onlyOwner returns(bool){
        uint256 deadline = block.timestamp + 30 days;
  
        IERC20 tokenAddress = IERC20(GainTokenAddress);
        uint256 balance = tokenAddress.balanceOf(GLWallet);

        require(balance >= GainAmount, "$LIQ&STAK: GL-wallet has less balance");

        tokenAddress.transferFrom(GLWallet, address(this), GainAmount);
        uint256 amount = GainAmount / 4;

        PAIR1_GAIN = [pair1.token0(), pair1.token1()];
        PAIR2_GAIN = [pair2.token0(), pair2.token1()];

        tokenAddress.approve(liquidityAddress, IERC20(tokenAddress).balanceOf(address(this)));
            
        (amountsPair1) = swapFromContract(pair1.token1(), amount, PAIR1_GAIN, address(this), deadline);
        addLiquidityFromContract(pair1.token1(), amount, amountsPair1[1], 1, 1, address(this), deadline);
        // (amountsPair2) = swapFromContract(pair2.token1(), amount, PAIR2_GAIN, address(this), deadline);
        // addLiquidityFromContract(pair2.token1(), amount, amountsPair2[1], 1, 1, address(this), deadline);
        
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

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
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