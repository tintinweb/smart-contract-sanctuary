/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

//// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/interfaces/IRocketDrop.sol


pragma solidity ^0.8.10;
// pragma experimental ABIEncoderV2;


interface IRocketDrop {
     struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 depositStamp;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;             // Address of LP token contract.
        uint256 lastRewardBlock;    // Last block number that ERC20s distribution occurs.
        uint256 accERC20PerShare;   // Accumulated ERC20s per share, times 1e36.
        IERC20 rewardToken;         // pool specific reward token.
        uint256 startBlock;         // pool specific block number when rewards start
        uint256 endBlock;           // pool specific block number when rewards end
        uint256 rewardPerBlock;     // pool specific reward per block
        uint256 paidOut;            // total paid out by pool
        uint256 tokensStaked;       // allows the same token to be staked across different pools
        uint256 gasAmount;          // eth fee charged on deposits and withdrawals (per pool)
        uint256 minStake;           // minimum tokens allowed to be staked
        uint256 maxStake;           // max tokens allowed to be staked
        address payable partnerTreasury;    // allows eth fee to be split with a partner on transfer
        uint256 partnerPercent;     // eth fee percent of partner split, 2 decimals (ie 10000 = 100.00%, 1002 = 10.02%)
    }

    // extra parameters for pools; optional
    struct PoolExtras {
        uint256 totalStakers;
        uint256 maxStakers;
        uint256 lpTokenFee;         // divide by 1000 ie 150 is 1.5%
        uint256 lockPeriod;         // time in blocks needed before withdrawal
        IERC20 accessToken;
        uint256 accessTokenMin;
        bool accessTokenRequired;
    }

    function deposit(uint256 _pid, uint256 _amount) external payable;
    function withdraw(uint256 _pid, uint256 _amount) external payable;
    function updatePool(uint256 _pid) external;
    function pending(uint256 _pid, address _user) external view returns (uint256);
    function rewardPerBlock(uint) external view returns (uint);
    function poolExtras(uint) external returns (PoolExtras memory);
    function userInfo(address) external returns (UserInfo memory);
    //mapping (uint256 => mapping (address => UserInfo)) public userInfo;
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: contracts/StakeManager.sol



