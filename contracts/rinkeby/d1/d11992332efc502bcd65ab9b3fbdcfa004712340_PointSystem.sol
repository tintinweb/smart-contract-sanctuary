/**
 *Submitted for verification at Etherscan.io on 2021-06-19
*/

//SPDX-License-Identifier: UNLICENSED



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


interface IPancakeRouter01 {
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

interface IPancakeRouter02 is IPancakeRouter01 {
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

pragma solidity ^0.8.4;

contract PointSystem is Ownable{
    
    IERC20 public MNG; //Token contract address
    
    uint8 private immutable decimals; // Decimals of the token
    
    IERC20 private constant USDT = IERC20(0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02); //USDT on binance chain
    
    mapping(address => mapping(uint8 => uint256)) private userPoints; //Mapping to store points
    mapping(address => uint256) private userUSDT;
    IPancakeRouter02 public _pancakeV2Router;
    uint256[50] public ratio = [10,15,20,25,30,35,40,45,50]; //Ratio store

    event PointsBought(uint256 token, uint8 ratio, uint256 points);
    event RatioChanged(uint8 ratioSelector,uint256 ratioValue);
    event PointsSold(uint256 USDTAmount, uint256 MNGReceived);
    event TokensConverted(uint256 amount, uint256 receivedUSDT);
    event MNGBought(uint value, uint finalBalance);

    constructor(IERC20 _MNG, uint8 _decimals){
        MNG = _MNG;
        decimals = _decimals;
        _pancakeV2Router = IPancakeRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        USDT.approve(address(_pancakeV2Router),1 * 10**18 * 10**18); //Huge approval
        MNG.approve(address(_pancakeV2Router),1 * 10**18 * 10**18);
    }

/*
    Function to buy points using token
    
    tokenAmount = Amount of token you want to spend
    ratioSelector = On which ratio you want to receive points

    **Important! You must approve tokens before calling this function
    Approve this contract to spend MNG tokens on your behalf

*/
    function buyPoints(uint256 tokenAmount, uint8 ratioSelector) external {
        require(MNG.allowance(msg.sender,address(this)) >= tokenAmount,"Set allowance first!");
        MNG.transferFrom(msg.sender,address(this),tokenAmount);

        uint256 points = (tokenAmount * ratio[ratioSelector]) / 10 ** decimals;
        userPoints[msg.sender][ratioSelector] += points;
        
        require(userPoints[msg.sender][ratioSelector] >= points,"You don't have enough points");
        userPoints[msg.sender][ratioSelector] -= points;
        
        _convertToUSDT(tokenAmount);
        
        emit PointsBought(tokenAmount,ratioSelector,points);
        
    }
    
    function buyMNG(address recepient) external payable {
        require(msg.value > 0,"BNB amount must be greater than 0");
        uint initBalance = MNG.balanceOf(recepient);
        swapBNBForTokens(msg.value,address(MNG),recepient);
        uint finalBalance = MNG.balanceOf(recepient) - initBalance;
        emit MNGBought(msg.value,finalBalance);
    }

/*
    Function to sell points and receive token
    
    amountUSDT = amount of USDT you want to sell for tokens
    
    **You can only sell USDT you got from the time of buy

*/     
    function sellPoints(uint256 amountUSDT) external {
        require(userUSDT[msg.sender] >= amountUSDT,"You don't have enough points");

        require(USDT.balanceOf(address(this)) >= amountUSDT,"Not enough USDT to sell");

        uint256 initBalanceBNB = address(this).balance;
        swapTokensForBNB(amountUSDT,address(USDT));
        uint256 receivedBNB = address(this).balance - initBalanceBNB;
        
        uint256 initBalanceMNG = MNG.balanceOf(address(this));
        swapBNBForTokens(receivedBNB,address(MNG),address(this));
        uint256 receivedMNG = MNG.balanceOf(address(this)) - initBalanceMNG;
        
        userUSDT[msg.sender] -= amountUSDT;
        
        MNG.transfer(msg.sender,receivedMNG);
        
        emit PointsSold(amountUSDT,receivedMNG);
    }
    
// Internal function to convert token to USDT

    function _convertToUSDT(uint256 amount) internal {
        uint256 initBalanceBNB = address(this).balance;
        swapTokensForBNB(amount,address(MNG));
        uint256 receivedBNB = address(this).balance - initBalanceBNB;
        
        uint256 initBalanceUSDT = USDT.balanceOf(address(this));
        swapBNBForTokens(receivedBNB,address(USDT),address(this));
        uint256 receivedUSDT = USDT.balanceOf(address(this)) - initBalanceUSDT;
        
        userUSDT[tx.origin] += receivedUSDT;
        
        emit TokensConverted(amount,receivedUSDT);
    }

// Internal function to swap tokens for BNB in pancakeswap 

    function swapTokensForBNB(uint256 tokenAmount, address token) private {
        // generate the pancakeswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = _pancakeV2Router.WETH();

        // make the swap
        _pancakeV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }
    
// Internal function to convert BNB to tokens on pancakeswap    
    function swapBNBForTokens(uint256 bnbAmount, address token, address recepient) private {

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = _pancakeV2Router.WETH();
        path[1] = token;

        // make the swap
        _pancakeV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmount}(
            0, // accept any amount of BNB
            path,
            recepient,
            block.timestamp + 360
        );
    }
    

// Owner view function to see anyones point balance in each ratio
    function getPoints(address addr, uint8 ratioSelector) external view returns (uint256) {
        return(userPoints[addr][ratioSelector]);
    }

// Can be called to withdraw any tokens send to this contract. Including MNG token!
    function transferAnyBEP20(address _tokenAddress, address _to, uint _amount) external onlyOwner {
        IERC20(_tokenAddress).transfer(_to, _amount);
    }
    
// To modify ratio system. Maximum 50 ratio allowed
    function modifyRatio(uint8 ratioSelector, uint256 ratioValue) external onlyOwner {
        ratio[ratioSelector] = ratioValue;
        emit RatioChanged(ratioSelector,ratioValue);
    }
}