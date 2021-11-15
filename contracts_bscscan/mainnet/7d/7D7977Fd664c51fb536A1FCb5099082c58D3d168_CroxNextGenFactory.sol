// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./CroxNextGen.sol";
import "./../libs/IBEP20.sol";

contract CroxNextGenFactory is Ownable {
    event NewCroxNextGenContract(address indexed croxNextGen);

    constructor() public {
        //
    }

    /*
     * @notice Deploy the pool
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _secRewardToken: second reward token address
     * @param _penaltyFee: penaltyFee percentage by 10000
     * @param _feeAddress: fee address
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _secRewardPerBlock: second reward per block (in rewardToken)
     * @param _startBlock: start block
     * @param _endBlock: end block
     * @param _lockPeriod: the lock period
     * @param _admin: admin address with ownership
     * @return address of new crox nextGen contract
     */
    function deployPool(
        address _stakedToken,
        address _rewardToken,
        address _secRewardToken,
        address _feeAddress,
        uint256 _penaltyFee,
        uint256 _rewardPerBlock,
        uint256 _secRewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _lockPeriod,
        address _admin
    ) external onlyOwner {
        require(IBEP20(_stakedToken).totalSupply() >= 0);
        require(IBEP20(_rewardToken).totalSupply() >= 0);
        require(_stakedToken != _rewardToken, "Tokens must be be different");
        address croxNextGenAddress = _nextGenAddress(IBEP20(_stakedToken), IBEP20(_rewardToken), _startBlock);

        CroxNextGenInitializable(croxNextGenAddress).initialize(
            _stakedToken,
            _rewardToken,
            _secRewardToken,
            _feeAddress,
            _penaltyFee,
            _rewardPerBlock,
            _secRewardPerBlock,
            _startBlock,
            _bonusEndBlock,
            _lockPeriod,
            _admin
        );

        emit NewCroxNextGenContract(croxNextGenAddress);
    }

    function _nextGenAddress(
        IBEP20 _stakedToken,
        IBEP20 _rewardToken,
        uint256 _startBlock
    ) internal returns (address) {
        bytes memory bytecode = type(CroxNextGenInitializable).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_stakedToken, _rewardToken, _startBlock));
        address croxNextGenAddress;

        assembly {
            croxNextGenAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        return croxNextGenAddress;
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

    constructor () internal {
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

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./../libs/IBEP20.sol";

contract CroxNextGenInitializable is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // The address of fee charge
    address public feeAddress;

    // The address of the crox nextGen factory
    address public CROX_NEXTGEN_FACTORY;

    // Whether it is initialized
    bool public isInitialized;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // Accrued token per share
    uint256 public secAccTokenPerShare;

    // The block number when CROX mining ends.
    uint256 public bonusEndBlock;

    // The block number when CROX mining starts.
    uint256 public startBlock;

    // The block number of the last pool update
    uint256 public lastRewardBlock;

    // CROX tokens created per block.
    uint256 public rewardPerBlock;

    // second reward tokens created per block.
    uint256 public secRewardPerBlock;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // The precision factor
    uint256 public SECOND_PRECISION_FACTOR;

    // The reward token
    IBEP20 public rewardToken;

    // The second reward token
    address public secRewardToken;

    // The staked token
    IBEP20 public stakedToken;

    // The withdraw penalty fee of main token
    uint256 public penaltyFee;

    // The deposit fee of main token
    uint256 public depositFee;

    // The maximum deposit fee of main token
    uint256 public constant MAXIMUM_DEPOSIT_FEE = 400;

    // The withdrawal interval
    uint256 public lockPeriod;

    // Max withdrawal interval: 30 days.
    uint256 public constant MAXIMUM_WITHDRAWAL_INTERVAL = 60 days;

    // The maximum staked token amount per user
    uint256 public stakedTokenLimit;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt
        uint256 secRewardDebt; // Second Reward debt
        uint256 withdrawFrom; // When can the user withdraw again.
    }

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event NewSecondRewardPerBlock(uint256 rewardPerBlock);
    event RewardsStop(uint256 blockNumber);
    event Withdraw(address indexed user, uint256 amount);
    event NewWithdrawalInterval(uint256 interval);
    event NewDepositFee(uint256 fee);

    constructor() public {
        CROX_NEXTGEN_FACTORY = msg.sender;
    }

    /*
     * @notice Initialize the contract
     * @param _stakedToken: staked token address
     * @param _rewardToken: reward token address
     * @param _rewardPerBlock: reward per block (in rewardToken)
     * @param _startBlock: start block
     * @param _bonusEndBlock: end block
     * @param _lockPeriod: lock period
     * @param _admin: admin address with ownership
     */
    function initialize(
        address _stakedToken,
        address _rewardToken,
        address _secRewardToken,
        address _feeAddress,
        uint256 _penaltyFee,
        uint256 _rewardPerBlock,
        uint256 _secRewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _lockPeriod,
        address _admin
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == CROX_NEXTGEN_FACTORY, "Not factory");
        require(_lockPeriod <= MAXIMUM_WITHDRAWAL_INTERVAL, "Invalid withdrawal interval");

        // Make this contract initialized
        isInitialized = true;

        stakedToken = IBEP20(_stakedToken);
        rewardToken = IBEP20(_rewardToken);
        penaltyFee = _penaltyFee;
        secRewardToken = _secRewardToken;
        rewardPerBlock = _rewardPerBlock;
        secRewardPerBlock = _secRewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        lockPeriod = _lockPeriod;
        feeAddress = _feeAddress;

        // Set initial deposit fees
        _setInitDepositFee();

        // Set the precision factors for reward tokens
        _setPrecisionFactor();

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_admin);
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        require(user.amount.add(_amount) <= stakedTokenLimit, "Stake token limitation reached");

        _updatePool();

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
            if (pending > 0) {
                rewardToken.transfer(address(msg.sender), pending);
                // user.withdrawFrom = block.timestamp.add(lockPeriod);
            }
            if (secRewardToken != address(0)) {
                uint256 secPending = user.amount.mul(secAccTokenPerShare).div(SECOND_PRECISION_FACTOR).sub(user.secRewardDebt);
                if (secPending > 0) {
                    IBEP20(secRewardToken).transfer(address(msg.sender), secPending);
                    // user.withdrawFrom = block.timestamp.add(lockPeriod);
                }
            }
        }

        if (_amount > 0) {
            uint256 feeStakedToken = _amount.mul(depositFee).div(10000);
            stakedToken.transferFrom(address(msg.sender), feeAddress, feeStakedToken);
            stakedToken.transferFrom(address(msg.sender), address(this), _amount.sub(feeStakedToken));
            user.amount = user.amount.add(_amount).sub(feeStakedToken);

            if (user.withdrawFrom == 0) {
                user.withdrawFrom = block.timestamp.add(lockPeriod);
            }
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);

        if (secRewardToken != address(0)) {
            user.secRewardDebt = user.amount.mul(secAccTokenPerShare).div(SECOND_PRECISION_FACTOR);
        }

        emit Deposit(msg.sender, _amount);
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");
        // require(user.withdrawFrom <= block.timestamp, "Withdrawal locked");

        _updatePool();

        uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            if (user.withdrawFrom <= block.timestamp) {
                stakedToken.transfer(address(msg.sender), _amount);
            } else {
                uint256 penalty = _amount.mul(penaltyFee).div(10000);
                stakedToken.transfer(feeAddress, penalty);
                stakedToken.transfer(address(msg.sender), _amount.sub(penalty));
            }
        }

        if (pending > 0) {
            rewardToken.transfer(address(msg.sender), pending);
            // user.withdrawFrom = block.timestamp.add(lockPeriod);
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);

        if (secRewardToken != address(0)) {
            uint256 secPending = user.amount.mul(secAccTokenPerShare).div(SECOND_PRECISION_FACTOR).sub(user.secRewardDebt);

            if (secPending > 0) {
                IBEP20(secRewardToken).transfer(address(msg.sender), secPending);
                // user.withdrawFrom = block.timestamp.add(lockPeriod);
            }

            user.secRewardDebt = user.amount.mul(secAccTokenPerShare).div(SECOND_PRECISION_FACTOR);
        }

        emit Withdraw(msg.sender, _amount);
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        // require(user.withdrawFrom <= block.timestamp, "Withdrawal locked");

        uint256 amountToTransfer = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.secRewardDebt = 0;
        user.withdrawFrom = 0;

        if (amountToTransfer > 0) {
            if (user.withdrawFrom <= block.timestamp) {
                stakedToken.transfer(address(msg.sender), amountToTransfer);
            } else {
                uint256 penalty = amountToTransfer.div(10);
                stakedToken.transfer(feeAddress, penalty);
                stakedToken.transfer(address(msg.sender), amountToTransfer.sub(penalty));
            }
        }

        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        rewardToken.transfer(address(msg.sender), _amount);
        IBEP20(secRewardToken).transfer(address(msg.sender), _amount);
    }

    /*
     * @notice Update StakedToken Limitation
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function updateStakedTokenLimit(uint256 _amount) external onlyOwner {
        stakedTokenLimit = _amount;
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(stakedToken), "Cannot be staked token");
        require(_tokenAddress != address(rewardToken), "Cannot be reward token");

        IBEP20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     * @param _feeAddress: new fee address
     */
    function updateFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0), "Invalid address");
        feeAddress = _feeAddress;
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner {
        bonusEndBlock = block.number;
    }

    /*
     * @notice Update reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }

    /*
     * @notice Update second reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateSecondRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        require(secRewardToken != address(0), "Second reward token doesn't exist");
        secRewardPerBlock = _rewardPerBlock;
        emit NewSecondRewardPerBlock(_rewardPerBlock);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @dev This function is only callable by owner.
     * @param _startBlock: the new start block
     * @param _bonusEndBlock: the new end block
     */
    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _bonusEndBlock) external onlyOwner {
        require(block.number < startBlock, "Pool has started");
        require(_startBlock < _bonusEndBlock, "New startBlock must be lower than new endBlock");
        require(block.number < _startBlock, "New startBlock must be higher than current block");

        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        emit NewStartAndEndBlocks(_startBlock, _bonusEndBlock);
    }

    /*
     * @notice Update the withdrawal interval
     * @dev Only callable by owner.
     * @param _interval: the withdrawal interval for staked token in seconds
     */
    function updateWithdrawalInterval(uint256 _interval) external onlyOwner {
        require(_interval <= MAXIMUM_WITHDRAWAL_INTERVAL, "Invalid withdrawal interval");
        lockPeriod = _interval;
        emit NewWithdrawalInterval(_interval);
    }

    /*
     * @notice Update the deposit fee
     * @dev Only callable by owner.
     * @param _fee: the deposit fee of first token
     */
    function updateDepositFee(uint256 _fee) external onlyOwner {
        require(_fee <= MAXIMUM_DEPOSIT_FEE, "Invalid deposit fee");
        depositFee = _fee;
        emit NewDepositFee(_fee);
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256, uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));
        if (block.number > lastRewardBlock && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 cakeReward = multiplier.mul(rewardPerBlock);
            uint256 adjustedTokenPerShare = accTokenPerShare.add(cakeReward.mul(PRECISION_FACTOR).div(stakedTokenSupply));
            uint256 secPendingReward = 0;

            if (secRewardToken != address(0)) {
                uint256 secCakeReward = multiplier.mul(secRewardPerBlock);
                uint256 secAdjustedTokenPerShare = secAccTokenPerShare.add(secCakeReward.mul(SECOND_PRECISION_FACTOR).div(stakedTokenSupply));
                secPendingReward = user.amount.mul(secAdjustedTokenPerShare).div(SECOND_PRECISION_FACTOR).sub(user.secRewardDebt);
            }
            return (user.amount.mul(adjustedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt), secPendingReward);
        } else {
            return (user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt), user.amount.mul(secAccTokenPerShare).div(SECOND_PRECISION_FACTOR).sub(user.secRewardDebt));
        }
    }

    // View function to see if user can withdraw staked token.
    function canWithdraw(address _user) external view returns (bool) {
        UserInfo storage user = userInfo[_user];
        return block.timestamp >= user.withdrawFrom;
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));

        if (stakedTokenSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        uint256 cakeReward = multiplier.mul(rewardPerBlock);
        uint256 secCakeReward = multiplier.mul(secRewardPerBlock);
        accTokenPerShare = accTokenPerShare.add(cakeReward.mul(PRECISION_FACTOR).div(stakedTokenSupply));
        secAccTokenPerShare = secAccTokenPerShare.add(secCakeReward.mul(SECOND_PRECISION_FACTOR).div(stakedTokenSupply));
        lastRewardBlock = block.number;
    }

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    /*
     * @notice Set precision factors of reward tokens
     */

    function _setPrecisionFactor() internal {
        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(10**(uint256(30).sub(decimalsRewardToken)));

        if (secRewardToken != address(0)) {
            uint256 decimalsSecRewardToken = uint256(IBEP20(secRewardToken).decimals());
            require(decimalsSecRewardToken < 30, "Must be inferior to 30");

            SECOND_PRECISION_FACTOR = uint256(10**(uint256(30).sub(decimalsSecRewardToken)));
        }
    }

    /*
     * @notice Set deposit fees of main tokens
     */

    function _setInitDepositFee() internal {
        depositFee = 400;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

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

