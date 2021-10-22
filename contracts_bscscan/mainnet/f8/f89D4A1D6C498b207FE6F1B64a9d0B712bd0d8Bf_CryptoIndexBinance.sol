// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity ^0.6.12;

//import statements go here
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract CryptoIndexBinance {
    using SafeMath for uint256;

    address public constant USDC_ADDRESS = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    
    address public constant BTCB_ADDRESS = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address public constant WETH_ADDRESS = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address public constant BNB_ADDRESS = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant ADA_ADDRESS = 0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47;
    address public constant XRP_ADDRESS = 0x1D2F0da169ceB9fC7B3144628dB156f3F6c60dBE;
    address public constant SOL_ADDRESS = 0x570A5D26f7765Ecb712C0924E4De545B89fD43dF;
    address public constant DOT_ADDRESS = 0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402;
    address public constant DOGE_ADDRESS = 0xbA2aE424d960c26247Dd6c32edC70B295c744C43;
    address public constant UNI_ADDRESS = 0xBf5140A22578168FD562DCcF235E5D43A02ce9B1;
    address public constant LTC_ADDRESS = 0xECCF35F941Ab67FfcAA9A1265C2fF88865caA005; 

    address public constant BTC_USD_ORACLE = 0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf;
    address public constant ETH_USD_ORACLE = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
    address public constant BNB_USD_ORACLE = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    address public constant ADA_USD_ORACLE = 0xa767f745331D267c7751297D982b050c93985627;
    address public constant XRP_USD_ORACLE = 0x93A67D414896A280bF8FFB3b389fE3686E014fda;
    address public constant SOL_USD_ORACLE = 0x0E8a53DD9c13589df6382F13dA6B3Ec8F919B323;
    address public constant DOT_USD_ORACLE = 0xC333eb0086309a16aa7c8308DfD32c8BBA0a2592;
    address public constant DOGE_USD_ORACLE = 0x3AB0A0d137D4F946fBB19eecc6e92E64660231C8;
    address public constant UNI_USD_ORACLE = 0xb57f259E7C24e56a1dA00F66b55A5640d9f9E7e4;
    address public constant LTC_USD_ORACLE = 0x9Dcf949BCA2F4A8a62350E0065d18902eE87Dca3; //doesn't seem to have an oracle currently?

    mapping (address => address) private oracle_addresses;

    constructor () public {
        oracle_addresses[BTCB_ADDRESS] = BTC_USD_ORACLE;
        oracle_addresses[WETH_ADDRESS] = ETH_USD_ORACLE;
        oracle_addresses[BNB_ADDRESS] = BNB_USD_ORACLE;
        oracle_addresses[ADA_ADDRESS] = ADA_USD_ORACLE;
        oracle_addresses[XRP_ADDRESS] = XRP_USD_ORACLE;
        oracle_addresses[SOL_ADDRESS] = SOL_USD_ORACLE;
        oracle_addresses[DOT_ADDRESS] = DOT_USD_ORACLE;
        oracle_addresses[DOGE_ADDRESS] = DOGE_USD_ORACLE;
        oracle_addresses[UNI_ADDRESS] = UNI_USD_ORACLE;
        oracle_addresses[LTC_ADDRESS] = LTC_USD_ORACLE;
    }
    address public constant SUSHISWAP_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    
    uint256 public totalNumberOfShares;
    mapping(address => uint256) public userNumberOfShares; 

    IUniswapV2Router02 public sushiSwapRouter = IUniswapV2Router02(SUSHISWAP_ROUTER);
    //more variables here
    // constructor() autoBalancer public {
    // } 
    
    /**
     * Returns the latest price
     */
    function getLatestPrice(address _oracle_address) public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(_oracle_address).latestRoundData();
        return price;
    }

    function updateSharesOnWithdrawal(address user) public { //make this ownable - only contract itself can update this?
        require (userNumberOfShares[user] > 0, "Error - This user has no shares");
        totalNumberOfShares -= userNumberOfShares[user];
        userNumberOfShares[user] = 0;
    }

    function getUserShares(address user) public view returns (uint256 userShares) {
        return userNumberOfShares[user];
    }

    function approve_spending (address token_address, address spender_address, uint256 amount_to_approve) public {
            IERC20(token_address).approve(spender_address, amount_to_approve);
    }
    
     receive() external payable {
    }

    function deposit (uint256 _amount, address token_address, address address_from) public {
        IERC20 token_ = IERC20(token_address);

        token_.transferFrom(
            address_from, 
            address(this), 
            _amount
        );
    }

    function depositFirstTime (uint256 _amount, address deposit_token_address, address address_from, address[] memory token_addresses) public {
        deposit(_amount, deposit_token_address, address_from);

        approve_spending(USDC_ADDRESS, SUSHISWAP_ROUTER, _amount);

        swapIntoNEqualParts(_amount, token_addresses);

        setSharesFirstTime(address_from);
    }

    function depositUserFunds (uint256 amount_, address token_address, address address_from, address[] memory token_addresses) public  {
        // TO DO - replace with deposit(amount_, token_address, address_from);
        IERC20 token_ = IERC20(token_address);

        token_.transferFrom(
            address_from, 
            address(this), 
            amount_
        );

        approve_spending(USDC_ADDRESS, SUSHISWAP_ROUTER, amount_);

        //here we need to figure out what we're dealing with... take token_addresses and get USDbalances
        uint256 Total_in_USD;
        uint256[] memory token_USD_balances = new uint256[](token_addresses.length);

        for (uint i; i<token_addresses.length; i++) {
            address[] memory token_balances = new address[](token_addresses.length);
            token_USD_balances[i] = getUSDBalanceOf(token_addresses[i], oracle_addresses[token_addresses[i]], 18);
            Total_in_USD = Total_in_USD.add(token_USD_balances[i]);
        }
        
        if (Total_in_USD > 0) {
            swapProportionately(token_addresses, token_USD_balances, Total_in_USD, amount_);
            updateSharesOnDeposit(address_from, Total_in_USD, amount_);
        } else {
            swapIntoNEqualParts(amount_, token_addresses);
            setSharesFirstTime(address_from);
        }
    }

    function getUSDBalanceOf(address token_address, address oracle_address, uint256 token_decimals) public view returns (uint256) {
        // uint256 token_decimals = IERC20(token_address).decimals();
        return balanceOf(token_address, address(this))
        .mul(uint256(getLatestPrice(oracle_address)))
        .div(10**(token_decimals+2));
    }

    function swapProportionately(
        address[] memory token_addresses, 
        uint256[] memory token_USD_balances, 
        uint256 totalUSDAmount, 
        uint256 depositAmount
        ) public 
        {
            for (uint i; i<token_addresses.length; i++) {
                address[] memory _path = new address[](2);
                _path[0] = USDC_ADDRESS;
                _path[1] = token_addresses[i];

                uint256 token_share = token_USD_balances[i].mul(depositAmount).div(totalUSDAmount);
                swap(token_share, uint256(0), _path, address(this), uint256(-1));
                }
    }

    function swapIntoNEqualParts(uint256 amount, address[] memory token_addresses) public {
        for (uint i; i<token_addresses.length; i++) {
            address[] memory _path = new address[](2);
            _path[0] = USDC_ADDRESS;
            _path[1] = token_addresses[i];
            swap(amount.div(token_addresses.length), uint256(0), _path, address(this), uint256(-1));
        }
    }

    function setSharesFirstTime(address user) public {
        userNumberOfShares[user] = 100000000;
        totalNumberOfShares = 100000000;
    }

    function updateSharesOnDeposit(address user, uint256 total_in_USD, uint256 deposit_amount) public { //make this ownable - only contract itself can update this?
        uint256 newSharesForUser = deposit_amount.mul(totalNumberOfShares).div(total_in_USD);
        totalNumberOfShares = totalNumberOfShares.add(newSharesForUser);
        if (userNumberOfShares[user] > 0) {
            userNumberOfShares[user] = userNumberOfShares[user].add(newSharesForUser);
        } else {
            userNumberOfShares[user] = newSharesForUser;
        }
    }

    function withdrawUserFunds(address user, address[] memory token_addresses) public {

        for (uint i; i<token_addresses.length; i++) {
            uint256 token_amount = getUserShares(user).mul(balanceOf(token_addresses[i], address(this))).div(totalNumberOfShares);
            approveSpendingWholeBalance(token_addresses[i], SUSHISWAP_ROUTER);
            address[] memory _path = new address[](2);
            _path[0] = token_addresses[i];
            _path[1] = USDC_ADDRESS;
            swap(token_amount, uint256(0), _path, address(this), uint256(-1));
        }

        approveSpendingWholeBalance(USDC_ADDRESS, user);
        
        uint256 USDC_amount = balanceOf(USDC_ADDRESS, address(this));
        IERC20(USDC_ADDRESS).transfer(user, USDC_amount);

        updateSharesOnWithdrawal(user);
    }

    // function executeThreeSwaps(
    //     address _from1, address _to1, uint256 _amount1,
    //     address _from2, address _to2, uint256 _amount2,
    //     address _from3, address _to3, uint256 _amount3
    //     ) public {
    //         executeRebalancingSwap(_from1, _to1, _amount1);
    //         executeRebalancingSwap(_from2, _to2, _amount2);
    //         executeRebalancingSwap(_from3, _to3, _amount3);
    // }

    // function executeRebalancingSwap(address _tokenToSwap, address _tokenSwappingTo, uint256 _amountToBeSwapped) public {
    //     approve_spending(_tokenToSwap, SUSHISWAP_ROUTER, _amountToBeSwapped);
    //     if (_tokenToSwap == WMATIC_ADDRESS || _tokenSwappingTo == WMATIC_ADDRESS) {
    //         address[] memory _path = new address[](2);
    //         _path[0] = _tokenToSwap;
    //         _path[1] = _tokenSwappingTo;
    //         swap(_amountToBeSwapped, uint256(0), _path, address(this), uint256(-1));
    //     } else {
    //         address[] memory _path = new address[](3);
    //         _path[0] = _tokenToSwap;
    //         _path[1] = WMATIC_ADDRESS;
    //         _path[2] = _tokenSwappingTo;
    //         swap(_amountToBeSwapped, uint256(0), _path, address(this), uint256(-1));
    //     }
        
    // }

    function approveSpendingWholeBalance(address _token, address _spender) public {
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        approve_spending(_token, _spender, tokenBalance);
    }
    
    function withdraw_matic(uint256 amount_) public {
        msg.sender.transfer(amount_); //TODO - change?
    }

    function withdrawAllUSDC(address _user) public {
        approveSpendingWholeBalance(USDC_ADDRESS, _user);
        uint256 USDC_amount = balanceOf(USDC_ADDRESS, address(this));
        IERC20(USDC_ADDRESS).transfer(_user, USDC_amount);
    }

    function withdrawAll(address _user, address _token_address) public {
        approveSpendingWholeBalance(_token_address, _user);
        uint256 USDC_amount = balanceOf(_token_address, address(this));
        IERC20(_token_address).transfer(_user, USDC_amount);
    }

    function balanceOf(address token_address, address user_address) public view returns (uint256 token_balance) {
        IERC20 _token = IERC20(token_address);
        token_balance = _token.balanceOf(user_address);
        return token_balance;
    }
    
    function swap(uint256 _amountIn, uint256 _amountOutMin, address[] memory _path, address _acct, uint256 _deadline) public {
        
       sushiSwapRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            _acct,
            _deadline);
        }      
    }

pragma solidity ^0.6.12;

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

pragma solidity ^0.6.12;

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