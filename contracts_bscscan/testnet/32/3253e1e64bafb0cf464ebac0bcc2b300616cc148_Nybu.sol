//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Nybu is Ownable, Pausable, ReentrancyGuard {

    uint public serviceFee; // fee rate (e.g. 200 = 2%, 150 = 1.50%)
    uint public vault; // wei
    uint public minimumBet; // wei
    uint public interval; // seconds
    uint public roundBuffer; //seconds

    uint public constant MAX_FEE = 1000; // 10%
    uint public constant MAX_EPOCHS_PER_CLAIM = 20; // To protect aginst GAS/DOS attacks, and protect the oracle from being hijacked by a single huge request

    uint public oracleFee; 

    mapping(uint => Round) public rounds; //round information
    mapping(address => uint[]) public userRounds;
    mapping(uint => mapping(address => Bet)) public ledger; // epoch => user => bet - this can be added to the rounds struct

    address public oracle;
    address public admin;

    uint internal requestId = 1; // 0 reserved for automted oracle calls

    event OracleRequest(uint indexed id, address indexed sender, uint indexed epoch);
    event OracleRequestFulfilled(uint indexed id, address indexed sender);

    event BetBull(address indexed sender, uint indexed epoch, uint amount);
    event BetBear(address indexed sender, uint indexed epoch, uint amount);
    event Setteled(address indexed sender, uint indexed epoch, uint amount);
    event RoundResultUpdated(uint indexed requestId, uint indexed epoch, int result);

    event NewMinimumBet(uint newMinimumBet);
    event NewRoundBuffer(uint newRoundBuffer);
    event NewOracleFee(uint newOracleBaseFee);
    event NewServiceFee(uint newServiceFee);

    event NewOracleAddress(address newOracleAddress);
    event NewAdminAddress(address newOperatorAddress);
    event ClaimFees(uint amount);
    
    event Pause();
    event Unpause();

    enum Position {
        None,
        Bull,
        Bear
    }

    enum Result {
        None,
        BullWon,
        BearWon,
        Draw,
        Cancelled
    }

    struct Bet {
        bool claimed;
        bool calledOracle;
        uint amount; 
        Position position;
    }

    struct Round {
        uint totalAmount;
        uint bullAmount;
        uint bearAmount;
        Result result;
    }

    modifier onlyOracle() {
        require(oracle == _msgSender(), "Access: not oracle");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    modifier onlyAdmin() {
        require(admin == _msgSender(), "Access: not admin");
        _;
    }

    constructor(uint _interval, uint _minimumBet, uint _roundBuffer, uint _fee, address _admin, address _oracle, uint _oracleFee) {
        interval = _interval;
        minimumBet = _minimumBet;
        roundBuffer = _roundBuffer;
        serviceFee = _fee;
        admin = _admin;
        oracle = _oracle;
        oracleFee = _oracleFee;
    }

    function betBull(uint epoch) external payable whenNotPaused nonReentrant notContract {

        uint activeRound = _ceilTimestamp(block.timestamp);

        require(epoch == activeRound, "Bet: Too early/late to place");
        require(ledger[activeRound][msg.sender].position == Position.None, "Bet: only one per round");
        require(msg.value >= minimumBet, "Bet: Must be >= minimumBet");

        Bet storage bet = ledger[activeRound][msg.sender];
        bet.amount = msg.value;
        bet.position = Position.Bull;

        Round storage round = rounds[activeRound];
        round.totalAmount += msg.value;
        round.bullAmount += msg.value;

        userRounds[msg.sender].push(activeRound);

        emit BetBull(msg.sender, epoch, msg.value);
    }

    function betBear(uint epoch) external payable whenNotPaused nonReentrant notContract {

        uint activeRound = _ceilTimestamp(block.timestamp);

        require(epoch == activeRound, "Bet: Too early/late to place");
        require(ledger[activeRound][msg.sender].position == Position.None, "Bet: only one per round");
        require(msg.value >= minimumBet, "Bet: Must be >= minimumBet");

        Bet storage bet = ledger[activeRound][msg.sender];
        bet.amount = msg.value;
        bet.position = Position.Bear;

        Round storage round = rounds[activeRound];
        round.totalAmount += msg.value;
        round.bearAmount += msg.value;

        userRounds[msg.sender].push(activeRound);

        emit BetBear(msg.sender, epoch, msg.value);
    }

    function claim(uint[] calldata timestamps) external payable nonReentrant notContract {
        require(timestamps.length <= MAX_EPOCHS_PER_CLAIM, "Claim: Max epochs/claim"); // TODO: no test for this
        _settleUserRounds(address(msg.sender), timestamps);
    }

    function getUserRounds(address user, uint cursor, uint limit) external view returns(uint[] memory, uint, uint){

        uint length = limit;

        if (length > userRounds[user].length - cursor) {
            length = userRounds[user].length - cursor;
        }

        uint[] memory timestamps = new uint[](length);

        for (uint i = 0; i < length; i++) {
            timestamps[i] = userRounds[user][i+cursor];
        }

        return (timestamps, cursor+length, userRounds[user].length);
    }

    function callback(uint id, address caller, uint[] calldata timestamps, int[] calldata results) public onlyOracle {
        updateRoundResult(id, timestamps, results);
        _settleUserRounds(caller, timestamps);

        emit OracleRequestFulfilled(id, caller);
    }

    function updateRoundResult(uint id, uint[] calldata timestamps, int[] calldata results) public onlyOracle {
        require(timestamps.length != 0 && results.length != 0, "Input: zero length");
        require(timestamps.length == results.length, "Input: different lengths");

        for (uint i = 0; i < timestamps.length; i++) {
            require(timestamps[i] + interval < block.timestamp, "Round: future/unfinished"); // Must wait for the round to end inorder to update it's price
            Round storage round = rounds[timestamps[i]];
            int oracleResult = results[i];
            if(oracleResult == 1){
                round.result = Result.BullWon;
            }else if (oracleResult == 2){
                round.result = Result.BearWon;
            }else if(oracleResult == 3){
                round.result = Result.Draw;
            }else if (oracleResult == 4){
                round.result = Result.Cancelled;
            }else {
                revert("Invalid result input");
            }
            emit RoundResultUpdated(id, timestamps[i], results[i]);
        }
    }

    function pause() external whenNotPaused onlyAdmin {
        _pause();

        emit Pause();
    }

    function unPause() external whenPaused onlyAdmin {
        _unpause();
        
        emit Unpause();
    }

    function setOracleFee(uint _fee) public onlyAdmin {
        require(_fee >= 0, "New value cannot be neagtive");
        oracleFee = _fee;

        emit NewOracleFee(_fee);
    }

    function setMinimumBet(uint _minimumBet) public onlyAdmin {
        require(_minimumBet > 0, "New value must be positive");
        minimumBet = _minimumBet;

        emit NewMinimumBet(_minimumBet);
    }

    function setRoundBuffer(uint _roundBuffer) public onlyAdmin {
        require(_roundBuffer >= 0, "New value cannot be negative");
        roundBuffer = _roundBuffer;

        emit NewRoundBuffer(_roundBuffer);
    }

    function setServiceFee(uint _fee) public onlyAdmin {
        require(_fee <= MAX_FEE, "Fee too high");
        serviceFee = _fee;

        emit NewServiceFee(_fee);
    }

    function setOracleAddress(address _oracle) public onlyOwner {
        require(_oracle != address(0), "Cannot be zero address");
        oracle = _oracle;

        emit NewOracleAddress(_oracle);
    }

    function setAdminAddress(address _admin) public onlyOwner {
        require(_admin != address(0), "Cannot be zero address");
        admin = _admin;

        emit NewAdminAddress(_admin);
    }

    function claimFees() external onlyOwner {
        uint currentVaultAmount = vault;
        vault = 0;
        _safeTransferBNB(owner(), currentVaultAmount);

        emit ClaimFees(currentVaultAmount);
    }

    function _settleUserRounds(address beneficiary, uint[] calldata timestamps) internal {

        uint length = timestamps.length;

        uint reward = 0;
        uint oracleRequests = 0;

        for (uint i = 0; i < length; i++) {

            uint epoch = timestamps[i];

            require(block.timestamp > epoch + interval + roundBuffer, "Round: Not finished");

            Bet storage bet = ledger[epoch][beneficiary];
            require(bet.position != Position.None, "Round: Doesn't exist or no bets from caller"); // Can be divided into two requires
            require(!bet.claimed, "Bet: Claimed");
            require(!bet.calledOracle || _msgSender() == oracle, "Bet: Called oracle");

            Round memory round = rounds[epoch];

            if( (round.bearAmount == 0 && bet.position == Position.Bull) || (round.bullAmount == 0 && bet.position == Position.Bear) || round.result == Result.Cancelled) {
                bet.claimed = true;
                reward += bet.amount;
                emit Setteled(_msgSender(), timestamps[i], bet.amount);
                continue;
            }

            if(round.result == Result.None){
                assert(_msgSender() != oracle); // Oracle should only settle updated rounds.
                bet.calledOracle = true;
                oracleRequests += 1;
                emit OracleRequest(requestId, beneficiary, timestamps[i]);
                continue;
            }

            uint betReward = 0;
            bet.claimed = true;

            if (round.result == Result.BullWon && bet.position == Position.Bull) {
                // Correct unclaimed Bull prediction
                uint upRatio = round.totalAmount / round.bullAmount;
                uint winnings = upRatio * bet.amount;
                uint feeAmount = (winnings * serviceFee) / 10000;
                vault += feeAmount;
                betReward = winnings - feeAmount;
            } else if (round.result == Result.BearWon && bet.position == Position.Bear) {
                // Correct unclaimed Bear prediction
                uint downRatio = round.totalAmount / round.bearAmount;
                uint winnings = downRatio * bet.amount;
                uint feeAmount = (winnings * serviceFee) / 10000;
                vault += feeAmount;
                betReward = winnings - feeAmount;
            } else if (round.result == Result.Draw) {
                // Unclaimmed draw round. Refund
                betReward = bet.amount;
            } 

            emit Setteled(_msgSender(), timestamps[i], betReward);
            reward += betReward;
        }

        if(oracleRequests != 0) {
            uint oracleFees = oracleRequests * oracleFee;
            require(msg.value >= oracleFees, "Oracle: Fee too low");
            requestId += 1;
            _safeTransferBNB(oracle, msg.value);
        } else if (msg.value != 0){
            vault += msg.value; // Data already on-chain, add to vault
        }

        if (reward != 0){
            _safeTransferBNB(beneficiary, reward);
        }
    }

    function _safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "Transfer: transfer failed");
    }

    function _ceilTimestamp(uint timestamp) internal view returns (uint) {
        return ((timestamp/interval) * interval) + interval;
    }

    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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