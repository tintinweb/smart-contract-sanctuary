// SPDX-License-Identifier: MIT

/**
 * @title Locker of EnergyFi launchpad enviroment
 * @dev This contract manages locks of pancakeswap LP tokens. LP tokens can be locked for
 * a specific time, locks can be incremented, split up into multiple locks, relocked and
 * withdrawn by owner if the unlock date is met.
 */

pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/pancake/IPancakePair.sol";
import "../interfaces/pancake/IPancakeFactory.sol";
import "../interfaces/IERC20Burn.sol";
import "../interfaces/IMigrator.sol";
import "../interfaces/IPancakeLocker.sol";

import "./TransferHelper.sol";

contract PancakeLocker is IPancakeLocker, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    /*---------------------------------------------------------------------------------------------
     * -------------------------------------------Structs-------------------------------------------
     */

    // holding lock information for user
    struct UserInfo {
        EnumerableSet.AddressSet lockedTokens; // list of locked LP tokens by user
        mapping(address => uint256[]) locksForToken;
    }

    // holding information about a token lock
    struct TokenLock {
        uint256 lockDate; // unix timestamp of locking date
        uint256 amount; // current amount in the lock
        uint256 initialAmount; // total amount added initially on locking
        uint256 unlockDate; // unix timestamp for ealiest unlock
        uint256 lockID; // unique identifier of a token lcok
        address owner; // owner address of the locked token allowed for access control
    }

    // holding information about the fees for a lock
    struct FeeStruct {
        uint256 bnbFee; // bnb fee charged on non whitelisted locking
        IERC20Burn secondaryFeeToken; // fee token optional to bnb
        uint256 secondaryTokenFee; // realative fee on fee token in parts per 1000
        uint256 secondaryTokenDiscount; // discount on liquidity fee
        uint256 liquidityFee; // fee on LP tokens
        uint256 referralPercent; // relative fee for referral in parts per 1000
        IERC20Burn referralToken; // token referrer has to hold
        uint256 referralHold; // amount of referral token referrer has to hold
        uint256 referralDiscount; // discount on fees for providing valid referrer
    }

    mapping(address => UserInfo) private users; // user infos for each user
    mapping(address => TokenLock[]) public tokenLocks; // token lock info for each LP token

    EnumerableSet.AddressSet private feeWhitelist; // addresses for locking without fees
    EnumerableSet.AddressSet private lockedTokens; // addresses of locked LP tokens

    FeeStruct public fees; // holding all fee information

    address payable public devaddr; // receiving fees
    address public migrator; //migrates locks
    IPancakeFactory public immutable PANCAKE_FACTORY; // factory of the LP token

    /*---------------------------------------------------------------------------------------------
     * -------------------------------------------Events-------------------------------------------
     */
    event onDeposit(
        address indexed lpToken,
        address indexed user,
        uint256 amount,
        uint256 lockDate,
        uint256 unlockDate
    );
    event onWithdraw(address indexed lpToken, uint256 amount);

    /**
     * @dev sets initially contract dependend addresses and fee parameter
     * @param _pancakeFactory address of the pancake factory
     */
    constructor(address _pancakeFactory) public {
        require(_pancakeFactory != address(0), "ZERO ADDRESS");
        PANCAKE_FACTORY = IPancakeFactory(_pancakeFactory);
        devaddr = msg.sender;

        fees.referralPercent = 250; // 250/1000 => 25%
        fees.bnbFee = 1 ether;
        fees.secondaryTokenFee = 100 ether;
        fees.secondaryTokenDiscount = 200;
        fees.liquidityFee = 10;
        fees.referralHold = 10 ether;
        fees.referralDiscount = 100;
    }

    /**
     * @notice locks specific amount of LP tokens for a given period of time
     * @dev fees are calculated if caller is not whitelisted
     * @param _lpToken address of the LP token to be locked
     * @param _amount total amount of LP tokens to be locked
     * @param _unlockDate unix timestamp when withdrawer is allowed to unlock LP tokens
     * @param _referral address of referrer for token locking
     * @param _feeInBnb bool indicating if base token is BNB
     * @param _withdrawer address which is allowed to unlock lock LP tokens after unlock date
     */
    function lockLPToken(
        address _lpToken,
        uint256 _amount,
        uint256 _unlockDate,
        address payable _referral,
        bool _feeInBnb,
        address payable _withdrawer
    ) external payable override nonReentrant {
        require(_unlockDate < 10000000000, "TIMESTAMP INVALID");
        require(_amount > 0, "INSUFFICIENT");

        // get LP from pancake factory
        IPancakePair lpair = IPancakePair(address(_lpToken));
        address factoryPairAddress = PANCAKE_FACTORY.getPair(
            lpair.token0(),
            lpair.token1()
        );
        require(factoryPairAddress == address(_lpToken), "NOT CAKE");

        // transfer lock amount to pancake locker
        TransferHelper.safeTransferFrom(
            _lpToken,
            address(msg.sender),
            address(this),
            _amount
        );

        // check if referrer holds sufficient referral token
        if (
            _referral != address(0) && address(fees.referralToken) != address(0)
        ) {
            require(
                fees.referralToken.balanceOf(_referral) >= fees.referralHold,
                "INADEQUATE BALANCE"
            );
        }

        // caller not whitelisted - charge fees
        if (!feeWhitelist.contains(msg.sender)) {
            // charge fee with BNB token
            if (_feeInBnb) {
                uint256 bnbFee = fees.bnbFee;
                // calculate discounted fee for providing valid referrer
                if (_referral != address(0)) {
                    bnbFee = bnbFee.mul(1000 - fees.referralDiscount).div(1000);
                }
                require(msg.value == bnbFee, "FEE NOT MET");

                // calculate referral fee
                uint256 devFee = bnbFee;
                if (bnbFee != 0 && _referral != address(0)) {
                    uint256 referralFee = devFee.mul(fees.referralPercent).div(
                        1000
                    );
                    _referral.transfer(referralFee);
                    devFee = devFee.sub(referralFee);
                }
                // transfer referral fee
                devaddr.transfer(devFee);
            } else {
                // burn fee in non BNB token
                uint256 burnFee = fees.secondaryTokenFee;
                // calculate discounted fee for providing valid referrer
                if (_referral != address(0)) {
                    burnFee = burnFee.mul(1000 - fees.referralDiscount).div(
                        1000
                    );
                }
                TransferHelper.safeTransferFrom(
                    address(fees.secondaryFeeToken),
                    address(msg.sender),
                    address(this),
                    burnFee
                );
                // calculate and transfer referral fee
                if (fees.referralPercent != 0 && _referral != address(0)) {
                    uint256 referralFee = burnFee.mul(fees.referralPercent).div(
                        1000
                    );
                    TransferHelper.safeApprove(
                        address(fees.secondaryFeeToken),
                        _referral,
                        referralFee
                    );
                    TransferHelper.safeTransfer(
                        address(fees.secondaryFeeToken),
                        _referral,
                        referralFee
                    );
                    burnFee = burnFee.sub(referralFee);
                }
                // burn remaining fee tokens
                fees.secondaryFeeToken.burn(burnFee);
            }
        } else if (msg.value > 0) {
            // send back BNB for whitelisted callers
            msg.sender.transfer(msg.value);
        }

        // calculate liquidity fee and send to dev address
        uint256 liquidityFee = _amount.mul(fees.liquidityFee).div(1000);
        if (!_feeInBnb && !feeWhitelist.contains(msg.sender)) {
            liquidityFee = liquidityFee
                .mul(1000 - fees.secondaryTokenDiscount)
                .div(1000);
        }
        TransferHelper.safeTransfer(_lpToken, devaddr, liquidityFee);
        uint256 amountLocked = _amount.sub(liquidityFee);

        // set variables for token lock
        TokenLock memory token_lock;
        token_lock.lockDate = block.timestamp;
        token_lock.amount = amountLocked;
        token_lock.initialAmount = amountLocked;
        token_lock.unlockDate = _unlockDate;
        token_lock.lockID = tokenLocks[_lpToken].length;
        token_lock.owner = _withdrawer;

        // update LP token with token lock
        tokenLocks[_lpToken].push(token_lock);
        lockedTokens.add(_lpToken);

        // update user with locked LP token
        UserInfo storage user = users[_withdrawer];
        user.lockedTokens.add(_lpToken);
        uint256[] storage user_locks = user.locksForToken[_lpToken];
        user_locks.push(token_lock.lockID);

        emit onDeposit(
            _lpToken,
            msg.sender,
            token_lock.amount,
            token_lock.lockDate,
            token_lock.unlockDate
        );
    }

    /**
     * @notice relocks the locked LP token by lock owner. A liquidity fee is calculated on
     * the locking amount. The new locking amount is old locking amount minus liquidity fee.
     * @param _lpToken address of the LP token to be relocked
     * @param _index position of the lock in the user locks for specific LP token set
     * @param _lockID unique identifier of the token lock
     * @param _unlockDate unix timestamp when withdrawer is allowed to unlock LP tokens
     */
    function relock(
        address _lpToken,
        uint256 _index,
        uint256 _lockID,
        uint256 _unlockDate
    ) external nonReentrant {
        require(_unlockDate < 10000000000, "TIMESTAMP INVALID");

        // check if lock is valid and sender is owner
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage tokenLock = tokenLocks[_lpToken][lockID];
        require(
            lockID == _lockID && tokenLock.owner == msg.sender,
            "LOCK MISMATCH"
        );
        // check if unlock timestamp is met to update LP tokens lock
        require(tokenLock.unlockDate < _unlockDate, "UNLOCK BEFORE");

        // calculate liquidity fee and new locking amount
        uint256 liquidityFee = tokenLock.amount.mul(fees.liquidityFee).div(
            1000
        );
        uint256 amountLocked = tokenLock.amount.sub(liquidityFee);

        // update lock parameter with new locking amount and unlock date
        tokenLock.amount = amountLocked;
        tokenLock.unlockDate = _unlockDate;

        // transfer liquidity fee to developer address
        TransferHelper.safeTransfer(_lpToken, devaddr, liquidityFee);
    }

    /**
     * @notice withdraws the desired amount of locked token by lock owner. Unlock timestamp
     * has to be met.
     * @param _lpToken address of the LP token to be withdrawn
     * @param _index position of the lock in the user locks for specific LP token set
     * @param _lockID unique identifier of the token lock
     * @param _amount amount to be withdrawn from the lock
     */
    function withdraw(
        address _lpToken,
        uint256 _index,
        uint256 _lockID,
        uint256 _amount
    ) external nonReentrant {
        require(_amount > 0, "ZERO WITHDRAWL");

        // check if lock is valid and sender is owner
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage userLock = tokenLocks[_lpToken][lockID];
        require(
            lockID == _lockID && userLock.owner == msg.sender,
            "LOCK MISMATCH"
        );
        // check if unlock timestamp is met to update LP tokens lock
        require(userLock.unlockDate < block.timestamp, "NOT YET");
        userLock.amount = userLock.amount.sub(_amount);

        // remove lock if total amount is withdrawn
        if (userLock.amount == 0) {
            uint256[] storage userLocks = users[msg.sender].locksForToken[
                _lpToken
            ];
            userLocks[_index] = userLocks[userLocks.length - 1];
            userLocks.pop();
            // remove users locked tokens if user has no other locks for same LP left
            if (userLocks.length == 0) {
                users[msg.sender].lockedTokens.remove(_lpToken);
            }
        }

        // transfer desired unlocked amount to caller (lock owner)
        TransferHelper.safeTransfer(_lpToken, msg.sender, _amount);
        emit onWithdraw(_lpToken, _amount);
    }

    /**
     * @notice increments the locked LP tokens amount by lock owner. A liquidity fee is
     * charged on sending additional tokens to the locking contract.
     * @param _lpToken address of the LP token to increment lock
     * @param _index position of the lock in the user locks for specific LP token set
     * @param _lockID unique identifier of the token lock
     * @param _amount additional LP amount to be locked
     */
    function incrementLock(
        address _lpToken,
        uint256 _index,
        uint256 _lockID,
        uint256 _amount
    ) external nonReentrant {
        require(_amount > 0, "ZERO AMOUNT");

        // check if lock is valid and sender is owner
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage userLock = tokenLocks[_lpToken][lockID];
        require(
            lockID == _lockID && userLock.owner == msg.sender,
            "LOCK MISMATCH"
        );

        // transfer desired additional LP lock amount
        TransferHelper.safeTransferFrom(
            _lpToken,
            address(msg.sender),
            address(this),
            _amount
        );

        // calculate and transfer liquidity fee to developer address
        uint256 liquidityFee = _amount.mul(fees.liquidityFee).div(1000);
        TransferHelper.safeTransfer(_lpToken, devaddr, liquidityFee);

        // increment amount in token lock
        uint256 amountLocked = _amount.sub(liquidityFee);
        userLock.amount = userLock.amount.add(amountLocked);

        emit onDeposit(
            _lpToken,
            msg.sender,
            amountLocked,
            userLock.lockDate,
            userLock.unlockDate
        );
    }

    /**
     * @notice splits up a specific token lock and creates an other new token lock with
     * the given amount. The existing token lock is reduced by the equivalent amount.
     * @dev a fee in BNB (bnbFee) is required to be sent by calling to create a new lock
     * @param _lpToken address of the LP token to be split up
     * @param _index position of the lock in the user locks for specific LP token set
     * @param _lockID unique identifier of the token lock to be split up
     * @param _amount LP amount to create a new lock with
     */
    function splitLock(
        address _lpToken,
        uint256 _index,
        uint256 _lockID,
        uint256 _amount
    ) external payable nonReentrant {
        require(_amount > 0, "ZERO AMOUNT");

        // check if lock is valid and sender is owner
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage userLock = tokenLocks[_lpToken][lockID];
        require(
            lockID == _lockID && userLock.owner == msg.sender,
            "LOCK MISMATCH"
        );

        // trasnfer BNB as fee to developer address
        require(msg.value == fees.bnbFee, "FEE NOT MET");
        devaddr.transfer(fees.bnbFee);

        // reduce existing lock amount with given amount
        userLock.amount = userLock.amount.sub(_amount);

        // create new lock with given amount
        TokenLock memory token_lock;
        token_lock.lockDate = userLock.lockDate;
        token_lock.amount = _amount;
        token_lock.initialAmount = _amount;
        token_lock.unlockDate = userLock.unlockDate;
        token_lock.lockID = tokenLocks[_lpToken].length;
        token_lock.owner = msg.sender;
        tokenLocks[_lpToken].push(token_lock);

        // update users locks
        UserInfo storage user = users[msg.sender];
        uint256[] storage user_locks = user.locksForToken[_lpToken];
        user_locks.push(token_lock.lockID);
    }

    /**
     * @notice transfers the lock owner ship to a new owner by the current owner
     * @param _lpToken address of the LP token to transfer the ownership of the lock for
     * @param _index position of the lock in the user locks for specific LP token set
     * @param _lockID unique identifier of the token lock to be split up
     * @param _newOwner address of the new lock owner
     */
    function transferLockOwnership(
        address _lpToken,
        uint256 _index,
        uint256 _lockID,
        address payable _newOwner
    ) external {
        require(
            msg.sender != _newOwner && msg.sender != address(0),
            "INVALID ADDRESS"
        );
        // check if lock is valid and sender is owner
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage transferredLock = tokenLocks[_lpToken][lockID];
        require(
            lockID == _lockID && transferredLock.owner == msg.sender,
            "LOCK MISMATCH"
        );

        // add lock information to the new owner
        UserInfo storage user = users[_newOwner];
        user.lockedTokens.add(_lpToken);
        uint256[] storage newOwnerLocks = user.locksForToken[_lpToken];
        newOwnerLocks.push(transferredLock.lockID);

        // remove lock information from old owner
        uint256[] storage oldOwnerLocks = users[msg.sender].locksForToken[
            _lpToken
        ];
        oldOwnerLocks[_index] = oldOwnerLocks[oldOwnerLocks.length - 1];
        oldOwnerLocks.pop();
        if (oldOwnerLocks.length == 0) {
            users[msg.sender].lockedTokens.remove(_lpToken);
        }
        transferredLock.owner = _newOwner;
    }

    /**
     * @notice migrates a existing lock to an other contract with help of migrator
     * @param _lpToken address of the LP token to migrate the lock for
     * @param _index position of the lock in the user locks for specific LP token set
     * @param _lockID unique identifier of the token lock to be split up
     * @param _amount amount of locked LP token to be migrated
     */
    function migrate(
        address _lpToken,
        uint256 _index,
        uint256 _lockID,
        uint256 _amount
    ) external nonReentrant {
        require(migrator != address(0), "NOT SET");
        require(_amount > 0, "ZERO MIGRATION");

        // check if lock is valid and sender is owner
        uint256 lockID = users[msg.sender].locksForToken[_lpToken][_index];
        TokenLock storage userLock = tokenLocks[_lpToken][lockID];
        require(
            lockID == _lockID && userLock.owner == msg.sender,
            "LOCK MISMATCH"
        );

        // decreases lock amount
        userLock.amount = userLock.amount.sub(_amount);

        // removes lock if total left amount is migrated
        if (userLock.amount == 0) {
            uint256[] storage userLocks = users[msg.sender].locksForToken[
                _lpToken
            ];
            userLocks[_index] = userLocks[userLocks.length - 1];
            userLocks.pop();
            // remove lock from user if no lock for same LP is left
            if (userLocks.length == 0) {
                users[msg.sender].lockedTokens.remove(_lpToken);
            }
        }

        // migrate token with migrator
        TransferHelper.safeApprove(_lpToken, migrator, _amount);
        IMigrator(migrator).migrate(
            _lpToken,
            _amount,
            userLock.unlockDate,
            msg.sender
        );
    }

    /*---------------------------------------------------------------------------------------------
     * --------------------------------------Setter functions--------------------------------------
     */

    /**
     * @notice set the dev address for receiving fees by owner
     * @param _devaddr fee receiver address
     */
    function setDev(address payable _devaddr) external onlyOwner {
        devaddr = _devaddr;
    }

    /**
     * @notice set the fees and fee tokens by owner
     * @param _referralPercent relative referral fee in parts per 1000
     * @param _referralDiscount relative discount fee in parts per 1000
     * @param _bnbFee BNB fee charged on lock creation for BNB base tokens
     * @param _secondaryTokenFee fee charged on locking non BNB base token
     * @param _secondaryTokenDiscount discount on liquidity fee
     * @param _liquidityFee fee on LP tokens
     */
    function setFees(
        uint256 _referralPercent,
        uint256 _referralDiscount,
        uint256 _bnbFee,
        uint256 _secondaryTokenFee,
        uint256 _secondaryTokenDiscount,
        uint256 _liquidityFee
    ) external onlyOwner {
        fees.referralPercent = _referralPercent;
        fees.referralDiscount = _referralDiscount;
        fees.bnbFee = _bnbFee;
        fees.secondaryTokenFee = _secondaryTokenFee;
        fees.secondaryTokenDiscount = _secondaryTokenDiscount;
        fees.liquidityFee = _liquidityFee;
    }

    /**
     * @notice set the referral token and amount to hold by a referrer
     * @param _referralToken address of burnable ERC20 token
     * @param _hold amount of referral token a referrer has to hold
     */
    function setReferralTokenAndHold(IERC20Burn _referralToken, uint256 _hold)
        external
        onlyOwner
    {
        fees.referralToken = _referralToken;
        fees.referralHold = _hold;
    }

    /**
     * @notice set secondary fee token as option to bnb as fee by owner
     * @param _secondaryFeeToken address of burnable ERC20 token
     */
    function setSecondaryFeeToken(address _secondaryFeeToken)
        external
        onlyOwner
    {
        fees.secondaryFeeToken = IERC20Burn(_secondaryFeeToken);
    }

    /**
     * @notice set migrator by owner
     * @param _migrator address of the new migrator contract
     */
    function setMigrator(address _migrator) external onlyOwner {
        migrator = _migrator;
    }

    /**
     * @notice whitelists a user by owner
     * @param _user address of the user to whitelist
     * @param _add bool if the given user should be added to (=true) or removed from (=false) whitelist
     */
    function whitelistFeeAccount(address _user, bool _add) external onlyOwner {
        if (_add) {
            feeWhitelist.add(_user);
        } else {
            feeWhitelist.remove(_user);
        }
    }

    /*---------------------------------------------------------------------------------------------
     * --------------------------------------Getter functions--------------------------------------
     */

    /**
     * @notice returns address of a LP token at a specific index of the set
     */
    function getLockedTokenAtIndex(uint256 _index)
        external
        view
        returns (address)
    {
        return lockedTokens.at(_index);
    }

    /**
     * @notice returns the total number of locks for given token
     * @param _lpToken address of token to get amount of locks for
     */
    function getNumLocksForToken(address _lpToken)
        external
        view
        returns (uint256)
    {
        return tokenLocks[_lpToken].length;
    }

    /**
     * @notice returns the total number of different locked lp tokens
     */
    function getNumLockedTokens() external view returns (uint256) {
        return lockedTokens.length();
    }

    /**
     * @notice returns the LP token address at a given index of the users set
     * @param _user address of the user
     * @param _index position of LP token in users lockedTokens set
     */
    function getUserLockedTokenAtIndex(address _user, uint256 _index)
        external
        view
        returns (address)
    {
        UserInfo storage user = users[_user];
        return user.lockedTokens.at(_index);
    }

    /**
     * @notice returns the token lock of a given position in the users lp token lock set
     * @param _user address of the user
     * @param _lpToken address of LP token
     * @param _index position of the token lock in the users token lock set for specific LP
     */
    function getUserLockForTokenAtIndex(
        address _user,
        address _lpToken,
        uint256 _index
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address
        )
    {
        uint256 lockID = users[_user].locksForToken[_lpToken][_index];
        TokenLock storage tokenLock = tokenLocks[_lpToken][lockID];
        return (
            tokenLock.lockDate,
            tokenLock.amount,
            tokenLock.initialAmount,
            tokenLock.unlockDate,
            tokenLock.lockID,
            tokenLock.owner
        );
    }

    /**
     * @notice returns the amount of different locked LP tokens for a given user
     * @param _user address of user to be checked
     */
    function getUserNumLockedTokens(address _user)
        external
        view
        returns (uint256)
    {
        UserInfo storage user = users[_user];
        return user.lockedTokens.length();
    }

    /**
     * @notice returns the amount of users locks for a specific LP token
     * @param _user address of the user
     * @param _lpToken address of LP token
     */
    function getUserNumLocksForToken(address _user, address _lpToken)
        external
        view
        returns (uint256)
    {
        UserInfo storage user = users[_user];
        return user.locksForToken[_lpToken].length;
    }

    /**
     * @notice returns if the given user is whitelisted
     * @param _user users address to be checked
     */
    function getUserWhitelistStatus(address _user)
        external
        view
        returns (bool)
    {
        return feeWhitelist.contains(_user);
    }

    /**
     * @notice returns the address of the user at a given index of the whitelist set
     * @param _index position of the user in the whitelist
     */
    function getWhitelistedUserAtIndex(uint256 _index)
        external
        view
        returns (address)
    {
        return feeWhitelist.at(_index);
    }

    /**
     * @notice returns the total amout of whitelisted users
     */
    function getWhitelistedUsersLength() external view returns (uint256) {
        return feeWhitelist.length();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 *@title Interface of Pancake pair
 *@notice This is an interface of the PancakeSwap pair
 *@dev A parital interface of the pancake pair to get token and factory addresses. The original code can be found on
 *https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/IPancakePair.sol
 */
interface IPancakePair {
    /**
     *@notice Returns the address of the pairs pancake factory
     *@return address of the related pancake factory
     */
    function factory() external view returns (address);

    /**
     *@notice Returns the address of the first token of the pair
     *@dev The order of the tokens may switch on pair creation. TokenA on creation has not to be token0
     *inside the pair contract.
     *@return address of the first token of the pair (token0)
     */
    function token0() external view returns (address);

    /**
     *@notice Returns the address of the second token of the pair
     *@dev The order of the tokens may switch on pair creation. TokenB on creation has not to be token1
     *inside the pair contract.
     *@return address of the second token of the pair (token1)
     */
    function token1() external view returns (address);

    /**
     *@notice Mints an amount of token to the given address
     *@dev This low-level function should be called from a contract which performs important safety checks
     *@param to address to mint the tokens to
     *@return the minted liquidity amount of tokens
     */
    function mint(address to) external returns (uint256);

    /**
     *@dev Returns the amount of tokens owned by `owner`.
     *@param owner the address off the account owning tokens
     */
    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 *@title Interface of Pancake factory
 *@notice This is an interface of the PancakeSwap factory
 *@dev A parital interface of the pancake factory. The original code can be found on
 *https://github.com/pancakeswap/pancake-swap-core/blob/master/contracts/interfaces/IPancakeFactory.sol
 */
interface IPancakeFactory {
    /**
     *@notice Creates a new pair of two tokens known as liquidity pool
     *@param tokenA The first token of the pair
     *@param tokenB The second token of the pair
     *@return pair address of the created pair
     */
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    /**
     *@notice Returns the pair address of two given tokens
     *@param tokenA The first token of the pair
     *@param tokenB The second token of the pair
     *@return pair address of the created pair
     */
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

// SPDX-License-Identifier: MIT

/**
 * @title Locker Interface of EnergyFi launchpad enviroment
 * @dev This Interface holds a function to lock LP token with the PancakeLocker contract.
 * This function is called from LaunchpadLockForwarder to lock LP tokens.
 */
pragma solidity 0.6.12;

interface IPancakeLocker {
    /**
     * @notice locks specific amount of LP tokens for a given period of time
     * @dev fees are calculated if caller is not whitelisted
     * @param _lpToken address of the LP token to be locked
     * @param _amount total amount of LP tokens to be locked
     * @param _unlockDate unix timestamp when withdrawer is allowed to unlock LP tokens
     * @param _referral address of referrer for token locking
     * @param _feeInBnb bool indicating if base token is BNB
     * @param _withdrawer address which is allowed to unlock lock LP tokens after unlock date
     */
    function lockLPToken(
        address _lpToken,
        uint256 _amount,
        uint256 _unlockDate,
        address payable _referral,
        bool _feeInBnb,
        address payable _withdrawer
    ) external payable;
}

// SPDX-License-Identifier: MIT

/**
 * @title Migrator Interface of the EnergyFi launchpad enviroment
 * @dev This interface describes the Migrator which is responsible for migrating locks.
 * It is called from the pancakeLocker contract to migrate a lock to an other contract.
 */

pragma solidity 0.6.12;

interface IMigrator {
    /**
     * @notice migrates an existing lock
     * @dev is called from PancakeLocker contract
     * @param lpToken address of the LP token to be migrated
     * @param amount total amount to be migrated
     * @param unlockDate unix timestamp of the date to unlock locked LP tokens
     * @param owner address of the lock owner
     */
    function migrate(
        address lpToken,
        uint256 amount,
        uint256 unlockDate,
        address owner
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 *@title Interface of a burnable ERC20 token
 *@dev This interface describes a burnable ERC20 token providing a burn function.
 */
interface IERC20Burn {
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     *@param owner account address owning the tokens
     *@param spender account address allowed by owner to spend the tokens
     */
    function allowance(address owner, address spender)
        external
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
     *@param spender account address allowed by owner to spend the tokens
     *@param amount number of tokens allowed spender to spend
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     *@dev Destroys `amount` tokens from the caller.
     *@param _amount the number of tokens to be destroyed
     */
    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

/**
 * @title TransferHelper of EnergyFi launchpad enviroment
 * @dev This library holds function to transfer tokens safely. It allows safe transfer
 * for BNB as well as ERC20 tokens from a sender to a receiver. The ERC20 token functions
 * are used with low level call function.
 */

pragma solidity 0.6.12;

library TransferHelper {
    /**
     * @notice calls the aprove function of a given token in a safe way
     * @dev uses low level call and reverts on fail
     * @param token address of the base token to be transferred
     * @param to address of token spender (allowed to call transferFrom)
     * @param value amount of tokens to transfer
     */
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    /**
     * @notice calls the transfer function of a given token in a safe way
     * @dev uses low level call and reverts on fail
     * @param token address of the base token to be transferred
     * @param to address of token receiver
     * @param value amount of tokens to transfer
     */
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    /**
     * @notice calls the transferFrom function of a given token in a safe way
     * @dev transfers needs to be approved first. uses low level call and reverts on fail
     * @param token address of the base token to be transferred
     * @param from address of token sender
     * @param to address of token receiver
     * @param value amount of tokens to transfer
     */
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    /**
     * @notice calls the transfer function of a given token in a safe way or transfers BNB
     * if base token is not a ERC20 token
     * @dev uses low level call and reverts on fail
     * @param token address of the base token to be transferred
     * @param to address of the token receiver
     * @param value amount of tokens to transfer
     * @param isERC20 bool to indicate if the base token in BNB (=false) or ERC20 token (=true)
     */
    function safeTransferBaseToken(
        address token,
        address payable to,
        uint256 value,
        bool isERC20
    ) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(
                abi.encodeWithSelector(0xa9059cbb, to, value)
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "TransferHelper: TRANSFER_FAILED"
            );
        }
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

pragma solidity >=0.6.0 <0.8.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
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