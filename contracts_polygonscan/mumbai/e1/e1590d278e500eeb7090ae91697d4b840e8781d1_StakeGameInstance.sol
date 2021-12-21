/**
 *Submitted for verification at polygonscan.com on 2021-12-20
*/

// File: Math.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}
// File: interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// File: interfaces/ITheFrontMan.sol

// contracts/TheFrontMan.sol


pragma solidity ^0.8.0;


interface ITheFrontMan {
    function newGame(address[] memory tokens, uint256[] memory pPrizeAmounts, uint64 pStartTime, uint8 pTotalEpochs, uint32 pEpochDuration, uint8 pGameTax, uint8 pVolatility, uint8 pTokenRand, uint256[] memory pMedian) external returns (address gameInstance);
    function gameCount() external view returns (uint256);
    function gameById(uint256 gameId) external view returns (address);
    function stake(uint256 gameId) external;
    function transfer(address tokenAddress, address to, uint256 amount) external;
}
// File: interfaces/IStakeGameInstance.sol


// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

interface IStakeGameInstance {
    function tokens() external view returns (address[] memory);
    function reserves() external view returns (uint256[] memory);
    function startTime() external view returns (uint64);
    function totalEpochs() external view returns (uint8);
    function epochDuration() external view returns (uint32);
    function endedByVote() external view returns (bool);
    function gameStarted() external view returns (bool);
    function gameEnded() external view returns (bool);
    function isAliveAtEpoch(address player, uint8 epochIndex) external view returns (bool);
    function canStakeAtEpoch(address player, uint8 epochIndex) external view returns (bool);
    function hasStakedAtEpoch(address player, uint8 epochIndex) external view returns (bool);
    function hasVotedAtEpoch(address player, uint8 epochIndex) external view returns (bool);
    function currentEpochIndex() external view returns (uint8);
    function amountsToStakeForEpoch(uint8 epochIndex) external view returns (uint256[] memory);
    function _stake(uint256[] memory amountsStaked, address player, uint8 epochIndex) external;
    function vote() external;
    function claimTokens() external;
    function _totalSharePerPlayer(uint8 epochIndex) external view returns (uint256);
    function globalShare() external view returns (uint256);

}
// File: StakeGameInstance.sol


// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;





