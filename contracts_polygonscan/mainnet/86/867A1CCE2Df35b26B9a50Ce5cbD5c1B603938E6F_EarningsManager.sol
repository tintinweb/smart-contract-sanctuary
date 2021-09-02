/**
 *Submitted for verification at polygonscan.com on 2021-09-02
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File contracts/interfaces/OZ_IERC20.sol
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


// File contracts/DeFi/uniswapv2/interfaces/IUniswapV2Pair.sol

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function HOLDING_ADDRESS() external view returns (address);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function destroy(uint value) external returns(bool);

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

    function handleEarnings() external returns(uint amount);
}


// File contracts/DeFi/uniswapv2/interfaces/IUniswapV2Factory.sol

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


// File contracts/DeFi/uniswapv2/interfaces/IUniswapV2Router01.sol

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


// File contracts/DeFi/uniswapv2/interfaces/IUniswapV2Router02.sol

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


// File contracts/interfaces/IPathOracle.sol


interface IPathOracle {
    /**
     * Assume claimFee uses msg.sender, and returns the amount of WETH sent to the caller
     */
    function appendPath(address token0, address token1) external;

    function stepPath(address from) external view returns(address to);
}


// File contracts/interfaces/IPriceOracle.sol


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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

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


// File contracts/core/EarningsManager.sol







