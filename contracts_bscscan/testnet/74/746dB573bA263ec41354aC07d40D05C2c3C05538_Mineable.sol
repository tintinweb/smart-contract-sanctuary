// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// pragma solidity >=0.5.0;


interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// pragma solidity >=0.6.2;

// pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

}

// File: contracts\interfaces\IPancakeRouter02.sol

// pragma solidity >=0.6.2;

interface IPancakeRouter02 is IPancakeRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


/*

███╗   ███╗██╗███╗   ██╗███████╗ █████╗ ██████╗ ██╗     ███████╗
████╗ ████║██║████╗  ██║██╔════╝██╔══██╗██╔══██╗██║     ██╔════╝
██╔████╔██║██║██╔██╗ ██║█████╗  ███████║██████╔╝██║     █████╗  
██║╚██╔╝██║██║██║╚██╗██║██╔══╝  ██╔══██║██╔══██╗██║     ██╔══╝  
██║ ╚═╝ ██║██║██║ ╚████║███████╗██║  ██║██████╔╝███████╗███████╗
╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝

*/

contract Mineable is Context, IBEP20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    event MinerTransferred(address previousOwner, address newOwner);
    
    address payable public minerAddress;
    address payable public marketingAddress;
    
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _whitelistExecs;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private _totalSupply;
    uint256 private _reflectionSupply;
    uint256 private _totalReflFees;
    
    string  private _name = "Mineable";
    string  private _symbol = "MINE";
    uint8   private _decimals = 9;
    
    uint256 private _minerFeeRate;
    uint256 private _prevMinerFee;
    
    uint256 private _reflectionFeeRate;
    uint256 private _prevReflFee;

    /* Marketing funds will be raised from mining rewards following alpha batch of miners */
    uint256 private _marketingFeeRate;
    uint256 private _prevMarketingFee;

    uint256 private _currentMinerFees;
    uint256 private _currentMarketingFees;

    uint256 private _amountOutMinimum;

    IPancakeRouter02 public pancakeV2Router;
    address public pairMineToWBNB;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;

    uint256 public  maxTokenSwap;
    
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    event ReceivedBNB(address, uint256);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    modifier whitelisted {
        require(_whitelistExecs[_msgSender()], "Only whitelisted executors can call this function");
        _;
    }
    
    constructor (uint256 _tokenSupply, uint256 _tokenMinerFee, uint256 _tokenReflectionFee, uint256 _tokenMarketingFee, uint256 _maxTokenSwap) {
		_totalSupply = _tokenSupply * 10**_decimals;
		_reflectionSupply = (MAX - (MAX % _totalSupply));
		
		_minerFeeRate = _tokenMinerFee; 		
		_reflectionFeeRate = _tokenReflectionFee;
        _marketingFeeRate = _tokenMarketingFee;
		
        maxTokenSwap = _maxTokenSwap * 10**_decimals;
	 
		_rOwned[_msgSender()] = _reflectionSupply;
		
		_currentMinerFees = 0;
		_currentMarketingFees = 0;
        _amountOutMinimum = 0;
		// Address points to PancakeSwap Router
		// pancakeV2Router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        /* Test Net Router */ 
        pancakeV2Router = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

        _whitelistExecs[_msgSender()] = true;

        emit OwnershipTransferred(address(0), owner());
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function setRouter(address _router) public onlyOwner {
        pancakeV2Router = IPancakeRouter02(_router);
    }

    function setPairAddress(address pairing) public onlyOwner {
        pairMineToWBNB = pairing;
    }
    function getPairAddress() public view returns (address) {
        return pairMineToWBNB;
    }
    
    function getOwner() public view override returns (address) {
        return owner();
    }
    
    function getReflectionFeeRate() public view returns (uint256) {
        return _reflectionFeeRate;
    }

    function getMinerFeeRate() public view returns (uint256) {
        return _minerFeeRate;
    }

    function getMarketingFeeRate() public view returns (uint256) {
        return _marketingFeeRate;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Decreased allowance below zero"));
        return true;
    }
    
    function reflectionFees() public view returns (uint256) {
        return _totalReflFees;
    }
    
    // What does this do?
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _totalReflFees = _totalReflFees.add(tAmount);
    }
    
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _totalSupply, "Amount must be less than supply");
        if(!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
    
    // Get current amount of token of caller based on how much they have in reflection
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _reflectionSupply, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    
    function callSwap() public whitelisted {
        uint256 contractTokenBalance = balanceOf(address(this));        
        if (!inSwapAndLiquify && swapAndLiquifyEnabled){
            contractTokenBalance = maxTokenSwap < contractTokenBalance ? maxTokenSwap : contractTokenBalance;
            _swapTokens(contractTokenBalance); 
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
    
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "TOKEN20: transfer from the zero address");
        require(recipient != address(0), "TOKEN20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        _tokenTransfer(sender, recipient, amount);
    }

    function _swapTokens(uint256 contractTokenBalance) private lockTheSwap {
        uint256 initialBalance = _currentMinerFees.add(_currentMarketingFees);
        _swapTokensForETH(contractTokenBalance);
        uint256 transferredBalance = address(this).balance.sub(initialBalance);
        _currentMinerFees = _currentMinerFees.add(transferredBalance.mul(100).div(_minerFeeRate.add(_marketingFeeRate).mul(_minerFeeRate).div(100)));
        _currentMarketingFees = _currentMarketingFees.add(transferredBalance.mul(100).div(_minerFeeRate.add(_marketingFeeRate).mul(_marketingFeeRate).div(100)));
    }
    
    function _swapTokensForETH(uint256 tokenAmount) private nonReentrant {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeV2Router.WETH();
        
        _approve(address(this), address(pancakeV2Router), tokenAmount);
        /* Avoid Frontrunning */
        uint256 amountOutMin = _amountOutMinimum;

        address payable contractAddress = payable(address(this));
        
        /* perform the swap */
        pancakeV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            amountOutMin,
            path,
            contractAddress,
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tMinerFee, uint256 tMarketingFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeMinerFee(tMinerFee);
        _takeMarketingFee(tMarketingFee);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _reflectFee(uint256 rReflFee, uint256 tReflFee) private {
        _reflectionSupply = _reflectionSupply.sub(rReflFee);
        _totalReflFees = _totalReflFees.add(tReflFee);
    }
    
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tReflFee, uint256 tMinerFee, uint256 tMarketingFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflFee) = _getRValues(tAmount, tReflFee, tMinerFee, tMarketingFee, _getRate());
        return (rAmount, rTransferAmount, rReflFee, tTransferAmount, tReflFee, tMinerFee, tMarketingFee);
    }
    
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tReflFee = calculateReflFee(tAmount);
        uint256 tMinerFee = calculateMinerFee(tAmount);
        uint256 tMarketingFee = calculateMarketingFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tReflFee).sub(tMinerFee).sub(tMarketingFee);
        return (tTransferAmount, tReflFee, tMinerFee, tMarketingFee);
    }
    
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tMinerFee, uint256 tMarketingFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rReflFee = tFee.mul(currentRate);
        uint256 rMinerFee = tMinerFee.mul(currentRate);
        uint256 rMarketingFee = tMarketingFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rReflFee).sub(rMinerFee).sub(rMarketingFee);
        return (rAmount, rTransferAmount, rReflFee);
    }
    
    /* Where the magic happens */
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
    
    function _getCurrentSupply() private view returns(uint256, uint256) {
        return (_reflectionSupply, _totalSupply);
    }

    function _takeMarketingFee(uint256 tMarketingFee) private {
        uint256 currentRate = _getRate();
        uint256 rMarketingFee = tMarketingFee.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rMarketingFee);

    }
    
    function _takeMinerFee(uint256 tMinerFee) private {
        uint256 currentRate = _getRate();
        uint256 rMinerFee = tMinerFee.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rMinerFee);
    }
    
    function calculateReflFee(uint256 amount) private view returns (uint256) {
        return amount.mul(_reflectionFeeRate).div(100);
    }
    
    function calculateMinerFee(uint256 amount) private view returns (uint256) {
        return amount.mul(_minerFeeRate).div(100);
    }

    function calculateMarketingFee(uint256 amount) private view returns (uint256) {
        return amount.mul(_marketingFeeRate).div(100);
    }

    function removeAllFee() public onlyOwner {
        if(_reflectionFeeRate == 0 && _minerFeeRate == 0 && _marketingFeeRate == 0) return;
        
        _minerFeeRate = 0;
        _reflectionFeeRate = 0;
        _marketingFeeRate = 0;
    }

    function setReflFeePrecentage(uint256 reflFee) external onlyOwner {
        _reflectionFeeRate = reflFee;
    }
    
    function setMinerFeePercentage(uint256 minerFee) external onlyOwner {
        _minerFeeRate = minerFee;
    }

    function setMinerAddress(address payable _minerAddress) external onlyOwner {
        minerAddress = _minerAddress;
    }

    /* Marketing funds will be raised from mining rewards following alpha batch of miners */
    function setMarketingFeePercentage(uint256 marketingFee) external onlyOwner {
        _marketingFeeRate = marketingFee;
    }

    function setMarketingAddress(address payable _marketingAddress) external onlyOwner {
        marketingAddress = _marketingAddress; 
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setMaxTokenSwap(uint256 swapAmount) external onlyOwner {
        maxTokenSwap = swapAmount * 10**_decimals;
    }

    function setSwapAmountOutMinimum(uint256 amount) external onlyOwner {
        _amountOutMinimum = amount;
    }

    function addToExecWhitelist(address exec) external onlyOwner {
        _whitelistExecs[exec] = true;
    }

    function removeFromExecWhitelist(address exec) external onlyOwner {
        _whitelistExecs[exec] = false;
    }
    
    function withdrawalMinerFees() external payable onlyOwner nonReentrant returns (bool) {
        uint256 amount = _currentMinerFees;
        (bool success, ) = minerAddress.call{value: amount}("");
        require(success, "Failed to send Miner Fees");
        _currentMinerFees = 0;
        return true;
    }

    function withdrawalMarketingFees() external payable onlyOwner nonReentrant returns (bool) {
        uint amount = _currentMarketingFees;
        (bool success, ) = marketingAddress.call{value: amount}("");
        require(success, "Failed to send Marketing Fees");
        _currentMarketingFees = 0;
        return true;
    }

    receive() external payable {
        emit ReceivedBNB(_msgSender(), msg.value);
    }
}

