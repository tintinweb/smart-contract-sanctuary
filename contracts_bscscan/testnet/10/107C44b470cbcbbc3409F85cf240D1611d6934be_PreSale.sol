// SPDX-License-Identifier: MIT
// Creator: Luiz Hemerly - @dreadnaugh

pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../uniswap/v2-core/contracts/interfaces/IUniswapV2Router02.sol";
import "../uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract PreSale is Ownable{

    //@dev mappings for whitelist, buy tokens sent to contract per wallet
    //and sale tokens pending to withdraw
    mapping (address => bool) public isWhitelisted;
    mapping (address => uint) public tokensSent;
    mapping (address => uint) public tokensToWithdraw;

    //@dev variables to define the sale
    uint public price; //price of sale token in buy tokens
    uint public hardCap; //maximum sell amount
    uint public softCap; //minimum amount to go ahead with sale
    uint public minTx; //minimum buy per wallet
    uint public maxTx; //maximum buy per wallet
    uint public liquidityPercentage; //percentage of buy tokens to add to liquidity
    uint public sold; //total sale tokens sold

    //@dev check if there is a whitelist for sale
    bool public isWhitelist;

    //@dev checkers for time lock and liquidity. Checked at withdraw
    bool public lockToPublic = false;
    bool public liquidityAdded = false;

    //UNIX Timestamps
    uint startTime;
    uint endTime;
    uint lock;

    //@dev sale token and buy token pair
    IERC20 saleToken;
    IERC20 buyToken;

    //@dev router to create pair and add liquidity
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    // Pancake: 0x10ED43C718714eb63d5aA57B78B54704E256024E
    // ApeSwap: 0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7

    constructor (uint price_, address saleToken_, address buyToken_,
    uint hardcap_, uint softCap_, uint minTx_, uint maxTx_, uint startTime_,
    uint endTime_, address operator_, uint liquidityPercentage_){

        price = price_;
        saleToken = IERC20(saleToken_);
        buyToken = IERC20(buyToken_);
        hardCap = hardcap_;
        softCap = softCap_;
        minTx = minTx_;
        maxTx = maxTx_;
        liquidityPercentage = liquidityPercentage_*10**16;
        startTime = startTime_;
        endTime = endTime_;
        _transferOwnership(operator_);

    }

    function setLock() external onlyOwner{
        lockToPublic = !lockToPublic;
    }

    function buyTokens(uint amount_) external {

        tokensSent[msg.sender] += amount_;

        require(block.timestamp >= startTime, "Presale: Sale not started yet");
        require(block.timestamp <= endTime, "Presale: Sale ended");
        require(amount_ <= buyToken.balanceOf(msg.sender), "Presale: Not enough tokens to buy!");
        require(tokensSent[msg.sender] >= minTx, "Presale: Lower than minimum value allowed.");
        require(tokensSent[msg.sender] <= maxTx, "Presale: Thank you but you can't buy that much to yourself only!");
        require((buyToken.balanceOf(address(this)) + amount_) <= hardCap, "Presale: Hardcap reached!");
        if (isWhitelist){
            require(isWhitelisted[msg.sender], "Presale: Your wallet is not in the whitelist!");
        }
        tokensToWithdraw[msg.sender] += amount_ / price;
        sold += amount_ / price;

        buyToken.transferFrom(msg.sender, address(this), amount_);
    }

    function extendLock(uint seconds_) external onlyOwner {
        require(block.timestamp <= startTime, "Presale: Already started can't change lock settings.");
        lock += seconds_;
    }

    function addLiquidity(address router, uint publicPrice) external onlyOwner {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        //uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        //    .createPair(address(saleToken), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        uint buyTokenAmount = buyToken.balanceOf(address(this)) * liquidityPercentage / 10**18;

        buyToken.approve(address(uniswapV2Router),
                        buyTokenAmount);

        uniswapV2Router.addLiquidity(
            address(buyToken),
            address(saleToken),
            buyTokenAmount,
            buyTokenAmount/publicPrice,
            0,
            0,
            address(this),
            block.timestamp
        );

        liquidityAdded = true;
    }

    //@dev buyer withdrawAll function
    function withdraw() external {
        require(liquidityAdded, "Presale: Liquidity not added yet.");
        if (lockToPublic){
            require(block.timestamp <= lock, "Presale: Tokens locked.");
        }
        uint _amount = tokensToWithdraw[msg.sender];
        tokensToWithdraw[msg.sender] = 0;
        saleToken.transfer(msg.sender, _amount);
    }

    //@dev buyer withdraw when sale failed
    function emergencyWithdraw() external {
        require(sold < softCap, "Presale: Softcap already reached.");
        uint _amount = tokensToWithdraw[msg.sender];
        tokensToWithdraw[msg.sender] = 0;
        sold -= _amount;
        tokensSent[msg.sender] = 0;
        buyToken.transfer(msg.sender, _amount);
    }

    //@dev dev withdrawAll function
    function devWithdraw() external onlyOwner {
        require(sold >= softCap, "Presale: Softcap not reached yet.");
        require(liquidityAdded, "Presale: Liquidity not added yet.");
        uint _amount = buyToken.balanceOf(address(this));
        buyToken.transfer(owner(), _amount);
    }

    //@dev dev withdrawAll any. Doesn't allow to withdraw own token if softcap is reached
    //reduce the hardcap
    function withdrawAny(address token_) external onlyOwner{
        IERC20 token = IERC20(token_);
        uint _amount;
        require(token != saleToken, "Presale: Use devWithdraw for sale token.");
        _amount = token.balanceOf(address(this));
        token.transfer(owner(), _amount);
    }

    //@dev pass a list to add or remove wallets from the whitelist
    function setWhitelist(address[] memory add, bool remove) external onlyOwner {
        if (remove) {
            for(uint i = 0; i < add.length; i++){
                isWhitelisted[add[i]] = false;
            }
        } else {
            for(uint i = 0; i < add.length; i++){
                isWhitelisted[add[i]] = true;
            }
        }
    }

    function haveWhitelist() external onlyOwner{
        isWhitelist = !isWhitelist;
    }
}

pragma solidity >=0.6.2;

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}