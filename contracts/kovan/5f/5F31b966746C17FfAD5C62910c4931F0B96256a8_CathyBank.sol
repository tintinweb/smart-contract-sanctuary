pragma solidity ^0.6.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/SafeMath.sol";
import {Arrays} from "@openzeppelin/contracts/utils/Arrays.sol";
import {ICETH} from "./interfaces/ICETH.sol";
import {ICERC20} from "./interfaces/ICERC20.sol";
// import {UniswapV2Router02} from "./UniswapV2Router02.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";

// TODO: Add supply USDT liquidty function
// TODO: Add swap feature of uniswap
contract CathyBank is Ownable {
    using SafeMath for uint256;

    uint256 public ethDepositDiscountPercentage;
    uint256 public ethWithdrawFeePercentage;
    address payable public CETHContractAddress;
    address public cathyBankContractAddress;
    address public phxToken;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    mapping(address => uint256) public ethDeposits;
    mapping(address => mapping(address => uint256)) tokenDeposits;
    mapping(address => uint256) public claimedRewards;
    address payable[] public cathyBankTokenHolders;

    address constant USDC = 0xb7a4F3E9097C08dA09517b5aB877F7a917224ede;

    // TODO: Add cUSDT contract address
    constructor(
        uint256 _ethDepositDiscountPercentage,
        uint256 _ethWithdrawFeePercentage,
        address payable _cETHContractAddress,
        address _cathyBankContractAddress,
        address _phxToken
    ) public {
        ethDepositDiscountPercentage = _ethDepositDiscountPercentage;
        ethWithdrawFeePercentage = _ethWithdrawFeePercentage;
        CETHContractAddress = _cETHContractAddress;
        cathyBankContractAddress = _cathyBankContractAddress;
        phxToken = _phxToken;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(phxToken, USDC);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(phxToken, _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
    }

    event ETHDepositTransaction(
        address sender,
        uint256 amount,
        uint256 totalBalance
    );

    event ETHWithdrawTransaction(
        address sender,
        uint256 amount,
        uint256 totalBalance
    );

    event LogETHExchangeRate(uint256 amount);
    event LogETHSupplyRate(uint256 amount);
    event MyLog(string, uint256);
    event LogAmount(uint256 amount);

    function swapTokensForEth(
        address baseToken,
        address quoteToken,
        uint256 tokenAmount
    ) public {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = phxToken;
        path[1] = uniswapV2Router.WETH();

        // _approve(address(this), address(uniswapV2Router), tokenAmount);
        IERC20(phxToken).approve(address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidtyToPool(
        uint256 phxAmountDesired_,
        uint256 usdcAmountDesired_,
        uint256 phxAmountMin_,
        uint256 usdcAmountMin_
    ) public returns (bool) {
        IERC20(phxToken).approve(address(this), phxAmountDesired_);
        IERC20(USDC).approve(address(this), usdcAmountDesired_);

        IERC20(phxToken).transfer(address(this), phxAmountDesired_);
        IERC20(USDC).transfer(address(this), usdcAmountDesired_);

        // IERC20(phxToken).approve(address(uniswapV2Router), phxAmountDesired_);
        // IERC20(USDC).approve(address(uniswapV2Router), usdcAmountDesired_);

        uniswapV2Router.addLiquidity(
            phxToken,
            USDC,
            phxAmountDesired_,
            usdcAmountDesired_,
            phxAmountMin_,
            usdcAmountMin_,
            address(this),
            block.timestamp
        );
    }

    function swapPHXToUSDC(uint256 tokenAmount_, uint256 amountOutMin_)
        public
        returns (bool)
    {
        IERC20(phxToken).approve(address(uniswapV2Router), tokenAmount_);

        address[] memory path = new address[](2);
        path[0] = phxToken;
        path[1] = USDC;

        uniswapV2Router.swapExactTokensForTokens(
            tokenAmount_,
            amountOutMin_,
            path,
            address(this),
            block.timestamp
        );

        return true;
    }

    // function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    //     // approve token transfer to cover all possible scenarios
    //     _approve(address(this), address(uniswapV2Router), tokenAmount);

    //     // add the liquidity
    //     uniswapV2Router.addLiquidityETH{value: ethAmount}(
    //         address(this),
    //         tokenAmount,
    //         0, // slippage is unavoidable
    //         0, // slippage is unavoidable
    //         owner(),
    //         block.timestamp
    //     );
    // }

    // This function can receive ETH because it is marked as "payable"
    function depositETH() public payable {
        require(msg.value > 0, "Invalid amount");
        ethDeposits[msg.sender] = ethDeposits[msg.sender].add(msg.value);

        emit ETHDepositTransaction(
            msg.sender,
            msg.value,
            ethDeposits[msg.sender]
        );

        // Supply received ETH from depositor to Compound
        supplyETHToCompound(CETHContractAddress, msg.value);
    }

    function supplyETHToCompound(
        address payable _cEtherContract,
        uint256 _amount
    ) internal returns (bool) {
        // Create a reference to the corresponding cToken contract
        ICETH cETH = ICETH(_cEtherContract);

        // Amount of current exchange rate from cToken to underlying
        // uint256 exchangeRate = cETH.exchangeRateCurrent();
        uint256 exchangeRate = cETH.exchangeRateStored();
        emit LogETHExchangeRate(exchangeRate);

        // Amount added to you supply balance this block
        uint256 supplyRate = cETH.supplyRatePerBlock();

        // Supply ETH in exchange for CETH
        // cETH.mint.value(msg.value)();
        cETH.mint.value(_amount)();

        return true;
    }

    function withdrawETH() public {
        ICETH cETH = ICETH(CETHContractAddress);
        require(ethDeposits[msg.sender] > 0);

        uint256 cETHBalance = cETH.balanceOf(address(this));

        emit LogAmount(ethWithdrawFeePercentage);

        // Redeem from compound
        // find way to get redeemAmount
        // uint256 redeemAmount = redeemETH(100000000000000000, false);
        // uint256 redeemAmount = redeemETH(_amount, true);
        redeemETH(cETHBalance, true);

        uint256 DECIMALS = 10**18;
        uint256 exchangeRate = cETH.exchangeRateStored();
        uint256 redeemAmount = (cETHBalance.mul(exchangeRate)).div(DECIMALS);
        emit LogAmount(redeemAmount);
        uint256 fee = (redeemAmount.mul(ethWithdrawFeePercentage)).div(
            DECIMALS
        );

        emit LogAmount(fee);
        uint256 net = redeemAmount - fee;
        emit LogAmount(net);

        ethDeposits[msg.sender] = 0;

        // emit ETHWithdrawTransaction(
        //     msg.sender,
        //     redeemAmount,
        //     ethDeposits[msg.sender]
        // );

        address payable receiver = msg.sender;

        // receiver.transfer(_amount);
        receiver.transfer(net);
    }

    // function withdrawETH(uint256 _amount) public {
    //     require(ethDeposits[msg.sender] >= _amount, "Insufficient balance.");

    //     // ethDeposits[msg.sender] = ethDeposits[msg.sender].sub(
    //     //     _amount.add(ethWithdrawFeePercentage)
    //     // );

    //     // Redeem from compound
    //     // find way to get redeemAmount
    //     uint256 redeemAmount = redeemETH(_amount, false);

    //     emit ETHWithdrawTransaction(
    //         msg.sender,
    //         redeemAmount,
    //         ethDeposits[msg.sender]
    //     );

    //     address payable receiver = msg.sender;

    //     receiver.transfer(_amount);
    // }

    function redeemETH(uint256 _amount, bool redeemType)
        public
        returns (uint256)
    {
        ICETH cETH = ICETH(CETHContractAddress);

        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cETH.redeem(_amount);
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cETH.redeemUnderlying(_amount);
        }

        // Error codes are listed here:
        // https://compound.finance/docs/ctokens#ctoken-error-codes
        emit MyLog("If this is not 0, there was an error", redeemResult);

        return redeemResult;
    }

    // This is needed to receive ETH when calling `redeemCEth`
    fallback() external payable {}

    function getETHBalance(address _account) public view returns (uint256) {
        uint256 depositBalance = ethDeposits[_account];

        // Find formula
    }

    function setCETHContractAddress(address payable _cETHContractAddress)
        public
        onlyOwner
    {
        CETHContractAddress = _cETHContractAddress;
    }

    function setCathyBankContractAddress(address _cathyBankContractAddress)
        public
        onlyOwner
    {
        cathyBankContractAddress = _cathyBankContractAddress;
    }

    function addShareHolder(address payable _shareholder)
        external
        onlyOwner
        returns (uint256)
    {
        ICERC20 cbt = ICERC20(cathyBankContractAddress);

        uint256 balance = cbt.balanceOf(_shareholder);

        require(balance > 0, "Not a CBT token holder.");

        cathyBankTokenHolders.push(_shareholder);

        return cathyBankTokenHolders.length;
    }

    /// @dev TODO: make sure to add validation only to get unclaimed rewards.
    /// Consider claimed rewards via the mapping claimedRewards
    function getETHRewardsShare(
        address payable _shareholder,
        uint256 _contractETHBalance
    ) internal returns (bool) {
        ICERC20 cbt = ICERC20(cathyBankContractAddress);

        uint256 balance = cbt.balanceOf(_shareholder);
        emit LogAmount(balance);

        uint256 totalSupply = cbt.totalSupply();
        emit LogAmount(totalSupply);

        uint256 sharePercentage = (balance.mul(100)).div(totalSupply);
        emit LogAmount(sharePercentage);

        // uint256 contractETHBalance = address(this).balance;
        // emit LogAmount(_contractETHBalance);

        // uint256 ethShare = sharePercentage.div(contractETHBalance);
        uint256 ethShare = (_contractETHBalance.mul(sharePercentage)).div(100);
        emit LogAmount(ethShare);

        _shareholder.transfer(ethShare);

        return true;
    }

    function distributeShareRewards() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        for (uint8 i = 0; i < cathyBankTokenHolders.length; i++) {
            getETHRewardsShare(cathyBankTokenHolders[i], contractETHBalance);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

pragma solidity ^0.6.6;

interface ICETH {
    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
}

pragma solidity ^0.6.6;

interface ICERC20 {
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity >=0.6.2;

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

