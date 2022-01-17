pragma solidity ^0.8.0;

// external
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

// interfaces
import "../interfaces/IPriceFeed.sol";

// internal
import "../utils/proxy/solidity-0.8.0/ProxyReentrancyGuard.sol";
import "../utils/proxy/solidity-0.8.0/ProxyOwned.sol";

contract ThalesRoyale is Initializable, ProxyOwned, PausableUpgradeable, ProxyReentrancyGuard {
    /* ========== LIBRARIES ========== */

    using SafeMathUpgradeable for uint;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== CONSTANTS =========== */

    uint public constant DOWN = 1;
    uint public constant UP = 2;

    /* ========== STATE VARIABLES ========== */

    IERC20Upgradeable public rewardToken;
    bytes32 public oracleKey;
    IPriceFeed public priceFeed;

    address public safeBox;
    uint public safeBoxPercentage;

    uint public rounds;
    uint public signUpPeriod;
    uint public roundChoosingLength;
    uint public roundLength;

    bool public nextSeasonStartsAutomatically;
    uint public pauseBetweenSeasonsTime;

    uint public roundTargetPrice;
    uint public buyInAmount;

    /* ========== SEASON VARIABLES ========== */

    uint public season;

    mapping(uint => uint) public rewardPerSeason;
    mapping(uint => uint) public signedUpPlayersCount;
    mapping(uint => uint) public roundInASeason;
    mapping(uint => bool) public seasonStarted;
    mapping(uint => bool) public seasonFinished;
    mapping(uint => uint) public seasonCreationTime;
    mapping(uint => bool) public royaleInSeasonStarted;
    mapping(uint => uint) public royaleSeasonEndTime;
    mapping(uint => uint) public roundInSeasonEndTime;
    mapping(uint => uint) public roundInASeasonStartTime;
    mapping(uint => address[]) public playersPerSeason;
    mapping(uint => mapping(address => uint256)) public playerSignedUpPerSeason;
    mapping(uint => mapping(uint => uint)) public roundResultPerSeason;
    mapping(uint => mapping(uint => uint)) public targetPricePerRoundPerSeason;
    mapping(uint => mapping(uint => uint)) public finalPricePerRoundPerSeason;
    mapping(uint => mapping(uint256 => mapping(uint256 => uint256))) public positionsPerRoundPerSeason;
    mapping(uint => mapping(uint => uint)) public totalPlayersPerRoundPerSeason;
    mapping(uint => mapping(uint => uint)) public eliminatedPerRoundPerSeason;

    mapping(uint => mapping(address => mapping(uint256 => uint256))) public positionInARoundPerSeason;
    mapping(uint => mapping(address => bool)) public rewardCollectedPerSeason;
    mapping(uint => uint) public rewardPerWinnerPerSeason;
    mapping(uint => uint) public unclaimedRewardPerSeason;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _owner,
        bytes32 _oracleKey,
        IPriceFeed _priceFeed,
        address _rewardToken,
        uint _rounds,
        uint _signUpPeriod,
        uint _roundChoosingLength,
        uint _roundLength,
        uint _buyInAmount,
        uint _pauseBetweenSeasonsTime,
        bool _nextSeasonStartsAutomatically
    ) public initializer {
        setOwner(_owner);
        initNonReentrant();
        oracleKey = _oracleKey;
        priceFeed = _priceFeed;
        rewardToken = IERC20Upgradeable(_rewardToken);
        rounds = _rounds;
        signUpPeriod = _signUpPeriod;
        roundChoosingLength = _roundChoosingLength;
        roundLength = _roundLength;
        buyInAmount = _buyInAmount;
        pauseBetweenSeasonsTime = _pauseBetweenSeasonsTime;
        nextSeasonStartsAutomatically = _nextSeasonStartsAutomatically;
    }

    /* ========== GAME ========== */

    function signUp() external {
        require(season > 0, "Initialize first season");
        require(block.timestamp < (seasonCreationTime[season] + signUpPeriod), "Sign up period has expired");
        require(playerSignedUpPerSeason[season][msg.sender] == 0, "Player already signed up");
        require(rewardToken.balanceOf(msg.sender) >= buyInAmount, "No enough sUSD for buy in");
        require(rewardToken.allowance(msg.sender, address(this)) >= buyInAmount, "No allowance.");

        playerSignedUpPerSeason[season][msg.sender] = block.timestamp;
        playersPerSeason[season].push(msg.sender);
        signedUpPlayersCount[season]++;

        _buyIn(msg.sender, buyInAmount);

        emit SignedUp(msg.sender, season);
    }

    function startRoyaleInASeason() external {
        require(block.timestamp > (seasonCreationTime[season] + signUpPeriod), "Can't start until signup period expires");
        require(signedUpPlayersCount[season] > 0, "Can not start, no players in a season");
        require(!royaleInSeasonStarted[season], "Already started");

        roundTargetPrice = priceFeed.rateForCurrency(oracleKey);
        roundInASeason[season] = 1;
        targetPricePerRoundPerSeason[season][roundInASeason[season]] = roundTargetPrice;
        royaleInSeasonStarted[season] = true;
        roundInASeasonStartTime[season] = block.timestamp;
        roundInSeasonEndTime[season] = roundInASeasonStartTime[season] + roundLength;
        totalPlayersPerRoundPerSeason[season][roundInASeason[season]] = signedUpPlayersCount[season];
        unclaimedRewardPerSeason[season] = rewardPerSeason[season];

        emit RoyaleStarted(season, signedUpPlayersCount[season], rewardPerSeason[season]);
    }

    function takeAPosition(uint position) external {
        require(position == DOWN || position == UP, "Position can only be 1 or 2");
        require(royaleInSeasonStarted[season], "Competition not started yet");
        require(!seasonFinished[season], "Competition finished");
        require(playerSignedUpPerSeason[season][msg.sender] != 0, "Player did not sign up");
        require(positionInARoundPerSeason[season][msg.sender][roundInASeason[season]] != position, "Same position");

        if (roundInASeason[season] != 1) {
            require(
                positionInARoundPerSeason[season][msg.sender][roundInASeason[season] - 1] ==
                    roundResultPerSeason[season][roundInASeason[season] - 1],
                "Player no longer alive"
            );
        }

        require(block.timestamp < roundInASeasonStartTime[season] + roundChoosingLength, "Round positioning finished");

        // this block is when sender change positions in a round - first reduce
        if (positionInARoundPerSeason[season][msg.sender][roundInASeason[season]] == DOWN) {
            positionsPerRoundPerSeason[season][roundInASeason[season]][DOWN]--;
        } else if (positionInARoundPerSeason[season][msg.sender][roundInASeason[season]] == UP) {
            positionsPerRoundPerSeason[season][roundInASeason[season]][UP]--;
        }

        // set new value
        positionInARoundPerSeason[season][msg.sender][roundInASeason[season]] = position;

        // add number of positions
        if (position == UP) {
            positionsPerRoundPerSeason[season][roundInASeason[season]][position]++;
        } else {
            positionsPerRoundPerSeason[season][roundInASeason[season]][position]++;
        }

        emit TookAPosition(msg.sender, season, roundInASeason[season], position);
    }

    function closeRound() external {
        require(royaleInSeasonStarted[season], "Competition not started yet");
        require(!seasonFinished[season], "Competition finished");
        require(block.timestamp > (roundInASeasonStartTime[season] + roundLength), "Can't close round yet");

        uint currentSeasonRound = roundInASeason[season];
        uint nextRound = currentSeasonRound + 1;

        // getting price
        uint currentPriceFromOracle = priceFeed.rateForCurrency(oracleKey);

        finalPricePerRoundPerSeason[season][currentSeasonRound] = currentPriceFromOracle;
        roundResultPerSeason[season][currentSeasonRound] = currentPriceFromOracle >= roundTargetPrice ? UP : DOWN;
        roundTargetPrice = currentPriceFromOracle;

        uint winningPositionsPerRound = roundResultPerSeason[season][currentSeasonRound] == UP
            ? positionsPerRoundPerSeason[season][currentSeasonRound][UP]
            : positionsPerRoundPerSeason[season][currentSeasonRound][DOWN];

        if (nextRound <= rounds) {
            // setting total players for next round (round + 1) to be result of position in a previous round
            totalPlayersPerRoundPerSeason[season][nextRound] = winningPositionsPerRound;
        }

        // setting eliminated players to be total players - number of winning players
        eliminatedPerRoundPerSeason[season][currentSeasonRound] =
            totalPlayersPerRoundPerSeason[season][currentSeasonRound] -
            winningPositionsPerRound;

        // if no one is left no need to set values
        if (winningPositionsPerRound > 0) {
            roundInASeason[season] = nextRound;
            targetPricePerRoundPerSeason[season][nextRound] = roundTargetPrice;
        }

        if (nextRound > rounds || winningPositionsPerRound <= 1) {
            seasonFinished[season] = true;

            uint numberOfWinners = 0;

            // in no one is winner pick from lest round
            if (winningPositionsPerRound == 0) {
                numberOfWinners = totalPlayersPerRoundPerSeason[season][currentSeasonRound];
                _populateReward(numberOfWinners);
            } else {
                // there is min 1 winner
                numberOfWinners = winningPositionsPerRound;
                _populateReward(numberOfWinners);
            }

            royaleSeasonEndTime[season] = block.timestamp;
            // first close previous round then royale
            emit RoundClosed(season, currentSeasonRound, roundResultPerSeason[season][currentSeasonRound]);
            emit RoyaleFinished(season, numberOfWinners, rewardPerWinnerPerSeason[season]);
        } else {
            roundInASeasonStartTime[season] = block.timestamp;
            roundInSeasonEndTime[season] = roundInASeasonStartTime[season] + roundLength;
            emit RoundClosed(season, currentSeasonRound, roundResultPerSeason[season][currentSeasonRound]);
        }
    }

    function startNewSeason() external seasonCanStart {
        season = season + 1;
        seasonCreationTime[season] = block.timestamp;
        seasonStarted[season] = true;

        emit NewSeasonStarted(season);
    }

    function claimRewardForSeason(uint _season) external onlyWinners(_season) {
        _claimRewardForSeason(msg.sender, _season);
    }

    /* ========== VIEW ========== */

    function canCloseRound() public view returns (bool) {
        return
            royaleInSeasonStarted[season] &&
            !seasonFinished[season] &&
            block.timestamp > (roundInASeasonStartTime[season] + roundLength);
    }

    function canStartRoyale() public view returns (bool) {
        return !royaleInSeasonStarted[season] && block.timestamp > (seasonCreationTime[season] + signUpPeriod);
    }

    function canStartNewSeason() public view returns (bool) {
        return nextSeasonStartsAutomatically && block.timestamp > seasonCreationTime[season] + pauseBetweenSeasonsTime;
    }

    function hasParticipatedInCurrentOrLastRoyale(address _player) public view returns (bool) {
        if (season > 1) {
            return playerSignedUpPerSeason[season][_player] > 0 || playerSignedUpPerSeason[season - 1][_player] > 0;
        } else {
            return playerSignedUpPerSeason[season][_player] > 0;
        }
    }

    function isPlayerAliveInASpecificSeason(address player, uint _season) public view returns (bool) {
        if (roundInASeason[_season] > 1) {
            return (positionInARoundPerSeason[_season][player][roundInASeason[_season] - 1] ==
                roundResultPerSeason[_season][roundInASeason[_season] - 1]);
        } else {
            return playerSignedUpPerSeason[_season][player] != 0;
        }
    }

    function isPlayerAlive(address player) public view returns (bool) {
        if (roundInASeason[season] > 1) {
            return (positionInARoundPerSeason[season][player][roundInASeason[season] - 1] ==
                roundResultPerSeason[season][roundInASeason[season] - 1]);
        } else {
            return playerSignedUpPerSeason[season][player] != 0;
        }
    }

    function getPlayersForSeason(uint _season) public view returns (address[] memory) {
        return playersPerSeason[_season];
    }

    /* ========== INTERNALS ========== */

    function _populateReward(uint numberOfWinners) internal {
        require(seasonFinished[season], "Royale must be finished");
        require(numberOfWinners > 0, "There is no alive players left in Royale");

        rewardPerWinnerPerSeason[season] = rewardPerSeason[season].div(numberOfWinners);
    }

    function _buyIn(address _sender, uint _amount) internal {
        (uint amountBuyIn, uint amountSafeBox) = _calculateSafeBoxOnAmount(_amount);

        if (amountSafeBox > 0) {
            rewardToken.safeTransferFrom(_sender, safeBox, amountSafeBox);
        }

        rewardToken.safeTransferFrom(_sender, address(this), amountBuyIn);
        rewardPerSeason[season] += amountBuyIn;
    }

    function _calculateSafeBoxOnAmount(uint _amount) internal view returns (uint, uint) {
        uint amountSafeBox = 0;

        if (safeBoxPercentage > 0) {
            amountSafeBox = _amount.div(100).mul(safeBoxPercentage);
        }

        uint amountBuyIn = _amount.sub(amountSafeBox);

        return (amountBuyIn, amountSafeBox);
    }

    function _claimRewardForSeason(address _winner, uint _season) internal {
        require(rewardPerSeason[_season] > 0, "Reward must be set");
        require(!rewardCollectedPerSeason[_season][_winner], "Player already collected reward");
        require(rewardToken.balanceOf(address(this)) >= rewardPerWinnerPerSeason[_season], "Not enough balance for rewards");

        // set collected -> true
        rewardCollectedPerSeason[_season][_winner] = true;

        unclaimedRewardPerSeason[_season] = unclaimedRewardPerSeason[_season].sub(rewardPerWinnerPerSeason[_season]);

        // transfering rewardPerPlayer
        rewardToken.safeTransfer(_winner, rewardPerWinnerPerSeason[_season]);

        // emit event
        emit RewardClaimed(_season, _winner, rewardPerWinnerPerSeason[_season]);
    }

    function _putFunds(
        address _from,
        uint _amount,
        uint _season
    ) internal {
        rewardPerSeason[_season] = rewardPerSeason[_season] + _amount;
        rewardToken.safeTransferFrom(_from, address(this), _amount);
        emit PutFunds(_from, _season, _amount);
    }

    /* ========== CONTRACT MANAGEMENT ========== */

    function putFunds(uint _amount, uint _season) external {
        require(_amount > 0, "Amount must be more then zero");
        require(_season >= season, "Cant put funds in a past");
        require(rewardToken.allowance(msg.sender, address(this)) >= buyInAmount, "No allowance.");

        _putFunds(msg.sender, _amount, _season);
    }

    function setNextSeasonStartsAutomatically(bool _nextSeasonStartsAutomatically) public onlyOwner {
        nextSeasonStartsAutomatically = _nextSeasonStartsAutomatically;
        emit NewNextSeasonStartsAutomatically(_nextSeasonStartsAutomatically);
    }

    function setPauseBetweenSeasonsTime(uint _pauseBetweenSeasonsTime) public onlyOwner {
        pauseBetweenSeasonsTime = _pauseBetweenSeasonsTime;
        emit NewPauseBetweenSeasonsTime(_pauseBetweenSeasonsTime);
    }

    function setSignUpPeriod(uint _signUpPeriod) public onlyOwner {
        signUpPeriod = _signUpPeriod;
        emit NewSignUpPeriod(_signUpPeriod);
    }

    function setRoundChoosingLength(uint _roundChoosingLength) public onlyOwner {
        roundChoosingLength = _roundChoosingLength;
        emit NewRoundChoosingLength(_roundChoosingLength);
    }

    function setRoundLength(uint _roundLength) public onlyOwner {
        roundLength = _roundLength;
        emit NewRoundLength(_roundLength);
    }

    function setPriceFeed(IPriceFeed _priceFeed) public onlyOwner {
        priceFeed = _priceFeed;
        emit NewPriceFeed(_priceFeed);
    }

    function setBuyInAmount(uint _buyInAmount) public onlyOwner {
        buyInAmount = _buyInAmount;
        emit NewBuyInAmount(_buyInAmount);
    }

    function setSafeBoxPercentage(uint _safeBoxPercentage) public onlyOwner {
        require(_safeBoxPercentage >= 0 && _safeBoxPercentage <= 100, "Must be in between 0 and 100 %");
        safeBoxPercentage = _safeBoxPercentage;
        emit NewSafeBoxPercentage(_safeBoxPercentage);
    }

    function setSafeBox(address _safeBox) public onlyOwner {
        safeBox = _safeBox;
        emit NewSafeBox(_safeBox);
    }

    /* ========== MODIFIERS ========== */

    modifier seasonCanStart() {
        require(msg.sender == owner || canStartNewSeason(), "Only owner can start season before pause between two seasons");
        require(seasonFinished[season] || season == 0, "Previous season must be finished");
        _;
    }

    modifier onlyWinners(uint _season) {
        require(seasonFinished[_season], "Royale must be finished!");
        require(isPlayerAliveInASpecificSeason(msg.sender, _season) == true, "Player is not alive");
        _;
    }

    /* ========== EVENTS ========== */

    event SignedUp(address user, uint season);
    event RoundClosed(uint season, uint round, uint result);
    event TookAPosition(address user, uint season, uint round, uint position);
    event RoyaleStarted(uint season, uint totalPlayers, uint totalReward);
    event RoyaleFinished(uint season, uint numberOfWinners, uint rewardPerWinner);
    event RewardClaimed(uint season, address winner, uint reward);
    event NewSeasonStarted(uint season);
    event NewBuyInAmount(uint buyInAmount);
    event NewPriceFeed(IPriceFeed priceFeed);
    event NewRoundLength(uint roundLength);
    event NewRoundChoosingLength(uint roundChoosingLength);
    event NewPauseBetweenSeasonsTime(uint pauseBetweenSeasonsTime);
    event NewSignUpPeriod(uint signUpPeriod);
    event NewNextSeasonStartsAutomatically(bool nextSeasonStartsAutomatically);
    event PutFunds(address from, uint season, uint amount);
    event NewSafeBoxPercentage(uint _safeBoxPercentage);
    event NewSafeBox(address _safeBox);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

interface IPriceFeed {
     // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }
    
    // Mutative functions
    function addAggregator(bytes32 currencyKey, address aggregatorAddress) external;

    function removeAggregator(bytes32 currencyKey) external;

    // Views
    function aggregators(bytes32 currencyKey) external view returns (address);

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time);

    function getRates() external view returns (uint[] memory);

    function getCurrencies() external view returns (bytes32[] memory);
}

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ProxyReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;
    bool private _initialized;

    function initNonReentrant() public {
        require(!_initialized, "Already initialized");
        _initialized = true;
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

pragma solidity ^0.8.0;

// Clone of syntetix contract without constructor
contract ProxyOwned {
    address public owner;
    address public nominatedOwner;
    bool private _initialized;
    bool private _transferredAtInit;

    function setOwner(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        require(!_initialized, "Already initialized, use nominateNewOwner");
        _initialized = true;
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    function transferOwnershipAtInit(address proxyAddress) external onlyOwner {
        require(proxyAddress != address(0), "Invalid address");
        require(!_transferredAtInit, "Already transferred");
        owner = proxyAddress;
        _transferredAtInit = true;
        emit OwnerChanged(owner, proxyAddress);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}