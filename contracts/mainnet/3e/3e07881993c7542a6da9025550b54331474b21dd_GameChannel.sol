pragma solidity ^0.4.24;

interface ConflictResolutionInterface {
    function minHouseStake(uint activeGames) external pure returns(uint);

    function maxBalance() external pure returns(int);

    function conflictEndFine() external pure returns(int);

    function isValidBet(uint8 _gameType, uint _betNum, uint _betValue) external pure returns(bool);

    function endGameConflict(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        bytes32 _serverSeed,
        bytes32 _userSeed
    )
        external
        view
        returns(int);

    function serverForceGameEnd(
        uint8 gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        uint _endInitiatedTime
    )
        external
        view
        returns(int);

    function userForceGameEnd(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        uint _endInitiatedTime
    )
        external
        view
        returns(int);
}

library MathUtil {
    /**
     * @dev Returns the absolute value of _val.
     * @param _val value
     * @return The absolute value of _val.
     */
    function abs(int _val) internal pure returns(uint) {
        if (_val < 0) {
            return uint(-_val);
        } else {
            return uint(_val);
        }
    }

    /**
     * @dev Calculate maximum.
     */
    function max(uint _val1, uint _val2) internal pure returns(uint) {
        return _val1 >= _val2 ? _val1 : _val2;
    }

    /**
     * @dev Calculate minimum.
     */
    function min(uint _val1, uint _val2) internal pure returns(uint) {
        return _val1 <= _val2 ? _val1 : _val2;
    }
}

