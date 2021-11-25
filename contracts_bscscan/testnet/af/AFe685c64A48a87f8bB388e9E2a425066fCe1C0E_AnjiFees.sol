/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

/**
 * BNB Distributor
 */

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

/**
 * BEP20 standard interface.
 */ 
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20 {
    function decimals() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//PancakeRouter


// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
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

// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

interface ANJI {
    function depositExternalBNB() external payable;
}

contract AnjiFees is Ownable {
    using SafeMath for uint256;

    //address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    //address public WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; //BSC testnet WBNB address

 //   address public routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //pancakeswap mainnet v2 router address
    address public routerAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;  //pancakeswap testnet router address

    mapping (address => uint) public  balanceOf;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    address public marketingWallet;
    address public charityWallet;
    address public anjiTokenContract;
    uint256 public marketingFee = 33;
    uint256 public charityFee = 34;
    uint256 public anjiFee = 33;
    
    bool public marketingTransferEnabled = true; 
    IUniswapV2Router02 public immutable uniswapV2Router;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived, uint256 tokensIntoLiqudity);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    constructor () {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(routerAddress);
        // Create a uniswap pair for this new token
        //uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
    }
    
     /**
     * @notice set the Anji token address by owner
     *
     * @param _anjiTokenContract: Anji token address
     */
    function setAnjiTokenAddress(address _anjiTokenContract) external onlyOwner {
        anjiTokenContract = _anjiTokenContract;
    }
    
    /**
     * @notice set the marketing wallet address by owner
     *
     * @param _marketingWallet: market wallet address
     */
    function setMarketingWalletAddress(address _marketingWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
    }
    
    /**
     * @notice set the charity wallet address by owner
     *
     * @param _charityWallet: charity wallet address
     */
    function setCharityWalletAddress(address _charityWallet) external onlyOwner {
        charityWallet = _charityWallet;
    }
    
    /**
     * @notice set the marketing wallet fee by owner
     *
     * @param _marketingFee: fee(%) for marketing 
     */
    function setMarketingFee(uint256 _marketingFee) external onlyOwner {
        marketingFee = _marketingFee;
    }
    
    /**
     * @notice set the charity wallet fee by owner
     *
     * @param _charityFee: fee(%) for charity
     */
    function setCharityFee(uint256 _charityFee) external onlyOwner {
        charityFee = _charityFee;
    }
    
    /**
     * @notice set the Anji token fee by owner
     *
     * @param _anjiFee: fee(%) for Anji token contract
     */
    function setAnjiFee(uint256 _anjiFee) external onlyOwner {
        anjiFee = _anjiFee;
    }
    
    /**
     * @notice turn on or off the marketing transfer by owner
     *
     * @param _marketingTransferEnabled: fee(%) for Anji token contract
     */
    function enableMarketingTransfer(bool _marketingTransferEnabled) external onlyOwner {
        marketingTransferEnabled = _marketingTransferEnabled;
    }
    
    /**
     * @notice distribute the dividend
     *
     */
    function distributeDividend() public{
        //uint256 amount = IBEP20(WBNB).balanceOf(address(this));
         
        uint256 amount = address(this).balance;
        require(amount > 0, "Balance is insufficient.");
        
        uint256 amountToMarketing = amount.mul(marketingFee).div(100);
        uint256 amountToCharity = amount.mul(charityFee).div(100);
        uint256 amountToAnji = amount.mul(anjiFee).div(100);
        
        uint256 distributedTotalAmount = amountToMarketing + amountToCharity + amountToAnji;
        require(amount >= distributedTotalAmount, "The amount distributed exceeds the total amount.");
        
        if (!marketingTransferEnabled){
            
			amountToAnji = amountToAnji.add(amountToMarketing);
			amountToMarketing = 0;
        } 
        
        if (amountToMarketing >0) { payable(marketingWallet).transfer(amountToMarketing); }
        if (amountToCharity >0) { payable(charityWallet).transfer(amountToCharity); }
        if (amountToAnji >0) { 
            ANJI(payable(anjiTokenContract)).depositExternalBNB{ value: amountToAnji }();
        }
    }
    
    
    /**
     * @notice return BNB balance of  this contract
     *
     */
    function BNBbalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @notice deposit WBNB from external
     *
     */
    function depositExternalBNB() external payable {
        balanceOf[address(this)] += msg.value;
    }
    
    /**
     * @notice withdraw WBNB from this contract to the "receiver" address
     *
     */
    function withdrawBNB(address receiver) external onlyOwner {
        uint256 BNBBalance = address(this).balance;
        require(BNBBalance > 0, 'Balance is insufficient');
        if (BNBBalance > 0) {
            payable(receiver).transfer(BNBBalance);
        }
    }
    
     /**
     * @notice withdraw any other tokens that are NOT ANJI tokens
     *
     * @param tokenaddress: token address that withdraw
     * @param receiver: receiver address
     */
    function withdrawTokens(address tokenaddress, address receiver) external onlyOwner {
        require(tokenaddress != address(this), 'can not withdraw Anji token');
        uint256 tokenBalance = IBEP20(tokenaddress).balanceOf(address(this));
        if (tokenBalance > 0) {
            IBEP20(tokenaddress).transfer(receiver, tokenBalance);
        }
    }
    
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function checkPCSRouter() public view returns (address,address)  {
        address factoryAddress = uniswapV2Router.factory();
        address wETHaddress = uniswapV2Router.WETH();
        return (factoryAddress, wETHaddress);
    }

    //swap specific tokens for bnb
    
    function swapTokensForBNB(address tokenAddress) public onlyOwner {

        //    uint256 BNBbalance = address(this).balance;
        uint256 tokenbalanceOfThis = IERC20(tokenAddress).balanceOf(address(this));
        require(tokenbalanceOfThis > 0, 'insufficient token balance');

        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = uniswapV2Router.WETH();
        //path[1] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //WBNB address
        //IBEP20(tokenAddress).approve(routerAddress, tokenbalanceOfThis);
        IBEP20(tokenAddress).approve(address(this), tokenbalanceOfThis);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenbalanceOfThis,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
  
    function swapTokensForBNB1(address tokenAddress) public onlyOwner {

        //    uint256 BNBbalance = address(this).balance;
        uint256 tokenbalanceOfThis = IBEP20(tokenAddress).balanceOf(address(this));
        require(tokenbalanceOfThis > 0, 'insufficient token balance');

        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //WBNB address

        //IBEP20(tokenAddress).approve(routerAddress, tokenbalanceOfThis);
        IBEP20(tokenAddress).approve(address(this), tokenbalanceOfThis);
        // make the swap
        uniswapV2Router.swapExactTokensForETH(
            tokenbalanceOfThis,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function swapTokensForBNB2(address tokenAddress) public onlyOwner {

        //    uint256 BNBbalance = address(this).balance;
        uint256 tokenbalanceOfThis = IBEP20(tokenAddress).balanceOf(address(this));
        require(tokenbalanceOfThis > 0, 'insufficient token balance');

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //WBNB address

        //IBEP20(tokenAddress).approve(routerAddress, tokenbalanceOfThis);
        IBEP20(tokenAddress).approve(address(this), tokenbalanceOfThis);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenbalanceOfThis,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
  
    function setRouterAddress(address account) public onlyOwner {

        routerAddress = account;
    }
    receive() external payable { }
}