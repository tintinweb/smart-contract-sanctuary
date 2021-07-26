/**
 *Submitted for verification at polygonscan.com on 2021-07-26
*/

/*
    StakeMars Protocol ("STM")

    This is the staking contract on Polygon.

    TELEGRAM: https://t.me/StakeMars
    WEBSITE: https://www.StakeMars.com/
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

contract MarsStaking is Ownable {
    uint256 internal constant DISTRIBUTION_MULTIPLIER = 2**112;

    IERC20 public token;
    IERC20 public tokenUSD;

    mapping(address => uint256) public stakeValue;
    mapping(address => uint256) public stakerPayouts;
    mapping(address => uint256) public lastStakingTime;

    uint256 public totalDistributions;
    uint256 public totalStaked;
    uint256 public totalStakers;
    uint256 public profitPerShare;
    uint256 private emptyStakeTokens;
    uint256 public stakingFeePeriod;
    uint256 public feeBPS;
    mapping(address => bool) private _whitelist;

    // Burn wallet
    address public feeTo;

    event OnStake(address sender, uint256 amount);
    event OnUnstake(address sender, uint256 amount);
    event OnWithdraw(address sender, uint256 amount);
    event OnDistribute(address sender, uint256 amount);
    event Received(address sender, uint256 amount);

    constructor(IERC20 _token, IERC20 _tokenUSD, address _feeAcc) {
        token = _token;
        tokenUSD = _tokenUSD;
        stakingFeePeriod = 604800 * 2;
        feeBPS = 10;
        feeTo = _feeAcc;
    }

    function dividendsOf(address staker) public view returns (uint256) {
        uint256 divPayout = profitPerShare * stakeValue[staker];
        require(divPayout >= stakerPayouts[staker], "dividend calc overflow");

        return (divPayout - stakerPayouts[staker]) / DISTRIBUTION_MULTIPLIER;
    }

    function enterStaking(uint256 amount) public {
        require(
            token.balanceOf(msg.sender) >= amount,
            "Cannot stake more STM than you hold unstaked."
        );
        if (stakeValue[msg.sender] == 0) totalStakers += 1;

        _addStake(amount);

        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Stake failed due to failed transfer."
        );

        emit OnStake(msg.sender, amount);
    }

    function leaveStaking(uint256 amount) external {
        require(
            stakeValue[msg.sender] >= amount,
            "Cannot unstake more STM than you have staked."
        );

        harvest(dividendsOf(msg.sender));

        if(amount != 0){
            if (stakeValue[msg.sender] == amount) totalStakers = totalStakers -= 1;

            totalStaked = totalStaked -= amount;
            stakeValue[msg.sender] = stakeValue[msg.sender] -= amount;
            stakerPayouts[msg.sender] = profitPerShare * stakeValue[msg.sender];

            token.approve(address(this), amount);

            uint256 amountAfterFee = amount;

            if(lastStakingTime[msg.sender] >= block.timestamp - stakingFeePeriod) {
                uint256 fee = feeBPS * amount / 10000;
                amountAfterFee = amount - fee;
                require(
                    token.transferFrom(address(this), feeTo, fee),
                    "Unstake failed due to failed transfer."
                );
            }
            require(
                token.transferFrom(address(this), msg.sender, amountAfterFee),
                "Unstake failed due to failed transfer."
            );
        }

        emit OnUnstake(msg.sender, amount);
    }

    function harvest(uint256 amount) internal {
        require(
            dividendsOf(msg.sender) >= amount,
            "Cannot withdraw more dividends than you have earned."
        );

        stakerPayouts[msg.sender] =
        stakerPayouts[msg.sender] +
        amount *
        DISTRIBUTION_MULTIPLIER;
        tokenUSD.approve(address(this), amount);
        require(
            tokenUSD.transferFrom(address(this), msg.sender, amount),
            "Transfer fail"
        );
        emit OnWithdraw(msg.sender, amount);
    }

    function distribute(uint256 amount) external {
        if (amount > 0) {
            require(tokenUSD.transferFrom(msg.sender, address(this), amount), "Failed due to failed transfer.");
            totalDistributions += amount;
            _increaseProfitPerShare(amount);
            emit OnDistribute(msg.sender, amount);
        }
    }

    function _addStake(uint256 _amount) internal {
        totalStaked += _amount;
        stakeValue[msg.sender] += _amount;
        lastStakingTime[msg.sender] = block.timestamp;

        uint256 payout = profitPerShare * _amount;
        stakerPayouts[msg.sender] = stakerPayouts[msg.sender] + payout;
    }

    function _increaseProfitPerShare(uint256 amount) internal {
        if (totalStaked != 0) {
            if (emptyStakeTokens != 0) {
                amount += emptyStakeTokens;
                emptyStakeTokens = 0;
            }
            profitPerShare += ((amount * DISTRIBUTION_MULTIPLIER) / totalStaked);
        } else {
            emptyStakeTokens += amount;
        }
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function setStakingFeePeriod(uint256 _Time) external onlyOwner {
        require(_Time <= 1209600, "Cannot be over 2 week");
        stakingFeePeriod = _Time;
        emit UpdateStakingFeePeriod(_Time);
    }

    function setFee(uint256 _fee) external onlyOwner {
        require(_fee <= 100, "Cannot be over 1%");
        feeBPS = _fee;
        emit UpdateFeeBPS(_fee);
    }

    event UpdateStakingFeePeriod(uint256 stakingFeePeriod);
    event UpdateFeeBPS(uint256 stakingFeeBPS);
}