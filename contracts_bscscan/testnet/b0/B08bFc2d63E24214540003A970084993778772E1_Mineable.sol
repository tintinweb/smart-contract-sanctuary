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
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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

    /* Constants */
    string constant private _name = "Mineable";
    string constant  private _symbol = "MINE";
    uint8  constant private _decimals = 9;
    
    /* 
        MINER FEE ADDRESS
        Only the owner can execute a withdrawal to this address
    */
    address payable immutable public minerAddress;
    
    /* 
       executor address can execute callSwap() to swap miner & marketing fees for BNB.
       This is done to create a separate transaction for a swap. Without a seperate transaction, 
            swapping would charge significant extra gas fees on occasional normal transactions.
       Essentially, we want to pay for the extra gas when swapping, not force the average Mineable investor to do so.
       Executor will start as the owner, but will later move to a separate smart contract to automate the swapping process.
    */
    address private _executor;

    
    uint256 private _totalSupply;
    
    mapping(address => uint256) private _tokensOwned;

    mapping(address => uint256) private _markedForMining;
    
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => uint256) private _coolDownBlock;
    mapping (address => bool) private _coolingDown;
    mapping (address => bool) private _avoidCoolDown;

    mapping (address => bool) private _isUnlimited;

    uint256 private _averageBlockTime;
    uint256 private _approxCooldownSeconds;

    uint256 private _transactionLimit;
    
    uint256 private _minerFeeRate;
    uint256 private _prevMinerFee;
    
    uint256 private _currentMinerFees;

    IPancakeRouter02 private _pancakeV2Router;
    address public pairMineToWBNB;
    
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    
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

    event ReceivedBNB(address sender, uint256 amount);

    event ExecutorTransferred(address previousExecutor, address newExecutor);

    event MinerFeesWithdrawn(uint256 amount);

    event MinerFeeRateAltered(uint256 newMinerFee);

    event MarkedForMining(address marker, uint256 markedAmount);

    event UnmarkedForMining(address marker, uint256 unmarkedAmount);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    modifier onlyExecutor {
        require(_msgSender() == _executor, "Only executor can call this function");
        _;
    }

    modifier coolDown (address sender, address recipient){
        if(_coolDownBlock[sender] <= block.number){
            _coolingDown[sender] = false;
        }
        if(_coolDownBlock[recipient] <= block.number){
            _coolingDown[recipient] = false;
        }
        require(!_coolingDown[sender] || _avoidCoolDown[sender], 'Sending account is still cooling down');
        require(!_coolingDown[recipient] || _avoidCoolDown[recipient], 'Recipient account is still cooling down');

        _;

        if(!_avoidCoolDown[sender]){
            _coolingDown[sender] = true;
            _coolDownBlock[sender] = uint256(block.number).add(_cooldownBlockCount());
        }
        if(!_avoidCoolDown[recipient]){
            _coolingDown[recipient] = true;
            _coolDownBlock[recipient] = uint256(block.number).add(_cooldownBlockCount());
        }
    }

    modifier limited (address sender, address recipient, uint256 amount) {
        require(amount <= _transactionLimit * 10**_decimals || (_isUnlimited[sender] && _isUnlimited[recipient]), 'Transfer amount exceeds limit');
        _;
    }
    
    /*
        @notice constructor will:
        - Init token supply
        - Init immutable addresses
        - Init fee rates
        - Fill owner's balance with total supply
        - Init the pancake router (not ready for swap until pairing is made)
        - Assign owner as executor. In the future, executor will be a separate contract to perform
        - Remove cooldown from owner, contract, and pancake router
        - Remove transaction limit from owner, contract, and pancake router
        - Assign an approximate 5 minute cool down based on block time (with average block time at ~3 seconds. Can be updated)
        - Assign a 10,000 Mineable transaction limit

        @param _marketingAddress = address to send marketing fees. For security, use a mutli-signature wallet like Gnosis
        @param _minerAddress = address to send miner fees. Again, use a multisig wallet
    */
    constructor (address payable _minerAddress) {
		_totalSupply = 21000000 * 10**_decimals;
		
        minerAddress = _minerAddress;

		_minerFeeRate = 6; 		
	
		_tokensOwned[_msgSender()] = _totalSupply;
		
		_currentMinerFees = 0;
		// Address points to PancakeSwap Router
		// _pancakeV2Router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        /* Test Net Router */ 
        _pancakeV2Router = IPancakeRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

        _executor = _msgSender();

        emit OwnershipTransferred(address(0), owner());
        // emit ExecutorTransferred(address(0), _executor);
        emit Transfer(address(0), _msgSender(), _totalSupply);

        _avoidCoolDown[_msgSender()] = true;
        _avoidCoolDown[address(this)] = true;
        /* Pancake Router */
        _avoidCoolDown[0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3] = true;

        _isUnlimited[_msgSender()] = true;
        _isUnlimited[address(this)] = true;
        _isUnlimited[0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3] = true;

        /* Average block time currently is 3 seconds */
        _averageBlockTime = 3;
        
        /* Transaction cool down of approximately 30 seconds */
        _approxCooldownSeconds = 30;

        /* Transaction Limit of 10,000 Mineable */
        _transactionLimit = 10000;
    }

    /*
        @dev see IBEP20 interface
        @return name of the contract (Mineable)
    */
    function name() public pure override returns (string memory) {
        return _name;
    }

    /*
        @dev see IBEP20 interface
        @return symbol for contract (MINE)
    */
    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    /*
        @dev see IBEP20 interface
        @return number of decimals used in contract (9)
    */
    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    /*
        @dev see IBEP20 interface
        @return total supply, including decimals (21,000,000.000000000 shown as 21,000,000,000,000,000)
    */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /*
        @dev see IBEP20 interface
        @param account: address to find the balance of
        @return Mineable balance of account, including decimals
    */
    function balanceOf(address account) public view override returns (uint256) {
        return _tokensOwned[account];
    }

    /*
        @dev see IBEP20 interface
        @param recipient: address of the wallet receiving Mineable token
        @param amount: amount of Mineable to send to recipient, INCLUDING DECIMALS
        @return boolean indicating success
    */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /*
        @dev see IBEP20 interface
        @param holder: the address that owns the Mineable
        @param spender: the address that has been granted permission to spend owner's Mineable on their behalf
        @return amount of Mineable spender is allowed to spend on behalf of owner
    */
    function allowance(address holder, address spender) public view override returns (uint256) {
        return _allowances[holder][spender];
    }

    /*
        @dev see IBEP20 interface
        @param spender: the address that msg.sender will grant permission to spend msg.sender's Mineable
        @param amount: how much Mineable spender is allowed to spend on msg.sender's behalf
        @return boolean indicating success
    */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /*
        @dev see IBEP20 interface
        @param sender: where the Mineable is sent from
        @param recipient: where the Mineable is sent to
        @param amount: amount of mineable to send, including decimals
        @requirement: sender has already given msg.sender approval to spend it's mineable
    */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Transfer amount exceeds allowance"));
        return true;
    }

    /* External View Functions */
    /*
        @return address of the current executor
    */
    function getExecutor() external view returns (address) {
        return _executor;
    }

    /*
        @return currently set average block time in seconds
        @notice executor will update average block time
        @dev average block time is used to approximate how many blocks it will take to cause a cooldown time of _approxCooldownSeconds
    */
    function getAverageBlockTime() external view returns (uint256) {
        return _averageBlockTime;
    }

    /*
        @return time (in minutes) to aim for with the cool down
        @notic executor can update cooldown time, but will rarely do so
    */
    function getApproximateCooldownSeconds() external view returns (uint256) {
        return _approxCooldownSeconds;
    }

    /*
        @return pairing address of MINE/WBNB (MINE/BNB) from pancake swap
    */
    function getPairAddress() external view returns (address) {
        return pairMineToWBNB;
    }
    
    /*
        @return the owner of the contract
    */
    function getOwner() external view override returns (address) {
        return owner();
    }

    /*
        @return the current miner fee rate (capped at 6%)
    */
    function getMinerFeeRate() external view returns (uint256) {
        return _minerFeeRate;
    }

    /*
        @return the currently set transaction limit
    */
    function getTransactionLimit() external view returns (uint256) {
        return _transactionLimit;
    }

    /*
        @return the current amount of Mineable marked for mining by account
    */
    function getMarkedForMining(address account) external view returns (uint256) {
        return _markedForMining[account];
    }

    /* External Functions */
    
    /* 
        @dev mark Mineable from msg.sender's account for mining. 
            - Removes amount (after converted to a reflection amount) from _reflectionsOwned[msg.sender] and adds them to _markedForMining[msg.sender]
        @notice tokens marked will be locked from the holder's usable balance

        @param amount = amount of Mineable to lock

        @return emits a MarkedForMining event, used for tracking when Mineable was marked
    */
    function markTokensForMining(uint256 amount) public {
        uint256 balance = balanceOf(_msgSender());
        require(amount <= balance, "Insufficient Unmarked Mineable to Mark");
        _tokensOwned[_msgSender()] = _tokensOwned[_msgSender()].sub(amount);
        _markedForMining[_msgSender()] = _markedForMining[_msgSender()].add(amount);

        emit MarkedForMining(_msgSender(), amount);
    }
    
    /*
        @dev unmarks Mineable from msg.sender's account for mining
            - Removes amount (after converted to a reflection amount) from _markedForMining[msg.sender] and adds them to _reflectionsOwned[msg.sender]
    */
    function unmarkMiningTokens(uint256 amount) public {
        uint256 markedBalance = _markedForMining[_msgSender()];
        require(amount <= markedBalance, "Insufficient Marked Mineable to Unmark");
        _markedForMining[_msgSender()] = _markedForMining[_msgSender()].sub(amount);
        _tokensOwned[_msgSender()] = _tokensOwned[_msgSender()].add(amount);

        emit UnmarkedForMining(_msgSender(), amount);
    }

    /* Public Functions */

    /*
        @dev helper function for for the approval process. Increases allowance of the spender by the addedValue

        @param spender = The address that will recieve an extra allowance
        @param addedValue = The amount of extra allowance

        @return true boolean indicating success (else throws an exception)
    */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /*
        @dev helper function for for the approval process. Decreases allowance of the spender by the subtracted Value

        @param spender = The address that will lose allowance
        @param addedValue = The amount of allowance to take away

        @return true boolean indicating success (else throws an exception)
    */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Decreased allowance below zero"));
        return true;
    }

    /* Only Owner Functions */
    
    /*
        @dev excludes an address from the cooldown mechanism

        @param toExclude = the address to exclude from the cooldown
    */
    function excludeFromCooldown(address toExclude) external onlyOwner {
        require(!_avoidCoolDown[toExclude], 'Address is already excluded from cooldown');
        _avoidCoolDown[toExclude] = true;
    }

    /*
        @dev includes an address in the cooldown mechanism

        @param toInclude = the address to include in the cooldown
    */
    function includeInCooldown(address toInclude) external onlyOwner {
        require(_avoidCoolDown[toInclude], 'Address is already included in cooldown');
        _avoidCoolDown[toInclude] = false;
    }

    /*
        @dev removes a transaction limit from an address

        @param cappedAddress = address to remove the transaction limit from
    */
    function uncapLimit(address cappedAddress) external onlyOwner {
        require(!_isUnlimited[cappedAddress], 'Address already has uncapped transaction limit');
        _isUnlimited[cappedAddress] = true;
    }
 
    /*
        @dev places the transaction limit on an address

        @param uncappedAddress = address to place the transaction limit on to
    */
    function capLimit(address uncappedAddress) external onlyOwner {
        require(_isUnlimited[uncappedAddress], 'Address already has capped transction limit');
        _isUnlimited[uncappedAddress] = false;
    }

    /*
        @dev sets the Pancake Swap V2 router address
    */
    function setRouter(address _router) external onlyOwner {
        _pancakeV2Router = IPancakeRouter02(_router);
    }

    /*
        @dev sets the MINE/BNB pairing address the contract uses for swappings
    */
    function setPairAddress(address pairing) external onlyOwner {
        pairMineToWBNB = pairing;
    }

    /*
        @dev sets the average bsc block time (in seconds); used in the cooldown mechanism
    */
    function setAverageBlockTime(uint256 blockTime) external onlyOwner {
        _averageBlockTime = blockTime;
    }

    /*
        @dev sets the approximate amount of minutes the cooldown mechanism will enforce
    */
    function setApproximateCooldownSeconds(uint256 cooldown) external onlyOwner {
        _approxCooldownSeconds = cooldown;
    }
    
    /*
        @dev sets the miner fee percentage
        @notice capped at 6%
    */
    function setMinerFeePercentage(uint256 minerFee) external onlyOwner {
        require(minerFee <= 6, "Miner fee capped at 6 percent");
        _minerFeeRate = minerFee;
        emit MinerFeeRateAltered(minerFee);
    }

    /*
        @dev flag to enable the contract to swap the accrued Miner and Marketing fees
    */
    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    /*
        @dev sets the executor address (defaults as the owner address)
        @notice _executor has priviledges to call the swap on the accrued Miner and Marketing fees
    */
    function setExecutor(address exec) external onlyOwner {
        _executor = exec;
    }

    /*
        @dev sets the transaction limit
        @notice limit does not need to include decimal amounts
    */
    function setTransactionLimit(uint256 limit) external onlyOwner {
        _transactionLimit = limit;
    }

    /* Only Executor Functions */

    /*
        @dev external function to call swap of the contract's Mineable to BNB using Pancake Swap
        @dev the swapping is called externally to avoid attaching extra gas fees to normal transfer
        @dev if the fee balance is greater than or equal to the withdrawAmount, a withdrawal is performed

        @param maxMineableSwap = the max amount of Mineable to use in the swap
        @param withdrawAmount = the amount of bnb that, if the contract balance is greather than, will call withdrawals
        @param swapPriceIncludingDecimals = the MINE/BNB swap price multiplied by 10^18 (bnb decimals)

        Requirement:
            - the external caller must be the Executor address

    */
    function callSwap(uint256 maxMineableSwap, uint256 withdrawAmount, uint256 swapPriceIncludingDecimals) external payable onlyExecutor {
        uint256 maxMineable = maxMineableSwap * 10**_decimals;

        uint256 contractTokenBalance = balanceOf(address(this));        
        if (!inSwapAndLiquify && swapAndLiquifyEnabled){
            contractTokenBalance = maxMineable < contractTokenBalance ? maxMineable : contractTokenBalance;
            _swapTokens(contractTokenBalance, swapPriceIncludingDecimals); 
        }

        if(_currentMinerFees >= withdrawAmount) {
            _withdrawMinerFees();
        }
    }

    /* Private Functions */

    /*
        @dev finds the approximate amount of blocks it will take to mine for _approxCooldownSeconds of time to pass
        @dev i.e. _approxCooldownSeconds = 15 seconds, _averageBlockTime = 3 seconds, 5 * 60 / 3 = 100 blocks cooldown to wait 5 minutes 

        @return the approximate amount of bsc blocks it will take to cover _approxCoolDownSeconds amount of time
    */
    function _cooldownBlockCount() private view returns (uint256) {
        return _approxCooldownSeconds.div(_averageBlockTime);
    }

    /*
        @dev private function to handle to approval process

        @param holder = the address that is approving spender to spend its Mineable
        @param spender = the address that is being approved to spend holder's Mineable
        @param amount = the amount of Mineable that spender is allowed to spend on behaf of holder

        @return emits an Approval event
    */
    function _approve(address holder, address spender, uint256 amount) private {
        require(holder != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
    
        _allowances[holder][spender] = amount;
        emit Approval(holder, spender, amount);
    }

    /*
        @dev private function to filter out zero addresses and empty amount transfers

        @param sender = address that is sending Mineable to recipient
        @param recipient = address that is receiving Mineable from sender
        @param amount = amount to remove from sender's wallet, before fees

        Modifier: 
            - cooldown(sender, recipient): set/enforce the cooldown mechanism
            - limited(sender, recipient, amount): enforce the transaction limit mechanism
    */
    function _transfer(address sender, address recipient, uint256 amount) coolDown(sender, recipient) limited(sender, recipient, amount) private {
        require(sender != address(0), "TOKEN20: transfer from the zero address");
        require(recipient != address(0), "TOKEN20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        _tokenTransfer(sender, recipient, amount);
    }

    /*
        @dev private function to handle the transfer process
            - getValues() returns the rAmount and rTransferAmount which represents reflection amounts before and after tax.
            - getValues() also returns tMinerFee, tMarketingFee, tReflFee, and rReflFees
                These are passed to _takeMinerFee(), _takeMarketingFee(), and _reflectFee()
        
        @param sender = the address to remove rAmount from _reflectionsOwned[sender]
        @param recipient = the address to add rTransferAmount (rAmount minus fees) to _reflectionsOwned[recipient]
        @param grossAmount = the gross token amount that will be removed from sender's account
    */
    function _tokenTransfer(address sender, address recipient, uint256 grossAmount) private {
        (uint256 netAmount, uint256 minerFee) = _getValues(grossAmount);
        _tokensOwned[sender] = _tokensOwned[sender].sub(grossAmount, "Insufficient Balance");
        _tokensOwned[recipient] = _tokensOwned[recipient].add(netAmount);
        _takeMinerFee(minerFee);
        emit Transfer(sender, recipient, netAmount);
    }

    /*
        @dev private function to track the amount of BNB earned after calling _swapTokensForETH
        @dev _currentMinerFees and _currentMarketingFees keep track of how much BNB the separate withdrawal functions should withdraw

        @param contractTokenBalance = either the Mineable balance of the contract found by balanceOf(address(this)) or the maxMineableSwap
        
        Modifier:
            - lockTheSwap = preventing reentrancy 
    */
    function _swapTokens(uint256 contractTokenBalance, uint256 swapPrice) private lockTheSwap {
        uint256 initialBalance = _currentMinerFees;
        _swapTokensForETH(contractTokenBalance, swapPrice);
        uint256 transferredBalance = address(this).balance.sub(initialBalance);
        
        _currentMinerFees = _currentMinerFees.add(transferredBalance);
    }
    
    /*
        @dev private function to swap out the Mineable tokens accrued from Miner and Marketing fees to BNB
        @dev swap is performed on Pancake Swap using the pairing address formed when the MINE/BNB20 pairing is created

        @param tokenAmount = the amount of Mineable to swap

        Modifier:
            - nonReentrant: preventing reentrancy, again

        @return emits a SwapTokensForEth event to indicate success. Contract wallet will recieve BNB after this function
    */
    function _swapTokensForETH(uint256 tokenAmount, uint256 swapPrice) private nonReentrant {
        address[] memory path = new address[](2);
        path[0] = address(this);
        /* NOTE: Pancake Router WETH() points to WBNB address, not WETH */
        path[1] = _pancakeV2Router.WETH();
        
        _approve(address(this), address(_pancakeV2Router), tokenAmount);
       
        uint256 minAmountOut = tokenAmount.mul(swapPrice).mul(80).div(100);
        /* perform the swap */
        _pancakeV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            minAmountOut,
            path,
            payable(address(this)),
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }

    /*
        @dev function to withdraw BNB following a swap
        @dev withdraws the Miner BNB fees

        @return true if withdrawal was a success
    */
    function _withdrawMinerFees() private nonReentrant returns (bool) {
        uint256 amount = _currentMinerFees;
        _currentMinerFees = 0;
        (bool success, ) = minerAddress.call{value: amount}("");
        require(success, "Failed to send Miner Fees");
        emit MinerFeesWithdrawn(amount);
        return true;
    }
    
    /*
        @dev used in _tokenTransfer to find the amounts to remove from sender, add to recipient, and allocate for fees
        @dev gets the tokenValues (tValues) and the reflectionValues (rValues) based upon the tokenAmount (tAmount) passed in
        @dev calls _getTValues(tAmount), then uses the returned tValues to calculate the rValues in _getRValues

        @param tAmount = the token amount to calculate the tValues and rValues from
        @return 
            - rAmount = reflectionAmount to be removed from _reflectionsOwned[sender]
            - rTransferAmount = reflectionAmount to be added to _reflectionsOwned[recipient]
            - rReflFee = reflectionAmount to be removed from the _reflectionSupply
            - tTransferAmount = the token representation of how much has been removed from sender's account
            - tReflFee = the token representation of how much Reflection fees have been taken
            - tMinerFee = the token representation of how much Miner fees have been taken
            - tMarketingFee = the token represntation of how much Marketing fees have been taken
    */
    function _getValues(uint256 grossAmount) private view returns (uint256, uint256) {
        uint256 minerFee = _calculateMinerFee(grossAmount);
        uint256 netAmount = grossAmount.sub(minerFee);
        return (netAmount, minerFee);
    }

    
    /*
        @dev private function to handle adding Mineable tokens to the contract wallet for Miner fees

        @param tMinerFee = the token amount that will be converted to reflectionAmount, then added to _reflectionsOwned[address(this)]

        @return emits a Transfer event from the _msgSender() to the contract
    */
    function _takeMinerFee(uint256 minerFee) private {
        _tokensOwned[address(this)] = _tokensOwned[address(this)].add(minerFee);
        emit Transfer(_msgSender(), address(this), minerFee);

    }
    
    /*
        @dev when given a token amount, find the token amount of to take for Miner fees

        @param amount = token amount used to calculate the respective Miner fees

        @return token amount of Miner fees to take from amount
    */
    function _calculateMinerFee(uint256 amount) private view returns (uint256) {
        return amount.mul(_minerFeeRate).div(100);
    }
    
    receive() external payable {
        emit ReceivedBNB(_msgSender(), msg.value);
    }
}

