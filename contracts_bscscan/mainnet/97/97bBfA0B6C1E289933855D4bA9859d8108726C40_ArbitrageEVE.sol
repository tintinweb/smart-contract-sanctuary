pragma solidity ^0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

interface IFlashloanReceiver {
    function executeOperation(
        address sender,
        address underlying,
        uint256 amount,
        uint256 fee,
        bytes calldata params
    ) external;
}

interface ICTokenFlashloan {
    function flashLoan(
        address receiver,
        uint256 amount,
        bytes calldata params
    ) external;
}

interface INaverSwapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface INaverSwapPair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IPromised {
    function mint(
        uint256 _collateral_amount,
        uint256 _share_amount,
        uint256 _dollar_out_min
    ) external;

    function redeem(
        uint256 _dollar_amount,
        uint256 _share_out_min,
        uint256 _collateral_out_min
    ) external;
}

contract ArbitrageEVE is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint112;

    address crBUSD = address(0x2Bc4eb013DDee29D37920938B96d353171289B7C);
    address naverSwapRouter =
        address(0x29A3Ea9fE2fc3CF8fd27d42dE4d12f022a25B326);
    address naverSwapPairNever =
        address(0x5f33cA991dD2362C8187bb71be089b51a7D5414A);
    address naverSwapPairEVE =
        address(0xC2D7cd44Cf6F81940582b76f1992d563417BADe7);

    address busd = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    address never = address(0x1137D5836ef0E0ed9aCc74AeF8ffe2eAf81120b5);
    address eve = address(0x48Ea7cBabc983E4D0d67B8b2578B5eA665f40DFB);
    address promised = address(0x761B25bC068a047A4A53eB9A12D89519da42aaE0);

    address payable profitAddress = payable(0xE1C54676C6b4064d0711794277718F80E8B9DE73);

    uint256 sharePercent = 2200;
    uint256 PRECISION = 10000;    
    
    function setSharePercent(uint256 _sharePercent) external onlyOwner {
        require(_sharePercent != sharePercent);
        sharePercent = _sharePercent;
    }

    function setProfitAddress(address payable _profitAddress) external onlyOwner {
        require(_profitAddress != payable(0) && _profitAddress != profitAddress);
        profitAddress = _profitAddress;
    }

    function long(uint256 amount) external onlyOwner {
        bytes memory data = abi.encode(0);
        ICTokenFlashloan(crBUSD).flashLoan(address(this), amount, data);
    }

    function short(uint256 amount) external onlyOwner {
        bytes memory data = abi.encode(1);
        ICTokenFlashloan(crBUSD).flashLoan(address(this), amount, data);
    }

    function longNoFlashLoan(uint256 amount) external onlyOwner {
        uint256 currentBalance = IERC20(busd).balanceOf(address(this));
        require(currentBalance >= amount);
        uint256 neverCost = buyNever(amount.mul(sharePercent).div(PRECISION));
        mintEVE(amount.sub(neverCost));
        sellEVE();
        sellNever();
        checkProfit(amount);
    }

    function shortNoFlashLoan(uint256 amount) external onlyOwner {
        uint256 currentBalance = IERC20(busd).balanceOf(address(this));
        require(currentBalance >= amount);
        buyEVE(amount);
        redeemEVE();
        sellNever();
        checkProfit(amount);
    }

    function checkProfit(uint256 inputAmount) internal {
        uint256 currentBalance = IERC20(busd).balanceOf(address(this));
        // profit must be greater than 1 busd
        uint256 profit = currentBalance.sub(inputAmount);
        require(profit >= 1 ether);
        IERC20(busd).transfer(profitAddress, profit);
    }


    function withdraw() public onlyOwner {
        uint256 busdAmount = IERC20(busd).balanceOf(address(this));
        if (busdAmount > 0) {
            IERC20(busd).transfer(profitAddress, busdAmount);
        }
    }

    function withdrawAll() external onlyOwner {
        this.withdraw();
        require(profitAddress.send(address(this).balance));
    }

    function buyNever(uint256 amount) internal returns (uint256) {
        uint256 previousBusdAmount = IERC20(busd).balanceOf(address(this));

        IERC20(busd).approve(naverSwapRouter, amount);

        uint256 deadline = block.timestamp + 60; // timeout 1 min

        address[] memory path = new address[](2);
        path[0] = busd;
        path[1] = never;

        INaverSwapRouter(naverSwapRouter).swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            deadline
        );

        uint256 currentBusdAmount = IERC20(busd).balanceOf(address(this));
        return previousBusdAmount.sub(currentBusdAmount);
    }

    function sellEVE() internal {
        uint256 eveAmount = IERC20(eve).balanceOf(address(this));
        require(eveAmount > 0);
        IERC20(eve).approve(naverSwapRouter, eveAmount);

        uint256 deadline = block.timestamp + 60;

        address[] memory path = new address[](2);
        path[0] = eve;
        path[1] = busd;

        INaverSwapRouter(naverSwapRouter).swapExactTokensForTokens(
            eveAmount,
            0,
            path,
            address(this),
            deadline
        );
    }

    function mintEVE(uint256 busdAmount) internal {
        uint256 neverAmount = IERC20(never).balanceOf(address(this));

        IERC20(busd).approve(promised, busdAmount);
        IERC20(never).approve(promised, neverAmount);

        IPromised(promised).mint(
            busdAmount,
            neverAmount,
            0
        );
    }

    function buyEVE(uint256 amount) internal {
        IERC20(busd).approve(naverSwapRouter, amount);

        uint256 deadline = block.timestamp + 60;

        address[] memory path = new address[](2);
        path[0] = busd;
        path[1] = eve;

        INaverSwapRouter(naverSwapRouter).swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            deadline
        );
    }

    function redeemEVE() internal {
        uint256 eveAmount = IERC20(eve).balanceOf(address(this));
        IERC20(eve).approve(promised, eveAmount);
        IPromised(promised).redeem(eveAmount, 0, 0);        
    }

    function sellNever() internal {
        uint256 neverAmount = IERC20(never).balanceOf(address(this));
        require(neverAmount > 0);
        IERC20(never).approve(naverSwapRouter, neverAmount);

        uint256 deadline = block.timestamp + 60;

        address[] memory path = new address[](2);
        path[0] = never;
        path[1] = busd;

        INaverSwapRouter(naverSwapRouter).swapExactTokensForTokens(
            neverAmount,
            0,
            path,
            address(this),
            deadline
        );
    }

    function executeOperation(
        address sender,
        address underlying,
        uint256 amount,
        uint256 fee,
        bytes calldata params
    ) external {
        require(sender == address(this));
        require(msg.sender == crBUSD);
        require(underlying == busd, "loan must be BUSD");

        uint256 currentBalance = IERC20(underlying).balanceOf(address(this));
        require(
            currentBalance >= amount,
            "Invalid balance, was the flashLoan successful?"
        );
        address cToken = msg.sender;

        uint256 action = abi.decode(params, (uint256));
        if (action == 0) {
            uint256 neverCost = buyNever(amount.mul(sharePercent).div(PRECISION));
            mintEVE(amount.sub(neverCost));
            sellEVE();
            sellNever();
        } else {
            buyEVE(amount);
            redeemEVE();
            sellNever();
        }
        // transfer fund + fee back to cToken
        require(
            IERC20(underlying).transfer(cToken, amount + fee),
            "Transfer fund back failed"
        );
        checkProfit(amount);
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