contract EarningsManager is Ownable {
    address public factory;
    IUniswapV2Factory Factory;
    address[] public swapPairs;
    mapping(address => uint256) public swapIndex;
    mapping(address => bool) public whitelist;

    modifier onlyFactory() {
        require(msg.sender == factory, "Gravity Finance: FORBIDDEN");
        _;
    }

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "Caller is not in whitelist!");
        _;
    }

    /**
    * @dev emitted when a new pair is added to the earnings manager
    * @param pairAddress the address of the newly added pair
    **/
    event pairAdded(address pairAddress);

    /**
    * @dev emitted when owner changes the whitelist
    * @param _address the address that had its whitelist status changed
    * @param newBool the new state of the address
    **/
    event whiteListChanged(address _address, bool newBool);

    /** 
    * @dev emitted when owner calls adminWithdraw
    * @param asset the address of the asset that was moved out of the fee manager
    **/
    event AdminWithdrawCalled(address asset);

    constructor(address _factory) {
        swapPairs.push(address(0));
        factory = _factory;
        Factory = IUniswapV2Factory(factory);
    }

    function addSwapPair(address pairAddress) external onlyFactory {
        require(swapIndex[pairAddress] == 0, "Already have pair catalouged");
        swapPairs.push(pairAddress);
        swapIndex[pairAddress] = swapPairs.length;

    }

    function adjustWhitelist(address _address, bool _bool) external onlyOwner {
        whitelist[_address] = _bool;
        emit whiteListChanged(_address, _bool);
    }

    function validTimeWindow(address pairAddress) public returns (uint valid, uint expires){
        IPriceOracle PriceOracle = IPriceOracle(Factory.priceOracle());
        //Assume there are only two swaps to get to the pool assets
        // swap wETH to GFI, and swap 1/2 GFI to Other

        //Two pair addresses to worry about is this one pairAddress, and the weth/gfi pair
        
        //Call get price to update prices on both pairs
        PriceOracle.getPrice(pairAddress);
        address firstAddress = Factory.getPair(Factory.weth(), Factory.gfi());
        PriceOracle.getPrice(firstAddress);

        //*****CHECK IF WE NEED TO LOOK AT ALTs
        (uint pairACurrentTime, uint pairAOtherTime) = PriceOracle.getOracleTime(firstAddress);
        (uint pairBCurrentTime, uint pairBOtherTime) = PriceOracle.getOracleTime(pairAddress);
        
        uint pairATimeTillExpire = pairACurrentTime + PriceOracle.priceValidEnd();
        uint pairATimeTillValid = pairACurrentTime + PriceOracle.priceValidStart();
        uint pairBTimeTillExpire = pairBCurrentTime + PriceOracle.priceValidEnd();
        uint pairBTimeTillValid = pairBCurrentTime + PriceOracle.priceValidStart();
        //Check if weth/gfi price time till valid is greater than pairAddress time till expires
        if ( pairATimeTillValid > pairBTimeTillExpire) {
            //Check if pairBs other time till valid is less than pairAs current time till expire
            if (pairBOtherTime + PriceOracle.priceValidStart() < pairATimeTillExpire){
                //If this is true, then we want to use pairBs other saved timestamp
                pairBTimeTillExpire = pairBOtherTime + PriceOracle.priceValidEnd();
                pairBTimeTillValid = pairBOtherTime + PriceOracle.priceValidStart();
            }
            //potentially add an else statment, not sure if you would ever make it here though
        }
        // Check if pairAddress price time till valid is greater than weth/gfi time till expires
        else if ( pairBTimeTillValid > pairATimeTillExpire){
            //Check if pairAs other time till valid is less than pairBs current time till expire
            if (pairAOtherTime + PriceOracle.priceValidStart() < pairBTimeTillExpire){
                //If this is true, then we want to use pairAs other saved timestamp
                pairATimeTillExpire = pairAOtherTime + PriceOracle.priceValidEnd();
                pairATimeTillValid = pairAOtherTime + PriceOracle.priceValidStart();
            }
            //potentially add an else statment, not sure if you would ever make it here though
        }
        //Now set the min time till valid, and max time till expire
        if (pairATimeTillValid > pairBTimeTillValid){
            valid = pairATimeTillValid;
        }
        else {
            valid = pairBTimeTillValid;
        }
        if (pairATimeTillExpire < pairBTimeTillExpire){
            expires = pairATimeTillExpire;
        }
        else {
            expires = pairBTimeTillExpire;
        }
    }

    /**
    * @dev emitted whenever whitelist address calls either the oracle or manual ProcessEarnings
    * @param pairAddress the address of the pair that just had it's earnings processed
    * @param timestamp the timestamp for when the earnings were processed
    **/
    event earningsProcessed(address pairAddress, uint timestamp);
    /**
    * @dev Will revert if prices are not valid, validTimeWindow() should be called before calling any functions that use price oracles to get min amounts
    * known inefficiency if target pair is wETH/GFI, it will trade all the wETH for GFI, then swap half the GFI back into wETH
    * @param pairAddress the address of the pair that you want to handle earnings for
    **/
    function oracleProcessEarnings(address pairAddress) external onlyWhitelist {
        address token0 = IUniswapV2Pair(pairAddress).token0();
        address token1 = IUniswapV2Pair(pairAddress).token1();
        uint256 minAmount;
        uint256 timeTillValid;
        uint256 slippage = Factory.slippage();
        address[] memory path = new address[](2);
        uint256 earnings = IUniswapV2Pair(pairAddress).handleEarnings(); //Delegates Earnings to a holding contract, and holding approves earnings manager to spend earnings
        require(
            OZ_IERC20(Factory.weth()).transferFrom(
                IUniswapV2Pair(pairAddress).HOLDING_ADDRESS(),
                address(this),
                earnings
            ),
            "Failed to transfer wETH from holding to EM"
        );
        uint256[] memory amounts = new uint256[](2);
        //First swap wETH into GFI
        address firstPairAddress =
            Factory.getPair(Factory.weth(), Factory.gfi());
        (minAmount, timeTillValid) = IPriceOracle(Factory.priceOracle())
            .calculateMinAmount(
            Factory.weth(),
            slippage,
            earnings,
            firstPairAddress
        );
        require(timeTillValid == 0, "Price(s) not valid Call validTimeWindow()");
        path[0] = Factory.weth();
        path[1] = Factory.gfi();
        OZ_IERC20(Factory.weth()).approve(Factory.router(), earnings);
        amounts = IUniswapV2Router02(Factory.router()).swapExactTokensForTokens(
            earnings,
            minAmount,
            path,
            address(this),
            block.timestamp
        );

        //Swap 1/2 GFI into other asset
        (minAmount, timeTillValid) = IPriceOracle(Factory.priceOracle())
            .calculateMinAmount(Factory.gfi(), slippage, (amounts[1] / 2), pairAddress);
        require(timeTillValid == 0, "Price(s) not valid Call validTimeWindow()");
        path[0] = Factory.gfi();
        if (token0 == Factory.gfi()) {
            path[1] = token1;
        } else {
            path[1] = token0;
        }
        //amounts[1] = amounts[1] * 9995 / 10000;
        OZ_IERC20(Factory.gfi()).approve(Factory.router(), (amounts[1] / 2));
        amounts = IUniswapV2Router02(Factory.router()).swapExactTokensForTokens(
            (amounts[1] / 2),
            minAmount,
            path,
            address(this),
            block.timestamp
        );

        //amounts[1] = amounts[1] * 9995 / 10000;
        if(amounts[0] > OZ_IERC20(path[0]).balanceOf(address(this))){
            amounts[0] = OZ_IERC20(path[0]).balanceOf(address(this));
        }
        if(amounts[1] > OZ_IERC20(path[1]).balanceOf(address(this))){
            amounts[1] = OZ_IERC20(path[1]).balanceOf(address(this));
        }
        uint256 token0Var = (slippage * amounts[0]) / 100;
        uint256 token1Var = (slippage * amounts[1]) / 100;
        OZ_IERC20(path[0]).approve(Factory.router(), amounts[0]);
        OZ_IERC20(path[1]).approve(Factory.router(), amounts[1]);
        (token0Var, token1Var,) = IUniswapV2Router02(Factory.router()).addLiquidity(//reuse tokenVars to avoid stack to deep errors
            path[0],
            path[1],
            amounts[0],
            amounts[1],
            token0Var,
            token1Var,
            address(this),
            block.timestamp
        );
        
        IUniswapV2Pair LPtoken = IUniswapV2Pair(pairAddress);
        require(
            LPtoken.destroy(LPtoken.balanceOf(address(this))),
            "Failed to burn LP tokens"
        );
        if((amounts[0] - token0Var) > 0){OZ_IERC20(path[0]).transfer(Factory.dustPan(), (amounts[0] - token0Var));}
        if((amounts[1] - token1Var) > 0){OZ_IERC20(path[1]).transfer(Factory.dustPan(), (amounts[1] - token1Var));}
        emit earningsProcessed(pairAddress, block.timestamp);
    }


    /**
    * @dev to be used if on chain oracle pricing is failing, whitelist address will use their own price oracle to calc minAmounts
    * known inefficiency if target pair is wETH/GFI, it will trade all the wETH for GFI, then swap half the GFI back into wETH
    * @param pairAddress the address of the pair that you want to handle earnings for
    **/
    function manualProcessEarnings(address pairAddress, uint[2] memory minAmounts) external onlyWhitelist{
        uint256 tokenBal;
        uint256 slippage = Factory.slippage();
        address[] memory path = new address[](2);
        uint256 earnings = IUniswapV2Pair(pairAddress).handleEarnings(); //Delegates Earnings to a holding contract, and holding approves earnings manager to spend earnings
        require(
            OZ_IERC20(Factory.weth()).transferFrom(
                IUniswapV2Pair(pairAddress).HOLDING_ADDRESS(),
                address(this),
                earnings
            ),
            "Failed to transfer wETH from holding to EM"
        );

        //So don't even need to call checkPrice here, this will fail if one of the prices isn't valid, so should make a seperate function that makes sure
        uint256[] memory amounts = new uint256[](2);
        //First swap wETH into GFI
        path[0] = Factory.weth();
        path[1] = Factory.gfi();
        OZ_IERC20(Factory.weth()).approve(Factory.router(), earnings);
        amounts = IUniswapV2Router02(Factory.router()).swapExactTokensForTokens(
            earnings,
            minAmounts[0],
            path,
            address(this),
            block.timestamp
        );

        //Swap 1/2 GFI into other asset
        tokenBal = amounts[1] / 2;
        path[0] = Factory.gfi();
        if (IUniswapV2Pair(pairAddress).token0() == Factory.gfi()) {
            path[1] = IUniswapV2Pair(pairAddress).token1();
        } else {
            path[1] = IUniswapV2Pair(pairAddress).token0();
        }
        OZ_IERC20(Factory.gfi()).approve(Factory.router(), (amounts[1] / 2));
        amounts = IUniswapV2Router02(Factory.router()).swapExactTokensForTokens(
            tokenBal,
            minAmounts[1],
            path,
            address(this),
            block.timestamp
        );

        OZ_IERC20 Token0 = OZ_IERC20(path[0]);
        OZ_IERC20 Token1 = OZ_IERC20(path[1]);

        uint256 minToken0 = (slippage * amounts[0]) / 100;
        uint256 minToken1 = (slippage * amounts[1]) / 100;
        Token0.approve(Factory.router(), amounts[0]);
        Token1.approve(Factory.router(), amounts[1]);

        (uint amountA, uint amountB,) = IUniswapV2Router02(Factory.router()).addLiquidity(
            path[0],
            path[1],
            amounts[0],
            amounts[1],
            minToken0,
            minToken1,
            address(this),
            block.timestamp
        );

        IUniswapV2Pair LPtoken = IUniswapV2Pair(pairAddress);
        require(
            LPtoken.destroy(LPtoken.balanceOf(address(this))),
            "Failed to burn LP tokens"
        );
        //Send remaining dust to dust pan
        if((amounts[0] - amountA) > 0){Token0.transfer(Factory.dustPan(), (amounts[0] - amountA));}
        if((amounts[1] - amountB) > 0){Token1.transfer(Factory.dustPan(), (amounts[1] - amountB));}
        emit earningsProcessed(pairAddress, block.timestamp);
    }

    /**
    * @dev should rarely be used, intended use is to collect dust and redistribute it to appropriate swap pools
    * Needed bc the price oracle earnings method has stack too deep errors when adding in transfer to Dust pan
    **/
    function adminWithdraw(address asset) external onlyOwner{
        //emit an event letting everyone know this was used
        OZ_IERC20 token = OZ_IERC20(asset);
        token.transfer(msg.sender, token.balanceOf(address(this)));
        emit AdminWithdrawCalled(asset);
    }
}