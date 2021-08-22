/**
 *Submitted for verification at polygonscan.com on 2021-08-22
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface OZ_IERC20 {
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



interface IPathOracle {
    /**
     * Assume claimFee uses msg.sender, and returns the amount of WETH sent to the caller
     */
    function appendPath(address token0, address token1) external;

    function stepPath(address from) external view returns(address to);
}



interface IPriceOracle {
    /**
     * Assume claimFee uses msg.sender, and returns the amount of WETH sent to the caller
     */

    struct oracle {
        uint[2] price0Cumulative;
        uint[2] price1Cumulative;
        uint32[2] timeStamp;
        uint8 index; // 0 or 1
    }

    function getPrice(address pairAddress) external returns (uint price0Average, uint price1Average, uint timeTillValid);

    function calculateMinAmount(address from, uint256 slippage, uint256 amount, address pairAddress) external returns (uint minAmount, uint timeTillValid);

    function getOracleTime(address pairAddress) external view returns(uint currentTimestamp, uint otherTimestamp);

    function priceValidStart() external view returns(uint);
    function priceValidEnd() external view returns(uint);
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


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);
    function weth() external view returns (address);
    function wbtc() external view returns (address);
    function gfi() external view returns (address);
    function earningsManager() external view returns (address);
    function feeManager() external view returns (address);
    function dustPan() external view returns (address);
    function governor() external view returns (address);
    function priceOracle() external view returns (address);
    function pathOracle() external view returns (address);
    function router() external view returns (address);
    function paused() external view returns (bool);
    function slippage() external view returns (uint);


    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}


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



interface iGovernance {
    /**
     * Assume claimFee uses msg.sender, and returns the amount of WETH sent to the caller
     */
    function delegateFee(address reciever) external returns (uint256);

    function claimFee() external returns (uint256);

    function tierLedger(address user, uint index) external returns(uint);

    function depositFee(uint256 amountWETH, uint256 amountWBTC) external;

    function Tiers(uint index) external returns(uint);
}








