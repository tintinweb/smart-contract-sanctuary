// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./MrsDogeDividendTracker.sol";
import "./MrsDogePot.sol";
import "./MrsDogeRound.sol";
import "./MrsDogeGameSettings.sol";
import "./MrsDogeTokenHolders.sol";
import "./MrsDogeToken.sol";
import "./MrsDogeGame.sol";
import "./MrsDogeStorage.sol";
import "./MrsDogeRoundFactory.sol";


contract MrsDoge is ERC20, Ownable {
    using SafeMath for uint256;
    //using IterableMapping for IterableMapping.Map;
    using MrsDogeGameSettings for MrsDogeGameSettings.RoundSettings;
    using MrsDogeGameSettings for MrsDogeGameSettings.PayoutSettings;
    using MrsDogeTokenHolders for MrsDogeTokenHolders.Holders;
    using MrsDogeToken for MrsDogeToken.Token;
    using MrsDogeGame for MrsDogeGame.Game;
    using MrsDogeStorage for MrsDogeStorage.Storage;
    using MrsDogeStorage for MrsDogeStorage.Fees;

    MrsDogeStorage.Storage private _storage;

    modifier onlyCurrentRound() {
        address currentRound = address(_storage.game.getCurrentRound());
        require(currentRound != address(0x0) && msg.sender == currentRound, "MRSDoge: caller must be current round");
        _;
    }

    modifier onlyTeamWallet() {
        require(msg.sender == _storage.teamWallet, "MRSDoge: caller must be the team wallet");
        _;
    }

    constructor() public ERC20("MrsDoge", "MrsDoge") {
        _storage.teamWallet = owner();

        _storage.roundFactory = new MrsDogeRoundFactory();
        _storage.dividendTracker = new MrsDogeDividendTracker();
    	  _storage.pot = new MrsDogePot();


    	  IUniswapV2Router02 _uniswapV2Router =      IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        _approve(address(this), address(_uniswapV2Router), type(uint256).max);


        _storage.token = MrsDogeToken.Token(
            address(this), //token address
            4, // liquidity fee
            4, // dividend fee low
            4, // pot fee low
            13, // dividend fee high
            13, // pot fee high
            86000 * 18, //fees lowering duration
            400000, //gas used for processing
            400000 * 10**18, // token swap threshold
            0, //accumulated liquidity tokens
            0, //accumulated dividend tokens
            0, //accumulated pot tokens
            false, //in swap
            _uniswapV2Pair, //pair
            _uniswapV2Router); //router

        _storage.game = MrsDogeGame.Game(
            new MrsDogeRound[](0),
            _storage.roundFactory,
            _storage.token);


        updateRoundSettings(
            false, //contractsDisabled
            0 * 10 ** 18, // tokensNeededToBuyTickets
            35, //userBonusDivisor
            65, // gameFeePotPercent,
            33, // gameFeeBuyTokensForPotPercent,
            2,  // gameFeeReferrerPercent
            20 * 60 * 12, // roundLengthBlocks,
            1000, // blocksAddedPer100TicketsBought,
            [uint256(0.001 ether), 0.00001 ether, 2000], //[initialTicketPrice, ticketPriceIncreasePerBlock, ticketPriceRoundPotDivisor]
            20 * 60 * 2); // gameCooldownBlocks)

        updatePayoutSettings(
            40,// roundPotPercent,
            25, // lastBuyerPayoutPercent,
            [uint256(20), 10, 5], // placePayoutPercents,
            [uint256(10), 10], // smallHolderSettings (lottery percent, lottery count)
            [uint256(10), 5], // largeHolderSettings
            [uint256(10), 2], // hugeHolderSettings
            10); // marketingPayoutPercent)


        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);

        _storage.dividendTracker.excludeFromDividends(address(_storage.dividendTracker));
        _storage.dividendTracker.excludeFromDividends(address(this));
        _storage.dividendTracker.excludeFromDividends(owner());
        _storage.dividendTracker.excludeFromDividends(_uniswapV2Pair);
        _storage.dividendTracker.excludeFromDividends(address(_uniswapV2Router));

        _mint(owner(), 500000000 * 10**18);
    }

    receive() external payable {

  	}

    function updateTeamWallet(address newTeamWallet) public onlyOwner {
       _storage.updateTeamWallet(newTeamWallet);
    }

    function updatePresaleWallet(address newPresaleWallet) public onlyOwner {
        _storage.updatePresaleWallet(newPresaleWallet);
        excludeFromFees(newPresaleWallet, true);
        _storage.dividendTracker.excludeFromDividends(newPresaleWallet);
    }

    function updateRoundFactory(address newRoundFactory) external onlyOwner {
        _storage.updateRoundFactory(newRoundFactory);
    }

    function lockRoundFactory() external onlyOwner {
        _storage.lockRoundFactory();
    }

    function getRoundFactory() external view returns (address) {
        return address(_storage.roundFactory);
    }

    function updateRoundSettings(
        bool contractsDisabled,
        uint256 tokensNeededToBuyTickets,
        uint256 userBonusDivisor,
        uint256 gameFeePotPercent,
        uint256 gameFeeBuyTokensForPotPercent,
        uint256 gameFeeReferrerPercent,
        uint256 roundLengthBlocks,
        uint256 blocksAddedPer100TicketsBought,
        uint256[3] memory ticketPriceInfo,
        uint256 gameCooldownBlocks)
        public onlyTeamWallet {
        _storage.roundSettings.updateRoundSettings(
            contractsDisabled,
            tokensNeededToBuyTickets,
            userBonusDivisor,
            gameFeePotPercent,
            gameFeeBuyTokensForPotPercent,
            gameFeeReferrerPercent,
            roundLengthBlocks,
            blocksAddedPer100TicketsBought,
            ticketPriceInfo,
            gameCooldownBlocks
        );
    }

    function updatePayoutSettings(
        uint256 roundPotPercent,
        uint256 lastBuyerPayoutPercent,
        uint256[3] memory placePayoutPercents,
        uint256[2] memory smallHolderSettings,
        uint256[2] memory laregHolderSettings,
        uint256[2] memory hugeHolderSettings,
        uint256 marketingPayoutPercent)
        public onlyTeamWallet {
        _storage.payoutSettings.updatePayoutSettings(
            roundPotPercent,
            lastBuyerPayoutPercent,
            placePayoutPercents,
            smallHolderSettings,
            laregHolderSettings,
            hugeHolderSettings,
            marketingPayoutPercent
        );
    }


    function extendCurrentRoundCooldown(uint256 blocks) public onlyTeamWallet {
        _storage.extendCurrentRoundCooldown(blocks);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _storage.token.excludeFromFees(account, excluded);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        _storage.token.updateGasForProcessing(newValue);
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        _storage.dividendTracker.updateClaimWait(claimWait);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _storage.isExcludedFromFees(account);
    }

    function processDividendTracker(uint256 gas) external {
        _storage.processDividendTracker(gas);
    }

    function claim() external {
        _storage.dividendTracker.processAccount(msg.sender, false);
    }

    function updateTokenHolderStatus(address user) private {
        if(!_storage.dividendTracker.excludedFromDividends(user) && user != address(_storage.pot)) {
            _storage.tokenHolders.updateTokenHolderStatus(user, balanceOf(user));
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0) && to != address(0), "ERC20: zero address transfer");


        MrsDogeRound currentRound = getCurrentRound();

        // complete the current round if it is over
        if(address(currentRound) != address(0x0)) {
            currentRound.completeRoundIfOver();
        } else { // don't allow adding liquidity before game starts
            if(to == _storage.token.uniswapV2Pair) {
                require(/*from == _storage.teamWallet ||*/ from == _storage.presaleWallet, "MRSDoge: cannot add liquidity before game starts");
            }
        }

        MrsDogeToken.TransferType transferType = _storage.token.getTransferType(from, to);

        // game starts when there is first buy from PancakeSwap
        if(transferType == MrsDogeToken.TransferType.Buy && !_storage.game.isActive()) {
            _storage.game.createNewRound();
        }

        _storage.possiblySwapContractTokens(from, to, transferType, owner(), balanceOf(address(this)));

        MrsDogeStorage.Fees memory fees = _storage.calculateTokenFee(from, to, amount, transferType);

        if(amount > 0 && _storage.token.feeBeginTimestamp[to] == 0) {
            _storage.token.feeBeginTimestamp[to] = block.timestamp;
        }

        uint256 totalFees = fees.calculateTotalFees();

        if(totalFees > 0) {
            amount = amount.sub(totalFees);

            super._transfer(from, address(this), totalFees);

            _storage.token.incrementAccumulatedTokens(fees);
        }

        super._transfer(from, to, amount);

        updateTokenHolderStatus(from);
        updateTokenHolderStatus(to);

        bool process = !_storage.token.inSwap && totalFees > 0;
        uint256 gasForProcessing = process ? _storage.token.gasForProcessing : 0;

        _storage.handleTransfer(from, to, gasForProcessing);
    }

    //Game

    function getCurrentRound() public view returns (MrsDogeRound) {
        return _storage.game.getCurrentRound();
    }


    function buyExactTickets(uint256 amount, address referrer) public payable {
        _storage.game.buyExactTickets(msg.sender, amount, referrer);
    }

    function completeRound() external {
        _storage.game.completeRound();
    }

    function lockTokenHolders(uint256 until) external onlyCurrentRound {
        _storage.tokenHolders.lockUntil(until);
    }

    function roundCompleted() external onlyCurrentRound {
        _storage.game.roundCompleted();
    }

    function getRandomHolders(uint256 seed, uint256 count, MrsDogeTokenHolders.HolderType holderType) external view returns (address[] memory) {
        return _storage.tokenHolders.getRandomHolders(seed, count, holderType);
    }

    function dividendTracker() external view returns (MrsDogeDividendTracker) {
        return _storage.dividendTracker;
    }

    function pot() external view returns (MrsDogePot) {
        return _storage.pot;
    }

    function teamWallet() external view returns (address) {
        return _storage.teamWallet;
    }

    function referredBy(address user) external view returns (address) {
        return _storage.game.referredBy(user);
    }

    function gameStats(address user)
        external
        view
        returns (uint256[] memory roundStats,
                 int256 currentBlocksLeft,
                 address lastBuyer,
                 uint256[] memory lastBuyerStats,
                 uint256[] memory userStats,
                 address[] memory topBuyerAddress,
                 uint256[] memory topBuyerData) {
        MrsDogeRound currentRound = getCurrentRound();
        if(address(currentRound) != address(0)) {
            return currentRound.gameStats(user);
        } else {
            roundStats = new uint256[](14);

            uint256 potBalance = address(_storage.pot).balance;

            roundStats[7] = potBalance.mul(_storage.payoutSettings.roundPotPercent).div(100);
            roundStats[11] = block.timestamp;
            roundStats[12] = block.number;
            roundStats[13] = potBalance;

            userStats = new uint256[](6);

            userStats[4] = balanceOf(user);
            userStats[5] = _storage.roundSettings.getUserBonusPermille(this, user);
        }
    }

    function settings()
        external
        view
        returns (MrsDogeGameSettings.RoundSettings memory contractRoundSettings,
                 MrsDogeGameSettings.PayoutSettings memory contractPayoutSettings,
                 MrsDogeGameSettings.RoundSettings memory currentRoundRoundSettings,
                 MrsDogeGameSettings.PayoutSettings memory currentRoundPayoutSettings,
                 address currentRoundAddress) {
        MrsDogeRound currentRound = getCurrentRound();

        contractRoundSettings = _storage.roundSettings;
        contractPayoutSettings = _storage.payoutSettings;

        if(address(currentRound) != address(0)) {
            currentRoundRoundSettings = currentRound.roundSettings();
            currentRoundPayoutSettings = currentRound.payoutSettings();
        }

        currentRoundAddress = address(currentRound);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }



    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