pragma solidity ^0.8.10;

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract RBXStakeManager is Ownable {
    IERC20 public rbxs;
    IRocketDrop public rocketDrop;

    struct PoolInfo {
        uint poolID;
        uint collected;
        uint distributed;
        uint amount;
        uint accounts;
        uint lastUpdateBlock;
        uint accruedValuePerShare;
        uint rewardPerBlock;
    }

    struct UserInfo {
        uint amount;
        uint distroDebt;
    }

    PoolInfo public poolInfo;

    mapping(address => UserInfo) public userInfo;
    //mapping()

    constructor(address _rocketDrop, address _rbxs){
        rocketDrop = IRocketDrop(_rocketDrop);
        rbxs = IERC20(_rbxs);
    }

    function createAllotment(address account, uint amount) public onlyOwner {
        UserInfo storage allotment = userInfo[account];
        require(allotment.amount == 0, "Allotment already established");
        
        uint bal0 = rbxs.balanceOf(address(this));
        rbxs.transferFrom(msg.sender, address(this), amount);
        rbxs.approve(address(rocketDrop),amount);
        rocketDrop.deposit(poolInfo.poolID, amount);
        poolInfo.amount += amount;
        uint newYield = rbxs.balanceOf(address(this)) - bal0;

        poolInfo.collected += newYield;
        poolInfo.accruedValuePerShare += newYield * 1e18 / poolInfo.amount;

        allotment.amount = amount;
        allotment.distroDebt = amount * poolInfo.accruedValuePerShare / 1e18;

        poolInfo.accounts += 1;
    }

    function transferAllotment(address account0, address account1, bool withClaim) public onlyOwner {
        UserInfo storage allotment0 = userInfo[account0];
        UserInfo storage allotment1 = userInfo[account1];
        require(allotment0.amount > 0, "Allotment does not exist");
        
        if(withClaim)
            internalClaim(account0);

        allotment1.amount += allotment0.amount;
        allotment1.distroDebt += allotment0.distroDebt;

        allotment0.amount = 0;
        allotment0.distroDebt = 0;
    }

    function discardAllotment(address account, bool withClaim) public onlyOwner {
        UserInfo storage allotment = userInfo[account];
        require(allotment.amount > 0, "Allotment does not exist");
        
        if(withClaim)
            internalClaim(account);
        
        poolInfo.amount -= allotment.amount;
        poolInfo.accounts -= 1;

        allotment.amount = 0;
        allotment.distroDebt = 0;


        rocketDrop.withdraw(poolInfo.poolID, allotment.amount);
        rbxs.transfer(msg.sender, rbxs.balanceOf(address(this)));
    }

    function batchCreate(address[] memory accounts, uint[] memory amounts) public onlyOwner {
        uint totalAmount;

        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        if(poolInfo.amount > 0){
            collectPoolYield();
        }

        rbxs.transferFrom(msg.sender, address(this), totalAmount);
        rbxs.approve(address(rocketDrop),totalAmount);
        rocketDrop.deposit(poolInfo.poolID, totalAmount);

        for (uint256 i = 0; i < accounts.length; i++) {
            require(userInfo[accounts[i]].amount == 0, "Allotment already exists");
            userInfo[accounts[i]].amount = amounts[i];
            userInfo[accounts[i]].distroDebt = amounts[i] * poolInfo.accruedValuePerShare / 1e18;
            poolInfo.accounts += 1;
            poolInfo.amount += userInfo[accounts[i]].amount;
        }   
    }

    function batchDiscard(address[] memory accounts, uint[] memory amounts) public onlyOwner {
        uint totalAmount;

        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += userInfo[accounts[i]].amount;
        }

        uint bal0 = rbxs.balanceOf(address(this));

        rocketDrop.withdraw(poolInfo.poolID, totalAmount);
        rbxs.transfer(msg.sender, totalAmount);

        uint newYield = rbxs.balanceOf(address(this)) - bal0;

        poolInfo.collected += newYield;
        poolInfo.accruedValuePerShare += newYield * 1e18 / poolInfo.amount;

        for (uint256 i = 0; i < accounts.length; i++) {
            poolInfo.amount -= userInfo[accounts[i]].amount;
            poolInfo.accounts -= 1;
            userInfo[accounts[i]].amount = 0;
            userInfo[accounts[i]].distroDebt = 0;
        }   
    }


    function pendingCurrent(address _account) public view returns (uint){
        UserInfo memory account = userInfo[_account];
        uint valuePerShare = poolInfo.accruedValuePerShare;

        return account.amount * valuePerShare / 1e18 - account.distroDebt;
    }


    function pending(address _account) public view returns (uint){
        uint pendingAmount = rocketDrop.pending(poolInfo.poolID, address(this));
        uint valuePerShare = poolInfo.accruedValuePerShare + (pendingAmount * 1e18 / poolInfo.amount);

        UserInfo memory account = userInfo[_account];

        return account.amount * valuePerShare / 1e18 - account.distroDebt;
    }

    function accountAllotment(address account) public view returns (uint){
        return userInfo[account].amount;
    }

    function uncollectedYield() public view returns (uint){
        return rocketDrop.pending(poolInfo.poolID, address(this));
    }

    function collectPoolYield() public {
        if(poolInfo.amount == 0){
            return;
        }

        uint bal0 = rbxs.balanceOf(address(this));

        rocketDrop.withdraw(poolInfo.poolID, 0);
        uint newYield = rbxs.balanceOf(address(this)) - bal0;
        poolInfo.collected += newYield;
        poolInfo.accruedValuePerShare += newYield * 1e18 / poolInfo.amount;

    }

    function claimAccountYield() public {
        UserInfo storage user = userInfo[msg.sender];
        collectPoolYield();

        uint pendingAmount = pendingCurrent(msg.sender);

        if(pendingAmount > 0){
            user.distroDebt += pendingAmount;
            distribute(msg.sender, pendingAmount);
        }  
    }

    function internalClaim(address account) internal {
        UserInfo storage user = userInfo[account];
        collectPoolYield();

        uint pendingAmount = pendingCurrent(account);

        if(pendingAmount > 0){
            user.distroDebt += pendingAmount;
            distribute(account, pendingAmount);
        }  
    }

    function distribute(address to, uint amount) internal {
        rbxs.transfer(to, amount);
        poolInfo.distributed += amount;
    }
    
    // used for pool access on rocketDrop
    function balanceOf(address account) external view returns (uint){
        return account == address(this) ? 1 : 0;
    }

    // admin functions
    
    function setPID(uint _pid) public onlyOwner {
        poolInfo.poolID = _pid;
    }

    function adjustBlockReward(uint256 _rewardPerBlock) public onlyOwner {
        poolInfo.rewardPerBlock = _rewardPerBlock;
    }

    function adjustRocketDrop(address _rocketDrop) public onlyOwner {
        rocketDrop = IRocketDrop(_rocketDrop);
    }

    function adjustRBXS(address _rbxs) public onlyOwner {
        rbxs = IERC20(_rbxs);
    }

    function adjustVPS(uint256 _accruedValuePerShare) public onlyOwner {
        poolInfo.accruedValuePerShare = _accruedValuePerShare;
    }

    function tokenRescue(address _recipient, address _ERC20address, uint256 _amount) public onlyOwner {
        IERC20(_ERC20address).transfer(_recipient, _amount);
    }

    function rescueNative(address payable _recipient) public onlyOwner {
        _recipient.transfer(address(this).balance);
    }

    function adjustUser(address _user, uint _amount, uint _distroDebt) public onlyOwner {
        userInfo[_user].amount = _amount;
        userInfo[_user].distroDebt = _distroDebt;
    }

}