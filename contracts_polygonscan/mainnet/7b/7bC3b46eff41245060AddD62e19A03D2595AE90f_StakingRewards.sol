/**
 *Submitted for verification at polygonscan.com on 2021-09-27
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;



// Part: IERC20

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// Part: SafeERC20

library SafeERC20 {
    bytes4 private constant TRANSFER_SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 private constant TRANSFERFROM_SELECTOR =
        bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    bytes4 private constant APPROVE_SELECTOR =
        bytes4(keccak256(bytes("approve(address,uint256)")));

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(TRANSFER_SELECTOR, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(TRANSFERFROM_SELECTOR, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFERFROM_FAILED"
        );
    }

    function safeApprove(
        address token,
        address spender,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(APPROVE_SELECTOR, spender, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "APPROVE_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// Part: SafeMath

/// @title a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x / y;
    }
}

// Part: FutureLockToken

/**
    @title Bare-bones Token implementation
    @notice Based on the ERC-20 token standard as defined at
            https://eips.ethereum.org/EIPS/eip-20
 */
contract FutureLockToken {
    using SafeMath for uint256;

    string public symbol;
    string public name;
    uint256 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    /// @dev for security, minter MUST be a smart contract
    address public minter;
    uint256 public weeksToUnlock;
    bool public unlocksWithPenalty;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor(uint256 _weeksToUnlock, bool _unlocksWithPenalty) public {
        minter = msg.sender;
        weeksToUnlock = _weeksToUnlock;
        unlocksWithPenalty = _unlocksWithPenalty;

        bytes1 first = bytes1(uint8(_weeksToUnlock / 10 + 48));
        bytes1 second = bytes1(uint8((_weeksToUnlock % 10) + 48));
        if (_unlocksWithPenalty) {
            name = string(
                abi.encodePacked(
                    bytes20("Compact RewardPACT: "),
                    first,
                    second,
                    bytes6(" Weeks")
                )
            );
            symbol = string(abi.encodePacked(bytes6("PACT-R"), first, second));
        } else {
            name = string(
                abi.encodePacked(
                    bytes20("Compact FuturePACT: "),
                    first,
                    second,
                    bytes6(" Weeks")
                )
            );
            symbol = string(abi.encodePacked(bytes6("PACT-F"), first, second));
        }
        emit Transfer(address(0), msg.sender, 0);
    }

    /**
        @notice Getter to check the current balance of an address
        @param _owner Address to query the balance of
        @return Token balance
     */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /**
        @notice Getter to check the amount of tokens that an owner allowed to a spender
        @param _owner The address which owns the funds
        @param _spender The address which will spend the funds
        @return The amount of tokens still available for the spender
     */
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /**
        @notice Approve an address to spend the specified amount of tokens on behalf of msg.sender
        @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
             and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
             race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
             https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        @param _spender The address which will spend the funds.
        @param _value The amount of tokens to be spent.
        @return Success boolean
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /** shared logic for transfer and transferFrom */
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_to != address(0) && _to != minter);
        require(balances[_from] >= _value, "Insufficient balance");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    /**
        @notice Transfer tokens to a specified address
        @param _to The address to transfer to
        @param _value The amount to be transferred
        @return Success boolean
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        @notice Transfer tokens from one address to another
        @param _from The address which you want to send tokens from
        @param _to The address which you want to transfer to
        @param _value The amount of tokens to be transferred
        @return Success boolean
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function mint(address _user, uint256 _value) external returns (bool) {
        require(msg.sender == minter);
        balances[_user] = balances[_user].add(_value);
        totalSupply = totalSupply.add(_value);
        emit Transfer(address(0), _user, _value);
        return true;
    }

    /**
        @notice Burn the future lock tokens to converted to them into locked tokens.
        @dev minter is a smart contract that can only call this when converting the lock token into a locked position.
     */
    function burn(address _user, uint256 _value) external returns (bool) {
        require(msg.sender == minter);
        require(balances[_user] >= _value, "Insufficient balance");
        balances[_user] = balances[_user].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Transfer(_user, address(0), _value);
        return true;
    }
}

// File: StakingRewards.sol

/**
    @title Staking Rewards
    @dev Users lock PACT within this contract in order to:
          * receive a portion of fees generated by the protocol
          * receive vote weight, used to decide which pools receive
            PACT emissions each week (voting happens in `IncentiveVoting`)

         This contract also handles minting and redemption of
         futurePACT and rewardPACT.
 */
