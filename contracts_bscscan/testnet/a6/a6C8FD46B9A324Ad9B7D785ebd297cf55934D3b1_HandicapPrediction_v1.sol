// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HandicapPrediction_v1 is Ownable, ReentrancyGuard {

    enum MatchStatus {NOT_EXISTED, AVAILABLE, FINISH, CANCEL, SUSPEND}
    enum PredictionStatus {ENABLE, DISABLE}

    struct Score {
        uint256 firstTeam;
        uint256 secondTeam;
    }

    struct Handicap{
        uint256 side;
        uint256 value;
    }

    struct Match {
        bytes32 description;
        uint256 startTime;
        uint256 endTime;
        Score score;
        MatchStatus status;
    }

    struct Prediction {
        address dealer;
        uint256 matchId;
        uint256 minPredict;
        uint256 hardCap;
        Handicap handicap;
        uint256 chosenTeam;
        uint256 totalUserDeposit;
        PredictionStatus status;
    }

    struct PredictHistory {
        uint256 predictValue;
        uint256 timeStamp;
    }

    struct PredictionStats {
        uint256 totalAmount;
        uint256 availableAmount;
    }

    mapping (address => bool) admins;
    mapping (uint256 => Match) public matches;
    mapping (uint256 => Prediction) public predictions;
    mapping (address => mapping (uint256 => PredictionStats)) public predictionStats;
    mapping (address => mapping(uint256 => PredictHistory[])) public predictHistories;
    mapping (address => mapping(uint256 => bool)) public withdrawable;
    uint256 public nMatches;
    uint256 public nPredictions;
    uint256 constant ZOOM = 10000;
    uint256 public fee = 50;

    /* ========== MODIFIERS ========== */

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || admins[msg.sender] == true, "!owner && admin");
        _;
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function createPrediction(uint256 _matchId, uint256 _minPredict, Handicap memory _handicap, uint256 _chosenTeam)
    external payable
    returns (uint256 _idx)
    {
        Match memory _match = matches[_matchId];
        require(_match.status == MatchStatus.AVAILABLE, 'match-not-available');
        require(_handicap.side == 1 || _handicap.side == 2, 'handicap-invalid');
        require(_chosenTeam == 1 || _chosenTeam == 2, 'chosen_team-invalid');
        require(msg.value > 0, 'dealer-not-deposit');
        uint256 _hardCap = msg.value;
        _idx = nPredictions;
        predictions[_idx] = Prediction(
            msg.sender,
            _matchId,
            _minPredict,
            _hardCap,
            _handicap,
            _chosenTeam,
            0,
            PredictionStatus.ENABLE
        );
        withdrawable[msg.sender][_idx] = true;
        nPredictions++;
        emit PredictionCreated(_idx, msg.sender, _matchId, _minPredict, _hardCap, _handicap);
    }

    function cancelPrediction(uint256 _predictionId) external {
        Prediction storage _prediction = predictions[_predictionId];
        require(msg.sender == _prediction.dealer, 'not-dealer');
        require(_prediction.totalUserDeposit == 0, 'user-has-deposit');
        require(_prediction.status == PredictionStatus.ENABLE, '!enable');

        _prediction.status = PredictionStatus.DISABLE;
        transferMoney(msg.sender, _prediction.hardCap);
    }

    function predict(uint256 _predictionId) payable external {
        uint256 _predictValue = msg.value;
        require(_predictValue > 0, 'predict-value = 0');
        Prediction memory _prediction = predictions[_predictionId];
        require(_prediction.dealer != address(0), 'prediction-not-exist');
        require(_prediction.status == PredictionStatus.ENABLE, 'prediction-not-enable');
        require(_prediction.totalUserDeposit + _predictValue <= _prediction.hardCap, 'reach-hard-cap');
        require(_predictValue >= _prediction.minPredict, '< min_predict');

        Match memory _match = matches[_prediction.matchId];
        require(_match.startTime <= block.timestamp && block.timestamp <= _match.endTime, 'invalid-predict-time');

        predictHistories[msg.sender][_predictionId].push(PredictHistory(_predictValue, block.timestamp));
        predictInternal(_predictionId, msg.sender, _predictValue);
        emit PredictCreated(msg.sender, _predictionId, _predictValue);
    }

    function claimReward(uint256 _predictionId) external {
        Prediction memory _prediction = predictions[_predictionId];
        Match memory _match = matches[_prediction.matchId];
        Score memory _score = _match.score;
        Handicap memory _handicap = _prediction.handicap;

        require(_match.status == MatchStatus.FINISH, 'match-not-finish');
        require(_match.endTime <= block.timestamp, 'end_time > timestamp');

        PredictionStats storage _predictionStats = predictionStats[msg.sender][_predictionId];
        if (_predictionStats.availableAmount > 0) {
            uint256 _reward = calculateReward(_score, _handicap, _predictionStats.availableAmount, 3 - _prediction.chosenTeam);
            _predictionStats.availableAmount = 0;
            if (_reward > 0) {
                transferMoney(msg.sender, _reward);
            }
        }
    }

    function dealerWithdraw(uint256 _predictionId) external {
        Prediction memory _prediction = predictions[_predictionId];
        require(msg.sender == _prediction.dealer, 'not-dealer');
        Match memory _match = matches[_prediction.matchId];
        Score memory _score = _match.score;
        Handicap memory _handicap = _prediction.handicap;

        require(_match.status == MatchStatus.FINISH, 'match-not-finish');
        require(_match.endTime <= block.timestamp, 'end_time > timestamp');
        require(withdrawable[msg.sender][_predictionId], 'can_not-withdraw');

        uint256 _totalUserReward = calculateReward(_score, _handicap, _prediction.totalUserDeposit, 3 -  _prediction.chosenTeam);

        if (_prediction.hardCap + _prediction.totalUserDeposit >= _totalUserReward) {
            transferMoney(msg.sender, _prediction.hardCap + _prediction.totalUserDeposit - _totalUserReward);
            withdrawable[msg.sender][_predictionId] = false;
        }
    }

    function calculateReward(Score memory _score, Handicap memory _handicap, uint256 _amount, uint256 _option)
    public pure returns(uint256)
    {
        if (_option == 1 || _option == 2) {
            //calculate win-side  1 - first | 2 - second
            uint256 _reward = 0;
            uint256 _winSide = 1;
            if (_score.firstTeam < _score.secondTeam) {
                _winSide++;
            }
            uint256 _diffScore = getDiffScore(_score);
            uint256 _integerPath = getIntegerPath(_handicap.value);
            uint256 _fractionalPath = getFractionalPath(_handicap.value);

            if (_fractionalPath == 0) {
                if (_diffScore == _integerPath) {
                    _reward = _amount;
                }
                if (_diffScore > _integerPath && _option == _winSide) {
                    _reward = _amount * 2;
                }
            }
            if (_fractionalPath == 2500) {
                if (_diffScore == _integerPath) {
                    _reward = _amount / 2 + _amount * (1 - isWin(_option, _winSide));
                }
                if (_diffScore > _integerPath && _option == _winSide) {
                    _reward = _amount * 2;
                }
            }
            if (_fractionalPath == 5000) {
                if (_diffScore > _integerPath && _option == _winSide) {
                    _reward = _amount * 2;
                }
            }
            if (_fractionalPath == 7500) {
                if (_diffScore == _integerPath + 1) {
                    _reward = _amount / 2 + _amount * isWin(_option, _winSide);
                }
                if (_diffScore > (_integerPath + 1) && _option == _winSide) {
                    _reward = _amount * 2;
                }
            }
            return _reward;
        }
        return 0;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setAdminPermission(address _admin, bool _status) external onlyOwner {
        admins[_admin] = _status;
    }

    function createMatches(bytes32[] calldata _descriptions, uint256[] calldata _startTimes, uint256[] calldata _endTimes)
    external onlyOwnerOrAdmin
    returns (uint256[] memory)
    {
        uint256[] memory _ids = new uint[](_descriptions.length);
        require(_descriptions.length == _startTimes.length && _startTimes.length == _endTimes.length, 'not-same-size');
        require(_descriptions.length > 0, 'size = 0');
        for (uint256 i = 0; i < _descriptions.length; i++) {
            _ids[i] = createSingleMatch(_descriptions[i], _startTimes[i], _endTimes[i]);
        }
        return _ids;
    }

    function updateMatchScores(uint256[] calldata _matchIds, uint256[] calldata _point1, uint256[] calldata _point2)
    external onlyOwnerOrAdmin {
        require(_matchIds.length > 0, 'size = 0');
        require(_matchIds.length == _point1.length && _point1.length == _point2.length, 'not-same-size');

        for (uint256 i = 0; i < _matchIds.length; i++) {
            updateMatchScore(_matchIds[i], Score(_point1[i], _point2[i]));
        }
    }

    function updateMatchStatuses(uint256[] memory _matchIds, uint256[] memory _status)
    external onlyOwnerOrAdmin
    {
        require(_matchIds.length > 0, 'size = 0');
        require(_matchIds.length == _status.length, 'not-same-size');
        for (uint256 i = 0; i < _matchIds.length; i++) {
            updateMatchStatus(_matchIds[i], _status[i]);
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function createSingleMatch(bytes32 _description, uint256 _startTime, uint256 _endTime) internal returns(uint256 _idx)
    {
        _idx = nMatches;
        matches[_idx] = Match(
            _description,
            _startTime,
            _endTime,
            Score(0, 0),
            MatchStatus.AVAILABLE
        );
        nMatches++;
        emit MatchCreated(_idx, _description, _startTime, _endTime);
    }

    function updateMatchScore(uint256 _matchId, Score memory _score) internal {
        Match storage _match = matches[_matchId];
        _match.score = _score;
        emit MatchScoreUpdated(msg.sender, _matchId, _score);
    }

    function updateMatchStatus(uint256 _matchId, uint256 _status) internal {
        Match storage _match = matches[_matchId];
        _match.status = MatchStatus(_status);
        emit MatchStatusUpdated(msg.sender, _matchId, _status);
    }

    function predictInternal(uint256 _predictionId, address _predictor, uint256 _predictValue) internal {
        PredictionStats storage _predictionStats = predictionStats[_predictor][_predictionId];
        _predictionStats.totalAmount += _predictValue;
        _predictionStats.availableAmount += _predictValue;
        Prediction storage _prediction = predictions[_predictionId];
        _prediction.totalUserDeposit += _predictValue;
    }

    function transferMoney(address _toAddress, uint256 _amount) internal {
        payable(_toAddress).transfer(_amount);
    }


    function getDiffScore(Score memory _score) internal pure returns(uint256 _res) {
        _res = _score.firstTeam > _score.secondTeam ? _score.firstTeam - _score.secondTeam : _score.secondTeam - _score.firstTeam;
    }

    function getIntegerPath(uint256 _num) internal pure returns(uint256) {
        return _num / ZOOM;
    }

    function getFractionalPath(uint256 _num) internal pure returns(uint256) {
        return _num % ZOOM;
    }

    function isWin(uint256 _option, uint256 _winSide) internal pure returns(uint256) {
        if (_option == _winSide) {
            return 1;
        }
        return 0;
    }

    /* =============== EVENTS ==================== */

    event PredictCreated(address predicttor, uint256 predictionId, uint256 predictValue);
    event PredictionCreated(uint256 idx, address dealer, uint256 matchId, uint256 minPredict, uint256 hardCap, Handicap handicap);
    event MatchScoreUpdated(address caller, uint256 matchId, Score score);
    event MatchStatusUpdated(address caller, uint256 matchId, uint256 status);
    event MatchCreated(uint256 idx, bytes32 descriptions, uint256 startTime, uint256 endTime);
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

    constructor () {
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

