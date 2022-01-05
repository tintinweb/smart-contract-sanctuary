//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IDex.sol";
import "./interfaces/IDuckies.sol";
import "./interfaces/IDuckFactory01.sol";

contract DuckFactory is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint128;

    address public tokenAddress;
    address public pancakeV2Pair;
    address private ZERO_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public PREVIOUS_FACTORY;

    // Swapping and creating LP
    address public routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // BSC Testnet - 0xD99D1c33F9fC3444f8101754aBC46c52416550D1, 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    modifier tradingStarted() {
        require(pancakeV2Pair != address(0), "DUCKFACTORY: Trading is not open");
        _;
    }

    constructor(address _duckiesAddress, address _routerAddr) {
        tokenAddress = _duckiesAddress;
        routerAddress = _routerAddr;
    }

    // Admin functions: Start
    function setRouterAddress(address _routerAddr) public onlyOwner() {
        routerAddress = _routerAddr;
    }

    function setTokenAddress(address _tokenAddr) public onlyOwner() {
        tokenAddress = _tokenAddr;
    }

    function setPairAddress(address _pairAddress) public onlyOwner() {
        pancakeV2Pair = _pairAddress;
    }

    function transferDuckiesOwnership(address _newFactory) public onlyOwner() {
        IDuckies duckies = IDuckies(tokenAddress);
        require(duckies.owner() == address(this), "DUCKFACTORY: not owner of Dukies");
        duckies.transferOwnership(_newFactory);
    }

    function transferPrevFactoryOwnership(address _newOwner) public onlyOwner() {
        IDuckFactory01 duckFactory = IDuckFactory01(PREVIOUS_FACTORY);
        require(duckFactory.owner() == address(this), "DUCKFACTORY: not owner of previous factory");
        duckFactory.transferOwnership(_newOwner);
    }

    function openTrading(uint256 _tokenAmount, uint256 _bnbAmount) external onlyOwner() {
        require(pancakeV2Pair == address(0), "DUCKFACTORY: trading is already open");
        IPancakeRouter02 pancakeV2Router = IPancakeRouter02(routerAddress);
        IERC20 token = IERC20(tokenAddress);
        token.approve(address(pancakeV2Router), _tokenAmount);
        pancakeV2Pair = IPancakeFactory(pancakeV2Router.factory()).createPair(tokenAddress, pancakeV2Router.WETH());
        pancakeV2Router.addLiquidityETH{value: _bnbAmount}(address(token),_tokenAmount,0,0,address(this),(block.timestamp + 600));
        IERC20(pancakeV2Pair).approve(address(pancakeV2Router), type(uint).max);
    }

    function airdropToUsers(address[] memory _addresses, uint256 _airdropAmount) public payable onlyOwner() {
        for (uint256 i = 0; i < _addresses.length; i++) {
            IERC20(tokenAddress).transfer(_addresses[i], _airdropAmount);
        }
    }

    function withdraw() public onlyOwner() {
        payable(address(msg.sender)).transfer(address(this).balance);
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function withdrawToken(address _tokenAddr) public onlyOwner() {
        IERC20(_tokenAddr).transfer(msg.sender, IERC20(_tokenAddr).balanceOf(address(this)));
    }

    function transferTokenAmountTo(address _to, address _tokenAddr, uint256 _withdrawAmount) public onlyOwner() {
        require(IERC20(_tokenAddr).balanceOf(address(this)) >= _withdrawAmount, "Balance is less than withdraw amount");
        IERC20(_tokenAddr).transfer(_to, _withdrawAmount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) public onlyOwner() tradingStarted() {
        IPancakeRouter02 pancakeV2Router = IPancakeRouter02(routerAddress);
        IERC20(tokenAddress).approve(address(pancakeV2Router), tokenAmount);
        pancakeV2Router.addLiquidityETH{value: bnbAmount} (
            tokenAddress,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            (block.timestamp + 600)
        );
    }

    // function to burn: transfer to null address
    function burnToken(uint256 _burnAmount) external onlyOwner() {
        IERC20(tokenAddress).transfer(ZERO_ADDRESS, _burnAmount);
    }


    // Functions to change factory: Start
    function transferFactory(address _oldFactory) external onlyOwner() {
        // 1. Initialize the old contract
        IDuckFactory01 oldDuckFactory = IDuckFactory01(_oldFactory);
        IDuckies duckies = IDuckies(tokenAddress);
        // 2. withdraw all BNB and Duckies
        oldDuckFactory.withdraw();
        // 3. withdraw all LP Balance if any
        address pairContractAddr = oldDuckFactory.pancakeV2Pair();
        if (pairContractAddr != address(0)) {
            oldDuckFactory.withdrawToken(pairContractAddr);
        }
        // 4. Set the pair
        pancakeV2Pair = pairContractAddr;
        // 5. Transfer ownership of duckies contract
        if (duckies.owner() == address(this)) {
            oldDuckFactory.transferDuckiesOwnership(address(this));
        }
        // 6. Set previous factory
        PREVIOUS_FACTORY = _oldFactory;

    }
    // Functions to change factory: End

    // Remove LP
    function removeLiquidity(uint256 _amount) external onlyOwner() {
        // 1. Initialize the router
        IPancakeRouter02 pancakeV2Router = IPancakeRouter02(routerAddress);
        // 2. Approve spending
        IERC20(pancakeV2Pair).approve(address(pancakeV2Router), _amount);
        // 3. Remove the liquidity
        pancakeV2Router.removeLiquidityETH(
            tokenAddress,
            _amount,
            0, // minimum is zero
            0, // minimum is zero
            address(this),
            (block.timestamp + 600)
        );
    }

    // Admin functions: End

    // receive and fallback methods
    receive() payable external {}
    fallback() payable external {}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOwnable {
    function owner() external view returns(address ownerAddress);

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    */
    function renounceOwnership() external;

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOwnable.sol";

interface IDuckies is IERC20, IOwnable {}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IOwnable.sol";

interface IDuckFactory01 is IOwnable {

    // All variables
    function tokenAddress() external view returns (address);
    function pancakeV2Pair() external view returns (address);
    function routerAddress() external view returns (address);

    function setRouterAddress(address _routerAddr) external;
    function setTokenAddress(address _tokenAddr) external;
    function setPairAddress(address _pairAddress) external;
    function transferDuckiesOwnership(address _newFactory) external;
    function openTrading(uint256 _tokenAmount, uint256 _bnbAmount) external;
    function airdropToUsers(address[] memory _addresses, uint256 _airdropAmount) external payable;
    function withdraw() external;
    function withdrawToken(address _tokenAddr) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeRouter02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
}