contract StakeGameInstance is IStakeGameInstance {
    struct PlayerStatus {
        uint64 stakedAt;
        uint64 votedAt;
        uint64 claimedAt;
   }

   struct EpochStatus {
        uint32 playerCount;
        uint32 voteCount;
        uint256 totalSharePerPlayer;
   }

    uint64 private _startTime;
    address private _theFrontMan;
    uint8 private _totalEpochs;
    uint32 private _epochDuration;
    uint16 private _gameTax;
    uint8 private _volatility;
    uint8 private _tokenRand;
    uint256[] private _medians;

    uint8 _endedByVoteAtEpoch;


    mapping(address => PlayerStatus) private _playerStatus;
    mapping(uint8 => EpochStatus) private _epochStatus;

    address[] private _tokens;
    uint256[] private _prizeAmounts;
    uint256[] private _totalReserve;
    uint256 private _globalShare;


    modifier isTheFrontMan {
        require(msg.sender == _theFrontMan, "FrontMan call contract only");
        _;
    }

    modifier hasNotClaimed {
        require(_playerStatus[msg.sender].claimedAt == 0, "Player has already claimed");
        _;
        _playerStatus[msg.sender].claimedAt = uint64(block.timestamp);
    }

    constructor(address[] memory pTokens, uint256[] memory pPrizeAmounts, uint64 pStartTime, uint8 pTotalEpochs, uint32 pEpochDuration, uint8 pGameTax, uint8 pVolatility, uint8 pTokenRand, uint256[] memory pMedian) {
        _theFrontMan = msg.sender;
        _tokens = pTokens;
        _prizeAmounts = pPrizeAmounts;
        _startTime = pStartTime;
        _totalEpochs = pTotalEpochs;
        _epochDuration = pEpochDuration;
        _gameTax = pGameTax;
        _volatility = pVolatility;
        _tokenRand = pTokenRand;
        _medians = pMedian;
    }

    function _totalSharePerPlayer(uint8 epochIndex) external view override returns (uint256) {
        return _epochStatus[epochIndex].totalSharePerPlayer;
    }

    function globalShare() external view override returns (uint256) {
        return _globalShare;
    }

    function _gameStartedAtTime(uint256 time) private view returns (bool) {
        return time >= _startTime;
    }

    function _gameEndedAtTime(uint256 time) private view returns (bool) {
        return time >= (_startTime + _totalEpochs * _epochDuration) || _endedByVoteAtEpoch != 0;
    }

    function _startTimeForEpoch(uint8 epochIndex) private view returns (uint64) {
        return _startTime + _epochDuration * epochIndex;
    }

    function _isAliveAtEpoch(address player, uint8 epochIndex) private view returns (bool) {
        if (epochIndex > 0) {
            return _playerStatus[player].stakedAt >= _startTimeForEpoch(epochIndex - 1);
        }
        return true;
    }

    function _hasStakedAtEpoch(address player, uint8 epochIndex) private view returns (bool) {
        return _playerStatus[player].stakedAt >= _startTimeForEpoch(epochIndex);
    }

    function _canStakeAtEpoch(address player, uint8 epochIndex) private view returns (bool) {
        return _isAliveAtEpoch(player, epochIndex) && !_hasStakedAtEpoch(player, epochIndex);
    }

    function _hasVotedAtEpoch(address player, uint8 epochIndex) private view returns (bool) {
        return _playerStatus[player].votedAt >= _startTimeForEpoch(epochIndex);
    }

    function _epochForTime(uint256 time) private view returns (uint8) {
        return _gameStartedAtTime(time) ?
            uint8(Math.min((time - _startTime) / _epochDuration, _endedByVoteAtEpoch > 0 ?
                _endedByVoteAtEpoch
                : _totalEpochs - 1))
            : 0;
    }

    function tokens() external view override returns (address[] memory) {
        return _tokens;
    }

    function reserves() external view override returns (uint256[] memory) {
        return _totalReserve;
    }

    function prizeAmounts() external view returns (uint256[] memory) {
        return _prizeAmounts;
    }

    function startTime() external view override returns (uint64) {
        return _startTime;
    }

    function totalEpochs() external view override returns (uint8) {
        return _totalEpochs;
    }

    function epochDuration() external view override returns (uint32) {
        return _epochDuration;
    }

    function endedByVote() external view override returns (bool) {
        return _endedByVoteAtEpoch > 0;
    }

    function gameTax() external view returns (uint16) {
        return _gameTax;
    }

    function gameStarted() external view override returns (bool) {
        return _gameStartedAtTime(block.timestamp);
    }

    function gameEnded() external view override returns (bool) {
        return _gameEndedAtTime(block.timestamp);
    }

    function isAliveAtEpoch(address player, uint8 epochIndex) external view override returns (bool) {
        return _isAliveAtEpoch(player, epochIndex);
    }

    function canStakeAtEpoch(address player, uint8 epochIndex) external view override returns (bool) {
        return _canStakeAtEpoch(player, epochIndex);
    }

    function hasStakedAtEpoch(address player, uint8 epochIndex) external view override returns (bool) {
        return _hasStakedAtEpoch(player, epochIndex);
    }

    function hasVotedAtEpoch(address player, uint8 epochIndex) external view override returns (bool) {
        return _hasVotedAtEpoch(player, epochIndex);
    }

    function currentEpochIndex() external view override returns (uint8) {
        return _epochForTime(block.timestamp);
    }

    function amountsToStakeForEpoch(uint8 epochIndex) external view override returns (uint256[] memory) {
        uint256[] memory amounts = new uint[](_tokens.length);

        if (epochIndex > 0 ) {
            for (uint256 i = 0; i < _tokens.length; i++) {
                string memory seed = string(abi.encodePacked(_tokens[i], (_startTime + (_epochDuration * epochIndex)), _epochStatus[epochIndex - 1].playerCount, _epochStatus[epochIndex - 1].voteCount));
                amounts[i] = _GaussianRNG(seed, _volatility, _medians[i], _tokenRand);
            }
        } else {
            for (uint256 i = 0; i < _tokens.length; i++) {
                string memory seed = string(abi.encodePacked(_tokens[i], _startTime));
                amounts[i] = _GaussianRNG(seed, _volatility, _medians[i], _tokenRand);
            }            
        }
        return amounts;
    }

    function _GaussianRNG(string memory seed, uint8 volatility, uint256 median,uint256 tokenRand) internal pure returns (uint256 resultGaussian) {
        uint256 _num = uint256(keccak256(abi.encodePacked(seed)));
        if (_countOnes(_num) < tokenRand ) {
            uint256 random = uint256(keccak256(abi.encodePacked(_num)));
            resultGaussian = uint256((_countOnes(random) ** volatility) * median / (128 ** volatility));
        } else {
            resultGaussian = 0;
        }  
        return resultGaussian;
    }

    function _countOnes(uint256 n) internal pure returns (uint256 count) {
        assembly {
            for { } gt(n, 0) { } {
                n := and(n, sub(n, 1))
                count := add(count, 1)
            }
        }
    }

    function _stake(uint256[] memory amountsStaked, address player, uint8 epochIndex) external override isTheFrontMan {
        PlayerStatus storage playerStatus = _playerStatus[player];
        EpochStatus storage epochStatus = _epochStatus[epochIndex];
        uint256 _totalSharePlayer;

        playerStatus.stakedAt = uint64(block.timestamp);
        epochStatus.playerCount += 1;
        for (uint256 i = 0; i < _tokens.length; i++) {
            _totalReserve[i] += amountsStaked[i];
            _totalSharePlayer += amountsStaked[i];
        }   

        if (epochStatus.totalSharePerPlayer == 0 && epochIndex == 0) {
            epochStatus.totalSharePerPlayer = _totalSharePlayer; 
        }  else if (epochStatus.totalSharePerPlayer == 0)  {
            epochStatus.totalSharePerPlayer = _epochStatus[epochIndex - 1].totalSharePerPlayer + _totalSharePlayer; 
        }
        _globalShare += _totalSharePlayer;
    }

    function vote() external override {
        uint8 epochIndex = _epochForTime(block.timestamp);
        require(epochIndex > 0, "Can't vote at epoch 0");
        require(_isAliveAtEpoch(msg.sender, epochIndex) == true, "Player is not alive");
        require(_hasVotedAtEpoch(msg.sender, epochIndex) == false, "Player already voted");

        _playerStatus[msg.sender].votedAt = uint64(block.timestamp);
        _epochStatus[epochIndex].voteCount += 1;

        uint32 totalVotes = _epochStatus[epochIndex].voteCount;
        uint32 totalPlayers = _epochStatus[epochIndex - 1].playerCount;

        if (totalPlayers / totalVotes < 2) {
            _endedByVoteAtEpoch = epochIndex;
        }
    }

    // claim when game stopped by vote
    function _claimToken1() private {
        require(_isAliveAtEpoch(msg.sender, _endedByVoteAtEpoch), "Player is not alive");

        EpochStatus storage epochStatus_A = _epochStatus[_endedByVoteAtEpoch];
        EpochStatus storage epochStatus_B = _epochStatus[_endedByVoteAtEpoch - 1];
        
        PlayerStatus storage playerStatus = _playerStatus[msg.sender];
        uint256 totalPlayerShare;

        uint256 deadShareReserve = _globalShare - (((epochStatus_B.playerCount - epochStatus_A.playerCount) * epochStatus_B.totalSharePerPlayer) + (epochStatus_A.playerCount * epochStatus_A.totalSharePerPlayer));

        if (playerStatus.stakedAt < (_startTime + (_epochDuration * _endedByVoteAtEpoch))) {
            totalPlayerShare = epochStatus_B.totalSharePerPlayer ;
        } else {
            totalPlayerShare = epochStatus_A.totalSharePerPlayer ;
        }

        uint256 playerShare = totalPlayerShare * 10**6 / _globalShare;
        uint256 deadShare = deadShareReserve * 10**6 / _globalShare;

        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 totalReserve = _prizeAmounts[i] + _totalReserve[i];
            uint256 playerAmount = playerShare * totalReserve / 10**6 ;
            uint256 taxAmount = playerAmount * _gameTax / 1000 ;
            uint256 leftOverAmount = ((deadShare  * _totalReserve[i] / 10**6 + _prizeAmounts[i]) / epochStatus_B.playerCount) + taxAmount ;

            IERC20(_tokens[i]).transfer(msg.sender, playerAmount - taxAmount);
            IERC20(_tokens[i]).transfer(_theFrontMan, leftOverAmount);
        }
    }

    // claim when game stopped normally
    function _claimToken2() private {
        require(_hasStakedAtEpoch(msg.sender, _totalEpochs - 1), "Player is not alive");
        EpochStatus storage epochStatus = _epochStatus[_totalEpochs - 1];

        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 totalReserve = _prizeAmounts[i] + _totalReserve[i];
            uint256 playerShare = totalReserve / epochStatus.playerCount;
            uint256 taxAmount = playerShare * _gameTax / 1000;
            IERC20(_tokens[i]).transfer(msg.sender, playerShare - taxAmount);
            IERC20(_tokens[i]).transfer(_theFrontMan, taxAmount);
        }
    }

    function claimTokens() external override hasNotClaimed {
        require(_gameEndedAtTime(block.timestamp) == true, "Game still in progress");

        if (_endedByVoteAtEpoch > 0) {
            _claimToken1();
        } else {
            _claimToken2();
        }
    }
}