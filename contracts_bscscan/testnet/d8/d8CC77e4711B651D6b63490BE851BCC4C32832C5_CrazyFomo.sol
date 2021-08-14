/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

// SPDX-License-Identifier: BSD
/**
   # CrazyFomo
   
   # CrazyFomo features:
   1% fee auto moved to dev wallet
   2% fee auto added to the liquidity pool
   4% fee auto distributed to all holders
   5% fee auto added to the pot.
   Last 6 buyers before the timer runs out split 70% of the pot
       proportional to their buys. Absolute last buyer gets 20% of the pot. 30% carries over to next round.
 */


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
        require(c >= a, "addition overflow");

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
        return sub(a, b, "subtraction overflow");
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
        require(c / a == b, "multiplication overflow");

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
        return div(a, b, "division by zero");
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
        return mod(a, b, "modulo by zero");
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

interface IERC20 {

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}


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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
}

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract CrazyFomo is Context, IERC20, Ownable {
    using SafeMath for uint256;

    address[] private _addressList;
    mapping (address => bool) private _AddressExists;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => uint256) private _lastRate;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    
    string private _name = "CrazyFomo";
    string private _symbol = "CFO3";
    uint8 private  _decimals = 18;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 3 * (10**9) * (10**18);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    address payable private _devWallet;
    
    uint256 private _minimumBuyForPotEligibility = 10000 * (10**18);
    
    uint256 public _devFee = 1;
    uint256 private _previousDevFee = _devFee;
    
    uint256 public _liquidityFee = 2;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 public _taxFee = 4;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _potFee = 5;
    uint256 private _previousPotFee = _potFee;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool inSwap;
    
    TransferType transferType;
    
    // IERC20 public bnb = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c); // main net
    IERC20 public bnb = IERC20(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd); // test net
    
    uint256[5] public feeFomo = [8, 12, 15, 18, 21];
    
    struct GameSettings {
        uint256 maxTxAmount; // maximum number of tokens in one transfer
        uint256 tokenSwapThreshold; // number of tokens needed in contract to swap and sell
        uint256 minimumBuyForPotEligibility; //minimum buy to be eligible to win share of the pot
        uint8   increaseRatio; // increase raito for minimumBuyForPotEligibility each eligibile buy %%
        uint256 initTimeLeft; // init number of seconds for the game
        uint256 maxTimeLeft; //maximum number of seconds the timer can be
        uint256 extraTimeEachPot; //if timer is under this value, the potFeeExtra is used
        uint256 eliglblePlayers; //number of players eligible for winning share of the pot
        uint256 potPayoutPercent; // what percent of the pot is paid out, vs. carried over to next round
        uint256 lastBuyerPayoutPercent; //what percent of the paid-out-pot is paid to absolute last buyer
    }

    GameSettings public gameSettings;

    bool public gameIsActive = false;

    uint256 private roundNumber;

    uint256 private timeLeftAtLastBuy;
    uint256 private lastBuyBlock;

    uint256 private liquidityTokens;
    uint256 private potTokens;

    address private liquidityAddress;
    address private gameSettingsUpdaterAddress;

    mapping (uint256 => Buyer[]) buyersByRound;

    modifier onlyGameSettingsUpdater() {
        require(_msgSender() == gameSettingsUpdaterAddress, "caller != game settings updater");
        _;
    }

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event GameSettingsUpdated(
        uint256 maxTxAmount,
        uint256 tokenSwapThreshold,
        uint256 minimumBuyForPotEligibility,
        uint8   increaseRatio,
        uint256 initTimeLeft,
        uint256 maxTimeLeft,
        uint256 extraTimeEachPot,
        uint256 eliglblePlayers,
        uint256 potPayoutPercent,
        uint256 lastBuyerPayoutPercent
    );

    event GameSettingsUpdaterUpdated(
        address oldGameSettingsUpdater,
        address newGameSettingsUpdater
    );

    event RoundStarted(
        uint256 number,
        uint256 potValue
    );

    event Buy(
        bool indexed isEligible,
        address indexed buyer,
        uint256 amount,
        uint256 timeLeftBefore,
        uint256 timeLeftAfter,
        uint256 blockTime,
        uint256 blockNumber
    );
    
    event RoundPayout(
        uint256 indexed roundNumber,
        address indexed buyer,
        uint256 amount,
        bool success
    );

    event RoundEnded(
        uint256 number,
        address[] winners,
        uint256[] winnerAmountsRound
    );
    
    enum TransferType {
        Normal,
        Buy,
        Sell,
        RemoveLiquidity
    }

    struct Buyer {
        address buyer;
        uint256 amount;
        uint256 timeLeftBefore;
        uint256 timeLeftAfter;
        uint256 blockTime;
        uint256 blockNumber;
    }

    constructor () public {
        gameSettings = GameSettings(
            2000000 * 10**18, //maxTxAmount is 2 million tokens
            200000 * 10**18, //tokenSwapThreshold is 200000 tokens
            10000 * 10**18, //minimumBuyForPotEligibility is 10000 tokens
            35, //increaseRatio 0.035% for minimumBuyForPotEligibility
            60 * 60 * 4, // initTimeLeft is 4 hours
            60 * 60 * 8, //maxTimeLeft is 8 hours
            30, //extraTimeEachPot is 30 seconds
            6, //eliglblePlayers is 6
            70, //potPayoutPercent is 70%
            28 //lastBuyerPayoutPerent is 28% of the 70%, which is ~20% overall
        );

        liquidityAddress = _msgSender();
        gameSettingsUpdaterAddress = _msgSender();
        _devWallet = _msgSender();
        
        _rOwned[_devWallet] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        //exclude owner and this contract from fee
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    // for any non-zero value it updates the game settings to that value
    function updateGameSettings(
        uint256 maxTxAmount,
        uint256 tokenSwapThreshold,
        uint256 minimumBuyForPotEligibility,
        uint8   increaseRatio,
        uint256 initTimeLeft,
        uint256 maxTimeLeft,
        uint256 extraTimeEachPot,
        uint256 eliglblePlayers,
        uint256 potPayoutPercent,
        uint256 lastBuyerPayoutPercent
    )
        public
        onlyGameSettingsUpdater {

        if(maxTxAmount > 0)  {
            require(maxTxAmount >= 1000000 * 10**18 && maxTxAmount <= 10000000 * 10**18);
            gameSettings.maxTxAmount = maxTxAmount;
        }
        if(tokenSwapThreshold > 0)  {
            require(tokenSwapThreshold >= 100000 * 10**18 && tokenSwapThreshold <= 1000000 * 10**18);
            gameSettings.tokenSwapThreshold = tokenSwapThreshold;
        }
        if(minimumBuyForPotEligibility > 0)  {
            require(minimumBuyForPotEligibility >= 1000 * 10**18 && minimumBuyForPotEligibility <= 100000 * 10**18);
            gameSettings.minimumBuyForPotEligibility = minimumBuyForPotEligibility;
        }
        if(increaseRatio > 0)  {
            require(increaseRatio >= 1 && increaseRatio <= 10 ** 5);
            gameSettings.increaseRatio = increaseRatio;
        }
        if(initTimeLeft > 0)  {
            require(initTimeLeft >= 1800 && initTimeLeft <= 86400);
            gameSettings.initTimeLeft = initTimeLeft;
        }
        if(maxTimeLeft > 0)  {
            require(maxTimeLeft >= 7200 && maxTimeLeft <= 86400);
            gameSettings.maxTimeLeft = maxTimeLeft;
        }
        if(extraTimeEachPot > 0)  {
            require(extraTimeEachPot >= 1 && extraTimeEachPot <= 3600);
            gameSettings.extraTimeEachPot = extraTimeEachPot;
        }
        if(eliglblePlayers > 0)  {
            require(eliglblePlayers >= 3 && eliglblePlayers <= 15);
            gameSettings.eliglblePlayers = eliglblePlayers;
        }
        if(potPayoutPercent > 0)  {
            require(potPayoutPercent >= 30 && potPayoutPercent <= 99);
            gameSettings.potPayoutPercent = potPayoutPercent;
        }
        if(lastBuyerPayoutPercent > 0)  {
            require(lastBuyerPayoutPercent >= 10 && lastBuyerPayoutPercent <= 60);
            gameSettings.lastBuyerPayoutPercent = lastBuyerPayoutPercent;
        }

        emit GameSettingsUpdated(
            maxTxAmount,
            tokenSwapThreshold,
            minimumBuyForPotEligibility,
            increaseRatio,
            initTimeLeft,
            maxTimeLeft,
            extraTimeEachPot,
            eliglblePlayers,
            potPayoutPercent,
            lastBuyerPayoutPercent
        );
    }

    function renounceGameSettingsUpdater() public virtual onlyGameSettingsUpdater {
        emit GameSettingsUpdaterUpdated(gameSettingsUpdaterAddress, address(0));
        gameSettingsUpdaterAddress = address(0);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function originBalanceOf(address account) public view returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        if (_lastRate[account] == 0) {
            return _rOwned[account].div(_getRate());
        }
        return _rOwned[account].div(_lastRate[account]);
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount > allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance < zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be < supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be < total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function setDevAddress(address payable dev) public onlyOwner() {
        _devWallet = dev;
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDev) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidityAndPot(tLiquidity);
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function startGame() public onlyOwner {
        require(!gameIsActive);

        // start on round 1
        roundNumber = roundNumber.add(1);

        timeLeftAtLastBuy = gameSettings.initTimeLeft;
        lastBuyBlock = block.number;

        gameIsActive = true;

        emit RoundStarted(
            roundNumber,
            potValue()
        );
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    struct TData {
        uint256 tAmount;
        uint256 tFee;
        uint256 tLiquidityAndPot;
        uint256 tDev;
        uint256 currentRate;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, TData memory data) = _getTValues(tAmount);
        data.tAmount = tAmount;
        data.currentRate = _getRate();
        
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(data);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, data.tFee, data.tLiquidityAndPot, data.tDev);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, TData memory) {
        uint256 healthLevel = 0;
        if (transferType == TransferType.Sell) {
            healthLevel = getHealthLevel();
        }
        
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidityAndPot = tAmount.mul(_liquidityFee.add(feeFomo[healthLevel])).div(100);
        uint256 tDev = calculateDevFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidityAndPot).sub(tDev);
        return (tTransferAmount, TData(0, tFee, tLiquidityAndPot, tDev, 0));
    }

    function _getRValues(TData memory _data) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = _data.tAmount.mul(_data.currentRate);
        uint256 rFee = _data.tFee.mul(_data.currentRate);
        uint256 rLiquidityAndPot = _data.tLiquidityAndPot.mul(_data.currentRate);
        uint256 rDev = _data.tDev.mul(_data.currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidityAndPot).sub(rDev);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function addAddress(address adr) private {
        if(_AddressExists[adr])
            return;
        _AddressExists[adr] = true;
        _addressList.push(adr);
    }
    
    function _takeLiquidityAndPot(uint256 tLiquidityAndPot) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidityAndPot = tLiquidityAndPot.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidityAndPot);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidityAndPot);

        //keep track of ratio of liquidity vs. pot

        uint256 potFee = currentPotFee();

        uint256 totalFee = potFee.add(_liquidityFee);

        if(totalFee > 0) {
            potTokens = potTokens.add(tLiquidityAndPot.mul(potFee).div(totalFee));
            liquidityTokens = liquidityTokens.add(tLiquidityAndPot.mul(_liquidityFee).div(totalFee));
        }
    }

    function _takeDev(uint256 tDev) private {
        uint256 currentRate =  _getRate();
        uint256 rDev = tDev.mul(currentRate);

        _rOwned[_devWallet] = _rOwned[_devWallet].add(rDev);
        if(_isExcluded[_devWallet])
            _tOwned[_devWallet] = _tOwned[_devWallet].add(tDev);
    }

    function getHealthLevel() private view returns(uint256) {
        uint256 bal = bnb.balanceOf(uniswapV2Pair);
        if (bal <= 320 * 10**18) {
            return 4;
        } else if (bal <= 450 * 10**18) {
            return 3;
        } else if (bal <= 650 * 10**18) {
            return 2;
        } else if (bal <= 1000 * 10**18) {
            return 1;
        }

        return 0;
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }
    
    function calculateDevFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_devFee).div(
            10**2
        );
    }


    function calculateLiquidityAndPotFee(uint256 _amount) private view returns (uint256) {
        uint256 currentPotFee = currentPotFee();

        return _amount.mul(_liquidityFee.add(currentPotFee)).div(
            10**2
        );
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 && _potFee == 0 && _devFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousPotFee = _potFee;
        _previousDevFee = _devFee;

        _taxFee = 0;
        _liquidityFee = 0;
        _potFee = 0;
        _devFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _potFee = _previousPotFee;
        _devFee = _previousDevFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function getTransferType(
        address from,
        address to)
        private
        view
        returns (TransferType) {
        if(from == uniswapV2Pair) {
            if(to == address(uniswapV2Router)) {
                return TransferType.RemoveLiquidity;
            }
            return TransferType.Buy;
        }
        if(to == uniswapV2Pair) {
            return TransferType.Sell;
        }
        if(from == address(uniswapV2Router)) {
            return TransferType.RemoveLiquidity;
        }

        return TransferType.Normal;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        require(amount > 0, "Transfer amount must be > 0");

        transferType = getTransferType(from, to);

        if(
            gameIsActive &&
            !inSwap &&
            transferType == TransferType.Sell &&
            from != liquidityAddress &&
            to != liquidityAddress
        ) {
            require(amount <= gameSettings.maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        completeRoundWhenNoTimeLeft();

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool overMinTokenBalance = contractTokenBalance >= gameSettings.tokenSwapThreshold;

        if(
            gameIsActive && 
            overMinTokenBalance &&
            !inSwap &&
            transferType != TransferType.Buy &&
            from != liquidityAddress &&
            to != liquidityAddress
        ) {
            inSwap = true;

            //Calculate how much to swap and liquify, and how much to just swap for the pot
            uint256 totalTokens = liquidityTokens.add(potTokens);

            if(totalTokens > 0) {
                uint256 swapTokens = contractTokenBalance.mul(liquidityTokens).div(totalTokens);

                //add liquidity
                swapAndLiquify(swapTokens);
            }

            //sell the rest
            uint256 sellTokens = balanceOf(address(this));

            swapTokensForEth(sellTokens);

            liquidityTokens = 0;
            potTokens = 0;

            inSwap = false;
        }
        
        //indicates if fee should be deducted from transfer
        bool takeFee = gameIsActive;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        addAddress(from);
        addAddress(to);

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);

        if(
            gameIsActive 
            && transferType == TransferType.Buy
        ) {
            handleBuyer(to, amount);
        }
    }

    function handleBuyer(address buyer, uint256 amount) private {

        int256 oldTimeLeft = timeLeft();

        if(oldTimeLeft < 0) {
            return;
        }

        int256 newTimeLeft = oldTimeLeft + 30; // eeach buy can increase

        bool isEligible = buyer != address(uniswapV2Router) &&
               !_isExcludedFromFee[buyer] &&
               amount >= _minimumBuyForPotEligibility;

        if(isEligible) {
            Buyer memory newBuyer = Buyer(
                buyer,
                amount,
                uint256(oldTimeLeft),
                uint256(newTimeLeft),
                block.timestamp,
                block.number
            );

            Buyer[] storage buyers = buyersByRound[roundNumber];

            bool added = false;

            // check if buyer would have a 2nd entry in last 6, and remove old one
            for(int256 i = int256(buyers.length) - 1;
                i >= 0 && i > int256(buyers.length) - int256(gameSettings.eliglblePlayers);
                i--) {
                Buyer storage existingBuyer = buyers[uint256(i)];

                if(existingBuyer.buyer == buyer) {
                    // shift all buyers after back one, and put new buyer at end of array
                    for(uint256 j = uint256(i).add(1); j < buyers.length; j = j.add(1)) {
                        buyers[j.sub(1)] = buyers[j];
                    }

                    buyers[buyers.length.sub(1)] = newBuyer;
                    added = true;
                    
                    break;
                }
            }

            if(!added) {
                buyers.push(newBuyer); 
            }

            _minimumBuyForPotEligibility = _minimumBuyForPotEligibility + _minimumBuyForPotEligibility.mul(gameSettings.increaseRatio).div(10 ** 5);
        }

        if(newTimeLeft < 0) {
            newTimeLeft = 0;
        }
        else if(newTimeLeft > int256(gameSettings.maxTimeLeft)) {
            newTimeLeft = int256(gameSettings.maxTimeLeft);
        }

        timeLeftAtLastBuy = uint256(newTimeLeft);
        lastBuyBlock = block.number;

        emit Buy(
            isEligible,
            buyer,
            amount,
            uint256(oldTimeLeft),
            uint256(newTimeLeft),
            block.timestamp,
            block.number
        );
    }

    function swapAndLiquify(uint256 swapAmount) private {
        // split the value able to be liquified into halves


        uint256 half = swapAmount.div(2);
        uint256 otherHalf = swapAmount.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityAddress,
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        uint256 currentRate = _getRate();
        _lastRate[sender] = currentRate;
        _lastRate[recipient] = currentRate;
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidityAndPot, uint256 tDev) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidityAndPot(tLiquidityAndPot);
        _takeDev(tDev);
        
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidityAndPot, uint256 tDev) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidityAndPot(tLiquidityAndPot);
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidityAndPot, uint256 tDev) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidityAndPot(tLiquidityAndPot);
        _takeDev(tDev);
        
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }


    function potValue() public view returns (uint256) {
        return address(this).balance.mul(gameSettings.potPayoutPercent).div(100);
    }

    function timeLeft() public view returns (int256) {
        if(!gameIsActive) {
            return 0;
        }

        uint256 blocksSinceLastBuy = block.number.sub(lastBuyBlock);

        return int256(timeLeftAtLastBuy) - int256(blocksSinceLastBuy.mul(3));
    }

    function currentPotFee() public view returns (uint256) {
        return _potFee;
    }

    function completeRoundWhenNoTimeLeft() public {
        int256 secondsLeft = timeLeft();

        if(secondsLeft >= 0) {
            return;
        }

        (address[] memory buyers, uint256[] memory payoutAmounts) = _getPayoutAmounts();

        uint256 lastRoundNumber = roundNumber;

        roundNumber = roundNumber.add(1);

        timeLeftAtLastBuy = gameSettings.initTimeLeft;
        lastBuyBlock = block.number;
        _minimumBuyForPotEligibility = gameSettings.minimumBuyForPotEligibility;

        for(uint256 i = 0; i < buyers.length; i = i.add(1)) {
            uint256 amount = payoutAmounts[i];

            if(amount > 0) {
                (bool success, ) = buyers[i].call { value: amount, gas: 5000 }("");

                emit RoundPayout(
                    lastRoundNumber,
                    buyers[i],
                    amount,
                    success
                );
            }
        }

        emit RoundEnded(
            lastRoundNumber,
            buyers,
            payoutAmounts
        );


        emit RoundStarted(
            roundNumber,
            potValue()
        );
    }

    function _getPayoutAmounts()
        internal
        view
        returns (address[] memory buyers,
                 uint256[] memory payoutAmounts) {

        buyers = new address[](gameSettings.eliglblePlayers);
        payoutAmounts = new uint256[](gameSettings.eliglblePlayers);

        Buyer[] storage roundBuyers = buyersByRound[roundNumber];

        if(roundBuyers.length > 0) {
            uint256 totalPayout = potValue();

            uint256 lastBuyerPayout = totalPayout.mul(gameSettings.lastBuyerPayoutPercent).div(100);

            uint256 payoutLeft = totalPayout.sub(lastBuyerPayout);


            uint256 numberOfWinners = roundBuyers.length > gameSettings.eliglblePlayers ? gameSettings.eliglblePlayers : roundBuyers.length;

            uint256 amountLeft;

            for(int256 i = int256(roundBuyers.length) - 1; i >= int256(roundBuyers.length) - int256(numberOfWinners); i--) {
                amountLeft = amountLeft.add(roundBuyers[uint256(i)].amount);
            }

            uint256 returnIndex = 0;

            for(int256 i = int256(roundBuyers.length) - 1; i >= int256(roundBuyers.length) - int256(numberOfWinners); i--) {

                uint256 amount = roundBuyers[uint256(i)].amount;

                uint256 payout = 0;

                if(amountLeft > 0) {
                    payout = payoutLeft.mul(amount).div(amountLeft);
                }

                amountLeft = amountLeft.sub(amount);
                payoutLeft = payoutLeft.sub(payout);

                buyers[returnIndex] = roundBuyers[uint256(i)].buyer;
                payoutAmounts[returnIndex] = payout;

                if(returnIndex == 0) {
                    payoutAmounts[0] = payoutAmounts[0].add(lastBuyerPayout);
                }

                returnIndex = returnIndex.add(1);
            }
        }
    }

    function getWinner(uint256 roundIdx)
        external
        view
        returns (address[] memory winnerAddresses,
                 uint256[] memory winnerTime,
                 uint256[] memory winnerRewards) {
        

        Buyer[] storage buyers = buyersByRound[roundIdx];
        
        uint256 iteration = 0;

        winnerAddresses = new address[](gameSettings.eliglblePlayers);
        winnerTime = new uint256[](gameSettings.eliglblePlayers);
        winnerRewards = new uint256[](gameSettings.eliglblePlayers);
        
        (, uint256[] memory payoutAmounts) = _getPayoutAmounts();

        for(int256 i = int256(buyers.length) - 1; i >= 0; i--) {

            Buyer storage buyer = buyers[uint256(i)];

            winnerAddresses[iteration] = buyer.buyer;
            winnerTime[iteration] = buyer.blockTime;
            winnerRewards[iteration] = payoutAmounts[iteration];

            iteration = iteration.add(1);

            if(iteration == gameSettings.eliglblePlayers) {
                break;
            }
        }
     }

    function gameStats()
        external
        view
        returns (uint256 currentRoundNumber,
                 int256 currentTimeLeft,
                 uint256 currentPotValue,
                 uint256 currentTimeLeftAtLastBuy,
                 uint256 currentLastBuyBlock,
                 uint256 currentBlockTime,
                 uint256 currentBlockNumber,
                 uint256 currentMinBuyForPotEligibility,
                 address[] memory lastBuyerAddress,
                 uint256[] memory lastBuyerData) {
        currentRoundNumber = roundNumber;
        currentTimeLeft = timeLeft();
        currentPotValue = potValue();
        currentTimeLeftAtLastBuy = timeLeftAtLastBuy;
        currentLastBuyBlock = lastBuyBlock;
        currentBlockTime = block.timestamp;
        currentBlockNumber = block.number;
        currentMinBuyForPotEligibility = _minimumBuyForPotEligibility;

        lastBuyerAddress = new address[](gameSettings.eliglblePlayers);
        lastBuyerData = new uint256[](gameSettings.eliglblePlayers.mul(6));

        Buyer[] storage buyers = buyersByRound[roundNumber];

        uint256 iteration = 0;

        (, uint256[] memory payoutAmounts) = _getPayoutAmounts();

        for(int256 i = int256(buyers.length) - 1; i >= 0; i--) {

            Buyer storage buyer = buyers[uint256(i)];

            lastBuyerAddress[iteration] = buyer.buyer;
            lastBuyerData[iteration.mul(6).add(0)] = buyer.amount;
            lastBuyerData[iteration.mul(6).add(1)] = buyer.timeLeftBefore;
            lastBuyerData[iteration.mul(6).add(2)] = buyer.timeLeftAfter;
            lastBuyerData[iteration.mul(6).add(3)] = buyer.blockTime;
            lastBuyerData[iteration.mul(6).add(4)] = buyer.blockNumber;
            lastBuyerData[iteration.mul(6).add(5)] = payoutAmounts[iteration];

            iteration = iteration.add(1);

            if(iteration == gameSettings.eliglblePlayers) {
                break;
            }
        }
    }
}