contract StakingRewards {
    using SafeMath for uint256;
    using SafeERC20 for address;

    struct StreamData {
        uint256 start;
        uint256 amount;
        uint256 claimed;
    }

    // `weeklyTotalWeight` and `weeklyWeightOf` track the total lock weight for each week,
    // calculated as the sum of [number of tokens] * [weeks to unlock] for all active locks.
    // The array index corresponds to the number of the epoch week.
    uint256[9362] public weeklyTotalWeight;
    mapping(address => uint256[9362]) public weeklyWeightOf;

    // `weeklyUnlocksOf` tracks the actual deposited balances of PACT. Any non-zero value
    // stored at an index < `getWeek` is considered unlocked and may be withdrawn
    mapping(address => uint256[9362]) public weeklyUnlocksOf;

    // `withdrawnUntil` tracks the most recent week for which each user has withdrawn their
    // expired PACT locks. Values in `weeklyUnlocksOf` with an index less than the related
    // value within `withdrawnUntil` have already been withdrawn.
    mapping(address => uint256) withdrawnUntil;

    // After a lock expires, a user calls to `initiateExitStream` and the withdrawable PACT
    // is streamed out linearly over the following week. This array is used to track data
    // related to the exit stream.
    mapping(address => StreamData) public exitStream;

    // Arrays which track the deployment addresses of futurePACT and rewardPACT.
    //
    // * "futurePACT" is an ERC20 which represents a future locked PACT balance in this contract.
    //   It is freely transferrible and used to simplify distributing locked PACT incentives.
    //   futurePACT is redeemed by calling `depositLockTokens`, which burns the token and creates
    //   a new PACT lock for the caller.
    // * "rewardPACT" functions similarly to futurePACT, however the holder has an option to
    //   pay a percentage of the underlying PACT in order to receive it immediately instead
    //   of as a lock. The size of the penalty ranges from 25% to 75% depending on the expected
    //   duration of the lock. The amount paid is converted to futurePACT and distributed to
    //   locked PACT positions in the same way as other protocol fees.
    //
    // Lock tokens exist in 4 week increments. They range from 8 to 52 weeks (8, 12, 16, ... 52)
    FutureLockToken[12] public futurePactTokens;
    FutureLockToken[12] public rewardPactTokens;

    // Mappings related to fee distribution
    //
    // Fees are transferred into this contract as they are collected, and in the same tokens
    // that they are collected in. The total amount collected each week is recorded in
    // `weeklyFeeAmounts`. At the end of a week, the fee amounts are streamed out over
    // the following week based on each user's lock weight at the end of that week. Data
    // about the active stream for each token is tracked in `activeUserStream`

    // fee token -> week -> total amount received that week
    mapping(address => mapping(uint256 => uint256)) public weeklyFeeAmounts;
    // user -> fee token -> data about the active stream
    mapping(address => mapping(address => StreamData)) activeUserStream;

    // array of all fee tokens that have been added
    address[] public feeTokens;
    // private mapping for tracking which addresses were added to `feeTokens`
    mapping(address => bool) seenFees;

    address public stakingToken;
    uint256 public startTime;

    uint256 constant WEEK = 86400 * 7;

    event NewLock(address indexed user, uint256 amount, uint256 lockWeeks);
    event ExtendLock(
        address indexed user,
        uint256 amount,
        uint256 oldWeeks,
        uint256 newWeeks
    );
    event NewExitStream(
        address indexed user,
        uint256 startTime,
        uint256 amount
    );
    event ExitStreamWithdrawal(
        address indexed user,
        uint256 claimed,
        uint256 remaining
    );
    event MintedLockTokens(
        address indexed caller,
        address indexed receiver,
        uint256 amount,
        uint256 lockWeeks,
        bool isPenalty
    );
    event RedeemedLockTokens(
        address indexed caller,
        address indexed receiver,
        uint256 amount,
        uint256 lockWeeks,
        bool isPenalty
    );
    event RedeemedLockTokensWithPenalty(
        address indexed caller,
        address indexed receiver,
        uint256 amount,
        uint256 lockWeeks,
        uint256 receivedAmount,
        uint256 penaltyAmount
    );
    event FeesReceived(
        address indexed caller,
        address indexed token,
        uint256 indexed week,
        uint256 amount
    );
    event FeesClaimed(
        address indexed caller,
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    /**
        @param _startTime Time of the first emissions. Should be set to the
                          same time as the planned token migration.
     */
    constructor(address _stakingToken, uint256 _startTime) public {
        stakingToken = _stakingToken;
        // must start on the epoch week
        startTime = (_startTime / WEEK) * WEEK;
        require(startTime == _startTime, "!epoch week");
    }

    function getWeek() public view returns (uint256) {
        if (startTime >= block.timestamp) return 0;
        return (block.timestamp - startTime) / WEEK;
    }

    /**
        @notice Get the current lock weight for a user
     */
    function userWeight(address _user) external view returns (uint256) {
        return weeklyWeightOf[_user][getWeek()];
    }

    /**
        @notice Get the total PACT balance held in this contract for a user,
                including both active and expired locks
     */
    function userBalance(address _user)
        external
        view
        returns (uint256 balance)
    {
        uint256 i = withdrawnUntil[_user] + 1;
        uint256 finish = getWeek() + 53;
        while (i < finish) {
            balance += weeklyUnlocksOf[_user][i];
            i++;
        }
        return balance;
    }

    /**
        @notice Get the current total lock weight
     */
    function totalWeight() external view returns (uint256) {
        return weeklyTotalWeight[getWeek()];
    }

    /**
        @notice Get data on a user's active PACT locks
        @param _user Address to query data for
        @return lockData dynamic array of [weeks until expiration, PACT balance of lock]
     */
    function getActiveUserLocks(address _user)
        external
        view
        returns (uint256[2][] memory lockData)
    {
        uint256 length = 0;
        uint256 week = getWeek();
        for (uint256 i = week + 1; i < week + 53; i++) {
            if (weeklyUnlocksOf[_user][i] > 0) length++;
        }
        lockData = new uint256[2][](length);
        uint256 x = 0;
        for (uint256 i = week + 1; i < week + 53; i++) {
            if (weeklyUnlocksOf[_user][i] > 0) {
                lockData[x] = [i - week, weeklyUnlocksOf[_user][i]];
                x++;
            }
        }
        return lockData;
    }

    // ===== LOCKING AND WITHDRAWING PACT =====

    /**
        @notice Deposit PACT into the contract to create a new lock.
        @dev A PACT lock is created for a given number of weeks. The minimum is 1, maximum 52.
             A user can have more than one lock active at a time. A user's total "lock weight"
             is calculated as the sum of [number of tokens] * [weeks until unlock] for all
             active locks. Fees are distributed porportionally according to a user's lock
             weight as a percentage of the total lock weight. At the start of each new week,
             each lock's weeks until unlock is reduced by 1. Locks that reach 0 week no longer
             receive any weight, and PACT may be withdrawn by calling `initiateExitStream`.
        @param _user Address to create a new lock for (does not have to be the caller)
        @param _amount Amount of PACT to lock. This balance transfered from the caller.
        @param _weeks The number of weeks for the lock.
     */
    function lock(
        address _user,
        uint256 _amount,
        uint256 _weeks
    ) external returns (bool) {
        require(_weeks > 0, "Min 1 week");
        require(_weeks < 53, "Max 52 weeks");
        require(_amount > 0, "Amount must be nonzero");

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 start = getWeek();
        _increaseAmount(weeklyTotalWeight, start, _amount, _weeks, 0);
        _increaseAmount(weeklyWeightOf[_user], start, _amount, _weeks, 0);

        uint256 end = start.add(_weeks);
        weeklyUnlocksOf[_user][end] = weeklyUnlocksOf[_user][end].add(_amount);

        emit NewLock(_user, _amount, _weeks);
        return true;
    }

    /**
        @notice Extend the length of an existing PACT lock.
        @param _amount Amount of PACT to extend the lock for. When the value given is equal
                       to the total size of the existing lock, the entire lock is moved. If
                       the amount is less, then the lock is effectively split into two locks,
                       with a portion of the balance extended to the new length and the
                       remaining balance at the old length.
        @param _weeks The number of weeks for the lock that is being extended.
        @param _newWeeks The number of weeks to extend the lock until.
     */
    function extendLock(
        uint256 _amount,
        uint256 _weeks,
        uint256 _newWeeks
    ) external returns (bool) {
        require(_weeks > 0, "Min 1 week");
        require(_newWeeks < 53, "Max 52 weeks");
        require(_weeks < _newWeeks, "newWeeks must be greater than weeks");
        require(_amount > 0, "Amount must be nonzero");

        uint256[9362] storage unlocks = weeklyUnlocksOf[msg.sender];
        uint256 start = getWeek();
        uint256 end = start.add(_weeks);
        unlocks[end] = unlocks[end].sub(_amount);
        end = start.add(_newWeeks);
        unlocks[end] = unlocks[end].add(_amount);

        _increaseAmount(weeklyTotalWeight, start, _amount, _newWeeks, _weeks);
        _increaseAmount(
            weeklyWeightOf[msg.sender],
            start,
            _amount,
            _newWeeks,
            _weeks
        );

        emit ExtendLock(msg.sender, _amount, _weeks, _newWeeks);
        return true;
    }

    /**
        @notice Create an exit stream, to withdraw expired PACT locks over 1 week
     */
    function initiateExitStream() external returns (bool) {
        StreamData storage stream = exitStream[msg.sender];
        uint256 streamable = streamableBalance(msg.sender);
        require(streamable > 0, "No withdrawable balance");

        uint256 amount = stream.amount.sub(stream.claimed).add(streamable);
        exitStream[msg.sender] = StreamData({
            start: block.timestamp,
            amount: amount,
            claimed: 0
        });
        withdrawnUntil[msg.sender] = getWeek();

        emit NewExitStream(msg.sender, block.timestamp, amount);
        return true;
    }

    /**
        @notice Withdraw PACT from an active or completed exit stream
     */
    function withdrawExitStream() external returns (bool) {
        StreamData storage stream = exitStream[msg.sender];
        uint256 amount;
        if (stream.start > 0) {
            amount = claimableExitStreamBalance(msg.sender);
            if (stream.start.add(WEEK) < block.timestamp) {
                delete exitStream[msg.sender];
            } else {
                stream.claimed = stream.claimed.add(amount);
            }
            stakingToken.safeTransfer(msg.sender, amount);
        }
        emit ExitStreamWithdrawal(
            msg.sender,
            amount,
            stream.amount.sub(stream.claimed)
        );
        return true;
    }

    /**
        @notice Get the amount of PACT in expired locks that is
                eligible to be released via an exit stream.
     */
    function streamableBalance(address _user) public view returns (uint256) {
        uint256 finishedWeek = getWeek();

        uint256[9362] storage unlocks = weeklyUnlocksOf[_user];
        uint256 amount;

        for (
            uint256 last = withdrawnUntil[_user] + 1;
            last <= finishedWeek;
            last++
        ) {
            amount = amount.add(unlocks[last]);
        }
        return amount;
    }

    /**
        @notice Get the amount of PACT available to withdraw from the active exit stream.
     */
    function claimableExitStreamBalance(address _user)
        public
        view
        returns (uint256)
    {
        StreamData storage stream = exitStream[msg.sender];
        if (stream.start == 0) return 0;
        if (stream.start.add(WEEK) < block.timestamp) {
            return stream.amount.sub(stream.claimed);
        } else {
            uint256 claimable = stream.amount.mul(
                block.timestamp.sub(stream.start)
            ) / WEEK;
            return claimable.sub(stream.claimed);
        }
    }

    // ===== futurePACT / rewardPACT =====

    /**
        @notice Deposit PACT to mint futurePACT or rewardPACT
        @dev Lock token contracts can be initially deployed by calling to mint 0 tokens
        @param _user Address to receive the newly minted tokens
        @param _amount Amount of PACT to deposit. lock tokens are minted 1:1 with deposited PACT.
        @param _weeks Number of weeks for the lock created when the lock tokens are deposited.
                      Must be a multiple of 4, ranging from 8 to 52.
        @param _penalty Set true to mint rewardPACT, false for futurePACT
        @return address of minted future lock token
     */
    function mintLockTokens(
        address _user,
        uint256 _amount,
        uint256 _weeks,
        bool _penalty
    ) external returns (FutureLockToken) {
        require(_weeks > 7 && _weeks < 53 && _weeks % 4 == 0, "Invalid weeks");
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 idx = (_weeks / 4).sub(2);
        FutureLockToken[12] storage tokenArray = _penalty
            ? rewardPactTokens
            : futurePactTokens;
        FutureLockToken token = tokenArray[idx];
        if (token == FutureLockToken(0)) {
            token = new FutureLockToken(_weeks, _penalty);
            tokenArray[idx] = token;
        }
        token.mint(_user, _amount);

        emit MintedLockTokens(msg.sender, _user, _amount, _weeks, _penalty);
        return token;
    }

    /**
        @notice Deposit futurePACT or rewardPACT to create a new lock
        @param _user Address to receive the newly minted tokens
        @param _amount Amount of lock tokens to deposit. Tokens are redeemed 1:1 for locked PACT.
        @param _weeks Number of weeks for the new lock. Indicates which lock token is used.
        @param _penalty if true, uses rewardPACT. if false, futurePACT.
     */
    function depositLockTokens(
        address _user,
        uint256 _amount,
        uint256 _weeks,
        bool _penalty
    ) external returns (bool) {
        require(_weeks > 7 && _weeks < 53 && _weeks % 4 == 0, "Invalid weeks");
        require(_amount > 0, "Cannot deposit zero");
        uint256 idx = (_weeks / 4).sub(2);
        FutureLockToken token = _penalty
            ? rewardPactTokens[idx]
            : futurePactTokens[idx];
        require(token != FutureLockToken(0), "Token does not exist");
        token.burn(msg.sender, _amount);

        uint256 start = getWeek();
        _increaseAmount(weeklyTotalWeight, start, _amount, _weeks, 0);
        _increaseAmount(weeklyWeightOf[_user], start, _amount, _weeks, 0);

        uint256 end = start.add(_weeks);
        weeklyUnlocksOf[_user][end] = weeklyUnlocksOf[_user][end].add(_amount);

        emit RedeemedLockTokens(msg.sender, _user, _amount, _weeks, _penalty);
        emit NewLock(_user, _amount, _weeks);
        return true;
    }

    /**
        @notice Deposit rewardPACT, paying a fee to receive PACT without locking.
        @dev The amount of PACT received ranges from 25% to 75% of the rewardPACT deposited,
             with the amount linearly decreasing based on the number of weeks of the lock.
             rewardPACT taken as a fee is converted to futurePACT and distributed to PACT lockers.
        @param _user Address to receive the unlocked PACT.
        @param _amount Amount of lock tokens to deposit.
        @param _weeks Number of weeks for the new lock. Indicates which lock token is used.
     */
    function unlockRewardTokens(
        address _user,
        uint256 _amount,
        uint256 _weeks
    ) external returns (bool) {
        require(_weeks > 7 && _weeks < 53 && _weeks % 4 == 0, "Invalid weeks");
        require(_amount > 0, "Cannot deposit zero");
        uint256 idx = (_weeks / 4).sub(2);
        FutureLockToken token = rewardPactTokens[idx];
        require(token != FutureLockToken(0), "Token does not exist");
        token.burn(msg.sender, _amount);

        // penalty increases linearly from 25% to 75% based on number of weeks locked
        uint256 received = _amount.mul(3) /
            4 -
            ((_amount / 2).mul(_weeks.sub(8)) / 44);
        uint256 penalty = _amount.sub(received);
        stakingToken.safeTransfer(_user, received);

        token = futurePactTokens[idx];
        if (token == FutureLockToken(0)) {
            token = new FutureLockToken(_weeks, false);
            futurePactTokens[idx] = token;
        }
        token.mint(address(this), penalty);

        if (!seenFees[address(token)]) {
            seenFees[address(token)] = true;
            feeTokens.push(address(token));
        }

        uint256 week = getWeek();
        weeklyFeeAmounts[address(token)][week] = weeklyFeeAmounts[
            address(token)
        ][week].add(penalty);

        emit RedeemedLockTokensWithPenalty(
            msg.sender,
            _user,
            _amount,
            _weeks,
            received,
            penalty
        );
        return true;
    }

    // ===== PROTOCOL FEES =====

    /**
        @notice Deposit protocol fees into the contract, to be distributed to PACT lockers
        @dev Called by `CompactPair` deployments each time a fee is collected
        @param _token Token being deposited
        @param _amount Amount of the token to deposit
     */
    function depositFee(address _token, uint256 _amount)
        external
        returns (bool)
    {
        if (_amount > 0) {
            if (!seenFees[_token]) {
                seenFees[_token] = true;
                feeTokens.push(_token);
            }
            uint256 received = IERC20(_token).balanceOf(address(this));
            _token.safeTransferFrom(msg.sender, address(this), _amount);
            received = IERC20(_token).balanceOf(address(this)).sub(received);
            uint256 week = getWeek();
            weeklyFeeAmounts[_token][week] = weeklyFeeAmounts[_token][week].add(
                received
            );
            emit FeesReceived(msg.sender, _token, week, _amount);
        }
        return true;
    }

    /**
        @notice Get an array of claimable amounts of different tokens accrued from protocol fees
        @param _user Address to query claimable amounts for
        @param _tokens List of tokens to query claimable amounts of
     */
    function claimable(address _user, address[] calldata _tokens)
        external
        view
        returns (uint256[] memory amounts)
    {
        amounts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            (amounts[i], ) = _getClaimable(_user, _tokens[i]);
        }
        return amounts;
    }

    /**
        @notice Claim accrued protocol fees that were received from locking PACT.
        @dev Fees are claimable up to the end of the previous week. Claimable fees from more
             than one week ago are released immediately, fees from the previous week are streamed.
        @param _user Address to claim for. Any account can trigger a claim for any other account.
        @param _tokens Array of tokens to claim for.
        @return claimedAmounts Array of amounts claimed.
     */
    function claim(address _user, address[] calldata _tokens)
        external
        returns (uint256[] memory claimedAmounts)
    {
        claimedAmounts = new uint256[](_tokens.length);
        StreamData memory stream;
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            (claimedAmounts[i], stream) = _getClaimable(_user, token);
            activeUserStream[_user][token] = stream;
            token.safeTransfer(_user, claimedAmounts[i]);
            emit FeesClaimed(msg.sender, _user, token, claimedAmounts[i]);
        }
        return claimedAmounts;
    }

    // ===== INTERNAL FUNCTIONS =====

    /**
        @dev Increase the amount within a lock weight array over a given time period
     */
    function _increaseAmount(
        uint256[9362] storage _record,
        uint256 _start,
        uint256 _amount,
        uint256 _rounds,
        uint256 _oldRounds
    ) internal {
        uint256 oldEnd = _start.add(_oldRounds);
        uint256 end = _start.add(_rounds);
        for (uint256 i = _start; i < end; i++) {
            uint256 amount = _amount.mul(end.sub(i));
            if (i < oldEnd) {
                amount = amount.sub(_amount.mul(oldEnd.sub(i)));
            }
            _record[i] = _record[i].add(amount);
        }
    }

    function _getClaimable(address _user, address _token)
        internal
        view
        returns (uint256, StreamData memory)
    {
        uint256 claimableWeek = getWeek();

        if (claimableWeek == 0) {
            // the first full week hasn't completed yet
            return (0, StreamData({start: startTime, amount: 0, claimed: 0}));
        }

        // the previous week is the claimable one
        claimableWeek -= 1;
        StreamData memory stream = activeUserStream[_user][_token];
        uint256 lastClaimWeek;
        if (stream.start == 0) {
            lastClaimWeek = 0;
        } else {
            lastClaimWeek = (stream.start - startTime) / WEEK;
        }

        uint256 amount;
        if (claimableWeek == lastClaimWeek) {
            // special case: claim is happening in the same week as a previous claim
            uint256 previouslyClaimed = stream.claimed;
            stream = _buildStreamData(_user, _token, claimableWeek);
            amount = stream.claimed.sub(previouslyClaimed);
            return (amount, stream);
        }

        if (stream.start > 0) {
            // if there is a partially claimed week, get the unclaimed amount and increment
            // `lastClaimWeeek` so we begin iteration on the following week
            amount = stream.amount.sub(stream.claimed);
            lastClaimWeek += 1;
        }

        // iterate over weeks that have passed fully without any claims
        for (uint256 i = lastClaimWeek; i < claimableWeek; i++) {
            uint256 lockBalance = weeklyWeightOf[_user][i];
            if (lockBalance == 0) continue;
            amount = amount.add(
                weeklyFeeAmounts[_token][i].mul(lockBalance) /
                    weeklyTotalWeight[i]
            );
        }

        // add a partial amount for the active week
        stream = _buildStreamData(_user, _token, claimableWeek);

        return (amount.add(stream.claimed), stream);
    }

    function _buildStreamData(
        address _user,
        address _token,
        uint256 _week
    ) internal view returns (StreamData memory) {
        uint256 start = startTime.add(_week.mul(WEEK));
        uint256 amount = weeklyFeeAmounts[_token][_week].mul(
            weeklyWeightOf[_user][_week]
        ) / weeklyTotalWeight[_week];
        uint256 claimed = amount.mul(block.timestamp - 604800 - start) / WEEK;
        return StreamData({start: start, amount: amount, claimed: claimed});
    }
}