/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

contract ENVRWDStakePool2 is Ownable {
    string public name = "ENV REWARD Pool 2";
    IERC20 public envToken;
    IERC20 public rewardToken;

    address[] public stakers;
    mapping(address => uint256) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    uint256 public totalStakedEnvTokenAmts;
    uint256 public wholeRewardTokenAmts;
    uint256 public feeRate;
    uint256 public totalFeeAmts;
    uint256 public feeAmt;

    event EthReceived(address indexed _from, uint256 _value);

    constructor(address _envToken, address _rewardToken) {
        envToken = IERC20(_envToken);
        rewardToken = IERC20(_rewardToken);
        feeRate = 0;
        totalFeeAmts = 0;
        feeAmt = 10**16;
    }

    // Set the reward token
    function setRewardToken(address _rewardTokenAddress) public onlyOwner {
        rewardToken = IERC20(_rewardTokenAddress);
    }

    // Set the fee rate from owner.
    function setFeeRate(uint256 _feeRate) public onlyOwner {
        require(
            _feeRate >= 0 && _feeRate <= 10000,
            "The input value is out of range."
        );
        feeRate = _feeRate;
    }

    // Set wholeRewardTokenAmts
    function setWholeRewardTokenAmts(uint256 _amt) public onlyOwner {
        require(_amt >= 0, "Amount should be greater than 0.");
        wholeRewardTokenAmts = _amt;
    }

    // Set feeAmt
    function setFeeAmt(uint256 _feeAmt) public onlyOwner {
        require(_feeAmt >= 0, "Amount should be greater than 0");
        feeAmt = _feeAmt;
    }

    // Stake ENV token.
    function stakeTokens(uint256 _amount) public payable {
        // Require if is in staking period.
        require(wholeRewardTokenAmts > 0, "Out of staking period");

        // Require amount greater than 0
        require(_amount > 0, "amount should be greater than 0");

        // Require msg.sender is not address(0)
        require(msg.sender != address(0), "cannot stake from zero address");

        // Require the msg has enough fee.
        require(msg.value >= feeAmt, "Insufficient fee");

        // Trasnfer ENV tokens to this contract for staking
        require(
            envToken.transferFrom(msg.sender, address(this), _amount),
            "Token transfer failed"
        );

        // Update staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        // Add user to stakers array *only* if they haven't staked already
        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        // Update staking status
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;

        // Update totalStakedEnvTokenAmts
        totalStakedEnvTokenAmts = totalStakedEnvTokenAmts + _amount;

        totalFeeAmts += msg.value;
        emit EthReceived(msg.sender, msg.value);
    }

    // Unstaking Tokens (Withdraw)
    function unstakeTokens() public {
        // Fetch staking balance
        uint256 balance = stakingBalance[msg.sender];

        // Require amount greater than 0
        require(balance > 0, "staking balance cannot be 0");

        // Transfer ENV tokens to this contract for unstaking.
        require(
            envToken.transfer(msg.sender, balance),
            "Token transfer failed."
        );

        // Reset staking balance
        stakingBalance[msg.sender] = 0;

        // Update staking status
        isStaking[msg.sender] = false;

        // Update totalStakedEnvTokenAmts
        totalStakedEnvTokenAmts = totalStakedEnvTokenAmts - balance;
    }

    // Reward Tokens
    function rewardTokens(uint256 _rewardAmount) public onlyOwner {
        require(stakers.length > 0, "No stakers");
        require(wholeRewardTokenAmts > 0, "Out of Staking period");
        require(
            wholeRewardTokenAmts - _rewardAmount >= 0,
            "Invalid Reward Amount"
        );

        // Issue tokens to all stakers
        for (uint256 i = 0; i < stakers.length; i++) {
            address recipient = stakers[i];
            uint256 balance = stakingBalance[recipient];
            if (balance > 0) {
                uint256 reward = (_rewardAmount * balance) /
                    totalStakedEnvTokenAmts;
                rewardToken.transfer(recipient, reward);
            }
        }

        wholeRewardTokenAmts = wholeRewardTokenAmts - _rewardAmount;
    }

    // Release whole stakingbalances to stakeholders after the staking period.
    function releaseStakes2StakeHolders() public onlyOwner {
        require(wholeRewardTokenAmts == 0, "Not finished the staking period.");
        // Refund tokens to all stakers
        for (uint256 i = 0; i < stakers.length; i++) {
            address recipient = stakers[i];
            uint256 balance = stakingBalance[recipient];
            if (balance > 0) {
                envToken.transfer(recipient, balance);
                totalStakedEnvTokenAmts = totalStakedEnvTokenAmts - balance;
                isStaking[recipient] = false;
            }
        }
    }

    // Withdraw the ENVs inside the contract to the owner.
    function withdrawENV(uint256 _amount) public onlyOwner {
        require(_amount <= envToken.balanceOf(address(this)), "Invalid amount");
        require(
            envToken.transfer(msg.sender, _amount),
            "Token transfer failed"
        );
    }

    // Release the [Reward] tokens inside the contract to the owner.
    function withdrawRewardToken(uint256 _amount) public onlyOwner {
        require(
            _amount <= rewardToken.balanceOf(address(this)),
            "Invalid amount."
        );
        require(
            rewardToken.transfer(msg.sender, _amount),
            "Token transfer failed."
        );
    }

    // Get the amount of current ENVs inside the contract.
    function getEnvTokenAmts() public view returns (uint256) {
        return envToken.balanceOf(address(this));
    }

    // Get the amount of current Rewards inside the contract.
    function getRewardTokenAmts() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    // Receive Ether function
    receive() external payable {
        emit EthReceived(msg.sender, msg.value);
    }

    // Withdraw totalFees(Ether) from the contract
    function withdrawFees() public payable onlyOwner {
        require(address(this).balance >= totalFeeAmts, "Insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = payable(msg.sender).call{value: totalFeeAmts}("");
        require(success, "Unable to send value, owner may have reverted");
        totalFeeAmts = 0;
    }
}