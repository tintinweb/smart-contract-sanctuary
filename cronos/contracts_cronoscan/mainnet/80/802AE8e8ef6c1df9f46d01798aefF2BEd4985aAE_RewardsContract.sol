/**
 *Submitted for verification at cronoscan.com on 2022-05-30
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// File: contracts/pleasebefinished.sol


pragma solidity ^0.8;



/*

*/

interface IMeerkatRouter02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapFeeReward() external pure returns (address);

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
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

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



interface IFarm {


    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SUSHI to distribute per block.
        uint256 lastRewardBlock;  // Last block number that SUSHI distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHI per share, times 1e12. See below.
    }

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    function poolInfo(uint256 pid) external view returns (IFarm.PoolInfo memory);
    function poolLength() external view returns (uint256);

    function userInfo(uint256 pid, address _user) external view returns (IFarm.UserInfo memory);

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);
    function emissionRate() external view returns (uint256);

    // View function to see pending CAKEs on frontend.
    function pending(uint256 pid, address _user) external view returns (uint256);

    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 pid, uint256 _amount) external;
    function deposit(uint256 pid, uint256 _amount, bool _withdrawRewards) external;
    function deposit(uint256 pid, uint256 _amount, address _referrer) external;

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 pid, uint256 _amount) external;
    function withdraw(uint256 pid, uint256 _amount, bool _withdrawRewards) external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 pid) external;
}


contract RewardsContract is ReentrancyGuard, Ownable {
    
    address public chef = 0x3ff306B55b9058045AC35bbb59da2548ABcb3195;
    address public rewardToken = 0x2924C3071E131580e597E0a8Ff5f0621ff0C2cc9;
    address public sphere = 0xc9FDE867a14376829Ab759F4C4871F67e2d3E441;
    address public cro = 0x5C7F8A570d578ED84E63fdFA7b1eE72dEae1AE23;
    address public mmf = 0x145677FC4d9b8F19B5D56d1820c48e0443049a30;
    address public routerTwo = 0xeC0A7a0C2439E8Cb67b992b12ecd020Ea943c7Be;
    uint256 public pid = 0;
    
    struct UserData {
        uint256 stake;
        uint256 rewardTally;
    }

    mapping(address => UserData) public userInfo;
    mapping(address => bool) public managers;
    uint256 public accSpherePerShare = 0;


    ///////////////////////
    //      EVENTS       //
    ///////////////////////

    event boughtSphere(uint256 indexed amount);
    event deposit(address indexed from, uint256 indexed amount);
    event withdraw(address indexed from, uint256 indexed amount);
    event sphereClaimed(address indexed from, uint256 indexed amount);

    ////////////////////////////////////////////
    //                                        //
    //        /* CORE FUNCTIONS */            //
    //                                        //
    ////////////////////////////////////////////

    function stake(uint256 _amount) public {
       UserData storage user = userInfo[msg.sender];
       IFarm.PoolInfo memory poolinf = IFarm(chef).poolInfo(pid);
       if (user.stake > 0) {
           harvest();
       }
       if (_amount > 0) {
           poolinf.lpToken.transferFrom(msg.sender, address(this), _amount);
           user.stake = user.stake + _amount;
           poolinf.lpToken.approve(chef, user.stake);
           IFarm(chef).deposit(pid, _amount);
           user.rewardTally = user.rewardTally + accSpherePerShare * _amount;
       }
       emit deposit(msg.sender, _amount);
    }

    function unstake() public {
       UserData storage user = userInfo[msg.sender];
       IFarm.PoolInfo memory poolinf = IFarm(chef).poolInfo(pid);
       require(user.stake != 0);
       if (user.stake > 0) {
           harvest();
       }
       IFarm(chef).withdraw(pid, user.stake);
       poolinf.lpToken.transfer(msg.sender, user.stake);
       emit withdraw(msg.sender, user.stake);
       user.stake = 0;
       user.rewardTally = 0;
    }

    function harvest() public nonReentrant {
        UserData storage user = userInfo[msg.sender];
        uint256 pending = user.stake * accSpherePerShare - user.rewardTally;
        user.rewardTally = user.stake * accSpherePerShare;
        if (pending > 0) {
            IERC20(sphere).transfer(msg.sender, pending);
        }
        

        emit sphereClaimed(msg.sender, pending);
    }
    
    ///////////////////////
    //                   //
    //    /* UTILS */    //
    //                   //
    ///////////////////////

    function getPathForRewardToCro() private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = rewardToken;
    path[1] = cro;

    return path;
    }

    function getPathForCroToSphere() private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = cro;
    path[1] = sphere;
    
    return path;
    }

    function convertToSphere() public payable {
      IFarm(chef).deposit(pid, 0);  
      uint256 rewardBal = IERC20(rewardToken).balanceOf(address(this));
      IERC20(rewardToken).approve(routerTwo, rewardBal);
      uint[] memory amounts = IMeerkatRouter02(routerTwo).swapExactTokensForETH(rewardBal, 0, getPathForRewardToCro(), address(this), block.timestamp);
      uint256 croAmount = amounts[amounts.length - 1];
      uint256 devFee = croAmount / 20;
      croAmount = croAmount - devFee;
      uint[] memory sphereOut = IMeerkatRouter02(mmf).swapExactETHForTokens{value: croAmount}(0,  getPathForCroToSphere(), address(this), block.timestamp);
      uint256 sphereAmt = sphereOut[sphereOut.length - 1];
      distribute(sphereAmt);
      emit boughtSphere(sphereAmt);
    }

    function distribute(uint256 amt) public onlyManager {
            accSpherePerShare = accSpherePerShare + amt * 1e18 / tvl();
        }
    
    function emergencyWithdraw() public {
            UserData storage user = userInfo[msg.sender];
            require(user.stake > 0);
            IFarm.PoolInfo memory poolinf = IFarm(chef).poolInfo(pid);
            IFarm(chef).withdraw(pid, user.stake);
            uint amount = user.stake;
            user.stake = 0;
            user.rewardTally = 0;
            poolinf.lpToken.transfer(msg.sender, amount);
        }
    
    function info() public view returns(IFarm.PoolInfo memory) {
        IFarm.PoolInfo memory pool = IFarm(chef).poolInfo(pid);
        return pool;
    }


    //////////////////////////////
    //      VIEW FUNCTIONS      //
    //////////////////////////////

    function pendingReward(address _user) public view returns(uint256) {
            UserData storage user = userInfo[_user];
            return user.stake * accSpherePerShare / 1e18 - user.rewardTally;
        }

    function viewBalance(address _user) external view returns(uint256) {
        UserData storage user = userInfo[_user];
        return user.stake;
    }


    function sphereBalance() public view returns(uint256) {
        return IERC20(sphere).balanceOf(address(this));
    }
    
    function tvl() public view returns(uint256) {
        IFarm.UserInfo memory vault = IFarm(chef).userInfo(pid, address(this));
        return vault.amount;
    }


    ////////////////////
    //  /* ADMIN */   //
    ////////////////////
    
    function erc20Recover(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner(), balance);
    }

    function recoverCRO(address payable to, uint256 amount) external onlyOwner {
        to.transfer(amount);
    }

    function addManager(address _manager) external onlyOwner {
        managers[_manager] = true;
    }

    function removeManager(address _manager) external onlyOwner {
        managers[_manager] = false;
    }

    modifier onlyManager() {
        require(managers[msg.sender] == true);
        _;
    }
    receive() external payable {}
    
}