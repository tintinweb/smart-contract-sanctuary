/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

// File: @openzeppelin/contracts/utils/Context.sol

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


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
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: contracts/TokenSwap.sol

pragma solidity ^0.8.0;



contract TokenSwap is Ownable {

    event AdminWalletUpdated(address addr);
    event LockIntervalUpdated(uint256 interval);
    event LockPercentageUpdated(uint256 percentage);
    event MinDepositUpdated(uint256 amount);

    event TokenWithdrawed(uint256 amount);

    event PhaseCreated(uint256 startTime, uint256 endTime, uint256 swapRate);
    event PhaseTimeUpdated(uint256 phaseId, uint256 startTime, uint256 endTime);
    event SwapRateUpdated(uint256 phaseId, uint256 swapRate);

    event Swapped(uint256 phaseId, address account, uint256 ethDeposit, uint256 ethRefund, uint256 tokenSwap, uint256 tokenLock, string referralCode);

    event TokenClaimed(uint256 phaseId, address account, uint256 amount);
    event TotalTokenClaimed(address account, uint256 amount);

    IERC20 private _token;

    address private _adminWallet;

    uint256 private _lockInterval;

    uint256 private _lockPercentage;

    uint256 private _minDeposit;

    struct ReferralCodeInfo {
        uint128 amount; // ETH
        uint128 numSwap;
    }

    // Mapping referral code to statistics information
    mapping(string => ReferralCodeInfo) private _referralCodes;

    struct PhaseInfo {
        uint128 startTime;
        uint128 endTime;
        uint256 swapRate;
    }

    uint256 private _totalPhases;

    // Mapping phase id to phase information
    mapping(uint256 => PhaseInfo) private _phases;

    struct LockedBalanceInfo {
        uint128 amount; // Token
        uint128 releaseTime;
    }

    uint256 private _totalLockedBalance;

    // Mapping phase id to user address and locked balance information
    mapping(uint256 => mapping(address => LockedBalanceInfo)) private _lockedBalances;

    mapping(address => uint256[]) private _boughtPhases;

    /**
     * @dev Throws if phase doesn't exist
     */
    modifier phaseExist(uint256 phaseId) {
        require(_phases[phaseId].swapRate > 0, "TokenSwap: phase doesn't exist");
        _;
    }

    /**
     * @dev Sets initial values
     */
    constructor(address token, address adminWallet)
    {
        _token = IERC20(token);

        _adminWallet = adminWallet;

        _lockInterval = 6 * 30 days; // 6 months

        _lockPercentage = 75; // 75%

        _minDeposit = 0.5 ether;
    }

    /**
     * @dev Returns smart contract information
     */
    function getContractInfo()
        public
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, address, address)
    {
        return (
            _lockInterval, _lockPercentage, _totalLockedBalance, _totalPhases, _token.balanceOf(address(this)), _minDeposit,
            _adminWallet, address(_token)
        );
    }

    /**
     * @dev Updates admin wallet address where contains ETH user deposited
     * to smart contract for swapping
     */
    function updateAdminWallet(address adminWallet)
        public
        onlyOwner
    {
        require(adminWallet != address(0), "TokenSwap: address is invalid");

        _adminWallet = adminWallet;

        emit AdminWalletUpdated(adminWallet);
    }

    /**
     * @dev Updates lock interval
     */
    function updateLockInterval(uint256 lockInterval)
        public
        onlyOwner
    {
        _lockInterval = lockInterval;

        emit LockIntervalUpdated(lockInterval);
    }

    /**
     * @dev Updates lock percentage
     */
    function updateLockPercentage(uint256 lockPercentage)
        public
        onlyOwner
    {
        require(lockPercentage <= 100, "TokenSwap: percentage is invalid");

        _lockPercentage = lockPercentage;

        emit LockPercentageUpdated(lockPercentage);
    }

    /**
     * @dev Updates minimum deposit amount
     */
    function updateMinDeposit(uint256 minDeposit)
        public
        onlyOwner
    {
        require(minDeposit > 0, "TokenSwap: amount is invalid");

        _minDeposit = minDeposit;

        emit MinDepositUpdated(minDeposit);
    }

    /**
     * @dev Withdraws token out of this smart contract and transfer to 
     * admin wallet
     *
     * Admin can withdraw all tokens that includes locked token of user in case emergency
     */
    function withdrawToken(uint256 amount)
        public
        onlyOwner
    {
        require(amount > 0, "TokenSwap: amount is invalid");

        _token.transfer(_adminWallet, amount);

        emit TokenWithdrawed(amount);
    }

    /**
     * @dev Creates new phase
     */
    function createPhase(uint256 startTime, uint256 endTime, uint256 swapRate)
        public
        onlyOwner
    {
        require(startTime >= block.timestamp && startTime > _phases[_totalPhases].endTime && startTime < endTime, "TokenSwap: time is invalid");

        require(swapRate > 0, "TokenSwap: rate is invalid");

        _totalPhases++;

        _phases[_totalPhases] = PhaseInfo(uint128(startTime), uint128(endTime), swapRate);

        emit PhaseCreated(startTime, endTime, swapRate);
    }

    /**
     * @dev Updates phase time
     */
    function updatePhaseTime(uint256 phaseId, uint256 startTime, uint256 endTime)
        public
        onlyOwner
        phaseExist(phaseId)
    {
        PhaseInfo storage phase = _phases[phaseId];

        if (startTime != 0) {
            phase.startTime = uint128(startTime);
        }

        if (endTime != 0) {
            phase.endTime = uint128(endTime);
        }

        require((startTime == 0 || startTime >= block.timestamp) && phase.startTime < phase.endTime, "TokenSwap: time is invalid");

        emit PhaseTimeUpdated(phaseId, startTime, endTime);
    }

    /**
     * @dev Updates swap rate
     */
    function updateSwapRate(uint256 phaseId, uint256 swapRate)
        public
        onlyOwner
        phaseExist(phaseId)
    {
        require(swapRate > 0, "TokenSwap: rate is invalid");

        _phases[phaseId].swapRate = swapRate;

        emit SwapRateUpdated(phaseId, swapRate);
    }

    /**
     * @dev Returns phase information
     */
    function getPhaseInfo(uint256 phaseId)
        public
        view
        returns (PhaseInfo memory)
    {
        return _phases[phaseId];
    }

    /**
     * @dev Returns current active phase information
     */
    function getActivePhaseInfo()
        public
        view
        returns (uint256, PhaseInfo memory)
    {
        uint256 currentTime = block.timestamp;

        for (uint256 i = 1; i <= _totalPhases; i++) {
            PhaseInfo memory phase = _phases[i];

            if (currentTime < phase.endTime) {
                return (i, phase);
            }
        }

        return (0, _phases[0]);
    }

    /**
     * @dev Returns referral code information
     */
    function getReferralCodeInfo(string memory referralCode)
        public
        view
        returns (ReferralCodeInfo memory)
    {
        return _referralCodes[referralCode];
    }

    /**
     * @dev Swaps ETH to token
     */
    function swap(uint256 phaseId, string memory referralCode)
        public
        payable
    {
        require(msg.value >= _minDeposit, "TokenSwap: msg.value is invalid");

        PhaseInfo memory phase = _phases[phaseId];

        require(block.timestamp >= phase.startTime && block.timestamp < phase.endTime, "TokenSwap: not in swapping time");

        uint256 remain = _token.balanceOf(address(this)) - _totalLockedBalance;

        require(remain > 0, "TokenSwap: not enough token");

        uint256 amount = msg.value * phase.swapRate / 1 ether;

        uint refund;

        // Calculates redundant money
        if (amount > remain) {
            refund = (amount - remain) * 1 ether / phase.swapRate;
            amount = remain;
        }

        // Refunds redundant money for user
        if (refund > 0) {
            payable(_msgSender()).transfer(refund);
        }

        // Transfers money to admin wallet
        payable(_adminWallet).transfer(msg.value - refund);

        // Calculates number of tokens that will be locked
        uint256 locked = amount * _lockPercentage / 100;

        // Transfers token for user
        _token.transfer(_msgSender(), amount - locked);

        // Manages total locked tokens in smart contract
        _totalLockedBalance += locked;

        // Manages locked tokens by user
        LockedBalanceInfo storage balance = _lockedBalances[phaseId][_msgSender()];
        balance.amount += uint128(locked);
        balance.releaseTime = uint128(phase.startTime + _lockInterval);

        // Manages referral codes
        ReferralCodeInfo storage referral = _referralCodes[referralCode];
        referral.amount += uint128(msg.value - refund);
        referral.numSwap++;

        uint256[] storage phases = _boughtPhases[_msgSender()];

        if (phases.length == 0 || phases[phases.length - 1] != phaseId) {
            phases.push(phaseId);
        }

        emit Swapped(phaseId, _msgSender(), msg.value, refund, amount, locked, referralCode);
    }

    /**
     * @dev Returns token balance of user in smart contract that includes
     * claimable and unclaimable
     */
    function getTokenBalance(address account)
        public
        view
        returns (uint256, uint256)
    {
        uint256 currentTime = block.timestamp;

        uint256 balance;

        uint256 lockedBalance;

        uint256[] memory phases = _boughtPhases[account];

        for (uint256 i = 0; i < phases.length; i++) {
            LockedBalanceInfo memory info = _lockedBalances[phases[i]][account];

            if (info.amount == 0) {
                continue;
            }

            if (info.releaseTime <= currentTime) {
                balance += info.amount;

            } else {
                lockedBalance += info.amount;
            }
        }

        return (balance, lockedBalance);
    }

    /**
     * @dev Claims the remainning token after lock time end
     */
    function claimToken()
        public
    {
        address msgSender = _msgSender();

        uint256 currentTime = block.timestamp;

        uint256 balance;

        uint256[] memory phases = _boughtPhases[msgSender];

        uint256 length = phases.length;

        for (uint256 i = 0; i < length; i++) {
            LockedBalanceInfo memory info = _lockedBalances[phases[i]][msgSender];

            uint256 amount = info.amount;

            if (amount == 0) {
                continue;
            }

            if (info.releaseTime <= currentTime) {
                balance += amount;

                emit TokenClaimed(phases[i], msgSender, amount);

                delete _lockedBalances[phases[i]][msgSender];
            }
        }

        require(balance > 0, "TokenSwap: balance isn't enough");

        _totalLockedBalance -= balance;

        _token.transfer(msgSender, balance);

        emit TotalTokenClaimed(msgSender, balance);
    }

    /**
     * @dev Returns locked balance information
     */
    function getLockedBalanceInfo(uint256 phaseId, address account)
        public
        view
        returns (LockedBalanceInfo memory)
    {
        return _lockedBalances[phaseId][account];
    }

    /**
     * @dev Returns phases that user bought
     */
    function getBoughtPhases(address account)
        public
        view
        returns (uint256[] memory)
    {
        return _boughtPhases[account];
    }

}