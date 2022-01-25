// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

interface Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    //view
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

contract PriceGameV3BscTestnet is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum Stages {
        Initial,
        GenesisRound,
        NormalRound,
        Paused
    }

    enum RoundStages {
        Start,
        Locked,
        Ended
    }

    struct RoundInfo {
        RoundStages stage;
        uint256 epoch;
        uint256 startBlock;
        uint256 startTs;
        uint256 lockBlock;
        uint256 endBlock;
        uint256 lockPrice;
        uint256 closePrice;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        bool pseudoRound;
        uint256 pseudoBullAmount;
        uint256 pseudoBearAmount;
    }
    struct Round {
        RoundInfo base; 
        mapping(uint32 => uint256) bullTokenAmounts;
        mapping(uint32 => uint256) bearTokenAmounts;
        mapping(uint32 => uint256) bullAmounts;
        mapping(uint32 => uint256) bearAmounts;
    }

    enum Position {
        Bull,
        Bear
    }

    struct BetInfo {
        Position position;
        uint256 tokenAmount;
        uint32 tokenIndex;
        uint32 feeRate;
        bool claimed; // default false
    }

    Router public constant router = Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    address public constant WBNB = 0x0d25C3F9bBdb17c7736a54ebd44c203268abc00e;
    address public constant CDZ = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee; // BUSD
    uint32  private constant INDEX_BNB = 0;
    uint32  private constant INDEX_CDZ = 1;
    address[] public tokens;
    bool[]  public enabled;

    uint256 private constant DENOMINATOR = 10000;
    uint32[] public feeRates;

    mapping(uint256 => address[]) private playerList;
    mapping(uint256 => Round) public rounds;
    mapping(uint256 => mapping(address => BetInfo)) public ledger;
    mapping(address => uint256[]) public userRounds;
    Stages public stage;
    uint256 public treasuryAmount;
    uint256 public currentEpoch;
    uint256 public lastActiveEpoch;
    uint256 public currentPrice;
    uint256 public epochBlocks;

    event Claim(
        address indexed sender,
        uint256 indexed currentEpoch,
        uint256 amount
    );
    event StartRound(uint256 indexed epoch, uint256 blockNumber);
    event LockRound(uint256 indexed epoch, uint256 blockNumber, uint256 price);
    event EndRound(uint256 indexed epoch, uint256 blockNumber, uint256 price);
    event Bet(
        address indexed account,
        uint256 indexed currentEpoch,
        address indexed token,
        uint256 tokenAmount,
        uint256 amount,
        bool isBull
    );

    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    function nextStage() internal {
        stage = Stages(uint(stage) + 1);
    }

    function nextEpoch() internal {
        currentEpoch = currentEpoch + 1;
    }

    function initialize(uint256 _epochBlocks) external initializer {
        __Ownable_init();

        epochBlocks = _epochBlocks;
        lastActiveEpoch = 1;
        currentPrice = 100;
        stage = Stages.Initial;

        // The index must be equal to INDEX_BNB
        tokens.push(address(0));
        enabled.push(true);
        feeRates.push(500); // 5%

        // The index must be equal to INDEX_CDZ
        tokens.push(CDZ);
        enabled.push(true);
        feeRates.push(100); // 1%
    }

    function next() external onlyOwner {
        if(stage == Stages.Initial) {
            nextStage();
            nextEpoch();
            _startRound(currentEpoch);
        } else if (stage == Stages.GenesisRound) {
            require(getNextRequiredAssistance() <= 0, "getNextRequiredAssistance() need to be 0 or below");
            _lockRound(currentEpoch);
            nextEpoch();
            _startRound(currentEpoch);
            nextStage();
        } else if (stage == Stages.NormalRound) {
            require(getNextRequiredAssistance() <= 0, "getNextRequiredAssistance() need to be 0 or below");
            _endRound(currentEpoch - 1);
            _calculateRewards(currentEpoch - 1);

            // if (rounds[currentEpoch - 1].base.rewardAmount > 0) {
            //     _distributeRewards(currentEpoch - 1);
            // }

            _lockRound(currentEpoch);
            nextEpoch();
            _startRound(currentEpoch);
        }
    }

    function getUserRounds(
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, BetInfo[] memory, uint256 ) {
        uint256 length = size;

        if (length > userRounds[user].length - cursor) {
            length = userRounds[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        BetInfo[] memory betInfo = new BetInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = userRounds[user][cursor + i];
            betInfo[i] = ledger[values[i]][user];
        }

        return (values, betInfo, cursor + length);
    }

    function betBear(uint32 tokenIndex, uint256 tokenAmount) external payable {
        if (tokenIndex == INDEX_BNB) {
            tokenAmount = msg.value;
        } else {
            address tokenAddress = tokens[tokenIndex];
            require(tokenAddress != address(0), "Invalid tokenIndex");
            IERC20Upgradeable(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenAmount);
        }

        _bet(msg.sender, tokenIndex, tokenAmount, false);
    }

    function betBull(uint32 tokenIndex, uint256 tokenAmount) external payable {
        if (tokenIndex == INDEX_BNB) {
            tokenAmount = msg.value;
        } else {
            address tokenAddress = tokens[tokenIndex];
            require(tokenAddress != address(0), "Invalid tokenIndex");
            IERC20Upgradeable(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenAmount);
        }

        _bet(msg.sender, tokenIndex, tokenAmount, true);
    }

    function _bet(address account, uint32 tokenIndex, uint256 tokenAmount, bool isBull) internal {
        require(ledger[currentEpoch][account].tokenAmount == 0, "Can only bet once per round");
        require(enabled[tokenIndex], "Token disabled");
        require(0 < tokenAmount, "Invalid tokenAmount");

        Round storage round = rounds[currentEpoch];
        require(round.base.stage == RoundStages.Start, "Round not bettable");

        // Update round data
        uint256 amount = getPrincipalOut(tokenIndex, tokenAmount);
        if (isBull) {
            round.bullTokenAmounts[tokenIndex] += tokenAmount;
            round.bullAmounts[tokenIndex] += amount;
            round.base.bullAmount += amount;
        } else {
            round.bearTokenAmounts[tokenIndex] += tokenAmount;
            round.bearAmounts[tokenIndex] += amount;
            round.base.bearAmount += amount;
        }
        round.base.pseudoRound = false;

        // Update user data
        BetInfo storage betInfo = ledger[currentEpoch][account];
        betInfo.position = isBull ? Position.Bull : Position.Bear;
        betInfo.tokenAmount = tokenAmount;
        betInfo.tokenIndex =  tokenIndex;
        betInfo.feeRate = feeRates[tokenIndex];
        userRounds[account].push(currentEpoch);

        playerList[currentEpoch].push(account);

        emit Bet(account, currentEpoch, tokens[tokenIndex], tokenAmount, amount, isBull);
    }

    function _startRound(uint256 epoch) internal {
        Round storage round = rounds[epoch];
        round.base.startBlock = block.number;
        round.base.startTs = block.timestamp;
        round.base.lockBlock = block.number + epochBlocks;
        round.base.endBlock = block.number + epochBlocks * 2;
        round.base.epoch = epoch;
        placePseudoRandomBet();

        emit StartRound(epoch, block.number);
    }

    function _lockRound(uint256 epoch) internal {
        Round storage round = rounds[epoch];

        // convert tokens to the principal toke
        uint256 bullAmount = 0;
        uint256 bearAmount = 0;
        for (uint32 i = 0; i < tokens.length; i ++) {
            if (i == INDEX_CDZ) {
                bullAmount += round.bullAmounts[i];
                bearAmount += round.bearAmounts[i];
            } else {
                if (0 < round.bullTokenAmounts[i]) {
                    uint256 amountOutMin = round.bullAmounts[i] * 98 / 100; // 2% of slippage
                    uint256 amountOut = _swap(tokens[i], CDZ, round.bullTokenAmounts[i], amountOutMin);
                    round.bullAmounts[i] = amountOut;
                    bullAmount += amountOut;
                }
                if (0 < round.bearTokenAmounts[i]) {
                    uint256 amountOutMin = round.bearAmounts[i] * 98 / 100; // 2% of slippage
                    uint256 amountOut = _swap(tokens[i], CDZ, round.bearTokenAmounts[i], amountOutMin);
                    round.bearAmounts[i] = amountOut;
                    bearAmount += amountOut;
                }
            }
        }
        round.base.bullAmount = bullAmount;
        round.base.bearAmount = bearAmount;

        round.base.lockPrice = currentPrice;
        round.base.stage =  RoundStages.Locked;
        round.base.endBlock = block.number + epochBlocks;

        emit LockRound(epoch, block.number, round.base.lockPrice);
    }

    function _endRound(uint256 epoch) internal {
        Round storage round = rounds[epoch];
        round.base.closePrice = currentPrice;
        round.base.stage = RoundStages.Ended;
        lastActiveEpoch = lastActiveEpoch + 1;

        emit EndRound(epoch, block.number, round.base.closePrice);
    }

    function getRound(uint epoch) public view returns(RoundInfo memory) {
        return rounds[epoch].base;
    }

    function getCurrentRound() public view returns(RoundInfo memory) {
        return rounds[currentEpoch].base;
    }

    function getUsersPerRound(uint256 epoch) external view returns (uint256, uint256, address[] memory) {
        RoundInfo memory roundInfo = rounds[epoch].base;
        address[] memory _playerList = playerList[epoch];
        return (roundInfo.startBlock, roundInfo.startTs, _playerList);
    }

    function getRoundTimestamps(
        uint256 startEpoch,
        uint256 size
    ) external view returns (uint256[] memory) {
        uint256 length;

        if (currentEpoch < startEpoch) {
            length = 0;
        } else {
            if (currentEpoch < startEpoch+size) {
                length = currentEpoch - startEpoch + 1;
            } else {
                length = size;
            }
        }

        uint256[] memory values = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = rounds[startEpoch + i].base.startTs;
        }
        return values;
    }

    function getNextRequiredAssistance() public view returns(int256) {
        if (lastActiveEpoch == 0) {
            return int(block.number);
        }
        RoundInfo memory roundInfo = rounds[lastActiveEpoch].base;
        if(roundInfo.stage == RoundStages.Start) {
            return int(roundInfo.lockBlock) - int(block.number);
        } else {
            return int(roundInfo.endBlock) - int(block.number);
        }
    }

    function setCurrentPrice(uint256 price) external onlyOwner {
        currentPrice = price;
    }
    function setBlockLength(uint256 blockLength) external onlyOwner {
        epochBlocks = blockLength;
    }

    function addToken(address tokenAddress, uint32 feeRate) external onlyOwner {
        require(tokenAddress != address(0), "Invalid tokenAddress");
        require(feeRate < DENOMINATOR, "Invalid feeRate");

        tokens.push(tokenAddress);
        enabled.push(true);
        feeRates.push(feeRate);
    }

    function enableToken(uint32 tokenIndex, bool enable) external onlyOwner {
        require(tokenIndex < tokens.length, "Invalid tokenIndex");
        enabled[tokenIndex] = enable;
    }

    function setFeeRate(uint32 tokenIndex, uint32 feeRate) external onlyOwner {
        require(tokenIndex < tokens.length, "Invalid tokenIndex");
        require(feeRate < DENOMINATOR, "Invalid feeRate");
        feeRates[tokenIndex] = feeRate;
    }

    function donateTreasury(uint256 amount) external {
        IERC20Upgradeable(CDZ).safeTransferFrom(msg.sender, address(this), amount);
        treasuryAmount = treasuryAmount + amount;
    }

    function claimTreasury(address payable _to) external onlyOwner {
        IERC20Upgradeable(CDZ).safeTransfer(_to, treasuryAmount);
        treasuryAmount = 0;
    }

    function getRandomNumber() public view returns (uint) {
        uint hashBlock = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, currentEpoch)));
        uint result = hashBlock % 99;
        if (result != 0) {
            return result;
        } else {
            return 32;
        }
    }

    function placePseudoRandomBet() internal {
        uint256 randomNumber = getRandomNumber();
        uint256 amountBull = randomNumber * 10 ** 13;
        uint256 amountBear = (100 - randomNumber) * 10 ** 13;

        Round storage round = rounds[currentEpoch];
        round.base.pseudoRound = true;
        round.base.pseudoBullAmount = amountBull;
        round.base.pseudoBearAmount = amountBear;

        round.bullTokenAmounts[INDEX_CDZ] = amountBull;
        round.bullAmounts[INDEX_CDZ] = amountBull;
        round.base.bullAmount = amountBull;

        round.bearTokenAmounts[INDEX_CDZ] = amountBear;
        round.bearAmounts[INDEX_CDZ] = amountBear;
        round.base.bearAmount = amountBear;

        treasuryAmount = treasuryAmount - amountBull - amountBear;
    }

    function claimable(uint256 epoch, address user) public view returns (bool) {
        BetInfo memory betInfo = ledger[epoch][user];
        RoundInfo memory roundInfo = rounds[epoch].base;
        if (roundInfo.lockPrice == roundInfo.closePrice) {
            return false;
        }
        return
            roundInfo.stage == RoundStages.Ended &&
            ((roundInfo.closePrice > roundInfo.lockPrice &&
                betInfo.position == Position.Bull) ||
                (roundInfo.closePrice < roundInfo.lockPrice &&
                    betInfo.position == Position.Bear));
    }

    function getClaimableAmount(uint256 epoch, address user) external view returns (uint256) {
        (uint256 reward,) = _getClaimableAmount(epoch, user);
        return reward;
    }

    function _getClaimableAmount(uint256 epoch, address user) internal view returns (uint256 reward, uint256 fee) {
        BetInfo memory betInfo = ledger[epoch][user];
        if (0 == betInfo.tokenAmount) return (0, 0);
        if (betInfo.claimed) return (0, 0);

        RoundInfo memory roundInfo = rounds[epoch].base;
        if (0 == roundInfo.rewardAmount) return (0, 0);
        if (roundInfo.stage != RoundStages.Ended) return (0, 0);

        if (claimable(epoch, user) == false) return (0, 0);

        return _getRewardForUser(epoch, user);
    }

    function _calculateRewards(uint256 epoch) internal {
        Round storage round = rounds[epoch];
        RoundInfo memory roundInfo = rounds[epoch].base;

        uint256 rewardAmount = 0;
        if (!roundInfo.pseudoRound) {
            if (roundInfo.closePrice > roundInfo.lockPrice) {
                // Bull wins
                round.base.rewardBaseCalAmount = roundInfo.bullAmount;
                rewardAmount = roundInfo.bullAmount + roundInfo.bearAmount;
                treasuryAmount += roundInfo.pseudoBullAmount * rewardAmount / roundInfo.bullAmount;
            } else if (roundInfo.closePrice < roundInfo.lockPrice) {
                // Bear wins
                round.base.rewardBaseCalAmount = roundInfo.bearAmount;
                rewardAmount = roundInfo.bullAmount + roundInfo.bearAmount;
                treasuryAmount += roundInfo.pseudoBearAmount * rewardAmount / roundInfo.bearAmount;
            }
        }

        round.base.rewardAmount = rewardAmount;
        if (rewardAmount == 0) {
            // No betting or no winners in the epoch
            treasuryAmount = treasuryAmount + roundInfo.bearAmount + roundInfo.bullAmount;
        }
    }

    function _getRewardForUser(
        uint256 epoch,
        address user
    ) internal view returns (uint256 reward, uint256 fee) {
        RoundInfo memory roundInfo = rounds[epoch].base;
        Round storage round = rounds[epoch];
        BetInfo memory betInfo = ledger[epoch][user];

        if (betInfo.tokenIndex == INDEX_CDZ) {
            reward =  betInfo.tokenAmount
                    * roundInfo.rewardAmount
                    / roundInfo.rewardBaseCalAmount;
        } else {
            if (betInfo.position == Position.Bull) {
                reward =  betInfo.tokenAmount
                    * round.bullAmounts[betInfo.tokenIndex]
                    * roundInfo.rewardAmount
                    / round.bullTokenAmounts[betInfo.tokenIndex]
                    / roundInfo.rewardBaseCalAmount;
            } else {
                reward =  betInfo.tokenAmount
                    * round.bearAmounts[betInfo.tokenIndex]
                    * roundInfo.rewardAmount
                    / round.bearTokenAmounts[betInfo.tokenIndex]
                    / roundInfo.rewardBaseCalAmount;
            }
        }

        if (0 < reward) {
            fee = reward * betInfo.feeRate / DENOMINATOR;
            reward -= fee;
        } else {
            fee = 0;
        }
    }

    // /*
    //  * @dev For auto-claiming
    //  */
    // function _distributeRewards(uint256 epoch) internal {
    //     RoundInfo memory roundInfo = rounds[epoch].base;
    //     require(0 < roundInfo.rewardAmount, "No Rewards to distribute");
    //     require(roundInfo.stage == RoundStages.Ended, "The round not ended");

    //     uint256 reward;
    //     uint256 fee;
    //     address claimant;
    //     address[] memory _playerList = getPlayerList(epoch);

    //     for (uint256 i = 0; i < _playerList.length; i++) {
    //         claimant = _playerList[i];
    //         if (ledger[epoch][claimant].claimed) continue;
    //         if (claimable(epoch, claimant) == false) continue;

    //         (reward, fee) = _getRewardForUser(epoch, claimant);
    //         if (0 < reward) {
    //             _claim(epoch, claimant, reward, fee);
    //         }
    //     }
    // }

    function _claim(uint256 epoch, address user, uint256 reward, uint256 fee) internal {
        treasuryAmount += fee;
        ledger[epoch][user].claimed = true;

        IERC20Upgradeable(CDZ).safeTransfer(user, reward);

        emit Claim(user, epoch, reward);
    }

    function claim(uint256 epoch) external {
        address claimant = msg.sender;
        (uint256 reward, uint256 fee) = _getClaimableAmount(epoch, claimant);
        require(0 < reward, "No reward");

        _claim(epoch, claimant, reward, fee);
    }

    function _getPath(address tokenIn, address tokenOut) internal pure returns (address[] memory) {
        if (tokenIn == WBNB || tokenOut == WBNB) {
            address[] memory path = new address[](2);
            path[0] = tokenIn;
            path[1] = tokenOut;
            return path;
        } else {
            address[] memory path = new address[](3);
            path[0] = tokenIn;
            path[1] = WBNB;
            path[2] = tokenOut;
            return path;
        }
    }

    function getPrincipalOut(uint32 tokenIndex, uint256 amountIn) public view returns (uint256) {
        if (tokenIndex == INDEX_CDZ) {
            return amountIn;
        }
        address tokenIn = (tokenIndex == INDEX_BNB) ? WBNB : tokens[tokenIndex];
        uint[] memory amounts = router.getAmountsOut(amountIn, _getPath(tokenIn, CDZ));
        return amounts[amounts.length - 1];
    }

    function _swap(address tokenIn, address tokenOut, uint amountIn, uint amountOutMin) internal returns (uint){
        if(tokenIn == address(0)) {
            address[] memory path = _getPath(address(WBNB), tokenOut);
            return router.swapExactETHForTokens{value: amountIn}(amountOutMin, path, address(this), block.timestamp)[1];
        } else if(tokenOut == address(0)) {
            address[] memory path = _getPath(tokenIn, address(WBNB));
            return router.swapExactTokensForETH(amountIn, amountOutMin, path, address(this), block.timestamp)[1];
        } else {
            address[] memory path = _getPath(tokenIn, tokenOut);
            uint[] memory amounts = router.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), block.timestamp);
            return amounts[amounts.length - 1];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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