contract Ownable {
    address public owner;
    address public pendingOwner;

    event LogOwnerShipTransferred(address indexed previousOwner, address indexed newOwner);
    event LogOwnerShipTransferInitiated(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Modifier, which throws if called by other account than owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Set contract creator as initial owner
     */
    constructor() public {
        owner = msg.sender;
        pendingOwner = address(0);
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        pendingOwner = _newOwner;
        emit LogOwnerShipTransferInitiated(owner, _newOwner);
    }

    /**
     * @dev PendingOwner can accept ownership.
     */
    function claimOwnership() public onlyPendingOwner {
        owner = pendingOwner;
        pendingOwner = address(0);
        emit LogOwnerShipTransferred(owner, pendingOwner);
    }
}

contract Activatable is Ownable {
    bool public activated = false;

    /// @dev Event is fired if activated.
    event LogActive();

    /// @dev Modifier, which only allows function execution if activated.
    modifier onlyActivated() {
        require(activated);
        _;
    }

    /// @dev Modifier, which only allows function execution if not activated.
    modifier onlyNotActivated() {
        require(!activated);
        _;
    }

    /// @dev activate contract, can be only called once by the contract owner.
    function activate() public onlyOwner onlyNotActivated {
        activated = true;
        emit LogActive();
    }
}

contract ConflictResolutionManager is Ownable {
    /// @dev Conflict resolution contract.
    ConflictResolutionInterface public conflictRes;

    /// @dev New Conflict resolution contract.
    address public newConflictRes = 0;

    /// @dev Time update of new conflict resolution contract was initiated.
    uint public updateTime = 0;

    /// @dev Min time before new conflict res contract can be activated after initiating update.
    uint public constant MIN_TIMEOUT = 3 days;

    /// @dev Min time before new conflict res contract can be activated after initiating update.
    uint public constant MAX_TIMEOUT = 6 days;

    /// @dev Update of conflict resolution contract was initiated.
    event LogUpdatingConflictResolution(address newConflictResolutionAddress);

    /// @dev New conflict resolution contract is active.
    event LogUpdatedConflictResolution(address newConflictResolutionAddress);

    /**
     * @dev Constructor
     * @param _conflictResAddress conflict resolution contract address.
     */
    constructor(address _conflictResAddress) public {
        conflictRes = ConflictResolutionInterface(_conflictResAddress);
    }

    /**
     * @dev Initiate conflict resolution contract update.
     * @param _newConflictResAddress New conflict resolution contract address.
     */
    function updateConflictResolution(address _newConflictResAddress) public onlyOwner {
        newConflictRes = _newConflictResAddress;
        updateTime = block.timestamp;

        emit LogUpdatingConflictResolution(_newConflictResAddress);
    }

    /**
     * @dev Active new conflict resolution contract.
     */
    function activateConflictResolution() public onlyOwner {
        require(newConflictRes != 0);
        require(updateTime != 0);
        require(updateTime + MIN_TIMEOUT <= block.timestamp && block.timestamp <= updateTime + MAX_TIMEOUT);

        conflictRes = ConflictResolutionInterface(newConflictRes);
        newConflictRes = 0;
        updateTime = 0;

        emit LogUpdatedConflictResolution(newConflictRes);
    }
}

contract Pausable is Activatable {
    using SafeMath for uint;

    /// @dev Is contract paused. Initial it is paused.
    bool public paused = true;

    /// @dev Time pause was called
    uint public timePaused = block.timestamp;

    /// @dev Modifier, which only allows function execution if not paused.
    modifier onlyNotPaused() {
        require(!paused, "paused");
        _;
    }

    /// @dev Modifier, which only allows function execution if paused.
    modifier onlyPaused() {
        require(paused);
        _;
    }

    /// @dev Modifier, which only allows function execution if paused longer than timeSpan.
    modifier onlyPausedSince(uint timeSpan) {
        require(paused && (timePaused.add(timeSpan) <= block.timestamp));
        _;
    }

    /// @dev Event is fired if paused.
    event LogPause();

    /// @dev Event is fired if pause is ended.
    event LogUnpause();

    /**
     * @dev Pause contract. No new game sessions can be created.
     */
    function pause() public onlyOwner onlyNotPaused {
        paused = true;
        timePaused = block.timestamp;
        emit LogPause();
    }

    /**
     * @dev Unpause contract. Initial contract is paused and can only be unpaused after activating it.
     */
    function unpause() public onlyOwner onlyPaused onlyActivated {
        paused = false;
        timePaused = 0;
        emit LogUnpause();
    }
}

contract Destroyable is Pausable {
    /// @dev After pausing the contract for 20 days owner can selfdestruct it.
    uint public constant TIMEOUT_DESTROY = 20 days;

    /**
     * @dev Destroy contract and transfer ether to owner.
     */
    function destroy() public onlyOwner onlyPausedSince(TIMEOUT_DESTROY) {
        selfdestruct(owner);
    }
}

contract GameChannelBase is Destroyable, ConflictResolutionManager {
    using SafeCast for int;
    using SafeCast for uint;
    using SafeMath for int;
    using SafeMath for uint;


    /// @dev Different game session states.
    enum GameStatus {
        ENDED, ///< @dev Game session is ended.
        ACTIVE, ///< @dev Game session is active.
        USER_INITIATED_END, ///< @dev User initiated non regular end.
        SERVER_INITIATED_END ///< @dev Server initiated non regular end.
    }

    /// @dev Reason game session ended.
    enum ReasonEnded {
        REGULAR_ENDED, ///< @dev Game session is regularly ended.
        SERVER_FORCED_END, ///< @dev User did not respond. Server forced end.
        USER_FORCED_END, ///< @dev Server did not respond. User forced end.
        CONFLICT_ENDED ///< @dev Server or user raised conflict ans pushed game state, opponent pushed same game state.
    }

    struct Game {
        /// @dev Game session status.
        GameStatus status;

        /// @dev User&#39;s stake.
        uint128 stake;

        /// @dev Last game round info if not regularly ended.
        /// If game session is ended normally this data is not used.
        uint8 gameType;
        uint32 roundId;
        uint betNum;
        uint betValue;
        int balance;
        bytes32 userSeed;
        bytes32 serverSeed;
        uint endInitiatedTime;
    }

    /// @dev Minimal time span between profit transfer.
    uint public constant MIN_TRANSFER_TIMESPAN = 1 days;

    /// @dev Maximal time span between profit transfer.
    uint public constant MAX_TRANSFER_TIMSPAN = 6 * 30 days;

    bytes32 public constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 public constant BET_TYPEHASH = keccak256(
        "Bet(uint32 roundId,uint8 gameType,uint256 number,uint256 value,int256 balance,bytes32 serverHash,bytes32 userHash,uint256 gameId)"
    );

    bytes32 public DOMAIN_SEPERATOR;

    /// @dev Current active game sessions.
    uint public activeGames = 0;

    /// @dev Game session id counter. Points to next free game session slot. So gameIdCntr -1 is the
    // number of game sessions created.
    uint public gameIdCntr = 1;

    /// @dev Only this address can accept and end games.
    address public serverAddress;

    /// @dev Address to transfer profit to.
    address public houseAddress;

    /// @dev Current house stake.
    uint public houseStake = 0;

    /// @dev House profit since last profit transfer.
    int public houseProfit = 0;

    /// @dev Min value user needs to deposit for creating game session.
    uint128 public minStake;

    /// @dev Max value user can deposit for creating game session.
    uint128 public maxStake;

    /// @dev Timeout until next profit transfer is allowed.
    uint public profitTransferTimeSpan = 14 days;

    /// @dev Last time profit transferred to house.
    uint public lastProfitTransferTimestamp;

    /// @dev Maps gameId to game struct.
    mapping (uint => Game) public gameIdGame;

    /// @dev Maps user address to current user game id.
    mapping (address => uint) public userGameId;

    /// @dev Maps user address to pending returns.
    mapping (address => uint) public pendingReturns;

    /// @dev Modifier, which only allows to execute if house stake is high enough.
    modifier onlyValidHouseStake(uint _activeGames) {
        uint minHouseStake = conflictRes.minHouseStake(_activeGames);
        require(houseStake >= minHouseStake, "inv houseStake");
        _;
    }

    /// @dev Modifier to check if value send fulfills user stake requirements.
    modifier onlyValidValue() {
        require(minStake <= msg.value && msg.value <= maxStake, "inv stake");
        _;
    }

    /// @dev Modifier, which only allows server to call function.
    modifier onlyServer() {
        require(msg.sender == serverAddress);
        _;
    }

    /// @dev Modifier, which only allows to set valid transfer timeouts.
    modifier onlyValidTransferTimeSpan(uint transferTimeout) {
        require(transferTimeout >= MIN_TRANSFER_TIMESPAN
                && transferTimeout <= MAX_TRANSFER_TIMSPAN);
        _;
    }

    /// @dev This event is fired when user creates game session.
    event LogGameCreated(address indexed user, uint indexed gameId, uint128 stake, bytes32 indexed serverEndHash, bytes32 userEndHash);

    /// @dev This event is fired when user requests conflict end.
    event LogUserRequestedEnd(address indexed user, uint indexed gameId);

    /// @dev This event is fired when server requests conflict end.
    event LogServerRequestedEnd(address indexed user, uint indexed gameId);

    /// @dev This event is fired when game session is ended.
    event LogGameEnded(address indexed user, uint indexed gameId, uint32 roundId, int balance, ReasonEnded reason);

    /// @dev this event is fired when owner modifies user&#39;s stake limits.
    event LogStakeLimitsModified(uint minStake, uint maxStake);

    /**
     * @dev Contract constructor.
     * @param _serverAddress Server address.
     * @param _minStake Min value user needs to deposit to create game session.
     * @param _maxStake Max value user can deposit to create game session.
     * @param _conflictResAddress Conflict resolution contract address.
     * @param _houseAddress House address to move profit to.
     * @param _chainId Chain id for signature domain.
     */
    constructor(
        address _serverAddress,
        uint128 _minStake,
        uint128 _maxStake,
        address _conflictResAddress,
        address _houseAddress,
        uint _chainId
    )
        public
        ConflictResolutionManager(_conflictResAddress)
    {
        require(_minStake > 0 && _minStake <= _maxStake);

        serverAddress = _serverAddress;
        houseAddress = _houseAddress;
        lastProfitTransferTimestamp = block.timestamp;
        minStake = _minStake;
        maxStake = _maxStake;

        DOMAIN_SEPERATOR =  keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256("Dicether"),
            keccak256("2"),
            _chainId,
            address(this)
        ));
    }

    /**
     * @dev Set gameIdCntr. Can be only set before activating contract.
     */
    function setGameIdCntr(uint _gameIdCntr) public onlyOwner onlyNotActivated {
        require(gameIdCntr > 0);
        gameIdCntr = _gameIdCntr;
    }

    /**
     * @notice Withdraw pending returns.
     */
    function withdraw() public {
        uint toTransfer = pendingReturns[msg.sender];
        require(toTransfer > 0);

        pendingReturns[msg.sender] = 0;
        msg.sender.transfer(toTransfer);
    }

    /**
     * @notice Transfer house profit to houseAddress.
     */
    function transferProfitToHouse() public {
        require(lastProfitTransferTimestamp.add(profitTransferTimeSpan) <= block.timestamp);

        // update last transfer timestamp
        lastProfitTransferTimestamp = block.timestamp;

        if (houseProfit <= 0) {
            // no profit to transfer
            return;
        }

        uint toTransfer = houseProfit.castToUint();

        houseProfit = 0;
        houseStake = houseStake.sub(toTransfer);

        houseAddress.transfer(toTransfer);
    }

    /**
     * @dev Set profit transfer time span.
     */
    function setProfitTransferTimeSpan(uint _profitTransferTimeSpan)
        public
        onlyOwner
        onlyValidTransferTimeSpan(_profitTransferTimeSpan)
    {
        profitTransferTimeSpan = _profitTransferTimeSpan;
    }

    /**
     * @dev Increase house stake by msg.value
     */
    function addHouseStake() public payable onlyOwner {
        houseStake = houseStake.add(msg.value);
    }

    /**
     * @dev Withdraw house stake.
     */
    function withdrawHouseStake(uint value) public onlyOwner {
        uint minHouseStake = conflictRes.minHouseStake(activeGames);

        require(value <= houseStake && houseStake.sub(value) >= minHouseStake);
        require(houseProfit <= 0 || houseProfit.castToUint() <= houseStake.sub(value));

        houseStake = houseStake.sub(value);
        owner.transfer(value);
    }

    /**
     * @dev Withdraw house stake and profit.
     */
    function withdrawAll() public onlyOwner onlyPausedSince(3 days) {
        houseProfit = 0;
        uint toTransfer = houseStake;
        houseStake = 0;
        owner.transfer(toTransfer);
    }

    /**
     * @dev Set new house address.
     * @param _houseAddress New house address.
     */
    function setHouseAddress(address _houseAddress) public onlyOwner {
        houseAddress = _houseAddress;
    }

    /**
     * @dev Set stake min and max value.
     * @param _minStake Min stake.
     * @param _maxStake Max stake.
     */
    function setStakeRequirements(uint128 _minStake, uint128 _maxStake) public onlyOwner {
        require(_minStake > 0 && _minStake <= _maxStake);
        minStake = _minStake;
        maxStake = _maxStake;
        emit LogStakeLimitsModified(minStake, maxStake);
    }

    /**
     * @dev Close game session.
     * @param _game Game session data.
     * @param _gameId Id of game session.
     * @param _userAddress User&#39;s address of game session.
     * @param _reason Reason for closing game session.
     * @param _balance Game session balance.
     */
    function closeGame(
        Game storage _game,
        uint _gameId,
        uint32 _roundId,
        address _userAddress,
        ReasonEnded _reason,
        int _balance
    )
        internal
    {
        _game.status = GameStatus.ENDED;

        activeGames = activeGames.sub(1);

        payOut(_userAddress, _game.stake, _balance);

        emit LogGameEnded(_userAddress, _gameId, _roundId, _balance, _reason);
    }

    /**
     * @dev End game by paying out user and server.
     * @param _userAddress User&#39;s address.
     * @param _stake User&#39;s stake.
     * @param _balance User&#39;s balance.
     */
    function payOut(address _userAddress, uint128 _stake, int _balance) internal {
        int stakeInt = _stake;
        int houseStakeInt = houseStake.castToInt();

        assert(_balance <= conflictRes.maxBalance());
        assert((stakeInt.add(_balance)) >= 0);

        if (_balance > 0 && houseStakeInt < _balance) {
            // Should never happen!
            // House is bankrupt.
            // Payout left money.
            _balance = houseStakeInt;
        }

        houseProfit = houseProfit.sub(_balance);

        int newHouseStake = houseStakeInt.sub(_balance);
        houseStake = newHouseStake.castToUint();

        uint valueUser = stakeInt.add(_balance).castToUint();
        pendingReturns[_userAddress] += valueUser;
        if (pendingReturns[_userAddress] > 0) {
            safeSend(_userAddress);
        }
    }

    /**
     * @dev Send value of pendingReturns[_address] to _address.
     * @param _address Address to send value to.
     */
    function safeSend(address _address) internal {
        uint valueToSend = pendingReturns[_address];
        assert(valueToSend > 0);

        pendingReturns[_address] = 0;
        if (_address.send(valueToSend) == false) {
            pendingReturns[_address] = valueToSend;
        }
    }

    /**
     * @dev Verify signature of given data. Throws on verification failure.
     * @param _sig Signature of given data in the form of rsv.
     * @param _address Address of signature signer.
     */
    function verifySig(
        uint32 _roundId,
        uint8 _gameType,
        uint _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _userHash,
        uint _gameId,
        address _contractAddress,
        bytes _sig,
        address _address
    )
        internal
        view
    {
        // check if this is the correct contract
        address contractAddress = this;
        require(_contractAddress == contractAddress, "inv contractAddress");

        bytes32 roundHash = calcHash(
                _roundId,
                _gameType,
                _num,
                _value,
                _balance,
                _serverHash,
                _userHash,
                _gameId
        );

        verify(
                roundHash,
                _sig,
                _address
        );
    }

     /**
     * @dev Check if _sig is valid signature of _hash. Throws if invalid signature.
     * @param _hash Hash to check signature of.
     * @param _sig Signature of _hash.
     * @param _address Address of signer.
     */
    function verify(
        bytes32 _hash,
        bytes _sig,
        address _address
    )
        internal
        pure
    {
        (bytes32 r, bytes32 s, uint8 v) = signatureSplit(_sig);
        address addressRecover = ecrecover(_hash, v, r, s);
        require(addressRecover == _address, "inv sig");
    }

    /**
     * @dev Calculate typed hash of given data (compare eth_signTypedData).
     * @return Hash of given data.
     */
    function calcHash(
        uint32 _roundId,
        uint8 _gameType,
        uint _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _userHash,
        uint _gameId
    )
        private
        view
        returns(bytes32)
    {
        bytes32 betHash = keccak256(abi.encode(
            BET_TYPEHASH,
            _roundId,
            _gameType,
            _num,
            _value,
            _balance,
            _serverHash,
            _userHash,
            _gameId
        ));

        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPERATOR,
            betHash
        ));
    }

    /**
     * @dev Split the given signature of the form rsv in r s v. v is incremented with 27 if
     * it is below 2.
     * @param _signature Signature to split.
     * @return r s v
     */
    function signatureSplit(bytes _signature)
        private
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(_signature.length == 65, "inv sig");

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := and(mload(add(_signature, 65)), 0xff)
        }
        if (v < 2) {
            v = v + 27;
        }
    }
}

