// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Lossless.sol";
import "IERC20.sol";
import "Benqi.sol";

contract BenqiLossless is Lossless {
    address public winner;
    uint256 public sponsorDeposit;
    BetSide public winningSide;
    /// Benqi QiAvax pool to deposit tokens
    QiAvax public qiToken;
    enum BetSide {
        OPEN,
        HOME,
        DRAW,
        AWAY
    }

    modifier correctBet(BetSide betSide) {
        require(
            betSide == BetSide.HOME ||
                betSide == BetSide.AWAY ||
                betSide == BetSide.DRAW,
            "invalid argument for bestide"
        );
        _;
    }

    constructor(
        address _qiToken,
        uint256 _matchStartTime,
        uint256 _matchFinishTime
    ) Lossless(_matchStartTime, _matchFinishTime) {
        status = MatchStatus.OPEN;
        qiToken = QiAvax(_qiToken);
        winningSide = BetSide.OPEN;
        winner = address(0);
    }

    function sponsor() public payable /*isOpen*/
    {
        require(msg.value > 0, "amount must be positif");
        uint256 amount = msg.value;
        // (bool success, ) = address(qiAvax).call.value(amount)("mint");
        // require(success, "Deposit failed");
        qiToken.mint{value: amount}();
        totalDeposits += amount;
        sponsorDeposit += amount;
        playerBalance[msg.sender] += amount;
    }

    function placeBet(BetSide betSide)
        public
        payable
        /*isOpen*/
        correctBet(betSide)
    {
        require(msg.value > 0, "amount must be positif");
        uint256 amount = msg.value;
        if (betSide == BetSide.HOME) {
            placeHomeBet(amount);
        } else if (betSide == BetSide.AWAY) {
            placeAwayBet(amount);
        } else if (betSide == BetSide.DRAW) {
            placeDrawBet(amount);
        }
        qiToken.mint{value: amount}();
        //(bool success, ) = address(qiAvax).call.value(amount)("mint");
        totalDeposits += amount;
        playerBalance[msg.sender] += amount;
    }

    function withdraw() public isPaid {
        require(playerBalance[msg.sender] > 0, "balance is zero");
        uint256 amount = playerBalance[msg.sender];
        playerBalance[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function setMatchWinnerAndWithdrawFromPool(BetSide _winningSide)
        public
        onlyOwner
        correctBet(_winningSide)
    {
        require(status == MatchStatus.OPEN, "Cant settle this match");
        status = MatchStatus.PAID;
        winningSide = _winningSide;
        uint256 contractBalance = qiToken.balanceOf(address(this));
        qiToken.redeem(contractBalance);
        findWinner();
        payoutWinner();
    }

    function findWinner() internal {
        if (winningSide == BetSide.HOME) {
            winner = findHomeWinner();
        } else if (winningSide == BetSide.AWAY) {
            winner = findAwayWinner();
        } else if (winningSide == BetSide.DRAW) {
            winner = findDrawWinner();
        }
    }

    function payoutWinner() internal {
        uint256 winnerPayout = qiToken.balanceOf(address(this)) - totalDeposits;
        playerBalance[winner] += winnerPayout;
    }

    function getQiTokenBalance() external view returns (uint256) {
        return qiToken.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";

/** @title Lossless
 *  @dev This contract implement is a boilerplate for lossless betting contracts for football 1X2.
 * Contract has an owner to settle the bet, to be replaced by Chainlink.
 * Process : - Owner creates contract, sets matchStartBlock and matchFinishBlock : Players can place bets before matchStartBlock
 * and owner can settle the game after matchFinishBlock.
 *           - Before matchStartBlock player can pick a side ( Home, Draw, Away), choose an amount and place a bet.
 *           - After placing a bet the player win points proportional to the 'amount' and 'blocks remaining before matchStartBlock'.
 *           - The chance of winning for the player is proportional to his points.
 *           - The money deposited for bets is then lent to a protocol and earns yield.
 *           - After game is finished and owner sets winning team, contract pick randomly a winner who bet on the right side.
 *           - Winner wins the yield generated, and other players are refunded.
 */

contract Lossless is Ownable {
    MatchStatus public status;
    /// block at which game is supposed to start
    uint256 public matchStartTime;
    /// block after which game should have ended
    uint256 public matchFinishTime;
    /// total amount deposited in the contract
    uint256 public totalDeposits;
    /// total points earned by players betting home
    uint256 public homePointsTrackers;
    /// total points earned by players betting draw
    uint256 public drawPointsTrackers;
    /// total points earned by players betting away
    uint256 public awayPointsTrackers;
    /// number of home bets
    uint256 public homeBets;
    /// number of draw bets
    uint256 public drawBets;
    /// number of away bets
    uint256 public awayBets;
    /// tracks total points earned by player betting home after bet number i, used for computing winner
    uint256[] public homePointsAfterBet;
    /// tracks total points earned by player betting draw after bet number i, used for computing winner
    uint256[] public drawPointsAfterBet;
    /// tracks total points earned by player betting away after bet number i, used for computing winner
    uint256[] public awayPointsAfterBet;
    /// tracks which playerr placed home bet number i
    mapping(uint256 => address) public homeBetPlacer;
    /// tracks which playerr placed draw bet number i
    mapping(uint256 => address) public drawBetPlacer;
    /// tracks which playerr placed away bet number i
    mapping(uint256 => address) public awayBetPlacer;
    /// tracks players deposits
    mapping(address => uint256) public playerBalance;
    /// tracks players home points
    mapping(address => uint256) public playerHomePoints;
    /// tracks players draw points
    mapping(address => uint256) public playerDrawPoints;
    /// tracks players away points
    mapping(address => uint256) public playerAwayPoints;
    enum MatchStatus {
        OPEN,
        PAID
    }

    /**
     * @dev Throws if called after game started
     */
    modifier isOpen() {
        require(status == MatchStatus.OPEN, "Match not open");
        require(block.timestamp < matchStartTime, "Cant place bet now");
        _;
    }

    /**
     * @dev Throws if called before game is Finished
     */

    modifier isFinished() {
        require(block.timestamp > matchFinishTime, "Game is finished");
        _;
    }

    /**
     * @dev Throws if called after game is Paid
     */
    modifier isPaid() {
        require(status == MatchStatus.PAID, "Match not paid");
        _;
    }

    /**
     * @dev Initialize the contract settings : matchStartBlock and matchFinishBlock.
     */
    constructor(uint256 _matchStartTime, uint256 _matchFinishTime) {
        status = MatchStatus.OPEN;
        matchStartTime = _matchStartTime;
        matchFinishTime = _matchFinishTime;
    }

    /**
     * @dev Places home bet.
     */
    function placeHomeBet(uint256 amount) internal {
        uint256 currentTime = block.timestamp;
        uint256 points = amount * (matchStartTime - currentTime);
        playerHomePoints[msg.sender] += points;
        homePointsTrackers += points;
        homePointsAfterBet.push(homePointsTrackers);
        homeBetPlacer[homeBets] = msg.sender;
        homeBets += 1;
    }

    /**
     * @dev Places draw bet.
     */
    function placeDrawBet(uint256 amount) internal {
        uint256 currentTime = block.timestamp;
        uint256 points = amount * (matchStartTime - currentTime);
        playerDrawPoints[msg.sender] += points;
        drawPointsTrackers += points;
        drawPointsAfterBet.push(drawPointsTrackers);
        drawBetPlacer[homeBets] = msg.sender;
        drawBets += 1;
    }

    /**
     * @dev Places away bet.
     */
    function placeAwayBet(uint256 amount) internal {
        uint256 currentTime = block.timestamp;
        uint256 points = amount * (matchStartTime - currentTime);
        playerAwayPoints[msg.sender] += points;
        awayPointsTrackers += points;
        awayPointsAfterBet.push(awayPointsTrackers);
        awayBetPlacer[awayBets] = msg.sender;
        awayBets += 1;
    }

    /**
     * @dev Find home winner.
     */
    function findHomeWinner() internal returns (address) {
        uint256 random = _random();
        random = random % homePointsTrackers;

        if (random < homePointsAfterBet[0]) {
            return homeBetPlacer[0];
        }

        uint256 hi = homePointsAfterBet.length - 1;
        uint256 lo = 0;

        while (lo <= hi) {
            uint256 mid = lo + (hi - lo) / 2;
            if (random < homePointsAfterBet[mid]) {
                hi = mid - 1;
            } else if (random > homePointsAfterBet[mid]) {
                lo = mid + 1;
            } else {
                return homeBetPlacer[mid + 1];
            }
        }
        return homeBetPlacer[lo];
    }

    /**
     * @dev Find Draw winner.
     */
    function findDrawWinner() internal returns (address) {
        uint256 random = _random();
        random = random % drawPointsTrackers;

        if (random < drawPointsAfterBet[0]) {
            return drawBetPlacer[0];
        }

        uint256 hi = drawPointsAfterBet.length - 1;
        uint256 lo = 0;

        while (lo <= hi) {
            uint256 mid = lo + (hi - lo) / 2;
            if (random < drawPointsAfterBet[mid]) {
                hi = mid - 1;
            } else if (random > drawPointsAfterBet[mid]) {
                lo = mid + 1;
            } else {
                return drawBetPlacer[mid + 1];
            }
        }
        return drawBetPlacer[lo];
    }

    /**
     * @dev Find away winner.
     */
    function findAwayWinner() internal returns (address) {
        uint256 random = _random();
        random = random % awayPointsTrackers;

        if (random < awayPointsAfterBet[0]) {
            return awayBetPlacer[0];
        }

        uint256 hi = awayPointsAfterBet.length - 1;
        uint256 lo = 0;

        while (lo <= hi) {
            uint256 mid = lo + (hi - lo) / 2;
            if (random < awayPointsAfterBet[mid]) {
                hi = mid - 1;
            } else if (random > awayPointsAfterBet[mid]) {
                lo = mid + 1;
            } else {
                return awayBetPlacer[mid + 1];
            }
        }
        return awayBetPlacer[lo];
    }

    /**
     * @dev Generate random number to compute the winner, to be replaced with Chainlink VRF.
     */
    function _random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        totalDeposits,
                        matchStartTime,
                        matchFinishTime
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface QIErc20 {
    function balanceOf(address) external view returns (uint256);

    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function balanceOfUnderlying(address) external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function borrowBalanceCurrent(address) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 amount,
        address collateral
    ) external returns (uint256);
}

interface QiAvax {
    function balanceOf(address) external view returns (uint256);

    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function balanceOfUnderlying(address) external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function borrowBalanceCurrent(address) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function repayBorrow() external payable;
}

interface Comptroller {
    function markets(address)
        external
        view
        returns (
            bool,
            uint256,
            bool
        );

    function enterMarkets(address[] calldata)
        external
        returns (uint256[] memory);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function closeFactorMantissa() external view returns (uint256);

    function liquidationIncentiveMantissa() external view returns (uint256);

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 actualRepayAmount
    ) external view returns (uint256, uint256);
}

interface PriceFeed {
    function getUnderlyingPrice(address cToken) external view returns (uint256);
}