contract FeeManager is Ownable {
    address[] public tokenList;
    mapping(address => uint256) public tokenIndex;
    address public factory;
    mapping(address => bool) public whitelist;
    IUniswapV2Factory Factory;

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "Caller is not in whitelist!");
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Gravity Finance: FORBIDDEN");
        _;
    }

    /**
    * @dev emitted when owner changes the whitelist
    * @param _address the address that had its whitelist status changed
    * @param newBool the new state of the address
    **/
    event whiteListChanged(address _address, bool newBool);

    /**
    * @dev emitted when catalougeTokens is called by factory
    * @param token0 the first token address of the swap pair
    * @param token1 the second token address of the swap pair
    **/
    event addTokens(address token0, address token1);

    /**
    * @dev emitted when fees are deposited into governance contract
    * @param amountWETH the amount of wETH deposited into the governance contract
    * @param amountWBTC the amount of wBTC deposited into the governance contract
    **/
    event feeDeposited(uint amountWETH, uint amountWBTC);

    /** 
    * @dev emitted when the fee manager makes a swap
    * @param from the address of the token it swapped from
    * @param to the address of the token it swapped into
    **/
    event swapped(address from, address to);

    /** 
    * @dev emitted when owner calls adminWithdraw
    * @param asset the address of the asset that was moved out of the fee manager
    **/
    event AdminWithdrawCalled(address asset);

    constructor(address _factory) {
        tokenList.push(address(0)); //populate the 0 index with the zero address
        factory = _factory;
        Factory = IUniswapV2Factory(factory);
    }

    /**
    * @dev called by owner to change the privelages for an address
    * @param _address the address that you want its privelages changed
    * @param _bool the new privelage for that address
    **/
    function adjustWhitelist(address _address, bool _bool) external onlyOwner {
        whitelist[_address] = _bool;
        emit whiteListChanged(_address, _bool);
    }

    /**
    * @dev When swap pairs are created, add their tokens to the tokenList if not already in it
    * @param token0 the first token address of the swap pair
    * @param token1 the second token address of the swap pair
    **/
    function catalougeTokens(address token0, address token1) external onlyFactory{
        if (tokenIndex[token0] == 0) {
            tokenList.push(token0);
            tokenIndex[token0] = tokenList.length - 1;
        }

        if (tokenIndex[token1] == 0) {
            tokenList.push(token1);
            tokenIndex[token1] = tokenList.length - 1;
        }
        emit addTokens(token0, token1);
    }

    /** 
    * @dev used to deposit wETH and wBTC into governance contract
    **/
    function deposit() external onlyWhitelist {
        OZ_IERC20 weth = OZ_IERC20(Factory.weth());
        OZ_IERC20 wbtc = OZ_IERC20(Factory.wbtc());
        uint256 amountWETH = weth.balanceOf(address(this));
        uint256 amountWBTC = wbtc.balanceOf(address(this));
        weth.approve(Factory.governor(), amountWETH);
        wbtc.approve(Factory.governor(), amountWBTC);
        iGovernance(Factory.governor()).depositFee(amountWETH, amountWBTC);
        emit feeDeposited(amountWETH, amountWBTC);
    }

    /** 
    * @dev used to get the time window for when it is valid to call oracleStepSwap without reverting
    * @param asset the asset you want to convert into the next asset in the path
    * @return valid expiration the unix timestamp for when price will be valid, and for when it will expire
    **/
    function validTimeWindow(address asset) external returns(uint valid, uint expiration){
        IPriceOracle PriceOracle = IPriceOracle(Factory.priceOracle());
        address nextAsset = IPathOracle(Factory.pathOracle()).stepPath(asset);
        address pairAddress = Factory.getPair(asset, nextAsset);
        
        //Call get price
        PriceOracle.getPrice(pairAddress);

        (uint pairCurrentTime,) = PriceOracle.getOracleTime(pairAddress);
        
        expiration = pairCurrentTime + PriceOracle.priceValidEnd();
        valid = pairCurrentTime + PriceOracle.priceValidStart();
    }

    /** 
    * @dev allows whitelist addresses to swap assets using oracles
    * @param asset the address of the token you want to swap for the next asset in the PathOracle pathMap
    * @param half a bool indicating whether or not to only swap half of the amount of the asset
    **/
    function oracleStepSwap(address asset, bool half) external onlyWhitelist{
        uint tokenBal = OZ_IERC20(asset).balanceOf(address(this));
        if(half){
            tokenBal / 2;
        }
        address[] memory path = new address[](2);
        address nextAsset = IPathOracle(Factory.pathOracle()).stepPath(asset);
        address pairAddress = Factory.getPair(asset, nextAsset);
        (uint minAmount, uint timeTillValid) = IPriceOracle(Factory.priceOracle())
            .calculateMinAmount(asset, Factory.slippage(), tokenBal, pairAddress);
        require(timeTillValid == 0, "Price(s) not valid Call checkPrice()");
        OZ_IERC20(asset).approve(Factory.router(), tokenBal);
        path[0] = asset;
        path[1] = nextAsset;
        IUniswapV2Router02(Factory.router()).swapExactTokensForTokens(
            tokenBal,
            minAmount,
            path,
            address(this),
            block.timestamp
        );
        emit swapped(path[0], path[1]);
    }

    /** 
    * @dev allows whitelist addresses to swap assets by manually providing the minimum amount
    * @param asset the address of the token you want to swap for the next asset in the PathOracle pathMap
    * @param half a bool indicating whether or not to only swap half of the amount of the asset
    * @param minAmount the minimum amount of the other asset the swap exchange should return
    **/
    function manualStepSwap(address asset, bool half, uint minAmount) external onlyWhitelist{

        uint tokenBal = OZ_IERC20(asset).balanceOf(address(this));
        if(half){
            tokenBal / 2;
        }
        tokenBal = OZ_IERC20(asset).balanceOf(address(this));
        address[] memory path = new address[](2);
        address nextAsset = IPathOracle(Factory.pathOracle()).stepPath(asset);
        OZ_IERC20(asset).approve(Factory.router(), tokenBal);
        path[0] = asset;
        path[1] = nextAsset;
        IUniswapV2Router02(Factory.router()).swapExactTokensForTokens(
            tokenBal,
            minAmount,
            path,
            address(this),
            block.timestamp
        );
        emit swapped(path[0], path[1]);
    }

    /** 
    * @dev only called in case of emergency, allows owner to move fees out of fee manager
    * @param asset the address of the asset to move out of fee manager
    **/
    function adminWithdraw(address asset) external onlyOwner{
        OZ_IERC20 token = OZ_IERC20(asset);
        token.transfer(msg.sender, token.balanceOf(address(this)));
        emit AdminWithdrawCalled(asset);
    }
}