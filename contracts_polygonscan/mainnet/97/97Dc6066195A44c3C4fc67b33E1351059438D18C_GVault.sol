/**
 *Submitted for verification at polygonscan.com on 2021-07-07
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity >0.8.0;

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
    
    
    // RESERVED FOR ONLY LP TOKEN
    function getReserves() external returns (uint256);

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

interface GFarmPool {

    /*
        Takes earning in GFarm
    */
    function harvest() external;

    /*
        Adds LPs
    */
    function stake(uint amount, address referral) external; 

    /*
        Adds an NFT
    */
    function stakeNft(uint nftType, uint nftId) external;

    /*
        Removes NFT by index
    */
    function unstakeNft(uint nftIndex) external;

    /*
        Removes LP from pool
    */
    function unstake(uint amount) external;
    
    /*
        View APR
    */
    function apy() external view returns (uint);
    
    function userNfts(address a, uint nftIndex) external view returns (uint, uint);
    
}

interface INFT {
    function transferFrom(address from, address to, uint tokenId) external;
    function approve(address to, uint256 TokenId) external;
}

// ====================================================================================================================================================
// CONTRACT BEGINS HERE

contract GVault is Ownable {
    
    using SafeMath for uint;

    struct NFT {
        uint nftId;
        uint nftType;
        address owner;
    }

    event LPDeposit(
        uint amount,
        address who
    );

    event LPWithdraw(
        uint amount,
        address who
    );
    
    IUniswapV2Router02 public immutable uniswapV2Router;

    IUniswapV2Pair public LPToken;
    IERC20 public immutable GFarmToken;
    IERC20 public immutable DAIToken;
    GFarmPool public immutable gfarmPool;
    
    INFT public immutable NFT3; //75x
    INFT public immutable NFT4; //100x
    INFT public immutable NFT5; //150x
    
    address private devg = 0x09c8FcfC626Fe827D4B761F38863d481D450De27;
    address private devh = 0xDa341fBC656333329837F662787c8b8105c1FC49;
    uint256 private devFee = 50; // in BP
    uint256 private nftFee = 30; // Per NFT, in BP
    
    function setDevFee(uint256 amountBP) public onlyOwner { // 200 is 20%
        require(amountBP <= 200);
        devFee = amountBP;
    }
    function setNFTFee(uint256 amountBPperNFT) public onlyOwner { // 50 is 5%
        require(amountBPperNFT <= 50);
        nftFee = amountBPperNFT;
    }
    
    mapping(address => uint) public balanceOf;
    mapping(uint => address) public users;
    mapping(address => bool) public userExists;
    mapping(uint => NFT) public NFTList;
    
    uint private dayCounter = 0;    
    mapping(uint => uint) private dayRewards;
    mapping(uint => uint) private dayTVL;
    uint private nextDay;
    

    
    // NFT BOOST VALUES
    uint[] private boostValues = [50, 75, 100];
    
    // SET NEW BOOST VALUES IN CASE GFARM NFT BOOST VALUED GET UPDATED - THIS IS FOR AESTHETIC PURPOSES ONLY, DOESN'T AFFECT VAULT PERFORMANCE
    function setNFTBoostValues(uint gold, uint plat, uint diam) public onlyOwner {
        boostValues = [gold, plat, diam];
    }
    
  
  	// CHECKS THE AMOUNT OF EACH NFT
    function numberOfNFT3() private view returns(uint) {
        uint counter = 0;
        for (uint i=0; i<5; i++) {
            if (NFTList[i].nftType == 3) {
                counter++;
            }
        }
        return counter;
    }
    
    function numberOfNFT4() private view returns(uint) {
        uint counter = 0;
        for (uint i=0; i<5; i++) {
            if (NFTList[i].nftType == 4) {
                counter++;
            }
        }
        return counter;
    }
    
    function numberOfNFT5() private view returns(uint) {
        uint counter = 0;
        for (uint i=0; i<5; i++) {
            if (NFTList[i].nftType == 5) {
                counter++;
            }
        }
        return counter;
    }

    function numberOfNFTs() private view returns(uint) {
        return (numberOfNFT3() + numberOfNFT4() + numberOfNFT5());
    }
	
    uint public totalBalance = 0;
    uint public numberOfUsers = 0;
    
    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        IERC20 _GFarmToken = IERC20(0x7075cAB6bCCA06613e2d071bd918D1a0241379E2);
        IERC20 _DAIToken = IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
        IUniswapV2Pair _LPToken = IUniswapV2Pair(0x0c7AD41d3E0DBC1CFdcdD717AfB0A72A65cDf069);
        GFarmPool _gfarmPool = GFarmPool(0x780BEDfcE47AD1C665c270616da09230E7036116);
        INFT _NFT3 = INFT(0x3378AD81D09DE23725Ee9B9270635c97Ed601921);
        INFT _NFT4 = INFT(0x02e2c5825C1a3b69C0417706DbE1327C2Af3e6C2);
        INFT _NFT5 = INFT(0x2D266A94469d05C9e06D52A4D0d9C23b157767c2);
        NFT3 = _NFT3;
        NFT4 = _NFT4;
        NFT5 = _NFT5;
        GFarmToken = _GFarmToken;
        DAIToken = _DAIToken;
        LPToken = _LPToken;
        gfarmPool = _gfarmPool;
        uniswapV2Router = _uniswapV2Router;
        LPToken.approve(0x780BEDfcE47AD1C665c270616da09230E7036116, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        LPToken.approve(address(this), 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        
        nextDay = block.timestamp + 39200;
        
        // Set NFTs 0-4 to empty (don't know if necessary but just in case)
        
        NFTList[0].nftType = 0;
        NFTList[0].owner = address(0);
        NFTList[0].nftId = 0;
        
        NFTList[1].nftType = 0;
        NFTList[1].owner = address(0);
        NFTList[1].nftId = 0;
        
        NFTList[2].nftType = 0;
        NFTList[2].owner = address(0);
        NFTList[2].nftId = 0;
        
        NFTList[3].nftType = 0;
        NFTList[3].owner = address(0);
        NFTList[3].nftId = 0;
        
        NFTList[4].nftType = 0;
        NFTList[4].owner = address(0);
        NFTList[4].nftId = 0;
    }
    
    
    
    // ============================================================================================================================================
    // NFT functions below
    
    
    function depositNFT(uint _type, uint id) public {
        require(2 < _type && _type < 6, "INVALID NFT TYPE");
        require(numberOfNFT5() < 5, "Full NFTs"); // MUST HAVE AVAILABLE SLOT - CAN'T HAVE WITH 5 150x NFTs
        
        // COMPOUND POOL BEFORE DEPOSIT
        compound();

        if(_type == 4) require(numberOfNFT4()+numberOfNFT5() < 5, "Full until 150x");
        if(_type == 3) require(numberOfNFT3()+numberOfNFT4()+numberOfNFT5() < 5, "Full until 100x or 150x");
        
        // GETS THE SMALLEST NFT
        uint toBeReplaced = getSmallestNFTType();
        
        // LOOKS OVER ALL 5 NFT SLOTS
        for(uint i=0; i<5; i++) {
            
            // IF THERE ARE NO EMPTY NFT SLOTS
            if(NFTList[i].nftType > toBeReplaced && toBeReplaced != 0) {

                // 1. UNSTAKE SMALLEST NFT AND TRANSFER IT TO ORIGINAL OWNER
                gfarmPool.unstakeNft(NFTList[i].nftId);
                if (NFTList[i].nftType == 3) {
                    NFT3.transferFrom(address(this), NFTList[i].owner, NFTList[i].nftId);
                }
                if (NFTList[i].nftType == 4) {
                    NFT4.transferFrom(address(this), NFTList[i].owner, NFTList[i].nftId);
                }

                // 2. REPLACE THE OLD NFT WITH NEW NFT IN MAPPING
                NFTList[i].nftType = _type;
                NFTList[i].nftId = id;
                NFTList[i].owner = _msgSender();
                
                // 3. TRANSFER NEW NFT FROM THE OWNER TO THIS CONTRACT AND APPROVES GFARM POOL FOR SPENDING - CHECKS TYPE
                if (NFTList[i].nftType == 3) {
                    NFT3.transferFrom(NFTList[i].owner, address(this), id);
                    NFT3.approve(address(gfarmPool), NFTList[i].nftId);
                }
                if (NFTList[i].nftType == 4) {
                    NFT4.transferFrom(NFTList[i].owner, address(this), id);
                    NFT4.approve(address(gfarmPool), NFTList[i].nftId);
                }
                if (NFTList[i].nftType == 5) {
                    NFT5.transferFrom(NFTList[i].owner, address(this), id);
                    NFT5.approve(address(gfarmPool), NFTList[i].nftId);
                }
                
                // 4. STAKE THE NEW NFT INTO THE GFARM POOL
                gfarmPool.stakeNft(_type, id);
                
                // 5. BREAK THE LOOP
                break;
            }
            
            // IF THERE ARE EMPTY NFT SLOTS
            if (toBeReplaced == 0 && NFTList[i].nftType == 0) {
                
                // 1. REPLACE THE EMPTY SLOT WITH NFT IN MAPPING
                NFTList[i].nftType = _type;
                NFTList[i].nftId = id;
                NFTList[i].owner = _msgSender();
                
                // 2. TRANSFER NFT FROM THE OWNER TO THIS CONTRACT - CHECKS TYPE
                if (NFTList[i].nftType == 3) {
                    NFT3.transferFrom(NFTList[i].owner, address(this), id);
                    NFT3.approve(address(gfarmPool), NFTList[i].nftId);
                }
                if (NFTList[i].nftType == 4) {
                    NFT4.transferFrom(NFTList[i].owner, address(this), id);
                    NFT4.approve(address(gfarmPool), NFTList[i].nftId);
                }
                if (NFTList[i].nftType == 5) {
                    NFT5.transferFrom(NFTList[i].owner, address(this), id);
                    NFT5.approve(address(gfarmPool), NFTList[i].nftId);
                }
                
                // 3. STAKE THE NFT INTO THE GFARM POOL
                gfarmPool.stakeNft(_type, id);
                
                // 4. BREAK THE LOOP
                break;
            }
        }
    }
  
  
  	function withdrawNFT(uint id) public {
  	    
  	    uint index = nftIdToIndex(id);
  	    
  	    // COMPOUND VAULT BEFORE WITHDRAWING NFT
  	    compound();
        
        for (uint i=0; i<5; i++) {
            // CHECKS FOR NFT OWNERSHIP & ID
            if (NFTList[i].owner == msg.sender && NFTList[i].nftId == id) {
            
                // UNSTAKES NFT FROM GFARM POOL
                gfarmPool.unstakeNft(index);
            
                // TRANSFER NFT BASED ON TYPE TO THE ORIGINAL OWNER
                if (NFTList[i].nftType == 3) {
                    NFT3.transferFrom(address(this), NFTList[i].owner, NFTList[i].nftId);
                }
                if (NFTList[i].nftType == 4) {
                    NFT4.transferFrom(address(this), NFTList[i].owner, NFTList[i].nftId);
                }
                if (NFTList[i].nftType == 5) {
                    NFT4.transferFrom(address(this), NFTList[i].owner, NFTList[i].nftId);
                }
                
                // REPLACE OLD NFT WITH EMPTY SLOT IN MAPPING
                NFTList[i].nftType = 0;
                NFTList[i].nftId = 0;
                NFTList[i].owner = address(0);
                
                break;
            }  
        }

    }
    
    
    function getSmallestNFTType() private view returns(uint) {
        for (uint i=0; i<5; i++) {
            
            // TYPE 0 MEANS EMPTY NFT SLOT
            if(NFTList[i].nftType == 0) {
                return 0;
            }
        }
        
        if(numberOfNFT3() > 0) return 3;
        if(numberOfNFT4() > 0) return 4;
        return 5;
    }    
    
    
    // EMERGENCY FUNCTION
  	function recoverNFT(uint id) public onlyOwner { // WITHDRAWS NFT TO THE ORIGINAL OWNER WITHOUT INTERACTING WITH LP VAULT IN CASE OF EMERGENCY - ADMIN ONLY
  	    
        uint index = nftIdToIndex(id);
        
         // UNSTAKES NFT FROM GFARM POOL
        gfarmPool.unstakeNft(index);
        
        for (uint i=0; i<5; i++) {
            
            if (NFTList[i].nftId == id) {
                // TRANSFER NFT BASED ON TYPE TO THE ORIGINAL OWNER
                if (NFTList[i].nftType == 3) {
                    NFT3.transferFrom(address(this), NFTList[i].owner, NFTList[i].nftId);
                }
                if (NFTList[i].nftType == 4) {
                    NFT4.transferFrom(address(this), NFTList[i].owner, NFTList[i].nftId);
                }
                if (NFTList[i].nftType == 5) {
                    NFT4.transferFrom(address(this), NFTList[i].owner, NFTList[i].nftId);
                }
                
                // REPLACE OLD NFT WITH EMPTY SLOT IN MAPPING
                NFTList[i].nftType = 0;
                NFTList[i].nftId = 0;
                NFTList[i].owner = address(0);
            
                break;                
            }

        }

    }
    
  	function recoverLP(uint amount) public { // LETS YOU WITHDRAW LP TOKENS WITHOUT INTERACTING WITH THE COMPOUND FUNCTION IN CASE OF EMERGENCY
  	    require(balanceOf[_msgSender()] >= amount, "Balance is not enough");
  	    
        balanceOf[_msgSender()] = balanceOf[_msgSender()].sub(amount);
        totalBalance = totalBalance.sub(amount);
      
        gfarmPool.unstake(amount);
        LPToken.transferFrom(address(this), _msgSender(), amount);

        emit LPWithdraw(amount, _msgSender());
    }
    
    function nftIdToIndex(uint nftid) public view returns (uint index) {
        require(nftid > 0);
        //9 means wrong nftid
        index = 9;
        
        for(uint i=0; i<5; i++) {
            
            uint id;
            (id, ) = gfarmPool.userNfts(address(this), i);

            if(id == nftid) {
                index = i;
                break;
            }
        }
    }

    // =================================================================================================================================================
    // LP + Compound functions below

    function depositLP(uint amount) public {    
        compound();
      
        LPToken.transferFrom(_msgSender(), address(this), amount);
        
        totalBalance = totalBalance.add(amount);
        balanceOf[_msgSender()] = balanceOf[_msgSender()].add(amount);
        
        if(!userExists[_msgSender()]) {
            userExists[_msgSender()] = true;
            users[numberOfUsers] = _msgSender();
            numberOfUsers++;
        }
      
        depositToGFarm();

        emit LPDeposit(amount, _msgSender());
    }
  
    function withdrawLP(uint amount) public {
        require(balanceOf[_msgSender()] >= amount, "Not enough in balance");
        require(amount > 0, "Can't withdraw zero balance");  
      
      	compound();
      
        balanceOf[_msgSender()] = balanceOf[_msgSender()].sub(amount);
        totalBalance = totalBalance.sub(amount);
      
        gfarmPool.unstake(amount);
        LPToken.transferFrom(address(this), _msgSender(), amount);

        emit LPWithdraw(amount, _msgSender());
    }
    
    function withdrawLPmax() public {
        require(balanceOf[_msgSender()] > 0, "Nothing to withdraw");
        
        compound();
        
        uint toWithdraw = balanceOf[_msgSender()];
        balanceOf[_msgSender()] = 0;
        totalBalance = totalBalance.sub(toWithdraw);
        
        gfarmPool.unstake(toWithdraw);
        LPToken.transferFrom(address(this), _msgSender(), toWithdraw);
        
        emit LPWithdraw(toWithdraw, _msgSender());
    }
    
    function compound() public {
        // Harvest rewards
        gfarmPool.harvest();
        
        // How much was harvested?
        uint256 currentBalance = GFarmToken.balanceOf(address(this));
        
        if (block.timestamp > nextDay) {
            dayCounter += 1;
            nextDay = block.timestamp + 39200;
        }
        
        // Get TVL balance in GFarm
        (uint gfarmCount,) = reservesLp();
        dayTVL[dayCounter] = totalBalance.mul(gfarmCount).mul(2).div(LPToken.totalSupply());
        dayRewards[dayCounter] += currentBalance;        

        
        // Has to have a small GFARM2 balance in the contract to send fees
        if(currentBalance > 10**10) {
    
            // Check that dev fees are above zero
            if (devFee > 0) {
                
                // Swap GFarm into DAI to pay dev fees
                swapGFarmForDAI(currentBalance.mul(devFee).div(1000));
            
                // How much DAI do we have
                uint256 currentDAIBalance = DAIToken.balanceOf(address(this));
                
                // Declare local variables
                uint devhFee;
                uint devgFee;

                // We have to account for devh referral rewards
                if (devFee > 30) {
                    devhFee = (devFee - 30).div(2); // 3% is reduced in devhFee because it earns +3% referral rewards
                    devgFee = (devFee - devhFee);
                } else {
                    devhFee = 0;
                    devgFee = devFee;
                }

                // Send devg the ratio of fees
                DAIToken.transfer(devg, currentDAIBalance.mul(devgFee).div(devFee));
                
                // Set new DAI balance after sending devg fee and transfer it to devh
                currentDAIBalance = DAIToken.balanceOf(address(this));
                
                // Check if there is balance to send
                if (currentDAIBalance > 0) {
                    DAIToken.transfer(devh, currentDAIBalance);
                }
            }
            
            // Send fees to every NFT staker
            if (nftFee > 0) {
                for (uint i=0; i < 5; i++) {
                    if(NFTList[i].owner != address(0)) {
                        GFarmToken.transfer(NFTList[i].owner, currentBalance.mul(nftFee).div(1000));
                    }
                }
            }

            uint lpcreated = 0;

            createLPTokens();
            lpcreated = LPToken.balanceOf(address(this));

            if(lpcreated > 0) {
            
                // Split new LP balance between all existing users
                for(uint i=0; i<numberOfUsers; i++) {
                    address user = users[i];
                    uint balance = balanceOf[user];
                    
                    // Calculate ratio of new balance based on LP created and total preexisting balance
                    uint additionalBalance = balance.mul(lpcreated).div(totalBalance);

                    balanceOf[user] = balance.add(additionalBalance);
                }
                
                // Update total balance
                totalBalance = totalBalance.add(lpcreated);
                
                // Stake the new LP into the GFarm pool and refer devh
                gfarmPool.stake(lpcreated, devh);
            }
        }
    }
    
    function unstakeFromGfarm(uint index) public {
        gfarmPool.unstakeNft(index);
    }
    
    function transferNFT3(uint id) public {
        NFT3.transferFrom(address(this), tx.origin, id);
    }
    
    function transferNFT4(uint id) public {
        NFT4.transferFrom(address(this), tx.origin, id);
    }
    
    function transferNFT5(uint id) public {
        NFT5.transferFrom(address(this), tx.origin, id);
    }
  
    function depositToGFarm() private {

        //get current unstaked LP balance
        uint currentBalance = LPToken.balanceOf(address(this));

        //stake currentBalance and refer devh
        gfarmPool.stake(currentBalance, devh);
    }
    
    function createLPTokens() private {
        
        // Get balance after harvest
        uint256 currentGFarmBalance = GFarmToken.balanceOf(address(this));
        
        
        // Check how much DAI was swapped into before adding liquidity
        uint256 DAIbefore = DAIToken.balanceOf(address(this));
        swapGFarmForDAI(currentGFarmBalance.div(2));
        uint256 DAInow = DAIToken.balanceOf(address(this));
        uint256 DAItoAdd = DAInow - DAIbefore;
        
        // Add liquidity with harvested balances
        addGFarmDAILiquidity(GFarmToken.balanceOf(address(this)), DAItoAdd);
        
    }
    
    
    // ====================================================================================================================================
    // VIEW FUNCTIONS Below
    
    
    // MY NFTs 0-4
    function myNFT0(address who) public view returns(NFT memory isNFT0) {
        if (NFTList[0].owner == who) {
            return NFTList[0];
        }
    }
    
    function myNFT1(address who) public view returns(NFT memory isNFT1) {
        if (NFTList[1].owner == who) {
            return NFTList[1];
        }
    }
    
    function myNFT2(address who) public view returns(NFT memory isNFT2) {
        if (NFTList[2].owner == who) {
            return NFTList[2];
        }
    }
    
    function myNFT3(address who) public view returns(NFT memory isNFT3) {
        if (NFTList[3].owner == who) {
            return NFTList[3];
        }
    }
    
    function myNFT4(address who) public view returns(NFT memory isNFT4) {
        if (NFTList[4].owner == who) {
            return NFTList[4];
        }
    }
    
    
    // VIEW ALL NFTs 0-4
    function viewNFT0() public view returns(NFT memory) {
        return NFTList[0];
    }
    
    function viewNFT1() public view returns(NFT memory) {
        return NFTList[1];
    }
    
    function viewNFT2() public view returns(NFT memory) {
        return NFTList[2];
    }
    
    function viewNFT3() public view returns(NFT memory) {
        return NFTList[3];
    }
    
    function viewNFT4() public view returns(NFT memory) {
        return NFTList[4];
    }
    
    // RETURN MULTIPLE NFTs
    function viewNFTs() public view returns(NFT memory, NFT memory, NFT memory, NFT memory, NFT memory) {
        return (NFTList[0], NFTList[1],NFTList[2], NFTList[3], NFTList[4]);
    }
    
    
    // VIEW YOUR LP BALANCE
    function myLPBalance(address who) public view returns(uint) {
        return balanceOf[who];
    }
    
    // VIEW NFT VAULT TOTAL BOOST
    function nftBoost() public view returns(uint) {
        return (numberOfNFT3()*boostValues[0] + numberOfNFT4()*boostValues[1] + numberOfNFT5()*boostValues[2]);
    }
    
    
    // VIEW VAULT TVL
    function tvl() public view returns(uint){
        if(totalBalance == 0){ return 0; }

        (, uint reserveUsd) = reservesLp();
        uint lpPriceUsd = reserveUsd.mul(1e5).mul(2).div(LPToken.totalSupply());

        return totalBalance.mul(lpPriceUsd).div(1e18);
    }
    function reservesLp() private view returns(uint, uint){
        (uint112 reserves0, uint112 reserves1, ) = LPToken.getReserves();
        if(LPToken.token0() == address(GFarmToken)){
            return (reserves0, reserves1);
        }else{
            return (reserves1, reserves0);
        }
    }
    
    // VIEW VAULT APR - TRACKS DAILY
    function apr() public view returns(uint) {
        if (dayCounter > 0 && dayTVL[dayCounter-1] > 0) {
            return (dayRewards[dayCounter-1].mul(365).mul(10000).div(dayTVL[dayCounter-1])); // 5 decimal accuracy
        }
        if (dayCounter == 0 && dayTVL[0] > 0) { // Applicable during the first day basically
            return (dayRewards[0].mul(365).mul(10000).div(dayTVL[0]));
        }
        return 0; // Return zero if there is no TVL in order to not divide by zero in if conditions
        
    }
    
    
    // =========================================================================================================================================
    // Below are Uniswap Router functions for swapping and adding liquidity
    
    function swapGFarmForDAI(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(GFarmToken);
        path[1] = address(DAIToken);
        
        GFarmToken.approve(address(uniswapV2Router), amount);
        
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function addGFarmDAILiquidity(uint256 GFarmAmount, uint256 DAIamount) private {
        
        GFarmToken.approve(address(uniswapV2Router), GFarmAmount);
        DAIToken.approve(address(uniswapV2Router), DAIamount);
        
        uniswapV2Router.addLiquidity(
            address(GFarmToken),
            address(DAIToken),
            GFarmAmount,
            DAIamount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }
}