pragma solidity ^0.6.12;

// SPDX-License-Identifier: MIT License

import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.6.12;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.12;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract MrsDogeDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IERC20 token;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForAutoClaim;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event MinimumTokenBalanceForAutoClaimUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() public DividendPayingToken("MRSDogeDividendTracker", "MRSDogeDividendTracker") {
        token = IERC20(msg.sender);
        claimWait = 3600;
        minimumTokenBalanceForAutoClaim = 10000 * (10**18); //must hold 10000+ tokens
    }

    function _transfer(address, address, uint256) internal override {
        require(false, "MRSDogeDividendTracker: No transfers allowed");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}
        excludedFromDividends[account] = true;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400, "MRSDogeDividendTracker: must be between 1 and 24 hours");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function updateMinimumTokenBalanceForAutoClaim(uint256 newMinimumTokenBalanceForAutoClaim) external onlyOwner {
        require(newMinimumTokenBalanceForAutoClaim <= 10000 * (10**18), "MRSDogeDividendTracker:  must be less <= to 10000");
        emit MinimumTokenBalanceForAutoClaimUpdated(newMinimumTokenBalanceForAutoClaim, minimumTokenBalanceForAutoClaim);
        minimumTokenBalanceForAutoClaim = newMinimumTokenBalanceForAutoClaim;
    }


    function getLastProcessedIndex() external view returns(uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }



    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = dividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if(lastClaimTime > block.timestamp)  {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function handleTransfer(address from, address to, uint256 gasForProcessing) external onlyOwner returns (uint256, uint256, uint256) {
        setBalance(payable(from), token.balanceOf(from));
        setBalance(payable(to), token.balanceOf(to));

        return process(gasForProcessing);
    }

    function matchTokenBalance(address user) external onlyOwner {
        setBalance(payable(user), token.balanceOf(user));
    }

    function setBalance(address payable account, uint256 newBalance) private {
        if(excludedFromDividends[account]) {
            return;
        }

        _setBalance(account, newBalance);

        if(newBalance >= minimumTokenBalanceForAutoClaim) {
            tokenHoldersMap.set(account, newBalance);
        }
        else {
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if(gas == 0 || numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while(gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if(canAutoClaim(lastClaimTimes[account])) {
                if(processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if(gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./MrsDoge.sol";
import "./MrsDogeRound.sol";
import "./MrsDogeLatestBuyerPot.sol";

contract MrsDogePot is Ownable {
    using SafeMath for uint256;

    MrsDoge public token;
    MrsDogeLatestBuyerPot public latestBuyerPot;

    uint256 public latestBuyerPercent;

    modifier onlyCurrentRound() {
        MrsDogeRound round = token.getCurrentRound();
        require(msg.sender == address(round), "MRSDogePot: caller is not the current round");
        _;
    }

    modifier onlyTokenOwner() {
        require(msg.sender == token.owner(), "MRSDogePot: caller is not the token owner");
        _;
    }

    event LatestBuyerPercentUpdated(uint256 newValue, uint256 oldValue);

    event RoundPotTaken(uint256 indexed roundNumber, uint256 amount);

    constructor() public {
    	token = MrsDoge(payable(owner()));
        latestBuyerPercent = 10;
        emit LatestBuyerPercentUpdated(latestBuyerPercent, 0);
    }

    receive() external payable {
        if(address(latestBuyerPot) == address(0)) {
            latestBuyerPot = new MrsDogeLatestBuyerPot();
        }

        uint256 forwardAmount = msg.value.mul(latestBuyerPercent).div(100);

        safeSend(address(latestBuyerPot), forwardAmount);
    }

    function updateLatestBuyerPercent(uint256 _latestBuyerPercent) public onlyTokenOwner {
        require(_latestBuyerPercent <= 50);
        emit LatestBuyerPercentUpdated(_latestBuyerPercent, latestBuyerPercent);
        latestBuyerPercent = _latestBuyerPercent;
    }

    function safeSend(address account, uint256 amount) private {
        (bool success,) = account.call {value: amount} ("");

        require(success, "MRSDogePot: could not send");
    }

    function takeRoundPot() external onlyCurrentRound {
    	MrsDogeRound round = token.getCurrentRound();

    	uint256 roundPot = address(this).balance.mul(round.roundPotPercent()).div(100);

        round.receiveRoundPot { value: roundPot } ();

        emit RoundPotTaken(round.roundNumber(), roundPot);
    }

    function takeBonus(uint256 amount) external onlyCurrentRound {
        MrsDogeRound round = token.getCurrentRound();

        round.receiveBonus { value: amount } ();
    }

    function takeGasFees(uint256 amount) external onlyCurrentRound {
        MrsDogeRound round = token.getCurrentRound();

        round.receiveGasFees { value: amount } ();
    }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./MrsDoge.sol";
import "./MrsDogeRoundStorage.sol";
import "./MrsDogeGameSettings.sol";
import "./MrsDogeRoundBuyers.sol";
import "./MrsDogeToken.sol";
import "./MrsDogeRoundFactory.sol";
import "./IReceivesBogRandV2.sol";
import "./IBogRandOracleV2.sol";
import "./IUniswapV2Router.sol";


contract MrsDogeRound is Ownable, IReceivesBogRandV2 {
    using SafeMath for uint256;
    using MrsDogeRoundBuyers for MrsDogeRoundBuyers.Buyers;
    using MrsDogeToken for MrsDogeToken.Token;
    using MrsDogeGameSettings for MrsDogeGameSettings.RoundSettings;
    using MrsDogeGameSettings for MrsDogeGameSettings.PayoutSettings;
    using MrsDogeRoundStorage for MrsDogeRoundStorage.Storage;

    MrsDogeRoundStorage.Storage private _storage;

    modifier onlyTokenContract() {
        require(_msgSender() == address(_storage.gameToken), "MRSDogeRound: caller is not MrsDoge");
        _;
    }

    modifier onlyPot() {
        require(_msgSender() == address(_storage.gameToken.pot()), "MRSDogeRound: caller is not MrsDoge");
        _;
    }

    modifier onlyRNG() {
        require(_msgSender() == address(_storage.rng), "MRSDogeRound: caller is not RNG");
        _;
    }

    constructor(IUniswapV2Router02 _uniswapV2Router, uint256 _roundNumber) public {
        _storage.uniswapV2Router = _uniswapV2Router;
        _storage.roundNumber = _roundNumber;

        //IBogRandOracleV2(0x0eCb31Afe9FE6a10f9A173843aE7957Df39D8236); testnet
        _storage.rng = IBogRandOracleV2(0xe308d2B81e543b21c8E1D0dF200965a7349eb1b7);
    }

    function makeTokenOwner(address tokenAddress) public onlyOwner {
        _storage.gameToken = MrsDoge(payable(tokenAddress));
        transferOwnership(tokenAddress);
    }

    function start() public onlyTokenContract {
        require(_storage.startBlock == 0);
        _storage.start();
    }


    function receiveRoundPot() external payable onlyPot {
        _storage.receiveRoundPot();
    }

    function receiveBonus() external payable onlyPot {

    }

    function receiveGasFees() external payable onlyPot {

    }


    //if the round is over, return the block that the cooldown is over
    function cooldownOverBlock() public view returns (uint256) {
        return _storage.cooldownOverBlock();
    }

    function priceForTickets(address user, uint256 amount) public view returns (uint256) {
        return _storage.calculatePriceForTickets(user, amount);
    }

    function roundPotPercent() public view returns (uint256) {
        return _storage.payoutSettings.roundPotPercent;
    }

    function extendCooldown(uint256 blocks) public onlyTokenContract {
        _storage.extendCooldown(blocks);
    }

    function returnFundsToPot() public onlyTokenContract {
        _storage.returnFundsToPot();
    }

    function buyExactTickets(address user, uint256 amount) external payable onlyTokenContract returns (bool) {
    	bool result = _storage.buyExactTickets(user, amount);
        return result;
    }

    function completeRoundIfOver() public onlyTokenContract returns (bool) {
       return _storage.completeRoundIfOver();
    }

    function receiveRandomness(bytes32 hash, uint256 random) external override onlyRNG {
        _storage.receiveRandomness(hash, random);
    }

    function roundNumber() external view returns (uint256) {
        return _storage.roundNumber;
    }

    function startTimestamp() external view returns (uint256) {
        return _storage.startTimestamp;
    }

    function blocksLeft() external view returns (int256) {
        return _storage.blocksLeft();
    }

    function topBuyer() public view returns (address, uint256) {
        MrsDogeRoundBuyers.Buyer storage buyer = _storage.buyers.topBuyer();
        return (buyer.user, buyer.ticketsBought);
    }


    function getNumberOfTicketsBought(address user) external view returns (uint256) {
        return _storage.getNumberOfTicketsBought(user);
    }

	function gameStats(
                address user)
        external
        view
        returns (uint256[] memory roundStats,
                 int256 blocksLeftAtCurrentBlock,
                 address lastBuyer,
                 uint256[] memory lastBuyerStats,
                 uint256[] memory userStats,
                 address[] memory topBuyerAddress,
                 uint256[] memory topBuyerData) {
        return _storage.generateGameStats(user);
    }

    function roundSettings()
        external
        view
        returns (MrsDogeGameSettings.RoundSettings memory) {
            return _storage.roundSettings;
    }

    function payoutSettings()
        external
        view
        returns (MrsDogeGameSettings.PayoutSettings memory) {
            return _storage.payoutSettings;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./MrsDoge.sol";
import "./SafeMath.sol";
import "./MathUtils.sol";

library MrsDogeGameSettings {
    using SafeMath for uint256;

	struct RoundSettings {
        bool contractsDisabled; //Whether contracts are banned from buying tickets
        uint256 tokensNeededToBuyTickets; //Number of tokens a user needs to buy tickets
        uint256 userBonusDivisor; //Divisor in function to calculate user's bonus (tokens^(3/8) * userBonusDivisor / 100)
        uint256 gameFeePotPercent; //Percent of game fees going towards the pot
        uint256 gameFeeBuyTokensForPotPercent; //Percent of game fees going towards buying tokens for the pot
        uint256 gameFeeReferrerPercent; //Percent of gae fees going to the referrer of the buyer
        uint256 roundLengthBlocks; //The length of a round (not including added time), in blocks
        uint256 blocksAddedPer100TicketsBought; //How many blocks are added to length of round for every 100 tickets bought. Minimum is always 1 block.
        uint256 initialTicketPrice; //How much one ticket costs at the start of the round, in Wei
        uint256 ticketPriceIncreasePerBlock; //How much the price increases per block, in Wei
        uint256 ticketPriceRoundPotDivisor; //If set, the price of a ticket costs (Round Pot / ticketPriceRoundPotDivisor)
        uint256 gameCooldownBlocks; //Number of blocks after the round ends before the next round starts
    }

    struct PayoutSettings {
        uint256 roundPotPercent; //Percent of main pot that is paid out to the round pot
        uint256 lastBuyerPayoutPercent; //Percent of round pot that is paid to the last ticket buyer
        uint256[3] placePayoutPercents; //Percent of round pot that is paid to first place in tickets bought
        uint256 smallHolderLotteryPayoutPercent; //Percent of round that is paid to 'smallHolderLotteryPayoutCount' small holders
        uint256 largeHolderLotteryPayoutPercent; //Percent of round that is paid to 'largeHolderLotteryPayoutCount' large holders
        uint256 hugeHolderLotteryPayoutPercent; //Percent of round that is paid to 'hugeHolderLotteryPayoutCount' huge holders
        uint256 smallHolderLotteryPayoutCount; //Number of small holders randomly chosen to split 'smallHolderLotteryPayoutPercent'
        uint256 largeHolderLotteryPayoutCount; //Number of large holders randomly chosen to split 'largeHolderLotteryPayoutPercent'
        uint256 hugeHolderLotteryPayoutCount; //Number of huge holders randomly chosen to split 'hugeHolderLotteryPayoutPercent'
        uint256 marketingPayoutPercent; //Percent of round pot that is paid to the marketing wallet, for marketing
    }




    event RoundSettingsUpdated(
        bool contractsDisabled,
        uint256 tokensNeededToBuyTickets,
        uint256 userBonusDivisor,
        uint256 gameFeePotPercent,
        uint256 gameFeeBuyTokensForPotPercent,
        uint256 gameFeeReferrerPercent,
        uint256 roundLengthBlocks,
        uint256 blocksAddedPer100TicketsBought,
        uint256 initialTicketPrice,
        uint256 ticketPriceIncreasePerBlock,
        uint256 ticketPriceRoundPotDivisor,
        uint256 gameCooldownBlocks);

    event PayoutSettingsUpdated(
        uint256 roundPotPercent,
        uint256 lastBuyerPayoutPercent,
        uint256[3] placePayoutPercents,
        uint256[2] smallHolderSettings,
        uint256[2] laregHolderSettings,
        uint256[2] hugeHolderSettings,
        uint256 marketingPayoutPercent);

    // for any non-zero value it updates the game settings to that value
    function updateRoundSettings(
        RoundSettings storage roundSettings,
        bool contractsDisabled,
        uint256 tokensNeededToBuyTickets,
        uint256 userBonusDivisor,
        uint256 gameFeePotPercent,
        uint256 gameFeeBuyTokensForPotPercent,
        uint256 gameFeeReferrerPercent,
        uint256 roundLengthBlocks,
        uint256 blocksAddedPer100TicketsBought,
        uint256[3] memory ticketPriceInfo,
        uint256 gameCooldownBlocks)
        external {
        roundSettings.contractsDisabled = contractsDisabled;
        roundSettings.tokensNeededToBuyTickets = tokensNeededToBuyTickets;
        roundSettings.userBonusDivisor = userBonusDivisor;
        roundSettings.gameFeePotPercent = gameFeePotPercent;
        roundSettings.gameFeeBuyTokensForPotPercent = gameFeeBuyTokensForPotPercent;
        roundSettings.gameFeeReferrerPercent = gameFeeReferrerPercent;
        roundSettings.roundLengthBlocks = roundLengthBlocks;
        roundSettings.blocksAddedPer100TicketsBought = blocksAddedPer100TicketsBought;
        roundSettings.initialTicketPrice = ticketPriceInfo[0];
        roundSettings.ticketPriceIncreasePerBlock = ticketPriceInfo[1];
        roundSettings.ticketPriceRoundPotDivisor = ticketPriceInfo[2];
        roundSettings.gameCooldownBlocks = gameCooldownBlocks;

        validateRoundSettings(roundSettings);

        emit RoundSettingsUpdated(
            contractsDisabled,
            tokensNeededToBuyTickets,
            userBonusDivisor,
            gameFeePotPercent,
            gameFeeBuyTokensForPotPercent,
            gameFeeReferrerPercent,
            roundLengthBlocks,
            blocksAddedPer100TicketsBought,
            ticketPriceInfo[0],
            ticketPriceInfo[1],
            ticketPriceInfo[2],
            gameCooldownBlocks);
    }

    function validateRoundSettings(RoundSettings storage roundSettings) private view {

        require(roundSettings.tokensNeededToBuyTickets <= 50000 * 10**18,
            "MRSDogeGameSettings: tokensNeededToBuyTickets must be <= 50000 tokens");

        require(roundSettings.userBonusDivisor >= 20 && roundSettings.userBonusDivisor <= 40,
            "MRSDogeGameSettings: userBonusDivisor must be between 20 and 40");

        require(roundSettings.gameFeeReferrerPercent <= 5,
            "MRSDogeGameSettings: gameFeeReferrerPercent must be <= 5");

        require(
            roundSettings.gameFeePotPercent
                .add(roundSettings.gameFeeBuyTokensForPotPercent)
                .add(roundSettings.gameFeeReferrerPercent) == 100,
            "MRSDogeGameSettings: pot percent, buy tokens percent, and referrer percent must sum to 100"
        );

        require(roundSettings.roundLengthBlocks >= 20 && roundSettings.roundLengthBlocks <= 28800,
            "MRSDogeGameSettings: round length blocks must be between 20 and 28800");
        require(roundSettings.blocksAddedPer100TicketsBought >= 1 && roundSettings.blocksAddedPer100TicketsBought <= 6000,
            "MRSDogeGameSettings: blocks added per 100 tickets bought must be between 1 and 6000");
        require(roundSettings.initialTicketPrice <= 10**18,
            "MRSDogeGameSettings: initial ticket price must not exceed 1 BNB");
        require(roundSettings.ticketPriceIncreasePerBlock <= 10**17,
            "MRSDogeGameSettings: ticket price increase per block must not exceed 0.1 BNB");

        require(roundSettings.ticketPriceRoundPotDivisor == 0 ||
            (roundSettings.ticketPriceRoundPotDivisor >= 10 && roundSettings.ticketPriceRoundPotDivisor <= 100000),
            "MRSDogeGameSettings: if set, ticket price round pot divisor must be between 10 and 10000");

        require(roundSettings.gameCooldownBlocks >= 20 && roundSettings.gameCooldownBlocks <= 28800,
            "MRSDogeGameSettings: cooldown must be between 20 and 28800 blocks");
    }

     // for any non-zero value it updates the game settings to that value
    function updatePayoutSettings(
        PayoutSettings storage payoutSettings,
        uint256 roundPotPercent,
        uint256 lastBuyerPayoutPercent,
        uint256[3] memory placePayoutPercents,
        uint256[2] memory smallHolderSettings,
        uint256[2] memory laregHolderSettings,
        uint256[2] memory hugeHolderSettings,
        uint256 marketingPayoutPercent)
        external {
        payoutSettings.roundPotPercent = roundPotPercent;
        payoutSettings.lastBuyerPayoutPercent = lastBuyerPayoutPercent;

        for(uint256 i = 0; i < 3; i++) {
            payoutSettings.placePayoutPercents[i] = placePayoutPercents[i];
        }

        payoutSettings.smallHolderLotteryPayoutPercent = smallHolderSettings[0];
        payoutSettings.largeHolderLotteryPayoutPercent = laregHolderSettings[0];
        payoutSettings.hugeHolderLotteryPayoutPercent = hugeHolderSettings[0];
        payoutSettings.smallHolderLotteryPayoutCount = smallHolderSettings[1];
        payoutSettings.largeHolderLotteryPayoutCount = laregHolderSettings[1];
        payoutSettings.hugeHolderLotteryPayoutCount = hugeHolderSettings[1];
        payoutSettings.marketingPayoutPercent = marketingPayoutPercent;

        validatePayoutSettings(payoutSettings);

        emit PayoutSettingsUpdated(
            roundPotPercent,
            lastBuyerPayoutPercent,
            placePayoutPercents,
            smallHolderSettings,
            laregHolderSettings,
            hugeHolderSettings,
            marketingPayoutPercent);
    }

    function validatePayoutSettings(PayoutSettings storage payoutSettings) private view {
        require(payoutSettings.roundPotPercent >= 1 && payoutSettings.roundPotPercent <= 50,
            "MRSDogeGameSettings: round pot percent must be between 1 and 50");
        require(payoutSettings.lastBuyerPayoutPercent <= 100,
            "MRSDogeGameSettings: last buyer percent must not exceed 100");
        require(payoutSettings.smallHolderLotteryPayoutPercent <= 50,
            "MRSDogeGameSettings: small holder lottery percent must not exceed 50");
        require(payoutSettings.largeHolderLotteryPayoutPercent <= 50,
            "MRSDogeGameSettings: large holder lottery percent must not exceed 50");
        require(payoutSettings.hugeHolderLotteryPayoutPercent <= 50,
            "MRSDogeGameSettings: huge holder lottery percent must not exceed 50");
        require(payoutSettings.marketingPayoutPercent <= 10,
            "MRSDogeGameSettings: marketing percent must not exceed 10");

        uint256 totalPayoutPercent = 0;

        for(uint256 i = 0; i < 3; i++) {
            totalPayoutPercent = totalPayoutPercent.add(payoutSettings.placePayoutPercents[i]);
        }

        totalPayoutPercent = totalPayoutPercent.
                                add(payoutSettings.lastBuyerPayoutPercent).
                                add(payoutSettings.smallHolderLotteryPayoutPercent).
                                add(payoutSettings.largeHolderLotteryPayoutPercent).
                                add(payoutSettings.hugeHolderLotteryPayoutPercent).
                                add(payoutSettings.marketingPayoutPercent);

        require(totalPayoutPercent == 100,
            "MRSDogeGameSettings: total payout percent must sum to 100");

        require(payoutSettings.smallHolderLotteryPayoutCount <= 20,
            "MRSDogeGameSettings: small holder lottery payout count must not exceed 20");
        require(payoutSettings.largeHolderLotteryPayoutCount <= 10,
            "MRSDogeGameSettings: large holder lottery payout count must not exceed 10");
        require(payoutSettings.hugeHolderLotteryPayoutCount <= 5,
            "MRSDogeGameSettings: huge holder lottery payout count must not exceed 5");
    }


    function calculatePriceForTickets(
        RoundSettings storage roundSettings,
        PayoutSettings storage payoutSettings,
        MrsDoge gameToken,
        uint256 startBlock,
        uint256 potBalance,
        address user,
        uint256 amount)
    public view returns (uint256) {
        if(amount == 0) {
            return 0;
        }

        uint256 price;

        if(roundSettings.ticketPriceRoundPotDivisor > 0) {
            uint256 roundPot = potBalance.mul(payoutSettings.roundPotPercent).div(100);

            uint256 roundPotAdjusted = MathUtils.sqrt(
                                            MathUtils.sqrt(roundPot ** 3).mul(10**9)
                                       );

            price = roundPotAdjusted.div(roundSettings.ticketPriceRoundPotDivisor);
        }
        else {
            price = roundSettings.initialTicketPrice;

            uint256 blocksElapsed = block.number.sub(startBlock);

            price = price.add(blocksElapsed.mul(roundSettings.ticketPriceIncreasePerBlock));
        }

        price = price.mul(amount);

        uint256 discount = calculateBonus(roundSettings, gameToken, user, price);

        price = price.sub(discount);

        return price;
    }

    function getUserBonusPermille(
        RoundSettings storage roundSettings,
        MrsDoge gameToken,
        address user)
    public view returns (uint256) {
        if(gameToken.isExcludedFromFees(user)) {
            return 0;
        }

        uint256 balanceWholeTokens = gameToken.balanceOf(user).div(10**18);

        uint256 value = balanceWholeTokens ** 3;
        value = MathUtils.eighthRoot(value);
        value = value.mul(roundSettings.userBonusDivisor).div(100);

        //max 33.3% bonus no matter what
        uint256 maxBonus = 333;

        if(value > maxBonus) {
            value = maxBonus;
        }

        return value;
    }

    function calculateBonus(
        RoundSettings storage roundSettings,
        MrsDoge gameToken,
        address user,
        uint256 amount)
    public view returns (uint256) {
        uint256 bonusPermille = getUserBonusPermille(roundSettings, gameToken, user);

        return amount.mul(bonusPermille).div(1000);
    }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./IterableMapping.sol";


library MrsDogeTokenHolders {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;

    uint256 public constant smallHolderTokensAmount = 50000 * 10**18;
    uint256 public constant largeHolderTokensAmount = 500000 * 10**18;
    uint256 public constant hugeHolderTokensAmount = 5000000 * 10**18;

    struct Holders {
        IterableMapping.Map smallTokenHolders;
        IterableMapping.Map largeTokenHolders;
        IterableMapping.Map hugeTokenHolders;
        uint256 updatesLockedUntil;
    }

    enum HolderType {
        Small,
        Large,
        Huge
    }

    function lockUntil(Holders storage holders, uint256 blockNumber) public {
        holders.updatesLockedUntil = blockNumber;
    }

    function removeUser(Holders storage holders, address user) public {
        holders.smallTokenHolders.remove(user);
        holders.largeTokenHolders.remove(user);
        holders.hugeTokenHolders.remove(user);
    }

    function canSetUser(Holders storage holders, IterableMapping.Map storage tokenHolders, address user) private view returns (bool) {
        return block.number >= holders.updatesLockedUntil || tokenHolders.inserted[user];
    }

    function updateTokenHolderStatus(Holders storage holders, address user, uint256 balance) public {
        bool updatesLocked = block.number < holders.updatesLockedUntil;

        if(balance >= smallHolderTokensAmount) {
            require(canSetUser(holders, holders.smallTokenHolders, user), "MRSDogeTokenHolders: can't add use to small token holders mapping");
            holders.smallTokenHolders.set(user, balance);
        }
        else if(holders.smallTokenHolders.inserted[user]) {
            require(!updatesLocked, "MRSDogeTokenHolders: can't remove user from small token holders mapping");
            holders.smallTokenHolders.remove(user);
        }

        if(balance >= largeHolderTokensAmount) {
            require(canSetUser(holders, holders.largeTokenHolders, user), "MRSDogeTokenHolders: can't add use to large token holders mapping");
            holders.largeTokenHolders.set(user, balance);
        }
        else if(holders.largeTokenHolders.inserted[user]) {
            require(!updatesLocked, "MRSDogeTokenHolders: can't remove user from large token holders mapping");
            holders.largeTokenHolders.remove(user);
        }

        if(balance >= hugeHolderTokensAmount) {
            require(canSetUser(holders, holders.hugeTokenHolders, user), "MRSDogeTokenHolders: can't add use to huge token holders mapping");
            holders.hugeTokenHolders.set(user, balance);
        }
        else if(holders.hugeTokenHolders.inserted[user]) {
            require(!updatesLocked, "MRSDogeTokenHolders: can't remove user from huge token holders mapping");
            holders.hugeTokenHolders.remove(user);
        }
    }

    function isSmallHolder(Holders storage holders, address user) public view returns (bool) {
        return holders.smallTokenHolders.inserted[user];
    }

    function isLargeHolder(Holders storage holders, address user) public view returns (bool) {
        return holders.largeTokenHolders.inserted[user];
    }

    function isHugeHolder(Holders storage holders, address user) public view returns (bool) {
        return holders.hugeTokenHolders.inserted[user];
    }


    // gets up to 'count' random holders, and users can be chosen multiple times
    function getRandomHolders(Holders storage holders, uint256 seed, uint256 count, HolderType holderType) public view returns (address[] memory users) {
        IterableMapping.Map storage map;

        if(holderType == HolderType.Small) {
            map = holders.smallTokenHolders;
        }
        else if(holderType == HolderType.Large) {
            map = holders.largeTokenHolders;
        }
        else {
            map = holders.hugeTokenHolders;
        }

        //make sure random indexes differs based on holder type
        seed = uint256(keccak256(abi.encode(seed, uint256(holderType) + 1)));

        if(map.size() > 0) {
            if(map.size() < count) {
                count = map.size();
            }

            users = new address[](count);

            for(uint256 i = 0; i < count; i = i.add(1)) {
                uint256 index = seed % count;
                users[i] = map.getKeyAtIndex(index);

                seed = uint256(keccak256(abi.encode(seed)));
            }
        }
    }

}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./MrsDoge.sol";
import "./MrsDogeStorage.sol";
import "./SafeMath.sol";
import "./IterableMapping.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";
import "./IERC20.sol";

library MrsDogeToken {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;


    struct Token {
        address tokenAddress;
        uint256 liquidityFee;
        uint256 dividendFeeLow;
        uint256 potFeeLow;
        uint256 dividendFeeHigh;
        uint256 potFeeHigh;
        uint256 feesLoweringDuration;
        uint256 gasForProcessing;
        uint256 tokenSwapThreshold;
        uint256 accumulatedLiquidityTokens;
        uint256 accumulatedDividendTokens;
        uint256 accumulatedPotTokens;
        bool inSwap;
        address uniswapV2Pair;
        IUniswapV2Router02 uniswapV2Router;
        mapping (address => bool) isExcludedFromFees;
        mapping (address => uint256) feeBeginTimestamp;
    }

    enum TransferType {
        Normal,
        Buy,
        Sell,
        RemoveLiquidity
    }

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    function excludeFromFees(Token storage token, address account, bool excluded) public {
        require(token.isExcludedFromFees[account] != excluded, "MRSDoge: account is already excluded");
        token.isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function updateGasForProcessing(Token storage token, uint256 newValue) public {
        require(newValue >= 200000 && newValue <= 500000, "MRSDoge: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != token.gasForProcessing, "MRSDoge: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, token.gasForProcessing);
        token.gasForProcessing = newValue;
    }

    function getTransferType(
        Token storage token,
        address from,
        address to)
        public
        view
        returns (TransferType) {
        if(from == token.uniswapV2Pair) {
            if(to == address(token.uniswapV2Router)) {
                return TransferType.RemoveLiquidity;
            }
            return TransferType.Buy;
        }
        if(to == token.uniswapV2Pair) {
            return TransferType.Sell;
        }
        if(from == address(token.uniswapV2Router)) {
            return TransferType.RemoveLiquidity;
        }

        return TransferType.Normal;
    }

    function swapTokensForEth(Token storage token, uint256 tokenAmount) public returns (uint256) {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = token.uniswapV2Router.WETH();

        uint256 initialBalance = address(this).balance;

        // make the swap
        token.uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        return address(this).balance.sub(initialBalance);
    }

    function addLiquidity(Token storage token, address recipient, uint256 tokenAmount, uint256 ethAmount) public {
        // add the liquidity
        token.uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            recipient,
            block.timestamp
        );

    }

    function swapAndLiquify(Token storage token, address recipient, uint256 tokens) public {
        // split the contract balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(token, half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 difference = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(token, recipient, otherHalf, difference);

        emit SwapAndLiquify(half, difference, otherHalf);
    }

    function incrementAccumulatedTokens(
        Token storage token,
        MrsDogeStorage.Fees memory fees) public {
        token.accumulatedLiquidityTokens = token.accumulatedLiquidityTokens.add(fees.liquidityFees);
        token.accumulatedDividendTokens = token.accumulatedDividendTokens.add(fees.dividendFees);
        token.accumulatedPotTokens = token.accumulatedDividendTokens.add(fees.potFees);
    }

    function totalAccumulatedTokens(
        Token storage token) public view returns (uint256) {
        return token.accumulatedLiquidityTokens
               .add(token.accumulatedDividendTokens)
               .add(token.accumulatedPotTokens);
    }

    function getTokenPrice(Token storage token) public view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(token.uniswapV2Pair);
        (uint256 left, uint256 right,) = pair.getReserves();

        (uint tokenReserves, uint bnbReserves) = (token.tokenAddress < token.uniswapV2Router.WETH()) ?
        (left, right) : (right, left);

        return (bnbReserves * 10**18) / tokenReserves;
    }

}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./MrsDogeRound.sol";
import "./MrsDogeToken.sol";
import "./MrsDogeGameSettings.sol";
import "./MrsDogeRoundFactory.sol";

library MrsDogeGame {
    using SafeMath for uint256;
    using MrsDogeGame for MrsDogeGame.Game;
    using MrsDogeToken for MrsDogeToken.Token;
    using MrsDogeGameSettings for MrsDogeGameSettings.RoundSettings;
    using MrsDogeGameSettings for MrsDogeGameSettings.PayoutSettings;

    struct Game {
        MrsDogeRound[] rounds;
        MrsDogeRoundFactory roundFactory;
        MrsDogeToken.Token token;
        mapping (address => uint256) userLastTicketBuys; // store last round a user bought tickets
        mapping (address => address) referrals; // maps referred to referrer
    }

    modifier onlyOnceGameHasStarted(Game storage game) {
        MrsDogeRound currentRound = getCurrentRound(game);
        require(address(currentRound) != address(0x0), "MRSDoge: game hasn't started");
        _;
    }

    event Referral(
        address indexed referrer,
        address indexed referred
    );


    event RoundStarted(
        address indexed contractAddress,
        uint256 indexed roundNumber
    );

    event BuyTickets(
        address indexed user,
        uint256 indexed roundNumber,
        uint256 amount,
        uint256 totalTickets,
        int256 blocksLeftBefore,
        int256 blocksLeftAfter
    );

    event RoundCompleted(
        address indexed contractAddress,
        uint256 indexed roundNumber
    );

    function isActive(Game storage game) public view returns (bool) {
        return game.rounds.length > 0;
    }

    function getCurrentRound(Game storage game) public view returns (MrsDogeRound) {
        if(game.rounds.length == 0) {
            return MrsDogeRound(0x0);
        }

        return game.rounds[game.rounds.length - 1];
    }

    function priceForTickets(
        Game storage game,
        MrsDoge gameToken,
        MrsDogeGameSettings.RoundSettings storage roundSettings,
        MrsDogeGameSettings.PayoutSettings storage payoutSettings,
        uint256 potBalance,
        address user,
        uint256 amount)
    public view onlyOnceGameHasStarted(game) returns (uint256) {
        MrsDogeRound currentRound = getCurrentRound(game);

        uint256 cooldownOverBlock = currentRound.cooldownOverBlock();

        if(cooldownOverBlock > 0) {
            require(block.number >= cooldownOverBlock, "MRSDoge: no price during cooldown");

            return roundSettings.calculatePriceForTickets(
                payoutSettings,
                gameToken,
                block.number,
                potBalance,
                user,
                amount);
        }

        return currentRound.priceForTickets(user, amount);
    }

    function buyExactTickets(
        Game storage game,
        address user,
        uint256 amount,
        address referrer)
    public onlyOnceGameHasStarted(game) returns (bool) {
        if(game.referrals[user] == address(0) && referrer != address(0)) {
            game.referrals[user] = referrer;

            emit Referral(referrer, user);
        }

        MrsDogeRound currentRound = getCurrentRound(game);

        // check if need to create a new round
        uint256 cooldownOverBlock = currentRound.cooldownOverBlock();

        if(cooldownOverBlock > 0) {
            require(block.number >= cooldownOverBlock, "MRSDoge: cannot buy during cooldown");

            currentRound = createNewRound(game);
        }

        int blocksLeftBefore = currentRound.blocksLeft();

        if(currentRound.buyExactTickets { value: msg.value } (user, amount)) {
            emit BuyTickets(
                user,
                currentRound.roundNumber(),
                amount,
                currentRound.getNumberOfTicketsBought(user),
                blocksLeftBefore,
                currentRound.blocksLeft());

            game.userLastTicketBuys[user] = currentRound.roundNumber();

            return true;
        }

        return false;
    }

    function createNewRound(
        Game storage game)
    public returns (MrsDogeRound) {
        MrsDogeRound currentRound = getCurrentRound(game);

        if(address(currentRound) != address(0)) {
            currentRound.returnFundsToPot();
        }

        MrsDogeRound round = game.roundFactory.createMrsDogeRound(
            game.token.uniswapV2Router,
            game.rounds.length.add(1));

        round.start();

        game.rounds.push(round);

        emit RoundStarted(
            address(round),
            round.roundNumber()
        );

        return round;
    }

    function completeRound(Game storage game) external onlyOnceGameHasStarted(game) {
        require(getCurrentRound(game).completeRoundIfOver(), "MRSDoge: round could not be completed");
    }

    function roundCompleted(Game storage game) external {
        MrsDogeRound currentRound = getCurrentRound(game);

        emit RoundCompleted(
            address(currentRound),
            currentRound.roundNumber()
        );
    }

    function referredBy(Game storage game, address user) external view returns (address) {
        return game.referrals[user];
    }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./MrsDoge.sol";
import "./MrsDogeToken.sol";
import "./MrsDogeGame.sol";
import "./MrsDogeDividendTracker.sol";
import "./MrsDogeGameSettings.sol";
import "./MrsDogePot.sol";
import "./MrsDogeTokenHolders.sol";
import "./MrsDogeRoundFactory.sol";
import "./IERC20.sol";


library MrsDogeStorage {
    using SafeMath for uint256;
    using MrsDogeToken for MrsDogeToken.Token;
    using MrsDogeGame for MrsDogeGame.Game;
    using MrsDogeGameSettings for MrsDogeGameSettings.RoundSettings;
    using MrsDogeGameSettings for MrsDogeGameSettings.PayoutSettings;


    struct Storage {
        MrsDogeRoundFactory roundFactory;
        MrsDogeDividendTracker dividendTracker;
        MrsDogePot pot;

        MrsDogeTokenHolders.Holders tokenHolders;

        MrsDogeToken.Token token;
        MrsDogeGame.Game game;

        MrsDogeGameSettings.RoundSettings roundSettings;
        MrsDogeGameSettings.PayoutSettings payoutSettings;

        address teamWallet;
        address presaleWallet;

        bool roundFactoryLocked;
    }

    struct Fees {
        uint256 liquidityFees;
        uint256 dividendFees;
        uint256 potFees;
    }


    event UpdateTeamWallet(
        address newTeamWallet,
        address oldTeamWallet
    );

    event UpdatePresaleWallet(
        address newPresaleWallet,
        address oldPresaleWallet
    );

    event UpdateRoundFactory(
        address newRoundFactory,
        address oldRoundFactory
    );

    event RoundFactoryLocked(
        address roundFactoryAddress
    );



    event CooldownExtended(
        uint256 roundNumber,
        uint256 blocksAdded,
        uint256 endBlock
    );

    event AddToPot(uint256 amount);

    event SendDividends(
        uint256 amount
    );

     event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    function updateTeamWallet(Storage storage _storage, address newTeamWallet) public {
        emit UpdateTeamWallet(newTeamWallet, _storage.teamWallet);
        _storage.teamWallet = newTeamWallet;
    }

    function updatePresaleWallet(Storage storage _storage, address newPresaleWallet) public {
        emit UpdatePresaleWallet(newPresaleWallet, _storage.presaleWallet);
        _storage.presaleWallet = newPresaleWallet;
    }


    function updateRoundFactory(Storage storage _storage, address newRoundFactory) public {
        require(!_storage.roundFactoryLocked, "MRSDoge: round factory is locked");
        emit UpdateRoundFactory(newRoundFactory, address(_storage.roundFactory));
        _storage.roundFactory = MrsDogeRoundFactory(newRoundFactory);
        _storage.game.roundFactory = _storage.roundFactory;
    }

    function lockRoundFactory(Storage storage _storage) public {
        require(!_storage.roundFactoryLocked, "MRSDoge: round factory already locked");
        _storage.roundFactoryLocked = true;
        emit RoundFactoryLocked(address(_storage.roundFactory));
    }

    function isExcludedFromFees(Storage storage _storage, address account) public view returns(bool) {
        return _storage.token.isExcludedFromFees[account];
    }

    function extendCurrentRoundCooldown(Storage storage _storage, uint256 blocks) public {
        require(blocks > 0 && blocks <= 28800, "MRSDoge: invalid value for blocks");

        MrsDogeRound currentRound = _storage.game.getCurrentRound();

        require(address(currentRound) != address(0x0), "MRSDoge: game has not started");

        uint256 cooldownOverBlock = currentRound.cooldownOverBlock();

        require(block.number < cooldownOverBlock, "MRSDoge: the cooldown is not active");

        currentRound.extendCooldown(blocks);

        emit CooldownExtended(
            currentRound.roundNumber(),
            blocks,
            currentRound.cooldownOverBlock()
        );
    }

    function processDividendTracker(
        Storage storage _storage,
        uint256 gas)
    public {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = _storage.dividendTracker.process(gas);
        emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }


    function handleTransfer(
        Storage storage _storage,
        address from,
        address to,
        uint256 gas)
    public {
        try _storage.dividendTracker.handleTransfer(from, to, gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
            if(gas > 0) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            }
        }
        catch {}
    }


    function possiblySwapContractTokens(
        Storage storage _storage,
        address from,
        address to,
        MrsDogeToken.TransferType transferType,
        address owner,
        uint256 contractTokenBalance
    ) public {

        bool overMinTokenBalance = contractTokenBalance >= _storage.token.tokenSwapThreshold;

        if(
            _storage.game.isActive() &&
            overMinTokenBalance &&
            !_storage.token.inSwap &&
            transferType == MrsDogeToken.TransferType.Sell &&
            from != owner &&
            to != owner
        ) {
            _storage.token.inSwap = true;

            _storage.token.swapAndLiquify(_storage.teamWallet, _storage.token.accumulatedLiquidityTokens);

            uint256 sellTokens = contractTokenBalance.sub(_storage.token.accumulatedLiquidityTokens);

            _storage.token.swapTokensForEth(sellTokens);

            uint256 toDividends = _storage.token.tokenAddress.balance.mul(_storage.token.accumulatedDividendTokens).div(sellTokens);
            uint256 toPot = _storage.token.tokenAddress.balance.sub(toDividends);

            (bool success1,) = address(_storage.dividendTracker).call{value: toDividends}("");

            if(success1) {
                emit SendDividends(toDividends);
            }

            (bool success2,) = address(_storage.pot).call{value: toPot}("");

            if(success2) {
                emit AddToPot(toPot);
            }

            _storage.token.accumulatedLiquidityTokens = 0;
            _storage.token.accumulatedDividendTokens = 0;
            _storage.token.accumulatedPotTokens = 0;

            _storage.token.inSwap = false;
        }
    }

    function calculateTokenFee(
        Storage storage _storage,
        address from,
        address to,
        uint256 amount,
        MrsDogeToken.TransferType transferType
    ) public view returns (Fees memory) {
        bool takeFee = _storage.game.isActive() && !_storage.token.inSwap;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(isExcludedFromFees(_storage, from) || isExcludedFromFees(_storage, to)) {
            takeFee = false;
        }

        // no transfer fees for first week
        if(transferType == MrsDogeToken.TransferType.Normal) {
            if(_storage.game.rounds.length == 0) {
                takeFee = false;
            } else {
                MrsDogeRound round = _storage.game.rounds[0];

                uint256 timeSinceStartOfFirstRound = block.timestamp.sub(round.startTimestamp());

                if(timeSinceStartOfFirstRound <= uint256(86400).mul(7)) {
                    takeFee = false;
                }
            }
        }

        if(!takeFee) {
            return Fees(0, 0, 0);
        }

        uint256 liquidityFeePerMillion = _storage.token.liquidityFee.mul(10000);
        uint256 dividendFeePerMillion = _storage.token.dividendFeeLow.mul(10000);
        uint256 potFeePerMillion = _storage.token.potFeeLow.mul(10000);

        if(transferType == MrsDogeToken.TransferType.Sell) {
            uint256 dividendFeePerMillionUpperBound = _storage.token.dividendFeeHigh.mul(10000);
            uint256 potFeePerMillionUpperBound = _storage.token.potFeeHigh.mul(10000);

            uint256 dividendFeeDifferencePerMillion = dividendFeePerMillionUpperBound.sub(dividendFeePerMillion);
            uint256 potFeeDifferencePerMillion = potFeePerMillionUpperBound.sub(potFeePerMillion);

            dividendFeePerMillion = dividendFeePerMillion.add(
                calculateExtraTokenFee(_storage, from, dividendFeeDifferencePerMillion)
            );

            potFeePerMillion = potFeePerMillion.add(
                calculateExtraTokenFee(_storage, from, potFeeDifferencePerMillion)
            );
        }


        return Fees(
            amount.mul(liquidityFeePerMillion).div(1000000),
            amount.mul(dividendFeePerMillion).div(1000000),
            amount.mul(potFeePerMillion).div(1000000)
        );
    }


    function calculateExtraTokenFee(
        Storage storage _storage,
        address from,
        uint256 max
    ) private view returns (uint256) {
        uint256 timeSinceFeeBegin = block.timestamp.sub(_storage.token.feeBeginTimestamp[from]);

        uint256 feeTimeLeft = 0;

        if(timeSinceFeeBegin < _storage.token.feesLoweringDuration) {
            feeTimeLeft = _storage.token.feesLoweringDuration.sub(timeSinceFeeBegin);
        }

        return max
               .mul(feeTimeLeft)
               .div(_storage.token.feesLoweringDuration);
    }

    function calculateTotalFees(Fees memory fees) public pure returns(uint256) {
        return fees.liquidityFees.add(fees.dividendFees).add(fees.potFees);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IUniswapV2Router.sol";
import "./MrsDogeRound.sol";

contract MrsDogeRoundFactory {
    function createMrsDogeRound(
        IUniswapV2Router02 _uniswapV2Router,
        uint256 roundNumber)
        public
        returns (MrsDogeRound) {
        MrsDogeRound round = new MrsDogeRound(
            _uniswapV2Router,
            roundNumber);

        round.makeTokenOwner(msg.sender);

        return round;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./SafeMathUint.sol";
import "./SafeMathInt.sol";
import "./DividendPayingTokenInterface.sol";
import "./DividendPayingTokenOptionalInterface.sol";


/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is ERC20, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  constructor(string memory _name, string memory _symbol) public ERC20(_name, _symbol) {

  }

  /// @dev Distributes dividends whenever ether is paid to this contract.
  receive() external virtual payable {
    distributeDividends(msg.value);
  }

  /// @notice Distributes ether to token holders as dividends.
  /// @dev It reverts if the total supply of tokens is 0.
  /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
  /// About undistributed ether:
  ///   In each distribution, there is a small amount of ether not distributed,
  ///     the magnified amount of which is
  ///     `(msg.value * magnitude) % totalSupply()`.
  ///   With a well-chosen `magnitude`, the amount of undistributed ether
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed ether in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved ether, so we don't do that.
  function distributeDividends(uint256 amount) public override payable {
    require(totalSupply() > 0);

    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, amount);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(msg.sender);
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      (bool success,) = user.call{value: _withdrawableDividend, gas: 3000}("");

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }


  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view virtual override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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

pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

// SPDX-License-Identifier: MIT

/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.6.12;

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns(uint256);

  /// @notice Distributes ether to token holders as dividends.
  /// @dev SHOULD distribute the paid ether to token holders as dividends.
  ///  SHOULD NOT directly transfer ether to token holders in this function.
  ///  MUST emit a `DividendsDistributed` event when the amount of distributed ether is greater than 0.
  function distributeDividends(uint256 amount) external payable;

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
  ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
  function withdrawDividend() external;

  /// @dev This event MUST emit when ether is distributed to token holders.
  /// @param from The address which sends ether to this contract.
  /// @param weiAmount The amount of distributed ether in wei.
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  /// @dev This event MUST emit when an address withdraws their dividend.
  /// @param to The address which withdraws ether from this contract.
  /// @param weiAmount The amount of withdrawn ether in wei.
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./MrsDoge.sol";
import "./MrsDogePot.sol";
import "./MrsDogeRound.sol";
import "./MathUtils.sol";

contract MrsDogeLatestBuyerPot {
    using SafeMath for uint256;

    MrsDoge public token;

    uint256 public permillePerHour;

    struct LatestBuyer
    {
        address user;
        uint256 roundNumber;
        uint256 blockNumber;
        uint256 earningsPerBlock;
    }

    LatestBuyer public latestBuyer;

    modifier onlyCurrentRound() {
        MrsDogeRound round = token.getCurrentRound();
        require(msg.sender == address(round), "MRSDogeLatestBuyerPot: caller is not the current round");
        _;
    }

    modifier onlyTokenOwner() {
        require(msg.sender == token.owner(), "MRSDogeLatestBuyerPot: caller is not the token owner");
        _;
    }

    event PermillePerHourUpdated(uint256 newValue, uint256 oldValue);
    event LatestBuyerPayout(address indexed user, uint256 indexed roundNumber, uint256 amount, uint256 blocksElapsed);

    constructor() public {
        MrsDogePot pot = MrsDogePot(msg.sender);

    	  token = MrsDoge(payable(pot.owner()));

        permillePerHour = 50;
        emit PermillePerHourUpdated(permillePerHour, 0);
    }

    receive() external payable {

    }

    function updatePermillePerHour(uint256 _permillePerHour) public onlyTokenOwner {
        require(_permillePerHour <= 500);
        emit PermillePerHourUpdated(_permillePerHour, permillePerHour);
        permillePerHour = _permillePerHour;
    }

    function sendEarnings(address user, uint256 amount, uint256 blocksElapsed) private {
        (bool success,) = user.call {value: amount} ("");

        if(success) {
            emit LatestBuyerPayout(
                latestBuyer.user,
                latestBuyer.roundNumber,
                amount,
                blocksElapsed);
        }
    }

    function calculateEarningsPerBlock(uint256 ticketsBought) private view returns (uint256) {
        uint256 earningsPerHour = permillePerHour.mul(address(this).balance).div(1000);

        earningsPerHour = earningsPerHour.mul(MathUtils.sqrt(ticketsBought.mul(10000)).div(100));

        return earningsPerHour.div(1200);
    }

    function handleBuy(address user, uint256 ticketsBought, uint256 payoutBonusPermille) external onlyCurrentRound {
        uint256 currentRoundNumber = token.getCurrentRound().roundNumber();
        uint256 currentBlock = block.number;

        if(latestBuyer.user != address(0x0) &&
           latestBuyer.roundNumber == currentRoundNumber) {
            uint256 blocksElapsed = currentBlock.sub(latestBuyer.blockNumber);
            uint256 earnings = blocksElapsed.mul(latestBuyer.earningsPerBlock);

            earnings = earnings.add(earnings.mul(payoutBonusPermille).div(1000));

            if(earnings > address(this).balance) {
                earnings = address(this).balance;
            }

            sendEarnings(latestBuyer.user, earnings, blocksElapsed);
        }

        latestBuyer.user = user;
        latestBuyer.roundNumber = currentRoundNumber;
        latestBuyer.blockNumber = currentBlock;
        latestBuyer.earningsPerBlock = calculateEarningsPerBlock(ticketsBought);
    }


    function latestBuyerUser() public view returns (address) {
        return latestBuyer.user;
    }

    function latestBuyerEarningsPerBlock() public view returns (uint256) {
        return latestBuyer.earningsPerBlock;
    }

}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./MrsDoge.sol";
import "./MrsDogeGameSettings.sol";
import "./MrsDogeRoundBuyers.sol";
import "./MrsDogeTokenHolders.sol";
import "./MrsDogeLatestBuyerPot.sol";
import "./MrsDogeRoundStorageStats.sol";
import "./IUniswapV2Router.sol";
import "./SafeMath.sol";
import "./IBogRandOracleV2.sol";


library MrsDogeRoundStorage {
    using SafeMath for uint256;
    using MrsDogeGameSettings for MrsDogeGameSettings.RoundSettings;
    using MrsDogeGameSettings for MrsDogeGameSettings.PayoutSettings;
    using MrsDogeRoundBuyers for MrsDogeRoundBuyers.Buyers;

    event Payout(
        address indexed user,
        PayoutType indexed payoutType,
        uint256 indexed place,
        uint256 amount
    );

    event ReferralPayout(
        address indexed referrer,
        address indexed referred,
        uint256 amount
    );

    enum PayoutType {
        LastBuyer,
        TopBuyer,
        SmallHolderLottery,
        LargeHolderLottery,
        HugeHolderLottery,
        Marketing
    }


    struct Storage {
    	uint256 roundNumber;

	    uint256 startBlock;
	    uint256 startTimestamp;

	    uint256 blocksLeftAtLastBuy;
	    uint256 lastBuyBlock;

        uint256 totalSpentOnTickets;
	    uint256 ticketsBought;

        uint256 tokensBurned;

	    uint256 endBlock;
	    uint256 endTimestamp;

	    uint256 mustReceiveRandomnessByBlock;

	    uint256 roundPot;

        MrsDogeRoundBuyers.Buyers buyers;
        IUniswapV2Router02 uniswapV2Router;

        MrsDoge gameToken;
        IBogRandOracleV2 rng;

        MrsDogeGameSettings.RoundSettings roundSettings;
        MrsDogeGameSettings.PayoutSettings payoutSettings;

        bool cooldownHasBeenExtended;

    }

    function start(
        Storage storage _storage
    ) public {

        (MrsDogeGameSettings.RoundSettings memory contractRoundSettings,
        MrsDogeGameSettings.PayoutSettings memory contractPayoutSettings,,,) = _storage.gameToken.settings();

        _storage.roundSettings = contractRoundSettings;
        _storage.payoutSettings = contractPayoutSettings;

        _storage.startBlock = block.number;
        _storage.startTimestamp = block.timestamp;

        _storage.blocksLeftAtLastBuy = _storage.roundSettings.roundLengthBlocks;
        _storage.lastBuyBlock = _storage.startBlock;
    }

    function receiveRoundPot(Storage storage _storage) public {
        require(_storage.endTimestamp > 0, "MRSDogeRound: round is not over");
        require(_storage.roundPot == 0, "MRSDogeRound: round pot already received");

        _storage.roundPot = msg.value;
    }

    function cooldownOverBlock(Storage storage _storage) public view returns(uint256) {
        if(_storage.endBlock == 0) {
            return 0;
        }

        return _storage.endBlock.add(_storage.roundSettings.gameCooldownBlocks);
    }

    function extendCooldown(Storage storage _storage, uint256 blocks) public {
        require(!_storage.cooldownHasBeenExtended, "MRSDogeRound: round cooldown has already been extended");
        _storage.cooldownHasBeenExtended = true;
        _storage.roundSettings.gameCooldownBlocks = _storage.roundSettings.gameCooldownBlocks.add(blocks);
    }

    function returnFundsToPot(Storage storage _storage) public {
        if(address(this).balance > 0) {
            sendToPot(_storage, address(this).balance);
        }
    }

    function blocksLeft(Storage storage _storage) public view returns (int256) {
        if(_storage.endTimestamp > 0) {
            return 0;
        }

        uint256 blocksSinceLastBuy = block.number.sub(_storage.lastBuyBlock);

        return int256(_storage.blocksLeftAtLastBuy) - int256(blocksSinceLastBuy);
    }

    function calculatePriceForTickets(Storage storage _storage, address user, uint256 amount) public view returns (uint256) {
        if(_storage.endTimestamp > 0) {
            return 0;
        }

        return _storage.roundSettings.calculatePriceForTickets(
            _storage.payoutSettings,
            _storage.gameToken,
            _storage.startBlock,
            potBalance(_storage),
            user,
            amount);
    }

    function isContract(address _address) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }

    function uintToString(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }


    function buyExactTickets(Storage storage _storage, address user, uint256 amount) public returns (bool) {
        require(_storage.endTimestamp == 0, "MRSDogeRound: round is over");
        require(amount > 0, "MRSDogeRound: cannot buy zero tickets");
        require(_storage.gameToken.balanceOf(user) >= _storage.roundSettings.tokensNeededToBuyTickets, "MRSDogeRound: insufficient tokens");
        if(_storage.roundSettings.contractsDisabled) {
            require(!isContract(user), "MRSDogeRound: contract cannot buy");
        }

        int256 oldBlocksLeft = blocksLeft(_storage);

        if(oldBlocksLeft < 0) {
            completeRoundIfOver(_storage);

            (bool success,) = user.call {value: msg.value, gas: 5000} ("");
            require(success, "MRSDogeRound: could not return ticket buy money");

            return false;
        }

        uint256 price = calculatePriceForTickets(_storage, user, amount);

        require(msg.value >= price, string(abi.encodePacked("MRSDogeRound: msg.value too low: ", uintToString(msg.value), " ", uintToString(price))));

        uint256 blocksAdded = _storage.roundSettings.blocksAddedPer100TicketsBought.mul(amount).div(100);

        if(blocksAdded == 0) {
            blocksAdded = 1;
        }

        uint256 newBlocksLeft = uint256(oldBlocksLeft + int256(blocksAdded));

        _storage.blocksLeftAtLastBuy = newBlocksLeft;
        _storage.lastBuyBlock = block.number;
        _storage.ticketsBought = _storage.ticketsBought.add(amount);
        _storage.totalSpentOnTickets = _storage.totalSpentOnTickets.add(price);


        if(_storage.blocksLeftAtLastBuy > _storage.roundSettings.roundLengthBlocks) {
            _storage.blocksLeftAtLastBuy = _storage.roundSettings.roundLengthBlocks;
        }

        uint256 returnAmount = msg.value.sub(price);

        (bool success,) = user.call {value: returnAmount } ("");

        require(success, "MRSDogeRound: could not return excess");

        _storage.buyers.handleBuy(user, amount, price);


        MrsDogeLatestBuyerPot latestBuyersPot = _storage.gameToken.pot().latestBuyerPot();


        //if(address(latestBuyersPot) != address(0)) {

            uint256 payoutBonusPermille = _storage.roundSettings.getUserBonusPermille(
                                             _storage.gameToken,
                                             latestBuyersPot.latestBuyerUser()
                                          );


            latestBuyersPot.handleBuy(user, amount, payoutBonusPermille);

        //}


        distribute(_storage, price, user);


        return true;
    }

    function distribute(Storage storage _storage, uint256 amount, address user) private {
        uint256 potFee = amount.mul(_storage.roundSettings.gameFeePotPercent).div(100);
        uint256 buyTokensForPotFee = amount.mul(_storage.roundSettings.gameFeeBuyTokensForPotPercent).div(100);
        uint256 referralFee = amount.sub(potFee).sub(buyTokensForPotFee);


        // send funds to pot
        sendToPot(_storage, potFee);

        // buy tokens for pot
        address[] memory path = new address[](2);
        path[0] = _storage.uniswapV2Router.WETH();
        path[1] = address(_storage.gameToken);

        address potAddress = address(_storage.gameToken.pot());

        uint256 balanceBefore = _storage.gameToken.balanceOf(potAddress);

        // make the swap
        _storage.uniswapV2Router.swapExactETHForTokens {value:buyTokensForPotFee} (
            0,
            path,
            potAddress,
            block.timestamp
        );

        uint256 balanceAfter = _storage.gameToken.balanceOf(potAddress);

        if(balanceAfter > balanceBefore) {
            _storage.tokensBurned = _storage.tokensBurned.add(balanceAfter.sub(balanceBefore));
        }

        //referral
        if(referralFee > 0) {
            address referrer = _storage.gameToken.referredBy(user);

            if(referrer != address(0)) {
                (bool success1,) = referrer.call { value: referralFee, gas: 5000 } ("");

                if(success1) {
                    emit ReferralPayout(referrer, user, referralFee);
                }
            }
            else {
                sendToPot(_storage, referralFee);
            }
        }
    }

    function sendToPot(Storage storage _storage, uint256 amount) private {
        (bool success,) = address(_storage.gameToken.pot()).call {value: amount } ("");
        require(success, "MRSDogeRound: send to pot failed");
    }

    function potBalance(Storage storage _storage) private view returns (uint256) {
        return address(_storage.gameToken.pot()).balance;
    }

    function completeRoundIfOver(Storage storage _storage) public returns (bool) {
        if(_storage.endTimestamp > 0) {
            return false;
        }

        if(blocksLeft(_storage) >= 0) {
            return false;
        }

        _storage.endBlock = block.number;
        _storage.endTimestamp = block.timestamp;

        _storage.gameToken.pot().takeRoundPot();

        uint256 gasCost = 10000000 gwei;

        if(potBalance(_storage) >= gasCost) {
            uint256 blocksToReceiveRandomness = 15;
            _storage.mustReceiveRandomnessByBlock = block.number.add(blocksToReceiveRandomness);

            _storage.gameToken.pot().takeGasFees(gasCost);

            _storage.gameToken.lockTokenHolders(_storage.mustReceiveRandomnessByBlock.add(1));
            _storage.rng.requestRandomnessBNBFee {value: gasCost } ();
        }

        payoutLastBuyer(_storage);
        payoutTopBuyers(_storage);
        payoutMarketing(_storage);

        _storage.gameToken.roundCompleted();

        return true;
    }

    function payoutLastBuyer(Storage storage _storage) private {
        uint256 payout = _storage.roundPot.mul(_storage.payoutSettings.lastBuyerPayoutPercent).div(100);

        if(_storage.buyers.lastBuyer != address(0x0)) {
            uint256 bonus = _storage.roundSettings.calculateBonus(_storage.gameToken, _storage.buyers.lastBuyer, payout);

            if(bonus > 0 && potBalance(_storage) >= bonus) {
                _storage.gameToken.pot().takeBonus(bonus);

                payout = payout.add(bonus);
            }

            (bool success,) = _storage.buyers.lastBuyer.call { value: payout, gas: 5000 } ("");

            if(success) {
                emit Payout(_storage.buyers.lastBuyer, PayoutType.LastBuyer, 0, payout);
            }

            _storage.buyers.lastBuyerPayout = payout;
        }
        else {
            sendToPot(_storage, payout);
        }
    }

    function payoutTopBuyers(Storage storage _storage) private {

        MrsDogeRoundBuyers.Buyer storage buyer = _storage.buyers.topBuyer();

        for(uint256 i = 0; i < MrsDogeRoundBuyers.maxLength(); i = i.add(1)) {
            uint256 payout = _storage.roundPot.mul(_storage.payoutSettings.placePayoutPercents[i]).div(100);

            if(payout == 0) {
                continue;
            }

            if(buyer.user != address(0x0)) {

                uint256 bonus = _storage.roundSettings.calculateBonus(_storage.gameToken, buyer.user, payout);

                if(bonus > 0 && potBalance(_storage) >= bonus) {
                    _storage.gameToken.pot().takeBonus(bonus);

                    payout = payout.add(bonus);
                }

                (bool success,) = buyer.user.call { value: payout, gas: 5000 } ("");

                if(success) {
                    emit Payout(buyer.user, PayoutType.TopBuyer, i.add(1), payout);
                }

                buyer.payout = payout;
            }
            else {
                sendToPot(_storage, payout);
            }

            buyer = _storage.buyers.list[buyer.next];
        }
    }

    function payoutMarketing(Storage storage _storage) private {
        uint256 payout = _storage.roundPot.mul(_storage.payoutSettings.marketingPayoutPercent).div(100);

        if(payout > 0) {
            (bool success,) = _storage.gameToken.teamWallet().call { value: payout, gas: 5000 } ("");

            if(success) {
                emit Payout(_storage.gameToken.teamWallet(), PayoutType.Marketing, 0, payout);
            }
        }
    }

    function receiveRandomness(Storage storage _storage, bytes32, uint256 random) public {
        if(block.number > _storage.mustReceiveRandomnessByBlock) {
            return;
        }

        //unlock
        _storage.gameToken.lockTokenHolders(0);

        address[] memory smallHolders = _storage.gameToken.getRandomHolders(random, _storage.payoutSettings.smallHolderLotteryPayoutCount, MrsDogeTokenHolders.HolderType.Small);
        address[] memory largeHolders = _storage.gameToken.getRandomHolders(random, _storage.payoutSettings.largeHolderLotteryPayoutCount, MrsDogeTokenHolders.HolderType.Large);
        address[] memory hugeHolders = _storage.gameToken.getRandomHolders(random, _storage.payoutSettings.hugeHolderLotteryPayoutCount, MrsDogeTokenHolders.HolderType.Huge);

        payoutHolders(_storage, smallHolders, _storage.payoutSettings.smallHolderLotteryPayoutPercent, PayoutType.SmallHolderLottery);
        payoutHolders(_storage, largeHolders, _storage.payoutSettings.largeHolderLotteryPayoutPercent, PayoutType.LargeHolderLottery);
        payoutHolders(_storage, hugeHolders, _storage.payoutSettings.hugeHolderLotteryPayoutPercent, PayoutType.HugeHolderLottery);
    }


    function payoutHolders(Storage storage _storage, address[] memory holders, uint256 percentOfRoundPot, PayoutType payoutType) private {
        uint256 totalPayout = _storage.roundPot.mul(percentOfRoundPot).div(100);

        if(holders.length > 0) {

            uint256 remaining = totalPayout;

            for(uint256 i = 0; i < holders.length; i = i.add(1)) {
                uint256 payout = remaining.div(holders.length.sub(i));

                uint256 bonus = _storage.roundSettings.calculateBonus(_storage.gameToken, holders[i], payout);

                uint256 payoutWithBonus = payout;

                if(bonus > 0 && potBalance(_storage) >= bonus) {
                    _storage.gameToken.pot().takeBonus(bonus);

                    payoutWithBonus = payout.add(bonus);
                }

                (bool success,) = holders[i].call {value: payoutWithBonus, gas: 5000} ("");

                if(success) {
                    emit Payout(holders[i], payoutType, 0, payoutWithBonus);
                }

                remaining = remaining.sub(payout);
            }
        }
        else {
            sendToPot(_storage, totalPayout);
        }
    }

    function getNumberOfTicketsBought(Storage storage _storage, address user) external view returns (uint256) {
        return _storage.buyers.list[user].ticketsBought;
    }
    
    function generateGameStats(
    			 Storage storage _storage,
        		 address user)
        public
        view
        returns (uint256[] memory roundStats,
                int256 blocksLeftAtCurrentBlock,
                 address lastBuyer,
                 uint256[] memory lastBuyerStats,
                 uint256[] memory userStats,
                 address[] memory topBuyerAddress,
                 uint256[] memory topBuyerData) {

        uint256 currentRoundPot = MrsDogeRoundStorageStats.generateCurrentRoundPot(_storage, cooldownOverBlock(_storage), potBalance(_storage));

        roundStats = MrsDogeRoundStorageStats.generateRoundStats(_storage, currentRoundPot);
        blocksLeftAtCurrentBlock = blocksLeft(_storage);

        lastBuyer = _storage.buyers.lastBuyer;

        lastBuyerStats = MrsDogeRoundStorageStats.generateLastBuyerStats(_storage, currentRoundPot);

        userStats = MrsDogeRoundStorageStats.generateUserStats(_storage, user);
        (topBuyerAddress, topBuyerData) = MrsDogeRoundStorageStats.generateTopBuyerStats(_storage, currentRoundPot);
    }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

import "./SafeMath.sol";


library MrsDogeRoundBuyers {
    using SafeMath for uint256;

    struct Buyers {
        mapping(address => Buyer) list;
        address head;
        address lastBuyer;
        uint256 lastBuyerBlock;
        uint256 lastBuyerPayout;
    }

    struct Buyer {
    	address user;
    	uint256 ticketsBought;
        uint256 totalSpentOnTickets;
        uint256 lastBuyBlock;
        uint256 lastBuyTimestamp;
        uint256 payout;
    	address prev;
    	address next;
    }

    function maxLength() public pure returns (uint256) {
        return 3;
    }

    function topBuyer(Buyers storage self) public view returns (Buyer storage) {
        return self.list[self.head];
    }

    function updateBuyerForBuy(Buyer storage buyer, uint256 ticketsBought, uint256 price) private {
        buyer.ticketsBought = buyer.ticketsBought.add(ticketsBought);
        buyer.totalSpentOnTickets = buyer.totalSpentOnTickets.add(price);
        buyer.lastBuyBlock = block.number;
        buyer.lastBuyTimestamp = block.timestamp;
    }

    function handleBuy(Buyers storage self, address user, uint256 amount, uint256 price) public {
    	Buyer storage buyer = self.list[user];

        self.lastBuyer = user;
        self.lastBuyerBlock = block.number;

        //set user
    	if(buyer.user == address(0x0)) {
            buyer.user = user;
    	}
    	else {
    		Buyer storage buyerPrev = self.list[buyer.prev];
    		Buyer storage buyerNext = self.list[buyer.next];

    		// already first
    		if(buyer.user == self.head) {
                updateBuyerForBuy(buyer, amount, price);
    			return;
    		}

            //check they are in the list
            if(buyerPrev.user != address(0x0)) {
                // at end of list
                if(buyerNext.user == address(0x0)) {
                    buyerPrev.next = address(0x0);
                }
                else {
                    buyerPrev.next = buyerNext.user;
                    buyerNext.prev = buyerPrev.user;
                }
            }
    	  }

        updateBuyerForBuy(buyer, amount, price);
        buyer.prev = address(0x0);
        buyer.next = address(0x0);

        // insert into list
        Buyer storage checkBuyer = self.list[self.head];

        if(checkBuyer.user == address(0x0)) {
            self.head = user;
            return;
        }

        uint256 count = 0;

        // only store if in top 3
        while(count < maxLength()) {
            if(buyer.ticketsBought > checkBuyer.ticketsBought) {
                Buyer storage buyerPrev = self.list[checkBuyer.prev];

                if(buyerPrev.user != address(0x0)) {
                    buyerPrev.next = buyer.user;
                    buyer.prev = buyerPrev.user;
                }
                else {
                    self.head = buyer.user;
                    buyer.prev = address(0x0);
                }

                buyer.next = checkBuyer.user;
                checkBuyer.prev = buyer.user;

                return;
            }

            if(checkBuyer.next == address(0x0)) {
                checkBuyer.next = buyer.user;
                buyer.prev = checkBuyer.user;

                return;
            }

            count = count.add(1);
            checkBuyer = self.list[checkBuyer.next];
        }
    }

}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

interface IReceivesBogRandV2 {
    function receiveRandomness(bytes32 hash, uint256 random) external;
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

interface IBogRandOracleV2 {
    // Request randomness with fee in BOG
    function getBOGFee() external view returns (uint256);
    function requestRandomness() external payable returns (bytes32 assignedHash, uint256 requestID);

    // Request randomness with fee in BNB
    function getBNBFee() external view returns (uint256);
    function requestRandomnessBNBFee() external payable returns (bytes32 assignedHash, uint256 requestID);
    
    // Retrieve request details
    enum RequestState { REQUESTED, FILLED, CANCELLED }
    function getRequest(uint256 requestID) external view returns (RequestState state, bytes32 hash, address requester, uint256 gas, uint256 requestedBlock);
    function getRequest(bytes32 hash) external view returns (RequestState state, uint256 requestID, address requester, uint256 gas, uint256 requestedBlock);
    // Get request blocks to use with blockhash as hash seed
    function getRequestBlock(uint256 requestID) external view returns (uint256);
    function getRequestBlock(bytes32 hash) external view returns (uint256);

    // RNG backend functions
    function seed(bytes32 hash) external;
    function getNextRequest() external view returns (uint256 requestID);
    function fulfilRequest(uint256 requestID, uint256 random, bytes32 newHash) external;
    function cancelRequest(uint256 requestID, bytes32 newHash) external;
    function getFullHashReserves() external view returns (uint256);
    function getDepletedHashReserves() external view returns (uint256);
    
    // Events
    event Seeded(bytes32 hash);
    event RandomnessRequested(uint256 requestID, bytes32 hash);
    event RandomnessProvided(uint256 requestID, address requester, uint256 random);
    event RequestCancelled(uint256 requestID);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;



library MathUtils {

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function eighthRoot(uint y) internal pure returns (uint z) {
        return sqrt(sqrt(sqrt(y)));
    }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;


import "./MrsDogeRoundStorage.sol";
import "./MrsDogeGameSettings.sol";
import "./MrsDogeRoundBuyers.sol";
import "./SafeMath.sol";

library MrsDogeRoundStorageStats {
    using SafeMath for uint256;
    using MrsDogeGameSettings for MrsDogeGameSettings.RoundSettings;

    function generateRoundStats(MrsDogeRoundStorage.Storage storage _storage, uint256 currentRoundPot)
    	public
    	view
    	returns (uint256[] memory roundStats) {
        roundStats = new uint256[](14);

        roundStats[0] = _storage.roundNumber;
        roundStats[1] = _storage.startBlock;
        roundStats[2] = _storage.startTimestamp;
        roundStats[3] = _storage.endBlock;
        roundStats[4] = _storage.endTimestamp;
        roundStats[5] = _storage.ticketsBought;
        roundStats[6] = _storage.totalSpentOnTickets;
        roundStats[7] = currentRoundPot;
        roundStats[8] = _storage.blocksLeftAtLastBuy;
        roundStats[9] = _storage.lastBuyBlock;
        roundStats[10] = _storage.tokensBurned;
        roundStats[11] = block.timestamp;
        roundStats[12] = block.number;
        roundStats[13] = address(_storage.gameToken.pot()).balance;
    }

    function generateLastBuyerStats(MrsDogeRoundStorage.Storage storage _storage, uint256 currentRoundPot)
    	public
    	view
    	returns (uint256[] memory lastBuyerStats) {
        lastBuyerStats = new uint256[](5);

        if(_storage.buyers.lastBuyerPayout > 0) {
            lastBuyerStats[0] = _storage.buyers.lastBuyerPayout;
        }
        else {
            lastBuyerStats[0] = calculateLastBuyerPayout(_storage, currentRoundPot);
        }

        if(_storage.buyers.lastBuyer != address(0)) {
            lastBuyerStats[1] = _storage.gameToken.balanceOf(_storage.buyers.lastBuyer);

            uint256 bonusPermille = _storage.roundSettings.getUserBonusPermille(_storage.gameToken, _storage.buyers.lastBuyer);
            lastBuyerStats[2] = bonusPermille;

            lastBuyerStats[3] = _storage.buyers.lastBuyerBlock;

            uint256 earningsPerBlock = _storage.gameToken.pot().latestBuyerPot().latestBuyerEarningsPerBlock();
            lastBuyerStats[4] = earningsPerBlock.add(earningsPerBlock.mul(bonusPermille).div(1000));
        }
    }

    function calculateLastBuyerPayout(MrsDogeRoundStorage.Storage storage _storage, uint256 currentRoundPot) private view returns (uint256 lastBuyerPayout) {
        lastBuyerPayout = currentRoundPot.mul(_storage.payoutSettings.lastBuyerPayoutPercent).div(100);
        uint256 bonus = _storage.roundSettings.calculateBonus(_storage.gameToken, _storage.buyers.lastBuyer, lastBuyerPayout);
        lastBuyerPayout = lastBuyerPayout.add(bonus);
    }

    function generateUserStats(
        MrsDogeRoundStorage.Storage storage _storage,
        address user)
    	public
        view
        returns (uint256[] memory userStats) {
        userStats = new uint256[](6);

        userStats[0] = _storage.buyers.list[user].ticketsBought;
        userStats[1] = _storage.buyers.list[user].totalSpentOnTickets;
        userStats[2] = _storage.buyers.list[user].lastBuyBlock;
        userStats[3] = _storage.buyers.list[user].lastBuyTimestamp;
        userStats[4] = _storage.gameToken.balanceOf(user);
        userStats[5] = _storage.roundSettings.getUserBonusPermille(_storage.gameToken, user);
    }

    function generateTopBuyerStats(MrsDogeRoundStorage.Storage storage _storage, uint256 currentRoundPot)
        public
        view
        returns (address[] memory topBuyerAddress,
                uint256[] memory topBuyerData) {
        uint256 maxLength = MrsDogeRoundBuyers.maxLength();

        uint256 topBuyerDataLength = 6;

        topBuyerAddress = new address[](maxLength);
        topBuyerData = new uint256[](maxLength.mul(topBuyerDataLength));

        MrsDogeRoundBuyers.Buyer storage buyer = _storage.buyers.list[_storage.buyers.head];

        for(uint256 i = 0; i < maxLength; i++) {

            uint256 payout = 0;

            if(i < 3) {
                if(buyer.payout > 0) {
                    payout = buyer.payout;
                }
                else {
                    payout = currentRoundPot.mul(_storage.payoutSettings.placePayoutPercents[i]).div(100);
                    payout = payout.add(
                        _storage.roundSettings.calculateBonus(
                            _storage.gameToken,
                            buyer.user,
                            payout
                        )
                    );
                }
            }

            topBuyerAddress[i] = buyer.user;

            uint256 startIndex = i.mul(topBuyerDataLength);

            topBuyerData[startIndex.add(0)] = buyer.ticketsBought;
            topBuyerData[startIndex.add(1)] = buyer.lastBuyBlock;
            topBuyerData[startIndex.add(2)] = buyer.lastBuyTimestamp;
            topBuyerData[startIndex.add(3)] = payout;
            topBuyerData[startIndex.add(4)] = _storage.gameToken.balanceOf(buyer.user);
            topBuyerData[startIndex.add(5)] = _storage.roundSettings.getUserBonusPermille(_storage.gameToken, buyer.user);

            buyer = _storage.buyers.list[buyer.next];
        }
    }

    function generateCurrentRoundPot(MrsDogeRoundStorage.Storage storage _storage, uint256 cooldownOverBlock, uint256 potBalance)
    	public
   	 	view
    	returns (uint256) {
        if(_storage.roundPot > 0 && (cooldownOverBlock == 0 || block.number < cooldownOverBlock)) {
            return _storage.roundPot;
        }

        if(cooldownOverBlock > 0 && block.number > cooldownOverBlock) {
            potBalance = potBalance.add(address(this).balance);
        }

        return potBalance.mul(_storage.payoutSettings.roundPotPercent).div(100);
    }

}

