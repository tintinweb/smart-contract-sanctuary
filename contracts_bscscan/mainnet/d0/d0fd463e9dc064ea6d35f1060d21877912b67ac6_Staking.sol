/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

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

// File openzeppelin-solidity/contracts/access/[email protected]

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File openzeppelin-solidity/contracts/token/ERC20/[email protected]

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File contracts/Staking.sol
pragma solidity ^0.8.2;

contract Staking is Ownable {
    struct Stake {
        uint256 stakedTokens;
        uint256 stakedRewardTokens;
        uint256 lastWithdrawnTime;
        uint256 cooldown;
    }

    uint256 public _divider = 1000;
    uint256 private _decimals = 18;
    uint256 private _rewardDecimals = 18;

    uint256 private _minimalAdditionalDelay = 20;
    uint256 public minimalDeposit = 10 * 10**_decimals;
    uint256 public rewardPeriod = 7 days;
    uint256 public ROI = 100;
    uint256 public rate = 2000;

    uint256 public totalTokensLocked;

    mapping(address => Stake) public Stakes;

    IERC20 _rewardToken;
    IERC20 _token;

    event Staked(address fromUser, uint256 amount);
    event Claimed(address byUser, uint256 reward);
    event Unstaked(address byUser, uint256 amount);

    function setRewardPeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod > 0, "Cannot be 0");
        rewardPeriod = newPeriod;
    }

    function setRate(uint256 newRate) external onlyOwner {
        require(rate > 0, "Cannot be 0");
        rate = newRate;
    }

    function setROI(uint256 newROI) external onlyOwner {
        require(newROI > 0, "Cannot be 0");
        ROI = newROI;
    }

    function setMinimalDeposit(uint256 newMinimalDeposit) external onlyOwner {
        minimalDeposit = newMinimalDeposit;
    }

    function setTokens(
        address token,
        address rewardToken,
        uint256 tokenDecimals,
        uint256 rewardTokenDecimals
    ) public onlyOwner {
        _rewardToken = IERC20(rewardToken);
        _token = IERC20(token);
        _decimals = tokenDecimals;
        _rewardDecimals = rewardTokenDecimals;
    }

    function getStakeInfo(address user)
        external
        view
        returns (
            uint256 stakedTokens,
            uint256 stakedRewardTokens,
            uint256 lastClaimed,
            uint256 cooldown
        )
    {
        return (
            Stakes[user].stakedTokens,
            Stakes[user].stakedRewardTokens,
            Stakes[user].lastWithdrawnTime,
            Stakes[user].cooldown
        );
    }

    function calculateAdditionalTime(
        uint256 staked,
        uint256 tokensReceived,
        uint256 cooldown,
        uint256 lastWithdrawn
    ) public view returns (uint256) {
        uint256 time = cooldown -
            ((block.timestamp - lastWithdrawn) * staked) /
            (staked + tokensReceived);
        return time;
    }

    constructor(
        address token,
        address rewardToken,
        uint256 tokenDecimals,
        uint256 rewardDecimals
    ) {
        setTokens(token, rewardToken, tokenDecimals, rewardDecimals);
    }

    function canClaim(address user) public view returns (bool) {
        return (getReward(user) > 0);
    }

    function getReward(address user) public view returns (uint256) {
        if (Stakes[user].stakedRewardTokens == 0) return 0;
        uint256 staked = Stakes[user].stakedRewardTokens;
        uint256 lastWithdrawn = Stakes[user].lastWithdrawnTime;
        uint256 cooldown = Stakes[user].cooldown;

        if (block.timestamp - cooldown <= lastWithdrawn) return 0;
        return (staked * ROI) / _divider;
    }

    function getTimings(address user) public view returns (uint256, uint256) {
        return (Stakes[user].lastWithdrawnTime, Stakes[user].cooldown);
    }

    function stake(uint256 tokens) external {
        require(tokens > 0, "Cannot stake 0");
        require(
            minimalDeposit <= tokens + Stakes[msg.sender].stakedRewardTokens,
            "Cannot stake such few tokens"
        );

        uint256 currentRewardBalance = _rewardToken.balanceOf(address(this));
        uint256 currentTokenBalance = _token.balanceOf(address(this));

        _rewardToken.transferFrom(msg.sender, address(this), tokens);
        uint256 rewardTokensReceived = _rewardToken.balanceOf(address(this)) -
            currentRewardBalance;

        _token.transferFrom(
            msg.sender,
            address(this),
            ((((rewardTokensReceived * rate) * _decimals) / _divider) /
                _rewardDecimals)
        );
        uint256 tokensReceived = _token.balanceOf(address(this)) -
            currentTokenBalance;

        require(
            tokensReceived > 0 && rewardTokensReceived > 0,
            "Cannot stake 0"
        );

        if (Stakes[msg.sender].stakedRewardTokens == 0) {
            Stakes[msg.sender].cooldown = rewardPeriod;
            Stakes[msg.sender].lastWithdrawnTime = block.timestamp;
        } else {
            uint256 reward = getReward(msg.sender);
            if (reward > 0) {
                _rewardToken.transfer(msg.sender, reward);
                Stakes[msg.sender].lastWithdrawnTime = block.timestamp;
                Stakes[msg.sender].cooldown = rewardPeriod;
            } else {
                Stakes[msg.sender].cooldown = calculateAdditionalTime(
                    Stakes[msg.sender].stakedRewardTokens,
                    rewardTokensReceived,
                    Stakes[msg.sender].cooldown,
                    Stakes[msg.sender].lastWithdrawnTime
                );
                Stakes[msg.sender].lastWithdrawnTime = block.timestamp;
            }
        }

        Stakes[msg.sender].stakedRewardTokens += rewardTokensReceived;
        Stakes[msg.sender].stakedTokens += tokensReceived;
        totalTokensLocked += rewardTokensReceived;

        emit Staked(msg.sender, tokensReceived);
    }

    function claim() public {
        require(canClaim(msg.sender), "Nothing to claim");
        uint256 reward = getReward(msg.sender);
        _rewardToken.transfer(msg.sender, reward);
        Stakes[msg.sender].lastWithdrawnTime = block.timestamp;
        Stakes[msg.sender].cooldown = rewardPeriod;

        emit Claimed(msg.sender, reward);
    }

    function unstake() external {
        require(
            Stakes[msg.sender].stakedRewardTokens > 0,
            "Nothing to unstake"
        );
        require(canClaim(msg.sender), "Can't unstake now");

        uint256 reward = getReward(msg.sender);
        uint256 unstakeRewardTokens = Stakes[msg.sender].stakedRewardTokens;
        uint256 unstakeTokens = Stakes[msg.sender].stakedTokens;

        _rewardToken.transfer(msg.sender, unstakeRewardTokens + reward);
        _token.transfer(msg.sender, unstakeTokens);

        totalTokensLocked = totalTokensLocked - unstakeRewardTokens;
        delete Stakes[msg.sender];
        emit Claimed(msg.sender, reward);
        emit Unstaked(msg.sender, unstakeRewardTokens);
    }
}