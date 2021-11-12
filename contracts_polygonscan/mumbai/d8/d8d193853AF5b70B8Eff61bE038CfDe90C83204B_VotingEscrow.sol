/**
 *Submitted for verification at polygonscan.com on 2021-11-11
*/

// SPDX-License-Identifier: MIT
// File: contracts/utils/SmartWalletWhitelist.sol


pragma solidity ^0.8.0;

/**
 * @dev Interface for checking whether address belongs to a whitelisted type of a smart wallet.
 * When new types are added - the whole contract is changed
 * The check() method is modifying to be able to use caching
 * for individual wallet addresses
*/
interface SmartWalletChecker {
    function check(address) external view returns (bool);
}

contract SmartWalletWhitelist {
    address public admin;
    address public checker;

    mapping(address => bool) public wallets;
    
    event ApproveWallet(address);
    event RevokeWallet(address);

    event CheckerChanged(address oldChecker, address newChecker);
    
    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    function setChecker(address _checker) external onlyAdmin {
        address currentChecker = checker;
        require(_checker == address(0), "Can't set zero address");
        emit CheckerChanged(currentChecker, checker);
        checker = _checker;
    }
    
    function approveWallet(address _wallet) external onlyAdmin {
        require(_wallet != address(0), "Can't approve zero address");
        wallets[_wallet] = true;
        emit ApproveWallet(_wallet);
    }

    function revokeWallet(address _wallet) external onlyAdmin {
        require(_wallet != address(0), "Can't revoke zero address");
        wallets[_wallet] = false;
        emit RevokeWallet(_wallet);
    }
    
    function check(address _wallet) external view returns (bool) {
        if (wallets[_wallet]) {
            return true;
        } else if (checker != address(0)) {
            return SmartWalletChecker(checker).check(_wallet);
        }
        return false;
    }
}
// File: contracts/Governance/IAMPT.sol


pragma solidity ^0.8.0;

interface IAMPT {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: contracts/Governance/VotingEscrow.sol


pragma solidity 0.8.4;
/*
# Voting escrow to have time-weighted votes
# Votes have a weight depending on time, so that users are committed
# to the future of (whatever they are voting for).
# The weight in this implementation is linear, and lock cannot be more than maxtime:
# w ^
# 1 +        /
#   |      /
#   |    /
#   |  /
#   |/
# 0 +--------+------> time
#       maxtime (4 years?)
*/



contract VotingEscrow {
    struct Point {
        int256 bias;
        int256 slope;
        uint256 ts;
        uint256 block;
    }

    struct Balance {
        uint256 amount;
        uint256 end;
    }

    enum Action {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME
    }

    /// @notice EIP-20 token name for this token
    string private _name;

    /// @notice EIP-20 token symbol for this token
    string private _symbol;

    bool private _entered;

    address public admin;
    IAMPT public amptToken;
    SmartWalletChecker public smartWalletChecker;

    mapping(address => Balance) private _lockedBalances;
    mapping(address => Balance) private _operationBalances;
    uint256 private _totalSupply;

    uint256 public epoch;
    mapping(uint256 => Point) public pointHistory;

    /// @dev A record of each account's delegate
    mapping (address => address) public delegates;

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint256) public nonces;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    uint256 internal constant WEEK = 604800; // 7 * 24 * 3600;
    uint256 internal constant MAXCAP = 126144000; // 4 * 365 * 24 * 3600;
    
    mapping(address => mapping(uint256 => Point)) public userPointHistory;
    mapping(address => uint256) public userPointEpoch;
    mapping(uint256 => int256) public slopeChanges;

    event Deposited(address indexed provider, uint256 value, uint256 indexed lockTime, uint256 actionType);
    event Withdrawn(address indexed provider, uint256 value);

    /// @notice An event that's emitted when an account changes their delegate
    event DelegateChanged(address indexed delegator, address indexed toDelegate);

    /// @notice An event that's emitted when an smart wallet Checker is changed
    event SmartWalletCheckedChanged(address oldChecked, address newChecker);