contract GameChannelConflict is GameChannelBase {
    using SafeCast for int;
    using SafeCast for uint;
    using SafeMath for int;
    using SafeMath for uint;

    /**
     * @dev Contract constructor.
     * @param _serverAddress Server address.
     * @param _minStake Min value user needs to deposit to create game session.
     * @param _maxStake Max value user can deposit to create game session.
     * @param _conflictResAddress Conflict resolution contract address
     * @param _houseAddress House address to move profit to
     * @param _chainId Chain id for signature domain.
     */
    constructor(
        address _serverAddress,
        uint128 _minStake,
        uint128 _maxStake,
        address _conflictResAddress,
        address _houseAddress,
        uint _chainId
    )
        public
        GameChannelBase(_serverAddress, _minStake, _maxStake, _conflictResAddress, _houseAddress, _chainId)
    {
        // nothing to do
    }

    /**
     * @dev Used by server if user does not end game session.
     * @param _roundId Round id of bet.
     * @param _gameType Game type of bet.
     * @param _num Number of bet.
     * @param _value Value of bet.
     * @param _balance Balance before this bet.
     * @param _serverHash Hash of server seed for this bet.
     * @param _userHash Hash of user seed for this bet.
     * @param _gameId Game session id.
     * @param _contractAddress Address of this contract.
     * @param _userSig User signature of this bet.
     * @param _userAddress Address of user.
     * @param _serverSeed Server seed for this bet.
     * @param _userSeed User seed for this bet.
     */
    function serverEndGameConflict(
        uint32 _roundId,
        uint8 _gameType,
        uint _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _userHash,
        uint _gameId,
        address _contractAddress,
        bytes _userSig,
        address _userAddress,
        bytes32 _serverSeed,
        bytes32 _userSeed
    )
        public
        onlyServer
    {
        verifySig(
                _roundId,
                _gameType,
                _num,
                _value,
                _balance,
                _serverHash,
                _userHash,
                _gameId,
                _contractAddress,
                _userSig,
                _userAddress
        );

        serverEndGameConflictImpl(
                _roundId,
                _gameType,
                _num,
                _value,
                _balance,
                _serverHash,
                _userHash,
                _serverSeed,
                _userSeed,
                _gameId,
                _userAddress
        );
    }

    /**
     * @notice Can be used by user if server does not answer to the end game session request.
     * @param _roundId Round id of bet.
     * @param _gameType Game type of bet.
     * @param _num Number of bet.
     * @param _value Value of bet.
     * @param _balance Balance before this bet.
     * @param _serverHash Hash of server seed for this bet.
     * @param _userHash Hash of user seed for this bet.
     * @param _gameId Game session id.
     * @param _contractAddress Address of this contract.
     * @param _serverSig Server signature of this bet.
     * @param _userSeed User seed for this bet.
     */
    function userEndGameConflict(
        uint32 _roundId,
        uint8 _gameType,
        uint _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _userHash,
        uint _gameId,
        address _contractAddress,
        bytes _serverSig,
        bytes32 _userSeed
    )
        public
    {
        verifySig(
            _roundId,
            _gameType,
            _num,
            _value,
            _balance,
            _serverHash,
            _userHash,
            _gameId,
            _contractAddress,
            _serverSig,
            serverAddress
        );

        userEndGameConflictImpl(
            _roundId,
            _gameType,
            _num,
            _value,
            _balance,
            _userHash,
            _userSeed,
            _gameId,
            msg.sender
        );
    }

    /**
     * @notice Cancel active game without playing. Useful if server stops responding before
     * one game is played.
     * @param _gameId Game session id.
     */
    function userCancelActiveGame(uint _gameId) public {
        address userAddress = msg.sender;
        uint gameId = userGameId[userAddress];
        Game storage game = gameIdGame[gameId];

        require(gameId == _gameId, "inv gameId");

        if (game.status == GameStatus.ACTIVE) {
            game.endInitiatedTime = block.timestamp;
            game.status = GameStatus.USER_INITIATED_END;

            emit LogUserRequestedEnd(msg.sender, gameId);
        } else if (game.status == GameStatus.SERVER_INITIATED_END && game.roundId == 0) {
            cancelActiveGame(game, gameId, userAddress);
        } else {
            revert();
        }
    }

    /**
     * @dev Cancel active game without playing. Useful if user starts game session and
     * does not play.
     * @param _userAddress Users&#39; address.
     * @param _gameId Game session id.
     */
    function serverCancelActiveGame(address _userAddress, uint _gameId) public onlyServer {
        uint gameId = userGameId[_userAddress];
        Game storage game = gameIdGame[gameId];

        require(gameId == _gameId, "inv gameId");

        if (game.status == GameStatus.ACTIVE) {
            game.endInitiatedTime = block.timestamp;
            game.status = GameStatus.SERVER_INITIATED_END;

            emit LogServerRequestedEnd(msg.sender, gameId);
        } else if (game.status == GameStatus.USER_INITIATED_END && game.roundId == 0) {
            cancelActiveGame(game, gameId, _userAddress);
        } else {
            revert();
        }
    }

    /**
    * @dev Force end of game if user does not respond. Only possible after a certain period of time
    * to give the user a chance to respond.
    * @param _userAddress User&#39;s address.
    */
    function serverForceGameEnd(address _userAddress, uint _gameId) public onlyServer {
        uint gameId = userGameId[_userAddress];
        Game storage game = gameIdGame[gameId];

        require(gameId == _gameId, "inv gameId");
        require(game.status == GameStatus.SERVER_INITIATED_END, "inv status");

        // theoretically we have enough data to calculate winner
        // but as user did not respond assume he has lost.
        int newBalance = conflictRes.serverForceGameEnd(
            game.gameType,
            game.betNum,
            game.betValue,
            game.balance,
            game.stake,
            game.endInitiatedTime
        );

        closeGame(game, gameId, game.roundId, _userAddress, ReasonEnded.SERVER_FORCED_END, newBalance);
    }

    /**
    * @notice Force end of game if server does not respond. Only possible after a certain period of time
    * to give the server a chance to respond.
    */
    function userForceGameEnd(uint _gameId) public {
        address userAddress = msg.sender;
        uint gameId = userGameId[userAddress];
        Game storage game = gameIdGame[gameId];

        require(gameId == _gameId, "inv gameId");
        require(game.status == GameStatus.USER_INITIATED_END, "inv status");

        int newBalance = conflictRes.userForceGameEnd(
            game.gameType,
            game.betNum,
            game.betValue,
            game.balance,
            game.stake,
            game.endInitiatedTime
        );

        closeGame(game, gameId, game.roundId, userAddress, ReasonEnded.USER_FORCED_END, newBalance);
    }

    /**
     * @dev Conflict handling implementation. Stores game data and timestamp if game
     * is active. If server has already marked conflict for game session the conflict
     * resolution contract is used (compare conflictRes).
     * @param _roundId Round id of bet.
     * @param _gameType Game type of bet.
     * @param _num Number of bet.
     * @param _value Value of bet.
     * @param _balance Balance before this bet.
     * @param _userHash Hash of user&#39;s seed for this bet.
     * @param _userSeed User&#39;s seed for this bet.
     * @param _gameId game Game session id.
     * @param _userAddress User&#39;s address.
     */
    function userEndGameConflictImpl(
        uint32 _roundId,
        uint8 _gameType,
        uint _num,
        uint _value,
        int _balance,
        bytes32 _userHash,
        bytes32 _userSeed,
        uint _gameId,
        address _userAddress
    )
        private
    {
        uint gameId = userGameId[_userAddress];
        Game storage game = gameIdGame[gameId];
        int maxBalance = conflictRes.maxBalance();
        int gameStake = game.stake;

        require(gameId == _gameId, "inv gameId");
        require(_roundId > 0, "inv roundId");
        require(keccak256(abi.encodePacked(_userSeed)) == _userHash, "inv userSeed");
        require(-gameStake <= _balance && _balance <= maxBalance, "inv balance"); // game.stake save to cast as uint128
        require(conflictRes.isValidBet(_gameType, _num, _value), "inv bet");
        require(gameStake.add(_balance).sub(_value.castToInt()) >= 0, "value too high"); // game.stake save to cast as uint128

        if (game.status == GameStatus.SERVER_INITIATED_END && game.roundId == _roundId) {
            game.userSeed = _userSeed;
            endGameConflict(game, gameId, _userAddress);
        } else if (game.status == GameStatus.ACTIVE
                || (game.status == GameStatus.SERVER_INITIATED_END && game.roundId < _roundId)) {
            game.status = GameStatus.USER_INITIATED_END;
            game.endInitiatedTime = block.timestamp;
            game.roundId = _roundId;
            game.gameType = _gameType;
            game.betNum = _num;
            game.betValue = _value;
            game.balance = _balance;
            game.userSeed = _userSeed;
            game.serverSeed = bytes32(0);

            emit LogUserRequestedEnd(msg.sender, gameId);
        } else {
            revert("inv state");
        }
    }

    /**
     * @dev Conflict handling implementation. Stores game data and timestamp if game
     * is active. If user has already marked conflict for game session the conflict
     * resolution contract is used (compare conflictRes).
     * @param _roundId Round id of bet.
     * @param _gameType Game type of bet.
     * @param _num Number of bet.
     * @param _value Value of bet.
     * @param _balance Balance before this bet.
     * @param _serverHash Hash of server&#39;s seed for this bet.
     * @param _userHash Hash of user&#39;s seed for this bet.
     * @param _serverSeed Server&#39;s seed for this bet.
     * @param _userSeed User&#39;s seed for this bet.
     * @param _userAddress User&#39;s address.
     */
    function serverEndGameConflictImpl(
        uint32 _roundId,
        uint8 _gameType,
        uint _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _userHash,
        bytes32 _serverSeed,
        bytes32 _userSeed,
        uint _gameId,
        address _userAddress
    )
        private
    {
        uint gameId = userGameId[_userAddress];
        Game storage game = gameIdGame[gameId];
        int maxBalance = conflictRes.maxBalance();
        int gameStake = game.stake;

        require(gameId == _gameId, "inv gameId");
        require(_roundId > 0, "inv roundId");
        require(keccak256(abi.encodePacked(_serverSeed)) == _serverHash, "inv serverSeed");
        require(keccak256(abi.encodePacked(_userSeed)) == _userHash, "inv userSeed");
        require(-gameStake <= _balance && _balance <= maxBalance, "inv balance"); // game.stake save to cast as uint128
        require(conflictRes.isValidBet(_gameType, _num, _value), "inv bet");
        require(gameStake.add(_balance).sub(_value.castToInt()) >= 0, "too high value"); // game.stake save to cast as uin128

        if (game.status == GameStatus.USER_INITIATED_END && game.roundId == _roundId) {
            game.serverSeed = _serverSeed;
            endGameConflict(game, gameId, _userAddress);
        } else if (game.status == GameStatus.ACTIVE
                || (game.status == GameStatus.USER_INITIATED_END && game.roundId < _roundId)) {
            game.status = GameStatus.SERVER_INITIATED_END;
            game.endInitiatedTime = block.timestamp;
            game.roundId = _roundId;
            game.gameType = _gameType;
            game.betNum = _num;
            game.betValue = _value;
            game.balance = _balance;
            game.serverSeed = _serverSeed;
            game.userSeed = _userSeed;

            emit LogServerRequestedEnd(_userAddress, gameId);
        } else {
            revert("inv state");
        }
    }

    /**
     * @dev End conflicting game without placed bets.
     * @param _game Game session data.
     * @param _gameId Game session id.
     * @param _userAddress User&#39;s address.
     */
    function cancelActiveGame(Game storage _game, uint _gameId, address _userAddress) private {
        // user need to pay a fee when conflict ended.
        // this ensures a malicious, rich user can not just generate game sessions and then wait
        // for us to end the game session and then confirm the session status, so
        // we would have to pay a high gas fee without profit.
        int newBalance = -conflictRes.conflictEndFine();

        // do not allow balance below user stake
        int stake = _game.stake;
        if (newBalance < -stake) {
            newBalance = -stake;
        }
        closeGame(_game, _gameId, 0, _userAddress, ReasonEnded.CONFLICT_ENDED, newBalance);
    }

    /**
     * @dev End conflicting game.
     * @param _game Game session data.
     * @param _gameId Game session id.
     * @param _userAddress User&#39;s address.
     */
    function endGameConflict(Game storage _game, uint _gameId, address _userAddress) private {
        int newBalance = conflictRes.endGameConflict(
            _game.gameType,
            _game.betNum,
            _game.betValue,
            _game.balance,
            _game.stake,
            _game.serverSeed,
            _game.userSeed
        );

        closeGame(_game, _gameId, _game.roundId, _userAddress, ReasonEnded.CONFLICT_ENDED, newBalance);
    }
}

