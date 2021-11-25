/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.2;



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



/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).x
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
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
    address private _previousOwner;
    uint256 private _lockTime;

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
    
    //Locks the contract for owner for the amount of time provided

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
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

interface IERC20RemovePauser is IERC20 {
    function removePauser() external;

    function pause() external;
    function unpause() external;
}

contract Presale is Ownable, ReentrancyGuard {
    event Deposited(address indexed user, uint256 amount);
    event Recovered(address token, uint256 amount);

    bool public initialized = false;
    bool public whitelistOff = false;

    address payable public treasury;

    uint256 public presaleStartTimestamp;
    uint256 public presaleEndTimestamp;
    uint256 public tokensPerBnb;
    uint256 public hardCapBnbAmount;
    uint256 public totalDepositedEthBalance;
    uint256 public minimumDepositBnbAmount;
    uint256 public maximumDepositBnbAmount;
    IERC20RemovePauser public PresaleStarter;
    address public token;

    IUniswapV2Router02 private pancakeswap;
    uint256 public lock = 0;

    mapping(address => uint256) public deposits;
    mapping(address => bool) public whitelist;
    uint256 public numWhitelisted = 0;
    
    

    constructor(
        address payable _treasury,
        uint256 _tokensPerBnb,
        uint256 _hardCapBnb,
        uint256 _minimumDepositBnbAmount,
        uint256 _maximumDepositBnbAmount,
        uint256 _presaleStartTimestamp,
        uint256 _presaleEndTimestamp
    ) {
        
        //Testnet 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    	//Mainnet 0x10ED43C718714eb63d5aA57B78B54704E256024E
    	
        pancakeswap = IUniswapV2Router02(
            0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        );
        treasury = _treasury;
        tokensPerBnb = _tokensPerBnb;
        hardCapBnbAmount = _hardCapBnb;
        minimumDepositBnbAmount = _minimumDepositBnbAmount;
        maximumDepositBnbAmount = _maximumDepositBnbAmount;
        presaleStartTimestamp = _presaleStartTimestamp;
        presaleEndTimestamp = _presaleEndTimestamp;
    }

    function addToWhitelist(address _whitelistee) public onlyOwner {
        require(
            numWhitelisted <= 200,
            "Cannot whitelist more than 200 addresses"
        );
        require(!whitelist[_whitelistee], "Whitelistee already added!");
        whitelist[_whitelistee] = true;
        numWhitelisted++;
    }

    function addToWhitelistMulti(address[] memory _whitelistees)
        public
        onlyOwner
    {
        require(
            _whitelistees.length <= 256,
            "Arrays cannot be over 256 in length"
        );

        for (uint256 i = 0; i < _whitelistees.length; i++) {
            addToWhitelist(_whitelistees[i]);
        }
    }

    function removeFromWhitelist(address _whitelistee) public onlyOwner {
        require(numWhitelisted > 0, "Cannot remove if no one is whitelisted");
        require(whitelist[_whitelistee], "Whitelistee does not exist!");
        whitelist[_whitelistee] = false;
        numWhitelisted--;
    }

    function removeFromWhitelistMulti(address[] memory _whitelistees)
        public
        onlyOwner
    {
        require(
            _whitelistees.length <= 256,
            "Arrays cannot be over 256 in length"
        );

        for (uint256 i = 0; i < _whitelistees.length; i++) {
            removeFromWhitelist(_whitelistees[i]);
        }
    }

    function initialize(
        address _token
    ) public onlyOwner {
        require(!initialized, "Already initialized");
        PresaleStarter = IERC20RemovePauser(_token);
        initialized = true;
        token = _token;
    }
    
    function buyTokens() external payable nonReentrant returns (bool) {
        require(initialized, "Not initialized");
        require(whitelist[_msgSender()] || whitelistOff, "You are not in the whitelist!");
        require(
            block.timestamp >= presaleStartTimestamp &&
                block.timestamp <= presaleEndTimestamp,
            "presale is not active"
        );
        require(
            totalDepositedEthBalance + (msg.value) <= hardCapBnbAmount,
            "deposit limits reached"
        );
        require(
            deposits[_msgSender()] + (msg.value) >= minimumDepositBnbAmount &&
                deposits[_msgSender()] + (msg.value) <= maximumDepositBnbAmount,
            "incorrect amount"
        );

        uint256 tokenAmount = (msg.value / 1 ether) * tokensPerBnb;

        bool result =  IERC20(token).transfer(_msgSender(), tokenAmount);

        totalDepositedEthBalance = totalDepositedEthBalance + (msg.value);

        deposits[_msgSender()] = deposits[_msgSender()] + (msg.value);

        emit Deposited(_msgSender(), msg.value);

        return result;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
        returns (bool)
    {
       // require(
       //     block.timestamp >= lock + (52 weeks),
        //    "You can claim LP tokens only after 52 weeks"
       // );
        bool result = IERC20(tokenAddress).transfer(this.owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
        return result;
    }

    function getDepositAmount() public view returns (uint256) {
        return totalDepositedEthBalance;
    }

    function releaseFunds() external onlyOwner {
        require(
            block.timestamp >= presaleEndTimestamp &&
                totalDepositedEthBalance < hardCapBnbAmount,
            "Presale is still active, or reached hardcap"
        );
        treasury.transfer(address(this).balance);
    }
    
    
     function setWhiteListOff(bool toggle) external onlyOwner {
       whitelistOff=toggle;
    }

    function addLiquidity(uint256 amountTokenDesired) external onlyOwner {
        require(
            block.timestamp >= presaleEndTimestamp ||
                totalDepositedEthBalance >= hardCapBnbAmount,
            "Presale is still active"
        );
        require(lock == 0, "Presale is already completed");

        // Set liquidity lock to now, this will be checked in recoverERC20 and also used for making sure the sale is over
        lock = block.timestamp;
        PresaleStarter.removePauser();

        uint256 treasuryAmount = address(this).balance / 5;

        treasury.transfer(treasuryAmount);

        uint256 liquidityEth = address(this).balance;

        PresaleStarter.approve(address(pancakeswap), amountTokenDesired);
        pancakeswap.addLiquidityETH{value: (liquidityEth)}(
            address(PresaleStarter),
            amountTokenDesired,
            amountTokenDesired,
            liquidityEth,
            address(this),
            block.timestamp + 60
        );
    }

    function presaleComplete() external view returns (bool) {
        return lock != 0;
    }
}