     /**
     * @notice Contract constructor
     * @param amptToken_ `AMPT` token address
     * @param smartWalletChecker_ SmartWalletChecker contract address
     * @param name_ Token name
     * @param symbol_ Token symbol
    */
    constructor(IAMPT amptToken_, SmartWalletChecker smartWalletChecker_, string memory name_, string memory symbol_) {
        amptToken = amptToken_;
        _name = name_;
        _symbol = symbol_;
        
        admin = msg.sender;

        smartWalletChecker = smartWalletChecker_;

        pointHistory[0].block = getBlockNumber();
        pointHistory[0].ts = getBlockTimestamp();

        _entered = false;
    }

    modifier onlyAllowed(address addr) {
        if (addr != tx.origin) {
            require(smartWalletChecker.check(addr), "Smart contract depositors not allowed");
        }
        _;
    }

    modifier nonReentrant() {
        require(!_entered, "reentrant call");
        _entered = true;
        _;
        _entered = false;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external pure returns (uint8) {
        return 18;
    }
    
    /**
     * @dev Returns the amount of locked tokens in existence.
    */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Calculate total voting power
     * @return Total voting power
    */
    function votePower() external view returns (uint256) {
        return _supplyAt(getBlockTimestamp());
    }

    /**
     * @notice Calculate total voting power at some point in the past
     * @param block_ Block to calculate the total voting power at
     * @return Total voting power ar `block`
    */
    function votePowerAt(uint256 block_) external view returns (uint256) {
        uint256 currentTimestamp = getBlockTimestamp();
        uint256 currentBlock = getBlockNumber();

        require(currentBlock >= block_, "Block must be in the past");
        
        uint256 _targetEpoch = findBlockEpoch(block_, epoch);
        Point memory point = pointHistory[_targetEpoch];
        uint256 dt = 0;

        if (epoch > _targetEpoch) {
            Point memory nextPoint = pointHistory[_targetEpoch + 1];
            if (point.block != nextPoint.block) {
                dt = (block_ - point.block) * (nextPoint.ts - point.ts) / (nextPoint.block - point.block);
            }
        } else if (point.block != currentBlock) {
            dt = (block_ - point.block) * (currentTimestamp - point.ts) / (currentBlock - point.block);
        }

        return _supplyAt(point.ts + dt);
    }

    /**
     * @notice Calculate total voting power at some point in the past
     * @param timestamp Time to calculate the total voting power at
     * @return Total voting power at that time
    */
    function _supplyAt(uint256 timestamp) internal view returns (uint256) {
        Point memory point = pointHistory[epoch];
        uint256 timeIndex = point.ts * WEEK / WEEK;

        for(int i=0; i <= 255; i++) {
            timeIndex += WEEK;
            int256 dSlope = 0;

            if (timeIndex > timestamp) {
                timeIndex = timestamp;
            } else {
                dSlope = slopeChanges[timeIndex];
            }

            point.bias -= point.slope * int256(timeIndex - point.ts);
            if (timeIndex == timestamp) {
                break;
            }
            point.slope += dSlope;
            point.ts = timeIndex;
        }

        if (point.bias < 0) {
            point.bias = 0;
        }
        return uint256(point.bias);
    }

        /**
     * @notice Binary search to estimate timestamp for block number
     * @param block_ Block to find
     * @param epoch_ Don't go beyond this epoch
     * @return Approximate timestamp for block
    */
    function findBlockEpoch(uint256 block_, uint256 epoch_) internal view returns (uint256)  {
        uint256 _min = 0;
        uint256 _max = epoch_;
        for(int i=0; i <= 128; i++) {
            if (_min >= _max) break;

            uint256 _mid = (_min + _max + 1) / 2;

            if (pointHistory[_mid].block <= block_) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    /**
     * @notice Record global data to checkpoint
    */
    function checkpoint() external {
        _checkpoint(address(0), Balance(0,0), Balance(0,0));
    }

    /**
     * @notice Get the current voting power for `msg.sender`
     * @param addr User wallet address
     * @return User voting power
    */
    function balanceOf(address addr) external view returns (uint256) {
        uint256 _epoch = userPointEpoch[addr];
        uint256 currentTimestamp = getBlockTimestamp();

        if (_epoch == 0) {
            return 0;
        } else {
            Point memory lastPoint = userPointHistory[addr][_epoch];
            lastPoint.bias -= lastPoint.slope * int256(currentTimestamp - lastPoint.ts);
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            return uint256(lastPoint.bias);
        }
    }

    /**
     * @dev Returns the amount of tokens owner by `addr`.
    */
    function locked(address addr) external view returns (Balance memory) {
        return _lockedBalances[addr];
    }

    /**
     * @dev Returns the amount of tokens owner by `addr` used for calculating vote power.
    */
    function operationLocked(address addr) external view returns (Balance memory) {
        return _operationBalances[addr];
    }

    function changeSmartWalletChecker(SmartWalletChecker newSmartWalletChecker) external {
        SmartWalletChecker currentWalletChecker = smartWalletChecker;
        require(msg.sender == admin, "Only admin can change smart wallet checker");
        require(newSmartWalletChecker != currentWalletChecker, "New smart wallet checker is the same as the old one");
        smartWalletChecker = newSmartWalletChecker;
        emit SmartWalletCheckedChanged(address(currentWalletChecker), address(newSmartWalletChecker));
    }

    /**
     * @notice Deposit `value` tokens for `msg.sender` and lock until `unlockTime`
     * @param value Amount to deposit
     * @param unlockTime Epoch time when tokens unlock, rounded down to whole weeks
    */
    function createLock(uint256 value, uint256 unlockTime) external nonReentrant onlyAllowed(msg.sender)  {
        require(value > 0, "Value must be greater than 0");

        Balance storage balance = _lockedBalances[msg.sender];
        require(balance.amount == 0, "Withdraw old tokens first");

        uint currentTimestamp = getBlockTimestamp();
        require(unlockTime > currentTimestamp, "Unlock time must be in the future");
        require(currentTimestamp + MAXCAP >= unlockTime, "Voting lock can be 4 years max");

        _depositFor(msg.sender, value, unlockTime, uint256(Action.CREATE_LOCK_TYPE));
    }

    /**
     * @notice Deposit `value` additional tokens for `msg.sender` without modifying the unlock time
     * @param value Amount of tokens to deposit and add to the lock
    */
    function increaseLockAmount(uint256 value) external nonReentrant onlyAllowed(msg.sender) {
        require(value > 0, "Value must be greater than 0");
        Balance storage balance = _lockedBalances[msg.sender]; 

        require(balance.amount > 0, "No existing lock found");
        require(balance.end > getBlockTimestamp(), "Cannot add to expired lock. Withdraw");

        _depositFor(msg.sender, value, 0, uint256(Action.INCREASE_LOCK_AMOUNT));
    }

    /**
     * @notice Extend the unlock time for `msg.sender` to `unlockTime`
     * @param newLockTime New epoch time for unlocking
    */
    function increaseLockTime(uint256 newLockTime) external nonReentrant onlyAllowed(msg.sender) {
        uint256 currentTimestamp = getBlockTimestamp();
        require(currentTimestamp + MAXCAP >= newLockTime, "Voting lock can be 4 years max");

        Balance storage balance = _lockedBalances[msg.sender]; 
        require(balance.amount > 0, "Nothing is locked");
        require(newLockTime > balance.end, "Lock time must be greater");
        require(balance.end > currentTimestamp, "Lock expired");

        _depositFor(msg.sender, 0, newLockTime, uint256(Action.INCREASE_UNLOCK_TIME));
    }

    /**
     * @notice Withdraw all tokens for `msg.sender`
     * @dev Only possible if the lock has expired
    */
    function withdraw() external nonReentrant {
        Balance storage _locked = _lockedBalances[msg.sender];
        Balance storage _operationLocked = _operationBalances[msg.sender];

        require(getBlockTimestamp() >= _locked.end, "Cannot withdraw before lock expires");
        uint256 value = _locked.amount;

        Balance memory _oldOperationLocked = _operationLocked;
        _totalSupply -= value;

        _locked.amount = 0;
        _operationLocked.amount = 0;

        _locked.end = 0;
        _operationLocked.end = 0;

        _checkpoint(msg.sender, _oldOperationLocked, _operationLocked);

        emit Withdrawn(msg.sender, value);
        assert(amptToken.transfer(msg.sender, value));
    }

    /**
     * @notice Deposit `value` tokens for `depositer` and add to the lock
     * @dev Anyone (even a smart contract) can deposit for someone else, but cannot extend their locktime and deposit for a brand new use
     * @param depositer User's wallet address
     * @param value Amount to add to user's lock
    */
    function depositFor(address depositer, uint256 value) external nonReentrant {
        Balance storage _locked = _lockedBalances[depositer]; 

        require(value > 0, "Value must be greater than 0");
        require(_locked.amount > 0, "No existing lock found");
        require(_locked.end > getBlockTimestamp(), "Cannot add to expired lock. Withdraw");

        _depositFor(depositer, value, 0, uint256(Action.DEPOSIT_FOR_TYPE));
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external onlyAllowed(msg.sender) {
        require(msg.sender != delegatee, "Cannot delegate to self");

        require(msg.sender != address(0), "Cannot delegate from the zero address");
        require(delegatee != address(0), "Cannot delegate to the zero address");
        
        _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(_name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "delegateBySig: invalid signature");
        require(signatory != msg.sender, "delegateBySig: cannot delegate to self");

        require(nonce == nonces[signatory], "delegateBySig: invalid nonce");
        nonces[signatory]++;
        require(getBlockTimestamp() <= expiry, "delegateBySig: signature expired");

        _delegate(signatory, delegatee);
    }

    /**
     * @notice Deposit and lock tokens for a user
     * @param depositer User's wallet address
     * @param value Amount to add to user's lock
     * @param unlockTime New time when to unlock the tokens, or 0 if unchanged
     * @param actionType Type of action to log
    */
    function _depositFor(address depositer, uint256 value, uint256 unlockTime, uint256 actionType) internal {
        Balance storage _locked = _lockedBalances[depositer];
        Balance storage _operationLocked = _operationBalances[depositer];
        Balance memory _oldOperationLocked = _operationLocked;

        _totalSupply += value;

        _locked.amount += value;
        if (unlockTime != 0) {
            _locked.end = unlockTime;
        }

        _operationLocked.amount += value;
        if (unlockTime != 0) {
            _operationLocked.end = unlockTime;
        }

        _checkpoint(depositer, _oldOperationLocked, _operationLocked);

        emit Deposited(depositer, value, _locked.end, actionType);
        if(value != 0) {
            assert(amptToken.transferFrom(depositer, address(this), value));
        }
    }

    function _delegate(address delegator, address delegatee) internal {
        Balance storage _sourceBalance = _operationBalances[delegator];
        Balance memory _oldSourceBalance = _sourceBalance;

        require(_sourceBalance.amount > 0, "No existing lock found");

        Balance storage _destinationBalance = _operationBalances[delegatee];
        Balance memory _oldDestinationBalance = _destinationBalance;

        delegates[delegator] = delegatee;
        emit DelegateChanged(delegator, delegatee);

        _sourceBalance.amount = 0;
        /// @dev The balance.end should be intact for the future deposits
        _checkpoint(delegator, _oldSourceBalance, _sourceBalance);

        _destinationBalance.amount += _oldSourceBalance.amount;
        if(_oldDestinationBalance.end == 0) {
            _destinationBalance.end = _oldSourceBalance.end;
        }
        _checkpoint(delegatee, _oldDestinationBalance, _destinationBalance);
    }

    struct CheckPointVars {
        int256 oldDslope;
        int256 newDslope;
        uint256 currentEpoch;
        uint256 currentBlock;
        uint256 currentTimestamp;
        uint256 currentUserEpoch;
    }

    /**
     * @notice Record global and per-user data to checkpoint
     * @param addr User's wallet address. No user checkpoint if 0x0
     * @param oldLocked Previous locked amount / end lock time for the user
     * @param newLocked New locked amount / end lock time for the user
    */
    function _checkpoint(address addr, Balance memory oldLocked, Balance memory newLocked) internal {
        Point memory _userPointOld = Point(0, 0, 0, 0);
        Point memory _userPointNew = Point(0, 0, 0, 0);

        CheckPointVars memory _checkpointVars = CheckPointVars(
            0, 
            0, 
            epoch, 
            getBlockNumber(), 
            getBlockTimestamp(), 
            userPointEpoch[addr]
        );

        if (addr != address(0)) {
            if (oldLocked.end > _checkpointVars.currentTimestamp && oldLocked.amount > 0) {
                _userPointOld.slope = int256(oldLocked.amount / MAXCAP);
                _userPointOld.bias = _userPointOld.slope * int256(oldLocked.end - _checkpointVars.currentTimestamp);
            }

            if (newLocked.end > _checkpointVars.currentTimestamp && newLocked.amount > 0) {
                _userPointNew.slope = int256(newLocked.amount / MAXCAP);
                _userPointNew.bias = _userPointNew.slope * int256(newLocked.end - _checkpointVars.currentTimestamp);
            }

            _checkpointVars.oldDslope = slopeChanges[oldLocked.end];
            if (newLocked.end != 0) {
                if (newLocked.end == oldLocked.end) {
                    _checkpointVars.newDslope = _checkpointVars.oldDslope;
                } else {
                    _checkpointVars.newDslope = slopeChanges[newLocked.end];
                }
            }
        }

        Point memory lastPoint = Point(0, 0, _checkpointVars.currentTimestamp, _checkpointVars.currentBlock);
        if (_checkpointVars.currentEpoch > 0) {
            lastPoint = pointHistory[_checkpointVars.currentEpoch];
        }

        uint lastCheckpoint = lastPoint.ts;
        Point memory initialLastPoint = lastPoint;
        uint256 blockSlope = 0;
        if (_checkpointVars.currentTimestamp > lastPoint.ts) {
            blockSlope = 1e18 * (_checkpointVars.currentBlock - lastPoint.block) / (_checkpointVars.currentTimestamp - lastPoint.ts);
        }

        uint256 timeIndex = lastCheckpoint * WEEK / WEEK;
        for (int256 i=0; i <= 255; i++) {
            timeIndex += WEEK;
            int256 dSlope = 0;

            if (timeIndex > _checkpointVars.currentTimestamp) {
                timeIndex = _checkpointVars.currentTimestamp;
            } else {
                dSlope = slopeChanges[timeIndex];
            }

            lastPoint.bias -= lastPoint.slope * int256(timeIndex - lastCheckpoint);
            lastPoint.slope += dSlope;
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            lastCheckpoint = timeIndex;
            lastPoint.ts = timeIndex;

            lastPoint.block = initialLastPoint.block + blockSlope * (timeIndex - initialLastPoint.ts) / 1e18;
            _checkpointVars.currentEpoch += 1;
            if (timeIndex == _checkpointVars.currentTimestamp) {
                lastPoint.block = _checkpointVars.currentBlock;
                break;
            } else {
                pointHistory[_checkpointVars.currentEpoch] = lastPoint;
            }
        }
        epoch = _checkpointVars.currentEpoch;

        if (addr != address(0)) {
            lastPoint.slope += (_userPointNew.slope - _userPointOld.slope);
            lastPoint.bias += (_userPointNew.bias - _userPointOld.bias);
            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
        }
        pointHistory[_checkpointVars.currentEpoch] = lastPoint;

        if (addr != address(0)) {
            if (oldLocked.end > _checkpointVars.currentTimestamp) {
                _checkpointVars.oldDslope += _userPointOld.slope;
                if (newLocked.end == oldLocked.end) {
                    _checkpointVars.oldDslope -= _userPointNew.slope;
                }
                slopeChanges[oldLocked.end] = _checkpointVars.oldDslope;
            }
            if (newLocked.end > _checkpointVars.currentTimestamp) {
                if (newLocked.end > oldLocked.end) {
                    _checkpointVars.newDslope -= _userPointNew.slope;
                    slopeChanges[newLocked.end] = _checkpointVars.newDslope;
                }
            }

            userPointEpoch[addr]++;
            _userPointNew.ts = _checkpointVars.currentTimestamp;
            _userPointNew.block = _checkpointVars.currentBlock;
            userPointHistory[addr][_checkpointVars.currentUserEpoch + 1] = _userPointNew;
        }
    }

    function getBlockNumber() public virtual view returns (uint256) {
        return block.number;
    }

    function getBlockTimestamp() public virtual view returns (uint256) {
        return block.timestamp;
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}