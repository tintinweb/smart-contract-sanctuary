// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "../interfaces/IERC20.sol";
import "../libraries/History.sol";
import "../libraries/VestingVaultStorage.sol";
import "../libraries/Storage.sol";
import "../interfaces/IVotingVault.sol";

contract VestingVault is IVotingVault {
    // Bring our libraries into scope
    using History for *;
    using VestingVaultStorage for *;
    using Storage for *;

    // NOTE: There is no emergency withdrawal, any funds not sent via deposit() are
    // unrecoverable by this version of the VestingVault

    // This contract has a privileged grant manager who can add grants or remove grants
    // It will not transfer in on each grant but rather check for solvency via state variables.

    // Immutables are in bytecode so don't need special storage treatment
    IERC20 public immutable token;

    // A constant which is how far back stale blocks are
    uint256 public immutable staleBlockLag;

    event VoteChange(address indexed to, address indexed from, int256 amount);

    /// @notice Constructs the contract.
    /// @param _token The erc20 token to grant.
    /// @param _stale Stale block used for voting power calculations.
    constructor(IERC20 _token, uint256 _stale) {
        token = _token;
        staleBlockLag = _stale;
    }

    /// @notice initialization function to set initial variables.
    /// @dev Can only be called once after deployment.
    /// @param manager_ The vault manager can add and remove grants.
    /// @param timelock_ The timelock address can change the unvested multiplier.
    function initialize(address manager_, address timelock_) public {
        require(Storage.uint256Ptr("initialized").data == 0, "initialized");
        Storage.set(Storage.uint256Ptr("initialized"), 1);
        Storage.set(Storage.addressPtr("manager"), manager_);
        Storage.set(Storage.addressPtr("timelock"), timelock_);
        Storage.set(Storage.uint256Ptr("unvestedMultiplier"), 100);
    }

    // deposits mapping(address => Grant)
    /// @notice A single function endpoint for loading grant storage
    /// @dev Only one Grant is allowed per address. Grants SHOULD NOT
    /// be modified.
    /// @return returns a storage mapping which can be used to look up grant data
    function _grants()
        internal
        pure
        returns (mapping(address => VestingVaultStorage.Grant) storage)
    {
        // This call returns a storage mapping with a unique non overwrite-able storage location
        // which can be persisted through upgrades, even if they change storage layout
        return (VestingVaultStorage.mappingAddressToGrantPtr("grants"));
    }

    /// @notice A single function endpoint for loading the starting
    /// point of the range for each accepted grant
    /// @dev This is modified any time a grant is accepted
    /// @return returns the starting point uint
    function _loadBound() internal pure returns (Storage.Uint256 memory) {
        // This call returns a storage mapping with a unique non overwrite-able storage location
        // which can be persisted through upgrades, even if they change storage layout
        return Storage.uint256Ptr("bound");
    }

    /// @notice A function to access the storage of the unassigned token value
    /// @dev The unassigned tokens are not part of any grant and ca be used
    /// for a future grant or withdrawn by the manager.
    /// @return A struct containing the unassigned uint.
    function _unassigned() internal pure returns (Storage.Uint256 storage) {
        return Storage.uint256Ptr("unassigned");
    }

    /// @notice A function to access the storage of the manager address.
    /// @dev The manager can access all functions with the onlyManager modifier.
    /// @return A struct containing the manager address.
    function _manager() internal pure returns (Storage.Address memory) {
        return Storage.addressPtr("manager");
    }

    /// @notice A function to access the storage of the timelock address
    /// @dev The timelock can access all functions with the onlyTimelock modifier.
    /// @return A struct containing the timelock address.
    function _timelock() internal pure returns (Storage.Address memory) {
        return Storage.addressPtr("timelock");
    }

    /// @notice A function to access the storage of the unvestedMultiplier value
    /// @dev The unvested multiplier is a number that represents the voting power of each
    /// unvested token as a percentage of a vested token. For example if
    /// unvested tokens have 50% voting power compared to vested ones, this value would be 50.
    /// This can be changed by governance in the future.
    /// @return A struct containing the unvestedMultiplier uint.
    function _unvestedMultiplier()
        internal
        pure
        returns (Storage.Uint256 memory)
    {
        return Storage.uint256Ptr("unvestedMultiplier");
    }

    modifier onlyManager() {
        require(msg.sender == _manager().data, "!manager");
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == _timelock().data, "!timelock");
        _;
    }

    /// @notice Getter for the grants mapping
    /// @param _who The owner of the grant to query
    /// @return Grant of the provided address
    function getGrant(address _who)
        external
        view
        returns (VestingVaultStorage.Grant memory)
    {
        return _grants()[_who];
    }

    /// @notice Accepts a grant
    /// @dev Sends token from the contract to the sender and back to the contract
    /// while assigning a numerical range to the unwithdrawn granted tokens.
    function acceptGrant() public {
        // load the grant
        VestingVaultStorage.Grant storage grant = _grants()[msg.sender];
        uint256 availableTokens = grant.allocation - grant.withdrawn;

        // check that grant has unwithdrawn tokens
        require(availableTokens > 0, "no grant available");

        // transfer the token to the user
        token.transfer(msg.sender, availableTokens);
        // transfer from the user back to the contract
        token.transferFrom(msg.sender, address(this), availableTokens);

        uint256 bound = _loadBound().data;
        grant.range = [bound, bound + availableTokens];
        Storage.set(Storage.uint256Ptr("bound"), bound + availableTokens);
    }

    /// @notice Adds a new grant.
    /// @dev Manager can set who the voting power will be delegated to initially.
    /// This potentially avoids the need for a delegation transaction by the grant recipient.
    /// @param _who The Grant recipient.
    /// @param _amount The total grant value.
    /// @param _startTime Optionally set a non standard start time. If set to zero then the start time
    ///                   will be made the block this is executed in.
    /// @param _expiration timestamp when the grant ends (all tokens count as unlocked).
    /// @param _cliff Timestamp when the cliff ends. No tokens are unlocked until this
    /// timestamp is reached.
    /// @param _delegatee Optional param. The address to delegate the voting power
    /// associated with this grant to
    function addGrantAndDelegate(
        address _who,
        uint128 _amount,
        uint128 _startTime,
        uint128 _expiration,
        uint128 _cliff,
        address _delegatee
    ) public onlyManager {
        // Consistency check
        require(
            _cliff <= _expiration && _startTime <= _expiration,
            "Invalid configuration"
        );
        // If no custom start time is needed we use this block.
        if (_startTime == 0) {
            _startTime = uint128(block.number);
        }

        Storage.Uint256 storage unassigned = _unassigned();
        Storage.Uint256 memory unvestedMultiplier = _unvestedMultiplier();

        require(unassigned.data >= _amount, "Insufficient balance");
        // load the grant.
        VestingVaultStorage.Grant storage grant = _grants()[_who];

        // If this address already has a grant, a different address must be provided
        // topping up or editing active grants is not supported.
        require(grant.allocation == 0, "Has Grant");

        // load the delegate. Defaults to the grant owner
        _delegatee = _delegatee == address(0) ? _who : _delegatee;

        // calculate the voting power. Assumes all voting power is initially locked.
        // Come back to this assumption.
        uint128 newVotingPower =
            (_amount * uint128(unvestedMultiplier.data)) / 100;

        // set the new grant
        _grants()[_who] = VestingVaultStorage.Grant(
            _amount,
            0,
            _startTime,
            _expiration,
            _cliff,
            newVotingPower,
            _delegatee,
            [uint256(0), uint256(0)]
        );

        // update the amount of unassigned tokens
        unassigned.data -= _amount;

        // update the delegatee's voting power
        History.HistoricalBalances memory votingPower = _votingPower();
        uint256 delegateeVotes = votingPower.loadTop(grant.delegatee);
        votingPower.push(grant.delegatee, delegateeVotes + newVotingPower);

        emit VoteChange(grant.delegatee, _who, int256(uint256(newVotingPower)));
    }

    /// @notice Removes a grant.
    /// @dev The manager has the power to remove a grant at any time. Any withdrawable tokens will be
    /// sent to the grant owner.
    /// @param _who The Grant owner.
    function removeGrant(address _who) public onlyManager {
        // load the grant
        VestingVaultStorage.Grant storage grant = _grants()[_who];
        // get the amount of withdrawable tokens
        uint256 withdrawable = _getWithdrawableAmount(grant);
        // it is simpler to just transfer withdrawable tokens instead of modifying the struct storage
        // to allow withdrawal through claim()
        token.transfer(_who, withdrawable);

        Storage.Uint256 storage unassigned = _unassigned();
        uint256 locked = grant.allocation - (grant.withdrawn + withdrawable);

        // return the unused tokens so they can be used for a different grant
        unassigned.data += locked;

        // update the delegatee's voting power
        History.HistoricalBalances memory votingPower = _votingPower();
        uint256 delegateeVotes = votingPower.loadTop(grant.delegatee);
        votingPower.push(
            grant.delegatee,
            delegateeVotes - grant.latestVotingPower
        );

        // Emit the vote change event
        emit VoteChange(
            grant.delegatee,
            _who,
            -1 * int256(uint256(grant.latestVotingPower))
        );

        // delete the grant
        delete _grants()[_who];
    }

    /// @notice Claim all withdrawable value from a grant.
    /// @dev claiming value resets the voting power, This could either increase or reduce the
    /// total voting power associated with the caller's grant.
    function claim() public {
        // load the grant
        VestingVaultStorage.Grant storage grant = _grants()[msg.sender];
        // get the withdrawable amount
        uint256 withdrawable = _getWithdrawableAmount(grant);

        // transfer the available amount
        token.transfer(msg.sender, withdrawable);
        grant.withdrawn += uint128(withdrawable);

        // only move range bound if grant was accepted
        if (grant.range[1] > 0) {
            grant.range[1] -= withdrawable;
        }

        // update the user's voting power
        _syncVotingPower(msg.sender, grant);
    }

    /// @notice Changes the caller's token grant voting power delegation.
    /// @dev The total voting power is not guaranteed to go up because
    /// the unvested token multiplier can be updated at any time.
    /// @param _to the address to delegate to
    function delegate(address _to) public {
        VestingVaultStorage.Grant storage grant = _grants()[msg.sender];
        // If the delegation has already happened we don't want the tx to send
        require(_to != grant.delegatee, "Already delegated");
        History.HistoricalBalances memory votingPower = _votingPower();

        uint256 oldDelegateeVotes = votingPower.loadTop(grant.delegatee);
        uint256 newVotingPower = _currentVotingPower(grant);

        // Remove old delegatee's voting power and emit event
        votingPower.push(
            grant.delegatee,
            oldDelegateeVotes - grant.latestVotingPower
        );
        emit VoteChange(
            grant.delegatee,
            msg.sender,
            -1 * int256(uint256(grant.latestVotingPower))
        );

        // Note - It is important that this is loaded here and not before the previous state change because if
        // _to == grant.delegatee and re-delegation was allowed we could be working with out of date state.
        uint256 newDelegateeVotes = votingPower.loadTop(_to);

        // add voting power to the target delegatee and emit event
        emit VoteChange(_to, msg.sender, int256(newVotingPower));
        votingPower.push(_to, newDelegateeVotes + newVotingPower);

        // update grant info
        grant.latestVotingPower = uint128(newVotingPower);
        grant.delegatee = _to;
    }

    /// @notice Manager-only token deposit function.
    /// @dev Deposited tokens are added to `_unassigned` and can be used to create grants.
    /// WARNING: This is the only way to deposit tokens into the contract. Any tokens sent
    /// via other means are not recoverable by this contract.
    /// @param _amount The amount of tokens to deposit.
    function deposit(uint256 _amount) public onlyManager {
        Storage.Uint256 storage unassigned = _unassigned();
        // update unassigned value
        unassigned.data += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
    }

    /// @notice Manager-only token withdrawal function.
    /// @dev The manager can withdraw tokens that are not being used by a grant.
    /// This function cannot be used to recover tokens that were sent to this contract
    /// by any means other than `deposit()`
    /// @param _amount the amount to withdraw
    /// @param _recipient the address to withdraw to
    function withdraw(uint256 _amount, address _recipient) public onlyManager {
        Storage.Uint256 storage unassigned = _unassigned();
        require(unassigned.data >= _amount, "Insufficient balance");
        // update unassigned value
        unassigned.data -= _amount;
        token.transfer(_recipient, _amount);
    }

    /// @notice Update a delegatee's voting power.
    /// @dev Voting power is only updated for this block onward.
    /// see `History` for more on how voting power is tracked and queried.
    /// Anybody can update a grant's voting power.
    /// @param _who the address who's voting power this function updates
    function updateVotingPower(address _who) public {
        VestingVaultStorage.Grant storage grant = _grants()[_who];
        _syncVotingPower(_who, grant);
    }

    /// @notice Helper to update a delegatee's voting power.
    /// @param _who the address who's voting power we need to sync
    /// @param _grant the storage pointer to the grant of that user
    function _syncVotingPower(
        address _who,
        VestingVaultStorage.Grant storage _grant
    ) internal {
        History.HistoricalBalances memory votingPower = _votingPower();

        uint256 delegateeVotes = votingPower.loadTop(_grant.delegatee);

        uint256 newVotingPower = _currentVotingPower(_grant);
        // get the change in voting power. Negative if the voting power is reduced
        int256 change =
            int256(newVotingPower) - int256(uint256(_grant.latestVotingPower));
        // do nothing if there is no change
        if (change == 0) return;
        if (change > 0) {
            votingPower.push(
                _grant.delegatee,
                delegateeVotes + uint256(change)
            );
        } else {
            // if the change is negative, we multiply by -1 to avoid underflow when casting
            votingPower.push(
                _grant.delegatee,
                delegateeVotes - uint256(change * -1)
            );
        }
        emit VoteChange(_grant.delegatee, _who, change);
        _grant.latestVotingPower = uint128(newVotingPower);
    }

    /// @notice Attempts to load the voting power of a user
    /// @param user The address we want to load the voting power of
    /// @param blockNumber the block number we want the user's voting power at
    // @param calldata the extra calldata is unused in this contract
    /// @return the number of votes
    function queryVotePower(
        address user,
        uint256 blockNumber,
        bytes calldata
    ) external override returns (uint256) {
        // Get our reference to historical data
        History.HistoricalBalances memory votingPower = _votingPower();
        // Find the historical data and clear everything more than 'staleBlockLag' into the past
        return
            votingPower.findAndClear(
                user,
                blockNumber,
                block.number - staleBlockLag
            );
    }

    /// @notice Loads the voting power of a user without changing state
    /// @param user The address we want to load the voting power of
    /// @param blockNumber the block number we want the user's voting power at
    /// @return the number of votes
    function queryVotePowerView(address user, uint256 blockNumber)
        external
        view
        returns (uint256)
    {
        // Get our reference to historical data
        History.HistoricalBalances memory votingPower = _votingPower();
        // Find the historical data
        return votingPower.find(user, blockNumber);
    }

    /// @notice Calculates how much a grantee can withdraw
    /// @param _grant the memory location of the loaded grant
    /// @return the amount which can be withdrawn
    function _getWithdrawableAmount(VestingVaultStorage.Grant memory _grant)
        internal
        view
        returns (uint256)
    {
        if (block.number < _grant.cliff || block.number < _grant.created) {
            return 0;
        }
        if (block.number >= _grant.expiration) {
            return (_grant.allocation - _grant.withdrawn);
        }
        uint256 unlocked =
            (_grant.allocation * (block.number - _grant.created)) /
                (_grant.expiration - _grant.created);
        return (unlocked - _grant.withdrawn);
    }

    /// @notice Returns the historical voting power tracker.
    /// @return A struct which can push to and find items in block indexed storage.
    function _votingPower()
        internal
        pure
        returns (History.HistoricalBalances memory)
    {
        // This call returns a storage mapping with a unique non overwrite-able storage location
        // which can be persisted through upgrades, even if they change storage layout.
        return (History.load("votingPower"));
    }

    /// @notice Helper that returns the current voting power of a grant
    /// @dev This is not always the recorded voting power since it uses the latest
    /// _unvestedMultiplier.
    /// @param _grant The grant to check for voting power.
    /// @return The current voting power of the grant.
    function _currentVotingPower(VestingVaultStorage.Grant memory _grant)
        internal
        view
        returns (uint256)
    {
        uint256 withdrawable = _getWithdrawableAmount(_grant);
        uint256 locked = _grant.allocation - (withdrawable + _grant.withdrawn);
        return (withdrawable + (locked * _unvestedMultiplier().data) / 100);
    }

    /// @notice timelock-only unvestedMultiplier update function.
    /// @dev Allows the timelock to update the unvestedMultiplier.
    /// @param _multiplier The new multiplier.
    function changeUnvestedMultiplier(uint256 _multiplier) public onlyTimelock {
        require(_multiplier <= 100, "Above 100%");
        Storage.set(Storage.uint256Ptr("unvestedMultiplier"), _multiplier);
    }

    /// @notice timelock-only timelock update function.
    /// @dev Allows the timelock to update the timelock address.
    /// @param timelock_ The new timelock.
    function setTimelock(address timelock_) public onlyTimelock {
        Storage.set(Storage.addressPtr("timelock"), timelock_);
    }

    /// @notice timelock-only manager update function.
    /// @dev Allows the timelock to update the manager address.
    /// @param manager_ The new manager.
    function setManager(address manager_) public onlyTimelock {
        Storage.set(Storage.addressPtr("manager"), manager_);
    }

    /// @notice A function to access the storage of the timelock address
    /// @dev The timelock can access all functions with the onlyTimelock modifier.
    /// @return The timelock address.
    function timelock() public pure returns (address) {
        return _timelock().data;
    }

    /// @notice A function to access the storage of the unvested token vote power multiplier.
    /// @return The unvested token multiplier
    function unvestedMultiplier() external pure returns (uint256) {
        return _unvestedMultiplier().data;
    }

    /// @notice A function to access the storage of the manager address.
    /// @dev The manager can access all functions with the olyManager modifier.
    /// @return The manager address.
    function manager() public pure returns (address) {
        return _manager().data;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

interface IERC20 {
    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    // Note this is non standard but nearly all ERC20 have exposed decimal functions
    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "./Storage.sol";

// This library is an assembly optimized storage library which is designed
// to track timestamp history in a struct which uses hash derived pointers.
// WARNING - Developers using it should not access the underlying storage
// directly since we break some assumptions of high level solidity. Please
// note this library also increases the risk profile of memory manipulation
// please be cautious in your usage of uninitialized memory structs and other
// anti patterns.
library History {
    // The storage layout of the historical array looks like this
    // [(128 bit min index)(128 bit length)] [0][0] ... [(64 bit block num)(192 bit data)] .... [(64 bit block num)(192 bit data)]
    // We give the option to the invoker of the search function the ability to clear
    // stale storage. To find data we binary search for the block number we need
    // This library expects the blocknumber indexed data to be pushed in ascending block number
    // order and if data is pushed with the same blocknumber it only retains the most recent.
    // This ensures each blocknumber is unique and contains the most recent data at the end
    // of whatever block it indexes [as long as that block is not the current one].

    // A struct which wraps a memory pointer to a string and the pointer to storage
    // derived from that name string by the storage library
    // WARNING - For security purposes never directly construct this object always use load
    struct HistoricalBalances {
        string name;
        // Note - We use bytes32 to reduce how easy this is to manipulate in high level sol
        bytes32 cachedPointer;
    }

    /// @notice The method by which inheriting contracts init the HistoricalBalances struct
    /// @param name The name of the variable. Note - these are globals, any invocations of this
    ///             with the same name work on the same storage.
    /// @return The memory pointer to the wrapper of the storage pointer
    function load(string memory name)
        internal
        pure
        returns (HistoricalBalances memory)
    {
        mapping(address => uint256[]) storage storageData =
            Storage.mappingAddressToUnit256ArrayPtr(name);
        bytes32 pointer;
        assembly {
            pointer := storageData.slot
        }
        return HistoricalBalances(name, pointer);
    }

    /// @notice An unsafe method of attaching the cached ptr in a historical balance memory objects
    /// @param pointer cached pointer to storage
    /// @return storageData A storage array mapping pointer
    /// @dev PLEASE DO NOT USE THIS METHOD WITHOUT SERIOUS REVIEW. IF AN EXTERNAL ACTOR CAN CALL THIS WITH
    //       ARBITRARY DATA THEY MAY BE ABLE TO OVERWRITE ANY STORAGE IN THE CONTRACT.
    function _getMapping(bytes32 pointer)
        private
        pure
        returns (mapping(address => uint256[]) storage storageData)
    {
        assembly {
            storageData.slot := pointer
        }
    }

    /// @notice This function adds a block stamp indexed piece of data to a historical data array
    ///         To prevent duplicate entries if the top of the array has the same blocknumber
    ///         the value is updated instead
    /// @param wrapper The wrapper which hold the reference to the historical data storage pointer
    /// @param who The address which indexes the array we need to push to
    /// @param data The data to append, should be at most 192 bits and will revert if not
    function push(
        HistoricalBalances memory wrapper,
        address who,
        uint256 data
    ) internal {
        // Check preconditions
        // OoB = Out of Bounds, short for contract bytecode size reduction
        require(data <= type(uint192).max, "OoB");
        // Get the storage this is referencing
        mapping(address => uint256[]) storage storageMapping =
            _getMapping(wrapper.cachedPointer);
        // Get the array we need to push to
        uint256[] storage storageData = storageMapping[who];
        // We load the block number and then shift it to be in the top 64 bits
        uint256 blockNumber = block.number << 192;
        // We combine it with the data, because of our require this will have a clean
        // top 64 bits
        uint256 packedData = blockNumber | data;
        // Load the array length
        (uint256 minIndex, uint256 length) = _loadBounds(storageData);
        // On the first push we don't try to load
        uint256 loadedBlockNumber = 0;
        if (length != 0) {
            (loadedBlockNumber, ) = _loadAndUnpack(storageData, length - 1);
        }
        // The index we push to, note - we use this pattern to not branch the assembly
        uint256 index = length;
        // If the caller is changing data in the same block we change the entry for this block
        // instead of adding a new one. This ensures each block numb is unique in the array.
        if (loadedBlockNumber == block.number) {
            index = length - 1;
        }
        // We use assembly to write our data to the index
        assembly {
            // Stores packed data in the equivalent of storageData[length]
            sstore(
                add(
                    // The start of the data slots
                    add(storageData.slot, 1),
                    // index where we store
                    index
                ),
                packedData
            )
        }
        // Reset the boundaries if they changed
        if (loadedBlockNumber != block.number) {
            _setBounds(storageData, minIndex, length + 1);
        }
    }

    /// @notice Loads the most recent timestamp of delegation power
    /// @param wrapper The memory struct which we want to search for historical data
    /// @param who The user who's balance we want to load
    /// @return the top slot of the array
    function loadTop(HistoricalBalances memory wrapper, address who)
        internal
        view
        returns (uint256)
    {
        // Load the storage pointer
        uint256[] storage userData = _getMapping(wrapper.cachedPointer)[who];
        // Load the length
        (, uint256 length) = _loadBounds(userData);
        // If it's zero no data has ever been pushed so we return zero
        if (length == 0) {
            return 0;
        }
        // Load the current top
        (, uint256 storedData) = _loadAndUnpack(userData, length - 1);
        // and return it
        return (storedData);
    }

    /// @notice Finds the data stored with the highest block number which is less than or equal to a provided
    ///         blocknumber.
    /// @param wrapper The memory struct which we want to search for historical data
    /// @param who The address which indexes the array to be searched
    /// @param blocknumber The blocknumber we want to load the historical data of
    /// @return The loaded unpacked data at this point in time.
    function find(
        HistoricalBalances memory wrapper,
        address who,
        uint256 blocknumber
    ) internal view returns (uint256) {
        // Get the storage this is referencing
        mapping(address => uint256[]) storage storageMapping =
            _getMapping(wrapper.cachedPointer);
        // Get the array we need to push to
        uint256[] storage storageData = storageMapping[who];
        // Pre load the bounds
        (uint256 minIndex, uint256 length) = _loadBounds(storageData);
        // Search for the blocknumber
        (, uint256 loadedData) =
            _find(storageData, blocknumber, 0, minIndex, length);
        // In this function we don't have to change the stored length data
        return (loadedData);
    }

    /// @notice Finds the data stored with the highest blocknumber which is less than or equal to a provided block number
    ///         Opportunistically clears any data older than staleBlock which is possible to clear.
    /// @param wrapper The memory struct which points to the storage we want to search
    /// @param who The address which indexes the historical data we want to search
    /// @param blocknumber The blocknumber we want to load the historical state of
    /// @param staleBlock A block number which we can [but are not obligated to] delete history older than
    /// @return The found data
    function findAndClear(
        HistoricalBalances memory wrapper,
        address who,
        uint256 blocknumber,
        uint256 staleBlock
    ) internal returns (uint256) {
        // Get the storage this is referencing
        mapping(address => uint256[]) storage storageMapping =
            _getMapping(wrapper.cachedPointer);
        // Get the array we need to push to
        uint256[] storage storageData = storageMapping[who];
        // Pre load the bounds
        (uint256 minIndex, uint256 length) = _loadBounds(storageData);
        // Search for the blocknumber
        (uint256 staleIndex, uint256 loadedData) =
            _find(storageData, blocknumber, staleBlock, minIndex, length);
        // We clear any data in the stale region
        // Note - Since find returns 0 if no stale data is found and we use > instead of >=
        //        this won't trigger if no stale data is found. Plus it won't trigger on minIndex == staleIndex
        //        == maxIndex and clear the whole array.
        if (staleIndex > minIndex) {
            // Delete the outdated stored info
            _clear(minIndex, staleIndex, storageData);
            // Reset the array info with stale index as the new minIndex
            _setBounds(storageData, staleIndex, length);
        }
        return (loadedData);
    }

    /// @notice Searches for the data stored at the largest blocknumber index less than a provided parameter.
    ///         Allows specification of a expiration stamp and returns the greatest examined index which is
    ///         found to be older than that stamp.
    /// @param data The stored data
    /// @param blocknumber the blocknumber we want to load the historical data for.
    /// @param staleBlock The oldest block that we care about the data stored for, all previous data can be deleted
    /// @param startingMinIndex The smallest filled index in the array
    /// @param length the length of the array
    /// @return Returns the largest stale data index seen or 0 for no seen stale data and the stored data
    function _find(
        uint256[] storage data,
        uint256 blocknumber,
        uint256 staleBlock,
        uint256 startingMinIndex,
        uint256 length
    ) private view returns (uint256, uint256) {
        // We explicitly revert on the reading of memory which is uninitialized
        require(length != 0, "uninitialized");
        // Do some correctness checks
        require(staleBlock <= blocknumber);
        require(startingMinIndex < length);
        // Load the bounds of our binary search
        uint256 maxIndex = length - 1;
        uint256 minIndex = startingMinIndex;
        uint256 staleIndex = 0;

        // We run a binary search on the block number fields in the array between
        // the minIndex and maxIndex. If we find indexes with blocknumber < staleBlock
        // we set staleIndex to them and return that data for an optional clearing step
        // in the calling function.
        while (minIndex != maxIndex) {
            // We use the ceil instead of the floor because this guarantees that
            // we pick the highest blocknumber less than or equal the requested one
            uint256 mid = (minIndex + maxIndex + 1) / 2;
            // Load and unpack the data in the midpoint index
            (uint256 pastBlock, uint256 loadedData) = _loadAndUnpack(data, mid);

            //  If we've found the exact block we are looking for
            if (pastBlock == blocknumber) {
                // Then we just return the data
                return (staleIndex, loadedData);

                // Otherwise if the loaded block is smaller than the block number
            } else if (pastBlock < blocknumber) {
                // Then we first check if this is possibly a stale block
                if (pastBlock < staleBlock) {
                    // If it is we mark it for clearing
                    staleIndex = mid;
                }
                // We then repeat the search logic on the indices greater than the midpoint
                minIndex = mid;

                // In this case the pastBlock > blocknumber
            } else {
                // We then repeat the search on the indices below the midpoint
                maxIndex = mid - 1;
            }
        }

        // We load at the final index of the search
        (uint256 _pastBlock, uint256 _loadedData) =
            _loadAndUnpack(data, minIndex);
        // This will only be hit if a user has misconfigured the stale index and then
        // tried to load father into the past than has been preserved
        require(_pastBlock <= blocknumber, "Search Failure");
        return (staleIndex, _loadedData);
    }

    /// @notice Clears storage between two bounds in array
    /// @param oldMin The first index to set to zero
    /// @param newMin The new minimum filled index, ie clears to index < newMin
    /// @param data The storage array pointer
    function _clear(
        uint256 oldMin,
        uint256 newMin,
        uint256[] storage data
    ) private {
        // Correctness checks on this call
        require(oldMin <= newMin);
        // This function is private and trusted and should be only called by functions which ensure
        // that oldMin < newMin < length
        assembly {
            // The layout of arrays in solidity is [length][data]....[data] so this pointer is the
            // slot to write to data
            let dataLocation := add(data.slot, 1)
            // Loop through each index which is below new min and clear the storage
            // Note - Uses strict min so if given an input like oldMin = 5 newMin = 5 will be a no op
            for {
                let i := oldMin
            } lt(i, newMin) {
                i := add(i, 1)
            } {
                // store at the starting data pointer + i 256 bits of zero
                sstore(add(dataLocation, i), 0)
            }
        }
    }

    /// @notice Loads and unpacks the block number index and stored data from a data array
    /// @param data the storage array
    /// @param i the index to load and unpack
    /// @return (block number, stored data)
    function _loadAndUnpack(uint256[] storage data, uint256 i)
        private
        view
        returns (uint256, uint256)
    {
        // This function is trusted and should only be called after checking data lengths
        // we use assembly for the sload to avoid reloading length.
        uint256 loaded;
        assembly {
            loaded := sload(add(add(data.slot, 1), i))
        }
        // Unpack the packed 64 bit block number and 192 bit data field
        return (
            loaded >> 192,
            loaded &
                0x0000000000000000ffffffffffffffffffffffffffffffffffffffffffffffff
        );
    }

    /// @notice This function sets our non standard bounds data field where a normal array
    ///         would have length
    /// @param data the pointer to the storage array
    /// @param minIndex The minimum non stale index
    /// @param length The length of the storage array
    function _setBounds(
        uint256[] storage data,
        uint256 minIndex,
        uint256 length
    ) private {
        // Correctness check
        require(minIndex < length);

        assembly {
            // Ensure data cleanliness
            let clearedLength := and(
                length,
                0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff
            )
            // We move the min index into the top 128 bits by shifting it left by 128 bits
            let minInd := shl(128, minIndex)
            // We pack the data using binary or
            let packed := or(minInd, clearedLength)
            // We store in the packed data in the length field of this storage array
            sstore(data.slot, packed)
        }
    }

    /// @notice This function loads and unpacks our packed min index and length for our custom storage array
    /// @param data The pointer to the storage location
    /// @return minInd the first filled index in the array
    /// @return length the length of the array
    function _loadBounds(uint256[] storage data)
        private
        view
        returns (uint256 minInd, uint256 length)
    {
        // Use assembly to manually load the length storage field
        uint256 packedData;
        assembly {
            packedData := sload(data.slot)
        }
        // We use a shift right to clear out the low order bits of the data field
        minInd = packedData >> 128;
        // We use a binary and to extract only the bottom 128 bits
        length =
            packedData &
            0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

// Copy of `Storage` with modified scope to match the VestingVault requirements
// This library allows for secure storage pointers across proxy implementations
// It will return storage pointers based on a hashed name and type string.
library VestingVaultStorage {
    // This library follows a pattern which if solidity had higher level
    // type or macro support would condense quite a bit.

    // Each basic type which does not support storage locations is encoded as
    // a struct of the same name capitalized and has functions 'load' and 'set'
    // which load the data and set the data respectively.

    // All types will have a function of the form 'typename'Ptr('name') -> storage ptr
    // which will return a storage version of the type with slot which is the hash of
    // the variable name and type string. This pointer allows easy state management between
    // upgrades and overrides the default solidity storage slot system.

    // A struct which represents 1 packed storage location (Grant)
    struct Grant {
        uint128 allocation;
        uint128 withdrawn;
        uint128 created;
        uint128 expiration;
        uint128 cliff;
        uint128 latestVotingPower;
        address delegatee;
        uint256[2] range;
    }

    /// @notice Returns the storage pointer for a named mapping of address to uint256[]
    /// @param name the variable name for the pointer
    /// @return data the mapping pointer
    function mappingAddressToGrantPtr(string memory name)
        internal
        pure
        returns (mapping(address => Grant) storage data)
    {
        bytes32 typehash = keccak256("mapping(address => Grant)");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

// This library allows for secure storage pointers across proxy implementations
// It will return storage pointers based on a hashed name and type string.
library Storage {
    // This library follows a pattern which if solidity had higher level
    // type or macro support would condense quite a bit.

    // Each basic type which does not support storage locations is encoded as
    // a struct of the same name capitalized and has functions 'load' and 'set'
    // which load the data and set the data respectively.

    // All types will have a function of the form 'typename'Ptr('name') -> storage ptr
    // which will return a storage version of the type with slot which is the hash of
    // the variable name and type string. This pointer allows easy state management between
    // upgrades and overrides the default solidity storage slot system.

    /// @dev The address type container
    struct Address {
        address data;
    }

    /// @notice A function which turns a variable name for a storage address into a storage
    ///         pointer for its container.
    /// @param name the variable name
    /// @return data the storage pointer
    function addressPtr(string memory name)
        internal
        pure
        returns (Address storage data)
    {
        bytes32 typehash = keccak256("address");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }

    /// @notice A function to load an address from the container struct
    /// @param input the storage pointer for the container
    /// @return the loaded address
    function load(Address storage input) internal view returns (address) {
        return input.data;
    }

    /// @notice A function to set the internal field of an address container
    /// @param input the storage pointer to the container
    /// @param to the address to set the container to
    function set(Address storage input, address to) internal {
        input.data = to;
    }

    /// @dev The uint256 type container
    struct Uint256 {
        uint256 data;
    }

    /// @notice A function which turns a variable name for a storage uint256 into a storage
    ///         pointer for its container.
    /// @param name the variable name
    /// @return data the storage pointer
    function uint256Ptr(string memory name)
        internal
        pure
        returns (Uint256 storage data)
    {
        bytes32 typehash = keccak256("uint256");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }

    /// @notice A function to load an uint256 from the container struct
    /// @param input the storage pointer for the container
    /// @return the loaded uint256
    function load(Uint256 storage input) internal view returns (uint256) {
        return input.data;
    }

    /// @notice A function to set the internal field of a unit256 container
    /// @param input the storage pointer to the container
    /// @param to the address to set the container to
    function set(Uint256 storage input, uint256 to) internal {
        input.data = to;
    }

    /// @notice Returns the storage pointer for a named mapping of address to uint256
    /// @param name the variable name for the pointer
    /// @return data the mapping pointer
    function mappingAddressToUnit256Ptr(string memory name)
        internal
        pure
        returns (mapping(address => uint256) storage data)
    {
        bytes32 typehash = keccak256("mapping(address => uint256)");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }

    /// @notice Returns the storage pointer for a named mapping of address to uint256[]
    /// @param name the variable name for the pointer
    /// @return data the mapping pointer
    function mappingAddressToUnit256ArrayPtr(string memory name)
        internal
        pure
        returns (mapping(address => uint256[]) storage data)
    {
        bytes32 typehash = keccak256("mapping(address => uint256[])");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }

    /// @notice Allows external users to calculate the slot given by this lib
    /// @param typeString the string which encodes the type
    /// @param name the variable name
    /// @return the slot assigned by this lib
    function getPtr(string memory typeString, string memory name)
        external
        pure
        returns (uint256)
    {
        bytes32 typehash = keccak256(abi.encodePacked(typeString));
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        return (uint256)(offset);
    }

    // A struct which represents 1 packed storage location with a compressed
    // address and uint96 pair
    struct AddressUint {
        address who;
        uint96 amount;
    }

    /// @notice Returns the storage pointer for a named mapping of address to uint256[]
    /// @param name the variable name for the pointer
    /// @return data the mapping pointer
    function mappingAddressToPackedAddressUint(string memory name)
        internal
        pure
        returns (mapping(address => AddressUint) storage data)
    {
        bytes32 typehash = keccak256("mapping(address => AddressUint)");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

interface IVotingVault {
    /// @notice Attempts to load the voting power of a user
    /// @param user The address we want to load the voting power of
    /// @param blockNumber the block number we want the user's voting power at
    /// @param extraData Abi encoded optional extra data used by some vaults, such as merkle proofs
    /// @return the number of votes
    function queryVotePower(
        address user,
        uint256 blockNumber,
        bytes calldata extraData
    ) external returns (uint256);
}