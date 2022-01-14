// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseTierStakingContract.sol";

contract FlexTierStakingContract is BaseTierStakingContract {

    uint8 public tierId = 0;
    uint8 public multiplier = 10; // in 1000
    uint8 public emergencyWithdrawlFee = 10;
    uint8 public enableEmergencyWithdrawl = 0;
    uint8 public enableRewards = 0; //disable rewards
    uint256 public unlockDuration = 7 * 24 * 60 * 60; // 7 days

    constructor(
        address _depositor,
        address _tokenAddress,
        address _feeAddress
    ) BaseTierStakingContract(
        tierId,
        multiplier,
        emergencyWithdrawlFee,
        enableEmergencyWithdrawl,
        unlockDuration,
        enableRewards,
        _depositor,
        _tokenAddress,
        _feeAddress
    ) {
        //
    }
  
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import './FullMath.sol';
import "./Pausable.sol";

// interface ITokenLocker {
//     function convertSharesToTokens(address _token, uint256 _shares) external view returns (uint256);
//     function LOCKS(uint256 lockId) external view returns (address, uint256, uint256, uint256, uint256, uint256, address, string memory);
// }

contract StakingHelper is Ownable, ReentrancyGuard, Pausable {

    using SafeERC20 for IERC20;
    
    struct Settings {
        uint256 startTimeForDeposit;
        uint256 endTimeForDeposit;
        uint256 ppMultiplier;
        uint256 privateSaleMultiplier;
        uint256 privateSaleTotalPP;
        uint256 withdrawalSuspensionStartTime;
        uint256 withdrawalSuspensionEndTime;
    }

    // mapping(address => uint256[]) public privateSaleUserLockerIds;
    uint256[] public privateSaleLockerIds;
    address public privateSaleLockerAddress;
    // ITokenLocker private tokenLocker;
    Settings public SETTINGS;

    constructor(
        uint256 _startTimeForDeposit,
        uint256 _endTimeForDeposit,
        uint256 _ppMultiplier,
        uint256 _privateSaleMultiplier,
        address _privateSaleLockerAddress
    ) {
        SETTINGS.startTimeForDeposit = _startTimeForDeposit;
        SETTINGS.endTimeForDeposit = _endTimeForDeposit;
        SETTINGS.ppMultiplier = _ppMultiplier;
        SETTINGS.privateSaleMultiplier = _privateSaleMultiplier;
        SETTINGS.withdrawalSuspensionEndTime = 0;
        SETTINGS.withdrawalSuspensionStartTime = 0;
        privateSaleLockerAddress = _privateSaleLockerAddress;
    }

    receive() external payable {
       revert('No Direct Transfer');
    }

    // function getUserSPP(address _user) external view returns (uint256) {
    //     uint256 userTotalPP = 0;
    //     uint256 tierTotalPP = 0;

    //     for (uint256 i = 0; i < stakingTierAddresses.length; i++) {
    //         (uint256 _userTierPP, uint256 _tierPP) = IStakingTierContract(stakingTierAddresses[i]).getPoolPercentagesWithUser(_user);
    //         userTotalPP += _userTierPP;
    //         tierTotalPP += _tierPP;
    //     }

    //     for (uint256 i = 0; i < privateSaleUserLockerIds[_user].length; i++) {
    //         userTotalPP += _getLockedPrivateSaleTokens(privateSaleUserLockerIds[_user][i]) * SETTINGS.privateSaleMultiplier;
    //     }

    //     tierTotalPP += SETTINGS.privateSaleTotalPP;
    //     return FullMath.mulDiv(userTotalPP, SETTINGS.ppMultiplier, tierTotalPP);
    // }

    function depositEnabled() external view returns (bool) {
        return _depositEnabled();
    }

    function _depositEnabled() internal view returns (bool) {
        return block.timestamp > SETTINGS.startTimeForDeposit && block.timestamp < SETTINGS.endTimeForDeposit;
    }

    function updateTime(uint256 _startTimeForDeposit, uint256 _endTimeForDeposit) external onlyOwner {
        SETTINGS.startTimeForDeposit = _startTimeForDeposit;
        SETTINGS.endTimeForDeposit = _endTimeForDeposit;
    }

    function transferExtraTokens(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }

    // function setPrivateSaleLockerIds(uint256[] memory _privateSaleLockerIds, address[] memory _privateSaleLockerOwners) external onlyOwner {
    //     require(_privateSaleLockerIds.length == _privateSaleLockerOwners.length, "Length Not Matched");

    //     for (uint256 i = 0; i < _privateSaleLockerOwners.length; i++) {
    //         address owner = _privateSaleLockerOwners[i];
    //         delete privateSaleUserLockerIds[owner];
    //     }

    //     for (uint256 i = 0; i < _privateSaleLockerIds.length; i++) {
    //         address owner = _privateSaleLockerOwners[i];
    //         uint256 lockId = _privateSaleLockerIds[i];

    //         privateSaleUserLockerIds[owner].push(lockId);
    //     }

    //     privateSaleLockerIds = _privateSaleLockerIds;
    // }

    function updatePrivateSaleTotalPP(uint256 _privateSaleTotalPP) external onlyOwner {
        SETTINGS.privateSaleTotalPP = _privateSaleTotalPP;
    }

    // function getLockedPrivateSaleTokens(uint256 lockerId) external view returns (uint256) {
    //     return _getLockedPrivateSaleTokens(lockerId);
    // }

    // function _getLockedPrivateSaleTokens(uint256 lockerId) internal view returns (uint256) {
    //     ( , uint256 sharesDeposited, uint256 sharesWithdrawn ,,,,,) = tokenLocker.LOCKS(lockerId);
    //    return tokenLocker.convertSharesToTokens(SETTINGS.tokenAddress,sharesDeposited - sharesWithdrawn); 
    // }

    // function updatePrivateSaleTotalPPFromContract() external onlyOwner {
    //     uint256 privateSaleTotalPP = 0;
    //     for (uint256 i = 0; i < privateSaleLockerIds.length; i++) {
    //         privateSaleTotalPP += (_getLockedPrivateSaleTokens(privateSaleLockerIds[i]) * SETTINGS.privateSaleMultiplier);
    //     }
    //     SETTINGS.privateSaleTotalPP = privateSaleTotalPP;
    // }

    function isWithdrawlAllowed() internal view returns (bool) {
        return block.timestamp < SETTINGS.withdrawalSuspensionStartTime || block.timestamp > SETTINGS.withdrawalSuspensionEndTime;
    }

    function setWithdrawalSuspension(uint256 _withdrawalSuspensionStartTime, uint256 _withdrawalSuspensionEndTime) external onlyOwner {
        SETTINGS.withdrawalSuspensionStartTime = _withdrawalSuspensionStartTime;
        SETTINGS.withdrawalSuspensionEndTime = _withdrawalSuspensionEndTime;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Pausable is Ownable {

    uint public lastPauseTime;
    bool public paused;

    event PauseChanged(bool isPaused);

    constructor() {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner() != address(0), "Owner must be set");
        // Paused will be false, and lastPauseTime will be 0 upon initialisation
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = block.timestamp;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Sourced from https://gist.github.com/paulrberg/439ebe860cd2f9893852e2cab5655b65, credits to Paulrberg for porting to solidity v0.8
/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        unchecked {
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './StakingHelper.sol';

interface IMigrator {
    function migrate(uint256 lockId, address owner, uint256 amount, uint256 ipp, uint256 unlockTime, uint256 lockTime) external returns (bool);
}

contract BaseTierStakingContract is StakingHelper {

    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    uint256 public CONTRACT_VERSION = 1;
  
    struct TokenLock {
        uint256 lockId;
        address owner;
        uint256 amount;
        uint256 iPP; // individual pool percentage
        uint256 unlockTime;
        uint256 lockTime;
    }

    struct Config {
        uint8 tierId; // 0 based index
        uint8 multiplier; // in 10 to support single decimal such as 0.1 and 1.2
        uint8 emergencyWithdrawlFee; // in 1000 so for 2% fee it will be 20
        uint8 enableEarlyWithdrawal;
        uint8 enableRewards;
        uint256 unlockDuration; // epoch timestamp
        address depositor;  // Depositor contract who is allowed to stake
        address feeAddress; // Address to receive the fee
    }

    struct LockParams {
        address payable owner; // the user who can withdraw tokens once the lock expires.
        uint256 amount; // amount of tokens to lock
    }

    EnumerableSet.AddressSet private users; 
    EnumerableSet.AddressSet private allowedMigrators; // Address of the contract that can migrate the tokens
    uint256 public tierTotalParticipationPoints;
    uint256 public nonce = 1; // incremental lock nonce counter, this is the unique ID for the next lock
    uint256 public minimumDeposit = 1000 * (10 ** 18); // minimum divisibility per lock at time of locking
    IERC20 public token; // token

    Config public config;
    mapping(uint256 => TokenLock) public locks; // map lockId nonce to the lock
    mapping(address => uint256[]) public userLocks; // UserAddress => LockId
    
    IMigrator public migrator;

    event OnLock(uint256 lockId, address owner, uint256 amountInTokens, uint256 iPP);
    event OnLockUpdated(uint256 lockId, address owner, uint256 amountInTokens, uint256 tierId);
    event OnWithdraw(uint256 lockId, address owner, uint256 amountInTokens);
    event OnFeeCharged(uint256 lockId, address owner, uint256 amountInTokens);
    event OnMigrate(uint256 lockId, address owner, uint256 amount, uint256 ipp, uint256 unlockTime, uint256 lockTime);
  
    constructor(
        uint8 _tierId,
        uint8 _multiplier,
        uint8 _emergencyWithdrawlFee,
        uint8 _enableEarlyWithdrawal,
        uint256 _unlockDuration,
        uint8 _enableRewards,
        address _depositor,
        address _tokenAddress,
        address _feeAddress
    ) StakingHelper(
        0,
        0,
        0,
        0,
        0x0f2257997A3aF27C027377e4bdeed583F804cc83
    ) {
        token = IERC20(_tokenAddress);
        config.tierId = _tierId;
        config.multiplier = _multiplier;
        config.emergencyWithdrawlFee = _emergencyWithdrawlFee;
        config.unlockDuration = _unlockDuration;
        config.enableEarlyWithdrawal = _enableEarlyWithdrawal;
        config.depositor = _depositor;
        config.feeAddress = _feeAddress;
        config.enableRewards = _enableRewards;
    }  

    // /**
    // * @notice set the migrator contract which allows the lock to be migrated
    // */
    // function setMigrator(IMigrator _migrator) external onlyOwner {
    //     migrator = _migrator;
    // }  

    /**
    * @notice Creates one lock for the specified token
    * @param _owner the owner of the lock
    * @param _amount amount of the lock
    * owner: user or contract who can withdraw the tokens
    * amount: must be >= 100 units
    * Fails is amount < 100
    */
    function singleLock(address payable _owner, uint256 _amount) public {
        LockParams memory param = LockParams(_owner, _amount);
        LockParams[] memory params = new LockParams[](1);
        params[0] = param;
        _lock(params);
    }
  
    function _lock(LockParams[] memory _lockParams) internal nonReentrant {
        require(msg.sender == config.depositor, 'Only depositor can call this function');
        require(_lockParams.length > 0, 'NO PARAMS');

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _lockParams.length; i++) {
            require(_lockParams[i].owner != address(0), 'No ADDR');
            require(_lockParams[i].amount > 0, 'No AMT');
            totalAmount += _lockParams[i].amount;
        }

        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(address(msg.sender), address(this), totalAmount);
        uint256 amountIn = token.balanceOf(address(this)) - balanceBefore;
        require(amountIn == totalAmount, 'NOT ENOUGH TOKEN');
        for (uint256 i = 0; i < _lockParams.length; i++) {
            LockParams memory lockParam = _lockParams[i];
            require(lockParam.amount >= minimumDeposit, 'MIN DEPOSIT');
            TokenLock memory tokenLock;
            tokenLock.lockId = nonce;
            tokenLock.owner = lockParam.owner;
            users.add(lockParam.owner);
            tokenLock.amount = lockParam.amount;
            tokenLock.lockTime = block.timestamp;
            tokenLock.unlockTime = block.timestamp + config.unlockDuration;
            tokenLock.iPP = lockParam.amount * config.multiplier;
            // record the lock globally
            locks[nonce] = tokenLock;
            tierTotalParticipationPoints += tokenLock.iPP;
            userLocks[tokenLock.owner].push(tokenLock.lockId);
            nonce++;
            emit OnLock(tokenLock.lockId, tokenLock.owner, tokenLock.amount, tokenLock.iPP);
        }
    }

    /**
    * @notice Creates multiple locks
    * @param _lockParams an array of locks with format: [LockParams[owner, amount]]
    * owner: user or contract who can withdraw the tokens
    * amount: must be >= 1000 units
    * Fails is amount < 1000
    */    
    function lock(LockParams[] memory _lockParams) external {
        _lock(_lockParams);
    }

    /**
    * @notice stake a specified amount to owner
    * @param _owner staking owner
    * @param _amount amount of token to stake
    */
    function stake(address payable _owner, uint256 _amount) external nonReentrant notPaused {
        require(_depositEnabled(), "Deposit is not enabled");
        require(_owner != address(0), 'No ADDRESS');
        require(_amount > 0, 'Amount of token to stake must be greater than 0');

        singleLock(_owner, _amount);
    }
  
    /**
    * @notice withdraw a specified amount from a lock. _amount is the ideal amount to be withdrawn.
    * however, this amount might be slightly different in rebasing tokens due to the conversion to shares,
    * then back into an amount
    * @param _lockId the lockId of the lock to be withdrawn
    */
    function withdraw(uint256 _lockId, uint256 _index, uint256 _amount) external nonReentrant {
        require(isWithdrawlAllowed(), 'NOT ALLOWED');

        TokenLock storage userLock = locks[_lockId];
        require(userLock.unlockTime <= block.timestamp || config.enableEarlyWithdrawal == 1, 'Early withdrawal is disabled');
        require(userLocks[msg.sender].length > _index, 'Index OOB');
        require(userLocks[msg.sender][_index] == _lockId, 'lockId NOT MATCHED');
        require(userLock.owner == msg.sender, 'OWNER');

        uint256 balance = token.balanceOf(address(this));
        uint256 withdrawableAmount = locks[_lockId].amount;
        require(withdrawableAmount > 0, 'NO TOKENS');
        require(_amount <= withdrawableAmount, 'AMOUNT < WAMNT');
        require(_amount <= balance, 'NOT ENOUGH TOKENS');

        locks[_lockId].amount = withdrawableAmount - _amount;
        uint256 decreaseIPP = _amount * config.multiplier;
        tierTotalParticipationPoints -= decreaseIPP;
        locks[_lockId].iPP -= decreaseIPP;

        if (userLock.unlockTime > block.timestamp && config.emergencyWithdrawlFee > 0) {
            uint256 fee = FullMath.mulDiv(_amount, config.emergencyWithdrawlFee, 1000);
            token.safeTransfer(config.feeAddress, fee);
            _amount = _amount - fee;
            emit OnFeeCharged(_lockId, msg.sender, fee);
        }
        token.safeTransfer(msg.sender, _amount);
        emit OnWithdraw(_lockId, msg.sender, _amount);
    }

    function changeConfig(uint8 tierId, uint8 multiplier, uint8 emergencyWithdrawlFee, uint8 enableEarlyWithdrawal, uint256 unlockDuration, uint8 enableRewards, address depositor, address feeAddress) external onlyOwner returns (bool) {
        config.tierId = tierId;
        config.multiplier = multiplier;
        config.emergencyWithdrawlFee = emergencyWithdrawlFee;
        config.enableEarlyWithdrawal = enableEarlyWithdrawal;
        config.unlockDuration = unlockDuration;
        config.depositor = depositor;
        config.feeAddress = feeAddress;
        config.enableRewards = enableRewards;
        return true;
    }
  
    function setDepositor(address _depositor) external onlyOwner {
        config.depositor = _depositor;
    }

    function getPoolPercentagesWithUser(address _user) external view returns(uint256, uint256) {
        return _getPoolPercentagesWithUser(_user);
    }

    function _getPoolPercentagesWithUser(address _user) internal view returns(uint256, uint256) {
        uint256 userLockIPP = 0;
        for (uint256 i = 0; i < userLocks[_user].length; i++) {
            TokenLock storage userLock = locks[userLocks[_user][i]];
            userLockIPP += userLock.iPP;
        }
        return (userLockIPP, tierTotalParticipationPoints);
    }

    // /**
    // * @notice migrates to the next locker version, only callable by lock owners
    // */
    // function migrateToNewVersion(uint256 _lockId) external nonReentrant {
    //     require(address(migrator) != address(0), "NOT SET");
    //     TokenLock storage userLock = locks[_lockId];
    //     require(userLock.owner == msg.sender, 'OWNER');
    //     uint256 amount = userLock.amount;
    //     require(amount > 0, 'AMOUNT');

    //     uint256 balance = token.balanceOf(address(this));
    //     require(amount <= balance, 'NOT ENOUGH TOKENS');
    //     token.safeApprove(address(migrator), amount);
    //     migrator.migrate(userLock.lockId, userLock.owner, userLock.amount, userLock.iPP, userLock.unlockTime, userLock.lockTime);
    //     emit OnMigrate(userLock.lockId, userLock.owner, userLock.amount, userLock.iPP, userLock.unlockTime, userLock.lockTime);
    //     userLock.amount = 0;
    //     tierTotalParticipationPoints -= userLock.iPP;
    //     userLock.iPP = 0;
    // }

    // function migrate(uint256 lockId, address owner, uint256 amount, uint256 ipp, uint256 unlockTime, uint256 lockTime) override external returns (bool) {
    //     require(allowedMigrators.contains(msg.sender), "FORBIDDEN");
    //     require(lockId > 0, 'POSITIVE LOCKID');
    //     require(owner != address(0), 'ADDRESS');
    //     require(amount > 0, 'AMOUNT');
    //     require(unlockTime > 0, 'unlockTime');
    //     require(lockTime > 0, 'lockTime');

    //     uint256 balanceBefore = token.balanceOf(address(this));
    //     token.safeTransferFrom(address(msg.sender), address(this), amount);
    //     uint256 amountIn = token.balanceOf(address(this)) - balanceBefore;
    //     require(amountIn == amount, 'NOT ENOUGH TOKEN');
    //     require(amount >= minimumDeposit, 'MIN DEPOSIT');
    //     TokenLock memory tokenLock;
    //     tokenLock.lockId = nonce;
    //     tokenLock.owner = owner;
    //     users.add(owner);
    //     tokenLock.amount = amount;
    //     tokenLock.lockTime = lockTime;
    //     tokenLock.unlockTime = unlockTime;
    //     tokenLock.iPP = ipp;
    //     // record the lock globally
    //     locks[nonce] = tokenLock;
    //     tierTotalParticipationPoints += tokenLock.iPP;
    //     userLocks[tokenLock.owner].push(tokenLock.lockId);
    //     nonce++;
    //     emit OnLock(tokenLock.lockId, tokenLock.owner, tokenLock.amount, tokenLock.iPP);
    //     return true;
    // }

    function getLockedUsersLength() external view returns(uint256) {
        return users.length();
    }

    function getLockedUserAt(uint256 _index) external view returns(address) {
        return users.at(_index);
    }

    function getMigratorsLength() external view returns(uint256) {
        return allowedMigrators.length();
    }

    function getMigratorAt(uint256 _index) external view returns(address) {
        return allowedMigrators.at(_index);
    }

    function toggleMigrator(address _migrator, uint8 add) external onlyOwner {
        if (add == 1) {
            allowedMigrators.add(_migrator);
        } else { 
            allowedMigrators.remove(_migrator);
        }
    }

    function getUserlocksLength(address _user) external view returns(uint256) {
        return userLocks[_user].length;
    }

    function changeEarlyWithdrawl(uint8 _enableEarlyWithdrawal) external onlyOwner {
        config.enableEarlyWithdrawal = _enableEarlyWithdrawal;
    }

    function changeUnlockDuration(uint8 _unlockDuration) external onlyOwner {
        config.unlockDuration = _unlockDuration;
    }  
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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