contract GameChannel is GameChannelConflict {
    /**
     * @dev contract constructor
     * @param _serverAddress Server address.
     * @param _minStake Min value user needs to deposit to create game session.
     * @param _maxStake Max value user can deposit to create game session.
     * @param _conflictResAddress Conflict resolution contract address.
     * @param _houseAddress House address to move profit to.
     * @param _chainId Chain id for signature domain.
     */
    constructor(
        address _serverAddress,
        uint128 _minStake,
        uint128 _maxStake,
        address _conflictResAddress,
        address _houseAddress,
        uint _chainId
    )
        public
        GameChannelConflict(_serverAddress, _minStake, _maxStake, _conflictResAddress, _houseAddress, _chainId)
    {
        // nothing to do
    }

    /**
     * @notice Create games session request. msg.value needs to be valid stake value.
     * @param _userEndHash Last entry of users&#39; hash chain.
     * @param _previousGameId User&#39;s previous game id, initial 0.
     * @param _createBefore Game can be only created before this timestamp.
     * @param _serverEndHash Last entry of server&#39;s hash chain.
     * @param _serverSig Server signature. See verifyCreateSig
     */
    function createGame(
        bytes32 _userEndHash,
        uint _previousGameId,
        uint _createBefore,
        bytes32 _serverEndHash,
        bytes _serverSig
    )
        public
        payable
        onlyValidValue
        onlyValidHouseStake(activeGames + 1)
        onlyNotPaused
    {
        uint previousGameId = userGameId[msg.sender];
        Game storage game = gameIdGame[previousGameId];

        require(game.status == GameStatus.ENDED, "prev game not ended");
        require(previousGameId == _previousGameId, "inv gamePrevGameId");
        require(block.timestamp < _createBefore, "expired");

        verifyCreateSig(msg.sender, _previousGameId, _createBefore, _serverEndHash, _serverSig);

        uint gameId = gameIdCntr++;
        userGameId[msg.sender] = gameId;
        Game storage newGame = gameIdGame[gameId];

        newGame.stake = uint128(msg.value); // It&#39;s safe to cast msg.value as it is limited, see onlyValidValue
        newGame.status = GameStatus.ACTIVE;

        activeGames = activeGames.add(1);

        // It&#39;s safe to cast msg.value as it is limited, see onlyValidValue
        emit LogGameCreated(msg.sender, gameId, uint128(msg.value), _serverEndHash,  _userEndHash);
    }


    /**
     * @dev Regular end game session. Used if user and house have both
     * accepted current game session state.
     * The game session with gameId _gameId is closed
     * and the user paid out. This functions is called by the server after
     * the user requested the termination of the current game session.
     * @param _roundId Round id of bet.
     * @param _balance Current balance.
     * @param _serverHash Hash of server&#39;s seed for this bet.
     * @param _userHash Hash of user&#39;s seed for this bet.
     * @param _gameId Game session id.
     * @param _contractAddress Address of this contract.
     * @param _userAddress Address of user.
     * @param _userSig User&#39;s signature of this bet.
     */
    function serverEndGame(
        uint32 _roundId,
        int _balance,
        bytes32 _serverHash,
        bytes32 _userHash,
        uint _gameId,
        address _contractAddress,
        address _userAddress,
        bytes _userSig
    )
        public
        onlyServer
    {
        verifySig(
                _roundId,
                0,
                0,
                0,
                _balance,
                _serverHash,
                _userHash,
                _gameId,
                _contractAddress,
                _userSig,
                _userAddress
        );

        regularEndGame(_userAddress, _roundId, _balance, _gameId, _contractAddress);
    }

    /**
     * @notice Regular end game session. Normally not needed as server ends game (@see serverEndGame).
     * Can be used by user if server does not end game session.
     * @param _roundId Round id of bet.
     * @param _balance Current balance.
     * @param _serverHash Hash of server&#39;s seed for this bet.
     * @param _userHash Hash of user&#39;s seed for this bet.
     * @param _gameId Game session id.
     * @param _contractAddress Address of this contract.
     * @param _serverSig Server&#39;s signature of this bet.
     */
    function userEndGame(
        uint32 _roundId,
        int _balance,
        bytes32 _serverHash,
        bytes32 _userHash,
        uint _gameId,
        address _contractAddress,
        bytes _serverSig
    )
        public
    {
        verifySig(
                _roundId,
                0,
                0,
                0,
                _balance,
                _serverHash,
                _userHash,
                _gameId,
                _contractAddress,
                _serverSig,
                serverAddress
        );

        regularEndGame(msg.sender, _roundId, _balance, _gameId, _contractAddress);
    }

    /**
     * @dev Verify server signature.
     * @param _userAddress User&#39;s address.
     * @param _previousGameId User&#39;s previous game id, initial 0.
     * @param _createBefore Game can be only created before this timestamp.
     * @param _serverEndHash Last entry of server&#39;s hash chain.
     * @param _serverSig Server signature.
     */
    function verifyCreateSig(
        address _userAddress,
        uint _previousGameId,
        uint _createBefore,
        bytes32 _serverEndHash,
        bytes _serverSig
    )
        private view
    {
        address contractAddress = this;
        bytes32 hash = keccak256(abi.encodePacked(
            contractAddress, _userAddress, _previousGameId, _createBefore, _serverEndHash
        ));

        verify(hash, _serverSig, serverAddress);
    }

    /**
     * @dev Regular end game session implementation. Used if user and house have both
     * accepted current game session state. The game session with gameId _gameId is closed
     * and the user paid out.
     * @param _userAddress Address of user.
     * @param _balance Current balance.
     * @param _gameId Game session id.
     * @param _contractAddress Address of this contract.
     */
    function regularEndGame(
        address _userAddress,
        uint32 _roundId,
        int _balance,
        uint _gameId,
        address _contractAddress
    )
        private
    {
        uint gameId = userGameId[_userAddress];
        Game storage game = gameIdGame[gameId];
        int maxBalance = conflictRes.maxBalance();
        int gameStake = game.stake;

        require(_gameId == gameId, "inv gameId");
        require(_roundId > 0, "inv roundId");
        // save to cast as game.stake hash fixed range
        require(-gameStake <= _balance && _balance <= maxBalance, "inv balance");
        require(game.status == GameStatus.ACTIVE, "inv status");

        assert(_contractAddress == address(this));

        closeGame(game, gameId, _roundId, _userAddress, ReasonEnded.REGULAR_ENDED, _balance);
    }
}

library SafeCast {
    /**
     * Cast unsigned a to signed a.
     */
    function castToInt(uint a) internal pure returns(int) {
        assert(a < (1 << 255));
        return int(a);
    }

    /**
     * Cast signed a to unsigned a.
     */
    function castToUint(int a) internal pure returns(uint) {
        assert(a >= 0);
        return uint(a);
    }
}

library SafeMath {

    /**
    * @dev Multiplies two unsigned integers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Multiplies two signed integers, throws on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
        int256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two unsigned integers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Integer division of two signed integers, truncating the quotient.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // Overflow only happens when the smallest negative int is multiplied by -1.
        int256 INT256_MIN = int256((uint256(1) << 255));
        assert(a != INT256_MIN || b != - 1);
        return a / b;
    }

    /**
    * @dev Subtracts two unsigned integers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Subtracts two signed integers, throws on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        assert((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
    * @dev Adds two unsigned integers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    /**
    * @dev Adds two signed integers, throws on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        assert((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }
}