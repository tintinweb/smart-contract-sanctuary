// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./lib/SignedSafeMath128.sol";
import "./Adminable.sol";
import "./DelegateInterface.sol";
import "./XOLEInterface.sol";
import "./DelegateInterface.sol";
import "./lib/DexData.sol";


// @title Voting Escrowed Token
// @notice Lock OLE to get time and amount weighted xOLE
// The weight in this implementation is linear, and lock cannot be more than maxtime (4 years)
contract XOLE is DelegateInterface, Adminable, XOLEInterface, XOLEStorage, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SignedSafeMath128 for int128;
    using DexData for bytes;

    /* We cannot really do block numbers per se b/c slope is per time, not per block
    and per block could be fairly bad b/c Ethereum changes blocktimes.
    What we can do is to extrapolate ***At functions
    */
    constructor() {
    }

    function initialize(
        address _oleToken,
        DexAggregatorInterface _dexAgg,
        uint _devFundRatio,
        address _dev
    ) public {
        require(msg.sender == admin, "Not admin");
        require(_oleToken != address(0), "_oleToken address cannot be 0");
        require(_dev != address(0), "_dev address cannot be 0");
        oleToken = IERC20(_oleToken);
        devFundRatio = _devFundRatio;
        dev = _dev;
        dexAgg = _dexAgg;
    }

    function setDexAgg(DexAggregatorInterface newDexAgg) external override onlyAdmin {
        dexAgg = newDexAgg;
    }

    // Fees sharing functions  =====

    function withdrawDevFund() external override {
        require(msg.sender == dev, "Dev only");
        require(devFund != 0, "No fund to withdraw");
        uint toSend = devFund;
        devFund = 0;
        oleToken.transfer(dev, toSend);
    }

    function convertToSharingToken(uint amount, uint minBuyAmount, bytes memory dexData) external override onlyAdminOrDeveloper() {
        require(totalSupply > 0, "Can't share without locked OLE");
        address fromToken;
        address toToken;
        // If no swapping, then assuming OLE reward distribution
        if (dexData.length == 0) {
            fromToken = address(oleToken);
        }
        // Not OLE
        else {
            if (dexData.isUniV2Class()) {
                address[] memory path = dexData.toUniV2Path();
                fromToken = path[0];
                toToken = path[path.length - 1];
            } else {
                DexData.V3PoolData[] memory path = dexData.toUniV3Path();
                fromToken = path[0].tokenA;
                toToken = path[path.length - 1].tokenB;
            }
        }
        uint newReward;
        if (fromToken == address(oleToken)) {
            uint claimable = totalRewarded.sub(withdrewReward);
            uint toShare = oleToken.balanceOf(address(this)).sub(claimable).sub(totalLocked).sub(devFund);
            require(toShare >= amount, 'Exceed OLE balance');
            newReward = toShare;
        } else {
            require(IERC20(fromToken).balanceOf(address(this)) >= amount, "Exceed available balance");
            (IERC20(fromToken)).approve(address(dexAgg), amount);
            newReward = dexAgg.sellMul(amount, minBuyAmount, dexData);
        }
        //fromToken or toToken equal OLE ,update reward
        if (fromToken == address(oleToken) || toToken == address(oleToken)) {
            uint newDevFund = newReward.mul(devFundRatio).div(10000);
            newReward = newReward.sub(newDevFund);
            devFund = devFund.add(newDevFund);
            totalRewarded = totalRewarded.add(newReward);
            lastUpdateTime = block.timestamp;
            rewardPerTokenStored = rewardPerToken(newReward);
            emit RewardAdded(fromToken, amount, newReward);
        } else {
            emit RewardConvert(fromToken, toToken, amount, newReward);
        }

    }

    function earned(address account) external override view returns (uint) {
        return earnedInternal(account);
    }

    function earnedInternal(address account) internal view returns (uint) {
        return (balances[account])
        .mul(rewardPerToken(0).sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
    }

    function rewardPerToken(uint newReward) internal view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        if (block.timestamp == lastUpdateTime) {
            return rewardPerTokenStored.add(newReward
            .mul(1e18)
            .div(totalSupply));
        } else {
            return rewardPerTokenStored;
        }
    }

    function withdrawReward() external override {
        uint reward = getReward();
        oleToken.safeTransfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    function getReward() internal updateReward(msg.sender) returns (uint) {
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            withdrewReward = withdrewReward.add(reward);
        }
        return reward;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken(0);
        rewards[account] = earnedInternal(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    /*** Admin Functions ***/
    function setDevFundRatio(uint newRatio) external override onlyAdmin {
        require(newRatio <= 10000);
        devFundRatio = newRatio;
    }

    function setDev(address newDev) external override onlyAdmin {
        dev = newDev;
    }


    function _mint(address account, uint amount) internal {
        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        if (delegates[account] == address(0)) {
            delegates[account] = account;
        }
        _moveDelegates(address(0), delegates[account], amount);
        _updateTotalSupplyCheckPoints();
    }

    function _burn(address account) internal {
        uint burnAmount = balances[account];
        totalSupply = totalSupply.sub(burnAmount);
        balances[account] = 0;
        emit Transfer(account, address(0), burnAmount);
        _moveDelegates(delegates[account], address(0), burnAmount);
        _updateTotalSupplyCheckPoints();
    }

    function _updateTotalSupplyCheckPoints() internal {
        uint32 blockNumber = safe32(block.number, "block number exceeds 32 bits");
        if (totalSupplyNumCheckpoints > 0 && totalSupplyCheckpoints[totalSupplyNumCheckpoints - 1].fromBlock == blockNumber) {
            totalSupplyCheckpoints[totalSupplyNumCheckpoints - 1].votes = totalSupply;
        }
        else {
            totalSupplyCheckpoints[totalSupplyNumCheckpoints] = Checkpoint(blockNumber, totalSupply);
            totalSupplyNumCheckpoints = totalSupplyNumCheckpoints + 1;
        }

    }

    function balanceOf(address addr) external view override returns (uint256){
        return balances[addr];
    }

    function totalSupplyAt(uint256 blockNumber) external view returns (uint){
        if (totalSupplyNumCheckpoints == 0) {
            return 0;
        }
        if (totalSupplyCheckpoints[totalSupplyNumCheckpoints - 1].fromBlock <= blockNumber) {
            return totalSupplyCheckpoints[totalSupplyNumCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (totalSupplyCheckpoints[0].fromBlock > blockNumber) {
            return 0;
        }

        uint lower;
        uint upper = totalSupplyNumCheckpoints - 1;
        while (upper > lower) {
            uint center = upper - (upper - lower) / 2;
            // ceil, avoiding overflow
            Checkpoint memory cp = totalSupplyCheckpoints[center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return totalSupplyCheckpoints[lower].votes;
    }

    /*
    @notice Deposit `_value` tokens for `msg.sender` and lock until `_unlock_time`
    @param _value Amount to deposit
    @param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
    */
    function create_lock(uint256 _value, uint256 _unlock_time) external override nonReentrant() {
        // Locktime is rounded down to weeks
        uint256 unlock_time = _unlock_time.div(WEEK).mul(WEEK);
        LockedBalance memory _locked = locked[msg.sender];

        require(_value > 0, "Non zero value");
        require(_locked.amount == 0, "Withdraw old tokens first");
        require(unlock_time > block.timestamp, "Can only lock until time in the future");
        require(unlock_time <= block.timestamp + MAXTIME, "Voting lock can be 4 years max");

        _deposit_for(msg.sender, _value, unlock_time, _locked, CREATE_LOCK_TYPE);
    }

    /*
    @notice Deposit `_value` additional tokens for `msg.sender`
    without modifying the unlock time
    @param _value Amount of tokens to deposit and add to the lock
    */
    function increase_amount(uint256 _value) external override nonReentrant() {
        LockedBalance memory _locked = locked[msg.sender];
        require(_value > 0, "need non - zero value");
        require(_locked.amount > 0, "No existing lock found");
        require(_locked.end > block.timestamp, "Cannot add to expired lock. Withdraw");
        _deposit_for(msg.sender, _value, 0, _locked, INCREASE_LOCK_AMOUNT);
    }

    /*
    @notice Extend the unlock time for `msg.sender` to `_unlock_time`
    @param _unlock_time New epoch time for unlocking
    */

    function increase_unlock_time(uint256 _unlock_time) external override nonReentrant() {
        LockedBalance memory _locked = locked[msg.sender];
        // Locktime is rounded down to weeks
        uint256 unlock_time = _unlock_time.div(WEEK).mul(WEEK);
        require(_locked.end > block.timestamp, "Lock expired");
        require(_locked.amount > 0, "Nothing is locked");
        require(unlock_time > _locked.end, "Can only increase lock duration");
        require(unlock_time <= block.timestamp + MAXTIME, "Voting lock can be 4 years max");

        _deposit_for(msg.sender, 0, unlock_time, _locked, INCREASE_UNLOCK_TIME);
    }
    /*
    @notice Deposit and lock tokens for a user
    @param _addr User's wallet address
    @param _value Amount to deposit
    @param unlock_time New time when to unlock the tokens, or 0 if unchanged
    @param locked_balance Previous locked amount / timestamp
    */
    function _deposit_for(address _addr, uint256 _value, uint256 unlock_time, LockedBalance memory _locked, int128 _type) internal updateReward(_addr) {
        uint256 locked_before = totalLocked;
        totalLocked = locked_before.add(_value);
        // Adding to existing lock, or if a lock is expired - creating a new one
        _locked.amount = _locked.amount.add(_value);

        if (unlock_time != 0) {
            _locked.end = unlock_time;
        }
        locked[_addr] = _locked;

        if (_value != 0) {
            assert(IERC20(oleToken).transferFrom(msg.sender, address(this), _value));
        }

        uint calExtraValue = _value;
        // only increase unlock time
        if (_value == 0) {
            _burn(_addr);
            calExtraValue = locked[_addr].amount;
        }
        uint weekCount = locked[_addr].end.sub(block.timestamp).div(WEEK);
        if (weekCount > 1) {
            uint extraToken = calExtraValue.mul(oneWeekExtraRaise).mul(weekCount - 1).div(10000);
            _mint(_addr, calExtraValue + extraToken);
        } else {
            _mint(_addr, calExtraValue);
        }
        emit Deposit(_addr, _value, _locked.end, _type, block.timestamp);
    }

    /*
    @notice Withdraw all tokens for `msg.sender`
    @dev Only possible if the lock has expired
    */
    function withdraw() external override nonReentrant() updateReward(msg.sender) {
        LockedBalance memory _locked = locked[msg.sender];
        require(_locked.amount >= 0, "Nothing to withdraw");
        require(block.timestamp >= _locked.end, "The lock didn't expire");
        uint256 value = _locked.amount;
        totalLocked = totalLocked.sub(value);
        _locked.end = 0;
        _locked.amount = 0;
        locked[msg.sender] = _locked;
        uint reward = getReward();
        require(IERC20(oleToken).transfer(msg.sender, value.add(reward)));
        _burn(msg.sender);
        emit Withdraw(msg.sender, value, block.timestamp);
        emit RewardPaid(msg.sender, reward);
    }


    /**
 * Delegate votes from `msg.sender` to `delegatee`
 * @param delegatee The address to delegate votes to
 */
    function delegate(address delegatee) public {
        require(delegatee != address(0), 'delegatee:0x');
        return _delegate(msg.sender, delegatee);
    }

    /**
     * Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        delegateBySigInternal(delegatee, nonce, expiry, v, r, s);
    }

    function delegateBySigs(address delegatee, uint[] memory nonce, uint[] memory expiry, uint8[] memory v, bytes32[] memory r, bytes32[] memory s) public {
        require(nonce.length == expiry.length && nonce.length == v.length && nonce.length == r.length && nonce.length == s.length);
        for (uint i = 0; i < nonce.length; i++) {
            (bool success,) = address(this).call(
                abi.encodeWithSignature("delegateBySig(address,uint256,uint256,uint8,bytes32,bytes32)", delegatee, nonce[i], expiry[i], v[i], r[i], s[i])
            );
            if (!success) emit FailedDelegateBySig(delegatee, nonce[i], expiry[i], v[i], r[i], s[i]);
        }
    }

    function delegateBySigInternal(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) internal {
        require(delegatee != address(0), 'delegatee:0x');
        require(block.timestamp <= expiry, "delegateBySig: signature expired");

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "delegateBySig: invalid signature");
        require(nonce == nonces[signatory], "delegateBySig: invalid nonce");

        _delegate(signatory, delegatee);
    }


    /**
     * Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint) {
        require(blockNumber < block.number, "getPriorVotes:not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2;
            // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        nonces[delegator]++;
        address currentDelegate = delegates[delegator];
        uint delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;
        emit DelegateChanged(delegator, currentDelegate, delegatee);
        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint oldVotes, uint newVotes) internal {
        uint32 blockNumber = safe32(block.number, "block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2 ** 32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly {chainId := chainid()}
        return chainId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @title SignedSafeMath128
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath128 {
    int128 constant private _INT128_MIN = -2**127;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int128 a, int128 b) internal pure returns (int128) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT128_MIN), "SignedSafeMath128: multiplication overflow");

        int128 c = a * b;
        require(c / a == b, "SignedSafeMath128: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int128 a, int128 b) internal pure returns (int128) {
        require(b != 0, "SignedSafeMath128: division by zero");
        require(!(b == -1 && a == _INT128_MIN), "SignedSafeMath128: division overflow");

        int128 c = a / b;
        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int128 a, int128 b) internal pure returns (int128) {
        int128 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath128: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int128 a, int128 b) internal pure returns (int128) {
        int128 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath128: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;


library DexData {
    uint256 private constant ADDR_SIZE = 20;
    uint256 private constant FEE_SIZE = 3;
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;


    uint constant dexNameStart = 0;
    uint constant dexNameLength = 1;
    uint constant feeStart = 1;
    uint constant feeLength = 3;
    uint constant uniV3QuoteFlagStart = 4;
    uint constant uniV3QuoteFlagLength = 1;

    uint8 constant DEX_UNIV2 = 1;
    uint8 constant DEX_UNIV3 = 2;
    uint8 constant DEX_PANCAKE = 3;
    uint8 constant DEX_SUSHI = 4;
    uint8 constant DEX_MDEX = 5;
    uint8 constant DEX_TRADERJOE = 6;
    uint8 constant DEX_SPOOKY = 7;
    uint8 constant DEX_QUICK = 8;
    uint8 constant DEX_SHIBA = 9;
    uint8 constant DEX_APE = 10;

    bytes constant UNIV2 = hex"01";

    struct V3PoolData {
        address tokenA;
        address tokenB;
        uint24 fee;
    }

    function toDex(bytes memory data) internal pure returns (uint8) {
        require(data.length >= dexNameLength, 'dex error');
        uint8 temp;
        assembly {
            temp := byte(0, mload(add(data, add(0x20, dexNameStart))))
        }
        return temp;
    }

    function toFee(bytes memory data) internal pure returns (uint24) {
        require(data.length >= dexNameLength + feeLength, 'fee error');
        uint temp;
        assembly {
            temp := mload(add(data, add(0x20, feeStart)))
        }
        return uint24(temp >> (256 - (feeLength * 8)));
    }

    function toDexDetail(bytes memory data) internal pure returns (uint32) {
        if (data.length == dexNameLength) {
            uint8 temp;
            assembly {
                temp := byte(0, mload(add(data, add(0x20, dexNameStart))))
            }
            return uint32(temp);
        } else {
            uint temp;
            assembly {
                temp := mload(add(data, add(0x20, dexNameStart)))
            }
            return uint32(temp >> (256 - ((feeLength + dexNameLength) * 8)));
        }
    }
    // true ,sell all
    function toUniV3QuoteFlag(bytes memory data) internal pure returns (bool) {
        require(data.length >= dexNameLength + feeLength + uniV3QuoteFlagLength, 'v3flag error');
        uint8 temp;
        assembly {
            temp := byte(0, mload(add(data, add(0x20, uniV3QuoteFlagStart))))
        }
        return temp > 0;
    }

    // univ2 class
    function isUniV2Class(bytes memory data) internal pure returns (bool) {
        return (data.length - dexNameLength) % 20 == 0;
    }
    // v2 path
    function toUniV2Path(bytes memory data) internal pure returns (address[] memory path) {
        data = slice(data, dexNameLength, data.length - dexNameLength);
        uint pathLength = data.length / 20;
        path = new address[](pathLength);
        for (uint i = 0; i < pathLength; i++) {
            path[i] = toAddress(data, 20 * i);
        }
    }

    // v3 path
    function toUniV3Path(bytes memory data) internal pure returns (V3PoolData[] memory path) {
        data = slice(data, uniV3QuoteFlagStart + uniV3QuoteFlagLength, data.length - (uniV3QuoteFlagStart + uniV3QuoteFlagLength));
        uint pathLength = numPools(data);
        path = new V3PoolData[](pathLength);
        for (uint i = 0; i < pathLength; i++) {
            V3PoolData memory pool;
            if (i != 0) {
                data = slice(data, NEXT_OFFSET, data.length - NEXT_OFFSET);
            }
            pool.tokenA = toAddress(data, 0);
            pool.fee = toUint24(data, ADDR_SIZE);
            pool.tokenB = toAddress(data, NEXT_OFFSET);
            path[i] = pool;
        }
    }

    function numPools(bytes memory path) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;
        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }
        return tempUint;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;
        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }
        return tempAddress;
    }


    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
                tempBytes := mload(0x40)

            // The first word of the slice result is potentially a partial
            // word read from the original array. To read it, we calculate
            // the length of that partial word and start copying that many
            // bytes into the array. The first word we copy will start with
            // data we don't care about, but the last `lengthmod` bytes will
            // land at the beginning of the contents of the new array. When
            // we're done copying, we overwrite the full first word with
            // the actual length of the slice.
                let lengthmod := and(_length, 31)

            // The multiplication in the next line is necessary
            // because when slicing multiples of 32 bytes (lengthmod == 0)
            // the following copy loop was copying the origin's length
            // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                // The multiplication in the next line has the same exact purpose
                // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

            //update free-memory pointer
            //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
            //zero out the 32 bytes slice we are about to return
            //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface DexAggregatorInterface {

    function sell(address buyToken, address sellToken, uint sellAmount, uint minBuyAmount, bytes memory data) external returns (uint buyAmount);

    function sellMul(uint sellAmount, uint minBuyAmount, bytes memory data) external returns (uint buyAmount);

    function buy(address buyToken, address sellToken, uint buyAmount, uint maxSellAmount, bytes memory data) external returns (uint sellAmount);

    function calBuyAmount(address buyToken, address sellToken, uint sellAmount, bytes memory data) external view returns (uint);

    function calSellAmount(address buyToken, address sellToken, uint buyAmount, bytes memory data) external view returns (uint);

    function getPrice(address desToken, address quoteToken, bytes memory data) external view returns (uint256 price, uint8 decimals);

    function getAvgPrice(address desToken, address quoteToken, uint32 secondsAgo, bytes memory data) external view returns (uint256 price, uint8 decimals, uint256 timestamp);

    //cal current avg price and get history avg price
    function getPriceCAvgPriceHAvgPrice(address desToken, address quoteToken, uint32 secondsAgo, bytes memory dexData) external view returns (uint price, uint cAvgPrice, uint256 hAvgPrice, uint8 decimals, uint256 timestamp);

    function updatePriceOracle(address desToken, address quoteToken, uint32 timeWindow, bytes memory data) external returns(bool);

    function updateV3Observation(address desToken, address quoteToken, bytes memory data) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./dex/DexAggregatorInterface.sol";


contract XOLEStorage {

    // EIP-20 token name for this token
    string public constant name = 'xOLE';

    // EIP-20 token symbol for this token
    string public constant symbol = 'xOLE';

    // EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    // Total number of tokens supply
    uint public totalSupply;

    // Total number of tokens locked
    uint public totalLocked;

    // Official record of token balances for each account
    mapping(address => uint) internal balances;

    mapping(address => LockedBalance) public locked;

    DexAggregatorInterface public dexAgg;

    IERC20 public oleToken;

    struct LockedBalance {
        uint256 amount;
        uint256 end;
    }

    uint constant oneWeekExtraRaise = 208;// 2.08% * 210 = 436% (4 years raise)

    int128 constant DEPOSIT_FOR_TYPE = 0;
    int128 constant CREATE_LOCK_TYPE = 1;
    int128 constant INCREASE_LOCK_AMOUNT = 2;
    int128 constant INCREASE_UNLOCK_TIME = 3;

    uint256 constant WEEK = 7 * 86400;  // all future times are rounded by week
    uint256 constant MAXTIME = 4 * 365 * 86400;  // 4 years
    uint256 constant MULTIPLIER = 10 ** 18;


    // dev team account
    address public dev;

    uint public devFund;

    uint public devFundRatio; // ex. 5000 => 50%

    // user => reward
    mapping(address => uint256) public rewards;

    // useless
    uint public totalStaked;

    // total to shared
    uint public totalRewarded;

    uint public withdrewReward;

    uint public lastUpdateTime;

    uint public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;


    // A record of each accounts delegate
    mapping(address => address) public delegates;

    // A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint votes;
    }

    mapping(uint256 => Checkpoint) public totalSupplyCheckpoints;

    uint256 public totalSupplyNumCheckpoints;

    // A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    // The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    // The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    // The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    // A record of states for signing / validating signatures
    mapping(address => uint) public nonces;

    // An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    // An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);


    event RewardAdded(address fromToken, uint convertAmount, uint reward);
    event RewardConvert(address fromToken, address toToken, uint convertAmount, uint returnAmount);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Deposit (
        address indexed provider,
        uint256 value,
        uint256 indexed locktime,
        int128 type_,
        uint256 ts
    );

    event Withdraw (
        address indexed provider,
        uint256 value,
        uint256 ts
    );

    event Supply (
        uint256 prevSupply,
        uint256 supply
    );

    event RewardPaid (
        address paidTo,
        uint256 amount
    );

    event FailedDelegateBySig(
        address indexed delegatee,
        uint indexed nonce, 
        uint expiry,
        uint8 v, 
        bytes32 r, 
        bytes32 s
    );
}


interface XOLEInterface {

    function convertToSharingToken(uint amount, uint minBuyAmount, bytes memory data) external;

    function withdrawDevFund() external;

    function earned(address account) external view returns (uint);

    function withdrawReward() external;

    /*** Admin Functions ***/

    function setDevFundRatio(uint newRatio) external;

    function setDev(address newDev) external;

    function setDexAgg(DexAggregatorInterface newDexAgg) external;

    // xOLE functions

    function create_lock(uint256 _value, uint256 _unlock_time) external;

    function increase_amount(uint256 _value) external;

    function increase_unlock_time(uint256 _unlock_time) external;

    function withdraw() external;

    function balanceOf(address addr) external view returns (uint256);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;


contract DelegateInterface {
    /**
     * Implementation address for this contract
     */
    address public implementation;

}

// SPDX-License-Identifier: BUSL-1.1


pragma solidity 0.7.6;

abstract contract Adminable {
    address payable public admin;
    address payable public pendingAdmin;
    address payable public developer;

    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    event NewAdmin(address oldAdmin, address newAdmin);
    constructor () {
        developer = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "caller must be admin");
        _;
    }
    modifier onlyAdminOrDeveloper() {
        require(msg.sender == admin || msg.sender == developer, "caller must be admin or developer");
        _;
    }

    function setPendingAdmin(address payable newPendingAdmin) external virtual onlyAdmin {
        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;
        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;
        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function acceptAdmin() external virtual {
        require(msg.sender == pendingAdmin, "only pendingAdmin can accept admin");
        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        // Store admin with value pendingAdmin
        admin = pendingAdmin;
        // Clear the pending value
        pendingAdmin = address(0);
        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
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

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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